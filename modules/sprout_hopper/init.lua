-- modules/sprout_hopper/init.lua
local TeleportService = game:GetService("TeleportService")
local HttpService     = game:GetService("HttpService")
local Players         = game:GetService("Players")
local lp              = Players.LocalPlayer

local ATLAS_URL        = "https://raw.githubusercontent.com/Chris12089/atlasbss/main/script.lua"
local POLL_INTERVAL    = 5
local SPROUT_GONE_WAIT = 20

-- ── Server hop state ──────────────────────────────────────────────────────────
local AllIDs       = {}
local foundAnything = ""
local actualHour   = os.date("!*t").hour

local File = pcall(function()
    AllIDs = HttpService:JSONDecode(readfile("NotSameServers.json"))
end)
if not File then
    table.insert(AllIDs, actualHour)
    pcall(function()
        writefile("NotSameServers.json", HttpService:JSONEncode(AllIDs))
    end)
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

-- ── Server hop ────────────────────────────────────────────────────────────────
local function TPReturner(dlog)
    local Site
    if foundAnything == "" then
        Site = HttpService:JSONDecode(game:HttpGet(
            "https://games.roblox.com/v1/games/" .. game.PlaceId ..
            "/servers/Public?sortOrder=Asc&limit=100"))
    else
        Site = HttpService:JSONDecode(game:HttpGet(
            "https://games.roblox.com/v1/games/" .. game.PlaceId ..
            "/servers/Public?sortOrder=Asc&limit=100&cursor=" .. foundAnything))
    end

    if Site.nextPageCursor
    and Site.nextPageCursor ~= "null"
    and Site.nextPageCursor ~= nil then
        foundAnything = Site.nextPageCursor
    else
        foundAnything = ""
    end

    local ID  = ""
    local num = 0

    for _, v in pairs(Site.data) do
        local Possible = true
        ID = tostring(v.id)

        if tonumber(v.maxPlayers) > tonumber(v.playing) then
            for _, Existing in pairs(AllIDs) do
                if num ~= 0 then
                    if ID == tostring(Existing) then
                        Possible = false
                    end
                else
                    if tonumber(actualHour) ~= tonumber(Existing) then
                        pcall(function()
                            delfile("NotSameServers.json")
                            AllIDs = {}
                            table.insert(AllIDs, actualHour)
                        end)
                    end
                end
                num = num + 1
            end

            if Possible then
                dlog("Hopping to server: " .. ID)
                table.insert(AllIDs, ID)
                pcall(function()
                    writefile("NotSameServers.json", HttpService:JSONEncode(AllIDs))
                end)
                task.wait(1)
                pcall(function()
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, ID, lp)
                end)
                task.wait(4)
            end
        end
    end
end

local function hop(dlog)
    pcall(function() TPReturner(dlog) end)
    if foundAnything ~= "" then
        pcall(function() TPReturner(dlog) end)
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
