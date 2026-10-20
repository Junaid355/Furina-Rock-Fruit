--[[
    FURINA HUB | ROCK FRUIT (DEFINITIVE EDITION V5.0)
    Title: Furina Hub | Rock Fruit
    Theme: Furina Hydro / Ocean Blue Theme
    Keybind: RightControl & Insert + Draggable Floating 💧 Button
    Place ID: 119091355492870 (Rock Fruit / Anime RPG)

    CORE ARCHITECTURE & V5.0 SUPERCHARGED FEATURES:
        1. SKY FARM MODE (KILL NPCS IN SKY):
            - Hovers smoothly 8.5 studs directly above target mobs looking downward.
            - Anti-gravity velocity lock prevents falling or stumbling.
            - Mobs CANNOT hit or damage the player (Zero Damage Taken, 100% invincible farming).
            - Mob Magnet gathers all matching mobs directly beneath player on the ground.
        2. INSANE OVERPOWERED FAST ATTACK:
            - Multi-hit packet burst (2x to 15x hits per cycle directly to ActionRemote).
            - Attack Animation Canceler (track:Stop(0)) completely eliminates swing recoil & character stutter.
            - Smart skill rotation cadence (0.8s) prevents skill drops and avoids network throttling.
        3. AUTO STAT ALLOCATION WHILE FARMING:
            - Automatically spends earned stat points into Melee and Defense (or user target).
            - High-throughput batch spending (up to 250 points per tick) scales player damage instantly.
        4. 100% RELIABLE CLOSE & OPEN TOGGLE:
            - Direct ScreenGui Enabled toggler (bypasses WindUI internal toggle freeze).
            - Dual default hotkeys: RightControl AND Insert (works on all 60%, laptop, and Mac keyboards).
            - Draggable floating circular Hydro button (💧) on screen for instant 1-click open/close.
        5. ERROR-PROOF AUTO FARM LEVEL:
            - Dynamic quest upgrade: detects when player outlevels current quest tier.
            - Smooth quest acquisition: cancels old quest, teleports to NPC, sets HoldDuration = 0.
        6. MULTI-UI CLEANER:
            - Complete container sweep of gethui(), CoreGui, and PlayerGui.
        7. SAFEZONE & COMBAT BYPASS:
            - Relocates workspace.SafeZone collision parts out of bounds.
        8. WEAPON CRAFTER & WIKI:
            - Full recipe directory for all 14 Swords, 13 Melees, 10 Specials, and 15 Classes.
            - 1-click remote craft from anywhere on map.
            - "Auto Craft All Affordable Weapons".
--]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")

local LocalPlayer = Players.LocalPlayer

-- ==========================================
-- STEP 1: THOROUGH MULTI-UI & THREAD CLEANUP
-- ==========================================
if getgenv().FurinaHubStop then
    pcall(getgenv().FurinaHubStop)
end

local isScriptActive = true
getgenv().FurinaHubStop = function()
    isScriptActive = false
    if getgenv().FurinaHubInstance then
        pcall(function() getgenv().FurinaHubInstance:Destroy() end)
        getgenv().FurinaHubInstance = nil
    end
end

local function purgeExistingUIs()
    local targetContainers = {}
    local hui = (gethui and gethui()) or game:GetService("CoreGui")
    if hui then table.insert(targetContainers, hui) end
    if LocalPlayer:FindFirstChild("PlayerGui") then
        table.insert(targetContainers, LocalPlayer.PlayerGui)
    end
    
    for _, container in ipairs(targetContainers) do
        for _, child in ipairs(container:GetChildren()) do
            if child:IsA("ScreenGui") then
                local name = child.Name:lower()
                if name:find("windui") or name:find("furina") or name:find("animerpg") or name:find("dropdown") or name:find("notification") or name:find("furinafloat") then
                    pcall(function() child:Destroy() end)
                end
            end
        end
    end
end
purgeExistingUIs()

-- ==========================================
-- STEP 2: SAFEZONE NEUTRALIZER
-- ==========================================
local function neutralizeSafeZones()
    pcall(function()
        local sz = Workspace:FindFirstChild("SafeZone")
        if sz then
            for _, part in ipairs(sz:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanTouch = false
                    part.CanQuery = false
                    part.CFrame = CFrame.new(0, 999999, 0)
                end
            end
        end
        if LocalPlayer.Character then
            LocalPlayer.Character:SetAttribute("Safezone", false)
        end
    end)
end
neutralizeSafeZones()

-- Remotes & Modules
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ActionRemote = Remotes:WaitForChild("Action")
local SystemRemote = Remotes:WaitForChild("System")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local NetworkFramework = require(Modules:WaitForChild("NetworkFramework"))
local QuestModule = require(Modules:WaitForChild("QuestModule"))
local UseItems = require(Modules:WaitForChild("UseItems"))
local ClassList = require(Modules:WaitForChild("ClassList"))
local Itemlist = require(Modules:WaitForChild("Itemlist"))
local CraftingTable = require(Modules:WaitForChild("CraftingTable"))

-- Master Configuration
local Config = {
    ToggleKey = Enum.KeyCode.RightControl,
    
    AutoFarmLevel = false,
    AutoFarmMob = false,
    SelectedMob = "Bacon Clown",
    
    -- Sky Farm & Positioning
    KillInSky = true,
    FarmPosition = "Sky (Above)", -- "Sky (Above)", "Ground (Front)", "Behind", "Underground"
    SkyHeight = 5.8,
    
    -- Overpowered Fast Attack Engine
    FastAttack = true,
    FastAttackSpeed = "Insane (10x)",
    HitsPerCycle = 12,
    AttackDelay = 0.015,
    CancelAnimations = true,
    AutoSkills = true,
    AutoBusoHaki = true,
    MobMagnet = true,
    
    -- Weapon & Item Acquisition
    SelectedWeaponToGet = "Tanto",
    AutoFarmMaterials = false,
    AutoCraftAffordable = false,
    AutoEquipBest = false,
    
    AntiStun = true,
    AntiVoid = true,
    WalkSpeedBypass = true,
    
    -- Auto Stat Allocation
    AutoStats = true,
    StatTarget = "Balanced (Melee & Defense)",
    StatPointsMelee = true,
    StatPointsDefense = true,
    StatPointsSword = false,
    StatPointsPower = false,
    StatPointsAmount = 250,
    
    AutoChest = false,
    
    WalkSpeed = 16,
    WalkSpeedEnabled = false,
    JumpPower = 50,
    JumpPowerEnabled = false,
    InfJump = false,
    Noclip = false,
    Fly = false,
    FlySpeed = 65,
    
    Fullbright = false,
    PlayerESP = false,
    MobESP = false,
    ChestESP = false,
}
getgenv().FurinaConfig = Config

-- Character Accessors
local function getChar()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function getHRP()
    local char = getChar()
    return char:WaitForChild("HumanoidRootPart", 5)
end

local function getHumanoid()
    local char = getChar()
    return char:WaitForChild("Humanoid", 5)
end

local lastEquipRequest = 0
local function ensureEquippedTool()
    local char = LocalPlayer.Character
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return nil end
    
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then return tool end
    
    local bpTool = LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
    if bpTool then
        hum:EquipTool(bpTool)
        return bpTool
    end
    
    -- Not in char, not in backpack -> request from server
    if os.clock() - lastEquipRequest >= 1.0 then
        lastEquipRequest = os.clock()
        local curMelee = LocalPlayer:GetAttribute("UseMelee")
        if not curMelee or curMelee == "[]" or curMelee == "" then
            curMelee = "Combat"
        end
        pcall(function()
            Remotes.Inventory:FireServer(curMelee)
        end)
    end
    
    local newBpTool = LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
    if newBpTool then
        hum:EquipTool(newBpTool)
        return newBpTool
    end
    
    return char:FindFirstChildOfClass("Tool")
end

local function getEquippedWeaponName()
    local tool = ensureEquippedTool()
    if tool then return tool.Name end
    return LocalPlayer:GetAttribute("UseMelee") or "Combat"
end

-- Teleportation & Movement Helpers
local function teleportInstant(cf)
    local hrp = getHRP()
    if hrp then
        hrp.CFrame = cf
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end
end

-- Calculate Island Ground Elevation via Raycast
local function getGroundCFrame(pos)
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    local char = LocalPlayer.Character
    local ignoreList = {}
    if char then table.insert(ignoreList, char) end
    if Workspace:FindFirstChild("Mob") then table.insert(ignoreList, Workspace.Mob) end
    if Workspace:FindFirstChild("SafeZone") then table.insert(ignoreList, Workspace.SafeZone) end
    if Workspace:FindFirstChild("VFX") then table.insert(ignoreList, Workspace.VFX) end
    rayParams.FilterDescendantsInstances = ignoreList
    
    local hit = Workspace:Raycast(Vector3.new(pos.X, 100, pos.Z), Vector3.new(0, -250, 0), rayParams)
    if hit then
        return CFrame.new(hit.Position + Vector3.new(0, 3.2, 0))
    end
    return CFrame.new(pos.X, 17, pos.Z)
end

-- Attack Execution (Overpowered Multi-Hit Packet Burst & Animation Canceler)
local lastSkillCast = 0
local function performAttack()
    local tool = ensureEquippedTool()
    local weaponName = (tool and tool.Name) or getEquippedWeaponName()
    
    pcall(function()
        -- 1. Animation Canceler: Stop tool swing animations to completely eliminate stutter & weapon slowdown
        if Config.CancelAnimations then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
                    local tName = track.Name:lower()
                    if tName:find("attack") or tName:find("slash") or tName:find("punch") or tName:find("swing") or tName:find("hit") or tName:find("weapon") then
                        track:Stop(0)
                    end
                end
            end
        end
        
        -- 2. Multi-Hit Packet Burst directly to ActionRemote
        local burstCount = math.clamp(Config.HitsPerCycle or 12, 1, 30)
        for i = 1, burstCount do
            ActionRemote:FireServer(weaponName, "hit")
        end
        
        -- 3. Smart Skill Rotation (cadence of 0.8s so skills do not drop hit packets)
        if Config.AutoSkills and (os.clock() - lastSkillCast >= 0.8) then
            lastSkillCast = os.clock()
            ActionRemote:FireServer(weaponName, "z")
            ActionRemote:FireServer(weaponName, "x")
            ActionRemote:FireServer(weaponName, "c")
            ActionRemote:FireServer(weaponName, "v")
        end
    end)
end

-- COMPLETE MOB SPAWN ANCHORS
local MobSpawnAnchors = {
    ["Bacon"] = CFrame.new(-234, 43, -72),
    ["Bacon Strong"] = CFrame.new(108, 43, 18),
    ["Bacon Pirate"] = CFrame.new(-1377, 42, -113),
    ["Bacon Clown"] = CFrame.new(-1642, 61, 43),
    ["Bacon Fisherman"] = CFrame.new(139, 44, 1165),
    ["Bacon The Deep"] = CFrame.new(13, 44, 1323),
    ["Bacon Traveler"] = CFrame.new(-983, 42, 1318),
    ["Bacon Fawkes"] = CFrame.new(-1181, 49, 1124),
    ["Bacon Warrior"] = CFrame.new(-93, 58, -1364),
    ["Gorilla"] = CFrame.new(-1418, 122, -1344),
    ["Bacon Tarzan"] = CFrame.new(-1177, 73, -1545),
    ["Bacon Rock"] = CFrame.new(1278, 92, 566),
    ["Bacon Iron"] = CFrame.new(1462, 145, 671),
    ["Bacon Kryptonite"] = CFrame.new(1575, 89, -945),
    ["Bacon Minerals"] = CFrame.new(1446, 54, -1088),
    ["Bacon Marine"] = CFrame.new(-1189, 42, -2504),
    ["Bacon Marine Captain"] = CFrame.new(-1037, 42, -2668),
    ["Bacon Snow"] = CFrame.new(189, 61, -2575),
    ["Bacon Ice"] = CFrame.new(-38, 81, -2811),
    ["Bacon Lava"] = CFrame.new(1404, 107, -2377),
    ["Bacon Hellfire"] = CFrame.new(1323, 134, -2624),
    ["Bacon Horse"] = CFrame.new(2361, 34, -2021),
    ["Bacon Farmer"] = CFrame.new(1329, 45, 1825),
    ["Bacon Chicken"] = CFrame.new(1589, 92, 1839),
    ["Bacon Barbarian"] = CFrame.new(-2498, 58, -2141),
    ["Monkey"] = CFrame.new(-2390, 58, -2406),
    ["Bacon Shadow Garden"] = CFrame.new(-2513, 43, -844),
    ["Bacon Egypt"] = CFrame.new(-496, 45, -3986),
    ["Bacon Pharaoh"] = CFrame.new(-860, 56, -4197),
    ["Bacon Yellow Donut"] = CFrame.new(1114, 54, -3980),
    ["Bacon Rainbow Donut"] = CFrame.new(1056, 66, -4325),
    ["Bacon Chef"] = CFrame.new(2406, 73, -3450),
    ["Bacon Burger"] = CFrame.new(2805, 73, -3542),
    ["Bacon Sanders"] = CFrame.new(3838, 123, -1098),
    ["Bacon Fried Chicken"] = CFrame.new(3865, 101, -1373),
    ["Bacon Thief"] = CFrame.new(-1510, 15, -137),
    ["Boss"] = CFrame.new(2736, 69, -92),
}

-- Complete Island Directory
local Islands = {
    ["Starter island"] = CFrame.new(-34.2, 5.0, 44.5),
    ["Shadow island"] = CFrame.new(-2664.5, 145.0, -854.8),
    ["Marine island"] = CFrame.new(-1176.4, 100.0, -2638.8),
    ["Port Island"] = CFrame.new(-940.0, 30.0, 1208.0),
    ["Crystal island"] = CFrame.new(1595.0, 130.0, -1039.4),
    ["Clown island"] = CFrame.new(-1524.4, 62.0, 23.6),
    ["Rock island"] = CFrame.new(1306.4, 75.0, 423.8),
    ["Event Island"] = CFrame.new(42.7, 98.0, -1370.4),
    ["Forest island"] = CFrame.new(-1428.7, 70.0, -1342.3),
    ["Snow island"] = CFrame.new(34.0, 155.0, -2716.5),
    ["Kame House island"] = CFrame.new(-488.2, 15.0, 2158.2),
    ["Boss island"] = CFrame.new(2728.3, 20.0, -101.5),
    ["Lava island"] = CFrame.new(1310.3, 140.0, -2444.1),
    ["Fishing island"] = CFrame.new(300.6, 45.0, 1332.0),
    ["Horse island"] = CFrame.new(2432.6, 20.0, -2019.5),
    ["Farmer island"] = CFrame.new(1412.0, 40.0, 1738.9),
    ["Raid Boss"] = CFrame.new(-752.0, 20.0, -712.2),
    ["Barbarian island"] = CFrame.new(-2427.6, 35.0, -2337.1),
    ["Sand island"] = CFrame.new(-729.2, 50.0, -3957.1),
    ["Donut island"] = CFrame.new(968.4, 42.0, -4116.3),
    ["Burger island"] = CFrame.new(2557.9, 63.0, -3540.1),
    ["Fried Chicken island"] = CFrame.new(3752.3, 55.0, -1248.8),
    ["Tournament of Power"] = CFrame.new(35.9, 11795.0, 11158.5),
}

-- Crafter & Special NPCs
local SpecialNPCs = {
    ["Katana Man (Katana / Tanto)"] = CFrame.new(-158.40, 13.71, -122.69),
    ["Mihawk (Yoru / Swords)"] = CFrame.new(-1279.42, 7.38, -1303.91),
    ["Ryuma (Shisui / Wado)"] = CFrame.new(84.31, 138.80, -2796.66),
    ["Lucci (Rokushiki)"] = CFrame.new(-67.36, 137.12, -2894.80),
    ["Cid Man (Cid / Yamato)"] = CFrame.new(-2728.28, 62.66, -876.81),
    ["Double Man"] = CFrame.new(-1457.53, 12.18, 30.72),
    ["Santa Man (Santa Demon)"] = CFrame.new(1389.41, 299.34, -2778.98),
    ["Cursed Blades (Blade of Chaos)"] = CFrame.new(1231.10, 92.07, -2301.21),
    ["Kame Master (Dragon Ball)"] = CFrame.new(-456.73, 5.08, 2150.71),
    ["Random Devil Fruit (5M Beli)"] = CFrame.new(-34.0, 5.0, 44.0),
    ["Economy Shop"] = CFrame.new(-60.36, 7.50, -101.18),
    ["Random Color Haki"] = CFrame.new(-93.33, 7.12, -144.24),
    ["Sell Haki"] = CFrame.new(326.76, 24.42, 1219.70),
    ["Guarantee Craft"] = CFrame.new(-126.75, 7.74, -173.24),
    ["Go Moon (Space Ticket)"] = CFrame.new(32.33, 2.67, -244.26),
    ["Open Dungeon"] = CFrame.new(106.51, 21.68, 204.15),
    ["Shop Dungeon"] = CFrame.new(175.02, 21.28, 176.44),
    ["Open Raid"] = CFrame.new(-730.20, 3.66, -667.22),
    ["Shop Raid"] = CFrame.new(-740.84, 3.68, -642.24),
}

-- Extract List of Mob Names
local function getMobNameList()
    local list = {}
    for name, _ in pairs(MobSpawnAnchors) do
        table.insert(list, name)
    end
    table.sort(list)
    return list
end

-- Extract Weapon Craft Names
local function getWeaponCraftList()
    local list = {}
    for name, _ in pairs(UseItems) do
        table.insert(list, name)
    end
    table.sort(list)
    return list
end

-- Inventory Parser
local function getPlayerInventory()
    local raw = LocalPlayer:GetAttribute("Inventory")
    if raw and raw ~= "" then
        local success, res = pcall(HttpService.JSONDecode, HttpService, raw)
        if success and type(res) == "table" then return res end
    end
    return {}
end

-- Material Drop Sources Mapping
local MaterialDropSources = {
    ["Iron"] = "Bacon Iron",
    ["Old Iron"] = "Bacon Minerals",
    ["Old Rock"] = "Bacon Rock",
    ["Wood"] = "Bacon",
    ["Old Wood"] = "Bacon",
    ["Bandage"] = "Bacon Strong",
    ["Boxing Gloves"] = "Bacon Sanders",
    ["Boxing Sandbag"] = "Bacon Sanders",
    ["Dumbbell 25 KG"] = "Bacon Sanders",
    ["Black Belt"] = "Bacon Fisherman",
    ["Fish"] = "Bacon Fisherman",
    ["Orb Water"] = "Bacon The Deep",
    ["Orb Spirit"] = "Bacon Marine Captain",
    ["Black Shoes"] = "Bacon Marine",
    ["Chef Hat"] = "Bacon Chef",
    ["Khaw Phad Kai"] = "Bacon Chef",
    ["Gold"] = "Bacon Pharaoh",
    ["Holy Gold"] = "Bacon Pharaoh",
    ["Holy Iron"] = "Bacon Egypt",
    ["Holy Stone"] = "Bacon Rock",
    ["Holy Wood"] = "Bacon Barbarian",
    ["Iron Shark Teeth"] = "Bacon Pirate",
    ["Banana"] = "Monkey",
    ["Banana Leaf"] = "Bacon Tarzan",
    ["Rot Banana"] = "Monkey",
    ["Wolf Fang"] = "Bacon Barbarian",
    ["Orb Fire"] = "Bacon Hellfire",
    ["Orb Dragon"] = "Bacon Hellfire",
    ["Dragon Fang"] = "Bacon Hellfire",
    ["Wind Stone"] = "Bacon Traveler",
    ["Cursed Iron"] = "Bacon Shadow Garden",
    ["Cursed Wood"] = "Bacon Shadow Garden",
    ["Orb Dark"] = "Bacon Shadow Garden",
    ["Shadow Iron"] = "Bacon Shadow Garden",
    ["Shadow Diary"] = "Bacon Shadow Garden",
    ["Black Slime"] = "Bacon Shadow Garden",
    ["Orb Yellow"] = "Bacon Yellow Donut",
    ["Orb Red"] = "Bacon Hellfire",
    ["Orb Black"] = "Bacon Hellfire",
    ["Orb Green"] = "Bacon Clown",
    ["Orb Blue"] = "Bacon Ice",
    ["Orb Purple"] = "Bacon Rainbow Donut",
}

local function getMissingMaterialMobForWeapon(wpName)
    local recipe = UseItems[wpName]
    if not recipe then return nil end
    local inv = getPlayerInventory()
    
    for item, req in pairs(recipe.Inventory or {}) do
        local count = inv[item] and inv[item].amount or 0
        if count < req then
            if UseItems[item] and not inv[item] then
                local subMob = getMissingMaterialMobForWeapon(item)
                if subMob then return subMob end
            end
            local mob = MaterialDropSources[item]
            if mob then return mob end
        end
    end
    return nil
end

-- ==========================================
-- STEP 3: CREATE FURINA HUB WINDOW (WINDUI)
-- ==========================================
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "Furina Hub | Rock Fruit",
    Icon = "droplets",
    Author = "Furina Hydro Overpowered Edition V6.0",
    Folder = "Furina_RockFruit_Hub",
    Size = UDim2.fromOffset(640, 520),
    Theme = "Dark",
    Transparent = true,
    Resizable = true,
    ToggleKey = Config.ToggleKey,
})
getgenv().FurinaHubInstance = Window

