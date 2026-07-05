--[[
================================================================================
MERGE VS MOBS - Slim Hub | KyriLib UI
Game: [⚔️] Merge Vs Mobs (Mesclar Vs Monstros)
PlaceId: 109509628648368
================================================================================
]]

local kyri = loadstring(game:HttpGet("https://kyrilib.dev/kyrilib/"))()

-- ============================================================================
-- KYRILIB UI + JUNKIE KEY SYSTEM
-- ============================================================================
local Junkie = loadstring(game:HttpGet("https://jnkie.com/sdk/library.lua"))()
Junkie.service = "Slim Hub"
Junkie.identifier = "1140699"
Junkie.provider = "Key System"

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

local w = kyri.new("Slim Hub MERGE VS MOBS", {
    GameName = "MergeVsMobs",
    AutoLoad = "default",
    Theme = {
        accent = Color3.fromRGB(255, 120, 60),
        bg = Color3.fromRGB(10, 10, 14),
        container = Color3.fromRGB(16, 16, 22),
        element = Color3.fromRGB(24, 24, 32),
        hover = Color3.fromRGB(34, 34, 46),
        active = Color3.fromRGB(255, 120, 60),
        text = Color3.fromRGB(245, 245, 255),
        subtext = Color3.fromRGB(150, 150, 170),
        border = Color3.fromRGB(42, 42, 58),
    },
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

w:notify("Authenticated", "Loading Slim Hub MERGE VS MOBS...", 3)

-- ============================================================================
-- SERVICES
-- ============================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Packet = require(ReplicatedStorage.Packages.Packet)
local UnitConfig = require(ReplicatedStorage.Shared.Config.UnitConfig)
local UpgradeCosts = require(ReplicatedStorage.Shared.Config.UpgradeCosts)
local MergeProgressionConfig = require(ReplicatedStorage.Shared.Config.MergeProgressionConfig)
local RebirthConfig = require(ReplicatedStorage.Shared.Config.RebirthConfig)
local PickupConfig = require(ReplicatedStorage.Shared.Config.PickupConfig)

local UpgradeClick = Packet("UpgradeClick", Packet.String)
local UnitControlAction = Packet("UnitControlAction", Packet.String)
local MoveUnit = Packet("MoveUnit", Packet.Instance, Packet.NumberU8)
local PreregisterUpdate = Packet("PreregisterUpdate", Packet.Instance, Packet.NumberU8)
local ToggleWaveSpeed = Packet("ToggleWaveSpeed", Packet.Nil)
local RequestUpgradeCosts = Packet("RequestUpgradeCosts", Packet.Nil)
local UpgradeCostsSnapshot = Packet("UpgradeCostsSnapshot", Packet.Any)
local RequestInactiveSlotsState = Packet("RequestInactiveSlotsState", Packet.Nil)
local InactiveSlotsState = Packet("InactiveSlotsState", Packet.Any)
local LoadUnits = Packet("LoadUnits", Packet.Nil)
local OfflineEarningsCollect = Packet("OfflineEarningsCollect", Packet.Any)
local RebirthAttempt = Packet("RebirthAttempt", Packet.Nil)
local WheelRequestSpin = Packet("WheelRequestSpin", Packet.Any)
local WheelRequestState = Packet("WheelRequestState", Packet.Nil)
local WheelSpinState = Packet("WheelSpinState", Packet.Any)
local RequestInventorySnapshot = Packet("RequestInventorySnapshot", Packet.Nil)
local InventorySnapshot = Packet("InventorySnapshot", Packet.Any)
local InventoryAction = Packet("InventoryAction", Packet.Any)
local RequestPotionEffectsSnapshot = Packet("RequestPotionEffectsSnapshot", Packet.Nil)
local PotionEffectsSnapshot = Packet("PotionEffectsSnapshot", Packet.Any)

local PotionConfig = require(ReplicatedStorage.Shared.Config.PotionConfig)

-- ============================================================================
-- STATE
-- ============================================================================
local State = {
    running = true,
    loopDelay = 1.2,

    autoBuyUnit = false,
    autoBuyLevel = false,
    autoMerge = false,
    mergeDelay = 0.45,
    autoEquipTower = false,
    reserveCoins = 0,
    maxUnitsBeforeStop = 0,

    autoDamage = false,
    autoFireRate = false,
    autoBaseHealth = false,
    autoActiveSlots = false,
    autoCoinValue = false,
    autoGemChance = false,
    autoPickupRadius = false,

    autoCollectPickups = false,
    pickupMagnetRadius = 180,
    autoClaimOffline = false,
    autoRebirth = false,
    autoWaveSpeed = false,

    autoWheelSpin = false,
    autoConsumePotions = false,
    consumeAllPotions = false,
    consumePotionsWhenIdle = true,

    walkSpeedEnabled = false,
    walkSpeed = 32,
    jumpPowerEnabled = false,
    jumpPower = 50,
}

local Connections = {}
local mergeLoopRunning = false
local buyLoopRunning = false
local pickupLoopConn = nil

local CachedCosts = {}
local CachedCurrencies = {}
local InactiveSlots = { filled = -1, capacity = 16 }
local savedServerPickupRadius = nil
local lastMagnetMaintainAt = 0
local lastCostRefreshAt = 0
local lastWheelStateRequestAt = 0
local lastWheelSpinAt = 0
local lastInventoryRequestAt = 0
local lastPotionConsumeAt = 0

local CachedWheelState = {}
local CachedInventoryPotions = {}
local CachedPotionEffects = {
    effects = {},
    serverTime = 0,
    receivedAt = 0,
}

-- ============================================================================
-- GAME HELPERS
-- ============================================================================
local function notify(title, text, duration)
    w:notify(title, text, duration or 2)
end

local function getPlotRoot()
    local plotNumber = LocalPlayer:FindFirstChild("PlotNumber")
    if not plotNumber then return nil end

    local map = Workspace:FindFirstChild("Map")
    local plots = map and map:FindFirstChild("Plots")
    local plotFolder = plots and plots:FindFirstChild(tostring(plotNumber.Value))
    if not plotFolder then return nil end

    local template = plotFolder:FindFirstChild("Template")
    return template or plotFolder
end

local function getUnitsFolder()
    local map = Workspace:FindFirstChild("Map")
    local globalUnits = map and map:FindFirstChild("GlobalUnits")
    if not globalUnits then return nil end
    return globalUnits:FindFirstChild(tostring(LocalPlayer.UserId) .. "_PlayerUnits")
end

local function getUnits()
    local folder = getUnitsFolder()
    if not folder then return {} end

    local units = {}
    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("Model") and child:GetAttribute("Id") and not child:GetAttribute("LocalBusy") then
            table.insert(units, child)
        end
    end
    return units
end

local function getAllUnitsRaw()
    local folder = getUnitsFolder()
    if not folder then return {} end

    local units = {}
    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("Model") and child:GetAttribute("Id") then
            table.insert(units, child)
        end
    end
    return units
end

local function getSlotIndex(unit)
    local slotRef = unit:FindFirstChild("SlotRef")
    if slotRef and slotRef:IsA("ObjectValue") and slotRef.Value then
        return tonumber(slotRef.Value.Name)
    end
    return nil
end

local function getCoins()
    local coins = LocalPlayer:GetAttribute("Coins")
    if typeof(coins) == "number" then
        return coins
    end
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    local coinValue = leaderstats and leaderstats:FindFirstChild("Coins")
    if coinValue then
        local n = tonumber(coinValue.Value)
        if n then return n end
    end
    return 0
end

local function getGems()
    local gems = LocalPlayer:GetAttribute("Gems")
    return typeof(gems) == "number" and gems or 0
end

local function getMergeMaxLevel()
    local realmId = LocalPlayer:GetAttribute("CurrentRealmId") or 1
    local range = MergeProgressionConfig.LevelRangeByRealm[realmId]
    if range and typeof(range.Max) == "number" then
        return range.Max
    end
    return MergeProgressionConfig.DefaultRealmMergeLevelRangeSize or #UnitConfig
end

local function canMergeLevel(level)
    if typeof(level) ~= "number" then return false end
    local nextLevel = math.floor(level + 0.5) + 1
    if nextLevel > #UnitConfig then return false end
    return nextLevel <= getMergeMaxLevel()
end

local function getUnitDps(level)
    local cfg = UnitConfig[level]
    if not cfg or typeof(cfg.Attack) ~= "table" then return 0 end
    local attack = cfg.Attack
    local damage = attack.Damage or 0
    local rate = attack.Rate or 1
    if rate <= 0 then rate = 1 end
    local dps = damage / rate
    if tostring(attack.Mechanic) == "BoomerangProjectile" then
        dps *= 2
    end
    return dps
end

local function getActiveSlotCount()
    local plot = getPlotRoot()
    if not plot then return 0 end
    local active = plot:FindFirstChild("ActiveSlots")
    return active and #active:GetChildren() or 0
end

local function getUpgradeLevel(upgradeType)
    local map = {
        Damage = "DamageUpgradeLevel",
        FireRate = "FireRateUpgradeLevel",
        SpawnLevel = "HighestSummon",
        SpawnUnit = "HighestSummonEver",
    }
    local attr = map[upgradeType]
    if attr then
        local value = LocalPlayer:GetAttribute(attr)
        if typeof(value) == "number" then
            return math.max(0, math.floor(value))
        end
    end
    return 0
end

local function applyUpgradeCostSnapshot(snapshot)
    if typeof(snapshot) ~= "table" then
        return
    end

    for key, value in pairs(snapshot) do
        local upgradeType = key
        if typeof(key) == "string" and key:lower():sub(-6) == "button" then
            upgradeType = key:sub(1, -7)
        end

        if typeof(value) == "table" then
            if typeof(value.Cost) == "number" then
                CachedCosts[upgradeType] = value.Cost
            end
            if typeof(value.CurrencyType) == "string" then
                CachedCurrencies[upgradeType] = value.CurrencyType
            end
        elseif typeof(value) == "number" then
            CachedCosts[upgradeType] = value
        end
    end
end

local function getUpgradeCurrency(upgradeType)
    if typeof(CachedCurrencies[upgradeType]) == "string" then
        return CachedCurrencies[upgradeType]
    end
    if UpgradeCosts.getCurrencyType then
        local ok, currency = pcall(function()
            return UpgradeCosts.getCurrencyType(upgradeType)
        end)
        if ok and typeof(currency) == "string" then
            return currency
        end
    end
    return "Coins"
end

local function getUpgradeCost(upgradeType)
    if typeof(CachedCosts[upgradeType]) == "number" then
        return CachedCosts[upgradeType]
    end

    local currentLevel = getUpgradeLevel(upgradeType)
    local costIndex = currentLevel + 1
    if upgradeType == "SpawnUnit" then
        costIndex = 1
    end

    local ok, cost = pcall(function()
        return UpgradeCosts.getUpgradeCost(upgradeType, costIndex)
    end)
    if ok and typeof(cost) == "number" then
        return cost
    end
    return math.huge
end

local function canAffordUpgrade(upgradeType)
    local cost = getUpgradeCost(upgradeType)
    if cost == math.huge then
        return false
    end
    local currency = getUpgradeCurrency(upgradeType)
    if currency == "Gems" then
        return getGems() >= cost
    end
    return getCoins() >= cost + State.reserveCoins
end

local function isMaxUpgrade(upgradeType)
    if UpgradeCosts.isMaxLevel then
        local ok, result = pcall(function()
            return UpgradeCosts.isMaxLevel(upgradeType, getUpgradeLevel(upgradeType))
        end)
        if ok then return result end
    end
    local maxLevel = UpgradeCosts.getMaxLevel and UpgradeCosts.getMaxLevel(upgradeType)
    if typeof(maxLevel) == "number" then
        return getUpgradeLevel(upgradeType) >= maxLevel
    end
    return false
end

local function buyUpgrade(upgradeType)
    UpgradeClick:Fire(upgradeType)
end

local function buyUnit()
    buyUpgrade("SpawnUnit")
end

local function buySpawnLevel()
    buyUpgrade("SpawnLevel")
end

local function mergeAllNative()
    local pulse = LocalPlayer:GetAttribute("MergeAllPressedPulse")
    if typeof(pulse) ~= "number" then
        pulse = 0
    end
    LocalPlayer:SetAttribute("MergeAllPressedPulse", pulse + 1)
    UnitControlAction:Fire("MergeAll")
end

local function equipBestTower()
    UnitControlAction:Fire("EquipBest")
end

local function isUnitBusy(unit)
    return unit:GetAttribute("LocalBusy") == true
end

local function waitForUnitsIdle(maxWait)
    local deadline = os.clock() + (maxWait or 2.5)
    while os.clock() < deadline do
        local anyBusy = false
        for _, unit in ipairs(getAllUnitsRaw()) do
            if isUnitBusy(unit) then
                anyBusy = true
                break
            end
        end
        if not anyBusy then
            return true
        end
        task.wait(0.12)
    end
    return false
end

local function performMerge(source, targetSlot)
    if not source or not source.Parent or isUnitBusy(source) then
        return false
    end
    if typeof(targetSlot) ~= "number" then
        return false
    end

    pcall(function()
        PreregisterUpdate:Fire(source, targetSlot)
    end)
    task.wait(0.28)
    pcall(function()
        MoveUnit:Fire(source, targetSlot)
    end)
    task.wait(State.mergeDelay)
    waitForUnitsIdle(2.5)
    return true
end

local function collectMergeGroups()
    local grouped = {}
    for _, unit in ipairs(getUnits()) do
        local level = unit:GetAttribute("Level")
        local slot = getSlotIndex(unit)
        if typeof(level) == "number" and slot and canMergeLevel(level) then
            grouped[level] = grouped[level] or {}
            table.insert(grouped[level], unit)
        end
    end
    return grouped
end

local function mergeAllPairs()
    local merged = 0
    local safety = 0

    while safety < 40 do
        safety += 1

        local grouped = collectMergeGroups()
        local levels = {}
        for level in pairs(grouped) do
            table.insert(levels, level)
        end
        table.sort(levels)

        local didMerge = false
        for _, level in ipairs(levels) do
            local list = grouped[level]
            if list and #list >= 2 then
                table.sort(list, function(a, b)
                    return (getSlotIndex(a) or 999) < (getSlotIndex(b) or 999)
                end)

                local target = list[1]
                local source = list[2]
                local targetSlot = getSlotIndex(target)

                if targetSlot and performMerge(source, targetSlot) then
                    merged += 1
                    didMerge = true
                    break
                end
            end
        end

        if not didMerge then
            break
        end
    end

    return merged
end

local function runAutoMergeLoop()
    if mergeLoopRunning then
        return
    end
    mergeLoopRunning = true

    task.spawn(function()
        while State.running and State.autoMerge do
            if LocalPlayer:GetAttribute("OwnsMergeAll") == true then
                pcall(mergeAllNative)
                task.wait(1.2)
            end

            local merged = mergeAllPairs()
            if merged > 0 then
                notify("Auto Merge", "Merged " .. merged .. " pairs", 2)
                task.wait(0.4)
            else
                task.wait(State.loopDelay)
            end
        end
        mergeLoopRunning = false
    end)
end

local function tryManualMerge()
    return mergeAllPairs()
end

local function countMergeFieldUnits()
    local count = 0
    for _, unit in ipairs(getAllUnitsRaw()) do
        local slot = getSlotIndex(unit)
        if typeof(slot) == "number" and slot >= 1 and slot <= 99 then
            count += 1
        end
    end
    return count
end

local function getMergeSlotCapacity()
    if InactiveSlots.capacity > 0 then
        return InactiveSlots.capacity
    end

    local plot = getPlotRoot()
    local slots = plot and plot:FindFirstChild("Slots")
    if slots then
        return #slots:GetChildren()
    end
    return 16
end

local function getMergeSlotsFilled()
    if InactiveSlots.filled >= 0 then
        return InactiveSlots.filled
    end
    return countMergeFieldUnits()
end

local function hasFreeSlot()
    local capacity = getMergeSlotCapacity()
    local filled = getMergeSlotsFilled()

    if State.maxUnitsBeforeStop > 0 and filled >= State.maxUnitsBeforeStop then
        return false
    end
    return filled < capacity
end

local function refreshUpgradeCostsIfNeeded()
    local now = os.clock()
    if now - lastCostRefreshAt < 4 then
        return
    end
    lastCostRefreshAt = now
    pcall(function()
        RequestUpgradeCosts:Fire()
        RequestInactiveSlotsState:Fire()
    end)
end

local function tryAutoBuyUnit()
    refreshUpgradeCostsIfNeeded()
    if not hasFreeSlot() then return end
    if not canAffordUpgrade("SpawnUnit") then return end
    buyUnit()
end

local function runAutoBuyLoop()
    if buyLoopRunning then
        return
    end
    buyLoopRunning = true

    task.spawn(function()
        while State.running and State.autoBuyUnit do
            tryAutoBuyUnit()
            task.wait(0.35)
        end
        buyLoopRunning = false
    end)
end

local function tryAutoBuyLevel()
    if not canAffordUpgrade("SpawnLevel") then return end
    if isMaxUpgrade("SpawnLevel") then return end
    buySpawnLevel()
end

local function tryAutoUpgrades()
    local upgrades = {
        { enabled = State.autoDamage, type = "Damage" },
        { enabled = State.autoFireRate, type = "FireRate" },
        { enabled = State.autoBaseHealth, type = "BaseHealth" },
        { enabled = State.autoActiveSlots, type = "ActiveSlots" },
        { enabled = State.autoCoinValue, type = "CoinValue" },
        { enabled = State.autoGemChance, type = "GemChance" },
        { enabled = State.autoPickupRadius, type = "PickupRadius" },
    }

    for _, entry in ipairs(upgrades) do
        if entry.enabled and not isMaxUpgrade(entry.type) and canAffordUpgrade(entry.type) then
            buyUpgrade(entry.type)
            return
        end
    end
end

local function getDefaultPickupRadius()
    local radius = LocalPlayer:GetAttribute("PickupRadius")
    if typeof(radius) == "number" and radius > 0 then
        return radius
    end
    return PickupConfig.PICKUP_RADIUS or 10
end

local function applyPickupMagnet(enable)
    if enable then
        if savedServerPickupRadius == nil then
            savedServerPickupRadius = getDefaultPickupRadius()
        end
        LocalPlayer:SetAttribute("PickupRadius", State.pickupMagnetRadius)
        return
    end

    local restore = savedServerPickupRadius
    if typeof(restore) ~= "number" or restore <= 0 then
        restore = PickupConfig.PICKUP_RADIUS or 10
    end
    LocalPlayer:SetAttribute("PickupRadius", restore)
    savedServerPickupRadius = nil
end

local function maintainPickupMagnet()
    if not State.autoCollectPickups then
        return
    end

    local now = os.clock()
    if now - lastMagnetMaintainAt < 0.4 then
        return
    end
    lastMagnetMaintainAt = now

    local current = LocalPlayer:GetAttribute("PickupRadius")
    if typeof(current) ~= "number" or current + 0.5 < State.pickupMagnetRadius then
        LocalPlayer:SetAttribute("PickupRadius", State.pickupMagnetRadius)
    end
end

local function ensurePickupLoop()
    if State.autoCollectPickups then
        applyPickupMagnet(true)
        if not pickupLoopConn then
            pickupLoopConn = RunService.Heartbeat:Connect(maintainPickupMagnet)
            table.insert(Connections, pickupLoopConn)
        end
    else
        applyPickupMagnet(false)
        if pickupLoopConn then
            pickupLoopConn:Disconnect()
            pickupLoopConn = nil
        end
    end
end

local function getEstimatedPotionServerTime()
    return CachedPotionEffects.serverTime + math.max(0, time() - CachedPotionEffects.receivedAt)
end

local function getPotionEffectSnapshotKey(effectType)
    if effectType == "Money" then
        return "Coin"
    end
    return effectType
end

local function isPotionEffectActive(effectType)
    local key = getPotionEffectSnapshotKey(effectType)
    local effects = CachedPotionEffects.effects
    local effect = effects[key]
    if effect == nil and key == "Coin" then
        effect = effects.Money
    end
    if typeof(effect) ~= "table" or typeof(effect.ExpiresAt) ~= "number" then
        return false
    end
    return effect.ExpiresAt > getEstimatedPotionServerTime() + 3
end

local function getPotionEffectType(potionId)
    local cfg = PotionConfig[potionId]
    if typeof(cfg) == "table" and typeof(cfg.EffectType) == "string" then
        return cfg.EffectType
    end
    return nil
end

local function countInventoryPotions()
    return #CachedInventoryPotions
end

local function refreshWheelStateIfNeeded()
    local now = os.clock()
    if now - lastWheelStateRequestAt < 4 then
        return
    end
    lastWheelStateRequestAt = now
    pcall(function()
        WheelRequestState:Fire()
    end)
end

local function refreshInventoryIfNeeded()
    local now = os.clock()
    if now - lastInventoryRequestAt < 6 then
        return
    end
    lastInventoryRequestAt = now
    pcall(function()
        RequestInventorySnapshot:Fire()
        RequestPotionEffectsSnapshot:Fire()
    end)
end

local function isFreeSpinReady(state)
    if state.FreeSpinAvailable == true then
        return true
    end
    if typeof(state.FreeSpinNextReadyAtUnix) == "number" and typeof(state.ServerTime) == "number" then
        return state.ServerTime >= state.FreeSpinNextReadyAtUnix
    end
    return false
end

local function requestWheelSpin(count)
    local spinCount = typeof(count) == "number" and math.max(1, math.floor(count)) or 1
    pcall(function()
        WheelRequestSpin:Fire({ Count = spinCount })
    end)
    lastWheelSpinAt = os.clock()
end

local function tryAutoWheelSpin()
    if not State.autoWheelSpin then
        return
    end

    refreshWheelStateIfNeeded()

    if os.clock() - lastWheelSpinAt < 8 then
        return
    end

    local state = CachedWheelState
    if typeof(state) ~= "table" then
        return
    end

    if state.SpinInProgress == true then
        return
    end

    local pending = typeof(state.PendingSpins) == "number" and state.PendingSpins or 0
    if pending > 0 then
        requestWheelSpin(pending)
        return
    end

    if isFreeSpinReady(state) then
        requestWheelSpin(1)
    end
end

local function consumeSinglePotion(potion)
    if typeof(potion) ~= "table" or typeof(potion.SaveId) ~= "string" then
        return false
    end
    pcall(function()
        InventoryAction:Fire({
            Action = "UsePotion",
            Category = "Potions",
            SaveId = potion.SaveId,
        })
    end)
    return true
end

local function consumeAllPotionsAction()
    pcall(function()
        InventoryAction:Fire({
            Action = "UseAllPotions",
            Category = "Potions",
        })
    end)
end

local function tryAutoConsumePotions()
    if not State.autoConsumePotions then
        return
    end

    local now = os.clock()
    if now - lastPotionConsumeAt < 2.5 then
        return
    end

    refreshInventoryIfNeeded()

    if countInventoryPotions() <= 0 then
        return
    end

    if State.consumeAllPotions then
        if State.consumePotionsWhenIdle then
            for _, potion in ipairs(CachedInventoryPotions) do
                local effectType = getPotionEffectType(potion.Id)
                if effectType and isPotionEffectActive(effectType) then
                    return
                end
            end
        end
        lastPotionConsumeAt = now
        consumeAllPotionsAction()
        return
    end

    for _, potion in ipairs(CachedInventoryPotions) do
        local effectType = getPotionEffectType(potion.Id)
        if not State.consumePotionsWhenIdle or not effectType or not isPotionEffectActive(effectType) then
            lastPotionConsumeAt = now
            consumeSinglePotion(potion)
            return
        end
    end
end

local function tryClaimOffline()
    pcall(function()
        OfflineEarningsCollect:Fire({ Mode = "Base" })
    end)
end

local function tryAutoRebirth()
    local rebirths = 0
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    local rebirthValue = leaderstats and leaderstats:FindFirstChild("Rebirths")
    if rebirthValue then
        rebirths = tonumber(rebirthValue.Value) or 0
    end

    local nextRebirth = RebirthConfig[tostring(rebirths + 1)] or RebirthConfig[rebirths + 1]
    if not nextRebirth then return end

    local requiredWave = nextRebirth.RequiredWave or nextRebirth.WaveRequired or nextRebirth.Wave
    local currentWave = LocalPlayer:GetAttribute("MaxWaveReached") or LocalPlayer:GetAttribute("WaveCurrentGlobal") or 1

    if typeof(requiredWave) == "number" and currentWave >= requiredWave then
        pcall(function()
            RebirthAttempt:Fire()
        end)
    end
end

local function applyWalkSpeed()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = State.walkSpeedEnabled and State.walkSpeed or (LocalPlayer:GetAttribute("BaseWalkSpeed") or 32)
    end
end

local function applyJumpPower()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.JumpPower = State.jumpPowerEnabled and State.jumpPower or 50
    end
end

local function getStatusText()
    local units = getUnits()
    local bestLevel = 0
    for _, unit in ipairs(units) do
        local level = unit:GetAttribute("Level")
        if typeof(level) == "number" and level > bestLevel then
            bestLevel = level
        end
    end

    local wave = LocalPlayer:GetAttribute("WaveCurrentGlobal") or 1
    local realm = LocalPlayer:GetAttribute("WaveRealmName") or "?"
    local rebirths = 0
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats and leaderstats:FindFirstChild("Rebirths") then
        rebirths = leaderstats.Rebirths.Value
    end

    return string.format(
        "Plot %s | Wave %s | Rebirths %s | Realm %s\nCoins %s | Gems %s | Field %s/%s | Best Lv.%s",
        LocalPlayer:FindFirstChild("PlotNumber") and LocalPlayer.PlotNumber.Value or "?",
        tostring(wave),
        tostring(rebirths),
        tostring(realm),
        tostring(getCoins()),
        tostring(getGems()),
        tostring(getMergeSlotsFilled()),
        tostring(getMergeSlotCapacity()),
        tostring(bestLevel)
    )
end

-- ============================================================================
-- MAIN LOOP
-- ============================================================================
local function automationTick()
    if State.autoBuyLevel then
        tryAutoBuyLevel()
    end

    if State.autoEquipTower then
        equipBestTower()
    end

    tryAutoUpgrades()

    if State.autoClaimOffline then
        tryClaimOffline()
    end

    if State.autoRebirth then
        tryAutoRebirth()
    end

    tryAutoWheelSpin()
    tryAutoConsumePotions()

    applyWalkSpeed()
    applyJumpPower()
end

table.insert(Connections, UpgradeCostsSnapshot.OnClientEvent:Connect(applyUpgradeCostSnapshot))
table.insert(Connections, InactiveSlotsState.OnClientEvent:Connect(function(payload)
    if typeof(payload) ~= "table" then
        return
    end
    if typeof(payload.Filled) == "number" then
        InactiveSlots.filled = payload.Filled
    end
    if typeof(payload.Capacity) == "number" then
        InactiveSlots.capacity = payload.Capacity
    end
end))
table.insert(Connections, WheelSpinState.OnClientEvent:Connect(function(payload)
    if typeof(payload) ~= "table" then
        return
    end
    CachedWheelState = payload
end))
table.insert(Connections, InventorySnapshot.OnClientEvent:Connect(function(payload)
    if typeof(payload) ~= "table" then
        return
    end

    CachedInventoryPotions = {}
    local potions = payload.Potions
    if typeof(potions) == "table" then
        for _, item in ipairs(potions) do
            if typeof(item) == "table" and typeof(item.SaveId) == "string" then
                table.insert(CachedInventoryPotions, item)
            end
        end
    end
end))
table.insert(Connections, PotionEffectsSnapshot.OnClientEvent:Connect(function(payload)
    if typeof(payload) ~= "table" then
        return
    end

    CachedPotionEffects.effects = typeof(payload.Effects) == "table" and payload.Effects or {}
    CachedPotionEffects.serverTime = typeof(payload.ServerTime) == "number" and payload.ServerTime or os.time()
    CachedPotionEffects.receivedAt = time()
end))
task.spawn(function()
    task.wait(2)
    pcall(function()
        RequestUpgradeCosts:Fire()
        RequestInactiveSlotsState:Fire()
        LoadUnits:Fire()
        WheelRequestState:Fire()
        RequestInventorySnapshot:Fire()
        RequestPotionEffectsSnapshot:Fire()
    end)

    while State.running do
        pcall(automationTick)
        task.wait(State.loopDelay)
    end
end)

-- ============================================================================
-- TABS
-- ============================================================================
local mainTab = w:tab("Main", "home")
local unitsTab = w:tab("Units", "swords")
local upgradesTab = w:tab("Upgrades", "trending-up")
local farmTab = w:tab("Farm", "coins")
local playerTab = w:tab("Player", "user")
local miscTab = w:tab("Misc", "settings")

-- MAIN
mainTab:section("Status")
mainTab:paragraph("Live stats", "Use the button below to view coins, wave, units, and rebirths.")
mainTab:button("Refresh Status", function()
    notify("Status", getStatusText(), 5)
end, "refresh_status")
mainTab:space(6)

mainTab:section("Automation")
mainTab:slider("Interval (seconds)", 0.3, 5, 1.2, function(val)
    State.loopDelay = val
end, "loop_delay", 0.1)

mainTab:slider("Reserve coins", 0, 100000, 0, function(val)
    State.reserveCoins = math.floor(val)
end, "reserve_coins")

mainTab:slider("Max units (0 = auto)", 0, 20, 0, function(val)
    State.maxUnitsBeforeStop = math.floor(val)
end, "max_units")

mainTab:space(8)
mainTab:section("Quick Actions")
mainTab:button("Buy Unit", function()
    buyUnit()
    notify("Purchase", "Unit requested")
end)
mainTab:button("Merge All (Gamepass)", function()
    mergeAllNative()
    notify("Merge", "Native Merge All sent")
end)
mainTab:button("Merge All Matching", function()
    task.spawn(function()
        local count = mergeAllPairs()
        notify("Merge", count > 0 and ("Merged " .. count .. " pairs") or "No pairs available", 3)
    end)
end)
mainTab:button("Equip Best to Tower", function()
    equipBestTower()
    notify("Tower", "Equip Best sent")
end)

-- UNITS
unitsTab:section("Auto Buy")
unitsTab:toggle("Auto Buy Unit", false, function(on)
    State.autoBuyUnit = on
    if on then
        runAutoBuyLoop()
    end
    notify("Auto Buy", on and "Enabled" or "Disabled")
end, "auto_buy_unit")

unitsTab:toggle("Auto Buy Level (Spawn Level)", false, function(on)
    State.autoBuyLevel = on
end, "auto_buy_level")

unitsTab:space(6)
unitsTab:section("Auto Merge")
unitsTab:toggle("Auto Merge (all matching)", false, function(on)
    State.autoMerge = on
    if on then
        runAutoMergeLoop()
        notify("Auto Merge", "Merging automatically...")
    else
        notify("Auto Merge", "Disabled")
    end
end, "auto_merge")

unitsTab:slider("Delay between merges", 0.2, 2, 0.45, function(val)
    State.mergeDelay = val
end, "merge_delay", 0.05)

unitsTab:paragraph("How it works", "Drag matching units onto each other in-game. This script replicates that with PreregisterUpdate + MoveUnit for each pair in a loop until no duplicates remain.")

unitsTab:space(6)
unitsTab:section("Towers")
unitsTab:toggle("Auto Equip Best to Tower", false, function(on)
    State.autoEquipTower = on
    notify("Tower", on and "Auto Equip Best ON" or "OFF")
end, "auto_equip_tower")

-- UPGRADES
upgradesTab:section("Automatic Upgrades")
upgradesTab:toggle("Auto Damage", false, function(on) State.autoDamage = on end, "auto_damage")
upgradesTab:toggle("Auto Fire Rate", false, function(on) State.autoFireRate = on end, "auto_firerate")
upgradesTab:toggle("Auto Base Health", false, function(on) State.autoBaseHealth = on end, "auto_base_health")
upgradesTab:toggle("Auto Active Slots", false, function(on) State.autoActiveSlots = on end, "auto_active_slots")
upgradesTab:toggle("Auto Coin Value", false, function(on) State.autoCoinValue = on end, "auto_coin_value")
upgradesTab:toggle("Auto Gem Chance", false, function(on) State.autoGemChance = on end, "auto_gem_chance")
upgradesTab:toggle("Auto Pickup Radius", false, function(on) State.autoPickupRadius = on end, "auto_pickup_radius")

upgradesTab:space(8)
upgradesTab:section("Manual Purchase")
local upgradeTypes = {"Damage", "FireRate", "BaseHealth", "ActiveSlots", "CoinValue", "GemChance", "PickupRadius", "SpawnLevel"}
for _, upgradeType in ipairs(upgradeTypes) do
    upgradesTab:button("Buy " .. upgradeType, function()
        buyUpgrade(upgradeType)
        notify("Upgrade", upgradeType .. " requested")
    end)
end

-- FARM
farmTab:section("Collection")
farmTab:paragraph("Native magnet", "The game pulls coins/gems toward you when they are in range. Auto pickup expands that radius to pull everything on the merge field at once (stay on your plot area).")
farmTab:toggle("Auto Collect Pickups", false, function(on)
    State.autoCollectPickups = on
    ensurePickupLoop()
    notify("Pickups", on and ("Magnet ON (radius " .. State.pickupMagnetRadius .. ")") or "OFF")
end, "auto_collect")

farmTab:slider("Magnet radius (studs)", 20, 350, 180, function(val)
    State.pickupMagnetRadius = math.floor(val)
    if State.autoCollectPickups then
        LocalPlayer:SetAttribute("PickupRadius", State.pickupMagnetRadius)
    end
end, "pickup_magnet_radius", 5)

farmTab:toggle("Auto Claim Offline", false, function(on)
    State.autoClaimOffline = on
end, "auto_offline")

farmTab:toggle("Auto Rebirth", false, function(on)
    State.autoRebirth = on
end, "auto_rebirth")

farmTab:space(8)
farmTab:section("Waves")
farmTab:toggle("Auto 2x Wave Speed", false, function(on)
    State.autoWaveSpeed = on
    if on then
        pcall(function() ToggleWaveSpeed:Fire() end)
    end
end, "auto_wave_speed")

farmTab:button("Toggle Wave Speed", function()
    pcall(function() ToggleWaveSpeed:Fire() end)
    notify("Waves", "Speed toggled")
end)

farmTab:button("Claim Offline Now", function()
    tryClaimOffline()
    notify("Offline", "Claim sent")
end)

farmTab:button("Try Rebirth", function()
    pcall(function() RebirthAttempt:Fire() end)
    notify("Rebirth", "Attempt sent")
end)

farmTab:space(8)
farmTab:section("Wheel & Potions")
farmTab:paragraph("Wheel", "Spins the wheel when a free spin is available or uses pending spins (PendingSpins).")
farmTab:toggle("Auto Spin Wheel", false, function(on)
    State.autoWheelSpin = on
    if on then
        pcall(function() WheelRequestState:Fire() end)
    end
    notify("Wheel", on and "Auto spin ON" or "OFF")
end, "auto_wheel")

farmTab:button("Spin Wheel Now", function()
    task.spawn(function()
        pcall(function() WheelRequestState:Fire() end)
        task.wait(0.5)

        local state = CachedWheelState
        local pending = typeof(state.PendingSpins) == "number" and state.PendingSpins or 0
        if pending > 0 then
            requestWheelSpin(pending)
            notify("Wheel", "Pending spin sent (" .. pending .. ")")
        elseif isFreeSpinReady(state) then
            requestWheelSpin(1)
            notify("Wheel", "Free spin sent")
        else
            notify("Wheel", "No spin available right now", 3)
        end
    end)
end)

farmTab:space(6)
farmTab:paragraph("Potions", "Consumes potions from inventory. By default only uses them when that buff type has expired.")
farmTab:toggle("Auto Consume Potions", false, function(on)
    State.autoConsumePotions = on
    if on then
        pcall(function()
            RequestInventorySnapshot:Fire()
            RequestPotionEffectsSnapshot:Fire()
        end)
    end
    notify("Potions", on and "Auto consume ON" or "OFF")
end, "auto_consume_potions")

farmTab:toggle("Consume all at once", false, function(on)
    State.consumeAllPotions = on
end, "consume_all_potions")

farmTab:toggle("Only when buff expired", true, function(on)
    State.consumePotionsWhenIdle = on
end, "consume_when_idle")

farmTab:button("Consume All Now", function()
    consumeAllPotionsAction()
    notify("Potions", "UseAllPotions sent")
end)

-- PLAYER
playerTab:section("Movement")
playerTab:toggle("WalkSpeed Custom", false, function(on)
    State.walkSpeedEnabled = on
    applyWalkSpeed()
end, "walkspeed_enabled")

playerTab:slider("WalkSpeed", 16, 200, 32, function(val)
    State.walkSpeed = val
    applyWalkSpeed()
end, "walkspeed")

playerTab:toggle("JumpPower Custom", false, function(on)
    State.jumpPowerEnabled = on
    applyJumpPower()
end, "jumppower_enabled")

playerTab:slider("JumpPower", 50, 300, 50, function(val)
    State.jumpPower = val
    applyJumpPower()
end, "jumppower")

playerTab:space(8)
playerTab:section("Teleport")
playerTab:button("TP to Plot", function()
    local plot = getPlotRoot()
    local spawn = plot and plot:FindFirstChild("SpawnLocation", true)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if spawn and hrp then
        hrp.CFrame = spawn.CFrame + Vector3.new(0, 4, 0)
        notify("TP", "Teleported to plot")
    else
        notify("Error", "Spawn not found", 3)
    end
end)

-- MISC
miscTab:section("Information")
miscTab:label("PlaceId: 109509628648368")
miscTab:label("RightControl = show/hide UI")
miscTab:space(8)

miscTab:section("Utilities")
miscTab:button("Reload Units", function()
    pcall(function()
        LoadUnits:Fire()
        RequestUpgradeCosts:Fire()
        RequestInactiveSlotsState:Fire()
    end)
    notify("Reload", "Snapshot requested")
end)

miscTab:button("Show Top 5 Units (DPS)", function()
    local ranking = {}
    for i = 1, #UnitConfig do
        table.insert(ranking, { level = i, name = UnitConfig[i].DisplayName, dps = getUnitDps(i) })
    end
    table.sort(ranking, function(a, b) return a.dps > b.dps end)

    local text = ""
    for i = 1, 5 do
        local entry = ranking[i]
        text = text .. string.format("%s. %s (Lv.%s)\n", i, entry.name, entry.level)
    end
    notify("Top DPS", text, 5)
end)

miscTab:space(8)
miscTab:button("Stop Automation", function()
    State.running = false
    notify("Hub", "Automation stopped")
end)

miscTab:button("Destroy Hub", function()
    State.running = false
    applyPickupMagnet(false)
    for _, conn in ipairs(Connections) do
        pcall(function() conn:Disconnect() end)
    end
    w:destroy()
end)

-- Character respawn hooks
table.insert(Connections, LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    applyWalkSpeed()
    applyJumpPower()
end))

task.defer(function()
    task.wait(2.5)
    if w.flags and w.flags.auto_merge then
        State.autoMerge = true
        runAutoMergeLoop()
    end
    if w.flags and w.flags.auto_buy_unit then
        State.autoBuyUnit = true
        runAutoBuyLoop()
    end
    if w.flags and w.flags.auto_collect then
        State.autoCollectPickups = true
        ensurePickupLoop()
    end
    if w.flags and w.flags.auto_wheel then
        State.autoWheelSpin = true
    end
    if w.flags and w.flags.auto_consume_potions then
        State.autoConsumePotions = true
    end
    if w.flags and w.flags.consume_all_potions then
        State.consumeAllPotions = true
    end
    if w.flags and w.flags.consume_when_idle == false then
        State.consumePotionsWhenIdle = false
    end
end)

notify("Slim Hub MERGE VS MOBS", "Script loaded! RightControl to hide.", 4)
