local Players     = game:GetService("Players")
local lp          = Players.LocalPlayer
local RAW_BASE    = "https://raw.githubusercontent.com/commoncrisp/b/main/"
local ACTION_TYPES  = { "atlas_config", "adjuster_loop", "rj_buyer" }
local TRIGGER_TYPES = { "honey", "material", "item", "tool", "time" }
local ATLAS_OPTIONS = { "atlas/1.json","atlas/2.json","atlas/stop.json","atlas/diamond mats.json","atlas/diamond mats vial.json","atlas/diamond honey.json" }
local ATLAS_OPTIONS_OPT = { "none","atlas/1.json","atlas/2.json","atlas/stop.json","atlas/diamond mats.json","atlas/diamond mats vial.json","atlas/diamond honey.json" }


-- ── GUI helpers ───────────────────────────────────────────────────────────────
local function corner(p, r) Instance.new("UICorner", p).CornerRadius = UDim.new(0, r or 6) end
local function pad(p, l, r, t, b)
    local u = Instance.new("UIPadding", p)
    u.PaddingLeft = UDim.new(0, l or 0); u.PaddingRight  = UDim.new(0, r or 0)
    u.PaddingTop  = UDim.new(0, t or 0); u.PaddingBottom = UDim.new(0, b or 0)
end

local function lbl(parent, text, size, pos, fs, color, bold)
    local l = Instance.new("TextLabel", parent)
    l.Size = size; l.Position = pos or UDim2.new(0,0,0,0)
    l.BackgroundTransparency = 1; l.Text = text
    l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
    l.TextSize = fs or 11; l.TextColor3 = color or Color3.fromRGB(170,170,170)
    l.TextXAlignment = Enum.TextXAlignment.Left
    return l
end

local function btn(parent, text, size, pos, bg, tc)
    local b = Instance.new("TextButton", parent)
    b.Size = size; b.Position = pos or UDim2.new(0,0,0,0)
    b.BackgroundColor3 = bg or Color3.fromRGB(38,38,38)
    b.Text = text; b.Font = Enum.Font.GothamBold
    b.TextSize = 11; b.TextColor3 = tc or Color3.fromRGB(200,200,200)
    b.BorderSizePixel = 0; corner(b)
    return b
end

local function input(parent, size, pos, placeholder)
    local b = Instance.new("TextBox", parent)
    b.Size = size; b.Position = pos or UDim2.new(0,0,0,0)
    b.BackgroundColor3 = Color3.fromRGB(28,28,28); b.BorderSizePixel = 0
    b.Text = ""; b.PlaceholderText = placeholder or ""
    b.PlaceholderColor3 = Color3.fromRGB(70,70,70)
    b.Font = Enum.Font.Code; b.TextSize = 11
    b.TextColor3 = Color3.fromRGB(200,200,200)
    b.ClearTextOnFocus = false; b.TextXAlignment = Enum.TextXAlignment.Left
    corner(b); pad(b, 8)
    return b
end

local function scroll(parent, size, pos)
    local s = Instance.new("ScrollingFrame", parent)
    s.Size = size; s.Position = pos or UDim2.new(0,0,0,0)
    s.BackgroundTransparency = 1; s.BorderSizePixel = 0
    s.ScrollBarThickness = 4; s.CanvasSize = UDim2.new(0,0,0,0)
    local l = Instance.new("UIListLayout", s)
    l.Padding = UDim.new(0, 4)
    l:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        s.CanvasSize = UDim2.new(0,0,0, l.AbsoluteContentSize.Y + 10)
    end)
    return s
end