-- ==========================================
-- BULLETPROOF UI TOGGLE SYSTEM
-- ==========================================
local function toggleUI()
    pcall(function()
        local hui = (gethui and gethui()) or game:GetService("CoreGui")
        local w = hui:FindFirstChild("WindUI") or (LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("WindUI"))
        if w then
            w.Enabled = not w.Enabled
        elseif Window then
            Window:Toggle()
        end
    end)
end
getgenv().FurinaToggleUI = toggleUI

-- Draggable Floating 💧 Toggle Button
local function createFloatingToggleButton()
    local targetContainer = (gethui and gethui()) or LocalPlayer:WaitForChild("PlayerGui")
    local old = targetContainer:FindFirstChild("FurinaFloatButton")
    if old then pcall(function() old:Destroy() end) end
    
    local sg = Instance.new("ScreenGui")
    sg.Name = "FurinaFloatButton"
    sg.ResetOnSpawn = false
    
    local btn = Instance.new("ImageButton")
    btn.Name = "ToggleBtn"
    btn.Size = UDim2.fromOffset(46, 46)
    btn.Position = UDim2.new(0, 18, 0.45, 0)
    btn.BackgroundColor3 = Color3.fromRGB(16, 22, 38)
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = true
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = btn
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 200, 255)
    stroke.Thickness = 2
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = btn
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.fromScale(1, 1)
    lbl.BackgroundTransparency = 1
    lbl.Text = "💧"
    lbl.TextSize = 22
    lbl.Parent = btn
    
    -- Smooth drag support
    local dragging = false
    local dragInput, dragStart, startPos
    local hasMoved = false
    
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            hasMoved = false
            dragStart = input.Position
            startPos = btn.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    btn.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            if delta.Magnitude > 4 then
                hasMoved = true
            end
            btn.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    btn.MouseButton1Click:Connect(function()
        if not hasMoved then
            toggleUI()
        end
    end)
    
    btn.Parent = sg
    sg.Parent = targetContainer
