local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'
local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local chams = loadstring(game:HttpGet("https://raw.githubusercontent.com/Stratxgy/Roblox-Chams-Highlight/refs/heads/main/Highlight.lua"))()
local ESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/linemaster2/esp-library/main/library.lua"))()
--aimbot shit
local players_service = game:GetService("Players")
local run_service = game:GetService("RunService")
local user_input_service = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = players_service.LocalPlayer

-- Aimbot Variables
local aimbot_enabled = false
local aimbot_fov_size = 50
local aimbot_aim_part = "Head"
local aimbot_smoothness = 5 
local show_fov = false
local aimbot_smoothness_enabled = true
local aimbot_prediction_enabled = false
local aimbot_prediction_strength_x = 0
local aimbot_prediction_strength_y = 0
local aimbot_sticky_aim_enabled = false
local locked_target = nil
local wallCheckEnabled = false
local teamCheckEnabled = false
local aimbot_keybind = Enum.UserInputType.MouseButton2 -- Default Keybind

-- Utility function to convert saved string to Enum
local function string_to_enum(string)
    -- Handles both MouseButton2 (UserInputType) and KeyCode enums
    if string:match("MouseButton") then
        return Enum.UserInputType[string]
    else
        local newstring = string:gsub("Enum.KeyCode.","")
        return Enum.KeyCode[newstring]
    end 
end 

-- Aimbot
local function aimbot()
    if not aimbot_enabled or not aimbot_keybind then
        return
    end

    -- checking for keycode or a mousebutton 
    if aimbot_keybind == Enum.UserInputType.MouseButton2 or aimbot_keybind == Enum.UserInputType.MouseButton1 then
        if not user_input_service:IsMouseButtonPressed(aimbot_keybind) then
            locked_target = nil
            return
        end
    else
        if not user_input_service:IsKeyDown(aimbot_keybind) then
            locked_target = nil
            return
        end
    end

    local camera = workspace.CurrentCamera
    local localCharacter = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

    if locked_target and aimbot_sticky_aim_enabled then
        if locked_target.Character and locked_target.Character:FindFirstChild(aimbot_aim_part) then
            local part = locked_target.Character[aimbot_aim_part]
            local predicted_position = part.Position
            
            if aimbot_prediction_enabled and locked_target.Character:FindFirstChild("HumanoidRootPart") then
                local velocity = locked_target.Character.HumanoidRootPart.Velocity
                predicted_position =
                    part.Position +
                    Vector3.new(
                        velocity.X * aimbot_prediction_strength_x * 0.1,
                        velocity.Y * aimbot_prediction_strength_y * 0.1,
                        0
                    )
            end
            
            local screen_pos = camera:WorldToViewportPoint(predicted_position)
            local target = Vector2.new(screen_pos.X, screen_pos.Y)
            local screen_center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
            local move = target - screen_center

            if aimbot_smoothness_enabled then
                local move_step = move / (aimbot_smoothness + 1)
                pcall(function() mousemoverel(move_step.X, move_step.Y) end)
            else
                pcall(function() mousemoverel(move.X, move.Y) end)
            end
            return
        else
            locked_target = nil
        end
    end

    local closest_player = nil
    local closest_distance = aimbot_fov_size

    for _, player in pairs(players_service:GetPlayers()) do
        if
            player ~= LocalPlayer and player.Character and
            player.Character:FindFirstChild(aimbot_aim_part)
           then
            -- Team Check (Integrated)
            if teamCheckEnabled and player.Team == LocalPlayer.Team then
                continue
            end
            
            local part = player.Character[aimbot_aim_part]
            local predicted_position = part.Position
            
            if aimbot_prediction_enabled and player.Character:FindFirstChild("HumanoidRootPart") then
                local velocity = player.Character.HumanoidRootPart.Velocity
                predicted_position =
                    part.Position +
                    Vector3.new(
                        velocity.X * aimbot_prediction_strength_x * 0.1,
                        velocity.Y * aimbot_prediction_strength_y * 0.1,
                        0
                    )
            end
            
            -- Wall Check (Integrated)
            if wallCheckEnabled and localCharacter then
                local rayDirection = (predicted_position - camera.CFrame.Position).Unit * 1000
                local raycastParams = RaycastParams.new()
                raycastParams.FilterDescendantsInstances = {localCharacter}
                raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

                local raycastResult = workspace:Raycast(camera.CFrame.Position, rayDirection, raycastParams)

                if raycastResult and not raycastResult.Instance:IsDescendantOf(player.Character) then
                    continue
                end
            end
            
            local screen_pos, on_screen = camera:WorldToViewportPoint(predicted_position)
            if on_screen then
                local distance =
                    (Vector2.new(screen_pos.X, screen_pos.Y) -
                    Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)).magnitude
                if distance < closest_distance then
                    closest_distance = distance
                    closest_player = player
                end
            end
        end
    end

    if closest_player then
        locked_target = closest_player
        local part = closest_player.Character[aimbot_aim_part]
        local predicted_position = part.Position
        
        if aimbot_prediction_enabled and closest_player.Character:FindFirstChild("HumanoidRootPart") then
            local velocity = closest_player.Character.HumanoidRootPart.Velocity
            predicted_position =
                part.Position +
                Vector3.new(
                    velocity.X * aimbot_prediction_strength_x * 0.1,
                    velocity.Y * aimbot_prediction_strength_y * 0.1,
                    0
                )
        end
        
        local screen_pos = camera:WorldToViewportPoint(predicted_position)
        local target = Vector2.new(screen_pos.X, screen_pos.Y)
        local screen_center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
        local move = target - screen_center

        if aimbot_smoothness_enabled then
            local move_step = move / (aimbot_smoothness + 1)
            pcall(function() mousemoverel(move_step.X, move_step.Y) end)
        else
            pcall(function() mousemoverel(move.X, move.Y) end)
        end
    end
