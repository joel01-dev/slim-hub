--[[
================================================================================
SLIM HUB - NUKE THE GAME
Game: Nuke The Game
PlaceId: 128784467030899
================================================================================
]]

local kyri = loadstring(game:HttpGet("https://kyrilib.dev/kyrilib/"))()

local Junkie = loadstring(game:HttpGet("https://jnkie.com/sdk/library.lua"))()
Junkie.service = "Slim Hub"
Junkie.identifier = "1140699"
Junkie.provider = "Key System"

local function VerifyKey(key)
    key = string.gsub(key or "", "^%s*(.-)%s*$", "%1")
    if key == "" then
        return false, "Please enter a key"
    end

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

    local err = result and result.message or "Invalid key"
    return false, tostring(err)
end

local function CopyKeyLink()
    local link = Junkie.get_key_link()
    if setclipboard then
        setclipboard(link)
    end
    return link
end

local w = kyri.new("Slim Hub", {
    GameName = "SlimHub",
    AutoLoad = "default",
    Theme = {
        accent = Color3.fromRGB(255, 80, 60),
        bg = Color3.fromRGB(12, 12, 18),
        container = Color3.fromRGB(18, 18, 26),
        element = Color3.fromRGB(26, 26, 36),
        hover = Color3.fromRGB(35, 35, 48),
        active = Color3.fromRGB(255, 80, 60),
        text = Color3.fromRGB(245, 245, 255),
        subtext = Color3.fromRGB(160, 160, 180),
        border = Color3.fromRGB(40, 40, 55),
    },
})

if not w then return end

local keyTab = w:tab("Key", "key")

keyTab:section("Authentication")
keyTab:paragraph("Enter your key", "Get your key from the Discord link below, paste it in the input, and click Verify.")

keyTab:button("Copy Discord Link", function()
    if setclipboard then
        setclipboard("https://discord.gg/MfRB5gAQ9N")
    end
    w:notify("Copied", "Discord link copied!", 2)
end, "copy_discord")

local keyInput = keyTab:input("Your Key", "Paste key here...", function()
end, "user_key")

keyTab:space(4)

keyTab:button("Verify Key", function()
    local key = keyInput.input.Text
    if not key or key:gsub("%s", "") == "" then
        w:notify("Error", "Please enter a key", 2)
        return
    end

    local ok, msg = VerifyKey(key)
    if ok then
        w:notify("Success", msg, 3)
    else
        w:notify("Failed", tostring(msg), 3)
    end
end, "verify_key")

keyTab:button("Copy Key Link", function()
    CopyKeyLink()
    w:notify("Copied", "Link copied to clipboard!", 2)
end, "copy_link")

while not getgenv().SCRIPT_KEY do
    task.wait(0.1)
end

w:notify("Authenticated", "Loading Slim Hub...", 3)

local Players = game:GetService("Players")
local LP = Players.LocalPlayer

LP:WaitForChild("PlayerScripts"):WaitForChild("NukeClientModules")
task.wait(0.5)

-- ============================================================================
-- SERVICES & GAME MODULES
-- ============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Remotes = require(ReplicatedStorage.Packages.Remotes)
local NukeRemotes = ReplicatedStorage:WaitForChild("NukeRemotes")
local BigNum = require(ReplicatedStorage.NukeShared.BigNum)
local UpgradeConfig = require(ReplicatedStorage.NukeShared.UpgradeConfig)
local Products = require(ReplicatedStorage.NukeShared.Products)
local DataController = require(ReplicatedStorage.Controllers.DataController)
local NukeConfig = require(LP:WaitForChild("PlayerScripts"):WaitForChild("NukeClientModules"):WaitForChild("Config"))

local HoldingUI = require(LP.PlayerScripts.NukeClientModules.HoldingUI)
local LockUI = require(LP.PlayerScripts.NukeClientModules.LockUI)
local HeldNuke = require(LP.PlayerScripts.NukeClientModules.HeldNuke)
local LaunchController = require(ReplicatedStorage.Controllers.LaunchController)

local PurchaseUpgrade = NukeRemotes:WaitForChild("PurchaseUpgrade")
local RedeemCode = NukeRemotes:WaitForChild("RedeemCode")

local MERGE_RADIUS = NukeConfig.MERGE_RADIUS or 6
local MERGE_POLL = NukeConfig.MERGE_POLL or 0.15
local PICKUP_RADIUS = NukeConfig.PICKUP_RADIUS or 7
local HOLD_FORWARD = NukeConfig.HOLD_FORWARD or 3
local HOLD_UP = NukeConfig.HOLD_UP or 2

-- ============================================================================
-- HELPERS
-- ============================================================================

local UPGRADE_LEVEL_KEYS = {
    TIER = "tierLevel",
    LOCKBASE = "lockBaseLevel",
    MAX = "maxLevel",
}

local function getDataSnapshot()
    local data = DataController:Get()
    local snap = {}

    for _, key in ipairs({ "cash", "tierLevel", "lockBaseLevel", "maxLevel", "rebirthLevel" }) do
        local done = false
        data:Observe({ key }, function(val)
            snap[key] = val
            done = true
        end)

        local start = os.clock()
        while not done and os.clock() - start < 1 do
            task.wait()
        end
    end

    return snap