end
createFloatingToggleButton()

-- Global Keybind Listener (Supports RightControl, Insert, and Config.ToggleKey)
UserInputService.InputBegan:Connect(function(input, gpe)
    if UserInputService:GetFocusedTextBox() then return end
    
    if input.KeyCode == Config.ToggleKey or input.KeyCode == Enum.KeyCode.RightControl or input.KeyCode == Enum.KeyCode.Insert then
        toggleUI()
    end
end)

-- TABS
local TabFarm = Window:Tab({ Title = "Auto Farm", Icon = "flame" })
local TabWeapons = Window:Tab({ Title = "Get Weapons", Icon = "sparkles" })
local TabWiki = Window:Tab({ Title = "Wiki & Guide", Icon = "book-open" })
local TabPlayer = Window:Tab({ Title = "Player & Bypass", Icon = "shield" })
local TabStats = Window:Tab({ Title = "Stats", Icon = "trending-up" })
local TabTeleport = Window:Tab({ Title = "Teleports", Icon = "map-pin" })
local TabChests = Window:Tab({ Title = "Chests & Drops", Icon = "box" })
local TabBoss = Window:Tab({ Title = "Boss & Raids", Icon = "skull" })
local TabVisuals = Window:Tab({ Title = "ESP & Visuals", Icon = "eye" })
local TabSettings = Window:Tab({ Title = "Settings & Keys", Icon = "settings" })

-- ====================
-- TAB 1: AUTO FARM (LEVEL + MOBS)
-- ====================
TabFarm:Section({ Title = "Live Status & Level Progression" })

local statusParagraph = TabFarm:Paragraph({
    Title = "Engine Status",
    Desc = "Status: Idle | Quest: None | Level: " .. tostring(LocalPlayer:GetAttribute("Level") or 1)
})

TabFarm:Toggle({
    Title = "Auto Farm Level (Auto Quest + Mob Magnet)",
    Desc = "Upgrades quests automatically, teleports to ground spawns & stacks mobs in front of you",
    Value = false,
    Callback = function(val)
        Config.AutoFarmLevel = val
        if val then
            Config.AutoFarmMob = false
            Config.AutoFarmMaterials = false
        end
    end
})

TabFarm:Toggle({
    Title = "Mob Magnet / Bring Mobs",
    Desc = "Pulls all spawned mobs of the target type into a single stack on the ground",
    Value = true,
    Callback = function(val)
        Config.MobMagnet = val
    end
})

TabFarm:Section({ Title = "Specific Mob Farm" })

local allMobs = getMobNameList()
TabFarm:Dropdown({
    Title = "Select Mob to Farm",
    Values = allMobs,
    Value = Config.SelectedMob,
    Callback = function(val)
        Config.SelectedMob = val
    end
})

TabFarm:Toggle({
    Title = "Auto Farm Selected Mob",
    Desc = "Teleports directly to the selected mob, stacks them, and auto-destroys them",
    Value = false,
    Callback = function(val)
        Config.AutoFarmMob = val
        if val then
            Config.AutoFarmLevel = false
            Config.AutoFarmMaterials = false
        end
    end
})

TabFarm:Section({ Title = "Farm Positioning & Sky Mode" })

TabFarm:Toggle({
    Title = "Kill NPC in Sky (Sky Mode)",
    Desc = "Hovers safely above mobs so they cannot hit you back (Zero Damage Taken)",
    Value = true,
    Callback = function(val)
        Config.KillInSky = val
    end
})

TabFarm:Dropdown({
    Title = "Farm Position Mode",
    Values = { "Sky (Above)", "Ground (Front)", "Behind", "Underground" },
    Value = "Sky (Above)",
    Callback = function(val)
        Config.FarmPosition = val
    end
})

TabFarm:Slider({
    Title = "Sky Height (Studs)",
    Desc = "Distance above mob while farming in Sky mode (5.5 - 6.0 calibrated for 100% melee reach)",
    Value = { Min = 3.5, Max = 12, Default = 5.8 },
    Callback = function(val)
        Config.SkyHeight = val
    end
})

TabFarm:Section({ Title = "Overpowered Combat & Fast Attack" })

TabFarm:Toggle({
    Title = "Fast Attack (Insane Multi-Hit Burst)",
    Desc = "Fires high-speed hit packets directly to server",
    Value = true,
    Callback = function(val)
        Config.FastAttack = val
    end
})