end

-- FOV Circle Logic (as provided in the prompt)
local fov_circle = nil
pcall(function() 
    fov_circle = Drawing.new("Circle")
    fov_circle.Color = Color3.fromRGB(255, 0, 0)
    fov_circle.Thickness = 1
    fov_circle.Transparency = 1
    fov_circle.Filled = false
end)


local function update_fov_circle()
    if fov_circle and show_fov then
        local screen_center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        fov_circle.Radius = aimbot_fov_size
        fov_circle.Position = screen_center
        fov_circle.Visible = true
    elseif fov_circle then
        fov_circle.Visible = false
    end
end

run_service.RenderStepped:Connect(aimbot)
run_service.RenderStepped:Connect(update_fov_circle)
--hbar

getgenv().hbar = {
    enabled = false,            
    barThickness = 3,         
    greenThickness = 1.5,      
    barColor = Color3.fromRGB(0, 0, 0),
    greenColor = Color3.fromRGB(0, 255, 0), 
    updateInterval = 0.1       
}



local player = game:GetService("Players").LocalPlayer
local camera = game:GetService("Workspace").CurrentCamera
local runService = game:GetService("RunService")


local function NewLine(thickness, color)
    local line = Drawing.new("Line")
    line.Visible = false
    line.From = Vector2.new(0, 0)
    line.To = Vector2.new(0, 0)
    line.Color = color
    line.Thickness = thickness
    line.Transparency = 1
    return line
end


local function UpdateHealthBar(plr)
    local library = {
        healthbar = NewLine(getgenv().hbar.barThickness, getgenv().hbar.barColor),
        greenhealth = NewLine(getgenv().hbar.greenThickness, getgenv().hbar.greenColor)
    }

    
    local function Updater()
        local connection
        connection = runService.RenderStepped:Connect(function()
       
            if plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character.Humanoid.Health > 0 and plr.Character:FindFirstChild("Head") then
                local HumPos, OnScreen = camera:WorldToViewportPoint(plr.Character.HumanoidRootPart.Position)
                if OnScreen then
                    local head = camera:WorldToViewportPoint(plr.Character.Head.Position)
                    local DistanceY = math.clamp((Vector2.new(head.X, head.Y) - Vector2.new(HumPos.X, HumPos.Y)).magnitude, 2, math.huge)

          
                    local d = (Vector2.new(HumPos.X - DistanceY, HumPos.Y - DistanceY*2) - Vector2.new(HumPos.X - DistanceY, HumPos.Y + DistanceY*2)).magnitude 
                    local healthoffset = plr.Character.Humanoid.Health / plr.Character.Humanoid.MaxHealth * d

             
                    library.greenhealth.From = Vector2.new(HumPos.X - DistanceY - 4, HumPos.Y + DistanceY*2)
                    library.greenhealth.To = Vector2.new(HumPos.X - DistanceY - 4, HumPos.Y + DistanceY*2 - healthoffset)

                    library.healthbar.From = Vector2.new(HumPos.X - DistanceY - 4, HumPos.Y + DistanceY*2)
                    library.healthbar.To = Vector2.new(HumPos.X - DistanceY - 4, HumPos.Y - DistanceY*2)


                    local green = getgenv().hbar.greenColor
                    local red = Color3.fromRGB(255, 0, 0)
                    library.greenhealth.Color = red:lerp(green, plr.Character.Humanoid.Health / plr.Character.Humanoid.MaxHealth)

  
                    library.greenhealth.Visible = getgenv().hbar.enabled
                    library.healthbar.Visible = getgenv().hbar.enabled
                else

                    library.greenhealth.Visible = false
                    library.healthbar.Visible = false
                end
            else

                library.greenhealth.Visible = false
                library.healthbar.Visible = false
            end
        end)
    end
    coroutine.wrap(Updater)()
end


for i, v in pairs(game:GetService("Players"):GetPlayers()) do
    if v.Name ~= player.Name then
        UpdateHealthBar(v)
    end
end


game.Players.PlayerAdded:Connect(function(newplr)
    if newplr.Name ~= player.Name then
        UpdateHealthBar(newplr)
    end
end)


game:GetService("RunService").Heartbeat:Connect(function()

    if getgenv().hbar.enabled == false then
 
        for _, v in pairs(game:GetService("Players"):GetPlayers()) do
            if v.Character and v.Character:FindFirstChild("Humanoid") then
                local library = v:FindFirstChild("DrawingHealthBar")
                if library then
                    library.greenhealth.Visible = false
                    library.healthbar.Visible = false
                end
            end
        end
    end
end)
--triggerbot
getgenv().triggerbot = {
    Settings = {
        isEnabled = false,
        clickDelay = 0,
        toggleKey = Enum.KeyCode.T,
        lastClickTime = 0
    },
    load = function()
        local Players = game:GetService("Players")
        local UserInputService = game:GetService("UserInputService")
        local StarterGui = game:GetService("StarterGui")
        local LocalPlayer = Players.LocalPlayer
        local mouse = LocalPlayer:GetMouse()

        -- Function to simulate mouse click
        local function simulateClick()
            mouse1click()
        end

        local function isHoveringPlayer()
            local target = mouse.Target

            if target then
                local character = target:FindFirstAncestorOfClass("Model")
                if character and Players:GetPlayerFromCharacter(character) then
                    return true
                end
            end
            return false
        end

        local function createNotification(message)
            StarterGui:SetCore("SendNotification", {
                Title = "Auto Fire",
                Text = message,
                Duration = 2,
            })
        end

        -- Listen for the toggle key press
        UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if input.KeyCode == getgenv().triggerbot.Settings.toggleKey and not gameProcessed then
                getgenv().triggerbot.Settings.isEnabled = not getgenv().triggerbot.Settings.isEnabled
                local statusMessage = getgenv().triggerbot.Settings.isEnabled and "enabled" or "disabled"
                print("Auto Fire is now " .. statusMessage)
                
                -- Show notification
                createNotification("Auto Fire is now " .. statusMessage)
            end
        end)

        -- Listen to mouse movement
        mouse.Move:Connect(function()
            if getgenv().triggerbot.Settings.isEnabled and isHoveringPlayer() then
                local currentTime = tick()
                if currentTime - getgenv().triggerbot.Settings.lastClickTime >= getgenv().triggerbot.Settings.clickDelay then
                    simulateClick()
                    getgenv().triggerbot.Settings.lastClickTime = currentTime
                end
            end
        end)
    end
}
--Anti Aim
getgenv().aaimweld = {
    enabled = false,          
    keybind = Enum.KeyCode.P,  
    toggle = false,            
    spinspeed = 500,           
    offset = false,            
    persist = true,        
}

