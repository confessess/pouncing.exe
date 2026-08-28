-- Pouncing.exe | Hitbox Module v7.0
-- Simple, reliable overlay hitbox expander
-- Creates welded transparent parts — always visible, never freezes
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local Config = {
    Enabled = false,
    TeamCheck = false,
    ShowExpanded = true,
    HitboxSize = 5,
    TargetParts = "Head",
    MaxDistance = 2000,

    -- Visuals
    VisualColor = Color3.fromRGB(255, 105, 180),

    -- Internal
    OverlayMap = {},
    Connections = {},
    FrameCounter = 0,
}

-- ============================================================
-- Team Detection
-- ============================================================

local function IsTeammate(player)
    if player == LocalPlayer then return true end
    if LocalPlayer.Team and player.Team and LocalPlayer.Team == player.Team then return true end
    if LocalPlayer.TeamColor and player.TeamColor and LocalPlayer.TeamColor == player.TeamColor then return true end
    return false
end

local function GetDistance(pos)
    local cam = workspace.CurrentCamera
    if not cam then return math.huge end
    return (pos - cam.CFrame.Position).Magnitude
end

-- ============================================================
-- Resolve parts to expand
-- ============================================================

local function GetPartsToExpand(character)
    local parts = {}
    local mode = Config.TargetParts

    if mode == "Head" then
        local p = character:FindFirstChild("Head")
        if p and p:IsA("BasePart") then table.insert(parts, p) end

    elseif mode == "Torso" then
        local names = {"UpperTorso", "Torso", "LowerTorso"}
        for _, n in ipairs(names) do
            local p = character:FindFirstChild(n)
            if p and p:IsA("BasePart") then table.insert(parts, p); break end
        end

    elseif mode == "HumanoidRootPart" then
        local p = character:FindFirstChild("HumanoidRootPart")
        if p and p:IsA("BasePart") then table.insert(parts, p) end

    elseif mode == "Head + Torso" then
        local h = character:FindFirstChild("Head")
        if h and h:IsA("BasePart") then table.insert(parts, h) end
        local names = {"UpperTorso", "Torso", "LowerTorso"}
        for _, n in ipairs(names) do
            local p = character:FindFirstChild(n)
            if p and p:IsA("BasePart") then table.insert(parts, p); break end
        end

    elseif mode == "Head + HRP" then
        local h = character:FindFirstChild("Head")
        if h and h:IsA("BasePart") then table.insert(parts, h) end
        local p = character:FindFirstChild("HumanoidRootPart")
        if p and p:IsA("BasePart") then table.insert(parts, p) end

    elseif mode == "All Major" then
        local names = {"Head", "HumanoidRootPart", "UpperTorso", "Torso", "LowerTorso"}
        for _, n in ipairs(names) do
            local p = character:FindFirstChild(n)
            if p and p:IsA("BasePart") then table.insert(parts, p) end
        end
    end

    return parts
end

-- ============================================================
-- Overlay management
-- ============================================================

local function DestroyOverlay(overlay)
    if overlay and overlay.Parent then
        pcall(function() overlay:Destroy() end)
    end
end

local function CreateOverlay(originalPart)
    if not originalPart or not originalPart:IsA("BasePart") then return nil end
    if not originalPart.Parent then return nil end

    local multiplier = math.clamp(Config.HitboxSize, 1, 25)
    local color = Config.VisualColor

    local overlay = Instance.new("Part")
    overlay.Name = "PouncingHB_" .. originalPart.Name
    overlay.Size = originalPart.Size * multiplier
    overlay.CFrame = originalPart.CFrame
    overlay.Anchored = false
    overlay.CanCollide = false
    overlay.Massless = true
    overlay.CastShadow = false
    overlay.Transparency = Config.ShowExpanded and 0.5 or 1
    overlay.Material = Enum.Material.ForceField
    overlay.Color = color
    overlay.Parent = originalPart.Parent

    -- Weld to original
    local weld = Instance.new("Weld")
    weld.Part0 = originalPart
    weld.Part1 = overlay
    weld.C0 = CFrame.new()
    weld.C1 = CFrame.new()
    weld.Parent = overlay

    return overlay
end

local function UpdateOverlay(overlay)
    if not overlay or not overlay.Parent then return false end
    overlay.Transparency = Config.ShowExpanded and 0.5 or 1
    overlay.Color = Config.VisualColor
    return true
end

local function ClearPlayerOverlays(player)
    local overlays = Config.OverlayMap[player]
    if not overlays then return end
    for _, overlay in pairs(overlays) do
        DestroyOverlay(overlay)
    end
    Config.OverlayMap[player] = nil
end

-- ============================================================
-- Update player
-- ============================================================

