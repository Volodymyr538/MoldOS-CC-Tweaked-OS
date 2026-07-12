-- MoldOS App: filemanager
-- Mouse-controlled file manager with copy/paste and rename

local W, H = term.getSize()
local currentPath = "/"
local clipboard = nil

local function clear()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1, 1)
end

local function getEntries(path)
    local list = fs.list(path)
    table.sort(list)
    local entries = {}
    if path ~= "/" then
        table.insert(entries, "..")
    end
    for _, name in ipairs(list) do
        table.insert(entries, name)
    end
    return entries
end

local function draw(entries, selectedIdx)
    clear()
    term.write("=== File Manager: " .. currentPath .. " ===")
    term.setCursorPos(1, 2)
    term.write(string.rep("-", W))

    local toolbarY = H
    term.setCursorPos(1, toolbarY)
    term.write("[New][Copy][Paste][Rename][Del][Quit]")

    if clipboard then
        term.setCursorPos(1, H - 1)
        term.setTextColor(colors.lightGray)
        term.write("Clipboard: " .. clipboard.name)
        term.setTextColor(colors.white)
    end

    local startY = 3
    local maxVisible = H - (clipboard and 5 or 4)
    local rows = {}

    for i = 1, math.min(#entries, maxVisible) do
        local name = entries[i]
        local entryPath = fs.combine(currentPath, name)
        local isDir = name == ".." or (fs.exists(entryPath) and fs.isDir(entryPath))
        local y = startY + i - 1
        term.setCursorPos(3, y)

        if i == selectedIdx then
            term.setTextColor(colors.yellow)
            term.write("> ")
        else
            term.setTextColor(colors.white)
            term.write("  ")
        end

        if isDir then
            term.write("[" .. name .. "]")
        else
            term.write(name)
        end
        term.setTextColor(colors.white)

        table.insert(rows, { y = y, name = name, isDir = isDir })
    end

    return rows, toolbarY
end

local function confirmDelete(name)
    clear()
    term.write("Delete '" .. name .. "'?")
    term.setCursorPos(1, 3)
    term.write("[ Yes ]      [ No ]")
    while true do
        local _, _, cx, cy = os.pullEvent("mouse_click")
        if cy == 3 then
            if cx >= 1 and cx <= 8 then return true end
            if cx >= 14 and cx <= 20 then return false end
        end
    end
end

local function newFolder()
    clear()
    term.write("New folder name:")
    term.setCursorPos(1, 3)
    write("> ")
    local name = read()
    if name and name ~= "" then
        local ok, err = pcall(fs.makeDir, fs.combine(currentPath, name))
        if not ok then
            printError("Failed to create folder: " .. tostring(err))
            sleep(1.5)
        end
    end
end

local function renameEntry(name)
    clear()
    term.write("Rename '" .. name .. "' to:")
    term.setCursorPos(1, 3)
    write("> ")
    local newName = read()
    if newName and newName ~= "" and newName ~= name then
        local oldPath = fs.combine(currentPath, name)
        local newPath = fs.combine(currentPath, newName)
        if fs.exists(newPath) then
            printError("A file with that name already exists.")
            sleep(1.5)
        else
            local ok, err = pcall(fs.move, oldPath, newPath)
            if not ok then
                printError("Failed to rename: " .. tostring(err))
                sleep(1.5)
            end
        end
    end
end

local function pasteHere()
    if not clipboard then return end
    local destPath = fs.combine(currentPath, clipboard.name)
    if fs.exists(destPath) then
        clear()
        term.write("'" .. clipboard.name .. "' already exists here.")
        term.setCursorPos(1, 3)
        term.write("Overwrite? [ Yes ]  [ No ]")
        while true do
            local _, _, cx, cy = os.pullEvent("mouse_click")
            if cy == 3 then
                if cx >= 1 and cx <= 8 then
                    fs.delete(destPath)
                    break
                elseif cx >= 12 and cx <= 18 then
                    return
                end
            end
        end
    end
    local ok, err = pcall(fs.copy, clipboard.path, destPath)
    if not ok then
        printError("Failed to paste: " .. tostring(err))
        sleep(1.5)
    end
end

local function main()
    local selected = nil

    while true do
        local entries = getEntries(currentPath)
        local rows, toolbarY = draw(entries, selected)

        local _, _, cx, cy = os.pullEvent("mouse_click")

        if cy == toolbarY then
            if cx >= 1 and cx <= 5 then
                newFolder()
            elseif cx >= 6 and cx <= 11 then
                if selected and entries[selected] and entries[selected] ~= ".." then
                    local name = entries[selected]
                    clipboard = { path = fs.combine(currentPath, name), name = name }
                end
            elseif cx >= 12 and cx <= 18 then
                pasteHere()
            elseif cx >= 19 and cx <= 26 then
                if selected and entries[selected] and entries[selected] ~= ".." then
                    renameEntry(entries[selected])
                    selected = nil
                end
            elseif cx >= 27 and cx <= 31 then
                if selected and entries[selected] and entries[selected] ~= ".." then
                    local name = entries[selected]
                    if confirmDelete(name) then
                        local entryPath = fs.combine(currentPath, name)
                        local ok, err = pcall(fs.delete, entryPath)
                        if not ok then
                            printError("Failed to delete: " .. tostring(err))
                            sleep(1.5)
                        end
                        selected = nil
                    end
                end
            elseif cx >= 32 and cx <= 37 then
                break
            end
        else
            for i, row in ipairs(rows) do
                if cy == row.y then
                    if selected == i then
                        if row.name == ".." then
                            currentPath = fs.getDir(currentPath)
                            if currentPath == "" then currentPath = "/" end
                            selected = nil
                        elseif row.isDir then
                            currentPath = fs.combine(currentPath, row.name)
                            selected = nil
                        else
                            shell.run("edit", fs.combine(currentPath, row.name))
                        end
                    else
                        selected = i
                    end
                    break
                end
            end
        end
    end

    clear()
end

main()