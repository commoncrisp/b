-- modules/commando_alt/init.lua
local RunService = game:GetService("RunService")
local RAW_BASE = "https://raw.githubusercontent.com/commoncrisp/b/main/"

local POS_START = Vector3.new(460,   52.5, 166)
local POS_A     = Vector3.new(480,   52.5, 154.3)
local POS_B     = Vector3.new(480,   52.5, 177)
local WAIT_SECS = 5
local SPEED     = 70

local _stopFlag = false

local function run(durationHours, dlog, atlasConfigPath)
    local debugConsole = loadstring(game:HttpGet(RAW_BASE .. "shared/debug_console.lua"))()
    dlog = dlog or debugConsole.log
    debugConsole.setVisible(true)

    _stopFlag = false
    local endTime = os.time() + (durationHours * 3600)
    local cycle = 0

    local lp = game:GetService("Players").LocalPlayer
    local char = lp.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local humanoid = char and char:FindFirstChild("Humanoid")

    if not hrp or not humanoid then
        dlog("[Commando] ERROR: No character found")
        return
    end

    local function flyTo(target)
        humanoid.PlatformStand = true
        hrp.Anchored = true
        local done = false
        local connection
        connection = RunService.Heartbeat:Connect(function(dt)
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            local dist = (hrp.Position - target).Magnitude
            if dist < 1 then
                done = true
                connection:Disconnect()
                return
            end
            hrp.CFrame = CFrame.new(hrp.Position + (target - hrp.Position).Unit * SPEED * dt)
        end)
        while not done do task.wait() end
        hrp.Anchored = false
        humanoid.PlatformStand = false
    end

    dlog("[Commando] Starting — duration: " .. durationHours .. "h")
    dlog("[Commando] Flying to start...")
    flyTo(POS_START)

    while not _stopFlag and os.time() < endTime do
        cycle = cycle + 1
        local remainingH = math.floor((endTime - os.time()) / 360) / 10
        dlog("[Commando] Cycle " .. cycle .. " | " .. remainingH .. "h remaining")

        -- wait at start (anchored so we dont fall)
        humanoid.PlatformStand = true
        hrp.Anchored = true
        task.wait(WAIT_SECS)
        hrp.Anchored = false
        humanoid.PlatformStand = false
        if _stopFlag then break end

        flyTo(POS_A)
        if _stopFlag then break end

        flyTo(POS_B)
        if _stopFlag then break end

        flyTo(POS_START)
    end

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
