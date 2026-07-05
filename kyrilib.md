--[[
================================================================================
KYRILIB - DOCUMENTAÇÃO COMPLETA 100% - TODOS OS RECURSOS
================================================================================

INSTALAÇÃO:
local kyri = loadstring(game:HttpGet("https://kyrilib.dev/kyrilib/"))()

FEATURES COMPLETAS:
- 10+ elementos (button, toggle, slider, dropdown, multiselect, colorpicker, keybind, etc)
- Sistema de config automático com flags
- 5 temas presets + editor completo
- 1000+ ícones Lucide
- Suporte mobile
- Key system integrado
- Métodos programáticos (:set, :get, :setcallback)
- Toggle visibility com RightControl
- HTTPS URLs para icons com cache

================================================================================
]]

-- ============================================================================
-- INSTALAÇÃO E SETUP BÁSICO
-- ============================================================================

local kyri = loadstring(game:HttpGet("https://kyrilib.dev/kyrilib/"))()

-- Criar janela principal
local w = kyri.new("Meu Script Hub", {
    GameName = "MeuJogo",           -- Nome para salvar configs
    AutoLoad = "default",           -- Carregar config automaticamente
    -- Theme = {                     -- Opcional: override de cores
    --     accent = Color3.fromRGB(255, 110, 150)
    -- },
    -- KeySystem = "Once",           -- Opcional: "Once" ou "Everytime"
    -- KeySettings = {               -- Opcional: config do key system
    --     Title = "Meu Script",
    --     Subtitle = "Digite sua key",
    --     Note = "Pegue no Discord",
    --     Creator = "SeuNome",
    --     Key = {"KEY-123", "KEY-456"},
    --     FileName = "MeuScript"
    -- }
})

-- IMPORTANTE: Se usar KeySystem, sempre verifique se a janela foi criada
if not w then return end

-- ============================================================================
-- TOGGLE VISIBILITY
-- ============================================================================

--[[
Pressione RightControl para mostrar/ocultar a janela
Isso funciona automaticamente, não precisa configurar nada
]]

-- ============================================================================
-- CRIAR TABS (ABAS)
-- ============================================================================

-- Icons Lucide comuns: sword, crosshair, users, settings, home, star, heart, shield, etc
-- Lista completa: https://lucide.dev/icons

local main = w:tab("Principal", "home")
local combat = w:tab("Combate", "crosshair")
local player = w:tab("Jogador", "user")
local visual = w:tab("Visual", "eye")
local misc = w:tab("Misc", "settings")
local advanced = w:tab("Avançado", "terminal")

-- ============================================================================
-- TAB PRINCIPAL - ELEMENTOS BÁSICOS
-- ============================================================================

main:section("Bem-vindo")
main:paragraph("Sobre", "Este é um script de exemplo usando KyriLib. Todos os elementos estão demonstrados aqui.")
main:space(8)

-- BUTTON
main:section("Botões")
main:button("Clique Aqui", function()
    w:notify("Sucesso", "Botão clicado!", 2)
end)

main:button("Outro Botão", function()
    print("Botão 2 pressionado")
end)

main:space()

-- TOGGLE
main:section("Toggles")
local flyToggle = main:toggle("Ativar Fly", false, function(state)
    w:notify("Fly", state and "Ativado" or "Desativado", 2)
    -- Seu código de fly aqui
end, "fly_enabled")

main:toggle("God Mode", false, function(state)
    print("God Mode:", state)
end, "god_mode")

main:space()

-- SLIDER
main:section("Sliders")
local walkspeedSlider = main:slider("WalkSpeed", 16, 500, 16, function(val)
    if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = val
    end
end, "walkspeed")

main:slider("JumpPower", 50, 500, 50, function(val)
    if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
        game.Players.LocalPlayer.Character.Humanoid.JumpPower = val
    end
end, "jumppower")

-- Slider com decimais (step 0.1)
main:slider("FOV", 70, 120, 90, function(val)
    print("FOV:", val)
end, "fov", 0.1)

main:space()

-- INPUT
main:section("Input de Texto")
local nameInput = main:input("Nome do Jogador", "Digite aqui...", function(text)
    w:notify("Input", "Nome: " .. text, 2)
end, "player_name")

-- ACESSAR O TEXTBOX DO INPUT
-- nameInput.input é a instância do TextBox
-- Você pode manipular diretamente se precisar

main:space()

