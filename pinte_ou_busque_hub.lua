--[[
================================================================================
PINTE OU BUSQUE - COMPLETE HUB (KyriLib UI)
================================================================================
Real analysis (via executor MCP):
 - Teams: Lobby / Hider / Seeker. You are currently a Hider.
 - Leaderstats: Money, Wins, Kills (server-authoritative -> read-only).
 - Mechanic: Hiders paint their head to hide; Seekers use the Blaster.
 - Confirmed remote: ReplicatedStorage.Blaster.Remotes.Shoot
     Shoot:FireServer(serverTime, blasterTool, cameraCFrame, {["1"]=humanoid})
 - RevealEnemies / Crate / Taunt / Freeze are DEV PRODUCTS (paid) in the Ids
   module -> NOT fired by "free" buttons here (avoids hallucination).

All features below use:
 (a) client-side physics (WalkSpeed, Fly, Noclip, Jump) or
 (b) client-side rendering (ESP, FOV, Lighting) or
 (c) the CONFIRMED Shoot remote above (blaster auto-shoot).
================================================================================
]]

-- ============================================================================
-- LOAD KYRILIB
-- ============================================================================
-- NOTE: the URL kyrilib.dev/kyrilib/ may return HTML (landing page) instead of
-- Lua code. We validate the result before using it.
local kyri

local function tryLoad(url)
	local ok, code = pcall(function() return game:HttpGet(url) end)
	if not ok or not code or #code < 100 then return nil end
	if string.sub(code, 1, 1) == "<" then return nil end -- probably HTML
	local fn
	ok, fn = pcall(loadstring, code)
	if not ok or type(fn) ~= "function" then return nil end
	local ok2, lib = pcall(fn)
	if not ok2 or not lib or type(lib) ~= "table" or not lib.new then return nil end
	return lib
end

kyri = tryLoad("https://raw.githubusercontent.com/Justanewplayer19/KyriLib/main/source.lua")
if not kyri then
	kyri = tryLoad("https://kyrilib.dev/kyrilib/")
end

if not kyri then
	error("Failed to load KyriLib from both sources.")
end

-- Essential services (defined before the panel)
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ============================================================================
-- KEY SYSTEM (FIXED KEY - no link shortener)
-- ============================================================================
-- Fixed key: scriptfree7
-- No link shortener / no external SDK. The key is posted on our Discord
-- in the "get key" channel. Just paste it below to continue.
local FIXED_KEY = "scriptfree7"
local DISCORD_LINK = "https://discord.gg/fdj3YhzJrS"

local function verifyKey(key)
	if key and key == FIXED_KEY then
		getgenv().SCRIPT_KEY = key
		return true, "Valid key"
	end
	return false, "Invalid key"
end

local keyWindow = kyri.new("Pinte ou Busque Hub - Key", {
	GameName = "PinteOuBusque_Key",
	AutoLoad = "default",
})
if not keyWindow then return end

local keyTab = keyWindow:tab("Key", "key")
keyTab:section("Authentication")
keyTab:paragraph("Fixed Key - No Link Shortener",
	"This script uses a FIXED KEY, there is NO link shortener or external key system. " ..
	"The key is: scriptfree7  (posted on our Discord in the 'get key' channel). " ..
	"Paste it below and click Verify to continue.")

keyTab:button("Copy Discord", function()
	if setclipboard then setclipboard(DISCORD_LINK) end
	keyWindow:notify("Copied", "Discord link copied!", 2)
end, "copy_discord")

local keyInput = keyTab:input("Your Key", "Paste key here...", function() end, "user_key")

keyTab:space(4)

keyTab:button("Verify Key", function()
	local key = keyInput.input.Text
	if not key or key == "" then
		keyWindow:notify("Error", "Please enter a key", 2)
		return
	end
	local ok, msg = verifyKey(key)
	if ok then
		keyWindow:notify("Success", msg, 3)
	else
		keyWindow:notify("Failed", msg, 2)
	end
end, "verify_key")

