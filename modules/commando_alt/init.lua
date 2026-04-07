-- modules/commando_alt/init.lua
local TweenService = game:GetService("TweenService")
local RAW_BASE = "https://raw.githubusercontent.com/commoncrisp/b/main/"

local POS_START = Vector3.new(460,   52.5, 166)
local POS_A     = Vector3.new(480,   52.5, 154.3)
local POS_B     = Vector3.new(480,   52.5, 177)
local WAIT_SECS = 5
local TWEEN_SPEED = 70 -- studs per second

local _stopFlag = false

local function tweenTo(hrp, humanoid, pos)
    local distance = (hrp.Position - pos).Magnitude
    local duration = math.max(0.1, distance / TWEEN_SPEED)
    local tween = TweenService:Create(hrp, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
        CFrame = CFrame.new(pos)
    })
    tween:Play()
    tween.Completed:Wait()
end

local function run(durationHours, dlog, atlasConfigPath)
    local debugConsole = loadstring(game:HttpGet(RAW_BASE .. "shared/debug_console.lua"))()
    dlog = dlog or debugConsole.log
    debugConsole.setVisible(true)

    _stopFlag = false
    local endTime = os.clock() + (durationHours * 3600)
    local cycle = 0

    dlog("[Commando] Starting — duration: " .. durationHours .. "h")

    local lp = game:GetService("Players").LocalPlayer
    local char = lp.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local humanoid = char and char:FindFirstChild("Humanoid")

    if not hrp or not humanoid then
        dlog("[Commando] ERROR: No character found")
        return
    end

    -- anchor and stay anchored the whole time
    humanoid.PlatformStand = true
    hrp.Anchored = true
    hrp.CFrame = CFrame.new(POS_START)

    while not _stopFlag and os.clock() < endTime do
        cycle = cycle + 1
        local remainingH = math.floor((endTime - os.clock()) / 360) / 10
        dlog("[Commando] Cycle " .. cycle .. " | " .. remainingH .. "h remaining")

        task.wait(WAIT_SECS)
        if _stopFlag then break end

        dlog("[Commando] Moving to A...")
        tweenTo(hrp, humanoid, POS_A)
        if _stopFlag then break end

        dlog("[Commando] Moving to B...")
        tweenTo(hrp, humanoid, POS_B)
        if _stopFlag then break end

        dlog("[Commando] Returning to start...")
        tweenTo(hrp, humanoid, POS_START)
    end

    -- unanchor when done or stopped
    hrp.Anchored = false
    humanoid.PlatformStand = false

    if _stopFlag then
        dlog("[Commando] Stopped by user")
    else
        dlog("[Commando] Duration complete!")
        if atlasConfigPath then
            dlog("[Commando] Swapping atlas config: " .. atlasConfigPath)
            pcall(function()
                local data = readfile(atlasConfigPath)
                writefile("Atlas/Preset 1.json", data)
                writefile("Atlas/Bee Swarm Simulator/Configs/Preset 1.json", data)
            end)
            dlog("[Commando] Reloading Atlas...")
            pcall(function()
                loadstring(game:HttpGet("https://raw.githubusercontent.com/Chris12089/atlasbss/main/script.lua"))()
            end)
        end
    end
end

local function stop()
    _stopFlag = true
end

return { run = run, stop = stop }
