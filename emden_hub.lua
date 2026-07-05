--[[
    ============================================================
    EMERGENCIA EMDEN - HUB COM FAST COLLECT E AUTO ROB
    ============================================================
    Funcionalidades:
    - Fast Collect: Coleta itens automaticamente
    - Auto Rob: Rouba caixas/elo automaticamente
    - ESP para drops e objetos de roubo
    - Configurações através de RemoteEvents
    ============================================================
]]

-- ============================================================================
-- KYRILIB UI + JUNKIE KEY SYSTEM
-- ============================================================================
local kyri = loadstring(game:HttpGet("https://kyrilib.dev/kyrilib/"))()

local Junkie = loadstring(game:HttpGet("https://jnkie.com/sdk/library.lua"))()
Junkie.service = "Slim Hub"
Junkie.identifier = "1140699"
Junkie.provider = "Key System"

pcall(function()
    game:GetService("RunService"):UnbindFromRenderStep("EmdenHubAimbot")
end)

local function VerifyKey(key)
    local result = Junkie.check_key(key)
    if result and result.valid then
        if result.message == "KEYLESS" then
            getgenv().SCRIPT_KEY = "KEYLESS"
            return true, "Keyless mode"
        elseif result.message == "KEY_VALID" then
            getgenv().SCRIPT_KEY = key
            return true, "Key valid"
        end
    end
    return false, "Invalid key"
end

local function CopyKeyLink()
    local link = Junkie.get_key_link()
    if setclipboard then setclipboard(link) end
    return link
end

local w = kyri.new("Emden Hub", {
    GameName = "EmergenciaEmden",
    AutoLoad = "default",
    Theme = {
        accent = Color3.fromRGB(0, 180, 255),
        bg = Color3.fromRGB(12, 12, 18),
        container = Color3.fromRGB(18, 18, 26),
        element = Color3.fromRGB(26, 26, 36),
        hover = Color3.fromRGB(35, 35, 48),
        active = Color3.fromRGB(0, 180, 255),
        text = Color3.fromRGB(245, 245, 255),
        subtext = Color3.fromRGB(160, 160, 180),
        border = Color3.fromRGB(40, 40, 55),
    }
})

if not w then return end

local keyTab = w:tab("Key", "key")

keyTab:section("Authentication")
keyTab:paragraph("Enter your key", "Get your key from the link below, paste it in the input, and click Verify.")

keyTab:button("Copy Discord Link", function()
    if setclipboard then setclipboard("https://discord.gg/MfRB5gAQ9N") end
    w:notify("Copied", "Discord link copied!", 2)
end, "copy_discord")

local keyInput = keyTab:input("Your Key", "Paste key here...", function() end, "user_key")

keyTab:space(4)

keyTab:button("Verify Key", function()
    local key = keyInput.input.Text
    if not key or key == "" then
        w:notify("Error", "Please enter a key", 2)
        return
    end

    local ok, msg = VerifyKey(key)
    if ok then
        w:notify("Success", msg, 3)
    else
        w:notify("Failed", msg, 2)
    end
end, "verify_key")

keyTab:button("Copy Key Link", function()
    CopyKeyLink()
    w:notify("Copied", "Link copied to clipboard!", 2)
end, "copy_link")

while not getgenv().SCRIPT_KEY do
    task.wait(0.1)
end

w:notify("Authenticated", "Loading Emden Hub...", 3)

-- ============================================================================
-- TABS
-- ============================================================================
local mainTab = w:tab("Main", "home")
local collectTab = w:tab("Collect", "package-plus")
local robTab = w:tab("Rob", "sword")
local aimTab = w:tab("Aimbot", "crosshair")
local moveTab = w:tab("Movement", "zap")
local weaponTab = w:tab("Weapons", "sword")
local vehicleTab = w:tab("Vehicles", "car")
local espTab = w:tab("ESP", "eye")
local extraTab = w:tab("Extra", "heart")
local trollTab = w:tab("Troll", "ghost")
local visualTab = w:tab("Visual", "palette")

-- ============================================================================
-- SERVICES & REFERENCES
-- ============================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Camera = Workspace.CurrentCamera

local SharedVehicleModule = require(ReplicatedStorage.Client.Database.Vehicles.Classes.SharedVehicleModule)
local WalkSpeeds = require(ReplicatedStorage.Client.Database.Animations.WalkSpeeds)
local DeathSettings = require(ReplicatedStorage.Client.ClientSettings.DeathSettings.DeathsettingsModule)
local LEGIT_MAX_SPEED = WalkSpeeds.Sprint or 21

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character

local Communication = require(ReplicatedStorage:WaitForChild("Native"):WaitForChild("Communication"))
local ClientShared = require(ReplicatedStorage:WaitForChild("ClientShared"))
local Enums = require(ReplicatedStorage:WaitForChild("Client"):WaitForChild("Enums"):WaitForChild("Enums"))
local ProjectileRegistry = require(ReplicatedStorage.Client.Classes.Weapon.ProjectileRegistry)
local CameraModule = require(ReplicatedStorage.Client.Modules.CameraModule)

local OnProjectileHit
local UseWeapon
local SendDeathTime
local DeployChute
local EmoteStateRemote
local VehicleKickoutRemote
local ChangeVehicleHealthRemote
local LockVehicleRemote
local AddWhitelistRemote
local CommFolder = ReplicatedStorage:WaitForChild("Client"):WaitForChild("Communication")

task.spawn(function()
    repeat task.wait() until Communication.IsLoaded
    OnProjectileHit = Communication:GetEvent("OnProjectileHit")
    UseWeapon = Communication:GetEvent("UseWeapon")
    SendDeathTime = CommFolder:WaitForChild("SendDeathTime")
    DeployChute = CommFolder:WaitForChild("DeployChute")
    EmoteStateRemote = CommFolder:WaitForChild("EmoteState")
    VehicleKickoutRemote = CommFolder:WaitForChild("VehicleKickoutPlayer")
    ChangeVehicleHealthRemote = CommFolder:WaitForChild("ChangeVehicleHealth")
    LockVehicleRemote = CommFolder:WaitForChild("LockVehicle")
    AddWhitelistRemote = CommFolder:WaitForChild("AddPlayerVehicleWhiteList")
    ChangeWantedRemote = CommFolder:WaitForChild("ChangeWantedXP")
    ChangeCrimeTimeRemote = CommFolder:WaitForChild("ChangeCrimeTime")
    ChangeCrimeMoneyRemote = CommFolder:WaitForChild("ChangeCrimeMoney")
    OnPunchEvent = CommFolder:WaitForChild("OnPunch")
    GunInteractionRemote = CommFolder:WaitForChild("GunInteraction")
end)

-- ============================================================================
-- CONFIG / STATE
-- ============================================================================
local Config = {
    -- Fast Collect
    FastCollectEnabled = false,
    FastCollectRadius = 50,
    FastCollectDelay = 0.08,
    FastCollectAutoE = true,
    FastCollectUseHit = true,
    
    -- Auto Rob
    AutoRobEnabled = false,
    AutoRobRadius = 15,
    AutoRobDelay = 0.2,
    RobHitsPerTarget = 8,
    RobFastPrompt = true,
    RobPromptTicks = 6,
    RobEquipDelay = 0.35,
    RobPromptDelay = 0.06,
    RobAutomat = true,
    RobBankATM = true,
    RobBox = true,
    RobNPC = true,
    RobPackstation = true,
    RobBankSafe = true,
    RobFacher = true,
    RobTresor = true,
    RobGroupByStation = true,
    RobDoor = true,
    RobBurn = true,
    RobGulli = true,
    RobTeleport = true,
    ToolBypass = true,
    DrillTicks = 20,
    BurnTicks = 25,
    LockpickAttempts = 5,
    
    -- ESP
    ESPEnabled = false,
    ESPDrops = true,
    ESPRobbery = true,
    ESPColor = Color3.fromRGB(0, 180, 255),
    
    -- Teleport
    TPToItems = false,
    TPSpeed = 50,

    -- Aimbot
    AimbotEnabled = false,
    AimbotHold = true,
    AimbotHoldMouse = false,
    AimbotFOV = 160,
    AimbotSmooth = 0.35,
    AimbotPart = "Head",
    AimbotTeamCheck = true,
    AimbotVisibleCheck = false,
    ShowFOVCircle = true,

    -- Player ESP (combate)
    PlayerESPEnabled = false,
    PlayerESPShowName = true,
    PlayerESPShowJob = true,
    PlayerESPShowHighlight = true,
    PlayerESPMaxDist = 400,

    -- Movimento (bypass seguro - NAO altera WalkSpeed/PlatformStand/CanCollide)
    SpeedBoostEnabled = false,
    SpeedBoostExtra = 24,
    SpeedBoostTurbo = false,
    FlyEnabled = false,
    FlySpeed = 120,
    FlyLift = 1.4,
    GlideEnabled = false,
    GlideSpeed = 16,
    GlideLift = 1.0,
    JumpBoostEnabled = false,
    JumpBoostPower = 8,
    InfiniteJump = false,
    NoFallDamage = false,
    AntiRagdoll = true,
    ForceSprint = false,
    InfiniteStamina = false,

    -- Vida / utilidades
    QuickHealEnabled = false,
    QuickHealThreshold = 60,
    QuickHealDelay = 0.4,
    FastDeathEnabled = false,
    FastDeathInterval = 0.35,
    AutoParachute = false,

    -- Armas
    NoRecoil = false,
    InfiniteAmmo = false,
    RapidFire = false,

    -- Veículos
    VehicleSpeedBoost = false,
    VehicleBoostMult = 1.15,
    VehicleNoDamage = false,
    VehicleInfiniteFuel = false,
    VehicleUnlock = false,

    -- Troll (analise colisao/remotes)
    TrollEnabled = false,
    TrollMaxDist = 100,
    TrollTeamCheck = false,
    TrollTargetName = "",
    TrollAutoShoot = false,
    TrollShootHits = 4,
    TrollShootDelay = 0.12,
    TrollVehicleRam = false,
    TrollRamSpeed = 130,
    TrollRamDist = 150,
    TrollUnlockNearby = false,
    TrollUnlockRadius = 50,
    TrollTpVehicleBehind = false,
    TrollEmoteSpam = false,
    TrollEmoteDelay = 0.6,
    TrollBillboard = false,
    TrollBillboardText = "TROLADO",
    TrollKickPassenger = false,
    TrollChaosGulli = false,
    TrollRainbowHighlight = false,
    TrollDestroyVehicle = false,
    TrollLockVehicle = false,
    TrollWhitelister = false,
    TrollModifyWanted = false,
    TrollWantedValue = 100,
    TrollModifyCrimeTime = false,
    TrollCrimeTimeValue = 30,
    TrollCrimeMoneyNegative = false,
    TrollCrimeMoneyValue = -1000,
    TrollPunchSpam = false,
    TrollPunchDelay = 0.3,
    TrollGunSpam = false,
    TrollAntiPunchCD = false,
}

-- ============================================================================
-- FAST COLLECT SYSTEM
-- ============================================================================
local FastCollectConnection = nil
local AutoRobConnection = nil
local CollectedItems = {}
local RobbedItems = {}

local function GetModelPart(model)
    if not model then return nil end
    if model:IsA("BasePart") then return model end
    if model.PrimaryPart then return model.PrimaryPart end
    for _, d in model:GetDescendants() do
        if d:IsA("BasePart") and d.Transparency < 1 then
            return d
        end
    end
    return model:FindFirstChildWhichIsA("BasePart", true)
end

local function TriggerPrompt(prompt, instant)
    if not prompt or not prompt:IsA("ProximityPrompt") then return false end
    if typeof(fireproximityprompt) == "function" then
        fireproximityprompt(prompt, instant ~= false and 1 or 0)
        return true
    end
    return false
end

-- ============================================================================
-- AUTO F/E GLOBAL (qualquer prompt que aparecer = instantâneo)
-- ============================================================================
local AutoFastPromptConnection = nil
local PromptShownConnection = nil
local AutoFastPromptCooldowns = {}
local LastAutoPromptScan = 0
local AUTO_PROMPT_COOLDOWN = 0.07

local function ShouldAutoTriggerPrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") or not prompt.Enabled then
        return false
    end
    if typeof(fireproximityprompt) ~= "function" then return false end

    local key = prompt.KeyboardKeyCode

    if Config.RobFastPrompt and key == Enum.KeyCode.F then
        return true
    end

    if Config.FastCollectEnabled and key == Enum.KeyCode.E then
        if not Config.FastCollectAutoE then return false end
        local action = prompt.ActionText:lower()
        if action:find("collect")
            or action:find("pick")
            or action:find("take")
            or action:find("sammeln")
            or action:find("aufheben")
            or prompt.Name == "Collect"
            or prompt.ActionText == "Collect" then
            return true
        end
    end

    return false
end

local function AutoTriggerPrompt(prompt)
    local now = tick()
    local id = tostring(prompt)
    if now - (AutoFastPromptCooldowns[id] or 0) < AUTO_PROMPT_COOLDOWN then
        return false
    end
    if TriggerPrompt(prompt, true) then
        AutoFastPromptCooldowns[id] = now
        return true
    end
    return false
end

local function OnPromptShown(prompt)
    if ShouldAutoTriggerPrompt(prompt) then
        task.defer(function()
            AutoTriggerPrompt(prompt)
        end)
    end
end

local function ScanNearbyAutoPrompts()
    if not Character or not Character:FindFirstChild("HumanoidRootPart") then return end
    if not Config.RobFastPrompt and not Config.FastCollectEnabled then return end

    local hrp = Character.HumanoidRootPart
    for _, prompt in Workspace:GetDescendants() do
        if prompt:IsA("ProximityPrompt") and ShouldAutoTriggerPrompt(prompt) then
            local anchor = prompt.Parent
            if anchor and anchor:IsA("BasePart") then
                local dist = (anchor.Position - hrp.Position).Magnitude
                if dist <= prompt.MaxActivationDistance + 2 then
                    AutoTriggerPrompt(prompt)
                end
            end
        end
    end
end

local function AutoFastPromptLoop()
    if not Config.RobFastPrompt and not Config.FastCollectEnabled then return end
    local now = tick()
    if now - LastAutoPromptScan < 0.08 then return end
    LastAutoPromptScan = now
    ScanNearbyAutoPrompts()
end

local function UpdateAutoFastPrompt()
    local shouldRun = Config.RobFastPrompt or (Config.FastCollectEnabled and Config.FastCollectAutoE)
    if shouldRun then
        if not PromptShownConnection then
            PromptShownConnection = ProximityPromptService.PromptShown:Connect(OnPromptShown)
        end
        if not AutoFastPromptConnection then
            AutoFastPromptConnection = RunService.Heartbeat:Connect(AutoFastPromptLoop)
        end
    else
        if PromptShownConnection then
            PromptShownConnection:Disconnect()
            PromptShownConnection = nil
        end
        if AutoFastPromptConnection then
            AutoFastPromptConnection:Disconnect()
            AutoFastPromptConnection = nil
        end
        AutoFastPromptCooldowns = {}
    end
end

-- Rob scope (Luau: max 200 locals por bloco)
local FindCollectibles, CollectItem, StartFastCollect, StopFastCollect
local FindRobberyTargets, RobTarget, PickNextRobEntry, GetRobEntryKey, StartAutoRob, StopAutoRob
local GetShootWeapon, FireProjectileHit, EquipRobTool, TeleportNearTarget
local FindDrillPrompt, FindRobPrompt, FindNearbyRobPrompt, IsRobEntryDone
local IsCorreiosRobTarget, IsBankRobTarget
local FindDrillTool, FindLockpickTool, FindBurnTool, FindCrowbarTool

do
    local LastAutoRobTick = 0
    local IsRobbing = false

local function GetRobPromptKey(method)
    if method == "drill" or method == "crowbar" then
        return Enum.KeyCode.F
    end
    if method == "door" or method == "tresor" then
        return Enum.KeyCode.E
    end
    return nil
end

FindRobPrompt = function(target, doorPart, method)
    if not target then return nil end

    local key = GetRobPromptKey(method)
    local hrp = Character and Character:FindFirstChild("HumanoidRootPart")

    local function pickPrompt(container)
        if not container then return nil end
        local best, bestDist = nil, math.huge
        for _, d in container:GetDescendants() do
            if d:IsA("ProximityPrompt") and d.Enabled then
                if not key or d.KeyboardKeyCode == key or d.Name == "Robbery" then
                    local anchor = d.Parent
                    if anchor and anchor:IsA("BasePart") and hrp then
                        local dist = (anchor.Position - hrp.Position).Magnitude
                        if dist <= d.MaxActivationDistance + 3 and dist < bestDist then
                            bestDist = dist
                            best = d
                        end
                    elseif not best then
                        best = d
                    end
                end
            end
        end
        return best
    end

    if method == "npc" then
        local root = target.PrimaryPart or target:FindFirstChild("HumanoidRootPart")
        local rob = root and root:FindFirstChild("Robbery")
        if rob and rob:IsA("ProximityPrompt") then
            return rob
        end
    end

    return pickPrompt(doorPart) or pickPrompt(target)
end

FindNearbyRobPrompt = function(method, radius)
    local key = GetRobPromptKey(method)
    local hrp = Character and Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local limit = radius or 8
    local best, bestDist = nil, limit
    for _, d in Workspace:GetDescendants() do
        if d:IsA("ProximityPrompt") and d.Enabled then
            if not key or d.KeyboardKeyCode == key or d.Name == "Robbery" then
                local anchor = d.Parent
                if anchor and anchor:IsA("BasePart") then
                    local dist = (anchor.Position - hrp.Position).Magnitude
                    if dist <= d.MaxActivationDistance + 2 and dist < bestDist then
                        bestDist = dist
                        best = d
                    end
                end
            end
        end
    end
    return best
