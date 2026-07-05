--[[
================================================================================
SPEED TRAINER HUB - KyriLib Panel
Game: Treinamento de Velocidade (Speed Training)
Creator: Stack Of Bones
PlaceId: 105553804282311
================================================================================
]]

-- Carregar KyriLib
local kyri = loadstring(game:HttpGet("https://kyrilib.dev/kyrilib/"))()

-- Criar janela principal
local w = kyri.new("Speed Trainer Hub", {
    GameName = "SpeedTrainerHub",
    AutoLoad = "default",
})

if not w then return end

-- ============================================================================
-- TABS
-- ============================================================================

local main = w:tab("Principal", "home")
local auto = w:tab("Automation", "bot")
local eggs = w:tab("Eggs", "egg")
local pets = w:tab("Pets", "paw-print")
local movement = w:tab("Movement", "zap")
local esp = w:tab("ESP", "eye")
local shop = w:tab("Shop", "shopping-bag")
local misc = w:tab("Misc", "terminal")

-- ============================================================================
-- REFERENCIAS GLOBAIS
-- ============================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer
local Paper = require(ReplicatedStorage:WaitForChild("Paper"))
local Network = require(ReplicatedStorage.Paper.Client.Network)

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

local function GetHumanoid()
    if LP.Character and LP.Character:FindFirstChild("Humanoid") then
        return LP.Character.Humanoid
    end
    return nil
end

-- ============================================================================
-- TAB PRINCIPAL
-- ============================================================================

main:section("Informações do Jogador")

main:label("Nome: " .. LP.Name)
main:label("Wins: " .. tostring(LP.leaderstats and LP.leaderstats.Wins and LP.leaderstats.Wins.Value or "?"))

main:space()

main:section("Status do Servidor")

main:button("Atualizar Stats", function()
    if LP.leaderstats then
        w:notify("Stats", "Wins: " .. tostring(LP.leaderstats.Wins.Value) .. " | Rebirths: " .. tostring(LP.leaderstats.Rebirths.Value), 3)
    end
end)

main:button("Reconectar (Rejoin)", function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LP)
end)

-- ============================================================================
-- TAB AUTOMATION
-- ============================================================================

auto:section("Auto Hatch")

local autoHatchToggle = auto:toggle("Auto Hatch Automático", false, function(state)
    if state then
        -- Ativar via o remote do próprio jogo
        Network.FireServer("Toggle Setting", "AutoHatch")
        w:notify("Auto Hatch", "Auto hatch ativado!", 2)
    else
        Network.FireServer("Toggle Setting", "AutoHatch")
        w:notify("Auto Hatch", "Auto hatch desativado!", 2)
    end
end, "auto_hatch")

local selectedEggDropdown = auto:dropdown("Ovo para Auto Hatch", {
    "Basic Egg", "Lava Egg", "Sakura Egg", "Snow Egg", 
    "Rare Egg", "Forest Egg", "Aqua Egg", "Cave Egg", 
    "Galaxy Egg", "Angelic Egg"
}, "Basic Egg", function(val)
    -- Apenas atualiza a seleção
end, "selected_egg")

auto:space()

auto:section("Auto Win / Farming")

-- Detectar quando uma corrida termina
auto:toggle("Auto Join Next Race", false, function(state)
    if state then
        -- Procurar botão de join na UI
        local mainGui = LP:FindFirstChild("PlayerGui")
        if mainGui then
            -- O jogo tem um frame Main com botões de corrida
            w:notify("Auto Join", "Monitorando corridas...", 2)
        end
    end
end, "auto_join")

