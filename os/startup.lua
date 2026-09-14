-- ============================================
--  MoldOS - /os/startup.lua
--  Runs automatically when the computer starts
-- ============================================

local W, H = term.getSize()
local DATA_DIR = "/os/data"
local APPS_DIR = "/os/apps"
local osName, osVersion = "MoldOS", "1.3"

local REPO_BASE = "https://raw.githubusercontent.com/Volodymyr538/OS/main/"
local SYSTEM_FILES = {
    { url = REPO_BASE .. "os/startup.lua", path = "/os/startup.lua" },
    { url = REPO_BASE .. "lib/avcore.lua", path = "/os/lib/avcore.lua" },
}
}
local APP_REGISTRY = {
    filemanager  = REPO_BASE .. "apps/filemanager.lua",
    sysinfo      = REPO_BASE .. "apps/sysinfo.lua",
    calc         = REPO_BASE .. "apps/calc.lua",
    netshare     = REPO_BASE .. "apps/netshare.lua",
    notes        = REPO_BASE .. "apps/notes.lua",
    snake        = REPO_BASE .. "apps/snake.lua",
    minesweeper  = REPO_BASE .. "apps/minesweeper.lua",
    antivirus    = REPO_BASE .. "apps/antivirus.lua",
}

-- ---------- monitor mirroring ----------

local monitor = peripheral.find("monitor")
if monitor then
    monitor.setTextScale(0.5)
end

local originalTerm = term.current()

local function mirror(fnName)
    return function(...)
        local args = { ... }
        local result = { originalTerm[fnName](table.unpack(args)) }
        if monitor then
            pcall(function() monitor[fnName](table.unpack(args)) end)
        end
        return table.unpack(result)
    end
end

if monitor then
    local mirrored = {}
    for _, name in ipairs({
        "write", "clear", "clearLine", "setCursorPos", "setCursorBlink",
        "setTextColour", "setTextColor", "setBackgroundColour", "setBackgroundColor",
        "scroll", "getCursorPos", "getSize", "isColour", "isColor",
        "getTextColour", "getTextColor", "getBackgroundColour", "getBackgroundColor",
        "blit",
    }) do
        mirrored[name] = mirror(name)
    end
    term.redirect(mirrored)
end

-- ---------- load/save helpers ----------

local function loadTable(path)
    if not fs.exists(path) then return nil end
    local f = fs.open(path, "r")
    local content = f.readAll()
    f.close()
    local ok, data = pcall(textutils.unserialize, content)
    if ok then return data end
    return nil
end

local function saveTable(path, tbl)
    local f = fs.open(path, "w")
    f.write(textutils.serialize(tbl))
    f.close()
end

local config = loadTable(DATA_DIR .. "/config.lua") or {}
local users = loadTable(DATA_DIR .. "/users.lua") or {}
local notifications = loadTable(DATA_DIR .. "/notifications.lua") or {}

-- ============================================
--  THEMES
-- ============================================

local THEMES_FILE = DATA_DIR .. "/theme.lua"

local themes = {
    default = {
        name = "Default",
        bg = colors.black, fg = colors.white,
        accent = colors.yellow, danger = colors.red,
        palette = nil,
    },
    ocean = {
        name = "Ocean",
        bg = colors.blue, fg = colors.white,
        accent = colors.cyan, danger = colors.red,
        palette = { [colors.blue] = 0x0a1f3d, [colors.black] = 0x0a1f3d },
    },
    forest = {
        name = "Forest",
        bg = colors.black, fg = colors.lime,
        accent = colors.green, danger = colors.red,
        palette = { [colors.black] = 0x0c1a0c },
    },
    sunset = {
        name = "Sunset",
        bg = colors.black, fg = colors.orange,
        accent = colors.red, danger = colors.magenta,
        palette = { [colors.black] = 0x2a0f1a },
    },
}

local function getCurrentThemeName()
    local saved = loadTable(THEMES_FILE)
    if saved and themes[saved] then return saved end
    return "default"
end

local currentThemeName = getCurrentThemeName()
local theme = themes[currentThemeName]

local function applyPalette()
    if theme.palette and term.setPaletteColor then
        for colorConst, hex in pairs(theme.palette) do
            pcall(term.setPaletteColor, colorConst, hex)
        end
    end
end
applyPalette()

local function setTheme(name)
    if themes[name] then
        currentThemeName = name
        theme = themes[name]
        saveTable(THEMES_FILE, name)
        applyPalette()
    end
