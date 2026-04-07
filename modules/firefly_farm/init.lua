local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local lp = Players.LocalPlayer

local function isNight()
    local clockTime = game:GetService("Lighting").ClockTime
    return clockTime < 6 or clockTime >= 18
end

local function getRandomServer()
    local placeId = game.PlaceId
    local currentJobId = game.JobId
    local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"

    local ok, result = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(url))
    end)

    if not ok or not result or not result.data then
        return nil
    end

    local validServers = {}
    for _, server in pairs(result.data) do
        if server.id ~= currentJobId and server.playing < server.maxPlayers then
            table.insert(validServers, server)
        end
    end

    if #validServers == 0 then return nil end
    return validServers[math.random(1, #validServers)]
end

local function serverHop(dlog)
    dlog("Finding a new server...")
    
    local maxAttempts = 5
    local attempt = 0
    
    while attempt < maxAttempts do
        attempt = attempt + 1
        dlog("Attempt " .. attempt .. "/" .. maxAttempts)
        
        local server = getRandomServer()
        if not server then
            dlog("No servers found, trying fallback...")
            pcall(function()
                TeleportService:Teleport(game.PlaceId)
            end)
            return
        end

        local ok, err = pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, lp)
        end)

        if ok then
            dlog("Teleport successful!")
            return
        else
            dlog("Teleport failed: " .. tostring(err) .. " retrying...")
            task.wait(3)
        end
    end

    -- all attempts failed use basic teleport
    dlog("All attempts failed, using basic teleport...")
    pcall(function()
        TeleportService:Teleport(game.PlaceId)
    end)
end

local function run(dlog)
    dlog("Firefly farm started!")
    dlog("Checking if night...")

    if not isNight() then
        dlog("It is day - finding new server...")
        task.wait(2)
        serverHop(dlog)
        return
    end

    dlog("It is NIGHT! Starting Atlas...")
    local ok, err = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Chris12089/atlasbss/main/script.lua"))()
    end)
    if not ok then
        dlog("ERROR loading Atlas: " .. tostring(err))
        return
    end
    dlog("Atlas running! Watching for day...")

    while true do
        task.wait(5)
        if not isNight() then
            dlog("Day detected! Finding new server...")
            task.wait(2)
            serverHop(dlog)
            return
        end
        dlog("Still night, continuing...")
    end
end

return run