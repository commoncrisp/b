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

-- ── Material keys (display name → Eggs cache key) ────────────────────────────
local MATERIAL_KEYS = {
    -- Misc
    ["Snowflake"]          = "Snowflake",
    ["Ticket"]             = "Ticket",
    ["Gumdrop"]            = "Gumdrops",
    ["Coconut"]            = "Coconut",
    ["Stinger"]            = "Stinger",
    ["Honeysuckle"]        = "Honeysuckle",
    ["Whirligig"]          = "Whirligig",
    ["Jelly Beans"]        = "JellyBeans",
    ["Red Extract"]        = "RedExtract",
    ["Blue Extract"]       = "BlueExtract",
    ["Glitter"]            = "Glitter",
    ["Glue"]               = "Glue",
    ["Oil"]                = "Oil",
    ["Enzymes"]            = "Enzymes",
    ["Tropical Drink"]     = "TropicalDrink",
    ["Purple Potion"]      = "PurplePotion",
    ["Super Smoothie"]     = "SuperSmoothie",
    ["Marshmallow Bee"]    = "MarshmallowBee",
    ["Magic Bean"]         = "MagicBean",
    ["Festive Bean"]       = "FestiveBean",
    ["Cloud Vial"]         = "CloudVial",
    ["Box-O-Frogs"]        = "Box-O-Frogs",
    ["Translator"]         = "Translator",
    ["Present"]            = "Present",
    ["Spirit Petal"]       = "SpiritPetal",
    ["Bloom Shaker"]       = "BloomShaker",
    -- Dice
    ["Field Dice"]         = "FieldDice",
    ["Smooth Dice"]        = "SmoothDice",
    ["Loaded Dice"]        = "LoadedDice",
    -- Challenge Passes
    ["Ant Pass"]           = "AntPass",
    ["Robo Pass"]          = "RoboPass",
    -- Bee Treats
    ["Treat"]              = "Treat",
    ["Atomic Treat"]       = "AtomicTreat",
    ["Star Treat"]         = "StarTreat",
    -- Nectar Vials
    ["Comforting Vial"]    = "ComfortingVial",
    ["Invigorating Vial"]  = "InvigoratingVial",
    ["Motivating Vial"]    = "MotivatingVial",
    ["Refreshing Vial"]    = "RefreshingVial",
    ["Satisfying Vial"]    = "SatisfyingVial",
    ["Nectar Shower Vial"] = "NectarShowerVial",
    -- Balloons
    ["Pink Balloon"]       = "PinkBalloon",
    ["Red Balloon"]        = "RedBalloon",
    ["White Balloon"]      = "WhiteBalloon",
    ["Black Balloon"]      = "BlackBalloon",
    -- Wax
    ["Soft Wax"]           = "SoftWax",
    ["Hard Wax"]           = "HardWax",
    ["Caustic Wax"]        = "CausticWax",
    ["Debug Wax"]          = "DebugWax",
    ["Swirled Wax"]        = "SwirledWax",
    ["Turpentine"]         = "Turpentine",
    -- Eggs / Jelly
    ["Basic Egg"]          = "Basic",
    ["Silver Egg"]         = "Silver",
    ["Gifted Silver Egg"]  = "GiftedSilver",
    ["Gold Egg"]           = "Gold",
    ["Gifted Gold Egg"]    = "GiftedGold",
    ["Diamond Egg"]        = "Diamond",
    ["Gifted Diamond Egg"] = "GiftedDiamond",
    ["Mythic Egg"]         = "Mythic",
    ["Gifted Mythic Egg"]  = "GiftedMythic",
    ["Star Egg"]           = "Star",
    ["Royal Jelly"]        = "RoyalJelly",
    ["Star Jelly"]         = "StarJelly",
    -- Other
    ["Neonberry"]          = "Neonberry",
    ["Bitterberry"]        = "Bitterberry",
    ["Blueberry"]          = "Blueberry",
    ["Strawberry"]         = "Strawberry",
    ["Pineapple"]          = "Pineapple",
    ["Sunflower Seed"]     = "SunflowerSeed",
    ["Moon Charm"]         = "MoonCharm",
    ["Micro-Converter"]    = "Micro-Converter",
    ["Gingerbread Bear"]   = "GingerbreadBear",
}

