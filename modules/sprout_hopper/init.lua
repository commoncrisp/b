-- modules/sprout_hopper/init.lua
local TeleportService = game:GetService("TeleportService")
local HttpService     = game:GetService("HttpService")
local Players         = game:GetService("Players")
local lp              = Players.LocalPlayer

local ATLAS_URL        = "https://raw.githubusercontent.com/Chris12089/atlasbss/main/script.lua"
local POLL_INTERVAL    = 5
local SPROUT_GONE_WAIT = 20

-- ── Sprout detection ──────────────────────────────────────────────────────────
local function findSprout()
    local folder = workspace:FindFirstChild("Sprouts")
    if folder then return folder:FindFirstChild("Sprout") end
    return nil
end

local function hasSprout()
    return findSprout() ~= nil
end

-- ── Hop ───────────────────────────────────────────────────────────────────────
local function hop(dlog)
    dlog("Hopping to random server...")
    local ok, err = pcall(function()
        TeleportService:Teleport(game.PlaceId)
    end)
    if not ok then
        dlog("Teleport error: " .. tostring(err))
    end
    task.wait(15)
end

-- ── Atlas launcher ────────────────────────────────────────────────────────────
local function launchAtlas(dlog)
    dlog("Launching Atlas...")
    task.spawn(function()
        local ok, err = pcall(function()
            loadstring(game:HttpGet(ATLAS_URL))()
        end)
        if not ok then dlog("Atlas error: " .. tostring(err)) end
    end)
end

-- ── Main ──────────────────────────────────────────────────────────────────────
local _stop = false

local function run(dlog)
    dlog = dlog or function(msg) print("[SproutHopper] " .. msg) end
    _stop = false

    dlog("=== Sprout Hopper started ===")

    while not _stop do
        local ok, err = pcall(function()
            if hasSprout() then
                dlog("Sprout found! Starting Atlas...")
                launchAtlas(dlog)

                while not _stop do
                    task.wait(POLL_INTERVAL)
                    if not hasSprout() then
                        dlog("Sprout is gone.")
                        break
                    end
                    dlog("Sprout still active...")
                end

                if _stop then return end

                dlog("Waiting " .. SPROUT_GONE_WAIT .. "s before hopping...")
                local waited = 0
                while waited < SPROUT_GONE_WAIT and not _stop do
                    task.wait(5)
                    waited = waited + 5
                    dlog("Hop in " .. (SPROUT_GONE_WAIT - waited) .. "s...")
                end
            else
                dlog("No sprout here — hopping...")
                hop(dlog)
            end
        end)

        if not ok then
            dlog("ERROR (recovering): " .. tostring(err))
            task.wait(5)
        end
    end

    dlog("=== Sprout Hopper stopped ===")
end

local function stop()
    _stop = true
end

return { run = run, stop = stop }