-- DROPDOWN
main:section("Dropdown")
local gameModeDropdown = main:dropdown("Modo de Jogo", {"Normal", "Hardcore", "Survival", "Creative"}, "Normal", function(val)
    w:notify("Modo", "Selecionado: " .. val, 2)
end, "game_mode")

main:dropdown("Teleport", {"Spawn", "Prisão", "Base Criminal", "Ilha Secreta"}, "Spawn", function(val)
    w:notify("Teleport", "Indo para: " .. val, 2)
end, "teleport_location")

main:space()

-- MULTISELECT
main:section("Multiselect")
local weaponsMultiselect = main:multiselect("Armas", {"Pistola", "Rifle", "Shotgun", "Sniper", "Faca"}, {"Pistola"}, function(selected)
    print("Armas selecionadas:", table.concat(selected, ", "))
end, "weapons")

-- ============================================================================
-- TAB COMBATE - AIMBOT E ESP
-- ============================================================================

combat:section("Aimbot")

combat:toggle("Ativar Aimbot", false, function(state)
    print("Aimbot:", state)
end, "aimbot_enabled")

combat:keybind("Tecla Aimbot", "X", false, function()
    print("Aimbot ativado por tecla!")
end, "aimbot_key")

combat:keybind("Tecla Fly", "Q", false, function()
    print("Fly ativado por tecla!")
end, "fly_key")

-- Keybind com hold (segurar)
combat:keybind("Speed Boost", "LeftShift", true, function(holding)
    if holding then
        print("Segurando Shift - Speed Boost ativo")
    else
        print("Soltou Shift - Speed Boost desativado")
    end
end, "boost_key")

combat:slider("Aimbot FOV", 1, 360, 120, function(val)
    print("FOV:", val)
end, "aimbot_fov")

combat:slider("Smoothness", 0, 100, 50, function(val)
    print("Smoothness:", val)
end, "aimbot_smooth", 0.1)

combat:dropdown("Target Part", {"Head", "Torso", "HumanoidRootPart"}, "Head", function(val)
    print("Target:", val)
end, "aimbot_part")

combat:dropdown("Priority", {"Closest", "Lowest Health", "Nearest to Crosshair"}, "Closest", function(val)
    print("Priority:", val)
end, "aimbot_priority")

combat:space()

combat:section("ESP")

combat:toggle("Ativar ESP", false, function(state)
    print("ESP:", state)
end, "esp_enabled")

combat:toggle("Show Names", true, function(state)
    print("Show Names:", state)
end, "esp_names")

combat:toggle("Show Health", true, function(state)
    print("Show Health:", state)
end, "esp_health")

combat:toggle("Show Distance", false, function(state)
    print("Show Distance:", state)
end, "esp_distance")

combat:colorpicker("ESP Color", Color3.fromRGB(255, 0, 0), function(color)
    print("ESP Color:", color)
end, "esp_color")

combat:colorpicker("Enemy Color", Color3.fromRGB(255, 255, 0), function(color)
    print("Enemy Color:", color)
end, "enemy_color")

-- ============================================================================
-- TAB JOGADOR - MOVIMENTO E STATS
-- ============================================================================

player:section("Movimento")

player:toggle("Infinite Jump", false, function(state)
    print("Infinite Jump:", state)
end, "inf_jump")

player:toggle("No Fall Damage", false, function(state)
    print("No Fall Damage:", state)
end, "no_fall")

player:slider("WalkSpeed", 16, 500, 16, function(val)
    if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = val
    end
end, "player_walkspeed")

player:slider("JumpPower", 50, 500, 50, function(val)
    if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
        game.Players.LocalPlayer.Character.Humanoid.JumpPower = val
    end
end, "player_jumppower")

player:space()

player:section("Teleport")

player:button("Teleport to Spawn", function()
    w:notify("Teleport", "Indo para Spawn...", 2)
end)

player:button("Teleport to Player", function()
    w:notify("Teleport", "Selecione um jogador", 2)
end)

-- ============================================================================
-- TAB VISUAL - TEMAS E CORES
-- ============================================================================

visual:section("Temas Preset")

visual:button("Midnight", function()
    w:apply_theme(kyri.presets["midnight"])
    w:notify("Tema", "Midnight aplicado!", 2)
end)

visual:button("Rose", function()
    w:apply_theme(kyri.presets["rose"])
    w:notify("Tema", "Rose aplicado!", 2)
end)

visual:button("Forest", function()
    w:apply_theme(kyri.presets["forest"])
    w:notify("Tema", "Forest aplicado!", 2)
end)

visual:button("Slate", function()
    w:apply_theme(kyri.presets["slate"])
    w:notify("Tema", "Slate aplicado!", 2)
end)

