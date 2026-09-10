-- MoldOS App: antivirus
-- Scans Lua files for suspicious patterns (not a real virus scanner,
-- pattern-based heuristics only). Can scan a single file (used by the
-- installer before running new apps) or the whole computer.

local W, H = term.getSize()

local function clear()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1, 1)
end

local RULES = {
    { pattern = "fs%.delete%s*%(%s*[\"']/%s*[\"']",       severity = "critical", desc = "Attempts to delete the root filesystem" },
    { pattern = "fs%.delete%s*%(%s*[\"']/os",              severity = "critical", desc = "Attempts to delete core system files" },
    { pattern = "disk%.format",                            severity = "high",     desc = "Formats a disk (destroys its contents)" },
    { pattern = "rednet%.broadcast.-http",                 severity = "high",     desc = "Broadcasts data possibly combined with a web request" },
    { pattern = "http%.post",                              severity = "medium",   desc = "Sends data to an external website" },
    { pattern = "http%.request",                           severity = "medium",   desc = "Makes a raw network request" },
    { pattern = "shell%.run%s*%(.-shell%.run",             severity = "medium",   desc = "Nested shell.run calls (possible fork-bomb pattern)" },
    { pattern = "while%s+true%s+do%s*shell%.run",          severity = "high",     desc = "Infinite loop repeatedly launching programs (fork-bomb risk)" },
    { pattern = "fs%.list%s*%(%s*[\"']/[\"']%s*%).-http",  severity = "high",     desc = "Reads the whole filesystem and appears to send it over the network" },
    { pattern = "os%.getComputerLabel.-http",              severity = "low",      desc = "Reads computer identity info near a network call" },
    { pattern = "%[%[.-%]%]",                               severity = "low",      desc = "Contains a long raw string block (could hide obfuscated code)" },
    { pattern = "loadstring%s*%(",                          severity = "medium",   desc = "Dynamically loads and executes code from a string" },
    { pattern = "load%s*%(.-http",                          severity = "critical", desc = "Downloads and executes code from the internet at runtime" },
}

local SEVERITY_ORDER = { critical = 4, high = 3, medium = 2, low = 1 }
local SEVERITY_COLOR = {
    critical = colors.red, high = colors.orange,
    medium = colors.yellow, low = colors.lightGray,
}

local function scanFile(path)
    if not fs.exists(path) or fs.isDir(path) then
        return nil, "not a file"
    end

    local f = fs.open(path, "r")
    local content = f.readAll()
    f.close()

    local findings = {}
    for _, rule in ipairs(RULES) do
        if content:find(rule.pattern) then
            table.insert(findings, rule)
        end
    end

    table.sort(findings, function(a, b)
        return SEVERITY_ORDER[a.severity] > SEVERITY_ORDER[b.severity]
    end)

    return findings
end

local function isFileSafe(path)
    local findings = scanFile(path)
    if not findings then return true end
    for _, f in ipairs(findings) do
        if f.severity == "critical" or f.severity == "high" then
            return false
        end
    end
    return true
end

if ... == "lib" then
    return { scanFile = scanFile, isFileSafe = isFileSafe }
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
            term.setTextColor(SEVERITY_COLOR[f.severity])
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

    local findings = scanFile(path)
    showFileReport(path, findings)
end

local function collectLuaFiles(dir, out)
    out = out or {}
    if not fs.exists(dir) then return out end
    for _, name in ipairs(fs.list(dir)) do
        local path = fs.combine(dir, name)
        if fs.isDir(path) then
            collectLuaFiles(path, out)
        elseif name:match("%.lua$") then
            table.insert(out, path)
        end
    end
    return out
end

local function fullSystemScan()
    clear()
    print("Scanning /os/apps and root for .lua files...")
    print("")

    local files = {}
    collectLuaFiles("/os/apps", files)
    for _, name in ipairs(fs.list("/")) do
        if name:match("%.lua$") and not fs.isDir(fs.combine("/", name)) then
            table.insert(files, fs.combine("/", name))
        end
    end

    local results = {}
    local flaggedCount = 0
    for _, path in ipairs(files) do
        write(fs.getName(path) .. "... ")
        local findings = scanFile(path)
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
    local event, p1 = os.pullEvent()
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
