-- modules/routes/builder.lua
local routeIO = loadstring(game:HttpGet("https://raw.githubusercontent.com/commoncrisp/b/main/shared/route_io.lua"))()

-- Dynamically scan atlas/ directory for .json config files
local ATLAS_OPTIONS = {}
pcall(function()
    for _, f in pairs(listfiles("atlas/")) do
        local name = f:match("([^/\\]+)$")
        if name and name:match("%.json$") then
            table.insert(ATLAS_OPTIONS, "atlas/" .. name)
        end
    end
end)
if #ATLAS_OPTIONS == 0 then
    ATLAS_OPTIONS = { "atlas/1.json" }  -- fallback if scan fails or folder empty
end
table.sort(ATLAS_OPTIONS)  -- alphabetical order

-- ── colours ──────────────────────────────────────────────────────────────────
local C = {
    bg      = Color3.fromRGB(30,  30,  40),
    panel   = Color3.fromRGB(40,  40,  55),
    accent  = Color3.fromRGB(80, 140, 255),
    btn     = Color3.fromRGB(55,  55,  75),
    btnHov  = Color3.fromRGB(70,  70,  95),
    red     = Color3.fromRGB(200, 60,  60),
    green   = Color3.fromRGB(60,  180, 80),
    text    = Color3.fromRGB(220, 220, 230),
    subtext = Color3.fromRGB(150, 150, 170),
}

-- ── helpers ───────────────────────────────────────────────────────────────────
local function corner(r, p) local c=Instance.new("UICorner",p) c.CornerRadius=UDim.new(0,r) end
local function pad(t,b,l,r,p) local u=Instance.new("UIPadding",p) u.PaddingTop=UDim.new(0,t) u.PaddingBottom=UDim.new(0,b) u.PaddingLeft=UDim.new(0,l) u.PaddingRight=UDim.new(0,r) end

local function label(text, parent, size, color)
    local l = Instance.new("TextLabel", parent)
    l.Text = text
    l.Size = size or UDim2.new(1,0,0,22)
    l.BackgroundTransparency = 1
    l.TextColor3 = color or C.text
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Font = Enum.Font.GothamMedium
    l.TextSize = 13
    return l
end

local function button(text, parent, size, color)
    local b = Instance.new("TextButton", parent)
    b.Text = text
    b.Size = size or UDim2.new(0,80,0,28)
    b.BackgroundColor3 = color or C.btn
    b.TextColor3 = C.text
    b.Font = Enum.Font.GothamMedium
    b.TextSize = 13
    b.AutoButtonColor = true
    corner(6, b)
    return b
end

local function input(parent, size, placeholder)
    local f = Instance.new("Frame", parent)
    f.Size = size or UDim2.new(1,0,0,28)
    f.BackgroundColor3 = Color3.fromRGB(25,25,35)
    corner(5, f)
    local tb = Instance.new("TextBox", f)
    tb.Size = UDim2.new(1,-10,1,0)
    tb.Position = UDim2.new(0,5,0,0)
    tb.BackgroundTransparency = 1
    tb.TextColor3 = C.text
    tb.PlaceholderText = placeholder or ""
    tb.PlaceholderColor3 = C.subtext
    tb.Font = Enum.Font.Gotham
    tb.TextSize = 12
    tb.TextXAlignment = Enum.TextXAlignment.Left
    tb.ClearTextOnFocus = false
    return f, tb
end

