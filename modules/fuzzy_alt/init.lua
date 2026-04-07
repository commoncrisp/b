local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local lp = Players.LocalPlayer


-- ── Constants ─────────────────────────────────────────────────────────
local RAW_BASE         = "https://raw.githubusercontent.com/commoncrisp/b/main/"
local ATLAS_URL        = "https://raw.githubusercontent.com/Chris12089/atlasbss/main/script.lua"
local ATLAS_CONFIG_SRC   = "atlas/1.json"
local ATLAS_CONFIG_DST   = "Preset 1.json"
local ATLAS_CONFIG_SRC_2 = "atlas/2.json"
local ATLAS_CONFIG_DIAMOND_MASK_MATS = "atlas/diamond mats.json"
local ATLAS_CONFIG_DIAMOND_MASK_MATS_VIAL = "atlas/diamond mats vial.json"
local ATLAS_CONFIG_DIAMOND_MASK_HONEY = "atlas/diamond honey.json"
local ATLAS_CONFIG_DST_2 = "Preset 2.json"
local PROGRESS_FILE    = "bss_fuzzyalt_progress_" .. lp.Name .. ".json"
local HIVE_FULL_SIZE   = 25
local HIVE_FULL_SIZE_2 = 35
local HIVE_FULL_SIZE_3 = 38
local ATLAS_RUN_MINS   = 60
local POLL_INTERVAL    = 10  -- seconds between hive size checks while Atlas runs
local COMP_NAME        = "4r4b"
local COMP_NAME_2      = "legendary"
local COMP_NAME_3      = "diamond_hive"
local ATLAS_COMP_NAME  = "1"
local HONEY_PER_RJ     = 1000000


-- Part 3: Bubble Mask
local BUBBLE_MASK_GLITTER    = 15
local BUBBLE_MASK_OIL        = 25
local BUBBLE_MASK_BLUEBERRY  = 500
local BUBBLE_MASK_BLUE_EXT   = 50
local ATLAS_RUN_MINS_3       = 120


-- Part 5: Diamond Mask
local DIAMOND_MASK_GLITTER   = 100
local DIAMOND_MASK_OIL       = 150
local DIAMOND_MASK_BLUE_EXT  = 250
local DIAMOND_MASK_EGGS      = 5
local DIAMOND_MASK_COMFORTING_VIAL = 1




-- ── Progress state ────────────────────────────────────────────────────
-- part: 0 = filling hive to 25 slots with Atlas
--       1 = running 4r4b adjuster (+ 1hr Atlas loops until met)
--       2 = filling hive to 35 slots, buying RJ, running legendary adjuster
--       3 = gathering Bubble Mask ingredients
--       4 = Bubble Mask acquired
local progress = {
    part = 0,
    account = lp.Name
}


local function saveProgress()
    pcall(function()
        writefile(PROGRESS_FILE, HttpService:JSONEncode(progress))
    end)
end


local function loadProgress()
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(PROGRESS_FILE))
    end)
    if ok and data and data.account == lp.Name then
        progress = data
        return true
    end
    return false
end


-- ── Load shared modules ───────────────────────────────────────────────
local debugConsole = loadstring(game:HttpGet(RAW_BASE .. "shared/debug_console.lua"))()
local dlog         = debugConsole.log
local flyTo        = loadstring(game:HttpGet(RAW_BASE .. "shared/fly_to.lua"))()
local beeAbilities = loadstring(game:HttpGet(RAW_BASE .. "data/bee_abilities.lua"))()
local compIO       = loadstring(game:HttpGet(RAW_BASE .. "modules/hive_adjuster/comp_io.lua"))()
local evaluate     = loadstring(game:HttpGet(RAW_BASE .. "modules/hive_adjuster/evaluator.lua"))()
local runRJLoop    = loadstring(game:HttpGet(RAW_BASE .. "modules/hive_adjuster/rj_loop.lua"))()


debugConsole.setVisible(true)


-- ── Helpers ───────────────────────────────────────────────────────────
local beeKeywords = {
    "Basic", "Bomber", "Brave", "Bumble", "Cool", "Hasty", "Looker", "Rad", "Rascal", "Stubborn",
    "Bubble", "Bucko", "Commander", "Demo", "Exhausted", "Fire", "Frosty", "Honey", "Rage", "Riley", "Shocked",
    "Baby", "Carpenter", "Demon", "Diamond", "Lion", "Music", "Ninja", "Shy",
    "Buoyant", "Fuzzy", "Precise", "Spicy", "Tadpole", "Vector",
    "Bear", "Cobalt", "Crimson", "Digital", "Festive", "Gummy", "Photon", "Puppy", "Tabby", "Vicious", "Windy"
}


