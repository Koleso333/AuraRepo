#!/bin/bash
# Запуск виртуального рабочего стола XFCE + VNC + noVNC в контейнере.
set -e
export DISPLAY=:1
GEOM=${GEOM:-1600x900x24}
VNC_PORT=${VNC_PORT:-5901}
WEB_PORT=${WEB_PORT:-6080}
PASSFILE=/opt/desktop/vncpasswd

pkill -f "Xvfb :1" 2>/dev/null || true
pkill -f "x11vnc.*-rfbport $VNC_PORT" 2>/dev/null || true
pkill -f "websockify.*$WEB_PORT" 2>/dev/null || true
sleep 1

Xvfb :1 -screen 0 "$GEOM" -nolisten tcp >/var/log/xvfb.log 2>&1 &
for i in $(seq 20); do xdpyinfo -display :1 >/dev/null 2>&1 && break; sleep 0.5; done

dbus-launch --exit-with-session startxfce4 >/var/log/xfce.log 2>&1 &
sleep 3

x11vnc -display :1 -rfbport "$VNC_PORT" -rfbauth "$PASSFILE" \
       -localhost -forever -shared -noxdamage -ncache 0 >/var/log/x11vnc.log 2>&1 &
sleep 2

websockify --web=/usr/share/novnc "$WEB_PORT" "localhost:$VNC_PORT" >/var/log/novnc.log 2>&1 &
sleep 2
echo "noVNC: http://localhost:$WEB_PORT/vnc.html"
