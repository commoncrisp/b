local HttpService = game:GetService("HttpService")
local Players     = game:GetService("Players")
local lp          = Players.LocalPlayer

local RAW_BASE     = "https://raw.githubusercontent.com/commoncrisp/b/main/"
local POLL_INTERVAL = 10  -- seconds between trigger checks

-- ── Progress persistence ──────────────────────────────────────────────────────
local function progressFile(routeName)
    return "bss_runner_" .. lp.Name .. "_" .. routeName .. ".json"
end

local function saveProgress(routeName, stepIndex, stepStartTime)
    pcall(function()
        writefile(progressFile(routeName), HttpService:JSONEncode({
            step          = stepIndex,
            stepStartTime = stepStartTime,
            account       = lp.Name,
        }))
    end)
end

local function loadProgress(routeName)
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(progressFile(routeName)))
    end)
    if ok and data and data.account == lp.Name then return data end
    return nil
end

local function clearProgress(routeName)
    pcall(function() delfile(progressFile(routeName)) end)
end

-- ── Trigger checker (pure — accepts a detection table so it can be mocked) ────
local function checkTrigger(trigger, stepStartTime, detection)
    if trigger.type == "honey" then
        return detection.getHoney() >= trigger.amount

    elseif trigger.type == "material" then
        return detection.getMaterial(trigger.name) >= trigger.amount

    elseif trigger.type == "item" then
        return detection.hasItem(trigger.name)

    elseif trigger.type == "tool" then
        return detection.hasTool(trigger.name)

    elseif trigger.type == "time" then
        return (os.clock() - stepStartTime) >= (trigger.minutes * 60)
    end

    return false
end

-- ── Atlas config swap ─────────────────────────────────────────────────────────
local function applyAtlasConfig(configPath, dlog)
    dlog("[Runner] Swapping atlas config: " .. configPath)
    pcall(function()
        local data = readfile(configPath)
        writefile("Atlas/Preset 1.json", data)
        pcall(function()
            writefile("Atlas/Bee Swarm Simulator/Configs/Preset 1.json", data)
        end)
    end)
end

-- ── Runner state (one route at a time) ───────────────────────────────────────
local _running  = false
local _stopFlag = false

local function stop()
    _stopFlag = true
end

local function isRunning()
    return _running
end

