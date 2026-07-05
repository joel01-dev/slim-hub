--[[
    ============================================================
    ARENA AIMBOT - Script com Kyrilib UI
    Jogo: Iniciante da Arena
    ============================================================
    Funcionalidades:
    - Aimbot com FOV configurável (botão direito para ativar)
    - ESP (nomes, health, distância, caixas, tracers)
    - Rapid Fire (disparo rápido)
    - Recoil Control
    - Speed Hack
    - Jump Hack
    - No Fall Damage
    - Infinite Ammo
    - Aimbot part selection (Head/Torso/HumanoidRootPart)
    - Spread control
    ============================================================
]]

-- ============================================================================
-- KYRILIB UI SETUP
-- ============================================================================
local kyri = loadstring(game:HttpGet("https://kyrilib.dev/kyrilib/"))()

local w = kyri.new("Arena Hub", {
    GameName = "ArenaAimbot",
    AutoLoad = "default",
    Theme = {
        accent = Color3.fromRGB(255, 60, 60),
        bg = Color3.fromRGB(12, 12, 18),
        container = Color3.fromRGB(18, 18, 26),
        element = Color3.fromRGB(26, 26, 36),
        hover = Color3.fromRGB(35, 35, 48),
        active = Color3.fromRGB(255, 60, 60),
        text = Color3.fromRGB(245, 245, 255),
        subtext = Color3.fromRGB(160, 160, 180),
        border = Color3.fromRGB(40, 40, 55),
    }
})

if not w then return end

-- ============================================================================
-- TABS
-- ============================================================================
local aimTab = w:tab("Aimbot", "crosshair")
local espTab = w:tab("ESP", "eye")
local weaponTab = w:tab("Armas", "sword")
local moveTab = w:tab("Movimento", "zap")
local visualTab = w:tab("Visual", "palette")

-- ============================================================================
-- SERVICES & REFERENCES
-- ============================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ============================================================================
-- STATE / CONFIG
-- ============================================================================
local Config = {
    -- Aimbot
    AimbotEnabled = false,
    AimbotFOV = 120,
    AimbotSmoothness = 0.3,
    AimbotPart = "Head",
    AimbotKey = Enum.UserInputType.MouseButton2,
    AimbotSpread = 0,
    ShowFOVCircle = true,
    FOVCircleColor = Color3.fromRGB(255, 255, 255),
    
    -- ESP
    ESPEnabled = false,
    ESPNames = true,
    ESPHealth = true,
    ESPDistance = true,
    ESPBoxes = true,
    ESPTracers = false,
    ESPColor = Color3.fromRGB(255, 60, 60),
    ESPEnemyColor = Color3.fromRGB(255, 255, 0),
    ESPTeamColor = Color3.fromRGB(0, 255, 100),
    ESPMaxDistance = 500,
    
    -- Weapon
    RapidFire = false,
    RapidFireDelay = 0.05,
    NoRecoil = false,
    InfiniteAmmo = false,
    
    -- Movement
    SpeedEnabled = false,
    SpeedValue = 50,
    JumpEnabled = false,
    JumpValue = 100,
    NoFallDamage = false,
    InfiniteJump = false,
    FlyEnabled = false,
    FlySpeed = 50,
}

-- ============================================================================
-- FOV CIRCLE
-- ============================================================================
local FOVCircle = Drawing and Drawing.new("Circle") or nil
if FOVCircle then
    FOVCircle.Visible = false
    FOVCircle.Radius = Config.AimbotFOV
    FOVCircle.Filled = false
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    FOVCircle.Color = Config.FOVCircleColor
    FOVCircle.Thickness = 1.5
    FOVCircle.Transparency = 0.8
end

-- ============================================================================
-- ESP SYSTEM
-- ============================================================================
local ESPObjects = {}

local function ClearESP()
    for _, obj in pairs(ESPObjects) do
        if obj then
            if obj.Type == "Drawing" then
                obj.Visible = false
            elseif obj.Type == "Highlight" then
                obj:Destroy()
            end
        end
    end
    ESPObjects = {}
end

local function IsTeamMate(player)
    if player.Team and LocalPlayer.Team then
        return player.Team == LocalPlayer.Team
    end
    return false
end

local function GetEnemyPlayers()
    local enemies = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            if not IsTeamMate(player) then
                table.insert(enemies, player)
            end
        end
    end
    return enemies
