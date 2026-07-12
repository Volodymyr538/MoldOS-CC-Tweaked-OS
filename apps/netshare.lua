-- MoldOS App: netshare
-- Send and receive files between computers over a wireless/wired modem

local W, H = term.getSize()
local PROTOCOL = "moldos_netshare"

local function clear()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1, 1)
end

local modem = peripheral.find("modem")
if not modem then
    clear()
    print("No modem attached to this computer.")
    print("")
    print("Click anywhere to exit...")
    os.pullEvent("mouse_click")
    return
end

if not rednet.isOpen(peripheral.getName(modem)) then
    rednet.open(peripheral.getName(modem))
end

local function scanComputers()
    clear()
    print("Scanning for computers...")
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
    print("Enter the full path of the file to send:")
    write("> ")
    local path = read()
    if not path or path == "" or not fs.exists(path) or fs.isDir(path) then
        print("")
        print("File not found.")
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
    print("Sent '" .. packet.name .. "' to computer " .. targetId .. ".")
    print("")
    print("Click anywhere to continue...")
    os.pullEvent("mouse_click")
end

local function sendMenu()
    local computers = scanComputers()
    local ids = {}
    for id in pairs(computers) do table.insert(ids, id) end
    table.sort(ids)

    if #ids == 0 then
        clear()
        print("No other computers found on the network.")
        print("")
        print("Click anywhere to go back...")
        os.pullEvent("mouse_click")
        return
    end

    clear()
    print("=== Computers Found ===")
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
    term.write("Click a computer to send a file to it")

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
            print("Received file from computer " .. senderId .. ":")
            print("  " .. packet.name)
            print("Saved to: " .. savePath)
            print("")
            print("Click anywhere to continue...")
            os.pullEvent("mouse_click")
        end
    end
end

local function mainMenu()
    while true do
        clear()
        print("=== MoldOS Netshare ===")
        print("Your computer ID: " .. os.getComputerID())
        print("")
        term.setCursorPos(4, 5)
        term.write("[ Send a File ]")
        term.setCursorPos(4, 7)
        term.write("[ Quit ]")

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