local function makeDropdown(parent, options, size, pos, onChange)
    local ITEM_H, MAX_V = 26, 5
    local selected = options[1]
    local open = false

    local c = Instance.new("Frame", parent)
    c.Size = size; c.Position = pos or UDim2.new(0,0,0,0)
    c.BackgroundTransparency = 1; c.ClipsDescendants = false; c.ZIndex = 10

    local b = Instance.new("TextButton", c)
    b.Size = UDim2.new(1, 0, 0, size.Y.Offset)
    b.BackgroundColor3 = Color3.fromRGB(28,28,28); b.BorderSizePixel = 0
    b.Font = Enum.Font.GothamBold; b.TextSize = 11
    b.TextColor3 = Color3.fromRGB(200,200,200)
    b.TextXAlignment = Enum.TextXAlignment.Left; b.ZIndex = 10
    corner(b); pad(b, 8)

    local arrow = Instance.new("TextLabel", b)
    arrow.Size = UDim2.new(0,20,1,0); arrow.Position = UDim2.new(1,-24,0,0)
    arrow.BackgroundTransparency = 1; arrow.Text = "▼"; arrow.ZIndex = 10
    arrow.Font = Enum.Font.GothamBold; arrow.TextSize = 10
    arrow.TextColor3 = Color3.fromRGB(120,120,120)

    local listH = math.min(#options, MAX_V) * ITEM_H
    local list = Instance.new("ScrollingFrame", c)
    list.Size = UDim2.new(1,0,0,listH)
    list.Position = UDim2.new(0,0,0, size.Y.Offset + 2)
    list.BackgroundColor3 = Color3.fromRGB(24,24,24); list.BorderSizePixel = 0
    list.Visible = false; list.ZIndex = 20; list.ScrollBarThickness = 4
    list.CanvasSize = UDim2.new(0,0,0, #options * ITEM_H)
    corner(list); Instance.new("UIListLayout", list)

    local function setValue(opt)
        selected = opt; b.Text = opt
        open = false; list.Visible = false; arrow.Text = "▼"
        if onChange then onChange(opt) end
    end

    for _, opt in ipairs(options) do
        local item = Instance.new("TextButton", list)
        item.Size = UDim2.new(1,0,0,ITEM_H); item.BackgroundTransparency = 1
        item.Font = Enum.Font.Gotham; item.TextSize = 11
        item.TextColor3 = Color3.fromRGB(180,180,180)
        item.TextXAlignment = Enum.TextXAlignment.Left
        item.BorderSizePixel = 0; item.ZIndex = 20; item.Text = "  " .. opt
        item.MouseEnter:Connect(function() item.BackgroundTransparency = 0; item.BackgroundColor3 = Color3.fromRGB(38,38,38) end)
        item.MouseLeave:Connect(function() item.BackgroundTransparency = 1 end)
        item.MouseButton1Click:Connect(function() setValue(opt) end)
    end

    b.MouseButton1Click:Connect(function()
        open = not open; list.Visible = open; arrow.Text = open and "▲" or "▼"
    end)

    setValue(options[1])
    return { getValue = function() return selected end, setValue = setValue }
end

-- ── Open ──────────────────────────────────────────────────────────────────────
local function open(onRun)
    for _, v in pairs(lp.PlayerGui:GetChildren()) do
        if v.Name == "RouteBuilder" then v:Destroy() end
    end

    local routeIO = loadstring(game:HttpGet(RAW_BASE .. "shared/route_io.lua"))()

    local sg = Instance.new("ScreenGui")
    sg.Name = "RouteBuilder"; sg.ResetOnSpawn = false; sg.Parent = lp.PlayerGui

    local win = Instance.new("Frame", sg)
    win.Size = UDim2.new(0,620,0,500); win.Position = UDim2.new(0.5,-310,0.5,-250)
    win.BackgroundColor3 = Color3.fromRGB(18,18,18); win.BorderSizePixel = 0
    win.Active = true; win.Draggable = true; corner(win, 8)

    local tb = Instance.new("Frame", win)
    tb.Size = UDim2.new(1,0,0,36); tb.BackgroundColor3 = Color3.fromRGB(12,12,12); tb.BorderSizePixel = 0; corner(tb, 8)
    lbl(tb, "ROUTE BUILDER", UDim2.new(1,-40,1,0), UDim2.new(0,14,0,0), 13, Color3.fromRGB(220,220,220), true)
    local xBtn = btn(tb, "✕", UDim2.new(0,30,0,30), UDim2.new(1,-33,0,3), Color3.fromRGB(180,50,50), Color3.new(1,1,1))
    xBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

    local content = Instance.new("Frame", win)
    content.Size = UDim2.new(1,0,1,-36); content.Position = UDim2.new(0,0,0,36)
    content.BackgroundTransparency = 1; content.BorderSizePixel = 0

    -- panels
    local panels = {}
    local function showPanel(name)
        for k, p in pairs(panels) do p.Visible = (k == name) end
    end

    -- shared state
    local editingSteps     = {}
    local editingName      = ""
    local editingStepIdx   = nil
    local currentAction    = {}
    local currentTrigger   = {}

    local refreshRouteList, refreshEditor, loadStepEditor  -- forward declarations

    -- ════════════════════════════════════════════════════════════════
    --  PANEL 1 — Route List
    -- ════════════════════════════════════════════════════════════════
    local listPanel = Instance.new("Frame", content)
    listPanel.Size = UDim2.new(1,0,1,0); listPanel.BackgroundTransparency = 1
    panels["list"] = listPanel

    btn(listPanel, "+ NEW ROUTE", UDim2.new(0,140,0,30), UDim2.new(0,14,0,10),
        Color3.fromRGB(30,60,30), Color3.fromRGB(100,220,100)).MouseButton1Click:Connect(function()
            editingName = "New Route"; editingSteps = {}
            refreshEditor(); showPanel("editor")
        end)

    local listScroll = scroll(listPanel, UDim2.new(1,-28,1,-58), UDim2.new(0,14,0,50))
    local emptyLbl = lbl(listScroll, "No routes yet. Click + NEW ROUTE.", UDim2.new(1,0,0,20), nil, 11, Color3.fromRGB(90,90,90))

    function refreshRouteList()
        for _, v in pairs(listScroll:GetChildren()) do
            if v:IsA("Frame") then v:Destroy() end
        end
        local routes = routeIO.list()
        emptyLbl.Visible = #routes == 0
        for _, name in ipairs(routes) do
            local row = Instance.new("Frame", listScroll)
            row.Size = UDim2.new(1,0,0,38); row.BackgroundColor3 = Color3.fromRGB(24,24,24); row.BorderSizePixel = 0; corner(row)
            lbl(row, name, UDim2.new(1,-220,1,0), UDim2.new(0,12,0,0), 12, Color3.fromRGB(210,210,210), true)

            local runB  = btn(row, "▶ RUN",  UDim2.new(0,62,0,26), UDim2.new(1,-210,0.5,-13), Color3.fromRGB(30,60,30),    Color3.fromRGB(100,220,100))
            local editB = btn(row, "✎ EDIT", UDim2.new(0,62,0,26), UDim2.new(1,-142,0.5,-13), Color3.fromRGB(28,28,50),    Color3.fromRGB(130,160,255))
            local delB  = btn(row, "✗ DEL",  UDim2.new(0,62,0,26), UDim2.new(1,-74, 0.5,-13), Color3.fromRGB(50,22,22),    Color3.fromRGB(220,80,80))

            local n = name
            runB.MouseButton1Click:Connect(function()
                if onRun then
                    local route = routeIO.load(n)
                    if route then sg:Destroy(); onRun(route) end
                end
            end)
            editB.MouseButton1Click:Connect(function()
                local route = routeIO.load(n)
                if route then
                    editingName = route.name
                    editingSteps = {}
                    for i, s in ipairs(route.steps) do
                        editingSteps[i] = {
                            action  = { type=s.action.type,  config=s.action.config,  comp=s.action.comp,  interval=s.action.interval },
                            trigger = { type=s.trigger.type, amount=s.trigger.amount, name=s.trigger.name, minutes=s.trigger.minutes },
                        }
                    end
                    refreshEditor(); showPanel("editor")
                end
            end)
            delB.MouseButton1Click:Connect(function()
                routeIO.delete(n); refreshRouteList()
            end)
        end
    end

    -- ════════════════════════════════════════════════════════════════
    --  PANEL 2 — Route Editor
    -- ════════════════════════════════════════════════════════════════
    local editorPanel = Instance.new("Frame", content)
    editorPanel.Size = UDim2.new(1,0,1,0); editorPanel.BackgroundTransparency = 1; editorPanel.Visible = false
    panels["editor"] = editorPanel

    lbl(editorPanel, "Name", UDim2.new(0,50,0,28), UDim2.new(0,14,0,10), 11, Color3.fromRGB(150,150,150))
    local nameBox = input(editorPanel, UDim2.new(0,280,0,28), UDim2.new(0,64,0,10), "Route name...")

    local stepsScroll = scroll(editorPanel, UDim2.new(1,-28,1,-110), UDim2.new(0,14,0,50))

    local addStepB  = btn(editorPanel, "+ ADD STEP",   UDim2.new(0,120,0,30), UDim2.new(0,14,1,-40),    Color3.fromRGB(28,28,50),  Color3.fromRGB(130,160,255))
    local saveRteB  = btn(editorPanel, "💾 SAVE",      UDim2.new(0,100,0,30), UDim2.new(0,144,1,-40),   Color3.fromRGB(30,60,30),  Color3.fromRGB(100,220,100))
    local edBackB   = btn(editorPanel, "← BACK",       UDim2.new(0,90,0,30),  UDim2.new(1,-104,1,-40),  Color3.fromRGB(38,38,38),  Color3.fromRGB(180,180,180))

    local function stepSummary(s)
        local a = s.action;  local t = s.trigger
        local aStr = a.type
        if a.type=="atlas_config"  then aStr = "atlas:" .. (a.config or "?"):match("([^/]+%.json)$"):gsub("%.json","") end
        if a.type=="adjuster_loop" then aStr = "adj:"   .. (a.comp or "?") end
        if a.type=="rj_buyer"      then aStr = "rj("    .. (a.interval or "?") .. "m)" end
        local tStr = t.type
        if t.type=="honey"    then tStr = "honey≥"  .. tostring(t.amount  or "?") end
        if t.type=="material" then tStr = (t.name or "?") .. "≥" .. tostring(t.amount or "?") end
        if t.type=="item"     then tStr = "item:" .. (t.name or "?") end
        if t.type=="tool"     then tStr = "tool:" .. (t.name or "?") end
        if t.type=="time"     then tStr = "time:" .. tostring(t.minutes or "?") .. "m" end
        return aStr .. "  →  " .. tStr
    end

    function refreshEditor()
        nameBox.Text = editingName
        for _, v in pairs(stepsScroll:GetChildren()) do
            if v:IsA("Frame") then v:Destroy() end
        end
        for i, step in ipairs(editingSteps) do
            local row = Instance.new("Frame", stepsScroll)
            row.Size = UDim2.new(1,0,0,36); row.BackgroundColor3 = Color3.fromRGB(24,24,24); row.BorderSizePixel = 0; corner(row)
            lbl(row, i .. ".  " .. stepSummary(step), UDim2.new(1,-168,1,0), UDim2.new(0,10,0,0), 10, Color3.fromRGB(190,190,190))
            local eB = btn(row, "✎", UDim2.new(0,28,0,24), UDim2.new(1,-160,0.5,-12), Color3.fromRGB(28,28,50), Color3.fromRGB(130,160,255))
            local uB = btn(row, "↑", UDim2.new(0,28,0,24), UDim2.new(1,-126,0.5,-12), Color3.fromRGB(30,30,30), Color3.fromRGB(180,180,180))
            local dB = btn(row, "↓", UDim2.new(0,28,0,24), UDim2.new(1,-92, 0.5,-12), Color3.fromRGB(30,30,30), Color3.fromRGB(180,180,180))
            local xB = btn(row, "✗", UDim2.new(0,28,0,24), UDim2.new(1,-58, 0.5,-12), Color3.fromRGB(50,22,22), Color3.fromRGB(220,80,80))
            local idx = i
            eB.MouseButton1Click:Connect(function() editingStepIdx = idx; loadStepEditor(editingSteps[idx]); showPanel("step") end)
            uB.MouseButton1Click:Connect(function()
                if idx > 1 then editingSteps[idx], editingSteps[idx-1] = editingSteps[idx-1], editingSteps[idx]; refreshEditor() end
            end)
            dB.MouseButton1Click:Connect(function()
                if idx < #editingSteps then editingSteps[idx], editingSteps[idx+1] = editingSteps[idx+1], editingSteps[idx]; refreshEditor() end
            end)
            xB.MouseButton1Click:Connect(function() table.remove(editingSteps, idx); refreshEditor() end)
        end
    end

    addStepB.MouseButton1Click:Connect(function() editingStepIdx = nil; loadStepEditor(nil); showPanel("step") end)

    saveRteB.MouseButton1Click:Connect(function()
        local name = nameBox.Text
        if name == "" then return end
        local ok, err = routeIO.save({ name = name, steps = editingSteps })
        if ok then
            editingName = name
            saveRteB.Text = "✓ SAVED"; saveRteB.TextColor3 = Color3.fromRGB(80,220,80)
            task.wait(1.5)
            saveRteB.Text = "💾 SAVE"; saveRteB.TextColor3 = Color3.fromRGB(100,220,100)
        else
            saveRteB.Text = "✗ " .. (err or "ERROR"); saveRteB.TextColor3 = Color3.fromRGB(220,80,80)
            task.wait(2)
            saveRteB.Text = "💾 SAVE"; saveRteB.TextColor3 = Color3.fromRGB(100,220,100)
        end
    end)

    edBackB.MouseButton1Click:Connect(function() refreshRouteList(); showPanel("list") end)

    -- ════════════════════════════════════════════════════════════════
    --  PANEL 3 — Step Editor
    -- ════════════════════════════════════════════════════════════════
    local stepPanel = Instance.new("Frame", content)
    stepPanel.Size = UDim2.new(1,0,1,0); stepPanel.BackgroundTransparency = 1; stepPanel.Visible = false
    panels["step"] = stepPanel

    local stepScroll = scroll(stepPanel, UDim2.new(1,-28,1,-50), UDim2.new(0,14,0,8))

    local confirmB = btn(stepPanel, "✓ CONFIRM", UDim2.new(0,110,0,30), UDim2.new(0,14,1,-40),   Color3.fromRGB(30,60,30),  Color3.fromRGB(100,220,100))
    local stBackB  = btn(stepPanel, "← BACK",    UDim2.new(0,90,0,30),  UDim2.new(1,-104,1,-40), Color3.fromRGB(38,38,38),  Color3.fromRGB(180,180,180))

    local acfFrames = {}  -- action config frames keyed by type
    local trFrames  = {}  -- trigger config frames keyed by type

    local function section(parent, title)
        local f = Instance.new("Frame", parent)
        f.BackgroundColor3 = Color3.fromRGB(20,20,20); f.BorderSizePixel = 0; corner(f)
        local fl = Instance.new("UIListLayout", f); fl.Padding = UDim.new(0,6)
        pad(f, 10, 10, 8, 8)
        fl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            f.Size = UDim2.new(1, 0, 0, fl.AbsoluteContentSize.Y + 16)
        end)
        lbl(f, title:upper(), UDim2.new(1,0,0,16), nil, 10, Color3.fromRGB(110,110,110), true)
        return f
    end

    local function row(parent)
        local r = Instance.new("Frame", parent)
        r.Size = UDim2.new(1,0,0,30); r.BackgroundTransparency = 1; return r
    end

    local function fieldRow(parent, labelText, widget)
        local r = row(parent)
        lbl(r, labelText, UDim2.new(0,100,1,0), UDim2.new(0,0,0,0), 11, Color3.fromRGB(150,150,150))
        widget.Size = UDim2.new(0,260,0,26); widget.Position = UDim2.new(0,104,0,2)
        widget.Parent = r
        return r
    end

    -- Action section
    local actSec   = section(stepScroll, "Action")
    local actTypeR = row(actSec)
    lbl(actTypeR, "Type", UDim2.new(0,100,1,0), UDim2.new(0,0,0,0), 11, Color3.fromRGB(150,150,150))
    local actTypeDd = makeDropdown(actTypeR, ACTION_TYPES, UDim2.new(0,200,0,28), UDim2.new(0,104,0,1), function(v)
        currentAction.type = v
        for t, f in pairs(acfFrames) do f.Visible = (t == v) end
    end)

    -- atlas_config fields
    local aAtlas  = row(actSec); acfFrames["atlas_config"] = aAtlas
    lbl(aAtlas, "Config", UDim2.new(0,100,1,0), UDim2.new(0,0,0,0), 11, Color3.fromRGB(150,150,150))
    local atlasDd = makeDropdown(aAtlas, ATLAS_OPTIONS, UDim2.new(0,350,0,28), UDim2.new(0,104,0,1), function(v) currentAction.config = v end)

    -- adjuster_loop fields
    local aAdj = Instance.new("Frame", actSec)
    aAdj.Size = UDim2.new(1,0,0,64); aAdj.BackgroundTransparency = 1; aAdj.Visible = false
    acfFrames["adjuster_loop"] = aAdj
    lbl(aAdj, "Comp name",    UDim2.new(0,100,0,26), UDim2.new(0,0,0,2),  11, Color3.fromRGB(150,150,150))
    local compBox = input(aAdj, UDim2.new(0,260,0,26), UDim2.new(0,104,0,2),  "e.g. 4r4b")
    compBox:GetPropertyChangedSignal("Text"):Connect(function() currentAction.comp = compBox.Text end)
    lbl(aAdj, "Atlas config", UDim2.new(0,100,0,26), UDim2.new(0,0,0,34), 11, Color3.fromRGB(150,150,150))
    local adjAtlasBox = input(aAdj, UDim2.new(0,260,0,26), UDim2.new(0,104,0,34), "e.g. atlas/1.json")
    adjAtlasBox:GetPropertyChangedSignal("Text"):Connect(function()
        currentAction.atlasConfig = adjAtlasBox.Text ~= "" and adjAtlasBox.Text or nil
    end)


    -- rj_buyer fields
    local aRJ = Instance.new("Frame", actSec)
    aRJ.Size = UDim2.new(1,0,0,64); aRJ.BackgroundTransparency = 1; aRJ.Visible = false
    acfFrames["rj_buyer"] = aRJ
    lbl(aRJ, "Interval (min)", UDim2.new(0,100,0,26), UDim2.new(0,0,0,2),  11, Color3.fromRGB(150,150,150))
    local intBox = input(aRJ, UDim2.new(0,120,0,26), UDim2.new(0,104,0,2),  "1–300 minutes")
    intBox:GetPropertyChangedSignal("Text"):Connect(function() currentAction.interval = tonumber(intBox.Text) end)
    lbl(aRJ, "Atlas config",   UDim2.new(0,100,0,26), UDim2.new(0,0,0,34), 11, Color3.fromRGB(150,150,150))
    local rjAtlasBox = input(aRJ, UDim2.new(0,260,0,26), UDim2.new(0,104,0,34), "e.g. atlas/1.json")
    rjAtlasBox:GetPropertyChangedSignal("Text"):Connect(function()
        currentAction.atlasConfig = rjAtlasBox.Text ~= "" and rjAtlasBox.Text or nil
    end)



    -- Trigger section
    local trgSec   = section(stepScroll, "Trigger")
    local trgTypeR = row(trgSec)
    lbl(trgTypeR, "Type", UDim2.new(0,100,1,0), UDim2.new(0,0,0,0), 11, Color3.fromRGB(150,150,150))
    local trgTypeDd = makeDropdown(trgTypeR, TRIGGER_TYPES, UDim2.new(0,200,0,28), UDim2.new(0,104,0,1), function(v)
        currentTrigger.type = v
        for t, f in pairs(trFrames) do f.Visible = (t == v) end
    end)

    -- honey
    local tHoney = row(trgSec); trFrames["honey"] = tHoney
    local honeyBox = input(nil, UDim2.new(), UDim2.new(), "e.g. 500000000")
    fieldRow(tHoney, "Amount", honeyBox)
    honeyBox:GetPropertyChangedSignal("Text"):Connect(function() currentTrigger.amount = tonumber(honeyBox.Text) end)

    -- material (two rows — need a wrapper frame)
    local tMat = Instance.new("Frame", trgSec); trFrames["material"] = tMat
    tMat.Size = UDim2.new(1,0,0,64); tMat.BackgroundTransparency = 1; tMat.Visible = false
    local matNameBox = input(nil, UDim2.new(), UDim2.new(), "e.g. Blue Extract")
    fieldRow(tMat, "Material", matNameBox)
    matNameBox:GetPropertyChangedSignal("Text"):Connect(function() currentTrigger.name = matNameBox.Text end)
    local matAmtBox = input(tMat, UDim2.new(0,120,0,26), UDim2.new(0,104,0,34), "e.g. 50")
    lbl(tMat, "Amount", UDim2.new(0,100,0,26), UDim2.new(0,0,0,34), 11, Color3.fromRGB(150,150,150))
    matAmtBox:GetPropertyChangedSignal("Text"):Connect(function() currentTrigger.amount = tonumber(matAmtBox.Text) end)

    -- item
    local tItem = row(trgSec); trFrames["item"] = tItem; tItem.Visible = false
    local itemBox = input(nil, UDim2.new(), UDim2.new(), "e.g. Diamond Mask")
    fieldRow(tItem, "Item name", itemBox)
    itemBox:GetPropertyChangedSignal("Text"):Connect(function() currentTrigger.name = itemBox.Text end)

    -- tool
    local tTool = row(trgSec); trFrames["tool"] = tTool; tTool.Visible = false
    local toolBox = input(nil, UDim2.new(), UDim2.new(), "e.g. Porcelain Dipper")
    fieldRow(tTool, "Tool name", toolBox)
    toolBox:GetPropertyChangedSignal("Text"):Connect(function() currentTrigger.name = toolBox.Text end)

    -- time
    local tTime = row(trgSec); trFrames["time"] = tTime; tTime.Visible = false
    local timeBox = input(nil, UDim2.new(), UDim2.new(), "e.g. 60")
    fieldRow(tTime, "Minutes", timeBox)
    timeBox:GetPropertyChangedSignal("Text"):Connect(function() currentTrigger.minutes = tonumber(timeBox.Text) end)

    -- ── loadStepEditor ────────────────────────────────────────────────────────
    function loadStepEditor(step)
        currentAction  = step and { type=step.action.type,  config=step.action.config,  comp=step.action.comp,  interval=step.action.interval }
                                or { type="atlas_config", config="atlas/1.json" }
        currentTrigger = step and { type=step.trigger.type, amount=step.trigger.amount, name=step.trigger.name, minutes=step.trigger.minutes }
                                or { type="time", minutes=60 }

        actTypeDd.setValue(currentAction.type)
        for t, f in pairs(acfFrames) do f.Visible = (t == currentAction.type) end
        atlasDd.setValue(currentAction.config or ATLAS_OPTIONS[1])
        compBox.Text = currentAction.comp or ""
        intBox.Text  = currentAction.interval and tostring(currentAction.interval) or ""

        adjAtlasBox.Text = currentAction.atlasConfig or ""
        rjAtlasBox.Text  = currentAction.atlasConfig or ""



        trgTypeDd.setValue(currentTrigger.type)
        for t, f in pairs(trFrames) do f.Visible = (t == currentTrigger.type) end
        honeyBox.Text   = currentTrigger.amount  and tostring(currentTrigger.amount)  or ""
        matNameBox.Text = currentTrigger.name    or ""
        matAmtBox.Text  = currentTrigger.amount  and tostring(currentTrigger.amount)  or ""
        itemBox.Text    = currentTrigger.name    or ""
        toolBox.Text    = currentTrigger.name    or ""
        timeBox.Text    = currentTrigger.minutes and tostring(currentTrigger.minutes) or ""
    end

    confirmB.MouseButton1Click:Connect(function()
        local newStep = {
            action  = { type=currentAction.type,  config=currentAction.config,  comp=currentAction.comp,  interval=currentAction.interval },
            trigger = { type=currentTrigger.type, amount=currentTrigger.amount, name=currentTrigger.name, minutes=currentTrigger.minutes },
        }
        if editingStepIdx then
            editingSteps[editingStepIdx] = newStep
        else
            table.insert(editingSteps, newStep)
        end
        refreshEditor(); showPanel("editor")
    end)

    stBackB.MouseButton1Click:Connect(function() showPanel("editor") end)

    -- ── Init ─────────────────────────────────────────────────────────────────
    refreshRouteList()
    showPanel("list")
end

return { open = open }
