-- Pouncing.exe | Hitbox Module v1.0
-- Hitbox expander with size control, transparency, team check
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local Config = {
    Enabled = false,
    TeamCheck = true,
    ShowExpanded = true,
    HeadSize = 5,
    TorsoSize = 3,
    Transparency = 0.9,
    OriginalSizes = {},
    Connections = {}
}

local RenderConnection = nil

local function IsTeammate(player)
    if not LocalPlayer.Team or not player.Team then return false end
    return player.Team == LocalPlayer.Team
end

local function GetTargetParts(character)
    local parts = {}
    local head = character:FindFirstChild("Head")
    local torso = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
    if head then parts.Head = head end
    if torso then parts.Torso = torso end
    return parts
end

local function SaveOriginalSize(part)
    if not part or Config.OriginalSizes[part] then return end
    Config.OriginalSizes[part] = {
        Size = part.Size,
        Transparency = part.Transparency,
        CanCollide = part.CanCollide
    }
end

local function RestoreOriginalSize(part)
    if not part or not Config.OriginalSizes[part] then return end
    local orig = Config.OriginalSizes[part]
    part.Size = orig.Size
    part.Transparency = orig.Transparency
    part.CanCollide = orig.CanCollide
    Config.OriginalSizes[part] = nil
end

local function ExpandPart(part, multiplier)
    if not part then return end
    SaveOriginalSize(part)
    local orig = Config.OriginalSizes[part]
    part.Size = orig.Size * multiplier
    if Config.ShowExpanded then
        part.Transparency = Config.Transparency
    else
        part.Transparency = orig.Transparency
    end
    part.CanCollide = false
end

local function UpdatePlayer(player)
    if player == LocalPlayer then return end
    if Config.TeamCheck and IsTeammate(player) then return end

    local character = player.Character
    if not character then return end
    local hum = character:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end

    local parts = GetTargetParts(character)
    if parts.Head then ExpandPart(parts.Head, Config.HeadSize) end
    if parts.Torso then ExpandPart(parts.Torso, Config.TorsoSize) end
end

local function OnRenderStep()
    if not Config.Enabled then return end
    for _, player in pairs(Players:GetPlayers()) do
        pcall(function() UpdatePlayer(player) end)
    end
end

local function OnCharacterRemoving(character)
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            RestoreOriginalSize(part)
        end
    end
end

local Module = {}

function Module.Init()
    Config.Connections.PlayerRemoving = Players.PlayerRemoving:Connect(function(player)
        local char = player.Character
        if char then OnCharacterRemoving(char) end
    end)

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            player.CharacterRemoving:Connect(OnCharacterRemoving)
        end
    end

    Players.PlayerAdded:Connect(function(player)
        if player == LocalPlayer then return end
        player.CharacterRemoving:Connect(OnCharacterRemoving)
    end)
end

function Module.Enable()
    Config.Enabled = true
    if not RenderConnection then
        RenderConnection = RunService.RenderStepped:Connect(OnRenderStep)
    end
end

function Module.Disable()
    Config.Enabled = false
    if RenderConnection then
        RenderConnection:Disconnect()
        RenderConnection = nil
    end
    -- Restore all original sizes
    for part, _ in pairs(Config.OriginalSizes) do
        RestoreOriginalSize(part)
    end
end

function Module.SetConfig(key, value)
    if key == "TeamCheck" then Config.TeamCheck = value
    elseif key == "ShowExpanded" then Config.ShowExpanded = value
    elseif key == "HeadSize" then Config.HeadSize = math.clamp(value, 1, 20)
    elseif key == "TorsoSize" then Config.TorsoSize = math.clamp(value, 1, 20)
    elseif key == "Transparency" then Config.Transparency = math.clamp(value, 0, 1)
    end
end

function Module.GetConfig()
    return Config
end

function Module.ResetConfig()
    Module.Disable()
    Config.TeamCheck = true
    Config.ShowExpanded = true
    Config.HeadSize = 5
    Config.TorsoSize = 3
    Config.Transparency = 0.9
end

function Module.Cleanup()
    Module.Disable()
    for name, conn in pairs(Config.Connections) do
        if typeof(conn) == "RBXScriptConnection" then
            pcall(function() conn:Disconnect() end)
        end
    end
    Config.Connections = {}
end

return Module