-- Auto Candy Script (Driving Empire) - v3
-- Features: Auto Farm, Auto Hop (new server), Auto Execute (Driving Empire only)
-- Toggle states persist across server hops.
-- Auto Execute uses GitHub raw URLs (more reliable than Pastebin).

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local UIS = UserInputService

-- ========== CONFIG ==========
local COLLECTIBLE_SPAWNER = "CollectibleSpawner"
local CANDY_PREFIX = "SPOOK_CANDY"
local TELEPORT_COOLDOWN = 0.2
local DRIVING_EMPIRE_PLACE_ID = 3351674303

-- ⚠️ PUT YOUR GITHUB RAW URL HERE
-- Format: https://raw.githubusercontent.com/USERNAME/REPO/main/SCRIPT.lua
-- Example: https://raw.githubusercontent.com/yourname/autocandy/main/script.lua
local SCRIPT_URL = "https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/YOUR_SCRIPT.lua"

-- Where to save toggle state so it survives the hop
local STATE_FILE = "AutoCandy_State.json"

-- ========== STATE PERSISTENCE ==========
local function saveState()
    local data = {
        autoFarm = _G.AutoCandy_Farm or false,
        autoHop = _G.AutoCandy_Hop or false,
        autoExecute = _G.AutoCandy_Execute or false,
    }
    _G.AutoCandy_SavedState = data
    pcall(function()
        if writefile and isfolder and not isfolder("AutoCandy") then
            makefolder("AutoCandy")
        end
        if writefile then
            writefile("AutoCandy/" .. STATE_FILE, HttpService:JSONEncode(data))
        end
    end)
end

local function loadState()
    if _G.AutoCandy_SavedState then
        return _G.AutoCandy_SavedState
    end
    local ok, content = pcall(function()
        if readfile and isfile and isfile("AutoCandy/" .. STATE_FILE) then
            return readfile("AutoCandy/" .. STATE_FILE)
        end
    end)
    if ok and content then
        local ok2, data = pcall(function() return HttpService:JSONDecode(content) end)
        if ok2 and data then return data end
    end
    return { autoFarm = false, autoHop = false, autoExecute = false }
end

local savedState = loadState()

-- ========== UI PARENT ==========
local function getParent()
    local ok, hui = pcall(function() return gethui and gethui() end)
    if ok and hui then return hui end
    local ok2, core = pcall(function() return game:GetService("CoreGui") end)
    if ok2 and core then return core end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local old = getParent():FindFirstChild("AutoCandyGui")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "AutoCandyGui"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = getParent()

-- ========== MAIN PANEL ==========
local main = Instance.new("Frame")
main.Size = UDim2.new(0, 260, 0, 260)
main.Position = UDim2.new(0.5, -130, 0.08, 0)
main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
main.BorderSizePixel = 0
main.Active = true
main.Parent = gui

local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = main
local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(60, 60, 60); s.Thickness = 1.5; s.Parent = main

-- ========== TITLE ==========
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 28)
title.Position = UDim2.new(0, 10, 0, 6)
title.BackgroundTransparency = 1
title.Text = "Auto Candy"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = main

-- ========== STATUS ==========
local statusLbl = Instance.new("TextLabel")
statusLbl.Size = UDim2.new(1, -20, 0, 18)
statusLbl.Position = UDim2.new(0, 10, 0, 34)
statusLbl.BackgroundTransparency = 1
statusLbl.Text = "Status: Idle"
statusLbl.TextColor3 = Color3.fromRGB(140, 140, 140)
statusLbl.Font = Enum.Font.Gotham
statusLbl.TextSize = 11
statusLbl.TextXAlignment = Enum.TextXAlignment.Left
statusLbl.Parent = main

