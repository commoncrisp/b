local rawBase = "https://raw.githubusercontent.com/commoncrisp/b/main/"

local function init()
    local debugConsole = loadstring(game:HttpGet(rawBase .. "shared/debug_console.lua"))()
    local dlog = debugConsole.log
    local webhook = loadstring(game:HttpGet(rawBase .. "shared/webhook.lua"))()
    local flyTo = loadstring(game:HttpGet(rawBase .. "shared/fly_to.lua"))()
    local gui = loadstring(game:HttpGet(rawBase .. "shared/gui.lua"))()

    local beeAbilities = loadstring(game:HttpGet(rawBase .. "data/bee_abilities.lua"))()
    local compIO = loadstring(game:HttpGet(rawBase .. "modules/hive_adjuster/comp_io.lua"))()
    local buildCompBuilder = loadstring(game:HttpGet(rawBase .. "modules/hive_adjuster/comp_builder.lua"))()
    local runHiveAdjuster = loadstring(game:HttpGet(rawBase .. "modules/hive_adjuster/init.lua"))()

    local runBtn, getComp = buildCompBuilder(gui.adjusterTabFrame, beeAbilities, compIO, dlog)

    runBtn.MouseButton1Click:Connect(function()
        dlog("Adjuster run clicked!")
        local comp = getComp()
        if not comp or #comp.requirements == 0 then
            dlog("ERROR: No requirements set in comp!")
            return
        end
        task.spawn(function()
            local ok, err = pcall(function()
                runHiveAdjuster(comp, dlog, flyTo)
            end)
            if not ok then
                dlog("ERROR: " .. tostring(err))
            end
        end)
    end)

    debugConsole.setVisible(gui.config.debugEnabled)

    task.spawn(function()
        while task.wait(1) do
            debugConsole.setVisible(gui.config.debugEnabled)
        end
    end)

    dlog("BSS Tools loaded!")
    dlog("Webhook: " .. (gui.config.webhookUrl ~= "" and "SET" or "NOT SET"))
    dlog("Debug: " .. tostring(gui.config.debugEnabled))
    dlog("Fuzzy Alt Auto Run: " .. tostring(gui.config.fuzzyAltAutoRun))

    gui.onScan(function()
        dlog("Scan button clicked!")
        if gui.config.webhookUrl == "" then
            dlog("ERROR: No webhook URL set — go to Settings tab!")
            return
        end
        dlog("Starting hive scan...")
        local ok, err = pcall(function()
            local hiveScanner = loadstring(game:HttpGet(rawBase .. "modules/hive_scanner/init.lua"))()
            hiveScanner(dlog, webhook, gui.config)
        end)
        if not ok then dlog("ERROR: " .. tostring(err)) end
    end)

    gui.onRJBuy(function(amount)
        dlog("RJ buy requested: " .. tostring(amount))
        if not amount or amount < 1 then
            dlog("ERROR: Invalid amount!")
            return
        end
        task.spawn(function()
            local buyRJ = loadstring(game:HttpGet(rawBase .. "modules/rj_buyer/init.lua"))()
            local ok, err = pcall(function()
                buyRJ(amount, dlog, flyTo)
            end)
            if not ok then dlog("ERROR: " .. tostring(err)) end
        end)
    end)

    -- ── Fuzzy Alt ──────────────────────────────────────────────────
    local fuzzyAltRunning = false

    local function runFuzzyAlt()
        if fuzzyAltRunning then
            dlog("Fuzzy Alt is already running!")
            return
        end
        fuzzyAltRunning = true
        dlog("Loading Fuzzy Alt script...")
        task.spawn(function()
            local ok, err = pcall(function()
                local fuzzyAlt = loadstring(game:HttpGet(rawBase .. "modules/fuzzy_alt/init.lua"))()
                fuzzyAlt(dlog, flyTo, compIO, beeAbilities)
            end)
            fuzzyAltRunning = false
            if not ok then
                dlog("ERROR (Fuzzy Alt): " .. tostring(err))
            end
            -- refresh the status display after it finishes or errors
            if gui.refreshFuzzyStatus then
                gui.refreshFuzzyStatus()
            end
        end)
    end

    gui.onFuzzyAlt(runFuzzyAlt)

    -- auto run on startup if enabled
    if gui.config.fuzzyAltAutoRun then
        dlog("Auto Run enabled — starting Fuzzy Alt...")
        task.wait(2) -- small delay to let the GUI settle
        runFuzzyAlt()
    end
    -- ── Routes ────────────────────────────────────────────────────────
    local detection   = loadstring(game:HttpGet(rawBase .. "shared/detection.lua"))()
    local routeRunner = loadstring(game:HttpGet(rawBase .. "shared/route_runner.lua"))()

    gui.onOpenBuilder(function()
        local builder = loadstring(game:HttpGet(rawBase .. "modules/routes/builder.lua"))()
        builder.open(function(route)
            dlog("Starting route: " .. route.name)
            gui.setRouteStatus("▶ Running: " .. route.name)
            task.spawn(function()
                local ok, err = pcall(function()
                    routeRunner.run(route, dlog, flyTo, detection)
                end)
                if ok then
                    gui.setRouteStatus("✓ Completed: " .. route.name)
                    dlog("Route completed: " .. route.name)
                else
                    gui.setRouteStatus("✗ Error: " .. tostring(err))
                    dlog("Route error: " .. tostring(err))
                end
            end)
        end)
    end)

    gui.onStopRoute(function()
        routeRunner.stop()
        gui.setRouteStatus("⏹ Stopped")
        dlog("Route stopped by user")
    end)

end

return init
