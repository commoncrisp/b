local HttpService = game:GetService("HttpService")

-- ── Route file naming ─────────────────────────────────────────────────────────
local PREFIX = "bss_route_"
local SUFFIX = ".json"

local function fileName(name)
    return PREFIX .. name .. SUFFIX
end

-- ── Action types ──────────────────────────────────────────────────────────────
--
--  atlas_config   → swap atlas preset
--    config         string   e.g. "atlas/1.json", "atlas/stop.json"
--
--  adjuster_loop  → run hive adjuster + atlas loop until comp satisfied
--    comp           string   e.g. "4r4b", "legendary", "diamond_hive"
--
--  rj_buyer       → buy RJ every N minutes
--    interval       number   minutes between buys (1–300)
--
-- ── Trigger types ─────────────────────────────────────────────────────────────
--
--  honey          → honey reaches a target amount
--    amount         number
--
--  material       → a material reaches a target count
--    name           string   display name e.g. "Blue Extract"
--    amount         number
--
--  item           → player owns a specific item (mask/guard/belt/boots/glider)
--    name           string   display name e.g. "Diamond Mask"
--
--  tool           → player owns a specific tool or bag (backpack scan)
--    name           string   display name e.g. "Porcelain Dipper"
--
--  time           → N minutes have passed since the step started
--    minutes        number

-- ── Validation ────────────────────────────────────────────────────────────────
local VALID_ACTION_TYPES  = { atlas_config=true, adjuster_loop=true, rj_buyer=true, sprout_hopper=true }
local VALID_TRIGGER_TYPES = { honey=true, material=true, item=true, tool=true, time=true }

local function validateStep(step, i)
    local prefix = "Step " .. i .. ": "
    if type(step) ~= "table" then return prefix .. "must be a table" end

    -- action
    local a = step.action
    if type(a) ~= "table" then return prefix .. "action missing" end
    if not VALID_ACTION_TYPES[a.type] then
        return prefix .. "unknown action type '" .. tostring(a.type) .. "'"
    end
    if a.type == "atlas_config" and type(a.config) ~= "string" then
        return prefix .. "atlas_config needs a config string"
    end
    if a.type == "adjuster_loop" and type(a.comp) ~= "string" then
        return prefix .. "adjuster_loop needs a comp string"
    end
    if a.type == "rj_buyer" then
        if type(a.interval) ~= "number" or a.interval < 1 or a.interval > 300 then
            return prefix .. "rj_buyer interval must be 1–300 minutes"
        end
    end

    -- trigger
    local t = step.trigger
    if type(t) ~= "table" then return prefix .. "trigger missing" end
    if not VALID_TRIGGER_TYPES[t.type] then
        return prefix .. "unknown trigger type '" .. tostring(t.type) .. "'"
    end
    if (t.type == "honey" or t.type == "time") and type(t.amount or t.minutes) ~= "number" then
        return prefix .. t.type .. " trigger needs a number"
    end
    if t.type == "honey"    and type(t.amount)  ~= "number" then return prefix .. "honey trigger needs amount" end
    if t.type == "time"     and type(t.minutes) ~= "number" then return prefix .. "time trigger needs minutes" end
    if t.type == "material" and type(t.name)    ~= "string" then return prefix .. "material trigger needs name" end
    if t.type == "material" and type(t.amount)  ~= "number" then return prefix .. "material trigger needs amount" end
    if t.type == "item"     and type(t.name)    ~= "string" then return prefix .. "item trigger needs name" end
    if t.type == "tool"     and type(t.name)    ~= "string" then return prefix .. "tool trigger needs name" end

    return nil -- no error
end

local function validate(route)
    if type(route) ~= "table"        then return "route must be a table" end
    if type(route.name) ~= "string"  then return "route.name must be a string" end
    if type(route.steps) ~= "table"  then return "route.steps must be a table" end
    if #route.steps == 0             then return "route has no steps" end
    for i, step in ipairs(route.steps) do
        local err = validateStep(step, i)
        if err then return err end
    end
    return nil
end

-- ── Save / load / list / delete ───────────────────────────────────────────────
local function save(route)
    local err = validate(route)
    if err then return false, "Validation failed: " .. err end
    local ok, encErr = pcall(function()
        writefile(fileName(route.name), HttpService:JSONEncode(route))
    end)
    if not ok then return false, "Write failed: " .. tostring(encErr) end
    return true, nil
end

local function load(name)
    local ok, result = pcall(function()
        return HttpService:JSONDecode(readfile(fileName(name)))
    end)
    if not ok then return nil, "Could not read file: " .. tostring(result) end
    local err = validate(result)
    if err then return nil, "Invalid route in file: " .. err end
    return result, nil
end