while not getgenv().SCRIPT_KEY do
	task.wait(0.1)
end

keyWindow:notify("Authenticated", "Loading Pinte ou Busque Hub...", 2)
task.wait(1)
keyWindow:destroy()

-- ============================================================================
-- MAIN WINDOW
-- ============================================================================
local w = kyri.new("Pinte ou Busque Hub", {
	GameName = "PinteOuBusque",
	AutoLoad = "default",
})

if not w then return end

-- ============================================================================
-- SERVICES / HELPERS (Players, LocalPlayer, Camera already defined above)
-- ============================================================================
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")

local Shoot = game.ReplicatedStorage:FindFirstChild("Blaster")
	and game.ReplicatedStorage.Blaster:FindFirstChild("Remotes")
	and game.ReplicatedStorage.Blaster.Remotes:FindFirstChild("Shoot")

local function getChar(plr)
	plr = plr or LocalPlayer
	return plr and plr.Character
end

local function getHRP(plr)
	local c = getChar(plr)
	return c and c:FindFirstChild("HumanoidRootPart")
end

local function getHum(plr)
	local c = getChar(plr)
	return c and c:FindFirstChildOfClass("Humanoid")
end

-- ============================================================================
-- GLIDE TELEPORT (anti-teleport bypass)
-- ============================================================================
-- DISCOVERED VIA MCP: the server reverts large CFrame-teleports (>= ~50 studs
-- per tick) but ACCEPTS small steps (<= ~25 studs). So we "glide" in small
-- steps with a short wait -> we reach the destination without being pulled back.
-- This also makes Noclip work (the character is no longer pulled back).
local GLIDE_STEP = 18        -- studs per step (below the ~25-50 limit)
local GLIDE_DELAY = 0.04     -- wait between steps (seconds)

local function glideTo(targetPos, stepSize, stepDelay)
	stepSize = stepSize or GLIDE_STEP
	stepDelay = stepDelay or GLIDE_DELAY
	local hrp = getHRP()
	if not hrp then return false end
	local cur = hrp.Position
	local guard = 0
	while (cur - targetPos).Magnitude > stepSize and guard < 200 do
		local dir = (targetPos - cur)
		local nextPos = cur + dir.Unit * stepSize
		hrp.CFrame = CFrame.new(nextPos, targetPos)
		guard = guard + 1
		task.wait(stepDelay)
		cur = hrp.Position
	end
	-- final exact step
	hrp.CFrame = CFrame.new(targetPos)
	return true
end

local function isEnemy(plr)
	if plr == LocalPlayer then return false end
	local myTeam = LocalPlayer.Team and LocalPlayer.Team.Name
	local theirTeam = plr.Team and plr.Team.Name
	if not myTeam or not theirTeam then return false end
	-- Enemy = different team (and not Lobby)
	return theirTeam ~= "Lobby" and theirTeam ~= myTeam
end

local function getBlasterTool()
	local char = getChar()
	if char then
		for _, t in ipairs(char:GetChildren()) do
			if t:IsA("Tool") then return t end
		end
	end
	local bp = LocalPlayer:FindFirstChild("Backpack")
	if bp then
		for _, t in ipairs(bp:GetChildren()) do
			if t:IsA("Tool") then return t end
		end
	end
	return nil
end

-- ============================================================================
-- TABS
-- ============================================================================
local principal = w:tab("Main", "home")
local jogador    = w:tab("Player", "user")
local combate    = w:tab("Combat", "crosshair")
local espTab     = w:tab("ESP", "eye")
local visual     = w:tab("Visual", "sun")
local misc       = w:tab("Server", "server")

-- ============================================================================
-- MAIN - LIVE STATUS
-- ============================================================================
principal:section("Game Status")
principal:label("Loading status...")
principal:paragraph("How it works",
	"Pinte ou Busque: Hiders paint their head to camouflage and escape. " ..
	"Seekers use the Blaster to tag the Hiders. You are on team " ..
	tostring(LocalPlayer.Team and LocalPlayer.Team.Name or "Lobby") .. ".")

