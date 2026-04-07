local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local lp = Players.LocalPlayer

local CONFIG_PATH = "bss_config.json"
local config = {
    webhookUrl = "",
    debugEnabled = true,
    fuzzyAltAutoRun = false
}

local function saveConfig()
    pcall(function()
        writefile(CONFIG_PATH, HttpService:JSONEncode(config))
    end)
end

pcall(function()
    local data = HttpService:JSONDecode(readfile(CONFIG_PATH))
    if data then
        config.webhookUrl      = data.webhookUrl or ""
        config.debugEnabled    = data.debugEnabled ~= false
        config.fuzzyAltAutoRun = data.fuzzyAltAutoRun == true
    end
end)

local scanCallback        = nil
local rjBuyCallback       = nil
local debugToggleCallback = nil
local fuzzyAltCallback    = nil

-- destroy any old instance so re-running the script is safe
for _, v in ipairs(lp.PlayerGui:GetChildren()) do
    if v.Name == "BSSTools" then v:Destroy() end
end

local sg = Instance.new("ScreenGui", lp.PlayerGui)
sg.Name = "BSSTools"
sg.ResetOnSpawn = false

local main = Instance.new("Frame", sg)
main.Size = UDim2.new(0, 580, 0, 420)
main.Position = UDim2.new(0.5, -290, 0.4, -210)
main.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)

-- ── Title bar ─────────────────────────────────────────────────────────
local titleBar = Instance.new("Frame", main)
titleBar.Size = UDim2.new(1, 0, 0, 36)
titleBar.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
titleBar.BorderSizePixel = 0
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 8)

local titleLabel = Instance.new("TextLabel", titleBar)
titleLabel.Size = UDim2.new(1, -40, 1, 0)
titleLabel.Position = UDim2.new(0, 14, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "BSS TOOLS"
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 13
titleLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left

local closeBtn = Instance.new("TextButton", titleBar)
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -33, 0, 3)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
closeBtn.Text = "✕"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 12
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.BorderSizePixel = 0
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

-- ── Sidebar ───────────────────────────────────────────────────────────
local sidebar = Instance.new("Frame", main)
sidebar.Size = UDim2.new(0, 120, 1, -36)
sidebar.Position = UDim2.new(0, 0, 0, 36)
sidebar.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
sidebar.BorderSizePixel = 0

local sidebarLayout = Instance.new("UIListLayout", sidebar)
sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
sidebarLayout.Padding = UDim.new(0, 4)

local sidePad = Instance.new("UIPadding", sidebar)
sidePad.PaddingTop   = UDim.new(0, 4)
sidePad.PaddingLeft  = UDim.new(0, 6)
sidePad.PaddingRight = UDim.new(0, 6)

-- ── Content area ──────────────────────────────────────────────────────
local contentArea = Instance.new("Frame", main)
contentArea.Size = UDim2.new(1, -120, 1, -36)
contentArea.Position = UDim2.new(0, 120, 0, 36)
contentArea.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
contentArea.BorderSizePixel = 0
contentArea.ClipsDescendants = true

local tabs    = {}
local tabBtns = {}

local function makeTabBtn(label, order)
    local btn = Instance.new("TextButton", sidebar)
    btn.Size = UDim2.new(1, 0, 0, 28)
    btn.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
    btn.Text = label
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.TextColor3 = Color3.fromRGB(150, 150, 150)
    btn.BorderSizePixel = 0
    btn.LayoutOrder = order
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    return btn
end

local function makeTabFrame()
    local f = Instance.new("Frame", contentArea)
    f.Size = UDim2.new(1, 0, 1, 0)
    f.BackgroundTransparency = 1
    f.Visible = false
    local pad = Instance.new("UIPadding", f)
    pad.PaddingLeft  = UDim.new(0, 14)
    pad.PaddingRight = UDim.new(0, 14)
    pad.PaddingTop   = UDim.new(0, 12)
    local layout = Instance.new("UIListLayout", f)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding   = UDim.new(0, 10)
    return f
end

