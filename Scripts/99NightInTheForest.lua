local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Lighting = game:GetService("Lighting")
local effect = Lighting:FindFirstChild("VibrantEffect")
local vibrantEffect = Lighting:FindFirstChild("VibrantEffect")
local RunService = game:GetService("RunService")

local instantInteractEnabled = false
local instantInteractConnection
local originalHoldDurations = {}

Lighting.ClockTime = 14
Lighting.GlobalShadows = false

WindUI:AddTheme({
    Name = "Dark",
    Accent = "#18181b",
    Dialog = "#18181b", 
    Outline = "#FFFFFF",
    Text = "#FFFFFF",
    Placeholder = "#999999",
    Background = "#0e0e10",
    Button = "#52525b",
    Icon = "#a1a1aa",
})

WindUI:AddTheme({
    Name = "Light",
    Accent = "#f4f4f5",
    Dialog = "#f4f4f5",
    Outline = "#000000", 
    Text = "#000000",
    Placeholder = "#666666",
    Background = "#ffffff",
    Button = "#e4e4e7",
    Icon = "#52525b",
})

WindUI:AddTheme({
    Name = "Gray",
    Accent = "#374151",
    Dialog = "#374151",
    Outline = "#d1d5db", 
    Text = "#f9fafb",
    Placeholder = "#9ca3af",
    Background = "#1f2937",
    Button = "#4b5563",
    Icon = "#d1d5db",
})

WindUI:AddTheme({
    Name = "Blue",
    Accent = "#1e40af",
    Dialog = "#1e3a8a",
    Outline = "#93c5fd", 
    Text = "#f0f9ff",
    Placeholder = "#60a5fa",
    Background = "#1e293b",
    Button = "#3b82f6",
    Icon = "#93c5fd",
})

WindUI:AddTheme({
    Name = "Green",
    Accent = "#059669",
    Dialog = "#047857",
    Outline = "#6ee7b7", 
    Text = "#ecfdf5",
    Placeholder = "#34d399",
    Background = "#064e3b",
    Button = "#10b981",
    Icon = "#6ee7b7",
})

WindUI:AddTheme({
    Name = "Purple",
    Accent = "#7c3aed",
    Dialog = "#6d28d9",
    Outline = "#c4b5fd", 
    Text = "#faf5ff",
    Placeholder = "#a78bfa",
    Background = "#581c87",
    Button = "#8b5cf6",
    Icon = "#c4b5fd",
})

local themes = {"Dark", "Light", "Gray", "Blue", "Green", "Purple"}
local currentThemeIndex = 1

if not getgenv().TransparencyEnabled then
    getgenv().TransparencyEnabled = true
end
-- auto upgrade campfire
local campfireFuelItems = {"Log", "Coal", "Chair", "Fuel Canister", "Oil Barrel", "Biofuel"}
local campfireDropPos = Vector3.new(0, 19, 0)
local selectedCampfireItem = nil -- Single item storage
local autoUpgradeCampfireEnabled = false

-- esp
local ie = {
    "Bandage", "Bolt", "Broken Fan", "Broken Microwave", "Cake", "Carrot", "Chair", "Coal", "Coin Stack",
    "Cooked Morsel", "Cooked Steak", "Fuel Canister", "Iron Body", "Leather Armor", "Log", "MadKit", "Metal Chair",
    "MedKit", "Old Car Engine", "Old Flashlight", "Old Radio", "Revolver", "Revolver Ammo", "Rifle", "Rifle Ammo",
    "Morsel", "Sheet Metal", "Steak", "Tyre", "Washing Machine"
}
local me = {"Bunny", "Wolf", "Alpha Wolf", "Bear", "Cultist", "Crossbow Cultist", "Alien", "Polar Bear"}
--auto scrap
local scrapjunkItems = {"Log", "Chair", "Tyre", "Bolt", "Broken Fan", "Broken Microwave", "Sheet Metal", "Old Radio", "Washing Machine", "Old Car Engine"}
local autoScrapPos = Vector3.new(21, 20, -5)
local selectedScrapItem = nil
local autoScrapItemsEnabled = false
-- combat
local killAuraToggle = false
local chopAuraToggle = false
local auraRadius = 50
local currentammount = 0

--Mobs
local function getMobs()
    local mobs = {}
    local mobNames = {}
    local index = 1
    for _, character in ipairs(workspace:WaitForChild("Characters"):GetChildren()) do
        if character.Name:match("^Lost Child") and character:GetAttribute("Lost") == true then
            table.insert(mobs, character)
            table.insert(mobNames, character.Name)
            index = index + 1
        end
    end
    return mobs, mobNames
end

local currentMobs, currentMobNames = getMobs()
local selectedMob = currentMobNames[1] or nil

-- auto cook
local autocookItems = {"Morsel", "Steak"}
local autoCookEnabledItems = {}
local autoCookEnabled = false

local toolsDamageIDs = {
    ["Old Axe"] = "3_7367831688",
    ["Good Axe"] = "112_7367831688",
    ["Strong Axe"] = "116_7367831688",
    ["Ice Axe"] = "116_7367831688",
    ["Morningstar"] = "116_7367831688",
    ["Laser Sword"] = "116_7367831688",
    ["Ice Sword"] = "116_7367831688",
    ["Katana"] = "116_7367831688",
    ["Trident"] = "116_7367831688",
    ["Poison Spear"] = "116_7367831688",
    ["Chainsaw"] = "647_8992824875",
    ["Spear"] = "196_8999010016"
}

