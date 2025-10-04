local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'
local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet('https://raw.githubusercontent.com/Skibidi50-lol/Cherry-Hub/refs/heads/main/Addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local Window = Library:CreateWindow({
    Title = 'Cherry Hub - Fisch V1.0.0 (BETA)',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local PlayerGUI = LocalPlayer:FindFirstChildOfClass("PlayerGui")
local RenderStepped = RunService.RenderStepped
local WaitForSomeone = RenderStepped.Wait

local TpSpotsFolder = Workspace:FindFirstChild("world"):WaitForChild("spawns"):WaitForChild("TpSpots")
local NpcFolder = Workspace:FindFirstChild("world"):WaitForChild("npcs")

-- Varbiables
local autoSell = false
local autoShake = false
local autoReel = false
local autoCast = false
local autoCastMode = "Legit"
local autoCastDelay = 2
local autoCatchMethod = "Perfect" --Perfect or Random catch method for Instant Reel
local ZoneCast = false
local Zone = "Brine Pool"
local Noclip = false
local AntiDrown = false
local CollarPlayer = false
local Target
local FreezeChar = false

--Safe way to get HumanoidRootPart
local function getHRP()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- Auto Farm
local autocast_running = false
local function StartAutoCast()
    if autocast_running then return end
    autocast_running = true
    task.spawn(function()
        while autoCast do
            local char = LocalPlayer.Character
            local rod = nil
            -- Find the equipped rod
            for _, tool in ipairs(char:GetChildren()) do
                if tool:IsA("Tool") and tool:FindFirstChild("events") and tool.events:FindFirstChild("cast") then 
                    rod = tool 
                    break 
                end
            end
            
            if rod then
                local cast = rod.events.cast
                if cast then 
                    if autoCastMode == "Rage" then
                        -- Rage Cast: Fires the server event directly
                        pcall(function() cast:FireServer(100,true) end) 
                    elseif autoCastMode == "Legit" then
                        -- Legit Cast: Simulates mouse click, waits delay, then releases
                        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, LocalPlayer, 0)
                        task.wait(autoCastDelay) 
                        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, LocalPlayer, 0)
                    end
                end
            end
            task.wait(autoCastDelay)
        end
        autocast_running = false
    end)
end
-- Auto Reel (Instant/Rage Reel)
local autoreel_running = false
local function StartAutoReel()
    if autoreel_running then return end
    autoreel_running = true
    task.spawn(function()
        local reelfinished = ReplicatedStorage:WaitForChild("events"):WaitForChild("reelfinished")
        while autoReel do
            local reel = PlayerGUI:FindFirstChild("reel")
            
            if reel and reel.Parent then
                local isPerfect
                if autoCatchMethod == "Perfect" then
                    isPerfect = true
                elseif autoCatchMethod == "Random" then
                    isPerfect = (math.random(0,1) == 1)
                else
                    isPerfect = true
                end
                
                -- Instant Reel Logic: Fires the server event directly
                pcall(function() reelfinished:FireServer(100, isPerfect) end)
            end
            
            -- Use a very fast delay for instant reel
            task.wait(0.05)
        end
        autoreel_running = false
    end)
end

-- Auto Shake(Rage Shake)
local autoshake_running = false
local function StartAutoShake()
    if autoshake_running then return end
    autoshake_running = true
    task.spawn(function()
        while autoShake do
            local shakeButton = PlayerGUI:FindFirstChild("shakeui")
            shakeButton = shakeButton and shakeButton:FindFirstChild("safezone")
            shakeButton = shakeButton and shakeButton:FindFirstChild("button")
            shakeButton = shakeButton and shakeButton:FindFirstChild("shake")
            
            -- Rage shake : Fires the server event directly
            if shakeButton then pcall(function() shakeButton:FireServer() end) end
            
            -- Use a very fast delay for rage shake
            task.wait(0.05)
        end
        autoshake_running = false
    end)
end


function SellFishAndReturnAll()
    local rootPart = getHRP()
    if not rootPart then return end

    local currentPosition = rootPart.CFrame
    local wasFreezeCharActive = FreezeChar
    if wasFreezeCharActive then
        FreezeChar = false -- Disable the loop while teleporting
    end
    
    rootPart.CFrame = CFrame.new(464, 151, 232)
    task.wait(0.5)
    
    local npc = Workspace:WaitForChild("world"):WaitForChild("npcs"):WaitForChild("Marc Merchant")
    local args = {
        {
            voice = 12,
            npc = npc,
            idle = npc:WaitForChild("description"):WaitForChild("idle")
        }
    }

    local sellAllEvent = ReplicatedStorage:WaitForChild("events"):WaitForChild("SellAll")
    sellAllEvent:InvokeServer(unpack(args))
    task.wait(0.5)
    sellAllEvent:FireServer(unpack(args))

    task.wait(3)

    rootPart.CFrame = currentPosition

    if wasFreezeCharActive then
        FreezeChar = true
        -- The FreezeCharacter toggle's callback (now running in task.spawn) will restart the position-locking
    end