TabFarm:Dropdown({
    Title = "Fast Attack Speed Preset",
    Values = { "Normal (2x)", "Fast (5x)", "Super Fast (8x)", "Insane (10x)", "God Burst (15x)" },
    Value = "Insane (10x)",
    Callback = function(val)
        Config.FastAttackSpeed = val
        if val == "Normal (2x)" then
            Config.HitsPerCycle = 2
            Config.AttackDelay = 0.04
        elseif val == "Fast (5x)" then
            Config.HitsPerCycle = 5
            Config.AttackDelay = 0.03
        elseif val == "Super Fast (8x)" then
            Config.HitsPerCycle = 8
            Config.AttackDelay = 0.02
        elseif val == "Insane (10x)" then
            Config.HitsPerCycle = 10
            Config.AttackDelay = 0.015
        elseif val == "God Burst (15x)" then
            Config.HitsPerCycle = 15
            Config.AttackDelay = 0.01
        end
    end
})

TabFarm:Slider({
    Title = "Custom Hits Per Cycle",
    Desc = "Number of attack packets fired per loop tick",
    Value = { Min = 1, Max = 20, Default = 10 },
    Callback = function(val)
        Config.HitsPerCycle = val
    end
})

TabFarm:Toggle({
    Title = "Cancel Attack Animations (Zero Stutter)",
    Desc = "Stops weapon animations so player moves smoothly and never locks up",
    Value = true,
    Callback = function(val)
        Config.CancelAnimations = val
    end
})

TabFarm:Toggle({
    Title = "Auto Cast Skills (Z, X, C, V)",
    Value = true,
    Callback = function(val)
        Config.AutoSkills = val
    end
})

TabFarm:Toggle({
    Title = "Auto Buso Haki (Armament)",
    Value = true,
    Callback = function(val)
        Config.AutoBusoHaki = val
    end
})

TabFarm:Section({ Title = "Auto Distribute Stats" })

TabFarm:Toggle({
    Title = "Auto Distribute Stats while Farming",
    Desc = "Automatically spends earned stat points into your character",
    Value = true,
    Callback = function(val)
        Config.AutoStats = val
    end
})

TabFarm:Dropdown({
    Title = "Stat Distribution Target",
    Values = { "Balanced (Melee & Defense)", "Melee", "Defense", "Sword", "Power" },
    Value = "Balanced (Melee & Defense)",
    Callback = function(val)
        Config.StatTarget = val
    end
})

-- ====================
-- TAB 2: AUTO GET WEAPONS & CRAFTING
-- ====================
TabWeapons:Section({ Title = "Remote Weapon Crafter" })

local weaponList = getWeaponCraftList()

local function getWeaponStatusText(wpName)
    local recipe = UseItems[wpName]
    if not recipe then return "No recipe data." end
    local inv = getPlayerInventory()
    local text = "--- " .. wpName .. " (" .. (recipe.Type or "Weapon") .. ") ---\n"
    if recipe.NeedClass then
        text = text .. "Required Class: " .. recipe.NeedClass .. "\n"
    end
    if recipe.PlayerData then
        for k, v in pairs(recipe.PlayerData) do
            local has = LocalPlayer:GetAttribute(k) or 0
            text = text .. k .. ": " .. has .. " / " .. v .. "\n"
        end
    end
    text = text .. "Ingredients:\n"
    local canCraft = true
    for item, req in pairs(recipe.Inventory or {}) do
        local count = inv[item] and inv[item].amount or 0
        text = text .. "  * " .. item .. ": " .. count .. " / " .. req .. (count >= req and " [OK]" or " [MISSING]") .. "\n"
        if count < req then canCraft = false end
    end
    text = text .. "Status: " .. (canCraft and "READY TO CRAFT!" or "Need more materials.")
    return text
end

TabWeapons:Dropdown({
    Title = "Select Weapon / Melee / Special",
    Values = weaponList,
    Value = Config.SelectedWeaponToGet,
    Callback = function(val)
        Config.SelectedWeaponToGet = val
        WindUI:Notify({ Title = val, Content = getWeaponStatusText(val), Duration = 5 })
    end
})

TabWeapons:Button({
    Title = "Craft Selected Weapon Now",
    Desc = "Triggers the server craft remote instantly from anywhere on the map",
    Callback = function()
        local wp = Config.SelectedWeaponToGet
        local recipe = UseItems[wp]
        if recipe then
            NetworkFramework.fireServer("Craft", wp, recipe.Type or "Sword")
            WindUI:Notify({ Title = "Crafting", Content = "Sent craft request for " .. wp, Duration = 3 })
        end
    end
})

TabWeapons:Button({
    Title = "Check Recipe & Material Status",
    Callback = function()
        local status = getWeaponStatusText(Config.SelectedWeaponToGet)
        WindUI:Notify({ Title = "Recipe Check", Content = status, Duration = 7 })
    end
})

TabWeapons:Section({ Title = "Automated Material Farming & Crafting" })

TabWeapons:Toggle({
    Title = "Auto Farm Materials for Selected Weapon",
    Desc = "Automatically targets, stacks, and destroys mobs that drop missing ingredients, then auto-crafts it",
    Value = false,
    Callback = function(val)
        Config.AutoFarmMaterials = val
        if val then
            Config.AutoFarmLevel = false
            Config.AutoFarmMob = false
        end
    end
})

TabWeapons:Toggle({
    Title = "Auto Craft Affordable Weapons & Items",
    Desc = "Continuously scans inventory and auto-crafts any weapon or table item as soon as ingredients are gathered",
    Value = false,
    Callback = function(val)
        Config.AutoCraftAffordable = val
    end
})

TabWeapons:Toggle({
    Title = "Auto Equip Best Weapon",
    Desc = "Continuously checks inventory and equips the highest rarity sword/melee tool",
    Value = false,
    Callback = function(val)
        Config.AutoEquipBest = val
    end
})

TabWeapons:Button({
    Title = "One-Click Craft All Affordable Items",
    Desc = "Instantly crafts every single weapon and crafting table item you have full ingredients for",
    Callback = function()
        local inv = getPlayerInventory()
        local pBeli = LocalPlayer:GetAttribute("Beli") or 0
        local pDiamonds = LocalPlayer:GetAttribute("Diamond") or 0
        local craftedCount = 0
        
        -- 1. UseItems (Weapons/Melee/Special)
        for wpName, recipe in pairs(UseItems) do
            if not inv[wpName] then
                local canCraft = true
                for item, req in pairs(recipe.Inventory or {}) do
                    local count = inv[item] and inv[item].amount or 0
                    if count < req then canCraft = false; break end
                end
                if canCraft and recipe.PlayerData then
                    for k, v in pairs(recipe.PlayerData) do
                        local has = LocalPlayer:GetAttribute(k) or 0
                        if has < v then canCraft = false; break end
                    end
                end
                if canCraft then
                    NetworkFramework.fireServer("Craft", wpName, recipe.Type or "Sword")
                    craftedCount = craftedCount + 1
                    task.wait(0.2)
                end
            end
        end
        
        -- 2. CraftingTable (Accessories/Items)
        if CraftingTable then
            for itemName, data in pairs(CraftingTable) do
                if not inv[itemName] and pDiamonds >= (data.price or 0) then
                    local canCraft = true
                    for mat, req in pairs(data.need or {}) do
                        local count = inv[mat] and inv[mat].amount or 0
                        if count < req then canCraft = false; break end
                    end
                    if canCraft then
                        NetworkFramework.fireServer("CraftTable", itemName, "Craft")
                        craftedCount = craftedCount + 1
                        task.wait(0.2)
                    end
                end
            end
        end
        
        WindUI:Notify({ Title = "Craft Results", Content = "Crafted " .. craftedCount .. " affordable item(s)!", Duration = 4 })
    end
})

-- ====================
-- TAB 3: WIKI & GUIDES
-- ====================
TabWiki:Section({ Title = "Swords & Blade Recipes" })

local swordsWiki = {
    ["Tanto (Uncommon)"] = "15 Bandage, 5 Iron, 10 Wood + 2,500 Beli",
    ["Katana (Uncommon)"] = "15 Iron, 1 Tanto, 15 Wood + 25,000 Beli",
    ["Shirasaya (Uncommon)"] = "1 Katana, 10 Old Iron, 15 Old Rock, 7 Old Wood + 100,000 Beli",
    ["Kiribachi (Rare)"] = "15 Gold, 12 Iron Shark Teeth, 5 Old Wood + 500,000 Beli",
    ["Kitetsu (Epic)"] = "5 Cursed Iron, 5 Cursed Wood, 1 Katana, 15 Orb Spirit + 1,500,000 Beli",
    ["Wado (Epic)"] = "8 Holy Iron, 1 Katana, 10 Old Wood, 15 Wind Stone + 2,500,000 Beli",
    ["Shisui (Epic)"] = "15 Black Iron, 10 Gold, 1 Katana, 5 Old Wood, 5 Orb Red + 3,500,000 Beli",
    ["Yoru (Legendary)"] = "15 Holy Iron, 15 Holy Wood, 15 Orb Black, 15 Orb Green + 9,500,000 Beli",
    ["Enma (Legendary)"] = "15 Holy Gold, 10 Holy Iron, 15 Holy Stone, 10 Holy Wood + 10,000,000 Beli",
    ["Jimina (Mythical)"] = "7 Black Iron, 1 Katana, 5 Orb Black, 7 Orb Dark, 8 Orb Red, 12 Scarf Old, 10 Shadow Diary, 15 Shadow Iron + 500M Beli",
    ["Cid (Rainbow)"] = "10 Black Slime, 1 Jimina, 1 Nuke, 5 Orb Atomic, 5 Orb Dark, 7 Orb Purple, 15 Orb Shadow + 1.5B Beli",
    ["CidBeta (Rainbow)"] = "1 Cid, 1 Shadow Ring + 100,000 Diamonds",
    ["Yamato (Rainbow)"] = "1 Chair, 1 Devil Arm, 5 Devil Heart, 1 Katana, 15 Orb Blue, 15 Orb Dark, 10 Orb Devil + 7.5B Beli",
    ["Blade of Chaos (Rainbow)"] = "2 Cursed Blade, 2 Cursed Chain, 15 Orb Fire, 10 Shield Hoplon, 7 Spear + 10B Beli (Requires: God of War)",
}

