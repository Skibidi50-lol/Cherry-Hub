local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Backpack = LocalPlayer:WaitForChild("Backpack")

local AutoCollect = false
local AutoHit = false
local autoClicking = false
local AutoCollectDelay = 5
local ClickInterval = 0.2
local AutoEB = false
local AutoEBRunning = false
local SellPlant = false
local SellBrainrot = false

local HeldToolName = {
    "Basic Bat",
    "Leather Grip Bat",
    "Iron Plate Bat",
    "Iron Core Bat",
    "Aluminum Bat"
}

local serverStartTime = os.time()

local shop = {
    seedList = {
        "Cactus Seed",
        "Strawberry Seed",
        "Pumpkin Seed",
        "Sunflower Seed",
        "Dragon Fruit Seed",
        "Eggplant Seed",
        "Watermelon Seed",
        "Grape Seed",
        "Cocotank Seed",
        "Carnivorous Plant Seed",
        "Mr Carrot Seed",
        "Tomatrio Seed",
        "Shroombino Seed",
        "Mango Seed"
    },

    gearList = {
        "Water Bucket",
        "Frost Grenade",
        "Banana Gun",
        "Frost Blower",
        "Carrot Launcher"
    },
    PlatformList = {
        "1","2","3","4","5",
        "6","7","8","9","10",
        "11","12","13","14",
        "15","16","17"
    }
}
--Buyed thangi boiiiii:joy:
local selectedSeeds = {}
local selectedGears = {}
local selectedPlatform = {}

local AutoBuyAllSeed = false
local AutoBuyAllGear = false
local AutoBuyPlatformAll = false

local AutoBuySelectedGear = false
local AutoBuySelectedSeed = false
local AutoBuyPlatformSelect = false

-- helper
local function GetMyPlot()
    for _, plot in ipairs(Workspace.Plots:GetChildren()) do
        local playerSign = plot:FindFirstChild("PlayerSign")
        if playerSign then
            local bg = playerSign:FindFirstChild("BillboardGui")
            local textLabel = bg and bg:FindFirstChild("TextLabel")
            if textLabel and (textLabel.Text == LocalPlayer.Name or textLabel.Text == LocalPlayer.DisplayName) then
                return plot
            end
        end
    end
    return nil
end

local function GetMyPlotName()
    local plot = GetMyPlot()
    return plot and plot.Name or "No Plot"
end

local function GetMoney()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    return leaderstats and leaderstats:FindFirstChild("Money") and leaderstats.Money.Value or 0
end

local function GetRebirth()
    local gui = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("Main")
    if gui and gui:FindFirstChild("Rebirth") then
        local text = gui.Rebirth.Frame.Title.Text or "Rebirth 0"
        local n = tonumber(text:match("%d+")) or 0
        return math.max(0, n - 1)
    end
    return 0
end

local function FormatTime(sec)
    local h = math.floor(sec / 3600)
    local m = math.floor((sec % 3600) / 60)
    local s = sec % 60
    return string.format("%02d:%02d:%02d", h, m, s)
end

-- safe remote getters
local function GetBridgeNet2()
    return ReplicatedStorage:FindFirstChild("BridgeNet2")
end

local function GetRemotesFolder()
    return ReplicatedStorage:FindFirstChild("Remotes")
end

--Auto hit func
local BrainrotsCache = {}

local function UpdateBrainrotsCache()
    local ok, folder = pcall(function()
        return Workspace:WaitForChild("ScriptedMap"):WaitForChild("Brainrots")
    end)
    if not ok or not folder then return end
    BrainrotsCache = {}
    for _, b in ipairs(folder:GetChildren()) do
        if b:FindFirstChild("BrainrotHitbox") then
            table.insert(BrainrotsCache, b)
        end
    end
end

local function GetNearestBrainrot()
    local nearest = nil
    local minDist = math.huge
    for _, b in ipairs(BrainrotsCache) do
        local hitbox = b:FindFirstChild("BrainrotHitbox")
        if hitbox then
            local dist = (HumanoidRootPart.Position - hitbox.Position).Magnitude
            if dist < minDist then
                minDist = dist
                nearest = b
            end
        end
    end
    return nearest
end

-- utility 
-- utility 
local function GetEquippedBat()
    for _, name in ipairs(HeldToolName) do
        local tool = Character:FindFirstChild(name)
        if tool then return tool end
    end
    return nil
end