end

function SellFishAndReturnOne()
    local rootPart = getHRP()
    if not rootPart then return end

    local currentPosition = rootPart.CFrame
    local wasFreezeCharActive = FreezeChar
    if wasFreezeCharActive then
        FreezeChar = false
    end

    rootPart.CFrame = CFrame.new(464, 151, 232)
    task.wait(0.5)
    
    Workspace:WaitForChild("world"):WaitForChild("npcs"):WaitForChild("Marc Merchant"):WaitForChild("merchant"):WaitForChild("sell"):InvokeServer()
    task.wait(3)

    rootPart.CFrame = currentPosition

    if wasFreezeCharActive then
        FreezeChar = true
    end
end

local Tabs = {
    Main = Window:AddTab('Main'),
    Teleports = Window:AddTab('Teleports'),
    LocalPlayer = Window:AddTab('LocalPlayer'),
    ['UI Settings'] = Window:AddTab('UI Settings'),
}


local AutoCastGroup = Tabs.Main:AddLeftGroupbox('Auto Cast')
local AutoReelGroup = Tabs.Main:AddLeftGroupbox('Auto Reel')
local AutoShakeGroup = Tabs.Main:AddLeftGroupbox('Auto Shake')
local FishUtilitiesGroup = Tabs.Main:AddRightGroupbox('Fish Utilities')

-- Auto Cast
AutoCastGroup:AddToggle('AutoCast', {
    Text = 'Enabled',
    Default = false,
    Tooltip = 'Automatically throws the rod',
    Callback = function(Value)
        autoCast = Value
        if Value then StartAutoCast() end
    end
})

AutoCastGroup:AddDropdown('AutoCastMode', {
    Text = 'Auto Cast Mode',
    Tooltip = 'Change the mode of the AutoCast',
    Values = {'Legit', 'Rage'},
    Default = autoCastMode,
  
    Callback = function(Value)
        autoCastMode = Value
    end
})


AutoCastGroup:AddSlider('AutoCastDelay', {
    Text = 'Auto-Cast Delay (seconds)',
    Default = 2,
    Min = 0.1,
    Max = 10,
    Rounding = 1,

    Callback = function(Value)
        autoCastDelay = Value
    end
})

-- Auto Reel (UPDATED)
AutoReelGroup:AddToggle('AutoReel', {
    Text = 'Enabled',
    Default = false,
    Tooltip = 'Automatically reels in the fishing rod instantly (Rage Reel)',
    Callback = function(Value)
        autoReel = Value
        if Value then StartAutoReel() end
    end
})

AutoReelGroup:AddDropdown('CatchMethod', {
    Text = 'Catch Method',
    Tooltip = 'Select the catch success state for Instant Reel',
    Values = {'Perfect', 'Random'},
    Default = autoCatchMethod,
    Callback = function(Value)
        autoCatchMethod = Value
    end
})

-- Auto Shake
AutoShakeGroup:AddToggle('AutoShake', {
    Text = 'Enabled',
    Default = false,
    Tooltip = 'Auto shaking the shake button',
    Callback = function(Value)
        autoShake = Value
        if Value then StartAutoShake() end
    end
})

AutoShakeGroup:AddLabel('Rage Shake')

-- Fish Utilities
local SellButton = FishUtilitiesGroup:AddButton({
    Text = 'Sell a fish',
    Func = function()
        SellFishAndReturnOne()
    end,
    DoubleClick = false,
    Tooltip = 'Sells the fish you are holding'
})

local SellAllSButton = FishUtilitiesGroup:AddButton({
    Text = "Sell All fish",
    Func = function()
        SellFishAndReturnAll()
    end,
    DoubleClick = false,
    Tooltip = "Sells all your fish"
})

local SellAllButton = FishUtilitiesGroup:AddButton({
    Text = 'Appraise fish (450C$)',
    Func = function()
        Workspace:WaitForChild("world"):WaitForChild("npcs"):WaitForChild("Appraiser"):WaitForChild("appraiser"):WaitForChild("appraise"):InvokeServer()
    end,
    DoubleClick = false,
    Tooltip = 'Appraises the fish you are holding'
})


local teleportSpots = {}

local racistPeople = { --[[ all racist people abandoned :pensive: ]] }

