-- modules/sprout_hopper/init.lua
-- Hops servers until finding one with an active sprout.
-- Runs Atlas while the sprout is alive.
-- Once the sprout disappears, waits 1 minute then hops again.

local TeleportService = game:GetService("TeleportService")
local HttpService     = game:GetService("HttpService")
local Players         = game:GetService("Players")
local lp              = Players.LocalPlayer

local ATLAS_URL        = "https://raw.githubusercontent.com/Chris12089/atlasbss/main/script.lua"
local POLL_INTERVAL    = 5    -- seconds between sprout checks while in a server
local SPROUT_GONE_WAIT = 60   -- seconds to wait after sprout disappears before hopping
local HOP_WAIT         = 8    -- seconds between each server hop attempt

-- ── Sprout detection ─────────────────────────────────────────────────────────
-- Sprouts appear as a Model/Part in workspace named "Sprout" or containing
-- "Sprout" in their name. BSS uses a model called "Sprout" under workspace.
local function findSprout()
    -- Direct child called "Sprout"
    local direct = workspace:FindFirstChild("Sprout")
    if direct then return direct end

    -- Sometimes nested under a folder (e.g. "Props", "Objects", "MapObjects")
    for _, folder in pairs(workspace:GetChildren()) do
        if folder:IsA("Model") or folder:IsA("Folder") then
            local s = folder:FindFirstChild("Sprout")
            if s then return s end
        end
    end

    -- Broad search as fallback
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj.Name == "Sprout" and (obj:IsA("Model") or obj:IsA("BasePart")) then
            return obj
        end
    end

    return nil
end

local function hasSprout()
    return findSprout() ~= nil
end

-- ── Server list ───────────────────────────────────────────────────────────────
local function getServers()
    local placeId = game.PlaceId
    local url = "https://games.roblox.com/v1/games/"
        .. placeId
        .. "/servers/Public?sortOrder=Asc&limit=100"

    local ok, result = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(url))
    end)

    if not ok or not result or not result.data then return {} end

    local valid = {}
    for _, server in pairs(result.data) do
        if server.id ~= game.JobId and server.playing < server.maxPlayers then
            table.insert(valid, server)
        end
    end
    return valid
end

-- ── Hop to a specific server ──────────────────────────────────────────────────
local function hopTo(serverId, dlog)
    local ok, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, serverId, lp)
    end)
    if not ok then
        dlog("Teleport failed: " .. tostring(err))
        return false
    end
    return true
end

local function fallbackHop(dlog)
    dlog("Using fallback random teleport...")
    pcall(function()
        TeleportService:Teleport(game.PlaceId)
    end)
end

-- ── Atlas launcher ────────────────────────────────────────────────────────────
local _atlasThread = nil

local function launchAtlas(dlog)
    dlog("Launching Atlas...")
    _atlasThread = task.spawn(function()
        local ok, err = pcall(function()
            loadstring(game:HttpGet(ATLAS_URL))()
        end)
        if not ok then
            dlog("Atlas error: " .. tostring(err))
        end
    end)
end

-- ── Main logic ────────────────────────────────────────────────────────────────
local _stop = false

local function run(dlog)
    dlog = dlog or function(msg) print("[SproutHopper] " .. msg) end
    _stop = false

    dlog("=== Sprout Hopper started ===")

    while not _stop do

        -- ── Check current server for sprout first ─────────────────────────
        if hasSprout() then
            dlog("Sprout found in current server! Starting Atlas...")
            launchAtlas(dlog)

            -- Wait while the sprout is alive
            while not _stop do
                task.wait(POLL_INTERVAL)
                if not hasSprout() then
                    dlog("Sprout is gone.")
                    break
                end
                dlog("Sprout still active...")
            end

            if _stop then break end

            -- Sprout gone — wait 1 minute before hopping
            dlog("Waiting " .. SPROUT_GONE_WAIT .. "s before hopping...")
            local waited = 0
            while waited < SPROUT_GONE_WAIT and not _stop do
                task.wait(5)
                waited = waited + 5
                dlog("Hop in " .. (SPROUT_GONE_WAIT - waited) .. "s...")
            end

            if _stop then break end
        end

        -- ── Hop to a new server ───────────────────────────────────────────
        dlog("Fetching server list...")
        local servers = getServers()

        if #servers == 0 then
            dlog("No servers found — retrying in " .. HOP_WAIT .. "s...")
            task.wait(HOP_WAIT)
        else
            -- Shuffle so we don't always hit the same servers
            for i = #servers, 2, -1 do
                local j = math.random(i)
                servers[i], servers[j] = servers[j], servers[i]
            end

            dlog("Found " .. #servers .. " servers — hopping...")
            local hopped = false
            for _, server in ipairs(servers) do
                if hopTo(server.id, dlog) then
                    hopped = true
                    -- Script will resume from top after rejoin via main.lua auto-reload
                    task.wait(15)  -- give time for teleport to process
                    break
                end
                task.wait(2)
            end

            if not hopped then
                dlog("All hops failed — fallback teleport")
                fallbackHop(dlog)
                task.wait(15)
            end
        end
    end

    dlog("=== Sprout Hopper stopped ===")
end

local function stop()
    _stop = true
end

return { run = run, stop = stop }
