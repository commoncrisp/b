local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local lp      = Players.LocalPlayer

local cache = nil
pcall(function() cache = require(RS:WaitForChild("ClientStatCache", 5)) end)

local function cacheGet(path)
    if not cache then return nil end
    local ok, v = pcall(function() return cache:Get(path) end)
    return ok and v or nil
end

local MATERIAL_KEYS = {
    ["Royal Jelly"]       = "RoyalJelly",
    ["Glitter"]           = "Glitter",
    ["Oil"]               = "Oil",
    ["Blue Extract"]      = "BlueExtract",
    ["Red Extract"]       = "RedExtract",
    ["Blueberry"]         = "Blueberry",
    ["Strawberry"]        = "Strawberry",
    ["Pineapple"]         = "Pineapple",
    ["Coconut"]           = "Coconut",
    ["Tropical Drink"]    = "TropicalDrink",
    ["Sunflower Seed"]    = "SunflowerSeed",
    ["Stinger"]           = "Stinger",
    ["Enzymes"]           = "Enzymes",
    ["Glue"]              = "Glue",
    ["Gumdrops"]          = "Gumdrops",
    ["Treat"]             = "Treat",
    ["Moon Charm"]        = "MoonCharm",
    ["Soft Wax"]          = "SoftWax",
    ["Hard Wax"]          = "HardWax",
    ["Caustic Wax"]       = "CausticWax",
    ["Swirled Wax"]       = "SwirledWax",
    ["Star Jelly"]        = "StarJelly",
    ["Spirit Petal"]      = "SpiritPetal",
    ["Purple Potion"]     = "PurplePotion",
    ["Turpentine"]        = "Turpentine",
    ["Neonberry"]         = "Neonberry",
    ["Micro-Converter"]   = "MicroConverter",
    ["Gold Egg"]          = "GoldEgg",
    ["Diamond Egg"]       = "DiamondEgg",
    ["Comforting Vial"]   = "ComfortingVial",
    ["Refreshing Vial"]   = "RefreshingVial",
    ["Satisfying Vial"]   = "SatisfyingVial",
    ["Invigorating Vial"] = "InvigoratingVial",
    ["Motivating Vial"]   = "MotivatingVial",
}

local function hasTool(name)
    local found = false
    pcall(function()
        for _, v in pairs(lp.Backpack:GetChildren()) do
            if v.Name == name then found = true end
        end
    end)
    pcall(function()
        if lp.Character then
            for _, v in pairs(lp.Character:GetChildren()) do
                if v.Name == name then found = true end
            end
        end
    end)
    return found
end

local function hasItem(name)
    local acc = cacheGet({"Accessories"})
    if type(acc) == "table" then
        for _, v in pairs(acc) do
            if tostring(v) == name then return true end
        end
    end
    return false
end

local function getMaterial(name)
    local key = MATERIAL_KEYS[name]
    if not key then return 0 end
    -- try top-level, then under Eggs, then under Materials
    return cacheGet({key})
        or cacheGet({"Eggs", key})
        or cacheGet({"Materials", key})
        or 0
end

local function getHoney()
    return cacheGet({"Honey"}) or 0
end