local player = game.Players.LocalPlayer
local runService = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")


local isSpinning = false
local togglePressed = false
local active = false
local spinWeld


local function setupCharacter(character)
    if not active then return end 

    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    local torso = character:FindFirstChild("UpperTorso") or character:WaitForChild("Torso")


    spinWeld = Instance.new("Weld")
    spinWeld.Part0 = humanoidRootPart
    spinWeld.Part1 = torso


    if getgenv().aaimweld.offset then
        spinWeld.C0 = CFrame.new(0, 1, 0) 
    else
        spinWeld.C0 = CFrame.new()
    end

    spinWeld.Parent = humanoidRootPart
end


local function updateOffset()
    if spinWeld then
        if getgenv().aaimweld.offset then
            spinWeld.C0 = CFrame.new(0, 1, 0)
        else
            spinWeld.C0 = CFrame.new()
        end
    end
end


local function spinCharacter(deltaTime)
    if spinWeld then
        local rotationSpeed = getgenv().aaimweld.spinspeed
        local rotationAngle = math.rad(rotationSpeed * deltaTime)
        spinWeld.C0 = spinWeld.C0 * CFrame.Angles(0, rotationAngle, 0)
    end
end


local function handleKeybindInput()
    userInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or not active then return end
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == getgenv().aaimweld.keybind then
            if getgenv().aaimweld.toggle then
                togglePressed = not togglePressed
                isSpinning = togglePressed
            else
                isSpinning = true
            end
        end
    end)

    userInputService.InputEnded:Connect(function(input)
        if not active then return end
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == getgenv().aaimweld.keybind and not getgenv().aaimweld.toggle then
            isSpinning = false
        end
    end)
end


runService.RenderStepped:Connect(function(deltaTime)
    if active and isSpinning then
        spinCharacter(deltaTime)
    end
end)


task.spawn(function()
    while true do
        if getgenv().aaimweld.enabled and not active then
            active = true
            if player.Character then
                setupCharacter(player.Character)
            end
        elseif not getgenv().aaimweld.enabled and active then
            active = false
            isSpinning = false 
            spinWeld = nil 
        end
        task.wait(0.5)
    end
end)


task.spawn(function()
    local lastOffset = getgenv().aaimweld.offset
    while true do
        if getgenv().aaimweld.offset ~= lastOffset then
            lastOffset = getgenv().aaimweld.offset
            updateOffset()
        end
        task.wait(0.5)
    end
end)


player.CharacterAdded:Connect(function(character)
    if getgenv().aaimweld.persist and active then
        setupCharacter(character)
    end
end)


if player.Character and getgenv().aaimweld.enabled then
    setupCharacter(player.Character)
end


handleKeybindInput()
--main
local Window = Library:CreateWindow({
    Title = 'Cherry.lua',
    Center = true, -- Set Center to true if you want the menu to appear in the center
    AutoShow = true, -- Set AutoShow to true if you want the menu to appear when it is created
    TabPadding = 8,
    MenuFadeTime = 0.2
})
--Tabs
local Tabs = {
    Aimbot = Window:AddTab('Aimbot'),
    Visual = Window:AddTab('Visual'),
    Misc = Window:AddTab('Misc'),
    ['UI Settings'] = Window:AddTab('UI Settings'),
}

local aimbotBox = Tabs.Aimbot:AddLeftGroupbox('Aimbot')
aimbotBox:AddToggle('AimbotToggle', {
    Text = 'Aimbot',
    Default = false, -- Default value (true / false)
    Tooltip = 'locking into players head', -- Information shown when you hover over the toggle
    Callback = function(Value)
        aimbot_enabled = Value
    end
})

aimbotBox:AddToggle('WallToggle', {
    Text = 'Wall Check',
    Default = false, -- Default value (true / false)
    Tooltip = 'Checking if the player is not in the wall', -- Information shown when you hover over the toggle
    Callback = function(Value)
        wallCheckEnabled = Value
    end
})

aimbotBox:AddToggle('TeamToggle', {
    Text = 'Team Check',
    Default = false, -- Default value (true / false)
    Tooltip = 'Checking if the player is in your team', -- Information shown when you hover over the toggle
    Callback = function(Value)
        teamCheckEnabled = Value
    end
})

aimbotBox:AddToggle('FovAimbotToggle', {
    Text = 'FOV Circle',
    Default = false, -- Default value (true / false)
    Tooltip = 'Create a fov circle to your aimbot', -- Information shown when you hover over the toggle
    Callback = function(Value)
        show_fov = Value
    end
})

