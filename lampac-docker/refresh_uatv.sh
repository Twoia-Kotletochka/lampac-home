#!/bin/bash
UA="Mozilla/5.0"
curl -sL --max-time 40 -A "$UA" "https://iptv-org.github.io/iptv/countries/ua.m3u" -o /tmp/ua.m3u
curl -sL --max-time 40 -A "$UA" "https://iptv.org.ua/iptv/ua.m3u" -o /tmp/big.m3u
python3 /srv/lampac/lampac-docker/gen_uatv.py >> /srv/lampac/lampac-docker/uatv-refresh.log 2>&1
