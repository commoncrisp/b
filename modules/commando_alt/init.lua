-- modules/commando_alt/init.lua
local RAW_BASE = "https://raw.githubusercontent.com/commoncrisp/b/main/"

local POS_START = Vector3.new(460,   52.5, 166)
local POS_A     = Vector3.new(480,   52.5, 154.3)
local POS_B     = Vector3.new(480,   52.5, 177)
local WAIT_SECS = 5

local _stopFlag = false

local function run(durationHours, dlog, atlasConfigPath)
    local debugConsole = loadstring(game:HttpGet(RAW_BASE .. "shared/debug_console.lua"))()
    dlog = dlog or debugConsole.log
    debugConsole.setVisible(true)

    local flyTo = loadstring(game:HttpGet(RAW_BASE .. "shared/fly_to.lua"))()

    _stopFlag = false
    local endTime   = os.clock() + (durationHours * 3600)
    local cycle     = 0

    dlog("[Commando] Starting — duration: " .. durationHours .. "h")
    dlog("[Commando] End time in " .. durationHours .. " hours")

    -- teleport to start
    local lp = game:GetService("Players").LocalPlayer
    local char = lp.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = CFrame.new(POS_START)
    end

    while not _stopFlag and os.clock() < endTime do
        cycle = cycle + 1
        local remainingH = math.floor((endTime - os.clock()) / 360) / 10
        dlog("[Commando] Cycle " .. cycle .. " | " .. remainingH .. "h remaining")

        -- wait at start
        dlog("[Commando] Waiting " .. WAIT_SECS .. "s at start...")
        task.wait(WAIT_SECS)
        if _stopFlag then break end

        -- move to A
        dlog("[Commando] Moving to A...")
        flyTo(POS_A, dlog)
        if _stopFlag then break end

        -- move to B
        dlog("[Commando] Moving to B...")
        flyTo(POS_B, dlog)
        if _stopFlag then break end

        -- back to start
        dlog("[Commando] Returning to start...")
        flyTo(POS_START, dlog)
    end

    if _stopFlag then
        dlog("[Commando] Stopped by user")
    else
        dlog("[Commando] Duration complete!")
        -- run atlas if config provided
        if atlasConfigPath then
            dlog("[Commando] Swapping to atlas config: " .. atlasConfigPath)
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