local itemSpots = {
    Training_Rod = CFrame.new(457.693848, 148.357529, 230.414307, 1, -0, 0, 0, 0.975410998, 0.220393807, -0, -0.220393807, 0.975410998),
    Plastic_Rod = CFrame.new(454.425385, 148.169739, 229.172424, 0.951755166, 0.0709736273, -0.298537821, -3.42726707e-07, 0.972884834, 0.231290117, 0.306858391, -0.220131472, 0.925948203),
    Lucky_Rod = CFrame.new(446.085999, 148.253006, 222.160004, 0.974526405, -0.22305499, 0.0233404674, 0.196993902, 0.901088715, 0.386306256, -0.107199371, -0.371867687, 0.922075212),
    Kings_Rod = CFrame.new(1375.57642, -810.201721, -303.509247, -0.7490201, 0.662445903, -0.0116144121, -0.0837960541, -0.0773290396, 0.993478119, 0.657227278, 0.745108068, 0.113431036),
    Flimsy_Rod = CFrame.new(471.107697, 148.36171, 229.642441, 0.841614008, 0.0774728209, -0.534493923, 0.00678436086, 0.988063335, 0.153898612, 0.540036798, -0.13314943, 0.831042409),
    Nocturnal_Rod = CFrame.new(-141.874237, -515.313538, 1139.04529, 0.161644459, -0.98684907, 1.87754631e-05, 1.87754631e-05, 2.21133232e-05, 1, -0.98684907, -0.161644459, 2.21133232e-05),
    Fast_Rod = CFrame.new(447.183563, 148.225739, 220.187454, 0.981104493, 1.26492232e-05, 0.193478703, -0.0522461236, 0.962867677, 0.264870107, -0.186291039, -0.269973755, 0.944674432),
    Carbon_Rod = CFrame.new(454.083618, 150.590073, 225.328827, 0.985374212, -0.170404434, 1.41561031e-07, 1.41561031e-07, 1.7285347e-06, 1, -0.170404434, -0.985374212, 1.7285347e-06),
    Long_Rod = CFrame.new(485.695038, 171.656326, 145.746109, -0.630167365, -0.776459217, -5.33461571e-06, 5.33461571e-06, -1.12056732e-05, 1, -0.776459217, 0.630167365, 1.12056732e-05),
    Mythical_Rod = CFrame.new(389.716705, 132.588821, 314.042847, 0, 1, 0, 0, 0, -1, -1, 0, 0),
    Midas_Rod = CFrame.new(401.981659, 133.258316, 326.325745, 0.16456604, 0.986365497, 0.00103566051, 0.00017541647, 0.00102066994, -0.999999464, -0.986366034, 0.1645661, -5.00679016e-06),
    Trident_Rod = CFrame.new(-1484.34192, -222.325562, -2194.77002, -0.466092706, -0.536795318, 0.703284025, -0.319611132, 0.843386114, 0.43191275, -0.824988723, -0.0234660208, -0.56466186),
    Enchated_Altar = CFrame.new(1310.54651, -799.469604, -82.7303467, 0.999973059, 0, 0.00733732153, 0, 1, 0, -0.00733732153, 0, 0.999973059),
    Bait_Crate = CFrame.new(384.57513427734375, 135.3519287109375, 337.5340270996094),
    Quality_Bait_Crate = CFrame.new(-177.876, 144.472, 1932.844),
    Crab_Cage = CFrame.new(474.803589, 149.664566, 229.49469, -0.721874595, 0, 0.692023814, 0, 1, 0, -0.692023814, 0, -0.721874595),
    GPS = CFrame.new(517.896729, 149.217636, 284.856842, 7.39097595e-06, -0.719539165, -0.694451928, -1, -7.39097595e-06, -3.01003456e-06, -3.01003456e-06, 0.694451928, -0.719539165),
    Basic_Diving_Gear = CFrame.new(369.174774, 132.508835, 248.705368, 0.228398502, -0.158300221, -0.96061182, 1.58026814e-05, 0.986692965, -0.162594408, 0.973567724, 0.037121132, 0.225361705),
    Fish_Radar = CFrame.new(365.75177, 134.50499, 274.105804, 0.704499543, -0.111681774, -0.70086211, 1.32396817e-05, 0.987542748, -0.157350808, 0.709704578, 0.110844307, 0.695724905)
}

local fisktable = {}

for i, v in pairs(TpSpotsFolder:GetChildren()) do
    if table.find(teleportSpots, v.Name) == nil then
        table.insert(teleportSpots, v.Name)
    end
end

for i, v in pairs(NpcFolder:GetChildren()) do
    if table.find(racistPeople, v.Name) == nil and v.Name ~= "mirror Area" then
        table.insert(racistPeople, v.Name)
    end
end

NpcFolder.ChildAdded:Connect(function(child)
    if table.find(racistPeople, child.Name) == nil and child.Name ~= "mirror Area" then
        table.insert(racistPeople, child.Name)
    end
end)
--tp
local TeleportsGroup = Tabs.Teleports:AddLeftGroupbox('Teleports')

