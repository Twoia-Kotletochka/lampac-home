#!/bin/bash
UA="Mozilla/5.0"
curl -sL --max-time 40 -A "$UA" "https://iptv-org.github.io/iptv/countries/ua.m3u" -o /tmp/ua.m3u
curl -sL --max-time 40 -A "$UA" "https://iptv.org.ua/iptv/ua.m3u" -o /tmp/big.m3u
DIR="$(cd "$(dirname "$0")" && pwd)"
python3 "$DIR/gen_uatv.py" >> "$DIR/uatv-refresh.log" 2>&1