local function GetBackpackBat()
    for _, name in ipairs(HeldToolName) do
        local tool = Backpack:FindFirstChild(name)
        if tool then return tool end
    end
    return nil
end

local function EquipBat()
    local bat = GetBackpackBat()
    if bat then
        bat.Parent = Character
    end
end

local function InstantWarpToBrainrot(brainrot)
    local hitbox = brainrot and brainrot:FindFirstChild("BrainrotHitbox")
    if hitbox then
        local offset = Vector3.new(0, 0.69, 2.5)
        HumanoidRootPart.CFrame = CFrame.new(hitbox.Position + offset, hitbox.Position)
    end
end

-- auto clicker
local function DoClick()
    pcall(function()
        VirtualUser:Button1Down(Vector2.new(0, 0))
        task.wait(0.03)
        VirtualUser:Button1Up(Vector2.new(0, 0))
    end)
end


local Window = Rayfield:CreateWindow({
   Name = "Cherry Hub - Plants Vs Brainrots",
   Icon = 0, -- Icon in Topbar. Can use Lucide Icons (string) or Roblox Image (number). 0 to use no icon (default).
   LoadingTitle = "Loading...",
   LoadingSubtitle = "by Cherry",
   ShowText = "Rayfield", -- for mobile users to unhide rayfield, change if you'd like
   Theme = "DarkBlue", -- Check https://docs.sirius.menu/rayfield/configuration/themes

   ToggleUIKeybind = "K", -- The keybind to toggle the UI visibility (string like "K" or Enum.KeyCode)

   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false, -- Prevents Rayfield from warning when the script has a version mismatch with the interface

   ConfigurationSaving = {
      Enabled = true,
      FolderName = nil, -- Create a custom folder for your hub/game
      FileName = "Big Hub"
   },

   Discord = {
      Enabled = false, -- Prompt the user to join your Discord server if their executor supports it
      Invite = "noinvitelink", -- The Discord invite code, do not include discord.gg/. E.g. discord.gg/ ABCD would be ABCD
      RememberJoins = true -- Set this to false to make them join the discord every time they load it up
   },

   KeySystem = false, -- Set this to true to use our key system
   KeySettings = {
      Title = "Untitled",
      Subtitle = "Key System",
      Note = "No method of obtaining the key is provided", -- Use this to tell the user how to get a key
      FileName = "Key", -- It is recommended to use something unique as other scripts using Rayfield may overwrite your key file
      SaveKey = true, -- The user's key will be saved, but if you change the key, they will be unable to use your script
      GrabKeyFromSite = false, -- If this is true, set Key below to the RAW site you would like Rayfield to get the key from
      Key = {"Hello"} -- List of keys that will be accepted by the system, can be RAW file links (pastebin, github etc) or simple strings ("hello","key22")
   }
})
--Tabs
local Upd = Window:CreateTab("Update", "list")
local Main = Window:CreateTab("Main", "blinds")
local Items = Window:CreateTab("Items", "drill")
local Shop = Window:CreateTab("Shop", "shopping-cart")
local Selling = Window:CreateTab("Selling", "dollar-sign")
local Misc = Window:CreateTab("Misc", "crown")
--Upd
local Section = Upd:CreateSection("Updates")
local Paragraph = Upd:CreateParagraph({Title = "V1.2.0", Content = "[🟩] - Duping (Visual Only)\n[🟩] - Items Tab (Nothing Here RN)"})
--Main
local Section = Main:CreateSection("Auto Hit")

local Toggle = Main:CreateToggle({
   Name = "Auto Hit",
   CurrentValue = false,
   Flag = "Autohit",
   Callback = function(Value)
    AutoHit = Value
    autoClicking = Value
    if Value then
        EquipBat()
        UpdateBrainrotsCache()

        -- AUTO CLICKER
        task.spawn(function()
            while autoClicking do
                if GetEquippedBat() then
                    DoClick()
                end
                task.wait(ClickInterval)
            end
        end)

        -- AUTO EQUIP
        task.spawn(function()
            while AutoHit do
                if not GetEquippedBat() then
                    EquipBat()
                end
                task.wait(0.5)
            end
        end)

        -- BRAINROTS CACHE REFRESH
        task.spawn(function()
            while AutoHit do
                UpdateBrainrotsCache()
                task.wait(1)
            end
        end)

        -- AUTO HIT BRAINROT
        task.spawn(function()
            while AutoHit do
                local currentTarget = GetNearestBrainrot()
                if currentTarget and currentTarget:FindFirstChild("BrainrotHitbox") then
                    InstantWarpToBrainrot(currentTarget)
                    pcall(function()
                        local remotes = GetRemotesFolder()
                        if remotes and remotes:FindFirstChild("AttacksServer") and remotes.AttacksServer:FindFirstChild("WeaponAttack") then
                            remotes.AttacksServer.WeaponAttack:FireServer({ { target = currentTarget.BrainrotHitbox } })
                        else
                            ReplicatedStorage.Remotes.AttacksServer.WeaponAttack:FireServer({ { target = currentTarget.BrainrotHitbox } })
                        end
                    end)
                end
                task.wait(ClickInterval)
            end
        end)

    else
        autoClicking = false
    end
   end,
})

