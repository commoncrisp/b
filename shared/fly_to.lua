local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local lp = Players.LocalPlayer

local TWEEN_SPEED = 70
local ARRIVAL_THRESHOLD = 5

local function flyTo(position, dlog)
    local char = lp.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local humanoid = char and char:FindFirstChild("Humanoid")
    if not hrp or not humanoid then
        if dlog then dlog("ERROR: No character found") end
        return false
    end

    local distance = (hrp.Position - position).Magnitude
    local duration = distance / TWEEN_SPEED

    humanoid.PlatformStand = true
    hrp.Anchored = true

    local tween = TweenService:Create(hrp, TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {
        CFrame = CFrame.new(position)
    })

    tween:Play()
    tween.Completed:Wait()

    local timeout = 5
    local elapsed = 0
    while (hrp.Position - position).Magnitude > ARRIVAL_THRESHOLD do
        task.wait(0.1)
        elapsed = elapsed + 0.1
        if elapsed >= timeout then
            hrp.Anchored = false
            humanoid.PlatformStand = false
            if dlog then dlog("ERROR: Timed out flying to position") end
            return false
        end
    end

    hrp.Anchored = false
    humanoid.PlatformStand = false
    task.wait(0.5)

    if dlog then dlog("Arrived at destination!") end
    return true
end

return flyTo