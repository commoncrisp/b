-- modules/sprout_hopper/init.lua
-- Hops servers until finding one with an active sprout.
-- Runs Atlas while the sprout is alive.
-- Once the sprout disappears, waits 1 minute then hops again.

local TeleportService = game:GetService("TeleportService")
local Players         = game:GetService("Players")
local lp              = Players.LocalPlayer

local ATLAS_URL        = "https://raw.githubusercontent.com/Chris12089/atlasbss/main/script.lua"
local POLL_INTERVAL    = 5   -- seconds between sprout checks while atlas is running
local SPROUT_GONE_WAIT = 30  -- seconds to wait after sprout disappears before hopping

-- ── Sprout detection ─────────────────────────────────────────────────────────
-- Sprout lives at Workspace.Sprouts.Sprout
local function findSprout()
    local folder = workspace:FindFirstChild("Sprouts")
    if folder then
        return folder:FindFirstChild("Sprout")
    end
    return nil
end

local function hasSprout()
    return findSprout() ~= nil
end

-- ── Atlas launcher ────────────────────────────────────────────────────────────
local function launchAtlas(map)
    dlog("Launching Atlas...")
    task.spawn(function()
        local ok, err = pcall(function()
            loadstring(game:HttpGet(ATLAS_URL))()
        end)
        if not ok then
            dlog("Atlas error: " .. tostring(err))
        end
    end)
end

-- ── Server hop ────────────────────────────────────────────────────────────────
local function hop
    dlog("Hopping to a random server...")
    pcall(function()
        TeleportService:Teleport(game.PlaceId)
    end)
    task.wait(15)
end

-- ── Main logic ────────────────────────────────────────────────────────────────
local _stop = false

local function run(dlog)
    dlog = dlog or function(msg) print("[SproutHopper] " .. msg) end
    _stop = false

    dlog("=== Sprout Hopper started ===")

    while not _stop do

        if hasSprout() then
            dlog("Sprout found! Starting Atlas...")
            launchAtlas(map)

            -- Poll until sprout disappears
            while not _stop do
                task.wait(POLL_INTERVAL)
                if not hasSprout() then
                    dlog("Sprout is gone.")
                    break
                end
                dlog("Sprout still active...")
            end

            if _stop then break end

            -- Wait 1 minute then hop
            dlog("Waiting " .. SPROUT_GONE_WAIT .. "s before hopping...")
            local waited = 0
            while waited < SPROUT_GONE_WAIT and not _stop do
                task.wait(5)
                waited = waited + 5
                dlog("Hop in " .. (SPROUT_GONE_WAIT - waited) .. "s...")
            end

            if _stop then break end
        else
            dlog("No sprout — hopping...")
            hop
        end

    end

    dlog("=== Sprout Hopper stopped ===")
end

local function stop()
    _stop = true
end

return { run = run, stop = stop }
