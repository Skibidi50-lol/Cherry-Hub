local allowedPlaceIds = {
    [96342491571673] = true, -- New Players Server
    [109983668079237] = true -- Normal
}

if not allowedPlaceIds[game.PlaceId] then
    game:GetService("Players").LocalPlayer:Kick("Unsupported Game Join Correct.")
    return
end

local UILibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/Skibidi50-lol/Cherry-Hub/refs/heads/main/Addons/LurkHackUIFIXED.lua"))()

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HRP = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

LocalPlayer.CharacterAdded:Connect(function(c)
    Character = c
    HRP = c:WaitForChild("HumanoidRootPart")
    Humanoid = c:WaitForChild("Humanoid")
end)

local Window = UILibrary:CreateWindow({
    Name = "Cherry Hub - SAB",
    Size = UDim2.new(0, 400, 0, 450)
})

-- Connection management for clean unload
local connections = {}
local function addConn(conn)
    table.insert(connections, conn)
end
local function cleanup()
    for _, c in ipairs(connections) do
        pcall(function() c:Disconnect() end)
    end
    connections = {}
    -- cleanup created instances
    pcall(function()
        if game.CoreGui:FindFirstChild("DYHUB_SAB_UI") then
            game.CoreGui.DYHUB_SAB_UI:Destroy()
        end
    end)
end


local espconfig = {
    ViewBaseTimers = false,
    ESP = false
} 

--Float
local floatConnection = nil

local function applyFloat(character)
    local hrp = character:WaitForChild("HumanoidRootPart")

    -- Remove old float
    if hrp:FindFirstChild("FloatPosition") then
        hrp.FloatPosition:Destroy()
    end

    local bp = Instance.new("BodyPosition")
    bp.Name = "FloatPosition"
    bp.MaxForce = Vector3.new(0, 10000, 0)
    bp.Position = hrp.Position + Vector3.new(0, 0.65, 0)
    bp.D = 1000
    bp.P = 10000
    bp.Parent = hrp

    -- Constantly update float position
    floatConnection = game:GetService("RunService").Heartbeat:Connect(function()
        if character and hrp and bp and character:FindFirstChild("Humanoid") and character.Humanoid.Health > 0 then
            bp.Position = hrp.Position + Vector3.new(0, 0.65, 0)
        else
            if floatConnection then
                floatConnection:Disconnect()
                floatConnection = nil
            end
        end
    end)
end

local function removeFloat(character)
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if hrp and hrp:FindFirstChild("FloatPosition") then
        hrp.FloatPosition:Destroy()
    end
    if floatConnection then
        floatConnection:Disconnect()
        floatConnection = nil
    end
end
--Tween To Base
local activeTween = false
local walkThread
local currentTween
local Y_OFFSET = 9
local STOP_DISTANCE = 5

local function applyAntiDeath(state)
    if Humanoid then
        for _, s in pairs({
            Enum.HumanoidStateType.FallingDown,
            Enum.HumanoidStateType.Ragdoll,
            Enum.HumanoidStateType.PlatformStanding,
            Enum.HumanoidStateType.Seated
        }) do
            Humanoid:SetStateEnabled(s, not state)
        end
        if state then
            Humanoid.Health = Humanoid.MaxHealth
            Humanoid:GetPropertyChangedSignal("Health"):Connect(function()
                if Humanoid.Health <= 0 then
                    Humanoid.Health = Humanoid.MaxHealth
                end
            end)
        end
    end
end

local function getBasePosition()
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return nil end
    for _, plot in ipairs(plots:GetChildren()) do
        local sign = plot:FindFirstChild("PlotSign")
        local base = plot:FindFirstChild("DeliveryHitbox")
        if sign and sign:FindFirstChild("YourBase") and sign.YourBase.Enabled and base then
            return base.Position
        end
    end
    return nil
end

local function isAtBase(basePos)
    if not basePos then return false end
    return (HRP.Position - basePos).Magnitude <= STOP_DISTANCE
end