local function list()
    local routes = {}
    pcall(function()
        for _, f in pairs(listfiles("")) do
            local name = f:match(PREFIX .. "(.+)" .. SUFFIX .. "$")
            if name then
                table.insert(routes, name)
            end
        end
    end)
    return routes
end

local function delete(name)
    local ok, err = pcall(function() delfile(fileName(name)) end)
    return ok, err
end

-- ── Self-test ─────────────────────────────────────────────────────────────────
local function selfTest()
    local Players = game:GetService("Players")
    local lp      = Players.LocalPlayer

    for _, v in pairs(lp.PlayerGui:GetChildren()) do
        if v.Name == "RouteIOTest" then v:Destroy() end
    end

    local sg = Instance.new("ScreenGui")
    sg.Name = "RouteIOTest"
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
    local W = Color3.fromRGB(180, 180, 180)

    local function pass(msg) passed = passed + 1; log("  PASS: " .. msg, G) end
    local function fail(msg) failed = failed + 1; log("  FAIL: " .. msg, R) end
    local function section(msg) log(msg, C) end

    -- ── Test 1: valid route saves and loads back correctly ────────────────────
    section("── Test 1: save + load round-trip ──")
    local sample = {
        name  = "_test_route",
        steps = {
            {
                action  = { type = "atlas_config", config = "atlas/1.json" },
                trigger = { type = "honey", amount = 500000000 }
            },
            {
                action  = { type = "adjuster_loop", comp = "4r4b" },
                trigger = { type = "material", name = "Blue Extract", amount = 50 }
            },
            {
                action  = { type = "rj_buyer", interval = 10 },
                trigger = { type = "item", name = "Diamond Mask" }
            },
            {
                action  = { type = "atlas_config", config = "atlas/stop.json" },
                trigger = { type = "time", minutes = 60 }
            },
        }
    }

    local saveOk, saveErr = save(sample)
    if saveOk then pass("saved '_test_route'") else fail("save failed: " .. tostring(saveErr)) end

    local loaded, loadErr = load("_test_route")
    if loaded then
        pass("loaded '_test_route'")
        if loaded.name == sample.name then pass("name matches") else fail("name mismatch") end
        if #loaded.steps == #sample.steps then pass("step count matches (" .. #loaded.steps .. ")") else fail("step count wrong") end
        if loaded.steps[1].action.config == "atlas/1.json" then pass("step 1 action.config correct") else fail("step 1 action.config wrong") end
        if loaded.steps[2].trigger.amount == 50 then pass("step 2 trigger.amount correct") else fail("step 2 trigger.amount wrong") end
        if loaded.steps[3].trigger.name == "Diamond Mask" then pass("step 3 trigger.name correct") else fail("step 3 trigger.name wrong") end
        if loaded.steps[4].trigger.minutes == 60 then pass("step 4 trigger.minutes correct") else fail("step 4 trigger.minutes wrong") end
    else
        fail("load failed: " .. tostring(loadErr))
    end

    -- ── Test 2: list() finds the saved route ──────────────────────────────────
    section("── Test 2: list ──")
    local found = false
    for _, name in pairs(list()) do
        if name == "_test_route" then found = true end
    end
    if found then pass("list() found '_test_route'") else fail("list() did not find '_test_route'") end

    -- ── Test 3: delete removes it ─────────────────────────────────────────────
    section("── Test 3: delete ──")
    local delOk = delete("_test_route")
    if delOk then pass("deleted '_test_route'") else fail("delete failed") end
    local reloaded, _ = load("_test_route")
    if not reloaded then pass("confirmed gone after delete") else fail("file still exists after delete") end

    -- ── Test 4: validation rejects bad routes ─────────────────────────────────
    section("── Test 4: validation ──")
    local function expectFail(label, badRoute)
        local err = validate(badRoute)
        if err then pass(label .. " rejected: " .. err) else fail(label .. " was not rejected") end
    end
    expectFail("no steps",       { name = "x", steps = {} })
    expectFail("missing action", { name = "x", steps = { { trigger = { type = "time", minutes = 1 } } } })
    expectFail("bad action type",{ name = "x", steps = { { action = { type = "nope" }, trigger = { type = "time", minutes = 1 } } } })
    expectFail("rj bad interval",{ name = "x", steps = { { action = { type = "rj_buyer", interval = 999 }, trigger = { type = "time", minutes = 1 } } } })
    expectFail("missing trigger",{ name = "x", steps = { { action = { type = "atlas_config", config = "atlas/1.json" } } } })

    -- ── Summary ───────────────────────────────────────────────────────────────
    section("── Summary ──")
    log("  Passed: " .. passed .. "  Failed: " .. failed, failed == 0 and G or R)
end

return {
    save     = save,
    load     = load,
    list     = list,
    delete   = delete,
    validate = validate,
    selfTest = selfTest,
}