end

local function CreateESP(player)
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
    
    local espData = {}
    
    -- Highlight
    if Config.ESPBoxes then
        local highlight = Instance.new("Highlight")
        highlight.FillColor = IsTeamMate(player) and Config.ESPTeamColor or Config.ESPEnemyColor
        highlight.FillTransparency = 0.7
        highlight.OutlineColor = IsTeamMate(player) and Config.ESPTeamColor or Config.ESPEnemyColor
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = player.Character
        espData.Highlight = highlight
    end
    
    -- Name ESP
    if Config.ESPNames then
        local nameBillboard = Instance.new("BillboardGui")
        nameBillboard.Size = UDim2.new(0, 200, 0, 30)
        nameBillboard.StudsOffset = Vector3.new(0, 3, 0)
        nameBillboard.AlwaysOnTop = true
        nameBillboard.LightInfluence = 0
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 1, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3 = Color3.new(1, 1, 1)
        nameLabel.TextStrokeTransparency = 0
        nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 14
        nameLabel.Text = player.Name
        nameLabel.Parent = nameBillboard
        
        nameBillboard.Adornee = player.Character:FindFirstChild("Head") or player.Character:FindFirstChild("HumanoidRootPart")
        nameBillboard.Parent = player.Character
        espData.NameGui = nameBillboard
    end
    
    -- Health ESP
    if Config.ESPHealth then
        local healthBillboard = Instance.new("BillboardGui")
        healthBillboard.Size = UDim2.new(0, 200, 0, 20)
        healthBillboard.StudsOffset = Vector3.new(0, 2.2, 0)
        healthBillboard.AlwaysOnTop = true
        healthBillboard.LightInfluence = 0
        
        local healthBar = Instance.new("Frame")
        healthBar.Size = UDim2.new(0.8, 0, 4, 0)
        healthBar.Position = UDim2.new(0.1, 0, 0, 0)
        healthBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        healthBar.BorderSizePixel = 0
        healthBar.Parent = healthBillboard
        
        local healthFill = Instance.new("Frame")
        healthFill.Size = UDim2.new(1, 0, 1, 0)
        healthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        healthFill.BorderSizePixel = 0
        healthFill.Parent = healthBar
        
        healthBillboard.Adornee = player.Char:FindFirstChild("Head") or player.Character:FindFirstChild("HumanoidRootPart")
        healthBillboard.Parent = player.Character
        espData.HealthGui = healthBillboard
        espData.HealthFill = healthFill
    end
    
    ESPObjects[player] = espData
end

local function UpdateESP()
    if not Config.ESPEnabled then
        ClearESP()
        return
    end
    
    -- Remove ESP for players that no longer exist
    for player, _ in pairs(ESPObjects) do
        if not player.Parent or not player.Character then
            if ESPObjects[player] and ESPObjects[player].Highlight then
                ESPObjects[player].Highlight:Destroy()
            end
            ESPObjects[player] = nil
        end
    end
    
    -- Add/update ESP for enemies
    for _, player in pairs(GetEnemyPlayers()) do
        if not ESPObjects[player] then
            CreateESP(player)
        end
        
        local espData = ESPObjects[player]
        if espData and player.Character and player.Character:FindFirstChild("Humanoid") then
            -- Update health bar
            if espData.HealthFill then
                local humanoid = player.Character.Humanoid
                local healthPercent = humanoid.Health / humanoid.MaxHealth
                espData.HealthFill.Size = UDim2.new(healthPercent, 0, 1, 0)
                espData.HealthFill.BackgroundColor3 = Color3.fromRGB(
                    255 * (1 - healthPercent),
                    255 * healthPercent,
                    0
                )
            end
        end
    end
end

-- ============================================================================
-- AIMBOT SYSTEM
-- ============================================================================
local AimbotTarget = nil

local function GetPartPosition(character, partName)
    if partName == "Closest" then
        local hrp = character:FindFirstChild("HumanoidRootPart")
        local head = character:FindFirstChild("Head")
        local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
        
        local cameraPos = Camera.CFrame.Position
        local closest = nil
        local closestDist = math.huge
        
        for _, part in pairs({hrp, head, torso}) do
            if part then
                local dist = (part.Position - cameraPos).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closest = part
                end
            end
        end
        return closest
    else
        return character:FindFirstChild(partName) or character:FindFirstChild("HumanoidRootPart")
    end