local function selfTest(dlog)
    local lines = {}
    local function out(msg)
        table.insert(lines, msg)
        if dlog then dlog (message) end
    end

    out("Cache: " .. (cache and "OK" or "MISSING"))
    out("Honey: " ..getHoney())

    out("-- TOOLS --")
    for _, name in ipairs({
        "Scooper","Rake","Clippers","Magnet","Empty","Super Scooper",
        "Pulsar","Electro-Magnet","Scissors","Honey Dipper","Bubble Wand",
        "Scythe","Sticker-Seeker","Golden Rake","Spark Staff",
        "Porcelain Dipper","Petal Wand","Tide Popper","Dark Scythe","Gummy Balls"
    }) do
        if hasTool(name) then out("  HAS: " .. name) end
    end

    out("-- BAGS --")
    for _, name in ipairs({
        "Pouch","Jar","Backpack","Canister","Mega-Jug","Compressor",
        "Elite Barrel","Port-O-Hive","Blue Port-O-Hive","Red Port-O-Hive",
        "Porcelain Port-O-Hive","Coconut Canister"
    }) do
        if hasTool(name) then out("  HAS: " .. name) end
    end

    out("-- ITEMS --")
    for _, name in ipairs({
        "Helmet","Propeller Hat","Beekeeper's Mask","Honey Mask","Fire Mask",
        "Bubble Mask","Gummy Mask","Demon Mask","Diamond Mask",
        "Brave Guard","Hasty Guard","Bomber Guard","Looker Guard",
        "Blue Guard","Elite Blue Guard","Bucko Guard",
        "Red Guard","Elite Red Guard","Riley Guard","Cobalt Guard","Crimson Guard",
        "Belt Pocket","Belt Bag","Mondo Belt Bag","Honeycomb Belt","Petal Belt","Coconut Belt",
        "Basic Boots","Hiking Boots","Beekeeper's Boots","Coconut Clogs","Gummy Boots",
        "Parachute","Glider"
    }) do
        if hasItem(name) then out("  HAS: " .. name) end
    end

    out("-- MATERIALS --")
    for displayName in pairs(MATERIAL_KEYS) do
        local count = getMaterial(displayName)
        if count > 0 then out("  " .. displayName .. ": " .. count) end
    end

    -- show results in a GUI
    for _, v in pairs(lp.PlayerGui:GetChildren()) do
        if v.Name == "DetectionTest" then v:Destroy() end
    end
    local sg = Instance.new("ScreenGui")
    sg.Name = "DetectionTest"
    sg.ResetOnSpawn = false
    sg.Parent = lp.PlayerGui
    local frame = Instance.new("Frame", sg)
    frame.Size = UDim2.new(0, 400, 0, 420)
    frame.Position = UDim2.new(0.5, -200, 0.5, -210)
    frame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    local closeBtn = Instance.new("TextButton", frame)
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -33, 0, 3)
    closeBtn.Text = "X"
    closeBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.BorderSizePixel = 0
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
    closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)
    local scroll = Instance.new("ScrollingFrame", frame)
    scroll.Size = UDim2.new(1, -10, 1, -42)
    scroll.Position = UDim2.new(0, 5, 0, 38)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 4
    local layout = Instance.new("UIListLayout", scroll)
    layout.Padding = UDim.new(0, 1)
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
    end)
    for i, line in ipairs(lines) do
        local lbl = Instance.new("TextLabel", scroll)
        lbl.Size = UDim2.new(1, -10, 0, 14)
        lbl.BackgroundTransparency = 1
        lbl.Text = line
        lbl.Font = Enum.Font.Code
        lbl.TextSize = 11
        lbl.TextColor3 = line:find("HAS:") and Color3.fromRGB(80, 220, 80)
            or line:find("^--") and Color3.fromRGB(80, 200, 220)
            or Color3.fromRGB(180, 180, 180)
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.LayoutOrder = i
        Instance.new("UIPadding", lbl).PaddingLeft = UDim.new(0, 4)
    end
end

-- ── Cache explorer ────────────────────────────────────────────────────────────
local function dumpCache(dlog)
    if not cache then dlog("[Cache] cache is nil!"); return end
    dlog("[Cache] Dumping top-level keys...")
    local ok, data = pcall(function() return cache:Get({}) end)
    if not ok or type(data) ~= "table" then
        dlog("[Cache] Get({}) failed or not a table: " .. tostring(data))
        -- try some known paths manually
        local paths = {
            {"Honey"}, {"Inv"}, {"Stats"}, {"Items"}, {"Materials"},
            {"Eggs"}, {"Backpack"}, {"Accessories"},
        }
        for _, p in ipairs(paths) do
            local v = cacheGet(p)
            dlog("[Cache] " .. table.concat(p,"/") .. " = " .. tostring(v):sub(1,80))
        end
        return
    end
    for k, v in pairs(data) do
        local t = type(v)
        if t == "table" then
            dlog("[Cache] [" .. tostring(k) .. "] = {table}")
            for k2, v2 in pairs(v) do
                dlog("[Cache]   [" .. tostring(k2) .. "] = " .. tostring(v2):sub(1,60))
            end
        else
            dlog("[Cache] [" .. tostring(k) .. "] = " .. tostring(v):sub(1,80))
        end
    end
end

return {
    hasTool       = hasTool,
    hasItem       = hasItem,
    getMaterial   = getMaterial,
    getHoney      = getHoney,
    selfTest      = selfTest,
    dumpCache     = dumpCache,
    MATERIAL_KEYS = MATERIAL_KEYS,
}