end

local function getUpgradeAffordInfo(upgradeType, snap)
    snap = snap or getDataSnapshot()

    local cash = BigNum.deserialize(snap.cash)
    local rebirth = snap.rebirthLevel or 0
    local mergeCap = Products.MergeCapForRebirth(rebirth)
    local level = snap[UPGRADE_LEVEL_KEYS[upgradeType]] or 1

    local maxed = UpgradeConfig.IsMaxed(upgradeType, level)
    if upgradeType == "LOCKBASE" then
        maxed = UpgradeConfig.GetMaxLevel("LOCKBASE", rebirth) <= level
    elseif upgradeType == "TIER" and not maxed then
        local nextTier = UpgradeConfig.GetValue("TIER", level + 1)
        if nextTier and mergeCap < nextTier then
            maxed = true
        end
    end

    if maxed then
        return {
            maxed = true,
            canAfford = false,
            level = level,
            cash = cash,
        }
    end

    local cost = UpgradeConfig.GetCost(upgradeType, level)
    return {
        maxed = false,
        canAfford = BigNum.gte(cash, cost),
        level = level,
        cost = cost,
        cash = cash,
    }
end

local function tryPurchaseUpgradeOnce(upgradeType)
    local before = getDataSnapshot()
    local info = getUpgradeAffordInfo(upgradeType, before)
    if info.maxed or not info.canAfford then
        return false, info.maxed and "maxed" or "poor"
    end

    local levelKey = UPGRADE_LEVEL_KEYS[upgradeType]
    local levelBefore = before[levelKey] or 1
    local cashBefore = before.cash

    pcall(function()
        PurchaseUpgrade:FireServer(upgradeType)
    end)

    for _ = 1, 20 do
        task.wait(0.1)
        local after = getDataSnapshot()

        if (after[levelKey] or 1) > levelBefore then
            return true
        end

        if after.cash ~= cashBefore then
            local cashAfter = BigNum.deserialize(after.cash)
            local cashStart = BigNum.deserialize(cashBefore)
            if not BigNum.gte(cashAfter, cashStart) then
                return true
            end
        end
    end

    return false, "timeout"
end

local function getCashText()
    local text = "N/A"
    local done = false

    local conn
    conn = DataController:Get():Observe({ "cash" }, function(val)
        if val then
            text = BigNum.money(BigNum.deserialize(val))
        end
        done = true
        if conn and conn.Disconnect then
            conn:Disconnect()
        end
    end)

    local start = os.clock()
    while not done and os.clock() - start < 2 do
        task.wait()
    end

    return text
end

local function getMyBase()
    local bases = Workspace:FindFirstChild("Bases")
    if not bases then return nil end

    for _, base in ipairs(bases:GetChildren()) do
        if base:GetAttribute("OwnerUserId") == LP.UserId then
            return base
        end
    end

    return nil
end

local function getMyNukesFolder()
    local base = getMyBase()
    return base and base:FindFirstChild("Nukes") or nil
end

local function getCharacterHRP()
    local char = LP.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getNukePos(nuke)
    if nuke:IsA("Model") then
        return nuke:GetPivot().Position
    end
    return nuke.Position
end

local function isHoldingNuke()
    local tier = HeldNuke.GetTier and HeldNuke.GetTier()
    return tier ~= nil
end

local function getHeldPos()
    local heldCFrame = HeldNuke.GetCFrame and HeldNuke.GetCFrame()
    if heldCFrame then
        return heldCFrame.Position
    end

    local hrp = getCharacterHRP()
    if not hrp then
        return nil
    end

    return (hrp.CFrame * CFrame.new(0, HOLD_UP, -HOLD_FORWARD)).Position
end

local function flatDist(a, b)
    local dx = a.X - b.X
    local dz = a.Z - b.Z
    return math.sqrt(dx * dx + dz * dz)
end

local function teleportToNuke(nuke)
    local hrp = getCharacterHRP()
    if not hrp then return false end

    local pos = getNukePos(nuke)
    hrp.CFrame = CFrame.new(pos.X, pos.Y + 3, pos.Z)
    return true
end

local function teleportForMerge(targetPos)
    local hrp = getCharacterHRP()
    if not hrp then return false end

    hrp.CFrame = CFrame.new(targetPos.X, targetPos.Y + 3, targetPos.Z + 1.5)
    return true
end

local function teleportToMyBase()
    local base = getMyBase()
    if not base then
        return false
    end

    local floor = base:FindFirstChild("Floor")
    if not floor then
        return false
    end

    local hrp = getCharacterHRP()
    if not hrp then
        return false
    end

    local pos
    if floor:IsA("BasePart") then
        pos = floor.Position
    else
        pos = floor:GetPivot().Position
    end

    hrp.CFrame = CFrame.new(pos.X, pos.Y + 3, pos.Z)
    return true
end

local function waitForHolding(expectedTier, timeout)
    local deadline = os.clock() + (timeout or 2)
    while os.clock() < deadline do
        local tier = HeldNuke.GetTier and HeldNuke.GetTier()
        if tier and (not expectedTier or tier == expectedTier) then
            return tier
        end
        task.wait(0.1)
    end
    return HeldNuke.GetTier and HeldNuke.GetTier()
