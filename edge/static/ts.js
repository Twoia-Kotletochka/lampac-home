(function () {
    'use strict';

    var unic_id = Lampa.Storage.get('lampac_unic_id', '');
    if (!unic_id) {
        unic_id = Lampa.Utils.uid(8).toLowerCase();
        Lampa.Storage.set('lampac_unic_id', unic_id);
    }

    // Адрес берём из текущего origin — ничего не зашито, работает на любом домене.
    Lampa.Storage.set('torrserver_url', location.host + '/ts');

    // Собственную авторизацию TorrServer на клиенте НЕ включаем: Lampac подставляет
    // учётные данные сам. Если её включить, Lampa начнёт слать свой заголовок
    // Authorization на /ts/*, он затрёт пароль входа на сайт, прокси ответит 401 —
    // и браузер будет бесконечно спрашивать пароль.
    Lampa.Storage.set('torrserver_auth', false);
    Lampa.Storage.set('torrserver_login', '');
    Lampa.Storage.set('torrserver_password', '');
})();

/* ------------------------------------------------------------------
   Открытие торрента во внешнем плеере одним кликом.

   Клик по файлу отдаёт .m3u, который система открывает плеером по
   умолчанию (VLC и т.п.). Пароль плеер не спрашивает: плейлист собирает
   сервер (/openin) и дописывает в него токен, дающий доступ ТОЛЬКО к
   воспроизведению — ни интерфейса, ни API по нему не получить.

   Встроенный плеер не ломается: событие 'create' штатно умеет отменять
   запуск через abort(), поэтому обезьяньих патчей здесь нет.
   Выключается в Настройки -> Плеер.
   ------------------------------------------------------------------ */
(function () {
    'use strict';

    var PARAM = 'open_in_external';

    if (!window.Lampa || !Lampa.Player || !Lampa.Player.listener) return;

    try {
        Lampa.SettingsApi.addParam({
            component: 'player',
            param: { name: PARAM, type: 'trigger', 'default': true },
            field: {
                name: 'Открывать торренты во внешнем плеере',
                description: 'Отдаёт .m3u — файл открывается в VLC. Выключите, чтобы смотреть в браузере'
            }
        });
    } catch (e) {}

    function enabled() {
        try {
            var v = Lampa.Storage.field(PARAM);
            return !(v === false || v === 'false');
        } catch (e) { return true; }
    }

    function isTorrentStream(url) {
        return typeof url === 'string' && url.indexOf('/ts/stream') !== -1;
    }

    function openExternal(data) {
        var url = String(data.url).replace('&preload', '&play');
        var title = String(data.title || 'video').replace(/[\r\n]+/g, ' ').slice(0, 120);

        var a = document.createElement('a');
        a.href = '/openin?u=' + encodeURIComponent(url) + '&title=' + encodeURIComponent(title);
        a.style.display = 'none';
        document.body.appendChild(a);
        a.click();
        setTimeout(function () { try { a.remove(); } catch (e) {} }, 5000);

        try { Lampa.Noty.show('Открываю во внешнем плеере'); } catch (e) {}
    }

    Lampa.Player.listener.follow('create', function (e) {
        try {
            if (!enabled()) return;
            if (!e || !e.data || !isTorrentStream(e.data.url)) return;
            e.abort();
            openExternal(e.data);
        } catch (err) {}
    });
})();

/* ------------------------------------------------------------------
   Заставка при простое в браузере.

   По умолчанию Lampa ставит тип Aerial — ролики Apple с sylvan.apple.com.
   В браузере они не работают НИКОГДА, по двум независимым причинам:
     1) Lampa строит адрес как .replace('https:', 'http:') — на https-странице
        браузер блокирует это как смешанный контент, запрос даже не уходит;
     2) сами файлы — настоящий QuickTime (ftyp 'qt  '), а не MP4. Chromium
        такой контейнер не проигрывает: <video> отдаёт ошибку 4
        (MEDIA_ERR_SRC_NOT_SUPPORTED) даже по https.
   На телевизоре ни то, ни другое не мешает, поэтому там заставка работает.

   Переводим на тип CUB: это обычный mp4 (ftyp isom, 1920x1080), проверено —
   проигрывается. Делается ОДИН раз: если потом выбрать Aerial вручную
   в Прочее -> Скринсейвер -> Тип заставки, выбор сохранится.
   ------------------------------------------------------------------ */
(function () {
    'use strict';
    try {
        if (location.protocol !== 'https:') return;            // телевизор не трогаем
        if (Lampa.Storage.get('screensaver_fixed', '')) return; // уже переключали
        Lampa.Storage.set('screensaver_fixed', '1');
        if (Lampa.Storage.get('screensaver_type', 'aerial') === 'aerial') {
            Lampa.Storage.set('screensaver_type', 'cub');
        }
    } catch (e) {}
})();
