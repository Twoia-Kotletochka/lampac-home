#!/usr/bin/env bash
# Внешний доступ к Lampa: домен через Cloudflare-туннель + вход по логину и паролю.
# Локальные клиенты (телевизор и прочие в домашней сети) продолжают ходить
# напрямую на порт 9118 без всякого пароля — их это не касается.
#
#   ./setup.sh
set -e
cd "$(dirname "$0")"

echo "== Внешний доступ к Lampa: настройка =="

command -v docker >/dev/null 2>&1 || { echo "!! Docker не найден." >&2; exit 1; }

# 1. Логин и пароль для входа снаружи
if [ ! -s creds.txt ]; then
  read -rp "Логин для входа снаружи [lampa]: " LOGIN
  LOGIN="${LOGIN:-lampa}"
  read -rsp "Пароль (Enter — сгенерировать надёжный): " PASS; echo
  if [ -z "$PASS" ]; then
    PASS=$(openssl rand -base64 18 | tr -d '\n=+/' | cut -c1-20)
    echo "   сгенерирован пароль: $PASS"
  fi
  printf '%s\n%s\n' "$LOGIN" "$PASS" > creds.txt
  chmod 600 creds.txt
fi
LOGIN=$(sed -n 1p creds.txt); PASS=$(sed -n 2p creds.txt)

# 2. Хеш пароля (bcrypt) — считает сам caddy, открытый пароль в конфиг не попадает
echo "-> Считаю хеш пароля..."
docker run --rm caddy:2-alpine caddy hash-password --plaintext "$PASS" > hash.txt
chmod 600 hash.txt

# 3. Токен для внешнего плеера: даёт доступ ТОЛЬКО к воспроизведению,
#    чтобы VLC не спрашивал пароль. Ни интерфейс, ни API по нему не открыть.
[ -s streamkey.txt ] || { openssl rand -hex 24 > streamkey.txt; chmod 600 streamkey.txt; }

# 4. Конфиг прокси из шаблона
sed -e "s|__USER__|$LOGIN|" -e "s|__HASH__|$(cat hash.txt)|" \
    -e "s|__STREAMKEY__|$(cat streamkey.txt)|" Caddyfile.template > Caddyfile
docker run --rm -v "$(pwd)/Caddyfile:/etc/caddy/Caddyfile:ro" caddy:2-alpine \
  caddy validate --config /etc/caddy/Caddyfile >/dev/null 2>&1 \
  && echo "-> Конфиг прокси собран и проверен."

# 5. Токен туннеля
[ -s .env ] || cp .env.example .env
chmod 600 .env
if ! grep -qE '^TUNNEL_TOKEN=.+' .env; then
  echo
  echo "Осталось создать туннель в Cloudflare:"
  echo "  Zero Trust -> Networks -> Tunnels -> Create a tunnel -> Cloudflared"
  echo "  Public hostname: ваш субдомен, Type HTTP, URL  127.0.0.1:9119"
  echo "  ВАЖНО: раздел Private Networks не трогать — он открывает всю вашу сеть."
  echo
  read -rp "Вставьте токен туннеля (или Enter, чтобы вписать в .env позже): " TOKEN
  [ -n "$TOKEN" ] && printf 'TUNNEL_TOKEN=%s\n' "$TOKEN" >> .env
fi

# 6. Запуск
if grep -qE '^TUNNEL_TOKEN=.+' .env; then
  docker compose up -d
else
  echo "-> Токена пока нет, поднимаю только слой авторизации."
  docker compose up -d auth
fi

cat <<TXT

== Готово ==
Логин:  $LOGIN
Пароль: $PASS   (лежит в creds.txt, права 600)

Порт 9119 слушает только loopback: из локальной сети он не виден,
попасть на него можно исключительно через туннель.
Локальный адрес http://<IP-сервера>:9118 работает как раньше, без пароля.

Сменить пароль: впишите новый в creds.txt, удалите hash.txt и запустите ./setup.sh снова.
TXT
