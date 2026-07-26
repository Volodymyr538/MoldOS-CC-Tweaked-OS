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

local function showError(msg)
    clear()
    term.setTextColor(colors.red)
    term.write("Error:")
    term.setCursorPos(1, 2)
    term.write(msg)
    term.setTextColor(colors.white)
    term.setCursorPos(1, 4)
    term.write("Click anywhere to continue...")
    os.pullEvent("mouse_click")
end

local function confirmDelete(name)
    clear()
    term.write("Delete '" .. name .. "'?")
    term.setCursorPos(1, 3)
    local yesLabel = "[ Yes ]"
    local noLabel = "[ No ]"
    local noX = #yesLabel + 6
    term.write(yesLabel)
    term.setCursorPos(noX, 3)
    term.write(noLabel)
    while true do
        local _, _, cx, cy = os.pullEvent("mouse_click")
        if cy == 3 then
            if cx >= 1 and cx <= #yesLabel then return true end
            if cx >= noX and cx <= noX + #noLabel then return false end
        end
    end
end

local function newFolder()
    clear()
    term.write("New folder name:")
    term.setCursorPos(1, 3)
    write("> ")
    local name = read()

    -- FIX: reject empty/whitespace-only names and names containing
    -- path separators, which could otherwise create nested or invalid folders
    if not name or name:match("^%s*$") then
        return
    end
    if name:find("/") then
        showError("Folder name cannot contain '/'.")
        return
    end

    local ok, err = pcall(fs.makeDir, fs.combine(currentPath, name))
    if not ok then
        showError("Failed to create folder: " .. tostring(err))
    end
end

local function renameEntry(name)
    clear()
    term.write("Rename '" .. name .. "' to:")
    term.setCursorPos(1, 3)
    write("> ")
    local newName = read()

    if not newName or newName:match("^%s*$") or newName == name then
        return
    end
    if newName:find("/") then
        showError("Name cannot contain '/'.")
        return
    end

    local oldPath = fs.combine(currentPath, name)

    -- FIX: block renaming read-only/protected paths (e.g. root system files)
    if fs.isReadOnly(oldPath) then
        showError("This file or folder is read-only and cannot be renamed.")
        return
    end

    local newPath = fs.combine(currentPath, newName)
    if fs.exists(newPath) then
        showError("A file with that name already exists.")
        return
    end

    local ok, err = pcall(fs.move, oldPath, newPath)
    if not ok then
        showError("Failed to rename: " .. tostring(err))
    end
end

local function pasteHere()
    if not clipboard then return end

    -- FIX: guard against a stale clipboard pointing at a file that
    -- no longer exists (e.g. deleted after being copied)
    if not fs.exists(clipboard.path) then
        showError("The copied file no longer exists.")
        clipboard = nil
        return
    end

    local destPath = fs.combine(currentPath, clipboard.name)

    -- FIX: prevent copying a folder into itself or one of its own subfolders
    if fs.isDir(clipboard.path) and destPath:sub(1, #clipboard.path) == clipboard.path then
        showError("Cannot paste a folder into itself.")
        return
    end

    if fs.exists(destPath) then
        clear()
        term.write("'" .. clipboard.name .. "' already exists here.")
        term.setCursorPos(1, 3)
        local overwriteLabel = "Overwrite? "
        local yesLabel = "[ Yes ]"
        local noLabel = "[ No ]"
        local yesX = #overwriteLabel + 1
        local noX = yesX + #yesLabel + 2
        term.write(overwriteLabel)
        term.setCursorPos(yesX, 3)
        term.write(yesLabel)
        term.setCursorPos(noX, 3)
        term.write(noLabel)
        while true do
            local _, _, cx, cy = os.pullEvent("mouse_click")
            if cy == 3 then
                if cx >= yesX and cx <= yesX + #yesLabel then
                    local ok, err = pcall(fs.delete, destPath)
                    if not ok then
                        showError("Failed to overwrite: " .. tostring(err))
                        return
                    end
                    break
                elseif cx >= noX and cx <= noX + #noLabel then
                    return
                end
            end
        end
    end

    local ok, err = pcall(fs.copy, clipboard.path, destPath)
    if not ok then
        showError("Failed to paste: " .. tostring(err))
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
                    local entryPath = fs.combine(currentPath, name)

                    -- FIX: block deleting read-only/protected system paths
                    if fs.isReadOnly(entryPath) then
                        showError("This file or folder is read-only and cannot be deleted.")
                    elseif confirmDelete(name) then
                        local ok, err = pcall(fs.delete, entryPath)
                        if not ok then
                            showError("Failed to delete: " .. tostring(err))
                        end
                        -- FIX: clear clipboard if it pointed at what we just deleted
                        if clipboard and clipboard.path == entryPath then
                            clipboard = nil
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