--[[
================================================================================
RIDE HAVEN - Slim Hub | KyriLib UI
Game: [NOVA BICICLETA] Ride Haven
PlaceId: 73071705436104
================================================================================
]]

local kyri = loadstring(game:HttpGet("https://kyrilib.dev/kyrilib/"))()

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

local w = kyri.new("Slim Hub RIDE HAVEN", {
    GameName = "RideHaven",
    AutoLoad = "default",
    Theme = {
        accent = Color3.fromRGB(80, 180, 255),
        bg = Color3.fromRGB(10, 12, 18),
        container = Color3.fromRGB(16, 18, 26),
        element = Color3.fromRGB(24, 28, 38),
        hover = Color3.fromRGB(34, 40, 54),
        active = Color3.fromRGB(80, 180, 255),
        text = Color3.fromRGB(245, 248, 255),
        subtext = Color3.fromRGB(150, 160, 180),
        border = Color3.fromRGB(42, 48, 62),
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
    w:notify(ok and "Success" or "Failed", msg, ok and 3 or 2)
end, "verify_key")
keyTab:button("Copy Key Link", function()
    CopyKeyLink()
    w:notify("Copied", "Link copied to clipboard!", 2)
end, "copy_link")

while not getgenv().SCRIPT_KEY do
    task.wait(0.1)
end

w:notify("Authenticated", "Loading Slim Hub RIDE HAVEN...", 3)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local QuestConfig = require(ReplicatedStorage.Modules.Shared.QuestConfig)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local TeleportEvent = Remotes:WaitForChild("Gameplay"):WaitForChild("TeleportEvent")
local LuckySpinSend = Remotes:WaitForChild("LuckySpin"):WaitForChild("Send")

local BikeList = ReplicatedStorage:WaitForChild("Asset"):WaitForChild("Bike"):WaitForChild("BikeList")

local QUEST_TABS = { "Daily", "Weekly", "Monthly" }
local TELEPORT_LOCATIONS = {
    "Highway_Race",
    "Drag_Race",
    "GP_Track_Race",
    "Mountain_Pass_Race",
    "Mini_Circuit_Race",
    "Lakeside_Loop_Race",
    "Side_Street_Race",
    "Beach",
    "Dealership",
    "Customization",
}

-- CFrame fallback map for teleport locations (used when Warp unavailable)
local LOCATION_CFRAMES = {
    Highway_Race = CFrame.new(-9125.9, -18.2, 2521.5) + Vector3.new(0, 4, 0),
    Drag_Race = CFrame.new(-9014.3, -18.2, 2999.5) + Vector3.new(0, 4, 0),
    GP_Track_Race = CFrame.new(-9859.1, 82.3, 8272.7) + Vector3.new(0, 4, 0),
    Lakeside_Loop_Race = CFrame.new(4445.7, 54.1, -642.9) + Vector3.new(0, 4, 0),
    Side_Street_Race = CFrame.new(-19707.1, 194.5, 3265.2) + Vector3.new(0, 4, 0),
    Mountain_Pass_Race = CFrame.new(-10350.8, -18.9, 1652.2) + Vector3.new(0, 4, 0),
    Mini_Circuit_Race = CFrame.new(-4921.6, 218.9, 14786.4) + Vector3.new(0, 4, 0),
    Beach = CFrame.new(-8299.8, -18.2, 1926.9) + Vector3.new(0, 4, 0),
    Dealership = CFrame.new(-9513.8, -17.8, -1685.2) + Vector3.new(0, 4, 0),
    Customization = CFrame.new(-9889.5, -18.0, -3477.1) + Vector3.new(0, 4, 0),
}

-- Warp is lazy-loaded: requiring at top level crashes some executors (RobloxScript context).
local WarpModule = nil
local WarpClients = {}

local function initWarp()
    if WarpModule then
        return true
    end

    local ok, mod = pcall(require, ReplicatedStorage.Modules.Warp)
    if not ok or not mod then
        return false
    end

    WarpModule = mod
    for _, name in ipairs({ "Dealership", "Quests", "Teleport" }) do
        local clientOk, client = pcall(function()
            return WarpModule.Client(name)
        end)
        if clientOk then
            WarpClients[name] = client
        end
    end

    return WarpClients.Dealership ~= nil
end

local function getWarpClient(name)
    initWarp()
    return WarpClients[name]
end

local State = {
    running = true,
    autoFarm = false,
    farmLocation = "Highway_Race",
    autoSpawnBike = true,
    farmHoldGas = true,
    farmStuckTeleport = true,
    farmMinSpeed = 50,
    farmStuckSeconds = 3,
    autoClaimQuests = false,
    autoLuckySpin = false,
    autoBuyUpgrade = false,
    buyReserveCash = 5000,
    antiAfk = false,
    selectedBike = "Honde Cbr250r 2017",
    selectedTeleport = "Highway_Race",
    -- Sky Farm settings
    skyFarm = true,
    skyAltitude = 500,
    skyRadius = 50,
    skySpeed = 300,
    -- Race Farm settings
    autoRace = false,
    raceTrack = "Race5",
    raceLaps = 1,
    raceDelay = 3,
}

local Connections = {}
local lastFarmTeleportAt = 0
local lastSpawnAttemptAt = 0
local lastQuestClaimAt = 0
local lastSpinAt = 0
local lastBuyAt = 0
local warpWarned = false
local farmDriveConn = nil
local farmGasHeld = false
local farmStuckSince = nil
local FARM_SPEED_CONVERSION = 0.7692307692307693

-- Sky Farm variables
local skyAngle = 0
local skyCenter = nil
local skyFarmConn = nil

local function notify(title, text, duration)
    w:notify(title, text, duration or 2)
end

local function warnWarpMissing()
    if warpWarned then
        return
    end
    warpWarned = true
    notify("Warp", "Shop/spawn/quests unavailable in this executor context", 4)
end

local function formatCash(amount)
    local s = tostring(math.floor(amount or 0))
    while true do
        local replaced, count = s:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
        s = replaced
        if count == 0 then break end
    end
    return "RM " .. s
end

local function getCash()
    local ls = LocalPlayer:FindFirstChild("leaderstats")
    local cash = ls and ls:FindFirstChild("Cash")
    return cash and tonumber(cash.Value) or 0
end

local function getMiles()
    local ls = LocalPlayer:FindFirstChild("leaderstats")
    local miles = ls and ls:FindFirstChild("Miles")
    return miles and tonumber(miles.Value) or 0
end

local function getValue()
    local ls = LocalPlayer:FindFirstChild("leaderstats")
    local value = ls and ls:FindFirstChild("Value")
    return value and tonumber(value.Value) or 0
end

local function getExtra()
    return LocalPlayer:FindFirstChild("Extra")
end

local function getCharacter()
    return LocalPlayer.Character
end

local function ownsBike(name)
    local folder = LocalPlayer:FindFirstChild("Vehicle")
    return folder and folder:FindFirstChild(name) ~= nil
end

local function getOwnedBikes()
    local folder = LocalPlayer:FindFirstChild("Vehicle")
    if not folder then return {} end
    local list = {}
    for _, child in ipairs(folder:GetChildren()) do
        table.insert(list, child.Name)
    end
    table.sort(list)
    return list
end

local function getBikePrice(name)
    local entry = BikeList:FindFirstChild(name)
    if not entry then return nil end
    return tonumber(entry:GetAttribute("VehiclePrice"))
end

local function getAllBikeNames()
    local names = {}
    for _, child in ipairs(BikeList:GetChildren()) do
        table.insert(names, child.Name)
    end
    table.sort(names)
    return names
end

local function isRidingBike()
    local char = getCharacter()
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    return hum and hum.SeatPart ~= nil
end

local function getCurrentSpeedMph()
    local char = getCharacter()
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return 0 end
    return hrp.AssemblyLinearVelocity.Magnitude * FARM_SPEED_CONVERSION
end

local function teleportTo(location)
    -- Try TeleportEvent directly (works!)
    if TeleportEvent then
        local ok, err = pcall(function()
            TeleportEvent:FireServer(location)
        end)
        if ok then
            return true
        end
    end
    
    -- Try Warp Teleport client
    if WarpModule then
        local client = WarpClients.Teleport
        if client then
            pcall(function()
                client:Fire(false, location)
            end)
            return true
        end
    end
    
    -- Try to init Warp and get Teleport client
    if not WarpModule then
        local ok = initWarp()
        if ok then
            local client = WarpClients.Teleport
            if client then
                pcall(function()
                    client:Fire(false, location)
                end)
                return true
            end
        end
    end
    
    -- Fallback: character CFrame teleport (used when not on bike)
    local char = getCharacter()
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp and LOCATION_CFRAMES[location] then
        pcall(function()
            hrp.CFrame = LOCATION_CFRAMES[location]
        end)
        return true
    end
    
    return false
end

local function teleportVehicleWithPlayer(location)
    local targetCF = LOCATION_CFRAMES[location]
    if not targetCF then return end
    
    local vehicle = getVehicleModel()
    if not vehicle then return end
    
    -- Use SetPrimaryPartCFrame if PrimaryPart is defined
    if vehicle.PrimaryPart then
        pcall(function()
            vehicle:SetPrimaryPartCFrame(targetCF + Vector3.new(0, 3, 0))
        end)
    else
        -- Otherwise, teleport all vehicle parts
        pcall(function()
            for _, part in ipairs(vehicle:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CFrame = targetCF + Vector3.new(0, 3, 0)
                end
            end
        end)
    end
end

local function fireDealership(vehicleName, action)
    -- Try using DealershipEvents directly (more reliable than Warp)
    local dealFolder = ReplicatedStorage:FindFirstChild("DealershipEvents")
    if dealFolder then
        local giftVeh = dealFolder:FindFirstChild("GiftVehicle")
        if giftVeh and giftVeh:IsA("RemoteFunction") then
            local ok, result = pcall(function()
                return giftVeh:InvokeServer(vehicleName, action)
            end)
            if ok and result == true then
                return true
            end
        end
    end
    
    -- Fallback: Warp client
    local client = getWarpClient("Dealership")
    if client then
        pcall(function()
            client:Fire(true, vehicleName, action)
        end)
        return true
    end
    
    warnWarpMissing()
    return false
end

local function spawnBike(name)
    if not name or not ownsBike(name) then
        name = getOwnedBikes()[1]
    end
    if not name then return false end
    return fireDealership(name, "Spawn")
end

local function getVehicleModel()
    local folder = workspace:FindFirstChild("Vehicles")
    local root = folder and folder:FindFirstChild(LocalPlayer.Name)
    if not root then return nil end
    if root:IsA("Model") then return root end
    return root:FindFirstChildWhichIsA("Model")
end

local function getVehicleDriveParts()
    local model = getVehicleModel()
    if not model then return nil end

    local tuner = model:FindFirstChild("Tuner", true)
    local iface = tuner and tuner:FindFirstChild("Interface")
    local values = iface and iface:FindFirstChild("Values")
    local seat = model:FindFirstChild("DriveSeat", true)

    if not values and not seat then return nil end
    return values, seat
end

local function getBestOwnedBikeName()
    local bestName, bestPrice = nil, -1
    for _, name in ipairs(getOwnedBikes()) do
        local price = getBikePrice(name) or 0
        if price > bestPrice then
            bestPrice = price
            bestName = name
        end
    end
    return bestName or getOwnedBikes()[1]
end

-- ============================================================================
-- SKY FARM SYSTEM - Bike flies in circles in the sky
-- ============================================================================

local function stopSkyFarm()
    if skyFarmConn then
        skyFarmConn:Disconnect()
        skyFarmConn = nil
    end
    skyAngle = 0
    skyCenter = nil
    if farmGasHeld then
        pcall(function()
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.W, false, game)
        end)
        farmGasHeld = false
    end
end

local function teleportVehicleToSky()
    local locCF = LOCATION_CFRAMES[State.farmLocation] or CFrame.new(-9125.9, -18.2, 2521.5)
    skyCenter = Vector3.new(locCF.X, State.skyAltitude, locCF.Z)
    
    local vehicle = getVehicleModel()
    if vehicle then
        local skyCF = CFrame.new(skyCenter)
        if vehicle.PrimaryPart then
            vehicle:SetPrimaryPartCFrame(skyCF)
        else
            for _, part in ipairs(vehicle:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CFrame = skyCF
                end
            end
        end
        local char = getCharacter()
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = skyCF
            hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        end
        return true
    end
    return false
end

-- ============================================================================
-- AUTO RACE FARM SYSTEM
-- ============================================================================

local function startSkyFarm()
    stopSkyFarm()
    
    -- Teleport vehicle to sky
    teleportVehicleToSky()
    
    -- Main loop: bike flying in circles
    skyFarmConn = RunService.Heartbeat:Connect(function()
        if not State.autoFarm or not State.skyFarm then
            return
        end
        
        local char = getCharacter()
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        
        if not hrp then return end
        
        -- If not seated, try to sit
        if not hum or not hum.SeatPart then
            local vehicle = getVehicleModel()
            local seat = vehicle and vehicle:FindFirstChild("DriveSeat", true)
            if seat then
                hrp.CFrame = seat.CFrame * CFrame.new(0, 3, 0)
            end
            return
        end
        
        -- Update center if needed
        if not skyCenter then
            local locCF = LOCATION_CFRAMES[State.farmLocation] or CFrame.new(-9125.9, -18.2, 2521.5)
            skyCenter = Vector3.new(locCF.X, State.skyAltitude, locCF.Z)
        end
        
        -- Calculate circle position
        skyAngle = (skyAngle + 0.03) % (math.pi * 2)
        local radius = State.skyRadius
        local circlePos = skyCenter + Vector3.new(math.cos(skyAngle) * radius, 0, math.sin(skyAngle) * radius)
        local lookDir = Vector3.new(-math.sin(skyAngle), 0, math.cos(skyAngle))
        
        -- Bike CFrame
        local bikeCF = CFrame.lookAt(circlePos, circlePos + lookDir)
        
        -- LOCK BIKE IN SKY
        hrp.CFrame = bikeCF
        hrp.AssemblyLinearVelocity = lookDir * State.skySpeed
        hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        
        -- LOCK VEHICLE ALSO
        local vehicle = getVehicleModel()
        if vehicle then
            if vehicle.PrimaryPart then
                vehicle.PrimaryPart.CFrame = bikeCF
                vehicle.PrimaryPart.AssemblyLinearVelocity = lookDir * State.skySpeed
                vehicle.PrimaryPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            end
            for _, part in ipairs(vehicle:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CFrame = bikeCF
                    part.AssemblyLinearVelocity = lookDir * State.skySpeed
                    part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                end
            end
        end
        
        -- MAX ACCELERATION (engine)
        local values, seat = getVehicleDriveParts()
        if values then
            values.Gear.Value = 1
            values.Throttle.Value = 1
            values.Clutch.Value = 1
            values.Brake.Value = 0
            if values:FindFirstChild("RPM") then values.RPM.Value = 9000 end
            if values:FindFirstChild("Torque") then values.Torque.Value = 1000 end
            if values:FindFirstChild("Horsepower") then values.Horsepower.Value = 200 end
            if values:FindFirstChild("SteerC") then values.SteerC.Value = 0 end
            if values:FindFirstChild("SteerT") then values.SteerT.Value = 0 end
            if values:FindFirstChild("PBrake") then values.PBrake.Value = false end
        end
        if seat then
            seat.ThrottleFloat = 1
            seat.SteerFloat = 0
        end
        
        -- Hold W
        if State.farmHoldGas then
            if not farmGasHeld then
                pcall(function()
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.W, false, game)
                end)
                farmGasHeld = true
            end
        end
        
        -- Show status
        if tick() % 2 < 0.05 then
            local mph = hrp.AssemblyLinearVelocity.Magnitude * FARM_SPEED_CONVERSION
            local earning = mph >= 50
            print(string.format("SKY FARM: %.0f MPH | %s | Alt: %.0f | RM: %s", mph, earning and "EARNING RM!" or "slow...", hrp.Position.Y, formatCash(getCash())))
        end
    end)
end

-- ============================================================================
-- AUTO RACE FARM SYSTEM
-- ============================================================================

local RacingRemotes = ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("UI") and ReplicatedStorage.Modules.UI:FindFirstChild("Racing") and ReplicatedStorage.Modules.UI.Racing:FindFirstChild("Remotes")
local JoinRaceEvent = RacingRemotes and RacingRemotes:FindFirstChild("JoinRace")
local LeaveRaceEvent = RacingRemotes and RacingRemotes:FindFirstChild("LeaveRace")
local FinishedRaceEvent = RacingRemotes and RacingRemotes:FindFirstChild("FinishedRace")

local function getRaceCheckpoints(raceName)
    local raceFolder = workspace:FindFirstChild(raceName)
    if not raceFolder then return {} end
    local cps = raceFolder:FindFirstChild("Checkpoints")
    if not cps then return {} end
    
    local list = {}
    for _, v in ipairs(cps:GetChildren()) do
        if v:IsA("BasePart") then
            local num = tonumber(v.Name:match("%d+")) or 0
            table.insert(list, {part = v, num = num})
        end
    end
    table.sort(list, function(a, b) return a.num < b.num end)
    return list
end

local function touchCheckpoint(hrp, cp)
    if typeof(firetouchinterest) == "function" then
        firetouchinterest(hrp, cp, 0)
        task.wait(0.03)
        firetouchinterest(hrp, cp, 1)
        return true
    end
    return false
end

local function completeRace(raceName, laps)
    if not JoinRaceEvent or not FinishedRaceEvent then return false end
    
    local char = getCharacter()
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    -- Join race
    local ok, err = pcall(function()
        JoinRaceEvent:FireServer(raceName, laps or 1)
    end)
    if not ok then return false end
    
    task.wait(1)
    
    local checkpoints = getRaceCheckpoints(raceName)
    if #checkpoints == 0 then return false end
    
    -- Complete each lap
    for lap = 1, (laps or 1) do
        for i, cp in ipairs(checkpoints) do
            hrp.CFrame = cp.part.CFrame * CFrame.new(0, 5, 0)
            task.wait(0.05)
            touchCheckpoint(hrp, cp.part)
            task.wait(0.03)
        end
    end
    
    task.wait(0.3)
    
    -- Finish race
    pcall(function()
        FinishedRaceEvent:FireServer()
    end)
    
    return true
end

local autoRaceRunning = false
local autoRaceConn = nil

local function stopAutoRace()
    autoRaceRunning = false
    if autoRaceConn then
        autoRaceConn:Disconnect()
        autoRaceConn = nil
    end
    if LeaveRaceEvent then
        pcall(function() LeaveRaceEvent:FireServer() end)
    end
end

local function startAutoRace()
    stopAutoRace()
    autoRaceRunning = true
    
    autoRaceConn = RunService.Heartbeat:Connect(function()
        if not State.autoRace or not autoRaceRunning then
            return
        end
        
        -- Run every X seconds (controlled by delay)
        if tick() % (State.raceDelay + 2) < 0.1 then
            task.spawn(function()
                local ok = completeRace(State.raceTrack, State.raceLaps)
                if ok then
                    print(string.format("RACE: %s (%d lap(s)) - COMPLETE!", State.raceTrack, State.raceLaps))
                end
            end)
        end
    end)
end

-- ============================================================================
-- OLD FARM FUNCTIONS (kept for compatibility, not used in sky mode)
-- ============================================================================

local function setFarmGasHeld(held)
    if held == farmGasHeld then return end
    pcall(function()
        VirtualInputManager:SendKeyEvent(held, Enum.KeyCode.W, false, game)
    end)
    farmGasHeld = held
end

local function applyFullThrottle()
    local values, seat = getVehicleDriveParts()
    if values then
        pcall(function()
            values.Throttle.Value = 1
            if values:FindFirstChild("Brake") then
                values.Brake.Value = 0
            end
            if values:FindFirstChild("SteerC") then
                values.SteerC.Value = 0
            end
            if values:FindFirstChild("SteerT") then
                values.SteerT.Value = 0
            end
        end)
    end
    if seat then
        pcall(function()
            seat.ThrottleFloat = 1
            seat.SteerFloat = 0
        end)
    end
    if State.farmHoldGas then
        setFarmGasHeld(true)
    end
end

local function releaseFarmThrottle()
    setFarmGasHeld(false)
    local values, seat = getVehicleDriveParts()
    if values then
        pcall(function()
            values.Throttle.Value = 0
        end)
    end
    if seat then
        pcall(function()
            seat.ThrottleFloat = 0
        end)
    end
end

local function farmRecoverPosition()
    if tick() - lastFarmTeleportAt < 2 then return end
    lastFarmTeleportAt = tick()
    farmStuckSince = nil
    
    -- Release throttle to stop earning
    releaseFarmThrottle()
    
    -- If on bike, teleport vehicle (keeps player seated)
    if isRidingBike() then
        teleportVehicleWithPlayer(State.farmLocation)
    else
        -- Not on bike - use character teleport
        teleportTo(State.farmLocation)
    end
end

local function stopFarmDriveLoop()
    if farmDriveConn then
        farmDriveConn:Disconnect()
        farmDriveConn = nil
    end
    releaseFarmThrottle()
    farmStuckSince = nil
end

local function startFarmDriveLoop()
    stopFarmDriveLoop()
    farmDriveConn = RunService.Heartbeat:Connect(function()
        if not State.autoFarm then return end

        if not isRidingBike() then
            farmStuckSince = nil
            return
        end

        applyFullThrottle()

        local speed = getCurrentSpeedMph()
        if speed >= State.farmMinSpeed then
            farmStuckSince = nil
            return
        end

        if not State.farmStuckTeleport then return end

        farmStuckSince = farmStuckSince or tick()
        if tick() - farmStuckSince >= State.farmStuckSeconds then
            farmRecoverPosition()
        end
    end)
end

local function beginAutoFarm()
    lastFarmTeleportAt = 0
    lastSpawnAttemptAt = 0
    farmStuckSince = nil
    stopFarmDriveLoop()
    stopSkyFarm()
    
    if State.skyFarm then
        -- SKY FARM MODE: bike flies in sky
        if isRidingBike() then
            startSkyFarm()
        else
            task.delay(1, function()
                if not State.autoFarm then return end
                if State.autoSpawnBike then
                    local bikeName = getBestOwnedBikeName()
                    if bikeName then
                        spawnBike(bikeName)
                        lastSpawnAttemptAt = tick()
                        notify("Farm", "Spawned: " .. bikeName, 2)
                    end
                end
                task.delay(1.5, function()
                    if State.autoFarm then
                        startSkyFarm()
                    end
                end)
            end)
        end
    else
        -- NORMAL MODE: ground farm
        if isRidingBike() then
            farmRecoverPosition()
        else
            farmRecoverPosition()
            task.delay(2, function()
                if not State.autoFarm then return end
                if State.autoSpawnBike then
                    local bikeName = getBestOwnedBikeName()
                    if bikeName then
                        spawnBike(bikeName)
                        lastSpawnAttemptAt = tick()
                        notify("Farm", "Spawned: " .. bikeName, 2)
                    end
                end
            end)
        end
    end
end

local function buyBike(name)
    if not name then return false end
    return fireDealership(name, "Buy")
end

local function sellBike(name)
    if not name or not ownsBike(name) then return false end
    return fireDealership(name, "Sell")
end

local function getSelectedQuestEntry(tab, index)
    local extra = getExtra()
    if not extra then return nil end
    local quests = extra:FindFirstChild("Quests")
    if not quests then return nil end
    local tabFolder = quests:FindFirstChild(tab)
    if not tabFolder then return nil end
    local cfg = QuestConfig[tab]
    if not cfg then return nil end
    local questId = tabFolder:GetAttribute("Quest" .. index) or 1
    return cfg.Pool[questId]
end

local function isQuestClaimed(tab, index)
    local extra = getExtra()
    if not extra then return true end
    local quests = extra:FindFirstChild("Quests")
    local tabFolder = quests and quests:FindFirstChild(tab)
    if not tabFolder then return true end
    return tabFolder:GetAttribute("Claimed" .. index) == true
end

local function getQuestProgressValue(tab, index)
    local extra = getExtra()
    if not extra then return 0 end
    local quests = extra:FindFirstChild("Quests")
    if not quests then return 0 end
    local tabFolder = quests:FindFirstChild(tab)
    if not tabFolder then return 0 end

    local quest = getSelectedQuestEntry(tab, index)
    if not quest then return 0 end

    if quest.Type == "Miles" then
        return math.max(0, (extra:GetAttribute("CurrentMiles") or 0) - (tabFolder:GetAttribute("StartMiles") or 0))
    elseif quest.Type == "Speed" then
        return tabFolder:GetAttribute("MaxSpeedSinceReset") or 0
    elseif quest.Type == "DriveTime" then
        return math.max(0, (extra:GetAttribute("CurrentDriveTime") or 0) - (tabFolder:GetAttribute("StartDriveTime") or 0))
    elseif quest.Type == "RaceWins" then
        return math.max(0, (extra:GetAttribute("CurrentRaceWins") or 0) - (tabFolder:GetAttribute("StartRaceWins") or 0))
    elseif quest.Type == "RaceParticipation" then
        return math.max(0, (extra:GetAttribute("CurrentRaceParticipation") or 0) - (tabFolder:GetAttribute("StartRaceParticipation") or 0))
    elseif quest.Type == "MoneyEarned" then
        return math.max(0, (extra:GetAttribute("CurrentEarnedMoney") or 0) - (tabFolder:GetAttribute("StartEarnedMoney") or 0))
    end
    return 0
end

local QuestRequestEvent = ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("Warp") and ReplicatedStorage.Modules.Warp:FindFirstChild("Index") and ReplicatedStorage.Modules.Warp.Index:FindFirstChild("Event") and ReplicatedStorage.Modules.Warp.Index.Event:FindFirstChild("Request")

local function tryClaimQuest(tab, index)
    if isQuestClaimed(tab, index) then return false end
    local quest = getSelectedQuestEntry(tab, index)
    if not quest or quest.Target <= 0 then return false end
    if getQuestProgressValue(tab, index) < quest.Target then return false end

    -- Try using Warp.Index.Event.Request directly (works!)
    if QuestRequestEvent then
        local ok, err = pcall(function()
            QuestRequestEvent:FireServer("ClaimQuest", tab, index)
        end)
        if ok then
            return true
        end
    end

    -- Fallback: Warp client
    local client = getWarpClient("Quests")
    if client then
        pcall(function()
            client:Fire(true, tab, index)
        end)
        return true
    end

    warnWarpMissing()
    return false
end

local function tryClaimAllQuests()
    local claimed = 0
    for _, tab in ipairs(QUEST_TABS) do
        local cfg = QuestConfig[tab]
        if cfg then
            for i = 1, cfg.QuestCount do
                if tryClaimQuest(tab, i) then
                    claimed += 1
                end
            end
        end
    end
    return claimed
end

local function tryLuckySpin()
    if getCash() < 30000 then return false end
    pcall(function()
        LuckySpinSend:FireServer()
    end)
    return true
end

local function getBestAffordableBike()
    local cash = getCash() - State.buyReserveCash
    local bestName, bestPrice = nil, -1
    for _, child in ipairs(BikeList:GetChildren()) do
        local price = tonumber(child:GetAttribute("VehiclePrice")) or 0
        if price <= cash and not ownsBike(child.Name) and price > bestPrice then
            bestPrice = price
            bestName = child.Name
        end
    end
    return bestName, bestPrice
end

task.spawn(function()
    while State.running do
        -- Spawn bike if auto farm is on and not riding
        if State.autoFarm and State.autoSpawnBike and not isRidingBike() then
            if tick() - lastSpawnAttemptAt >= 6 then
                local bikeName = getBestOwnedBikeName()
                if bikeName and spawnBike(bikeName) then
                    lastSpawnAttemptAt = tick()
                end
            end
        end

        -- Start farm loop if on bike but loop hasn't started yet
        if State.autoFarm and isRidingBike() and not farmDriveConn and not skyFarmConn then
            if State.skyFarm then
                startSkyFarm()
            else
                startFarmDriveLoop()
            end
        end

        if State.autoClaimQuests and tick() - lastQuestClaimAt >= 4 then
            local n = tryClaimAllQuests()
            if n > 0 then
                notify("Quests", "Claimed " .. n .. " reward(s)", 2)
            end
            lastQuestClaimAt = tick()
        end

        if State.autoLuckySpin and tick() - lastSpinAt >= 8 then
            if tryLuckySpin() then
                notify("Spin", "Lucky spin sent", 2)
            end
            lastSpinAt = tick()
        end

        if State.autoBuyUpgrade and tick() - lastBuyAt >= 6 then
            local name, price = getBestAffordableBike()
            if name and buyBike(name) then
                notify("Shop", "Buying " .. name .. " (" .. formatCash(price) .. ")", 2)
            end
            lastBuyAt = tick()
        end

        task.wait(0.35)
    end
end)

local farmTab = w:tab("Farm", "zap")
local raceTab = w:tab("Race", "flag")
local autoTab = w:tab("Auto", "bot")
local shopTab = w:tab("Shop", "shopping-cart")
local tpTab = w:tab("Teleport", "map-pin")
local miscTab = w:tab("Misc", "settings")

local allBikeNames = getAllBikeNames()
local ownedBikeNames = getOwnedBikes()
if #ownedBikeNames == 0 then
    ownedBikeNames = { "No bikes owned" }
end

farmTab:section("Money Farm")
farmTab:paragraph("How it works", "The game pays RM only while you MOVE above 50 MPH on the server (every ~1.1s). You must ride on an open road at full gas — sitting still, wall-trapped burnout, or fake speed does NOT pay.")

farmTab:toggle("Auto Farm", false, function(on)
    State.autoFarm = on
    if on then
        beginAutoFarm()
        if State.skyFarm then
            notify("Farm", "SKY FARM ON — bike flying in the sky!", 3)
        else
            notify("Farm", "Auto farm ON — full gas + open road", 3)
        end
    else
        stopFarmDriveLoop()
        stopSkyFarm()
        notify("Farm", "Auto farm OFF", 2)
    end
end, "auto_farm")

farmTab:space(4)

farmTab:section("Sky Farm (RECOMMENDED)")
farmTab:paragraph("Sky Farm", "The bike flies in circles in the sky at high speed. Works because the game pays RM based on SPEED, not ground contact. Much more stable than driving on the road!")

farmTab:toggle("Sky Farm Mode", true, function(on)
    State.skyFarm = on
    if on then
        notify("Sky Farm", "Sky mode activated! Bike will fly!", 3)
    else
        notify("Sky Farm", "Ground mode activated", 2)
    end
end, "sky_farm_mode")

farmTab:slider("Altitude (Y)", 100, 2000, State.skyAltitude, function(val)
    State.skyAltitude = val
end, "sky_altitude")

farmTab:slider("Circle Radius", 10, 200, State.skyRadius, function(val)
    State.skyRadius = val
end, "sky_radius")

farmTab:slider("Speed (studs/s)", 100, 500, State.skySpeed, function(val)
    State.skySpeed = val
end, "sky_speed")

farmTab:space(4)

farmTab:section("Ground Farm (legacy)")
farmTab:dropdown("Farm Location", TELEPORT_LOCATIONS, State.farmLocation, function(val)
    State.farmLocation = val
end, "farm_location")

farmTab:toggle("Auto Spawn Best Owned Bike", true, function(on)
    State.autoSpawnBike = on
end, "auto_spawn_bike")

farmTab:toggle("Hold Full Gas (W)", true, function(on)
    State.farmHoldGas = on
    if not on then
        setFarmGasHeld(false)
    elseif State.autoFarm and isRidingBike() then
        setFarmGasHeld(true)
    end
end, "farm_hold_gas")

farmTab:toggle("Re-teleport When Stuck", true, function(on)
    State.farmStuckTeleport = on
end, "farm_stuck_tp")

farmTab:slider("Min Speed To Earn (MPH)", 50, 120, State.farmMinSpeed, function(val)
    State.farmMinSpeed = val
end, "farm_min_speed")

farmTab:slider("Stuck Seconds Before TP", 2, 10, State.farmStuckSeconds, function(val)
    State.farmStuckSeconds = val
end, "farm_stuck_seconds")

farmTab:space(4)

farmTab:section("Actions")
farmTab:button("Teleport To Farm Now", function()
    teleportTo(State.farmLocation)
    notify("Farm", "Teleported to " .. State.farmLocation, 2)
end)

farmTab:button("Spawn Best Owned Bike", function()
    local name = getBestOwnedBikeName()
    if name and spawnBike(name) then
        notify("Bike", "Spawning " .. name, 2)
    else
        notify("Bike", "No owned bike or Warp unavailable", 2)
    end
end)

farmTab:button("Show Farm Speed", function()
    local speed = getCurrentSpeedMph()
    local earning = speed >= State.farmMinSpeed
    notify("Farm", string.format("%.0f MPH — %s", speed, earning and "earning RM" or "NOT earning (too slow)"), 3)
end)

raceTab:section("Auto Race Farm")
raceTab:paragraph("Race Farm", "Automatically completes races by teleporting to each checkpoint and using firetouchinterest. Earns RM rewards per completed race!")

raceTab:toggle("Auto Race", false, function(on)
    State.autoRace = on
    if on then
        startAutoRace()
        notify("Race", "Auto Race ON - completing " .. State.raceTrack, 3)
    else
        stopAutoRace()
        notify("Race", "Auto Race OFF", 2)
    end
end, "auto_race")

raceTab:dropdown("Track", {"Race1", "Race2", "Race3", "Race4", "Race5", "Race6", "Race7"}, State.raceTrack, function(val)
    State.raceTrack = val
end, "race_track")

raceTab:dropdown("Laps", {"1", "2", "3", "5", "10"}, tostring(State.raceLaps), function(val)
    State.raceLaps = tonumber(val) or 1
end, "race_laps")

raceTab:slider("Delay Between Races (sec)", 1, 10, State.raceDelay, function(val)
    State.raceDelay = val
end, "race_delay")

raceTab:space(4)

raceTab:section("Track Info")
raceTab:label("Race1 = 31 checkpoints (long)")
raceTab:label("Race2 = 17 checkpoints")
raceTab:label("Race3 = 29 checkpoints")
raceTab:label("Race4 = 9 checkpoints")
raceTab:label("Race5 = 3 checkpoints (SHORT - recommended)")
raceTab:label("Race6 = 9 checkpoints")
raceTab:label("Race7 = 9 checkpoints")

raceTab:space(4)

raceTab:section("Manual Actions")
raceTab:button("Complete Race Now", function()
    task.spawn(function()
        local ok = completeRace(State.raceTrack, State.raceLaps)
        if ok then
            notify("Race", State.raceTrack .. " complete!", 3)
        else
            notify("Race", "Failed! No join/finished remote?", 3)
        end
    end)
end)

raceTab:button("Leave Race", function()
    if LeaveRaceEvent then
        pcall(function() LeaveRaceEvent:FireServer() end)
        notify("Race", "Left race", 2)
    end
end)

autoTab:section("Quests")
autoTab:paragraph("Quest claim", "Only sends claim when a quest is 100% complete. Server validates progress.")

autoTab:toggle("Auto Claim Quests", false, function(on)
    State.autoClaimQuests = on
    notify("Quests", on and "Auto claim ON" or "OFF", 2)
end, "auto_claim_quests")

autoTab:button("Claim All Completed Quests", function()
    local n = tryClaimAllQuests()
    notify("Quests", n > 0 and ("Sent " .. n .. " claim(s)") or "Nothing ready to claim", 2)
end)

autoTab:space(6)
autoTab:section("Lucky Spin")

autoTab:toggle("Auto Lucky Spin", false, function(on)
    State.autoLuckySpin = on
    notify("Spin", on and "Auto spin ON (needs 30k RM)" or "OFF", 2)
end, "auto_spin")

autoTab:button("Spin Lucky Wheel Now", function()
    if tryLuckySpin() then
        notify("Spin", "Spin sent", 2)
    else
        notify("Spin", "Need at least RM 30,000", 3)
    end
end)

shopTab:section("Dealership")

shopTab:dropdown("Bike To Buy", allBikeNames, State.selectedBike, function(val)
    State.selectedBike = val
end, "selected_bike")

shopTab:button("Buy Selected Bike", function()
    local price = getBikePrice(State.selectedBike)
    if not price then
        notify("Shop", "Unknown bike", 2)
        return
    end
    if ownsBike(State.selectedBike) then
        notify("Shop", "Already owned", 2)
        return
    end
    if getCash() < price then
        notify("Shop", "Not enough cash (" .. formatCash(getCash()) .. ")", 3)
        return
    end
    if buyBike(State.selectedBike) then
        notify("Shop", "Buy sent: " .. State.selectedBike, 2)
    end
end)

shopTab:button("Buy Best Affordable Bike", function()
    local name, price = getBestAffordableBike()
    if not name then
        notify("Shop", "No affordable bike found", 3)
        return
    end
    if buyBike(name) then
        notify("Shop", "Buying " .. name .. " (" .. formatCash(price) .. ")", 2)
    end
end)

shopTab:toggle("Auto Buy Upgrades", false, function(on)
    State.autoBuyUpgrade = on
    notify("Shop", on and "Auto buy ON" or "OFF", 2)
end, "auto_buy_upgrade")

shopTab:slider("Keep Cash Reserve", 0, 500000, State.buyReserveCash, function(val)
    State.buyReserveCash = val
end, "cash_reserve")

shopTab:space(6)
shopTab:section("Owned Bikes")

local sellSelection = ownedBikeNames[1] or "No bikes owned"
shopTab:dropdown("Owned Bike", ownedBikeNames, sellSelection, function(val)
    sellSelection = val
end, "owned_bike_select")

shopTab:button("Spawn Selected Owned Bike", function()
    if sellSelection == "No bikes owned" then return end
    if spawnBike(sellSelection) then
        notify("Bike", "Spawn sent", 2)
    end
end)

shopTab:button("Sell Selected Owned Bike", function()
    if sellSelection == "No bikes owned" then return end
    if sellBike(sellSelection) then
        notify("Shop", "Sell sent", 2)
    end
end)

tpTab:section("Locations")
tpTab:dropdown("Destination", TELEPORT_LOCATIONS, State.selectedTeleport, function(val)
    State.selectedTeleport = val
end, "teleport_select")

tpTab:button("Teleport Now", function()
    teleportTo(State.selectedTeleport)
    notify("Teleport", "Going to " .. State.selectedTeleport, 2)
end)

for _, loc in ipairs(TELEPORT_LOCATIONS) do
    tpTab:button("Go: " .. loc:gsub("_", " "), function()
        teleportTo(loc)
        notify("Teleport", loc, 2)
    end)
end

miscTab:section("Player Stats")
miscTab:button("Refresh Stats", function()
    notify("Stats", formatCash(getCash()) .. " | Miles: " .. getMiles() .. " | Value: " .. formatCash(getValue()), 4)
end)

miscTab:button("Show Current Speed", function()
    notify("Speed", string.format("%.0f MPH (needs 50+ to earn)", getCurrentSpeedMph()), 3)
end)

miscTab:space(6)
miscTab:section("Utility")

miscTab:toggle("Anti AFK", false, function(on)
    State.antiAfk = on
    if on then
        Connections.antiAfk = LocalPlayer.Idled:Connect(function()
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end)
        notify("AFK", "Anti AFK ON", 2)
    elseif Connections.antiAfk then
        Connections.antiAfk:Disconnect()
        Connections.antiAfk = nil
        notify("AFK", "Anti AFK OFF", 2)
    end
end, "anti_afk")

miscTab:button("Rejoin Server", function()
    pcall(function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
    end)
end)

miscTab:space(6)
miscTab:paragraph("Daily reward", "Claim manually at the DailyPad in the map — auto touch does not grant RM (server-side pad).")

task.defer(function()
    if initWarp() then
        notify("Loaded", "Slim Hub RIDE HAVEN ready!", 3)
    else
        notify("Loaded", "Hub ready — teleport works; shop/quests need Warp support", 4)
    end
end)