TeleportsGroup:AddDropdown('PlaceTeleport', {
    Text = 'Place teleport',
    Tooltip = 'Teleport to a place',
    Values = teleportSpots,
    Default = '',
  
    Callback = function(Value)
        local hrp = getHRP()
        if teleportSpots ~= nil and hrp ~= nil then
            hrp.CFrame = TpSpotsFolder:FindFirstChild(Value).CFrame + Vector3.new(0, 5, 0)
        end
    end
})

TeleportsGroup:AddDropdown('NPCTeleport', {
    Text = 'Teleport to Npc',
    Tooltip = 'Teleport to a rod',
    Values = racistPeople,
    Default = '',
  
    Callback = function(Value)
        local hrp = getHRP()
        local npc = NpcFolder:FindFirstChild(Value)
        if racistPeople ~= nil and hrp ~= nil and npc and npc:FindFirstChild("HumanoidRootPart") then
            hrp.CFrame = npc.HumanoidRootPart.CFrame + Vector3.new(0, 1, 0)
        end
    end
})

TeleportsGroup:AddDropdown('ItemTeleport', {
    Text = 'Teleport to item',
    Tooltip = 'Teleport to a rod',
    Values = {"Bait_Crate", "Carbon_Rod", "Crab_Cage", "Fast_Rod", "Nocturnal_Rod", "Flimsy_Rod", "GPS", "Long_Rod", "Lucky_Rod", "Plastic_Rod", "Training_Rod", "Kings_Rod", "Mythical_Rod", "Midas_Rod", "Trident_Rod", "Enchated_Altar", "Quality_Bait_Crate", "Basic_Diving_Gear", "Fish_Radar"},
    Default = '',
  
    Callback = function(Value)
        local hrp = getHRP()
        if itemSpots ~= nil and hrp ~= nil then
            hrp.CFrame = itemSpots[Value]
        end
    end
})
--localplayer stuff
local LocalPlayerGroup = Tabs.LocalPlayer:AddLeftGroupbox('LocalPlayer')

LocalPlayerGroup:AddToggle('AntiDrown', {
    Text = 'Disable Oxygen',
    Default = false,
    Tooltip = 'Allows you to stay in water infinitely',
    Callback = function(Value)
        AntiDrown = Value
        if Value == true then
            local CharAddedAntiDrownCon
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("client") and LocalPlayer.Character.client:WaitForChild("oxygen").Enabled == true then	
                LocalPlayer.Character.client.oxygen.Enabled = false	
            end	
            CharAddedAntiDrownCon = LocalPlayer.CharacterAdded:Connect(function(newChar)	
                local oxygen = newChar:FindFirstChild("client") and newChar.client:WaitForChild("oxygen")
                if oxygen and oxygen.Enabled == true and AntiDrown == true then	
                    oxygen.Enabled = false	
                end	
            end)
        end
    end
})

local FreezeCharacterGroup = Tabs.LocalPlayer:AddLeftGroupbox('Freeze Character')

FreezeCharacterGroup:AddToggle('FreezeCharacter', {
    Text = 'Enabled',
    Default = false,
    Tooltip = "Freezes your character in current location",
    Callback = function(Value)
        FreezeChar = Value
        local hrp = getHRP()
        if not hrp then return end

        local oldpos = hrp.CFrame

        task.spawn(function() -- Use task.spawn to prevent UI thread from blocking
            while FreezeChar do
                task.wait()
                local currentHRP = getHRP()
                if currentHRP then
                    currentHRP.CFrame = oldpos
                else
                    break
                end
            end
        end)
    end
})


local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')

-- I set NoUI so it does not show up in the keybinds menu
MenuGroup:AddButton('Unload', function() Library:Unload() end)
MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', { Default = 'K', NoUI = true, Text = 'Menu keybind' })

-- Start Auto-Farm Logic if enabled on load
if autoCast then StartAutoCast() end
if autoReel then StartAutoReel() end
if autoShake then StartAutoShake() end


local FrameTimer = tick()
local FrameCounter = 0;
local FPS = 60;

local WatermarkConnection = game:GetService('RunService').RenderStepped:Connect(function()
    FrameCounter += 1;

    if (tick() - FrameTimer) >= 1 then
        FPS = FrameCounter;
        FrameTimer = tick();
        FrameCounter = 0;
    end;

    Library:SetWatermark(('Cherry Hub V1.0.0 | %s fps | %s ms | Game: Fisch'):format(
        math.floor(FPS),
        math.floor(game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue())
    ));
end);

Library.ToggleKeybind = Options.MenuKeybind 

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })
ThemeManager:SetFolder('MyScriptHub')
SaveManager:SetFolder('MyScriptHub/specific-game')
SaveManager:BuildConfigSection(Tabs['UI Settings'])
ThemeManager:ApplyToTab(Tabs['UI Settings'])
SaveManager:LoadAutoloadConfig()