local HIVE_POSITIONS = {
    [1] = Vector3.new(-3,     5.9, 330.6),
    [2] = Vector3.new(-42.1,  5.9, 330.6),
    [3] = Vector3.new(-76.5,  5.9, 330.6),
    [4] = Vector3.new(-114.5, 5.9, 330.6),
    [5] = Vector3.new(-147.5, 5.9, 330.6),
    [6] = Vector3.new(-185.5, 5.9, 330.6),
}


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


local function getHiveSize()
    local hive = scanHive()
    local count = 0
    for _ in pairs(hive) do count = count + 1 end
    return count
end


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


-- ── Atlas control ─────────────────────────────────────────────────────
local atlasThread = nil


local function writeAtlasConfig(srcFile, dstName)
    if not isfile(srcFile) then
        dlog("WARNING: Atlas config not found at " .. srcFile)
        return false
    end
    local data = readfile(srcFile)
    writefile("Atlas/Bee Swarm Simulator/Configs/" .. dstName, data)
    dlog("Atlas config written: " .. dstName)
    return true
end


local function startAtlas()
    task.wait(5)
    dlog("Starting Atlas (preset 1)...")
    local data = readfile("atlas/1.json")
    writefile("Atlas/Preset 1.json", data)
    pcall(function()
        writefile("Atlas/Preset 1.json", data)
    end)
    if atlasThread then
        -- atlas thread already running, config swap is enough
        dlog("Atlas already running — config swapped to preset 1")
        return
    end
    local ok, content = pcall(function() return game:HttpGet(ATLAS_URL) end)
    if not ok then
        dlog("ERROR: Failed to fetch Atlas: " .. tostring(content))
        return
    end
    atlasThread = task.spawn(function()
        loadstring(content)()
    end)
    dlog("Atlas thread started")
end


local function changeConfig(config)
    local data = readfile(config)
    writefile("Atlas/Preset 1.json", data)
    pcall(function()
        writefile("Atlas/Bee Swarm Simulator/Configs/Preset 1.json", data)
    end)
    dlog("Config swapped to " .. config)
end


-- ── Run adjuster for a given comp ────────────────────────────────────
local function runAdjuster(compName)
    dlog("Loading comp: " .. compName)
    local comp = compIO.load(compName)
    if not comp then
        dlog("ERROR: Could not load comp '" .. compName .. "'!")
        return false
    end


    dlog("Flying to hive...")
    local hivePos = getHivePosition()
    if not hivePos then
        dlog("ERROR: Could not find hive position!")
        return false
    end
    local arrived = flyTo(hivePos, dlog)
    if not arrived then
        dlog("ERROR: Could not reach hive!")
        return false
    end


    dlog("Scanning hive...")
    local currentHive = scanHive()
    local beeCount = 0
    for _ in pairs(currentHive) do beeCount = beeCount + 1 end
    dlog("Found " .. beeCount .. " bees")


    local evalResult = evaluate(currentHive, comp, beeAbilities)
    dlog("Evaluation: " .. evalResult.summary)


    if #evalResult.unsatisfied == 0 then
        dlog("Comp '" .. compName .. "' already satisfied!")
        return true
    end


    local loopResult = runRJLoop(currentHive, comp, beeAbilities, evaluate, scanHive, dlog)
    dlog("RJ loop done. Used " .. loopResult.rjUsed .. " RJ.")


    local finalEval = evaluate(loopResult.finalHive, comp, beeAbilities)
    dlog("Final evaluation: " .. finalEval.summary)


    return #finalEval.unsatisfied == 0
end


-- ── Check if comp requirements are met without running RJ ─────────────
local function compIsSatisfied(compName)
    local comp = compIO.load(compName)
    if not comp then return false end
    local currentHive = scanHive()
    local evalResult = evaluate(currentHive, comp, beeAbilities)
    return #evalResult.unsatisfied == 0
end