local function switchTab(name)
    for k, f in pairs(tabs) do
        -- tabs may be a Frame or a ScrollingFrame parented directly to contentArea
        f.Visible = (k == name)
    end
    for k, b in pairs(tabBtns) do
        if k == name then
            b.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
            b.TextColor3 = Color3.fromRGB(220, 220, 220)
        else
            b.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
            b.TextColor3 = Color3.fromRGB(150, 150, 150)
        end
    end
end

local function sectionLabel(parent, text, order)
    local lbl = Instance.new("TextLabel", parent)
    lbl.Size = UDim2.new(1, 0, 0, 14)
    lbl.BackgroundTransparency = 1
    lbl.Text = text:upper()
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 10
    lbl.TextColor3 = Color3.fromRGB(120, 120, 120)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.LayoutOrder = order
end

local function makeBtn(parent, text, order)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = Color3.fromRGB(34, 34, 34)
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.BorderSizePixel = 0
    btn.LayoutOrder = order
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    return btn
end

local function makeToggleRow(parent, labelText, order, initEnabled, onToggle)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, 0, 0, 34)
    row.BackgroundTransparency = 1
    row.LayoutOrder = order

    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1, -60, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextColor3 = Color3.fromRGB(180, 180, 180)
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local btn = Instance.new("TextButton", row)
    btn.Size = UDim2.new(0, 46, 0, 24)
    btn.Position = UDim2.new(1, -46, 0.5, -12)
    btn.BorderSizePixel = 0
    btn.Text = ""
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)

    local circle = Instance.new("Frame", btn)
    circle.Size = UDim2.new(0, 18, 0, 18)
    circle.BackgroundColor3 = Color3.new(1, 1, 1)
    circle.BorderSizePixel = 0
    Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)

    local enabled = initEnabled
    local function setState(val)
        enabled = val
        if enabled then
            btn.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
            circle.Position = UDim2.new(1, -21, 0.5, -9)
        else
            btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            circle.Position = UDim2.new(0, 3, 0.5, -9)
        end
        if onToggle then onToggle(enabled) end
    end

    setState(initEnabled)
    btn.MouseButton1Click:Connect(function() setState(not enabled) end)

    return row
end

-- ════════════════════════════════════════════════════════════
--  TAB 1: HIVE SCANNER
-- ════════════════════════════════════════════════════════════
local hiveTab = makeTabFrame()
tabs["Hive Scanner"] = hiveTab
tabBtns["Hive Scanner"] = makeTabBtn("🐝 Hive", 1)
tabBtns["Hive Scanner"].MouseButton1Click:Connect(function() switchTab("Hive Scanner") end)

sectionLabel(hiveTab, "Hive Scanner", 1)
local scanBtn = makeBtn(hiveTab, "RUN HIVE SCAN", 2)
scanBtn.MouseButton1Click:Connect(function()
    if scanCallback then scanCallback() end
end)

-- ════════════════════════════════════════════════════════════
--  TAB 2: RJ BUYER
-- ════════════════════════════════════════════════════════════
local rjTab = makeTabFrame()
tabs["RJ Buyer"] = rjTab
tabBtns["RJ Buyer"] = makeTabBtn("🍯 RJ", 2)
tabBtns["RJ Buyer"].MouseButton1Click:Connect(function() switchTab("RJ Buyer") end)

sectionLabel(rjTab, "RJ Buyer", 1)

local rjRow = Instance.new("Frame", rjTab)
rjRow.Size = UDim2.new(1, 0, 0, 34)
rjRow.BackgroundTransparency = 1
rjRow.LayoutOrder = 2

local rjInput = Instance.new("TextBox", rjRow)
rjInput.Size = UDim2.new(1, -90, 1, 0)
rjInput.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
rjInput.BorderSizePixel = 0
rjInput.Text = ""
rjInput.PlaceholderText = "Amount..."
rjInput.PlaceholderColor3 = Color3.fromRGB(70, 70, 70)
rjInput.Font = Enum.Font.Code
rjInput.TextSize = 12
rjInput.TextColor3 = Color3.fromRGB(200, 200, 200)
rjInput.ClearTextOnFocus = false
rjInput.TextXAlignment = Enum.TextXAlignment.Left
Instance.new("UICorner", rjInput).CornerRadius = UDim.new(0, 6)
Instance.new("UIPadding", rjInput).PaddingLeft = UDim.new(0, 8)

