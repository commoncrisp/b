local rawBase ="https://raw.githubusercontent.com/commoncrisp/b/main/"

local Players = game:GetService("Players")
local lp = Players.LocalPlayer

local sg = Instance.new("ScreenGui", lp.PlayerGui)
sg.ResetOnSpawn = false
local frame = Instance.new("Frame", sg)
frame.Size = UDim2.new(0, 300, 0, 200)
frame.Position = UDim2.new(0.5, -150, 0.5, -100)
frame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
frame.BorderSizePixel = 0
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local closeBtn = Instance.new("TextButton", frame)
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -33, 0, 3)
closeBtn.Text = "X"
closeBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.BorderSizePixel = 0
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

local scroll = Instance.new("ScrollingFrame", frame)
scroll.Size = UDim2.new(1, -20, 1, -45)
scroll.Position = UDim2.new(0, 10, 0, 38)
scroll.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 6)

local layout = Instance.new("UIListLayout", scroll)
layout.Padding = UDim.new(0, 2)
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
end)

local order = 0
local function dlog(msg)
    order = order + 1
    local lbl = Instance.new("TextLabel", scroll)
    lbl.Size = UDim2.new(1, -10, 0, 16)
    lbl.BackgroundTransparency = 1
    lbl.Text = "[" .. string.format("%.1f", os.clock()) .. "] " .. msg
    lbl.Font = Enum.Font.Code
    lbl.TextSize = 11
    lbl.TextColor3 = Color3.fromRGB(50, 255, 100)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.LayoutOrder = order
    Instance.new("UIPadding", lbl).PaddingLeft = UDim.new(0, 5)
    print("[FireflyFarm] " .. msg)
end

local function isNight()
    local clockTime = game:GetService("Lighting").ClockTime
    return clockTime < 6 or clockTime >= 18
end

local function getTimeOfDay()
    local clockTime = game:GetService("Lighting").ClockTime
    -- how far from night (18 or 0)
    -- closer to midday (12) = hop faster
    -- closer to dusk (18) or dawn (6) = wait longer
    if clockTime >= 6 and clockTime < 10 then
        return "early_day", 3  -- just after dawn, long wait
    elseif clockTime >= 10 and clockTime < 14 then
        return "midday", 1     -- midday, hop immediately
    elseif clockTime >= 14 and clockTime < 18 then
        return "late_day", 3   -- approaching dusk, wait a bit
    else
        return "night", 0      -- night!
    end
end

dlog("Waiting for game to load...")

-- wait for game to fully load
local loaded = false
task.spawn(function()
    game:GetService("ContentProvider"):PreloadAsync({workspace})
    loaded = true
end)

local timeout = 0
while not loaded and timeout < 10 do
    task.wait(1)
    timeout = timeout + 1
end

task.wait(2)

dlog("Checking time of day...")
local timeLabel, waitTime = getTimeOfDay()
dlog("Time: " .. timeLabel .. " (ClockTime: " .. string.format("%.1f", game:GetService("Lighting").ClockTime) .. ")")

if timeLabel == "night" then
    dlog("It is night! Running firefly farm...")
    local ok, err = pcall(function()
        local fireflyFarm = loadstring(game:HttpGet(rawBase .. "modules/firefly_farm/init.lua"))()
        fireflyFarm(dlog)
    end)
    if not ok then
        dlog("FATAL ERROR: " .. tostring(err))
    end
elseif timeLabel == "midday" then
    dlog("Midday - hopping immediately!")
    task.wait(1)
    local ok, err = pcall(function()
        local fireflyFarm = loadstring(game:HttpGet(rawBase .. "modules/firefly_farm/init.lua"))()
        fireflyFarm(dlog)
    end)
    if not ok then
        dlog("FATAL ERROR: " .. tostring(err))
    end
else
    dlog("Approaching " .. (timeLabel == "late_day" and "dusk" or "dawn") .. " - waiting " .. waitTime .. "s then checking...")
    task.wait(waitTime)
    local ok, err = pcall(function()
        local fireflyFarm = loadstring(game:HttpGet(rawBase .. "modules/firefly_farm/init.lua"))()
        fireflyFarm(dlog)
    end)
    if not ok then
        dlog("FATAL ERROR: " .. tostring(err))
    end
end