aimbotBox:AddSlider('FovSlider', {
    Text = 'FOV Circle Size',
    Default = 50,
    Min = 50,
    Max = 500,
    Rounding = 0,
    Compact = false,

    Callback = function(Value)
        aimbot_fov_size = Value
    end
})

aimbotBox:AddToggle('SmoothToggle', {
    Text = 'Smoothness',
    Default = false, -- Default value (true / false)
    Tooltip = 'Speed how the aimbot should locking', -- Information shown when you hover over the toggle
    Callback = function(Value)
        aimbot_smoothness_enabled = Value
    end
})

aimbotBox:AddSlider('SmoothnesSlider', {
    Text = 'Adjust Smoothness',
    Default = 5,
    Min = 1,
    Max = 10,
    Rounding = 0,
    Compact = false,

    Callback = function(Value)
        aimbot_smoothness = Value
    end
})

aimbotBox:AddToggle('StickyToggle', {
    Text = 'Sticky Aim',
    Default = false, -- Default value (true / false)
    Tooltip = 'IDK', -- Information shown when you hover over the toggle
    Callback = function(Value)
        aimbot_sticky_aim_enabled = Value
    end
})

aimbotBox:AddLabel('Aimbot Keybind'):AddKeyPicker('KeyPicker', {
    Default = 'MB2', -- String as the name of the keybind (MB1, MB2 for mouse buttons)
    SyncToggleState = false,
    Mode = 'Hold',

    Text = 'Keybind to Enable the aimbot',
    NoUI = false,
    Callback = function(Value)
        aimbot_keybind = Value
    end,
})

aimbotBox:AddDropdown('TargetAimbotDropdown', {
    Values = { 'Head', 'HumanoidRootPart'},
    Default = 1, -- number index of the value / string
    Multi = false, -- true / false, allows multiple choices to be selected

    Text = 'Aimbot Part',
    Tooltip = 'Chaneg the Aimbot Part to lock in', -- Information shown when you hover over the dropdown

    Callback = function(Value)
        aimbot_aim_part = Value
    end
})

local triggerBox = Tabs.Aimbot:AddLeftGroupbox('Auto Fire')

triggerBox:AddButton({
    Text = 'Load Auto Fire',
    Func = function()
        getgenv().triggerbot.load()
    end,
    DoubleClick = false,
    Tooltip = 'Load The Auto Fire Module'
})

triggerBox:AddSlider('CooldownSlider', {
    Text = 'Auto Fire Delay',
    Default = 0,
    Min = 0,
    Max = 1,
    Rounding = 1,
    Compact = false,

    Callback = function(Value)
        getgenv().trigger.clickDelay = Value
    end
})

triggerBox:AddLabel('Auto Fire Keybind'):AddKeyPicker('AutoFireKeyPicker', {
    Default = 'T', -- String as the name of the keybind (MB1, MB2 for mouse buttons)
    SyncToggleState = false,
    Mode = 'Toggle',

    Text = 'Keybind to Enable the auto fire',
    NoUI = false,
    Callback = function(Value)
        getgenv().triggerbot.toggleKey = Value
    end,
})


local predictBox = Tabs.Aimbot:AddRightGroupbox('Prediction')

predictBox:AddToggle('PredictionToggle', {
    Text = 'Aimbot Prediction',
    Default = false, -- Default value (true / false)
    Tooltip = 'make the aimbot aim to the x or y postion', -- Information shown when you hover over the toggle
    Callback = function(Value)
        aimbot_prediction_enabled = Value
    end
})

predictBox:AddSlider('XSlider', {
    Text = 'Adjust Prediction X',
    Default = 0,
    Min = 0,
    Max = 1,
    Rounding = 1,
    Compact = false,

    Callback = function(Value)
        aimbot_prediction_strength_x = Value
    end
})

predictBox:AddSlider('YSlider', {
    Text = 'Adjust Prediction Y',
    Default = 0,
    Min = 0,
    Max = 1,
    Rounding = 1,
    Compact = false,

    Callback = function(Value)
        aimbot_prediction_strength_y = Value
    end
})

local chamsBox = Tabs.Visual:AddLeftGroupbox('Chams')

chamsBox:AddToggle('chamsToggle', {
    Text = 'Chams Enabled',
    Default = false, -- Default value (true / false)
    Tooltip = 'highlight player', -- Information shown when you hover over the toggle
    Callback = function(Value)
        getgenv().chams.enabled = Value
    end
})

chamsBox:AddToggle('chamsTeamToggle', {
    Text = 'Team Check',
    Default = false, -- Default value (true / false)
    Tooltip = 'checking if the player is in your team,', -- Information shown when you hover over the toggle
    Callback = function(Value)
        getgenv().chams.teamcheck = Value
    end
})

chamsBox:AddLabel('Chams Fill Color'):AddColorPicker('ChamsFillColorPicker', {
    Default = Color3.new(255, 255, 255),
    Title = 'Custom the chams fill color', -- Optional. Allows you to have a custom color picker title (when you open it)
    Transparency = 0, -- Optional. Enables transparency changing for this color picker (leave as nil to disable)

    Callback = function(Value)
        getgenv().chams.fillColor = Value
    end
})

chamsBox:AddLabel('Chams Outline Color'):AddColorPicker('ChamsOutlineColorPicker', {
    Default = Color3.new(255, 255, 255),
    Title = 'Custom the chams Outline color', -- Optional. Allows you to have a custom color picker title (when you open it)
    Transparency = 0, -- Optional. Enables transparency changing for this color picker (leave as nil to disable)

    Callback = function(Value)
        getgenv().chams.outlineColor = Value
    end
})