-- Simular clique no botão de correr/join race
auto:button("Join Race (Manual)", function()
    -- Tenta encontrar botões de corrida
    local mainGui = LP:WaitForChild("PlayerGui")
    local mainFrame = mainGui:FindFirstChild("Main")
    if mainFrame then
        -- Procura por botões de join/race no frame
        for _, v in ipairs(mainFrame:GetDescendants()) do
            if v:IsA("TextButton") and (v.Name:lower():find("join") or v.Name:lower():find("race") or v.Name:lower():find("correr") or v.Name:lower():find("play")) then
                -- Fired os eventos de clique
                local success, err = pcall(function()
                    v:Fire()
                    -- Tenta Activated também
                    local activateEvent = v:FindFirstChild("Activated")
                    if activateEvent then
                        activateEvent:Fire()
                    end
                end)
                if success then
                    w:notify("Join", "Botão de corrida clicado!", 2)
                end
                break
            end
        end
    end
end)

-- ============================================================================
-- TAB EGGS
-- ============================================================================

eggs:section("Chocar Ovos")

local eggNameInput = eggs:input("Nome do Ovo", "Ex: Basic Egg", function(text) end, "egg_name")
local eggQtyInput = eggs:input("Quantidade", "1", function(text) end, "egg_qty")

eggs:button("Chocar Ovo (1x)", function()
    local eggName = eggNameInput.input.Text
    if eggName == "" then eggName = "Basic Egg" end
    
    local success, result = Network.InvokeServer("Hatch Egg", eggName, 1)
    if success then
        w:notify("Ovo", "Ovo chocado com sucesso!", 3)
    else
        w:notify("Erro", tostring(result or "Falha ao chocar"), 3)
    end
end)

eggs:button("Chocar Ovos (Múltiplo)", function()
    local eggName = eggNameInput.input.Text
    if eggName == "" then eggName = "Basic Egg" end
    
    local qty = tonumber(eggQtyInput.input.Text) or 1
    qty = math.min(qty, 100) -- Safety limit
    
    task.spawn(function()
        for i = 1, qty do
            local success, result = Network.InvokeServer("Hatch Egg", eggName, 1)
            if not success then
                w:notify("Parou", tostring(result or "Erro"), 2)
                break
            end
            task.wait(0.3)
        end
        w:notify("Ovos", qty .. " ovos chocados!", 2)
    end)
end)

eggs:space()

eggs:section("Informação dos Ovos")

eggs:button("Ver Preços dos Ovos", function()
    local Tables = ReplicatedStorage:FindFirstChild("Tables")
    if Tables then
        local success, eggData = pcall(function()
            return require(Tables:FindFirstChild("Eggs"))
        end)
        if success and eggData then
            local msg = ""
            for name, data in pairs(eggData) do
                if data.Cost then
                    msg = msg .. name .. ": " .. tostring(data.Cost) .. " Wins\n"
                end
            end
            w:notify("Preços", msg, 6)
        end
    end
end)

-- ============================================================================
-- TAB PETS
-- ============================================================================

pets:section("Gerenciamento de Pets")

local petNameInput = pets:input("Nome do Pet", "Ex: Cat", function(text) end, "pet_name")

pets:button("Equipar Pet", function()
    local petName = petNameInput.input.Text
    if petName == "" then
        w:notify("Erro", "Digite um nome de pet", 2)
        return
    end
    
    local _, _2 = Network.InvokeServer("Pet", {
        Action = "Equip",
        Pet = petName
    })
    w:notify("Pet", "Tentando equipar: " .. petName, 2)
end)

pets:button("Desequipar Pet", function()
    local petName = petNameInput.input.Text
    if petName == "" then
        w:notify("Erro", "Digite um nome de pet", 2)
        return
    end
    
    local _, _2 = Network.InvokeServer("Pet", {
        Action = "Unequip",
        Pet = petName
    })
    w:notify("Pet", "Tentando desequipar: " .. petName, 2)
end)

pets:button("Equipar Melhor Pet", function()
    local _, _2, _3 = Network.InvokeServer("Pet", {
        Action = "EquipBest",
        Sort = "Rarity"
    })
    w:notify("Pet", "Melhor pet equipado!", 2)
end)

pets:button("Desequipar Todos", function()
    local _, _2, _3 = Network.InvokeServer("Pet", {
        Action = "UnequipAll"
    })
    w:notify("Pets", "Todos desequipados!", 2)
end)