-- Periodically update status (low frequency to avoid spam)
task.spawn(function()
	while w and w._alive ~= false do
		task.wait(5)
		local ls = LocalPlayer:FindFirstChild("leaderstats")
		local function val(n) return ls and ls:FindFirstChild(n) and ls[n].Value or "?" end
		local teams = {}
		for _, t in ipairs(game:GetService("Teams"):GetTeams()) do
			table.insert(teams, t.Name .. ":" .. #t:GetPlayers())
		end
		pcall(function()
			w:notify("Status", string.format(
				"Money:%s Wins:%s Kills:%s | %s",
				val("Money"), val("Wins"), val("Kills"), table.concat(teams, " ")
			), 2)
		end)
	end
end)

principal:space()

principal:section("Quick Actions")
principal:button("Copy Job ID", function()
	local jid = game.JobId
	w:notify("Job ID", jid ~= "" and jid or "No job (private)", 3)
	if jid and jid ~= "" then
		pcall(function() setclipboard(jid) end)
	end
end)

principal:button("Rejoin Server", function()
	pcall(function()
		TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
	end)
	w:notify("Rejoin", "Trying to rejoin...", 3)
end)

principal:button("Destroy Panel", function()
	w:destroy()
end)

-- ============================================================================
-- PLAYER - MOVEMENT
-- ============================================================================
jogador:section("Movement")

jogador:slider("WalkSpeed", 16, 500, 16, function(val)
	local h = getHum()
	if h then h.WalkSpeed = val end
end, "walkspeed")

jogador:slider("JumpPower", 50, 500, 50, function(val)
	local h = getHum()
	if h then
		h.JumpPower = val
		if h:FindFirstChild("UseJumpPower") then
			h.UseJumpPower = true
		end
	end
end, "jumppower")

jogador:slider("Gravity", 0, 196, 196, function(val)
	Workspace.Gravity = val
end, "gravity")

jogador:space()

jogador:section("Movement Cheats")

local infJump = jogador:toggle("Infinite Jump", false, function() end, "inf_jump")
local noclip = jogador:toggle("Noclip", false, function() end, "noclip")
local flyTog = jogador:toggle("Fly", false, function(state)
	w:notify("Fly", state and "Enabled" or "Disabled", 2)
end, "fly")
local flySpeed = 50
jogador:slider("Fly Speed", 10, 300, 50, function(val) flySpeed = val end, "flyspeed")

-- Fly + Noclip + InfJump loop
local flying, flyBV, flyBG
local UIS = game:GetService("UserInputService")

RunService.Heartbeat:Connect(function(dt)
	local char = getChar()
	if not char then return end

	-- Noclip
	if noclip:get() then
		for _, p in ipairs(char:GetDescendants()) do
			if p:IsA("BasePart") and p.CanCollide then
				p.CanCollide = false
			end
		end
	end

	-- Infinite Jump
	if infJump:get() and UIS:IsKeyDown(Enum.KeyCode.Space) then
		local h = getHum()
		if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
	end

	-- Fly
	if flyTog:get() then
		local hrp = getHRP()
		if hrp then
			if not flyBV then
				flyBV = Instance.new("BodyVelocity")
				flyBV.MaxForce = Vector3.new(1e9, 1e9, 1e9)
				flyBV.Parent = hrp
				flyBG = Instance.new("BodyGyro")
				flyBG.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
				flyBG.P = 9e4
				flyBG.Parent = hrp
			end
			flyBG.CFrame = Camera.CFrame
			local dir = Vector3.new()
			if UIS:IsKeyDown(Enum.KeyCode.W) then dir += Camera.CFrame.LookVector end
			if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= Camera.CFrame.LookVector end
			if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= Camera.CFrame.RightVector end
			if UIS:IsKeyDown(Enum.KeyCode.D) then dir += Camera.CFrame.RightVector end
			if UIS:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0,1,0) end
			if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0,1,0) end
			flyBV.Velocity = dir.Unit * flySpeed
		end
	else
		if flyBV then flyBV:Destroy() flyBV = nil end
		if flyBG then flyBG:Destroy() flyBG = nil end
	end