end

local function TriggerPromptBurst(prompt, times)
    if not prompt then return 0 end
    local hits = 0
    for _ = 1, times or 1 do
        if TriggerPrompt(prompt, true) then
            hits += 1
        end
        task.wait(Config.RobPromptDelay or 0.06)
    end
    return hits
end

local function TouchCollect(part)
    if not part then return false end
    if typeof(firetouchinterest) == "function" then
        firetouchinterest(part, 0)
        firetouchinterest(part, 1)
        return true
    end
    if Character and Character:FindFirstChild("HumanoidRootPart") then
        Character.HumanoidRootPart.CFrame = part.CFrame
        return true
    end
    return false
end

FindCollectibles = function()
    local collectibles = {}
    local seen = {}

    -- Drops do jogo usam tag OneShotItems
    for _, item in ipairs(CollectionService:GetTagged("OneShotItems")) do
        if not seen[item] and item.Parent then
            seen[item] = true
            table.insert(collectibles, item)
        end
    end

    return collectibles
end

local function CollectViaHit(item)
    if not Config.FastCollectUseHit or not OnProjectileHit then return false end

    local part = GetModelPart(item)
    if not part or not Character or not Character:FindFirstChild("HumanoidRootPart") then
        return false
    end

    local index = ProjectileRegistry.CurrentIndex
    local hrp = Character.HumanoidRootPart
    local ok = pcall(function()
        OnProjectileHit:Fire(index, {
            HitPart = part,
            HitPoint = part.Position,
            HitType = Enums.HitTypes.OneShotItems,
            Index = index,
            Distance = (part.Position - hrp.Position).Magnitude,
            Direction = (part.Position - hrp.Position).Unit,
            HitOffset = part.CFrame,
            Material = part.Material,
            Normal = Vector3.new(0, 1, 0),
            Time = tick(),
            Penetrate = false,
        })
    end)

    if ok then
        ProjectileRegistry.CurrentIndex = index + 1
    end
    return ok
end

CollectItem = function(item)
    if not item or CollectedItems[item] then return false end
    if not item.Parent then return false end

    local part = GetModelPart(item)
    if not part then return false end

    local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt and TriggerPrompt(prompt, true) then
        CollectedItems[item] = true
        return true
    end

    if CollectViaHit(item) then
        CollectedItems[item] = true
        return true
    end

    if TouchCollect(part) then
        CollectedItems[item] = true
        return true
    end

    return false
end

local function PruneCollectedItems()
    for item in pairs(CollectedItems) do
        if not item.Parent then
            CollectedItems[item] = nil
        end
    end
end

local function FastCollectLoop()
    if not Config.FastCollectEnabled or not Character or not Character:FindFirstChild("HumanoidRootPart") then return end

    PruneCollectedItems()

    for _, item in ipairs(FindCollectibles()) do
        if not CollectedItems[item] then
            local part = GetModelPart(item)
            if part then
                local distance = (part.Position - Character.HumanoidRootPart.Position).Magnitude
                if distance <= Config.FastCollectRadius or Config.TPToItems then
                    if Config.TPToItems then
                        Character.HumanoidRootPart.CFrame = part.CFrame + Vector3.new(0, 2, 0)
                    end
                    CollectItem(item)
                end
            end
        end
    end
end

local LastCollectTick = 0

StartFastCollect = function()
    if FastCollectConnection then return end
    UpdateAutoFastPrompt()

    FastCollectConnection = RunService.Heartbeat:Connect(function()
        if Config.FastCollectEnabled and tick() - LastCollectTick >= Config.FastCollectDelay then
            LastCollectTick = tick()
            FastCollectLoop()
        end
    end)
end

StopFastCollect = function()
    if FastCollectConnection then
        FastCollectConnection:Disconnect()
        FastCollectConnection = nil
        CollectedItems = {}
    end
    UpdateAutoFastPrompt()
end

-- ============================================================================
-- AUTO ROB SYSTEM (multi-metodo: tiro, broca, lockpick, maçarico, pé de cabra)
-- ============================================================================

local function CanRobTeamTarget(model)
    local teamLock = model:GetAttribute("CanCloseByTeam")
    if teamLock == nil then return true end
    local lockJob = ClientShared.Enums.EnumFromName("JobCategory", teamLock)
    return lockJob ~= ClientShared.LocalPlayer.JobCategory
end

local function FindInContainers(predicate)
    local function search(container)
        if not container then return nil end
        for _, child in container:GetChildren() do
            if child:IsA("Tool") and predicate(child) then
                return child
            end
        end
        return nil
    end
    return search(Character) or search(LocalPlayer:FindFirstChild("Backpack"))
end

local function GetEquippedWeapon()
    if not Character then return nil end
    for _, tool in Character:GetChildren() do
        if tool:IsA("Tool") and (tool:GetAttribute("ToolClass") or tool:FindFirstChild("Handle")) then
            return tool
        end
    end
    return Character:FindFirstChildOfClass("Tool")
end

GetShootWeapon = function()
    local weapon = GetEquippedWeapon()
    if weapon then return weapon end
    if not Config.ToolBypass then return nil end
    return FindInContainers(function(tool)
        return tool:FindFirstChild("Handle") and tool:GetAttribute("ToolClass")
    end)
end

FindDrillTool = function()
    if not Config.ToolBypass then
        local equipped = GetEquippedWeapon()
        if equipped and equipped:FindFirstChild("OnBohrerTriggered") then
            return equipped
        end
        return nil
    end
    return FindInContainers(function(tool)
        return tool:FindFirstChild("OnBohrerTriggered") and tool:FindFirstChild("StartStopEvent")
    end)
end

FindLockpickTool = function()
    if not Config.ToolBypass then
        local equipped = GetEquippedWeapon()
        if equipped and equipped:FindFirstChild("OnUnlockDoor") then
            return equipped
        end
        return nil
    end
    return FindInContainers(function(tool)
        return tool:FindFirstChild("OnUnlockDoor")
    end)
end

FindCrowbarTool = function()
    if not Config.ToolBypass then
        local equipped = GetEquippedWeapon()
        if equipped and (equipped:FindFirstChild("OnBreakObject") or equipped:GetAttribute("ToolName") == "Crowbar") then
            return equipped
        end
        return nil
    end
    return FindInContainers(function(tool)
        return tool:FindFirstChild("OnBreakObject")
            or tool:GetAttribute("ToolName") == "Crowbar"
    end)
end

FindBurnTool = function()
    if not Config.ToolBypass then
        local equipped = GetEquippedWeapon()
        if equipped and equipped:GetAttribute("ToolName") == "BunsenBurner" then
            return equipped
        end
        return nil
    end
    return FindInContainers(function(tool)
        return tool:GetAttribute("ToolName") == "BunsenBurner"
            or tool:FindFirstChild("OnPlayEffect")
    end)
end

EquipRobTool = function(method)
    if not Character then return nil end
    local hum = Character:FindFirstChildOfClass("Humanoid")
    if not hum then return nil end

    local tool
    if method == "shoot" or method == "npc" then
        tool = GetShootWeapon()
    elseif method == "drill" then
        tool = FindDrillTool()
    elseif method == "door" or method == "tresor" then
        tool = FindLockpickTool()
    elseif method == "crowbar" then
        tool = FindCrowbarTool()
    elseif method == "burn" then
        tool = FindBurnTool()
    end

    if tool and tool.Parent ~= Character then
        pcall(function() hum:EquipTool(tool) end)
        task.wait(Config.RobEquipDelay or 0.35)
    end

    return tool
end

local function TryFastPromptRob(entry, target)
    if not Config.RobFastPrompt then return false end

    local method = entry.Method
    local doorPart = entry.Door
    local equipped = EquipRobTool(method)
    if not equipped and method ~= "npc" then
        return false
    end

    task.wait(0.12)

    local prompt
    if method == "drill" then
        prompt = FindDrillPrompt(doorPart, target)
    else
        prompt = FindRobPrompt(target, doorPart, method) or FindNearbyRobPrompt(method, 10)
    end

    if not prompt then
        return false
    end

    if InstantPromptUntilDone(prompt, doorPart, target) then
        return true
    end

    return TriggerPromptBurst(prompt, 2) > 0
end

local function GetDrillDoor(model)
    if model:GetAttribute("IsOpen") == true then return nil end
    local door = model:FindFirstChild("Door") or model:FindFirstChild("Door", true)
    if door and door:GetAttribute("IsOpen") ~= true then
        return door
    end
    if CollectionService:HasTag(model, "Door") and model:GetAttribute("IsOpen") ~= true then
        return model
    end
    return nil
end

local function GetAncestorPath(model)
    local parts = {}
    local current = model
    while current do
        table.insert(parts, current.Name:lower())
        current = current.Parent
    end
    return table.concat(parts, "/")
end

local function IsHouseRobTarget(model)
    if not model then return false end
    if model:GetAttribute("IsHouse") == true or model:GetAttribute("House") == true then return true end
    local path = GetAncestorPath(model)
    for _, hint in ipairs({ "house", "haus", "wohnung", "home", "residential", "playerhouse", "casas", "casa" }) do
        if path:find(hint, 1, true) then return true end
    end
    return false
end

IsBankRobTarget = function(model)
    if not model or IsHouseRobTarget(model) then return false end
    if model:GetAttribute("IsBank") == true or model:GetAttribute("Bank") == true then return true end
    if CollectionService:HasTag(model, "Facher") then return true end
    local path = GetAncestorPath(model)
    for _, hint in ipairs({ "bank", "sparkasse", "tresor", "facher", "safe2", "safe" }) do
        if path:find(hint, 1, true) then return true end
    end
    return false
end

IsCorreiosRobTarget = function(model)
    if not model or IsHouseRobTarget(model) or IsBankRobTarget(model) then return false end
    if not CollectionService:HasTag(model, "Packstation") then return false end
    local path = GetAncestorPath(model)
    if path:find("correio", 1, true) or path:find("post", 1, true) then return true end
    return true
end

local function IsDoorDone(doorPart)
    if not doorPart or not doorPart.Parent then return true end
    if doorPart:GetAttribute("IsOpen") == true then return true end
    if doorPart:GetAttribute("Open") == true then return true end
    if doorPart:GetAttribute("Destroyed") == true then return true end
    if doorPart.Name == "break" or doorPart.Name:lower() == "broken" then return true end

    local hasEnabledF = false
    for _, d in doorPart:GetDescendants() do
        if d:IsA("ProximityPrompt") and d.Enabled and d.KeyboardKeyCode == Enum.KeyCode.F then
            hasEnabledF = true
            break
        end
    end
    if not hasEnabledF and doorPart:IsA("BasePart") then
        for _, d in doorPart:GetChildren() do
            if d:IsA("ProximityPrompt") and d.Enabled and d.KeyboardKeyCode == Enum.KeyCode.F then
                hasEnabledF = true
                break
            end
        end
    end
    if not hasEnabledF then return true end

    return false
end

local function GetRobStationGroup(model)
    if not model then return model end
    local current = model.Parent
    while current and current ~= Workspace do
        local name = current.Name:lower()
        if name:find("correio", 1, true) or name:find("post", 1, true)
            or name:find("packstation", 1, true) or name:find("postamt", 1, true) then
            return current
        end
        current = current.Parent
    end
    return model
end

local function DoorHasDrillPrompt(part)
    if IsDoorDone(part) then return false end
    if part.Name == "Door" or CollectionService:HasTag(part, "Door") then return true end
    for _, d in part:GetDescendants() do
        if d:IsA("ProximityPrompt") and d.Enabled and d.KeyboardKeyCode == Enum.KeyCode.F then
            return true
        end
    end
    return false
end

local function GetAllDrillDoors(model)
    if not model or model:GetAttribute("IsOpen") == true then return {} end

    local doors = {}
    local seen = {}

    local function tryAdd(part)
        if not part or seen[part] or not DoorHasDrillPrompt(part) then return end
        seen[part] = true
        table.insert(doors, part)
    end

    tryAdd(model:FindFirstChild("Door"))
    for _, desc in model:GetDescendants() do
        if desc.Name == "Door" or CollectionService:HasTag(desc, "Door") then
            tryAdd(desc)
        elseif desc:IsA("ProximityPrompt") and desc.Enabled and desc.KeyboardKeyCode == Enum.KeyCode.F then
            local anchor = desc.Parent
            if anchor and anchor:IsA("BasePart") then
                tryAdd(anchor)
            end
        end
    end

    if #doors == 0 then
        local fallback = GetDrillDoor(model)
        if fallback then
            tryAdd(fallback)
        end
    end

    return doors
end

GetRobEntryKey = function(entry)
    if entry and entry.Door then return entry.Door end
    return entry and entry.Target
end

local function GetRobHitType(model)
    if CollectionService:HasTag(model, "RobBox") then
        return Enums.HitTypes.SchmuckBox
    end
    if CollectionService:HasTag(model, "Automat") or CollectionService:HasTag(model, "BankAutomat") then
        return Enums.HitTypes.Automat
    end
    return nil
end

local function IsTargetDone(model, doorPart)
    if not model or not model.Parent then return true end

    if doorPart then
        return IsDoorDone(doorPart)
    end

    if model:GetAttribute("IsOpen") == true then return true end
    if model:GetAttribute("Destroyed") == true then return true end

    if CollectionService:HasTag(model, "BurnObject") then
        local temp = model:GetAttribute("Temperatur")
        if temp and temp > 10 then return true end
        return false
    end

    if model.Name == "break" or model.Name:lower() == "broken" then
        return true
    end

    local anyDrillLeft = false
    for _, door in ipairs(GetAllDrillDoors(model)) do
        if not IsDoorDone(door) then
            anyDrillLeft = true
            break
        end
    end
    if not anyDrillLeft and #GetAllDrillDoors(model) == 0 then
        local door = model:FindFirstChild("Door", true)
        if door and IsDoorDone(door) then return true end
    end
    if not anyDrillLeft then return true end

    return false
end

IsRobEntryDone = function(entry)
    if not entry then return true end
    return IsTargetDone(entry.Target, entry.Door)
end

FindDrillPrompt = function(doorPart, target)
    if doorPart then
        for _, d in doorPart:GetDescendants() do
            if d:IsA("ProximityPrompt") and d.Enabled and d.KeyboardKeyCode == Enum.KeyCode.F then
                return d
            end
        end
        if doorPart:IsA("BasePart") then
            for _, d in doorPart:GetChildren() do
                if d:IsA("ProximityPrompt") and d.Enabled and d.KeyboardKeyCode == Enum.KeyCode.F then
                    return d
                end
            end
        end
    end

    if target and not doorPart then
        local prompt = FindRobPrompt(target, doorPart, "drill")
        if prompt and (prompt.ActionText == "Drill" or prompt.KeyboardKeyCode == Enum.KeyCode.F) then
            return prompt
        end
        return FindNearbyRobPrompt("drill", 6)
    end

    return nil
end

local function InstantPromptUntilDone(prompt, doorPart, target, maxTicks)
    if not prompt or not Config.RobFastPrompt then return false end

    local ticks = maxTicks or Config.RobPromptTicks or 8
    for _ = 1, ticks do
        if IsTargetDone(target, doorPart) then return true end
        TriggerPrompt(prompt, true)
        task.wait(Config.RobPromptDelay or 0.04)
    end

    return IsTargetDone(target, doorPart)
end

local function RegisterProjectile(tool)
    if not OnProjectileHit or not UseWeapon then return nil end

    local weapon = tool or GetShootWeapon()
    if not weapon then return nil end

    local index = ProjectileRegistry.CurrentIndex
    local cam = Workspace.CurrentCamera
    local center = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
    local ray = cam:ViewportPointToRay(center.X, center.Y)
    local origin = ray.Origin
    local direction = ray.Direction.Unit

    UseWeapon:Fire("FireGun", {
        [index] = {
            Index = index,
            Origin = origin,
            Direction = direction,
            Tool = weapon,
            Character = Character,
        }
    })

    ProjectileRegistry.CurrentIndex = index + 1
    return index
end

FireProjectileHit = function(target, hitType)
    if not OnProjectileHit then return false end

    local part = GetModelPart(target)
    if not part or not Character or not Character:FindFirstChild("HumanoidRootPart") then
        return false
    end

    local index = RegisterProjectile()
    if not index then return false end

    local look = CFrame.lookAt(part.Position, part.Position + Vector3.new(0, 0, 1))

    OnProjectileHit:Fire(index, {
        HitOffset = part.CFrame:Inverse() * look,
        HitPoint = part.Position,
        HitType = hitType,
        Index = index,
        HitPart = part,
        Material = part.Material,
        Distance = (part.Position - Character.HumanoidRootPart.Position).Magnitude,
        Direction = (part.Position - Character.HumanoidRootPart.Position).Unit,
        Normal = Vector3.new(0, 1, 0),
        Time = tick(),
        Penetrate = false,
    })

    return true
end

local function RobShootTarget(target)
    if not OnProjectileHit or not UseWeapon then return false end
    if not GetShootWeapon() then return false end

    local hitType = GetRobHitType(target)
    if not hitType then return false end

    local hits = 0
    for _ = 1, Config.RobHitsPerTarget do
        if IsTargetDone(target) then break end
        if FireProjectileHit(target, hitType) then
            hits = hits + 1
        end
        task.wait(0.08)
    end

    return hits > 0
