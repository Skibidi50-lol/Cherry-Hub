local UILibrary = {}

-- Сервисы
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

-- Настройки анимации
local AnimationSpeed = 0.3
local EasingStyle = Enum.EasingStyle.Quart
local EasingDirection = Enum.EasingDirection.Out

-- Функция создания твина
local function Tween(object, properties, duration)
    local tweenInfo = TweenInfo.new(duration or AnimationSpeed, EasingStyle, EasingDirection)
    local tween = TweenService:Create(object, tweenInfo, properties)
    tween:Play()
    return tween
end

-- Функция создания скруглённых углов
local function AddCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = parent
    return corner
end

-- Функция создания тени
local function AddShadow(parent)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.Position = UDim2.new(0.5, 0, 0.5, 3)
    shadow.Size = UDim2.new(1, 20, 1, 20)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.7
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(10, 10, 118, 118)
    shadow.ZIndex = parent.ZIndex - 1
    shadow.Parent = parent
    return shadow
end

-- Создание главного окна
function UILibrary:CreateWindow(config)
    config = config or {}
    local windowName = config.Name or "UI Library"
    local windowSize = config.Size or UDim2.new(0, 420, 0, 480)
    
    -- ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CustomUI"
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = CoreGui
    
    -- Main Frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    mainFrame.Size = windowSize
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui
    AddCorner(mainFrame, 12)
    
    -- Топ бар
    local topBar = Instance.new("Frame")
    topBar.Name = "TopBar"
    topBar.Size = UDim2.new(1, 0, 0, 40)
    topBar.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    topBar.BorderSizePixel = 0
    topBar.Parent = mainFrame
    AddCorner(topBar, 12)
    
    -- Заголовок
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Position = UDim2.new(0, 15, 0, 0)
    title.Size = UDim2.new(1, -80, 1, 0)
    title.BackgroundTransparency = 1
    title.Text = windowName
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = topBar
    
    -- Кнопка закрытия
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.AnchorPoint = Vector2.new(1, 0.5)
    closeBtn.Position = UDim2.new(1, -10, 0.5, 0)
    closeBtn.Size = UDim2.new(0, 28, 0, 28)
    closeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    closeBtn.TextSize = 18
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = topBar
    AddCorner(closeBtn, 6)
    
    closeBtn.MouseButton1Click:Connect(function()
        Tween(mainFrame, {Size = UDim2.new(0, 0, 0, 0)}, 0.3)
        wait(0.3)
        screenGui:Destroy()
    end)
    
    closeBtn.MouseEnter:Connect(function()
        Tween(closeBtn, {BackgroundColor3 = Color3.fromRGB(200, 50, 50)})
    end)
    
    closeBtn.MouseLeave:Connect(function()
        Tween(closeBtn, {BackgroundColor3 = Color3.fromRGB(30, 30, 35)})
    end)
    
    -- Контейнер для вкладок
    local tabContainer = Instance.new("Frame")
    tabContainer.Name = "TabContainer"
    tabContainer.Position = UDim2.new(0, 10, 0, 50)
    tabContainer.Size = UDim2.new(0, 120, 1, -60)
    tabContainer.BackgroundTransparency = 1
    tabContainer.Parent = mainFrame
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 6)
    tabLayout.Parent = tabContainer
    
    -- Контейнер для содержимого
    local contentContainer = Instance.new("Frame")
    contentContainer.Name = "ContentContainer"
    contentContainer.Position = UDim2.new(0, 140, 0, 50)
    contentContainer.Size = UDim2.new(1, -150, 1, -60)
    contentContainer.BackgroundTransparency = 1
    contentContainer.ClipsDescendants = true
    contentContainer.Parent = mainFrame
    
    -- Драг система
    local dragging, dragInput, dragStart, startPos
    
    topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    topBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

      local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "UIToggleButton"
    toggleButton.AnchorPoint = Vector2.new(1, 1)
    toggleButton.Position = UDim2.new(1, -15, 1, -15)
    toggleButton.Size = UDim2.new(0, 110, 0, 40)
    toggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    toggleButton.Text = "🧩 Hide UI"
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.TextSize = 14
    toggleButton.Font = Enum.Font.GothamBold
    toggleButton.Parent = screenGui
    AddCorner(toggleButton, 10)

    -- Hover animation
    toggleButton.MouseEnter:Connect(function()
        Tween(toggleButton, {BackgroundColor3 = Color3.fromRGB(60, 60, 200)}, 0.2)
    end)
    toggleButton.MouseLeave:Connect(function()
        Tween(toggleButton, {BackgroundColor3 = Color3.fromRGB(40, 40, 45)}, 0.2)
    end)

    -- Show/Hide main UI
    local uiVisible = true
    toggleButton.MouseButton1Click:Connect(function()
        uiVisible = not uiVisible
        mainFrame.Visible = uiVisible
        toggleButton.Text = uiVisible and "🧩 Hide UI" or "🧩 Show UI"
        Tween(toggleButton, {BackgroundColor3 = uiVisible and Color3.fromRGB(60, 60, 200) or Color3.fromRGB(40, 40, 45)}, 0.2)
    end)

    -- Make toggle draggable
    local draggingToggle = false
    local dragInputToggle, dragStartToggle, startPosToggle

    toggleButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingToggle = true
            dragStartToggle = input.Position
            startPosToggle = toggleButton.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    draggingToggle = false
                end
            end)
        end
    end)

    toggleButton.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInputToggle = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInputToggle and draggingToggle then
            local delta = input.Position - dragStartToggle
            toggleButton.Position = UDim2.new(
                startPosToggle.X.Scale,
                startPosToggle.X.Offset + delta.X,
                startPosToggle.Y.Scale,
                startPosToggle.Y.Offset + delta.Y
            )
        end
    end)
    
    -- Анимация появления
    mainFrame.Size = UDim2.new(0, 0, 0, 0)
    Tween(mainFrame, {Size = windowSize}, 0.4)
    
    local Window = {}
    Window.Tabs = {}
    Window.CurrentTab = nil
    
    -- Создание вкладки
    function Window:CreateTab(tabName)
        local Tab = {}
        
        -- Кнопка вкладки
        local tabButton = Instance.new("TextButton")
        tabButton.Name = tabName
        tabButton.Size = UDim2.new(1, 0, 0, 35)
        tabButton.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
        tabButton.BorderSizePixel = 0
        tabButton.Text = tabName
        tabButton.TextColor3 = Color3.fromRGB(150, 150, 150)
        tabButton.TextSize = 14
        tabButton.Font = Enum.Font.Gotham
        tabButton.Parent = tabContainer
        AddCorner(tabButton, 6)
        
        -- Содержимое вкладки
        local tabContent = Instance.new("ScrollingFrame")
        tabContent.Name = tabName .. "Content"
        tabContent.Size = UDim2.new(1, 0, 1, 0)
        tabContent.BackgroundTransparency = 1
        tabContent.BorderSizePixel = 0
        tabContent.ScrollBarThickness = 4
        tabContent.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 90)
        tabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
        tabContent.Visible = false
        tabContent.Parent = contentContainer
        
        local contentLayout = Instance.new("UIListLayout")
        contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
        contentLayout.Padding = UDim.new(0, 8)
        contentLayout.Parent = tabContent
        
        contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            tabContent.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 10)
        end)
        
        -- Логика переключения вкладок
        tabButton.MouseButton1Click:Connect(function()
            if Window.CurrentTab then
                local oldButton = tabContainer:FindFirstChild(Window.CurrentTab)
                local oldContent = contentContainer:FindFirstChild(Window.CurrentTab .. "Content")
                if oldButton then
                    Tween(oldButton, {BackgroundColor3 = Color3.fromRGB(25, 25, 30), TextColor3 = Color3.fromRGB(150, 150, 150)})
                end
                if oldContent then
                    oldContent.Visible = false
                end
            end
            
            Tween(tabButton, {BackgroundColor3 = Color3.fromRGB(60, 60, 200), TextColor3 = Color3.fromRGB(255, 255, 255)})
            tabContent.Visible = true
            Window.CurrentTab = tabName
        end)
        
        tabButton.MouseEnter:Connect(function()
            if Window.CurrentTab ~= tabName then
                Tween(tabButton, {BackgroundColor3 = Color3.fromRGB(35, 35, 40)})
            end
        end)
        
        tabButton.MouseLeave:Connect(function()
            if Window.CurrentTab ~= tabName then
                Tween(tabButton, {BackgroundColor3 = Color3.fromRGB(25, 25, 30)})
            end
        end)
        
        -- Активировать первую вкладку
        if not Window.CurrentTab then
            tabButton.BackgroundColor3 = Color3.fromRGB(60, 60, 200)
            tabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            tabContent.Visible = true
            Window.CurrentTab = tabName
        end
        
        -- Кнопка
        function Tab:CreateButton(config)
            config = config or {}
            local buttonName = config.Name or "Button"
            local callback = config.Callback or function() end
            
            local button = Instance.new("TextButton")
            button.Size = UDim2.new(1, -10, 0, 35)
            button.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
            button.BorderSizePixel = 0
            button.Text = buttonName
            button.TextColor3 = Color3.fromRGB(220, 220, 220)
            button.TextSize = 14
            button.Font = Enum.Font.Gotham
            button.Parent = tabContent
            AddCorner(button, 6)
            
            button.MouseButton1Click:Connect(function()
                Tween(button, {BackgroundColor3 = Color3.fromRGB(60, 60, 200)}, 0.1)
                wait(0.1)
                Tween(button, {BackgroundColor3 = Color3.fromRGB(40, 40, 45)}, 0.1)
                callback()
            end)
            
            button.MouseEnter:Connect(function()
                Tween(button, {BackgroundColor3 = Color3.fromRGB(40, 40, 45)})
            end)
            
            button.MouseLeave:Connect(function()
                Tween(button, {BackgroundColor3 = Color3.fromRGB(30, 30, 35)})
            end)
            
            return button
        end
        
        -- Toggle (переключатель)
        function Tab:CreateToggle(config)
            config = config or {}
            local toggleName = config.Name or "Toggle"
            local default = config.Default or false
            local callback = config.Callback or function() end
            
            local toggleFrame = Instance.new("Frame")
            toggleFrame.Size = UDim2.new(1, -10, 0, 35)
            toggleFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
            toggleFrame.BorderSizePixel = 0
            toggleFrame.Parent = tabContent
            AddCorner(toggleFrame, 6)
            
            local toggleLabel = Instance.new("TextLabel")
            toggleLabel.Position = UDim2.new(0, 12, 0, 0)
            toggleLabel.Size = UDim2.new(1, -60, 1, 0)
            toggleLabel.BackgroundTransparency = 1
            toggleLabel.Text = toggleName
            toggleLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
            toggleLabel.TextSize = 14
            toggleLabel.Font = Enum.Font.Gotham
            toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
            toggleLabel.Parent = toggleFrame
            
            local toggleButton = Instance.new("TextButton")
            toggleButton.AnchorPoint = Vector2.new(1, 0.5)
            toggleButton.Position = UDim2.new(1, -10, 0.5, 0)
            toggleButton.Size = UDim2.new(0, 40, 0, 20)
            toggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            toggleButton.BorderSizePixel = 0
            toggleButton.Text = ""
            toggleButton.Parent = toggleFrame
            AddCorner(toggleButton, 10)
            
            local toggleCircle = Instance.new("Frame")
            toggleCircle.Position = UDim2.new(0, 2, 0.5, 0)
            toggleCircle.AnchorPoint = Vector2.new(0, 0.5)
            toggleCircle.Size = UDim2.new(0, 16, 0, 16)
            toggleCircle.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
            toggleCircle.BorderSizePixel = 0
            toggleCircle.Parent = toggleButton
            AddCorner(toggleCircle, 8)
            
            local toggled = default
            
            local function updateToggle()
                if toggled then
                    Tween(toggleButton, {BackgroundColor3 = Color3.fromRGB(60, 60, 200)})
                    Tween(toggleCircle, {Position = UDim2.new(1, -18, 0.5, 0), BackgroundColor3 = Color3.fromRGB(255, 255, 255)})
                else
                    Tween(toggleButton, {BackgroundColor3 = Color3.fromRGB(40, 40, 45)})
                    Tween(toggleCircle, {Position = UDim2.new(0, 2, 0.5, 0), BackgroundColor3 = Color3.fromRGB(200, 200, 200)})
                end
                callback(toggled)
            end
            
            toggleButton.MouseButton1Click:Connect(function()
                toggled = not toggled
                updateToggle()
            end)
            
            updateToggle()
            
            return {
                Set = function(value)
                    toggled = value
                    updateToggle()
                end
            }
        end
        
        -- Slider (ползунок)
        function Tab:CreateSlider(config)
            config = config or {}
            local sliderName = config.Name or "Slider"
            local min = config.Min or 0
            local max = config.Max or 100
            local default = config.Default or 50
            local callback = config.Callback or function() end
            
            local sliderFrame = Instance.new("Frame")
            sliderFrame.Size = UDim2.new(1, -10, 0, 50)
            sliderFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
            sliderFrame.BorderSizePixel = 0
            sliderFrame.Parent = tabContent
            AddCorner(sliderFrame, 6)
            
            local sliderLabel = Instance.new("TextLabel")
            sliderLabel.Position = UDim2.new(0, 12, 0, 5)
            sliderLabel.Size = UDim2.new(1, -24, 0, 18)
            sliderLabel.BackgroundTransparency = 1
            sliderLabel.Text = sliderName
            sliderLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
            sliderLabel.TextSize = 14
            sliderLabel.Font = Enum.Font.Gotham
            sliderLabel.TextXAlignment = Enum.TextXAlignment.Left
            sliderLabel.Parent = sliderFrame
            
            local valueLabel = Instance.new("TextLabel")
            valueLabel.Position = UDim2.new(1, -12, 0, 5)
            valueLabel.Size = UDim2.new(0, 50, 0, 18)
            valueLabel.AnchorPoint = Vector2.new(1, 0)
            valueLabel.BackgroundTransparency = 1
            valueLabel.Text = tostring(default)
            valueLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
            valueLabel.TextSize = 13
            valueLabel.Font = Enum.Font.Gotham
            valueLabel.TextXAlignment = Enum.TextXAlignment.Right
            valueLabel.Parent = sliderFrame
            
            local sliderBack = Instance.new("Frame")
            sliderBack.Position = UDim2.new(0, 12, 1, -18)
            sliderBack.Size = UDim2.new(1, -24, 0, 6)
            sliderBack.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            sliderBack.BorderSizePixel = 0
            sliderBack.Parent = sliderFrame
            AddCorner(sliderBack, 3)
            
            local sliderFill = Instance.new("Frame")
            sliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
            sliderFill.BackgroundColor3 = Color3.fromRGB(60, 60, 200)
            sliderFill.BorderSizePixel = 0
            sliderFill.Parent = sliderBack
            AddCorner(sliderFill, 3)
            
            local sliderButton = Instance.new("TextButton")
            sliderButton.AnchorPoint = Vector2.new(0.5, 0.5)
            sliderButton.Position = UDim2.new((default - min) / (max - min), 0, 0.5, 0)
            sliderButton.Size = UDim2.new(0, 14, 0, 14)
            sliderButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            sliderButton.BorderSizePixel = 0
            sliderButton.Text = ""
            sliderButton.Parent = sliderBack
            AddCorner(sliderButton, 7)
            
            local dragging = false
            
            local function updateSlider(input)
                local pos = math.clamp((input.Position.X - sliderBack.AbsolutePosition.X) / sliderBack.AbsoluteSize.X, 0, 1)
                local value = math.floor(min + (max - min) * pos)
                
                Tween(sliderFill, {Size = UDim2.new(pos, 0, 1, 0)}, 0.1)
                Tween(sliderButton, {Position = UDim2.new(pos, 0, 0.5, 0)}, 0.1)
                valueLabel.Text = tostring(value)
                callback(value)
            end
            
            sliderButton.MouseButton1Down:Connect(function()
                dragging = true
                Tween(sliderButton, {Size = UDim2.new(0, 16, 0, 16)}, 0.1)
            end)
            
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                    Tween(sliderButton, {Size = UDim2.new(0, 14, 0, 14)}, 0.1)
                end
            end)
            
            UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    updateSlider(input)
                end
            end)
            
            return {
                Set = function(value)
                    local pos = (value - min) / (max - min)
                    Tween(sliderFill, {Size = UDim2.new(pos, 0, 1, 0)})
                    Tween(sliderButton, {Position = UDim2.new(pos, 0, 0.5, 0)})
                    valueLabel.Text = tostring(value)
                end
            }
        end
        
        -- Dropdown (выпадающий список)
        function Tab:CreateDropdown(config)
            config = config or {}
            local dropdownName = config.Name or "Dropdown"
            local options = config.Options or {"Option 1", "Option 2"}
            local default = config.Default or options[1]
            local callback = config.Callback or function() end
            
            local dropdownFrame = Instance.new("Frame")
            dropdownFrame.Size = UDim2.new(1, -10, 0, 35)
            dropdownFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
            dropdownFrame.BorderSizePixel = 0
            dropdownFrame.ClipsDescendants = false
            dropdownFrame.Parent = tabContent
            AddCorner(dropdownFrame, 6)
            
            local dropdownLabel = Instance.new("TextLabel")
            dropdownLabel.Position = UDim2.new(0, 12, 0, 0)
            dropdownLabel.Size = UDim2.new(1, -90, 1, 0)
            dropdownLabel.BackgroundTransparency = 1
            dropdownLabel.Text = dropdownName
            dropdownLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
            dropdownLabel.TextSize = 14
            dropdownLabel.Font = Enum.Font.Gotham
            dropdownLabel.TextXAlignment = Enum.TextXAlignment.Left
            dropdownLabel.Parent = dropdownFrame
            
            local selectedLabel = Instance.new("TextLabel")
            selectedLabel.AnchorPoint = Vector2.new(1, 0.5)
            selectedLabel.Position = UDim2.new(1, -30, 0.5, 0)
            selectedLabel.Size = UDim2.new(0, 60, 0, 20)
            selectedLabel.BackgroundTransparency = 1
            selectedLabel.Text = default
            selectedLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
            selectedLabel.TextSize = 13
            selectedLabel.Font = Enum.Font.Gotham
            selectedLabel.TextXAlignment = Enum.TextXAlignment.Right
            selectedLabel.Parent = dropdownFrame
            
            local arrow = Instance.new("TextLabel")
            arrow.AnchorPoint = Vector2.new(1, 0.5)
            arrow.Position = UDim2.new(1, -10, 0.5, 0)
            arrow.Size = UDim2.new(0, 15, 0, 15)
            arrow.BackgroundTransparency = 1
            arrow.Text = "▼"
            arrow.TextColor3 = Color3.fromRGB(150, 150, 150)
            arrow.TextSize = 10
            arrow.Font = Enum.Font.Gotham
            arrow.Parent = dropdownFrame
            
            local dropdownList = Instance.new("Frame")
            dropdownList.Position = UDim2.new(0, 0, 1, 5)
            dropdownList.Size = UDim2.new(1, 0, 0, 0)
            dropdownList.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
            dropdownList.BorderSizePixel = 0
            dropdownList.ClipsDescendants = true
            dropdownList.Visible = false
            dropdownList.ZIndex = 10
            dropdownList.Parent = dropdownFrame
            AddCorner(dropdownList, 6)
            
            local listLayout = Instance.new("UIListLayout")
            listLayout.SortOrder = Enum.SortOrder.LayoutOrder
            listLayout.Parent = dropdownList
            
            local opened = false
            
            local dropdownButton = Instance.new("TextButton")
            dropdownButton.Size = UDim2.new(1, 0, 1, 0)
            dropdownButton.BackgroundTransparency = 1
            dropdownButton.Text = ""
            dropdownButton.Parent = dropdownFrame
            
            dropdownButton.MouseButton1Click:Connect(function()
                opened = not opened
                if opened then
                    dropdownList.Visible = true
                    local targetHeight = #options * 30
                    Tween(dropdownList, {Size = UDim2.new(1, 0, 0, targetHeight)}, 0.2)
                    Tween(arrow, {Rotation = 180}, 0.2)
                else
                    Tween(dropdownList, {Size = UDim2.new(1, 0, 0, 0)}, 0.2)
                    Tween(arrow, {Rotation = 0}, 0.2)
                    wait(0.2)
                    dropdownList.Visible = false
                end
            end)
            
            for _, option in ipairs(options) do
                local optionButton = Instance.new("TextButton")
                optionButton.Size = UDim2.new(1, 0, 0, 30)
                optionButton.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
                optionButton.BorderSizePixel = 0
                optionButton.Text = option
                optionButton.TextColor3 = Color3.fromRGB(200, 200, 200)
                optionButton.TextSize = 13
                optionButton.Font = Enum.Font.Gotham
                optionButton.Parent = dropdownList
                
                optionButton.MouseButton1Click:Connect(function()
                    selectedLabel.Text = option
                    opened = false
                    Tween(dropdownList, {Size = UDim2.new(1, 0, 0, 0)}, 0.2)
                    Tween(arrow, {Rotation = 0}, 0.2)
                    wait(0.2)
                    dropdownList.Visible = false
                    callback(option)
                end)
                
                optionButton.MouseEnter:Connect(function()
                    Tween(optionButton, {BackgroundColor3 = Color3.fromRGB(35, 35, 40)})
                end)
                
                optionButton.MouseLeave:Connect(function()
                    Tween(optionButton, {BackgroundColor3 = Color3.fromRGB(25, 25, 30)})
                end)
            end
            
            return dropdownFrame
        end
        
        -- Textbox (поле ввода)
        function Tab:CreateTextbox(config)
            config = config or {}
            local textboxName = config.Name or "Textbox"
            local placeholder = config.Placeholder or "Enter text..."
            local callback = config.Callback or function() end
            
            local textboxFrame = Instance.new("Frame")
            textboxFrame.Size = UDim2.new(1, -10, 0, 60)
            textboxFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
            textboxFrame.BorderSizePixel = 0
            textboxFrame.Parent = tabContent
            AddCorner(textboxFrame, 6)
            
            local textboxLabel = Instance.new("TextLabel")
            textboxLabel.Position = UDim2.new(0, 12, 0, 5)
            textboxLabel.Size = UDim2.new(1, -24, 0, 18)
            textboxLabel.BackgroundTransparency = 1
            textboxLabel.Text = textboxName
            textboxLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
            textboxLabel.TextSize = 14
            textboxLabel.Font = Enum.Font.Gotham
            textboxLabel.TextXAlignment = Enum.TextXAlignment.Left
            textboxLabel.Parent = textboxFrame
            
            local textbox = Instance.new("TextBox")
            textbox.Position = UDim2.new(0, 12, 0, 28)
            textbox.Size = UDim2.new(1, -24, 0, 25)
            textbox.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            textbox.BorderSizePixel = 0
            textbox.Text = ""
            textbox.PlaceholderText = placeholder
            textbox.TextColor3 = Color3.fromRGB(220, 220, 220)
            textbox.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
            textbox.TextSize = 13
            textbox.Font = Enum.Font.Gotham
            textbox.TextXAlignment = Enum.TextXAlignment.Left
            textbox.ClearTextOnFocus = false
            textbox.Parent = textboxFrame
            AddCorner(textbox, 5)
            
            local padding = Instance.new("UIPadding")
            padding.PaddingLeft = UDim.new(0, 8)
            padding.PaddingRight = UDim.new(0, 8)
            padding.Parent = textbox
            
            textbox.Focused:Connect(function()
                Tween(textbox, {BackgroundColor3 = Color3.fromRGB(50, 50, 60)})
            end)
            
            textbox.FocusLost:Connect(function(enterPressed)
                Tween(textbox, {BackgroundColor3 = Color3.fromRGB(40, 40, 45)})
                if enterPressed then
                    callback(textbox.Text)
                end
            end)
            
            return {
                Set = function(text)
                    textbox.Text = text
                end,
                Get = function()
                    return textbox.Text
                end
            }
        end
        
        -- Label (текстовая метка)
        function Tab:CreateLabel(text)
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -10, 0, 30)
            label.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
            label.BorderSizePixel = 0
            label.Text = text or "Label"
            label.TextColor3 = Color3.fromRGB(200, 200, 200)
            label.TextSize = 14
            label.Font = Enum.Font.Gotham
            label.TextWrapped = true
            label.Parent = tabContent
            AddCorner(label, 6)
            
            local padding = Instance.new("UIPadding")
            padding.PaddingLeft = UDim.new(0, 12)
            padding.PaddingRight = UDim.new(0, 12)
            padding.Parent = label
            
            return {
                Set = function(newText)
                    label.Text = newText
                end
            }
        end
        
        -- Separator (разделитель)
        function Tab:CreateSeparator()
            local separator = Instance.new("Frame")
            separator.Size = UDim2.new(1, -10, 0, 2)
            separator.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            separator.BorderSizePixel = 0
            separator.Parent = tabContent
            AddCorner(separator, 1)
            
            return separator
        end
        
        table.insert(Window.Tabs, Tab)
        return Tab
    end
    
    return Window
end

return UILibrary
