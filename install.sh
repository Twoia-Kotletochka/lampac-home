#!/usr/bin/env bash
# Установка self-hosted Lampac NextGen из этого пакета.
# Требуется: Docker + docker compose (плагин v2). Запускать на Linux-хосте.
#   ./install.sh
set -e
cd "$(dirname "$0")"

echo "== Lampac self-hosted — установка =="

if ! command -v docker >/dev/null 2>&1; then
  echo "!! Docker не найден. Установите Docker и повторите." >&2
  exit 1
fi

# 1. Docker-образ: из архива (самодостаточно) или из реестра ghcr.io
if [ -f lampac-image.tar ]; then
  echo "-> Загружаю Docker-образ из архива..."
  docker load -i lampac-image.tar
elif [ -f lampac-image.tar.gz ]; then
  echo "-> Загружаю Docker-образ из архива (gz)..."
  gunzip -c lampac-image.tar.gz | docker load
else
  echo "-> Образа в пакете нет — тяну из ghcr.io..."
  docker compose pull
fi

# 2. Пароль root, если ещё нет
if [ ! -s lampac-docker/config/passwd ]; then
  echo "-> Генерирую пароль root Lampac..."
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -base64 16 | tr -d '\n=+/' > lampac-docker/config/passwd
  else
    head -c 16 /dev/urandom | base64 | tr -d '\n=+/' > lampac-docker/config/passwd
  fi
  chmod 600 lampac-docker/config/passwd
  echo "   пароль root: $(cat lampac-docker/config/passwd)"
fi

# 3. Каталоги данных
mkdir -p storage/cache storage/data/ts storage/data/dlna lampac-docker/database

# 4. Запуск
echo "-> Запускаю контейнер..."
docker compose up -d

# 5. (опц.) авто-обновление украинского IPTV-плейлиста раз в сутки
if command -v crontab >/dev/null 2>&1 && [ -f lampac-docker/refresh_uatv.sh ]; then
  chmod +x lampac-docker/refresh_uatv.sh
  DIR="$(pwd)/lampac-docker"
  ( crontab -l 2>/dev/null | grep -v refresh_uatv.sh; echo "30 5 * * * $DIR/refresh_uatv.sh" ) | crontab - 2>/dev/null && \
    echo "-> Cron авто-обновления IPTV поставлен (05:30)."
fi

# локальный IP хоста — только для подсказки
IP=$(hostname -I 2>/dev/null | awk '{print $1}')
[ -z "$IP" ] && IP="<IP-этого-сервера>"

cat <<EOF

== Готово! ==
Адрес сервера в конфиги вписывать НЕ нужно — Lampac подставляет его сам
(переменная {localhost}) по тому адресу, по которому вы к нему обращаетесь.

Веб-Lampa:             http://$IP:9118
Плагин для Lampa (ТВ): Настройки -> Расширения -> http://$IP:9118/on.js
  (это единственный адрес, который вводится вручную — на нём завязано остальное)
Парсер торрентов:      Jackett, настроится сам
TorrServer:            http://$IP:9118/ts
EOF
