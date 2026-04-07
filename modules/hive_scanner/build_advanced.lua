local Players = game:GetService("Players")
local lp = Players.LocalPlayer

local function buildAdvancedList(beeKeywords, dlog)
    local advanced_results = {}

    local honeycombs = workspace:FindFirstChild("Honeycombs")
    if not honeycombs then
        dlog("ERROR: No Honeycombs found")
        return advanced_results
    end

    local myHive = nil
    for _, h in pairs(honeycombs:GetChildren()) do
        local owner = h:FindFirstChild("Owner")
        if owner and tostring(owner.Value) == lp.Name then
            myHive = h
            break
        end
    end
    if not myHive then
        dlog("ERROR: No hive found")
        return advanced_results
    end

    local cells = myHive:FindFirstChild("Cells") or myHive:FindFirstChild("Slots") or myHive
    for _, cell in pairs(cells:GetChildren()) do
        pcall(function()
            local bName = "Empty"
            local isGifted = false

            if cell:GetAttribute("Gifted") == true or cell:GetAttribute("IsGifted") == true then
                isGifted = true
            end

            for _, obj in pairs(cell:GetDescendants()) do
                if obj:IsA("ValueBase") then
                    local valStr = tostring(obj.Value)
                    for _, key in pairs(beeKeywords) do
                        if valStr:find(key) then
                            bName = valStr
                            break
                        end
                    end
                end

                if obj:GetAttribute("Gifted") == true or obj:GetAttribute("IsGifted") == true then
                    isGifted = true
                end

                local objName = obj.Name:lower()
                if objName:find("gifted") then
                    if obj:IsA("BoolValue") and obj.Value == true then
                        isGifted = true
                    elseif tostring(obj.Value):lower():find("true") then
                        isGifted = true
                    end
                end
            end

            if bName ~= "Empty" then
                table.insert(advanced_results, {Slot = cell.Name, Name = bName, Gifted = isGifted})
            end
        end)
    end

    table.sort(advanced_results, function(a, b)
        return (tonumber(a.Slot:match("%d+")) or 0) < (tonumber(b.Slot:match("%d+")) or 0)
    end)

    dlog("Advanced scan done: " .. #advanced_results .. " slots mapped")
    return advanced_results
end

return buildAdvancedList