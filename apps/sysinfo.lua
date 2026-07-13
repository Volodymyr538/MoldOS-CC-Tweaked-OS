-- MoldOS App: sysinfo
-- Shows information about the computer

local lang = dofile("/os/lib/lang.lua")
local t = lang.t

term.setTextColor(colors.white)
print("=== " .. t("sysinfo_title") .. " ===")
print("")
print(t("craftos_version") .. " " .. _HOST)
print(t("computer_id") .. " " .. os.getComputerID())
local label = os.getComputerLabel()
print(t("computer_label") .. " " .. (label or t("not_set")))
print("")

local total = fs.getCapacity("/")
local free = fs.getFreeSpace("/")
if total and free then
    print(t("disk_label") .. " " .. math.floor(free / 1024) .. " KB " .. t("free_of") .. " " .. math.floor(total / 1024) .. " KB")
end

print("")
print(t("click_exit"))
os.pullEvent("mouse_click")