end

local function IsVisible(targetPart)
    if not targetPart then return false end
    
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character, targetPart.Parent}
    rayParams.IgnoreWater = true
    
    local direction = (targetPart.Position - Camera.CFrame.Position)
    local result = Workspace:Raycast(Camera.CFrame.Position, direction, rayParams)
    
    if result then
        if result.Instance:IsDescOf(targetPart.Parent) then
            return true
        end
    end
    return true
end

local function GetTargetInFOV()
    local closestTarget = nil
    local closestDist = Config.AimbotFOV
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    for _, player in pairs(GetEnemyPlayers()) do
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            local humanoid = player.Character.Humanoid
            if humanoid.Health > 0 then
                local targetPart = GetPartPosition(player.Character, Config.AimbotPart)
                if targetPart then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                    if onScreen then
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                        if dist < closestDist then
                            if IsVisible(targetPart) then
                                closestDist = dist
                                closestTarget = targetPart
                            end
                        end
                    end
                end
            end
        end
    end
    
    return closestTarget
end

local function AimAtTarget(target)
    if not target then return end
    
    local cameraPos = Camera.CFrame.Position
    local targetPos = target.Position
    
    -- Apply spread
    if Config.AimbotSpread > 0 then
        local spreadAmount = Config.AimbotSpread
        targetPos = targetPos + Vector3.new(
            math.random(-spreadAmount, spreadAmount),
            math.random(-spreadAmount, spreadAmount),
            math.random(-spreadAmount, spreadAmount)
        )
    end
    
    local direction = (targetPos - cameraPos)
    local targetCFrame = CFrame.lookAt(cameraPos, cameraPos + direction)
    
    -- Smooth aim
    Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, 1 - Config.AimbotSmoothness)
end

-- ============================================================================
-- RAPID FIRE SYSTEM
-- ============================================================================
local RapidFireConnection = nil
local OriginalFireRate = nil

local function SetupRapidFire(weapon)
    if not weapon then return end
    
    -- Try to find the weapon's fire rate property
    local success, fireRate = pcall(function()
        return weapon:FindFirstChild("FireRate") or weapon:FindFirstChild("fireRate") or weapon:FindFirstChild("Rate")
    end)
    
    if success and fireRate then
        if not OriginalFireRate then
            OriginalFireRate = fireRate.Value
        end
        if Config.RapidFire then
            fireRate.Value = Config.RapidFireDelay
        else
            fireRate.Value = OriginalFireRate or 0.1
        end
    end
end

-- ============================================================================
-- RECOIL CONTROL
-- ============================================================================
local RecoilConnection = nil

local function SetupRecoilControl()
    -- Hook into weapon recoil
    local char = LocalPlayer.Character
    if not char then return end
    
    local weapon = char:FindFirstChildOfClass("Tool")
    if not weapon then return end
    
    -- Common recoil patterns
    local success = pcall(function()
        local module = require(weapon:FindFirstChild("WeaponController") or weapon:FindFirstChild("WeaponData") or weapon:FindFirstChild("Config"))
        if module then
            if Config.NoRecoil then
                if module.Recoil then module.Recoil = 0 end
                if module.recoil then module.recoil = 0 end
                if module.Kick then module.Kick = 0 end
                if module.kick then module.kick = 0 end
            end
        end
    end)
end

-- ============================================================================
-- MOVEMENT MODIFICATIONS
-- ============================================================================
local function SetupMovement()
    local char = LocalPlayer.Character
    if not char then return end
    
    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    if Config.SpeedEnabled then
        humanoid.WalkSpeed = Config.SpeedValue
    else
        humanoid.WalkSpeed = 16
    end
    
    if Config.JumpEnabled then
        humanoid.JumpPower = Config.JumpValue
    else
        humanoid.JumpPower = 50
    end
end

-- ============================================================================
-- FLY SYSTEM
-- ============================================================================
local FlyBodyVelocity = nil
local FlyBodyGyro = nil

local function StartFly()
    local char = LocalPlayer.Character
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    FlyBodyVelocity = Instance.new("BodyVelocity")
    FlyBodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    FlyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
    FlyBodyVelocity.Parent = hrp
    
    FlyBodyGyro = Instance.new("BodyGyro")
    FlyBodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    FlyBodyGyro.P = 9e4
    FlyBodyGyro.Parent = hrp