local function getAnyToolWithDamageID(isChopAura)
    for toolName, damageID in pairs(toolsDamageIDs) do
        if isChopAura and toolName ~= "Old Axe" and toolName ~= "Good Axe" and toolName ~= "Strong Axe" then
            continue
        end
        local tool = LocalPlayer:FindFirstChild("Inventory") and LocalPlayer.Inventory:FindFirstChild(toolName)
        if tool then
            return tool, damageID
        end
    end
    return nil, nil
end

local function equipTool(tool)
    if tool then
        ReplicatedStorage:WaitForChild("RemoteEvents").EquipItemHandle:FireServer("FireAllClients", tool)
    end
end

local function unequipTool(tool)
    if tool then
        ReplicatedStorage:WaitForChild("RemoteEvents").UnequipItemHandle:FireServer("FireAllClients", tool)
    end
end

local function killAuraLoop()
    while killAuraToggle do
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local tool, damageID = getAnyToolWithDamageID(false)
            if tool and damageID then
                equipTool(tool)
                for _, mob in ipairs(Workspace.Characters:GetChildren()) do
                    if mob:IsA("Model") then
                        local part = mob:FindFirstChildWhichIsA("BasePart")
                        if part and (part.Position - hrp.Position).Magnitude <= auraRadius then
                            pcall(function()
                                ReplicatedStorage:WaitForChild("RemoteEvents").ToolDamageObject:InvokeServer(
                                    mob,
                                    tool,
                                    damageID,
                                    CFrame.new(part.Position)
                                )
                            end)
                        end
                    end
                end
                task.wait(0.1)
            else
                task.wait(1)
            end
        else
            task.wait(0.5)
        end
    end
end

local function chopAuraLoop()
    while chopAuraToggle do
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local tool, baseDamageID = getAnyToolWithDamageID(true)
            if tool and baseDamageID then
                equipTool(tool)
                currentammount = currentammount + 1
                local trees = {}
                local map = Workspace:FindFirstChild("Map")
                if map then
                    if map:FindFirstChild("Foliage") then
                        for _, obj in ipairs(map.Foliage:GetChildren()) do
                            if obj:IsA("Model") and obj.Name == "Small Tree" then
                                table.insert(trees, obj)
                            end
                        end
                    end
                    if map:FindFirstChild("Landmarks") then
                        for _, obj in ipairs(map.Landmarks:GetChildren()) do
                            if obj:IsA("Model") and obj.Name == "Small Tree" then
                                table.insert(trees, obj)
                            end
                        end
                    end
                end
                for _, tree in ipairs(trees) do
                    local trunk = tree:FindFirstChild("Trunk")
                    if trunk and trunk:IsA("BasePart") and (trunk.Position - hrp.Position).Magnitude <= auraRadius then
                        local alreadyammount = false
                        task.spawn(function()
                            while chopAuraToggle and tree and tree.Parent and not alreadyammount do
                                alreadyammount = true
                                currentammount = currentammount + 1
                                pcall(function()
                                    ReplicatedStorage:WaitForChild("RemoteEvents").ToolDamageObject:InvokeServer(
                                        tree,
                                        tool,
                                        tostring(currentammount) .. "_7367831688",
                                        CFrame.new(-2.962610244751, 4.5547881126404, -75.950843811035, 0.89621275663376, -1.3894891459643e-08, 0.44362446665764, -7.994568895775e-10, 1, 3.293635941759e-08, -0.44362446665764, -2.9872644802253e-08, 0.89621275663376)
                                    )
                                end)
                                task.wait(0.5)
                            end
                        end)
                    end
                end
                task.wait(0.1)
            else
                task.wait(1)
            end
        else
            task.wait(0.5)
        end
    end
