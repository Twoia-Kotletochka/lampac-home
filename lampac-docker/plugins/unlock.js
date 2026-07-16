(function () {
    'use strict';

    // Возврат «Торрентов»/«Парсера»/«TorrServer» в магазинных сборках Lampa (демо-режим).
    // Адрес сервера здесь НЕ нужен: парсер настраивается в on.js через {localhost}.

    try {
        localStorage.setItem('remove_white_and_demo', '1'); // выключить демо-режим
        localStorage.setItem('parser_use', '1');            // не глушить торренты
    } catch (e) {}

    function apply() {
        if (!window.Lampa || !Lampa.Storage) return false;
        try {
            Lampa.Storage.set('parser_use', true);
            Lampa.Storage.set('torrents_use', true);

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
