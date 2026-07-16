(function () {
    'use strict';

    // Включение торрентов + жёсткая автонастройка парсера Jackett на наш сервер.
    var HOST = '192.168.0.92:9118';

    try {
        localStorage.setItem('remove_white_and_demo', '1');
        localStorage.setItem('parser_use', '1');
    } catch (e) {}

    function apply() {
        if (!window.Lampa || !Lampa.Storage) return false;
        try {
            Lampa.Storage.set('parser_use', true);
            Lampa.Storage.set('torrents_use', true);
            Lampa.Storage.set('parser_torrent_type', 'jackett');
            Lampa.Storage.set('jackett_url', HOST);
            Lampa.Storage.set('jackett_key', '1');

            window.lampa_settings = window.lampa_settings || {};
            window.lampa_settings.torrents_use = true;
            window.lampa_settings.demo = false;

            if (Lampa.Settings && Lampa.Settings.listener) {
                Lampa.Settings.listener.follow('open', function (e) {
                    try {
                        if (e && e.name === 'main' && e.body) {
                            e.body.find(['parser', 'server', 'plugins']
                                .map(function (a) { return '[data-component="' + a + '"]'; }).join(', '))
                                .removeClass('hide');
                        }
                    } catch (_) {}
                });
            }
            return true;
        } catch (e) { return false; }
    }

    if (!apply()) {
        if (window.Lampa && Lampa.Listener) {
            Lampa.Listener.follow('app', function (e) { if (e.type === 'ready') apply(); });
        }
        var t = setInterval(function () { if (apply()) clearInterval(t); }, 500);
        setTimeout(function () { clearInterval(t); }, 20000);
    }
})();
