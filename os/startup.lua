-- ============================================
--  MoldOS - /os/startup.lua
--  Runs automatically when the computer starts
--  (via the root /startup.lua, which calls this file)
-- ============================================

local W, H = term.getSize()
local DATA_DIR = "/os/data"
local APPS_DIR = "/os/apps"
local osName, osVersion = "MoldOS", "1.0"

-- ---------- UI helpers ----------

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

-- ---------- load config and users ----------

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
--  BOOT SCREEN
-- ============================================

local function bootScreen()
    clear()
    center(math.floor(H / 2) - 1, osName .. " v" .. osVersion)
    center(math.floor(H / 2) + 1, "Starting system...")

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
--  LOGIN SCREEN
-- ============================================

local function loginScreen()
    local anyUser = next(users)
    if not anyUser then
        return "guest"
    end

    while true do
        clear()
        center(4, osName)
        center(6, "Login")
        term.setCursorPos(1, 3)
        term.write(string.rep("-", W))

        term.setCursorPos(4, 8)
        term.write("Username: ")
        local inputUser = read()

        local userData = users[inputUser]
        if not userData then
            term.setCursorPos(4, 11)
            term.setTextColor(colors.red)
            term.write("User not found.")
            term.setTextColor(colors.white)
            sleep(1.2)
        else
            term.setCursorPos(4, 9)
            term.write("Password: ")
            local inputPass = read("*")

            if userData.password == "" or userData.password == inputPass then
                return inputUser
            else
                term.setCursorPos(4, 11)
                term.setTextColor(colors.red)
                term.write("Incorrect password.")
                term.setTextColor(colors.white)
                sleep(1.2)
            end
        end
    end
end

-- ============================================
--  COMMAND CONSOLE
-- ============================================

local currentUser = nil

local commands = {}

commands["help"] = function()
    print("Available commands:")
    print("  help            - list commands")
    print("  open <app>      - run a program")
    print("  list            - list installed programs")
    print("  ls              - list files in current folder")
    print("  clear           - clear the screen")
    print("  whoami          - show current user")
    print("  about           - system information")
    print("  reboot          - reboot")
    print("  shutdown        - shutdown")
    print("  exit            - exit to regular CraftOS shell")
end

commands["list"] = function()
    if not fs.exists(APPS_DIR) then
        print("Apps folder not found.")
        return
    end
    local files = fs.list(APPS_DIR)
    if #files == 0 then
        print("No apps installed.")
        return
    end
    print("Installed apps:")
    for _, f in ipairs(files) do
        local name = f:gsub("%.lua$", "")
        print("  " .. name)
    end
end

commands["open"] = function(args)
    local progName = args[1]
    if not progName then
        print("Usage: open <program name>")
        return
    end
    local path = fs.combine(APPS_DIR, progName .. ".lua")
    if not fs.exists(path) then
        print("Program '" .. progName .. "' not found.")
        print("Use 'list' to see available programs.")
        return
    end
    local ok, err = pcall(function() shell.run(path) end)
    if not ok then
        printError("Error running program: " .. tostring(err))
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
    print("Language: " .. tostring(config.language))
    print("Country: " .. tostring(config.country))
    print("Time zone: " .. tostring(config.timezone))
    print(_HOST)
end

commands["reboot"] = function()
    os.reboot()
end

commands["shutdown"] = function()
    os.shutdown()
end

commands["exit"] = function()
    print("Exiting to regular CraftOS shell. Type 'reboot' to return to " .. osName .. ".")
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
    print(osName .. " v" .. osVersion .. " - command console")
    print("Welcome, " .. currentUser .. "! Type 'help' for a list of commands.")
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
                    printError("Error: " .. tostring(err))
                end
            else
                print("Unknown command: " .. cmdName)
                print("Type 'help' for a list of commands.")
            end
        end
    end
end

-- ============================================
--  START
-- ============================================

if not fs.exists(APPS_DIR) then fs.makeDir(APPS_DIR) end
if not fs.exists(DATA_DIR) then fs.makeDir(DATA_DIR) end

bootScreen()
currentUser = loginScreen()
consoleLoop()