visual:button("Padrão (Kyri)", function()
    w:apply_theme(kyri.presets["kyri"])
    w:notify("Tema", "Tema padrão aplicado!", 2)
end)

visual:space()

visual:section("Customização")

visual:colorpicker("Cor de Destaque", kyri.theme.accent, function(c)
    w:accent(c)
end, "accent_color")

visual:slider("Transparência", 0, 100, 100, function(val)
    -- Ajustar transparência da janela
end, "window_transparency")

visual:space()

visual:section("Notificações de Teste")

visual:button("Notificação Curta", function()
    w:notify("Teste", "Esta é uma notificação curta", 2)
end)

visual:button("Notificação Longa", function()
    w:notify("Teste", "Esta é uma notificação mais longa que fica visível por 5 segundos", 5)
end)

-- ============================================================================
-- TAB MISC - PROGRESS BAR E IMAGENS
-- ============================================================================

misc:section("Progress Bar")

local progressBar = misc:progressbar("Carregando...", 100)

misc:button("Iniciar Carregamento", function()
    task.spawn(function()
        for i = 0, 100, 10 do
            progressBar:set(i, true)
            task.wait(0.2)
        end
        w:notify("Concluído", "Carregamento finalizado!", 3)
    end)
end)

misc:space()

misc:section("Imagens")

misc:image("rbxassetid://7734053495", 120)

misc:space()

misc:section("Informações")

misc:label("Versão: 1.0.0")
misc:label("Criador: SeuNome")
misc:label("Discord: discord.gg/seuservidor")

misc:space()

misc:section("Ações")

misc:button("Resetar Configs", function()
    w:notify("Reset", "Configs resetadas!", 2)
end)

misc:button("Sair do Script", function()
    w:destroy()
end)

-- ============================================================================
-- TAB AVANÇADO - MÉTODOS PROGRAMÁTICOS
-- ============================================================================

advanced:section("Manipulação de Toggles")

advanced:button("Ativar Fly Programaticamente", function()
    -- Usar :set() para mudar o valor
    flyToggle:set(true)
    
    -- Ler o valor atual com :get()
    local currentState = flyToggle:get()
    w:notify("Toggle", "Fly está: " .. tostring(currentState), 2)
end)

advanced:button("Desativar Fly Programaticamente", function()
    flyToggle:set(false)
    w:notify("Toggle", "Fly desativado!", 2)
end)

advanced:button("Mudar Callback do Fly", function()
    -- Usar :setcallback() para mudar a função
    flyToggle:setcallback(function(state)
        w:notify("Novo Callback", "Fly mudou para: " .. tostring(state), 2)
        print("Novo callback executado!")
    end)
    w:notify("Callback", "Callback do Fly foi mudado!", 2)
end)

advanced:space()

advanced:section("Manipulação de Sliders")

advanced:button("Set WalkSpeed para 100", function()
    -- Usar :set() para mudar o valor
    walkspeedSlider:set(100)
    
    -- Ler o valor atual com :get()
    local currentVal = walkspeedSlider:get()
    w:notify("Slider", "WalkSpeed: " .. currentVal, 2)
end)

advanced:button("Set WalkSpeed para 200", function()
    walkspeedSlider:set(200)
    w:notify("Slider", "WalkSpeed setado para 200!", 2)
end)

advanced:button("Mudar Callback do WalkSpeed", function()
    walkspeedSlider:setcallback(function(val)
        w:notify("Novo Callback", "WalkSpeed: " .. val, 2)
        print("Novo callback do slider!")
    end)
    w:notify("Callback", "Callback do WalkSpeed foi mudado!", 2)
end)

advanced:space()

advanced:section("Manipulação de Dropdowns")

advanced:button("Set Modo para Hardcore", function()
    -- Usar :set() para mudar o valor
    gameModeDropdown:set("Hardcore")
    w:notify("Dropdown", "Modo setado para Hardcore!", 2)
end)

advanced:button("Set Modo para Creative", function()
    gameModeDropdown:set("Creative")
    w:notify("Dropdown", "Modo setado para Creative!", 2)
end)

advanced:space()

advanced:section("Manipulação de Multiselect")

advanced:button("Selecionar Todas as Armas", function()
    -- Usar :set() com uma tabela
    weaponsMultiselect:set({"Pistola", "Rifle", "Shotgun", "Sniper", "Faca"})
    w:notify("Multiselect", "Todas as armas selecionadas!", 2)
end)