end

local function getNukesByTier()
    local folder = getMyNukesFolder()
    local grouped = {}
    if not folder then return grouped end

    for _, nuke in ipairs(folder:GetChildren()) do
        if nuke:IsA("BasePart") or nuke:IsA("Model") then
            local tier = nuke:GetAttribute("Tier")
            if tier then
                grouped[tier] = grouped[tier] or {}
                table.insert(grouped[tier], nuke)
            end
        end
    end

    return grouped
end

local function findMergePair()
    for tier, list in pairs(getNukesByTier()) do
        if #list >= 2 then
            return tier, list[1], list[2]
        end
    end
    return nil
end

local mergePausedUntil = 0
local launchSequenceActive = false

local function isLaunchSequenceActive()
    return launchSequenceActive
end

local function isMergePaused()
    return launchSequenceActive or os.clock() < mergePausedUntil
end

local function pauseMergeForLaunch(seconds)
    mergePausedUntil = os.clock() + (seconds or 2)
end

local function findPlotNukeSameTier(tier)
    local folder = getMyNukesFolder()
    if not folder then return nil end

    local heldPos = getHeldPos()
    local hrp = getCharacterHRP()
    local refPos = heldPos or (hrp and hrp.Position)
    if not refPos then return nil end

    local best, bestDist = nil, math.huge
    for _, nuke in ipairs(folder:GetChildren()) do
        if (nuke:IsA("BasePart") or nuke:IsA("Model")) and nuke:GetAttribute("Tier") == tier then
            local dist = flatDist(getNukePos(nuke), refPos)
            if dist < bestDist then
                best = nuke
                bestDist = dist
            end
        end
    end

    return best, bestDist
end

local function tryMergeOnce()
    if isMergePaused() then
        return false
    end

    local hrp = getCharacterHRP()
    if not hrp then return false end

    if not isHoldingNuke() then
        local tier, nukeA = findMergePair()
        if not tier or not nukeA then
            return false
        end

        teleportToNuke(nukeA)
        task.wait(0.25)

        pcall(function()
            Remotes.PickUp:FireServer("Nuke")
        end)

        local heldTier = waitForHolding(tier, 2)
        if heldTier ~= tier then
            if heldTier then
                pcall(HoldingUI.RequestDrop)
            end
            return false
        end

        return true
    end

    local heldTier = HeldNuke.GetTier()
    local target, dist = findPlotNukeSameTier(heldTier)
    if not target then
        return false
    end

    if dist > MERGE_RADIUS then
        teleportForMerge(getNukePos(target))
        task.wait(0.2)
        dist = flatDist(getNukePos(target), getHeldPos() or hrp.Position)
    end

    if dist <= MERGE_RADIUS then
        pcall(function()
            Remotes.MergeRequest:FireServer(target)
        end)
        task.wait(0.6)
        return true
    end

    return false
end

local function getEnemyBasesText()
    local bases = Workspace:FindFirstChild("Bases")
    if not bases then return "No bases found." end

    local lines = {}
    for _, base in ipairs(bases:GetChildren()) do
        local ownerId = base:GetAttribute("OwnerUserId")
        if ownerId and ownerId ~= LP.UserId then
            local ownerName = "Offline"
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr.UserId == ownerId then
                    ownerName = plr.Name
                    break
                end
            end
            table.insert(lines, base.Name .. " - " .. ownerName)
        end
    end

    if #lines == 0 then
        return "No enemy bases on this server."
    end

    return table.concat(lines, "\n")
end

local function countPlotNukes()
    local folder = getMyNukesFolder()
    if not folder then return 0 end
    return #folder:GetChildren()
end

local function isNukeOnCooldown()
    local readyAt = HoldingUI.GetCooldownUntil and HoldingUI.GetCooldownUntil() or 0
    return workspace:GetServerTimeNow() < readyAt
end

local function waitForNukeReady(timeout)
    local deadline = os.clock() + (timeout or 120)
    while os.clock() < deadline do
        if not isNukeOnCooldown() then
            return true
        end
        if launchSequenceActive and not isHoldingNuke() then
            return false
        end
        task.wait(0.25)
    end
    return false
end

local function isLaunchInProgress()
    return LaunchController.IsLaunchInProgress and LaunchController:IsLaunchInProgress()
end

local function isLaunchTargeting()
    return LaunchController.IsTargeting and LaunchController:IsTargeting()
end

local function fireButtonActivated(btn)
    if not btn then
        return false
    end

    local fired = false

    pcall(function()
        if typeof(firesignal) == "function" then
            firesignal(btn.Activated)
            fired = true
        end
    end)

    if fired then
        return true
    end

    pcall(function()
        if getconnections then
            for _, conn in getconnections(btn.Activated) do
                if conn.Function then
                    conn:Function()
                    fired = true
                elseif conn.Fire then
                    conn:Fire()
                    fired = true
                end
            end
        end
    end)

    return fired
end