local Slider = Main:CreateSlider({
   Name = "Auto Hit Delay",
   Range = {0.1, 1},
   Increment = 0.1,
   Suffix = "Seconds",
   CurrentValue = 0.2,
   Flag = "DelaySlider",
   Callback = function(Value)
       ClickInterval = Value
   end,
})

local Paragraph = Main:CreateParagraph({Title = "WARNING", Content = "USE THIS ONLY ON PRIVATE SERVER ONLY OR YOU WILL BE BANNED"})

local Range = 20
local Cooldown = 0.05
local autoAttack = false


local Section = Main:CreateSection("Kill Aura")

local Button = Main:CreateButton({
   Name = "Load Kill Aura (Keybind is T) (PC ONLY)",
   Callback = function()



local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local Event = RS.Remotes.AttacksServer.WeaponAttack

local Char = Player.Character or Player.CharacterAdded:Wait()
local HRP = Char:WaitForChild("HumanoidRootPart")

Player.CharacterAdded:Connect(function(c)
    Char = c
    HRP = c:WaitForChild("HumanoidRootPart")
end)

UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.T then
        autoAttack = not autoAttack
        game.StarterGui:SetCore("SendNotification", {
            Title = "Kill Aura",
            Text = autoAttack and "On" or "Off",
            Duration = 2
        })
    end
end)

task.spawn(function()
    while task.wait(Cooldown) do
        if autoAttack and HRP then
            local targets = {}
            for _, mob in ipairs(workspace.ScriptedMap.Brainrots:GetChildren()) do
                local pp = mob.PrimaryPart or mob:FindFirstChild("HumanoidRootPart")
                if pp and (pp.Position - HRP.Position).Magnitude <= Range then
                    table.insert(targets, mob.Name)
                end
            end
            if #targets > 0 then
                Event:FireServer(targets)
            end
        end
    end
end)

end
})

local Slider = Main:CreateSlider({
   Name = "Kill Aura Delay",
   Range = {0.05, 1},
   Increment = 0.05,
   Suffix = "Seconds",
   CurrentValue = 0.05,
   Flag = "DelaySliderV2",
   Callback = function(Value)
       Cooldown = Value
   end,
})


