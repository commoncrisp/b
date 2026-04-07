local TweenService = game:GetService("TweenService")
local lp = game:GetService("Players").LocalPlayer
local debugConsole = loadstring(game:HttpGet("https://raw.githubusercontent.com/commoncrisp/b/main/shared/debug_console.lua"))()
local dlog = debugConsole.log
debugConsole.setVisible(true)

local char = lp.Character
local hrp = char and char:FindFirstChild("HumanoidRootPart")
local humanoid = char and char:FindFirstChild("Humanoid")

if not hrp then dlog("no hrp!") return end

local TWEEN_SPEED = 70
local POS_START = Vector3.new(460, 52.5, 166)
local POS_A     = Vector3.new(480, 52.5, 154.3)
local POS_B     = Vector3.new(480, 52.5, 177)

local function tweenTo(pos)
    local dist = (hrp.Position - pos).Magnitude
    local dur = math.max(0.1, dist / TWEEN_SPEED)
    local t = TweenService:Create(hrp, TweenInfo.new(dur, Enum.EasingStyle.Linear), { CFrame = CFrame.new(pos) })
    t:Play()
    t.Completed:Wait()
end

dlog("anchoring...")
humanoid.PlatformStand = true
hrp.Anchored = true

local keepAnchored = true
task.spawn(function()
    while keepAnchored do
        hrp.Anchored = true
        humanoid.PlatformStand = true
        task.wait()
    end
end)

dlog("tweening to start...")
tweenTo(POS_START)
task.wait(2)

dlog("tweening to A...")
tweenTo(POS_A)
dlog("arrived at A, anchored: " .. tostring(hrp.Anchored))
task.wait(2)

dlog("tweening to B...")
tweenTo(POS_B)
dlog("arrived at B, anchored: " .. tostring(hrp.Anchored))
task.wait(2)

dlog("tweening back to start...")
tweenTo(POS_START)
dlog("back at start, anchored: " .. tostring(hrp.Anchored))
task.wait(2)

keepAnchored = false
hrp.Anchored = false
humanoid.PlatformStand = false
dlog("done, unanchored")