local function makeDropdown(parent, options, defaultIdx)
    local chosen = defaultIdx or 1
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1,0,0,28)
    frame.BackgroundColor3 = Color3.fromRGB(25,25,35)
    corner(5, frame)

    local display = Instance.new("TextButton", frame)
    display.Size = UDim2.new(1,-28,1,0)
    display.BackgroundTransparency = 1
    display.TextColor3 = C.text
    display.Font = Enum.Font.Gotham
    display.TextSize = 12
    display.TextXAlignment = Enum.TextXAlignment.Left
    display.Text = "  " .. (options[chosen] or "—")
    display.AutoButtonColor = false

    local arrow = Instance.new("TextLabel", frame)
    arrow.Size = UDim2.new(0,28,1,0)
    arrow.Position = UDim2.new(1,-28,0,0)
    arrow.BackgroundTransparency = 1
    arrow.TextColor3 = C.subtext
    arrow.Text = "▾"
    arrow.TextSize = 14
    arrow.Font = Enum.Font.GothamMedium

    local listFrame = nil
    local function closeList() if listFrame then listFrame:Destroy() listFrame=nil end end

    local function openList()
        closeList()
        listFrame = Instance.new("Frame", frame)
        listFrame.Size = UDim2.new(1,0,0,math.min(#options,6)*28)
        listFrame.Position = UDim2.new(0,0,1,2)
        listFrame.BackgroundColor3 = Color3.fromRGB(30,30,45)
        listFrame.ZIndex = 10
        corner(5, listFrame)

        local scroll = Instance.new("ScrollingFrame", listFrame)
        scroll.Size = UDim2.new(1,0,1,0)
        scroll.BackgroundTransparency = 1
        scroll.ScrollBarThickness = 4
        scroll.CanvasSize = UDim2.new(0,0,0,#options*28)
        scroll.ZIndex = 10

        local layout = Instance.new("UIListLayout", scroll)
        layout.SortOrder = Enum.SortOrder.LayoutOrder

        for i, opt in ipairs(options) do
            local ob = Instance.new("TextButton", scroll)
            ob.Size = UDim2.new(1,0,0,28)
            ob.BackgroundColor3 = (i==chosen) and C.accent or Color3.fromRGB(35,35,50)
            ob.TextColor3 = C.text
            ob.Font = Enum.Font.Gotham
            ob.TextSize = 12
            ob.TextXAlignment = Enum.TextXAlignment.Left
            ob.ZIndex = 11
            pad(0,0,8,0,ob)
            ob.Text = opt
            ob.LayoutOrder = i
            ob.MouseButton1Click:Connect(function()
                chosen = i
                display.Text = "  " .. opt
                closeList()
            end)
        end
    end

    display.MouseButton1Click:Connect(function() if listFrame then closeList() else openList() end end)
    arrow.MouseButton1Down:Connect(function() if listFrame then closeList() else openList() end end)

    return frame, function() return options[chosen] end, function(v)
        for i,o in ipairs(options) do if o==v then chosen=i display.Text="  "..o return end end
    end
end

local function scrollList(parent, size)
    local sf = Instance.new("ScrollingFrame", parent)
    sf.Size = size or UDim2.new(1,0,1,-40)
    sf.BackgroundTransparency = 1
    sf.ScrollBarThickness = 5
    sf.CanvasSize = UDim2.new(0,0,0,0)
    sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
    local layout = Instance.new("UIListLayout", sf)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0,4)
    return sf
end

-- ── step summary ──────────────────────────────────────────────────────────────
local function stepSummary(s)
    local a, t = s.action, s.trigger
    local aStr = a.type or "?"
    if a.type == "atlas_config" then
        aStr = "atlas: " .. (a.config or "?")
    elseif a.type == "adjuster_loop" then
        aStr = "adjuster(" .. (a.comp or "?") .. ")"
    elseif a.type == "rj_buyer" then
        aStr = "rj_buyer(every " .. (a.interval or "?") .. "s)"
    end
    local tStr = t.type or "?"
    if t.type == "honey"    then tStr = "≥"  ..(t.amount or "?").." honey"
    elseif t.type == "material" then tStr = "≥"  ..(t.amount or "?").." "..(t.name or "?")
    elseif t.type == "item"     then tStr = "own "..(t.name or "?")
    elseif t.type == "tool"     then tStr = "tool "..(t.name or "?")
    elseif t.type == "time"     then tStr = (t.minutes or "?").."min"
    end
    return aStr .. "  →  " .. tStr
end

-- ── main open function ────────────────────────────────────────────────────────
local M = {}

function M.open(onRun)
    local lp = game:GetService("Players").LocalPlayer
    local sg = Instance.new("ScreenGui")
    sg.Name = "BSSRoutesBuilder"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = lp.PlayerGui

    -- main window
    local win = Instance.new("Frame", sg)
    win.Size = UDim2.new(0,620,0,500)
    win.Position = UDim2.new(0.5,-310,0.5,-250)
    win.BackgroundColor3 = C.bg
    win.BorderSizePixel = 0
    corner(10, win)

    -- title bar / drag
    local titleBar = Instance.new("Frame", win)
    titleBar.Size = UDim2.new(1,0,0,36)
    titleBar.BackgroundColor3 = C.panel
    titleBar.BorderSizePixel = 0
    corner(10, titleBar)
    local titleFix = Instance.new("Frame", titleBar)
    titleFix.Size = UDim2.new(1,0,0.5,0)
    titleFix.Position = UDim2.new(0,0,0.5,0)
    titleFix.BackgroundColor3 = C.panel
    titleFix.BorderSizePixel = 0

    local titleL = label("BSS Routes Builder", titleBar, UDim2.new(1,-40,1,0))
    titleL.Position = UDim2.new(0,12,0,0)
    titleL.TextSize = 14

    local closeB = button("✕", titleBar, UDim2.new(0,28,0,28), C.red)
    closeB.Position = UDim2.new(1,-32,0,4)
    closeB.MouseButton1Click:Connect(function() sg:Destroy() end)

    -- drag
    do
        local drag, dragStart, winStart = false
        titleBar.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                drag=true dragStart=i.Position winStart=win.Position
            end
        end)
        game:GetService("UserInputService").InputChanged:Connect(function(i)
            if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
                local d = i.Position - dragStart
                win.Position = UDim2.new(winStart.X.Scale, winStart.X.Offset+d.X, winStart.Y.Scale, winStart.Y.Offset+d.Y)
            end
        end)
        game:GetService("UserInputService").InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then drag=false end
        end)
    end

    local content = Instance.new("Frame", win)
    content.Size = UDim2.new(1,0,1,-36)
    content.Position = UDim2.new(0,0,0,36)
    content.BackgroundTransparency = 1

    -- ── three panels ──────────────────────────────────────────────────────────
    local panels = {}
    local function makePanel()
        local f = Instance.new("Frame", content)
        f.Size = UDim2.new(1,0,1,0)
        f.BackgroundTransparency = 1
        f.Visible = false
        pad(10,10,12,12,f)
        table.insert(panels, f)
        return f
    end
    local function showPanel(n)
        for i,p in ipairs(panels) do p.Visible=(i==n) end
    end

    -- forward declarations for mutual recursion
    local refreshRouteList, refreshEditor, loadStepEditor

    -- ═══════════════════════════════════════════════════════════════════════════
    -- PANEL 1 — Route List
    -- ═══════════════════════════════════════════════════════════════════════════
    local p1 = makePanel()
    label("Saved Routes", p1, UDim2.new(1,0,0,26)).TextSize = 16

    local p1List = scrollList(p1, UDim2.new(1,0,1,-80))
    p1List.Position = UDim2.new(0,0,0,32)

    local newRouteB = button("+ New Route", p1, UDim2.new(1,0,0,32), C.accent)
    newRouteB.Position = UDim2.new(0,0,1,-38)

    local currentRoute = nil  -- the route table being edited

    refreshRouteList = function()
        for _,c in ipairs(p1List:GetChildren()) do
            if c:IsA("Frame") or c:IsA("TextButton") then c:Destroy() end
        end
        local names = routeIO.list()
        if #names == 0 then
            label("No routes saved yet.", p1List, UDim2.new(1,0,0,28), C.subtext)
            return
        end
        for idx, name in ipairs(names) do
            local row = Instance.new("Frame", p1List)
            row.Size = UDim2.new(1,-8,0,36)
            row.BackgroundColor3 = C.panel
            row.LayoutOrder = idx
            corner(6, row)

            label(name, row, UDim2.new(1,-200,1,0)).Position = UDim2.new(0,10,0,0)

            local runB = button("Run", row, UDim2.new(0,54,0,26), C.green)
            runB.Position = UDim2.new(1,-172,0.5,-13)
            runB.MouseButton1Click:Connect(function()
                local r = routeIO.load(name)
                if r and onRun then onRun(r) end
            end)

            local editB = button("Edit", row, UDim2.new(0,54,0,26))
            editB.Position = UDim2.new(1,-114,0.5,-13)
            editB.MouseButton1Click:Connect(function()
                local r = routeIO.load(name)
                if r then
                    -- deep copy steps so edits don't mutate saved data
                    local steps = {}
                    for i, s in ipairs(r.steps) do
                        steps[i] = {
                            action  = {
                                type        = s.action.type,
                                config      = s.action.config,
                                comp        = s.action.comp,
                                interval    = s.action.interval,
                                atlasConfig = s.action.atlasConfig,
                            },
                            trigger = {
                                type    = s.trigger.type,
                                amount  = s.trigger.amount,
                                name    = s.trigger.name,
                                minutes = s.trigger.minutes,
                            },
                        }
                    end
                    currentRoute = { name = r.name, steps = steps }
                    refreshEditor()
                    showPanel(2)
                end
            end)

            local delB = button("Del", row, UDim2.new(0,44,0,26), C.red)
            delB.Position = UDim2.new(1,-56,0.5,-13)
            delB.MouseButton1Click:Connect(function()
                routeIO.delete(name)
                refreshRouteList()
            end)
        end
    end

    newRouteB.MouseButton1Click:Connect(function()
        currentRoute = { name = "", steps = {} }
        refreshEditor()
        showPanel(2)
    end)

    -- ═══════════════════════════════════════════════════════════════════════════
    -- PANEL 2 — Route Editor
    -- ═══════════════════════════════════════════════════════════════════════════
    local p2 = makePanel()
    label("Route Editor", p2, UDim2.new(1,0,0,24)).TextSize = 16

    local nameRow = Instance.new("Frame", p2)
    nameRow.Size = UDim2.new(1,0,0,28)
    nameRow.Position = UDim2.new(0,0,0,28)
    nameRow.BackgroundTransparency = 1
    label("Name:", nameRow, UDim2.new(0,50,1,0))
    local _, nameBox = input(nameRow, UDim2.new(1,-54,1,0))
    nameBox.Parent.Position = UDim2.new(0,54,0,0)

    local stepScroll = scrollList(p2, UDim2.new(1,0,1,-130))
    stepScroll.Position = UDim2.new(0,0,0,64)

    local p2Btns = Instance.new("Frame", p2)
    p2Btns.Size = UDim2.new(1,0,0,60)
    p2Btns.Position = UDim2.new(0,0,1,-66)
    p2Btns.BackgroundTransparency = 1

    local addStepB = button("+ Add Step", p2Btns, UDim2.new(0,110,0,30), C.accent)
    addStepB.Position = UDim2.new(0,0,0,0)

    local saveRouteB = button("Save Route", p2Btns, UDim2.new(0,110,0,30), C.green)
    saveRouteB.Position = UDim2.new(0,118,0,0)

    local backB1 = button("← Back", p2Btns, UDim2.new(0,90,0,30))
    backB1.Position = UDim2.new(0,236,0,0)

    local p2Status = label("", p2Btns, UDim2.new(1,0,0,22), C.subtext)
    p2Status.Position = UDim2.new(0,0,0,34)

    local editingStepIdx = nil  -- nil = new step

    refreshEditor = function()
        nameBox.Text = currentRoute.name or ""
        for _, c in ipairs(stepScroll:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end
        for idx, s in ipairs(currentRoute.steps) do
            local row = Instance.new("Frame", stepScroll)
            row.Size = UDim2.new(1,-8,0,36)
            row.BackgroundColor3 = C.panel
            row.LayoutOrder = idx
            corner(6, row)

            label(idx..". "..stepSummary(s), row, UDim2.new(1,-170,1,0)).Position = UDim2.new(0,8,0,0)

            local editSB = button("Edit", row, UDim2.new(0,44,0,26))
            editSB.Position = UDim2.new(1,-162,0.5,-13)
            editSB.MouseButton1Click:Connect(function()
                editingStepIdx = idx
                loadStepEditor(s)
                showPanel(3)
            end)

            local upB = button("↑", row, UDim2.new(0,28,0,26))
            upB.Position = UDim2.new(1,-114,0.5,-13)
            upB.MouseButton1Click:Connect(function()
                if idx > 1 then
                    currentRoute.steps[idx], currentRoute.steps[idx-1] = currentRoute.steps[idx-1], currentRoute.steps[idx]
                    refreshEditor()
                end
            end)

            local downB = button("↓", row, UDim2.new(0,28,0,26))
            downB.Position = UDim2.new(1,-82,0.5,-13)
            downB.MouseButton1Click:Connect(function()
                if idx < #currentRoute.steps then
                    currentRoute.steps[idx], currentRoute.steps[idx+1] = currentRoute.steps[idx+1], currentRoute.steps[idx]
                    refreshEditor()
                end
            end)

            local delSB = button("✕", row, UDim2.new(0,28,0,26), C.red)
            delSB.Position = UDim2.new(1,-48,0.5,-13)
            delSB.MouseButton1Click:Connect(function()
                table.remove(currentRoute.steps, idx)
                refreshEditor()
            end)
        end
    end

    addStepB.MouseButton1Click:Connect(function()
        editingStepIdx = nil
        loadStepEditor(nil)
        showPanel(3)
    end)

    saveRouteB.MouseButton1Click:Connect(function()
        currentRoute.name = nameBox.Text
        local ok, err = routeIO.validate(currentRoute)
        if not ok then p2Status.Text = "Error: " .. tostring(err) return end
        local saved, serr = routeIO.save(currentRoute)
        if saved then
            p2Status.Text = "Saved!"
            task.delay(2, function() p2Status.Text = "" end)
        else
            p2Status.Text = "Save failed: " .. tostring(serr)
        end
    end)

    backB1.MouseButton1Click:Connect(function()
        refreshRouteList()
        showPanel(1)
    end)

    -- ═══════════════════════════════════════════════════════════════════════════
    -- PANEL 3 — Step Editor
    -- ═══════════════════════════════════════════════════════════════════════════
    local p3 = makePanel()

    -- scroll the whole step editor
    local p3Scroll = Instance.new("ScrollingFrame", p3)
    p3Scroll.Size = UDim2.new(1,0,1,-44)
    p3Scroll.BackgroundTransparency = 1
    p3Scroll.ScrollBarThickness = 5
    p3Scroll.CanvasSize = UDim2.new(0,0,0,0)
    p3Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

    local p3Layout = Instance.new("UIListLayout", p3Scroll)
    p3Layout.SortOrder = Enum.SortOrder.LayoutOrder
    p3Layout.Padding = UDim.new(0,8)

    -- ACTION section
    local actHeader = label("Action", p3Scroll, UDim2.new(1,0,0,22))
    actHeader.TextSize = 14
    actHeader.TextColor3 = C.accent
    actHeader.LayoutOrder = 1

    local actTypeLabel = label("Type:", p3Scroll, UDim2.new(1,0,0,18))
    actTypeLabel.LayoutOrder = 2

    local ACTION_TYPES = {"atlas_config", "adjuster_loop", "rj_buyer"}
    local actDropFrame, getActType, setActType = makeDropdown(p3Scroll, ACTION_TYPES, 1)
    actDropFrame.LayoutOrder = 3

    -- atlas_config config fields
    local atlasConfigSection = Instance.new("Frame", p3Scroll)
    atlasConfigSection.Size = UDim2.new(1,0,0,56)
    atlasConfigSection.BackgroundTransparency = 1
    atlasConfigSection.LayoutOrder = 4
    local atlasLayout = Instance.new("UIListLayout", atlasConfigSection)
    atlasLayout.Padding = UDim.new(0,4)
    label("Atlas config file:", atlasConfigSection, UDim2.new(1,0,0,18)).LayoutOrder = 1
    local atlasDropFrame, getAtlasConfig, setAtlasConfig = makeDropdown(atlasConfigSection, ATLAS_OPTIONS, 1)
    atlasDropFrame.LayoutOrder = 2
    atlasDropFrame.Size = UDim2.new(1,0,0,28)

    -- adjuster_loop config fields
    local adjSection = Instance.new("Frame", p3Scroll)
    adjSection.Size = UDim2.new(1,0,0,112)
    adjSection.BackgroundTransparency = 1
    adjSection.LayoutOrder = 5
    local adjLayout = Instance.new("UIListLayout", adjSection)
    adjLayout.Padding = UDim.new(0,4)
    label("Composition name:", adjSection, UDim2.new(1,0,0,18)).LayoutOrder = 1
    local _, compBox = input(adjSection, UDim2.new(1,0,0,28), "e.g. diamond mats")
    compBox.Parent.LayoutOrder = 2
    label("Atlas config (optional, type name):", adjSection, UDim2.new(1,0,0,18)).LayoutOrder = 3
    local _, adjAtlasBox = input(adjSection, UDim2.new(1,0,0,28), "e.g. atlas/diamond mats.json")
    adjAtlasBox.Parent.LayoutOrder = 4

    -- rj_buyer config fields
    local rjSection = Instance.new("Frame", p3Scroll)
    rjSection.Size = UDim2.new(1,0,0,112)
    rjSection.BackgroundTransparency = 1
    rjSection.LayoutOrder = 6
    local rjLayout = Instance.new("UIListLayout", rjSection)
    rjLayout.Padding = UDim.new(0,4)
    label("Buy interval (seconds):", rjSection, UDim2.new(1,0,0,18)).LayoutOrder = 1
    local _, intBox = input(rjSection, UDim2.new(1,0,0,28), "e.g. 30")
    intBox.Parent.LayoutOrder = 2
    label("Atlas config (optional, type name):", rjSection, UDim2.new(1,0,0,18)).LayoutOrder = 3
    local _, rjAtlasBox = input(rjSection, UDim2.new(1,0,0,28), "e.g. atlas/diamond honey.json")
    rjAtlasBox.Parent.LayoutOrder = 4

    -- TRIGGER section
    local trigHeader = label("Trigger (advance when…)", p3Scroll, UDim2.new(1,0,0,22))
    trigHeader.TextSize = 14
    trigHeader.TextColor3 = C.accent
    trigHeader.LayoutOrder = 7

    local trigTypeLabel = label("Type:", p3Scroll, UDim2.new(1,0,0,18))
    trigTypeLabel.LayoutOrder = 8

    local TRIGGER_TYPES = {"honey", "material", "item", "tool", "time"}
    local trigDropFrame, getTrigType, setTrigType = makeDropdown(p3Scroll, TRIGGER_TYPES, 1)
    trigDropFrame.LayoutOrder = 9

    local honeySection   = Instance.new("Frame", p3Scroll) honeySection.Size=UDim2.new(1,0,0,50) honeySection.BackgroundTransparency=1 honeySection.LayoutOrder=10
    local matSection     = Instance.new("Frame", p3Scroll) matSection.Size=UDim2.new(1,0,0,90) matSection.BackgroundTransparency=1 matSection.LayoutOrder=11
    local itemSection    = Instance.new("Frame", p3Scroll) itemSection.Size=UDim2.new(1,0,0,50) itemSection.BackgroundTransparency=1 itemSection.LayoutOrder=12
    local toolSection    = Instance.new("Frame", p3Scroll) toolSection.Size=UDim2.new(1,0,0,50) toolSection.BackgroundTransparency=1 toolSection.LayoutOrder=13
    local timeSection    = Instance.new("Frame", p3Scroll) timeSection.Size=UDim2.new(1,0,0,50) timeSection.BackgroundTransparency=1 timeSection.LayoutOrder=14

    -- honey
    do local l=Instance.new("UIListLayout",honeySection) l.Padding=UDim.new(0,4)
       label("Honey amount (≥):", honeySection, UDim2.new(1,0,0,18)).LayoutOrder=1 end
    local _, honeyBox = input(honeySection, UDim2.new(1,0,0,28), "e.g. 1000000")
    honeyBox.Parent.LayoutOrder=2

    -- material
    do local l=Instance.new("UIListLayout",matSection) l.Padding=UDim.new(0,4)
       label("Material name:", matSection, UDim2.new(1,0,0,18)).LayoutOrder=1 end
    local _, matNameBox = input(matSection, UDim2.new(1,0,0,28), "e.g. Royal Jelly")
    matNameBox.Parent.LayoutOrder=2
    label("Amount (≥):", matSection, UDim2.new(1,0,0,18)).LayoutOrder=3
    local _, matAmtBox = input(matSection, UDim2.new(1,0,0,28), "e.g. 5")
    matAmtBox.Parent.LayoutOrder=4

    -- item
    do local l=Instance.new("UIListLayout",itemSection) l.Padding=UDim.new(0,4)
       label("Item name:", itemSection, UDim2.new(1,0,0,18)).LayoutOrder=1 end
    local _, itemBox = input(itemSection, UDim2.new(1,0,0,28), "e.g. Diamond Mask")
    itemBox.Parent.LayoutOrder=2

    -- tool
    do local l=Instance.new("UIListLayout",toolSection) l.Padding=UDim.new(0,4)
       label("Tool name:", toolSection, UDim2.new(1,0,0,18)).LayoutOrder=1 end
    local _, toolBox = input(toolSection, UDim2.new(1,0,0,28), "e.g. Basic Egg")
    toolBox.Parent.LayoutOrder=2

    -- time
    do local l=Instance.new("UIListLayout",timeSection) l.Padding=UDim.new(0,4)
       label("Minutes:", timeSection, UDim2.new(1,0,0,18)).LayoutOrder=1 end
    local _, timeBox = input(timeSection, UDim2.new(1,0,0,28), "e.g. 30")
    timeBox.Parent.LayoutOrder=2

    -- show/hide action+trigger sections based on dropdown
    local function refreshSections()
        local at = getActType()
        atlasConfigSection.Visible = (at == "atlas_config")
        adjSection.Visible         = (at == "adjuster_loop")
        rjSection.Visible          = (at == "rj_buyer")

        local tt = getTrigType()
        honeySection.Visible  = (tt == "honey")
        matSection.Visible    = (tt == "material")
        itemSection.Visible   = (tt == "item")
        toolSection.Visible   = (tt == "tool")
        timeSection.Visible   = (tt == "time")
    end

    -- Wire dropdowns to refresh sections
    -- (patch into display button click)
    do
        local origActClick = actDropFrame:FindFirstChildWhichIsA("TextButton").MouseButton1Click
        actDropFrame:FindFirstChildWhichIsA("TextButton").MouseButton1Click:Connect(function()
            task.defer(refreshSections)
        end)
        trigDropFrame:FindFirstChildWhichIsA("TextButton").MouseButton1Click:Connect(function()
            task.defer(refreshSections)
        end)
        -- also hook list items via polling (simple approach: refresh every time panel is shown)
    end

    -- bottom buttons for step editor
    local p3Btns = Instance.new("Frame", p3)
    p3Btns.Size = UDim2.new(1,0,0,36)
    p3Btns.Position = UDim2.new(0,0,1,-40)
    p3Btns.BackgroundTransparency = 1

    local confirmB = button("Confirm Step", p3Btns, UDim2.new(0,130,0,30), C.green)
    confirmB.Position = UDim2.new(0,0,0,0)

    local backB2 = button("← Back", p3Btns, UDim2.new(0,90,0,30))
    backB2.Position = UDim2.new(0,138,0,0)

    local p3Status = label("", p3Btns, UDim2.new(1,-240,1,0), C.subtext)
    p3Status.Position = UDim2.new(0,240,0,4)

    -- track current action state (for adjuster/rj atlas config text)
    local currentAction = {}

    loadStepEditor = function(step)
        currentAction = {}
        if step then
            setActType(step.action.type)
            if step.action.type == "atlas_config" then
                setAtlasConfig(step.action.config or ATLAS_OPTIONS[1])
            elseif step.action.type == "adjuster_loop" then
                compBox.Text    = step.action.comp or ""
                adjAtlasBox.Text = step.action.atlasConfig or ""
            elseif step.action.type == "rj_buyer" then
                intBox.Text     = tostring(step.action.interval or "")
                rjAtlasBox.Text  = step.action.atlasConfig or ""
            end
            setTrigType(step.trigger.type)
            honeyBox.Text   = tostring(step.trigger.amount  or "")
            matNameBox.Text = step.trigger.name    or ""
            matAmtBox.Text  = tostring(step.trigger.amount  or "")
            itemBox.Text    = step.trigger.name    or ""
            toolBox.Text    = step.trigger.name    or ""
            timeBox.Text    = tostring(step.trigger.minutes or "")
            currentAction   = { type = step.action.type, atlasConfig = step.action.atlasConfig }
        else
            setActType("atlas_config")
            setAtlasConfig(ATLAS_OPTIONS[1])
            compBox.Text = "" adjAtlasBox.Text = "" intBox.Text = "" rjAtlasBox.Text = ""
            setTrigType("honey")
            honeyBox.Text="" matNameBox.Text="" matAmtBox.Text="" itemBox.Text="" toolBox.Text="" timeBox.Text=""
            currentAction = {}
        end
        refreshSections()
        p3Status.Text = ""
    end

    confirmB.MouseButton1Click:Connect(function()
        local at = getActType()
        local action = { type = at }
        if at == "atlas_config" then
            action.config = getAtlasConfig()
        elseif at == "adjuster_loop" then
            action.comp = compBox.Text
            if adjAtlasBox.Text ~= "" then action.atlasConfig = adjAtlasBox.Text end
        elseif at == "rj_buyer" then
            local n = tonumber(intBox.Text)
            if not n then p3Status.Text = "Interval must be a number" return end
            action.interval = n
            if rjAtlasBox.Text ~= "" then action.atlasConfig = rjAtlasBox.Text end
        end

        local tt = getTrigType()
        local trigger = { type = tt }
        if tt == "honey" then
            local n = tonumber(honeyBox.Text)
            if not n then p3Status.Text = "Honey must be a number" return end
            trigger.amount = n
        elseif tt == "material" then
            if matNameBox.Text == "" then p3Status.Text = "Material name required" return end
            local n = tonumber(matAmtBox.Text)
            if not n then p3Status.Text = "Amount must be a number" return end
            trigger.name = matNameBox.Text
            trigger.amount = n
        elseif tt == "item" then
            if itemBox.Text == "" then p3Status.Text = "Item name required" return end
            trigger.name = itemBox.Text
        elseif tt == "tool" then
            if toolBox.Text == "" then p3Status.Text = "Tool name required" return end
            trigger.name = toolBox.Text
        elseif tt == "time" then
            local n = tonumber(timeBox.Text)
            if not n then p3Status.Text = "Minutes must be a number" return end
            trigger.minutes = n
        end

        local step = { action = action, trigger = trigger }
        if editingStepIdx then
            currentRoute.steps[editingStepIdx] = step
        else
            table.insert(currentRoute.steps, step)
        end
        editingStepIdx = nil
        refreshEditor()
        showPanel(2)
    end)

    backB2.MouseButton1Click:Connect(function()
        editingStepIdx = nil
        showPanel(2)
    end)

    -- show panel 1 to start
    refreshRouteList()
    showPanel(1)

    return sg
end

return M