advanced:button("Selecionar Apenas Pistola e Rifle", function()
    weaponsMultiselect:set({"Pistola", "Rifle"})
    w:notify("Multiselect", "Pistola e Rifle selecionadas!", 2)
end)

advanced:space()

advanced:section("Manipulação de Input")

advanced:button("Ler Texto do Input", function()
    -- Acessar a propriedade .input para pegar o TextBox
    local textBox = nameInput.input
    local text = textBox.Text
    w:notify("Input", "Texto: " .. text, 3)
end)

advanced:button("Setar Texto no Input", function()
    -- Manipular diretamente o TextBox
    local textBox = nameInput.input
    textBox.Text = "NovoNome123"
    w:notify("Input", "Texto setado!", 2)
end)

advanced:space()

advanced:section("Manipulação de Color Picker")

-- Criar um color picker para demonstração
local testColorPicker = advanced:colorpicker("Cor de Teste", Color3.fromRGB(0, 255, 0), function(color)
    print("Cor mudou para:", color)
end, "test_color")

advanced:button("Set Cor para Vermelho", function()
    -- Usar :set() para mudar a cor
    testColorPicker:set(Color3.fromRGB(255, 0, 0))
    w:notify("ColorPicker", "Cor setada para vermelho!", 2)
end)

advanced:button("Set Cor para Azul", function()
    testColorPicker:set(Color3.fromRGB(0, 0, 255))
    w:notify("ColorPicker", "Cor setada para azul!", 2)
end)

advanced:button("Ler Cor Atual", function()
    -- Usar :get() para ler a cor
    local currentColor = testColorPicker:get()
    w:notify("ColorPicker", "R: " .. math.floor(currentColor.R * 255) .. 
             " G: " .. math.floor(currentColor.G * 255) .. 
             " B: " .. math.floor(currentColor.B * 255), 3)
end)

-- ============================================================================
-- EXEMPLOS DE USO DO CONFIG SYSTEM
-- ============================================================================

--[[
O sistema de config funciona automaticamente quando você usa flags.

Para ler um valor:
local speed = w.flags.walkspeed

Para definir um valor e disparar o callback:
w.flags.walkspeed_set(100, true)

Configs são salvas automaticamente no arquivo especificado em GameName.
Color3 values serializam corretamente.
]]

-- Exemplo prático de leitura de config
advanced:section("Config System")

advanced:button("Ler WalkSpeed do Config", function()
    local speed = w.flags.walkspeed
    w:notify("Config", "WalkSpeed salvo: " .. tostring(speed), 2)
end)

advanced:button("Set WalkSpeed via Config", function()
    -- Setar valor e disparar callback (segundo argumento = true)
    w.flags.walkspeed_set(150, true)
    w:notify("Config", "WalkSpeed setado para 150!", 2)
end)

advanced:button("Set WalkSpeed SEM disparar callback", function()
    -- Setar valor SEM disparar callback (segundo argumento = false)
    w.flags.walkspeed_set(250, false)
    w:notify("Config", "WalkSpeed setado para 250 (sem callback)!", 2)
end)

-- ============================================================================
-- EXEMPLOS DE KEY SYSTEM
-- ============================================================================

--[[
Para usar o key system, adicione estas opções ao criar a janela:

local w = kyri.new("Meu Script", {
    GameName = "MeuJogo",
    KeySystem = "Once",  -- ou "Everytime"
    KeySettings = {
        Title = "Meu Script",
        Subtitle = "Digite sua key para continuar",
        Note = "Pegue uma key no Discord",
        Creator = "SeuNome",
        Key = {"KEY-123", "KEY-456", "KEY-789"},
        FileName = "MeuScript"
    }
})

if not w then return end  -- Usuário fechou sem key válida

Modos:
- "Once": Salva a key, não pede de novo (a menos que você mude as keys)
- "Everytime": Sempre pede a key

Key Expiry:
No modo "Once", a key salva é validada contra sua lista Key atual em toda execução.
Mudar ou remover uma key no seu script invalida imediatamente quaisquer cópias salvas.
]]

-- ============================================================================
-- EXEMPLOS DE TEMAS
-- ============================================================================

--[[
Temas presets disponíveis:
- kyri (padrão)
- midnight
- rose
- forest
- slate

Aplicar preset:
w:apply_theme(kyri.presets["midnight"])

Override parcial:
w:apply_theme({
    accent = Color3.fromRGB(255, 80, 80),
    bg = Color3.fromRGB(10, 10, 15)
})

Theme keys disponíveis:
- bg: fundo principal
- container: header, sidebar
- element: botões, inputs
- hover: cor de hover
- active: cor ativa
- accent: destaques
- text: texto primário
- subtext: texto secundário
- border: bordas

Settings Tab:
A aba Settings é criada automaticamente com:
- Dropdown de presets
- Color pickers individuais para cada propriedade do tema
]]