chamsBox:AddSlider('FillSlider', {
    Text = 'Fill Transparency',
    Default = 1,
    Min = 0,
    Max = 1,
    Rounding = 1,
    Compact = false,

    Callback = function(Value)
        getgenv().chams.fillTransparency = Value
    end
})

chamsBox:AddSlider('OutlineSlider', {
    Text = 'Outline Transparency',
    Default = 0,
    Min = 0,
    Max = 1,
    Rounding = 1,
    Compact = false,

    Callback = function(Value)
        getgenv().chams.outlineTransparency = Value
    end
})
--lol target hud baby sex (thanks chat gpt)
getgenv().targethud = {
    enabled = false, -- Toggle HUD on/off
    maxDistance = 5, -- Maximum distance to detect targets
    defaultHealthColor = Color3.fromRGB(128, 0, 128), -- Default health bar color (purple)
    backgroundTransparency = 0.3, -- Transparency of the outer box
}

local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local playerGui = player:WaitForChild("PlayerGui")

-- Create a ScreenGui to hold the HUD
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = playerGui

-- Create the outer box (background)
local outerBox = Instance.new("Frame")
outerBox.Size = UDim2.new(0, 200, 0, 120) -- Increased height for equipped item
outerBox.Position = UDim2.new(0.5, -100, 0.8, -140) -- Centered horizontally
outerBox.BackgroundColor3 = Color3.fromRGB(22, 22, 31) -- Dark gray
outerBox.BackgroundTransparency = getgenv().targethud.backgroundTransparency -- Set transparency
outerBox.BorderColor3 = Color3.fromRGB(80, 80, 80) -- Border color
outerBox.BorderSizePixel = 1
outerBox.Parent = screenGui
outerBox.Visible = false -- Default hidden

-- Create the header area (blank top bar)
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 20)
header.Position = UDim2.new(0, 0, 0, 0)
header.BackgroundColor3 = Color3.fromRGB(50, 50, 65) -- Slightly lighter gray
header.BorderSizePixel = 0
header.Parent = outerBox

-- Create the player's display name label
local displayNameLabel = Instance.new("TextLabel")
displayNameLabel.Size = UDim2.new(1, -10, 0, 20)
displayNameLabel.Position = UDim2.new(0, 5, 0, 20) -- Below the header
displayNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- White text
displayNameLabel.BackgroundTransparency = 1
displayNameLabel.Font = Enum.Font.GothamBold
displayNameLabel.TextSize = 14
displayNameLabel.Text = ""
displayNameLabel.TextXAlignment = Enum.TextXAlignment.Left
displayNameLabel.Parent = outerBox

-- Create the equipped item label
local equippedItemLabel = Instance.new("TextLabel")
equippedItemLabel.Size = UDim2.new(1, -10, 0, 20)
equippedItemLabel.Position = UDim2.new(0, 5, 0, 40) -- Positioned below the display name
equippedItemLabel.TextColor3 = Color3.fromRGB(200, 200, 200) -- Slightly dimmed white
equippedItemLabel.BackgroundTransparency = 1
equippedItemLabel.Font = Enum.Font.Gotham
equippedItemLabel.TextSize = 12
equippedItemLabel.Text = "None"
equippedItemLabel.TextXAlignment = Enum.TextXAlignment.Left
equippedItemLabel.Parent = outerBox

-- Create the health bar background
local healthBarBackground = Instance.new("Frame")
healthBarBackground.Size = UDim2.new(0.9, 0, 0, 10) -- Slightly narrower for padding
healthBarBackground.Position = UDim2.new(0.05, 0, 0, 70) -- Below the equipped item
healthBarBackground.BackgroundColor3 = Color3.fromRGB(50, 50, 50) -- Dark gray background
healthBarBackground.BorderColor3 = Color3.fromRGB(80, 80, 80) -- Border color
healthBarBackground.BorderSizePixel = 1
healthBarBackground.Parent = outerBox

-- Create the health bar (foreground)
local healthBar = Instance.new("Frame")
healthBar.Size = UDim2.new(0.5, 0, 1, 0)
healthBar.Position = UDim2.new(0, 0, 0, 0)
healthBar.BackgroundColor3 = getgenv().targethud.defaultHealthColor
healthBar.BorderSizePixel = 0
healthBar.Parent = healthBarBackground

-- Create the health number label
local healthNumberLabel = Instance.new("TextLabel")
healthNumberLabel.Size = UDim2.new(1, 0, 1, 0)
healthNumberLabel.Position = UDim2.new(0, 0, 0, 0)
healthNumberLabel.BackgroundTransparency = 1
healthNumberLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
healthNumberLabel.Font = Enum.Font.Gotham
healthNumberLabel.TextSize = 12
healthNumberLabel.Text = "100%"
healthNumberLabel.TextXAlignment = Enum.TextXAlignment.Center
healthNumberLabel.TextYAlignment = Enum.TextYAlignment.Center
healthNumberLabel.Parent = healthBarBackground

-- Create the player's avatar image
local avatarImage = Instance.new("ImageLabel")
avatarImage.Size = UDim2.new(0, 40, 0, 40)
avatarImage.Position = UDim2.new(1, -45, 0, -20)
avatarImage.BackgroundTransparency = 1
avatarImage.Image = ""
avatarImage.Parent = outerBox