-- ── Part 0: Fill hive to 25 slots using Atlas comp "1" ───────────────
local function runPart0()
    dlog("=== PART 0: Filling hive with Atlas (comp: " .. ATLAS_COMP_NAME .. ") ===")


    local size = getHiveSize()
    dlog("Current hive size: " .. size .. "/" .. HIVE_FULL_SIZE)


    if size >= HIVE_FULL_SIZE then
        dlog("Hive already full! Skipping Part 0.")
        return
    end


    changeConfig("atlas/1.json")


    while true do
        task.wait(POLL_INTERVAL)
        local currentSize = getHiveSize()
        dlog("Hive size: " .. currentSize .. "/" .. HIVE_FULL_SIZE)


        if currentSize >= HIVE_FULL_SIZE then
            dlog("Hive is full!")
            changeConfig("atlas/stop.json")
            break
        end
    end


    progress.part = 1
    saveProgress()
    dlog("Part 0 complete. Progress saved.")
end


-- ── Part 1: Run 4r4b, loop with 1hr Atlas breaks until satisfied ──────
local function runPart1()
    dlog("=== PART 1: Running adjuster '" .. COMP_NAME .. "' ===")


    while true do
        dlog("Running hive adjuster...")
        local satisfied = runAdjuster(COMP_NAME)


        if satisfied then
            dlog("=== PART 1 COMPLETE: '" .. COMP_NAME .. "' requirements met! ===")
            progress.part = 2
            saveProgress()
            break
        end


        dlog("Requirements not yet met. Running Atlas for " .. ATLAS_RUN_MINS .. " minutes...")
        changeConfig("atlas/1.json")


        local waitSeconds = ATLAS_RUN_MINS * 60
        local elapsed = 0
        while elapsed < waitSeconds do
            task.wait(POLL_INTERVAL)
            elapsed = elapsed + POLL_INTERVAL
            local remaining = math.floor((waitSeconds - elapsed) / 60)
            dlog("Atlas running... " .. remaining .. "min remaining")
        end


        changeConfig("atlas/stop.json")
        dlog("Atlas run complete. Re-running adjuster...")
    end
end


-- ── Honey / RJ helpers ───────────────────────────────────────────────
local RS = game:GetService("ReplicatedStorage")


local function getHoney()
    local count = 0
    pcall(function()
        local cache = require(RS:WaitForChild("ClientStatCache"))
        count = cache:Get({"Honey"}) or 0
    end)
    return count
end


local function buyMaxRJ(dlog, flyTo)
    local honey = getHoney()
    local rjToBuy = math.floor(honey / HONEY_PER_RJ)
    if rjToBuy < 1 then
        dlog("Not enough honey to buy any RJ (have " .. honey .. ")")
        return 0
    end
    dlog("Honey: " .. honey .. " → buying " .. rjToBuy .. " RJ")
    local buyRJ = loadstring(game:HttpGet(RAW_BASE .. "modules/rj_buyer/init.lua"))()
    local ok, err = pcall(function()
        buyRJ(rjToBuy, dlog, flyTo)
    end)
    if not ok then
        dlog("ERROR buying RJ: " .. tostring(err))
        return 0
    end
    return rjToBuy
end


-- ── Part 2: Fill to 35 slots, buy max RJ, run legendary adjuster ──────
local function runPart2()
    dlog("=== PART 2: Filling hive to " .. HIVE_FULL_SIZE_2 .. " slots ===")


    local size = getHiveSize()
    dlog("Current hive size: " .. size .. "/" .. HIVE_FULL_SIZE_2)


    if size < HIVE_FULL_SIZE_2 then
        changeConfig("atlas/1.json")
        while true do
            task.wait(POLL_INTERVAL)
            local currentSize = getHiveSize()
            dlog("Hive size: " .. currentSize .. "/" .. HIVE_FULL_SIZE_2)
            if currentSize >= HIVE_FULL_SIZE_2 then
                dlog("Hive reached " .. HIVE_FULL_SIZE_2 .. " slots!")
                changeConfig("atlas/stop.json")
                break
            end
        end
    else
        dlog("Hive already at " .. size .. " slots, skipping Atlas fill.")
    end


    -- main loop: buy RJ → run legendary adjuster → repeat until satisfied
    while true do
        dlog("Buying max RJ from honey...")
        buyMaxRJ(dlog, flyTo)


        dlog("Running legendary adjuster...")
        local satisfied = runAdjuster(COMP_NAME_2)


        if satisfied then
            dlog("=== PART 2 COMPLETE: '" .. COMP_NAME_2 .. "' requirements met! ===")
            progress.part = 3
            saveProgress()
            break
        end


        dlog("Requirements not yet met. Running Atlas for " .. ATLAS_RUN_MINS .. " minutes...")
        changeConfig("atlas/1.json")


        local waitSeconds = ATLAS_RUN_MINS * 60
        local elapsed = 0
        while elapsed < waitSeconds do
            task.wait(POLL_INTERVAL)
            elapsed = elapsed + POLL_INTERVAL
            local remaining = math.floor((waitSeconds - elapsed) / 60)
            dlog("Atlas running... " .. remaining .. "min remaining")
        end


        changeConfig("atlas/stop.json")
        dlog("Atlas run complete. Buying RJ and re-running adjuster...")
    end