local function UpdatePlayer(player)
    if player == LocalPlayer then return end

    if Config.TeamCheck and IsTeammate(player) then
        ClearPlayerOverlays(player)
        return
    end

    local character = player.Character
    if not character then
        ClearPlayerOverlays(player)
        return
    end

    local hum = character:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then
        ClearPlayerOverlays(player)
        return
    end

    local root = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso")
    if root then
        local dist = GetDistance(root.Position)
        if dist > Config.MaxDistance then
            ClearPlayerOverlays(player)
            return
        end
    end

    if not Config.OverlayMap[player] then
        Config.OverlayMap[player] = {}
    end
    local overlays = Config.OverlayMap[player]

    local targetParts = GetPartsToExpand(character)
    local needed = {}
    for _, part in ipairs(targetParts) do
        needed[part] = true
    end

    -- Create/update
    for part, _ in pairs(needed) do
        local existing = overlays[part]
        if existing and existing.Parent then
            UpdateOverlay(existing)
        else
            if existing then DestroyOverlay(existing) end
            overlays[part] = CreateOverlay(part)
        end
    end

    -- Remove stale
    for part, overlay in pairs(overlays) do
        if not needed[part] then
            DestroyOverlay(overlay)
            overlays[part] = nil
        end
    end
end

-- ============================================================
-- Render loop
-- ============================================================

local RenderConnection = nil

local function OnRenderStep()
    if not Config.Enabled then return end
    Config.FrameCounter = Config.FrameCounter + 1
    if Config.FrameCounter % 3 ~= 0 then return end

    for _, player in pairs(Players:GetPlayers()) do
        pcall(function() UpdatePlayer(player) end)
    end
end

-- ============================================================
-- Character lifecycle
-- ============================================================

local function OnCharacterAdded(player, character)
    ClearPlayerOverlays(player)
    task.delay(0.1, function()
        if Config.Enabled then
            pcall(function() UpdatePlayer(player) end)
        end
    end)
end

local function OnCharacterRemoving(player, character)
    ClearPlayerOverlays(player)
end

local function HookPlayer(player)
    if player == LocalPlayer then return end
    if Config.Connections[player] then return end

    Config.Connections[player] = {
        Added = player.CharacterAdded:Connect(function(char)
            OnCharacterAdded(player, char)
        end),
        Removing = player.CharacterRemoving:Connect(function(char)
            OnCharacterRemoving(player, char)
        end),
    }

    if player.Character then
        OnCharacterAdded(player, player.Character)
    end
end

local function UnhookPlayer(player)
    local conns = Config.Connections[player]
    if conns then
        pcall(function() conns.Added:Disconnect() end)
        pcall(function() conns.Removing:Disconnect() end)
        Config.Connections[player] = nil
    end
    ClearPlayerOverlays(player)
end

-- ============================================================
-- Module API
-- ============================================================

local Module = {}

function Module.Init()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            pcall(function() HookPlayer(player) end)
        end
    end

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
    for player, overlays in pairs(Config.OverlayMap) do
        for _, overlay in pairs(overlays) do
            DestroyOverlay(overlay)
        end
    end
    Config.OverlayMap = {}
end

function Module.SetConfig(key, value)
    if key == "TeamCheck" then 
        Config.TeamCheck = value
        if value then
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and IsTeammate(player) then
                    ClearPlayerOverlays(player)
                end
            end
        end
    elseif key == "ShowExpanded" then 
        Config.ShowExpanded = value
        for _, overlays in pairs(Config.OverlayMap) do
            for _, overlay in pairs(overlays) do
                UpdateOverlay(overlay)
            end
        end
    elseif key == "HitboxSize" then 
        Config.HitboxSize = math.clamp(value, 1, 25)
        for player, _ in pairs(Config.OverlayMap) do
            ClearPlayerOverlays(player)
        end
    elseif key == "TargetParts" then 
        Config.TargetParts = value
        for player, _ in pairs(Config.OverlayMap) do
            ClearPlayerOverlays(player)
        end
    elseif key == "MaxDistance" then Config.MaxDistance = value
    elseif key == "VisualColor" then 
        Config.VisualColor = value
        for _, overlays in pairs(Config.OverlayMap) do
            for _, overlay in pairs(overlays) do
                UpdateOverlay(overlay)
            end
        end
    end
end

function Module.GetConfig()
    return Config
end

function Module.ResetConfig()
    Module.Disable()
    Config.TeamCheck = false
    Config.ShowExpanded = true
    Config.HitboxSize = 5
    Config.TargetParts = "Head"
    Config.MaxDistance = 2000
    Config.VisualColor = Color3.fromRGB(255, 105, 180)
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
end

return Module