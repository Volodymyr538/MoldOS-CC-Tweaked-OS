-- MoldOS Library: avcore
-- Shared antivirus scanning logic, used by both apps/antivirus.lua (the
-- user-facing scanner app) and installer.lua (which scans freshly
-- downloaded files before finishing setup). Loaded via dofile() and
-- used purely as a library -- this file has no UI of its own.

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

-- Scans a single file's contents and returns a list of matched rules,
-- sorted from most to least severe. Returns nil if the path doesn't
-- point at a readable file.
local function scanFile(path)
    if not fs.exists(path) or fs.isDir(path) then
        return nil
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

-- Convenience check: true if the file has no "critical" or "high"
-- findings (i.e. safe enough to run without an explicit warning).
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

-- Recursively collects every .lua file under a directory into `out`.
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

return {
    RULES = RULES,
    SEVERITY_ORDER = SEVERITY_ORDER,
    SEVERITY_COLOR = SEVERITY_COLOR,
    scanFile = scanFile,
    isFileSafe = isFileSafe,
    collectLuaFiles = collectLuaFiles,
}
