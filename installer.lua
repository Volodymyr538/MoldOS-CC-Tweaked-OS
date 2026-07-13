-- ============================================
--  MoldOS Installer
--  Run via: wget run <link to installer.lua on GitHub>
-- ============================================

local REPO_BASE = "https://raw.githubusercontent.com/Volodymyr538/OS/main/"

local FILES_TO_DOWNLOAD = {
    { url = REPO_BASE .. "os/startup.lua",       path = "/os/startup.lua" },
    { url = REPO_BASE .. "lib/lang.lua",         path = "/os/lib/lang.lua" },
    { url = REPO_BASE .. "apps/filemanager.lua", path = "/os/apps/filemanager.lua" },
    { url = REPO_BASE .. "apps/sysinfo.lua",     path = "/os/apps/sysinfo.lua" },
    { url = REPO_BASE .. "apps/calc.lua",        path = "/os/apps/calc.lua" },
    { url = REPO_BASE .. "apps/netshare.lua",    path = "/os/apps/netshare.lua" },
    { url = REPO_BASE .. "apps/notes.lua",       path = "/os/apps/notes.lua" },
    { url = REPO_BASE .. "apps/snake.lua",       path = "/os/apps/snake.lua" },
    { url = REPO_BASE .. "apps/minesweeper.lua", path = "/os/apps/minesweeper.lua" },
}

local W, H = term.getSize()

local installerText = {
    en = {
        title = "MoldOS Setup",
        welcome = "Welcome to the MoldOS installation wizard.",
        welcome2 = "You will now be asked a few setup questions.",
        click_begin = "Click anywhere to begin...",
        select_ui_lang = "Select Interface Language",
        select_country = "Select Country",
        select_timezone = "Time Zone",
        create_profile = "Create Profile",
        enter_username = "Enter username:",
        set_password = "Set a password (leave empty for none):",
        field_empty = "This field cannot be empty!",
        review = "Review your settings",
        ui_language = "Interface language:",
        country = "Country:",
        timezone = "Time zone:",
        username = "Username:",
        password = "Password:",
        none = "(none)",
        install = "Install",
        cancel = "Cancel",
        cancelled = "Installation cancelled.",
        installing = "Installing MoldOS",
        preparing = "Preparing system...",
        saving = "Saving settings...",
        creating_account = "Creating user account...",
        downloading = "Downloading files from GitHub...",
        finishing = "Finishing installation...",
        complete = "Installation Complete",
        success = "MoldOS was installed successfully!",
        rebooting = "The computer will now reboot.",
        error_title = "Installation Error",
        failed_files = "Failed to download files:",
        check_http = "Check that HTTP is enabled on the server",
        check_repo = "and that REPO_BASE in installer.lua is correct.",
    },
    ru = {
        title = "Установка MoldOS",
        welcome = "Добро пожаловать в мастер установки MoldOS.",
        welcome2 = "Сейчас потребуется задать несколько настроек.",
        click_begin = "Нажмите в любом месте, чтобы начать...",
        select_ui_lang = "Выберите язык интерфейса",
        select_country = "Выбор страны",
        select_timezone = "Часовой пояс",
        create_profile = "Создание профиля",
        enter_username = "Введите имя пользователя:",
        set_password = "Придумайте пароль (можно оставить пустым):",
        field_empty = "Поле не может быть пустым!",
        review = "Проверьте настройки",
        ui_language = "Язык интерфейса:",
        country = "Страна:",
        timezone = "Часовой пояс:",
        username = "Пользователь:",
        password = "Пароль:",
        none = "(не задан)",
        install = "Установить",
        cancel = "Отмена",
        cancelled = "Установка отменена.",
        installing = "Установка MoldOS",
        preparing = "Подготовка системы...",
        saving = "Сохранение настроек...",
        creating_account = "Создание учётной записи...",
        downloading = "Скачивание файлов с GitHub...",
        finishing = "Завершение установки...",
        complete = "Установка завершена",
        success = "MoldOS успешно установлена!",
        rebooting = "Компьютер сейчас перезагрузится.",
        error_title = "Ошибка установки",
        failed_files = "Не удалось скачать файлы:",
        check_http = "Проверьте, что HTTP включён на сервере",
        check_repo = "и что REPO_BASE в installer.lua указан верно.",
    },
}