end

local function StopFly()
    if FlyBodyVelocity then
        FlyBodyVelocity:Destroy()
        FlyBodyVelocity = nil
    end
    if FlyBodyGyro then
        FlyBodyGyro:Destroy()
        FlyBodyGyro = nil
    end
end

local function UpdateFly()
    if not Config.FlyEnabled then
        StopFly()
        return
    end
    
    if not FlyBodyVelocity then
        StartFly()
    end
    
    if FlyBodyVelocity and FlyBodyGyro then
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local cameraDirection = Camera.CFrame.LookVector
            local moveDir = Vector3.new(0, 0, 0)
            
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                moveDir = moveDir + cameraDirection
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                moveDir = moveDir - cameraDirection
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                moveDir = moveDir - Camera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                moveDir = moveDir + Camera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                moveDir = moveDir + Vector3.new(0, 1, 0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                moveDir = moveDir - Vector3.new(0, 1, 0)
            end
            
            FlyBodyVelocity.Velocity = moveDir.Unit * Config.FlySpeed
            FlyBodyGyro.CFrame = Camera.CFrame
        end
    end
end

-- ============================================================================
-- INFINITE JUMP
-- ============================================================================
local InfiniteJumpConnection = nil

local function SetupInfiniteJump()
    if Config.InfiniteJump then
        InfiniteJumpConnection = UserInputService.JumpRequest:Connect(function()
            local char = LocalPlayer.Character
            if char then
                local humanoid = char:FindFirstChild("Humanoid")
                if humanoid then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end)
    else
        if InfiniteJumpConnection then
            InfiniteJumpConnection:Disconnect()
            InfiniteJumpConnection = nil
        end
    end
end

-- ============================================================================
-- NO FALL DAMAGE
-- ============================================================================
local function SetupNoFallDamage()
    if Config.NoFallDamage then
        local char = LocalPlayer.Character
        if char then
            local humanoid = char:FindFirstChild("Humanoid")
            if humanoid then
                humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
            end
        end
    end
end

-- ============================================================================
-- INFINITE AMMO
-- ============================================================================
local function SetupInfiniteAmmo()
    if not Config.InfiniteAmmo then return end
    
    local char = LocalPlayer.Character
    if not char then return end
    
    local weapon = char:FindFirstChildOfClass("Tool")
    if not weapon then return end
    
    pcall(function()
        local ammo = weapon:FindFirstChild("Ammo") or weapon:FindFirstChild("ammo") or weapon:FindFirstChild("CurrentAmmo")
        if ammo then
            ammo.Value = ammo.MaxValue or 999
        end
    end)
end

-- ============================================================================
-- MAIN UPDATE LOOP
-- ============================================================================
local UpdateConnection = RunService.RenderStepped:Connect(function()
    -- Update FOV Circle
    if FOVCircle then
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        FOVCircle.Radius = Config.AimbotFOV
        FOVCircle.Visible = Config.ShowFOVCircle and Config.AimbotEnabled
        FOVCircle.Color = Config.FOVCircleColor
    end
    
    -- Aimbot
    if Config.AimbotEnabled then
        AimbotTarget = GetTargetInFOV()
        if AimbotTarget then
            AimAtTarget(AimbotTarget)
        end
    end
    
    -- ESP
    UpdateESP()
    
    -- Fly
    UpdateFly()
    
    -- Movement
    SetupMovement()
    
    -- Infinite Ammo
    SetupInfiniteAmmo()
end)

-- ============================================================================
-- INPUT HANDLING (Right Click for Aimbot)
-- ============================================================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.UserInputType == Config.AimbotKey then
        Config.AimbotEnabled = not Config.AimbotEnabled
        w:notify("Aimbot", Config.AimbotEnabled and "Ativado" or "Desativado", 1)
    end
end)

-- ============================================================================
-- CHARACTER HANDLING
-- ============================================================================
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    SetupNoFallDamage()
    SetupRecoilControl()
end)

-- ============================================================================
-- UI - AIMBOT TAB
-- ============================================================================
aimTab:section("Aimbot Principal")

local aimbotToggle = aimTab:toggle("Ativar Aimbot", false, function(state)
    Config.AimbotEnabled = state
end, "aimbot_enabled")

