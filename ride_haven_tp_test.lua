local LP = game:GetService("Players").LocalPlayer
local function pos()
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    return hrp and hrp.Position
end

local p1 = pos()
local R = { p1 = tostring(p1) }

pcall(function()
    local Warp = require(game.ReplicatedStorage.Modules.Warp)
    Warp.Client("Teleport"):Fire(false, "Beach")
end)
task.wait(2.5)
R.p2 = tostring(pos())
R.moved = p1 and pos() and (p1 - pos()).Magnitude or 0

pcall(function()
    game.ReplicatedStorage.Remotes.Gameplay.TeleportEvent:FireServer("Dealership")
end)
task.wait(2.5)
R.p3 = tostring(pos())
R.moved2 = p1 and pos() and (p1 - pos()).Magnitude or 0

print("[TP_TEST]", game:GetService("HttpService"):JSONEncode(R))