local uiLang = "en"
local function t(key)
    return installerText[uiLang][key] or installerText.en[key] or key
end

local function clear()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1, 1)
end

local function center(y, text)
    local x = math.floor((W - #text) / 2) + 1
    term.setCursorPos(x, y)
    term.write(text)
end

local function header(title)
    clear()
    term.setCursorPos(1, 1)
    term.write(string.rep("=", W))
    center(2, title)
    term.setCursorPos(1, 3)
    term.write(string.rep("=", W))
    term.setCursorPos(1, 5)
end

local function waitClick(msg)
    local _, h = term.getSize()
    term.setCursorPos(1, h)
    term.write(msg)
    os.pullEvent("mouse_click")
end

local function selectMenu(title, options)
    while true do
        header(title)
        local buttonY = {}
        for i, opt in ipairs(options) do
            local y = 5 + i
            buttonY[i] = y
            term.setCursorPos(4, y)
            term.setTextColor(colors.white)
            term.write("[ " .. opt .. " ]")
        end
        term.setCursorPos(1, H)
        term.write("Click an option to select")

        local _, _, cx, cy = os.pullEvent("mouse_click")
        for i, y in ipairs(buttonY) do
            if cy == y then
                return i, options[i]
            end
        end
    end
end

local function textInput(title, prompt, hideChar, allowEmpty)
    while true do
        header(title)
        term.write(prompt)
        term.setCursorPos(1, 7)
        term.write("> ")
        local value = read(hideChar)
        if value ~= "" or allowEmpty then
            return value
        end
        term.setCursorPos(1, 9)
        term.setTextColor(colors.red)
        term.write(t("field_empty"))
        term.setTextColor(colors.white)
        sleep(1)
    end
end

local function progressStep(label, y, duration)
    term.setCursorPos(4, y)
    term.write(label)
    local barWidth = W - 10
    local barX = 4
    local barY = y + 1
    term.setCursorPos(barX, barY)
    term.write("[" .. string.rep(" ", barWidth - 2) .. "]")
    local steps = barWidth - 2
    for i = 1, steps do
        term.setCursorPos(barX + i, barY)
        term.write("=")
        sleep(duration / steps)
    end
end

-- ============================================
--  STEP 1: Language
-- ============================================

clear()
center(4, "MoldOS")
term.setCursorPos(4, 7)
term.write("[ English ]")
term.setCursorPos(4, 9)
term.write("[ Русский ]")
term.setCursorPos(1, H)
term.write("Select interface language / Выберите язык интерфейса")

while true do
    local _, _, cx, cy = os.pullEvent("mouse_click")
    if cy == 7 then
        uiLang = "en"
        break
    elseif cy == 9 then
        uiLang = "ru"
        break
    end
end

-- ============================================
--  STEP 2: Welcome
-- ============================================

header(t("title"))
term.write(t("welcome"))
term.setCursorPos(1, 7)
term.write(t("welcome2"))
waitClick(t("click_begin"))

-- ============================================
--  STEP 3: Country
-- ============================================

local _, country = selectMenu(t("select_country"), {
    "Moldova",
    "Russia",
    "Ukraine",
    "Belarus",
    "Other",
})

-- ============================================
--  STEP 4: Time zone
-- ============================================

local _, timezone = selectMenu(t("select_timezone"), {
    "UTC+2 (Chisinau)",
    "UTC+3 (Moscow)",
    "UTC+2 (Kyiv)",
    "UTC+0",
    "Other",
})

-- ============================================
--  STEP 5: User profile
-- ============================================

local username = textInput(t("create_profile"), t("enter_username"), nil, false)
local password = textInput(t("create_profile"), t("set_password"), "*", true)

-- ============================================
--  STEP 6: Confirmation
-- ============================================

header(t("review"))
term.write(t("ui_language") .. " " .. (uiLang == "ru" and "Русский" or "English"))
term.setCursorPos(1, 7); term.write(t("country") .. " " .. country)
term.setCursorPos(1, 8); term.write(t("timezone") .. " " .. timezone)
term.setCursorPos(1, 9); term.write(t("username") .. " " .. username)
term.setCursorPos(1, 10); term.write(t("password") .. " " .. (password == "" and t("none") or string.rep("*", #password)))
term.setCursorPos(1, 12)
term.write("[ " .. t("install") .. " ]        [ " .. t("cancel") .. " ]")

local proceed = false
while true do
    local _, _, cx, cy = os.pullEvent("mouse_click")
    if cy == 12 then
        if cx >= 1 and cx <= (4 + #t("install")) then
            proceed = true
            break
        elseif cx >= 20 and cx <= (24 + #t("cancel")) then
            proceed = false
            break
        end
    end
end

if not proceed then
    clear()
    print(t("cancelled"))
    return
end

-- ============================================
--  STEP 7: Installation
-- ============================================

header(t("installing"))

progressStep(t("preparing"), 5, 0.6)

if not fs.exists("/os") then fs.makeDir("/os") end
if not fs.exists("/os/apps") then fs.makeDir("/os/apps") end
if not fs.exists("/os/lib") then fs.makeDir("/os/lib") end
if not fs.exists("/os/data") then fs.makeDir("/os/data") end

progressStep(t("saving"), 8, 0.6)

local config = {
    country = country,
    timezone = timezone,
    osName = "MoldOS",
    osVersion = "1.3",
}
local cfgFile = fs.open("/os/data/config.lua", "w")
cfgFile.write(textutils.serialize(config))
cfgFile.close()

local langFile = fs.open("/os/data/language.lua", "w")
langFile.write(textutils.serialize(uiLang))
langFile.close()

progressStep(t("creating_account"), 14, 0.8)

local users = {}
users[username] = { password = password }
local usersFile = fs.open("/os/data/users.lua", "w")
usersFile.write(textutils.serialize(users))
usersFile.close()

header(t("installing"))
term.setCursorPos(4, 5)
term.write(t("downloading"))

local downloadY = 7
local failedFiles = {}

for i, item in ipairs(FILES_TO_DOWNLOAD) do
    term.setCursorPos(4, downloadY + i - 1)
    term.write(fs.getName(item.path) .. "...")

    local response = http.get(item.url)
    if response then
        local content = response.readAll()
        response.close()

        local dir = fs.getDir(item.path)
        if dir ~= "" and not fs.exists(dir) then
            fs.makeDir(dir)
        end

        local f = fs.open(item.path, "w")
        f.write(content)
        f.close()

        term.setCursorPos(W - 6, downloadY + i - 1)
        term.setTextColor(colors.lime)
        term.write("OK")
        term.setTextColor(colors.white)
    else
        term.setCursorPos(W - 10, downloadY + i - 1)
        term.setTextColor(colors.red)
        term.write("FAIL")
        term.setTextColor(colors.white)
        table.insert(failedFiles, item.path)
    end
end

sleep(0.5)

if not fs.exists("/startup.lua") then
    local su = fs.open("/startup.lua", "w")
    su.write('shell.run("/os/startup.lua")\n')
    su.close()
end

if #failedFiles > 0 then
    header(t("error_title"))
    term.write(t("failed_files"))
    for i, f in ipairs(failedFiles) do
        term.setCursorPos(4, 6 + i)
        term.write(f)
    end
    term.setCursorPos(1, 6 + #failedFiles + 2)
    term.write(t("check_http"))
    term.setCursorPos(1, 6 + #failedFiles + 3)
    term.write(t("check_repo"))
    waitClick(t("click_begin"))
    return
end

progressStep(t("finishing"), 20, 0.6)

-- ============================================
--  STEP 8: Done
-- ============================================

header(t("complete"))
center(6, t("success"))
center(8, t("rebooting"))
sleep(2)
os.reboot()