end


-- ── Part 3 helpers ────────────────────────────────────────────────────
local function getItem(name)
    local count = 0
    pcall(function()
        local cache = require(RS:WaitForChild("ClientStatCache"))
        count = cache:Get({"Eggs", name}) or 0
    end)
    return count
end


local function getRJCount()
    return getItem("RoyalJelly")
end


local function hasBubbleMask()
    local ok, data = pcall(function()
        local cache = require(RS:WaitForChild("ClientStatCache"))
        return cache:Get({"Accessories"})
    end)
    if ok and type(data) == "table" then
        for _, v in pairs(data) do
            if tostring(v) == "Bubble Mask" then
                return true
            end
        end
    end
    return false
end


local function getBubbleMaskStatus()
    local glitter   = getItem("Glitter")
    local oil       = getItem("Oil")
    local blueExt   = getItem("BlueExtract")
    local blueberry = getItem("Blueberry")


    local blueExtNeeded = math.max(0, BUBBLE_MASK_BLUE_EXT - blueExt)


    dlog("Bubble Mask ingredients:")
    dlog("  Glitter:      " .. glitter .. "/" .. BUBBLE_MASK_GLITTER)
    dlog("  Oil:          " .. oil .. "/" .. BUBBLE_MASK_OIL)
    dlog("  Blue Extract: " .. blueExt .. "/" .. BUBBLE_MASK_BLUE_EXT .. " (need " .. blueExtNeeded .. " more)")
    dlog("  Blueberry:    " .. blueberry .. "/" .. BUBBLE_MASK_BLUEBERRY)


    local hasEnoughForSwitch = (
        glitter   >= BUBBLE_MASK_GLITTER and
        oil       >= BUBBLE_MASK_OIL and
        blueberry >= (BUBBLE_MASK_BLUEBERRY + (25 * blueExtNeeded))
    )


    return {
        glitter        = glitter,
        oil            = oil,
        blueExt        = blueExt,
        blueberry      = blueberry,
        blueExtNeeded  = blueExtNeeded,
        hasEnoughForSwitch = hasEnoughForSwitch,
        allIngredients = blueExtNeeded == 0 and hasEnoughForSwitch
    }
end


local function getDiamondMaskStatus()
    local glitter   = getItem("Glitter")
    local oil       = getItem("Oil")
    local blueExt   = getItem("BlueExtract")
    local diamondEgg = getItem("DiamondEgg")
    local comforting_vial = getItem("ComfortingVial")


