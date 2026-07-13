-- ============================================
--  MoldOS - /os/startup.lua
--  Runs automatically when the computer starts
-- ============================================

local W, H = term.getSize()
local DATA_DIR = "/os/data"
local APPS_DIR = "/os/apps"
local osName, osVersion = "MoldOS", "1.3"

local lang = dofile("/os/lib/lang.lua")
local t = lang.t

-- GitHub repo used for update / install
local REPO_BASE = "https://raw.githubusercontent.com/Volodymyr538/OS/main/"
local SYSTEM_FILES = {
    { url = REPO_BASE .. "os/startup.lua", path = "/os/startup.lua" },
    { url = REPO_BASE .. "lib/lang.lua", path = "/os/lib/lang.lua" },
}
local APP_REGISTRY = {
    filemanager  = REPO_BASE .. "apps/filemanager.lua",
    sysinfo      = REPO_BASE .. "apps/sysinfo.lua",
    calc         = REPO_BASE .. "apps/calc.lua",
    netshare     = REPO_BASE .. "apps/netshare.lua",
    notes        = REPO_BASE .. "apps/notes.lua",
    snake        = REPO_BASE .. "apps/snake.lua",
    minesweeper  = REPO_BASE .. "apps/minesweeper.lua",
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

local function saveTable(path, tbl)
    local f = fs.open(path, "w")
    f.write(textutils.serialize(tbl))
    f.close()
end

local config = loadTable(DATA_DIR .. "/config.lua") or {}
local users = loadTable(DATA_DIR .. "/users.lua") or {}

-- ============================================
--  BOOT SCREEN
-- ============================================

local function bootScreen()
    clear()
    center(math.floor(H / 2) - 1, osName .. " v" .. osVersion)
    center(math.floor(H / 2) + 1, t("starting_system"))

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
--  LOGIN SCREEN (click your account, then type password)
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
        center(5, t("select_account"))
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
            while true do
                clear()
                center(3, osName)
                center(5, t("welcome_back") .. " " .. chosen)
                term.setCursorPos(1, 4)
                term.write(string.rep("-", W))

                term.setCursorPos(4, 8)
                term.write(t("password_colon") .. " ")
                local inputPass = read("*")

                if userData.password == "" or userData.password == inputPass then
                    return chosen
                else
                    term.setCursorPos(4, 10)
                    term.setTextColor(colors.red)
                    term.write(t("incorrect_password"))
                    term.setTextColor(colors.white)
                    sleep(1.2)
                    break
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
        return t("good_morning")
    elseif hour >= 12 and hour < 17 then
        return t("good_afternoon")
    elseif hour >= 17 and hour < 21 then
        return t("good_evening")
    else
        return t("good_night")
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
--  UPDATE / INSTALL
-- ============================================

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
    clear()
    print(t("checking_updates"))
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
        print(t("update_some_failed"))
    else
        print(t("update_complete"))
        sleep(1.5)
        os.reboot()
    end
    print("")
    print(t("click_go_back"))
    os.pullEvent("mouse_click")
end

local function runInstall()
    clear()
    print("=== " .. t("install_app") .. " ===")
    print("")
    print(t("available_apps"))
    for name in pairs(APP_REGISTRY) do
        print("  " .. name)
    end
    print("")
    write(t("enter_app_name") .. " ")
    local appName = read()

    local url = APP_REGISTRY[appName]
    if not url then
        print("")
        print(t("unknown_app") .. " " .. tostring(appName))
        print("")
        print(t("click_go_back"))
        os.pullEvent("mouse_click")
        return
    end

    print("")
    print(t("installing_dots") .. " '" .. appName .. "'...")
    local path = fs.combine(APPS_DIR, appName .. ".lua")
    local ok, err = downloadFile(url, path)
    if ok then
        print(t("installed_success"))
    else
        print(t("install_failed") .. " " .. tostring(err))
    end
    print("")
    print(t("click_go_back"))
    os.pullEvent("mouse_click")
end

-- ============================================
--  SETTINGS
-- ============================================

local currentUser = nil

local function changePassword()
    clear()
    print("=== " .. t("change_password") .. " ===")
    print("")
    write(t("current_password") .. " ")
    local current = read("*")

    local userData = users[currentUser]
    if userData.password ~= "" and userData.password ~= current then
        print("")
        print(t("incorrect_current"))
        sleep(1.5)
        return
    end

    write(t("new_password") .. " ")
    local newPass = read("*")
    userData.password = newPass
    saveTable(DATA_DIR .. "/users.lua", users)

    print("")
    print(t("password_changed"))
    sleep(1.2)
end

local function renameUser()
    clear()
    print("=== " .. t("change_username") .. " ===")
    print("")
    write(t("new_username") .. " ")
    local newName = read()

    if not newName or newName == "" then
        return
    end
    if users[newName] then
        print("")
        print(t("username_taken"))
        sleep(1.5)
        return
    end

    users[newName] = users[currentUser]
    users[currentUser] = nil
    currentUser = newName
    saveTable(DATA_DIR .. "/users.lua", users)

    print("")
    print(t("username_changed") .. " '" .. newName .. "'!")
    sleep(1.2)
end

local function createUser()
    clear()
    print("=== " .. t("create_new_user") .. " ===")
    print("")
    write(t("username_label2") .. " ")
    local newName = read()

    if not newName or newName == "" then
        return
    end
    if users[newName] then
        print("")
        print(t("user_exists"))
        sleep(1.5)
        return
    end

    write(t("new_password") .. " ")
    local newPass = read("*")

    users[newName] = { password = newPass }
    saveTable(DATA_DIR .. "/users.lua", users)

    print("")
    print(t("user_created") .. " ('" .. newName .. "')")
    sleep(1.2)
end

local function deleteUser()
    clear()
    print("=== " .. t("delete_user") .. " ===")
    print("")
    for name in pairs(users) do
        print("  " .. name)
    end
    print("")
    write(t("username_label2") .. " ")
    local targetName = read()

    if targetName == currentUser then
        print("")
        print(t("cannot_delete_self"))
        sleep(1.5)
        return
    end
    if not users[targetName] then
        print("")
        print(t("user_not_found"))
        sleep(1.5)
        return
    end

    users[targetName] = nil
    saveTable(DATA_DIR .. "/users.lua", users)
    print("")
    print("'" .. targetName .. "' " .. t("user_deleted"))
    sleep(1.2)
end

local function changeLanguage()
    clear()
    term.write(t("select_ui_language"))
    term.setCursorPos(4, 3)
    term.write("[ English ]")
    term.setCursorPos(4, 5)
    term.write("[ Русский ]")

    while true do
        local _, _, cx, cy = os.pullEvent("mouse_click")
        if cy == 3 then
            lang.setLanguage("en")
            return
        elseif cy == 5 then
            lang.setLanguage("ru")
            return
        end
    end
end

local function runSettings()
    local options = {
        { label = t("change_password"), action = changePassword },
        { label = t("change_username"), action = renameUser },
        { label = t("create_new_user"), action = createUser },
        { label = t("delete_user"),   action = deleteUser },
        { label = t("select_ui_language"), action = changeLanguage },
        { label = t("back"),            action = function() return "back" end },
    }

    while true do
        clear()
        term.write("=== " .. t("settings") .. " ===")
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
        print(t("no_modem"))
        print("")
        print(t("click_go_back"))
        os.pullEvent("mouse_click")
        return
    end

    if not rednet.isOpen(peripheral.getName(modem)) then
        rednet.open(peripheral.getName(modem))
    end

    print("=== " .. t("network_chat") .. " ===")
    print(t("your_computer_id") .. " " .. os.getComputerID())
    print("")
    print(t("enter_target_id"))
    write("> ")
    local target = read()

    print(t("type_message"))
    print("")

    local function listenLoop()
        while true do
            local senderId, message = rednet.receive("moldos_chat")
            print("[" .. senderId .. "] " .. tostring(message))
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
                    print(t("invalid_target"))
                end
            end
        end
    end

    parallel.waitForAny(listenLoop, sendLoop)
    rednet.close(peripheral.getName(modem))
end

-- ============================================
--  APP LIST (click to launch)
-- ============================================

local systemActions = {
    { label = t("about_system"),  action = function()
        clear()
        print(osName .. " v" .. osVersion)
        print(t("country_label") .. " " .. tostring(config.country))
        print(t("timezone_label") .. " " .. tostring(config.timezone))
        print(_HOST)
        print("")
        print(t("click_go_back"))
        os.pullEvent("mouse_click")
    end },
    { label = t("network_chat"), action = rednetChat },
    { label = t("settings"), action = runSettings },
    { label = t("check_updates"), action = runUpdate },
    { label = t("install_app"), action = runInstall },
    { label = t("log_out"), action = logOut },
    { label = t("reboot"),   action = function() os.reboot() end },
    { label = t("shutdown"), action = function() os.shutdown() end },
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
    center(2, osName .. " - " .. getGreeting() .. ", " .. currentUser)

    local clockStr = getClockString()
    term.setCursorPos(W - #clockStr, 1)
    term.setTextColor(colors.yellow)
    term.write(clockStr)
    term.setTextColor(colors.white)

    term.setCursorPos(1, 3)
    term.write(string.rep("=", W))

    local y = 5
    local rows = {}

    term.setCursorPos(4, y)
    term.setTextColor(colors.yellow)
    term.write(t("apps_section"))
    term.setTextColor(colors.white)
    y = y + 1

    if #apps == 0 then
        term.setCursorPos(4, y)
        term.setTextColor(colors.lightGray)
        term.write(t("no_apps"))
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
    term.write(t("system_section"))
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
                term.setTextColor(colors.yellow)
                term.write(clockStr)
                term.setTextColor(colors.white)
                timerId = os.startTimer(1)
            end
        end

        for _, row in ipairs(rows) do
            if cy == row.y then
                local ok, err = pcall(row.action)
                if not ok then
                    clear()
                    print(t("error_running"))
                    print(err)
                    print("")
                    print(t("click_go_back"))
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
showGreeting(currentUser)
menuLoop()