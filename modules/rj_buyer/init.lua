local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local lp = Players.LocalPlayer

local SHOP_POS = Vector3.new(-295, 52, 67)

local function calculatePurchases(totalAmount)
    local purchases = {}
    local remaining = totalAmount
    local validAmounts = {
        100000000, 10000000, 1000000, 100000,
        10000, 1000, 100, 10, 1
    }
    for _, amount in ipairs(validAmounts) do
        while remaining >= amount do
            table.insert(purchases, amount)
            remaining = remaining - amount
        end
    end
    return purchases
end

local function buyRJ(totalAmount, dlog, flyTo)
    if not totalAmount or totalAmount < 1 then
        dlog("ERROR: Invalid amount")
        return
    end

    local purchases = calculatePurchases(totalAmount)
    local total = 0
    for _, v in ipairs(purchases) do total = total + v end

    dlog("Buying " .. total .. " RJ in " .. #purchases .. " purchases")
    dlog("Flying to RJ shop...")

    local arrived = flyTo(SHOP_POS, dlog)
    if not arrived then
        dlog("ERROR: Failed to arrive at shop!")
        return
    end

    task.wait(0.5)

    local event = ReplicatedStorage:WaitForChild("Events"):WaitForChild("ItemPackageEvent")
    for i, amount in ipairs(purchases) do
        local ok, err = pcall(function()
            event:InvokeServer("Purchase", {
                Type = "RoyalJelly",
                Category = "Eggs",
                Amount = amount
            })
        end)
        if ok then
            dlog("✓ Bought " .. amount .. " RJ (" .. i .. "/" .. #purchases .. ")")
        else
            dlog("✗ ERROR: " .. tostring(err))
        end
        task.wait(0.3)
    end

    dlog("All done! Bought " .. total .. " RJ total")
end

return buyRJ