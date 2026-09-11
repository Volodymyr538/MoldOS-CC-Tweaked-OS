-- MoldOS App: antivirus
-- User-facing scanner UI. The actual scanning rules live in
-- /os/lib/avcore.lua, shared with installer.lua.

local W, H = term.getSize()
local av = dofile("/os/lib/avcore.lua")

local function clear()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1, 1)
end

local function showFileReport(path, findings)
    clear()
    term.write("=== Scan: " .. fs.getName(path) .. " ===")
    term.setCursorPos(1, 2)
    term.write(string.rep("-", W))

    local y = 3
    if #findings == 0 then
        term.setTextColor(colors.lime)
        term.setCursorPos(2, y)
        term.write("No suspicious patterns found.")
        term.setTextColor(colors.white)
    else
        for _, f in ipairs(findings) do
            if y > H - 2 then break end
            term.setCursorPos(2, y)
            term.setTextColor(av.SEVERITY_COLOR[f.severity])
            term.write("[" .. f.severity:upper() .. "] ")
            term.setTextColor(colors.white)
            term.write(f.desc)
            y = y + 1
        end
    end

    term.setCursorPos(1, H)
    term.write("Click anywhere to continue...")
    os.pullEvent("mouse_click")
end

local function scanSingleFile()
    clear()
    print("Enter full path of file to scan:")
    write("> ")
    local path = read()
    if not path or path == "" or not fs.exists(path) then
        clear()
        print("File not found.")
        sleep(1.2)
        return
    end
    if fs.isDir(path) then
        clear()
        print("That is a folder, not a file. Use 'Full System Scan' instead.")
        sleep(1.5)
        return
    end

    local findings = av.scanFile(path)
    showFileReport(path, findings)
end

local function fullSystemScan()
    clear()
    print("Scanning /os/apps and root for .lua files...")
    print("")

    local files = av.collectLuaFiles("/os/apps", {})
    for _, name in ipairs(fs.list("/")) do
        if name:match("%.lua$") and not fs.isDir(fs.combine("/", name)) then
            table.insert(files, fs.combine("/", name))
        end
    end

    local results = {}
    local flaggedCount = 0
    for _, path in ipairs(files) do
        write(fs.getName(path) .. "... ")
        local findings = av.scanFile(path)
        if findings and #findings > 0 then
            local worst = findings[1].severity
            print(worst:upper())
            flaggedCount = flaggedCount + 1
        else
            print("clean")
        end
        table.insert(results, { path = path, findings = findings })
    end

    print("")
    print(#files .. " file(s) scanned, " .. flaggedCount .. " flagged.")
    print("")
    print("Click anywhere to view details, or wait to return...")

    local timer = os.startTimer(4)
    local event = os.pullEvent()
    if event == "mouse_click" then
        for _, r in ipairs(results) do
            if r.findings and #r.findings > 0 then
                showFileReport(r.path, r.findings)
            end
        end
    end
end

local function mainMenu()
    while true do
        clear()
        term.write("=== MoldOS Antivirus ===")
        term.setCursorPos(1, 2)
        term.write(string.rep("-", W))
        term.setCursorPos(2, 4)
        term.write("Pattern-based scanner. Flags suspicious code")
        term.setCursorPos(2, 5)
        term.write("for you to review -- not a guarantee of safety.")

        term.setCursorPos(4, 8)
        term.write("[ Scan a File ]")
        term.setCursorPos(4, 10)
        term.write("[ Full System Scan ]")
        term.setCursorPos(4, 12)
        term.write("[ Quit ]")

        local _, _, cx, cy = os.pullEvent("mouse_click")
        if cy == 8 then
            scanSingleFile()
        elseif cy == 10 then
            fullSystemScan()
        elseif cy == 12 then
            break
        end
    end
    clear()
end

mainMenu()