end

local function RobDrillTarget(doorPart, target)
    if not doorPart then return false end

    local drill = FindDrillTool()
    if not drill then return false end

    if Config.RobFastPrompt then
        EquipRobTool("drill")
        task.wait(0.1)
        local prompt = FindDrillPrompt(doorPart, target)
        if prompt and InstantPromptUntilDone(prompt, doorPart, target, Config.RobPromptTicks or 8) then
            return true
        end
    end

    local startStop = drill:FindFirstChild("StartStopEvent")
    local bohrer = drill:FindFirstChild("OnBohrerTriggered")
    if not startStop or not bohrer then return false end

    local tickWait = Config.RobFastPrompt and 0.05 or 0.25
    startStop:FireServer(true)
    for _ = 1, Config.DrillTicks do
        if doorPart:GetAttribute("IsOpen") == true then break end
        bohrer:FireServer(doorPart)
        task.wait(tickWait)
    end
    startStop:FireServer(false)

    return doorPart:GetAttribute("IsOpen") == true
end

local function RobTresorTarget(tresor)
    local remote = tresor:FindFirstChild("UnLockDoorTresor")
    if not remote then return false end

    for _ = 1, Config.LockpickAttempts do
        if IsTargetDone(tresor) then return true end
        local ok = remote:InvokeServer()
        if ok == true then return true end
        if ok == "cant" or ok == "IsDay" then return false end
        task.wait(Config.RobFastPrompt and 0.15 or 0.5)
    end

    return IsTargetDone(tresor)
end

local function RobDoorLockpick(door)
    local lockpick = FindLockpickTool()
    if not lockpick then return false end

    local onUnlock = lockpick:FindFirstChild("OnUnlockDoor")
    if not onUnlock then return false end

    for _ = 1, Config.LockpickAttempts do
        if IsTargetDone(door) then return true end
        local ok = onUnlock:InvokeServer(door)
        if ok == true then return true end
        if ok == "IsDay" then return false end
        task.wait(Config.RobFastPrompt and 0.12 or 0.4)
    end

    return IsTargetDone(door)
end

local function RobBurnTarget(target)
    local remote = target:FindFirstChild("OnChangeTemperaturFromClient")
    if not remote then return false end

    local burnTool = FindBurnTool()
    if burnTool and Character then
        local hum = Character:FindFirstChildOfClass("Humanoid")
        if hum and burnTool.Parent ~= Character then
            pcall(function() hum:EquipTool(burnTool) end)
            task.wait(Config.RobEquipDelay or 0.35)
        end
    end

    local onPlay = burnTool and burnTool:FindFirstChild("OnPlayEffect")
    if onPlay then
        pcall(function() onPlay:FireServer(true) end)
    end

    local tickWait = Config.RobFastPrompt and 0.05 or 0.4
    for _ = 1, Config.BurnTicks do
        if IsTargetDone(target) then break end
        remote:FireServer()
        task.wait(tickWait)
    end

    if onPlay then
        pcall(function() onPlay:FireServer(false) end)
    end

    return IsTargetDone(target)
end

local function RobCrowbarTarget(target)
    local remote = target:FindFirstChild("OnBreakObject")
    if not remote then return false end
    remote:FireServer()
    task.wait(0.3)
    return IsTargetDone(target) or target:GetAttribute("IsOpen") == true
end

FindRobberyTargets = function()
    local targets = {}
    local seen = {}

    local function add(target, method, extra)
        if seen[target] then return end
        local door = extra and extra.Door
        if IsTargetDone(target, door) then return end
        seen[target] = true
        local entry = { Target = target, Method = method }
        if extra then
            for k, v in pairs(extra) do
                entry[k] = v
            end
        end
        table.insert(targets, entry)
    end

    if Config.RobAutomat then
        for _, obj in ipairs(CollectionService:GetTagged("Automat")) do
            add(obj, "shoot")
        end
    end

    if Config.RobBankATM then
        for _, obj in ipairs(CollectionService:GetTagged("BankAutomat")) do
            add(obj, "shoot")
        end
    end

    if Config.RobBox then
        for _, obj in ipairs(CollectionService:GetTagged("RobBox")) do
            add(obj, "shoot")
        end
    end

    if Config.RobNPC then
        for _, obj in ipairs(CollectionService:GetTagged("RobableNPC")) do
            if obj:FindFirstChild("OnRob") then
                add(obj, "npc")
            end
        end
    end

    if Config.RobPackstation then
        for _, obj in ipairs(CollectionService:GetTagged("Packstation")) do
            if IsCorreiosRobTarget(obj) and CanRobTeamTarget(obj) then
                for _, door in ipairs(GetAllDrillDoors(obj)) do
                    if not seen[door] and not IsTargetDone(obj, door) then
                        seen[door] = true
                        table.insert(targets, {
                            Target = obj,
                            Method = "drill",
                            Door = door,
                            Station = obj,
                            StationGroup = GetRobStationGroup(obj),
                        })
                    end
                end
            end
        end
    end

    if Config.RobBankSafe then
        for _, obj in ipairs(CollectionService:GetTagged("Packstation")) do
            if IsBankRobTarget(obj) and not IsHouseRobTarget(obj) and CanRobTeamTarget(obj) then
                for _, door in ipairs(GetAllDrillDoors(obj)) do
                    if not seen[door] and not IsTargetDone(obj, door) then
                        seen[door] = true
                        table.insert(targets, {
                            Target = obj,
                            Method = "drill",
                            Door = door,
                            Station = obj,
                            StationGroup = GetRobStationGroup(obj),
                        })
                    end
                end
            end
        end
    end

    if Config.RobFacher then
        for _, obj in ipairs(CollectionService:GetTagged("Facher")) do
            if IsBankRobTarget(obj) and not IsHouseRobTarget(obj) and CanRobTeamTarget(obj) then
                for _, door in ipairs(GetAllDrillDoors(obj)) do
                    if not seen[door] and not IsTargetDone(obj, door) then
                        seen[door] = true
                        table.insert(targets, {
                            Target = obj,
                            Method = "drill",
                            Door = door,
                            Station = obj,
                            StationGroup = GetRobStationGroup(obj),
                        })
                    end
                end
            end
        end
    end

    if Config.RobTresor then
        for _, obj in ipairs(CollectionService:GetTagged("Tresor")) do
            if CanRobTeamTarget(obj) and IsBankRobTarget(obj) and not IsHouseRobTarget(obj) then
                add(obj, "tresor")
            end
        end
    end

    if Config.RobDoor then
        for _, obj in ipairs(CollectionService:GetTagged("Door")) do
            if CanRobTeamTarget(obj) and obj:FindFirstChild("Hand", true) then
                add(obj, "door")
            end
        end
    end

    if Config.RobBurn then
        for _, obj in ipairs(CollectionService:GetTagged("BurnObject")) do
            if obj:FindFirstChild("OnChangeTemperaturFromClient") then
                add(obj, "burn")
            end
        end
    end

    if Config.RobGulli then
        for _, obj in ipairs(CollectionService:GetTagged("Gulli")) do
            if obj:FindFirstChild("OnBreakObject") then
                add(obj, "crowbar")
            end
        end
    end

    return targets
end

TeleportNearTarget = function(target, doorPart)
    if not Config.RobTeleport or not Character or not Character:FindFirstChild("HumanoidRootPart") then return end
    local part = GetModelPart(doorPart or target)
    if part then
        Character.HumanoidRootPart.CFrame = part.CFrame * CFrame.new(0, 0.5, 2.8)
    end
end

PickNextRobEntry = function(entries)
    local hrp = Character and Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local pending = {}
    for _, entry in ipairs(entries) do
        local key = GetRobEntryKey(entry)
        if key and not RobbedItems[key] and not IsRobEntryDone(entry) then
            table.insert(pending, entry)
        end
    end
    if #pending == 0 then return nil end

    if Config.RobGroupByStation then
        local byGroup = {}
        for _, entry in ipairs(pending) do
            local group = entry.StationGroup or entry.Station or entry.Target
            byGroup[group] = byGroup[group] or {}
            table.insert(byGroup[group], entry)
        end

        local nearestGroup, nearestDist = nil, math.huge
        for group, list in pairs(byGroup) do
            local part = GetModelPart(list[1].Door or list[1].Target)
            if part then
                local dist = (part.Position - hrp.Position).Magnitude
                if dist < nearestDist then
                    nearestDist = dist
                    nearestGroup = group
                end
            end
        end

        if nearestGroup then
            local best, bestDist = nil, math.huge
            for _, entry in ipairs(byGroup[nearestGroup]) do
                local part = GetModelPart(entry.Door or entry.Target)
                if part then
                    local dist = (part.Position - hrp.Position).Magnitude
                    if dist < bestDist then
                        bestDist = dist
                        best = entry
                    end
                end
            end
            return best
        end
    end

    local best, bestDist = nil, math.huge
    for _, entry in ipairs(pending) do
        local part = GetModelPart(entry.Door or entry.Target)
        if part then
            local dist = (part.Position - hrp.Position).Magnitude
            if dist < bestDist then
                bestDist = dist
                best = entry
            end
        end
    end
    return best
end

local RobFailCounts = {}

local function PruneRobbedItems()
    for key, _ in pairs(RobbedItems) do
        if typeof(key) ~= "Instance" or not key.Parent or IsDoorDone(key) then
            RobbedItems[key] = nil
            RobFailCounts[key] = nil
        end
    end
end

RobTarget = function(entry)
    local target = entry.Target
    local key = GetRobEntryKey(entry)
    if not target or not key or RobbedItems[key] or IsRobEntryDone(entry) then return false end

    TeleportNearTarget(target, entry.Door)
    task.wait(0.08)

    local ok = false
    local method = entry.Method

    if Config.RobFastPrompt and method ~= "shoot" then
        TryFastPromptRob(entry, target)
        if IsRobEntryDone(entry) then
            RobbedItems[key] = tick()
            RobFailCounts[key] = nil
            return true
        end
    end

    if method == "npc" then
        local onRob = target:FindFirstChild("OnRob")
        if onRob and onRob:IsA("RemoteEvent") then
            if target:GetAttribute("CanRobNPC") == false then return false end
            onRob:FireServer()
            ok = true
        end
    elseif method == "shoot" then
        ok = RobShootTarget(target)
    elseif method == "drill" then
        ok = RobDrillTarget(entry.Door, target)
    elseif method == "tresor" then
        ok = RobTresorTarget(target)
    elseif method == "door" then
        ok = RobDoorLockpick(target)
    elseif method == "burn" then
        ok = RobBurnTarget(target)
    elseif method == "crowbar" then
        ok = RobCrowbarTarget(target)
    end

    if ok or IsRobEntryDone(entry) then
        RobbedItems[key] = tick()
        RobFailCounts[key] = nil
        return true
    end

    RobFailCounts[key] = (RobFailCounts[key] or 0) + 1
    if RobFailCounts[key] >= 3 or (entry.Door and IsDoorDone(entry.Door)) then
        RobbedItems[key] = tick()
        RobFailCounts[key] = nil
    end

    return false
end

local function AutoRobLoop()
    if not Config.AutoRobEnabled or IsRobbing then return end
    if not Character or not Character:FindFirstChild("HumanoidRootPart") then return end
    if tick() - LastAutoRobTick < Config.AutoRobDelay then return end
    LastAutoRobTick = tick()

    PruneRobbedItems()

    local entry = PickNextRobEntry(FindRobberyTargets())
    if not entry then return end

    local part = GetModelPart(entry.Door or entry.Target)
    if part then
        local distance = (part.Position - Character.HumanoidRootPart.Position).Magnitude
        if distance <= Config.AutoRobRadius or Config.RobTeleport then
            IsRobbing = true
            task.spawn(function()
                RobTarget(entry)
                IsRobbing = false
            end)
        end
    end
end

StartAutoRob = function()
    if AutoRobConnection then return end
    UpdateAutoFastPrompt()
    AutoRobConnection = RunService.Heartbeat:Connect(AutoRobLoop)
end

StopAutoRob = function()
    if AutoRobConnection then
        AutoRobConnection:Disconnect()
        AutoRobConnection = nil
        RobbedItems = {}
        RobFailCounts = {}
    end
    UpdateAutoFastPrompt()
end

end -- rob scope

-- ============================================================================
-- COMBATE / MOVIMENTO / ARMAS / VEÍCULOS
-- ============================================================================
local StartCombatLoop, StopCombat, RunSelfTest
local GetTrollTarget, ClearTrollVisuals, ShootAtPlayer, UpdateTroll
local GetAimbotTarget, GetLocalJobCategory, GetJobDisplayName, GetCurrentVehicle, ClearPlayerESP
local BindAimbotRender, UnbindAimbotRender, UpdatePlayerESP, IsAimbotHoldInput
local GetMovementDeltaTime, ApplySpeedBypass, UpdateFly, UpdateGlide, UpdateMovementExtras, UpdateFallProtection
local UpdateWeaponMods, UpdateVehicleMods
local SetupJumpBoost, SetupFallProtection, ZeroCharacterVelocity, SetFlyHumanoidState
local ConnectCombat, DisconnectCombat
local FlySmoothVel = Vector3.zero
local LastMovementTick = tick()
local CombatConnections = {}
local PlayerESPObjects = {}
local JumpBoostConn = nil
local AimbotHolding = false
local AimbotStickyPart = nil
local AimbotStickyPos = nil
local AimbotStickyChar = nil
local AimbotStickyUntil = 0
local AimbotTargetPos = nil
local AimbotSmoothCF = nil
local AimbotSmoothTargetPos = nil
local AimbotSmoothBodyYaw = nil
local AimbotSavedAutoRotate = nil
local AimbotCamLocked = false
local AimbotLocalCamOffset = nil
local LastAimbotTick = tick()
local FlyFreefallDisabled = false
local LastQuickHealTick = 0
local LastFastDeathTick = 0
local LastParachuteTick = 0
local LastTrollTick = 0
local LastTrollEmoteTick = 0
local LastTrollUnlockTick = 0
local LastTrollGulliTick = 0
local LastTrollKickTick = 0
local LastTrollTpTick = 0
local LastTrollPunchTick = 0
local LastTrollGunTick = 0
local TrollBillboardObjects = {}
local TrollHighlightObjects = {}
local TrollEmoteIndex = 1
local TrollEmoteList = { 1, 2, 3, "HandsUp", "Dance" }
local FOVCircle = Drawing and Drawing.new("Circle") or nil
if FOVCircle then
    FOVCircle.Visible = false
    FOVCircle.Radius = Config.AimbotFOV
    FOVCircle.Filled = false
    FOVCircle.Thickness = 1.5
    FOVCircle.Transparency = 0.75
    FOVCircle.Color = Color3.fromRGB(0, 180, 255)
end

do -- combat shared

ConnectCombat = function(name, conn)
    CombatConnections[name] = conn
end

DisconnectCombat = function(name)
    if CombatConnections[name] then
        CombatConnections[name]:Disconnect()
        CombatConnections[name] = nil
    end
end

local function GetPlayerCharacter(plr)
    if plr.Character and plr.Character.Parent then
        return plr.Character
    end
    local folder = Workspace:FindFirstChild("Characters")
    if folder then
        local model = folder:FindFirstChild(plr.Name)
        if model then return model end
    end
    for _, model in ipairs(CollectionService:GetTagged("Character")) do
        if model.Name == plr.Name then
            return model
        end
    end
    local vehicles = Workspace:FindFirstChild("Vehicles")
    if vehicles then
        for _, veh in vehicles:GetChildren() do
            local ok, occupants = pcall(function()
                return SharedVehicleModule:GetOccupants(veh)
            end)
            if ok and occupants then
                for _, char in ipairs(occupants) do
                    if char and (char.Name == plr.Name or Players:GetPlayerFromCharacter(char) == plr) then
                        return char
                    end
                end
            end
            local seats = veh:FindFirstChild("Seats")
            if seats then
                for _, seat in seats:GetChildren() do
                    if seat:IsA("VehicleSeat") and seat.Occupant then
                        local char = seat.Occupant.Parent
                        if char and (char.Name == plr.Name or Players:GetPlayerFromCharacter(char) == plr) then
                            return char
                        end
                    end
                end
            end
        end
    end
    return nil
end

local function IsLocalCharacter(char)
    if not char then return true end
    if char == Character then return true end
    if ClientShared.LocalPlayer.MyCharacter and char == ClientShared.LocalPlayer.MyCharacter then
        return true
    end
    return char.Name == LocalPlayer.Name
end

local function GetPlayerFromCharacter(char)
    for _, plr in ipairs(Players:GetPlayers()) do
        if GetPlayerCharacter(plr) == char then
            return plr
        end
    end
    return Players:FindFirstChild(char.Name)
end

local function NormalizeJobCategory(job)
    if job == nil then return nil end
    if type(job) == "number" then return job end
    if type(job) == "string" then
        local ok, val = pcall(function()
            return ClientShared.Enums.EnumFromName("JobCategory", job)
        end)
        return (ok and val) or job
    end
    return job
end

GetLocalJobCategory = function()
    local lp = ClientShared.LocalPlayer
    if lp and lp.JobCategory ~= nil then
        return NormalizeJobCategory(lp.JobCategory)
    end
    return NormalizeJobCategory(LocalPlayer:GetAttribute("JobCategory"))
end