local function tweenWalkTo(pos)
    if currentTween then currentTween:Cancel() end
    local targetPos = Vector3.new(pos.X, pos.Y + Y_OFFSET, pos.Z)
    local distance = (targetPos - HRP.Position).Magnitude
    local duration = distance / math.max(Humanoid.WalkSpeed, 24)
    currentTween = TweenService:Create(HRP, TweenInfo.new(duration, Enum.EasingStyle.Linear), { CFrame = CFrame.new(targetPos) })
    currentTween:Play()
    Humanoid:ChangeState(Enum.HumanoidStateType.Running)
    currentTween.Completed:Wait()
end

local function stopTweenToBase()
    activeTween = false
    if currentTween then currentTween:Cancel() end
    if walkThread then task.cancel(walkThread) end
    Humanoid.WalkSpeed = 24
    warn("Stopped Tween to Base")
end

local function walkToBase()
    while activeTween do
        local basePos = getBasePosition()
        if not basePos then warn("Base not found") break end
        if isAtBase(basePos) then warn("Reached base") stopTweenToBase() break end
        local path = PathfindingService:CreatePath()
        path:ComputeAsync(HRP.Position, basePos)
        if path.Status == Enum.PathStatus.Success then
            for _, wp in ipairs(path:GetWaypoints()) do
                if not activeTween then return end
                if isAtBase(basePos) then stopTweenToBase() return end
                tweenWalkTo(wp.Position)
            end
        else
            tweenWalkTo(basePos)
        end
        task.wait(1.5)
    end
end

local function startTweenToBase()
    if activeTween then return end
    activeTween = true
    applyAntiDeath(true)
    Humanoid.WalkSpeed = 24
    print("Starting Tween to Base...")
    walkThread = task.spawn(function()
        while activeTween do
            walkToBase()
            task.wait(1)
        end
    end)
end

-- =======================================
-- ⚡ Speed Coil Auto Buy
-- =======================================
local function buyAndEquipItem(itemName)
    local success, err = pcall(function()
        local remote = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net"):WaitForChild("RF/CoinsShopService/RequestBuy")
        remote:InvokeServer(itemName)
    end)
    if success then
        task.delay(0.5, function()
            local backpack = LocalPlayer:WaitForChild("Backpack", 5)
            local tool = backpack and backpack:FindFirstChild(itemName)
            if tool then
                local char = LocalPlayer.Character
                if char then
                    tool.Parent = char
                    task.wait(0.25)
                    tool.Parent = backpack
                end
            end
        end)
    else
        warn("Buy failed:", err)
    end
end

local function buyAndEquipSpeedCoil()
    buyAndEquipItem("Speed Coil")
    local backpack = LocalPlayer:WaitForChild("Backpack")
    local tool
    for i = 1, 20 do
        tool = backpack:FindFirstChild("Speed Coil")
        if tool then break end
        task.wait(0.5)
    end
    if tool then
        tool.Parent = LocalPlayer.Character
        task.wait(0.3)
        tool.Parent = backpack
    end
end
task.spawn(buyAndEquipSpeedCoil)
--Esp highlight
local espEnabled = espconfig.ESP
local espUpdateConn

local function addHighlightToCharacter(char)
    if not char or char == LocalPlayer.Character or char:FindFirstChild("ESP") then return end
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP"
    highlight.FillTransparency = 0.75
    highlight.OutlineTransparency = 0.5
    highlight.FillColor = Color3.new(0, 170, 255)
    highlight.OutlineColor = Color3.new(0, 170, 255)
    highlight.Adornee = char
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = char
end

local function removeHighlightFromCharacter(char)
    local highlight = char and char:FindFirstChild("ESP")
    if highlight then highlight:Destroy() end
end

local function enableESP()
    if espUpdateConn then return end
    espUpdateConn = RunService.Heartbeat:Connect(function()
        if not espEnabled then return end
        if not _G._lastESPUpdate or (tick() - _G._lastESPUpdate) >= 0.1 then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    addHighlightToCharacter(player.Character)
                end
            end
            _G._lastESPUpdate = tick()
        end
    end)
    addConn(espUpdateConn)
end

local function disableESP()
    if espUpdateConn then
        pcall(function() espUpdateConn:Disconnect() end)
        espUpdateConn = nil
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            removeHighlightFromCharacter(player.Character)
        end
    end