local function cancelLaunchTargeting()
    local playerGui = LP:FindFirstChildOfClass("PlayerGui")
    if playerGui then
        local screenGui = playerGui:FindFirstChild("ScreenGui")
        local cancelHolder = screenGui and screenGui:FindFirstChild("CancelHolder")
        local cancelFrame = cancelHolder and cancelHolder:FindFirstChild("Cancel")
        local cancelBtn = cancelFrame and cancelFrame:FindFirstChild("TextButton")
        fireButtonActivated(cancelBtn)
    end

    restorePlayerCamera()

    local hrp = getCharacterHRP()
    if hrp then
        hrp.Anchored = false
    end

    task.wait(0.35)
end

local function restorePlayerCamera()
    local cam = Workspace.CurrentCamera
    if not cam then
        return
    end

    cam.FieldOfView = 70

    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.Anchored = false
        cam.CFrame = CFrame.lookAt(hrp.Position + Vector3.new(0, 4, 14), hrp.Position + Vector3.new(0, 2, 0))
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            cam.CameraSubject = hum
        end
    end

    cam.CameraType = Enum.CameraType.Custom

    local playerGui = LP:FindFirstChildOfClass("PlayerGui")
    if playerGui then
        local launchGui = playerGui:FindFirstChild("NukeLaunchGui")
        if launchGui then
            pcall(function()
                launchGui:Destroy()
            end)
        end

        local screenGui = playerGui:FindFirstChild("ScreenGui")
        if screenGui then
            local cancelHolder = screenGui:FindFirstChild("CancelHolder")
            if cancelHolder then
                cancelHolder.Visible = false
            end
        end
    end
end

local function getCityBreakablesCenter(city)
    local breakables = city:FindFirstChild("_BREAKABLES") or city:FindFirstChild("Destroyable")
    if not breakables then
        return nil
    end

    local sum = Vector3.zero
    local count = 0

    for _, child in ipairs(breakables:GetChildren()) do
        local pos
        if child:IsA("Model") then
            pos = child:GetPivot().Position
        elseif child:IsA("BasePart") then
            pos = child.Position
        end

        if pos then
            sum = sum + pos
            count = count + 1
        end
    end

    if count == 0 then
        return nil
    end

    return sum / count
end

local function getCityLaunchTarget()
    local city = Workspace:FindFirstChild("CityModel")
    if not city then
        return nil
    end

    local position = getCityBreakablesCenter(city)
    if not position then
        local floor = city:FindFirstChild("Floor")
        position = floor and floor:GetPivot().Position or city:GetPivot().Position
    end

    local displayName = "City"

    local floor = city:FindFirstChild("Floor")
    if floor then
        for _, desc in ipairs(floor:GetDescendants()) do
            if desc:IsA("TextLabel") and desc.Text:find("%(") then
                displayName = desc.Text:match("^(.-)%s*%(") or desc.Text
                break
            end
        end
    end

    return {
        kind = "city",
        name = displayName,
        position = position,
        instance = city,
    }
end

local function getClaimableCommanderTargets()
    local targets = {}

    for _, child in ipairs(Workspace:GetChildren()) do
        if child:IsA("Model") and child.Name:match("^ClaimableCommander_") then
            table.insert(targets, {
                kind = "commander",
                name = child.Name,
                position = child:GetPivot().Position,
                instance = child,
            })
        end
    end

    return targets
end

local function getGameLaunchTarget(mode)
    if mode == "city" or mode == "auto" then
        local cityTarget = getCityLaunchTarget()
        if cityTarget then
            return cityTarget
        end
    end

    if mode == "commander" or mode == "auto" then
        local commanders = getClaimableCommanderTargets()
        if #commanders > 0 then
            local hrp = getCharacterHRP()
            if not hrp then
                return commanders[1]
            end

            local best = commanders[1]
            local bestDist = (best.position - hrp.Position).Magnitude
            for i = 2, #commanders do
                local dist = (commanders[i].position - hrp.Position).Magnitude
                if dist < bestDist then
                    best = commanders[i]
                    bestDist = dist
                end
            end
            return best
        end
    end

    return nil
end

local function getGameTargetsText()
    local lines = {}
    local city = getCityLaunchTarget()
    if city then
        table.insert(lines, "City: " .. city.name)
    end

    for _, commander in ipairs(getClaimableCommanderTargets()) do
        table.insert(lines, "Commander: " .. commander.name)
    end

    if #lines == 0 then
        return "No game targets on this server."
    end

    return table.concat(lines, "\n")
end

local function pickupAnyPlotNuke()
    if isHoldingNuke() then
        return true
    end

    local folder = getMyNukesFolder()
    if not folder then
        return false
    end

    local nukes = folder:GetChildren()
    if #nukes == 0 then
        return false
    end

    teleportToNuke(nukes[1])
    task.wait(0.25)

    pcall(function()
        Remotes.PickUp:FireServer("Nuke")
    end)

    return waitForHolding(nil, 2) ~= nil
end

local function getLaunchButton()
    local playerGui = LP:FindFirstChildOfClass("PlayerGui")
    if not playerGui then
        return nil
    end

    local screenGui = playerGui:FindFirstChild("ScreenGui")
    local holdingFrame = screenGui and screenGui:FindFirstChild("HoldingFrame")
    local launch = holdingFrame and holdingFrame:FindFirstChild("Launch")
    return launch and launch:FindFirstChild("TextButton")