local function GetPlayerJobCategory(plr, char)
    if not plr then return nil end
    char = char or GetPlayerCharacter(plr)

    local fromShared = nil
    pcall(function()
        if ClientShared.Players then
            for _, data in pairs(ClientShared.Players) do
                if data and data.Name == plr.Name and data.JobCategory ~= nil then
                    fromShared = NormalizeJobCategory(data.JobCategory)
                end
            end
        end
    end)
    if fromShared then return fromShared end

    if char then
        local attr = char:GetAttribute("JobCategory") or char:GetAttribute("Job") or char:GetAttribute("Team")
        if attr ~= nil then return NormalizeJobCategory(attr) end
    end

    local plrAttr = plr:GetAttribute("JobCategory") or plr:GetAttribute("Job") or plr:GetAttribute("Team")
    if plrAttr ~= nil then return NormalizeJobCategory(plrAttr) end

    return nil
end

local function IsSameTeam(plr, char, teamCheckEnabled)
    if teamCheckEnabled == nil then
        teamCheckEnabled = Config.AimbotTeamCheck
    end
    if not teamCheckEnabled then return false end
    if not plr then return false end
    local myJob = GetLocalJobCategory()
    local theirJob = GetPlayerJobCategory(plr, char)
    if myJob == nil or theirJob == nil then return false end
    return myJob == theirJob
end

local function IsSameJob(plr, char)
    return IsSameTeam(plr, char, Config.TrollTeamCheck)
end

GetJobDisplayName = function(job)
    if job == nil then return "No job" end
    if type(job) == "string" then return job end
    local name = nil
    pcall(function()
        if ClientShared.Enums.EnumToName then
            name = ClientShared.Enums.EnumToName("JobCategory", job)
        end
    end)
    if not name or name == "" then
        pcall(function()
            if ClientShared.Enums.GetNameFromEnum then
                name = ClientShared.Enums.GetNameFromEnum("JobCategory", job)
            end
        end)
    end
    return (name and name ~= "") and name or tostring(job)
end

local function BuildPlayerESPText(plr, char)
    local lines = {}
    if Config.PlayerESPShowName then
        local display = plr.DisplayName ~= "" and plr.DisplayName or plr.Name
        table.insert(lines, display)
    end
    if Config.PlayerESPShowJob then
        table.insert(lines, GetJobDisplayName(GetPlayerJobCategory(plr, char)))
    end
    return table.concat(lines, "\n")
end

do -- aim scope

local function GetAimbotRaycastFilter()
    local filter = { Camera }
    if Character then table.insert(filter, Character) end
    if ClientShared.LocalPlayer.MyCharacter then
        table.insert(filter, ClientShared.LocalPlayer.MyCharacter)
    end
    local charsFolder = Workspace:FindFirstChild("Characters")
    if charsFolder then
        local mine = charsFolder:FindFirstChild(LocalPlayer.Name)
        if mine then table.insert(filter, mine) end
    end
    return filter
end

local function IsValidAimTarget(char, hum)
    if not char or not hum or hum.Health <= 0 then return false end
    if IsLocalCharacter(char) then return false end
    if hum:GetAttribute("IsDeath") == true then return false end
    if char:GetAttribute("RagdollState") == Enums.RagdollState.Ragdolled then return false end
    return true
end

local function GetAimViewportCenter()
    return Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
end

local function GetAimWorldPoint(part, char)
    if not part then return nil end
    if part.Name == "Head" then
        return part.Position
    end
    if part.Name == "HumanoidRootPart" or part.Name == "UpperTorso" or part.Name == "Torso" then
        return part.Position + Vector3.new(0, 0.6, 0)
    end
    return part.Position
end

local function GetAimPart(char, partName)
    if partName == "Closest" then
        local parts = {
            char:FindFirstChild("Head"),
            char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"),
            char:FindFirstChild("HumanoidRootPart"),
        }
        local best, bestDist = nil, math.huge
        for _, part in ipairs(parts) do
            if part then
                local dist = (part.Position - Camera.CFrame.Position).Magnitude
                if dist < bestDist then
                    bestDist = dist
                    best = part
                end
            end
        end
        return best
    end
    return char:FindFirstChild(partName) or char:FindFirstChild("HumanoidRootPart")
end

local function GetPlayerVehicle(char, hum)
    hum = hum or (char and char:FindFirstChildOfClass("Humanoid"))
    if not hum or not hum.SeatPart then return nil end
    return SharedVehicleModule:GetVehicleBySeat(hum.SeatPart) or hum.SeatPart:FindFirstAncestorWhichIsA("Model")
end

local function IsPlayerInVehicle(char, hum)
    hum = hum or (char and char:FindFirstChildOfClass("Humanoid"))
    return hum ~= nil and hum.SeatPart ~= nil
end

local function GetVehicleAimPart(veh)
    if not veh then return nil end
    local chassis = veh:FindFirstChild("Chassis")
    if chassis then
        if chassis:IsA("BasePart") then return chassis end
        if chassis:IsA("Model") then
            return chassis.PrimaryPart
                or chassis:FindFirstChildWhichIsA("BasePart", true)
        end
    end
    if veh:IsA("BasePart") then return veh end
    return veh.PrimaryPart or veh:FindFirstChildWhichIsA("BasePart", true)
end

local function GetAimCandidates(char, partName)
    local hum = char:FindFirstChildOfClass("Humanoid")
    local inVehicle = IsPlayerInVehicle(char, hum)
    local seen = {}
    local candidates = {}

    local function addCandidate(part, pos, priority)
        if not part or not pos then return end
        local key = string.format("%.1f:%.1f:%.1f", pos.X, pos.Y, pos.Z)
        if seen[key] then return end
        seen[key] = true
        table.insert(candidates, { part = part, pos = pos, priority = priority or 0 })
    end

    local function addNamedPart(name, priority, yOffset)
        local part = char:FindFirstChild(name)
        if part then
            addCandidate(part, GetAimWorldPoint(part, char) + Vector3.new(0, yOffset or 0, 0), priority)
        end
    end

    if partName == "Closest" then
        addNamedPart("Head", 0)
        addNamedPart("UpperTorso", 1)
        addNamedPart("Torso", 1)
        addNamedPart("HumanoidRootPart", 2)
    else
        local part = char:FindFirstChild(partName) or char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
        if part then
            addCandidate(part, GetAimWorldPoint(part, char), 0)
        end
    end

    if inVehicle and hum and hum.SeatPart then
        local head = char:FindFirstChild("Head")
        if head then
            addCandidate(head, head.Position, 0)
        end
        local upper = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
        if upper then
            addCandidate(upper, GetAimWorldPoint(upper, char), 1)
        end

        local seat = hum.SeatPart
        local seatCf = seat.CFrame
        local root = hum.RootPart
        if root then
            addCandidate(root, GetAimWorldPoint(root, char), 2)
        end
        addCandidate(seat, (seatCf * CFrame.new(0, 1.35, 0.25)).Position, 3)
        addCandidate(seat, (seatCf * CFrame.new(0, 0.95, 0.45)).Position, 4)
        addCandidate(seat, (seatCf * CFrame.new(0, 0.95, -0.45)).Position, 5)

        local veh = GetPlayerVehicle(char, hum)
        if veh then
            local chassisPart = GetVehicleAimPart(veh)
            if chassisPart then
                addCandidate(chassisPart, chassisPart.Position + Vector3.new(0, 1.0, 0), 6)
            end
        end
    end

    table.sort(candidates, function(a, b)
        return a.priority < b.priority
    end)
    return candidates
end

local function IsPartVisible(worldPos, char)
    if not Config.AimbotVisibleCheck or not worldPos then return true end
    if char and IsPlayerInVehicle(char) then return true end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = GetAimbotRaycastFilter()
    params.IgnoreWater = true

    if char then
        local veh = GetPlayerVehicle(char)
        if veh then
            table.insert(params.FilterDescendantsInstances, veh)
        end
    end

    local origin = Camera.CFrame.Position
    local dir = worldPos - origin
    local dist = dir.Magnitude
    if dist < 0.5 then return true end
    local hit = Workspace:Raycast(origin, dir.Unit * dist, params)
    if not hit then return true end
    if char and hit.Instance:IsDescendantOf(char) then return true end
    return false
end

IsAimbotHoldInput = function(input)
    if Config.AimbotHoldMouse then
        return input.UserInputType == Enum.UserInputType.MouseButton2
    end
    return input.KeyCode == Enum.KeyCode.LeftAlt or input.KeyCode == Enum.KeyCode.RightAlt
end

local function ScoreAimPosition(worldPos, center, maxFov, char)
    if not worldPos then return nil end
    local screenPos, onScreen = Camera:WorldToViewportPoint(worldPos)
    if screenPos.Z <= 0 then return nil end
    local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
    if dist > maxFov then return nil end
    if not IsPartVisible(worldPos, char) then return nil end
    return dist
end

local function ReleaseCharacterAim()
    if AimbotSavedAutoRotate ~= nil then
        local char = ClientShared.LocalPlayer.MyCharacter or Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.AutoRotate = AimbotSavedAutoRotate end
        AimbotSavedAutoRotate = nil
    end
    AimbotSmoothBodyYaw = nil
end

local function ResetAimbotSmooth()
    AimbotSmoothCF = nil
    AimbotSmoothTargetPos = nil
    AimbotLocalCamOffset = nil
    ReleaseCharacterAim()
end

local function GetAimbotCameraPosition(hrp)
    if not hrp then
        return Camera.CFrame.Position
    end
    if not AimbotLocalCamOffset then
        AimbotLocalCamOffset = hrp.CFrame:PointToObjectSpace(Camera.CFrame.Position)
    end
    return hrp.CFrame:PointToWorldSpace(AimbotLocalCamOffset)
end

local function ResolveAimPoint(part, char)
    if not part then return nil end
    if char then
        for _, candidate in ipairs(GetAimCandidates(char, Config.AimbotPart)) do
            if candidate.part == part then
                return candidate.pos
            end
        end
    end
    return GetAimWorldPoint(part, char) or part.Position
end

local function GetLiveAimPos(part, char)
    return ResolveAimPoint(part, char)
end

GetAimbotTarget = function()
    local center = GetAimViewportCenter()
    local maxFov = Config.AimbotFOV
    local now = tick()

    if AimbotStickyPart and AimbotStickyPart.Parent and AimbotStickyChar and now < AimbotStickyUntil then
        local stickyHum = AimbotStickyChar:FindFirstChildOfClass("Humanoid")
        local stickyPlr = GetPlayerFromCharacter(AimbotStickyChar)
        local stickyPos = GetLiveAimPos(AimbotStickyPart, AimbotStickyChar)
        if stickyHum and stickyPlr and IsValidAimTarget(AimbotStickyChar, stickyHum) and not IsSameTeam(stickyPlr, AimbotStickyChar) then
            local stickyDist = ScoreAimPosition(stickyPos, center, maxFov * 1.45, AimbotStickyChar)
            if stickyDist then
                AimbotTargetPos = stickyPos
                return AimbotStickyPart
            end
        end
    end

    local bestPart, bestPos, bestDist = nil, nil, maxFov

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local char = GetPlayerCharacter(plr)
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if IsValidAimTarget(char, hum) and not IsSameTeam(plr, char) then
                for _, candidate in ipairs(GetAimCandidates(char, Config.AimbotPart)) do
                    local dist = ScoreAimPosition(candidate.pos, center, maxFov, char)
                    if dist and dist < bestDist then
                        bestDist = dist
                        bestPart = candidate.part
                        bestPos = candidate.pos
                    end
                end
            end
        end
    end

    if bestPart then
        local bestChar = bestPart:FindFirstAncestorOfClass("Model")
        AimbotStickyPart = bestPart
        AimbotStickyPos = bestPos
        AimbotStickyChar = bestChar
        AimbotStickyUntil = now + 0.55
        AimbotTargetPos = bestPos
    else
        AimbotStickyPart = nil
        AimbotStickyPos = nil
        AimbotStickyChar = nil
        AimbotStickyUntil = 0
        AimbotTargetPos = nil
    end

    return bestPart
end

local function ReleaseAimCamera()
    if AimbotCamLocked then
        CameraModule.IsEnabled = true
        AimbotCamLocked = false
    end
    if Camera and Camera.CameraType == Enum.CameraType.Scriptable then
        Camera.CameraType = Enum.CameraType.Custom
    end
end

local function LockAimbotCamera()
    if not AimbotCamLocked then
        CameraModule.IsEnabled = false
        AimbotCamLocked = true
    end
    if Camera then
        Camera.CameraType = Enum.CameraType.Scriptable
    end
end

local function GetAimSmoothAlpha(dt)
    local smooth = math.clamp(Config.AimbotSmooth, 0.01, 0.99)
    local turnSpeed = 4 + (1 - smooth) * 48
    return 1 - math.exp(-dt * turnSpeed)
end

local function ApplyCharacterAimRotation(targetPos, alpha)
    local char = ClientShared.LocalPlayer.MyCharacter or Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    if hum.Sit or hum.SeatPart or ClientShared.LocalPlayer:GetSeatPart() then return end
    if Config.FlyEnabled then return end

    if AimbotSavedAutoRotate == nil then
        AimbotSavedAutoRotate = hum.AutoRotate
    end
    hum.AutoRotate = false

    local rootPos = hrp.Position
    local flat = Vector3.new(targetPos.X - rootPos.X, 0, targetPos.Z - rootPos.Z)
    if flat.Magnitude < 0.05 then return end

    local targetCF = CFrame.lookAt(rootPos, rootPos + flat.Unit)
    local _, currentY = hrp.CFrame:ToEulerAnglesYXZ()
    local _, targetY = targetCF:ToEulerAnglesYXZ()

    if AimbotSmoothBodyYaw == nil then
        AimbotSmoothBodyYaw = currentY
    end

    local delta = ((targetY - AimbotSmoothBodyYaw + math.pi) % (2 * math.pi)) - math.pi
    AimbotSmoothBodyYaw = AimbotSmoothBodyYaw + delta * alpha
    hrp.CFrame = CFrame.new(rootPos) * CFrame.Angles(0, AimbotSmoothBodyYaw, 0)
    hrp.AssemblyAngularVelocity = Vector3.zero
end

local function SyncGameAimState(active)
    if not active or not GetShootWeapon() then return end
    pcall(function()
        local lp = ClientShared.LocalPlayer
        if lp.EnableAim and not lp.IsAim then
            lp:EnableAim()
        end
        if lp.EnabledRotForce then
            lp:EnabledRotForce()
        end
    end)
end

local function AimAt(part, dt)
    if not part or not Camera then return end
    LockAimbotCamera()
    SyncGameAimState(true)

    AimbotTargetPos = ResolveAimPoint(part, AimbotStickyChar) or AimbotTargetPos or part.Position
    local rawTargetPos = AimbotTargetPos
    if not AimbotSmoothTargetPos then
        AimbotSmoothTargetPos = rawTargetPos
    end
    local posAlpha = 1 - math.exp(-dt * 22)
    AimbotSmoothTargetPos = AimbotSmoothTargetPos:Lerp(rawTargetPos, posAlpha)

    local lookAlpha = GetAimSmoothAlpha(dt)
    ApplyCharacterAimRotation(AimbotSmoothTargetPos, lookAlpha)

    local char = ClientShared.LocalPlayer.MyCharacter or Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local camPos = GetAimbotCameraPosition(hrp)
    local desiredCF = CFrame.lookAt(camPos, AimbotSmoothTargetPos)

    if not AimbotSmoothCF then
        AimbotSmoothCF = Camera.CFrame
    end

    local blended = AimbotSmoothCF:Lerp(desiredCF, lookAlpha)
    Camera.CFrame = CFrame.new(camPos) * blended.Rotation
    AimbotSmoothCF = Camera.CFrame
end

local AimbotRenderBound = false

pcall(function()
    RunService:UnbindFromRenderStep("EmdenHubAimbot")
end)

local function UpdateFOVCircle()
    if not FOVCircle then return end
    if Config.ShowFOVCircle and Config.AimbotEnabled then
        FOVCircle.Visible = true
        FOVCircle.Radius = Config.AimbotFOV
        FOVCircle.Position = GetAimViewportCenter()
    else
        FOVCircle.Visible = false
    end
end

local function UpdateAimbot()
    Camera = Workspace.CurrentCamera
    UpdateFOVCircle()

    local now = tick()
    local dt = math.clamp(now - LastAimbotTick, 1 / 240, 0.05)
    LastAimbotTick = now

    if Config.AimbotEnabled and (not Config.AimbotHold or AimbotHolding) then
        local part = GetAimbotTarget()
        if part then
            AimAt(part, dt)
            return
        end
    end

    if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        AimbotLocalCamOffset = nil
        AimbotSmoothCF = nil
    end
    ResetAimbotSmooth()
    ReleaseAimCamera()
end

BindAimbotRender = function()
    if AimbotRenderBound then return end
    AimbotRenderBound = true
    RunService:BindToRenderStep("EmdenHubAimbot", Enum.RenderPriority.Last.Value, UpdateAimbot)
end

UnbindAimbotRender = function()
    if not AimbotRenderBound then return end
    AimbotRenderBound = false
    AimbotStickyPart = nil
    AimbotStickyPos = nil
    AimbotStickyChar = nil
    AimbotStickyUntil = 0
    AimbotTargetPos = nil
    ResetAimbotSmooth()
    ReleaseAimCamera()
    pcall(function()
        RunService:UnbindFromRenderStep("EmdenHubAimbot")
    end)
end

