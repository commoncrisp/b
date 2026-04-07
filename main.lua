-- Auto Rejoin
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local player = Players.LocalPlayer

local function onErrorMessageChanged(errorMessage)
    if errorMessage and errorMessage ~= "" then
        print("Error detected: " .. errorMessage)
        if player then
            wait()
            TeleportService:Teleport(game.PlaceId, player)
        end
    end
end
GuiService.ErrorMessageChanged:Connect(onErrorMessageChanged)

-- BSS Tools
local rawBase = "https://raw.githubusercontent.com/commoncrisp/a/main/"
local init = loadstring(game:HttpGet(rawBase .. "shared/init.lua"))()
init()