local rjBtn = Instance.new("TextButton", rjRow)
rjBtn.Size = UDim2.new(0, 80, 1, 0)
rjBtn.Position = UDim2.new(1, -80, 0, 0)
rjBtn.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
rjBtn.Text = "BUY"
rjBtn.Font = Enum.Font.GothamBold
rjBtn.TextSize = 11
rjBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
rjBtn.BorderSizePixel = 0
Instance.new("UICorner", rjBtn).CornerRadius = UDim.new(0, 6)
rjBtn.MouseButton1Click:Connect(function()
    local amount = tonumber(rjInput.Text)
    if rjBuyCallback and amount then
        rjBuyCallback(amount)
    end
end)

-- ════════════════════════════════════════════════════════════
--  TAB 3: ADJUSTER
--  This is a plain Frame passed to buildCompBuilderTab().
--  buildCompBuilderTab creates its own internal ScrollingFrame
--  so we just pass the raw frame as the container.
-- ════════════════════════════════════════════════════════════
local adjusterTab = Instance.new("Frame", contentArea)
adjusterTab.Size = UDim2.new(1, 0, 1, 0)
adjusterTab.BackgroundTransparency = 1
adjusterTab.Visible = false

tabs["Adjuster"] = adjusterTab
tabBtns["Adjuster"] = makeTabBtn("🔧 Adjuster", 3)
tabBtns["Adjuster"].MouseButton1Click:Connect(function() switchTab("Adjuster") end)

local adjusterTabFrame = adjusterTab

-- ════════════════════════════════════════════════════════════
--  TAB 4: FUZZY ALT
-- ════════════════════════════════════════════════════════════
local FUZZY_PART_COUNT    = 7
local PROGRESS_FILE_PREFIX = "bss_fuzzyalt_progress_"
local PART_NAMES = {
    [0] = "Part 0 — Filling hive to 25 slots",
    [1] = "Part 1 — Running 4r4b adjuster",
    [2] = "Part 2 — Filling to 35 slots & legendary",
    [3] = "Part 3 — Gathering Bubble Mask ingredients",
    [4] = "Part 4 complete — Bubble Mask acquired ✓",
    [5] = "Part 5 — Hive for Diamond Mask",
    [6] = "Part 6 — Diamond Mask",
}

local fuzzyTabOuter = Instance.new("Frame", contentArea)
fuzzyTabOuter.Size = UDim2.new(1, 0, 1, 0)
fuzzyTabOuter.BackgroundTransparency = 1
fuzzyTabOuter.Visible = false

local fuzzyTab = Instance.new("ScrollingFrame", fuzzyTabOuter)
fuzzyTab.Size = UDim2.new(1, 0, 1, 0)
fuzzyTab.BackgroundTransparency = 1
fuzzyTab.BorderSizePixel = 0
fuzzyTab.ScrollBarThickness = 4
fuzzyTab.CanvasSize = UDim2.new(0, 0, 0, 0)

local fuzzyPad = Instance.new("UIPadding", fuzzyTab)
fuzzyPad.PaddingLeft  = UDim.new(0, 14)
fuzzyPad.PaddingRight = UDim.new(0, 14)
fuzzyPad.PaddingTop   = UDim.new(0, 12)

local fuzzyLayout = Instance.new("UIListLayout", fuzzyTab)
fuzzyLayout.SortOrder = Enum.SortOrder.LayoutOrder
fuzzyLayout.Padding = UDim.new(0, 10)
fuzzyLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    fuzzyTab.CanvasSize = UDim2.new(0, 0, 0, fuzzyLayout.AbsoluteContentSize.Y + 20)
end)