end)

jogador:space()
jogador:section("Reset")
jogador:button("Reset Character", function()
	local h = getHum()
	if h then h.Health = 0 end
	w:notify("Reset", "Character reset", 2)
end)

-- ============================================================================
-- TELEPORT
-- ============================================================================
jogador:space()
jogador:section("Teleport")

local playerNames = {}
for _, p in ipairs(Players:GetPlayers()) do
	if p ~= LocalPlayer then table.insert(playerNames, p.Name) end
end
if #playerNames == 0 then table.insert(playerNames, "No other players") end

local tpTarget = jogador:dropdown("Target", playerNames, playerNames[1] or "—", function() end, "tp_target")

jogador:button("Refresh List", function()
	local n = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then table.insert(n, p.Name) end
	end
	if #n == 0 then n = {"No other players"} end
	tpTarget:set(n[1])
	w:notify("Teleport", "List refreshed", 2)
end)

local function resolveTarget()
	local name = tpTarget:get()
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Name == name then return p end
	end
	return nil
end

jogador:button("Teleport to Target", function()
	local t = resolveTarget()
	local thrp = t and getHRP(t)
	local hrp = getHRP()
	if hrp and thrp then
		w:notify("Teleport", "Gliding to " .. t.Name, 2)
		task.spawn(function()
			glideTo(thrp.Position + Vector3.new(0, 3, 0))
		end)
	else
		w:notify("Teleport", "Target or character unavailable", 3)
	end
end)

jogador:button("Pull Target to Me", function()
	local t = resolveTarget()
	local thrp = t and getHRP(t)
	local hrp = getHRP()
	if hrp and thrp then
		w:notify("Teleport", "Pulling " .. t.Name, 2)
		task.spawn(function()
			glideTo(thrp.Position, 18, 0.04) -- move you close
			thrp.CFrame = hrp.CFrame + Vector3.new(0, 3, 0)
		end)
	else
		w:notify("Teleport", "Target or character unavailable", 3)
	end
end)

-- ============================================================================
-- COIN COLLECTOR (teleport + natural walk)
-- ============================================================================
-- MECHANIC CONFIRMED VIA MCP:
--  - Coins are in Workspace.ClientCoins (Coin_1, Coin_2, ... MeshParts)
--  - Collected by CONTACT when passing over them (server-side proximity).
--  - CFrame-teleport alone does NOT collect; walking through with MoveTo collects.
--  - Real sync remote: ReplicatedStorage.Remotes.CoinSync
--    (used by the game; real collection is server-validated by contact).
-- Strategy: glide to each coin in small steps (accepted by server) -> natural pickup.
jogador:space()
jogador:section("Collect Coins")

local coinRunning = false

jogador:toggle("Auto Collect Coins", false, function(state)
	coinRunning = state
	if state then
		w:notify("Coins", "Starting collection...", 2)
		task.spawn(function()
			local char = getChar()
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if not hum then
				w:notify("Coins", "No character/Humanoid", 3)
				coinRunning = false
				return
			end
			local collected = 0
			while coinRunning do
				local cc = Workspace:FindFirstChild("ClientCoins")
				if cc then
					-- get live coins
					local coins = {}
					for _, c in ipairs(cc:GetChildren()) do
						if c:IsA("BasePart") and c.Parent == cc then
							table.insert(coins, c)
						end
					end
					if #coins == 0 then
						task.wait(0.5)
					else
						for _, coin in ipairs(coins) do
							if not coinRunning then break end
							if not coin.Parent then continue end
							local startMoney = (function()
								local ls = LocalPlayer:FindFirstChild("leaderstats")
								local m = ls and ls:FindFirstChild("Money")
								return m and m.Value or 0
							end)()
							-- glide to the coin (small steps accepted by server)
							-- collected by natural contact during the glide
							glideTo(coin.Position, 18, 0.03)
							-- wait for collection or short timeout
							local t = 0
							while t < 0.8 do
								task.wait(0.1)
								t = t + 0.1
								local now = (function()
									local ls = LocalPlayer:FindFirstChild("leaderstats")
									local m = ls and ls:FindFirstChild("Money")
									return m and m.Value or 0
								end)()
								if now > startMoney then
									collected = collected + (now - startMoney)
									break
								end
							end
						end
					end
				else
					task.wait(0.5)
				end
			end
			w:notify("Coins", "Collection stopped. Total: +" .. collected, 3)
		end)
	else
		w:notify("Coins", "Collection stopped", 2)
	end
end, "coin_auto")

