-- MoldOS Language Module
-- /os/lib/lang.lua
-- Loaded via: local lang = dofile("/os/lib/lang.lua")
-- Usage: lang.t("key") returns the translated string for the current language

local LANG_FILE = "/os/data/language.lua"

local translations = {
    en = {
        installer_title = "MoldOS Setup",
        installer_welcome = "Welcome to the MoldOS installation wizard.",
        installer_welcome2 = "You will now be asked a few setup questions.",
        click_to_begin = "Click anywhere to begin...",
        select_language = "Select Language",
        select_country = "Select Country",
        select_timezone = "Time Zone",
        create_profile = "Create Profile",
        enter_username = "Enter username:",
        set_password = "Set a password (leave empty for none):",
        field_empty = "This field cannot be empty!",
        review_settings = "Review your settings",
        language_label = "Language",
        country_label = "Country",
        timezone_label = "Time zone",
        username_label = "Username",
        password_label = "Password",
        none = "(none)",
        install_btn = "Install",
        cancel_btn = "Cancel",
        install_cancelled = "Installation cancelled.",
        installing = "Installing MoldOS",
        preparing_system = "Preparing system...",
        saving_settings = "Saving settings...",
        creating_account = "Creating user account...",
        downloading_files = "Downloading files from GitHub...",
        finishing_install = "Finishing installation...",
        install_complete = "Installation Complete",
        install_success = "MoldOS was installed successfully!",
        rebooting_now = "The computer will now reboot.",
        install_error = "Installation Error",
        failed_download = "Failed to download files:",
        check_http = "Check that HTTP is enabled on the server",
        check_repo = "and that REPO_BASE in installer.lua is correct.",

        starting_system = "Starting system...",
        select_account = "Select your account",
        welcome_back = "Welcome back,",
        password_colon = "Password:",
        incorrect_password = "Incorrect password.",
        good_morning = "Good morning",
        good_afternoon = "Good afternoon",
        good_evening = "Good evening",
        good_night = "Good night",

        apps_section = "-- Apps --",
        system_section = "-- System --",
        no_apps = "(no apps installed)",
        about_system = "About System",
        network_chat = "Network Chat",
        settings = "Settings",
        check_updates = "Check for Updates",
        install_app = "Install App",
        log_out = "Log Out",
        reboot = "Reboot",
        shutdown = "Shutdown",
        click_go_back = "Click anywhere to go back...",
        error_running = "Error running program:",

        change_password = "Change Password",
        change_username = "Change Username",
        create_new_user = "Create New User",
        delete_user = "Delete a User",
        back = "Back",
        current_password = "Current password:",
        incorrect_current = "Incorrect current password.",
        new_password = "New password (leave empty for none):",
        password_changed = "Password changed successfully!",
        new_username = "New username:",
        username_taken = "That username is already taken.",
        username_changed = "Username changed to",
        username_label2 = "Username:",
        user_exists = "That username already exists.",
        user_created = "User created!",
        user_not_found = "User not found.",
        cannot_delete_self = "You cannot delete the account you are logged into.",
        user_deleted = "deleted.",
        select_ui_language = "Select interface language",

        checking_updates = "Checking for updates...",
        update_complete = "Update complete! Rebooting...",
        update_some_failed = "Some files failed to update. Check your connection.",
        available_apps = "Available apps:",
        enter_app_name = "Enter app name to install:",
        unknown_app = "Unknown app:",
        installing_dots = "Installing",
        installed_success = "Installed successfully!",
        install_failed = "Failed:",

        no_modem = "No modem attached to this computer.",
        your_computer_id = "Your computer ID:",
        enter_target_id = "Enter target computer ID (or 'all' to broadcast):",
        type_message = "Type your message. Type 'exit' to quit chat.",
        invalid_target = "Invalid target ID.",

        file_manager_title = "File Manager:",
        new_folder_name = "New folder name:",
        rename_to = "Rename to:",
        already_exists = "already exists.",
        overwrite_question = "Overwrite?",
        yes = "Yes",
        no = "No",
        delete_confirm = "Delete",
        clipboard_label = "Clipboard:",
        quit = "Quit",

        calc_title = "MoldOS Calculator",

        sysinfo_title = "System Information",
        craftos_version = "CraftOS version:",
        computer_id = "Computer ID:",
        computer_label = "Computer label:",
        not_set = "(not set)",
        disk_label = "Disk:",
        free_of = "free of",
        click_exit = "Click anywhere to exit...",

        notes_title = "MoldOS Notes",
        new_note_title = "New note title:",
        note_exists = "A note with that title already exists.",
        writing_note = "Writing note:",
        type_note = "Type your note. Finish with an empty line.",
        new_note_btn = "New Note",
        delete_btn = "Delete",
        no_notes = "(no notes yet)",

        netshare_title = "MoldOS Netshare",
        scanning = "Scanning for computers...",
        no_computers_found = "No other computers found on the network.",
        computers_found = "Computers Found",
        click_computer_send = "Click a computer to send a file to it",
        enter_file_path = "Enter the full path of the file to send:",
        file_not_found = "File not found.",
        sent_to = "Sent",
        to_computer = "to computer",
        received_from = "Received file from computer",
        saved_to = "Saved to:",
        send_file_btn = "Send a File",
        click_continue = "Click anywhere to continue...",

        score_label = "Score:",
        game_over = "Game Over! Final score:",
        you_win = "You win! Click anywhere to exit...",
        boom = "Boom! Click anywhere to exit...",
        arrow_keys_quit = "Arrow keys to move, Q to quit",
        left_click_reveal = "Left-click: reveal   Right-click: flag",
    },

    ru = {
        installer_title = "Установка MoldOS",
        installer_welcome = "Добро пожаловать в мастер установки MoldOS.",
        installer_welcome2 = "Сейчас потребуется задать несколько настроек.",
        click_to_begin = "Нажмите в любом месте, чтобы начать...",
        select_language = "Выбор языка",
        select_country = "Выбор страны",
        select_timezone = "Часовой пояс",
        create_profile = "Создание профиля",
        enter_username = "Введите имя пользователя:",
        set_password = "Придумайте пароль (можно оставить пустым):",
        field_empty = "Поле не может быть пустым!",
        review_settings = "Проверьте настройки",
        language_label = "Язык",
        country_label = "Страна",
        timezone_label = "Часовой пояс",
        username_label = "Пользователь",
        password_label = "Пароль",
        none = "(не задан)",
        install_btn = "Установить",
        cancel_btn = "Отмена",
        install_cancelled = "Установка отменена.",
        installing = "Установка MoldOS",
        preparing_system = "Подготовка системы...",
        saving_settings = "Сохранение настроек...",
        creating_account = "Создание учётной записи...",
        downloading_files = "Скачивание файлов с GitHub...",
        finishing_install = "Завершение установки...",
        install_complete = "Установка завершена",
        install_success = "MoldOS успешно установлена!",
        rebooting_now = "Компьютер сейчас перезагрузится.",
        install_error = "Ошибка установки",
        failed_download = "Не удалось скачать файлы:",
        check_http = "Проверьте, что HTTP включён на сервере",
        check_repo = "и что REPO_BASE в installer.lua указан верно.",

        starting_system = "Запуск системы...",
        select_account = "Выберите свой аккаунт",
        welcome_back = "С возвращением,",
        password_colon = "Пароль:",
        incorrect_password = "Неверный пароль.",
        good_morning = "Доброе утро",
        good_afternoon = "Добрый день",
        good_evening = "Добрый вечер",
        good_night = "Доброй ночи",

        apps_section = "-- Приложения --",
        system_section = "-- Система --",
        no_apps = "(приложений не установлено)",
        about_system = "О системе",
        network_chat = "Сетевой чат",
        settings = "Настройки",
        check_updates = "Проверить обновления",
        install_app = "Установить приложение",
        log_out = "Выйти из аккаунта",
        reboot = "Перезагрузка",
        shutdown = "Выключение",
        click_go_back = "Нажмите в любом месте, чтобы вернуться...",
        error_running = "Ошибка запуска программы:",

        change_password = "Сменить пароль",
        change_username = "Сменить имя пользователя",
        create_new_user = "Создать пользователя",
        delete_user = "Удалить пользователя",
        back = "Назад",
        current_password = "Текущий пароль:",
        incorrect_current = "Неверный текущий пароль.",
        new_password = "Новый пароль (можно оставить пустым):",
        password_changed = "Пароль успешно изменён!",
        new_username = "Новое имя пользователя:",
        username_taken = "Это имя уже занято.",
        username_changed = "Имя пользователя изменено на",
        username_label2 = "Имя пользователя:",
        user_exists = "Пользователь с таким именем уже существует.",
        user_created = "Пользователь создан!",
        user_not_found = "Пользователь не найден.",
        cannot_delete_self = "Нельзя удалить аккаунт, в который вы вошли.",
        user_deleted = "удалён.",
        select_ui_language = "Выберите язык интерфейса",

        checking_updates = "Проверка обновлений...",
        update_complete = "Обновление завершено! Перезагрузка...",
        update_some_failed = "Некоторые файлы не удалось обновить. Проверьте соединение.",
        available_apps = "Доступные приложения:",
        enter_app_name = "Введите название приложения для установки:",
        unknown_app = "Неизвестное приложение:",
        installing_dots = "Установка",
        installed_success = "Установлено успешно!",
        install_failed = "Ошибка:",

        no_modem = "К этому компьютеру не подключён модем.",
        your_computer_id = "ID вашего компьютера:",
        enter_target_id = "Введите ID компьютера-получателя (или 'all' для рассылки всем):",
        type_message = "Введите сообщение. Введите 'exit' для выхода из чата.",
        invalid_target = "Неверный ID получателя.",

        file_manager_title = "Файловый менеджер:",
        new_folder_name = "Название новой папки:",
        rename_to = "Переименовать в:",
        already_exists = "уже существует.",
        overwrite_question = "Перезаписать?",
        yes = "Да",
        no = "Нет",
        delete_confirm = "Удалить",
        clipboard_label = "Буфер обмена:",
        quit = "Выход",

        calc_title = "Калькулятор MoldOS",

        sysinfo_title = "Информация о системе",
        craftos_version = "Версия CraftOS:",
        computer_id = "ID компьютера:",
        computer_label = "Имя компьютера:",
        not_set = "(не задано)",
        disk_label = "Диск:",
        free_of = "свободно из",
        click_exit = "Нажмите в любом месте, чтобы выйти...",

        notes_title = "Заметки MoldOS",
        new_note_title = "Заголовок новой заметки:",
        note_exists = "Заметка с таким названием уже существует.",
        writing_note = "Написание заметки:",
        type_note = "Введите текст заметки. Завершите пустой строкой.",
        new_note_btn = "Новая заметка",
        delete_btn = "Удалить",
        no_notes = "(заметок пока нет)",

        netshare_title = "MoldOS Обмен файлами",
        scanning = "Поиск компьютеров...",
        no_computers_found = "Другие компьютеры в сети не найдены.",
        computers_found = "Найденные компьютеры",
        click_computer_send = "Нажмите на компьютер, чтобы отправить ему файл",
        enter_file_path = "Введите полный путь к файлу для отправки:",
        file_not_found = "Файл не найден.",
        sent_to = "Отправлено",
        to_computer = "компьютеру",
        received_from = "Получен файл от компьютера",
        saved_to = "Сохранено в:",
        send_file_btn = "Отправить файл",
        click_continue = "Нажмите в любом месте, чтобы продолжить...",

        score_label = "Счёт:",
        game_over = "Игра окончена! Итоговый счёт:",
        you_win = "Вы победили! Нажмите в любом месте, чтобы выйти...",
        boom = "Бум! Нажмите в любом месте, чтобы выйти...",
        arrow_keys_quit = "Стрелки для движения, Q для выхода",
        left_click_reveal = "ЛКМ: открыть   ПКМ: флажок",
    },
}

local M = {}

local function loadCurrentLang()
    if fs.exists(LANG_FILE) then
        local f = fs.open(LANG_FILE, "r")
        local content = f.readAll()
        f.close()
        local ok, data = pcall(textutils.unserialize, content)
        if ok and data and translations[data] then
            return data
        end
    end
    return "en"
end

M.current = loadCurrentLang()

function M.setLanguage(code)
    if translations[code] then
        M.current = code
        local f = fs.open(LANG_FILE, "w")
        f.write(textutils.serialize(code))
        f.close()
    end
end

function M.t(key)
    local dict = translations[M.current] or translations.en
    return dict[key] or translations.en[key] or key
end

return M