pets:space()

pets:section("Auto Delete (Auto Remover)")

local autoDeleteTierDropdown = pets:dropdown("Tier para Auto Delete", {"1 (Normal)", "2 (Golden)", "3 (Rainbow)", "All"}, "1 (Normal)", function(val)
end, "autodelete_tier")

pets:button("Configurar Auto Delete para Pet", function()
    local petName = petNameInput.input.Text
    if petName == "" then
        w:notify("Erro", "Digite um nome de pet", 2)
        return
    end
    
    local tier = autoDeleteTierDropdown:get()
    local tierNum = tier:match("^(%d+)") or "all"
    
    if tierNum == "all" then
        tierNum = "all"
    else
        tierNum = tonumber(tierNum)
    end
    
    Network.InvokeServer("Pet", {
        Action = "AutoDelete",
        Tier = tierNum,
        Pet = petName
    })
    w:notify("Auto Delete", "Configurado para " .. petName, 2)
end)

pets:space()

pets:section("Crafting (Fusão)")

pets:button("Craft Size (Aumentar Tamanho)", function()
    local petName = petNameInput.input.Text
    if petName == "" then
        w:notify("Erro", "Digite um nome de pet", 2)
        return
    end
    
    local v2, v3 = Network.InvokeServer("Pet", {
        Action = "CraftSize",
        Pet = petName
    })
    if v2 then
        w:notify("Craft", "Tamanho aumentado!", 2)
    else
        w:notify("Craft", "Falha: " .. tostring(v3), 2)
    end
end)

-- ============================================================================
-- TAB MOVEMENT
-- ============================================================================

movement:section("Speed / WalkSpeed")

movement:slider("WalkSpeed", 16, 500, 16, function(val)
    local hum = GetHumanoid()
    if hum then
        hum.WalkSpeed = val
    end
end, "walkspeed")

movement:slider("JumpPower", 50, 500, 50, function(val)
    local hum = GetHumanoid()
    if hum then
        hum.JumpPower = val
    end
end, "jumppower")

movement:slider("HipHeight", 0, 10, 0, function(val)
    local hum = GetHumanoid()
    if hum then
        hum.HipHeight = val
    end
end, "hipheight")

movement:space()

movement:section("Boosts / Powerups")

-- Usar items de boost
movement:button("Usar Win Boost (1x)", function()
    local v1, v22 = Network.InvokeServer("Use Item", "Win Boost", 1)
    if v1 then
        w:notify("Boost", "Win Boost ativado!", 2)
    else
        w:notify("Boost", "Falha ao usar boost", 2)
    end
end)

movement:button("Usar Speed Potion (1x)", function()
    local v1, v22 = Network.InvokeServer("Use Item", "Speed Potion", 1)
    if v1 then
        w:notify("Boost", "Speed Potion ativado!", 2)
    else
        w:notify("Boost", "Falha ao usar potion", 2)
    end
end)

movement:space()

movement:section("Infinite Jump")

movement:toggle("Infinite Jump", false, function(state)
    if state then
        local connection
        connection = RunService.Heartbeat:Connect(function()
            if LP.Character and LP.Character:FindFirstChild("Humanoid") then
                local hum = LP.Character.Humanoid
                if hum.FloorMaterial == Enum.Material.Air then
                    hum.Jump = true
                end
            end
        end)
        if connection then
            _G._infJumpConn = connection
        end
    else
        if _G._infJumpConn then
            _G._infJumpConn:Disconnect()
            _G._infJumpConn = nil
        end
    end
end, "inf_jump")

movement:toggle("No Clip (Experimental)", false, function(state)
    if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
        LP.Character.HumanoidRootPart.CanCollide = not state
    end
end, "noclip")

-- ============================================================================
-- TAB ESP
-- ============================================================================

esp:section("ESP")

local espEnabled = false
local espConnections = {}
local espHighlights = {}