end

-- ---------- UI helpers (theme-aware) ----------

local function clear()
    term.setBackgroundColor(theme.bg)
    term.setTextColor(theme.fg)
    term.clear()
    term.setCursorPos(1, 1)
end

local function center(y, text)
    local x = math.floor((W - #text) / 2) + 1
    term.setCursorPos(x, y)
    term.write(text)
end

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
--  PIN PAD (3x3 mouse keypad)
-- ============================================

local function drawPinPad(originX, originY)
    local layout = {
        { "1", "2", "3" },
        { "4", "5", "6" },
        { "7", "8", "9" },
        { "",  "0", "<" },
    }
    local hitboxes = {}
    for row, line in ipairs(layout) do
        local y = originY + (row - 1) * 2
        for col, digit in ipairs(line) do
            local x = originX + (col - 1) * 6
            if digit ~= "" then
                term.setCursorPos(x, y)
                term.write("[ " .. digit .. " ]")
                table.insert(hitboxes, { x1 = x, x2 = x + 4, y = y, digit = digit })
            end
        end
    end
    return hitboxes
end

local function pinInput(title, originY, maxLen)
    maxLen = maxLen or 8
    local entered = ""
    while true do
        clear()
        center(3, title)

        local dots = string.rep("*", #entered) .. string.rep("-", math.max(0, 4 - #entered))
        center(originY - 2, dots)

        local hitboxes = drawPinPad(math.floor((W - 17) / 2) + 1, originY)

        local submitY = originY + 8
        local submitLabel = "[ Enter ]"
        local cancelLabel = "[ Cancel ]"
        local submitX = math.floor((W - (#submitLabel + #cancelLabel + 2)) / 2) + 1
        local cancelX = submitX + #submitLabel + 2
        term.setCursorPos(submitX, submitY)
        term.write(submitLabel)
        term.setCursorPos(cancelX, submitY)
        term.write(cancelLabel)

        local _, _, cx, cy = os.pullEvent("mouse_click")

        if cy == submitY then
            if cx >= submitX and cx <= submitX + #submitLabel then
                return entered
            elseif cx >= cancelX and cx <= cancelX + #cancelLabel then
                return nil
            end
        else
            for _, hb in ipairs(hitboxes) do
                if cy == hb.y and cx >= hb.x1 and cx <= hb.x2 then
                    if hb.digit == "<" then
                        entered = entered:sub(1, -2)
                    elseif #entered < maxLen then
                        entered = entered .. hb.digit
                    end
                    break
                end
            end
        end
    end
end

-- ============================================
--  LOGIN SCREEN (click account; PIN pad if a PIN is set, else instant login)
-- ============================================

local function loginScreen()
    local userList = {}
    for name in pairs(users) do
        table.insert(userList, name)
    end
    table.sort(userList)

    if #userList == 0 then
        return "guest"
    end

    while true do
        clear()
        center(3, osName)
        center(5, "Select your account")
        term.setCursorPos(1, 4)
        term.write(string.rep("-", W))

        local rows = {}
        local y = 7
        for _, name in ipairs(userList) do
            term.setCursorPos(4, y)
            term.write("[ " .. name .. " ]")
            table.insert(rows, { y = y, name = name })
            y = y + 1
        end

        local _, _, cx, cy = os.pullEvent("mouse_click")
        local chosen = nil
        for _, row in ipairs(rows) do
            if cy == row.y then
                chosen = row.name
                break
            end
        end

        if chosen then
            local userData = users[chosen]

            if not userData.pin or userData.pin == "" then
                return chosen
            end

            while true do
                local entered = pinInput("PIN for " .. chosen, 8, 8)
                if entered == nil then
                    break
                elseif entered == userData.pin then
                    return chosen
                else
                    clear()
                    center(math.floor(H / 2), "Incorrect PIN.")
                    sleep(1)
                end
            end
        end
    end
end

-- ============================================
--  GREETING & CLOCK
-- ============================================

local function getGreeting()
    local hour = os.time("ingame")
    if hour >= 5 and hour < 12 then
        return "Good morning"
    elseif hour >= 12 and hour < 17 then
        return "Good afternoon"
    elseif hour >= 17 and hour < 21 then
        return "Good evening"
    else
        return "Good night"
    end
end

local function getClockString()
    local hour = os.time("ingame")
    local h = math.floor(hour)
    local m = math.floor((hour - h) * 60)
    return string.format("%02d:%02d", h, m)
end

local function showGreeting(user)
    clear()
    center(math.floor(H / 2), getGreeting() .. ", " .. user .. "!")
    sleep(1.2)
end

-- ============================================
--  NOTIFICATIONS
-- ============================================

local function addNotification(text)
    table.insert(notifications, { text = text, time = os.time("ingame") })
    while #notifications > 20 do
        table.remove(notifications, 1)
    end
    saveTable(DATA_DIR .. "/notifications.lua", notifications)
end

local function hasUnread()
    return #notifications > 0
end

local function viewNotifications()
    clear()
    print("=== Notifications ===")
    print("")
    if #notifications == 0 then
        print("(no notifications)")
    else
        for i = #notifications, 1, -1 do
            print("- " .. notifications[i].text)
        end
    end
    print("")
    term.setCursorPos(1, H)
    term.write("[ Clear All ]          [ Back ]")

    while true do
        local _, _, cx, cy = os.pullEvent("mouse_click")
        if cy == H then
            if cx >= 1 and cx <= 12 then
                notifications = {}
                saveTable(DATA_DIR .. "/notifications.lua", notifications)
                return
            elseif cx >= 23 and cx <= 29 then
                return
            end
        end
    end
end

-- ============================================
--  UPDATE / INSTALL  (with re-run protection)
-- ============================================

local operationInProgress = false

local function downloadFile(url, path)
    local response = http.get(url)
    if not response then
        return false, "failed to fetch " .. url
    end
    local content = response.readAll()
    response.close()

    local dir = fs.getDir(path)
    if dir ~= "" and not fs.exists(dir) then
        fs.makeDir(dir)
    end

    local f = fs.open(path, "w")
    f.write(content)
    f.close()
    return true
end

local function runUpdate()
    if operationInProgress then
        clear()
        print("An update or install is already running.")
        sleep(1.2)
        return
    end
    operationInProgress = true

    clear()
    print("Checking for updates...")
    print("")

    local anyFailed = false
    for _, item in ipairs(SYSTEM_FILES) do
        write(fs.getName(item.path) .. "... ")
        local ok, err = downloadFile(item.url, item.path)
        if ok then
            print("OK")
        else
            print("FAILED")
            anyFailed = true
        end
    end

    print("")
    if anyFailed then
        print("Some files failed to update. Check your connection.")
        operationInProgress = false
    else
        print("Update complete! Rebooting...")
        sleep(1.5)
        os.reboot()
    end
    print("")
    print("Click anywhere to go back...")
    os.pullEvent("mouse_click")
    operationInProgress = false
end

local function findAppInRegistry(name)
    if not name then return nil, nil end
    local trimmed = name:match("^%s*(.-)%s*$"):lower()
    for key, url in pairs(APP_REGISTRY) do
        if key:lower() == trimmed then
            return key, url
        end
    end
    return nil, nil
end

local function runInstall()
    if operationInProgress then
        clear()
        print("An update or install is already running.")
        sleep(1.2)
        return
    end
    operationInProgress = true

    clear()
    print("=== Install App ===")
    print("")
    print("Available apps:")
    for name in pairs(APP_REGISTRY) do
        print("  " .. name)
    end
    print("")
    write("Enter app name to install: ")
    local appNameInput = read()

    local appName, url = findAppInRegistry(appNameInput)
    if not url then
        print("")
        print("Unknown app: " .. tostring(appNameInput))
        print("")
        print("Click anywhere to go back...")
        os.pullEvent("mouse_click")
        operationInProgress = false
        return
    end

    local path = fs.combine(APPS_DIR, appName .. ".lua")
    if fs.exists(path) then
        print("")
        print("'" .. appName .. "' is already installed.")
        term.setCursorPos(1, H)
        term.write("[ Reinstall ]          [ Cancel ]")
        local proceed = false
        while true do
            local _, _, cx, cy = os.pullEvent("mouse_click")
            if cy == H then
                if cx >= 1 and cx <= 12 then
                    proceed = true
                    break
                elseif cx >= 23 and cx <= 31 then
                    break
                end
            end
        end
        if not proceed then
            operationInProgress = false
            return
        end
    end

    clear()
    print("Installing '" .. appName .. "'...")
    local ok, err = downloadFile(url, path)
    if ok then
        print("Installed successfully!")
        addNotification("App installed: " .. appName)
    else
        print("Failed: " .. tostring(err))
    end
    print("")
    print("Click anywhere to go back...")
    os.pullEvent("mouse_click")
    operationInProgress = false
end

-- ============================================
--  SETTINGS
-- ============================================

local currentUser = nil

local function isValidPin(pin)
    return pin ~= nil and pin:match("^%d+$") ~= nil and #pin >= 4 and #pin <= 8
end

local function changePin()
    local userData = users[currentUser]

    if userData.pin and userData.pin ~= "" then
        local current = pinInput("Enter current PIN", 8, 8)
        if current == nil then return end
        if current ~= userData.pin then
            clear()
            center(math.floor(H / 2), "Incorrect PIN.")
            sleep(1.2)
            return
        end
    end

    local newPin = pinInput("Set new PIN (4-8 digits)", 8, 8)
    if newPin == nil then return end

    if newPin == "" then
        userData.pin = ""
        saveTable(DATA_DIR .. "/users.lua", users)
        clear()
        center(math.floor(H / 2), "PIN removed.")
        sleep(1.2)
        return
    end

    if not isValidPin(newPin) then
        clear()
        center(math.floor(H / 2), "PIN must be 4-8 digits.")
        sleep(1.5)
        return
    end

    userData.pin = newPin
    saveTable(DATA_DIR .. "/users.lua", users)
    clear()
    center(math.floor(H / 2), "PIN updated successfully!")
    sleep(1.2)
end

local function renameUser()
    clear()
    print("=== Change Username ===")
    print("")
    write("New username: ")
    local newName = read()

    if not newName or newName:match("^%s*$") then
        return
    end
    if users[newName] then
        print("")
        print("That username is already taken.")
        sleep(1.5)
        return
    end

    users[newName] = users[currentUser]
    users[currentUser] = nil
    currentUser = newName
    saveTable(DATA_DIR .. "/users.lua", users)

    print("")
    print("Username changed to '" .. newName .. "'!")
    sleep(1.2)
end

local function createUser()
    clear()
    print("=== New User ===")
    print("")
    write("Username: ")
    local newName = read()

    if not newName or newName:match("^%s*$") then
        return
    end
    if users[newName] then
        print("")
        print("That username already exists.")
        sleep(1.5)
        return
    end

    users[newName] = { pin = "" }
    saveTable(DATA_DIR .. "/users.lua", users)

    print("")
    print("User '" .. newName .. "' created! (no PIN set)")
    sleep(1.2)
end

local function countUsers()
    local n = 0
    for _ in pairs(users) do n = n + 1 end
    return n
end

local function deleteUser()
    clear()
    print("=== Delete a User ===")
    print("")
    for name in pairs(users) do
        print("  " .. name)
    end
    print("")
    write("Username to delete: ")
    local targetName = read()

    if targetName == currentUser then
        print("")
        print("You cannot delete the account you are logged into.")
        sleep(1.5)
        return
    end
    if not users[targetName] then
        print("")
        print("User not found.")
        sleep(1.5)
        return
    end
    if countUsers() <= 1 then
        print("")
        print("You cannot delete the last remaining user.")
        sleep(1.5)
        return
    end

    users[targetName] = nil
    saveTable(DATA_DIR .. "/users.lua", users)
    print("")
    print("User '" .. targetName .. "' deleted.")
    sleep(1.2)
end

local function chooseTheme()
    local names = {}
    for key in pairs(themes) do table.insert(names, key) end
    table.sort(names)

    while true do
        clear()
        term.write("=== Choose Theme ===")
        local rows = {}
        local y = 3
        for _, key in ipairs(names) do
            term.setCursorPos(4, y)
            if key == currentThemeName then
                term.setTextColor(theme.accent)
                term.write("> " .. themes[key].name .. " (current)")
                term.setTextColor(theme.fg)
            else
                term.write("  " .. themes[key].name)
            end
            table.insert(rows, { y = y, key = key })
            y = y + 1
        end
        term.setCursorPos(4, y + 1)
        term.write("[ Back ]")

        local _, _, cx, cy = os.pullEvent("mouse_click")
        if cy == y + 1 then
            return
        end
        for _, row in ipairs(rows) do
            if cy == row.y then
                setTheme(row.key)
            end
        end
    end
end

local function runSettings()
    local options = {
        { label = "Change PIN",      action = changePin },
        { label = "Change Username", action = renameUser },
        { label = "Create New User", action = createUser },
        { label = "Delete a User",   action = deleteUser },
        { label = "Choose Theme",    action = chooseTheme },
        { label = "Back",            action = function() return "back" end },
    }

    while true do
        clear()
        term.write("=== Settings ===")
        local y = 3
        local rows = {}
        for _, opt in ipairs(options) do
            term.setCursorPos(4, y)
            term.write("[ " .. opt.label .. " ]")
            table.insert(rows, { y = y, action = opt.action })
            y = y + 1
        end

        local _, _, cx, cy = os.pullEvent("mouse_click")
        for _, row in ipairs(rows) do
            if cy == row.y then
                local result = row.action()
                if result == "back" then
                    return
                end
                break
            end
        end
    end
end

local function logOut()
    currentUser = loginScreen()
    showGreeting(currentUser)
end

-- ============================================
--  RENDET (network chat)
-- ============================================

local function rednetChat()
    clear()
    local modem = peripheral.find("modem")
    if not modem then
        print("No modem attached to this computer.")
        print("")
        print("Click anywhere to go back...")
        os.pullEvent("mouse_click")
        return
    end

    if not rednet.isOpen(peripheral.getName(modem)) then
        rednet.open(peripheral.getName(modem))
    end

    print("=== MoldOS Chat ===")
    print("Your computer ID: " .. os.getComputerID())
    print("")
    print("Enter target computer ID (or 'all' to broadcast):")
    write("> ")
    local target = read()

    print("Type your message. Type 'exit' to quit chat.")
    print("")

    local function listenLoop()
        while true do
            local senderId, message = rednet.receive("moldos_chat")
            print("[" .. senderId .. "] " .. tostring(message))
            addNotification("New message from #" .. senderId)
        end
    end

    local function sendLoop()
        while true do
            write("me> ")
            local msg = read()
            if msg == "exit" then
                return
            end
            if target == "all" then
                rednet.broadcast(msg, "moldos_chat")
            else
                local targetId = tonumber(target)
                if targetId then
                    rednet.send(targetId, msg, "moldos_chat")
                else
                    print("Invalid target ID.")
                end
            end
        end
    end

    parallel.waitForAny(listenLoop, sendLoop)
    rednet.close(peripheral.getName(modem))
end

-- ============================================
--  THIRD-PARTY APP API
-- ============================================

_G.MoldAPI = {
    version = osVersion,
    notify = function(text)
        addNotification(tostring(text))
    end,
    getTheme = function()
        return { name = theme.name, bg = theme.bg, fg = theme.fg, accent = theme.accent }
    end,
    getCurrentUser = function()
        return currentUser
    end,
}

local function readCertificate(path)
    local f = fs.open(path, "r")
    local firstLines = {}
    for i = 1, 10 do
        local line = f.readLine()
        if not line then break end
        table.insert(firstLines, line)
    end
    f.close()

    local text = table.concat(firstLines, "\n")
    local name = text:match("MOLDCERT_NAME%s*=%s*\"(.-)\"")
    local version = text:match("MOLDCERT_VERSION%s*=%s*\"(.-)\"")
    local author = text:match("MOLDCERT_AUTHOR%s*=%s*\"(.-)\"")
    local key = text:match("MOLDCERT_KEY%s*=%s*\"(.-)\"")

    if name then
        return { name = name, version = version or "?", author = author or "?", key = key or "?" }
    end
    return nil
end

-- ============================================
--  APP LIST (click to launch) - TABBED
-- ============================================

local systemActions = {
    { label = "About System",  action = function()
        clear()
        print(osName .. " v" .. osVersion)
        print("Country: " .. tostring(config.country))
        print("Time zone: " .. tostring(config.timezone))
        print("Theme: " .. theme.name)
        print(_HOST)
        print("")
        print("Click anywhere to go back...")
        os.pullEvent("mouse_click")
    end },
    { label = "Notifications", action = viewNotifications },
    { label = "Network Chat", action = rednetChat },
    { label = "Settings", action = runSettings },
    { label = "Check for Updates", action = runUpdate },
    { label = "Install App", action = runInstall },
    { label = "Log Out", action = logOut },
    { label = "Reboot",   action = function() os.reboot() end },
    { label = "Shutdown", action = function() os.shutdown() end },
}

local function getAppList()
    local apps = {}
    if fs.exists(APPS_DIR) then
        local files = fs.list(APPS_DIR)
        table.sort(files)
        for _, f in ipairs(files) do
            local path = fs.combine(APPS_DIR, f)
            if f:match("%.lua$") and not fs.isDir(path) then
                local cert = readCertificate(path)
                table.insert(apps, {
                    label = cert and cert.name or f:gsub("%.lua$", ""),
                    path = path,
                    cert = cert,
                })
            end
        end
    end
    return apps
end

local currentTab = "apps"

local function drawMenu(apps)
    clear()
    term.setCursorPos(1, 1)
    term.write(string.rep("=", W))
    center(2, osName .. " - " .. getGreeting() .. ", " .. currentUser)

    if hasUnread() then
        term.setCursorPos(2, 1)
        term.setTextColor(theme.danger)
        term.write("*")
        term.setTextColor(theme.fg)
    end

    local clockStr = getClockString()
    term.setCursorPos(W - #clockStr, 1)
    term.setTextColor(theme.accent)
    term.write(clockStr)
    term.setTextColor(theme.fg)

    term.setCursorPos(1, 3)
    term.write(string.rep("=", W))

    local tabY = 4
    term.setCursorPos(2, tabY)
    if currentTab == "apps" then
        term.setTextColor(theme.accent)
        term.write("[ Apps ]")
        term.setTextColor(colors.lightGray)
        term.write("  System")
    else
        term.setTextColor(colors.lightGray)
        term.write("  Apps  ")
        term.setTextColor(theme.accent)
        term.write("[ System ]")
    end
    term.setTextColor(theme.fg)
    term.setCursorPos(1, tabY + 1)
    term.write(string.rep("-", W))

    local y = tabY + 3
    local rows = {}
    local maxY = H - 1

    if currentTab == "apps" then
        if #apps == 0 then
            term.setCursorPos(4, y)
            term.setTextColor(colors.lightGray)
            term.write("(no apps installed)")
            term.setTextColor(theme.fg)
        else
            for _, app in ipairs(apps) do
                if y <= maxY then
                    term.setCursorPos(4, y)
                    term.write("[ " .. app.label .. " ]")
                    table.insert(rows, { y = y, action = function() shell.run(app.path) end })
                    y = y + 1
                end
            end
        end
    else
        for _, item in ipairs(systemActions) do
            if y <= maxY then
                term.setCursorPos(4, y)
                term.write("[ " .. item.label .. " ]")
                table.insert(rows, { y = y, action = item.action })
                y = y + 1
            end
        end
    end

    return rows, tabY
end

local function menuLoop()
    while true do
        local apps = getAppList()
        local rows, tabY = drawMenu(apps)

        local timerId = os.startTimer(1)
        local clicked = false
        local cx, cy

        while not clicked do
            local event, p1, p2, p3 = os.pullEvent()
            if event == "mouse_click" then
                cx, cy = p2, p3
                clicked = true
            elseif event == "timer" and p1 == timerId then
                local clockStr = getClockString()
                term.setCursorPos(W - #clockStr, 1)
                term.setTextColor(theme.accent)
                term.write(clockStr)
                term.setTextColor(theme.fg)
                timerId = os.startTimer(1)
            end
        end

        os.cancelTimer(timerId)

        if cy == tabY then
            if cx >= 1 and cx <= 9 then
                currentTab = "apps"
            elseif cx >= 10 and cx <= 20 then
                currentTab = "system"
            end
        else
            for _, row in ipairs(rows) do
                if cy == row.y then
                    local ok, err = pcall(row.action)
                    if not ok then
                        clear()
                        term.setTextColor(theme.danger)
                        print("Error running program:")
                        term.setTextColor(theme.fg)
                        print(tostring(err))
                        print("")
                        print("Click anywhere to go back...")
                        os.pullEvent("mouse_click")
                    end
                    break
                end
            end
        end
    end
end

-- ============================================
--  START
-- ============================================

if not fs.exists(APPS_DIR) then fs.makeDir(APPS_DIR) end
if not fs.exists(DATA_DIR) then fs.makeDir(DATA_DIR) end

local function main()
    bootScreen()
    currentUser = loginScreen()
    showGreeting(currentUser)
    menuLoop()
end

local ok, err = pcall(main)
if not ok then
    clear()
    term.setTextColor(colors.red)
    print("MoldOS encountered a fatal error:")
    term.setTextColor(colors.white)
    print(tostring(err))
    print("")
    print("Type 'reboot' to restart, or 'shell' for a raw CraftOS prompt.")
end