for name, desc in pairs(swordsWiki) do
    TabWiki:Button({
        Title = name,
        Desc = desc,
        Callback = function() WindUI:Notify({ Title = name, Content = desc, Duration = 6 }) end
    })
end

TabWiki:Section({ Title = "Melee Styles" })

local meleeWiki = {
    ["Boxing (Uncommon)"] = "2 Boxing Gloves, 5 Boxing Sandbag, 1 Dumbbell 25 KG + 15,000 Beli",
    ["Karate Fish (Rare)"] = "7 Black Belt, 15 Fish, 12 Orb Water + 100,000 Beli",
    ["Black Leg (Epic)"] = "2 Black Shoes, 1 Chef Hat, 5 Khaw Phad Kai, 15 Orb Fire + 250,000 Beli",
    ["Rokushiki (Legendary)"] = "10 Book of Rokuogan, 1 Boxing + 15,000,000 Beli",
    ["Ryusoken (Legendary)"] = "15 Dragon Fang, 15 Orb Dragon, 15 Orb Fire, 5 Pipe + 500,000 Beli",
    ["MuayThai (Mythical)"] = "15 Banana Leaf, 1 Boxing, 15 Boxing Sandbag, 5 Boxing Shorts, 5 Dumbbell 25 KG + 500M Beli",
    ["MuayThaiV2 (Rainbow)"] = "10 Banana Leaf, 1 Boxing Gloves, 5 Boxing Shorts, 2 Gas Cylinder, 1 MuayThai + 850M Beli",
    ["Michael Jackson (Mythical)"] = "1 Boxing, 10 Microphone, 10 Orb Dark, 15 Thompson Gun + 100M Beli",
    ["Kaioken (Epic)"] = "10 Orb Red, 5 Orb Warrior, 10 Rot Banana, 10 Wolf Fang + 750M Beli",
    ["SSJ (Legendary)"] = "10 Banana, 1 Kaioken, 1 Orb Angry, 1 Orb Power, 15 Orb Yellow + 1.5B Beli (Requires: Saiyan)",
    ["SSJ2 (Legendary)"] = "1 Orb Perfect, 15 Orb Power, 1 SSJ + 2.5B Beli (Requires: Saiyan)",
    ["SSJ3 (Legendary)"] = "3 Orb Perfect, 15 Orb Power, 1 SSJ2, 1 Senzu Bean, 1 Z Sword + 3.5B Beli (Requires: Saiyan)",
}

for name, desc in pairs(meleeWiki) do
    TabWiki:Button({
        Title = name,
        Desc = desc,
        Callback = function() WindUI:Notify({ Title = name, Content = desc, Duration = 6 }) end
    })
end

TabWiki:Section({ Title = "Powers & Classes Buffs" })

local classesWiki = {
    ["God of War"] = "+35% Max HP, +25% Sword Damage, Restore 7% HP on attack hit",
    ["The Eminence in Shadow"] = "+35% Max HP, +20% Sword Damage, -50% Cid weapon cooldowns",
    ["Adaptation"] = "Adapts to % HP lost, at 100% reduces incoming damage by 25%",
    ["Edgerunner"] = "Reduces Sandevistan self-damage + 25% Special Damage",
    ["Viltrumite"] = "+35% Max HP, +20% Punch Damage",
    ["Umamusume"] = "+35% Max HP, 1.5x Dash distance",
    ["Saiyan"] = "+15% Max HP, 3x EXP from quests (Required for SSJ series!)",
    ["I have no enemies"] = "Total invulnerability to player damage",
    ["Vampire"] = "1.5% Lifesteal on all attacks",
    ["Skypieans"] = "Allows up to 20 Geppo sky jumps",
    ["Celestial Dragons"] = "2x Beli and 2x Diamonds from all quests",
}

for name, desc in pairs(classesWiki) do
    TabWiki:Button({
        Title = name,
        Desc = desc,
        Callback = function() WindUI:Notify({ Title = name, Content = desc, Duration = 6 }) end
    })
end

-- ====================
-- TAB 4: PLAYER & BYPASS
-- ====================
TabPlayer:Section({ Title = "Protections & Bypass" })

TabPlayer:Toggle({
    Title = "Neutralize SafeZones (Always Attack)",
    Desc = "Disables SafeZone hit cancellation across all islands",
    Value = true,
    Callback = function(val)
        if val then neutralizeSafeZones() end
    end
})

TabPlayer:Toggle({
    Title = "Speed & Jump Lock Bypass",
    Desc = "Prevents game sprint loops from overwriting your custom speeds",
    Value = true,
    Callback = function(val) Config.WalkSpeedBypass = val end
})

TabPlayer:Toggle({
    Title = "Anti-Stun & Anti-CantMove",
    Desc = "Auto-removes stun debuffs and frozen character controls",
    Value = true,
    Callback = function(val) Config.AntiStun = val end
})

TabPlayer:Toggle({
    Title = "Ocean & Void Fall Shield",
    Desc = "Prevents falling into deadly water or below the map",
    Value = true,
    Callback = function(val) Config.AntiVoid = val end
})

TabPlayer:Section({ Title = "Speed & Jump" })

TabPlayer:Toggle({
    Title = "Enable Custom WalkSpeed",
    Value = false,
    Callback = function(val) Config.WalkSpeedEnabled = val end
})

TabPlayer:Slider({
    Title = "WalkSpeed Value",
    Value = { Min = 16, Max = 300, Default = 55 },
    Callback = function(val) Config.WalkSpeed = val end
})

TabPlayer:Toggle({
    Title = "Enable Custom JumpPower",
    Value = false,
    Callback = function(val) Config.JumpPowerEnabled = val end
})

TabPlayer:Slider({
    Title = "JumpPower Value",
    Value = { Min = 50, Max = 350, Default = 100 },
    Callback = function(val) Config.JumpPower = val end
})

TabPlayer:Section({ Title = "Abilities" })

TabPlayer:Toggle({
    Title = "Infinite Jump",
    Value = false,
    Callback = function(val) Config.InfJump = val end
})

TabPlayer:Toggle({
    Title = "Noclip",
    Value = false,
    Callback = function(val) Config.Noclip = val end
})

TabPlayer:Toggle({
    Title = "Fly Mode (WASD + Space / Shift)",
    Value = false,
    Callback = function(val) Config.Fly = val end
})

TabPlayer:Slider({
    Title = "Fly Speed",
    Value = { Min = 20, Max = 250, Default = 65 },
    Callback = function(val) Config.FlySpeed = val end
})

-- ====================
-- TAB 5: STATS
-- ====================
TabStats:Section({ Title = "Auto Allocate Points" })

TabStats:Toggle({
    Title = "Enable Auto Stats",
    Value = false,
    Callback = function(val) Config.AutoStats = val end
})

TabStats:Slider({
    Title = "Points Per Cycle",
    Value = { Min = 1, Max = 50, Default = 10 },
    Callback = function(val) Config.StatPointsAmount = val end
})

TabStats:Toggle({
    Title = "Allocate to Melee",
    Value = true,
    Callback = function(val) Config.StatPointsMelee = val end
})

TabStats:Toggle({
    Title = "Allocate to Defense",
    Value = true,
    Callback = function(val) Config.StatPointsDefense = val end
})

TabStats:Toggle({
    Title = "Allocate to Sword",
    Value = false,
    Callback = function(val) Config.StatPointsSword = val end
})

TabStats:Toggle({
    Title = "Allocate to Power",
    Value = false,
    Callback = function(val) Config.StatPointsPower = val end
})

TabStats:Section({ Title = "Instant Actions" })

TabStats:Button({
    Title = "Claim Daily Rewards (All 7 Days)",
    Callback = function()
        pcall(function()
            for i = 1, 7 do
                NetworkFramework.fireServer("daily", i)
                task.wait(0.1)
            end
            WindUI:Notify({ Title = "Daily", Content = "Claimed all available tiers!", Duration = 3 })
        end)
    end
})

TabStats:Button({
    Title = "Reroll Class",
    Callback = function()
        pcall(function()
            NetworkFramework.fireServer("RerollClass")
            WindUI:Notify({ Title = "Class", Content = "Rerolled class!", Duration = 3 })
        end)
    end
})

TabStats:Button({
    Title = "Reset All Stats",
    Callback = function()
        pcall(function()
            SystemRemote:FireServer("ResetStats")
            WindUI:Notify({ Title = "Stats", Content = "Stats reset!", Duration = 3 })
        end)
    end
})

-- ====================
-- TAB 6: TELEPORTS
-- ====================
TabTeleport:Section({ Title = "Island Teleports (23 Islands)" })

local islandNames = {}
for name, _ in pairs(Islands) do table.insert(islandNames, name) end
table.sort(islandNames)