end

local function requestLaunchClick()
    if not isHoldingNuke() then
        return false
    end

    if isNukeOnCooldown() then
        return false
    end

    local tier = HeldNuke.GetTier and HeldNuke.GetTier()
    if tier then
        pcall(function()
            HoldingUI.Show(tier)
        end)
    end

    task.wait(0.15)

    if fireButtonActivated(getLaunchButton()) then
        return true
    end

    pcall(function()
        Remotes.LaunchRequest:FireServer()
    end)

    return true
end

local function launchAtPosition(position)
    if isLaunchInProgress() then
        return false
    end

    if not isHoldingNuke() then
        return false
    end

    if isLaunchTargeting() then
        cancelLaunchTargeting()
    end

    if not waitForNukeReady(120) then
        return false
    end

    teleportToMyBase()
    task.wait(0.3)

    if not isHoldingNuke() then
        return false
    end

    local targeting = false

    for attempt = 1, 2 do
        if isLaunchTargeting() then
            cancelLaunchTargeting()
        end

        if isNukeOnCooldown() then
            waitForNukeReady(30)
        end

        if not isHoldingNuke() then
            break
        end

        requestLaunchClick()

        for _ = 1, 40 do
            task.wait(0.1)
            if isLaunchTargeting() then
                targeting = true
                break
            end
        end

        if targeting then
            break
        end
    end

    if not targeting or not isHoldingNuke() then
        cancelLaunchTargeting()
        return false
    end

    task.wait(1.05)

    if not isHoldingNuke() then
        cancelLaunchTargeting()
        return false
    end

    pcall(function()
        Remotes.LaunchConfirm:FireServer(position)
    end)

    for _ = 1, 160 do
        task.wait(0.1)
        if not isHoldingNuke() and not isLaunchInProgress() and not isLaunchTargeting() then
            restorePlayerCamera()
            return true
        end
    end

    restorePlayerCamera()
    return not isHoldingNuke()
end

local function tryAutoLaunchGameBase(mode)
    if isLaunchInProgress() or launchSequenceActive then
        return false, "busy"
    end

    launchSequenceActive = true

    local success, result, detail = pcall(function()
        local target = getGameLaunchTarget(mode or "auto")
        if not target then
            return false, "no_target"
        end

        if not isHoldingNuke() then
            if not pickupAnyPlotNuke() then
                return false, "no_nuke"
            end
        end

        if not isHoldingNuke() then
            return false, "no_nuke"
        end

        teleportToMyBase()
        task.wait(0.3)

        if not isHoldingNuke() then
            if not pickupAnyPlotNuke() then
                return false, "dropped"
            end
            teleportToMyBase()
            task.wait(0.3)
        end

        if not isHoldingNuke() then
            return false, "dropped"
        end

        if launchAtPosition(target.position) then
            task.wait(0.5)
            restorePlayerCamera()
            return true, target.name
        end

        restorePlayerCamera()
        return false, "failed"
    end)

    launchSequenceActive = false
    restorePlayerCamera()

    if not success then
        return false, "error"
    end

    return result, detail
end

-- ============================================================================
-- TABS
-- ============================================================================

local main = w:tab("Main", "home")
local auto = w:tab("Auto Farm", "bot")
local nukes = w:tab("Nukes", "zap")
local bases = w:tab("Bases", "shield")
local visuals = w:tab("Visuals", "eye")
local misc = w:tab("Misc", "terminal")

-- ============================================================================
-- MAIN
-- ============================================================================

main:section("Status")

main:label("Player: " .. LP.Name)
main:label("Base: " .. (getMyBase() and getMyBase().Name or "N/A"))
main:label("Nukes on plot: " .. tostring(countPlotNukes()))
main:label("Holding nuke: " .. (isHoldingNuke() and "Yes" or "No"))

main:space()

main:section("Cash")

main:button("View Cash", function()
    w:notify("Cash", getCashText(), 4)
end, "show_cash")

main:button("Refresh Status", function()
    w:notify("Status", "Cash: " .. getCashText() .. "\nNukes: " .. countPlotNukes(), 4)
end, "refresh_status")

-- ============================================================================
-- AUTO FARM
-- ============================================================================

local autoMergeRunning = false
local autoCollectRunning = false
local autoLockRunning = false
local autoDropRunning = false
local autoBuyRunning = false
local autoLaunchRunning = false
local autoDropInterval = 4
local autoBuyInterval = 3
local autoBuyQuantity = 10
local autoBuyRemaining = 0
local autoLaunchInterval = 8
local autoLaunchMode = "auto"
local lastMerge = 0
local lastDrop = 0
local lastLaunch = 0

local autoDropLoopActive = false
local autoDropToggle
local syncingDropUI = false

local function startAutoDropLoop()
    if autoDropLoopActive then
        return
    end
    autoDropLoopActive = true
    lastDrop = 0
    task.spawn(function()
        while autoDropRunning do
            if not isLaunchSequenceActive() then
                local now = os.clock()
                if isHoldingNuke() and now - lastDrop >= autoDropInterval then
                    pcall(function()
                        HoldingUI.RequestDrop()
                    end)
                    lastDrop = now
                end
            end
            task.wait(0.1)
        end
        autoDropLoopActive = false
    end)
