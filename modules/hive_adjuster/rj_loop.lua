local RS = game:GetService("ReplicatedStorage")

local function getRJCount()
    local count = 0
    pcall(function()
        local cache = require(RS:WaitForChild("ClientStatCache"))
        count = cache:Get({"Eggs", "RoyalJelly"}) or 0
    end)
    return count
end

local function useRJ(slotName)
    local x, y = slotName:match("C(%d+),(%d+)")
    if not x or not y then
        return false, "Invalid slot name: " .. tostring(slotName)
    end
    local ok, err = pcall(function()
        RS:WaitForChild("Events"):WaitForChild("ConstructHiveCellFromEgg"):InvokeServer(
            tonumber(x), tonumber(y), "RoyalJelly", 1, false
        )
    end)
    return ok, err
end

local function runRJLoop(currentHive, comp, beeAbilities, evaluate, scanHive, dlog)
    dlog("Starting RJ loop...")

    local totalRJUsed = 0
    local slotsCompleted = 0

    while true do
        local rjCount = getRJCount()
        dlog("RJ remaining: " .. tostring(rjCount))

        if rjCount <= 0 then
            dlog("Out of RJ! Stopping.")
            return {
                rjUsed = totalRJUsed,
                slotsCompleted = slotsCompleted,
                finalHive = currentHive,
                complete = false  -- ran out of RJ, outer loop should farm and retry
            }
        end

        local evalResult = evaluate(currentHive, comp, beeAbilities)
        dlog(evalResult.summary)

        local requirementsMet = #evalResult.unsatisfied == 0
        local priorityClear = #evalResult.slotsToRJPriority == 0

        if requirementsMet and priorityClear then
            dlog("All requirements satisfied and no never-keep bees remaining!")
            return {
                rjUsed = totalRJUsed,
                slotsCompleted = slotsCompleted,
                finalHive = currentHive,
                complete = true
            }
        end

        -- pick next slot: priority (never-keep / event bees) first, then regular
        local target = nil
        if #evalResult.slotsToRJPriority > 0 then
            target = evalResult.slotsToRJPriority[1]
            dlog("[PRIORITY] RJing slot " .. target.slot .. " (" .. tostring(target.currentBee) .. " — " .. (target.reason or "priority") .. ")")
        elseif #evalResult.slotsToRJ > 0 then
            target = evalResult.slotsToRJ[1]
            dlog("RJing slot " .. target.slot .. " (currently: " .. tostring(target.currentBee) .. ")")
        else
            -- no slots to RJ at all — hive is fully locked
            dlog("No slots available to RJ!")
            return {
                rjUsed = totalRJUsed,
                slotsCompleted = slotsCompleted,
                finalHive = currentHive,
                complete = requirementsMet and priorityClear
            }
        end

        local before = scanHive()

        local ok, err = useRJ(target.slot)
        if not ok then
            dlog("ERROR using RJ on " .. target.slot .. ": " .. tostring(err))
            return {
                rjUsed = totalRJUsed,
                slotsCompleted = slotsCompleted,
                finalHive = currentHive,
                complete = false
            }
        end

        totalRJUsed = totalRJUsed + 1
        task.wait(0.3)

        local after = scanHive()

        local newBee = after[target.slot]
        if newBee then
            local giftedStr = newBee.gifted and " [★ GIFTED]" or ""
            dlog("Got: " .. tostring(newBee.name) .. giftedStr)

            if before[target.slot] and before[target.slot].name == newBee.name and not newBee.gifted then
                dlog("WARNING: Bee did not change - may be out of RJ!")
                local rjCheck = getRJCount()
                if rjCheck <= 0 then
                    dlog("Confirmed out of RJ! Stopping.")
                    return {
                        rjUsed = totalRJUsed,
                        slotsCompleted = slotsCompleted,
                        finalHive = after,
                        complete = false
                    }
                end
            else
                slotsCompleted = slotsCompleted + 1
            end
        else
            dlog("WARNING: Could not read slot after RJ")
        end

        currentHive = after
        task.wait(0.1)
    end
end

return runRJLoop