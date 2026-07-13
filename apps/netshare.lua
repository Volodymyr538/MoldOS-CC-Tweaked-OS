-- MoldOS App: netshare
-- Send and receive files between computers over a wireless/wired modem

local W, H = term.getSize()
local PROTOCOL = "moldos_netshare"

local lang = dofile("/os/lib/lang.lua")
local t = lang.t

local function clear()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1, 1)
end

local modem = peripheral.find("modem")
if not modem then
    clear()
    print(t("no_modem"))
    print("")
    print(t("click_exit"))
    os.pullEvent("mouse_click")
    return
end

if not rednet.isOpen(peripheral.getName(modem)) then
    rednet.open(peripheral.getName(modem))
end

local function scanComputers()
    clear()
    print(t("scanning"))
    rednet.broadcast("ping", PROTOCOL .. "_ping")

    local found = {}
    local timer = os.startTimer(2)
    while true do
        local event, p1, p2, p3 = os.pullEvent()
        if event == "rednet_message" then
            local senderId, message, protocol = p1, p2, p3
            if protocol == PROTOCOL .. "_pong" then
                found[senderId] = message
            end
        elseif event == "timer" and p1 == timer then
            break
        end
    end
    return found
end

local function pingResponder()
    while true do
        local senderId, message, protocol = rednet.receive(PROTOCOL .. "_ping")
        local label = os.getComputerLabel() or ("Computer " .. os.getComputerID())
        rednet.send(senderId, label, PROTOCOL .. "_pong")
    end
end

local function pickFile()
    clear()
    print(t("enter_file_path"))
    write("> ")
    local path = read()
    if not path or path == "" or not fs.exists(path) or fs.isDir(path) then
        print("")
        print(t("file_not_found"))
        sleep(1.5)
        return nil
    end
    return path
end

local function sendFile(targetId, path)
    local f = fs.open(path, "r")
    local content = f.readAll()
    f.close()

    local packet = {
        name = fs.getName(path),
        content = content,
    }
    rednet.send(targetId, packet, PROTOCOL .. "_file")

    clear()
    print(t("sent_to") .. " '" .. packet.name .. "' " .. t("to_computer") .. " " .. targetId .. ".")
    print("")
    print(t("click_continue"))
    os.pullEvent("mouse_click")
end

local function sendMenu()
    local computers = scanComputers()
    local ids = {}
    for id in pairs(computers) do table.insert(ids, id) end
    table.sort(ids)

    if #ids == 0 then
        clear()
        print(t("no_computers_found"))
        print("")
        print(t("click_exit"))
        os.pullEvent("mouse_click")
        return
    end

    clear()
    print("=== " .. t("computers_found") .. " ===")
    local rows = {}
    local y = 3
    for _, id in ipairs(ids) do
        local label = computers[id]
        term.setCursorPos(4, y)
        term.write("[ #" .. id .. " " .. tostring(label) .. " ]")
        table.insert(rows, { y = y, id = id })
        y = y + 1
    end
    term.setCursorPos(1, H)
    term.write(t("click_computer_send"))

    local _, _, cx, cy = os.pullEvent("mouse_click")
    local chosenId = nil
    for _, row in ipairs(rows) do
        if cy == row.y then
            chosenId = row.id
            break
        end
    end

    if chosenId then
        local path = pickFile()
        if path then
            sendFile(chosenId, path)
        end
    end
end

local function receiveLoop()
    while true do
        local senderId, packet, protocol = rednet.receive(PROTOCOL .. "_file")
        if type(packet) == "table" and packet.name and packet.content then
            local savePath = fs.combine("/", packet.name)
            local counter = 1
            while fs.exists(savePath) do
                savePath = fs.combine("/", counter .. "_" .. packet.name)
                counter = counter + 1
            end
            local f = fs.open(savePath, "w")
            f.write(packet.content)
            f.close()

            clear()
            print(t("received_from") .. " " .. senderId .. ":")
            print("  " .. packet.name)
            print(t("saved_to") .. " " .. savePath)
            print("")
            print(t("click_continue"))
            os.pullEvent("mouse_click")
        end
    end
end

local function mainMenu()
    while true do
        clear()
        print("=== " .. t("netshare_title") .. " ===")
        print(t("your_computer_id") .. " " .. os.getComputerID())
        print("")
        term.setCursorPos(4, 5)
        term.write("[ " .. t("send_file_btn") .. " ]")
        term.setCursorPos(4, 7)
        term.write("[ " .. t("quit") .. " ]")

        local _, _, cx, cy = os.pullEvent("mouse_click")
        if cy == 5 then
            sendMenu()
        elseif cy == 7 then
            break
        end
    end
end

parallel.waitForAny(pingResponder, receiveLoop, mainMenu)
rednet.close(peripheral.getName(modem))
clear()