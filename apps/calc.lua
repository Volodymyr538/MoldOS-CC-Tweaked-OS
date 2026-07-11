-- MoldOS App: calc
-- Простой калькулятор. Поддерживает + - * / ( )
-- Введи 'exit' чтобы выйти

print("=== Калькулятор MoldOS ===")
print("Введи выражение (например: 2 + 2 * 3)")
print("Команда 'exit' - выход")
print("")

while true do
    write("calc> ")
    local input = read()

    if input == "exit" then
        break
    end

    if input:match("^[%d%s%+%-%*%/%(%)%.]+$") then
        local fn, err = load("return " .. input)
        if fn then
            local ok, result = pcall(fn)
            if ok then
                print("= " .. tostring(result))
            else
                printError("Ошибка вычисления")
            end
        else
            printError("Некорректное выражение")
        end
    else
        printError("Разрешены только числа и операторы + - * / ( )")
    end
end