end

local function applyAutoDropState(state, notify)
    autoDropRunning = state
    if state then
        startAutoDropLoop()
        if notify then
            w:notify("Auto Drop", "Enabled - drops every " .. autoDropInterval .. "s", 3)
        end
    elseif notify then
        w:notify("Auto Drop", "Disabled", 2)
    end
end

local function setAutoDropEnabled(state, notify)
    applyAutoDropState(state, notify)
    syncingDropUI = true
    if autoDropToggle and autoDropToggle.set then
        pcall(function()
            autoDropToggle:set(state)
        end)
    end
    syncingDropUI = false
end

auto:section("Auto Merge")

auto:paragraph("Merge", "Picks up a nuke, teleports to another of the same tier on your plot, and merges (radius " .. MERGE_RADIUS .. " studs). Auto Drop turns on with Auto Merge.")

auto:toggle("Auto Merge", false, function(state)
    autoMergeRunning = state
    if state then
        task.spawn(function()
            while autoMergeRunning do
                local now = os.clock()
                if not isMergePaused() and now - lastMerge >= MERGE_POLL then
                    local ok, result = pcall(tryMergeOnce)
                    if ok and result then
                        lastMerge = now + 0.5
                    end
                end
                task.wait(MERGE_POLL)
            end
        end)
        setAutoDropEnabled(true, false)
        w:notify("Auto Merge", "Enabled - needs 2+ same-tier nukes on plot. Auto Drop also enabled.", 3)
    else
        setAutoDropEnabled(false, false)
        w:notify("Auto Merge", "Disabled", 2)
    end
end, "auto_merge")

auto:space()

auto:section("Auto Collect")

auto:paragraph("Collect", "Tries to pick up spawned nukes with PickUp(\"Nuke\").")

auto:toggle("Auto PickUp", false, function(state)
    autoCollectRunning = state
    if state then
        task.spawn(function()
            while autoCollectRunning do
                if not isLaunchSequenceActive() and not isHoldingNuke() then
                    pcall(function()
                        Remotes.PickUp:FireServer("Nuke")
                    end)
                end
                task.wait(NukeConfig.PICKUP_SCAN_INTERVAL or 0.1)
            end
        end)
        w:notify("Auto Collect", "Enabled", 2)
    else
        w:notify("Auto Collect", "Disabled", 2)
    end
end, "auto_collect")

auto:space()

auto:section("Auto Drop")

auto:paragraph("Drop", "Automatically drops the bomb while you are holding it.")

autoDropToggle = auto:toggle("Auto Drop", false, function(state)
    if syncingDropUI then
        return
    end
    applyAutoDropState(state, true)
end, "auto_drop")

auto:slider("Drop Interval (sec)", 1, 30, 4, function(val)
    autoDropInterval = val
end, "auto_drop_interval", 0.5)

auto:space()

auto:section("Auto Launch (Game Base)")

auto:paragraph("GameLaunch", "Picks up a nuke, teleports to your base, holds the bomb, clicks launch, and throws at the City/Oil Rig center. Merge/drop pause only during launch.")

local autoLaunchModeDropdown = auto:dropdown("Target", { "Auto (City first)", "City (Oil Rig/Event)", "Claimable Commander" }, "Auto (City first)", function(val)
    if val:find("Commander") then
        autoLaunchMode = "commander"
    elseif val:find("City") and not val:find("Auto") then
        autoLaunchMode = "city"
    else
        autoLaunchMode = "auto"
    end
end, "auto_launch_mode")

auto:slider("Launch Interval (sec)", 3, 60, 8, function(val)
    autoLaunchInterval = val
end, "auto_launch_interval")

auto:toggle("Auto Launch Game Base", false, function(state)
    autoLaunchRunning = state
    if state then
        lastLaunch = 0
        task.spawn(function()
            while autoLaunchRunning do
                local now = os.clock()
                if now - lastLaunch >= autoLaunchInterval then
                    local mode = autoLaunchMode
                    if autoLaunchModeDropdown.get then
                        local val = autoLaunchModeDropdown:get()
                        if val and val:find("Commander") then
                            mode = "commander"
                        elseif val and val:find("City") and not val:find("Auto") then
                            mode = "city"
                        else
                            mode = "auto"
                        end
                    end

                    local result, detail = tryAutoLaunchGameBase(mode)
                    if result then
                        lastLaunch = now
                        w:notify("Auto Launch", "Launched at " .. tostring(detail), 2)
                    end
                end
                task.wait(0.5)
            end
        end)
        w:notify("Auto Launch", "Enabled - targets: City/Commander game bases", 3)
    else
        w:notify("Auto Launch", "Disabled", 2)
    end
end, "auto_launch")

auto:button("View Game Targets", function()
    w:notify("Game Targets", getGameTargetsText(), 5)
end, "list_game_targets")

auto:space()

auto:section("Auto Lock")

