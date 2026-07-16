import re, json

OUT = "/srv/lampac/lampac-docker/plugins/uatv.js"

AD_RE = re.compile(r'iptv\.org\.ua|tva\.in\.ua|tva\.org\.ua|mater\.com|fas-tv|ревиз|reviz|💰|👍|\*in-ua|\*org\*ua', re.I)

def parse(path, drop_radio=False, drop_ads=False):
    try:
        text = open(path, encoding="utf-8", errors="ignore").read().replace("\r", "")
    except Exception:
        return []
    lines = text.split("\n")
    out, cur = [], None
    for line in lines:
        line = line.strip()
        if line.startswith("#EXTINF"):
            name = line[line.rfind(",") + 1:].strip()
            m = re.search(r'tvg-logo="([^"]*)"', line)
            logo = m.group(1) if m else ""
            g = re.search(r'group-title="([^"]*)"', line)
            group = g.group(1) if g else ""
            cur = {"title": name, "img": logo, "group": group}
        elif line and not line.startswith("#") and cur:
            cur["url"] = line
            bad = False
            if drop_ads and (AD_RE.search(cur["title"]) or AD_RE.search(cur.get("group", ""))):
                bad = True
            if drop_radio and cur.get("group", "").upper().find("РАДІО") >= 0:
                bad = True
            if cur["title"] and not bad:
                out.append(cur)
            cur = None
    # дедуп по title+url
    seen, uniq = set(), []
    for c in out:
        k = c["title"] + "|" + c["url"]
        if k in seen:
            continue
        seen.add(k)
        uniq.append(c)
    uniq.sort(key=lambda c: c["title"].lower())
    return uniq

list1 = parse("/tmp/ua.m3u")                                   # iptv-org (чистый)
list2 = parse("/tmp/big.m3u", drop_radio=True, drop_ads=True)  # агрегатор (фильтр рекламы/радио)

LISTS = [
    {"name": "Украïна ТВ", "channels": list1},
    {"name": "Украïна ТВ+", "channels": list2},
]
data_js = json.dumps(LISTS, ensure_ascii=False)

plugin = r'''(function () {
    'use strict';

    var LISTS = __LISTS__;

    function playChannels(channels, index) {
        var playlist = channels.map(function (c) {
            return { title: c.title, url: c.url, img: c.img, need_check_live_stream: true, iptv: true };
        });
        try { Lampa.Player.runas(Lampa.Storage.field('player_iptv')); } catch (e) {}
        Lampa.Player.play(playlist[index]);
        Lampa.Player.playlist(playlist);
    }

    function open(list) {
        var channels = list.channels;
        var items = channels.map(function (c, i) {
            return { title: c.title, subtitle: c.group || '', idx: i };
        });
        Lampa.Select.show({
            title: list.name + ' (' + channels.length + ')',
            items: items,
            onBack: function () { Lampa.Controller.toggle('menu'); },
            onSelect: function (item) { playChannels(channels, item.idx); }
        });
    }

    function addMenu() {
        if (!window.$ || !$('.menu .menu__list').length) return false;
        var icon = '<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><rect x="2" y="4" width="20" height="13" rx="2" stroke="currentColor" stroke-width="2"/><path d="M8 20h8M12 17v3" stroke="currentColor" stroke-width="2" stroke-linecap="round"/></svg>';
        LISTS.forEach(function (list, li) {
            var action = 'uatv' + li;
            if ($('.menu .menu__list [data-action="' + action + '"]').length) return;
            var item = $('<li class="menu__item selector" data-action="' + action + '"><div class="menu__ico">' + icon + '</div><div class="menu__text">' + list.name + '</div></li>');
            item.on('hover:enter', function () { open(list); });
            $('.menu .menu__list').eq(0).append(item);
        });
        return true;
    }

    function start() {
        if (addMenu()) return;
        var tries = 0;
        var t = setInterval(function () {
            tries++;
            if (addMenu() || tries > 40) clearInterval(t);
        }, 500);
    }

    if (window.appready) start();
    else if (window.Lampa && Lampa.Listener) Lampa.Listener.follow('app', function (e) { if (e.type === 'ready') start(); });
    else start();
})();
'''

plugin = plugin.replace("__LISTS__", data_js)
open(OUT, "w", encoding="utf-8").write(plugin)
print("list1 (iptv-org):", len(list1), "| list2 (aggregator):", len(list2), "-> size:", len(plugin))
