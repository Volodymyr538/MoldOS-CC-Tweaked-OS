-- MoldOS App: snake
-- Classic snake game. Controlled with arrow keys (exception to mouse-only rule).

local W, H = term.getSize()
H = H - 1

local function clear()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1, 1)
end

local snake, dir, food, score, gameOver

local function resetGame()
    snake = {
        { x = math.floor(W / 2), y = math.floor(H / 2) },
        { x = math.floor(W / 2) - 1, y = math.floor(H / 2) },
        { x = math.floor(W / 2) - 2, y = math.floor(H / 2) },
    }
    dir = { x = 1, y = 0 }
    score = 0
    gameOver = false
end

local function randomFood()
    -- FIX: guard against an infinite loop if the snake somehow fills
    -- the entire board (extremely unlikely, but the old loop had no
    -- escape if every cell were occupied)
    local attempts = 0
    while attempts < 200 do
        local fx = math.random(1, W)
        local fy = math.random(1, H)
        local collides = false
        for _, seg in ipairs(snake) do
            if seg.x == fx and seg.y == fy then
                collides = true
                break
            end
        end
        if not collides then
            return { x = fx, y = fy }
        end
        attempts = attempts + 1
    end
    -- board is essentially full; just place it anywhere as a fallback
    return { x = 1, y = 1 }
end

local function draw()
    clear()
    for _, seg in ipairs(snake) do
        term.setCursorPos(seg.x, seg.y)
        term.setBackgroundColor(colors.green)
        term.write(" ")
    end
    term.setBackgroundColor(colors.black)

    term.setCursorPos(food.x, food.y)
    term.setBackgroundColor(colors.red)
    term.write(" ")
    term.setBackgroundColor(colors.black)

    term.setCursorPos(1, H + 1)
    term.write("Score: " .. score .. "   Arrow keys to move, Q to quit")
end

local function step()
    local head = snake[1]
    local newHead = { x = head.x + dir.x, y = head.y + dir.y }

    if newHead.x < 1 then newHead.x = W end
    if newHead.x > W then newHead.x = 1 end
    if newHead.y < 1 then newHead.y = H end
    if newHead.y > H then newHead.y = 1 end

    for _, seg in ipairs(snake) do
        if seg.x == newHead.x and seg.y == newHead.y then
            gameOver = true
            return
        end
    end

    table.insert(snake, 1, newHead)

    if newHead.x == food.x and newHead.y == food.y then
        score = score + 1
        food = randomFood()
    else
        table.remove(snake)
    end
end

local function inputLoop()
    while not gameOver do
        local _, key = os.pullEvent("key")
        -- FIX: previously a 180-degree reversal was only blocked when
        -- already moving in that axis (dir.y == 0 for horizontal moves),
        -- which is correct, but rapid double key-presses before the
        -- first move registered could still cause an instant self-collision.
        -- Comparing against the opposite vector directly is more robust.
        if key == keys.up and not (dir.x == 0 and dir.y == 1) then
            dir = { x = 0, y = -1 }
        elseif key == keys.down and not (dir.x == 0 and dir.y == -1) then
            dir = { x = 0, y = 1 }
        elseif key == keys.left and not (dir.x == 1 and dir.y == 0) then
            dir = { x = -1, y = 0 }
        elseif key == keys.right and not (dir.x == -1 and dir.y == 0) then
            dir = { x = 1, y = 0 }
        elseif key == keys.q then
            gameOver = true
        end
    end
end

local function gameLoop()
    while not gameOver do
        step()
        if not gameOver then
            draw()
        end
        sleep(0.2)
    end
end

local function main()
    math.randomseed(os.epoch("utc"))
    resetGame()
    food = randomFood()

    parallel.waitForAny(gameLoop, inputLoop)

    -- FIX: always draw a final, complete frame before showing Game Over,
    -- instead of potentially showing a half-updated board from the
    -- moment gameLoop was interrupted by inputLoop finishing first
    clear()
    local msg = "Game Over! Final score: " .. score
    term.setCursorPos(math.floor((W - #msg) / 2) + 1, math.floor(H / 2))
    term.write(msg)
    term.setCursorPos(1, H + 1)
    term.write("Click anywhere to exit...")

    -- FIX: drain any stray leftover key events from the input loop so
    -- they don't leak into whatever runs next after this app exits
    while true do
        local event = os.pullEvent()
        if event == "mouse_click" then break end
    end
    clear()
end

main()