-- ========== TOGGLE HELPER ==========
local function makeToggle(yPos, label)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 32)
    btn.Position = UDim2.new(0, 10, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(40, 10, 10)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.Text = label .. ": OFF"
    btn.Parent = main

    local btnC = Instance.new("UICorner")
    btnC.CornerRadius = UDim.new(0, 8)
    btnC.Parent = btn

    local btnS = Instance.new("UIStroke")
    btnS.Color = Color3.fromRGB(239, 68, 68)
    btnS.Thickness = 1.5
    btnS.Parent = btn

    return btn, btnS
end

local farmBtn, fs = makeToggle(58, "Auto Farm")
local hopBtn, hs = makeToggle(94, "Auto Hop")
local execBtn, es = makeToggle(130, "Auto Execute")

-- ========== COUNTERS ==========
local countLbl = Instance.new("TextLabel")
countLbl.Size = UDim2.new(1, -20, 0, 16)
countLbl.Position = UDim2.new(0, 10, 0, 168)
countLbl.BackgroundTransparency = 1
countLbl.Text = "Candies collected: 0"
countLbl.TextColor3 = Color3.fromRGB(34, 197, 94)
countLbl.Font = Enum.Font.GothamBold
countLbl.TextSize = 11
countLbl.TextXAlignment = Enum.TextXAlignment.Left
countLbl.Parent = main

local targetLbl = Instance.new("TextLabel")
targetLbl.Size = UDim2.new(1, -20, 0, 16)
targetLbl.Position = UDim2.new(0, 10, 0, 186)
targetLbl.BackgroundTransparency = 1
targetLbl.Text = "Target: None"
targetLbl.TextColor3 = Color3.fromRGB(140, 140, 140)
targetLbl.Font = Enum.Font.Gotham
targetLbl.TextSize = 10
targetLbl.TextXAlignment = Enum.TextXAlignment.Left
targetLbl.Parent = main

local infoLbl = Instance.new("TextLabel")
infoLbl.Size = UDim2.new(1, -20, 0, 30)
infoLbl.Position = UDim2.new(0, 10, 0, 208)
infoLbl.BackgroundTransparency = 1
infoLbl.Text = "States persist across hops. Exec only in Driving Empire."
infoLbl.TextColor3 = Color3.fromRGB(100, 100, 100)
infoLbl.Font = Enum.Font.Gotham
infoLbl.TextSize = 9
infoLbl.TextXAlignment = Enum.TextXAlignment.Left
infoLbl.TextWrapped = true
infoLbl.Parent = main

-- ========== STATE ==========
local autoFarm = false
local autoHop = false
local autoExecute = false
local candyCount = 0
local currentTarget = nil
local farmThread = nil
local originalCFrame = nil

-- ========== HELPERS ==========
local function setStatus(text, color)
    statusLbl.Text = "Status: " .. text
    statusLbl.TextColor3 = color or Color3.fromRGB(140, 140, 140)
end

local function setTarget(text, color)
    targetLbl.Text = "Target: " .. text
    targetLbl.TextColor3 = color or Color3.fromRGB(140, 140, 140)
end

local function updateCounter()
    countLbl.Text = string.format("Candies collected: %d", candyCount)
end

local function getHRP()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function anyToggleOn()
    return autoFarm or autoHop or autoExecute
end

local function setToggleVisual(btn, stroke, isOn, label)
    btn.Text = label .. ": " .. (isOn and "ON" or "OFF")
    btn.BackgroundColor3 = isOn and Color3.fromRGB(10, 40, 10) or Color3.fromRGB(40, 10, 10)
    stroke.Color = isOn and Color3.fromRGB(34, 197, 94) or Color3.fromRGB(239, 68, 68)
end

-- ========== CANDY FINDER ==========
local function getCandies()
    local candies = {}
    local ok, spawner = pcall(function()
        return Workspace:FindFirstChild(COLLECTIBLE_SPAWNER)
    end)
    if not ok or not spawner then return candies end

    for _, child in ipairs(spawner:GetChildren()) do
        if child.Name:find(CANDY_PREFIX) then
            local okPivot, pivot = pcall(function() return child:GetPivot() end)
            if okPivot and pivot then
                table.insert(candies, child)
            end
        end
    end
    return candies
end

local function distanceTo(obj)
    local hrp = getHRP()
    if not hrp then return math.huge end
    local ok, pos = pcall(function() return obj:GetPivot().Position end)
    if not ok then return math.huge end
    return (hrp.Position - pos).Magnitude
end

local function getNearestCandy()
    if currentTarget then
        local ok, parent = pcall(function() return currentTarget.Parent end)
        if ok and parent then return currentTarget end
        currentTarget = nil
    end

    local candies = getCandies()
    local best, bestDist = nil, math.huge
    for _, candy in ipairs(candies) do
        local d = distanceTo(candy)
        if d < bestDist then best, bestDist = candy, d end
    end
    return best
end

-- ========== TELEPORT ==========
local function teleportTo(obj)
    local hrp = getHRP()
    if not hrp then return false end

    local ok, pivot = pcall(function() return obj:GetPivot() end)
    if not ok then return false end

    local targetPos = pivot.Position + Vector3.new(0, 3, 0)
    hrp.CFrame = CFrame.new(targetPos)
    return true
end

-- ========== COLLECT ==========
local function collectCandy(candy)
    if not candy then return true end
    teleportTo(candy)
    task.wait(0.15)

    local prompt = candy:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt and prompt.Enabled then
        if fireproximityprompt then
            pcall(function() fireproximityprompt(prompt) end)
        else
            pcall(function()
                prompt.HoldDuration = 0
                prompt:InputHoldBegin()
                task.wait(0.05)
                prompt:InputHoldEnd()
            end)
        end
    end

    local waited = 0
    while waited < 1.5 and anyToggleOn() do
        task.wait(0.1)
        waited += 0.1
        if not candy.Parent then return true end
    end
    return true
end

-- ========== RETURN TO START ==========
local function returnToStart()
    if not originalCFrame then return end
    local hrp = getHRP()
    if not hrp then return end
    hrp.CFrame = originalCFrame
    task.wait(0.3)
end

-- ========== SERVER HOP ==========
local function hopToNewServer()
    setStatus("Fetching new server...", Color3.fromRGB(234, 179, 8))

    _G.AutoCandy_SavedState = {
        autoFarm = autoFarm,
        autoHop = autoHop,
        autoExecute = autoExecute,
    }
    saveState()

    local ok, servers = pcall(function()
        local url = string.format(
            "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100",
            DRIVING_EMPIRE_PLACE_ID
        )
        local res = game:HttpGet(url)
        return HttpService:JSONDecode(res)
    end)

    if not ok or not servers or not servers.data or #servers.data == 0 then
        setStatus("Hop failed - no servers", Color3.fromRGB(239, 68, 68))
        return false
    end

    local candidates = {}
    for _, srv in ipairs(servers.data) do
        if srv.id ~= game.JobId and srv.playing < srv.maxPlayers then
            table.insert(candidates, srv)
        end
    end

    if #candidates == 0 then
        setStatus("No other servers available", Color3.fromRGB(239, 68, 68))
        return false
    end

    local chosen = candidates[math.random(1, #candidates)]
    setStatus("Joining new server...", Color3.fromRGB(34, 197, 94))

    local ok2 = pcall(function()
        TeleportService:TeleportToPlaceInstance(DRIVING_EMPIRE_PLACE_ID, chosen.id, LocalPlayer)
    end)

    if not ok2 then
        setStatus("Teleport failed", Color3.fromRGB(239, 68, 68))
        return false
    end
    return true
end

-- ========== AUTO EXECUTE (GitHub-optimized) ==========
local function executeScript()
    if game.PlaceId ~= DRIVING_EMPIRE_PLACE_ID then
        setStatus("❌ Not in Driving Empire", Color3.fromRGB(239, 68, 68))
        return false
    end

    if not SCRIPT_URL or SCRIPT_URL:find("YOUR_USERNAME") then
        setStatus("❌ Edit SCRIPT_URL first!", Color3.fromRGB(239, 68, 68))
        return false
    end

    if not SCRIPT_URL:find("raw.githubusercontent.com") and not SCRIPT_URL:find("/raw/") then
        setStatus("❌ URL not a raw link", Color3.fromRGB(239, 68, 68))
        return false
    end

    setStatus("Fetching script...", Color3.fromRGB(234, 179, 8))

    -- Step 1: fetch
    local ok1, code = pcall(function() return game:HttpGet(SCRIPT_URL, true) end)
    if not ok1 then
        setStatus("❌ HttpGet: " .. tostring(code):sub(1, 20), Color3.fromRGB(239, 68, 68))
        return false
    end
    if not code or #code < 50 then
        setStatus("❌ Empty fetch (bad URL?)", Color3.fromRGB(239, 68, 68))
        return false
    end

    -- Check if we got HTML instead of Lua
    if code:sub(1, 15):lower():find("<!doctype") or code:sub(1, 5):lower():find("<html") then
        setStatus("❌ Got HTML - not raw", Color3.fromRGB(239, 68, 68))
        return false
    end

    -- Step 2: compile
    setStatus("Compiling...", Color3.fromRGB(234, 179, 8))
    local fn, err = loadstring(code)
    if not fn then
        setStatus("❌ Compile: " .. tostring(err):sub(1, 22), Color3.fromRGB(239, 68, 68))
        return false
    end

    -- Step 3: run
    setStatus("Running...", Color3.fromRGB(234, 179, 8))
    local ok2, runErr = pcall(fn)
    if ok2 then
        setStatus("✅ Executed!", Color3.fromRGB(34, 197, 94))
        return true
    else
        setStatus("❌ Runtime: " .. tostring(runErr):sub(1, 22), Color3.fromRGB(239, 68, 68))
        return false
    end
end

-- ========== MAIN LOOP ==========
local function startFarm()
    if farmThread then return end

    local hrp = getHRP()
    if hrp then originalCFrame = hrp.CFrame end

    autoFarm = true
    setToggleVisual(farmBtn, fs, true, "Auto Farm")
    setStatus("Farming", Color3.fromRGB(34, 197, 94))
    saveState()

    farmThread = task.spawn(function()
        while autoFarm do
            if not anyToggleOn() then break end

            local candy = getNearestCandy()
            if not candy then
                setTarget("None", Color3.fromRGB(140, 140, 140))
                setStatus("All candies taken", Color3.fromRGB(34, 197, 94))
                returnToStart()

                if autoHop then
                    hopToNewServer()
                    break
                end

                autoFarm = false
                setToggleVisual(farmBtn, fs, false, "Auto Farm")
                setStatus("Idle - back at start", Color3.fromRGB(140, 140, 140))
                saveState()
                break
            end

            currentTarget = candy
            setTarget(candy.Name, Color3.fromRGB(234, 179, 8))
            setStatus("Collecting " .. candy.Name, Color3.fromRGB(234, 179, 8))

            collectCandy(candy)
            if not anyToggleOn() then break end

            candyCount += 1
            updateCounter()
            setStatus("Collected!", Color3.fromRGB(34, 197, 94))
            currentTarget = nil
            task.wait(TELEPORT_COOLDOWN)
        end
    end)
end

local function stopFarm()
    autoFarm = false
    setToggleVisual(farmBtn, fs, false, "Auto Farm")
    setStatus("Idle")
    setTarget("None", Color3.fromRGB(140, 140, 140))
    currentTarget = nil
    if farmThread then
        task.cancel(farmThread)
        farmThread = nil
    end
    saveState()
end

-- ========== BUTTON HANDLERS ==========
farmBtn.MouseButton1Click:Connect(function()
    if autoFarm then stopFarm() else startFarm() end
end)

hopBtn.MouseButton1Click:Connect(function()
    autoHop = not autoHop
    setToggleVisual(hopBtn, hs, autoHop, "Auto Hop")
    saveState()
end)

execBtn.MouseButton1Click:Connect(function()
    autoExecute = not autoExecute
    setToggleVisual(execBtn, es, autoExecute, "Auto Execute")
    saveState()
    if autoExecute then
        executeScript()
    end
end)

-- ========== DRAGGING ==========
do
    local dragging, dragStart, startPos
    title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                                      startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

-- ========== RESTORE PREVIOUS STATE (after hop) ==========
if savedState then
    if savedState.autoFarm then
        task.spawn(function()
            task.wait(1)
            startFarm()
        end)
    end
    if savedState.autoHop then
        autoHop = true
        setToggleVisual(hopBtn, hs, true, "Auto Hop")
    end
    if savedState.autoExecute then
        autoExecute = true
        setToggleVisual(execBtn, es, true, "Auto Execute")
        task.spawn(function()
            task.wait(1.5)
            executeScript()
        end)
    end
end

setStatus("Idle - Ready")
