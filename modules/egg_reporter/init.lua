-- modules/egg_reporter/init.lua
-- Snapshots material counts at session start then reports gains every 5 mins to Discord.
-- Survives server hops by saving session state to a file.

local HttpService = game:GetService("HttpService")
local RS          = game:GetService("ReplicatedStorage")

local WEBHOOK_URL     = "https://discord.com/api/webhooks/1479333945169416266/HEMzsjq6LvBpqUEKRsHGsU_b06hjNt7Kwf9e7C1AiWkp35VPEQmg425uusTxY6aihfPu"
local REPORT_INTERVAL = 300 -- 5 minutes in seconds
local SESSION_FILE    = "egg_reporter_session.json"

local MATERIAL_KEYS = {
    -- Misc
    ["Snowflake"]          = "Snowflake",
    ["Ticket"]             = "Ticket",
    ["Gumdrop"]            = "Gumdrop",
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

-- ── Cache ─────────────────────────────────────────────────────────────────────
local cache = nil
pcall(function() cache = require(RS:WaitForChild("ClientStatCache", 5)) end)

local function getCount(cacheKey)
    if not cache then return 0 end
    local ok, v = pcall(function() return cache:Get({"Eggs", cacheKey}) end)
    return (ok and tonumber(v)) or 0
end

local function snapshot()
    local counts = {}
    for displayName, cacheKey in pairs(MATERIAL_KEYS) do
        counts[displayName] = getCount(cacheKey)
    end
    return counts
end

-- modules/egg_reporter/init.lua
local function loadSession()
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(SESSION_FILE))
    end)
    if ok and type(data) == "table" then return data end
    return nil
end

local function saveSession(data)
    pcall(writefile, SESSION_FILE, HttpService:JSONEncode(data))
end

-- ── Webhook ───────────────────────────────────────────────────────────────────
local function sendWebhook(content)
    local reqFn = request or http_request or (syn and syn.request) or (fluxus and fluxus.request)
    if not reqFn then return end
    -- split into 1900 char chunks just in case
    while #content > 1900 do
        local cut = content:sub(1, 1900):find("\n[^\n]*$") or 1900
        pcall(function()
            reqFn({
                Url     = WEBHOOK_URL,
                Method  = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body    = HttpService:JSONEncode({ content = content:sub(1, cut) }),
            })
        end)
        content = content:sub(cut + 1)
        task.wait(0.5)
    end
    pcall(function()
        reqFn({
            Url     = WEBHOOK_URL,
            Method  = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body    = HttpService:JSONEncode({ content = content }),
        })
    end)
end

-- ── Main ──────────────────────────────────────────────────────────────────────
local _stop = false

local function run(dlog)
    dlog = dlog or function(msg) print("[EggReporter] " .. msg) end
    _stop = false

    if not cache then
        dlog("ERROR: ClientStatCache not found — reporter disabled.")
        return
    end

    local nowTime    = os.time()
    local session    = loadSession()
    local sessionStart, lastReport, startCounts

    if session then
        dlog("Resuming session from file...")
        sessionStart = session.sessionStart
        lastReport   = session.lastReport
        startCounts  = session.startCounts
    else
        dlog("Starting new session, snapshotting counts...")
        sessionStart = nowTime
        lastReport   = nowTime
        startCounts  = snapshot()
        saveSession({ sessionStart = sessionStart, lastReport = lastReport, startCounts = startCounts })
    end

    dlog("Reporter running — reporting every " .. (REPORT_INTERVAL / 60) .. " mins.")
    dlog("Next report in: " .. math.max(0, math.floor(timeLeft)) .. "s")

    while not _stop do
        task.wait(5)
        if _stop then break end

        local currentTime = os.time()
        local timeLeft = REPORT_INTERVAL - (currentTime - lastReport)
        

        if currentTime - lastReport >= REPORT_INTERVAL then
            local current     = snapshot()
            local lines       = {}
            local totalGained = 0

            for displayName in pairs(MATERIAL_KEYS) do
                local gained = (current[displayName] or 0) - (startCounts[displayName] or 0)
                if gained > 0 then
                    table.insert(lines, "**" .. displayName .. "**: +" .. gained
                        .. " (total: " .. (current[displayName] or 0) .. ")")
                    totalGained = totalGained + gained
                end
            end

            local elapsed = math.floor((currentTime - sessionStart) / 60)
            local msg

            if totalGained == 0 then
                msg = "🐝 **Material Report** | Session: " .. elapsed .. " mins\nNo materials gained this session."
            else
                table.sort(lines)
                msg = "🐝 **Material Report** | Session: " .. elapsed .. " mins\n" .. table.concat(lines, "\n")
            end

            dlog("Sending report to Discord...")
            sendWebhook(msg)
            dlog("Report sent.")

            lastReport = currentTime
            saveSession({ sessionStart = sessionStart, lastReport = lastReport, startCounts = startCounts })
        end
    end

    dlog("Reporter stopped.")
end

local function stop()
    _stop = true
end

return { run = run, stop = stop }