local function DestroyPlayerESPEntry(plr)
    local entry = PlayerESPObjects[plr]
    if not entry then return end
    if entry.highlight then pcall(function() entry.highlight:Destroy() end) end
    if entry.billboard then pcall(function() entry.billboard:Destroy() end) end
    PlayerESPObjects[plr] = nil
end

ClearPlayerESP = function()
    for plr in pairs(PlayerESPObjects) do
        DestroyPlayerESPEntry(plr)
    end
    PlayerESPObjects = {}
end

local function SyncPlayerESPVisuals(plr, char)
    local entry = PlayerESPObjects[plr]
    if not entry then
        entry = {}
        PlayerESPObjects[plr] = entry
    end

    local ally = IsSameTeam(plr, char)
    local color = ally and Color3.fromRGB(80, 255, 120) or Color3.fromRGB(255, 80, 80)
    local hrp = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
    if not hrp then return end

    if Config.PlayerESPShowHighlight then
        if not entry.highlight or not entry.highlight.Parent then
            if entry.highlight then pcall(function() entry.highlight:Destroy() end) end
            local hl = Instance.new("Highlight")
            hl.Name = "EmdenHubESP"
            hl.FillTransparency = 0.65
            hl.OutlineTransparency = 0
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.FillColor = color
            hl.OutlineColor = color
            hl.Adornee = char
            hl.Parent = char
            entry.highlight = hl
        else
            entry.highlight.FillColor = color
            entry.highlight.OutlineColor = color
        end
    elseif entry.highlight then
        pcall(function() entry.highlight:Destroy() end)
        entry.highlight = nil
    end

    local showLabel = Config.PlayerESPShowName or Config.PlayerESPShowJob
    if showLabel then
        local lineCount = (Config.PlayerESPShowName and 1 or 0) + (Config.PlayerESPShowJob and 1 or 0)
        if not entry.billboard or not entry.billboard.Parent then
            if entry.billboard then pcall(function() entry.billboard:Destroy() end) end
            local bb = Instance.new("BillboardGui")
            bb.Name = "EmdenHubESPName"
            bb.AlwaysOnTop = true
            bb.Adornee = hrp
            bb.Parent = hrp

            local label = Instance.new("TextLabel")
            label.Name = "Info"
            label.BackgroundTransparency = 1
            label.TextStrokeTransparency = 0.2
            label.TextStrokeColor3 = Color3.new(0, 0, 0)
            label.Font = Enum.Font.GothamBold
            label.TextSize = 14
            label.TextXAlignment = Enum.TextXAlignment.Center
            label.TextYAlignment = Enum.TextYAlignment.Center
            label.Parent = bb

            entry.billboard = bb
            entry.label = label
        end

        entry.billboard.Size = UDim2.new(0, 220, 0, math.max(28, lineCount * 18 + 8))
        entry.billboard.StudsOffset = Vector3.new(0, 3.2, 0)
        entry.label.Size = UDim2.new(1, 0, 1, 0)
        entry.label.Text = BuildPlayerESPText(plr, char)
        entry.label.TextColor3 = color
    elseif entry.billboard then
        pcall(function() entry.billboard:Destroy() end)
        entry.billboard = nil
        entry.label = nil
    end
end

UpdatePlayerESP = function()
    if not Config.PlayerESPEnabled then
        ClearPlayerESP()
        return
    end
    if not Config.PlayerESPShowHighlight and not Config.PlayerESPShowName and not Config.PlayerESPShowJob then
        ClearPlayerESP()
        return
    end

    local seen = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local char = GetPlayerCharacter(plr)
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if char and hrp then
                local dist = (hrp.Position - Camera.CFrame.Position).Magnitude
                if dist <= Config.PlayerESPMaxDist then
                    seen[plr] = true
                    SyncPlayerESPVisuals(plr, char)
                end
            end
        end
    end

    for plr in pairs(PlayerESPObjects) do
        if not seen[plr] then
            DestroyPlayerESPEntry(plr)
        end
    end
end

end -- aim scope

do -- movement scope

local function IsOnFoot()
    if not Character then return false end
    local hum = Character:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    if ClientShared.LocalPlayer:GetSeatPart() then return false end
    if hum:GetState() == Enum.HumanoidStateType.Dead then return false end
    return true
end

GetMovementDeltaTime = function()
    local now = tick()
    local dt = now - LastMovementTick
    LastMovementTick = now
    return math.clamp(dt, 1 / 120, 0.1)
end

local function GetFlatCameraVectors()
    local cam = Camera.CFrame
    local flatLook = Vector3.new(cam.LookVector.X, 0, cam.LookVector.Z)
    local flatRight = Vector3.new(cam.RightVector.X, 0, cam.RightVector.Z)
    if flatLook.Magnitude > 0 then flatLook = flatLook.Unit end
    if flatRight.Magnitude > 0 then flatRight = flatRight.Unit end
    return flatLook, flatRight
end

local function GetFlyMoveInput(includeVertical)
    local flatLook, flatRight = GetFlatCameraVectors()
    local move = Vector3.zero
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += flatLook end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= flatLook end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= flatRight end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += flatRight end
    if includeVertical then
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.yAxis * Config.FlyLift end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move -= Vector3.yAxis * (Config.FlyLift * 0.6) end
    end
    return move
end

-- Direcao 3D pela camera (W/S inclui subir/descer olhando pra cima/baixo)
local function GetFlyMoveInput3D()
    local cam = Camera.CFrame
    local move = Vector3.zero
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += cam.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= cam.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= cam.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += cam.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.yAxis end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move -= Vector3.yAxis end
    return move
end

ZeroCharacterVelocity = function(hrp)
    pcall(function()
        ClientShared.LocalPlayer:SetVelocitiyToPrimaryPart(Vector3.zero)
    end)
    if hrp then
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end
end

local function GetUprightRagdollState()
    local ragdolled = Enums.RagdollState.Ragdolled
    for _, val in pairs(Enums.RagdollState) do
        if val ~= ragdolled then
            return val
        end
    end
    return nil
end

SetupFallProtection = function(hum)
    if not hum then return end
    if not Config.NoFallDamage and not Config.AntiRagdoll then return end
    pcall(function()
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    end)
end

-- Bloqueia ragdoll/queda forcada (comum ao voar muito alto)
local function PreventRagdoll(hum, aggressive)
    if not hum or not Character then return end
    if not aggressive and not Config.AntiRagdoll and not Config.NoFallDamage then return end

    pcall(function()
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    end)

    local ragdolled = Enums.RagdollState.Ragdolled
    if Character:GetAttribute("RagdollState") == ragdolled then
        pcall(function()
            local upright = GetUprightRagdollState()
            if upright then
                Character:SetAttribute("RagdollState", upright)
            end
        end)
        pcall(function() ClientShared.LocalPlayer:UnRagdollCharacter() end)
        pcall(function() ClientShared.LocalPlayer:SetRagdoll(false) end)
        pcall(function() ClientShared.LocalPlayer:StopRagdoll() end)
    end

    if aggressive or Config.AntiRagdoll then
        local state = hum:GetState()
        if state == Enum.HumanoidStateType.Ragdoll
            or state == Enum.HumanoidStateType.FallingDown
            or state == Enum.HumanoidStateType.Freefall then
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)
        end
        if hum.PlatformStand then
            pcall(function() hum.PlatformStand = false end)
        end
    end
end

UpdateFallProtection = function()
    if not Character then return end
    local hum = Character:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    local protect = Config.NoFallDamage or Config.AntiRagdoll or Config.FlyEnabled
    if not protect then return end

    PreventRagdoll(hum, Config.FlyEnabled)
end

local function FindBandageTool()
    return FindInContainers(function(tool)
        if not tool:FindFirstChild("OnActivate") then return false end
        local toolClass = tool:GetAttribute("ToolClass")
        if toolClass == Enums.ToolClasses.Bandage then return true end
        local toolName = tostring(tool:GetAttribute("ToolName") or "")
        return toolName:find("Bandage") ~= nil
            or toolName:find("FirstAid") ~= nil
            or toolName:find("Disinfectant") ~= nil
    end)
end

local function UseBandageSelf()
    if not Character then return false end
    local hum = Character:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 or hum.Health >= hum.MaxHealth then return false end
    if Character:FindFirstChild("Bandage") then return false end

    local tool = FindBandageTool()
    if not tool then return false end

    local onActivate = tool:FindFirstChild("OnActivate")
    if not onActivate then return false end

    if tool.Parent ~= Character then
        pcall(function() hum:EquipTool(tool) end)
        task.wait(0.12)
    end

    local ok, result = pcall(function()
        if onActivate:IsA("RemoteFunction") then
            return onActivate:InvokeServer(1)
        end
        if onActivate:IsA("RemoteEvent") then
            onActivate:FireServer(1)
            return true
        end
        return false
    end)

    if ok and result then
        pcall(function() ClientShared.LocalPlayer:PlaySound("BandageNutzen") end)
    end
    return ok and result == true
end

local function IsDowned()
    if not Character then return false end
    local hum = Character:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    if hum:GetAttribute("IsDeath") == true then return true end
    if Character:GetAttribute("RagdollState") == Enums.RagdollState.Ragdolled then return true end
    if ClientShared.LocalPlayer.LowLife and hum.Health <= 10 then return true end
    return false
end

local function TryFastDeath()
    if not Config.FastDeathEnabled or not IsDowned() then return end

    local now = tick()
    if now - LastFastDeathTick < Config.FastDeathInterval then return end
    LastFastDeathTick = now

    local hum = Character and Character:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    pcall(function()
        if SendDeathTime then
            SendDeathTime:FireServer(DeathSettings.TimeUntilRealDeath or 185)
            SendDeathTime:FireServer(0)
            SendDeathTime:FireServer(9999)
        end
        ClientShared.LocalPlayer:ReplicateSignalEvent("SendDeathTime"):Fire(0)
    end)

    if hum.Health > 0 then
        pcall(function() hum:TakeDamage(hum.Health + 50) end)
    end
end

local function UpdateQuickHeal()
    if not Config.QuickHealEnabled or not Character then return end
    local hum = Character:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 or hum.Health >= hum.MaxHealth then return end
    if hum.Health > Config.QuickHealThreshold then return end
    if IsDowned() then return end

    local now = tick()
    if now - LastQuickHealTick < Config.QuickHealDelay then return end

    if UseBandageSelf() then
        LastQuickHealTick = now
    end
end

UpdateMovementExtras = function()
    if Config.InfiniteStamina then
        pcall(function()
            local lp = ClientShared.LocalPlayer
            if lp.Stamina < lp.MaxStamina then
                lp:AddStamina(lp.MaxStamina)
            end
        end)
    end

    if Config.ForceSprint and IsOnFoot() and not ClientShared.LocalPlayer.LowLife then
        pcall(function()
            ClientShared.LocalPlayer:SetSprint(true)
        end)
    end

    if Config.AutoParachute and Character and not Config.FlyEnabled then
        local hum = Character:FindFirstChildOfClass("Humanoid")
        local chute = Character:FindFirstChild("ParachuteAccessory")
        if hum and chute and hum:GetState() == Enum.HumanoidStateType.Freefall then
            local now = tick()
            if now - LastParachuteTick > 1.5 then
                LastParachuteTick = now
                local tool = FindInContainers(function(t)
                    return t:GetAttribute("ToolName") == "Parachute" and t:FindFirstChild("OnActivate")
                end)
                if tool then
                    local onActivate = tool:FindFirstChild("OnActivate")
                    pcall(function()
                        if onActivate:IsA("RemoteFunction") then
                            onActivate:InvokeServer()
                        elseif DeployChute then
                            DeployChute:FireServer()
                        end
                    end)
                end
            end
        end
    end

    UpdateQuickHeal()
    TryFastDeath()
end

-- Bypass speed: sprint do jogo + CFrame extra (nao altera WalkSpeed)
ApplySpeedBypass = function(dt)
    if not Config.SpeedBoostEnabled or not IsOnFoot() or Config.FlyEnabled then return end

    pcall(function()
        ClientShared.LocalPlayer:SetSprint(true)
    end)

    local hum = Character:FindFirstChildOfClass("Humanoid")
    local hrp = Character:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end

    local state = hum:GetState()
    local grounded = state == Enum.HumanoidStateType.Running
        or state == Enum.HumanoidStateType.Walking
    if not grounded and not Config.SpeedBoostTurbo then return end

    if hum.MoveDirection.Magnitude <= 0 then return end

    local extra = Config.SpeedBoostExtra
    if not Config.SpeedBoostTurbo then
        local currentSpeed = Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z).Magnitude
        extra = math.min(extra, math.max(0, LEGIT_MAX_SPEED - currentSpeed))
    end

    if extra > 0 then
        hrp.CFrame = hrp.CFrame + hum.MoveDirection * extra * dt
    end
end

-- Fly: CFrame translation only (no velocity / PlatformStand) — bypasses FlyHack + FlyCheckV2
SetFlyHumanoidState = function(hum, flying)
    if not hum then return end
    pcall(function()
        if flying then
            if not FlyFreefallDisabled then
                hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
                FlyFreefallDisabled = true
            end
            hum:ChangeState(Enum.HumanoidStateType.Running)
            if hum.PlatformStand then hum.PlatformStand = false end
        elseif FlyFreefallDisabled then
            hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
            FlyFreefallDisabled = false
        end
    end)
end

UpdateFly = function(dt)
    if not Config.FlyEnabled or not IsOnFoot() then
        FlySmoothVel = Vector3.zero
        local hum = Character and Character:FindFirstChildOfClass("Humanoid")
        if hum then SetFlyHumanoidState(hum, false) end
        return
    end

    local hum = Character:FindFirstChildOfClass("Humanoid")
    local hrp = Character:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end

    PreventRagdoll(hum, true)
    SetFlyHumanoidState(hum, true)
    ZeroCharacterVelocity(hrp)

    local move = GetFlyMoveInput3D()
    local targetVel = move.Magnitude > 0 and move.Unit * Config.FlySpeed or Vector3.zero
    local smoothAlpha = 1 - math.exp(-dt * 14)
    FlySmoothVel = FlySmoothVel:Lerp(targetVel, smoothAlpha)

    if FlySmoothVel.Magnitude > 0.05 then
        local newPos = hrp.Position + FlySmoothVel * dt
        hrp.CFrame = CFrame.new(newPos) * (hrp.CFrame - hrp.CFrame.Position)
    end
end

-- Glide: controle no ar via CFrame, sem PlatformStand/Velocity (evita FlyHack/FlyCheckV2)
UpdateGlide = function(dt)
    if Config.FlyEnabled or not Config.GlideEnabled or not IsOnFoot() then return end

    local hum = Character:FindFirstChildOfClass("Humanoid")
    local hrp = Character:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end

    local state = hum:GetState()
    local inAir = state == Enum.HumanoidStateType.Freefall
        or state == Enum.HumanoidStateType.Jumping
        or state == Enum.HumanoidStateType.FallingDown

    if not inAir then return end

    local move = GetFlyMoveInput(false)
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.yAxis * Config.GlideLift end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move -= Vector3.yAxis * (Config.GlideLift * 0.6) end

    if move.Magnitude <= 0 then return end
    hrp.CFrame = hrp.CFrame + move.Unit * Config.GlideSpeed * dt
end

SetupJumpBoost = function()
    if JumpBoostConn then
        JumpBoostConn:Disconnect()
        JumpBoostConn = nil
    end
    if not Config.JumpBoostEnabled and not Config.InfiniteJump then return end

    JumpBoostConn = UserInputService.JumpRequest:Connect(function()
        if not Character then return end
        local hum = Character:FindFirstChildOfClass("Humanoid")
        local hrp = Character:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp then return end

        if Config.InfiniteJump then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end

        if Config.JumpBoostEnabled then
            local boost = math.clamp(Config.JumpBoostPower, 1, 12)
            hrp.CFrame = hrp.CFrame + Vector3.new(0, boost * 0.08, 0)
        end
    end)
end

local function SetupInfiniteJump()
    SetupJumpBoost()
end

UpdateWeaponMods = function()
    if Config.NoRecoil then
        pcall(function()
            ClientShared.LocalPlayer:SetRecoilRate(0)
        end)
    end
    if not Character then return end
    if Config.InfiniteAmmo or Config.RapidFire then
        ClientShared.LocalPlayer.ReloadDeb = false
    end
    for _, tool in ipairs(Character:GetChildren()) do
        if tool:IsA("Tool") then
            if Config.InfiniteAmmo then
                local maxMag = tool:GetAttribute("Magazine") or 30
                if maxMag < 30 then maxMag = 30 end
                tool:SetAttribute("Ammo", 9999)
                tool:SetAttribute("Magazine", maxMag)
            end
        end
    end
end

GetCurrentVehicle = function()
    if _G.CurrentVehicle and _G.CurrentVehicle.Parent then
        return _G.CurrentVehicle
    end
    local seat = ClientShared.LocalPlayer:GetSeatPart()
    if seat then
        return SharedVehicleModule:GetVehicleBySeat(seat) or seat:FindFirstAncestorOfClass("Model")
    end
    if ClientShared.LocalPlayer.MyVehicle then
        return ClientShared.LocalPlayer.MyVehicle
    end
    return nil
end

