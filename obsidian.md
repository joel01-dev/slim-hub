---
name: obsidianui
description: Biblioteca de UI avançada para Roblox, com sistema de temas, salvamento de configs e muitos elementos personalizáveis.
---

-- ═══════════════════════════════════════════════════════════════════════════════
## -- OBSIDIAN UI LIBRARY - COMPLETE REFERENCE
-- ═══════════════════════════════════════════════════════════════════════════════

-- ╔══════════════════════════════════════════════════════════════════════════════╗
## -- ║                     1. INSTALAÇÃO                                          ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

local Repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"

local Library = loadstring(game:HttpGet(Repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(Repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(Repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles
local Labels  = Library.Labels
local Buttons = Library.Buttons

-- ╔══════════════════════════════════════════════════════════════════════════════╗
## -- ║  2. JANELA (WINDOW)                                                        ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

## -- ─── 2.1 CREATEWINDOW - TODAS AS OPÇÕES ────────────────────────────────────────

local Window = Library:CreateWindow({
    -- Obrigatórios:
    Title = "My Hub",                    -- Título da janela
    Footer = "Version 1.0",              -- Texto do rodapé

    -- Ícone:
    Icon = "home",                       -- Icon name (lucide) ou ID numérico
    IconSize = UDim2.fromOffset(20,20),  -- Tamanho do ícone

    -- Imagem de fundo:
    BackgroundImage = "",                -- rbxassetid://

    -- Comportamento inicial:
    AutoShow = true,                     -- Mostrar automaticamente ao criar
    Center = true,                       -- Centralizar na tela
    Resizable = true,                    -- Permitir redimensionar
    Position = UDim2.fromScale(.5,.5),   -- Posição inicial
    Size = UDim2.fromOffset(750,600),    -- Tamanho inicial

    -- Busca:
    DisableSearch = false,               -- Desabilitar barra de busca
    SearchbarSize = UDim2.fromOffset(220,30), -- Tamanho da barra de busca
    GlobalSearch = true,                 -- Busca global entre abas

    -- Aparência:
    CornerRadius = 12,                   -- Raio das bordas arredondadas
    NotifySide = "Right",                -- Lado das notificações (Left/Right)
    ShowCustomCursor = true,             -- Usar cursor customizado
    Font = Enum.Font.GothamMedium,       -- Fonte padrão
    ToggleKeybind = Enum.KeyCode.RightShift, -- Tecla para mostrar/esconder

    -- Mobile:
    MobileButtonsSide = "Left",          -- Botões mobile (Left/Right)
    ShowMobileButtons = true,            -- Mostrar botões em mobile
    UnlockMouseWhileOpen = false,        -- Destravar mouse com UI aberta

    -- Sidebar:
    EnableSidebarResize = true,          -- Permitir redimensionar sidebar
    EnableCompacting = true,             -- Permitir compactar sidebar
    DisableCompactingSnap = false,       -- Desabilitar snap da compactação
    SidebarCompacted = false,            -- Sidebar começa compactada?
    MinContainerWidth = 350,             -- Largura mínima do container
    MinSidebarWidth = 180,               -- Largura mínima da sidebar
    SidebarCompactWidth = 60,            -- Largura quando compactada
    CompactWidthActivation = 700,        -- Largura para ativar compactação automática
})

## -- ─── 2.2 WINDOW METHODS ────────────────────────────────────────────────────────

Window:ChangeTitle("New Title")              -- Mudar título
Window:SetFooter("New Footer")               -- Mudar rodapé
Window:SetSidebarWidth(250)                  -- Definir largura da sidebar
Window:SetCornerRadius(10)                   -- Definir raio das bordas
Window:Toggle()                              -- Alternar visibilidade
Window:SetCompact(true)                      -- Compactar sidebar (icon-only)
Window:SetCompact(false)                     -- Restaurar sidebar expandida
Window:SetBackgroundImage("rbxassetid://123")-- Mudar imagem de fundo

## -- ─── 2.3 CONFIGURAÇÕES GLOBAIS ────────────────────────────────────────────────

Library.ForceCheckbox = false                -- AddToggle vira checkbox visual?
Library.ShowToggleFrameInKeybinds = true     -- Mostrar checkbox dos toggles no menu de keybinds
Library.NotifyOnError = false                -- Mostrar notificação em erros?

-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  3. TABS                                                                   ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

## -- ─── 3.1 CRIAR TABS ────────────────────────────────────────────────────────────

-- Formato simples:
local MainTab = Window:AddTab("Main", "home")

-- Formato completo:
local MainTab = Window:AddTab({
    Name = "Main",
    Icon = "home",
    Description = "Main Features"
})

## -- ─── 3.2 KEY SYSTEM TAB ────────────────────────────────────────────────────────

local KeyTab = Window:AddKeyTab("Key System")
-- ou
local KeyTab = Window:AddKeyTab({
    Name = "Key System",
    Icon = "key"
})

-- KeyBox (recebe apenas o texto digitado como parâmetro):
KeyTab:AddKeyBox(function(InputText)
    local Success = InputText == "MY_KEY"
    if Success then
        print("Chave válida!")
    end
end)

## -- ─── 3.3 TAB METHODS ───────────────────────────────────────────────────────────

Tab:SetVisible(true/false)                   -- Mostrar/esconder tab
Tab:UpdateWarningBox({                       -- Atualizar warning box
    Title = "Warning",
    Text = "Example",
    IsNormal = false,
    Visible = true,
    LockSize = true,
})

-- ╔══════════════════════════════════════════════════════════════════════════════╗
 ## -- ║  4.  GROUPBOXES                                                             ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

-- Left:
local MainGroup = MainTab:AddLeftGroupbox("Main Features", "wrench")
-- Right:
local MiscGroup = MainTab:AddRightGroupbox("Misc", "settings")
-- Genérico (com Side):
local Groupbox = MainTab:AddGroupbox({
    Side = 1,          -- 1 = Left, 2 = Right
    Name = "Features",
    IconName = "home"
})

-- ╔══════════════════════════════════════════════════════════════════════════════╗
## -- ║  5. ELEMENTOS DE UI                                                        ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  ❌❌❌ MÉTODOS QUE NÃO EXISTEM NO OBSIDIAN UI ❌❌❌                          ║
-- ║                                                                              ║
-- ║  ⚠️  NÃO USE: AddParagraph  →  Use AddLabel com DoesWrap = true               ║
-- ║  ⚠️  NÃO USE: AddTextbox   →  Use AddInput                                    ║
-- ║  ⚠️  NÃO USE: AddList      →  Use AddDropdown                                 ║
-- ║  ⚠️  NÃO USE: AddSwitch    →  Use AddToggle                                   ║
-- ║  ⚠️  NÃO USE: AddKeybind   →  Use AddKeyPicker                                ║
-- ║  ⚠️  NÃO USE: AddColourPicker → Use AddColorPicker                            ║
-- ║                                                                              ║
-- ║  ⚠️  REGRA IMPORTANTE: AddColorPicker NÃO funciona diretamente no Groupbox!   ║
-- ║  ⚠️  AddColorPicker SÓ pode ser chamado encadeado em:                        ║
-- ║        • Toggle:  Groupbox:AddToggle(...):AddColorPicker(...)                 ║
-- ║        • Label:   Groupbox:AddLabel(...):AddColorPicker(...)                  ║
-- ║  ⚠️  ERRADO:  Groupbox:AddColorPicker(...)  →  "attempt to call missing method" ║
-- ║  ⚠️  CORRETO: local Toggle = Groupbox:AddToggle(...)                         ║
-- ║  ⚠️           Toggle:AddColorPicker(...)                                      ║
-- ║                                                                              ║
-- ║  ⚠️  REGRA IMPORTANTE: AddKeyPicker NÃO funciona diretamente no Groupbox!    ║
-- ║  ⚠️  AddKeyPicker NÃO funciona encadeado em Label!                           ║
-- ║  ⚠️  AddKeyPicker SÓ funciona encadeado em Toggle!                           ║
-- ║  ⚠️  ERRADO:  Groupbox:AddKeyPicker(...)  →  "attempt to call missing method"  ║
-- ║  ⚠️  ERRADO:  Groupbox:AddLabel(...):AddKeyPicker(...)  →  "attempt to call     ║
-- ║  ⚠️             missing method 'SetValue' of table"                           ║
-- ║  ⚠️  CORRETO: local KeyToggle = Groupbox:AddToggle("KeyToggle",              ║
-- ║  ⚠️           { Text = "Keybind", Default = false })                          ║
-- ║  ⚠️           KeyToggle:AddKeyPicker("MenuKeybind", { ... })                  ║
-- ║                                                                              ║
-- ║  QUALQUER TENTATIVA DE USAR QUALQUER UM DESSES MÉTODOS                       ║
-- ║  RESULTARÁ EM ERRO "attempt to call missing method"                          ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  ✅ ÍCONES EM STRING - TOTALMENTE VÁLIDOS                                  ║
-- ║                                                                              ║
-- ║  A Library possui a função Library:GetCustomIcon() que carrega o módulo      ║
-- ║  Lucide. Strings como "home", "settings", "user", "train", etc. são         ║
-- ║  totalmente válidas e funcionam normalmente nos parâmetros Icon.             ║
-- ║                                                                              ║
-- ║  O próprio Example.lua oficial usa:                                          ║
-- ║    Window:AddTab("Main", "user")                                             ║
-- ║    Window:AddTab("UI Settings", "settings")                                  ║
-- ║                                                                              ║
-- ║  Você pode usar AMBOS os formatos:                                           ║
-- ║    • String de nome do ícone Lucide (ex: "home", "user", "settings")         ║
-- ║    • ID numérico de asset (ex: 95816097006870)                               ║
-- ║                                                                              ║
-- ║  ⚠️ ÚNICO CASO DE ERRO: Se o nome da string não existir no módulo Lucide    ║
-- ║  ou se o módulo falhar ao carregar, o erro será:                             ║
-- ║  "attempt to index nil with 'Url'"                                           ║
-- ║                                                                              ║
-- ║  ✅ EXEMPLOS VÁLIDOS:                                                       ║
-- ║    local Window = Library:CreateWindow({ Icon = "home", ... })               ║
-- ║    local Tab = Window:AddTab("Main", "user")                                 ║
-- ║    local Group = Tab:AddLeftGroupbox("Menu", "settings")                     ║
-- ║    Library:Notify({ Title = "OK", Description = "feito", Time = 3 })         ║
-- ║                                                                              ║
-- ║    -- Alternativamente, use ID numérico:                                     ║
-- ║    local Window = Library:CreateWindow({ Icon = 95816097006870, ... })       ║
-- ║                                                                              ║
-- ║  Referência de ícones: https://lucide.dev/                                   ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  📌 BOA PRÁTICA: ACESSAR LABELS                                            ║
-- ║                                                                              ║
-- ║  A Library.Labels funciona corretamente quando o label é criado com Idx.     ║
-- ║  Se você criou: Groupbox:AddLabel({ Text = "Status", Idx = "StatusLabel" })  ║
-- ║  Então: Library.Labels.StatusLabel:SetText("novo texto") funciona normal.    ║
-- ║                                                                              ║
-- ║  PORÉM, como BOA PRÁTICA, é recomendado capturar o retorno de AddLabel()     ║
-- ║  em uma variável local. Isso é mais direto e evita digitar o Idx errado.     ║
-- ║                                                                              ║
-- ║  ✅ FORMA COM Library.Labels (funciona se Idx foi definido):                ║
-- ║    Groupbox:AddLabel({ Text = "Status", Idx = "StatusLabel" })               ║
-- ║    Library.Labels.StatusLabel:SetText("novo texto")  -- OK!                  ║
-- ║                                                                              ║
-- ║  ✅ FORMA RECOMENDADA (capturar retorno em variável local):                 ║
-- ║    local StatusLabel = Groupbox:AddLabel({                                   ║
-- ║        Text = "Status",                                                      ║
-- ║        DoesWrap = true,                                                      ║
-- ║        Size = 14,                                                            ║
-- ║    })                                                                        ║
-- ║    StatusLabel:SetText("novo texto")  -- Referência direta                  ║
-- ║                                                                              ║
-- ║  ⚠️ CUIDADO: Se esquecer de passar o Idx ao criar o label, Library.Labels   ║
-- ║  não terá a chave, e acessá-la resultará em nil.                            ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

## -- ─── 5.1 LABELS (AddLabel) ─────────────────────────────────────────────────────

-- Básico:
local Label = Groupbox:AddLabel({
    Text = "Hello",
    DoesWrap = true,        -- Quebrar texto? (padrão: false)
    Size = 14,              -- Tamanho da fonte
    Visible = true,         -- Visível?
    Idx = "StatusLabel"     -- Index para acessar via Library.Labels
})

-- Methods:
Label:SetText("Running")    -- Mudar texto
Label:SetVisible(true)      -- Mostrar/esconder

## -- ─── 5.2 BUTTONS (AddButton) ───────────────────────────────────────────────────

-- Básico:
Groupbox:AddButton({ Text = "Execute", Func = function() end })

-- Completo:
Groupbox:AddButton({
    Text = "Execute",
    Func = function() end,
    DoubleClick = false,         -- Dois cliques para ativar
    Tooltip = "Tooltip",
    DisabledTooltip = "Disabled",
    Risky = false,               -- Texto em vermelho
    Disabled = false,
    Visible = true
})

-- Sub Button:
local Button = Groupbox:AddButton({ Text = "Main" })
Button:AddButton({ Text = "Sub", Func = function() end })

-- Methods:
Button:SetText("New Text")      -- Mudar texto
Button:SetVisible(true)         -- Mostrar/esconder
Button:SetDisabled(false)       -- Ativar/desativar

## -- ─── 5.3 TOGGLES (AddToggle) ───────────────────────────────────────────────────

-- Básico:
Groupbox:AddToggle("AutoFarm", {
    Text = "Auto Farm",
    Default = false,
})

-- Completo:
Groupbox:AddToggle("AutoFarm", {
    Text = "Auto Farm",
    Default = false,             -- Valor inicial
    Tooltip = "Enable autofarm",
    DisabledTooltip = "Disabled",
    Risky = false,
    Disabled = false,
    Visible = true,
    Callback = function(Value) end
})

-- Methods:
Toggles.AutoFarm:SetValue(true)         -- Mudar valor
Toggles.AutoFarm:SetText("Farm")        -- Mudar texto
Toggles.AutoFarm:SetVisible(true)       -- Mostrar/esconder
Toggles.AutoFarm:SetDisabled(false)     -- Ativar/desativar

-- Events (recomendado usar separado dos elementos):
Toggles.AutoFarm:OnChanged(function(Value) end)

## -- ─── 5.4 CHECKBOXES (AddCheckbox) ──────────────────────────────────────────────

-- Para forçar AddToggle a usar checkbox visual:
Library.ForceCheckbox = true

Groupbox:AddCheckbox("KillAura", {
    Text = "Kill Aura",
    Tooltip = "...",
    DisabledTooltip = "...",
    Default = false,
    Disabled = false,
    Visible = true,
    Risky = false,
    Callback = function(Value) end
})

-- Aceita os mesmos métodos/eventos de Toggle.

## -- ─── 5.5 INPUTS (AddInput) ─────────────────────────────────────────────────────

-- Básico:
Groupbox:AddInput("PlayerName", {
    Text = "Player",
    Placeholder = "Name"
})

-- Completo:
Groupbox:AddInput("PlayerName", {
    Text = "Player",
    Default = "",
    Placeholder = "Enter Name",
    Finished = true,             -- Só dispara callback ao pressionar Enter
    Numeric = false,             -- Apenas números?
    ClearTextOnFocus = false,    -- Limpar ao focar?
    ClearTextOnBlur = false,     -- Limpar ao perder foco?
    AllowEmpty = true,           -- Permitir valor vazio?
    EmptyReset = "",             -- Valor ao ficar vazio
    MaxLength = 100,             -- Máximo de caracteres
    Tooltip = "",
    DisabledTooltip = "",
    Disabled = false,
    Visible = true,
    Callback = function(Value) end
})

-- Methods:
Options.PlayerName:SetValue("Test")         -- Mudar valor
Options.PlayerName:SetText("Username")      -- Mudar label
Options.PlayerName:SetVisible(true)
Options.PlayerName:SetDisabled(false)

-- Events:
Options.PlayerName:OnChanged(function(Value) end)

## -- ─── 5.6 SLIDERS (AddSlider) ───────────────────────────────────────────────────

-- Básico:
Groupbox:AddSlider("WalkSpeed", {
    Text = "WalkSpeed",
    Default = 16,
    Min = 16,
    Max = 200,
    Rounding = 0,                -- Casas decimais
})

-- Completo:
Groupbox:AddSlider("WalkSpeed", {
    Text = "WalkSpeed",
    Default = 16,
    Min = 16,
    Max = 200,
    Rounding = 0,                -- Casas decimais
    Prefix = "$",                -- Texto antes do valor
    Suffix = "studs/s",          -- Texto depois do valor
    Compact = false,             -- Esconder label do título
    HideMax = false,             -- Esconder valor máximo
    FormatDisplayValue = function(Slider, Value)
        if Value == Slider.Max then return "Max" end
        return tostring(Value)
    end,
    Tooltip = "",
    DisabledTooltip = "",
    Disabled = false,
    Visible = true,
    Callback = function(Value) end
})

-- Methods:
Options.WalkSpeed:SetValue(100)            -- Mudar valor
Options.WalkSpeed:SetMin(0)                -- Mudar mínimo
Options.WalkSpeed:SetMax(500)              -- Mudar máximo
Options.WalkSpeed:SetPrefix("$")           -- Mudar prefixo
Options.WalkSpeed:SetSuffix("%")           -- Mudar sufixo
Options.WalkSpeed:SetText("Speed")         -- Mudar label
Options.WalkSpeed:SetDisabled(false)
Options.WalkSpeed:SetVisible(true)

-- Events:
Options.WalkSpeed:OnChanged(function(Value) end)

## -- ─── 5.7 DROPDOWNS (AddDropdown) ───────────────────────────────────────────────

-- Single Select:
Groupbox:AddDropdown("Weapon", {
    Text = "Weapon",
    Values = { "Sword", "Gun", "Bow" },
    Default = 1                  -- Índice numérico ou string
})

-- Multi Select:
Groupbox:AddDropdown("Targets", {
    Text = "Targets",
    Multi = true,
    Values = { "Player", "NPC", "Boss" }
})

-- Completo:
Groupbox:AddDropdown("Target", {
    Text = "Target",
    Values = {},
    Default = nil,
    DisabledValues = {},             -- Valores desabilitados
    Multi = false,
    Searchable = true,               -- Campo de busca
    MaxVisibleDropdownItems = 12,    -- Itens visíveis (padrão: 8)
    AllowNull = true,                -- Permitir nenhum selecionado
    SpecialType = "Player",          -- "Player" ou "Team" (auto-preenche)
    ExcludeLocalPlayer = true,       -- Excluir local do SpecialType Player
    Tooltip = "",
    DisabledTooltip = "",
    Disabled = false,
    Visible = true,
    Callback = function(Value) end
})

-- Methods:
Options.Target:SetValue("Player")            -- Selecionar valor
Options.Target:SetValues({ "A", "B" })       -- Substituir valores
Options.Target:AddValues({ "C" })            -- Adicionar valores
Options.Target:SetDisabledValues({ "B" })    -- Desabilitar valores
Options.Target:AddDisabledValues({ "D" })    -- Adicionar desabilitados
Options.Target:GetActiveValues()             -- Valores selecionados (multi: table, single: número)

-- Multi select value:
Options.Targets:SetValue({ Player = true, NPC = true })

-- Events:
Options.Weapon:OnChanged(function() end)

## -- ─── 5.8 KEYPICKERS (AddKeyPicker) ─────────────────────────────────────────────

-- ⚠️ ATENÇÃO: AddKeyPicker SÓ funciona encadeado em Toggle!
-- ⚠️ NÃO funciona em Label nem diretamente no Groupbox!
-- ⚠️ ERRADO:  Groupbox:AddKeyPicker(...) → "attempt to call missing method"
-- ⚠️ ERRADO:  Groupbox:AddLabel(...):AddKeyPicker(...) → "missing method 'SetValue'"
-- ⚠️ CORRETO: local T = Groupbox:AddToggle("KeyToggle", { Text = "Key", Default = false })
-- ⚠️           T:AddKeyPicker("Bind", { ... })

Toggle:AddKeyPicker("FarmBind", {
    Text = "Farm Key",
    Default = "F",                        -- Tecla padrão
    Mode = "Toggle",                      -- Always, Toggle, Hold, Press
    Modes = { "Always", "Toggle", "Hold", "Press" },
    SyncToggleState = true,               -- Sincronizar com toggle pai
    NoUI = false,                         -- Esconder do menu de keybinds?
    WaitForCallback = false,              -- Travar durante callback
    Callback = function(State) end,       -- State = true/false (Toggle/Hold)
    ChangedCallback = function(Key) end,  -- Quando a tecla é alterada
})

-- Modes:
-- Always  = sempre ativo
-- Toggle  = liga/desliga ao pressionar
-- Hold    = ativo enquanto segura
-- Press   = dispara uma vez ao pressionar

-- Events:
Options.FarmBind:OnClick(function() end)     -- Quando pressionado
Options.FarmBind:OnChanged(function(Key) end)-- Quando tecla muda

-- Methods:
Options.FarmBind:GetState()                  -- Retorna se está ativo
Options.FarmBind:SetValue({ "F", "Toggle" }) -- { tecla, modo }
Options.FarmBind.Modifiers                   -- Modificadores (shift, ctrl, etc)

## -- ─── 5.9 COLOR PICKERS (AddColorPicker) ────────────────────────────────────────

-- Encadeado em Toggle ou Label:
Toggle:AddColorPicker("ESPColor", {
    Title = "ESP Color",
    Default = Color3.fromRGB(255,0,0),
    Transparency = 0,             -- nil para desabilitar transparência
    Callback = function(Color) end
})

-- Também pode ser encadeado em Label:
-- Groupbox:AddLabel("Color"):AddColorPicker("Idx", { ... })

-- Methods:
Options.ESPColor:SetValueRGB(Color3.fromRGB(0,255,0))              -- Definir cor RGB
Options.ESPColor:SetValue({H = 0, S = 1, V = 1}, 0)               -- HSV + transparência

-- Properties:
Options.ESPColor.Value                                             -- Color3 atual
Options.ESPColor.Transparency                                      -- Transparência atual (0-1)

-- Events:
Options.ESPColor:OnChanged(function() end)

## -- ─── 5.10 DIVIDERS (AddDivider) ────────────────────────────────────────────────

Groupbox:AddDivider()                            -- Divisor simples
Groupbox:AddDivider("Text")                      -- Com texto
Groupbox:AddDivider({                            -- Com opções
    Text = "Section",
    MarginTop = 10,
    MarginBottom = 10,
    Margin = 10,         -- Aplica top e bottom igual
})

-- ╔══════════════════════════════════════════════════════════════════════════════╗
## -- ║  6. CONTAINERS ESPECIAIS                                                   ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

## -- ─── 6.1 DEPENDENCY BOX ────────────────────────────────────────────────────────

-- Container invisível (só aparece quando as dependências são atendidas):
local Box = Groupbox:AddDependencyBox()
Box:AddSlider("Volume", { Text = "Volume", Default = 50, Min = 0, Max = 100 })
Box:SetupDependencies({
    { Toggles.AutoFarm, true },   -- Só mostra se AutoFarm = true
    -- { Options.Mode, "Stereo" } -- E se Mode = "Stereo"
})

## -- ─── 6.2 DEPENDENCY GROUPBOX ───────────────────────────────────────────────────

-- Como Dependency Box mas com visual de groupbox (mesmo lado do pai):
local Advanced = Groupbox:AddDependencyGroupbox()
Advanced:AddToggle("Extra", { Text = "Extra Setting" })
Advanced:SetupDependencies({
    { Toggles.AutoFarm, true },
})

## -- ─── 6.3 TABBOX ────────────────────────────────────────────────────────────────

local TabBox = MainTab:AddLeftTabbox()       -- ou AddRightTabbox()
local Combat = TabBox:AddTab("Combat", "sword")
local Farm   = TabBox:AddTab("Farm", "pickaxe")
Combat:AddToggle("KillAura", { Text = "Kill Aura" })
Farm:AddToggle("AutoFarm", { Text = "Auto Farm" })

-- ╔══════════════════════════════════════════════════════════════════════════════╗
## -- ║  7. MÍDIA (VIEWPORT, IMAGE, VIDEO, UI PASSTHROUGH)                         ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

## -- ─── 7.1 VIEWPORT (3D) ─────────────────────────────────────────────────────────

-- Exibe um objeto 3D interativo dentro da UI:
Groupbox:AddViewport("Preview", {
    Object = workspace.Part,
    Camera = Instance.new("Camera"),  -- Opcional
    Interactive = true,                -- Orbit/zoom
    AutoFocus = true,                  -- Foco automático no objeto
    Clone = true,                      -- Clonar objeto?
    Height = 200,
    Callback = function(Viewport) end
})

-- Methods:
Viewport:SetObject(part)
Viewport:SetCamera(camera)
Viewport:SetInteractive(true)
Viewport:SetHeight(200)
Viewport:Focus()
Viewport:SetVisible(true)

## -- ─── 7.2 IMAGE ─────────────────────────────────────────────────────────────────

Groupbox:AddImage("Logo", {
    Image = "rbxassetid://123",
    Height = 200,
    Transparency = 0,
    Color = Color3.new(1,1,1),
    ScaleType = Enum.ScaleType.Fit,
    RectOffset = Vector2.zero,
    RectSize = Vector2.zero,
})

-- Methods:
Image:SetImage(newId)
Image:SetTransparency(0.5)
Image:SetColor(Color3.new(1,0,0))
Image:SetHeight(150)

## -- ─── 7.3 VIDEO ─────────────────────────────────────────────────────────────────

Groupbox:AddVideo("Trailer", {
    Video = "rbxassetid://123",
    Playing = true,
    Looped = true,
    Volume = 1,
    Height = 200,
})

-- Methods:
Video:Play()
Video:Pause()
Video:SetPlaying(true)
Video:SetLooped(true)
Video:SetVolume(0.5)

## -- ─── 7.4 UI PASSTHROUGH ────────────────────────────────────────────────────────

-- Embed qualquer GuiBase2d dentro da UI:
Groupbox:AddUIPassthrough("Custom", { Instance = Frame, Height = 120 })

-- Methods:
Passthrough:SetInstance(newFrame)
Passthrough:SetHeight(200)
Passthrough:SetVisible(true)

-- ╔══════════════════════════════════════════════════════════════════════════════╗
## -- ║  8. NOTIFICAÇÕES                                                            ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

## -- ─── 8.1 SIMPLES ───────────────────────────────────────────────────────────────

Library:Notify("Loaded", 5)            -- Descrição, Tempo (segundos)

## -- ─── 8.2 AVANÇADA ──────────────────────────────────────────────────────────────

Library:Notify({
    Title = "Hub",
    Description = "Loaded",
    Time = 5,
    Persist = false,        -- Notificação persistente?
    Steps = 5,              -- Para notificação com progresso
    SoundId = "",           -- ID do som
    Icon = "check",         -- Ícone
    BigIcon = "",           -- Ícone grande
    IconColor = Color3.new(1,1,1),
})

## -- ─── 8.3 PERSISTENTE ───────────────────────────────────────────────────────────

local Notify = Library:Notify({ Title = "Loading", Description = "Wait", Persist = true })
Notify:ChangeTitle("New Title")            -- Mudar título
Notify:ChangeDescription("Finished")       -- Mudar descrição
Notify:ChangeStep(3)                       -- Mudar passo (progresso)
Notify:Destroy()                           -- Destruir notificação

-- ╔══════════════════════════════════════════════════════════════════════════════╗
## -- ║  9. DIALOGS                                                                ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

local Dialog = Window:AddDialog("ConfirmDialog", {
    Title = "Confirm",
    Description = "Continue?",
    AutoDismiss = true,                  -- Fechar ao confirmar?
    OutsideClickDismiss = true,          -- Fechar ao clicar fora?
    Icon = "alert",                      -- Ícone
    TitleColor = Color3.new(1,1,1),
    DescriptionColor = Color3.new(1,1,1),
    FooterButtons = {
        Cancel = {
            Title = "Cancel",
            Variant = "Ghost",           -- Variants: Primary, Secondary, Ghost, Destructive
            Order = 1,
            Callback = function() end
        },
        Confirm = {
            Title = "Confirm",
            Variant = "Primary",
            WaitTime = 3,                -- Tempo mínimo antes de poder clicar
            Order = 2,
            Callback = function(self) end
        }
    }
})

-- Dialog herda métodos de Groupbox (AddToggle, AddInput, etc):
Dialog:AddToggle("DisableSecondary", { Text = "Desabilitar botão", Default = false })

-- Methods:
Dialog:AddFooterButton("Extra", { Title = "Do", Variant = "Secondary", Callback = function() end })
Dialog:RemoveFooterButton("Extra")       -- Remover botão
Dialog:SetButtonDisabled("Confirm", true)-- Desabilitar botão
Dialog:SetButtonOrder("Delete", 5)       -- Mudar ordem
Dialog:SetTitle("New Title")             -- Mudar título
Dialog:SetDescription("New Desc")        -- Mudar descrição
Dialog:Dismiss()                         -- Fechar dialog

-- ╔══════════════════════════════════════════════════════════════════════════════╗
## -- ║  10. LOADING SCREEN                                                        ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

local Loading = Library:CreateLoading({
    Title = "Hub",
    Icon = 95816097006870,
    TotalSteps = 4,
    ShowSidebar = true,
    WindowWidth = 500,
    WindowHeight = 400,
})

## -- ─── 10.1 LOADING METHODS ──────────────────────────────────────────────────────

Loading:SetMessage("Loading...")              -- Mensagem principal
Loading:SetDescription("Please wait...")      -- Mensagem secundária
Loading:SetCurrentStep(1)                     -- Passo atual
Loading:SetTotalSteps(10)                     -- Total de passos
Loading:SetLoadingIcon("info")                -- Ícone giratório
Loading:SetLoadingIconTweenTime(2)            -- Velocidade da rotação (0 = parado)
Loading:SetLoadingIconColor(Color3.new(1,0,0))-- Cor do ícone
Loading:ShowSidebarPage(true)                 -- Mostrar sidebar
Loading:ShowErrorPage(true)                   -- Mostrar página de erro
Loading:SetErrorMessage("Failed")             -- Texto do erro
Loading:SetErrorButtons({ Retry = { Title = "Retry", Variant = "Primary", Callback = function() end } })
Loading:Continue()                            -- Fechar loading e abrir janela
Loading:Destroy()                             -- Fechar loading

## -- ─── 10.2 LOADING SIDEBAR ──────────────────────────────────────────────────────

-- Sidebar funciona como Groupbox:
Loading.Sidebar:AddLabel("Version: 1.0")

-- ╔══════════════════════════════════════════════════════════════════════════════╗
## -- ║  11. ELEMENTOS FLUTUANTES                                                   ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

## -- ─── 11.1 DRAGGABLE LABEL / WATERMARK ──────────────────────────────────────────

local Watermark = Library:AddDraggableLabel("My Hub")
Watermark:SetText("FPS: 60")       -- Mudar texto
Watermark:SetVisible(true)         -- Mostrar/esconder

## -- ─── 11.2 DRAGGABLE BUTTON ─────────────────────────────────────────────────────

local DraggableBtn = Library:AddDraggableButton("Open", function(self)
    print("Clicked!")
end)
DraggableBtn:SetText("New Text")

## -- ─── 11.3 DRAGGABLE MENU ───────────────────────────────────────────────────────

local Holder, Container = Library:AddDraggableMenu("Stats")
-- Container tem UIListLayout, adicione elementos com ZIndex >= 11
local Label = Instance.new("TextLabel")
Label.Text = "Hello"
Label.Size = UDim2.new(0, 100, 0, 24)
Label.ZIndex = 11
Label.Parent = Container

-- ╔══════════════════════════════════════════════════════════════════════════════╗
## -- ║  12. LIBRARY METHODS & PROPERTIES                                          ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

## -- ─── 12.1 LIBRARY METHODS ──────────────────────────────────────────────────────

Library:Toggle()                                -- Alternar visibilidade da janela
Library:Toggle(true/false)                      -- Forçar estado
Library:Unload()                                -- Descarregar biblioteca (limpa tudo)
Library:SetFont(Enum.Font.GothamMedium)         -- Mudar fonte global
Library:SetNotifySide("Left")                   -- Mudar lado das notificações
Library:SetDPIScale(125)                        -- Escala DPI (125 = 125%)
Library:OnUnload(function() end)                -- Callback ao descarregar
Library:GiveSignal(connection)                  -- Registrar conexão para cleanup

-- Cursor:
Library:ChangeCursorIcon("rbxassetid://123")
Library:ChangeCursorIconSize(UDim2.fromOffset(32,32))
Library:ResetCursorIcon()

-- Registry (tema):
Library:AddToRegistry(Instance, { BackgroundColor3 = "MainColor" })
Library:RemoveFromRegistry(Instance)
Library:UpdateColorsUsingRegistry()

-- Helpers:
Library:SafeCallback(func, ...)                 -- Chamar função com proteção de erro
Library:GetTextBounds("Text", Font, 14, 200)    -- Medir texto (width, height)
Library:GetBetterColor(color, 0.1)              -- Ajustar brilho de cor
Library:GetLighterColor(color)                  -- Versão mais clara
Library:GetDarkerColor(color)                   -- Versão mais escura

## -- ─── 12.2 LIBRARY PROPERTIES ───────────────────────────────────────────────────

Library.Toggled                     -- boolean: janela visível?
Library.Unloaded                    -- boolean: biblioteca descarregada?
Library.ForceCheckbox               -- boolean: AddToggle vira checkbox?
Library.NotifyOnError               -- boolean: mostrar notificação em erro?
Library.CantDragForced              -- boolean: impedir arrastar janela?
Library.IsMobile                    -- boolean: dispositivo móvel?
Library.Scheme                      -- table: esquema de cores atual
Library.KeybindFrame                -- Frame: menu de keybinds
Library.ToggleKeybind               -- KeyPicker: tecla da janela

-- ╔══════════════════════════════════════════════════════════════════════════════╗
## -- ║  13. GLOBAL TABLES                                                         ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

Library.Options          -- Todos os sliders, inputs, dropdowns, color pickers
Library.Toggles          -- Todos os toggles e checkboxes
Library.Labels           -- Todos os labels (com Idx)
Library.Buttons          -- Todos os botões (com Idx)

-- Exemplos de uso:
Options.WalkSpeed.Value
Toggles.AutoFarm.Value
Labels.StatusLabel:SetText("Running")

-- ╔══════════════════════════════════════════════════════════════════════════════╗
## -- ║  14. THEME MANAGER (Produção)                                              ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

## -- ─── 14.1 SETUP BÁSICO ─────────────────────────────────────────────────────────

ThemeManager:SetLibrary(Library)
ThemeManager:SetFolder("MyHub")
ThemeManager:ApplyToTab(Tabs.Settings)         -- Criar UI de temas na tab
ThemeManager:ApplyToGroupbox(Groupbox)          -- Aplicar em groupbox específico

## -- ─── 14.2 CARREGAMENTO ─────────────────────────────────────────────────────────

ThemeManager:LoadDefault()                      -- Carregar tema padrão
ThemeManager:ApplyTheme("Ocean")                -- Aplicar tema pelo nome
ThemeManager:GetCustomTheme("MyTheme")          -- Carregar tema customizado

## -- ─── 14.3 SALVAR / DELETAR ─────────────────────────────────────────────────────

ThemeManager:SaveDefault("MyTheme")             -- Salvar tema como padrão
ThemeManager:SaveCustomTheme("MyTheme")         -- Salvar tema customizado
ThemeManager:Delete("MyTheme")                  -- Deletar tema
ThemeManager:ReloadCustomThemes()               -- Recarregar temas customizados

## -- ─── 14.4 OUTROS ───────────────────────────────────────────────────────────────

ThemeManager:ThemeUpdate()                      -- Forçar atualização do tema
ThemeManager:SetDefaultTheme({
    FontColor = Color3.new(1,1,1),
    MainColor = Color3.new(0,0,0),
    AccentColor = Color3.new(0,0.5,1),
    BackgroundColor = Color3.new(0.1,0.1,0.1),
    OutlineColor = Color3.new(0.2,0.2,0.2),
    FontFace = Enum.Font.GothamMedium,
})

-- ╔══════════════════════════════════════════════════════════════════════════════╗
## -- ║  15. SAVE MANAGER (Produção)                                               ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

## -- ─── 15.1 SETUP BÁSICO ─────────────────────────────────────────────────────────

SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()               -- Não salvar configurações de tema
SaveManager:SetIgnoreIndexes({ "MenuKeybind" }) -- Ignorar indexes específicos
SaveManager:SetFolder("MyHub")                  -- Pasta principal
SaveManager:SetSubFolder("SubFolder")           -- Subpasta opcional
SaveManager:BuildConfigSection(Tabs.Settings)   -- UI de configurações na tab
SaveManager:LoadAutoloadConfig()                -- Carregar config salva

## -- ─── 15.2 MANIPULAR CONFIGS ────────────────────────────────────────────────────

SaveManager:Save("ConfigName")                  -- Salvar configuração manualmente
SaveManager:Load("ConfigName")                  -- Carregar configuração
SaveManager:Delete("ConfigName")                -- Deletar configuração
SaveManager:RefreshConfigList()                 -- Listar configurações

## -- ─── 15.3 AUTOLOAD ─────────────────────────────────────────────────────────────

SaveManager:GetAutoloadConfig()                 -- Nome da config auto-load
SaveManager:SaveAutoloadConfig("ConfigName")    -- Definir auto-load
SaveManager:DeleteAutoLoadConfig()              -- Remover auto-load

## -- ─── 15.4 ORDEM DE CARREGAMENTO ────────────────────────────────────────────────

SaveManager:SetLoadingOrder(true, {
    "Dropdown", "ColorPicker", "KeyPicker", "Slider", "Input", "Toggle"
})

-- ╔══════════════════════════════════════════════════════════════════════════════╗
## -- ║  16. ORDEM RECOMENDADA DE PRODUÇÃO                                         ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

-- 1.  Load Library
-- 2.  Create Window
-- 3.  Create Tabs
-- 4.  Create Groupboxes
-- 5.  Create UI Elements (Toggles, Sliders, etc)
-- 6.  Create Callbacks using OnChanged (separado dos elementos)
-- 7.  Setup ThemeManager
-- 8.  Setup SaveManager
-- 9.  Load Default Theme: ThemeManager:LoadDefault()
-- 10. Load Autoload Config: SaveManager:LoadAutoloadConfig()

-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║                    FIM DA REFERÊNCIA                                       ║
-- ║               EXEMPLO PRÁTICO ABAIXO                                       ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝


-- example script by https://github.com/mstudio45/LinoriaLib/blob/main/Example.lua and modified by deivid
-- You can suggest changes with a pull request or something

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

Library.ForceCheckbox = false -- Forces AddToggle to AddCheckbox
Library.ShowToggleFrameInKeybinds = true -- Make toggle keybinds work inside the keybinds UI (aka adds a toggle to the UI). Good for mobile users (Default value = true)

local Window = Library:CreateWindow({
	-- Set Center to true if you want the menu to appear in the center
	-- Set AutoShow to true if you want the menu to appear when it is created
	-- Set Resizable to true if you want to have in-game resizable Window
	-- Set MobileButtonsSide to "Left" or "Right" if you want the ui toggle & lock buttons to be on the left or right side of the window
	-- Set ShowCustomCursor to false if you don't want to use the Linoria cursor
	-- NotifySide = Changes the side of the notifications (Left, Right) (Default value = Left)
	-- Position and Size are also valid options here
	-- but you do not need to define them unless you are changing them :)

	Title = "mspaint",
	Footer = "version: example",
	Icon = 95816097006870,
	NotifySide = "Right",
	ShowCustomCursor = true,
})

-- CALLBACK NOTE:
-- Passing in callback functions via the initial element parameters (i.e. Callback = function(Value)...) works
-- HOWEVER, using Toggles/Options.INDEX:OnChanged(function(Value) ... ) is the RECOMMENDED way to do this.
-- I strongly recommend decoupling UI code from logic code. i.e. Create your UI elements FIRST, and THEN setup :OnChanged functions later.

-- You do not have to set your tabs & groups up this way, just a prefrence.
-- You can find more icons in https://lucide.dev/
local Tabs = {
	-- Creates a new tab titled Main
	Main = Window:AddTab("Main", "user"),
	Key = Window:AddKeyTab("Key System"),
	["UI Settings"] = Window:AddTab("UI Settings", "settings"),
}


--[[
Example of how to add a warning box to a tab; the title AND text support rich text formatting.

local UISettingsTab = Tabs["UI Settings"]

UISettingsTab:UpdateWarningBox({
	Visible = true,
	Title = "Warning",
	Text = "This is a warning box!",
})

--]]

-- Groupbox and Tabbox inherit the same functions
-- except Tabboxes you have to call the functions on a tab (Tabbox:AddTab(Name))
local LeftGroupBox = Tabs.Main:AddLeftGroupbox("Groupbox", "boxes")

-- We can also get our Main tab via the following code:
-- local LeftGroupBox = Window.Tabs.Main:AddLeftGroupbox("Groupbox", "boxes")

-- Tabboxes are a tiny bit different, but here's a basic example:
--[[

local TabBox = Tabs.Main:AddLeftTabbox() -- Add Tabbox on left side

local Tab1 = TabBox:AddTab("Tab 1")
local Tab2 = TabBox:AddTab("Tab 2")

-- You can now call AddToggle, etc on the tabs you added to the Tabbox
]]

-- Groupbox:AddToggle
-- Arguments: Index, Options
LeftGroupBox:AddToggle("MyToggle", {
	Text = "This is a toggle",
	Tooltip = "This is a tooltip", -- Information shown when you hover over the toggle
	DisabledTooltip = "I am disabled!", -- Information shown when you hover over the toggle while it's disabled

	Default = true, -- Default value (true / false)
	Disabled = false, -- Will disable the toggle (true / false)
	Visible = true, -- Will make the toggle invisible (true / false)
	Risky = false, -- Makes the text red (the color can be changed using Library.Scheme.Red) (Default value = false)

	Callback = function(Value)
		print("[cb] MyToggle changed to:", Value)
	end,
})
	:AddColorPicker("ColorPicker1", {
		Default = Color3.new(1, 0, 0),
		Title = "Some color1", -- Optional. Allows you to have a custom color picker title (when you open it)
		Transparency = 0, -- Optional. Enables transparency changing for this color picker (leave as nil to disable)

		Callback = function(Value)
			print("[cb] Color changed!", Value)
		end,
	})
	:AddColorPicker("ColorPicker2", {
		Default = Color3.new(0, 1, 0),
		Title = "Some color2",

		Callback = function(Value)
			print("[cb] Color changed!", Value)
		end,
	})

-- Fetching a toggle object for later use:
-- Toggles.MyToggle.Value

-- Toggles is a table added to getgenv() by the library
-- You index Toggles with the specified index, in this case it is 'MyToggle'
-- To get the state of the toggle you do toggle.Value

-- Calls the passed function when the toggle is updated
Toggles.MyToggle:OnChanged(function()
	-- here we get our toggle object & then get its value
	print("MyToggle changed to:", Toggles.MyToggle.Value)
end)

-- This should print to the console: "My toggle state changed! New value: false"
Toggles.MyToggle:SetValue(false)

LeftGroupBox:AddCheckbox("MyCheckbox", {
	Text = "This is a checkbox",
	Tooltip = "This is a tooltip", -- Information shown when you hover over the toggle
	DisabledTooltip = "I am disabled!", -- Information shown when you hover over the toggle while it's disabled

	Default = true, -- Default value (true / false)
	Disabled = false, -- Will disable the toggle (true / false)
	Visible = true, -- Will make the toggle invisible (true / false)
	Risky = false, -- Makes the text red (the color can be changed using Library.Scheme.Red) (Default value = false)

	Callback = function(Value)
		print("[cb] MyCheckbox changed to:", Value)
	end,
})

Toggles.MyCheckbox:OnChanged(function()
	print("MyCheckbox changed to:", Toggles.MyCheckbox.Value)
end)

-- 1/15/23
-- Deprecated old way of creating buttons in favor of using a table
-- Added DoubleClick button functionality

--[[
	Groupbox:AddButton
	Arguments: {
		Text = string,
		Func = function,
		DoubleClick = boolean
		Tooltip = string,
	}

	You can call :AddButton on a button to add a SubButton!
]]

local MyButton = LeftGroupBox:AddButton({
	Text = "Button",
	Func = function()
		print("You clicked a button!")
	end,
	DoubleClick = false,

	Tooltip = "This is the main button",
	DisabledTooltip = "I am disabled!",

	Disabled = false, -- Will disable the button (true / false)
	Visible = true, -- Will make the button invisible (true / false)
	Risky = false, -- Makes the text red (the color can be changed using Library.Scheme.Red) (Default value = false)
})

local MyButton2 = MyButton:AddButton({
	Text = "Sub button",
	Func = function()
		print("You clicked a sub button!")
	end,
	DoubleClick = true, -- You will have to click this button twice to trigger the callback
	Tooltip = "This is the sub button",
	DisabledTooltip = "I am disabled!",
})

local MyDisabledButton = LeftGroupBox:AddButton({
	Text = "Disabled Button",
	Func = function()
		print("You somehow clicked a disabled button!")
	end,
	DoubleClick = false,
	Tooltip = "This is a disabled button",
	DisabledTooltip = "I am disabled!", -- Information shown when you hover over the button while it's disabled
	Disabled = true,
})

--[[
	NOTE: You can chain the button methods!
	EXAMPLE:

	LeftGroupBox:AddButton({ Text = 'Kill all', Func = Functions.KillAll, Tooltip = 'This will kill everyone in the game!' })
		:AddButton({ Text = 'Kick all', Func = Functions.KickAll, Tooltip = 'This will kick everyone in the game!' })
]]

-- Groupbox:AddLabel
-- Arguments: Text, DoesWrap, Idx
-- Arguments: Idx, Options
LeftGroupBox:AddLabel("This is a label")
LeftGroupBox:AddLabel("This is a label\n\nwhich wraps its text!", true)
LeftGroupBox:AddLabel("This is a label exposed to Labels", true, "TestLabel")
LeftGroupBox:AddLabel("SecondTestLabel", {
	Text = "This is a label made with table options and an index",
	DoesWrap = true, -- Defaults to false
})

LeftGroupBox:AddLabel("SecondTestLabel", {
	Text = "This is a label that doesn't wrap it's own text",
	DoesWrap = false, -- Defaults to false
})

-- Options is a table added to getgenv() by the library
-- You index Options with the specified index, in this case it is 'SecondTestLabel' & 'TestLabel'
-- To set the text of the label you do label:SetText

-- Options.TestLabel:SetText("first changed!")
-- Options.SecondTestLabel:SetText("second changed!")

-- Groupbox:AddDivider
-- Arguments: None
LeftGroupBox:AddDivider()

--[[
	Groupbox:AddSlider
	Arguments: Idx, SliderOptions

	SliderOptions: {
		Text = string,
		Default = number,
		Min = number,
		Max = number,
		Suffix = string,
		Rounding = number,
		Compact = boolean,
		HideMax = boolean,
	}

	Text, Default, Min, Max, Rounding must be specified.
	Suffix is optional.
	Rounding is the number of decimal places for precision.

	Compact will hide the title label of the Slider

	HideMax will only display the value instead of the value & max value of the slider
	Compact will do the same thing
]]
LeftGroupBox:AddSlider("MySlider", {
	Text = "This is my slider!",
	Default = 0,
	Min = 0,
	Max = 5,
	Rounding = 1,
	Compact = false,

	Callback = function(Value)
		print("[cb] MySlider was changed! New value:", Value)
	end,

	Tooltip = "I am a slider!", -- Information shown when you hover over the slider
	DisabledTooltip = "I am disabled!", -- Information shown when you hover over the slider while it's disabled

	Disabled = false, -- Will disable the slider (true / false)
	Visible = true, -- Will make the slider invisible (true / false)
})

-- Options is a table added to getgenv() by the library
-- You index Options with the specified index, in this case it is 'MySlider'
-- To get the value of the slider you do slider.Value

local Number = Options.MySlider.Value
Options.MySlider:OnChanged(function()
	print("MySlider was changed! New value:", Options.MySlider.Value)
end)

-- This should print to the console: "MySlider was changed! New value: 3"
Options.MySlider:SetValue(3)

LeftGroupBox:AddSlider("MySlider2", {
	Text = "This is my custom display slider!",
	Default = 0,
	Min = 0,
	Max = 5,
	Rounding = 0,
	Compact = false,

	FormatDisplayValue = function(slider, value)
		if value == slider.Max then return 'Everything' end
		if value == slider.Min then return 'Nothing' end
		-- If you return nil, the default formatting will be applied
	end,

	Tooltip = "I am a slider!", -- Information shown when you hover over the slider
	DisabledTooltip = "I am disabled!", -- Information shown when you hover over the slider while it's disabled

	Disabled = false, -- Will disable the slider (true / false)
	Visible = true, -- Will make the slider invisible (true / false)
})

-- Groupbox:AddInput
-- Arguments: Idx, Info
LeftGroupBox:AddInput("MyTextbox", {
	Default = "My textbox!",
	Numeric = false, -- true / false, only allows numbers
	Finished = false, -- true / false, only calls callback when you press enter
	ClearTextOnFocus = true, -- true / false, if false the text will not clear when textbox focused

	Text = "This is a textbox",
	Tooltip = "This is a tooltip", -- Information shown when you hover over the textbox

	Placeholder = "Placeholder text", -- placeholder text when the box is empty
	-- MaxLength is also an option which is the max length of the text

	Callback = function(Value)
		print("[cb] Text updated. New text:", Value)
	end,
})

Options.MyTextbox:OnChanged(function()
	print("Text updated. New text:", Options.MyTextbox.Value)
end)

-- Groupbox:AddDropdown
-- Arguments: Idx, Info

local DropdownGroupBox = Tabs.Main:AddRightGroupbox("Dropdowns")

DropdownGroupBox:AddDropdown("MyDropdown", {
	Values = { "This", "is", "a", "dropdown" },
	Default = 1, -- number index of the value / string
	Multi = false, -- true / false, allows multiple choices to be selected

	Text = "A dropdown",
	Tooltip = "This is a tooltip", -- Information shown when you hover over the dropdown
	DisabledTooltip = "I am disabled!", -- Information shown when you hover over the dropdown while it's disabled

	Searchable = false, -- true / false, makes the dropdown searchable (great for a long list of values)

	Callback = function(Value)
		print("[cb] Dropdown got changed. New value:", Value)
	end,

	Disabled = false, -- Will disable the dropdown (true / false)
	Visible = true, -- Will make the dropdown invisible (true / false)
})

Options.MyDropdown:OnChanged(function()
	print("Dropdown got changed. New value:", Options.MyDropdown.Value)
end)

Options.MyDropdown:SetValue("This")

DropdownGroupBox:AddDropdown("MySearchableDropdown", {
	Values = { "This", "is", "a", "searchable", "dropdown" },
	Default = 1, -- number index of the value / string
	Multi = false, -- true / false, allows multiple choices to be selected

	Text = "A searchable dropdown",
	Tooltip = "This is a tooltip", -- Information shown when you hover over the dropdown
	DisabledTooltip = "I am disabled!", -- Information shown when you hover over the dropdown while it's disabled

	Searchable = true, -- true / false, makes the dropdown searchable (great for a long list of values)

	Callback = function(Value)
		print("[cb] Dropdown got changed. New value:", Value)
	end,

	Disabled = false, -- Will disable the dropdown (true / false)
	Visible = true, -- Will make the dropdown invisible (true / false)
})

DropdownGroupBox:AddDropdown("MyDisplayFormattedDropdown", {
	Values = { "This", "is", "a", "formatted", "dropdown" },
	Default = 1, -- number index of the value / string
	Multi = false, -- true / false, allows multiple choices to be selected

	Text = "A display formatted dropdown",
	Tooltip = "This is a tooltip", -- Information shown when you hover over the dropdown
	DisabledTooltip = "I am disabled!", -- Information shown when you hover over the dropdown while it's disabled

	FormatDisplayValue = function(Value) -- You can change the display value for any values. The value will be still same, only the UI changes.
		if Value == "formatted" then
			return "display formatted" -- formatted -> display formatted but in Options.MyDisplayFormattedDropdown.Value it will still return formatted if its selected.
		end

		return Value
	end,

	Searchable = false, -- true / false, makes the dropdown searchable (great for a long list of values)

	Callback = function(Value)
		print("[cb] Display formatted dropdown got changed. New value:", Value)
	end,

	Disabled = false, -- Will disable the dropdown (true / false)
	Visible = true, -- Will make the dropdown invisible (true / false)
})

-- Multi dropdowns
DropdownGroupBox:AddDropdown("MyMultiDropdown", {
	-- Default is the numeric index (e.g. "This" would be 1 since it if first in the values list)
	-- Default also accepts a string as well

	-- Currently you can not set multiple values with a dropdown

	Values = { "This", "is", "a", "dropdown" },
	Default = 1,
	Multi = true, -- true / false, allows multiple choices to be selected

	Text = "A multi dropdown",
	Tooltip = "This is a tooltip", -- Information shown when you hover over the dropdown

	Callback = function(Value)
		print("[cb] Multi dropdown got changed:")
		for key, value in next, Options.MyMultiDropdown.Value do
			print(key, value) -- should print something like This, true
		end
	end,
})

Options.MyMultiDropdown:SetValue({
	This = true,
	is = true,
})

DropdownGroupBox:AddDropdown("MyDisabledDropdown", {
	Values = { "This", "is", "a", "dropdown" },
	Default = 1, -- number index of the value / string
	Multi = false, -- true / false, allows multiple choices to be selected

	Text = "A disabled dropdown",
	Tooltip = "This is a tooltip", -- Information shown when you hover over the dropdown
	DisabledTooltip = "I am disabled!", -- Information shown when you hover over the dropdown while it's disabled

	Callback = function(Value)
		print("[cb] Disabled dropdown got changed. New value:", Value)
	end,

	Disabled = true, -- Will disable the dropdown (true / false)
	Visible = true, -- Will make the dropdown invisible (true / false)
})

DropdownGroupBox:AddDropdown("MyDisabledValueDropdown", {
	Values = { "This", "is", "a", "dropdown", "with", "disabled", "value" },
	DisabledValues = { "disabled" }, -- Disabled Values that are unclickable
	Default = 1, -- number index of the value / string
	Multi = false, -- true / false, allows multiple choices to be selected

	Text = "A dropdown with disabled value",
	Tooltip = "This is a tooltip", -- Information shown when you hover over the dropdown
	DisabledTooltip = "I am disabled!", -- Information shown when you hover over the dropdown while it's disabled

	Callback = function(Value)
		print("[cb] Dropdown with disabled value got changed. New value:", Value)
	end,

	Disabled = false, -- Will disable the dropdown (true / false)
	Visible = true, -- Will make the dropdown invisible (true / false)
})

DropdownGroupBox:AddDropdown("MyVeryLongDropdown", {
	Values = {
		"This",
		"is",
		"a",
		"very",
		"long",
		"dropdown",
		"with",
		"a",
		"lot",
		"of",
		"values",
		"but",
		"you",
		"can",
		"see",
		"more",
		"than",
		"8",
		"values",
	},
	Default = 1, -- number index of the value / string
	Multi = false, -- true / false, allows multiple choices to be selected

	MaxVisibleDropdownItems = 12, -- Default: 8, allows you to change the size of the dropdown list

	Text = "A very long dropdown",
	Tooltip = "This is a tooltip", -- Information shown when you hover over the dropdown
	DisabledTooltip = "I am disabled!", -- Information shown when you hover over the dropdown while it's disabled

	Searchable = false, -- true / false, makes the dropdown searchable (great for a long list of values)

	Callback = function(Value)
		print("[cb] Very long dropdown got changed. New value:", Value)
	end,

	Disabled = false, -- Will disable the dropdown (true / false)
	Visible = true, -- Will make the dropdown invisible (true / false)
})

DropdownGroupBox:AddDropdown("MyPlayerDropdown", {
	SpecialType = "Player",
	ExcludeLocalPlayer = true, -- true / false, excludes the localplayer from the Player type
	Text = "A player dropdown",
	Tooltip = "This is a tooltip", -- Information shown when you hover over the dropdown

	Callback = function(Value)
		print("[cb] Player dropdown got changed:", Value)
	end,
})

DropdownGroupBox:AddDropdown("MyTeamDropdown", {
	SpecialType = "Team",
	Text = "A team dropdown",
	Tooltip = "This is a tooltip", -- Information shown when you hover over the dropdown

	Callback = function(Value)
		print("[cb] Team dropdown got changed:", Value)
	end,
})

-- Label:AddColorPicker
-- Arguments: Idx, Info

-- You can also ColorPicker & KeyPicker to a Toggle as well

LeftGroupBox:AddLabel("Color"):AddColorPicker("ColorPicker", {
	Default = Color3.new(0, 1, 0), -- Bright green
	Title = "Some color", -- Optional. Allows you to have a custom color picker title (when you open it)
	Transparency = 0, -- Optional. Enables transparency changing for this color picker (leave as nil to disable)

	Callback = function(Value)
		print("[cb] Color changed!", Value)
	end,
})

Options.ColorPicker:OnChanged(function()
	print("Color changed!", Options.ColorPicker.Value)
	print("Transparency changed!", Options.ColorPicker.Transparency)
end)

Options.ColorPicker:SetValueRGB(Color3.fromRGB(0, 255, 140))

-- AddKeyPicker MUST be chained on a Toggle, NOT a Label
-- Chaining on Label causes: "attempt to call missing method 'SetValue' of table"
-- because the Library internally calls ParentObj:SetValue() in KeyPicker:Update()

local KeyPickerToggle = LeftGroupBox:AddToggle("KeyPickerToggle", { Text = "Keybind", Default = false })
KeyPickerToggle:AddKeyPicker("KeyPicker", {
	-- SyncToggleState works with toggles.
	-- It allows you to make a keybind which has its state synced with its parent toggle

	-- Example: Keybind which you use to toggle flyhack, etc.
	-- Changing the toggle disables the keybind state and toggling the keybind switches the toggle state

	Default = "MB2", -- String as the name of the keybind (MB1, MB2 for mouse buttons)
	SyncToggleState = true,

	-- You can define custom Modes but I have never had a use for it.
	Mode = "Toggle", -- Modes: Always, Toggle, Hold, Press (example down below)

	Text = "Auto lockpick safes", -- Text to display in the keybind menu
	NoUI = false, -- Set to true if you want to hide from the Keybind menu,

	-- Occurs when the keybind is clicked, Value is `true`/`false`
	Callback = function(Value)
		print("[cb] Keybind clicked!", Value)
	end,

	-- Occurs when the keybind itself is changed, `NewKey` is a KeyCode Enum OR a UserInputType Enum, `NewModifiers` is a table with KeyCode Enum(s) or nil
	ChangedCallback = function(NewKey, NewModifiers)
		print("[cb] Keybind changed!", NewKey, table.unpack(NewModifiers or {}))
	end,
})

-- OnClick is only fired when you press the keybind and the mode is Toggle
-- Otherwise, you will have to use Keybind:GetState()
Options.KeyPicker:OnClick(function()
	print("Keybind clicked!", Options.KeyPicker:GetState())
end)

Options.KeyPicker:OnChanged(function()
	print("Keybind changed!", Options.KeyPicker.Value, table.unpack(Options.KeyPicker.Modifiers or {}))
end)

task.spawn(function()
	while task.wait(1) do
		-- example for checking if a keybind is being pressed
		local state = Options.KeyPicker:GetState()
		if state then
			print("KeyPicker is being held down")
		end

		if Library.Unloaded then
			break
		end
	end
end)

Options.KeyPicker:SetValue({ "MB2", "Hold" }) -- Sets keybind to MB2, mode to Hold

-- AddKeyPicker (Press Mode) — STILL must be chained on a Toggle, not a Label
-- Even with Mode = "Press", the Library calls ParentObj:SetValue() internally

local KeybindNumber = 0

local PressKeyToggle = LeftGroupBox:AddToggle("PressKeyToggle", { Text = "Press Keybind", Default = false })
PressKeyToggle:AddKeyPicker("KeyPicker2", {
	-- Example: Press Keybind which you use to run a callback when the key was pressed.

	Default = "X", -- String as the name of the keybind (MB1, MB2 for mouse buttons)

	Mode = "Press",
	WaitForCallback = false, -- Locks the keybind during the execution of Callback and OnChanged.

	Text = "Increase Number", -- Text to display in the keybind menu

	-- Occurs when the keybind is clicked, Value is always `true` for Press keybind.
	Callback = function()
		KeybindNumber = KeybindNumber + 1
		print("[cb] Keybind clicked! Number increased to:", KeybindNumber)
	end
})

-- Long text label to demonstrate UI scrolling behaviour.
local LeftGroupBox2 = Tabs.Main:AddLeftGroupbox("Groupbox #2")
LeftGroupBox2:AddLabel(
	"This label spans multiple lines! We're gonna run out of UI space...\nJust kidding! Scroll down!\n\n\nHello from below!",
	true
)

local TabBox = Tabs.Main:AddRightTabbox() -- Add Tabbox on right side

-- Anything we can do in a Groupbox, we can do in a Tabbox tab (AddToggle, AddSlider, AddLabel, etc etc...)
local Tab1 = TabBox:AddTab("Tab 1")
Tab1:AddToggle("Tab1Toggle", { Text = "Tab1 Toggle" })

local Tab2 = TabBox:AddTab("Tab 2")
Tab2:AddToggle("Tab2Toggle", { Text = "Tab2 Toggle" })

Library:OnUnload(function()
	print("Unloaded!")
end)

-- Anything we can do in a Groupbox, we can do in a Key tab (AddToggle, AddSlider, AddLabel, etc etc...)
Tabs.Key:AddLabel({
	Text = "Key: Banana",
	DoesWrap = true,
	Size = 16,
})

Tabs.Key:AddKeyBox(function(ReceivedKey)
	-- KeyBox only takes the callback for the button, you need to implement your own key check inside the callback
	local Success = ReceivedKey == "Banana"

	print("Expected Key: Banana - Received Key:", ReceivedKey, "| Success:", Success)
	Library:Notify({
		Title = "Expected Key: Banana",
		Description = "Received Key: " .. ReceivedKey .. "\nSuccess: " .. tostring(Success),
		Time = 4,
	})
end)

-- DraggableLabel

Library:AddDraggableLabel("This is a Draggable Label")

-- UI Settings
local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu", "wrench")

MenuGroup:AddToggle("KeybindMenuOpen", {
	Default = Library.KeybindFrame.Visible,
	Text = "Open Keybind Menu",
	Callback = function(value)
		Library.KeybindFrame.Visible = value
	end,
})
MenuGroup:AddToggle("ShowCustomCursor", {
	Text = "Custom Cursor",
	Default = true,
	Callback = function(Value)
		Library.ShowCustomCursor = Value
	end,
})
MenuGroup:AddDropdown("NotificationSide", {
	Values = { "Left", "Right" },
	Default = "Right",

	Text = "Notification Side",

	Callback = function(Value)
		Library:SetNotifySide(Value)
	end,
})
MenuGroup:AddDropdown("DPIDropdown", {
	Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
	Default = "100%",

	Text = "DPI Scale",

	Callback = function(Value)
		Value = Value:gsub("%%", "")
		local DPI = tonumber(Value)

		Library:SetDPIScale(DPI)
	end,
})

MenuGroup:AddSlider("UICornerSlider", {
	Text = "Corner Radius",
	Default = Library.CornerRadius,
	Min = 0,
	Max = 20,
	Rounding = 0,
	Callback = function(value)
		Window:SetCornerRadius(value)
	end
})

MenuGroup:AddDivider()
local MenuKeyToggle = MenuGroup:AddToggle("MenuKeyToggle", { Text = "Menu bind", Default = false })
MenuKeyToggle:AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind", SyncToggleState = true, Mode = "Toggle" })

MenuGroup:AddButton("Unload", function()
	Library:Unload()
end)

Library.ToggleKeybind = Options.MenuKeybind -- Allows you to have a custom keybind for the menu

-- Addons:
-- SaveManager (Allows you to have a configuration system)
-- ThemeManager (Allows you to have a menu theme system)

-- Hand the library over to our managers
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

-- Ignore keys that are used by ThemeManager.
-- (we dont want configs to save themes, do we?)
SaveManager:IgnoreThemeSettings()

-- Adds our MenuKeybind to the ignore list
-- (do you want each config to have a different menu key? probably not.)
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

-- use case for doing it this way:
-- a script hub could have themes in a global folder
-- and game configs in a separate folder per game
ThemeManager:SetFolder("MyScriptHub")
SaveManager:SetFolder("MyScriptHub/specific-game")
SaveManager:SetSubFolder("specific-place") -- if the game has multiple places inside of it (for example: DOORS)
-- you can use this to save configs for those places separately
-- The path in this script would be: MyScriptHub/specific-game/settings/specific-place
-- [ This is optional ]

-- Builds our config menu on the right side of our tab
SaveManager:BuildConfigSection(Tabs["UI Settings"])

-- Builds our theme menu (with plenty of built in themes) on the left side
-- NOTE: you can also call ThemeManager:ApplyToGroupbox to add it to a specific groupbox
ThemeManager:ApplyToTab(Tabs["UI Settings"])

-- You can use the SaveManager:LoadAutoloadConfig() to load a config
-- which has been marked to be one that auto loads!
SaveManager:LoadAutoloadConfig()