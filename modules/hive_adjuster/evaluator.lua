local function evaluate(currentHive, comp, beeAbilities)
    local result = {
        satisfied = {},
        unsatisfied = {},
        slotsToRJ = {},
        slotsToRJPriority = {}, -- never-keep and event bee slots, RJ'd first
        slotsToKeep = {},
        summary = ""
    }

    local reqProgress = {}
    for i, req in ipairs(comp.requirements) do
        reqProgress[i] = {
            req = req,
            found = 0,
            needed = req.count,
            slots = {}
        }
    end

    local lockedSlots = {}   -- slots that will NOT be RJ'd
    local priorityRJ = {}    -- slots flagged for priority RJ (never-keep / event bees)

    -- build never-keep and event bee lookup tables
    local neverKeepMap = {}
    for _, entry in ipairs(comp.neverKeep or {}) do
        neverKeepMap[entry.name] = entry
    end

    local eventBeeSet = {}
    for _, name in ipairs(comp.eventBees or {}) do
        eventBeeSet[name] = true
    end

    -- track gifted counts per bee type for keep list maxCount logic
    local giftedKeptCount = {}
    local totalKeptCount = {}

    -- track which bee types are already gifted in the hive
    local giftedBeesInHive = {}
    for slotName, slotData in pairs(currentHive) do
        if slotData.gifted then
            giftedBeesInHive[slotData.name] = true
        end
    end

    -- PASS 1: lock slots that cant be RJ'd (canRJ = false)
    for slotName, slotData in pairs(currentHive) do
        local beeName = slotData.name
        local beeData = beeAbilities[beeName]
        if beeData and not beeData.canRJ then
            lockedSlots[slotName] = true
            table.insert(result.slotsToKeep, {
                slot = slotName,
                bee = beeName,
                reason = "canRJ is false"
            })
        end
    end

    -- PASS 2: never-keep and event bees — checked before requirements,
    -- override everything. If giftedOnly is true and the bee IS gifted,
    -- skip it (let it fall through to requirements / keep list checks).
    for slotName, slotData in pairs(currentHive) do
        if not lockedSlots[slotName] and not priorityRJ[slotName] then
            local beeName = slotData.name
            local isGifted = slotData.gifted

            -- check neverKeep
            local nkEntry = neverKeepMap[beeName]
            if nkEntry then
                -- giftedOnly = true means "only RJ non-gifted, keep gifted"
                if nkEntry.giftedOnly and isGifted then
                    -- gifted version is exempt from never-keep, falls through
                else
                    priorityRJ[slotName] = true
                    table.insert(result.slotsToRJPriority, {
                        slot = slotName,
                        currentBee = beeName,
                        currentGifted = isGifted,
                        reason = "neverKeep"
                    })
                end
            end

            -- check eventBees (always RJ regardless of gifted)
            if not priorityRJ[slotName] and eventBeeSet[beeName] then
                priorityRJ[slotName] = true
                table.insert(result.slotsToRJPriority, {
                    slot = slotName,
                    currentBee = beeName,
                    currentGifted = isGifted,
                    reason = "eventBee"
                })
            end
        end
    end

    -- PASS 3: requirements (skip already priority-RJ'd slots)
    for slotName, slotData in pairs(currentHive) do
        if not lockedSlots[slotName] and not priorityRJ[slotName] then
            local beeName = slotData.name
            local isGifted = slotData.gifted
            local beeData = beeAbilities[beeName]

            for i, progress in ipairs(reqProgress) do
                local req = progress.req
                local matches = false

                if req.type == "token" and beeData then
                    for _, token in ipairs(beeData.tokens) do
                        if token == req.value then
                            matches = true
                            break
                        end
                    end
                elseif req.type == "specific" then
                    matches = beeName == req.value
                end

                if matches and req.gifted and not isGifted then
                    matches = false
                end

                if matches and progress.found < progress.needed then
                    progress.found = progress.found + 1
                    table.insert(progress.slots, slotName)
                    lockedSlots[slotName] = true
                    break
                end
            end
        end
    end

    -- PASS 4: keep list with maxCount logic
    for slotName, slotData in pairs(currentHive) do
        if not lockedSlots[slotName] and not priorityRJ[slotName] then
            local beeName = slotData.name
            local isGifted = slotData.gifted

            for _, keepEntry in ipairs(comp.keepList) do
                if keepEntry.name == beeName then
                    local max = keepEntry.maxCount or math.huge

                    if not keepEntry.stopIfGifted then
                        -- always keep mode: cap by total kept count
                        local kept = totalKeptCount[beeName] or 0
                        if kept < max then
                            lockedSlots[slotName] = true
                            totalKeptCount[beeName] = kept + 1
                            table.insert(result.slotsToKeep, {
                                slot = slotName,
                                bee = beeName,
                                reason = "in keepList"
                            })
                        end
                    elseif keepEntry.stopIfGifted and isGifted then
                        -- gifted only mode: cap by gifted kept count
                        local kept = giftedKeptCount[beeName] or 0
                        if kept < max then
                            lockedSlots[slotName] = true
                            giftedKeptCount[beeName] = kept + 1
                            table.insert(result.slotsToKeep, {
                                slot = slotName,
                                bee = beeName,
                                reason = "in keepList and gifted"
                            })
                        end
                    end
                end
            end

            -- globalStopIfGifted (only if not already handled)
            if not lockedSlots[slotName] and comp.globalStopIfGifted and isGifted then
                local giftedCount = 0
                for _, other in pairs(currentHive) do
                    if other.name == beeName and other.gifted then
                        giftedCount = giftedCount + 1
                    end
                end
                if giftedCount <= 1 then
                    lockedSlots[slotName] = true
                    table.insert(result.slotsToKeep, {
                        slot = slotName,
                        bee = beeName,
                        reason = "globalStopIfGifted - first gifted of this type"
                    })
                end
            end
        end
    end

    -- build satisfied/unsatisfied
    for i, progress in ipairs(reqProgress) do
        if progress.found >= progress.needed then
            table.insert(result.satisfied, {
                req = progress.req,
                found = progress.found,
                slots = progress.slots
            })
        else
            table.insert(result.unsatisfied, {
                req = progress.req,
                found = progress.found,
                needed = progress.needed,
                slots = progress.slots
            })
        end
    end

    -- build slotsToRJ (non-priority unlocked slots)
    for slotName, slotData in pairs(currentHive) do
        if not lockedSlots[slotName] and not priorityRJ[slotName] then
            table.insert(result.slotsToRJ, {
                slot = slotName,
                currentBee = slotData.name,
                currentGifted = slotData.gifted
            })
        end
    end

    -- summary
    local lines = {}
    table.insert(lines, "Requirements met: " .. #result.satisfied .. "/" .. #comp.requirements)
    table.insert(lines, "Priority RJ slots: " .. #result.slotsToRJPriority)
    table.insert(lines, "Slots to RJ: " .. #result.slotsToRJ)
    table.insert(lines, "Slots locked: " .. #result.slotsToKeep)
    for _, u in ipairs(result.unsatisfied) do
        local reqDesc = u.req.value
        table.insert(lines, "Still need: " .. (u.needed - u.found) .. "x " .. reqDesc .. (u.req.gifted and " (gifted)" or ""))
    end
    result.summary = table.concat(lines, "\n")

    return result
end

return evaluate