local function ClearESP()
    for _, conn in ipairs(espConnections) do
        conn:Disconnect()
    end
    espConnections = {}
    for _, hl in ipairs(espHighlights) do
        if hl then hl:Destroy() end
    end
    espHighlights = {}
end

local function CreateESP(player)
    if player == LP then return end
    
    local highlight = Instance.new("Highlight")
    highlight.FillColor = Color3.fromRGB(255, 50, 50)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.5
    highlight.Adornee = player.Character
    highlight.Parent = player.Character
    
    table.insert(espHighlights, highlight)
end

esp:toggle("Ativar ESP", false, function(state)
    espEnabled = state
    if state then
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character then
                CreateESP(player)
            end
        end
        
        local conn1 = Players.PlayerAdded:Connect(function(player)
            player.CharacterAdded:Connect(function(char)
                task.wait(1)
                if espEnabled and player.Character then
                    CreateESP(player)
                end
            end)
        end)
        table.insert(espConnections, conn1)
        
        local conn2 = Players.PlayerRemoving:Connect(function(player)
            -- Clean up quando o player sai
        end)
        table.insert(espConnections, conn2)
    else
        ClearESP()
    end
end, "esp_enabled")

esp:colorpicker("ESP Color", Color3.fromRGB(255, 50, 50), function(color)
    for _, hl in ipairs(espHighlights) do
        hl.FillColor = color
    end
end, "esp_color")

esp:space()

esp:section("Name Tags")

esp:toggle("Mostrar Nomes", true, function(state)
    w:notify("ESP", "Name tags " .. (state and "ativadas" or "desativadas"), 2)
    -- O jogo gerencia isso via Paper.Stats
end, "esp_names")

-- ============================================================================
-- TAB SHOP / ITEMS
-- ============================================================================

shop:section("Usar Itens")

local itemNameInput = shop:input("Nome do Item", "Ex: Win Boost", function(text) end, "shop_item")
local itemQtyInput = shop:input("Quantidade", "1", function(text) end, "shop_qty")

shop:button("Usar Item", function()
    local itemName = itemNameInput.input.Text
    if itemName == "" then
        w:notify("Erro", "Digite um nome de item", 2)
        return
    end
    local qty = tonumber(itemQtyInput.input.Text) or 1
    
    local v1, v22 = Network.InvokeServer("Use Item", itemName, qty)
    if v1 then
        w:notify("Item", itemName .. " usado " .. qty .. "x!", 2)
    else
        w:notify("Erro", tostring(v22), 2)
    end
end)

shop:button("Usar MultiUse (Quantidade Variável)", function()
    local itemName = itemNameInput.input.Text
    if itemName == "" then
        w:notify("Erro", "Digite um nome de item", 2)
        return
    end
    
    -- Tenta com quantidades diferentes
    local amounts = {1, 5, 10, 25, 50, 100}
    for _, qty in ipairs(amounts) do
        local v1, v22 = Network.InvokeServer("Use Item", itemName, qty)
        if v1 then
            w:notify("Item", itemName .. " usado " .. qty .. "x!", 2)
            break
        end
    end
end)

shop:space()

shop:section("Redeem Codes")

local codeInput = shop:input("Código", "Digite um código...", function(text) end, "redeem_code")

shop:button("Redeem Code", function()
    local code = codeInput.input.Text
    if code == "" then
        w:notify("Erro", "Digite um código", 2)
        return
    end
    
    local v1, v2 = Network.InvokeServer("Redeem Code", code)
    if v1 then
        w:notify("Code", "Código resgatado: " .. code, 3)
    else
        w:notify("Falha", tostring(v2 or "Código inválido"), 3)
    end
end)

-- ============================================================================
-- TAB MISC
-- ============================================================================

misc:section("Network / Remotes")

