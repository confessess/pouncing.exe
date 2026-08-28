-- Pouncing.exe | Hitbox Module v2.0
-- Battle-tested hitbox expander for Arsenal, Da Hood, Zee Hood
-- Handles R6/R15, MeshParts, server reconciliation, character respawns
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
    ExpandLimbs = false,
    LimbSize = 2,
    MaxDistance = 2000,

    -- Internal
    OriginalSizes = {},
    Connections = {},
    CharacterMap = {}, -- maps Player -> Character (to detect respawns)
}

-- ============================================================
-- Helpers
-- ============================================================

local function IsTeammate(player)
    if not LocalPlayer.Team or not player.Team then return false end
    return player.Team == LocalPlayer.Team
end

local function IsValidPart(part)
    if not part then return false end
    if typeof(part) ~= "Instance" then return false end
    if not part:IsA("BasePart") then return false end
    local s = pcall(function() return part.Size end)
    return s
end

local function GetDistance(pos)
    local cam = workspace.CurrentCamera
    if not cam then return math.huge end
    return (pos - cam.CFrame.Position).Magnitude
end

-- ============================================================
-- Part discovery — handles R6, R15, and custom rigs
-- ============================================================

local function GetTargetParts(character)
    local parts = {}

    -- Head (always priority #1)
    local head = character:FindFirstChild("Head")
    if head and IsValidPart(head) then parts.Head = head end

    -- Torso — try multiple names for R6/R15 compatibility
    local torsoNames = {"HumanoidRootPart", "UpperTorso", "Torso", "LowerTorso", "Body"}
    for _, name in ipairs(torsoNames) do
        local part = character:FindFirstChild(name)
        if part and IsValidPart(part) then
            parts.Torso = part
            break
        end
    end

    -- Limbs (optional)
    if Config.ExpandLimbs then
        local limbNames = {
            "LeftUpperArm", "LeftLowerArm", "LeftHand",
            "RightUpperArm", "RightLowerArm", "RightHand",
            "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
            "RightUpperLeg", "RightLowerLeg", "RightFoot",
            "Left Arm", "Right Arm", "Left Leg", "Right Leg"
        }
        parts.Limbs = {}
        for _, name in ipairs(limbNames) do
            local part = character:FindFirstChild(name)
            if part and IsValidPart(part) then
                table.insert(parts.Limbs, part)
            end
        end
    end

    return parts
end

-- ============================================================
-- Size save / restore
-- ============================================================

local function SaveOriginal(part)
    if not IsValidPart(part) then return end
    if Config.OriginalSizes[part] then return end
    local ok, size = pcall(function() return part.Size end)
    if not ok then return end
    local ok2, trans = pcall(function() return part.Transparency end)
    if not ok2 then trans = 0 end
    local ok3, collide = pcall(function() return part.CanCollide end)
    if not ok3 then collide = true end
    local ok4, massless = pcall(function() return part.Massless end)
    if not ok4 then massless = false end

    Config.OriginalSizes[part] = {
        Size = size,
        Transparency = trans,
        CanCollide = collide,
        Massless = massless,
    }
end

local function RestorePart(part)
    if not IsValidPart(part) then return end
    local orig = Config.OriginalSizes[part]
    if not orig then return end
    pcall(function()
        part.Size = orig.Size
        part.Transparency = orig.Transparency
        part.CanCollide = orig.CanCollide
        part.Massless = orig.Massless
    end)
    Config.OriginalSizes[part] = nil
end

local function ClearCharacter(character)
    -- Remove all OriginalSizes entries belonging to this character
    -- (don't try to restore — parts are being destroyed)
    for part, _ in pairs(Config.OriginalSizes) do
        if typeof(part) == "Instance" then
            local ok, parent = pcall(function() return part.Parent end)
            if ok and parent == character then
                Config.OriginalSizes[part] = nil
            end
        end
    end
end

-- ============================================================
-- Expansion
-- ============================================================

local function ExpandPart(part, multiplier)
    if not IsValidPart(part) then return end
    SaveOriginal(part)

    local orig = Config.OriginalSizes[part]
    if not orig then return end

    -- Clamp multiplier to prevent physics engine death
    multiplier = math.clamp(multiplier, 1, 25)

    local newSize = orig.Size * multiplier

    pcall(function()
        part.Size = newSize
        part.Massless = true
        part.CanCollide = false
        if Config.ShowExpanded then
            part.Transparency = math.clamp(Config.Transparency, 0, 1)
        else
            part.Transparency = orig.Transparency
        end
    end)
end

local function UpdatePlayer(player)
    if player == LocalPlayer then return end
    if Config.TeamCheck and IsTeammate(player) then return end

    local character = player.Character
    if not character then return end

    -- Wait for character to be ready
    local hum = character:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if hum.Health <= 0 then return end

    -- Distance check (performance + stealth)
    local root = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso")
    if root then
        local dist = GetDistance(root.Position)
        if dist > Config.MaxDistance then return end
    end

    local parts = GetTargetParts(character)

    if parts.Head then
        ExpandPart(parts.Head, Config.HeadSize)
    end

    if parts.Torso then
        ExpandPart(parts.Torso, Config.TorsoSize)
    end

    if parts.Limbs then
        for _, limb in ipairs(parts.Limbs) do
            ExpandPart(limb, Config.LimbSize)
        end
    end
end

-- ============================================================
-- Render loop — re-applies every frame to beat server reconciliation
-- ============================================================

local RenderConnection = nil

local function OnRenderStep()
    if not Config.Enabled then return end
    for _, player in pairs(Players:GetPlayers()) do
        pcall(function() UpdatePlayer(player) end)
    end
end

-- ============================================================
-- Character lifecycle
-- ============================================================

local function OnCharacterAdded(player, character)
    -- Clear any old entries for this player
    Config.CharacterMap[player] = character

    -- When character loads, wait a tick then expand
    task.delay(0.1, function()
        if Config.Enabled then
            pcall(function() UpdatePlayer(player) end)
        end
    end)
end

local function OnCharacterRemoving(player, character)
    ClearCharacter(character)
    if Config.CharacterMap[player] == character then
        Config.CharacterMap[player] = nil
    end
end

local function HookPlayer(player)
    if player == LocalPlayer then return end
    if Config.Connections[player] then return end

    local charAddedConn = player.CharacterAdded:Connect(function(char)
        OnCharacterAdded(player, char)
    end)

    local charRemovingConn = player.CharacterRemoving:Connect(function(char)
        OnCharacterRemoving(player, char)
    end)

    Config.Connections[player] = {
        Added = charAddedConn,
        Removing = charRemovingConn,
    }

    -- If they already have a character, hook it now
    if player.Character then
        OnCharacterAdded(player, player.Character)
    end
end

local function UnhookPlayer(player)
    local conns = Config.Connections[player]
    if conns then
        if conns.Added then pcall(function() conns.Added:Disconnect() end) end
        if conns.Removing then pcall(function() conns.Removing:Disconnect() end) end
        Config.Connections[player] = nil
    end
    if player.Character then
        ClearCharacter(player.Character)
    end
    Config.CharacterMap[player] = nil
end

-- ============================================================
-- Module API
-- ============================================================

local Module = {}

function Module.Init()
    -- Hook all existing players
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            pcall(function() HookPlayer(player) end)
        end
    end

    -- Hook future players
    Config.Connections.PlayerAdded = Players.PlayerAdded:Connect(function(player)
        if player ~= LocalPlayer then
            pcall(function() HookPlayer(player) end)
        end
    end)

    Config.Connections.PlayerRemoving = Players.PlayerRemoving:Connect(function(player)
        pcall(function() UnhookPlayer(player) end)
    end)
end

function Module.Enable()
    Config.Enabled = true
    if not RenderConnection then
        RenderConnection = RunService.RenderStepped:Connect(OnRenderStep)
    end
    -- Force expand all visible players immediately
    for _, player in pairs(Players:GetPlayers()) do
        pcall(function() UpdatePlayer(player) end)
    end
end

function Module.Disable()
    Config.Enabled = false
    if RenderConnection then
        RenderConnection:Disconnect()
        RenderConnection = nil
    end

    -- Restore ALL expanded parts
    for part, orig in pairs(Config.OriginalSizes) do
        pcall(function() RestorePart(part) end)
    end
    Config.OriginalSizes = {}
end

function Module.SetConfig(key, value)
    if key == "TeamCheck" then Config.TeamCheck = value
    elseif key == "ShowExpanded" then Config.ShowExpanded = value
    elseif key == "HeadSize" then Config.HeadSize = math.clamp(value, 1, 25)
    elseif key == "TorsoSize" then Config.TorsoSize = math.clamp(value, 1, 25)
    elseif key == "Transparency" then Config.Transparency = math.clamp(value, 0, 1)
    elseif key == "ExpandLimbs" then Config.ExpandLimbs = value
    elseif key == "LimbSize" then Config.LimbSize = math.clamp(value, 1, 25)
    elseif key == "MaxDistance" then Config.MaxDistance = value
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
    Config.ExpandLimbs = false
    Config.LimbSize = 2
    Config.MaxDistance = 2000
end

function Module.Cleanup()
    Module.Disable()

    for player, _ in pairs(Config.Connections) do
        if typeof(player) == "Instance" and player:IsA("Player") then
            pcall(function() UnhookPlayer(player) end)
        end
    end

    if Config.Connections.PlayerAdded then
        pcall(function() Config.Connections.PlayerAdded:Disconnect() end)
    end
    if Config.Connections.PlayerRemoving then
        pcall(function() Config.Connections.PlayerRemoving:Disconnect() end)
    end

    Config.Connections = {}
    Config.CharacterMap = {}
    Config.OriginalSizes = {}
end

return Module