end
--lock base timer esp
local plotTimers_Enabled = espconfig.ViewBaseTimers
local plotTimers_RenderConnection = nil
local plotTimers_OriginalProperties = {}

local function disablePlotTimers()
    plotTimers_Enabled = false
    if plotTimers_RenderConnection then
        pcall(function() plotTimers_RenderConnection:Disconnect() end)
        plotTimers_RenderConnection = nil
    end
    for label, props in pairs(plotTimers_OriginalProperties) do
        pcall(function()
            if label and label.Parent then
                local bb = label:FindFirstAncestorWhichIsA("BillboardGui")
                if bb and bb.Parent then
                    bb.Enabled = props.bb_enabled
                    bb.AlwaysOnTop = props.bb_alwaysOnTop
                    bb.Size = props.bb_size
                    bb.MaxDistance = props.bb_maxDistance
                    label.TextScaled = props.label_textScaled
                    label.TextWrapped = props.label_textWrapped
                    label.AutomaticSize = props.label_automaticSize
                    label.Size = props.label_size
                    label.TextSize = props.label_textSize
                end
            end
        end)
    end
    table.clear(plotTimers_OriginalProperties)
end

local function enablePlotTimers()
    disablePlotTimers()
    plotTimers_Enabled = true
    local camera = workspace.CurrentCamera
    local DISTANCE_THRESHOLD = 45
    local SCALE_START, SCALE_RANGE = 100, 300
    local MIN_TEXT_SIZE, MAX_TEXT_SIZE = 30, 36
    local lastUpdate = 0

    plotTimers_RenderConnection = RunService.RenderStepped:Connect(function()
        if not plotTimers_Enabled then return end
        if tick() - lastUpdate < 0.1 then return end
        lastUpdate = tick()

        for _, label in ipairs(workspace.Plots:GetDescendants()) do
            if label:IsA("TextLabel") and label.Name == "RemainingTime" then
                local bb = label:FindFirstAncestorWhichIsA("BillboardGui")
                if not bb then continue end
                local model = bb:FindFirstAncestorWhichIsA("Model")
                if not model then continue end
                local basePart = model:FindFirstChildWhichIsA("BasePart", true)
                if not basePart then continue end
                if not plotTimers_OriginalProperties[label] then
                    plotTimers_OriginalProperties[label] = {
                        bb_enabled = bb.Enabled,
                        bb_alwaysOnTop = bb.AlwaysOnTop,
                        bb_size = bb.Size,
                        bb_maxDistance = bb.MaxDistance,
                        label_textScaled = label.TextScaled,
                        label_textWrapped = label.TextWrapped,
                        label_automaticSize = label.AutomaticSize,
                        label_size = label.Size,
                        label_textSize = label.TextSize,
                    }
                end
                bb.MaxDistance = 10000
                bb.AlwaysOnTop = true
                bb.ClipsDescendants = false
                bb.Size = UDim2.new(0, 300, 0, 150)
                label.TextScaled = false
                label.TextWrapped = true
                label.ClipsDescendants = false
                label.Size = UDim2.new(1, 0, 0, 32)
                label.AutomaticSize = Enum.AutomaticSize.Y

                local distance = (camera.CFrame.Position - basePart.Position).Magnitude
                if distance > DISTANCE_THRESHOLD and basePart.Position.Y >= 0 then
                    bb.Enabled = false
                else
                    bb.Enabled = true
                    local t = math.clamp((distance - SCALE_START) / SCALE_RANGE, 0, 1)
                    local newTextSize = math.clamp(MIN_TEXT_SIZE + (MAX_TEXT_SIZE - MIN_TEXT_SIZE) * t, MIN_TEXT_SIZE, MAX_TEXT_SIZE)
                    label.TextSize = newTextSize
                    label.Size = UDim2.new(1, 0, 0, newTextSize + 6)
                end
            end
        end
    end)
    addConn(plotTimers_RenderConnection)
end
--main
local MainTab = Window:CreateTab("Main")

