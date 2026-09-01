#!/usr/bin/sh
set -eu

check_host="${LAMPAC_STARTUP_CHECK_HOST:-ns3bg91xvuqfvq9h.cfhttp.top}"
check_url="${LAMPAC_STARTUP_CHECK_URL:-http://ns3bg91xvuqfvq9h.cfhttp.top/api/v1.0/conf?apikey=1}"
wait_seconds="${LAMPAC_STARTUP_WAIT_SECONDS:-180}"

case "$wait_seconds" in
  ''|*[!0-9]*)
    wait_seconds=180
    ;;
esac

started_at="$(date +%s)"
deadline=$((started_at + wait_seconds))
attempt=0

network_ready() {
  getent ahostsv4 "$check_host" >/dev/null 2>&1 &&
    curl --fail --silent --show-error --max-time 5 --output /dev/null "$check_url"
}

while ! network_ready; do
  attempt=$((attempt + 1))
  now="$(date +%s)"

  if [ "$now" -ge "$deadline" ]; then
    echo "[lampac-startup] Network check did not pass within ${wait_seconds}s; starting Lampac with degraded-network warning."
    break
  fi

  if [ "$attempt" -eq 1 ] || [ $((attempt % 5)) -eq 0 ]; then
    echo "[lampac-startup] Waiting for DNS and upstream connectivity (${check_host}), attempt ${attempt}."
  fi

  sleep 2
done

if network_ready; then
  elapsed=$(( $(date +%s) - started_at ))
  echo "[lampac-startup] DNS and upstream are ready after ${elapsed}s."
fi

exec "$@"