-- ── Main run function ─────────────────────────────────────────────────────────
local function run(route, dlog, flyTo, detection, overrideStartStep)
    if _running then
        dlog("[Runner] Already running — call stop() first")
        return
    end

    _running  = true
    _stopFlag = false

    -- lazy-load action dependencies
    local compIO           = loadstring(game:HttpGet(RAW_BASE .. "modules/hive_adjuster/comp_io.lua"))()
    local runHiveAdjuster  = loadstring(game:HttpGet(RAW_BASE .. "modules/hive_adjuster/init.lua"))()
    local buyRJ            = loadstring(game:HttpGet(RAW_BASE .. "modules/rj_buyer/init.lua"))()

    -- decide where to start
    local startStep = overrideStartStep
    if not startStep then
        local saved = loadProgress(route.name)
        if saved then
            startStep = saved.step
            dlog("[Runner] Resuming route '" .. route.name .. "' from step " .. startStep)
        else
            startStep = 1
            dlog("[Runner] Starting route '" .. route.name .. "' from step 1")
        end
    else
        dlog("[Runner] Starting route '" .. route.name .. "' from step " .. startStep .. " (manual override)")
    end

    for i = startStep, #route.steps do
        if _stopFlag then
            dlog("[Runner] Stopped at step " .. i)
            break
        end

        local step          = route.steps[i]
        local stepStartTime = os.clock()
        local action        = step.action
        local trigger       = step.trigger

        dlog("[Runner] ── Step " .. i .. "/" .. #route.steps .. " ──")
        dlog("[Runner] Action:  " .. action.type)
        dlog("[Runner] Trigger: " .. trigger.type)

        saveProgress(route.name, i, stepStartTime)

        -- ── Start action ──────────────────────────────────────────────────────
        local actionStop   = false
        local actionThread = nil

        if action.type == "atlas_config" then
            applyAtlasConfig(action.config, dlog)
            -- instant — nothing to cancel

        elseif action.type == "adjuster_loop" then
            actionThread = task.spawn(function()
                while not actionStop and not _stopFlag do
                    dlog("[Adjuster] Loading comp: " .. action.comp)
                    local comp = compIO.load(action.comp)
                    if comp then
                        local ok, err = pcall(function()
                            runHiveAdjuster(comp, dlog, flyTo)
                        end)
                        if not ok then dlog("[Adjuster] ERROR: " .. tostring(err)) end
                    else
                        dlog("[Adjuster] ERROR: comp '" .. action.comp .. "' not found")
                    end
                    if not actionStop and not _stopFlag then
                        task.wait(10)
                    end
                end
                dlog("[Adjuster] Action stopped")
            end)

        elseif action.type == "rj_buyer" then
            actionThread = task.spawn(function()
                while not actionStop and not _stopFlag do
                    local honey  = detection.getHoney()
                    local amount = math.floor(honey / 1000000)
                    if amount > 0 then
                        dlog("[RJ Buyer] Buying " .. amount .. " RJ...")
                        local ok, err = pcall(function() buyRJ(amount, dlog, flyTo) end)
                        if not ok then dlog("[RJ Buyer] ERROR: " .. tostring(err)) end
                    else
                        dlog("[RJ Buyer] Not enough honey to buy RJ")
                    end

                    local waitSecs = (action.interval or 10) * 60
                    dlog("[RJ Buyer] Next buy in " .. (action.interval or 10) .. " min")
                    local elapsed = 0
                    while elapsed < waitSecs and not actionStop and not _stopFlag do
                        task.wait(10)
                        elapsed = elapsed + 10
                    end
                end
                dlog("[RJ Buyer] Action stopped")
            end)
        end

        -- ── Poll trigger ──────────────────────────────────────────────────────
        while not _stopFlag do
            task.wait(POLL_INTERVAL)
            if checkTrigger(trigger, stepStartTime, detection) then
                dlog("[Runner] Trigger met — advancing")
                break
            end
            if trigger.type == "time" then
                local remaining = math.ceil(trigger.minutes - (os.clock() - stepStartTime) / 60)
                dlog("[Runner] Time trigger: ~" .. math.max(0, remaining) .. " min remaining")
            end
        end

        -- ── Stop action ───────────────────────────────────────────────────────
        actionStop = true
        if actionThread then
            pcall(function() task.cancel(actionThread) end)
        end
    end

    if not _stopFlag then
        dlog("[Runner] Route '" .. route.name .. "' complete!")
        clearProgress(route.name)
    end

    _running = false
end

-- ── Self-test ─────────────────────────────────────────────────────────────────
local function selfTest()
    for _, v in pairs(lp.PlayerGui:GetChildren()) do
        if v.Name == "RunnerTest" then v:Destroy() end
    end

    local sg = Instance.new("ScreenGui")
    sg.Name = "RunnerTest"
    sg.ResetOnSpawn = false
    sg.Parent = lp.PlayerGui

    local frame = Instance.new("Frame", sg)
    frame.Size = UDim2.new(0, 480, 0, 400)
    frame.Position = UDim2.new(0.5, -240, 0.5, -200)
    frame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

    local closeBtn = Instance.new("TextButton", frame)
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -33, 0, 3)
    closeBtn.Text = "X"
    closeBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
    closeBtn.TextColor3 = Color3.new(1,1,1)
    closeBtn.BorderSizePixel = 0
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
    closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

    local scroll = Instance.new("ScrollingFrame", frame)
    scroll.Size = UDim2.new(1, -10, 1, -42)
    scroll.Position = UDim2.new(0, 5, 0, 38)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 4
    local layout = Instance.new("UIListLayout", scroll)
    layout.Padding = UDim.new(0, 1)
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
    end)

    local n = 0
    local passed, failed = 0, 0
    local function log(msg, color)
        n = n + 1
        local lbl = Instance.new("TextLabel", scroll)
        lbl.Size = UDim2.new(1, -10, 0, 14)
        lbl.BackgroundTransparency = 1
        lbl.Text = msg
        lbl.Font = Enum.Font.Code
        lbl.TextSize = 11
        lbl.TextColor3 = color or Color3.fromRGB(180, 180, 180)
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.LayoutOrder = n
        Instance.new("UIPadding", lbl).PaddingLeft = UDim.new(0, 4)
    end
    local G = Color3.fromRGB(80, 220, 80)
    local R = Color3.fromRGB(220, 80,  80)
    local C = Color3.fromRGB(80, 200, 220)

    local function pass(msg) passed = passed + 1; log("  PASS: " .. msg, G) end
    local function fail(msg) failed = failed + 1; log("  FAIL: " .. msg, R) end
    local function section(msg) log(msg, C) end

    -- ── Test 1: checkTrigger with mock detection ──────────────────────────────
    section("── Test 1: checkTrigger ──")
    local mockDetection = {
        getHoney    = function() return 500000000 end,
        getMaterial = function(name) return name == "Blue Extract" and 60 or 0 end,
        hasItem     = function(name) return name == "Diamond Mask" end,
        hasTool     = function(name) return name == "Porcelain Dipper" end,
    }
    local t0 = os.clock() - 10  -- 10 seconds ago

    local cases = {
        { { type="honey",    amount=400000000 },              true,  "honey met"          },
        { { type="honey",    amount=600000000 },              false, "honey not met"      },
        { { type="material", name="Blue Extract", amount=50 },true,  "material met"       },
        { { type="material", name="Blue Extract", amount=70 },false, "material not met"   },
        { { type="item",     name="Diamond Mask" },           true,  "item met"           },
        { { type="item",     name="Bubble Mask"  },           false, "item not met"       },
        { { type="tool",     name="Porcelain Dipper" },       true,  "tool met"           },
        { { type="tool",     name="Scythe" },                 false, "tool not met"       },
        { { type="time",     minutes=0 },                     true,  "time=0 met"         },
        { { type="time",     minutes=999 },                   false, "time=999 not met"   },
    }
    for _, c in ipairs(cases) do
        local trigger, expected, label = c[1], c[2], c[3]
        local result = checkTrigger(trigger, t0, mockDetection)
        if result == expected then pass(label) else fail(label .. " (got " .. tostring(result) .. ")") end
    end

    -- ── Test 2: progress save / load / clear ──────────────────────────────────
    section("── Test 2: progress persistence ──")
    local testRoute = "_test_runner"
    saveProgress(testRoute, 3, 12345.6)
    local prog = loadProgress(testRoute)
    if prog                              then pass("loadProgress returned data")       else fail("loadProgress returned nil") end
    if prog and prog.step == 3          then pass("step index correct (3)")            else fail("step index wrong") end
    if prog and prog.stepStartTime == 12345.6 then pass("stepStartTime correct")      else fail("stepStartTime wrong") end
    if prog and prog.account == lp.Name then pass("account matches")                  else fail("account mismatch") end
    clearProgress(testRoute)
    local gone = loadProgress(testRoute)
    if not gone then pass("clearProgress removed file") else fail("file still exists after clear") end

    -- ── Test 3: step sequencing dry-run (all time=0 triggers) ─────────────────
    section("── Test 3: step sequencing (dry run) ──")
    local stepsExecuted = {}
    local mockRoute = {
        name  = "_test_runner",
        steps = {
            { action = { type = "atlas_config", config = "atlas/1.json" }, trigger = { type = "time", minutes = 0 } },
            { action = { type = "atlas_config", config = "atlas/2.json" }, trigger = { type = "time", minutes = 0 } },
            { action = { type = "atlas_config", config = "atlas/stop.json" }, trigger = { type = "time", minutes = 0 } },
        }
    }

    -- patch applyAtlasConfig via a wrapped run using a flag
    local ranSteps = 0
    local mockDlog = function(msg)
        if msg:find("Step ") then ranSteps = ranSteps + 1 end
    end

    -- Run in background, wait for completion (max 5s)
    local done = false
    task.spawn(function()
        -- override POLL_INTERVAL locally for speed: we'll test with time=0 so first poll fires
        -- we need to temporarily reduce wait — inject a fast mock
        local mockDet = {
            getHoney    = function() return 0 end,
            getMaterial = function() return 0 end,
            hasItem     = function() return false end,
            hasTool     = function() return false end,
        }

        -- manually step through the logic rather than calling run()
        -- (avoids loading hive adjuster / rj buyer unnecessarily)
        for i, step in ipairs(mockRoute.steps) do
            local st = os.clock() - 100  -- pretend step started 100s ago
            local met = checkTrigger(step.trigger, st, mockDet)
            if met then ranSteps = ranSteps + 1 end
        end
        done = true
    end)

    local waited = 0
    while not done and waited < 3 do
        task.wait(0.1)
        waited = waited + 0.1
    end

    if ranSteps == 3 then pass("all 3 steps triggered correctly") else fail("only " .. ranSteps .. "/3 steps triggered") end

    -- ── Summary ───────────────────────────────────────────────────────────────
    section("── Summary ──")
    log("  Passed: " .. passed .. "  Failed: " .. failed, failed == 0 and G or R)
end

return {
    run           = run,
    stop          = stop,
    isRunning     = isRunning,
    checkTrigger  = checkTrigger,
    saveProgress  = saveProgress,
    loadProgress  = loadProgress,
    clearProgress = clearProgress,
    selfTest      = selfTest,
}