end
--Items
local BlueprintItems = {"Crafting Blueprint", "Defense Blueprint", "Furniture Blueprint"}
local selectedBlueprintItems = {}
local PeltsItems = {"Bunny Foot", "Wolf Pelt", "Alpha Wolf Pelt", "Bear Pelt", "Arctic Fox Pelt", "Polar Bear Pelt"}
local selectedPeltsItems = {}
local junkItems = {"Bolt", "Sheet Metal", "UFO Junk", "UFO Component", "Broken Fan", "Old Radio", "Broken Microwave", "Tyre", "Metal Chair", "Old Car Engine", "Washing Machine", "Cultist Experiment", "Cultist Prototype", "UFO Scrap", "Cultist Gem", "Gem of the Forest Fragment", "Feather", "Old Boot"}
local selectedJunkItems = {}
local fuelItems = {"Log", "Chair", "Coal", "Fuel Canister", "Oil Barrel"}
local selectedFuelItems = {}
local foodItems = {"Cake", "Cooked Steak", "Cooked Morsel", "Ribs", "Salmon", "Cooked Salmon", "Cooked Ribs", "Mackerel", "Cooked Mackerel", "Steak", "Morsel", "Berry", "Carrot", "Stew", "Hearty Stew", "Corn", "Pumpkin", "Meat? Sandwich", "Pumpkin", "Seafood Chowder", "Steak Dinner", "Pumpkin Soup", "BBQ Ribs", "Carrot Cake", "Jar of Jelly", "Mackerel", "Salmon", "Clownfish", "Swordfish", "Jellyfish", "Char", "Eel", "Shark", "Cooked Clownfish", "Cooked Swordfish", "Cooked Jellyfish", "Cooked Char", "Cooked Eel", "Cooked Shark"}
local selectedFoodItems = {}
local medicalItems = {"Bandage", "MedKit"}
local selectedMedicalItems = {}
local equipmentItems = {"Revolver", "Rifle", "Revolver Ammo", "Rifle Ammo", "Giant Sack", "Good Sack", "Strong Axe", "Good Axe", "Frozen Shuriken", "Tactical Shotgun", "Snowball", "Kunai", "Leather Body", "Poison Armour", "Iron Body", "Thorn Body", "Riot Shield", "Alien Armour", "Red Key", "Blue Key", "Yellow Key", "Grey Key", "Frog Key", "Chili Seeds", "Flower Seeds", "Berry Seeds", "Firefly Seeds", "Old Rod", "Good Rod", "Strong Rod"}
local selectedEquipmentItems = {}
--Bring Helper
local function moveItemToPos(item, position)
    if not item or not item:IsDescendantOf(workspace) or not item:IsA("BasePart") and not item:IsA("Model") then return end
    local part = item:IsA("Model") and (item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart") or item:FindFirstChild("Handle")) or item
    if not part or not part:IsA("BasePart") then return end

    if item:IsA("Model") and not item.PrimaryPart then
        pcall(function() item.PrimaryPart = part end)
    end

    pcall(function()
        game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents").RequestStartDraggingItem:FireServer(item)
        if item:IsA("Model") then
            item:SetPrimaryPartCFrame(CFrame.new(position))
        else
            part.CFrame = CFrame.new(position)
        end
        game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents").StopDraggingItem:FireServer(item)
    end)
end
--tp
function tp1()
	(game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()):WaitForChild("HumanoidRootPart").CFrame =
CFrame.new(0.43132782, 15.77634621, -1.88620758, -0.270917892, 0.102997094, 0.957076371, 0.639657021, 0.762253821, 0.0990355015, -0.719334781, 0.639031112, -0.272391081)
end

local function tp2()
    local targetPart = workspace:FindFirstChild("Map")
        and workspace.Map:FindFirstChild("Landmarks")
        and workspace.Map.Landmarks:FindFirstChild("Stronghold")
        and workspace.Map.Landmarks.Stronghold:FindFirstChild("Functional")
        and workspace.Map.Landmarks.Stronghold.Functional:FindFirstChild("EntryDoors")
        and workspace.Map.Landmarks.Stronghold.Functional.EntryDoors:FindFirstChild("DoorRight")
        and workspace.Map.Landmarks.Stronghold.Functional.EntryDoors.DoorRight:FindFirstChild("Model")
    if targetPart then
        local children = targetPart:GetChildren()
        local destination = children[5]
        if destination and destination:IsA("BasePart") then
            local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = destination.CFrame + Vector3.new(0, 5, 0)
            end
        end
    end
end

local Confirmed = false
WindUI:Popup({
    Title = "Cherry Loaded! - 99 Night in the Forest",
    Icon = "cherry",
    IconThemed = true,
    Content = "CherryWare",
    Buttons = {
        { Title = "Cancel", Variant = "Secondary", Callback = function() end },
        { Title = "Continue", Icon = "arrow-right", Callback = function() Confirmed = true end, Variant = "Primary" }
    }
})
repeat task.wait() until Confirmed

local Window = WindUI:CreateWindow({
    Folder = "CherryWare",
    Author = "Cherry",
    Title = "99 Night in the Forest (Beta)",
    IconThemed = true,
    Icon = "cherry",
    Author = "CherryWare",
    Size = UDim2.fromOffset(580, 460),
    Transparent = true,
    Theme = "Purple",
    SideBarWidth = 200,
    ScrollBarEnabled = true,
})

Window:EditOpenButton({
    Title = "CherryWare - Open",
    Icon = "monitor",
    CornerRadius = UDim.new(0, 6),
    StrokeThickness = 2,
    Color = ColorSequence.new(Color3.fromRGB(30, 30, 30), Color3.fromRGB(255, 255, 255)),
    Draggable = true,
})

local ConfigManager = Window.ConfigManager

local Config = ConfigManager:CreateConfig("Config")
--Tabs
local Tabs = {}

Tabs.Upd = Window:Tab({
    Title = "Update Note",
    Icon = "notebook",
})

Tabs.Auto = Window:Tab({
    Title = "Automation",
    Icon = "repeat",
})

Tabs.Combat = Window:Tab({
    Title = "Combat",
    Icon = "sword",
})

Tabs.br = Window:Tab({
    Title = "Bring",
    Icon = "package",
})
Tabs.Tp = Window:Tab({
    Title = "Teleport",
    Icon = "map",
})

Tabs.esp = Window:Tab({
    Title = "ESP",
    Icon = "eye",
})

Tabs.plr = Window:Tab({
    Title = "Player",
    Icon = "user",
})

Tabs.Misc = Window:Tab({
    Title = "Misc",
    Icon = "dices",
})
--Update

local Section = Tabs.Upd:Section({ 
    Title = "Updates",
    TextXAlignment = "Left",
    TextSize = 17,
	Icon = "notebook"
})

local Paragraph = Tabs.Upd:Paragraph({
    Title = "Update",
    Desc = "Jump Boost\nESP",
    Locked = false,
})

--Auto
local Section = Tabs.Auto:Section({ 
    Title = "Auto Upgrade Campfire",
    TextXAlignment = "Left",
    TextSize = 17,
	Icon = "flame"
})

Tabs.Auto:Dropdown({
    Title = "Auto Upgrade Campfire",
    Desc = "Choose the items",
    Values = campfireFuelItems,
    Multi = false,
    AllowNone = true,
    Callback = function(option)
        selectedCampfireItem = option
    end
})

Tabs.Auto:Toggle({
    Title = "Auto Upgrade Campfire",
    Value = false,
    Callback = function(checked)
        autoUpgradeCampfireEnabled = checked
        if checked then
            task.spawn(function()
                while autoUpgradeCampfireEnabled do
                    -- Check if an item is selected
                    if selectedCampfireItem then
                        for _, item in ipairs(workspace:WaitForChild("Items"):GetChildren()) do
                            if item.Name == selectedCampfireItem then
                                moveItemToPos(item, campfireDropPos)
                            end
                        end
                    end
                    task.wait(2)
                end
            end)
        end
    end
})

local Section = Tabs.Auto:Section({ 
    Title = "Auto Cook Food",
    TextXAlignment = "Left",
    TextSize = 17,
	Icon = "flame"
})

Tabs.Auto:Dropdown({
    Title = "Auto Cook Food",
    Values = autocookItems,
    Multi = true,
    AllowNone = true,
    Callback = function(options)
        for _, itemName in ipairs(autocookItems) do
            autoCookEnabledItems[itemName] = table.find(options, itemName) ~= nil
        end
    end
})

Tabs.Auto:Toggle({
    Title = "Auto Cook Food",
    Value = false,
    Callback = function(state)
        autoCookEnabled = state
    end
})

coroutine.wrap(function()
    while true do
        if autoCookEnabled then
            for itemName, enabled in pairs(autoCookEnabledItems) do
                if enabled then
                    for _, item in ipairs(Workspace:WaitForChild("Items"):GetChildren()) do
                        if item.Name == itemName then
                            moveItemToPos(item, campfireDropPos)
                        end
                    end
                end
            end
        end
        task.wait(0.5)
    end
end)()

local Section = Tabs.Auto:Section({ 
    Title = "Auto Scrap Item",
    TextXAlignment = "Left",
    TextSize = 17,
	Icon = "cog"
})

Tabs.Auto:Dropdown({
    Title = "Auto Scrap Items",
    Desc = "Choose the items",
    Values = scrapjunkItems,
    Multi = false,
    AllowNone = true,
    Callback = function(option)
        selectedScrapItem = option
    end
})

Tabs.Auto:Toggle({
    Title = "Auto Scrap Item",
    Value = false,
    Callback = function(checked)
        autoScrapItemsEnabled = checked
        if checked then
            task.spawn(function()
                while autoScrapItemsEnabled do
                    -- Check if an item is selected
                    if selectedScrapItem then
                        for _, item in ipairs(workspace:WaitForChild("Items"):GetChildren()) do
                            if item.Name == selectedScrapItem then
                                moveItemToPos(item, autoScrapPos)
                            end
                        end
                    end
                    task.wait(2)
                end
            end)
        end
    end
})

--Combat
local Section = Tabs.Combat:Section({ 
    Title = "Combat Settings",
    TextXAlignment = "Left",
    TextSize = 17,
	Icon = "sword"
})

Tabs.Combat:Toggle({
    Title = "Kill Aura",
    Value = false,
    Callback = function(state)
        killAuraToggle = state
        if state then
            task.spawn(killAuraLoop)
        else
            local tool, _ = getAnyToolWithDamageID(false)
            unequipTool(tool)
        end
    end
})

Tabs.Combat:Toggle({
    Title = "Chop Aura",
    Value = false,
    Callback = function(state)
        chopAuraToggle = state
        if state then
            task.spawn(chopAuraLoop)
        else
            local tool, _ = getAnyToolWithDamageID(true)
            unequipTool(tool)
        end
    end
})

local Section = Tabs.Combat:Section({ 
    Title = "Aura Settings",
    TextXAlignment = "Left",
    TextSize = 17,
})

Tabs.Combat:Slider({
    Title = "Aura Radius",
    Value = { Min = 50, Max = 500, Default = 50 },
    Callback = function(value)
        auraRadius = math.clamp(value, 10, 500)
    end
})

local Keybind = Tabs.Combat:Keybind({
    Title = "Window Keybind",
    Desc = "Keybind to open ui",
    Value = "G",
    Callback = function(v)
        Window:SetToggleKey(Enum.KeyCode[v])
    end
})
--bring
Tabs.br:Dropdown({
    Title = "Select Junk Items",
    Desc = "Choose items to bring",
    Values = junkItems,
    Multi = true,
    AllowNone = true,
    Callback = function(options)
        selectedJunkItems = options
    end
})

Tabs.br:Button({
    Title = "Bring Junk Items",
    Locked = false,
    Callback = function()
        local player = game.Players.LocalPlayer
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
        local hrp = player.Character.HumanoidRootPart
        local targetPos = hrp.Position + Vector3.new(2, 0, 0)
        for _, itemName in ipairs(selectedJunkItems) do
            for _, item in ipairs(workspace:GetDescendants()) do
                if item.Name == itemName and (item:IsA("BasePart") or item:IsA("Model")) and (item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")) then
                    moveItemToPos(item, targetPos)
                end
            end
        end
    end
})

Tabs.br:Section({ Title = "Fuel", Icon = "flame" })

Tabs.br:Dropdown({
    Title = "Select Fuel Items",
    Desc = "Choose items to bring",
    Values = fuelItems,
    Multi = true,
    AllowNone = true,
    Callback = function(options)
        selectedFuelItems = options
    end
})

Tabs.br:Button({
    Title = "Bring Fuel Items",
    Locked = false,
    Callback = function()
        local player = game.Players.LocalPlayer
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
        local hrp = player.Character.HumanoidRootPart
        local targetPos = hrp.Position + Vector3.new(2, 0, 0)
        local broughtItems = 0
        for _, itemName in ipairs(selectedFuelItems) do
            for _, item in ipairs(workspace:GetDescendants()) do
                if item.Name == itemName and (item:IsA("BasePart") or item:IsA("Model")) then
                    moveItemToPos(item, targetPos)
                    broughtItems = broughtItems + 1
                end
            end
        end
    end
})

Tabs.br:Section({ Title = "Food", Icon = "utensils" })

Tabs.br:Dropdown({
    Title = "Select Food Items",
    Desc = "Choose items to bring",
    Values = foodItems,
    Multi = true,
    AllowNone = true,
    Callback = function(options)
        selectedFoodItems = options
    end
})

Tabs.br:Button({
    Title = "Bring Food Items",
    Locked = false,
    Callback = function()
        local player = game.Players.LocalPlayer
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
        local hrp = player.Character.HumanoidRootPart
        local targetPos = hrp.Position + Vector3.new(2, 0, 0)
        for _, itemName in ipairs(selectedFoodItems) do
            for _, item in ipairs(workspace:GetDescendants()) do
                if item.Name == itemName and (item:IsA("BasePart") or item:IsA("Model")) and (item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")) then
                    moveItemToPos(item, targetPos)
                end
            end
        end
    end
})

Tabs.br:Section({ Title = "Medicine", Icon = "bandage" })

Tabs.br:Dropdown({
    Title = "Select Medical Items",
    Desc = "Choose items to bring",
    Values = medicalItems,
    Multi = true,
    AllowNone = true,
    Callback = function(options)
        selectedMedicalItems = options
    end
})

Tabs.br:Button({
    Title = "Bring Medical Items",
    Locked = false,
    Callback = function()
        local player = game.Players.LocalPlayer
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
        local hrp = player.Character.HumanoidRootPart
        local targetPos = hrp.Position + Vector3.new(2, 0, 0)
        for _, itemName in ipairs(selectedMedicalItems) do
            for _, item in ipairs(workspace:GetDescendants()) do
                if item.Name == itemName and (item:IsA("BasePart") or item:IsA("Model")) and (item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")) then
                    moveItemToPos(item, targetPos)
                end
            end
        end
    end
})

Tabs.br:Section({ Title = "Equipment", Icon = "sword" })

Tabs.br:Dropdown({
    Title = "Select Equipment Items",
    Desc = "Choose items to bring",
    Values = equipmentItems,
    Multi = true,
    AllowNone = true,
    Callback = function(options)
        selectedEquipmentItems = options
    end
})

Tabs.br:Button({
    Title = "Bring Equipment Items",
    Locked = false,
    Callback = function()
        local player = game.Players.LocalPlayer
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
        local hrp = player.Character.HumanoidRootPart
        local targetPos = hrp.Position + Vector3.new(2, 0, 0)
        for _, itemName in ipairs(selectedEquipmentItems) do
            for _, item in ipairs(workspace:GetDescendants()) do
                if item.Name == itemName and (item:IsA("BasePart") or item:IsA("Model")) and (item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")) then
                    moveItemToPos(item, targetPos)
                end
            end
        end
    end
})

local Section = Tabs.Tp:Section({ 
    Title = "Teleport Settings",
    TextXAlignment = "Left",
    TextSize = 17,
	Icon = "map"
})

Tabs.Tp:Toggle({
    Title = "Scan Map",
    Default = false,
    Callback = function(state)
        getgenv().scan_map = state

        task.spawn(function()
            local Players = game:GetService("Players")
            local player = Players.LocalPlayer
            local character = player.Character or player.CharacterAdded:Wait()
            local hrp = character:WaitForChild("HumanoidRootPart", 3)
            if not hrp then return end

            local map = workspace:FindFirstChild("Map")
            if not map then return end

            local foliage = map:FindFirstChild("Foliage") or map:FindFirstChild("Landmarks")
            if not foliage then return end

            while getgenv().scan_map do
                local trees = {}
                for _, obj in ipairs(foliage:GetChildren()) do
                    if obj.Name == "Small Tree" and obj:IsA("Model") then
                        local trunk = obj:FindFirstChild("Trunk") or obj.PrimaryPart
                        if trunk then
                            table.insert(trees, trunk)
                        end
                    end
                end

                for _, trunk in ipairs(trees) do
                    if not getgenv().scan_map then break end
                    if trunk and trunk.Parent then
                        local treeCFrame = trunk.CFrame
                        local rightVector = treeCFrame.RightVector
                        local targetPosition = treeCFrame.Position + rightVector * 69
                        hrp.CFrame = CFrame.new(targetPosition)
                        task.wait(0.1)
                    end
                end
            end
        end)
    end
})

Tabs.Tp:Button({
    Title = "Teleport to Campfire",
    Locked = false,
    Callback = function()
        tp1()
    end
})

Tabs.Tp:Button({
    Title = "Teleport to Stronghold",
    Locked = false,
    Callback = function()
        tp2()
    end
})

Tabs.Tp:Button({
    Title = "Teleport to Trader (Bunny Foot)",
    Callback=function()
        local pos = Vector3.new(-37.08, 3.98, -16.33)
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local hrp = character:WaitForChild("HumanoidRootPart")
        hrp.CFrame = CFrame.new(pos)
    end
})

Tabs.Tp:Button({
    Title = "Teleport to Safe Zone",
    Callback = function()
        if not workspace:FindFirstChild("SafeZonePart") then
            local createpart = Instance.new("Part")
            createpart.Name = "SafeZonePart"
            createpart.Size = Vector3.new(50, 50, 50)
            createpart.Position = Vector3.new(0, 105, 0)
            createpart.Anchored = true
            createpart.CanCollide = false
            createpart.Transparency = 0.8
            createpart.Color = Color3.fromRGB(255, 255, 255)
            createpart.Parent = workspace
        end
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local hrp = character:WaitForChild("HumanoidRootPart")
        hrp.CFrame = CFrame.new(0, 110, 0)
    end
})

local Section = Tabs.Tp:Section({ 
    Title = "Lost Child Settings",
    TextXAlignment = "Left",
    TextSize = 17,
	Icon = "baby"
})

local MobDropdown = Tabs.Tp:Dropdown({
    Title = "Select Child",
    Values = currentMobNames,
    Multi = false,
    AllowNone = true,
    Callback = function(options)
        selectedMob = options[#options] or currentMobNames[1] or nil
    end
})

Tabs.Tp:Button({
    Title = "Refresh List",
    Locked = false,
    Callback = function()
        currentMobs, currentMobNames = getMobs()
        if #currentMobNames > 0 then
            selectedMob = currentMobNames[1]
            MobDropdown:Refresh(currentMobNames)
        else
            selectedMob = nil
            MobDropdown:Refresh({ "No child found" })
        end
    end
})

Tabs.Tp:Button({
    Title = "Teleport to Child",
    Locked = false,
    Callback = function()
        if selectedMob and currentMobs then
            for i, name in ipairs(currentMobNames) do
                if name == selectedMob then
                    local targetMob = currentMobs[i]
                    if targetMob then
                        local part = targetMob.PrimaryPart or targetMob:FindFirstChildWhichIsA("BasePart")
                        if part and game.Players.LocalPlayer.Character then
                            local hrp = game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                            if hrp then
                                hrp.CFrame = part.CFrame + Vector3.new(0, 5, 0)
                            end
                        end
                    end
                    break
                end
            end
        end
    end
})
--esp
function createESPText(part, text, color)
    if part:FindFirstChild("ESPTexto") then return end

    local esp = Instance.new("BillboardGui")
    esp.Name = "ESPText"
    esp.Adornee = part
    esp.Size = UDim2.new(0, 100, 0, 20)
    esp.StudsOffset = Vector3.new(0, 2.5, 0)
    esp.AlwaysOnTop = true
    esp.MaxDistance = 300

    local label = Instance.new("TextLabel")
    label.Parent = esp
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color or Color3.fromRGB(255,255,0)
    label.TextStrokeTransparency = 0.2
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold

    esp.Parent = part
end

local function Aesp(nome, tipo)
    local container
    local color
    if tipo == "item" then
        container = workspace:FindFirstChild("Items")
        color = Color3.fromRGB(0, 255, 0)
    elseif tipo == "mob" then
        container = workspace:FindFirstChild("Characters")
        color = Color3.fromRGB(255, 255, 0)
    else
        return
    end
    if not container then return end

    for _, obj in ipairs(container:GetChildren()) do
        if obj.Name == nome then
            local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
            if part then
                createESPText(part, obj.Name, color)
            end
        end
    end
end

local function Desp(nome, tipo)
    local container
    if tipo == "item" then
        container = workspace:FindFirstChild("Items")
    elseif tipo == "mob" then
        container = workspace:FindFirstChild("Characters")
    else
        return
    end
    if not container then return end

    for _, obj in ipairs(container:GetChildren()) do
        if obj.Name == nome then
            local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
            if part then
                for _, gui in ipairs(part:GetChildren()) do
                    if gui:IsA("BillboardGui") and gui.Name == "ESPTexto" then
                        gui:Destroy()
                    end
                end
            end
        end
    end
end

local selectedItems = {}
local selectedMobs = {}
local espItemsEnabled = false
local espMobsEnabled = false
local espConnections = {}

Tabs.esp:Section({ Title = "Esp Items", Icon = "package" })

Tabs.esp:Toggle({
    Title = "Enable Esp",
    Value = false,
    Callback = function(state)
        espItemsEnabled = state
        for _, name in ipairs(ie) do
            if state and table.find(selectedItems, name) then
                Aesp(name, "item")
            else
                Desp(name, "item")
            end
        end

        if state then
            if not espConnections["Items"] then
                local container = workspace:FindFirstChild("Items")
                if container then
                    espConnections["Items"] = container.ChildAdded:Connect(function(obj)
                        if table.find(selectedItems, obj.Name) then
                            local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                            if part then
                                createESP(part, obj.Name, Color3.fromRGB(0, 255, 0))
                            end
                        end
                    end)
                end
            end
        else
            if espConnections["Items"] then
                espConnections["Items"]:Disconnect()
                espConnections["Items"] = nil
            end
        end
    end
})

Tabs.esp:Dropdown({
    Title = "Esp Items",
    Values = ie,
    Value = {},
    Multi = true,
    AllowNone = true,
    Callback = function(options)
        selectedItems = options
        if espItemsEnabled then
            for _, name in ipairs(ie) do
                if table.find(selectedItems, name) then
                    Aesp(name, "item")
                else
                    Desp(name, "item")
                end
            end
        else
            for _, name in ipairs(ie) do
                Desp(name, "item")
            end
        end
    end
})

Tabs.esp:Section({ Title = "Esp Entity", Icon = "user" })

Tabs.esp:Dropdown({
    Title = "Esp Entity",
    Values = me,
    Value = {},
    Multi = true,
    AllowNone = true,
    Callback = function(options)
        selectedMobs = options
        if espMobsEnabled then
            for _, name in ipairs(me) do
                if table.find(selectedMobs, name) then
                    Aesp(name, "mob")
                else
                    Desp(name, "mob")
                end
            end
        else
            for _, name in ipairs(me) do
                Desp(name, "mob")
            end
        end
    end
})

Tabs.esp:Toggle({
    Title = "Enable Esp",
    Value = false,
    Callback = function(state)
        espMobsEnabled = state
        for _, name in ipairs(me) do
            if state and table.find(selectedMobs, name) then
                Aesp(name, "mob")
            else
                Desp(name, "mob")
            end
        end

        if state then
            if not espConnections["Mobs"] then
                local container = workspace:FindFirstChild("Characters")
                if container then
                    espConnections["Mobs"] = container.ChildAdded:Connect(function(obj)
                        if table.find(selectedMobs, obj.Name) then
                            local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                            if part then
                                createESP(part, obj.Name, Color3.fromRGB(255, 255, 0))
                            end
                        end
                    end)
                end
            end
        else
            if espConnections["Mobs"] then
                espConnections["Mobs"]:Disconnect()
                espConnections["Mobs"] = nil
            end
        end
    end
})


--player
local Section = Tabs.plr:Section({ 
    Title = "Player Settings",
    TextXAlignment = "Left",
    TextSize = 17,
	Icon = "user"
})

local Players = game:GetService("Players")
local speed = 16
local jump = 50
local InfiniteJump = false



local function setSpeed(val)
    local humanoid = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid.WalkSpeed = val end
end

local function setJump(val)
    local humanoid = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.JumpPower = val
    end
end

Tabs.plr:Toggle({
    Title = "Enable Speed",
    Value = false,
    Callback = function(state)
        setSpeed(state and speed or 16)
    end
})


Tabs.plr:Slider({
    Title = "Speed",
    Value = { Min = 16, Max = 150, Default = 16 },
    Callback = function(value)
        speed = value
    end
})

Tabs.plr:Toggle({
    Title = "Enable Jump Boost",
    Value = false,
    Callback = function(state)
        setJump(state and jump or 16)
    end
})

Tabs.plr:Slider({
    Title = "Jump Boost Ammount",
    Value = { Min = 10, Max = 300, Default = 50 },
    Callback = function(value)
        jump = value
    end
})

Tabs.plr:Toggle({
    Title = "Infinite Jump",
    Value = false,
    Callback = function(state)
        InfiniteJump = state
        game:GetService("UserInputService").JumpRequest:connect(function()
            if InfiniteJump then
                game:GetService"Players".LocalPlayer.Character:FindFirstChildOfClass'Humanoid':ChangeState("Jumping")
            end
        end)
    end
})

local Section = Tabs.Misc:Section({ 
    Title = "Misc",
    TextXAlignment = "Left",
    TextSize = 17,
	Icon = "dices"
})

Tabs.Misc:Toggle({
    Title = "Instant Interact",
    Value = false,
    Callback = function(state)
        instantInteractEnabled = state

        if state then
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

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local torchLoop = nil


local originalParents = {
    Sky = nil,
    Bloom = nil,
    CampfireEffect = nil
}

-- Function to store original parents
local function storeOriginalParents()
    local Lighting = game:GetService("Lighting")
    
    local sky = Lighting:FindFirstChild("Sky")
    local bloom = Lighting:FindFirstChild("Bloom")
    local campfireEffect = Lighting:FindFirstChild("CampfireEffect")
    
    if sky and not originalParents.Sky then
        originalParents.Sky = sky.Parent
    end
    if bloom and not originalParents.Bloom then
        originalParents.Bloom = bloom.Parent
    end
    if campfireEffect and not originalParents.CampfireEffect then
        originalParents.CampfireEffect = campfireEffect.Parent
    end
end

storeOriginalParents()

local originalColorCorrectionParent = nil

local function storeColorCorrectionParent()
    local Lighting = game:GetService("Lighting")
    local colorCorrection = Lighting:FindFirstChild("ColorCorrection")
    
    if colorCorrection and not originalColorCorrectionParent then
        originalColorCorrectionParent = colorCorrection.Parent
    end
end

storeColorCorrectionParent()

Tabs.Misc:Toggle({
    Title = "Disable Fog",
    Value = false,
    Callback = function(state)
        local Lighting = game:GetService("Lighting")
        
        if state then
            local sky = Lighting:FindFirstChild("Sky")
            local bloom = Lighting:FindFirstChild("Bloom")
            local campfireEffect = Lighting:FindFirstChild("CampfireEffect")
            
            if sky then
                sky.Parent = nil
            end
            if bloom then
                bloom.Parent = nil
            end
            if campfireEffect then
                campfireEffect.Parent = nil
            end
        else
            local sky = game:FindFirstChild("Sky", true)
            local bloom = game:FindFirstChild("Bloom", true) 
            local campfireEffect = game:FindFirstChild("CampfireEffect", true)
            
            if not sky then sky = Lighting:FindFirstChild("Sky") end
            if not bloom then bloom = Lighting:FindFirstChild("Bloom") end
            if not campfireEffect then campfireEffect = Lighting:FindFirstChild("CampfireEffect") end
            
            if sky then
                sky.Parent = originalParents.Sky or Lighting
            end
            if bloom then
                bloom.Parent = originalParents.Bloom or Lighting
            end
            if campfireEffect then
                campfireEffect.Parent = originalParents.CampfireEffect or Lighting
            end
            

        end
    end
})

local vibrantEffect = Lighting:FindFirstChild("VibrantEffect") or Instance.new("ColorCorrectionEffect")
vibrantEffect.Name = "VibrantEffect"
vibrantEffect.Saturation = 0.9
vibrantEffect.Contrast = 0.4
vibrantEffect.Brightness = 0.1
vibrantEffect.Enabled = false
vibrantEffect.Parent = Lighting

Tabs.Misc:Toggle({
    Title = "Vibrant Colors",
    Default = false,
    Callback = function(state)
        if state then
            Lighting.Ambient = Color3.fromRGB(180, 180, 180)
            Lighting.OutdoorAmbient = Color3.fromRGB(170, 170, 170)
            Lighting.ColorShift_Top = Color3.fromRGB(255, 230, 200)
            Lighting.ColorShift_Bottom = Color3.fromRGB(200, 240, 255)
            vibrantEffect.Enabled = true
        else
            Lighting.Ambient = Color3.new(0, 0, 0)
            Lighting.OutdoorAmbient = Color3.new(0, 0, 0)
            Lighting.ColorShift_Top = Color3.new(0, 0, 0)
            Lighting.ColorShift_Bottom = Color3.new(0, 0, 0)
            vibrantEffect.Enabled = false
        end
    end
})

Tabs.Misc:Button({
    Title = "FPS Boost",
    Callback = function()
        pcall(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            local lighting = game:GetService("Lighting")
            lighting.Brightness = 0
            lighting.FogEnd = 100
            lighting.GlobalShadows = false
            lighting.EnvironmentDiffuseScale = 0
            lighting.EnvironmentSpecularScale = 0
            lighting.ClockTime = 14
            lighting.OutdoorAmbient = Color3.new(0, 0, 0)
            local terrain = workspace:FindFirstChildOfClass("Terrain")
            if terrain then
                terrain.WaterWaveSize = 0
                terrain.WaterWaveSpeed = 0
                terrain.WaterReflectance = 0
                terrain.WaterTransparency = 1
            end
            for _, obj in ipairs(lighting:GetDescendants()) do
                if obj:IsA("PostEffect") or obj:IsA("BloomEffect") or obj:IsA("ColorCorrectionEffect") or obj:IsA("SunRaysEffect") or obj:IsA("BlurEffect") then
                    obj.Enabled = false
                end
            end
            for _, obj in ipairs(game:GetDescendants()) do
                if obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
                    obj.Enabled = false
                elseif obj:IsA("Texture") or obj:IsA("Decal") then
                    obj.Transparency = 1
                end
            end
            for _, part in ipairs(workspace:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CastShadow = false
                end
            end
        end)
    end
})

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local torchLoop = nil

Tabs.Misc:Toggle({
    Title = "Auto Stun Deer",
    Value = false,
    Callback = function(state)
        if state then
            torchLoop = RunService.RenderStepped:Connect(function()
                pcall(function()
                    local remote = ReplicatedStorage:FindFirstChild("RemoteEvents")
                        and ReplicatedStorage.RemoteEvents:FindFirstChild("DeerHitByTorch")
                    local deer = workspace:FindFirstChild("Characters")
                        and workspace.Characters:FindFirstChild("Deer")
                    if remote and deer then
                        remote:InvokeServer(deer)
                    end
                end)
                task.wait(0.1)
            end)
        else
            if torchLoop then
                torchLoop:Disconnect()
                torchLoop = nil
            end
        end
    end
})

Window:SelectTab(1)