-- Update the HUD when hovering over a player
local function updateTargetHUD()
    if not getgenv().targethud.enabled then
        outerBox.Visible = false
        return
    end

    local targetPlayer = nil
    local targetCharacter = nil
    local targetHumanoid = nil

    -- Check if the mouse is hovering over a player
    for _, otherPlayer in pairs(game.Players:GetPlayers()) do
        if otherPlayer.Character and otherPlayer.Character:FindFirstChild("Head") then
            local head = otherPlayer.Character.Head
            local distance = (mouse.Hit.p - head.Position).magnitude

            if distance < getgenv().targethud.maxDistance then
                targetPlayer = otherPlayer
                targetCharacter = otherPlayer.Character
                targetHumanoid = targetCharacter:FindFirstChild("Humanoid")
                break
            end
        end
    end

    if targetPlayer and targetHumanoid then
        -- Show the HUD and update display name
        outerBox.Visible = true
        displayNameLabel.Text = string.format("%s (%s)", targetPlayer.DisplayName, targetPlayer.Name)

        -- Update equipped item
        local equippedTool = targetPlayer.Character:FindFirstChildOfClass("Tool")
        if equippedTool then
            equippedItemLabel.Text = equippedTool.Name
        else
            equippedItemLabel.Text = "None"
        end

        -- Update health bar and health number
        local healthPercentage = math.clamp(targetHumanoid.Health / targetHumanoid.MaxHealth, 0, 1)
        healthBar.Size = UDim2.new(healthPercentage, 0, 1, 0)
        healthNumberLabel.Text = string.format("%d%%", math.floor(healthPercentage * 100))

        local avatarId = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. targetPlayer.UserId .. "&width=420&height=420&format=png"
        avatarImage.Image = avatarId
    else
        outerBox.Visible = false
    end
end

game:GetService("RunService").RenderStepped:Connect(updateTargetHUD)

local hudBox = Tabs.Visual:AddRightGroupbox('Target Hud')

hudBox:AddToggle('hudToggle', {
    Text = 'Target Hud',
    Default = false, -- Default value (true / false)
    Tooltip = 'Show the other player tool and health by hovering over them', -- Information shown when you hover over the toggle
    Callback = function(Value)
        getgenv().targethud.enabled = Value
    end
})

local healthBox = Tabs.Visual:AddLeftGroupbox('Health Bar')

healthBox:AddToggle('healthToggle', {
    Text = 'Health Bar',
    Default = false, -- Default value (true / false)
    Tooltip = 'Show other player Health', -- Information shown when you hover over the toggle
    Callback = function(Value)
        getgenv().hbar.enabled = Value
    end
})

local espBox = Tabs.Visual:AddRightGroupbox('ESP Settings')

espBox:AddToggle('espToggle', {
    Text = 'Enabled',
    Default = false, -- Default value (true / false)
    Tooltip = 'Enabled the esp', -- Information shown when you hover over the toggle
    Callback = function(Value)
        ESP.Enabled = Value
    end
})

espBox:AddToggle('boxToggle', {
    Text = 'Boxes',
    Default = false, -- Default value (true / false)
    Tooltip = 'Enabled the boxes esp', -- Information shown when you hover over the toggle
    Callback = function(Value)
        ESP.ShowBox = Value
    end
})

espBox:AddToggle('nameToggle', {
    Text = 'Names',
    Default = false, -- Default value (true / false)
    Tooltip = 'Enabled the names esp', -- Information shown when you hover over the toggle
    Callback = function(Value)
        ESP.ShowNames = Value
    end
})

espBox:AddToggle('healthToggle', {
    Text = 'Health',
    Default = false, -- Default value (true / false)
    Tooltip = 'Enabled the health esp', -- Information shown when you hover over the toggle
    Callback = function(Value)
        ESP.ShowHealth = Value
    end
})

espBox:AddToggle('tracerToggle', {
    Text = 'Tracer',
    Default = false, -- Default value (true / false)
    Tooltip = 'Enabled the tracer esp', -- Information shown when you hover over the toggle
    Callback = function(Value)
        ESP.ShowTracer = Value
    end
})

espBox:AddToggle('distanceToggle', {
    Text = 'Distance',
    Default = false, -- Default value (true / false)
    Tooltip = 'Enabled the distance esp', -- Information shown when you hover over the toggle
    Callback = function(Value)
        ESP.ShowDistance = Value
    end
})

espBox:AddToggle('EspTeamToggle', {
    Text = 'Team Check',
    Default = false, -- Default value (true / false)
    Tooltip = 'Check if the players is in your team or not', -- Information shown when you hover over the toggle
    Callback = function(Value)
        ESP.Teamcheck = Value
    end
})
--Misc
getgenv().FovChanger = {
    Enabled = false,
    Fov = 70
}
--camera
local cameraBox = Tabs.Misc:AddLeftGroupbox('Camera')

cameraBox:AddToggle('ZoomToggle', {
    Text = 'Infinite Zoom',
    Default = false, -- Default value (true / false)
    Tooltip = 'Infinitly Zooming', -- Information shown when you hover over the toggle
    Callback = function(Value)
        if Value then
            game:GetService("Players").LocalPlayer.CameraMaxZoomDistance = 99999
        else
            game:GetService("Players").LocalPlayer.CameraMaxZoomDistance = 128
        end
    end
})

cameraBox:AddToggle('FovChangerToggle', {
    Text = 'Camera Field Of View',
    Default = false, -- Default value (true / false)
    Tooltip = 'Enable the Field Of View Changer', -- Information shown when you hover over the toggle
    Callback = function(Value)
        getgenv().FovChanger.Enabled = Value
    end
})

cameraBox:AddSlider('FovChangerSlider', {
    Text = 'Field Of View Ammount',
    Default = 70,
    Min = 10,
    Max = 120,
    Rounding = 0,
    Compact = false,

    Callback = function(Value)
        getgenv().FovChanger.Fov = Value
        if getgenv().FovChanger.Enabled then
            workspace.Camera.FieldOfView = Value
        end
    end
})
--desync
local desyncBox = Tabs.Misc:AddLeftGroupbox('Desync')

local DesyncSettings = {
    Enabled = false,
    Strength = 50,
    Frequency = 0.1,
}