-- ============================================================================
-- EXEMPLOS DE ICONES LUCIDE
-- ============================================================================

--[[
1000+ ícones disponíveis. Use o nome exato de https://lucide.dev/icons

Exemplos comuns:
- sword, axe, skull, flame, shield
- crosshair, target, eye, ghost
- users, user, user-plus, crown
- star, heart, bolt, zap
- settings, sliders, wrench
- key, lock, unlock
- map-pin, compass, navigation
- home, search, filter
- list, grid, layout-dashboard
- music, volume-2, mic
- wifi, bluetooth
- monitor, smartphone, camera
- video, image, file, folder
- download, upload, save, trash
- edit, copy, share, send
- mail, bell, clock, calendar
- info, alert-triangle, check, x
- plus, minus, arrow-right
- chevron-down
- terminal, bot, gamepad, gamepad-2

Uso com nomes Lucide:
w:tab("Nome", "icon-name")
w:tab("Custom", "rbxassetid://123456")

HTTPS URLs:
Quando você passa uma URL https://, KyriLib baixa a imagem em background usando
a função request() do executor, faz cache no disco via getcustomasset(), e carrega.
O ícone aparece quando o download terminar.

Requer executor com suporte a request() e getcustomasset() (Wave, Volt, Madium, etc).

Exemplo:
w:tab("Web", "https://example.com/icon.png")

Outros formatos suportados:
- rbxassetid://7734053495 (Roblox asset ID)
- rbxthumb://type=Asset&id=123&w=150&h=150 (Roblox thumbnail)
]]

-- ============================================================================
-- NOTIFICAÇÃO FINAL
-- ============================================================================

w:notify("Sucesso", "Script carregado completamente!", 3)
w:notify("Dica", "Pressione RightControl para mostrar/ocultar", 5)

-- ============================================================================
-- FIM DO SCRIPT
-- ============================================================================

--[[
RECURSOS:
- Documentação: https://justanewplayer19.github.io/KyriLib
- GitHub: https://github.com/Justanewplayer19/KyriLib
- Lucide Icons: https://lucide.dev/icons

DICAS PARA IA:
1. Sempre use strings únicas para flags
2. Callbacks recebem o valor atual (boolean, number, string, table, Color3)
3. Use nomes Lucide exatos como aparecem no site
4. Sempre verifique if not w then return end quando usar KeySystem
5. Configs são salvas automaticamente quando flags são usadas
6. Métodos disponíveis: :set(), :get(), :setcallback() para Toggle, Slider, Dropdown, Multiselect, ColorPicker
7. Input tem propriedade .input que é o TextBox
8. Pressione RightControl para toggle visibility
9. HTTPS URLs para icons requerem executor com request() e getcustomasset()
10. Use task.spawn() para loops longos (como progress bar) para não travar a UI

API RESUMO:
- kyri.new(title, options) → window
- w:tab(name, icon) → tab
- w:notify(title, text, duration)
- w:accent(color)
- w:apply_theme(overrides)
- w:destroy()
- tab:button(text, callback)
- tab:toggle(text, default, callback, flag) → toggle object
- tab:slider(text, min, max, default, callback, flag, step) → slider object
- tab:input(text, placeholder, callback, flag) → input object (com .input property)
- tab:dropdown(text, options, default, callback, flag) → dropdown object
- tab:multiselect(text, options, default, callback, flag) → multiselect object
- tab:colorpicker(text, default, callback, flag) → colorpicker object
- tab:keybind(text, default, hold_to_interact, callback, flag)
- tab:progressbar(text, max) → progressbar object
- tab:image(asset_id, height)
- tab:section(text)
- tab:label(text)
- tab:paragraph(title, body)
- tab:space(height)

MÉTODOS DE OBJETOS:
- toggle:set(state), toggle:get(), toggle:setcallback(fn)
- slider:set(val), slider:get(), slider:setcallback(fn)
- dropdown:set(val)
- multiselect:set(table)
- colorpicker:set(color), colorpicker:get()
- progressbar:set(value, animated)

CONFIG SYSTEM:
- w.flags.flagname → ler valor
- w.flags.flagname_set(value, fireCallback) → setar valor
]]