tabs["Fuzzy Alt"] = fuzzyTabOuter
tabBtns["Fuzzy Alt"] = makeTabBtn("🍬 Fuzzy", 4)
tabBtns["Fuzzy Alt"].MouseButton1Click:Connect(function() switchTab("Fuzzy Alt") end)

sectionLabel(fuzzyTab, "Status", 1)

local statusBox = Instance.new("Frame", fuzzyTab)
statusBox.Size = UDim2.new(1, 0, 0, 60)
statusBox.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
statusBox.BorderSizePixel = 0
statusBox.LayoutOrder = 2
Instance.new("UICorner", statusBox).CornerRadius = UDim.new(0, 6)

local statusPad = Instance.new("UIPadding", statusBox)
statusPad.PaddingLeft   = UDim.new(0, 10)
statusPad.PaddingRight  = UDim.new(0, 10)
statusPad.PaddingTop    = UDim.new(0, 8)
statusPad.PaddingBottom = UDim.new(0, 8)

local statusBoxLayout = Instance.new("UIListLayout", statusBox)
statusBoxLayout.SortOrder = Enum.SortOrder.LayoutOrder
statusBoxLayout.Padding   = UDim.new(0, 2)

local partLabel = Instance.new("TextLabel", statusBox)
partLabel.Size = UDim2.new(1, 0, 0, 16)
partLabel.BackgroundTransparency = 1
partLabel.Font = Enum.Font.GothamBold
partLabel.TextSize = 11
partLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
partLabel.TextXAlignment = Enum.TextXAlignment.Left
partLabel.LayoutOrder = 1

local stateLabel = Instance.new("TextLabel", statusBox)
stateLabel.Size = UDim2.new(1, 0, 0, 16)
stateLabel.BackgroundTransparency = 1
stateLabel.Font = Enum.Font.Code
stateLabel.TextSize = 11
stateLabel.TextColor3 = Color3.fromRGB(130, 130, 130)
stateLabel.TextXAlignment = Enum.TextXAlignment.Left
stateLabel.LayoutOrder = 2

local function refreshStatus()
    local progressFile = PROGRESS_FILE_PREFIX .. lp.Name .. ".json"
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(progressFile))
    end)
    if ok and data then
        local part = data.part or 0
        partLabel.Text = PART_NAMES[part] or ("Part " .. part)
        partLabel.TextColor3 = part >= FUZZY_PART_COUNT
            and Color3.fromRGB(80, 200, 80)
            or  Color3.fromRGB(200, 200, 200)
        stateLabel.Text = "Account: " .. (data.account or lp.Name)
    else
        partLabel.Text  = "No progress saved"
        partLabel.TextColor3 = Color3.fromRGB(130, 130, 130)
        stateLabel.Text = "Script has not been run yet"
    end
end

refreshStatus()

local refreshBtn = makeBtn(fuzzyTab, "↻ REFRESH STATUS", 3)
refreshBtn.LayoutOrder = 3
refreshBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
refreshBtn.TextColor3 = Color3.fromRGB(130, 160, 255)
refreshBtn.MouseButton1Click:Connect(refreshStatus)

sectionLabel(fuzzyTab, "Auto Run", 4)

makeToggleRow(fuzzyTab, "Auto run on startup", 5, config.fuzzyAltAutoRun, function(enabled)
    config.fuzzyAltAutoRun = enabled
    saveConfig()
end)

sectionLabel(fuzzyTab, "Start At Part", 6)

local selectedStartPart = 0
local dropdownOpen = false

local dropdownContainer = Instance.new("Frame", fuzzyTab)
dropdownContainer.Size = UDim2.new(1, 0, 0, 34)
dropdownContainer.BackgroundTransparency = 1
dropdownContainer.LayoutOrder = 7
dropdownContainer.ZIndex = 10
dropdownContainer.ClipsDescendants = false

