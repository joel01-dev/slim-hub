-- KyriLib UI loader
local kyri = loadstring(game:HttpGet("https://kyrilib.dev/kyrilib/"))()

-- Junkie key system backend
local Junkie = loadstring(game:HttpGet("https://jnkie.com/sdk/library.lua"))()
Junkie.service = "Slim Hub"
Junkie.identifier = "1140699"
Junkie.provider = "Key System"

-- Key verification via Junkie
local function Verify(key)
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

local function Copy()
    local link = Junkie.get_key_link()
    if setclipboard then setclipboard(link) end
    return link
end

-- Create window (no native KeySystem since we use Junkie's external API)
local w = kyri.new("Slim Hub", {
    GameName = "ChadDevelopment",
    AutoLoad = "default",
    Theme = {
        accent = Color3.fromRGB(130, 80, 255),
        bg = Color3.fromRGB(15, 15, 20),
        container = Color3.fromRGB(20, 20, 28),
        element = Color3.fromRGB(28, 28, 38),
        hover = Color3.fromRGB(35, 35, 48),
        active = Color3.fromRGB(130, 80, 255),
        text = Color3.fromRGB(240, 240, 250),
        subtext = Color3.fromRGB(160, 160, 180),
        border = Color3.fromRGB(40, 40, 55),
    }
})

-- Custom key input tab
local keyTab = w:tab("Key", "key")

keyTab:section("Authentication")
keyTab:paragraph("Enter your key", "Get your key from the Discord link below, paste it in the input, and click Verify.")

keyTab:button("Copy Discord Link", function()
    if setclipboard then setclipboard("https://discord.gg/MfRB5gAQ9N") end
    w:notify("Copied", "Discord link copied!", 2)
end, "copy_discord")

local keyInput = keyTab:input("Your Key", "Paste key here...", function()
    -- Live validation optional
end, "user_key")

keyTab:space(4)

keyTab:button("Verify Key", function()
    local key = keyInput.input.Text
    if not key or key == "" then
        w:notify("Error", "Please enter a key", 2)
        return
    end

    local ok, msg = Verify(key)
    if ok then
        w:notify("Success", msg, 3)
    else
        w:notify("Failed", msg, 2)
    end
end, "verify_key")

keyTab:button("Copy Key Link", function()
    Copy()
    w:notify("Copied", "Link copied to clipboard!", 2)
end, "copy_link")

-- Wait for authentication
while not getgenv().SCRIPT_KEY do
    task.wait(0.1)
end

w:notify("Authenticated", "Loading script...", 3)
