-- ============================================
--  MoldOS - /os/startup.lua
--  Запускается автоматически при включении компьютера
--  (через корневой /startup.lua, который зовёт этот файл)
-- ============================================

local W, H = term.getSize()
local DATA_DIR = "/os/data"
local APPS_DIR = "/os/apps"
local osName, osVersion = "MoldOS", "1.0"

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

-- ---------- загрузка конфигурации и пользователей ----------

local function loadTable(path)
    if not fs.exists(path) then return nil end
    local f = fs.open(path, "r")
    local content = f.readAll()
    f.close()
    local ok, data = pcall(textutils.unserialize, content)
    if ok then return data end
    return nil
end

local config = loadTable(DATA_DIR .. "/config.lua") or {}
local users = loadTable(DATA_DIR .. "/users.lua") or {}

-- ============================================
--  ЭКРАН ЗАПУСКА СИСТЕМЫ
-- ============================================

local function bootScreen()
    clear()
    center(math.floor(H / 2) - 1, osName .. " v" .. osVersion)
    center(math.floor(H / 2) + 1, "Запуск системы...")

    local barWidth = math.min(W - 4, 30)
    local barX = math.floor((W - barWidth) / 2) + 1
    local barY = math.floor(H / 2) + 3
    term.setCursorPos(barX, barY)
    term.write("[" .. string.rep(" ", barWidth - 2) .. "]")
    for i = 1, barWidth - 2 do
        term.setCursorPos(barX + i, barY)
        term.write("=")
        sleep(0.03)
    end
    sleep(0.3)
end

-- ============================================
--  ЭКРАН ВХОДА
-- ============================================

local function loginScreen()
    -- если пользователей ещё нет, пропускаем вход
    local anyUser = next(users)
    if not anyUser then
        return "guest"
    end

    while true do
        clear()
        center(4, osName)
        center(6, "Вход в систему")
        term.setCursorPos(1, 3)
        term.write(string.rep("-", W))

        term.setCursorPos(4, 8)
        term.write("Логин: ")
        local inputUser = read()

        local userData = users[inputUser]
        if not userData then
            term.setCursorPos(4, 11)
            term.setTextColor(colors.red)
            term.write("Пользователь не найден.")
            term.setTextColor(colors.white)
            sleep(1.2)
        else
            term.setCursorPos(4, 9)
            term.write("Пароль: ")
            local inputPass = read("*")

            if userData.password == "" or userData.password == inputPass then
                return inputUser
            else
                term.setCursorPos(4, 11)
                term.setTextColor(colors.red)
                term.write("Неверный пароль.")
                term.setTextColor(colors.white)
                sleep(1.2)
            end
        end
    end
end

-- ============================================
--  КОНСОЛЬ КОМАНД
-- ============================================

local currentUser = nil

local commands = {}

commands["help"] = function()
    print("Доступные команды:")
    print("  help            - список команд")
    print("  open <прогр>    - запустить программу")
    print("  list            - список программ")
    print("  ls              - список файлов текущей папки")
    print("  clear           - очистить экран")
    print("  whoami          - показать текущего пользователя")
    print("  about           - информация о системе")
    print("  reboot          - перезагрузка")
    print("  shutdown        - выключение")
    print("  exit            - выйти в обычный shell CraftOS")
end

commands["list"] = function()
    if not fs.exists(APPS_DIR) then
        print("Папка приложений не найдена.")
        return
    end
    local files = fs.list(APPS_DIR)
    if #files == 0 then
        print("Приложений не установлено.")
        return
    end
    print("Установленные приложения:")
    for _, f in ipairs(files) do
        local name = f:gsub("%.lua$", "")
        print("  " .. name)
    end
end

commands["open"] = function(args)
    local progName = args[1]
    if not progName then
        print("Использование: open <название программы>")
        return
    end
    local path = fs.combine(APPS_DIR, progName .. ".lua")
    if not fs.exists(path) then
        print("Программа '" .. progName .. "' не найдена.")
        print("Используй 'list' чтобы увидеть доступные программы.")
        return
    end
    local ok, err = pcall(function() shell.run(path) end)
    if not ok then
        printError("Ошибка запуска: " .. tostring(err))
    end
end

commands["ls"] = function()
    local files = fs.list(shell.dir())
    for _, f in ipairs(files) do
        print("  " .. f)
    end
end

commands["clear"] = function()
    clear()
end

commands["whoami"] = function()
    print(currentUser)
end

commands["about"] = function()
    print(osName .. " v" .. osVersion)
    print("Язык: " .. tostring(config.language))
    print("Страна: " .. tostring(config.country))
    print("Часовой пояс: " .. tostring(config.timezone))
    print(_HOST)
end

commands["reboot"] = function()
    os.reboot()
end

commands["shutdown"] = function()
    os.shutdown()
end

commands["exit"] = function()
    print("Выход в обычный CraftOS shell. Введи 'reboot' чтобы вернуться в " .. osName .. ".")
    shell.run("shell")
end

local function splitArgs(line)
    local parts = {}
    for word in line:gmatch("%S+") do
        table.insert(parts, word)
    end
    return parts
end

local function consoleLoop()
    clear()
    print(osName .. " v" .. osVersion .. " - консоль команд")
    print("Добро пожаловать, " .. currentUser .. "! Введи 'help' для списка команд.")
    print("")

    while true do
        term.setTextColor(colors.lime)
        write(currentUser .. "@" .. osName:lower() .. "> ")
        term.setTextColor(colors.white)

        local line = read()
        local parts = splitArgs(line)
        local cmdName = parts[1]

        if cmdName then
            table.remove(parts, 1)
            local cmdFn = commands[cmdName]
            if cmdFn then
                local ok, err = pcall(cmdFn, parts)
                if not ok then
                    printError("Ошибка: " .. tostring(err))
                end
            else
                print("Неизвестная команда: " .. cmdName)
                print("Введи 'help' для списка команд.")
            end
        end
    end
end

-- ============================================
--  ЗАПУСК
-- ============================================

if not fs.exists(APPS_DIR) then fs.makeDir(APPS_DIR) end
if not fs.exists(DATA_DIR) then fs.makeDir(DATA_DIR) end

bootScreen()
currentUser = loginScreen()
consoleLoop()
