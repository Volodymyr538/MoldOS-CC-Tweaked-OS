-- ============================================
--  MoldOS Installer
--  Запускается через: wget run <ссылка на installer.lua с GitHub>
-- ============================================

local REPO_BASE = "https://raw.githubusercontent.com/Volodymyr538/OS/main/"

local FILES_TO_DOWNLOAD = {
    { url = REPO_BASE .. "os/startup.lua",           path = "/os/startup.lua" },
    { url = REPO_BASE .. "os/apps/filemanager.lua",  path = "/os/apps/filemanager.lua" },
    { url = REPO_BASE .. "os/apps/sysinfo.lua",      path = "/os/apps/sysinfo.lua" },
    { url = REPO_BASE .. "os/apps/calc.lua",         path = "/os/apps/calc.lua" },
}

local W, H = term.getSize()

-- ---------- утилиты интерфейса ----------

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

local function waitKey(msg)
    local _, h = term.getSize()
    term.setCursorPos(1, h)
    term.write(msg or "Нажми любую клавишу...")
    os.pullEvent("key")
end

-- меню выбора из списка (стрелки + Enter)
local function selectMenu(title, options)
    local selected = 1
    while true do
        header(title)
        for i, opt in ipairs(options) do
            term.setCursorPos(4, 5 + i)
            if i == selected then
                term.setTextColor(colors.white)
                term.write("> " .. opt)
            else
                term.setTextColor(colors.lightGray)
                term.write("  " .. opt)
            end
        end
        term.setTextColor(colors.white)
        term.setCursorPos(1, H)
        term.write("Стрелки - выбор, Enter - подтвердить")

        local _, key = os.pullEvent("key")
        if key == keys.up then
            selected = selected - 1
            if selected < 1 then selected = #options end
        elseif key == keys.down then
            selected = selected + 1
            if selected > #options then selected = 1 end
        elseif key == keys.enter then
            return selected, options[selected]
        end
    end
end

-- ввод текста с заголовком
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
        term.write("Поле не может быть пустым!")
        term.setTextColor(colors.white)
        sleep(1)
    end
end

-- ---------- прогресс-бар установки ----------

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
--  ШАГ 1: Приветствие
-- ============================================

header("Установка MoldOS")
term.write("Добро пожаловать в мастер установки MoldOS.")
term.setCursorPos(1, 7)
term.write("Сейчас потребуется задать несколько настроек.")
waitKey("Нажми любую клавишу, чтобы начать...")

-- ============================================
--  ШАГ 2: Язык
-- ============================================

local _, language = selectMenu("Выбор языка", {
    "Русский",
    "English",
})

-- ============================================
--  ШАГ 3: Страна
-- ============================================

local _, country = selectMenu("Выбор страны", {
    "Россия",
    "Молдова",
    "Украина",
    "Беларусь",
    "Другая",
})

-- ============================================
--  ШАГ 4: Часовой пояс
-- ============================================

local _, timezone = selectMenu("Часовой пояс", {
    "UTC+2 (Кишинёв)",
    "UTC+3 (Москва)",
    "UTC+2 (Киев)",
    "UTC+0",
    "Другой",
})

-- ============================================
--  ШАГ 5: Профиль пользователя
-- ============================================

local username = textInput("Создание профиля", "Введите имя пользователя:", nil, false)
local password = textInput("Создание профиля", "Придумайте пароль (можно оставить пустым):", "*", true)

-- ============================================
--  ШАГ 6: Подтверждение
-- ============================================

header("Проверьте данные")
term.write("Язык: " .. language)
term.setCursorPos(1, 7); term.write("Страна: " .. country)
term.setCursorPos(1, 8); term.write("Часовой пояс: " .. timezone)
term.setCursorPos(1, 9); term.write("Пользователь: " .. username)
term.setCursorPos(1, 10); term.write("Пароль: " .. (password == "" and "(не задан)" or string.rep("*", #password)))
term.setCursorPos(1, 12)
term.write("Enter - начать установку, любая другая - отмена")

local _, key = os.pullEvent("key")
if key ~= keys.enter then
    clear()
    print("Установка отменена.")
    return
end

-- ============================================
--  ШАГ 7: Установка
-- ============================================

header("Установка MoldOS")

progressStep("Подготовка системы...", 5, 0.6)

if not fs.exists("/os") then fs.makeDir("/os") end
if not fs.exists("/os/apps") then fs.makeDir("/os/apps") end
if not fs.exists("/os/data") then fs.makeDir("/os/data") end

progressStep("Сохранение настроек...", 8, 0.6)

local config = {
    language = language,
    country = country,
    timezone = timezone,
    osName = "MoldOS",
    osVersion = "1.0",
}
local cfgFile = fs.open("/os/data/config.lua", "w")
cfgFile.write(textutils.serialize(config))
cfgFile.close()

progressStep("Создание учётной записи...", 14, 0.8)

local users = {}
users[username] = { password = password }
local usersFile = fs.open("/os/data/users.lua", "w")
usersFile.write(textutils.serialize(users))
usersFile.close()

header("Установка MoldOS")
term.setCursorPos(4, 5)
term.write("Скачивание файлов с GitHub...")

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
        term.write("ОШИБКА")
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
    header("Ошибка установки")
    term.write("Не удалось скачать файлы:")
    for i, f in ipairs(failedFiles) do
        term.setCursorPos(4, 6 + i)
        term.write(f)
    end
    term.setCursorPos(1, 6 + #failedFiles + 2)
    term.write("Проверь, что HTTP включён в конфиге сервера")
    term.setCursorPos(1, 6 + #failedFiles + 3)
    term.write("и что ссылка REPO_BASE в installer.lua верна.")
    waitKey()
    return
end

progressStep("Завершение установки...", 20, 0.6)

-- ============================================
--  ШАГ 8: Готово
-- ============================================

header("Установка завершена")
center(6, "MoldOS успешно установлена!")
center(8, "Компьютер сейчас перезагрузится.")
sleep(2)
os.reboot()