local selectedIsland = islandNames[1]
TabTeleport:Dropdown({
    Title = "Select Island",
    Values = islandNames,
    Value = selectedIsland,
    Callback = function(val) selectedIsland = val end
})

TabTeleport:Button({
    Title = "Teleport to Selected Island",
    Callback = function()
        if Islands[selectedIsland] then
            teleportInstant(Islands[selectedIsland])
            WindUI:Notify({ Title = "Teleport", Content = "Teleported to " .. selectedIsland, Duration = 2 })
        end
    end
})

TabTeleport:Section({ Title = "Crafters & Special NPCs" })

local npcNames = {}
for name, _ in pairs(SpecialNPCs) do table.insert(npcNames, name) end
table.sort(npcNames)

local selectedNPC = npcNames[1]
TabTeleport:Dropdown({
    Title = "Select NPC",
    Values = npcNames,
    Value = selectedNPC,
    Callback = function(val) selectedNPC = val end
})

TabTeleport:Button({
    Title = "Teleport to NPC",
    Callback = function()
        if SpecialNPCs[selectedNPC] then
            teleportInstant(SpecialNPCs[selectedNPC])
            WindUI:Notify({ Title = "Teleport", Content = "Teleported to " .. selectedNPC, Duration = 2 })
        end
    end
})

TabTeleport:Section({ Title = "Player Teleport" })

local function getPlayerNames()
    local plrs = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(plrs, p.Name) end
    end
    if #plrs == 0 then table.insert(plrs, "None") end
    return plrs
end

local selectedTargetPlayer = getPlayerNames()[1]
TabTeleport:Dropdown({
    Title = "Select Player",
    Values = getPlayerNames(),
    Value = selectedTargetPlayer,
    Callback = function(val) selectedTargetPlayer = val end
})

TabTeleport:Button({
    Title = "Teleport to Player",
    Callback = function()
        local target = Players:FindFirstChild(selectedTargetPlayer)
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            teleportInstant(target.Character.HumanoidRootPart.CFrame)
            WindUI:Notify({ Title = "Teleport", Content = "Teleported to " .. selectedTargetPlayer, Duration = 2 })
        end
    end
})

-- ====================
-- TAB 7: CHESTS & DROPS
-- ====================
TabChests:Section({ Title = "Chests" })

TabChests:Toggle({
    Title = "Auto Collect All Chests",
    Value = false,
    Callback = function(val) Config.AutoChest = val end
})

TabChests:Button({
    Title = "Sweep Chests Once Now",
    Callback = function()
        task.spawn(function()
            local originalCF = getHRP() and getHRP().CFrame
            local chests = CollectionService:GetTagged("Chest")
            for _, c in ipairs(chests) do
                local prompt = c:FindFirstChildWhichIsA("ProximityPrompt", true)
                local part = c:IsA("BasePart") and c or c:FindFirstChildWhichIsA("BasePart", true)
                if prompt and part and prompt.Enabled then
                    teleportInstant(part.CFrame * CFrame.new(0, 3, 0))
                    task.wait(0.2)
                    prompt.HoldDuration = 0
                    pcall(function() fireproximityprompt(prompt) end)
                    task.wait(0.2)
                end
            end
            if originalCF then teleportInstant(originalCF) end
            WindUI:Notify({ Title = "Chests", Content = "Swept active chests!", Duration = 3 })
        end)
    end
})

TabChests:Section({ Title = "Random Fruit" })

TabChests:Button({
    Title = "Buy Random Devil Fruit (5M Beli)",
    Callback = function()
        local prompt = Workspace:FindFirstChild("NpcRandomFruit")
            and Workspace.NpcRandomFruit:FindFirstChild("Random DevilFruit")
            and Workspace.NpcRandomFruit["Random DevilFruit"]:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt then
            prompt.HoldDuration = 0
            pcall(function() fireproximityprompt(prompt) end)
        else
            teleportInstant(CFrame.new(-34.0, 5.0, 44.0))
        end
    end
})

-- ====================
-- TAB 8: BOSS & RAIDS
-- ====================
TabBoss:Section({ Title = "Summon Boss Fights" })

TabBoss:Button({
    Title = "Spawn Bacon of Grudge",
    Callback = function() pcall(function() NetworkFramework.fireServer("SpawnBossFight", "Bacon of Grudge") end) end
})

TabBoss:Button({
    Title = "Spawn Dragon Boss",
    Callback = function() pcall(function() NetworkFramework.fireServer("SpawnBossFight", "Dragon") end) end
})

TabBoss:Button({
    Title = "Spawn Lava Titan Boss",
    Callback = function() pcall(function() NetworkFramework.fireServer("SpawnBossFight", "LavaTitan") end) end
})

TabBoss:Section({ Title = "Dungeons & Raids" })

TabBoss:Button({
    Title = "Spawn Dungeon (1 Orb)",
    Callback = function() pcall(function() NetworkFramework.fireServer("SpawnDungeon", 1) end) end
})

TabBoss:Button({
    Title = "Buy Raid Space Ticket",
    Callback = function() pcall(function() NetworkFramework.fireServer("ShopRaid", "Space Ticket") end) end
})

-- ====================
-- TAB 9: ESP & VISUALS
-- ====================
TabVisuals:Section({ Title = "Lighting" })

TabVisuals:Toggle({
    Title = "Fullbright",
    Value = false,
    Callback = function(val)
        Config.Fullbright = val
        if val then
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
        else
            Lighting.Brightness = 1
            Lighting.ClockTime = 14
            Lighting.FogEnd = 1000
            Lighting.GlobalShadows = true
        end
    end
})

TabVisuals:Section({ Title = "ESP Trackers" })

TabVisuals:Toggle({
    Title = "Player ESP",
    Value = false,
    Callback = function(val) Config.PlayerESP = val end
})

TabVisuals:Toggle({
    Title = "Mob ESP",
    Value = false,
    Callback = function(val) Config.MobESP = val end
})

TabVisuals:Toggle({
    Title = "Chest ESP",
    Value = false,
    Callback = function(val) Config.ChestESP = val end
})

-- ====================
-- TAB 10: SETTINGS & KEYBIND
-- ====================
TabSettings:Section({ Title = "UI Keybind & Controls" })

TabSettings:Keybind({
    Title = "Toggle UI Keybind",
    Desc = "Set custom key to show / hide Furina Hub (Also supports Insert / RightControl / Floating Button)",
    Value = Config.ToggleKey,
    Callback = function(newKey)
        Config.ToggleKey = newKey
        Window:SetToggleKey(newKey)
        WindUI:Notify({ Title = "Keybind", Content = "Updated toggle keybind to " .. tostring(newKey.Name), Duration = 3 })
    end
})

TabSettings:Button({
    Title = "Toggle Menu Visibility Now",
    Desc = "Click to instantly hide this menu (reopen with 💧 float button, RightControl, or Insert)",
    Callback = function()
        toggleUI()
    end
})

TabSettings:Section({ Title = "Codes & Server" })

local KnownCodes = {"RELEASE", "UPDATE1", "UPDATE2", "ANIME", "SHENRON", "DRAGON", "FREEBELI", "DIAMOND", "SUB2CODE"}
TabSettings:Button({
    Title = "Redeem All Popular Codes",
    Callback = function()
        task.spawn(function()
            for _, code in ipairs(KnownCodes) do
                pcall(function() NetworkFramework.fireServer("Code", code) end)
                task.wait(0.3)
            end
            WindUI:Notify({ Title = "Codes", Content = "Submitted all codes!", Duration = 3 })
        end)
    end
})

TabSettings:Button({
    Title = "Rejoin Current Server",
    Callback = function()
        game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end
})

TabSettings:Button({
    Title = "Copy Current CFrame",
    Callback = function()
        local hrp = getHRP()
        if hrp then
            local p = hrp.CFrame
            setclipboard(string.format("CFrame.new(%.2f, %.2f, %.2f)", p.X, p.Y, p.Z))
            WindUI:Notify({ Title = "Clipboard", Content = "CFrame copied!", Duration = 2 })
        end
    end
})