auto:toggle("Auto Lock Base", false, function(state)
    autoLockRunning = state
    if state then
        task.spawn(function()
            while autoLockRunning do
                pcall(function()
                    LockUI.RequestLock()
                end)
                task.wait(30)
            end
        end)
        w:notify("Auto Lock", "Enabled", 2)
    else
        w:notify("Auto Lock", "Disabled", 2)
    end
end, "auto_lock")

-- ============================================================================
-- NUKES
-- ============================================================================

nukes:section("Actions")

nukes:button("PickUp Nuke", function()
    pcall(function()
        Remotes.PickUp:FireServer("Nuke")
    end)
    w:notify("Nuke", "PickUp sent", 2)
end, "pickup_nuke")

nukes:button("Drop Nuke", function()
    pcall(function()
        HoldingUI.RequestDrop()
    end)
    w:notify("Nuke", "Drop sent", 2)
end, "drop_nuke")

nukes:button("Manual Merge", function()
    task.spawn(function()
        local ok, result = pcall(tryMergeOnce)
        if ok and result then
            w:notify("Merge", "Merge requested", 2)
        else
            w:notify("Merge", "Need 2 same-tier nukes on plot", 3)
        end
    end)
end, "manual_merge")

nukes:space()

nukes:section("Launch")

nukes:button("Launch at Game Base", function()
    task.spawn(function()
        local result, detail = tryAutoLaunchGameBase("auto")
        if result then
            w:notify("Launch", "Launched at " .. tostring(detail), 3)
        elseif detail == "no_target" then
            w:notify("Launch", "No game base found", 3)
        elseif detail == "no_nuke" then
            w:notify("Launch", "No nuke on plot to pick up", 3)
        elseif detail == "cooldown" then
            w:notify("Launch", "Nuke on cooldown", 3)
        else
            w:notify("Launch", "Launch failed", 3)
        end
    end)
end, "launch_game_base")

nukes:button("Start Launch", function()
    task.spawn(function()
        if not isHoldingNuke() then
            w:notify("Launch", "Hold a nuke first", 2)
            return
        end
        if isNukeOnCooldown() then
            w:notify("Launch", "Nuke on cooldown", 2)
            return
        end
        if requestLaunchClick() then
            w:notify("Launch", "Launch clicked", 2)
        else
            w:notify("Launch", "Failed to click launch", 2)
        end
    end)
end, "start_launch")

nukes:paragraph("Launch", "Auto Launch targets City/Oil Rig and claimable Commanders. Manual launch opens normal targeting.")

-- ============================================================================
-- BASES
-- ============================================================================

bases:section("My Base")

bases:button("Lock Base", function()
    pcall(function()
        LockUI.RequestLock()
    end)
    w:notify("Base", "Lock requested", 2)
end, "lock_base")

bases:button("View Enemy Bases", function()
    w:notify("Enemy Bases", getEnemyBasesText(), 6)
end, "list_enemy_bases")

bases:space()

bases:section("Upgrades")

local selectedUpgrade = "TIER"
local upgradeDropdown = bases:dropdown("Upgrade Type", { "TIER", "LOCKBASE", "MAX" }, "TIER", function(val)
    selectedUpgrade = val
end, "upgrade_type")

bases:button("Buy Upgrade", function()
    local upgradeType = selectedUpgrade
    if upgradeDropdown.get then
        upgradeType = upgradeDropdown:get() or selectedUpgrade
    end

    task.spawn(function()
        local ok, reason = tryPurchaseUpgradeOnce(upgradeType)
        if ok then
            w:notify("Upgrade", "Purchase confirmed: " .. tostring(upgradeType), 2)
        elseif reason == "maxed" then
            w:notify("Upgrade", "Upgrade maxed out", 2)
        elseif reason == "poor" then
            w:notify("Upgrade", "Not enough cash", 2)
        else
            w:notify("Upgrade", "Purchase not confirmed", 2)
        end
    end)
end, "buy_upgrade")

bases:space()

bases:section("Auto Buy Upgrade")

bases:paragraph("AutoBuy", "Buys upgrades when you have enough cash. Quantity only decreases after a confirmed purchase.")

local autoBuyQtySlider = bases:slider("Quantity", 1, 100, 10, function(val)
    autoBuyQuantity = math.floor(val)
end, "auto_buy_qty")

bases:slider("Interval (sec)", 1, 30, 3, function(val)
    autoBuyInterval = val
end, "auto_buy_interval", 0.5)