-- ── Tool tier lists (index = tier, higher = better) ───────────────────────────
local TOOL_TIERS = {
    "Scooper", "Rake", "Clippers", "Magnet", "Vacuum", "Super-Scooper",
    "Pulsar", "Electro-Magnet", "Scissors", "Honey Dipper", "Bubble Wand",
    "Scythe", "Sticker-Seeker", "Golden Rake", "Spark Staff",
    "Porcelain Dipper", "Petal Wand", "Tide Popper", "Dark Scythe", "Gummyballer",
}
local BAG_TIERS = {
    "Pouch", "Jar", "Backpack", "Canister", "Mega-Jug", "Compressor",
    "Elite Barrel", "Port-O-Hive", "Blue Port-O-Hive", "Red Port-O-Hive",
    "Porcelain Port-O-Hive", "Coconut Canister",
}
local TOOL_TIER_MAP, BAG_TIER_MAP = {}, {}
for i, v in ipairs(TOOL_TIERS) do TOOL_TIER_MAP[v] = i end
for i, v in ipairs(BAG_TIERS)  do BAG_TIER_MAP[v]  = i end

-- ── hasTool: true if player owns this tool/bag OR any higher-tier one ─────────
local function hasTool(name)
    local toolTier = TOOL_TIER_MAP[name]
    local bagTier  = BAG_TIER_MAP[name]

    if toolTier then
        -- check Collectors cache
        local collectors = cacheGet({"Collectors"})
        if type(collectors) == "table" then
            for _, v in pairs(collectors) do
                if (TOOL_TIER_MAP[v] or 0) >= toolTier then return true end
            end
        end
        -- fallback: check character/backpack instances
        pcall(function()
            for _, v in pairs(lp.Backpack:GetChildren()) do
                if (TOOL_TIER_MAP[v.Name] or 0) >= toolTier then return true end
            end
        end)
        pcall(function()
            if lp.Character then
                for _, v in pairs(lp.Character:GetChildren()) do
                    if (TOOL_TIER_MAP[v.Name] or 0) >= toolTier then return true end
                end
            end
        end)
        return false
    elseif bagTier then
        local backpacks = cacheGet({"Backpacks"})
        if type(backpacks) == "table" then
            for _, v in pairs(backpacks) do
                if (BAG_TIER_MAP[v] or 0) >= bagTier then return true end
            end
        end
        return false
    end

    return false
end

-- ── hasItem: true if player owns the accessory ───────────────────────────────
local function hasItem(name)
    local acc = cacheGet({"Accessories"})
    if type(acc) == "table" then
        for _, v in pairs(acc) do
            if tostring(v) == name then return true end
        end
    end
    return false
end

-- ── getMaterial: returns count from Eggs cache ───────────────────────────────
local function getMaterial(name)
    local key = MATERIAL_KEYS[name]
    if not key then return 0 end
    return cacheGet({"Eggs", key}) or 0
end

-- ── getHoney ──────────────────────────────────────────────────────────────────
local function getHoney()
    return cacheGet({"Honey"}) or 0
end

-- ── selfTest ──────────────────────────────────────────────────────────────────
local function selfTest(dlog)
    local lines = {}
    local function out(msg)
        table.insert(lines, msg)
        if dlog then dlog(msg) end
    end

    out("Cache: " .. (cache and "OK" or "MISSING"))
    out("Honey: " .. getHoney())

    out("-- TOOLS --")
    for _, name in ipairs(TOOL_TIERS) do
        if hasTool(name) then out("  HAS: " .. name) end
    end
    out("-- BAGS --")
    for _, name in ipairs(BAG_TIERS) do
        if hasTool(name) then out("  HAS: " .. name) end
    end
    out("-- ITEMS --")
    local itemList = {
        "Helmet","Propeller Hat","Beekeeper's Mask","Honey Mask","Fire Mask",
        "Bubble Mask","Gummy Mask","Demon Mask","Diamond Mask",
        "Brave Guard","Hasty Guard","Bomber Guard","Looker Guard",
        "Blue Guard","Elite Blue Guard","Bucko Guard",
        "Red Guard","Elite Red Guard","Riley Guard","Cobalt Guard","Crimson Guard",
        "Belt Pocket","Belt Bag","Mondo Belt Bag","Honeycomb Belt","Petal Belt","Coconut Belt",
        "Basic Boots","Hiking Boots","Beekeeper's Boots","Coconut Clogs","Gummy Boots",
        "Parachute","Glider",
    }
    for _, name in ipairs(itemList) do
        if hasItem(name) then out("  HAS: " .. name) end
    end
    out("-- MATERIALS --")
    for displayName in pairs(MATERIAL_KEYS) do
        local count = getMaterial(displayName)
        if count and count > 0 then out("  " .. displayName .. ": " .. count) end
    end
end

-- ── Cache explorer ────────────────────────────────────────────────────────────
local function dumpCache(dlog)
    if not cache then dlog("[Cache] cache is nil!"); return end
    dlog("[Cache] Dumping top-level keys...")
    local ok, data = pcall(function() return cache:Get({}) end)
    if not ok or type(data) ~= "table" then
        dlog("[Cache] Get({}) failed: " .. tostring(data))
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