jogador:button("Collect All Now", function()
	local char = getChar()
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local cc = Workspace:FindFirstChild("ClientCoins")
	if not hum or not cc then
		w:notify("Coins", "No character or coins", 3)
		return
	end
	local coins = {}
	for _, c in ipairs(cc:GetChildren()) do
		if c:IsA("BasePart") then table.insert(coins, c) end
	end
	if #coins == 0 then
		w:notify("Coins", "No active coins", 3)
		return
	end
	w:notify("Coins", "Collecting " .. #coins .. " coins...", 3)
	task.spawn(function()
		local collected = 0
		for _, coin in ipairs(coins) do
			if not coin.Parent then continue end
			local b = (function()
				local ls = LocalPlayer:FindFirstChild("leaderstats")
				local m = ls and ls:FindFirstChild("Money")
				return m and m.Value or 0
			end)()
			-- glide to the coin (faster than MoveTo and accepted by server)
			glideTo(coin.Position, 18, 0.03)
			local t = 0
			while t < 0.8 do
				task.wait(0.1)
				t = t + 0.1
				local now = (function()
					local ls = LocalPlayer:FindFirstChild("leaderstats")
					local m = ls and ls:FindFirstChild("Money")
					return m and m.Value or 0
				end)()
				if now > b then
					collected = collected + (now - b)
					break
				end
			end
		end
		w:notify("Coins", "Collected: +" .. collected .. " Money", 4)
	end)
end)

-- ============================================================================
-- COMBAT - AIMBOT + AUTO-SHOOT (confirmed Shoot remote)
-- ============================================================================
combate:section("Aimbot")

-- Right mouse button state (hold to aim) - declared before the callbacks
local aimHolding = false
local UIS = game:GetService("UserInputService")
UIS.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		aimHolding = true
	end
end)
UIS.InputEnded:Connect(function(input, gp)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		aimHolding = false
	end
end)

-- FOV circle drawing (Drawing API) - created BEFORE the toggles that use it
local aimFovCircle = Drawing.new("Circle")
aimFovCircle.Visible = false
aimFovCircle.Color = Color3.fromRGB(255, 80, 80)
aimFovCircle.Thickness = 1.5
aimFovCircle.Filled = false
aimFovCircle.NumSides = 64

-- Controls whether the circle appears (local boolean, default on)
local aimShowFov = true

-- Computes the pixel radius of the angular FOV relative to the camera's vertical FOV
local function updateFovCircle()
	local fovDeg = w.flags.aim_fov or 120
	local camFov = Camera.FieldOfView
	local halfH = Camera.ViewportSize.Y / 2
	local radiusPx = math.tan(math.rad(fovDeg) / 2) / math.tan(math.rad(camFov) / 2) * halfH
	aimFovCircle.Radius = math.clamp(radiusPx, 5, math.max(Camera.ViewportSize.X, Camera.ViewportSize.Y))
	aimFovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
end

-- Master: enables/disables the system. Aiming only engages while HOLDING right mouse.
local aimEnabled = combate:toggle("Enable Aimbot (hold RMB)", false, function(state)
	w:notify("Aimbot", state and "Armed - hold right mouse to aim" or "Disarmed", 3)
end, "aim_enabled")