local Section = Main:CreateSection("Auto Collect Money")
--Auto Collect
local function GetNearestPlot()
    local nearestPlot = nil
    local minDist = math.huge
    for _, plot in ipairs(Workspace.Plots:GetChildren()) do
        if plot:IsA("Folder") then
            local center = plot:FindFirstChild("Center") or plot:FindFirstChildWhichIsA("BasePart")
            if center then
                local dist = (HumanoidRootPart.Position - center.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    nearestPlot = plot
                end
            end
        end
    end
    return nearestPlot
end

local function CollectFromPlot(plot)
    if not plot then return end
    local brainrotsFolder = plot:FindFirstChild("Brainrots")
    if not brainrotsFolder then return end

    for i = 1, 17 do
        local slot = brainrotsFolder:FindFirstChild(tostring(i))
        if slot and slot:FindFirstChild("Brainrot") then
            local brainrot = slot:FindFirstChild("Brainrot")
            if brainrot:FindFirstChild("BrainrotHitbox") then
                local hitbox = brainrot.BrainrotHitbox
                local offset = Vector3.new(0, 1, 3)
                HumanoidRootPart.CFrame = CFrame.new(hitbox.Position + offset, hitbox.Position)
                task.wait(0.2)
                pcall(function()
                    local remotes = GetRemotesFolder()
                    if remotes and remotes:FindFirstChild("AttacksServer") and remotes.AttacksServer:FindFirstChild("WeaponAttack") then
                        remotes.AttacksServer.WeaponAttack:FireServer({ { target = hitbox } })
                    else
                        ReplicatedStorage.Remotes.AttacksServer.WeaponAttack:FireServer({ { target = hitbox } })
                    end
                end)
            end
        end
    end
end


local Toggle = Main:CreateToggle({
   Name = "Auto Collect Money",
   CurrentValue = false,
   Flag = "Autocollectmoney",
   Callback = function(Value)
    AutoCollect = Value
        if Value then
            task.spawn(function()
                while AutoCollect do
                    local nearestPlot = GetNearestPlot()
                    if nearestPlot then
                        CollectFromPlot(nearestPlot)
                    end
                    task.wait(AutoCollectDelay)
                end
            end)
        end
   end
})

local Slider = Main:CreateSlider({
   Name = "Auto Collect Delay",
   Range = {1, 60},
   Increment = 1,
   Suffix = "Seconds",
   CurrentValue = 5,
   Flag = "DelaySlider2",
   Callback = function(Value)
        AutoCollectDelay = Value
   end,
})

local Paragraph = Main:CreateParagraph({Title = "WARNING", Content = "USE THIS ONLY ON PRIVATE SERVER ONLY OR YOU WILL BE BANNED"})

local Section = Main:CreateSection("Equip Best Brainrot")

local Button = Main:CreateButton({
   Name = "Equip Best Brainrot",
   Callback = function()
      game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("EquipBestBrainrots"):FireServer()
   end,
})

local Toggle = Main:CreateToggle({
   Name = "Auto Equip Best Brainrot",
   CurrentValue = false,
   Flag = "AutoEB",
   Callback = function(Value)
    AutoEB = Value
        while AutoEB do
            game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("EquipBestBrainrots"):FireServer()
            task.wait(3.5)
        end
   end
})
--Items
local Section = Items:CreateSection("Soon Skid")

--shop
local Section = Shop:CreateSection("Auto Buy Seeds")

local Dropdown = Shop:CreateDropdown({
   Name = "Select Seeds",
   Options = shop.seedList,
   CurrentOption = nil,
   MultipleOptions = true,
   Flag = "SeedDropdown",
   Callback = function(Options)
      selectedSeeds = Options
   end,
})

local Toggle = Shop:CreateToggle({
   Name = "Auto Buy Seeds",
   CurrentValue = false,
   Flag = "AutoBSeed",
   Callback = function(Value)
      AutoBuySelectedSeed = Value
        if Value then
            task.spawn(function()
                while AutoBuySelectedSeed do
                    if #selectedSeeds > 0 then
                        for _, seed in ipairs(selectedSeeds) do
                            if not AutoBuySelectedSeed then break end
                            local BuySeedRemote = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("BuyItem")
                            BuySeedRemote:FireServer(seed)
                            task.wait(0.3)
                        end
                    end
                    task.wait(0.1)
                end
            end)
        end
   end
})

local Section = Shop:CreateSection("Auto Buy Gear")

local Dropdown = Shop:CreateDropdown({
   Name = "Select Gear",
   Options = shop.gearList,
   CurrentOption = nil,
   MultipleOptions = true,
   Flag = "GearDropdown",
   Callback = function(Options)
      selectedGears = Options
   end,
})

local Toggle = Shop:CreateToggle({
   Name = "Auto Buy Gear",
   CurrentValue = false,
   Flag = "AutoBGear",
   Callback = function(Value)
      AutoBuySelectedGear = Value
        if Value then
            task.spawn(function()
                while AutoBuySelectedGear do
                    for _, gear in ipairs(shop.gearList) do
                        if not AutoBuySelectedGear then break end
                        local BuyGearRemote = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("BuyGear")
                        BuyGearRemote:FireServer(gear)
                        task.wait(0.3)
                    end
                    task.wait(0.1)
                end
            end)
        end
   end
})

local Section = Shop:CreateSection("Auto Buy Platform")

local Dropdown = Shop:CreateDropdown({
   Name = "Select Platform",
   Options = shop.PlatformList,
   CurrentOption = nil,
   MultipleOptions = true,
   Flag = "Dropdown",
   Callback = function(Options)
      selectedPlatform = Options
   end,
})

local Toggle = Shop:CreateToggle({
   Name = "Auto Buy Platform",
   CurrentValue = false,
   Flag = "AutoBplatf",
   Callback = function(Value)
      AutoBuyPlatformSelect = Value
        if Value and #selectedPlatform > 0 then
            task.spawn(function()
                while state do
                    for _, platform in ipairs(selectedPlatform) do
                        local BuyPlatformRemote = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("BuyPlatform")
                        BuyPlatformRemote:FireServer(platform)
                        task.wait(0.3)
                    end
                    task.wait(0.1)
                end
            end)
        end
   end
})

local Section = Shop:CreateSection("GUI")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local OpenUI = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("OpenUI")

local player = Players.LocalPlayer
local SeedsGUI = player:WaitForChild("PlayerGui"):WaitForChild("Main"):WaitForChild("Seeds")
local GearsGUI = player:WaitForChild("PlayerGui"):WaitForChild("Main"):WaitForChild("Gears")

local Button = Shop:CreateButton({
   Name = "Show Seeds GUI",
   Callback = function()
        pcall(function()
            OpenUI:Fire(SeedsGUI, true)
            Rayfield:Notify({
                Title = "GUI",
                Content = "Successfully open Seeds GUI",
                Duration = 4,
                Image = 4483362458,
            })
        end)
   end,
})

local Button = Shop:CreateButton({
   Name = "Show Gears GUI",
   Callback = function()
        pcall(function()
            OpenUI:Fire(GearsGUI, true)
            Rayfield:Notify({
                Title = "GUI",
                Content = "Successfully open Gears GUI",
                Duration = 4,
                Image = 4483362458,
            })
        end)
   end,
})

--Selling
local Section = Selling:CreateSection("Selling")

local Toggle = Selling:CreateToggle({
   Name = "Auto Sell Brainrots (All)",
   CurrentValue = false,
   Flag = "Autosbrainrot",
   Callback = function(Value)
      SellBrainrot = Value
   end
})

local Toggle = Selling:CreateToggle({
   Name = "Auto Sell Plants (All)",
   CurrentValue = false,
   Flag = "Autosplant",
   Callback = function(Value)
      SellPlant = Value
   end
})

task.spawn(function()
    while task.wait(0.69) do
        if SellBrainrot or SellPlant then
            local remotes = GetRemotesFolder()
            if remotes and remotes:FindFirstChild("ItemSell") then
                pcall(function() remotes.ItemSell:FireServer() end)
            else
                pcall(function() ReplicatedStorage.Remotes.ItemSell:FireServer() end)
            end
        end
    end
end)

AntiAFKEnabled = false

local Section = Misc:CreateSection("Misc Settings")

local Toggle = Misc:CreateToggle({
   Name = "Anti Afk",
   CurrentValue = false,
   Flag = "AntiAFK",
   Callback = function(Value)
      AntiAFKEnabled = Value
        if Value then
            local conn
            conn = Players.LocalPlayer.Idled:Connect(function()
                if AntiAFKEnabled then
                    VirtualUser:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
                    task.wait(0.1)
                    VirtualUser:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
                else
                    conn:Disconnect()
                end
            end)
        end
   end
})

local Button = Misc:CreateButton({
   Name = "FPS Boost",
   Callback = function()
      loadstring(game:HttpGet("https://raw.githubusercontent.com/dyumra/DYHUB-Universal-Game/refs/heads/main/Nigga.lua"))()
   end,
})

local Section = Misc:CreateSection("Cherry Special")

local Button = Misc:CreateButton({
   Name = "Duping (Visual)",
   Callback = function()
      local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Turtle-Brand/Turtle-Lib/main/source.lua"))()
      local window = library:Window("Cherry - Duping PVSB")

            local function cloneHeldTool()
            local char = player.Character
            if not char then return end

            local tool = nil
            for _, item in ipairs(char:GetChildren()) do
                if item:IsA("Tool") then
                    tool = item
                    break
                end
            end

            if not tool then
                    game:GetService("StarterGui"):SetCore("SendNotification",{
                        Title = "Cherry Duping",
                        Text = "Hold Tools First!",
                    })
                return
            end

            local fake = tool:Clone()

            for _,desc in ipairs(fake:GetDescendants()) do
                if desc:IsA("Script") or desc:IsA("LocalScript") then
                    desc:Destroy()
                end
            end
            fake.Parent = Backpack 

            game:GetService("StarterGui"):SetCore("SendNotification",{
                Title = "Cherry Duping",
                Text = "Duped!",
            })
        end

        window:Button("Start Duping", function()
            cloneHeldTool()
        end)

        window:Label("Hold Tool To Dupe", Color3.fromRGB(127, 143, 166))
        window:Label("CHERRY HUB", Color3.fromRGB(327, 343, 366))
   end,
})