desyncBox:AddToggle('DesyncToggle', {
    Text = 'Desync',
    Default = false,
    Tooltip = 'Walkable Desync',
    Callback = function(Value)
        DesyncSettings.Enabled = Value
        print("Desync " .. (DesyncSettings.Enabled and "Enabled" or "Disabled"))
    end
})

desyncBox:AddLabel('Desync Keybind'):AddKeyPicker('DesyncKeyPicker', {
    Default = 'E',
    SyncToggleState = false,
    Mode = 'Toggle',
    Text = 'Keybind to enable desync',
    NoUI = false,
    Callback = function()
        DesyncSettings.Enabled = not DesyncSettings.Enabled
        print("Desync " .. (DesyncSettings.Enabled and "Enabled" or "Disabled"))
        desyncBox:SetToggleState('DesyncToggle', DesyncSettings.Enabled) -- Sync toggle state with keybind
    end
})

desyncBox:AddSlider('DesyncStrength', {
    Text = 'Desync Strength',
    Default = 50,
    Min = 10,
    Max = 100,
    Rounding = 0,
    Tooltip = 'Adjust the intensity of the desync effect',
    Callback = function(Value)
        DesyncSettings.Strength = Value
    end
})

-- Function to clear unwanted scripts
local function clearUnwantedScripts(character)
    for _, v in pairs(character:GetChildren()) do
        if v:IsA("Script") and v.Name ~= "Health" and v.Name ~= "Sound" and v:FindFirstChild("LocalScript") then
            v:Destroy()
        end
    end
end

-- Handle character spawning
game.Players.LocalPlayer.CharacterAdded:Connect(function(char)
    repeat task.wait() until char and char:FindFirstChild("HumanoidRootPart")
    clearUnwantedScripts(char)
    
    char.ChildAdded:Connect(function(child)
        if child:IsA("Script") and child:FindFirstChild("LocalScript") then
            task.wait(0.25)
            child.LocalScript:FireServer()
        end
    end)
end)
-- Improved desync
local RunService = game:GetService("RunService")
local lastUpdate = tick()

RunService.Heartbeat:Connect(function()
    if not DesyncSettings.Enabled then return end

    local char = game.Players.LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- Update desync periodically based on frequency
    if tick() - lastUpdate >= DesyncSettings.Frequency then
        local originalCFrame = hrp.CFrame
        local originalVelocity = hrp.AssemblyLinearVelocity

        -- Apply subtle CFrame offset for desync
        local randomAngle = math.rad(math.random(-5, 5)) -- Small random rotation
        hrp.CFrame = originalCFrame * CFrame.Angles(0, randomAngle, 0)

        -- Apply randomized velocity offset within safer range
        local strength = DesyncSettings.Strength
        local offset = Vector3.new(
            math.random(-strength, strength),
            math.random(-strength / 2, strength / 2),
            math.random(-strength, strength)
        )
        hrp.AssemblyLinearVelocity = originalVelocity + offset

        task.spawn(function()
            RunService.RenderStepped:Wait() -- Wait one frame
            if hrp and hrp.Parent then
                hrp.CFrame = originalCFrame
                hrp.AssemblyLinearVelocity = originalVelocity
            end
        end)

        lastUpdate = tick()
    end
end)
--plr
local plrBox = Tabs.Misc:AddLeftGroupbox('Player')

plrBox:AddToggle('AntiFlingToggle', {
    Text = 'Anti Fling',
    Default = false,
    Tooltip = 'Anti Fling from other exploiters',
    Callback = function(Value)
        if Value then
			antiFlingConnection = game:GetService("RunService").Heartbeat:Connect(function()
				for _, part in pairs(character:GetChildren()) do
					if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
						part.CanCollide = false
					 	if part.Velocity.magnitude > 50 then
							part.Velocity = Vector3.new(0,0,0)
						end
					end
				end
			end)
		else
			if antiFlingConnection then
				antiFlingConnection:Disconnect()
				antiFlingConnection = nil
			end
			for _, part in pairs(character:GetChildren()) do
				if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
					part.CanCollide = true
				end
			end
		end
    end
})

plrBox:AddToggle('AntiVoidToggle', {
    Text = 'Anti Void',
    Default = false,
    Tooltip = 'Prevent you from falling into the void',
    Callback = function(Value)
       if Value then
			antiVoidConnection = game:GetService("RunService").Heartbeat:Connect(function()
				if humanoidRootPart.Position.Y < -100 or humanoidRootPart.Position.Y > 400 then
					humanoidRootPart.CFrame = lastSafePosition
				end
			end)

			positionConnection = game:GetService("RunService").Heartbeat:Connect(function()
				if humanoidRootPart.Velocity.magnitude < 50 and humanoidRootPart.RotVelocity.magnitude < 50 then
					lastSafePosition = humanoidRootPart.CFrame
				end
			end)

			velocityConnection = game:GetService("RunService").Stepped:Connect(function()
				if humanoidRootPart.Velocity.magnitude > 50 then
					humanoidRootPart.Velocity = Vector3.new(0,0,0)
				end
				if humanoidRootPart.RotVelocity.magnitude > 50 then
					humanoidRootPart.RotVelocity = Vector3.new(0,0,0)
				end
			end)
		else
			if antiVoidConnection then antiVoidConnection:Disconnect() antiVoidConnection = nil end
			if positionConnection then positionConnection:Disconnect() positionConnection = nil end
			if velocityConnection then velocityConnection:Disconnect() velocityConnection = nil end
		end
    end
})
--speed

getgenv().speed = {
    enabled = false,     
    speed = 16,        
    control = false,
    friction = 2.0,    
    keybind = Enum.KeyCode.KeypadDivide
}