combate:slider("Aimbot FOV", 5, 360, 120, function() end, "aim_fov")
combate:slider("Smoothness", 0, 100, 60, function() end, "aim_smooth", 0.1)
combate:dropdown("Target Part", {"Head", "HumanoidRootPart", "Torso"}, "Head", function() end, "aim_part")
combate:dropdown("Target Team", {"Enemies", "Seekers", "Hiders", "All"}, "Enemies", function() end, "aim_team")

combate:toggle("Show FOV (circle)", true, function(state)
	aimShowFov = state
	if not state then aimFovCircle.Visible = false end
end, "aim_showfov")

combate:space()
combate:section("Auto-Shoot (Blaster)")

combate:toggle("Auto-Shoot", false, function(state)
	if state and not Shoot then
		w:notify("Auto-Shoot", "Shoot remote not found!", 3)
	elseif state then
		w:notify("Auto-Shoot", "Enabled (requires Blaster equipped)", 3)
	end
end, "autoshoot")

combate:slider("Max Shoot Distance", 10, 500, 200, function() end, "shoot_range")

-- Function: find best target
local function getAimTarget()
	local teamMode = w.flags.aim_team
	local partName = w.flags.aim_part
	local best, bestScore = nil, math.huge
	local camPos = Camera.CFrame.Position
	local camLook = Camera.CFrame.LookVector
	local maxFovRad = math.rad(w.flags.aim_fov or 120)

	for _, p in ipairs(Players:GetPlayers()) do
		if p == LocalPlayer then continue end
		local theirTeam = p.Team and p.Team.Name
		if teamMode == "Seekers" and theirTeam ~= "Seeker" then continue end
		if teamMode == "Hiders" and theirTeam ~= "Hider" then continue end
		if teamMode == "Enemies" and not isEnemy(p) then continue end

		local char = getChar(p)
		if not char then continue end
		local part = char:FindFirstChild(partName) or char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
		if not part then continue end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hum or hum.Health <= 0 then continue end

		local dir = (part.Position - camPos)
		local dist = dir.Magnitude
		if dist > (w.flags.shoot_range or 200) then continue end
		dir = dir.Unit
		local ang = math.acos(math.clamp(dir:Dot(camLook), -1, 1))
		if ang > maxFovRad then continue end
		if ang < bestScore then
			bestScore = ang
			best = {part = part, hum = hum, dist = dist}
		end
	end
	return best
end

-- Function: fire the confirmed Shoot remote
local lastShot = 0
local function tryAutoShoot(target)
	if not Shoot then return end
	local tool = getBlasterTool()
	if not tool then return end
	local now = Workspace:GetServerTimeNow()
	if now - lastShot < 0.12 then return end
	lastShot = now
	local tagged = {["1"] = target.hum}
	pcall(function()
		Shoot:FireServer(now, tool, Camera.CFrame, tagged)
	end)
end

-- Aimbot + Auto-shoot loop (RenderStepped for camera smoothness)
RunService.RenderStepped:Connect(function(dt)
	-- FOV circle: shows whenever the "Show FOV" option is on
	-- (no need to arm aimbot, works as a live aim guide)
	if aimShowFov then
		updateFovCircle()
		aimFovCircle.Visible = true
	else
		aimFovCircle.Visible = false
	end

	-- Only aim if armed AND holding right mouse
	if not (aimEnabled:get() and aimHolding) then return end

	local target = getAimTarget()
	if not target then return end

	local smooth = (w.flags.aim_smooth or 60) / 100
	local desired = CFrame.new(Camera.CFrame.Position, target.part.Position)
	Camera.CFrame = Camera.CFrame:Lerp(desired, math.clamp(smooth, 0.05, 1))

	if w.flags.autoshoot and target.dist <= (w.flags.shoot_range or 200) then
		tryAutoShoot(target)
	end
end)

