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
--  APP LIST (click to launch)
-- ============================================

local currentUser = nil

-- built-in system actions shown alongside apps
local systemActions = {
    { label = "About System",  action = function()
        clear()
        print(osName .. " v" .. osVersion)
        print("Language: " .. tostring(config.language))
        print("Country: " .. tostring(config.country))
        print("Time zone: " .. tostring(config.timezone))
        print(_HOST)
        print("")
        print("Click anywhere to go back...")
        os.pullEvent("mouse_click")
    end },
    { label = "Reboot",   action = function() os.reboot() end },
    { label = "Shutdown", action = function() os.shutdown() end },
}

local function getAppList()
    local apps = {}
    if fs.exists(APPS_DIR) then
        local files = fs.list(APPS_DIR)
        table.sort(files)
        for _, f in ipairs(files) do
            table.insert(apps, {
                label = f:gsub("%.lua$", ""),
                path = fs.combine(APPS_DIR, f),
            })
        end
    end
    return apps
end

local function drawMenu(apps)
    clear()
    term.setCursorPos(1, 1)
    term.write(string.rep("=", W))
    center(2, osName .. " - Welcome, " .. currentUser)
    term.setCursorPos(1, 3)
    term.write(string.rep("=", W))

    local y = 5
    local rows = {}

    term.setCursorPos(4, y)
    term.setTextColor(colors.yellow)
    term.write("-- Apps --")
    term.setTextColor(colors.white)
    y = y + 1

    if #apps == 0 then
        term.setCursorPos(4, y)
        term.setTextColor(colors.lightGray)
        term.write("(no apps installed)")
        term.setTextColor(colors.white)
        y = y + 1
    else
        for _, app in ipairs(apps) do
            term.setCursorPos(4, y)
            term.write("[ " .. app.label .. " ]")
            table.insert(rows, { y = y, action = function() shell.run(app.path) end })
            y = y + 1
        end
    end

    y = y + 1
    term.setCursorPos(4, y)
    term.setTextColor(colors.yellow)
    term.write("-- System --")
    term.setTextColor(colors.white)
    y = y + 1

    for _, item in ipairs(systemActions) do
        term.setCursorPos(4, y)
        term.write("[ " .. item.label .. " ]")
        table.insert(rows, { y = y, action = item.action })
        y = y + 1
    end

    return rows
end

local function menuLoop()
    while true do
        local apps = getAppList()
        local rows = drawMenu(apps)

        local _, _, cx, cy = os.pullEvent("mouse_click")
        for _, row in ipairs(rows) do
            if cy == row.y then
                local ok, err = pcall(row.action)
                if not ok then
                    clear()
                    print("Error running program:")
                    print(err)
                    print("")
                    print("Click anywhere to go back...")
                    os.pullEvent("mouse_click")
                end
                break
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
menuLoop()