local dropdownBtn = Instance.new("TextButton", dropdownContainer)
dropdownBtn.Size = UDim2.new(1, 0, 0, 34)
dropdownBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
dropdownBtn.BorderSizePixel = 0
dropdownBtn.Font = Enum.Font.GothamBold
dropdownBtn.TextSize = 12
dropdownBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
dropdownBtn.TextXAlignment = Enum.TextXAlignment.Left
dropdownBtn.ZIndex = 10
Instance.new("UICorner", dropdownBtn).CornerRadius = UDim.new(0, 6)
Instance.new("UIPadding", dropdownBtn).PaddingLeft = UDim.new(0, 10)

local arrowLabel = Instance.new("TextLabel", dropdownBtn)
arrowLabel.Size = UDim2.new(0, 30, 1, 0)
arrowLabel.Position = UDim2.new(1, -30, 0, 0)
arrowLabel.BackgroundTransparency = 1
arrowLabel.Text = "▼"
arrowLabel.Font = Enum.Font.GothamBold
arrowLabel.TextSize = 10
arrowLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
arrowLabel.ZIndex = 10

local ITEM_HEIGHT          = 30
local DROPDOWN_MAX_VISIBLE = 4

local dropdownList = Instance.new("ScrollingFrame", dropdownContainer)
dropdownList.Size = UDim2.new(1, 0, 0, math.min(FUZZY_PART_COUNT, DROPDOWN_MAX_VISIBLE) * ITEM_HEIGHT)
dropdownList.Position = UDim2.new(0, 0, 0, 36)
dropdownList.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
dropdownList.BorderSizePixel = 0
dropdownList.Visible = false
dropdownList.ZIndex = 20
dropdownList.ScrollBarThickness = 4
dropdownList.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
dropdownList.ScrollingEnabled = true
dropdownList.CanvasSize = UDim2.new(0, 0, 0, FUZZY_PART_COUNT * ITEM_HEIGHT)
Instance.new("UICorner", dropdownList).CornerRadius = UDim.new(0, 6)
Instance.new("UIListLayout", dropdownList).SortOrder = Enum.SortOrder.LayoutOrder

local function getPartLabel(part)
    local name = PART_NAMES[part]
    if name then return name:match("^(Part %d+)") or ("Part " .. part) end
    return "Part " .. part
end

local function updateDropdownLabel()
    dropdownBtn.Text = getPartLabel(selectedStartPart)
end

local function closeDropdown()
    dropdownOpen = false
    dropdownList.Visible = false
    arrowLabel.Text = "▼"
end

for i = 0, FUZZY_PART_COUNT - 1 do
    local item = Instance.new("TextButton", dropdownList)
    item.Size = UDim2.new(1, 0, 0, ITEM_HEIGHT)
    item.BackgroundTransparency = 1
    item.Font = Enum.Font.Gotham
    item.TextSize = 12
    item.TextColor3 = Color3.fromRGB(180, 180, 180)
    item.TextXAlignment = Enum.TextXAlignment.Left
    item.BorderSizePixel = 0
    item.LayoutOrder = i
    item.ZIndex = 20
    item.Text = "  " .. getPartLabel(i)
    item.MouseEnter:Connect(function()
        item.BackgroundTransparency = 0
        item.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
    end)
    item.MouseLeave:Connect(function()
        item.BackgroundTransparency = 1
    end)
    item.MouseButton1Click:Connect(function()
        selectedStartPart = i
        updateDropdownLabel()
        closeDropdown()
    end)
end

dropdownBtn.MouseButton1Click:Connect(function()
    dropdownOpen = not dropdownOpen
    dropdownList.Visible = dropdownOpen
    arrowLabel.Text = dropdownOpen and "▲" or "▼"
end)

updateDropdownLabel()

