(function () {
    'use strict';

    // адрес сервера подставляет сам Lampac ({localhost} -> http://хост:порт). IP не зашит.
    var LHOST = '{localhost}';                             // напр. http://host:9118
    var LHOSTNP = LHOST.replace(/^https?:\/\//, '');       // хост:порт без схемы (для парсера)

    // === Lampac inline unlock: демо-режим off + автонастройка парсера Jackett ===
    // Выполняется при каждой загрузке on.js (грузится надёжно как добавленный плагин).
    // блокируем загрузку CUB-плагина shots (заставки на главной): фильтруем его URL из putScriptAsync
    try {
        if (window.Lampa && Lampa.Utils && Lampa.Utils.putScriptAsync && !Lampa.Utils.__noshots) {
            var _psa = Lampa.Utils.putScriptAsync;
            Lampa.Utils.putScriptAsync = function (urls, ok, err) {
                try { if (Array.isArray(urls)) urls = urls.filter(function (u) { return String(u).indexOf('/plugin/shots') === -1; }); } catch (_) {}
                return _psa.call(this, urls, ok, err);
            };
            Lampa.Utils.__noshots = true;
        }
        // подстраховка CSS: прячем строки/элементы shots, если плагин всё же успел загрузиться
        if (!document.getElementById('__noshots_css')) {
            var st = document.createElement('style');
            st.id = '__noshots_css';
            st.textContent = '.shots-line-title,.shots-slides,.shots-view-button{display:none !important}';
            (document.head || document.body || document.documentElement).appendChild(st);
        }
    } catch (e) {}

    try {
        var need_reload = false;
        if (!localStorage.getItem('remove_white_and_demo')) { localStorage.setItem('remove_white_and_demo', '1'); need_reload = true; }
        if (!localStorage.getItem('parser_use')) { localStorage.setItem('parser_use', '1'); need_reload = true; }

        window.lampa_settings = window.lampa_settings || {};
        window.lampa_settings.demo = false;
        window.lampa_settings.torrents_use = true;

        // отключить shots (заставки/превью CUB на главной)
        window.lampa_settings.shots = false;

        if (window.Lampa && Lampa.Storage) {
            Lampa.Storage.set('parser_use', true);
            Lampa.Storage.set('torrents_use', true);
            Lampa.Storage.set('parser_torrent_type', 'jackett');
            Lampa.Storage.set('jackett_url', LHOSTNP);
            Lampa.Storage.set('jackett_key', '1');
            Lampa.Storage.set('shots', false);
        }

        // подстраховка: снимаем скрытие разделов настроек при каждом открытии
        if (window.Lampa && Lampa.Settings && Lampa.Settings.listener) {
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

        // одноразовая перезагрузка, чтобы стартовая проверка демо-режима прошла с флагом
        if (need_reload && !sessionStorage.getItem('__lampac_unlock_done')) {
            sessionStorage.setItem('__lampac_unlock_done', '1');
            setTimeout(function () { location.reload(); }, 1500);
        }
    } catch (e) {}

    // украинский IPTV (свой плагин с сервера, каналы встроены)
    try { Lampa.Utils.putScriptAsync([LHOST + '/uatv.js'], function () {}); } catch (e) {}

    Lampa.Utils.putScriptAsync([{plugins}], function() {});
})();
