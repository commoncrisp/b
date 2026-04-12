-- modules/sprout_hopper/init.lua
local TeleportService = game:GetService("TeleportService")
local HttpService     = game:GetService("HttpService")
local Players         = game:GetService("Players")
local lp              = Players.LocalPlayer

local ATLAS_URL        = "https://raw.githubusercontent.com/Chris12089/atlasbss/main/script.lua"
local POLL_INTERVAL    = 5
local SPROUT_GONE_WAIT = 20
local HOP_WAIT         = 4
local VISITED_FILE     = "sprout_visited.json"

-- ── Visited server tracking ───────────────────────────────────────────────────
local function loadVisited()
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(VISITED_FILE))
    end)
    return (ok and type(data) == "table") and data or {}
end

local function saveVisited(visited)
    pcall(writefile, VISITED_FILE, HttpService:JSONEncode(visited))
end

local function markVisited(jobId)
    local visited = loadVisited()
    table.insert(visited, jobId)
    while #visited > 20 do table.remove(visited, 1) end
    saveVisited(visited)
end

local function wasVisited(jobId)
    local visited = loadVisited()
    for _, id in ipairs(visited) do
        if id == jobId then return true end
    end
    return false
end

-- ── Sprout detection ──────────────────────────────────────────────────────────
local function findSprout()
    local folder = workspace:FindFirstChild("Sprouts")
    if folder then return folder:FindFirstChild("Sprout") end
    return nil
end

local function hasSprout()
    return findSprout() ~= nil
end

-- ── Server list ───────────────────────────────────────────────────────────────
local function getServers()
    local url = "https://games.roblox.com/v1/games/"
        .. game.PlaceId
        .. "/servers/Public?sortOrder=Asc&limit=100"

    local ok, result = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(url))
    end)

    if not ok or not result or not result.data then return {} end

    local valid = {}
    for _, server in pairs(result.data) do
        if server.id ~= game.JobId
        and not wasVisited(server.id)
        and server.playing < server.maxPlayers then
            table.insert(valid, server)
        end
    end
    return valid
end

-- ── Hop ───────────────────────────────────────────────────────────────────────
local function hop(dlog)
    local servers = getServers()

    if #servers == 0 then
        dlog("No unvisited servers found — clearing history and retrying in " .. HOP_WAIT .. "s...")
        saveVisited({})
        task.wait(HOP_WAIT)
        return
    end

    for i = #servers, 2, -1 do
        local j = math.random(i)
        servers[i], servers[j] = servers[j], servers[i]
    end

    dlog("Found " .. #servers .. " unvisited servers — hopping...")
    markVisited(game.JobId)

    local originalJobId = game.JobId
    local hopped = false

    for _, server in ipairs(servers) do
        local ok, err = pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id)
        end)
        if not ok then
            dlog("Teleport failed: " .. tostring(err))
            task.wait(2)
        else
            -- wait and check if we actually moved
            task.wait(15)
            if game.JobId ~= originalJobId then
                hopped = true
                break
            else
                dlog("Teleport silently failed — trying next server...")
            end
        end
    end

    if not hopped then
        dlog("All hops failed — fallback teleport")
        markVisited(game.JobId)
        pcall(function() TeleportService:Teleport(game.PlaceId) end)
        task.wait(15)
    end
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
