-- MoldOS App: notes
-- Simple notes app with mouse-clickable note list

local W, H = term.getSize()
local NOTES_DIR = "/os/data/notes"

local lang = dofile("/os/lib/lang.lua")
local t = lang.t

local function clear()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1, 1)
end

if not fs.exists(NOTES_DIR) then
    fs.makeDir(NOTES_DIR)
end

local function getNoteList()
    local files = fs.list(NOTES_DIR)
    table.sort(files)
    return files
end

local function readNote(name)
    local f = fs.open(fs.combine(NOTES_DIR, name), "r")
    local content = f.readAll()
    f.close()
    return content
end

local function writeNote(name, content)
    local f = fs.open(fs.combine(NOTES_DIR, name), "w")
    f.write(content)
    f.close()
end

local function newNote()
    clear()
    print(t("new_note_title"))
    write("> ")
    local title = read()
    if not title or title == "" then return end

    local path = fs.combine(NOTES_DIR, title)
    if fs.exists(path) then
        print(t("note_exists"))
        sleep(1.5)
        return
    end

    clear()
    print(t("writing_note") .. " " .. title)
    print(t("type_note"))
    print("")

    local lines = {}
    while true do
        local line = read()
        if line == "" then break end
        table.insert(lines, line)
    end

    writeNote(title, table.concat(lines, "\n"))
end

local function viewNote(name)
    clear()
    term.write("=== " .. name .. " ===")
    term.setCursorPos(1, 2)
    term.write(string.rep("-", W))

    local content = readNote(name)
    local y = 3
    for line in (content .. "\n"):gmatch("(.-)\n") do
        term.setCursorPos(1, y)
        term.write(line)
        y = y + 1
        if y > H - 2 then break end
    end

    local deleteLabel = "[ " .. t("delete_btn") .. " ]"
    local backLabel = "[ " .. t("back") .. " ]"
    local backX = #deleteLabel + 6

    term.setCursorPos(1, H)
    term.write(deleteLabel)
    term.setCursorPos(backX, H)
    term.write(backLabel)

    while true do
        local _, _, cx, cy = os.pullEvent("mouse_click")
        if cy == H then
            if cx >= 1 and cx <= #deleteLabel then
                fs.delete(fs.combine(NOTES_DIR, name))
                return
            elseif cx >= backX and cx <= backX + #backLabel then
                return
            end
        end
    end
end

local function mainMenu()
    while true do
        clear()
        term.write("=== " .. t("notes_title") .. " ===")
        term.setCursorPos(1, 2)
        term.write(string.rep("-", W))

        local notes = getNoteList()
        local rows = {}
        local y = 4

        if #notes == 0 then
            term.setCursorPos(4, y)
            term.setTextColor(colors.lightGray)
            term.write(t("no_notes"))
            term.setTextColor(colors.white)
            y = y + 1
        else
            for _, name in ipairs(notes) do
                term.setCursorPos(4, y)
                term.write("[ " .. name .. " ]")
                table.insert(rows, { y = y, name = name })
                y = y + 1
            end
        end

        local newNoteLabel = "[ " .. t("new_note_btn") .. " ]"
        local quitLabel = "[ " .. t("quit") .. " ]"
        local quitX = #newNoteLabel + 6

        term.setCursorPos(1, H)
        term.write(newNoteLabel)
        term.setCursorPos(quitX, H)
        term.write(quitLabel)

        local _, _, cx, cy = os.pullEvent("mouse_click")
        if cy == H then
            if cx >= 1 and cx <= #newNoteLabel then
                newNote()
            elseif cx >= quitX and cx <= quitX + #quitLabel then
                break
            end
        else
            for _, row in ipairs(rows) do
                if cy == row.y then
                    viewNote(row.name)
                    break
                end
            end
        end
    end
    clear()
end

mainMenu()