local function setSpeed(player, speed)
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = speed
    end
end

local function enhanceControl(player, reset)
    local character = player.Character or player.CharacterAdded:Wait()
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if rootPart then
        if reset then
    
            rootPart.CustomPhysicalProperties = PhysicalProperties.new()
        else
      
            rootPart.CustomPhysicalProperties = PhysicalProperties.new(
                0.7, 
                speed.friction,
                0.5,
                1.0, 
                0.5  
            )
        end
    end
end

local function applySpeedBoost(player)
    local character = player.Character or player.CharacterAdded:Wait()

    if speed.enabled then
        setSpeed(player, speed.speed)
        if speed.control then
            enhanceControl(player, false) 
        end
    else
        setSpeed(player, 16)
        if speed.control then
            enhanceControl(player, true) 
        end
    end
end


local function toggleSpeedBoost()
    speed.enabled = not speed.enabled
    print("Speed boost enabled:", speed.enabled)
    applySpeedBoost(game.Players.LocalPlayer)
end

local player = game.Players.LocalPlayer


if player.Character then
    applySpeedBoost(player)
end


player.CharacterAdded:Connect(function()
    applySpeedBoost(player)
end)


game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == speed.keybind then
        toggleSpeedBoost()
    end
end)


game:GetService("RunService").RenderStepped:Connect(function()
    if speed.enabled then
        setSpeed(player, speed.speed)
    end
end)
--movement
local moveBox = Tabs.Misc:AddRightTabbox()
local SpeedTab = moveBox:AddTab('WalkSpeed')

SpeedTab:AddToggle('SpeedToggle', {
    Text = 'Speed Master Switch',
    Default = false, -- Default value (true / false)
    Tooltip = 'Change your player speed', -- Information shown when you hover over the toggle

    Callback = function(Value)
        getgenv().speed.enabled = Value
    end
})

SpeedTab:AddSlider('SpeedSlider', {
    Text = 'Speed Ammount',
    Default = 16,
    Min = 16,
    Max = 1000,
    Rounding = 10,
    Compact = false,

    Callback = function(Value)
        getgenv().speed.speed = Value
    end
})

SpeedTab:AddLabel('Speed Keybind'):AddKeyPicker('SpeedKeyPicker', {
    Default = 'KeypadDivide',
    SyncToggleState = false,

    Mode = 'Toggle',

    Text = 'Speed Keybind', -- Text to display in the keybind menu
    NoUI = false, -- Set to true if you want to hide from the Keybind menu,

    ChangedCallback = function(New)
        getgenv().speed.keybind = New
    end
})

local InfiniteJumpEnabled = false

local otherTab = moveBox:AddTab('Other')

otherTab:AddToggle('InfJumpToggle', {
    Text = 'Infinite Jump',
    Default = false, -- Default value (true / false)
    Tooltip = 'Make you jump infinitly', -- Information shown when you hover over the toggle

    Callback = function(Value)
        InfiniteJumpEnabled = Value
        game:GetService("UserInputService").JumpRequest:connect(function()
            if InfiniteJumpEnabled then
                game:GetService"Players".LocalPlayer.Character:FindFirstChildOfClass'Humanoid':ChangeState("Jumping")
            end
        end)
    end
})

otherTab:AddToggle('AntiAimToggle', {
    Text = 'Anti Aim Master Switch',
    Default = false, -- Default value (true / false)
    Tooltip = 'Spin bot', -- Information shown when you hover over the toggle

    Callback = function(Value)
        getgenv().spin.enabled = Value
    end
})

otherTab:AddLabel('Anti Aim Keybind'):AddKeyPicker('Anti Aim Keybind', {
    Default = 'P', -- String as the name of the keybind (MB1, MB2 for mouse buttons)
    Text = 'Anti Aim Keybind', -- Text to display in the keybind menu
    NoUI = false, -- Set to true if you want to hide from the Keybind menu
    -- Occurs when the keybind itself is changed, `New` is a KeyCode Enum OR a UserInputType Enum
    ChangedCallback = function(New)
        getgenv().aaimweld.keybind = New
    end
})

otherTab:AddToggle('Anti Aim Toggle (Toggle or Hold)', {
    Text = 'Anti Aim Toggle (Toggle or Hold)',
    Default = false, -- Default value (true / false)
    Tooltip = 'Cant hit me (probably)', -- Information shown when you hover over the toggle
    Callback = function(Value)
        getgenv().aaimweld.toggle = Value
    end
})

otherTab:AddSlider('Anti Aim Spin Speed', {
    Text = 'Anti Aim Spin Speed',
    Default = 500,
    Min = 300,
    Max = 4000,
    Rounding = 1,
    Compact = false,
    Callback = function(Value)
        getgenv().aaimweld.spinspeed = Value
    end
})

otherTab:AddToggle('Anti Aim Offset', {
    Text = 'Anti Aim Offset',
    Default = false, -- Default value (true / false)
    Tooltip = 'It makes your chest go way off and it looks funny', -- Information shown when you hover over the toggle
    Callback = function(Value)
        getgenv().aaimweld.offset = Value
    end
})



--menu
local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')

MenuGroup:AddButton('Unload', function() Library:Unload() end)
MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', { Default = 'RightControl', NoUI = true, Text = 'Menu keybind' })

Library.ToggleKeybind = Options.MenuKeybind -- Allows you to have a custom keybind for the menu


ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })
ThemeManager:SetFolder('MyScriptHub')
SaveManager:SetFolder('MyScriptHub/specific-game')
SaveManager:BuildConfigSection(Tabs['UI Settings'])
ThemeManager:ApplyToTab(Tabs['UI Settings'])
ThemeManager:ApplyTheme('Tokyo Night')