UpdateVehicleMods = function()
    local vehicle = GetCurrentVehicle()
    if not vehicle then return end

    if Config.VehicleUnlock then
        vehicle:SetAttribute("CanDrive", true)
        vehicle:SetAttribute("Locked", false)
    end

    if Config.VehicleInfiniteFuel then
        if vehicle:GetAttribute("Fuel") ~= nil then
            vehicle:SetAttribute("Fuel", 100)
        end
        if vehicle:GetAttribute("FuelPercent") ~= nil then
            vehicle:SetAttribute("FuelPercent", 100)
        end
    end

    if Config.VehicleNoDamage then
        if vehicle:GetAttribute("Health") ~= nil then
            vehicle:SetAttribute("Health", vehicle:GetAttribute("MaxHealth") or 3000)
        end
    end

    if Config.VehicleSpeedBoost then
        local chassis = vehicle:FindFirstChild("Chassis")
        local part = chassis and (chassis.PrimaryPart or chassis:FindFirstChildWhichIsA("BasePart", true))
        if part then
            local vel = part.AssemblyLinearVelocity
            local flat = Vector3.new(vel.X, 0, vel.Z)
            if flat.Magnitude > 8 then
                local mult = math.clamp(Config.VehicleBoostMult, 1, 1.25)
                part.AssemblyLinearVelocity = flat.Unit * math.min(flat.Magnitude * mult, 120)
            end
        end
    end
end

end -- movement scope

do -- troll scope

-- ============================================================================
-- TROLL SYSTEM (analise: colisao fisica + remotes legitimos)
-- ============================================================================
GetTrollTarget = function()
    if Config.TrollTargetName and Config.TrollTargetName ~= "" then
        local named = Players:FindFirstChild(Config.TrollTargetName)
        if named and named ~= LocalPlayer then
            return named
        end
    end

    if not Character or not Character:FindFirstChild("HumanoidRootPart") then
        return nil
    end

    local origin = Character.HumanoidRootPart.Position
    local best, bestDist = nil, Config.TrollMaxDist

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local char = GetPlayerCharacter(plr)
            if not Config.TrollTeamCheck or not IsSameJob(plr, char) then
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hum and hrp and hum.Health > 0 then
                    local dist = (hrp.Position - origin).Magnitude
                    if dist < bestDist then
                        bestDist = dist
                        best = plr
                    end
                end
            end
        end
    end

    return best
end

ShootAtPlayer = function(plr, hits)
    if not plr or not OnProjectileHit then return false end
    if not GetShootWeapon() then return false end

    local char = GetPlayerCharacter(plr)
    if not char then return false end

    local part = char:FindFirstChild("Head") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart")
    if not part then return false end

    local count = 0
    local total = hits or Config.TrollShootHits
    for _ = 1, total do
        if FireProjectileHit(part, Enums.HitTypes.Character) then
            count += 1
        end
        task.wait(Config.TrollShootDelay)
    end

    return count > 0
end

local function GetVehicleChassisPart(vehicle)
    if not vehicle then return nil end
    local chassis = vehicle:FindFirstChild("Chassis")
    return chassis and (chassis.PrimaryPart or chassis:FindFirstChildWhichIsA("BasePart", true))
end

local function UpdateTrollVehicleRam()
    if not Config.TrollVehicleRam then return end

    local target = GetTrollTarget()
    if not target then return end

    local char = GetPlayerCharacter(target)
    local targetPart = char and char:FindFirstChild("HumanoidRootPart")
    if not targetPart then return end

    local vehicle = GetCurrentVehicle()
    local part = GetVehicleChassisPart(vehicle)
    if not part then return end

    local offset = targetPart.Position - part.Position
    local flat = Vector3.new(offset.X, 0, offset.Z)
    if flat.Magnitude > Config.TrollRamDist or flat.Magnitude < 2 then return end

    local dir = flat.Unit
    part.AssemblyLinearVelocity = dir * Config.TrollRamSpeed + Vector3.new(0, 8, 0)
    pcall(function()
        part.CFrame = CFrame.lookAt(part.Position, part.Position + dir)
    end)
end

local function TrollUnlockNearbyVehicles()
    if not Config.TrollUnlockNearby or not Character or not Character:FindFirstChild("HumanoidRootPart") then return end

    local now = tick()
    if now - LastTrollUnlockTick < 2 then return end
    LastTrollUnlockTick = now

    local origin = Character.HumanoidRootPart.Position
    local folder = Workspace:FindFirstChild("Vehicles")
    if not folder then return end

    for _, vehicle in ipairs(folder:GetChildren()) do
        local part = GetVehicleChassisPart(vehicle) or GetModelPart(vehicle)
        if part then
            local dist = (part.Position - origin).Magnitude
            if dist <= Config.TrollUnlockRadius then
                vehicle:SetAttribute("Locked", false)
                vehicle:SetAttribute("CanDrive", true)
            end
        end
    end
end

local function TrollDestroyTargetVehicle(plr)
    if not Config.TrollDestroyVehicle or not plr then return end

    local char = GetPlayerCharacter(plr)
    local seat = char and char:FindFirstChildOfClass("Humanoid") and char.Humanoid.SeatPart
    if not seat then return end

    local vehFolder = Workspace:FindFirstChild("Vehicles")
    if not vehFolder then return end

    for _, veh in ipairs(vehFolder:GetChildren()) do
        local part = veh.PrimaryPart or veh:FindFirstChildWhichIsA("BasePart")
        if part and (part.Position - seat.Position).Magnitude <= 15 then
            pcall(function()
                if ChangeVehicleHealthRemote then
                    ChangeVehicleHealthRemote:FireServer(veh, -9999)
                end
            end)
            return
        end
    end
end

local function TrollLockTargetVehicle(plr)
    if not Config.TrollLockVehicle or not VehicleKickoutRemote then return end

    local char = GetPlayerCharacter(plr)
    local seat = char and char:FindFirstChildOfClass("Humanoid") and char.Humanoid.SeatPart
    if not seat then return end

    local vehFolder = Workspace:FindFirstChild("Vehicles")
    if not vehFolder then return end

    for _, veh in ipairs(vehFolder:GetChildren()) do
        local part = veh.PrimaryPart or veh:FindFirstChildWhichIsA("BasePart")
        if part and (part.Position - seat.Position).Magnitude <= 15 then
            pcall(function()
                local lockFn = CommFolder:FindFirstChild("LockVehicle")
                if lockFn then lockFn:InvokeServer(veh) end
            end)
            return
        end
    end
end

local function TrollAddWhitelist(plr)
    if not Config.TrollWhitelister or not plr then return end

    local vehFolder = Workspace:FindFirstChild("Vehicles")
    if not vehFolder then return end

    for _, veh in ipairs(vehFolder:GetChildren()) do
        local attr = veh:GetAttribute("WhiteList")
        if attr ~= false then
            pcall(function()
                local wlFn = CommFolder:FindFirstChild("AddPlayerVehicleWhiteList")
                if wlFn then wlFn:InvokeServer(veh, plr) end
            end)
        end
    end
end

local ChangeWantedRemote
local ChangeCrimeTimeRemote
local ChangeCrimeMoneyRemote

local function TrollModifyPlayerStats(plr)
    if not plr then return end

    if Config.TrollModifyWanted and ChangeWantedRemote then
        pcall(function()
            ChangeWantedRemote:FireServer(plr, Config.TrollWantedValue)
        end)
    end

    if Config.TrollModifyCrimeTime and ChangeCrimeTimeRemote then
        pcall(function()
            ChangeCrimeTimeRemote:FireServer(plr, Config.TrollCrimeTimeValue)
        end)
    end

    if Config.TrollCrimeMoneyNegative and ChangeCrimeMoneyRemote then
        pcall(function()
            ChangeCrimeMoneyRemote:FireServer(plr, Config.TrollCrimeMoneyValue)
        end)
    end
end

local function TrollTpVehicleBehind(plr)
    if not Config.TrollTpVehicleBehind or not plr then return end

    local now = tick()
    if now - LastTrollTpTick < 1.5 then return end

    local char = GetPlayerCharacter(plr)
    local targetPart = char and char:FindFirstChild("HumanoidRootPart")
    if not targetPart then return end

    local vehicle = GetCurrentVehicle()
    local part = GetVehicleChassisPart(vehicle)
    if not part then return end

    LastTrollTpTick = now
    part.CFrame = targetPart.CFrame * CFrame.new(0, 1, -10)
    part.AssemblyLinearVelocity = targetPart.CFrame.LookVector * Config.TrollRamSpeed
end

local function TryKickPassenger(plr)
    if not Config.TrollKickPassenger or not plr or not VehicleKickoutRemote then return end

    local vehicle = GetCurrentVehicle()
    if not vehicle then return end

    local now = tick()
    if now - LastTrollKickTick < 1 then return end
    LastTrollKickTick = now

    pcall(function()
        VehicleKickoutRemote:InvokeServer(plr)
    end)
end

local function TrollPunchSpam(plr)
    if not Config.TrollPunchSpam or not plr then return end

    local now = tick()
    if now - LastTrollPunchTick < Config.TrollPunchDelay then return end
    LastTrollPunchTick = now

    -- Usa FireProjectileHit (weapon hit system) - mesmo que ShootAtPlayer mas direto
    local char = GetPlayerCharacter(plr)
    if not char then return end

    local targetPart = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
    if targetPart and OnProjectileHit then
        pcall(function()
            FireProjectileHit(targetPart, Enums.HitTypes.Character)
        end)
    end
end

local function TrollGunSpam(plr)
    if not Config.TrollGunSpam or not plr or not GunInteractionRemote then return end

    local now = tick()
    if now - LastTrollGunTick < Config.TrollPunchDelay then return end
    LastTrollGunTick = now

    -- GunInteraction é para firing de armas - testa com os parâmetros corretos
    local char = GetPlayerCharacter(plr)
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    pcall(function()
        -- "fg" = fire gun, último param é IsAim (pode precisar de arma equipada)
        GunInteractionRemote:FireServer("fg", nil, root, true, false)
    end)
end

local function TrollChaosNearTarget(plr)
    if not Config.TrollChaosGulli or not plr then return end

    local now = tick()
    if now - LastTrollGulliTick < 2 then return end

    local char = GetPlayerCharacter(plr)
    local targetPart = char and char:FindFirstChild("HumanoidRootPart")
    if not targetPart then return end

    for _, obj in ipairs(CollectionService:GetTagged("Gulli")) do
        local part = GetModelPart(obj)
        if part and (part.Position - targetPart.Position).Magnitude <= 25 then
            local remote = obj:FindFirstChild("OnBreakObject")
            if remote then
                LastTrollGulliTick = now
                pcall(function() remote:FireServer() end)
                return
            end
        end
    end
end

ClearTrollVisuals = function()
    for _, obj in pairs(TrollBillboardObjects) do
        pcall(function() obj:Destroy() end)
    end
    TrollBillboardObjects = {}

    for _, obj in pairs(TrollHighlightObjects) do
        pcall(function() obj:Destroy() end)
    end
    TrollHighlightObjects = {}
end

local function UpdateTrollBillboards()
    if not Config.TrollBillboard and not Config.TrollRainbowHighlight then
        ClearTrollVisuals()
        return
    end

    local seen = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local char = GetPlayerCharacter(plr)
            if not Config.TrollTeamCheck or not IsSameJob(plr, char) then
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local dist = Character and Character:FindFirstChild("HumanoidRootPart")
                        and (hrp.Position - Character.HumanoidRootPart.Position).Magnitude
                        or 0
                    if dist <= Config.TrollMaxDist then
                        seen[plr] = true

                        if Config.TrollBillboard and not TrollBillboardObjects[plr] then
                            local bb = Instance.new("BillboardGui")
                            bb.Size = UDim2.new(0, 220, 0, 50)
                            bb.StudsOffset = Vector3.new(0, 4, 0)
                            bb.AlwaysOnTop = true
                            bb.Adornee = hrp

                            local label = Instance.new("TextLabel")
                            label.Size = UDim2.new(1, 0, 1, 0)
                            label.BackgroundTransparency = 1
                            label.Text = Config.TrollBillboardText
                            label.TextColor3 = Color3.fromRGB(255, 60, 60)
                            label.TextStrokeTransparency = 0
                            label.Font = Enum.Font.GothamBlack
                            label.TextSize = 22
                            label.Parent = bb
                            bb.Parent = char
                            TrollBillboardObjects[plr] = bb
                        end

                        if Config.TrollRainbowHighlight then
                            if not TrollHighlightObjects[plr] then
                                local hl = Instance.new("Highlight")
                                hl.FillTransparency = 0.5
                                hl.OutlineTransparency = 0
                                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                                hl.Parent = char
                                TrollHighlightObjects[plr] = hl
                            end
                            local hue = (tick() * 0.6) % 1
                            local color = Color3.fromHSV(hue, 1, 1)
                            TrollHighlightObjects[plr].FillColor = color
                            TrollHighlightObjects[plr].OutlineColor = color
                        end
                    end
                end
            end
        end
    end

    for plr, obj in pairs(TrollBillboardObjects) do
        if not seen[plr] then
            pcall(function() obj:Destroy() end)
            TrollBillboardObjects[plr] = nil
        end
    end

    for plr, obj in pairs(TrollHighlightObjects) do
        if not seen[plr] or not Config.TrollRainbowHighlight then
            pcall(function() obj:Destroy() end)
            TrollHighlightObjects[plr] = nil
        end
    end
end

local function UpdateTrollEmoteSpam()
    if not Config.TrollEmoteSpam or not EmoteStateRemote then return end

    local now = tick()
    if now - LastTrollEmoteTick < Config.TrollEmoteDelay then return end
    LastTrollEmoteTick = now

    local emote = TrollEmoteList[TrollEmoteIndex]
    TrollEmoteIndex = TrollEmoteIndex % #TrollEmoteList + 1

    pcall(function()
        EmoteStateRemote:FireServer(emote)
    end)
end

UpdateTroll = function()
    if not Config.TrollEnabled then
        ClearTrollVisuals()
        return
    end

    local target = GetTrollTarget()

    if Config.TrollAutoShoot and target then
        local now = tick()
        local cooldown = Config.TrollShootDelay * math.max(Config.TrollShootHits, 1) + 0.2
        if now - LastTrollTick >= cooldown then
            LastTrollTick = now
            task.spawn(function()
                ShootAtPlayer(target)
            end)
        end
    end

    UpdateTrollVehicleRam()
    TrollUnlockNearbyVehicles()
    TrollDestroyTargetVehicle(target)
    TrollLockTargetVehicle(target)
    TrollAddWhitelist(target)
    UpdateTrollBillboards()
    UpdateTrollEmoteSpam()
    TryKickPassenger(target)
    TrollChaosNearTarget(target)
    TrollTpVehicleBehind(target)
    TrollModifyPlayerStats(target)
    TrollPunchSpam(target)
    TrollGunSpam(target)
end

end -- troll scope

