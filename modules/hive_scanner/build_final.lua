local function buildFinalList(bee_list, advanced_results, dlog)
    local final_list = {}
    local advancedSlots = {}

    for _, entry in pairs(advanced_results) do
        advancedSlots[entry.Slot] = true
    end

    for _, t in ipairs(bee_list) do
        local x, y, beeName = t[1], t[2], t[3]
        local slotName = "C" .. x .. "," .. y
        local gifted = not advancedSlots[slotName]
        table.insert(final_list, {x, y, beeName, gifted})
    end

    dlog("Final list built: " .. #final_list .. " entries")
    return final_list
end

return buildFinalList