aimTab:keybind("Tecla Aimbot", "MouseButton2", false, function()
    Config.AimbotEnabled = not Config.AimbotEnabled
    aimbotToggle:set(Config.AimbotEnabled)
end, "aimbot_key")

aimTab:space(8)

aimTab:section("Configuração do FOV")

aimTab:slider("FOV (pixels)", 10, 500, 120, function(val)
    Config.AimbotFOV = val
end, "aimbot_fov")

aimTab:slider("Smoothness", 0, 100, 30, function(val)
    Config.AimbotSmoothness = val / 100
end, "aimbot_smooth")

aimTab:space(8)

aimTab:section("Spread (Dispersão)")

aimTab:slider("Spread", 0, 50, 0, function(val)
    Config.AimbotSpread = val
end, "aimbot_spread")

aimTab:space(8)

aimTab:section("Parte do Corpo")

aimTab:dropdown("Target Part", {"Head", "Torso", "HumanoidRootPart", "Closest"}, "Head", function(val)
    Config.AimbotPart = val
end, "aimbot_part")

aimTab:space(8)

aimTab:section("FOV Circle")

local fovCircleToggle = aimTab:toggle("Mostrar Círculo FOV", true, function(state)
    Config.ShowFOVCircle = state
end, "show_fov_circle")

aimTab:colorpicker("Cor do Círculo", Color3.fromRGB(255, 255, 255), function(color)
    Config.FOVCircleColor = color
end, "fov_circle_color")

aimTab:space(8)

aimTab:section("Prioridade")

aimTab:dropdown("Prioridade", {"Perto da Mira", "Mais Próximo", "Menos Vida"}, "Perto da Mira", function(val)
    Config.AimbotPriority = val
end, "aimbot_priority")

-- ============================================================================
-- UI - ESP TAB
-- ============================================================================
espTab:section("ESP Principal")

local espToggle = espTab:toggle("Ativar ESP", false, function(state)
    Config.ESPEnabled = state
    if not state then
        ClearESP()
    end
end, "esp_enabled")

espTab:space(8)

espTab:section("Opções de ESP")

espTab:toggle("Mostrar Nomes", true, function(state)
    Config.ESPNames = state
end, "esp_names")

espTab:toggle("Mostrar Barra de Vida", true, function(state)
    Config.ESPHealth = state
end, "esp_health")

espTab:toggle("Mostrar Distância", false, function(state)
    Config.ESPDistance = state
end, "esp_distance")

espTab:toggle("Mostrar Caixas (Highlight)", true, function(state)
    Config.ESPBoxes = state
end, "esp_boxes")

espTab:toggle("Mostrar Tracers", false, function(state)
    Config.ESPTracers = state
end, "esp_tracers")

espTab:space(8)

espTab:section("Cores do ESP")

espTab:colorpicker("Cor Inimigo", Color3.fromRGB(255, 60, 60), function(color)
    Config.ESPColor = color
end, "esp_color")

espTab:colorpicker("Cor Aliado", Color3.fromRGB(0, 255, 100), function(color)
    Config.ESPTeamColor = color
end, "esp_team_color")

espTab:space(8)

espTab:section("Alcance")

espTab:slider("Distância Máxima", 50, 1000, 500, function(val)
    Config.ESPMaxDistance = val
end, "esp_max_dist")

-- ============================================================================
-- UI - WEAPON TAB
-- ============================================================================
weaponTab:section("Disparo")

local rapidFireToggle = weaponTab:toggle("Rapid Fire", false, function(state)
    Config.RapidFire = state
end, "rapid_fire")

weaponTab:slider("Delay do Rapid Fire", 1, 100, 5, function(val)
    Config.RapidFireDelay = val / 1000
end, "rapid_fire_delay")

weaponTab:space(8)

weaponTab:section("Recoil")

local recoilToggle = weaponTab:toggle("No Recoil", false, function(state)
    Config.NoRecoil = state
    SetupRecoilControl()
end, "no_recoil")

weaponTab:space(8)

weaponTab:section("Munição")

local ammoToggle = weaponTab:toggle("Munição Infinita", false, function(state)
    Config.InfiniteAmmo = state
end, "infinite_ammo")

weaponTab:space(8)

weaponTab:section("Informações")