-- ── Part 3: Gather Bubble Mask ingredients ────────────────────────────
local function runPart3()
    dlog("=== PART 3: Gathering Bubble Mask ingredients ===")
    dlog("Goal: 15 Glitter, 25 Oil, 500 Blueberries, 50 Blue Extract")


    while true do
        dlog("------------------------------------")


        -- check if already done
        dlog("Checking if Bubble Mask already acquired...")
        if hasBubbleMask() then
            dlog("=== PART 3 COMPLETE: Bubble Mask acquired! ===")
            progress.part = 4
            saveProgress()
            break
        end
        dlog("No Bubble Mask yet. Checking ingredients...")


        local status = getBubbleMaskStatus()


        -- summarise what's still missing
        local missing = {}
        if status.glitter   < BUBBLE_MASK_GLITTER   then table.insert(missing, "Glitter (" .. (BUBBLE_MASK_GLITTER - status.glitter) .. " more needed)") end
        if status.oil       < BUBBLE_MASK_OIL        then table.insert(missing, "Oil (" .. (BUBBLE_MASK_OIL - status.oil) .. " more needed)") end
        if status.blueExt   < BUBBLE_MASK_BLUE_EXT   then table.insert(missing, "Blue Extract (" .. status.blueExtNeeded .. " more needed)") end
        local berryNeeded = BUBBLE_MASK_BLUEBERRY + (25 * status.blueExtNeeded)
        if status.blueberry < berryNeeded            then table.insert(missing, "Blueberry (" .. (berryNeeded - status.blueberry) .. " more needed)") end


        if #missing == 0 then
            dlog("✓ All ingredients accounted for!")
        else
            dlog("Still missing: " .. table.concat(missing, " | "))
        end


        -- all ingredients gathered — just keep running atlas preset 1
        -- and wait for Atlas to auto-buy the mask
        if status.allIngredients then
            dlog("All ingredients gathered! Atlas preset 1 is running.")
            dlog("Waiting for Atlas to auto-purchase the Bubble Mask...")
            changeConfig("atlas/1.json")


            while true do
                task.wait(POLL_INTERVAL * 6) -- check every minute
                dlog("Checking for Bubble Mask purchase...")
                if hasBubbleMask() then
                    dlog("=== PART 3 COMPLETE: Bubble Mask acquired! ===")
                    changeConfig("atlas/stop.json")
                    progress.part = 4
                    saveProgress()
                    return
                end
                dlog("Not purchased yet. Atlas still running, will check again in 60s.")
            end
        end


        -- need more blue extracts — farm honey using 750m - (rj_owned * 1m) formula
        if status.blueExtNeeded > 0 and status.glitterNeeded < 1 then
            local currentRJ    = getRJCount()
            local honeyNeeded  = math.max(0, 750000000 - (currentRJ * HONEY_PER_RJ))
            local rjToBuy      = math.floor((honeyNeeded / HONEY_PER_RJ) - 100000000)
            local currentHoney = getHoney()


            dlog("Blue Extracts needed: " .. status.blueExtNeeded)
            dlog("Current RJ owned: " .. currentRJ)
            dlog("Honey target: 750,000,000 - (" .. currentRJ .. " x 1,000,000) = " .. honeyNeeded)
            dlog("RJ to buy after farming: " .. rjToBuy)
            dlog("Current honey: " .. currentHoney .. "/" .. honeyNeeded)


            if honeyNeeded <= 0 then
                dlog("Already have enough RJ (" .. currentRJ .. ") — skipping honey farm.")
            elseif currentHoney < honeyNeeded then
                dlog("Not enough honey yet. Switching to Atlas preset 2 to farm honey...")
               
                changeConfig(ATLAS_CONFIG_SRC_2)
               


                while true do
                    task.wait(POLL_INTERVAL * 6)
                    local honey = getHoney()
                    local pct = math.floor((honey / honeyNeeded) * 100)
                    dlog("Farming honey: " .. honey .. "/" .. honeyNeeded .. " (" .. pct .. "%)")


                    if honey >= honeyNeeded then
                        dlog("Honey target reached! Stopping Atlas preset 2...")
                        changeConfig("atlas/stop.json")


                        -- recalculate rjToBuy in case RJ changed during farming
                        local rjNow = getRJCount()
                        local finalRJ = math.max(0, math.floor((750000000 - (rjNow * HONEY_PER_RJ)) / HONEY_PER_RJ))
                        dlog("Buying " .. finalRJ .. " RJ (recalculated with current RJ: " .. rjNow .. ")...")
                        if finalRJ > 0 then
                            local buyRJ = loadstring(game:HttpGet(RAW_BASE .. "modules/rj_buyer/init.lua"))()
                            local ok, err = pcall(function()
                                buyRJ(finalRJ, dlog, flyTo)
                            end)
                            if not ok then
                                dlog("ERROR buying RJ: " .. tostring(err))
                            else
                                dlog("✓ Bought " .. finalRJ .. " RJ successfully")
                            end
                        else
                            dlog("No RJ to buy after recalculation.")
                        end


                        dlog("Switching back to Atlas preset 1...")
                        changeConfig("atlas/1.json")
                        break
                    end
                end
            else
                dlog("Already have enough honey. Buying " .. rjToBuy .. " RJ now...")
                changeConfig("atlas/stop.json")
                if rjToBuy > 0 then
                    local buyRJ = loadstring(game:HttpGet(RAW_BASE .. "modules/rj_buyer/init.lua"))()
                    local ok, err = pcall(function()
                        buyRJ(rjToBuy, dlog, flyTo)
                    end)
                    if not ok then
                        dlog("ERROR buying RJ: " .. tostring(err))
                    else
                        dlog("✓ Bought " .. rjToBuy .. " RJ successfully")
                    end
                end
                changeConfig("atlas/1.json")
            end
        else
            dlog("Blue Extracts: ✓ (" .. status.blueExt .. "/" .. BUBBLE_MASK_BLUE_EXT .. ")")
            dlog("Atlas preset 1 running. Waiting for remaining ingredients (glitter/oil/blueberries)...")
            changeConfig("atlas/1.json")
        end


        -- short wait before re-checking ingredients
        dlog("Re-checking ingredients in 60 seconds...")
        task.wait(60)
    end
