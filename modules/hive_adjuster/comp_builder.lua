local HttpService = game:GetService("HttpService")

local function buildCompBuilderTab(tabFrame, beeAbilities, compIO, dlog)

    local allTokens = {}
    local tokenSet = {}
    for _, data in pairs(beeAbilities) do
        for _, token in ipairs(data.tokens) do
            if not tokenSet[token] then
                tokenSet[token] = true
                table.insert(allTokens, token)
            end
        end
    end
    table.sort(allTokens)

    local allBees = {}
    for name, _ in pairs(beeAbilities) do
        table.insert(allBees, name)
    end
    table.sort(allBees)

    local currentComp = {
        name = "New Comp",
        hiveSize = 25,
        requirements = {},
        keepList = {},
        neverKeep = {},
        eventBees = {},
        globalStopIfGifted = false
    }

    local function makeLabel(parent, text, size, pos, color, order)
        local lbl = Instance.new("TextLabel", parent)
        lbl.Size = size or UDim2.new(1, 0, 0, 20)
        lbl.Position = pos or UDim2.new(0, 0, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 11
        lbl.TextColor3 = color or Color3.fromRGB(180, 180, 180)
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        if order then lbl.LayoutOrder = order end
        return lbl
    end

    local function makeInput(parent, placeholder, order)
        local box = Instance.new("TextBox", parent)
        box.Size = UDim2.new(1, 0, 0, 28)
        box.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
        box.BorderSizePixel = 0
        box.Text = ""
        box.PlaceholderText = placeholder
        box.PlaceholderColor3 = Color3.fromRGB(70, 70, 70)
        box.Font = Enum.Font.Code
        box.TextSize = 11
        box.TextColor3 = Color3.fromRGB(200, 200, 200)
        box.ClearTextOnFocus = false
        box.TextXAlignment = Enum.TextXAlignment.Left
        box.LayoutOrder = order or 0
        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
        Instance.new("UIPadding", box).PaddingLeft = UDim.new(0, 6)
        return box
    end

    local function makeBtn(parent, text, order, width)
        local btn = Instance.new("TextButton", parent)
        btn.Size = width and UDim2.new(0, width, 0, 28) or UDim2.new(1, 0, 0, 28)
        btn.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
        btn.Text = text
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 11
        btn.TextColor3 = Color3.fromRGB(200, 200, 200)
        btn.BorderSizePixel = 0
        btn.LayoutOrder = order or 0
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        return btn
    end

    local function makeDropdown(parent, options, default, order)
        local frame = Instance.new("Frame", parent)
        frame.Size = UDim2.new(1, 0, 0, 28)
        frame.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
        frame.BorderSizePixel = 0
        frame.LayoutOrder = order or 0
        frame.ZIndex = 10
        frame.ClipsDescendants = false
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

        local selected = Instance.new("TextButton", frame)
        selected.Size = UDim2.new(1, 0, 1, 0)
        selected.BackgroundTransparency = 1
        selected.Text = default or options[1] or "Select..."
        selected.Font = Enum.Font.Code
        selected.TextSize = 11
        selected.TextColor3 = Color3.fromRGB(200, 200, 200)
        selected.TextXAlignment = Enum.TextXAlignment.Left
        selected.ZIndex = 10
        Instance.new("UIPadding", selected).PaddingLeft = UDim.new(0, 6)

        local isOpen = false

        local dropdown = Instance.new("Frame", frame)
        dropdown.Size = UDim2.new(1, 0, 0, math.min(#options, 6) * 28)
        dropdown.Position = UDim2.new(0, 0, 1, 2)
        dropdown.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        dropdown.BorderSizePixel = 0
        dropdown.Visible = false
        dropdown.ZIndex = 100
        dropdown.ClipsDescendants = false
        Instance.new("UICorner", dropdown).CornerRadius = UDim.new(0, 6)

        local ddScroll = Instance.new("ScrollingFrame", dropdown)
        ddScroll.Size = UDim2.new(1, 0, 1, 0)
        ddScroll.BackgroundTransparency = 1
        ddScroll.BorderSizePixel = 0
        ddScroll.ScrollBarThickness = 4
        ddScroll.CanvasSize = UDim2.new(0, 0, 0, #options * 28)
        ddScroll.ZIndex = 100

        local ddLayout = Instance.new("UIListLayout", ddScroll)
        ddLayout.SortOrder = Enum.SortOrder.LayoutOrder

        local onChange = nil

        for i, option in ipairs(options) do
            local optBtn = Instance.new("TextButton", ddScroll)
            optBtn.Size = UDim2.new(1, 0, 0, 28)
            optBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            optBtn.BackgroundTransparency = 0
            optBtn.Text = option
            optBtn.Font = Enum.Font.Code
            optBtn.TextSize = 11
            optBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
            optBtn.TextXAlignment = Enum.TextXAlignment.Left
            optBtn.LayoutOrder = i
            optBtn.ZIndex = 100
            Instance.new("UIPadding", optBtn).PaddingLeft = UDim.new(0, 6)

            optBtn.MouseButton1Click:Connect(function()
                selected.Text = option
                dropdown.Visible = false
                isOpen = false
                if onChange then onChange(option) end
            end)
            optBtn.MouseEnter:Connect(function()
                optBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
            end)
            optBtn.MouseLeave:Connect(function()
                optBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            end)
        end

        selected.MouseButton1Click:Connect(function()
            isOpen = not isOpen
            dropdown.Visible = isOpen
        end)

        return frame, selected, function(fn) onChange = fn end
    end

    local scroll = Instance.new("ScrollingFrame", tabFrame)
    scroll.Size = UDim2.new(1, 0, 1, 0)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 4
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)

    local mainLayout = Instance.new("UIListLayout", scroll)
    mainLayout.SortOrder = Enum.SortOrder.LayoutOrder
    mainLayout.Padding = UDim.new(0, 8)
    mainLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0, 0, 0, mainLayout.AbsoluteContentSize.Y + 20)
    end)

    local function section(text, order)
        local lbl = Instance.new("TextLabel", scroll)
        lbl.Size = UDim2.new(1, 0, 0, 14)
        lbl.BackgroundTransparency = 1
        lbl.Text = text:upper()
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 10
        lbl.TextColor3 = Color3.fromRGB(120, 120, 120)
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.LayoutOrder = order
        return lbl
    end

    section("Comp Name", 1)
    local nameInput = makeInput(scroll, "Comp name...", 2)
    nameInput.Text = currentComp.name
    nameInput:GetPropertyChangedSignal("Text"):Connect(function()
        currentComp.name = nameInput.Text
    end)

    section("Hive Size", 3)
    local _, hiveSizeSelected, onHiveSizeChange = makeDropdown(
        scroll,
        {"25", "50", "75", "100", "125", "150", "175", "200", "225"},
        "25",
        4
    )
    onHiveSizeChange(function(val)
        currentComp.hiveSize = tonumber(val)
    end)

    -- ── REQUIREMENTS ──────────────────────────────────────────────────
    section("Requirements", 5)

    local reqContainer = Instance.new("Frame", scroll)
    reqContainer.Size = UDim2.new(1, 0, 0, 0)
    reqContainer.BackgroundTransparency = 1
    reqContainer.BorderSizePixel = 0
    reqContainer.AutomaticSize = Enum.AutomaticSize.Y
    reqContainer.LayoutOrder = 6

    local reqLayout = Instance.new("UIListLayout", reqContainer)
    reqLayout.SortOrder = Enum.SortOrder.LayoutOrder
    reqLayout.Padding = UDim.new(0, 4)

    local function addReqRow(req)
        local row = Instance.new("Frame", reqContainer)
        row.Size = UDim2.new(1, 0, 0, 28)
        row.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
        row.BorderSizePixel = 0
        row.LayoutOrder = #currentComp.requirements
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

        local typeLbl = Instance.new("TextLabel", row)
        typeLbl.Size = UDim2.new(0, 60, 1, 0)
        typeLbl.Position = UDim2.new(0, 4, 0, 0)
        typeLbl.BackgroundTransparency = 1
        typeLbl.Text = req.type == "token" and "TOKEN" or "BEE"
        typeLbl.Font = Enum.Font.GothamBold
        typeLbl.TextSize = 10
        typeLbl.TextColor3 = req.type == "token" and Color3.fromRGB(50, 200, 255) or Color3.fromRGB(255, 200, 50)
        typeLbl.TextXAlignment = Enum.TextXAlignment.Left

        local valueLbl = Instance.new("TextLabel", row)
        valueLbl.Size = UDim2.new(1, -160, 1, 0)
        valueLbl.Position = UDim2.new(0, 66, 0, 0)
        valueLbl.BackgroundTransparency = 1
        valueLbl.Text = req.value .. " x" .. req.count .. (req.gifted and " ★" or "")
        valueLbl.Font = Enum.Font.Code
        valueLbl.TextSize = 11
        valueLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
        valueLbl.TextXAlignment = Enum.TextXAlignment.Left

        local removeBtn = Instance.new("TextButton", row)
        removeBtn.Size = UDim2.new(0, 24, 0, 24)
        removeBtn.Position = UDim2.new(1, -28, 0.5, -12)
        removeBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
        removeBtn.Text = "✕"
        removeBtn.Font = Enum.Font.GothamBold
        removeBtn.TextSize = 11
        removeBtn.TextColor3 = Color3.new(1,1,1)
        removeBtn.BorderSizePixel = 0
        Instance.new("UICorner", removeBtn).CornerRadius = UDim.new(0, 4)
        removeBtn.MouseButton1Click:Connect(function()
            for i, r in ipairs(currentComp.requirements) do
                if r == req then
                    table.remove(currentComp.requirements, i)
                    break
                end
            end
            row:Destroy()
        end)
    end

    local addReqFrame = Instance.new("Frame", scroll)
    addReqFrame.Size = UDim2.new(1, 0, 0, 100)
    addReqFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
    addReqFrame.BorderSizePixel = 0
    addReqFrame.LayoutOrder = 7
    addReqFrame.ClipsDescendants = false
    Instance.new("UICorner", addReqFrame).CornerRadius = UDim.new(0, 6)

    local addReqLayout = Instance.new("UIListLayout", addReqFrame)
    addReqLayout.SortOrder = Enum.SortOrder.LayoutOrder
    addReqLayout.Padding = UDim.new(0, 4)

    local addReqPad = Instance.new("UIPadding", addReqFrame)
    addReqPad.PaddingLeft = UDim.new(0, 6)
    addReqPad.PaddingRight = UDim.new(0, 6)
    addReqPad.PaddingTop = UDim.new(0, 6)
    addReqPad.PaddingBottom = UDim.new(0, 6)

    local _, reqTypeSelected, onReqTypeChange = makeDropdown(addReqFrame, {"token", "specific"}, "token", 1)
    local currentReqType = "token"
    local currentReqValue = allTokens[1]
    local reqValueDropdown = nil

    local function buildValueDropdown()
        if reqValueDropdown then reqValueDropdown:Destroy() end
        local options = currentReqType == "token" and allTokens or allBees
        currentReqValue = options[1]
        local container, _, onValueChange = makeDropdown(addReqFrame, options, options[1], 2)
        reqValueDropdown = container
        onValueChange(function(val) currentReqValue = val end)
    end

    buildValueDropdown()
    onReqTypeChange(function(val)
        currentReqType = val
        buildValueDropdown()
    end)

    local bottomRow = Instance.new("Frame", addReqFrame)
    bottomRow.Size = UDim2.new(1, 0, 0, 28)
    bottomRow.BackgroundTransparency = 1
    bottomRow.BorderSizePixel = 0
    bottomRow.LayoutOrder = 3

    local countInput = Instance.new("TextBox", bottomRow)
    countInput.Size = UDim2.new(0, 60, 1, 0)
    countInput.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
    countInput.BorderSizePixel = 0
    countInput.Text = "1"
    countInput.PlaceholderText = "Count"
    countInput.Font = Enum.Font.Code
    countInput.TextSize = 11
    countInput.TextColor3 = Color3.fromRGB(200, 200, 200)
    countInput.ClearTextOnFocus = false
    Instance.new("UICorner", countInput).CornerRadius = UDim.new(0, 6)
    Instance.new("UIPadding", countInput).PaddingLeft = UDim.new(0, 6)

    local giftedBtn = Instance.new("TextButton", bottomRow)
    giftedBtn.Size = UDim2.new(0, 80, 1, 0)
    giftedBtn.Position = UDim2.new(0, 68, 0, 0)
    giftedBtn.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
    giftedBtn.Text = "Gifted: OFF"
    giftedBtn.Font = Enum.Font.GothamBold
    giftedBtn.TextSize = 10
    giftedBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
    giftedBtn.BorderSizePixel = 0
    Instance.new("UICorner", giftedBtn).CornerRadius = UDim.new(0, 6)

    local reqGifted = false
    giftedBtn.MouseButton1Click:Connect(function()
        reqGifted = not reqGifted
        giftedBtn.Text = reqGifted and "Gifted: ON" or "Gifted: OFF"
        giftedBtn.TextColor3 = reqGifted and Color3.fromRGB(255, 200, 50) or Color3.fromRGB(150, 150, 150)
        giftedBtn.BackgroundColor3 = reqGifted and Color3.fromRGB(60, 50, 20) or Color3.fromRGB(38, 38, 38)
    end)

    local addReqBtn = Instance.new("TextButton", bottomRow)
    addReqBtn.Size = UDim2.new(0, 60, 1, 0)
    addReqBtn.Position = UDim2.new(1, -60, 0, 0)
    addReqBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
    addReqBtn.Text = "+ ADD"
    addReqBtn.Font = Enum.Font.GothamBold
    addReqBtn.TextSize = 10
    addReqBtn.TextColor3 = Color3.fromRGB(100, 255, 100)
    addReqBtn.BorderSizePixel = 0
    Instance.new("UICorner", addReqBtn).CornerRadius = UDim.new(0, 6)
    addReqBtn.MouseButton1Click:Connect(function()
        local count = tonumber(countInput.Text) or 1
        local req = {
            type = currentReqType,
            value = currentReqValue,
            count = count,
            gifted = reqGifted
        }
        table.insert(currentComp.requirements, req)
        addReqRow(req)
        dlog("Added requirement: " .. currentReqType .. " " .. currentReqValue .. " x" .. count)
    end)

    -- ── KEEP LIST ─────────────────────────────────────────────────────
    section("Keep List", 8)

    local keepContainer = Instance.new("Frame", scroll)
    keepContainer.Size = UDim2.new(1, 0, 0, 0)
    keepContainer.BackgroundTransparency = 1
    keepContainer.BorderSizePixel = 0
    keepContainer.AutomaticSize = Enum.AutomaticSize.Y
    keepContainer.LayoutOrder = 9

    local keepLayout = Instance.new("UIListLayout", keepContainer)
    keepLayout.SortOrder = Enum.SortOrder.LayoutOrder
    keepLayout.Padding = UDim.new(0, 4)

    local function addKeepRow(entry)
        local row = Instance.new("Frame", keepContainer)
        row.Size = UDim2.new(1, 0, 0, 28)
        row.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
        row.BorderSizePixel = 0
        row.LayoutOrder = #currentComp.keepList
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

        -- bee name
        local nameLbl = Instance.new("TextLabel", row)
        nameLbl.Size = UDim2.new(0, 90, 1, 0)
        nameLbl.Position = UDim2.new(0, 6, 0, 0)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = entry.name
        nameLbl.Font = Enum.Font.Code
        nameLbl.TextSize = 11
        nameLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left

        -- gifted label
        local giftedLbl = Instance.new("TextLabel", row)
        giftedLbl.Size = UDim2.new(0, 70, 1, 0)
        giftedLbl.Position = UDim2.new(0, 100, 0, 0)
        giftedLbl.BackgroundTransparency = 1
        giftedLbl.Text = entry.stopIfGifted and "Gifted only" or "Always"
        giftedLbl.Font = Enum.Font.GothamBold
        giftedLbl.TextSize = 10
        giftedLbl.TextColor3 = entry.stopIfGifted and Color3.fromRGB(255, 200, 50) or Color3.fromRGB(50, 255, 100)
        giftedLbl.TextXAlignment = Enum.TextXAlignment.Left

        -- max count label
        local maxLbl = Instance.new("TextLabel", row)
        maxLbl.Size = UDim2.new(0, 50, 1, 0)
        maxLbl.Position = UDim2.new(0, 174, 0, 0)
        maxLbl.BackgroundTransparency = 1
        maxLbl.Font = Enum.Font.GothamBold
        maxLbl.TextSize = 10
        maxLbl.TextXAlignment = Enum.TextXAlignment.Left
        if entry.maxCount then
            maxLbl.Text = "Max:" .. entry.maxCount
            maxLbl.TextColor3 = Color3.fromRGB(130, 160, 255)
        else
            maxLbl.Text = "No cap"
            maxLbl.TextColor3 = Color3.fromRGB(100, 100, 100)
        end

        local removeBtn = Instance.new("TextButton", row)
        removeBtn.Size = UDim2.new(0, 24, 0, 24)
        removeBtn.Position = UDim2.new(1, -28, 0.5, -12)
        removeBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
        removeBtn.Text = "✕"
        removeBtn.Font = Enum.Font.GothamBold
        removeBtn.TextSize = 11
        removeBtn.TextColor3 = Color3.new(1,1,1)
        removeBtn.BorderSizePixel = 0
        Instance.new("UICorner", removeBtn).CornerRadius = UDim.new(0, 4)
        removeBtn.MouseButton1Click:Connect(function()
            for i, e in ipairs(currentComp.keepList) do
                if e == entry then
                    table.remove(currentComp.keepList, i)
                    break
                end
            end
            row:Destroy()
        end)
    end

    local addKeepFrame = Instance.new("Frame", scroll)
    addKeepFrame.Size = UDim2.new(1, 0, 0, 0)
    addKeepFrame.AutomaticSize = Enum.AutomaticSize.Y
    addKeepFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
    addKeepFrame.BorderSizePixel = 0
    addKeepFrame.LayoutOrder = 10
    addKeepFrame.ClipsDescendants = false
    Instance.new("UICorner", addKeepFrame).CornerRadius = UDim.new(0, 6)

    local addKeepLayout = Instance.new("UIListLayout", addKeepFrame)
    addKeepLayout.SortOrder = Enum.SortOrder.LayoutOrder
    addKeepLayout.Padding = UDim.new(0, 4)

    local addKeepPad = Instance.new("UIPadding", addKeepFrame)
    addKeepPad.PaddingLeft = UDim.new(0, 6)
    addKeepPad.PaddingRight = UDim.new(0, 6)
    addKeepPad.PaddingTop = UDim.new(0, 6)
    addKeepPad.PaddingBottom = UDim.new(0, 6)

    local _, keepBeeSelected, onKeepBeeChange = makeDropdown(addKeepFrame, allBees, allBees[1], 1)
    local currentKeepBee = allBees[1]
    onKeepBeeChange(function(val) currentKeepBee = val end)

    local keepBottomRow = Instance.new("Frame", addKeepFrame)
    keepBottomRow.Size = UDim2.new(1, 0, 0, 28)
    keepBottomRow.BackgroundTransparency = 1
    keepBottomRow.BorderSizePixel = 0
    keepBottomRow.LayoutOrder = 2

    local keepGiftedBtn = Instance.new("TextButton", keepBottomRow)
    keepGiftedBtn.Size = UDim2.new(0, 100, 1, 0)
    keepGiftedBtn.Position = UDim2.new(0, 0, 0, 0)
    keepGiftedBtn.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
    keepGiftedBtn.Text = "Gifted only: OFF"
    keepGiftedBtn.Font = Enum.Font.GothamBold
    keepGiftedBtn.TextSize = 10
    keepGiftedBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
    keepGiftedBtn.BorderSizePixel = 0
    Instance.new("UICorner", keepGiftedBtn).CornerRadius = UDim.new(0, 6)

    local keepStopIfGifted = false
    keepGiftedBtn.MouseButton1Click:Connect(function()
        keepStopIfGifted = not keepStopIfGifted
        keepGiftedBtn.Text = keepStopIfGifted and "Gifted only: ON" or "Gifted only: OFF"
        keepGiftedBtn.TextColor3 = keepStopIfGifted and Color3.fromRGB(255, 200, 50) or Color3.fromRGB(150, 150, 150)
        keepGiftedBtn.BackgroundColor3 = keepStopIfGifted and Color3.fromRGB(60, 50, 20) or Color3.fromRGB(38, 38, 38)
    end)

    -- max count input for keep list
    local keepMaxInput = Instance.new("TextBox", keepBottomRow)
    keepMaxInput.Size = UDim2.new(0, 50, 1, 0)
    keepMaxInput.Position = UDim2.new(0, 108, 0, 0)
    keepMaxInput.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
    keepMaxInput.BorderSizePixel = 0
    keepMaxInput.Text = ""
    keepMaxInput.PlaceholderText = "Max"
    keepMaxInput.PlaceholderColor3 = Color3.fromRGB(70, 70, 70)
    keepMaxInput.Font = Enum.Font.Code
    keepMaxInput.TextSize = 11
    keepMaxInput.TextColor3 = Color3.fromRGB(200, 200, 200)
    keepMaxInput.ClearTextOnFocus = false
    Instance.new("UICorner", keepMaxInput).CornerRadius = UDim.new(0, 6)
    Instance.new("UIPadding", keepMaxInput).PaddingLeft = UDim.new(0, 6)

    local addKeepBtn = Instance.new("TextButton", keepBottomRow)
    addKeepBtn.Size = UDim2.new(0, 60, 1, 0)
    addKeepBtn.Position = UDim2.new(1, -60, 0, 0)
    addKeepBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
    addKeepBtn.Text = "+ ADD"
    addKeepBtn.Font = Enum.Font.GothamBold
    addKeepBtn.TextSize = 10
    addKeepBtn.TextColor3 = Color3.fromRGB(100, 255, 100)
    addKeepBtn.BorderSizePixel = 0
    Instance.new("UICorner", addKeepBtn).CornerRadius = UDim.new(0, 6)
    addKeepBtn.MouseButton1Click:Connect(function()
        local maxVal = tonumber(keepMaxInput.Text) or nil
        local entry = {
            name = currentKeepBee,
            stopIfGifted = keepStopIfGifted,
            maxCount = maxVal
        }
        table.insert(currentComp.keepList, entry)
        addKeepRow(entry)
        dlog("Added to keep list: " .. currentKeepBee .. (maxVal and " (max " .. maxVal .. ")" or ""))
    end)

    -- ── NEVER KEEP ────────────────────────────────────────────────────
    section("Never Keep", 11)

    local neverKeepContainer = Instance.new("Frame", scroll)
    neverKeepContainer.Size = UDim2.new(1, 0, 0, 0)
    neverKeepContainer.BackgroundTransparency = 1
    neverKeepContainer.BorderSizePixel = 0
    neverKeepContainer.AutomaticSize = Enum.AutomaticSize.Y
    neverKeepContainer.LayoutOrder = 12

    local neverKeepLayout = Instance.new("UIListLayout", neverKeepContainer)
    neverKeepLayout.SortOrder = Enum.SortOrder.LayoutOrder
    neverKeepLayout.Padding = UDim.new(0, 4)

    local function addNeverKeepRow(entry)
        local row = Instance.new("Frame", neverKeepContainer)
        row.Size = UDim2.new(1, 0, 0, 28)
        row.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
        row.BorderSizePixel = 0
        row.LayoutOrder = #currentComp.neverKeep
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

        local nameLbl = Instance.new("TextLabel", row)
        nameLbl.Size = UDim2.new(1, -180, 1, 0)
        nameLbl.Position = UDim2.new(0, 6, 0, 0)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = entry.name
        nameLbl.Font = Enum.Font.Code
        nameLbl.TextSize = 11
        nameLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left

        local giftedOnlyLbl = Instance.new("TextLabel", row)
        giftedOnlyLbl.Size = UDim2.new(0, 120, 1, 0)
        giftedOnlyLbl.Position = UDim2.new(1, -148, 0, 0)
        giftedOnlyLbl.BackgroundTransparency = 1
        giftedOnlyLbl.Text = entry.giftedOnly and "Skip gifted" or "RJ all"
        giftedOnlyLbl.Font = Enum.Font.GothamBold
        giftedOnlyLbl.TextSize = 10
        giftedOnlyLbl.TextColor3 = entry.giftedOnly and Color3.fromRGB(255, 200, 50) or Color3.fromRGB(255, 100, 100)
        giftedOnlyLbl.TextXAlignment = Enum.TextXAlignment.Left

        local removeBtn = Instance.new("TextButton", row)
        removeBtn.Size = UDim2.new(0, 24, 0, 24)
        removeBtn.Position = UDim2.new(1, -28, 0.5, -12)
        removeBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
        removeBtn.Text = "✕"
        removeBtn.Font = Enum.Font.GothamBold
        removeBtn.TextSize = 11
        removeBtn.TextColor3 = Color3.new(1,1,1)
        removeBtn.BorderSizePixel = 0
        Instance.new("UICorner", removeBtn).CornerRadius = UDim.new(0, 4)
        removeBtn.MouseButton1Click:Connect(function()
            for i, e in ipairs(currentComp.neverKeep) do
                if e == entry then
                    table.remove(currentComp.neverKeep, i)
                    break
                end
            end
            row:Destroy()
        end)
    end

    local addNeverKeepFrame = Instance.new("Frame", scroll)
    addNeverKeepFrame.Size = UDim2.new(1, 0, 0, 0)
    addNeverKeepFrame.AutomaticSize = Enum.AutomaticSize.Y
    addNeverKeepFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
    addNeverKeepFrame.BorderSizePixel = 0
    addNeverKeepFrame.LayoutOrder = 13
    addNeverKeepFrame.ClipsDescendants = false
    Instance.new("UICorner", addNeverKeepFrame).CornerRadius = UDim.new(0, 6)

    local addNKLayout = Instance.new("UIListLayout", addNeverKeepFrame)
    addNKLayout.SortOrder = Enum.SortOrder.LayoutOrder
    addNKLayout.Padding = UDim.new(0, 4)

    local addNKPad = Instance.new("UIPadding", addNeverKeepFrame)
    addNKPad.PaddingLeft = UDim.new(0, 6)
    addNKPad.PaddingRight = UDim.new(0, 6)
    addNKPad.PaddingTop = UDim.new(0, 6)
    addNKPad.PaddingBottom = UDim.new(0, 6)

    local _, nkBeeSelected, onNKBeeChange = makeDropdown(addNeverKeepFrame, allBees, allBees[1], 1)
    local currentNKBee = allBees[1]
    onNKBeeChange(function(val) currentNKBee = val end)

    local nkBottomRow = Instance.new("Frame", addNeverKeepFrame)
    nkBottomRow.Size = UDim2.new(1, 0, 0, 28)
    nkBottomRow.BackgroundTransparency = 1
    nkBottomRow.BorderSizePixel = 0
    nkBottomRow.LayoutOrder = 2

    local nkGiftedOnlyBtn = Instance.new("TextButton", nkBottomRow)
    nkGiftedOnlyBtn.Size = UDim2.new(0, 140, 1, 0)
    nkGiftedOnlyBtn.Position = UDim2.new(0, 0, 0, 0)
    nkGiftedOnlyBtn.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
    nkGiftedOnlyBtn.Text = "Skip gifted: OFF"
    nkGiftedOnlyBtn.Font = Enum.Font.GothamBold
    nkGiftedOnlyBtn.TextSize = 10
    nkGiftedOnlyBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
    nkGiftedOnlyBtn.BorderSizePixel = 0
    Instance.new("UICorner", nkGiftedOnlyBtn).CornerRadius = UDim.new(0, 6)

    local nkGiftedOnly = false
    nkGiftedOnlyBtn.MouseButton1Click:Connect(function()
        nkGiftedOnly = not nkGiftedOnly
        nkGiftedOnlyBtn.Text = nkGiftedOnly and "Skip gifted: ON" or "Skip gifted: OFF"
        nkGiftedOnlyBtn.TextColor3 = nkGiftedOnly and Color3.fromRGB(255, 200, 50) or Color3.fromRGB(150, 150, 150)
        nkGiftedOnlyBtn.BackgroundColor3 = nkGiftedOnly and Color3.fromRGB(60, 50, 20) or Color3.fromRGB(38, 38, 38)
    end)

    local addNKBtn = Instance.new("TextButton", nkBottomRow)
    addNKBtn.Size = UDim2.new(0, 60, 1, 0)
    addNKBtn.Position = UDim2.new(1, -60, 0, 0)
    addNKBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
    addNKBtn.Text = "+ ADD"
    addNKBtn.Font = Enum.Font.GothamBold
    addNKBtn.TextSize = 10
    addNKBtn.TextColor3 = Color3.fromRGB(100, 255, 100)
    addNKBtn.BorderSizePixel = 0
    Instance.new("UICorner", addNKBtn).CornerRadius = UDim.new(0, 6)
    addNKBtn.MouseButton1Click:Connect(function()
        local entry = {
            name = currentNKBee,
            giftedOnly = nkGiftedOnly
        }
        table.insert(currentComp.neverKeep, entry)
        addNeverKeepRow(entry)
        dlog("Added to never keep: " .. currentNKBee .. (nkGiftedOnly and " (skip gifted)" or " (RJ all)"))
    end)

    -- ── EVENT BEES ────────────────────────────────────────────────────
    section("Event Bees (RJ at start)", 14)

    local eventBeeContainer = Instance.new("Frame", scroll)
    eventBeeContainer.Size = UDim2.new(1, 0, 0, 0)
    eventBeeContainer.BackgroundTransparency = 1
    eventBeeContainer.BorderSizePixel = 0
    eventBeeContainer.AutomaticSize = Enum.AutomaticSize.Y
    eventBeeContainer.LayoutOrder = 15

    local eventBeeLayout = Instance.new("UIListLayout", eventBeeContainer)
    eventBeeLayout.SortOrder = Enum.SortOrder.LayoutOrder
    eventBeeLayout.Padding = UDim.new(0, 4)

    local function addEventBeeRow(beeName)
        local row = Instance.new("Frame", eventBeeContainer)
        row.Size = UDim2.new(1, 0, 0, 28)
        row.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
        row.BorderSizePixel = 0
        row.LayoutOrder = #currentComp.eventBees
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

        local nameLbl = Instance.new("TextLabel", row)
        nameLbl.Size = UDim2.new(1, -36, 1, 0)
        nameLbl.Position = UDim2.new(0, 6, 0, 0)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = beeName
        nameLbl.Font = Enum.Font.Code
        nameLbl.TextSize = 11
        nameLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left

        local removeBtn = Instance.new("TextButton", row)
        removeBtn.Size = UDim2.new(0, 24, 0, 24)
        removeBtn.Position = UDim2.new(1, -28, 0.5, -12)
        removeBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
        removeBtn.Text = "✕"
        removeBtn.Font = Enum.Font.GothamBold
        removeBtn.TextSize = 11
        removeBtn.TextColor3 = Color3.new(1,1,1)
        removeBtn.BorderSizePixel = 0
        Instance.new("UICorner", removeBtn).CornerRadius = UDim.new(0, 4)
        removeBtn.MouseButton1Click:Connect(function()
            for i, e in ipairs(currentComp.eventBees) do
                if e == beeName then
                    table.remove(currentComp.eventBees, i)
                    break
                end
            end
            row:Destroy()
        end)
    end

    local addEventFrame = Instance.new("Frame", scroll)
    addEventFrame.Size = UDim2.new(1, 0, 0, 0)
    addEventFrame.AutomaticSize = Enum.AutomaticSize.Y
    addEventFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
    addEventFrame.BorderSizePixel = 0
    addEventFrame.LayoutOrder = 16
    addEventFrame.ClipsDescendants = false
    Instance.new("UICorner", addEventFrame).CornerRadius = UDim.new(0, 6)

    local addEventLayout = Instance.new("UIListLayout", addEventFrame)
    addEventLayout.SortOrder = Enum.SortOrder.LayoutOrder
    addEventLayout.Padding = UDim.new(0, 4)

    local addEventPad = Instance.new("UIPadding", addEventFrame)
    addEventPad.PaddingLeft = UDim.new(0, 6)
    addEventPad.PaddingRight = UDim.new(0, 6)
    addEventPad.PaddingTop = UDim.new(0, 6)
    addEventPad.PaddingBottom = UDim.new(0, 6)

    local addEventRow = Instance.new("Frame", addEventFrame)
    addEventRow.Size = UDim2.new(1, 0, 0, 28)
    addEventRow.BackgroundTransparency = 1
    addEventRow.BorderSizePixel = 0
    addEventRow.LayoutOrder = 1

    local _, eventBeeSelected, onEventBeeChange = makeDropdown(addEventFrame, allBees, allBees[1], 1)
    local currentEventBee = allBees[1]
    onEventBeeChange(function(val) currentEventBee = val end)

    local addEventBtn = Instance.new("TextButton", addEventFrame)
    addEventBtn.Size = UDim2.new(1, 0, 0, 28)
    addEventBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
    addEventBtn.Text = "+ ADD EVENT BEE"
    addEventBtn.Font = Enum.Font.GothamBold
    addEventBtn.TextSize = 10
    addEventBtn.TextColor3 = Color3.fromRGB(100, 255, 100)
    addEventBtn.BorderSizePixel = 0
    addEventBtn.LayoutOrder = 2
    Instance.new("UICorner", addEventBtn).CornerRadius = UDim.new(0, 6)
    addEventBtn.MouseButton1Click:Connect(function()
        table.insert(currentComp.eventBees, currentEventBee)
        addEventBeeRow(currentEventBee)
        dlog("Added event bee: " .. currentEventBee)
    end)

    -- ── GLOBAL SETTINGS ───────────────────────────────────────────────
    section("Global Settings", 17)

    local globalGiftedBtn = makeBtn(scroll, "Global Stop If Gifted: OFF", 18)
    globalGiftedBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
    globalGiftedBtn.MouseButton1Click:Connect(function()
        currentComp.globalStopIfGifted = not currentComp.globalStopIfGifted
        globalGiftedBtn.Text = currentComp.globalStopIfGifted and "Global Stop If Gifted: ON" or "Global Stop If Gifted: OFF"
        globalGiftedBtn.TextColor3 = currentComp.globalStopIfGifted and Color3.fromRGB(255, 200, 50) or Color3.fromRGB(150, 150, 150)
        globalGiftedBtn.BackgroundColor3 = currentComp.globalStopIfGifted and Color3.fromRGB(60, 50, 20) or Color3.fromRGB(38, 38, 38)
    end)

    -- ── REBUILD FROM LOADED COMP ──────────────────────────────────────
    local function rebuildFromComp(comp)
        for _, child in pairs(reqContainer:GetChildren()) do
            if not child:IsA("UIListLayout") then child:Destroy() end
        end
        for _, child in pairs(keepContainer:GetChildren()) do
            if not child:IsA("UIListLayout") then child:Destroy() end
        end
        for _, child in pairs(neverKeepContainer:GetChildren()) do
            if not child:IsA("UIListLayout") then child:Destroy() end
        end
        for _, child in pairs(eventBeeContainer:GetChildren()) do
            if not child:IsA("UIListLayout") then child:Destroy() end
        end

        nameInput.Text = comp.name
        hiveSizeSelected.Text = tostring(comp.hiveSize or 25)

        for _, req in ipairs(comp.requirements or {}) do addReqRow(req) end
        for _, entry in ipairs(comp.keepList or {}) do addKeepRow(entry) end
        for _, entry in ipairs(comp.neverKeep or {}) do addNeverKeepRow(entry) end
        for _, name in ipairs(comp.eventBees or {}) do addEventBeeRow(name) end

        local g = comp.globalStopIfGifted or false
        globalGiftedBtn.Text = g and "Global Stop If Gifted: ON" or "Global Stop If Gifted: OFF"
        globalGiftedBtn.TextColor3 = g and Color3.fromRGB(255, 200, 50) or Color3.fromRGB(150, 150, 150)
        globalGiftedBtn.BackgroundColor3 = g and Color3.fromRGB(60, 50, 20) or Color3.fromRGB(38, 38, 38)
    end

    -- ── SAVE & LOAD ───────────────────────────────────────────────────
    section("Save & Load", 19)

    local saveBtn = makeBtn(scroll, "SAVE COMP", 20)
    saveBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
    saveBtn.TextColor3 = Color3.fromRGB(100, 255, 100)
    saveBtn.MouseButton1Click:Connect(function()
        if currentComp.name == "" then
            dlog("ERROR: Comp needs a name!")
            return
        end
        local ok = compIO.save(currentComp)
        if ok then
            dlog("Saved comp: " .. currentComp.name)
            saveBtn.Text = "✓ SAVED"
            task.wait(1.5)
            saveBtn.Text = "SAVE COMP"
            refreshCompList()
        else
            dlog("ERROR: Failed to save comp!")
        end
    end)

    local loadSection = Instance.new("Frame", scroll)
    loadSection.Size = UDim2.new(1, 0, 0, 0)
    loadSection.BackgroundTransparency = 1
    loadSection.AutomaticSize = Enum.AutomaticSize.Y
    loadSection.BorderSizePixel = 0
    loadSection.LayoutOrder = 21

    local loadLayout = Instance.new("UIListLayout", loadSection)
    loadLayout.SortOrder = Enum.SortOrder.LayoutOrder
    loadLayout.Padding = UDim.new(0, 4)

    function refreshCompList()
        for _, child in pairs(loadSection:GetChildren()) do
            if not child:IsA("UIListLayout") then child:Destroy() end
        end
        local comps = compIO.list()
        if #comps == 0 then
            makeLabel(loadSection, "No saved comps", UDim2.new(1, 0, 0, 20), nil, Color3.fromRGB(100, 100, 100), 1)
            return
        end
        for i, compName in ipairs(comps) do
            local row = Instance.new("Frame", loadSection)
            row.Size = UDim2.new(1, 0, 0, 28)
            row.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
            row.BorderSizePixel = 0
            row.LayoutOrder = i
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

            local nameLbl = Instance.new("TextLabel", row)
            nameLbl.Size = UDim2.new(1, -120, 1, 0)
            nameLbl.Position = UDim2.new(0, 6, 0, 0)
            nameLbl.BackgroundTransparency = 1
            nameLbl.Text = compName
            nameLbl.Font = Enum.Font.Code
            nameLbl.TextSize = 11
            nameLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left

            local loadBtn = Instance.new("TextButton", row)
            loadBtn.Size = UDim2.new(0, 50, 0, 22)
            loadBtn.Position = UDim2.new(1, -112, 0.5, -11)
            loadBtn.BackgroundColor3 = Color3.fromRGB(40, 60, 80)
            loadBtn.Text = "LOAD"
            loadBtn.Font = Enum.Font.GothamBold
            loadBtn.TextSize = 10
            loadBtn.TextColor3 = Color3.fromRGB(100, 180, 255)
            loadBtn.BorderSizePixel = 0
            Instance.new("UICorner", loadBtn).CornerRadius = UDim.new(0, 4)
            loadBtn.MouseButton1Click:Connect(function()
                local loaded = compIO.load(compName)
                if loaded then
                    currentComp = loaded
                    rebuildFromComp(loaded)
                    dlog("Loaded comp: " .. compName)
                else
                    dlog("ERROR: Failed to load comp!")
                end
            end)

            local deleteBtn = Instance.new("TextButton", row)
            deleteBtn.Size = UDim2.new(0, 50, 0, 22)
            deleteBtn.Position = UDim2.new(1, -58, 0.5, -11)
            deleteBtn.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
            deleteBtn.Text = "DELETE"
            deleteBtn.Font = Enum.Font.GothamBold
            deleteBtn.TextSize = 10
            deleteBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
            deleteBtn.BorderSizePixel = 0
            Instance.new("UICorner", deleteBtn).CornerRadius = UDim.new(0, 4)
            deleteBtn.MouseButton1Click:Connect(function()
                compIO.delete(compName)
                dlog("Deleted comp: " .. compName)
                refreshCompList()
            end)
        end
    end

    refreshCompList()

    -- ── EXPORT / IMPORT ───────────────────────────────────────────────
    section("Export / Import", 22)

    local exportBtn = makeBtn(scroll, "EXPORT COMP", 23)
    local exportBox = makeInput(scroll, "Export string will appear here...", 24)
    exportBox.TextEditable = false

    exportBtn.MouseButton1Click:Connect(function()
        local str = compIO.export(currentComp)
        if str then
            exportBox.Text = str
            dlog("Comp exported! Copy the text below.")
        else
            dlog("ERROR: Failed to export comp!")
        end
    end)

    local importBox = makeInput(scroll, "Paste import string here...", 25)

    local importBtn = makeBtn(scroll, "IMPORT COMP", 26)
    importBtn.MouseButton1Click:Connect(function()
        local imported = compIO.import(importBox.Text)
        if imported then
            currentComp = imported
            rebuildFromComp(imported)
            dlog("Imported comp: " .. imported.name)
            refreshCompList()
        else
            dlog("ERROR: Invalid import string!")
        end
    end)

    -- ── RUN ───────────────────────────────────────────────────────────
    section("Run", 27)

    local runBtn = makeBtn(scroll, "▶ RUN HIVE ADJUSTER", 28)
    runBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
    runBtn.TextColor3 = Color3.fromRGB(100, 255, 100)
    runBtn.Size = UDim2.new(1, 0, 0, 36)

    return runBtn, function() return currentComp end
end

return buildCompBuilderTab