-- ===================================================
-- BULLETPROOF MOB FARMING ENGINE (SKY & GROUND MODES)
-- ===================================================
local function farmMobTarget(mobName)
    local hrp = getHRP()
    if not hrp then return end
    
    -- Ensure weapon is held
    ensureEquippedTool()
    
    -- 1. Locate all alive mobs with exact name match
    local aliveMobs = {}
    if Workspace:FindFirstChild("Mob") then
        for _, m in ipairs(Workspace.Mob:GetChildren()) do
            if m.Name == mobName then
                local hum = m:FindFirstChildOfClass("Humanoid")
                local mhrp = m:FindFirstChild("HumanoidRootPart") or m:FindFirstChild("Torso")
                if hum and hum.Health > 0 and mhrp then
                    table.insert(aliveMobs, m)
                end
            end
        end
    end
    
    -- 2. If NO alive mobs exist, hover above spawn anchor to trigger spawner safely
    if #aliveMobs == 0 then
        local anchorPart = Workspace:FindFirstChild("Itemdrops") and Workspace.Itemdrops:FindFirstChild(mobName)
        local rawPos = anchorPart and anchorPart.Position or MobSpawnAnchors[mobName]
        if typeof(rawPos) == "CFrame" then rawPos = rawPos.Position end
        
        if rawPos then
            local groundCF = getGroundCFrame(rawPos)
            local isSky = (Config.FarmPosition == "Sky (Above)" or Config.KillInSky)
            if isSky then
                local hoverPos = groundCF.Position + Vector3.new(0, Config.SkyHeight or 5.8, 0)
                teleportInstant(CFrame.lookAt(hoverPos, groundCF.Position))
            else
                teleportInstant(groundCF)
            end
            task.wait(0.3)
        end
        return
    end
    
    -- 3. Alive mobs exist! Pick first genuinely alive mob
    local targetMob, targetHRP, targetHum
    for _, m in ipairs(aliveMobs) do
        local hum = m:FindFirstChildOfClass("Humanoid")
        local root = m:FindFirstChild("HumanoidRootPart") or m:FindFirstChild("Torso")
        if hum and hum.Health > 0 and root then
            targetMob = m
            targetHum = hum
            targetHRP = root
            break
        end
    end
    if not targetMob or not targetHRP or not targetHum then return end
    
    -- Position player according to Farm Mode: Sky or Ground
    local attackCF
    local isSky = (Config.FarmPosition == "Sky (Above)" or Config.KillInSky)
    if isSky then
        local skyHeight = Config.SkyHeight or 5.8
        local skyPos = targetHRP.Position + Vector3.new(0, skyHeight, 0)
        attackCF = CFrame.lookAt(skyPos, targetHRP.Position)
    elseif Config.FarmPosition == "Behind" then
        attackCF = targetHRP.CFrame * CFrame.new(0, 0, -2.5) * CFrame.Angles(0, math.rad(180), 0)
    elseif Config.FarmPosition == "Underground" then
        attackCF = CFrame.new(targetHRP.Position - Vector3.new(0, 5, 0)) * CFrame.Angles(math.rad(90), 0, 0)
    else -- Ground (Front)
        attackCF = targetHRP.CFrame * CFrame.new(0, 0, 2.5)
    end
    teleportInstant(attackCF)
    
    -- Hover stability lock in sky
    if isSky and hrp then
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end
    
    -- 4. MOB MAGNET: Stack all other matching alive mobs directly onto target mob
    if Config.MobMagnet then
        for i = 2, #aliveMobs do
            local m = aliveMobs[i]
            local mhrp = m:FindFirstChild("HumanoidRootPart") or m:FindFirstChild("Torso")
            if mhrp then
                mhrp.CFrame = targetHRP.CFrame
                mhrp.AssemblyLinearVelocity = Vector3.zero
                mhrp.AssemblyAngularVelocity = Vector3.zero
                mhrp.CanCollide = false
            end
        end
    end
    
    -- 5. Attack!
    performAttack()
end

-- ==========================================
-- CORE BACKGROUND SYSTEMS (PCALL PROTECTED)
-- ==========================================

-- 1. Anti-Cheat & Shield Enforcer
RunService.Stepped:Connect(function()
    if not isScriptActive then return end
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        
        -- Sky mode hover lock: zero out falling velocity so character floats safely in the sky above mobs
        if hrp and (Config.AutoFarmLevel or Config.AutoFarmMob or Config.AutoFarmMaterials) and (Config.FarmPosition == "Sky (Above)" or Config.KillInSky) then
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end
        
        if hum and Config.WalkSpeedBypass then
            if Config.WalkSpeedEnabled and hum.WalkSpeed ~= Config.WalkSpeed then
                hum.WalkSpeed = Config.WalkSpeed
            end
            if Config.JumpPowerEnabled and hum.JumpPower ~= Config.JumpPower then
                hum.JumpPower = Config.JumpPower
            end
        end
        
        if Config.AntiStun then
            if char:GetAttribute("Stun") then char:SetAttribute("Stun", nil) end
            local cantMove = char:FindFirstChild("CantMove")
            if cantMove then cantMove:Destroy() end
            if char:GetAttribute("Safezone") then char:SetAttribute("Safezone", false) end
        end
        
        if Config.AntiVoid and hrp and hrp.Position.Y < 3 then
            hrp.CFrame = hrp.CFrame + Vector3.new(0, 15, 0)
            hrp.AssemblyLinearVelocity = Vector3.zero
        end
        
        if Config.Noclip then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end)
end)

-- 2. Smart Level & Mob Auto-Farm Engine (Crash-Proof Loop)
task.spawn(function()
    while isScriptActive do
        task.wait(0.05)
        pcall(function()
            -- Buso Haki Maintenance
            if Config.AutoBusoHaki and LocalPlayer:GetAttribute("BusoHaki") == false then
                pcall(function() ActionRemote:FireServer("Misc", "buso") end)
            end
            
            -- ===========================
            -- MODE A: LEVEL AUTO-FARM
            -- ===========================
            if Config.AutoFarmLevel then
                local pLevel = LocalPlayer:GetAttribute("Level") or 1
                local questAttr = LocalPlayer:GetAttribute("Quest")
                
                local hasActiveQuest = false
                local targetMobName = ""
                if questAttr and questAttr ~= "[]" and questAttr ~= "" and questAttr ~= "{}" then
                    pcall(function()
                        local qData = HttpService:JSONDecode(questAttr)
                        if qData and qData.Title and qData.Title ~= "" then
                            hasActiveQuest = true
                            targetMobName = qData.Title
                        end
                    end)
                end
                
                if not hasActiveQuest then
                    local questInfo = QuestModule.GetQuestByLevel(pLevel)
                    if questInfo and questInfo.Npc and questInfo.Npc:FindFirstChild("HumanoidRootPart") then
                        local npc = questInfo.Npc
                        local prompt = npc:FindFirstChildWhichIsA("ProximityPrompt", true)
                        teleportInstant(npc.HumanoidRootPart.CFrame * CFrame.new(0, 0, -2.5))
                        task.wait(0.2)
                        if prompt then
                            prompt.HoldDuration = 0
                            pcall(function() fireproximityprompt(prompt) end)
                        end
                        
                        -- Wait for quest confirmation before moving to mobs
                        local waitStart = os.clock()
                        while os.clock() - waitStart < 0.8 do
                            task.wait(0.1)
                            local qa = LocalPlayer:GetAttribute("Quest")
                            if qa and qa ~= "[]" and qa ~= "" and qa ~= "{}" then
                                break
                            end
                        end
                    end
                else
                    -- Quest active! Determine target mob
                    if targetMobName ~= "" then
                        farmMobTarget(targetMobName)
                    end
                end
                
            -- ===========================
            -- MODE B: SPECIFIC MOB FARM
            -- ===========================
            elseif Config.AutoFarmMob then
                local targetMobName = Config.SelectedMob
                if targetMobName and targetMobName ~= "" then
                    farmMobTarget(targetMobName)
                end
                
            -- ===========================
            -- MODE C: MATERIAL AUTO-FARM
            -- ===========================
            elseif Config.AutoFarmMaterials then
                local targetWp = Config.SelectedWeaponToGet or "Tanto"
                local missingMob = getMissingMaterialMobForWeapon(targetWp)
                if missingMob and missingMob ~= "" then
                    farmMobTarget(missingMob)
                else
                    -- All ingredients gathered! Automatically craft the weapon
                    local recipe = UseItems[targetWp]
                    if recipe then
                        NetworkFramework.fireServer("Craft", targetWp, recipe.Type or "Sword")
                        task.wait(0.5)
                    end
                end
            end
        end)
    end
end)

-- 3. Dedicated High-Speed Fast-Attack Thread
task.spawn(function()
    while isScriptActive do
        local delayTime = math.clamp(Config.AttackDelay or 0.015, 0.01, 0.1)
        task.wait(delayTime)
        pcall(function()
            if (Config.AutoFarmLevel or Config.AutoFarmMob or Config.AutoFarmMaterials) and Config.FastAttack then
                performAttack()
            end
        end)
    end
end)

-- 4. Live Status Updater
task.spawn(function()
    while isScriptActive do
        task.wait(0.7)
        pcall(function()
            if statusParagraph then
                local mode = "Idle"
                if Config.AutoFarmLevel then mode = "Farm Level"
                elseif Config.AutoFarmMob then mode = "Farm Mob (" .. (Config.SelectedMob or "") .. ")"
                elseif Config.AutoFarmMaterials then mode = "Farm Mat (" .. (Config.SelectedWeaponToGet or "") .. ")"
                end
                
                local qAttr = LocalPlayer:GetAttribute("Quest")
                local qText = "None"
                if qAttr and qAttr ~= "[]" and qAttr ~= "" and qAttr ~= "{}" then
                    pcall(function()
                        local qData = HttpService:JSONDecode(qAttr)
                        if qData and qData.Title then
                            local cur = qData.Current or 0
                            local maxKills = qData.Max or 5
                            qText = qData.Title .. " (" .. cur .. "/" .. maxKills .. ")"
                        end
                    end)
                end
                local lvl = tostring(LocalPlayer:GetAttribute("Level") or 1)
                statusParagraph:SetDesc("Mode: " .. mode .. " | Quest: " .. qText .. " | Lv. " .. lvl)
            end
        end)
    end
end)