end


local function runPart4()
    dlog("=== PART 4: Filling hive to " .. HIVE_FULL_SIZE_3 .. " slots ===")


    local size = getHiveSize()
    dlog("Current hive size: " .. size .. "/" .. HIVE_FULL_SIZE_3)


    if size < HIVE_FULL_SIZE_3 then
        changeConfig("atlas/1.json")
        while true do
            task.wait(POLL_INTERVAL)
            local currentSize = getHiveSize()
            dlog("Hive size: " .. currentSize .. "/" .. HIVE_FULL_SIZE_3)
            if currentSize >= HIVE_FULL_SIZE_3 then
                dlog("Hive reached " .. HIVE_FULL_SIZE_3 .. " slots!")
                changeConfig("atlas/stop.json")
                break
            end
        end
    else
        dlog("Hive already at " .. size .. " slots, skipping Atlas fill.")


    while true do
        dlog("Buying max RJ from honey...")
        buyMaxRJ(dlog, flyTo)


        dlog("Running legendary adjuster...")
        local satisfied = runAdjuster(COMP_NAME_3)


        if satisfied then
            dlog("=== PART 2 COMPLETE: '" .. COMP_NAME_3 .. "' requirements met! ===")
            progress.part = 3
            saveProgress()
            break
        end


        dlog("Requirements not yet met. Running Atlas for " .. ATLAS_RUN_MINS .. " minutes...")
        changeConfig("atlas/1.json")


        local waitSeconds = ATLAS_RUN_MINS * 60
        local elapsed = 0
        while elapsed < waitSeconds do
            task.wait(POLL_INTERVAL)
            elapsed = elapsed + POLL_INTERVAL
            local remaining = math.floor((waitSeconds - elapsed) / 60)
            dlog("Atlas running... " .. remaining .. "min remaining")
        end


        changeConfig("atlas/stop.json")
        dlog("Atlas run complete. Buying RJ and re-running adjuster...")
    end
end








   


-- ── Main ──────────────────────────────────────────────────────────────
local function main(startPart)
    -- Must add in to start atlas
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Chris12089/atlasbss/main/script.lua"))()







    dlog("====================================")
    dlog("  BSS Fuzzy Alt Script")
    dlog("  Account: " .. lp.Name)
    dlog("====================================")


    local resumed = loadProgress()
    if resumed then
        dlog("Resuming from saved progress. Part: " .. progress.part)
    else
        dlog("No saved progress found. Starting fresh at Part 0.")
        progress.part = 0
        saveProgress()
    end


    -- manual start part overrides saved progress
    if startPart and startPart ~= progress.part then
        dlog("Manual override: jumping to Part " .. startPart)
        progress.part = startPart
        saveProgress()
    end


    dlog("Starting at Part " .. progress.part)


    if progress.part == 0 then
        runPart0()
    end


    if progress.part == 1 then
        runPart1()
    end


    if progress.part == 2 then
        runPart2()
    end


    if progress.part == 3 then
        runPart3()


    end


    if progress.part == 4 then
        runPart4()
    end


    if progress.part >= 5 then
        dlog("Part 4 already completed for account: " .. lp.Name)
        dlog("Hive requirements already met! Ready for Part 5 (not yet implemented).")
end


return function(dlog_, flyTo_, compIO_, beeAbilities_, startPart)
    main(startPart)
end

