-- modules/gifted_farmer/init.lua
-- Automatically farms a hive with 40 unique gifted bee types.
--
-- Phase 1 : Enable RollToGifted, run Atlas until a gifted Basic Bee appears.
-- Phase 2 : RJ every unprotected slot until 1 gifted of every Common → Legendary
--           bee type is in the hive.
--           Protected (never RJ'd):
--             • any slot whose bee type has exactly 1 gifted copy in the hive
--             • any mythic slot whose bee type has only 1 copy (gifted or not)
--             • any event bee slot (canRJ = false anyway)
-- Phase 3 : Apply 8 star treats to each event bee, then 1 star treat to each
--           unique-gifted mythic.
-- Phase 4 : Apply 2 star eggs to any 2 slots that are not unique gifteds.

local RS      = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local lp      = Players.LocalPlayer

-- ── Config ────────────────────────────────────────────────────────────────────
local ATLAS_URL     = "https://raw.githubusercontent.com/Chris12089/atlasbss/main/script.lua"
local POLL_INTERVAL = 10    -- seconds between hive checks during atlas phase
local RJ_WAIT       = 0.5   -- seconds between RJ casts
local TREAT_WAIT    = 0.4   -- seconds between star treat casts

-- ── Bee database (inlined so the module is self-contained) ────────────────────
local BEE_DATA = {
    -- Common
    BasicBee     = { rarity = "common",    canRJ = true  },
    -- Rare
    BomberBee    = { rarity = "rare",      canRJ = true  },
    BraveBee     = { rarity = "rare",      canRJ = true  },
    BumbleBee    = { rarity = "rare",      canRJ = true  },
    CoolBee      = { rarity = "rare",      canRJ = true  },
    HastyBee     = { rarity = "rare",      canRJ = true  },
    LookerBee    = { rarity = "rare",      canRJ = true  },
    RadBee       = { rarity = "rare",      canRJ = true  },
    RascalBee    = { rarity = "rare",      canRJ = true  },
    StubbornBee  = { rarity = "rare",      canRJ = true  },
    -- Epic
    BubbleBee    = { rarity = "epic",      canRJ = true  },
    BuckoBee     = { rarity = "epic",      canRJ = true  },
    CommanderBee = { rarity = "epic",      canRJ = true  },
    DemoBee      = { rarity = "epic",      canRJ = true  },
    ExhaustedBee = { rarity = "epic",      canRJ = true  },
    FireBee      = { rarity = "epic",      canRJ = true  },
    FrostyBee    = { rarity = "epic",      canRJ = true  },
    HoneyBee     = { rarity = "epic",      canRJ = true  },
    RageBee      = { rarity = "epic",      canRJ = true  },
    RileyBee     = { rarity = "epic",      canRJ = true  },
    ShockedBee   = { rarity = "epic",      canRJ = true  },
    -- Legendary
    BabyBee      = { rarity = "legendary", canRJ = true  },
    CarpenterBee = { rarity = "legendary", canRJ = true  },
    DemonBee     = { rarity = "legendary", canRJ = true  },
    DiamondBee   = { rarity = "legendary", canRJ = true  },
    LionBee      = { rarity = "legendary", canRJ = true  },
    MusicBee     = { rarity = "legendary", canRJ = true  },
    NinjaBee     = { rarity = "legendary", canRJ = true  },
    ShyBee       = { rarity = "legendary", canRJ = true  },
    -- Mythic
    BuoyantBee   = { rarity = "mythic",    canRJ = true  },
    FuzzyBee     = { rarity = "mythic",    canRJ = true  },
    PreciseBee   = { rarity = "mythic",    canRJ = true  },
    SpicyBee     = { rarity = "mythic",    canRJ = true  },
    TadpoleBee   = { rarity = "mythic",    canRJ = true  },
    VectorBee    = { rarity = "mythic",    canRJ = true  },
    -- Event (canRJ = false — gifted via star treats instead)
    BearBee      = { rarity = "event",     canRJ = false },
    CobaltBee    = { rarity = "event",     canRJ = false },
    CrimsonBee   = { rarity = "event",     canRJ = false },
    DigitalBee   = { rarity = "event",     canRJ = false },
    FestiveBee   = { rarity = "event",     canRJ = false },
    GummyBee     = { rarity = "event",     canRJ = false },
    PhotonBee    = { rarity = "event",     canRJ = false },
    PuppyBee     = { rarity = "event",     canRJ = false },
    TabbyBee     = { rarity = "event",     canRJ = false },
    ViciousBee   = { rarity = "event",     canRJ = false },
    WindyBee     = { rarity = "event",     canRJ = false },
}

-- Bees that must each have exactly 1 gifted copy to finish the RJ phase
local TARGET_RARITIES = { common = true, rare = true, epic = true, legendary = true }

-- All known bee name strings (used for value scanning)
local BEE_KEYWORDS = {}
for name in pairs(BEE_DATA) do
    table.insert(BEE_KEYWORDS, name)
end

-- ── Logging ───────────────────────────────────────────────────────────────────
local _dlog = function(msg)
    print("[GiftedFarmer] " .. tostring(msg))
end

local function log(msg)
    _dlog("[GiftedFarmer] " .. tostring(msg))
end

-- ── Hive scanner ──────────────────────────────────────────────────────────────
-- Returns: table keyed by slotName →
--   { name=string, gifted=bool, slot=string, x=number|nil, y=number|nil }
local function scanHive()
    local result = {}

    local honeycombs = workspace:FindFirstChild("Honeycombs")
    if not honeycombs then log("ERROR: No Honeycombs folder in workspace") return result end

    local myHive = nil
    for _, h in pairs(honeycombs:GetChildren()) do
        local owner = h:FindFirstChild("Owner")
        if owner and tostring(owner.Value) == lp.Name then
            myHive = h
            break
        end
    end
    if not myHive then log("ERROR: Could not find player hive") return result end

    local cells = myHive:FindFirstChild("Cells")
               or myHive:FindFirstChild("Slots")
               or myHive

    for _, cell in pairs(cells:GetChildren()) do
        pcall(function()
            local beeName  = nil
            local isGifted = false

            -- attribute-based gifted check (fastest)
            if cell:GetAttribute("Gifted") == true
            or cell:GetAttribute("IsGifted") == true then
                isGifted = true
            end

            -- descendant scan for bee name + fallback gifted flags
            for _, obj in pairs(cell:GetDescendants()) do
                -- bee name search
                if not beeName and obj:IsA("ValueBase") then
                    local v = tostring(obj.Value)
                    for _, kw in ipairs(BEE_KEYWORDS) do
                        if v:find(kw, 1, true) then
                            beeName = kw
                            break
                        end
                    end
                end

                -- gifted from descendant attributes
                if obj:GetAttribute("Gifted") == true
                or obj:GetAttribute("IsGifted") == true then
                    isGifted = true
                end

                -- gifted from descendant name/value
                local nm = obj.Name:lower()
                if nm:find("gifted") then
                    if obj:IsA("BoolValue") and obj.Value == true then
                        isGifted = true
                    elseif tostring(obj.Value):lower():find("true") then
                        isGifted = true
                    end
                end
            end

            if beeName then
                -- parse C<x>,<y> slot name
                local sx, sy = cell.Name:match("C(%d+),(%d+)")
                result[cell.Name] = {
                    name   = beeName,
                    gifted = isGifted,
                    slot   = cell.Name,
                    x      = tonumber(sx),
                    y      = tonumber(sy),
                }
            end
        end)
    end

    return result
end

-- ── Hive analysis ─────────────────────────────────────────────────────────────
-- giftedCounts[beeName] = how many gifted of that type exist
-- mythicCounts[beeName] = how many of that mythic type exist (gifted or not)
local function analyzeHive(hive)
    local giftedCounts = {}
    local mythicCounts = {}
    local eventSlots   = {}

    for _, slot in pairs(hive) do
        local data = BEE_DATA[slot.name]
        if not data then continue end

        if slot.gifted then
            giftedCounts[slot.name] = (giftedCounts[slot.name] or 0) + 1
        end
        if data.rarity == "mythic" then
            mythicCounts[slot.name] = (mythicCounts[slot.name] or 0) + 1
        end
        if data.rarity == "event" then
            table.insert(eventSlots, slot)
        end
    end

    return giftedCounts, mythicCounts, eventSlots
end

-- Returns true + nil when all target bees have a gifted copy.
-- Returns false + missing bee name otherwise.
local function allTargetsGifted(giftedCounts)
    for beeName, data in pairs(BEE_DATA) do
        if TARGET_RARITIES[data.rarity] then
            if not giftedCounts[beeName] or giftedCounts[beeName] == 0 then
                return false, beeName
            end
        end
    end
    return true, nil
end

-- ── Remote helpers ────────────────────────────────────────────────────────────
local Events = RS:WaitForChild("Events")

local function useRJ(slot)
    if not slot.x or not slot.y then
        log("WARN: slot " .. tostring(slot.slot) .. " has no x/y — skipping RJ")
        return false
    end
    local ok, err = pcall(function()
        Events:WaitForChild("ConstructHiveCellFromEgg"):InvokeServer(
            slot.x, slot.y, "RoyalJelly", 1, false
        )
    end)
    if not ok then log("RJ error on " .. slot.slot .. ": " .. tostring(err)) end
    return ok
end

-- Star treats are applied with BeeStarEvent (1 treat per call).
-- If your game uses a different remote, swap it here.
local function useStarTreat(slot)
    if not slot.x or not slot.y then
        log("WARN: slot " .. tostring(slot.slot) .. " has no x/y — skipping treat")
        return false
    end
    local ok, err = pcall(function()
        Events:WaitForChild("BeeStarEvent"):FireServer(slot.x, slot.y)
    end)
    if not ok then log("Star treat error on " .. slot.slot .. ": " .. tostring(err)) end
    return ok
end

-- Star eggs are placed via ConstructHiveCellFromEgg with "Star Egg".
local function useStarEgg(slot)
    if not slot.x or not slot.y then
        log("WARN: slot " .. tostring(slot.slot) .. " has no x/y — skipping egg")
        return false
    end
    local ok, err = pcall(function()
        Events:WaitForChild("ConstructHiveCellFromEgg"):InvokeServer(
            slot.x, slot.y, "Star Egg", 1, false
        )
    end)
    if not ok then log("Star egg error on " .. slot.slot .. ": " .. tostring(err)) end
    return ok
end

-- ── Phase 0 : Enable RollToGifted ────────────────────────────────────────────
local function enableRollToGifted()
    log("Enabling RollToGifted setting...")
    local args = { "RollToGifted", true }
    Events:WaitForChild("PlayerSettingsEvent"):FireServer(unpack(args))
    task.wait(0.5)
    log("RollToGifted enabled.")
end

-- ── Phase 1 : Atlas → gifted Basic Bee ───────────────────────────────────────
local function hasGiftedBasic(hive)
    for _, slot in pairs(hive) do
        if slot.name == "BasicBee" and slot.gifted then
            return true
        end
    end
    return false
end

local _atlasRunning = false

local function launchAtlas()
    if _atlasRunning then return end
    _atlasRunning = true
    task.spawn(function()
        log("Launching Atlas...")
        local ok, err = pcall(function()
            loadstring(game:HttpGet(ATLAS_URL))()
        end)
        if not ok then log("Atlas launch error: " .. tostring(err)) end
        _atlasRunning = false
    end)
end

local function waitForGiftedBasic()
    log("Phase 1: Waiting for a gifted Basic Bee to appear in hive...")

    local hive = scanHive()
    if hasGiftedBasic(hive) then
        log("Gifted Basic Bee already present — skipping Phase 1.")
        return
    end

    launchAtlas()

    while true do
        task.wait(POLL_INTERVAL)
        hive = scanHive()
        if hasGiftedBasic(hive) then
            log("Phase 1 complete: gifted Basic Bee found!")
            return
        end
        log("Still waiting for gifted Basic Bee...")
    end
end

-- ── Phase 2 : RJ phase ────────────────────────────────────────────────────────
-- Keep RJing until every Common→Legendary type has 1 gifted copy.
-- A slot is protected (never RJ'd) when ANY of:
--   1. It is an event bee (canRJ = false)
--   2. It is the only gifted copy of its type in the hive
--   3. It is a mythic bee and there is only 1 of that mythic type in the hive
local function rjPhase()
    log("Phase 2: RJ phase — building gifted Common–Legendary collection...")

    while true do
        local hive = scanHive()
        local giftedCounts, mythicCounts, _ = analyzeHive(hive)

        local done, missing = allTargetsGifted(giftedCounts)
        if done then
            log("Phase 2 complete: all Common→Legendary types are gifted!")
            return
        end
        log("Missing gifted: " .. tostring(missing) .. " (and possibly others)")

        -- Identify a slot to RJ.
        -- Priority ordering: non-gifted before gifted (to avoid destroying
        -- the only gifted copy of a type that we're trying to keep).
        local target      = nil
        local targetScore = -1   -- higher = more preferred

        for _, slot in pairs(hive) do
            local data = BEE_DATA[slot.name]
            if not data then continue end

            -- ── Protection checks ──────────────────────────────────────────
            -- 1. Event bees: never RJ
            if data.rarity == "event" then continue end

            -- 2. Only gifted of this type → protect it
            if slot.gifted and (giftedCounts[slot.name] or 0) == 1 then
                continue
            end

            -- 3. Mythic with only 1 copy in hive → protect it
            if data.rarity == "mythic" and (mythicCounts[slot.name] or 0) == 1 then
                continue
            end
            -- ──────────────────────────────────────────────────────────────

            -- Score: prefer non-gifted bees (score 1) over gifted duplicates (score 0)
            local score = slot.gifted and 0 or 1

            -- Also prefer bees whose type is already satisfied (we have a gifted)
            -- so we RJ the "extra" ones first
            if (giftedCounts[slot.name] or 0) >= 1 then
                score = score + 2   -- definitely a spare — higher priority target
            end

            if score > targetScore then
                target      = slot
                targetScore = score
            end
        end

        if not target then
            log("No eligible slot to RJ — hive may be fully locked. Waiting " .. POLL_INTERVAL .. "s...")
            task.wait(POLL_INTERVAL)
        else
            log("RJing " .. target.slot
                .. " (" .. target.name
                .. (target.gifted and " [gifted]" or "") .. ")")
            useRJ(target)
            task.wait(RJ_WAIT)
        end
    end
end

-- ── Phase 3 : Star treat phase ────────────────────────────────────────────────
-- Apply 8 star treats to each event bee (to gift them).
-- Then apply 1 star treat to each unique-gifted mythic bee.
local function starTreatPhase()
    log("Phase 3: Star treat phase...")

    -- Round 1: event bees (8 treats each)
    local hive = scanHive()
    for _, slot in pairs(hive) do
        local data = BEE_DATA[slot.name]
        if data and data.rarity == "event" then
            log("Applying 8 star treats to " .. slot.name .. " @ " .. slot.slot)
            for i = 1, 1 do
                useStarTreat(slot)
                task.wait(TREAT_WAIT)
            end
        end
    end

    -- Round 2: one-of-a-kind gifted mythics (1 treat each)
    hive = scanHive()
    local giftedCounts, mythicCounts, _ = analyzeHive(hive)

    for _, slot in pairs(hive) do
        local data = BEE_DATA[slot.name]
        if data and data.rarity == "mythic"
           and slot.gifted
           and (giftedCounts[slot.name] or 0) == 1 then
            log("Applying 1 star treat to gifted " .. slot.name .. " @ " .. slot.slot)
            useStarTreat(slot)
            task.wait(TREAT_WAIT)
        end
    end

    log("Phase 3 complete.")
end

-- ── Phase 4 : Star egg phase ──────────────────────────────────────────────────
-- Use 2 star eggs on slots that are not unique gifteds.
local function starEggPhase()
    log("Phase 4: Star egg phase — placing 2 star eggs...")

    local hive = scanHive()
    local giftedCounts, _, _ = analyzeHive(hive)

    local placed = 0
    for _, slot in pairs(hive) do
        if placed >= 2 then break end

        local data = BEE_DATA[slot.name]
        if not data then continue end

        -- Skip event bees (just treated) and unique gifteds
        if data.rarity == "event" then continue end
        if slot.gifted and (giftedCounts[slot.name] or 0) == 1 then continue end

        log("Using star egg on " .. slot.slot .. " (" .. slot.name .. ")")
        useStarEgg(slot)
        task.wait(0.5)
        placed = placed + 1
    end

    log("Phase 4 complete. Placed " .. placed .. " star egg(s).")
end

-- ── Entry point ───────────────────────────────────────────────────────────────
local function run(dlog)
    if dlog then _dlog = dlog end

    log("=== Gifted Farmer starting ===")

    enableRollToGifted()
    waitForGiftedBasic()
    rjPhase()
    starTreatPhase()
    starEggPhase()

    log("=== Gifted Farmer complete! ===")
end

return { run = run }
