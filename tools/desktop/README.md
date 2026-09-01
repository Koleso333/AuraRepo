# Виртуальный рабочий стол в контейнере

XFCE + x11vnc + noVNC + Chromium для сессий Claude Code on the web.

## Установка

    sudo tools/desktop/setup-desktop.sh     # печатает сгенерированный VNC-пароль
    /opt/desktop/start-desktop.sh           # поднимает Xvfb :1, XFCE, VNC 5901, noVNC 6080

Доступ: `http://localhost:6080/vnc.html`, пароль из вывода setup-скрипта.
VNC слушает только localhost.

## Особенности среды

Весь исходящий HTTPS идёт через агент-прокси с перевыпуском TLS, поэтому:

* CA-бандл `/root/.ccr/ca-bundle.crt` импортируется в системное хранилище и в NSS-базу браузера;
* Chromium запускается через обёртку `/usr/local/bin/chromium` с `--proxy-server`,
  `--disable-quic` и `--ssl-version-max=tls1.2` — большой TLS 1.3 ClientHello
  (post-quantum keyshare) egress-прокси обрывает с `ERR_CONNECTION_RESET`;
* `github.com` в браузере отдаёт заглушку политики: работа с GitHub идёт через MCP-инструменты.
