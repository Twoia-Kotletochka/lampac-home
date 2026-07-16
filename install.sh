#!/usr/bin/env bash
# Установка self-hosted Lampac NextGen из этого пакета.
# Требуется: Docker + docker compose (плагин v2). Запускать на Linux-хосте.
#   ./install.sh
# Опции через переменные окружения:
#   SERVER_IP=192.168.1.50 ./install.sh   — заменить адрес сервера в конфигах
set -e
cd "$(dirname "$0")"

echo "== Lampac self-hosted — установка =="

if ! command -v docker >/dev/null 2>&1; then
  echo "!! Docker не найден. Установите Docker и повторите." >&2
  exit 1
fi

# 1. Docker-образ: загрузить из архива (самодостаточно) или подтянуть из реестра
if [ -f lampac-image.tar ]; then
  echo "-> Загружаю Docker-образ из архива (lampac-image.tar)..."
  docker load -i lampac-image.tar
elif [ -f lampac-image.tar.gz ]; then
  echo "-> Загружаю Docker-образ из архива (lampac-image.tar.gz)..."
  gunzip -c lampac-image.tar.gz | docker load
else
  echo "-> Образа в пакете нет — тяну из реестра ghcr.io..."
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
  echo "   пароль: $(cat lampac-docker/config/passwd)"
fi

# 3. Каталоги данных
mkdir -p storage/cache storage/data/ts storage/data/dlna lampac-docker/database

# 4. (опц.) сменить IP сервера во всех конфигах
if [ -n "$SERVER_IP" ] && [ "$SERVER_IP" != "192.168.0.92" ]; then
  echo "-> Меняю адрес 192.168.0.92 -> $SERVER_IP..."
  grep -rl '192\.168\.0\.92' lampac-docker/ 2>/dev/null | xargs -r sed -i "s/192\.168\.0\.92/$SERVER_IP/g"
fi

# 5. Запуск
echo "-> Запускаю контейнер..."
docker compose up -d

# 6. (опц.) авто-обновление украинского IPTV-плейлиста раз в сутки
if command -v crontab >/dev/null 2>&1 && [ -f lampac-docker/refresh_uatv.sh ]; then
  chmod +x lampac-docker/refresh_uatv.sh
  DIR="$(pwd)/lampac-docker"
  ( crontab -l 2>/dev/null | grep -v refresh_uatv.sh; echo "30 5 * * * $DIR/refresh_uatv.sh" ) | crontab - 2>/dev/null && \
    echo "-> Cron авто-обновления IPTV поставлен (05:30)."
fi

IP="${SERVER_IP:-<адрес-этого-сервера>}"
echo ""
echo "== Готово! =="
echo "Веб-Lampa:            http://$IP:9118"
echo "Плагин для Lampa (ТВ): добавьте в Расширения  http://$IP:9118/on.js"
echo "Парсер (Jackett):     http://$IP:9118   (ключ пустой, настроится сам)"
echo "TorrServer:           http://$IP:9118/ts"
