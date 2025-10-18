-- NeonDark UI Library | Modern Dark Theme
-- Place in ReplicatedStorage as "NeonDark"

local NeonDark = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Theme Colors (Fresh Dark Aesthetic)
local Theme = {
    Primary = Color3.fromRGB(25, 25, 35),      -- Deep Navy
    Secondary = Color3.fromRGB(35, 35, 45),    -- Dark Gray
    Accent = Color3.fromRGB(100, 150, 255),    -- Neon Blue
    AccentHover = Color3.fromRGB(120, 170, 255),
    Success = Color3.fromRGB(100, 200, 150),
    Danger = Color3.fromRGB(255, 100, 100),
    Warning = Color3.fromRGB(255, 200, 100),
    TextPrimary = Color3.fromRGB(255, 255, 255),
    TextSecondary = Color3.fromRGB(200, 200, 210),
    TextMuted = Color3.fromRGB(150, 150, 160),
    Border = Color3.fromRGB(60, 60, 70),
    Shadow = Color3.fromRGB(0, 0, 0)
}

-- Animation Settings
local Anim = {
    Duration = 0.2,
    EaseInOut = Enum.EasingStyle.Quart,
    EaseBack = Enum.EasingStyle.Back
}

-- Create ScreenGui
function NeonDark:CreateGui()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "NeonDarkUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    return screenGui
end

-- Create Main Frame
function NeonDark:Frame(parent, size, pos, name)
    local frame = Instance.new("Frame")
    frame.Name = name or "Frame"
    frame.Size = size or UDim2.new(1, 0, 1, 0)
    frame.Position = pos or UDim2.new(0, 0, 0, 0)
    frame.BackgroundColor3 = Theme.Primary
    frame.BorderSizePixel = 0
    frame.Parent = parent
    
    -- Corner
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame
    
    -- Stroke
    local stroke = Instance.new("UIStroke")
    stroke.Color = Theme.Border
    stroke.Thickness = 1
    stroke.Parent = frame
    
    -- Shadow (UIStroke)
    local shadow = Instance.new("UIStroke")
    shadow.Color = Theme.Shadow
    shadow.Thickness = 8
    shadow.Transparency = 0.8
    shadow.Parent = frame
    
    return frame
end

-- Create Button
function NeonDark:Button(parent, text, size, pos, callback)
    local button = self:Frame(parent, size, pos, "Button")
    button.BackgroundColor3 = Theme.Secondary
    
    local corner = button:FindFirstChild("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    
    local stroke = button:FindFirstChild("UIStroke")
    stroke.Color = Theme.Accent
    stroke.Thickness = 2
    
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Theme.TextPrimary
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = button
    
    -- Hover Effects
    local hoverTween = TweenService:Create(button, {Time = Anim.Duration}, {
        BackgroundColor3 = Theme.Accent,
        Size = UDim2.new(size.X.Scale, size.X.Offset + 4, size.Y.Scale, size.Y.Offset + 4)
    }, Anim.EaseInOut)
    
    local normalTween = TweenService:Create(button, {Time = Anim.Duration}, {
        BackgroundColor3 = Theme.Secondary,
        Size = size
    }, Anim.EaseInOut)
    
    button.MouseEnter:Connect(function()
        hoverTween:Play()
        stroke.Color = Theme.AccentHover
    end)
    
    button.MouseLeave:Connect(function()
        normalTween:Play()
        stroke.Color = Theme.Accent
    end)
    
    button.MouseButton1Click:Connect(callback or function() end)
    
    return button
end

-- Create Toggle Button
function NeonDark:Toggle(parent, text, size, pos, callback)
    local container = self:Frame(parent, size, pos, "Toggle")
    container.BackgroundTransparency = 1
    
    local toggle = self:Frame(container, UDim2.new(0, 60, 0, 30), UDim2.new(1, -70, 0.5, -15))
    local isOn = false
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -70, 1, 0)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Theme.TextPrimary
    label.TextScaled = true
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    -- Toggle Animation
    local onTween = TweenService:Create(toggle, {Time = 0.2}, {
        BackgroundColor3 = Theme.Success,
        Position = UDim2.new(1, -70, 0.5, -15)
    }, Anim.EaseBack)
    
    local offTween = TweenService:Create(toggle, {Time = 0.2}, {
        BackgroundColor3 = Theme.Danger,
        Position = UDim2.new(1, -70, 0.5, -15)
    }, Anim.EaseBack)
    
    toggle.MouseButton1Click:Connect(function()
        isOn = not isOn
        if isOn then
            onTween:Play()
        else
            offTween:Play()
        end
        callback(isOn)
    end)
    
    return container
end

-- Create Text Input
function NeonDark:Input(parent, placeholder, size, pos, callback)
    local input = self:Frame(parent, size, pos, "Input")
    input.BackgroundColor3 = Theme.Secondary
    
    local corner = input:FindFirstChild("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    
    local textBox = Instance.new("TextBox")
    textBox.Name = "TextBox"
    textBox.Size = UDim2.new(1, -12, 1, -12)
    textBox.Position = UDim2.new(0, 6, 0, 6)
    textBox.BackgroundTransparency = 1
    textBox.Text = ""
    textBox.PlaceholderText = placeholder
    textBox.PlaceholderColor3 = Theme.TextMuted
    textBox.TextColor3 = Theme.TextPrimary
    textBox.TextScaled = true
    textBox.Font = Enum.Font.Gotham
    textBox.ClearTextOnFocus = false
    textBox.Parent = input
    
    textBox.FocusLost:Connect(function()
        callback(textBox.Text)
    end)
    
    return input
end

-- Create Title
function NeonDark:Title(parent, text, size, pos)
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = size or UDim2.new(1, 0, 0, 50)
    title.Position = pos or UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = text
    title.TextColor3 = Theme.TextPrimary
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.TextSize = 28
    title.Parent = parent
    return title
end

return NeonDark
