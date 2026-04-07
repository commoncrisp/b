local Players = game:GetService("Players")
local lp = Players.LocalPlayer

local debugGui = Instance.new("ScreenGui", lp.PlayerGui)
debugGui.ResetOnSpawn = false

local debugFrame = Instance.new("Frame", debugGui)
debugFrame.Visible = false
debugFrame.Size = UDim2.new(0, 400, 0, 250)
debugFrame.Position = UDim2.new(0.5, -200, 0.7, 0)
debugFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
debugFrame.Active = true
debugFrame.Draggable = true

local debugTitle = Instance.new("TextLabel", debugFrame)
debugTitle.Size = UDim2.new(1, -40, 0, 30)
debugTitle.Position = UDim2.new(0, 10, 0, 0)
debugTitle.BackgroundTransparency = 1
debugTitle.Text = "DEBUG CONSOLE"
debugTitle.Font = Enum.Font.GothamBold
debugTitle.TextSize = 12
debugTitle.TextColor3 = Color3.fromRGB(255, 200, 50)
debugTitle.TextXAlignment = Enum.TextXAlignment.Left

local debugBox = Instance.new("TextBox", debugFrame)
debugBox.Size = UDim2.new(1, -20, 1, -40)
debugBox.Position = UDim2.new(0, 10, 0, 35)
debugBox.MultiLine = true
debugBox.TextYAlignment = Enum.TextYAlignment.Top
debugBox.TextWrapped = true
debugBox.ClearTextOnFocus = false
debugBox.TextEditable = false
debugBox.Font = Enum.Font.Code
debugBox.TextSize = 11
debugBox.TextColor3 = Color3.fromRGB(50, 255, 100)
debugBox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
debugBox.Text = ""

local closeDebug = Instance.new("TextButton", debugFrame)
closeDebug.Size = UDim2.new(0, 30, 0, 30)
closeDebug.Position = UDim2.new(1, -30, 0, 0)
closeDebug.Text = "X"
closeDebug.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
closeDebug.TextColor3 = Color3.new(1, 1, 1)
closeDebug.MouseButton1Click:Connect(function()
    debugFrame.Visible = false
end)

local logLines = {}
local function dlog(msg)
    print("[DEBUG] " .. msg)
    table.insert(logLines, "[" .. string.format("%.2f", os.clock()) .. "] " .. msg)
    debugBox.Text = table.concat(logLines, "\n")
end

local function setVisible(enabled)
    debugFrame.Visible = enabled
end

return {
    log = dlog,
    setVisible = setVisible
}
