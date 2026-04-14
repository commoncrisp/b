-- modules/sprout_hopper/init.lua
local TeleportService = game:GetService("TeleportService")
local HttpService     = game:GetService("HttpService")
local Players         = game:GetService("Players")
local lp              = Players.LocalPlayer

local ATLAS_URL        = "https://raw.githubusercontent.com/Chris12089/atlasbss/main/script.lua"
local POLL_INTERVAL    = 5
local SPROUT_GONE_WAIT = 20
local _WAIT         = 4
local VISITED_FILE     = "sprout_visited.json"
local FAILS_FILE       = "sprout_fails.json"
local FAIL_LIMIT       = 3
local FAIL_WAIT        = 180
local MIN_EMPTY_SLOTS  = 4

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

local function targetVisited(jobId)
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

-- ── Fail counter ──────────────────────────────────────────────────────────────
local function loadFails()
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(FAILS_FILE))
    end)
    return (ok and type(data) == "table") and data.count or 0
end

local function saveFails(count)
    pcall(writefile, FAILS_FILE, HttpService:JSONEncode({ count = count }))
end

local function resetFails()
    saveFails(0)
end

local consecutiveFails = loadFails()

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
        local emptySlots = server.maxPlayers - server.playing
        if server.id ~= game.JobId
        and not wasVisited(server.id)
        and emptySlots >= MIN_EMPTY_SLOTS then
            table.insert(valid, server)
        end
    end
    return valid
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

-- ── Hop ───────────────────────────────────────────────────────────────────────
local function hop(dlog)
    local servers = getServers()

    local lastTeleportFailReason = nil

    TeleportService.TeleportInitFailed:Connect(function(player, reason, errorMessage)
        lastTeleportFailReason = reason
        dlog("TeleportInitFailed: " .. tostring(reason) .. " — " .. tostring(errorMessage))
    end)

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
        if consecutiveFails >= FAIL_LIMIT then break end

        -- ── Re-check slots live just before teleporting ──────────────────────
        local freshOk, freshResult = pcall(function()
            local url = "https://games.roblox.com/v1/games/"
                .. game.PlaceId
                .. "/servers/Public?sortOrder=Asc&limit=100"
            return HttpService:JSONDecode(game:HttpGet(url))
        end)

        if freshOk and freshResult and freshResult.data then
            local stillFresh = false
            for _, fresh in ipairs(freshResult.data) do
                if fresh.id == server.id then
                    local emptySlots = fresh.maxPlayers - fresh.playing
                    if emptySlots >= MIN_EMPTY_SLOTS then
                        stillFresh = true
                    else
                        dlog("Server filled up before teleport (" .. emptySlots .. " slots) — skipping...")
                    end
                    break
                end
            end
            if not stillFresh then
                task.wait(1)
                goto continue
            end
        end
        -- ─────────────────────────────────────────────────────────────────────

        local ok, err = pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id)
        end)
        if not ok then
            dlog("Teleport failed: " .. tostring(err))
            task.wait(2)
        else
            task.wait(15)
            if game.JobId ~= originalJobId then
                hopped = true
                consecutiveFails = 0
                resetFails()
                break
            else
                if lastTeleportFailReason ~= Enum.TeleportResult.GameFull then
                    consecutiveFails = consecutiveFails + 1
                    saveFails(consecutiveFails)
                    dlog("Teleport silently failed (" .. consecutiveFails .. "/" .. FAIL_LIMIT .. ")")
                else
                    dlog("Server was full — not counting as failure, skipping...")
                end
                lastTeleportFailReason = nil
                if consecutiveFails >= FAIL_LIMIT then break end
            end
        end

        ::continue::
    end

    if not hopped then
        if consecutiveFails >= FAIL_LIMIT then
            dlog("Teleports blocked — launching Atlas for " .. (FAIL_WAIT/60) .. " mins while waiting...")
            consecutiveFails = 0
            resetFails()
            saveVisited({})
            launchAtlas(dlog)
            local waited = 0
            while waited < FAIL_WAIT do
                task.wait(10)
                waited = waited + 10
                dlog("Resuming hops in " .. (FAIL_WAIT - waited) .. "s...")
            end
            dlog("Resuming hops now...")
        else
            dlog("All servers tried — fallback teleport")
            pcall(function() TeleportService:Teleport(game.PlaceId) end)
            task.wait(15)
        end
    end
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
