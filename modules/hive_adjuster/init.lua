local Players = game:GetService("Players")
local lp = Players.LocalPlayer

local HIVE_POSITIONS = {
    [1] = Vector3.new(-3,     5.9, 330.6),
    [2] = Vector3.new(-42.1,  5.9, 330.6),
    [3] = Vector3.new(-76.5,  5.9, 330.6),
    [4] = Vector3.new(-114.5, 5.9, 330.6),
    [5] = Vector3.new(-147.5, 5.9, 330.6),
    [6] = Vector3.new(-185.5, 5.9, 330.6),
}

local beeKeywords = {
    "Basic", "Bomber", "Brave", "Bumble", "Cool", "Hasty", "Looker", "Rad", "Rascal", "Stubborn",
    "Bubble", "Bucko", "Commander", "Demo", "Exhausted", "Fire", "Frosty", "Honey", "Rage", "Riley", "Shocked",
    "Baby", "Carpenter", "Demon", "Diamond", "Lion", "Music", "Ninja", "Shy",
    "Buoyant", "Fuzzy", "Precise", "Spicy", "Tadpole", "Vector",
    "Bear", "Cobalt", "Crimson", "Digital", "Festive", "Gummy", "Photon", "Puppy", "Tabby", "Vicious", "Windy"
}

local function getHivePosition()
    local honeycombs = workspace:FindFirstChild("Honeycombs")
    if not honeycombs then return nil end
    for _, hive in pairs(honeycombs:GetChildren()) do
        local owner = hive:FindFirstChild("Owner")
        if owner and tostring(owner.Value) == lp.Name then
            local num = tonumber(hive.Name:match("%d+"))
            if num and HIVE_POSITIONS[num] then
                return HIVE_POSITIONS[num]
            end
        end
    end
    return nil
end

local function scanHive()
    local result = {}
    local honeycombs = workspace:FindFirstChild("Honeycombs")
    if not honeycombs then return result end

    local myHive = nil
    for _, hive in pairs(honeycombs:GetChildren()) do
        local owner = hive:FindFirstChild("Owner")
        if owner and tostring(owner.Value) == lp.Name then
            myHive = hive
            break
        end
    end
    if not myHive then return result end

    local cells = myHive:FindFirstChild("Cells") or myHive:FindFirstChild("Slots") or myHive

    local bee_list = {}
    for _, slot in pairs(cells:GetChildren()) do
        local x, y = slot.Name:match("C(%d+),(%d+)")
        x = tonumber(x) or 0
        y = tonumber(y) or 0
        for _, obj in pairs(slot:GetDescendants()) do
            if obj:IsA("StringValue") then
                local val = tostring(obj.Value)
                for _, key in pairs(beeKeywords) do
                    if val:find(key) then
                        table.insert(bee_list, {x, y, val})
                        break
                    end
                end
            end
        end
    end

    local advancedSlots = {}
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
                advancedSlots[cell.Name] = isGifted
            end
        end)
    end

    for _, t in ipairs(bee_list) do
        local slotName = "C" .. t[1] .. "," .. t[2]
        result[slotName] = {
            name = t[3],
            gifted = advancedSlots[slotName] or false
        }
    end

    return result
end

local function run(comp, dlog, flyTo)
    local rawBase = "https://raw.githubusercontent.com/commoncrisp/a/main/"

    local beeAbilities = loadstring(game:HttpGet(rawBase .. "data/bee_abilities.lua"))()
    local evaluate = loadstring(game:HttpGet(rawBase .. "modules/hive_adjuster/evaluator.lua"))()
    local runRJLoop = loadstring(game:HttpGet(rawBase .. "modules/hive_adjuster/rj_loop.lua"))()

    dlog("Scanning hive...")
    local currentHive = scanHive()
    local beeCount = 0
    for _ in pairs(currentHive) do beeCount = beeCount + 1 end
    dlog("Found " .. tostring(beeCount) .. " bees")

    local evalResult = evaluate(currentHive, comp, beeAbilities)
    dlog("Initial evaluation:")
    dlog(evalResult.summary)

    if #evalResult.unsatisfied == 0 then
        dlog("Hive already matches comp! Nothing to do.")
        return
    end

    -- fly to hive
    dlog("Finding hive position...")
    local hivePos = getHivePosition()
    if not hivePos then
        dlog("ERROR: Could not find hive position!")
        return
    end
    dlog("Flying to hive...")
    local arrived = flyTo(hivePos, dlog)
    if not arrived then
        dlog("ERROR: Could not reach hive!")
        return
    end

    local loopResult = runRJLoop(currentHive, comp, beeAbilities, evaluate, scanHive, dlog)

    dlog("Done! Used " .. loopResult.rjUsed .. " RJ")
    dlog("Final hive evaluation:")
    local finalEval = evaluate(loopResult.finalHive, comp, beeAbilities)
    dlog(finalEval.summary)
end

return run