MainTab:CreateToggle({
    Name = "Float",
    Default = false,
    Callback = function(Value)
        local Player = game:GetService("Players").LocalPlayer
        local Character = Player.Character or Player.CharacterAdded:Wait()

        if Value then
            applyFloat(Character)
        else
            removeFloat(Character)
        end

        Player.CharacterAdded:Connect(function(char)
            task.wait(1)
            if Value then
                applyFloat(char)
            end
        end)
    end
})

MainTab:CreateToggle({
    Name = "God Mode",
    Default = false,
    Callback = function(Value)
        local Player = game:GetService("Players").LocalPlayer

        if Value then
            local Character = Player.Character or Player.CharacterAdded:Wait()
            local Humanoid = Character:FindFirstChildOfClass("Humanoid")

            if Humanoid then
                local Clone = Humanoid:Clone()
                Clone.Parent = Character
                Humanoid:Destroy()
                Clone.Name = "Humanoid"
                workspace.CurrentCamera.CameraSubject = Clone
            end
        else
            warn("godmode error")
        end
    end
})

MainTab:CreateToggle({
    Name = "Tween To Base",
    Default = false,
    Callback = function(Value)
        if Value then 
            startTweenToBase() 
        else 
            stopTweenToBase() 
        end
    end
})

local arb = false
local rbDelay = 60

MainTab:CreateToggle({
    Name = "Auto Rebirth",
    Default = false,
    Callback = function(Value)
        arb = Value
        while arb do
            game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Net"):WaitForChild("RF/Rebirth/RequestRebirth"):InvokeServer()
            task.wait(rbDelay)
        end
    end
})

MainTab:CreateSlider({
    Name = "Rebirth Delay",
    Min = 1,
    Max = 500,
    Default = 60,
    Callback = function(Value)
        rbDelay = Value
        print(rbDelay)
    end
})

--ESP
local espTab = Window:CreateTab("Visuals")
espTab:CreateToggle({
    Name = "ESP Highlight",
    Default = false,
    Callback = function(Value)
        espEnabled = Value
        espconfig.ESP = Value
        if Value then
            enableESP() 
        else 
            disableESP() 
        end
    end
})

espTab:CreateToggle({
    Name = "Lock Base Timer ESP",
    Default = false,
    Callback = function(Value)
        espconfig.ViewBaseTimers = Value
        if Value then 
            enablePlotTimers() 
        else 
            disablePlotTimers() 
        end
    end
})
--Pet Rarity ESP (thanks chat gpt for making the refresh thing)
local RunService = game:GetService("RunService")
local activeConnections = {}
local activeEspGuis = {}
local espCounts = {}
local espEnabled = false
local refreshThread

-- 🎨 Rarity Colors
local rarityColors = {
	Common = Color3.fromRGB(180, 180, 180),
	Uncommon = Color3.fromRGB(100, 255, 100),
	Rare = Color3.fromRGB(100, 200, 255),
	Epic = Color3.fromRGB(180, 100, 255),
	Legendary = Color3.fromRGB(255, 100, 100),
	Mythic = Color3.fromRGB(255, 200, 0),
	["Brainrot God"] = Color3.fromRGB(255, 0, 255),
	Secret = Color3.fromRGB(0, 0, 0),
}

local function getColorForRarity(text)
	for rarity, color in pairs(rarityColors) do
		if string.lower(text) == string.lower(rarity) then
			return color
		end
	end
	return Color3.fromRGB(255, 255, 255)
end