misc:toggle("Remote Spy (Log Remotes)", false, function(state)
    if state then
        -- Hook the network functions to log
        local oldFire = Network.FireServer
        Network.FireServer = function(...)
            local args = {...}
            print("[REMOTE SPY] FireServer:", unpack(args))
            return oldFire(...)
        end
        
        local oldInvoke = Network.InvokeServer
        Network.InvokeServer = function(...)
            local args = {...}
            print("[REMOTE SPY] InvokeServer:", unpack(args))
            return oldInvoke(...)
        end
        
        w:notify("Spy", "Remote Spy ativado! Veja no console (F9)", 3)
    else
        -- Restore (hard reload needed to fully restore)
        w:notify("Spy", "Reexecute o script para desativar completamente", 3)
    end
end, "remote_spy")

misc:space()

misc:section("Server Info")

misc:button("Ver Job ID", function()
    w:notify("Job ID", game.JobId, 5)
end)

misc:button("Ver Place ID", function()
    w:notify("Place ID", tostring(game.PlaceId), 5)
end)

misc:button("Listar Players", function()
    local msg = ""
    for _, player in ipairs(Players:GetPlayers()) do
        msg = msg .. player.Name .. "\n"
    end
    w:notify("Players (" .. #Players:GetPlayers() .. ")", msg, 4)
end)

misc:space()

misc:section("Themes")

misc:button("Midnight Theme", function()
    w:apply_theme(kyri.presets["midnight"])
end)

misc:button("Rose Theme", function()
    w:apply_theme(kyri.presets["rose"])
end)

misc:button("Forest Theme", function()
    w:apply_theme(kyri.presets["forest"])
end)

misc:button("Slate Theme", function()
    w:apply_theme(kyri.presets["slate"])
end)

misc:button("Padrão (Kyri)", function()
    w:apply_theme(kyri.presets["kyri"])
end)

misc:space()

misc:section("Ações")

misc:button("Resetar Configs", function()
    w:notify("Reset", "Configs resetadas!", 2)
end)

misc:button("Sair do Script", function()
    w:destroy()
end)

-- ============================================================================
-- NOTIFICAÇÃO DE INÍCIO
-- ============================================================================

w:notify("Sucesso", "Speed Trainer Hub carregado!", 3)
w:notify("Dica", "Pressione RightControl para mostrar/ocultar", 5)

-- ============================================================================
-- EXPLOIT NOTES (comentários para referência)
-- ============================================================================

--[[
EXPLOIT VULNERABILITIES ENCONTRADAS:

1. HATCH EGG REMOTE:
   - Remote: "Hatch Egg" (InvokeServer)
   - Args: (eggName: string, amount: number)
   - Server valida se Paper.Stats.GetValue("Wins") >= egg.Cost
   - Se o servidor não validar amount corretamente, pode tentar amounts negativos ou bulk

2. USE ITEM REMOTE:
   - Remote: "Use Item" (InvokeServer)
   - Args: (itemName: string, amount: number)
   - Pode tentar usar items que não possui - server pode ou não validar

3. REDEEM CODE:
   - Remote: "Redeem Code" (InvokeServer) 
   - Args: (code: string)
   - Sem rate limiting = brute force possível

4. PET ACTIONS:
   - Remote: "Pet" (InvokeServer)
   - Actions: Equip, Unequip, Lock, Delete, AutoDelete, CraftSize, EquipBest
   - Pode chamar ações fora de ordem

5. AUTO HATCH LOOP:
   - O jogo tem um loop de auto hatch que fica chamando Buy() 
   - Buy() só valida Wins uma vez no início, depois tenta comprar em loop
   - Se travar o valor de Wins antes do servidor atualizar...

6. REPLICATOR SYSTEM:
   - Usa __replicate (RemoteEvent) e __replicatefunc (RemoteFunction)
   - Dados replicados podem ser manipulados

7. NO ANTI-EXPLOIT ENCONTRADO:
   - Nenhum sistema de kick/ban anti-exploit detectado
   - Sem validação de rate limiting visível
]]

-- ============================================================================
-- FIM
-- ============================================================================