weaponTab:label("Rapid Fire: Aumenta a cadência de tiro")
weaponTab:label("No Recoil: Remove o recuo da arma")
weaponTab:label("Infinite Ammo: Nunca fica sem munição")

-- ============================================================================
-- UI - MOVEMENT TAB
-- ============================================================================
moveTab:section("Velocidade")

local speedToggle = moveTab:toggle("Speed Hack", false, function(state)
    Config.SpeedEnabled = state
end, "speed_enabled")

moveTab:slider("Velocidade", 16, 500, 50, function(val)
    Config.SpeedValue = val
end, "speed_value")

moveTab:space(8)

moveTab:section("Pulo")

local jumpToggle = moveTab:toggle("Jump Hack", false, function(state)
    Config.JumpEnabled = state
end, "jump_enabled")

moveTab:slider("Força do Pulo", 50, 500, 100, function(val)
    Config.JumpValue = val
end, "jump_value")

moveTab:space(8)

moveTab:section("Voo")

local flyToggle = moveTab:toggle("Fly", false, function(state)
    Config.FlyEnabled = state
    if not state then
        StopFly()
    end
end, "fly_enabled")

moveTab:slider("Velocidade do Voo", 10, 200, 50, function(val)
    Config.FlySpeed = val
end, "fly_speed")

moveTab:space(8)

moveTab:section("Dano")

local noFallToggle = moveTab:toggle("No Fall Damage", false, function(state)
    Config.NoFallDamage = state
    if state then
        SetupNoFallDamage()
    end
end, "no_fall_damage")

local infJumpToggle = moveTab:toggle("Infinite Jump", false, function(state)
    Config.InfiniteJump = state
    SetupInfiniteJump()
end, "infinite_jump")

moveTab:space(8)

moveTab:section("Controles")

moveTab:label("WASD - Mover")
moveTab:label("Space - Subir (Fly)")
moveTab:label("Shift - Descer (Fly)")

-- ============================================================================
-- UI - VISUAL TAB
-- ============================================================================
visualTab:section("Tema")

visualTab:button("Vermelho", function()
    w:apply_theme({
        accent = Color3.fromRGB(255, 60, 60),
        active = Color3.fromRGB(255, 60, 60),
    })
    w:notify("Tema", "Vermelho aplicado!", 2)
end)

visualTab:button("Azul", function()
    w:apply_theme({
        accent = Color3.fromRGB(60, 120, 255),
        active = Color3.fromRGB(60, 120, 255),
    })
    w:notify("Tema", "Azul aplicado!", 2)
end)

visualTab:button("Roxo", function()
    w:apply_theme({
        accent = Color3.fromRGB(130, 80, 255),
        active = Color3.fromRGB(130, 80, 255),
    })
    w:notify("Tema", "Roxo aplicado!", 2)
end)

visualTab:button("Verde", function()
    w:apply_theme({
        accent = Color3.fromRGB(60, 255, 100),
        active = Color3.fromRGB(60, 255, 100),
    })
    w:notify("Tema", "Verde aplicado!", 2)
end)

visualTab:button("Rosa", function()
    w:apply_theme({
        accent = Color3.fromRGB(255, 100, 180),
        active = Color3.fromRGB(255, 100, 180),
    })
    w:notify("Tema", "Rosa aplicado!", 2)
end)

visualTab:space(8)

visualTab:section("Cor de Destaque")

visualTab:colorpicker("Accent Color", Color3.fromRGB(255, 60, 60), function(c)
    w:accent(c)
end, "accent_color")

visualTab:space(8)

visualTab:section("Informações")

visualTab:label("Script para: Iniciante da Arena")
visualTab:label("Versão: 2.0")
visualTab:label("UI: Kyrilib")
visualTab:space(4)

visualTab:button("Destruir Script", function()
    if UpdateConnection then UpdateConnection:Disconnect() end
    if RapidFireConnection then RapidFireConnection:Disconnect() end
    if InfiniteJumpConnection then InfiniteJumpConnection:Disconnect() end
    ClearESP()
    StopFly()
    w:destroy()
end)

-- ============================================================================
-- NOTIFICATION
-- ============================================================================
w:notify("Script Carregado!", "Pressione RightControl para mostrar/ocultar", 5)
w:notify("Aimbot", "Clique com botão direito para ativar", 3)