local savePartBtn = makeBtn(fuzzyTab, "SAVE START PART", 8)
savePartBtn.LayoutOrder = 8
savePartBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 50)
savePartBtn.TextColor3 = Color3.fromRGB(130, 160, 255)
savePartBtn.MouseButton1Click:Connect(function()
    closeDropdown()
    local progressFile = PROGRESS_FILE_PREFIX .. lp.Name .. ".json"
    local ok = pcall(function()
        writefile(progressFile, HttpService:JSONEncode({
            part    = selectedStartPart,
            account = lp.Name
        }))
    end)
    if ok then
        savePartBtn.Text = "✓ SAVED (Part " .. selectedStartPart .. ")"
        savePartBtn.TextColor3 = Color3.fromRGB(80, 200, 80)
        refreshStatus()
        task.wait(1.5)
        savePartBtn.Text = "SAVE START PART"
        savePartBtn.TextColor3 = Color3.fromRGB(130, 160, 255)
    else
        savePartBtn.Text = "✗ ERROR"
        savePartBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
        task.wait(1.5)
        savePartBtn.Text = "SAVE START PART"
        savePartBtn.TextColor3 = Color3.fromRGB(130, 160, 255)
    end
end)

sectionLabel(fuzzyTab, "Manual Control", 9)

local startFuzzyBtn = makeBtn(fuzzyTab, "▶ START FUZZY ALT", 10)
startFuzzyBtn.LayoutOrder = 10
startFuzzyBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
startFuzzyBtn.TextColor3 = Color3.fromRGB(100, 255, 100)
startFuzzyBtn.MouseButton1Click:Connect(function()
    if fuzzyAltCallback then
        closeDropdown()
        startFuzzyBtn.Text = "RUNNING..."
        startFuzzyBtn.BackgroundColor3 = Color3.fromRGB(30, 60, 30)
        startFuzzyBtn.TextColor3 = Color3.fromRGB(60, 160, 60)
        fuzzyAltCallback(selectedStartPart)
    end
end)

local resetBtn = makeBtn(fuzzyTab, "⚠ RESET PROGRESS", 11)
resetBtn.LayoutOrder = 11
resetBtn.BackgroundColor3 = Color3.fromRGB(60, 28, 28)
resetBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
resetBtn.MouseButton1Click:Connect(function()
    local progressFile = PROGRESS_FILE_PREFIX .. lp.Name .. ".json"
    pcall(function() delfile(progressFile) end)
    startFuzzyBtn.Text = "▶ START FUZZY ALT"
    startFuzzyBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
    startFuzzyBtn.TextColor3 = Color3.fromRGB(100, 255, 100)
    refreshStatus()
end)

-- ════════════════════════════════════════════════════════════
--  TAB 5: ROUTES
-- ════════════════════════════════════════════════════════════
local routesTab = makeTabFrame()
tabs["Routes"] = routesTab
tabBtns["Routes"] = makeTabBtn("🗺 Routes", 5)
tabBtns["Routes"].MouseButton1Click:Connect(function() switchTab("Routes") end)

local openBuilderCallback = nil
local stopRouteCallback   = nil

sectionLabel(routesTab, "Route Runner", 1)

local routeStatusBox = Instance.new("Frame", routesTab)
routeStatusBox.Size = UDim2.new(1, 0, 0, 44)
routeStatusBox.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
routeStatusBox.BorderSizePixel = 0
routeStatusBox.LayoutOrder = 2
Instance.new("UICorner", routeStatusBox).CornerRadius = UDim.new(0, 6)
local routeStatusPad = Instance.new("UIPadding", routeStatusBox)
routeStatusPad.PaddingLeft = UDim.new(0, 10)
routeStatusPad.PaddingTop  = UDim.new(0, 6)

local routeStatusLabel = Instance.new("TextLabel", routeStatusBox)
routeStatusLabel.Size = UDim2.new(1, -10, 1, 0)
routeStatusLabel.BackgroundTransparency = 1
routeStatusLabel.Text = "No route running"
routeStatusLabel.Font = Enum.Font.Gotham
routeStatusLabel.TextSize = 12
routeStatusLabel.TextColor3 = Color3.fromRGB(130, 130, 130)
routeStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
routeStatusLabel.TextWrapped = true

local openBuilderBtn = makeBtn(routesTab, "📋 OPEN ROUTE BUILDER", 3)
openBuilderBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 50)
openBuilderBtn.TextColor3 = Color3.fromRGB(130, 160, 255)
openBuilderBtn.MouseButton1Click:Connect(function()
    if openBuilderCallback then openBuilderCallback() end
end)