RunSelfTest = function()
    local lines = {}
    local function add(name, ok, detail)
        table.insert(lines, (ok and "[OK] " or "[FAIL] ") .. name .. (detail and (": " .. detail) or ""))
    end

    add("Communication", Communication.IsLoaded == true, tostring(Communication.IsLoaded))
    add("ClientShared", ClientShared ~= nil)
    add("Camera", Camera ~= nil)
    add("Character", Character ~= nil, Character and Character.Name or "nil")
    add("Collectibles", #FindCollectibles() >= 0, tostring(#FindCollectibles()))
    add("Rob targets", #FindRobberyTargets() >= 0, tostring(#FindRobberyTargets()))
    add("Players", #Players:GetPlayers() > 0, tostring(#Players:GetPlayers()))
    add("Current vehicle", GetCurrentVehicle() ~= nil, GetCurrentVehicle() and GetCurrentVehicle().Name or "none")
    add("Drawing FOV", FOVCircle ~= nil, FOVCircle and "yes" or "no")
    add("Aimbot target", GetAimbotTarget() ~= nil, GetAimbotTarget() and "detected" or "none in FOV")
    add("My job", true, GetJobDisplayName(GetLocalJobCategory()))
    add("OnProjectileHit", OnProjectileHit ~= nil)
    add("UseWeapon", UseWeapon ~= nil)
    add("Fast Collect", FastCollectConnection ~= nil, Config.FastCollectEnabled and "on" or "off")
    add("Auto Rob", AutoRobConnection ~= nil, Config.AutoRobEnabled and "on" or "off")
    add("Troll target", GetTrollTarget() ~= nil, GetTrollTarget() and GetTrollTarget().Name or "none")
    add("Shoot weapon", GetShootWeapon() ~= nil, GetShootWeapon() and GetShootWeapon().Name or "no weapon")
    add("Player ESP", Config.PlayerESPEnabled, (Config.PlayerESPShowName and "name " or "") .. (Config.PlayerESPShowJob and "job " or "") .. (Config.PlayerESPShowHighlight and "highlight" or ""))
    local hum = Character and Character:FindFirstChildOfClass("Humanoid")
    add("WalkSpeed", hum ~= nil, hum and (hum.WalkSpeed .. " (max " .. LEGIT_MAX_SPEED .. ")") or "no char")
    add("Speed bypass", true, "extra=" .. Config.SpeedBoostExtra .. " cap=" .. math.max(0, LEGIT_MAX_SPEED - (hum and hum.WalkSpeed or 0) - 1))

    return table.concat(lines, "\n")
end

StartCombatLoop = function()
    if CombatConnections.MainLoop then return end
    BindAimbotRender()
    ConnectCombat("MainLoop", RunService.RenderStepped:Connect(function()
        Camera = Workspace.CurrentCamera
        UpdatePlayerESP()

        local dt = GetMovementDeltaTime()
        ApplySpeedBypass(dt)
        UpdateFly(dt)
        UpdateGlide(dt)
        UpdateMovementExtras()
        UpdateFallProtection()
        UpdateTroll()
        UpdateWeaponMods()
        UpdateVehicleMods()

    end))

    ConnectCombat("AimHold", UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if IsAimbotHoldInput(input) then
            AimbotHolding = true
        end
        if input.KeyCode == Enum.KeyCode.F then
            Config.FlyEnabled = not Config.FlyEnabled
            if not Config.FlyEnabled then
                FlySmoothVel = Vector3.zero
                local hrp = Character and Character:FindFirstChild("HumanoidRootPart")
                ZeroCharacterVelocity(hrp)
                local hum = Character and Character:FindFirstChildOfClass("Humanoid")
                if hum then SetFlyHumanoidState(hum, false) end
            end
            w:notify("Fly", Config.FlyEnabled and "ON - smooth 3D flight" or "OFF", 2)
        end
    end))
    ConnectCombat("AimRelease", UserInputService.InputEnded:Connect(function(input)
        if IsAimbotHoldInput(input) then
            AimbotHolding = false
        end
    end))
end

StopCombat = function()
    for name in pairs(CombatConnections) do
        DisconnectCombat(name)
    end
    UnbindAimbotRender()
    ClearPlayerESP()
    ClearTrollVisuals()
    if FOVCircle then FOVCircle.Visible = false end
    if JumpBoostConn then JumpBoostConn:Disconnect() JumpBoostConn = nil end
end

end -- combat scope

StartCombatLoop()

-- ============================================================================
-- ESP SYSTEM
-- ============================================================================
local ESPObjects = {}

local function ClearESP()
    for _, obj in pairs(ESPObjects) do
        if obj then
            pcall(function() obj:Destroy() end)
        end
    end
    ESPObjects = {}
end

local function CreateESP(target, color)
    if not target then return end
    
    local part = target:IsA("Model") and (target.PrimaryPart or target:FindFirstChild("HumanoidRootPart")) or target
    if not part then return end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 200, 0, 30)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Adornee = part
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = color
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.Text = target.Name
    
    label.Parent = billboard
    billboard.Parent = target
    
    ESPObjects[target] = billboard
end

local function UpdateESP()
    if not Config.ESPEnabled then
        ClearESP()
        return
    end

    local seen = {}

    if Config.ESPDrops then
        for _, item in pairs(FindCollectibles()) do
            seen[item] = true
            if not ESPObjects[item] then
                CreateESP(item, Config.ESPColor)
            end
        end
    end

    if Config.ESPRobbery then
        for _, entry in ipairs(FindRobberyTargets()) do
            local target = entry.Target
            seen[target] = true
            if not ESPObjects[target] then
                CreateESP(target, Color3.fromRGB(255, 100, 100))
            end
        end
    end

    for target, obj in pairs(ESPObjects) do
        if not seen[target] then
            pcall(function() obj:Destroy() end)
            ESPObjects[target] = nil
        end
    end
end

-- ============================================================================
-- UI - MAIN TAB
-- ============================================================================
mainTab:section("Status")

mainTab:button("Test Connection", function()
    local collectibles = FindCollectibles()
    local robberies = FindRobberyTargets()
    local methods = {}
    for _, entry in ipairs(robberies) do
        methods[entry.Method] = (methods[entry.Method] or 0) + 1
    end
    local detail = {}
    for method, count in pairs(methods) do
        table.insert(detail, method .. "=" .. count)
    end
    w:notify("Test", "Collectibles: " .. #collectibles .. " | Rob: " .. #robberies, 3)
    if #detail > 0 then
        w:notify("Targets", table.concat(detail, ", "), 4)
    end
end)

mainTab:button("Full Self-Test", function()
    local report = RunSelfTest()
    w:notify("Self-Test", report, 8)
end)

mainTab:space(8)

mainTab:section("Info")
mainTab:label("Game: Emergencia Emden")
mainTab:label("Shoot: ATM, Jewels (needs gun)")
mainTab:label("Bank: lockpick > bomb > blowtorch > drill")
mainTab:label("Post office = all F boxes (TP each)")
mainTab:label("Bank = Facher + F boxes + Tresor (no houses)")
mainTab:label("Instant F: fireproximityprompt skips hold")
mainTab:label("Speed/Fly: CFrame bypass (safe)")
mainTab:label("Fly: F key | Aimbot: hold Left Alt")
mainTab:label("Press RightControl to toggle menu")

-- ============================================================================
-- UI - FAST COLLECT TAB
-- ============================================================================
collectTab:section("Fast Collect")

local fastCollectToggle = collectTab:toggle("Enable Fast Collect", false, function(state)
    Config.FastCollectEnabled = state
    if state then
        StartFastCollect()
        w:notify("Fast Collect", "Enabled!", 2)
    else
        StopFastCollect()
        w:notify("Fast Collect", "Disabled!", 2)
    end
end, "fast_collect_enabled")

collectTab:space(8)

collectTab:section("Configurações")

collectTab:slider("Raio de Coleta (studss)", 10, 100, 50, function(val)
    Config.FastCollectRadius = val
end, "collect_radius")

collectTab:slider("Delay (segundos)", 1, 100, 8, function(val)
    Config.FastCollectDelay = val / 100
end, "collect_delay")

collectTab:toggle("Auto E instantâneo (Collect)", true, function(state)
    Config.FastCollectAutoE = state
    UpdateAutoFastPrompt()
end, "fast_collect_auto_e")

collectTab:toggle("Coletar via Hit (OneShotItems)", true, function(state)
    Config.FastCollectUseHit = state
end, "fast_collect_hit")

collectTab:label("Drops = tag OneShotItems (toque/hit)")
collectTab:label("E Collect = auto quando prompt aparece")

collectTab:space(8)

collectTab:toggle("Teleportar até itens", false, function(state)
    Config.TPToItems = state
end, "tp_to_items")

collectTab:slider("Velocidade TP", 20, 100, 50, function(val)
    Config.TPSpeed = val
end, "tp_speed")

collectTab:space(8)

collectTab:section("Ações")

collectTab:button("Testar Fast Collect", function()
    task.spawn(function()
        local lines = {}
        local function add(s) table.insert(lines, s) end
        add("OneShotItems: " .. #FindCollectibles())
        add("fireproximityprompt: " .. tostring(typeof(fireproximityprompt) == "function"))
        add("OnProjectileHit: " .. tostring(OnProjectileHit ~= nil))
        add("Auto E: " .. tostring(Config.FastCollectAutoE))
        local hrp = Character and Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local nearE = 0
            for _, d in Workspace:GetDescendants() do
                if d:IsA("ProximityPrompt") and d.Enabled and d.KeyboardKeyCode == Enum.KeyCode.E then
                    local anchor = d.Parent
                    if anchor and anchor:IsA("BasePart") and (anchor.Position - hrp.Position).Magnitude <= d.MaxActivationDistance + 2 then
                        nearE += 1
                    end
                end
            end
            add("Prompts E perto: " .. nearE)
        end
        w:notify("Collect Test", table.concat(lines, "\n"), 6)
    end)
end)

collectTab:button("Coletar Tudo Agora", function()
    local count = 0
    for _, item in pairs(FindCollectibles()) do
        CollectItem(item)
        count = count + 1
    end
    w:notify("Fast Collect", "Coletados: " .. count, 3)
end)

-- ============================================================================
-- UI - AUTO ROB TAB
-- ============================================================================
robTab:section("Auto Rob")

local autoRobToggle = robTab:toggle("Ativar Auto Rob", false, function(state)
    Config.AutoRobEnabled = state
    if state then
        StartAutoRob()
        w:notify("Auto Rob", "Ativado!", 2)
    else
        StopAutoRob()
        w:notify("Auto Rob", "Desativado!", 2)
    end
end, "auto_rob_enabled")

robTab:space(8)

robTab:section("Configurações")

robTab:slider("Raio de Roubo (studss)", 5, 50, 15, function(val)
    Config.AutoRobRadius = val
end, "rob_radius")

robTab:slider("Delay (segundos)", 1, 100, 50, function(val)
    Config.AutoRobDelay = val / 100
end, "rob_delay")

robTab:slider("Tiros por alvo", 1, 20, 8, function(val)
    Config.RobHitsPerTarget = val
end, "rob_hits")

robTab:slider("Ticks broca", 5, 40, 20, function(val)
    Config.DrillTicks = val
end, "rob_drill_ticks")

robTab:slider("Ticks maçarico", 5, 50, 25, function(val)
    Config.BurnTicks = val
end, "rob_burn_ticks")

robTab:space(8)

robTab:section("Fast F (Prompt)")

robTab:toggle("Auto F instantâneo (fireproximityprompt)", true, function(state)
    Config.RobFastPrompt = state
    UpdateAutoFastPrompt()
    if state then
        w:notify("Fast F", "Qualquer prompt F perto = auto!", 3)
    end
end, "rob_fast_prompt")

robTab:label("Funciona SEM apertar F — ao aparecer o prompt")
robTab:label("Drill, pé de cabra, etc. (hold ignorado)")

robTab:slider("Ticks do prompt F/E", 1, 15, 6, function(val)
    Config.RobPromptTicks = val
end, "rob_prompt_ticks")

robTab:slider("Delay equipar tool (ms)", 10, 80, 35, function(val)
    Config.RobEquipDelay = val / 100
end, "rob_equip_delay")

robTab:label("F = broca/pé cabra | E = lockpick")
robTab:label("Precisa da tool na mochila/toolbar")

robTab:space(8)

robTab:section("Alvos - Tiro")

robTab:toggle("Automat", true, function(state) Config.RobAutomat = state end, "rob_automat")
robTab:toggle("Bank ATM", true, function(state) Config.RobBankATM = state end, "rob_bank")
robTab:toggle("RobBox (Joias)", true, function(state) Config.RobBox = state end, "rob_box")
robTab:toggle("NPC (OnRob)", true, function(state) Config.RobNPC = state end, "rob_npc")

robTab:space(8)

robTab:section("Alvos - Ferramentas")

robTab:toggle("Correios (todas caixas F)", true, function(state) Config.RobPackstation = state end, "rob_packstation")
robTab:toggle("Cofre Banco caixas F", true, function(state) Config.RobBankSafe = state end, "rob_bank_safe")
robTab:toggle("Facher banco (compart.)", true, function(state) Config.RobFacher = state end, "rob_facher")
robTab:toggle("Cofre Banco (Tresor E)", true, function(state) Config.RobTresor = state end, "rob_tresor")
robTab:label("Ignora cofres/caixas de CASAS")
robTab:toggle("Portas (Lockpick)", true, function(state) Config.RobDoor = state end, "rob_door")
robTab:toggle("Grades (Maçarico)", true, function(state) Config.RobBurn = state end, "rob_burn")
robTab:toggle("Bueiro (Pé de Cabra)", true, function(state) Config.RobGulli = state end, "rob_gulli")

robTab:space(8)

robTab:section("Geral")

robTab:toggle("Completar todas caixas antes de trocar", true, function(state)
    Config.RobGroupByStation = state
end, "rob_group_station")
robTab:label("TP em cada caixa F do correio/banco")

robTab:toggle("Bypass ferramentas (mochila)", true, function(state) Config.ToolBypass = state end, "rob_bypass")
robTab:toggle("Teleportar até alvo", true, function(state) Config.RobTeleport = state end, "rob_tp")

robTab:space(8)

robTab:section("Ações")

robTab:button("Testar F + Tools", function()
    task.spawn(function()
        local lines = {}
        local function add(s) table.insert(lines, s) end

        add("fireproximityprompt: " .. tostring(typeof(fireproximityprompt) == "function"))
        add("Drill: " .. tostring(FindDrillTool() ~= nil))
        add("Lockpick: " .. tostring(FindLockpickTool() ~= nil))
        add("Crowbar: " .. tostring(FindCrowbarTool() ~= nil))
        add("Bunsen: " .. tostring(FindBurnTool() ~= nil))
        add("Arma: " .. tostring(GetShootWeapon() ~= nil))

        local targets = FindRobberyTargets()
        local drillCount, correiosDoors, bankDoors = 0, 0, 0
        for _, entry in ipairs(targets) do
            if entry.Method == "drill" then
                drillCount += 1
                if entry.Station and IsCorreiosRobTarget(entry.Station) then correiosDoors += 1 end
                if entry.Station and IsBankRobTarget(entry.Station) then bankDoors += 1 end
            end
        end
        add("Alvos total: " .. #targets)
        add("Caixas F (drill): " .. drillCount .. " | Correio: " .. correiosDoors .. " | Banco: " .. bankDoors)
        if #targets > 0 then
            local entry = targets[1]
            TeleportNearTarget(entry.Target, entry.Door)
            task.wait(0.4)
            EquipRobTool(entry.Method)
            task.wait(Config.RobEquipDelay)
            local prompt = entry.Method == "drill"
                and FindDrillPrompt(entry.Door, entry.Target)
                or (FindRobPrompt(entry.Target, entry.Door, entry.Method) or FindNearbyRobPrompt(entry.Method, 12))
            if prompt then
                add("Prompt: " .. prompt.ActionText .. " [" .. tostring(prompt.KeyboardKeyCode) .. "] hold=" .. prompt.HoldDuration)
                TriggerPrompt(prompt, true)
                add("F/E instantâneo disparado")
                task.wait(0.2)
                add("Aberto: " .. tostring(IsRobEntryDone(entry)))
            else
                add("Sem prompt (equipa tool certa)")
            end
        end

        w:notify("Rob Test", table.concat(lines, "\n"), 8)
    end)
end)

robTab:button("Roubar Tudo Agora", function()
    task.spawn(function()
        local count = 0
        local skipped = 0
        for _ = 1, 200 do
            local entry = PickNextRobEntry(FindRobberyTargets())
            if not entry then break end
            if RobTarget(entry) then
                count = count + 1
            else
                skipped = skipped + 1
                RobbedItems[GetRobEntryKey(entry)] = tick()
            end
            task.wait(0.2)
        end
        w:notify("Auto Rob", "Sucesso: " .. count .. " | Falhou: " .. skipped, 4)
    end)
end)

-- ============================================================================
-- UI - AIMBOT TAB
-- ============================================================================
aimTab:section("Aimbot")

aimTab:toggle("Enable Aimbot", false, function(state)
    Config.AimbotEnabled = state
end, "aimbot_enabled")

aimTab:toggle("Hold to aim (Left Alt)", true, function(state)
    Config.AimbotHold = state
end, "aimbot_hold")

aimTab:toggle("Use RMB instead of Alt", false, function(state)
    Config.AimbotHoldMouse = state
end, "aimbot_hold_mouse")

aimTab:toggle("Team check (JobCategory)", true, function(state)
    Config.AimbotTeamCheck = state
end, "aimbot_team")

aimTab:toggle("Visibility check", false, function(state)
    Config.AimbotVisibleCheck = state
end, "aimbot_vis")

aimTab:toggle("Show FOV circle", true, function(state)
    Config.ShowFOVCircle = state
end, "aimbot_fov_circle")

aimTab:space(8)

aimTab:slider("FOV (pixels)", 20, 400, 160, function(val)
    Config.AimbotFOV = val
end, "aimbot_fov")

aimTab:slider("Smoothness x100 (low=snap, high=smooth)", 1, 95, 35, function(val)
    Config.AimbotSmooth = val / 100
end, "aimbot_smooth")

aimTab:dropdown("Target part", {"Head", "UpperTorso", "HumanoidRootPart", "Closest"}, "Head", function(val)
    Config.AimbotPart = val
end, "aimbot_part")

aimTab:label("Toggle ON + hold Left Alt (or RMB)")
aimTab:label("Camera rotates only — stays on your character")
aimTab:label("Vehicle targets: seat + body aim points")
aimTab:label("Player ESP: ESP tab")

-- ============================================================================
-- UI - MOVIMENTO TAB (bypass anti-cheat Emden)
-- ============================================================================
moveTab:section("Anti-Cheat Notice")
moveTab:label("Does NOT change WalkSpeed/Fly/Noclip directly")
moveTab:label("Server bans: Speed hack, Fly, Noclip")
moveTab:label("Use CFrame bypass modes below")

moveTab:space(8)

moveTab:section("Speed Bypass (safe)")

moveTab:toggle("CFrame Speed Boost", false, function(state)
    Config.SpeedBoostEnabled = state
    if state then
        w:notify("Speed", "Extra max ~" .. math.max(0, LEGIT_MAX_SPEED - 5) .. " studs/s", 3)
    end
end, "speed_boost_enabled")

moveTab:slider("Extra studs/s", 5, 60, 24, function(val)
    Config.SpeedBoostExtra = val
end, "speed_boost_extra")

moveTab:toggle("Turbo mode (ignore cap)", false, function(state)
    Config.SpeedBoostTurbo = state
    if state then
        w:notify("Turbo", "RISK: above legit sprint!", 4)
    end
end, "speed_boost_turbo")

moveTab:label("Normal cap up to sprint (21)")

moveTab:space(8)

moveTab:section("Fly (F key)")
moveTab:label("Smooth 3D flight - WASD + Space/Shift")
moveTab:label("CFrame only — bypasses FlyHack / FlyCheckV2")

moveTab:toggle("Smooth fly", false, function(state)
    Config.FlyEnabled = state
    if not state then
        FlySmoothVel = Vector3.zero
        local hum = Character and Character:FindFirstChildOfClass("Humanoid")
        if hum then SetFlyHumanoidState(hum, false) end
    end
end, "fly_enabled")

moveTab:slider("Fly speed", 30, 300, 120, function(val)
    Config.FlySpeed = val
end, "fly_speed")

moveTab:slider("Up/down force", 1, 30, 12, function(val)
    Config.FlyLift = val / 10
end, "fly_lift")

moveTab:label("Toggle: F key | WASD + Space/Shift")

moveTab:space(8)

moveTab:section("Glide (air)")

moveTab:toggle("Air glide", false, function(state)
    Config.GlideEnabled = state
end, "glide_enabled")

moveTab:slider("Glide speed", 5, 25, 16, function(val)
    Config.GlideSpeed = val
end, "glide_speed")

moveTab:slider("Up/down force", 1, 30, 10, function(val)
    Config.GlideLift = val / 10
end, "glide_lift")

moveTab:label("WASD + Space/Shift in air")

moveTab:space(8)

moveTab:section("Jump")

moveTab:toggle("Jump Boost (CFrame)", false, function(state)
    Config.JumpBoostEnabled = state
    SetupJumpBoost()
end, "jump_boost_enabled")

moveTab:slider("Jump power", 1, 12, 8, function(val)
    Config.JumpBoostPower = val
end, "jump_boost_power")

moveTab:toggle("Infinite Jump", false, function(state)
    Config.InfiniteJump = state
    SetupJumpBoost()
end, "inf_jump")

moveTab:space(8)

moveTab:section("Protection")

moveTab:toggle("Anti Ragdoll", true, function(state)
    Config.AntiRagdoll = state
    local hum = Character and Character:FindFirstChildOfClass("Humanoid")
    if state and hum then SetupFallProtection(hum) end
end, "anti_ragdoll")

moveTab:label("Auto during fly | prevents random falls")

moveTab:toggle("No Fall Damage", false, function(state)
    Config.NoFallDamage = state
    local hum = Character and Character:FindFirstChildOfClass("Humanoid")
    if state and hum then SetupFallProtection(hum) end
end, "no_fall")

moveTab:space(8)

moveTab:section("Stamina / Sprint")

moveTab:toggle("Infinite stamina", false, function(state)
    Config.InfiniteStamina = state
end, "inf_stamina")

moveTab:toggle("Force sprint", false, function(state)
    Config.ForceSprint = state
end, "force_sprint")

moveTab:label("Sprint blocked in LowLife (<=10 HP)")

-- ============================================================================
-- UI - EXTRA TAB (vida / utilidades)
-- ============================================================================
extraTab:section("Curar Rapido")

extraTab:toggle("Auto cura (bandage)", false, function(state)
    Config.QuickHealEnabled = state
end, "quick_heal_enabled")

extraTab:slider("Curar abaixo de HP", 10, 95, 60, function(val)
    Config.QuickHealThreshold = val
end, "quick_heal_threshold")

extraTab:slider("Delay cura (ms)", 2, 20, 4, function(val)
    Config.QuickHealDelay = val / 10
end, "quick_heal_delay")

extraTab:button("Curar agora (bandage)", function()
    if UseBandageSelf() then
        w:notify("Cura", "Bandage usado!", 2)
    else
        w:notify("Cura", "Precisa bandage na mochila/toolbar", 3)
    end
end)

extraTab:label("Usa OnActivate:InvokeServer(1) legitimo")

extraTab:space(8)

extraTab:section("Morte Rapida (caido)")

extraTab:toggle("Fast death quando caido", false, function(state)
    Config.FastDeathEnabled = state
end, "fast_death_enabled")

extraTab:slider("Intervalo tentativa (ms)", 2, 10, 4, function(val)
    Config.FastDeathInterval = val / 10
end, "fast_death_interval")

extraTab:label("Detecta: IsDeath, Ragdoll, LowLife")
extraTab:label("Timer normal: ~185s | sem paramedico: ~15s")

extraTab:space(8)

extraTab:section("Outros (analise)")

extraTab:toggle("Para-quedas auto", false, function(state)
    Config.AutoParachute = state
end, "auto_parachute")

extraTab:label("DeployChute + tool Parachute")
extraTab:label("Stamina/Drinks: AddStamina legitimo")
extraTab:label("Ice shoes: speed 24 so no gelo (nativo)")

extraTab:space(8)

extraTab:section("Wanted / Crime")

extraTab:toggle("Modificar wanted XP", false, function(state)
    Config.TrollModifyWanted = state
end, "troll_modify_wanted")

extraTab:slider("Valor wanted XP", -500, 500, 100, function(val)
    Config.TrollWantedValue = val
end, "troll_wanted_value")

extraTab:toggle("Modificar crime time", false, function(state)
    Config.TrollModifyCrimeTime = state
end, "troll_modify_crime_time")

extraTab:slider("Crime time (seg)", 0, 120, 30, function(val)
    Config.TrollCrimeTimeValue = val
end, "troll_crime_time_value")

extraTab:toggle("Crime money negativo", false, function(state)
    Config.TrollCrimeMoneyNegative = state
end, "troll_crime_money_negative")

extraTab:slider("Crime money ($)", -5000, 0, -1000, function(val)
    Config.TrollCrimeMoneyValue = val
end, "troll_crime_money_value")

-- ============================================================================
-- UI - ARMAS TAB
-- ============================================================================
weaponTab:section("Modificações")

weaponTab:toggle("No Recoil", false, function(state)
    Config.NoRecoil = state
end, "no_recoil")

weaponTab:toggle("Infinite Ammo", false, function(state)
    Config.InfiniteAmmo = state
end, "inf_ammo")

weaponTab:toggle("Skip Reload Debounce", false, function(state)
    Config.RapidFire = state
end, "rapid_fire")

weaponTab:space(8)

weaponTab:label("Ammo: reserva + pente via atributos")
weaponTab:label("Recoil: SetRecoilRate(0) do jogo")

-- ============================================================================
-- UI - VEÍCULOS TAB
-- ============================================================================
vehicleTab:section("Modificações")

vehicleTab:toggle("Speed Boost", false, function(state)
    Config.VehicleSpeedBoost = state
end, "veh_boost")

vehicleTab:slider("Multiplicador", 100, 125, 115, function(val)
    Config.VehicleBoostMult = val / 100
end, "veh_boost_mult")

vehicleTab:label("Max 1.25x - evita CarFly ban")

vehicleTab:toggle("Sem dano (atributo)", false, function(state)
    Config.VehicleNoDamage = state
end, "veh_nodmg")

vehicleTab:toggle("Combustível infinito", false, function(state)
    Config.VehicleInfiniteFuel = state
end, "veh_fuel")

vehicleTab:toggle("Destravar veículo", false, function(state)
    Config.VehicleUnlock = state
end, "veh_unlock")

vehicleTab:space(8)

vehicleTab:button("Info Veículo Atual", function()
    local veh = GetCurrentVehicle()
    if veh then
        w:notify("Veículo", veh.Name .. " | Fuel=" .. tostring(veh:GetAttribute("Fuel")) .. " HP=" .. tostring(veh:GetAttribute("Health")), 4)
    else
        w:notify("Veículo", "Você não está em um veículo", 3)
    end
end)

-- ============================================================================
-- UI - ESP TAB
-- ============================================================================
espTab:section("ESP Principal")

local espToggle = espTab:toggle("Ativar ESP", false, function(state)
    Config.ESPEnabled = state
    if not state then ClearESP() end
end, "esp_enabled")

espTab:space(8)

espTab:section("Opções")

espTab:toggle("Mostrar Drops", true, function(state)
    Config.ESPDrops = state
end, "esp_drops")

espTab:toggle("Mostrar Roubo", true, function(state)
    Config.ESPRobbery = state
end, "esp_robbery")

espTab:space(8)

espTab:section("Cor")

espTab:colorpicker("Cor ESP", Color3.fromRGB(0, 180, 255), function(color)
    Config.ESPColor = color
end, "esp_color")

espTab:space(8)

espTab:section("ESP Jogadores")

espTab:toggle("Ativar ESP Jogadores", false, function(state)
    Config.PlayerESPEnabled = state
    if not state then ClearPlayerESP() end
end, "player_esp_enabled")

espTab:toggle("Mostrar Nome", true, function(state)
    Config.PlayerESPShowName = state
    if not state and not Config.PlayerESPShowJob then ClearPlayerESP() end
end, "player_esp_name")

espTab:toggle("Mostrar Emprego", true, function(state)
    Config.PlayerESPShowJob = state
    if not state and not Config.PlayerESPShowName and not Config.PlayerESPShowHighlight then ClearPlayerESP() end
end, "player_esp_job")

espTab:toggle("Highlight (cor time)", true, function(state)
    Config.PlayerESPShowHighlight = state
    if not state and not Config.PlayerESPShowName and not Config.PlayerESPShowJob then ClearPlayerESP() end
end, "player_esp_highlight")

espTab:slider("Distancia ESP jogadores", 50, 800, 400, function(val)
    Config.PlayerESPMaxDist = val
end, "player_esp_dist")

espTab:label("Verde = mesmo job | Vermelho = inimigo")

-- ============================================================================
-- UI - TROLL TAB
-- ============================================================================
trollTab:section("Analise do jogo")

trollTab:label("FUNCIONA: tiro, carro, ragdoll por colisao")
trollTab:label("FUNCIONA: destrancar carros, emote, billboard")
trollTab:label("NAO FUNCIONA: fling direto (AH.Fling ban)")
trollTab:label("NAO FUNCIONA: ragdoll forcado em outros")
trollTab:label("NAO FUNCIONA: roubar jogador (OnRob = NPC)")

trollTab:space(8)

trollTab:section("Geral")

trollTab:toggle("Ativar Troll", false, function(state)
    Config.TrollEnabled = state
    if not state then ClearTrollVisuals() end
end, "troll_enabled")

trollTab:slider("Distancia alvo (studs)", 20, 250, 100, function(val)
    Config.TrollMaxDist = val
end, "troll_max_dist")

trollTab:toggle("Ignorar mesmo job", false, function(state)
    Config.TrollTeamCheck = not state
end, "troll_ignore_team")

if typeof(trollTab.textbox) == "function" then
    trollTab:textbox("Nome alvo (vazio=mais perto)", "", function(text)
        Config.TrollTargetName = text or ""
    end, "troll_target_name")
else
    trollTab:label("Campo nome alvo não suportado por esta Kyrilib")
end

trollTab:space(8)

trollTab:section("Ataque")

trollTab:toggle("Auto atirar no alvo", false, function(state)
    Config.TrollAutoShoot = state
end, "troll_auto_shoot")

trollTab:slider("Tiros por rajada", 1, 12, 4, function(val)
    Config.TrollShootHits = val
end, "troll_shoot_hits")

trollTab:slider("Delay tiro (ms)", 5, 30, 12, function(val)
    Config.TrollShootDelay = val / 100
end, "troll_shoot_delay")

trollTab:button("Atirar no alvo agora", function()
    local target = GetTrollTarget()
    if not target then
        w:notify("Troll", "Nenhum alvo no raio", 3)
        return
    end
    if not GetShootWeapon() then
        w:notify("Troll", "Precisa de arma equipada", 3)
        return
    end
    task.spawn(function()
        local ok = ShootAtPlayer(target)
        w:notify("Troll", ok and ("Atirou em " .. target.Name) or "Falhou (servidor?)", 3)
    end)
end)

trollTab:label("HitType Character via OnProjectileHit")

trollTab:space(8)

trollTab:section("Veiculo / Colisao")

trollTab:toggle("Carro acelerar no alvo", false, function(state)
    Config.TrollVehicleRam = state
    if state then
        w:notify("Troll", "Entre num carro e acelere!", 3)
    end
end, "troll_vehicle_ram")

trollTab:slider("Velocidade ram", 60, 200, 130, function(val)
    Config.TrollRamSpeed = val
end, "troll_ram_speed")

trollTab:slider("Distancia ram", 30, 250, 150, function(val)
    Config.TrollRamDist = val
end, "troll_ram_dist")

trollTab:toggle("TP carro atras do alvo", false, function(state)
    Config.TrollTpVehicleBehind = state
    if state then
        w:notify("Troll", "RISCO: CarTeleport ban possivel", 4)
    end
end, "troll_tp_vehicle")

trollTab:toggle("Destrancar carros perto", false, function(state)
    Config.TrollUnlockNearby = state
end, "troll_unlock_nearby")

trollTab:slider("Raio destrancar", 15, 100, 50, function(val)
    Config.TrollUnlockRadius = val
end, "troll_unlock_radius")

trollTab:toggle("Expulsar passageiro", false, function(state)
    Config.TrollKickPassenger = state
end, "troll_kick_passenger")

trollTab:label("Ram = fisica real, ragdoll por impacto")

trollTab:space(8)

trollTab:section("Dano / Lock")

trollTab:toggle("Destruir carro do alvo", false, function(state)
    Config.TrollDestroyVehicle = state
end, "troll_destroy_vehicle")

trollTab:toggle("Trancar carro do alvo", false, function(state)
    Config.TrollLockVehicle = state
end, "troll_lock_vehicle")

trollTab:toggle("Permitir usar carro trancado", false, function(state)
    Config.TrollWhitelister = state
end, "troll_whitelister")

trollTab:label("Use ChangeVehicleHealth/FireServer para dano")
trollTab:label("LockVehicle:InvokeServer(vehicleModel) tranca")

trollTab:space(8)

trollTab:section("Ataques Extras")

trollTab:toggle("Punch spam no alvo", false, function(state)
    Config.TrollPunchSpam = state
end, "troll_punch_spam")

trollTab:slider("Delay punch (ms)", 10, 100, 30, function(val)
    Config.TrollPunchDelay = val / 100
end, "troll_punch_delay")

trollTab:toggle("GunInteraction spam", false, function(state)
    Config.TrollGunSpam = state
end, "troll_gun_spam")

trollTab:space(8)

trollTab:section("Anti-Cheat Bypass")

trollTab:toggle("Anti-punch cooldown", false, function(state)
    Config.TrollAntiPunchCD = state
end, "troll_anti_punch_cd")

trollTab:label("OnPunch usa (part, health, HitTypes.Character)")
trollTab:label("GunInteraction: FireServer('fg', tool, root)")

trollTab:space(8)

trollTab:section("Visual / Caos")

trollTab:toggle("Billboard no alvo", false, function(state)
    Config.TrollBillboard = state
    if not state then ClearTrollVisuals() end
end, "troll_billboard")

if typeof(trollTab.textbox) == "function" then
    trollTab:textbox("Texto billboard", "TROLADO", function(text)
        Config.TrollBillboardText = text ~= "" and text or "TROLADO"
    end, "troll_billboard_text")
else
    trollTab:label("Campo texto billboard não suportado por esta Kyrilib")
end

trollTab:toggle("Highlight arco-iris", false, function(state)
    Config.TrollRainbowHighlight = state
    if not state then ClearTrollVisuals() end
end, "troll_rainbow")

trollTab:toggle("Spam emote (EmoteState)", false, function(state)
    Config.TrollEmoteSpam = state
end, "troll_emote_spam")

trollTab:toggle("Quebrar bueiro perto do alvo", false, function(state)
    Config.TrollChaosGulli = state
end, "troll_chaos_gulli")

-- ============================================================================
-- UI - VISUAL TAB
-- ============================================================================
visualTab:section("Temas")

visualTab:button("Azul (Padrão)", function()
    w:apply_theme(kyri.presets["kyri"])
    w:notify("Tema", "Azul aplicado!", 2)
end)

visualTab:button("Midnight", function()
    w:apply_theme(kyri.presets["midnight"])
    w:notify("Tema", "Midnight aplicado!", 2)
end)

visualTab:button("Forest", function()
    w:apply_theme(kyri.presets["forest"])
    w:notify("Tema", "Forest aplicado!", 2)
end)

visualTab:button("Rose", function()
    w:apply_theme(kyri.presets["rose"])
    w:notify("Tema", "Rose aplicado!", 2)
end)

visualTab:space(8)

visualTab:section("Cor de Destaque")

visualTab:colorpicker("Accent", Color3.fromRGB(0, 180, 255), function(c)
    w:accent(c)
end, "accent_color")

visualTab:space(8)

visualTab:section("Controles")

visualTab:button("Destruir Script", function()
    StopFastCollect()
    StopAutoRob()
    UpdateAutoFastPrompt()
    StopCombat()
    ClearESP()
    w:destroy()
end)

-- ============================================================================
-- CHARACTER HANDLING
-- ============================================================================
LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    LastMovementTick = tick()
    FlySmoothVel = Vector3.zero
    task.wait(0.5)
    SetupJumpBoost()
    local hum = char:FindFirstChildOfClass("Humanoid")
    SetupFallProtection(hum)
end)

-- ============================================================================
-- MAIN LOOP
-- ============================================================================
RunService.RenderStepped:Connect(function()
    if Config.ESPEnabled then
        UpdateESP()
    end
end)

-- ============================================================================
-- NOTIFICATION
-- ============================================================================
if Character then
    SetupJumpBoost()
    SetupFallProtection(Character:FindFirstChildOfClass("Humanoid"))
end

UpdateAutoFastPrompt()

w:notify("Emden Hub", "Loaded! Press RightControl", 5)
w:notify("Movement", "Speed/Fly/Glide = CFrame bypass", 4)
w:notify("Fly", "F = smooth 3D flight (WASD + Space/Shift)", 4)
w:notify("Extra", "Quick heal + fast death in Extra tab", 4)
w:notify("Troll", "Troll tab: collision + remotes analysis", 4)
w:notify("Aimbot", "Enable in Aimbot tab + hold Left Alt", 4)