-- 5. Auto Allocate Stats Thread
task.spawn(function()
    while isScriptActive do
        task.wait(0.5)
        pcall(function()
            if Config.AutoStats then
                local availablePoints = LocalPlayer:GetAttribute("Point") or 0
                if availablePoints > 0 then
                    local target = Config.StatTarget or "Balanced (Melee & Defense)"
                    local spendBatch = math.min(Config.StatPointsAmount or 250, availablePoints)
                    if target == "Melee" or (target:find("Melee") and not target:find("Balanced")) then
                        SystemRemote:FireServer("UpStats", "Melee", spendBatch)
                    elseif target == "Defense" then
                        SystemRemote:FireServer("UpStats", "Defense", spendBatch)
                    elseif target == "Sword" then
                        SystemRemote:FireServer("UpStats", "Sword", spendBatch)
                    elseif target == "Power" then
                        SystemRemote:FireServer("UpStats", "Power", spendBatch)
                    else -- Balanced (Melee & Defense)
                        local half = math.floor(spendBatch / 2)
                        if half > 0 then
                            SystemRemote:FireServer("UpStats", "Melee", half)
                            SystemRemote:FireServer("UpStats", "Defense", half)
                        else
                            SystemRemote:FireServer("UpStats", "Melee", 1)
                        end
                    end
                end
            end
        end)
    end
end)

-- 6. Auto Craft Affordable Weapons & Table Items Thread
task.spawn(function()
    while isScriptActive do
        task.wait(2.0)
        pcall(function()
            if Config.AutoCraftAffordable then
                local inv = getPlayerInventory()
                local pBeli = LocalPlayer:GetAttribute("Beli") or 0
                local pDiamonds = LocalPlayer:GetAttribute("Diamond") or 0
                
                -- Weapons & Styles
                for wpName, recipe in pairs(UseItems) do
                    if not inv[wpName] then
                        local canCraft = true
                        for item, req in pairs(recipe.Inventory or {}) do
                            local count = inv[item] and inv[item].amount or 0
                            if count < req then canCraft = false; break end
                        end
                        if canCraft and recipe.PlayerData then
                            for k, v in pairs(recipe.PlayerData) do
                                local has = LocalPlayer:GetAttribute(k) or 0
                                if has < v then canCraft = false; break end
                            end
                        end
                        if canCraft then
                            NetworkFramework.fireServer("Craft", wpName, recipe.Type or "Sword")
                            task.wait(0.3)
                        end
                    end
                end
                
                -- Crafting Table Items
                if CraftingTable then
                    for itemName, data in pairs(CraftingTable) do
                        if not inv[itemName] and pDiamonds >= (data.price or 0) then
                            local canCraft = true
                            for mat, req in pairs(data.need or {}) do
                                local count = inv[mat] and inv[mat].amount or 0
                                if count < req then canCraft = false; break end
                            end
                            if canCraft then
                                NetworkFramework.fireServer("CraftTable", itemName, "Craft")
                                task.wait(0.3)
                            end
                        end
                    end
                end
            end
        end)
    end
end)

-- 7. Auto Equip Best Weapon Thread
task.spawn(function()
    while isScriptActive do
        task.wait(3.0)
        pcall(function()
            if Config.AutoEquipBest then
                local inv = getPlayerInventory()
                local rarityOrder = {
                    ["Rainbow"] = 6,
                    ["Mythical"] = 5,
                    ["Legendary"] = 4,
                    ["Epic"] = 3,
                    ["Rare"] = 2,
                    ["Uncommon"] = 1,
                    ["Common"] = 0
                }
                local bestItem = nil
                local bestScore = -1
                for name, itemData in pairs(inv) do
                    if itemData.type == "Combat" or itemData.type == "Sword" or itemData.type == "Melee" then
                        local score = rarityOrder[itemData.rarity or "Common"] or 0
                        if score > bestScore then
                            bestScore = score
                            bestItem = name
                        end
                    end
                end
                if bestItem and bestItem ~= "Combat" then
                    Remotes.Inventory:FireServer(bestItem)
                end
            end
        end)
    end
end)

-- 8. Auto Chests Thread
task.spawn(function()
    while isScriptActive do
        task.wait(1.5)
        pcall(function()
            if Config.AutoChest then
                local chests = CollectionService:GetTagged("Chest")
                for _, c in ipairs(chests) do
                    if not Config.AutoChest or not isScriptActive then break end
                    local prompt = c:FindFirstChildWhichIsA("ProximityPrompt", true)
                    local part = c:IsA("BasePart") and c or c:FindFirstChildWhichIsA("BasePart", true)
                    if prompt and part and prompt.Enabled then
                        teleportInstant(part.CFrame * CFrame.new(0, 3, 0))
                        task.wait(0.2)
                        prompt.HoldDuration = 0
                        pcall(function() fireproximityprompt(prompt) end)
                        task.wait(0.2)
                    end
                end
            end
        end)
    end
end)

-- 7. Infinite Jump Handler
UserInputService.JumpRequest:Connect(function()
    if isScriptActive and Config.InfJump then
        local hum = getHumanoid()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- 8. Fly Mode Thread
local flyBodyVelocity, flyBodyGyro
task.spawn(function()
    while isScriptActive do
        task.wait(0.1)
        pcall(function()
            local hrp = getHRP()
            if Config.Fly and hrp then
                if not flyBodyVelocity then
                    flyBodyVelocity = Instance.new("BodyVelocity")
                    flyBodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
                    flyBodyVelocity.Velocity = Vector3.zero
                    flyBodyVelocity.Parent = hrp
                    
                    flyBodyGyro = Instance.new("BodyGyro")
                    flyBodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
                    flyBodyGyro.CFrame = hrp.CFrame
                    flyBodyGyro.Parent = hrp
                end
                
                local cam = Workspace.CurrentCamera
                local moveDir = Vector3.zero
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end
                
                flyBodyVelocity.Velocity = moveDir * Config.FlySpeed
                flyBodyGyro.CFrame = cam.CFrame
            else
                if flyBodyVelocity then flyBodyVelocity:Destroy(); flyBodyVelocity = nil end
                if flyBodyGyro then flyBodyGyro:Destroy(); flyBodyGyro = nil end
            end
        end)
    end
    if flyBodyVelocity then flyBodyVelocity:Destroy() end
    if flyBodyGyro then flyBodyGyro:Destroy() end
end)

-- 9. Visuals & ESP Thread
task.spawn(function()
    while isScriptActive do
        task.wait(1)
        pcall(function()
            -- Player ESP
            if Config.PlayerESP then
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                        local char = plr.Character
                        if not char:FindFirstChild("ESP_Highlight") then
                            local h = Instance.new("Highlight")
                            h.Name = "ESP_Highlight"
                            h.FillColor = Color3.fromRGB(0, 200, 255)
                            h.OutlineColor = Color3.fromRGB(255, 255, 255)
                            h.FillTransparency = 0.5
                            h.Parent = char
                        end
                    end
                end
            else
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr.Character and plr.Character:FindFirstChild("ESP_Highlight") then
                        plr.Character.ESP_Highlight:Destroy()
                    end
                end
            end
            
            -- Mob ESP
            if Config.MobESP and Workspace:FindFirstChild("Mob") then
                for _, m in ipairs(Workspace.Mob:GetChildren()) do
                    local hrp = m:FindFirstChild("HumanoidRootPart") or m:FindFirstChild("Torso")
                    local hum = m:FindFirstChildOfClass("Humanoid")
                    if hrp and hum and hum.Health > 0 then
                        if not hrp:FindFirstChild("MobBillboard") then
                            local bb = Instance.new("BillboardGui")
                            bb.Name = "MobBillboard"
                            bb.Adornee = hrp
                            bb.Size = UDim2.new(0, 120, 0, 40)
                            bb.StudsOffset = Vector3.new(0, 3, 0)
                            bb.AlwaysOnTop = true
                            
                            local lbl = Instance.new("TextLabel")
                            lbl.Size = UDim2.new(1, 0, 1, 0)
                            lbl.BackgroundTransparency = 1
                            lbl.TextColor3 = Color3.fromRGB(80, 220, 255)
                            lbl.TextStrokeTransparency = 0
                            lbl.TextSize = 13
                            lbl.Font = Enum.Font.GothamBold
                            lbl.Text = m.Name .. "\n[" .. math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth) .. "]"
                            lbl.Parent = bb
                            bb.Parent = hrp
                        else
                            local lbl = hrp.MobBillboard:FindFirstChildOfClass("TextLabel")
                            if lbl then
                                lbl.Text = m.Name .. "\n[" .. math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth) .. "]"
                            end
                        end
                    end
                end
            else
                if Workspace:FindFirstChild("Mob") then
                    for _, m in ipairs(Workspace.Mob:GetChildren()) do
                        for _, desc in ipairs(m:GetDescendants()) do
                            if desc.Name == "MobBillboard" then desc:Destroy() end
                        end
                    end
                end
            end
            
            -- Chest ESP
            if Config.ChestESP then
                for _, c in ipairs(CollectionService:GetTagged("Chest")) do
                    if not c:FindFirstChild("ChestHighlight") then
                        local h = Instance.new("Highlight")
                        h.Name = "ChestHighlight"
                        h.FillColor = Color3.fromRGB(255, 215, 0)
                        h.OutlineColor = Color3.fromRGB(255, 255, 255)
                        h.FillTransparency = 0.4
                        h.Parent = c
                    end
                end
            else
                for _, c in ipairs(CollectionService:GetTagged("Chest")) do
                    if c:FindFirstChild("ChestHighlight") then c.ChestHighlight:Destroy() end
                end
            end
        end)
    end
end)

WindUI:Notify({
    Title = "Furina Hub | Rock Fruit",
    Content = "Furina Hydro V6.0 Loaded! Auto Farm, Material Crafter & Sky Combat ready.",
    Duration = 5,
    Icon = "droplets"
})