-- Simple hitbox extender (visually enlarges enemy parts)
combate:space()
combate:section("Hitbox")
combate:toggle("Hitbox Extender", false, function(state)
	local sz = state and Vector3.new(5,5,5) or nil
	for _, p in ipairs(Players:GetPlayers()) do
		if not isEnemy(p) then continue end
		local char = getChar(p)
		if not char then continue end
		for _, part in ipairs(char:GetChildren()) do
			if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
				if state then
					if not part:GetAttribute("__origSize") then
						part:SetAttribute("__origSize", part.Size)
					end
					part.Size = sz
				else
					local o = part:GetAttribute("__origSize")
					if o then part.Size = o end
				end
			end
		end
	end
	w:notify("Hitbox", state and "Enlarged" or "Restored", 2)
end, "hitbox")

-- ============================================================================
-- ESP (Drawing API)
-- ============================================================================
espTab:section("ESP Global")
local espOn = espTab:toggle("Enable ESP", false, function(state)
	w:notify("ESP", state and "On" or "Off", 2)
	if not state then clearEsp() end
end, "esp_on")

espTab:toggle("Show Name", true, function() end, "esp_name")
espTab:toggle("Show Distance", true, function() end, "esp_dist")
espTab:toggle("Show Team", true, function() end, "esp_team")
espTab:toggle("Box", true, function() end, "esp_box")
espTab:toggle("Tracer", false, function() end, "esp_tracer")
espTab:colorpicker("Enemy Color", Color3.fromRGB(255, 60, 60), function() end, "esp_color")
espTab:dropdown("Team Filter", {"All", "Enemies", "Seekers", "Hiders"}, "Enemies", function() end, "esp_filter")

-- Drawing ESP system
local drawings = {}
local function makeDraw()
	local d = {
		box = Drawing.new("Square"),
		name = Drawing.new("Text"),
		dist = Drawing.new("Text"),
		tracer = Drawing.new("Line"),
	}
	d.box.Thickness = 2
	d.box.Filled = false
	d.name.Size = 14
	d.name.Center = true
	d.dist.Size = 13
	d.dist.Center = true
	d.tracer.Thickness = 1
	return d
end

local function clearEsp()
	for _, d in pairs(drawings) do
		for _, v in pairs(d) do pcall(function() v:Remove() end) end
	end
	drawings = {}
end

local function worldToScreen(pos)
	local v, onScreen = Camera:WorldToViewportPoint(pos)
	return Vector2.new(v.X, v.Y), onScreen, v.Z
end

