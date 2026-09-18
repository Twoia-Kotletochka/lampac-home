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
