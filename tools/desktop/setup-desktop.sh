#!/bin/bash
# Разворачивает виртуальный рабочий стол (XFCE + x11vnc + noVNC) и Chromium
# в контейнере Claude Code on the web. Запускать от root.
set -e
export DEBIAN_FRONTEND=noninteractive
HERE=$(cd "$(dirname "$0")" && pwd)

apt-get update -qq
apt-get install -y --no-install-recommends \
  xfce4 xfce4-terminal dbus-x11 x11vnc xvfb novnc websockify python3-numpy \
  fonts-dejavu-core scrot x11-utils ca-certificates libnss3-tools

# Доверие к CA агент-прокси (система + NSS-хранилище браузера)
if [ -f /root/.ccr/ca-bundle.crt ]; then
  cp /root/.ccr/ca-bundle.crt /usr/local/share/ca-certificates/ccr-agent-proxy.crt
  update-ca-certificates
  mkdir -p /root/.pki/nssdb
  [ -f /root/.pki/nssdb/cert9.db ] || certutil -N -d sql:/root/.pki/nssdb --empty-password
  tmp=$(mktemp -d)
  csplit -z -f "$tmp/ca-" -b '%03d.pem' /root/.ccr/ca-bundle.crt '/BEGIN CERTIFICATE/' '{*}' >/dev/null
  for f in "$tmp"/ca-*.pem; do
    certutil -A -d sql:/root/.pki/nssdb -t "C,," -n "ccr-$(basename "$f" .pem)" -i "$f" 2>/dev/null || true
  done
  rm -rf "$tmp"
fi

mkdir -p /opt/desktop
install -m 755 "$HERE/start-desktop.sh" /opt/desktop/start-desktop.sh
install -m 755 "$HERE/chromium" /usr/local/bin/chromium

cat > /usr/share/applications/chromium-desktop.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=Chromium
Exec=/usr/local/bin/chromium %U
Icon=web-browser
Categories=Network;WebBrowser;
EOF

# Пароль VNC
PW=${VNC_PASSWORD:-$(head -c 9 /dev/urandom | base64 | tr -d '/+=' | cut -c1-8)}
x11vnc -storepasswd "$PW" /opt/desktop/vncpasswd >/dev/null 2>&1
chmod 600 /opt/desktop/vncpasswd
echo "VNC-пароль: $PW"
echo "Запуск: /opt/desktop/start-desktop.sh"