local stopRouteBtn = makeBtn(routesTab, "⏹ STOP ROUTE", 4)
stopRouteBtn.BackgroundColor3 = Color3.fromRGB(60, 28, 28)
stopRouteBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
stopRouteBtn.MouseButton1Click:Connect(function()F
    if stopRouteCallback then stopRouteCallback() end
end)


-- ════════════════════════════════════════════════════════════
--  TAB 6: SETTINGS
-- ════════════════════════════════════════════════════════════
local settingsTab = makeTabFrame()
tabs["Settings"] = settingsTab
tabBtns["Settings"] = makeTabBtn("⚙ Settings", 6)
tabBtns["Settings"].MouseButton1Click:Connect(function() switchTab("Settings") end)

sectionLabel(settingsTab, "Webhook URL", 1)

local webhookRow = Instance.new("Frame", settingsTab)
webhookRow.Size = UDim2.new(1, 0, 0, 34)
webhookRow.BackgroundTransparency = 1
webhookRow.LayoutOrder = 2

local webhookBox = Instance.new("TextBox", webhookRow)
webhookBox.Size = UDim2.new(1, -70, 1, 0)
webhookBox.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
webhookBox.BorderSizePixel = 0
webhookBox.Text = config.webhookUrl
webhookBox.PlaceholderText = "https://discord.com/api/webhooks/..."
webhookBox.PlaceholderColor3 = Color3.fromRGB(70, 70, 70)
webhookBox.Font = Enum.Font.Code
webhookBox.TextSize = 11
webhookBox.TextColor3 = Color3.fromRGB(200, 200, 200)
webhookBox.ClearTextOnFocus = false
webhookBox.TextXAlignment = Enum.TextXAlignment.Left
webhookBox.TextTruncate = Enum.TextTruncate.AtEnd
Instance.new("UICorner", webhookBox).CornerRadius = UDim.new(0, 6)
Instance.new("UIPadding", webhookBox).PaddingLeft = UDim.new(0, 8)

local saveWebhookBtn = Instance.new("TextButton", webhookRow)
saveWebhookBtn.Size = UDim2.new(0, 62, 1, 0)
saveWebhookBtn.Position = UDim2.new(1, -62, 0, 0)
saveWebhookBtn.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
saveWebhookBtn.Text = "SAVE"
saveWebhookBtn.Font = Enum.Font.GothamBold
saveWebhookBtn.TextSize = 11
saveWebhookBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
saveWebhookBtn.BorderSizePixel = 0
Instance.new("UICorner", saveWebhookBtn).CornerRadius = UDim.new(0, 6)
saveWebhookBtn.MouseButton1Click:Connect(function()
    config.webhookUrl = webhookBox.Text
    saveConfig()
    saveWebhookBtn.Text = "✓"
    saveWebhookBtn.TextColor3 = Color3.fromRGB(80, 200, 80)
    task.wait(1.5)
    saveWebhookBtn.Text = "SAVE"
    saveWebhookBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
end)

sectionLabel(settingsTab, "Debug Console", 3)

makeToggleRow(settingsTab, "Show debug console", 4, config.debugEnabled, function(enabled)
    config.debugEnabled = enabled
    saveConfig()
    if debugToggleCallback then debugToggleCallback(enabled) end
end)

-- ════════════════════════════════════════════════════════════
--  Default tab
-- ════════════════════════════════════════════════════════════
switchTab("Hive Scanner")

return {
    config             = config,
    adjusterTabFrame   = adjusterTabFrame,
    onScan             = function(cb) scanCallback = cb end,
    onRJBuy            = function(cb) rjBuyCallback = cb end,
    onDebugToggle      = function(cb) debugToggleCallback = cb end,
    onFuzzyAlt         = function(cb) fuzzyAltCallback = cb end,
    refreshFuzzyStatus = refreshStatus,
    -- Routes
    onOpenBuilder  = function(cb) openBuilderCallback = cb end,
    onStopRoute    = function(cb) stopRouteCallback = cb end,
    setRouteStatus = function(text) routeStatusLabel.Text = text end,
}