local function createESP(rarityLabel)
	if not rarityLabel:IsA("TextLabel") or rarityLabel.Name ~= "Rarity" then return end
	if brainrotOnly and rarityLabel.Text ~= "Brainrot God" then return end

	local billboard = rarityLabel:FindFirstAncestorWhichIsA("BillboardGui")
	if not billboard then return end
	local adornee = billboard.Parent
	if not adornee or not adornee:IsA("Attachment") then return end

	if adornee:FindFirstChild("RarityESP") then return end -- Prevent duplicates

	espCounts[adornee] = (espCounts[adornee] or 0) + 1
	local offsetIndex = espCounts[adornee]

	local espGui = Instance.new("BillboardGui")
	espGui.Name = "RarityESP"
	espGui.Adornee = adornee
	espGui.Size = UDim2.new(0, 100, 0, 40)
	espGui.AlwaysOnTop = true
	espGui.StudsOffset = Vector3.new(0, 2 + (offsetIndex - 1) * 0.8, 0)
	espGui.MaxDistance = 1e6
	espGui.Parent = adornee

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.TextStrokeTransparency = 0.3
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Text = rarityLabel.Text
	label.TextColor3 = getColorForRarity(rarityLabel.Text)
	label.Parent = espGui

	local conn = RunService.RenderStepped:Connect(function()
		if rarityLabel and label then
			label.Text = rarityLabel.Text
			label.TextColor3 = getColorForRarity(rarityLabel.Text)
		end
	end)

	table.insert(activeConnections, conn)
	table.insert(activeEspGuis, espGui)
end

local function clearAllESP()
	for _, conn in ipairs(activeConnections) do
		pcall(function() conn:Disconnect() end)
	end
	activeConnections = {}

	for _, gui in ipairs(activeEspGuis) do
		pcall(function() gui:Destroy() end)
	end
	activeEspGuis = {}

	espCounts = {}
end

local function scanForRarityLabels()
	for _, descendant in ipairs(workspace:GetDescendants()) do
		if descendant:IsA("TextLabel") and descendant.Name == "Rarity" then
			createESP(descendant)
		end
	end
end

local function refreshESP()
	while espEnabled do
		clearAllESP()
		scanForRarityLabels()
		task.wait(1.5)
	end
end

espTab:CreateToggle({
	Name = "Pet Rarity ESP (Refreshable)",
	Default = false,
	Callback = function(Value)
		espEnabled = Value
		if Value then
			task.spawn(refreshESP)
		else
			clearAllESP()
		end
	end
})

--misc
local instantInteractEnabled = false
local instantInteractConnection
local originalHoldDurations = {}

local miscTab = Window:CreateTab("Misc")

miscTab:CreateToggle({
    Name = "Instant Prompt",
    Default = false,
    Callback = function(Value)
         instantInteractEnabled = Value

        if Value then
            originalHoldDurations = {}
            instantInteractConnection = task.spawn(function()
                while instantInteractEnabled do
                    for _, obj in ipairs(workspace:GetDescendants()) do
                        if obj:IsA("ProximityPrompt") then
                            if originalHoldDurations[obj] == nil then
                                originalHoldDurations[obj] = obj.HoldDuration
                            end
                            obj.HoldDuration = 0
                        end
                    end
                    task.wait(0.5)
                end
            end)
        else
            if instantInteractConnection then
                instantInteractEnabled = false
            end
            for obj, value in pairs(originalHoldDurations) do
                if obj and obj:IsA("ProximityPrompt") then
                    obj.HoldDuration = value
                end
            end
            originalHoldDurations = {}
        end
    end
})


miscTab:CreateButton({
    Name = "No Fog",
    Callback = function()
        game.Lighting.FogEnd = 100000
        game.Lighting.FogStart = 0
        game.Lighting.ClockTime = 14
        game.Lighting.Brightness = 2
        game.Lighting.GlobalShadows = false
    end
})

miscTab:CreateLabel("Server Settings")

miscTab:CreateButton({
    Name = "Copy Server Job ID",
    Callback = function()
         setclipboard(game.JobId)
    end
})

miscTab:CreateButton({
    Name = "Server Hop",
    Callback = function()
       local module = loadstring(game:HttpGet"https://raw.githubusercontent.com/LeoKholYt/roblox/main/lk_serverhop.lua")()
       module:Teleport(game.PlaceId) 
    end
})

miscTab:CreateButton({
    Name = "Rejoin",
    Callback = function()
        local ts = game:GetService("TeleportService")
        local p = game:GetService("Players").LocalPlayer
        ts:Teleport(game.PlaceId, p)
    end
})

local creditTab = Window:CreateTab("Credits")

creditTab:CreateLabel("Credit To : #Skibidi50-lol")
creditTab:CreateLabel("????")
