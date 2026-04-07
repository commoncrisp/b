local Players = game:GetService("Players")
local lp = Players.LocalPlayer

local function run(dlog, webhook, config)
    local rawBase = "https://raw.githubusercontent.com/commoncrisp/a/main/"

    local beeKeywords = loadstring(game:HttpGet(rawBase .. "modules/hive_scanner/bee_keywords.lua"))()
    local buildBeeList = loadstring(game:HttpGet(rawBase .. "modules/hive_scanner/build_bee_list.lua"))()
    local buildAdvancedList = loadstring(game:HttpGet(rawBase .. "modules/hive_scanner/build_advanced.lua"))()
    local buildFinalList = loadstring(game:HttpGet(rawBase .. "modules/hive_scanner/build_final.lua"))()

    dlog("Starting scan for: " .. lp.Name)

    local bee_list = buildBeeList(beeKeywords, dlog)
    local advanced_results = buildAdvancedList(beeKeywords, dlog)
    local final_list = buildFinalList(bee_list, advanced_results, dlog)

    if #final_list == 0 then
        dlog("ERROR: No bees found")
        return
    end

    local lines = {"**HIVE SCAN — " .. lp.Name .. "**", "```"}
    for _, t in ipairs(final_list) do
        local slotStr = string.format("%-8s", "C" .. t[1] .. "," .. t[2])
        local giftedStr = t[4] and "[★ GIFTED]" or "[  NORMAL ]"
        table.insert(lines, slotStr .. " " .. giftedStr .. " : " .. t[3])
    end
    table.insert(lines, "```")
    table.insert(lines, "_Total bees: " .. #final_list .. "_")

    webhook.send(table.concat(lines, "\n"), dlog, config.webhookUrl)
    dlog("All done!")
end

return run