local autoBuyToggle
autoBuyToggle = bases:toggle("Auto Buy Upgrade", false, function(state)
    autoBuyRunning = state
    if state then
        if autoBuyQtySlider.get then
            autoBuyQuantity = math.floor(autoBuyQtySlider:get() or autoBuyQuantity)
        end
        autoBuyRemaining = autoBuyQuantity

        if autoBuyRemaining <= 0 then
            autoBuyRunning = false
            if autoBuyToggle and autoBuyToggle.set then
                autoBuyToggle:set(false)
            end
            w:notify("Auto Buy", "Set a quantity greater than 0", 2)
            return
        end

        task.spawn(function()
            while autoBuyRunning and autoBuyRemaining > 0 do
                local upgradeType = selectedUpgrade
                if upgradeDropdown.get then
                    upgradeType = upgradeDropdown:get() or selectedUpgrade
                end

                local info = getUpgradeAffordInfo(upgradeType)
                if info.maxed then
                    w:notify("Auto Buy", "Upgrade maxed out", 3)
                    break
                end

                if info.canAfford then
                    local ok = tryPurchaseUpgradeOnce(upgradeType)
                    if ok then
                        autoBuyRemaining = autoBuyRemaining - 1
                        w:notify("Auto Buy", "Purchased! Remaining: " .. autoBuyRemaining, 2)
                    end
                end

                if autoBuyRemaining <= 0 then
                    break
                end

                task.wait(autoBuyInterval)
            end

            autoBuyRunning = false
            if autoBuyToggle and autoBuyToggle.set then
                autoBuyToggle:set(false)
            end

            if autoBuyRemaining <= 0 then
                w:notify("Auto Buy", "Quantity completed", 3)
            end
        end)

        w:notify("Auto Buy", autoBuyRemaining .. " purchases configured", 3)
    else
        w:notify("Auto Buy", "Disabled - remaining: " .. autoBuyRemaining, 2)
    end
end, "auto_buy")

-- ============================================================================
-- VISUALS
-- ============================================================================

local espNukesRunning = false
local espHighlights = {}

local function clearHighlights(list)
    for _, hl in ipairs(list) do
        pcall(function()
            hl:Destroy()
        end)
    end
    table.clear(list)
end

visuals:section("ESP")

visuals:toggle("ESP Nukes (Plot)", false, function(state)
    espNukesRunning = state
    if state then
        task.spawn(function()
            while espNukesRunning do
                local folder = getMyNukesFolder()
                if folder then
                    for _, nuke in ipairs(folder:GetChildren()) do
                        if not nuke:FindFirstChild("NukeHubESP") then
                            local hl = Instance.new("Highlight")
                            hl.Name = "NukeHubESP"
                            hl.FillColor = Color3.fromRGB(255, 60, 60)
                            hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                            hl.FillTransparency = 0.45
                            hl.Adornee = nuke
                            hl.Parent = nuke
                            table.insert(espHighlights, hl)
                        end
                    end
                end
                task.wait(1)
            end
            clearHighlights(espHighlights)
        end)
        w:notify("ESP", "ESP Nukes enabled", 2)
    else
        clearHighlights(espHighlights)
        w:notify("ESP", "ESP Nukes disabled", 2)
    end
end, "esp_nukes")

local espBasesRunning = false
local espBaseHighlights = {}

visuals:toggle("ESP Enemy Bases", false, function(state)
    espBasesRunning = state
    if state then
        task.spawn(function()
            while espBasesRunning do
                local basesFolder = Workspace:FindFirstChild("Bases")
                if basesFolder then
                    for _, base in ipairs(basesFolder:GetChildren()) do
                        local ownerId = base:GetAttribute("OwnerUserId")
                        if ownerId and ownerId ~= LP.UserId then
                            if not base:FindFirstChild("NukeHubESP") then
                                local hl = Instance.new("Highlight")
                                hl.Name = "NukeHubESP"
                                hl.FillColor = Color3.fromRGB(60, 255, 100)
                                hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                                hl.FillTransparency = 0.65
                                hl.Adornee = base
                                hl.Parent = base
                                table.insert(espBaseHighlights, hl)
                            end
                        end
                    end
                end
                task.wait(1)
            end
            clearHighlights(espBaseHighlights)
        end)
        w:notify("ESP", "ESP Bases enabled", 2)
    else
        clearHighlights(espBaseHighlights)
        w:notify("ESP", "ESP Bases disabled", 2)
    end
end, "esp_bases")

-- ============================================================================
-- MISC
-- ============================================================================

misc:section("Code")

local codeInput = misc:input("Code", "BOOM", function() end, "redeem_code")

misc:button("Redeem Code", function()
    local code = codeInput.input.Text
    if code == "" then
        w:notify("Error", "Enter a code", 2)
        return
    end

    pcall(function()
        RedeemCode:FireServer(code)
    end)
    w:notify("Code", "Code sent: " .. code, 3)
end, "redeem_code_btn")

misc:space()

misc:section("Server")

misc:button("Job ID", function()
    w:notify("Job ID", game.JobId, 5)
end, "show_job")

misc:button("Place ID", function()
    w:notify("Place ID", tostring(game.PlaceId), 5)
end, "show_place")

misc:button("List Players", function()
    local msg = {}
    for _, player in ipairs(Players:GetPlayers()) do
        table.insert(msg, player.Name .. " (" .. player.UserId .. ")")
    end
    w:notify("Players", table.concat(msg, "\n"), 5)
end, "list_players")

misc:space()

misc:section("Actions")

misc:button("Rejoin", function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LP)
end, "rejoin")

misc:button("Close Hub", function()
    clearHighlights(espHighlights)
    clearHighlights(espBaseHighlights)
    w:destroy()
end, "close_hub")

-- ============================================================================
-- STARTUP
-- ============================================================================

w:notify("Slim Hub", "Loaded successfully!", 3)
w:notify("Tip", "RightControl to show/hide the menu", 5)
