local Players = game:GetService("Players")
local lp = Players.LocalPlayer

local function buildBeeList(beeKeywords, dlog)
    local bee_list = {}

    local honeycombs = workspace:FindFirstChild("Honeycombs")
    local myHive = nil
    if honeycombs then
        for _, hive in pairs(honeycombs:GetChildren()) do
            local owner = hive:FindFirstChild("Owner")
            if owner and tostring(owner.Value) == lp.Name then
                myHive = hive
                break
            end
        end
    end
    if not myHive then
        dlog("ERROR: No hive found for " .. lp.Name)
        return bee_list
    end
    dlog("Found hive: " .. myHive.Name)

    local cellsFolder = myHive:FindFirstChild("Cells") or myHive:FindFirstChild("Slots") or myHive
    for _, slot in pairs(cellsFolder:GetChildren()) do
        local slotName = slot.Name
        local x_cord, y_cord = slotName:match("C(%d+),(%d+)")
        x_cord = tonumber(x_cord) or 0
        y_cord = tonumber(y_cord) or 0
        for _, obj in pairs(slot:GetDescendants()) do
            if obj:IsA("StringValue") then
                local val = tostring(obj.Value)
                for _, key in pairs(beeKeywords) do
                    if val:find(key) then
                        table.insert(bee_list, {x_cord, y_cord, val})
                        break
                    end
                end
            end
        end
    end

    table.sort(bee_list, function(a, b)
        if a[1] ~= b[1] then return a[1] < b[1] end
        return a[2] < b[2]
    end)

    dlog("Basic scan done: " .. #bee_list .. " bees found")
    return bee_list
end

return buildBeeList