RunService.RenderStepped:Connect(function()
	if not espOn:get() then
		if next(drawings) then clearEsp() end
		return
	end

	local filter = w.flags.esp_filter
	local col = w.flags.esp_color or Color3.fromRGB(255, 60, 60)

	-- Players that should stay visible this frame (filter/disconnect)
	local seenThisFrame = {}

	for _, p in ipairs(Players:GetPlayers()) do
		if p == LocalPlayer then continue end
		local theirTeam = p.Team and p.Team.Name
		if filter == "Enemies" and not isEnemy(p) then continue end
		if filter == "Seekers" and theirTeam ~= "Seeker" then continue end
		if filter == "Hiders" and theirTeam ~= "Hider" then continue end

		-- Mark as active: avoids the drawing freezing at an old location
		seenThisFrame[p.Name] = true

		local char = getChar(p)
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local head = char and (char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart"))
		if not hrp or not head then
			if drawings[p.Name] then
				for _, v in pairs(drawings[p.Name]) do v.Visible = false end
			end
			continue
		end

		local d = drawings[p.Name] or makeDraw()
		drawings[p.Name] = d

		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health <= 0 then
			for _, v in pairs(d) do v.Visible = false end
			continue
		end

		local pos, onScreen = worldToScreen(head.Position)
		if not onScreen then
			for _, v in pairs(d) do v.Visible = false end
			continue
		end

		local rootPos, rootOn = worldToScreen(hrp.Position)
		local dist = (hrp.Position - Camera.CFrame.Position).Magnitude
		local size = math.clamp(2000 / dist, 12, 200)

		-- Box
		d.box.Visible = w.flags.esp_box
		d.box.Color = col
		d.box.Size = Vector2.new(size, size * 1.6)
		d.box.Position = Vector2.new(pos.X - size/2, pos.Y - size*0.8)

		-- Name
		d.name.Visible = w.flags.esp_name
		d.name.Color = col
		d.name.Text = p.Name
		d.name.Position = Vector2.new(pos.X, pos.Y - size*0.8 - 16)

		-- Distance
		d.dist.Visible = w.flags.esp_dist
		d.dist.Color = col
		d.dist.Text = math.floor(dist) .. "m"
		d.dist.Position = Vector2.new(pos.X, pos.Y + size*0.8 + 2)

		-- Tracer
		d.tracer.Visible = w.flags.esp_tracer
		d.tracer.Color = col
		d.tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
		d.tracer.To = pos
	end

	-- Sweep drawings of players that left the filter / disconnected
	-- (avoids "old locations" frozen on screen)
	for name, d in pairs(drawings) do
		if not seenThisFrame[name] then
			for _, v in pairs(d) do pcall(function() v:Remove() end) end
			drawings[name] = nil
		end
	end
end)

-- ============================================================================
-- VISUAL
-- ============================================================================
visual:section("Camera and Light")

visual:slider("Camera FOV", 50, 120, 70, function(val)
	Camera.FieldOfView = val
end, "fov")

visual:toggle("Fullbright", false, function(state)
	Lighting.Ambient = state and Color3.fromRGB(255,255,255) or Color3.fromRGB(0,0,0)
	Lighting.Brightness = state and 5 or 2
	Lighting.ClockTime = state and 14 or 12
	Lighting.FogEnd = state and 100000 or 1000
	w:notify("Visual", state and "Fullbright On" or "Restored", 2)
end, "fullbright")

visual:toggle("Remove Fog", false, function(state)
	Lighting.FogEnd = state and 100000 or 1000
	w:notify("Visual", state and "Fog removed" or "Fog restored", 2)
end, "nofog")

visual:space()
visual:section("Themes (KyriLib)")

local themes = {"kyri", "midnight", "rose", "forest", "slate"}
for _, tname in ipairs(themes) do
	visual:button(tname:gsub("^%l", string.upper), function()
		if kyri.presets and kyri.presets[tname] then
			w:apply_theme(kyri.presets[tname])
			w:notify("Theme", tname .. " applied!", 2)
		else
			w:notify("Theme", "Preset unavailable", 2)
		end
	end)
end

visual:space()
visual:section("Accent Color")
visual:colorpicker("Accent", kyri.theme.accent, function(c)
	w:accent(c)
end, "accent")

-- ============================================================================
-- SERVER / MISC
-- ============================================================================
misc:section("Online Players")

local playerListLabel = misc:label("Click to see players")

misc:button("List Players", function()
	local n = {}
	for _, p in ipairs(Players:GetPlayers()) do
		table.insert(n, p.Name .. " [" .. (p.Team and p.Team.Name or "?") .. "]")
	end
	w:notify("Server (" .. #n .. ")", table.concat(n, "\n"), 5)
end)

misc:space()
misc:section("Discord / Key")
misc:label("Discord: discord.gg/fdj3YhzJrS")
misc:label("Fixed key - no link shortener")
misc:label("Get the key on our Discord in the 'get key' channel!")
misc:label("Use Discord to test scripts and send feedback!")

misc:button("Copy Discord", function()
	pcall(function() setclipboard(DISCORD_LINK) end)
	w:notify("Discord", "Invite copied to clipboard!", 3)
end)

misc:space()
misc:section("Information")
misc:label("Place: " .. tostring(game.PlaceId))
misc:label("Your UserId: " .. tostring(LocalPlayer.UserId))

misc:space()
misc:section("Notifications")
misc:button("Notification Test", function()
	w:notify("Test", "Pinte ou Busque panel working!", 3)
end)

misc:button("Usage Tip", function()
	w:notify("Tip", "RightControl shows/hides the panel", 5)
end)

-- ============================================================================
-- FINAL NOTIFICATION
-- ============================================================================
w:notify("Success", "Pinte ou Busque Hub loaded!", 3)
w:notify("Tip", "RightControl = show/hide", 5)
