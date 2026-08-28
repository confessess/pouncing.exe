-- Pouncing.exe | Hitbox Module v5.0
-- Overlay-based hitbox expansion — original parts NEVER modified
-- No physics desync, no freezing, smooth visuals
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local Config = {
    Enabled = false,
    TeamCheck = false,
    ShowExpanded = true,
    HeadSize = 5,
    TorsoSize = 3,
    Transparency = 0.9,
    ExpandLimbs = false,
    LimbSize = 2,
    MaxDistance = 2000,
    Comprehensive = false,
    UpdateRate = 3,
    VisualStyle = "Transparent", -- "Transparent", "Outline", "Glow", "Wireframe"
    VisualColor = Color3.fromRGB(255, 105, 180),

    -- Internal
    OverlayMap = {}, -- player -> {partName -> overlayPart}
    Connections = {},
    CharacterMap = {},
    FrameCounter = 0,
}

-- ============================================================
-- Team Detection
-- ============================================================

local function IsTeammate(player)
    if player == LocalPlayer then return true end
    if LocalPlayer.Team and player.Team and LocalPlayer.Team == player.Team then return true end
    if LocalPlayer.TeamColor and player.TeamColor and LocalPlayer.TeamColor == player.TeamColor then return true end
    local myStats = LocalPlayer:FindFirstChild("leaderstats")
    local theirStats = player:FindFirstChild("leaderstats")
    if myStats and theirStats then
        local myTeam = myStats:FindFirstChild("Team") or myStats:FindFirstChild("team")
        local theirTeam = theirStats:FindFirstChild("Team") or theirStats:FindFirstChild("team")
        if myTeam and theirTeam and myTeam.Value == theirTeam.Value then return true end
    end
    return false
end

-- ============================================================
-- Helpers
-- ============================================================

local function GetDistance(pos)
    local cam = workspace.CurrentCamera
    if not cam then return math.huge end
    return (pos - cam.CFrame.Position).Magnitude
end

-- ============================================================
-- Part discovery
-- ============================================================

local function GetAllCharacterParts(character)
    local parts = {}
    for _, child in pairs(character:GetDescendants()) do
        if child:IsA("BasePart") then
            local parent = child.Parent
            local parentName = parent and parent.Name or ""
            local isAccessory = parentName:match("Accessory") or parentName:match("Hat") or parentName:match("Gear")
            local isTool = parentName:match("Tool") or (child.Name:match("Handle") and parent and parent:IsA("Tool"))
            local isEffect = child.Name:match("Trail") or child.Name:match("Particle") or child.Name:match("Beam")
            if not isAccessory and not isTool and not isEffect then
                table.insert(parts, child)
            end
        end
    end
    return parts
end

local function GetTargetParts(character)
    local parts = {}
    local head = character:FindFirstChild("Head")
    if head and head:IsA("BasePart") then parts.Head = head end

    local torsoNames = {"HumanoidRootPart", "UpperTorso", "Torso", "LowerTorso", "Body"}
    for _, name in ipairs(torsoNames) do
        local part = character:FindFirstChild(name)
        if part and part:IsA("BasePart") then
            parts.Torso = part
            break
        end
    end

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
            if part and part:IsA("BasePart") then
                table.insert(parts.Limbs, part)
            end
        end
    end

    return parts
end

-- ============================================================
-- Overlay creation & management
-- ============================================================

local function CreateOverlay(originalPart, multiplier)
    if not originalPart or not originalPart:IsA("BasePart") then return nil end
    if not originalPart.Parent then return nil end

    multiplier = math.clamp(multiplier, 1, 25)

    local overlay = Instance.new("Part")
    overlay.Name = "Pouncing_Hitbox_" .. originalPart.Name
    overlay.Size = originalPart.Size * multiplier
    overlay.CFrame = originalPart.CFrame
    overlay.Anchored = false
    overlay.CanCollide = false
    overlay.Massless = true
    overlay.CastShadow = false
    overlay.Parent = originalPart.Parent

    -- Weld to original part
    local weld = Instance.new("Weld")
    weld.Part0 = originalPart
    weld.Part1 = overlay
    weld.C0 = CFrame.new()
    weld.C1 = CFrame.new()
    weld.Parent = overlay

    -- Visual styling
    if Config.VisualStyle == "Transparent" then
        overlay.Transparency = Config.ShowExpanded and math.clamp(Config.Transparency, 0, 1) or 1
        overlay.Material = Enum.Material.ForceField
        overlay.Color = Config.VisualColor
    elseif Config.VisualStyle == "Outline" then
        overlay.Transparency = 1
        overlay.Material = Enum.Material.SmoothPlastic
        overlay.Color = Config.VisualColor
        local hl = Instance.new("SelectionBox")
        hl.Name = "Pouncing_Outline"
        hl.Adornee = overlay
        hl.Color3 = Config.VisualColor
        hl.LineThickness = 0.03
        hl.Parent = overlay
    elseif Config.VisualStyle == "Glow" then
        overlay.Transparency = 0.7
        overlay.Material = Enum.Material.Neon
        overlay.Color = Config.VisualColor
    elseif Config.VisualStyle == "Wireframe" then
        overlay.Transparency = 1
        local hl = Instance.new("SelectionBox")
        hl.Name = "Pouncing_Outline"
        hl.Adornee = overlay
        hl.Color3 = Config.VisualColor
        hl.LineThickness = 0.02
        hl.Parent = overlay
    end

    return overlay
end

local function UpdateOverlayVisual(overlay)
    if not overlay then return end

    if Config.VisualStyle == "Transparent" then
        overlay.Transparency = Config.ShowExpanded and math.clamp(Config.Transparency, 0, 1) or 1
        overlay.Material = Enum.Material.ForceField
        overlay.Color = Config.VisualColor
    elseif Config.VisualStyle == "Outline" then
        overlay.Transparency = 1
        local hl = overlay:FindFirstChild("Pouncing_Outline")
        if hl then
            hl.Color3 = Config.VisualColor
            hl.Visible = Config.ShowExpanded
        end
    elseif Config.VisualStyle == "Glow" then
        overlay.Transparency = Config.ShowExpanded and 0.7 or 1
        overlay.Material = Enum.Material.Neon
        overlay.Color = Config.VisualColor
    elseif Config.VisualStyle == "Wireframe" then
        overlay.Transparency = 1
        local hl = overlay:FindFirstChild("Pouncing_Outline")
        if hl then
            hl.Color3 = Config.VisualColor
            hl.Visible = Config.ShowExpanded
        end
    end
end

local function DestroyOverlay(overlay)
    if overlay then
        pcall(function() overlay:Destroy() end)
    end
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

    -- TEAM CHECK
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

    local function EnsureOverlay(originalPart, multiplier)
        if not originalPart or not originalPart:IsA("BasePart") then return end
        local key = originalPart
        if overlays[key] and overlays[key].Parent then
            -- Update visual only
            UpdateOverlayVisual(overlays[key])
            return
        end
        -- Create new overlay
        if overlays[key] then
            DestroyOverlay(overlays[key])
        end
        overlays[key] = CreateOverlay(originalPart, multiplier)
    end

    if Config.Comprehensive then
        local parts = GetAllCharacterParts(character)
        for _, part in ipairs(parts) do
            EnsureOverlay(part, Config.HeadSize)
        end
        -- Clean up overlays for parts that no longer exist
        for key, overlay in pairs(overlays) do
            if typeof(key) == "Instance" then
                local ok, parent = pcall(function() return key.Parent end)
                if not ok or not parent or parent ~= character then
                    DestroyOverlay(overlay)
                    overlays[key] = nil
                end
            end
        end
    else
        local parts = GetTargetParts(character)
        if parts.Head then EnsureOverlay(parts.Head, Config.HeadSize) end
        if parts.Torso then EnsureOverlay(parts.Torso, Config.TorsoSize) end
        if parts.Limbs then
            for _, limb in ipairs(parts.Limbs) do
                EnsureOverlay(limb, Config.LimbSize)
            end
        end
        -- Clean up old overlays
        local validKeys = {}
        if parts.Head then validKeys[parts.Head] = true end
        if parts.Torso then validKeys[parts.Torso] = true end
        if parts.Limbs then
            for _, limb in ipairs(parts.Limbs) do
                validKeys[limb] = true
            end
        end
        for key, overlay in pairs(overlays) do
            if not validKeys[key] then
                DestroyOverlay(overlay)
                overlays[key] = nil
            end
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
    if Config.FrameCounter % Config.UpdateRate ~= 0 then return end

    for _, player in pairs(Players:GetPlayers()) do
        pcall(function() UpdatePlayer(player) end)
    end
end

-- ============================================================
-- Character lifecycle
-- ============================================================

local function OnCharacterAdded(player, character)
    Config.CharacterMap[player] = character
    ClearPlayerOverlays(player)
    task.delay(0.1, function()
        if Config.Enabled then
            pcall(function() UpdatePlayer(player) end)
        end
    end)
end

local function OnCharacterRemoving(player, character)
    ClearPlayerOverlays(player)
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
    ClearPlayerOverlays(player)
    Config.CharacterMap[player] = nil
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
    -- Destroy ALL overlays
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
        -- Update all existing overlays
        for _, overlays in pairs(Config.OverlayMap) do
            for _, overlay in pairs(overlays) do
                UpdateOverlayVisual(overlay)
            end
        end
    elseif key == "HeadSize" then Config.HeadSize = math.clamp(value, 1, 25)
    elseif key == "TorsoSize" then Config.TorsoSize = math.clamp(value, 1, 25)
    elseif key == "Transparency" then 
        Config.Transparency = math.clamp(value, 0, 1)
        for _, overlays in pairs(Config.OverlayMap) do
            for _, overlay in pairs(overlays) do
                UpdateOverlayVisual(overlay)
            end
        end
    elseif key == "ExpandLimbs" then Config.ExpandLimbs = value
    elseif key == "LimbSize" then Config.LimbSize = math.clamp(value, 1, 25)
    elseif key == "MaxDistance" then Config.MaxDistance = value
    elseif key == "Comprehensive" then 
        Config.Comprehensive = value
        -- Clear and rebuild
        for player, _ in pairs(Config.OverlayMap) do
            ClearPlayerOverlays(player)
        end
    elseif key == "UpdateRate" then Config.UpdateRate = math.clamp(value, 1, 10)
    elseif key == "VisualStyle" then 
        Config.VisualStyle = value
        for _, overlays in pairs(Config.OverlayMap) do
            for _, overlay in pairs(overlays) do
                UpdateOverlayVisual(overlay)
            end
        end
    elseif key == "VisualColor" then 
        Config.VisualColor = value
        for _, overlays in pairs(Config.OverlayMap) do
            for _, overlay in pairs(overlays) do
                UpdateOverlayVisual(overlay)
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
    Config.HeadSize = 5
    Config.TorsoSize = 3
    Config.Transparency = 0.9
    Config.ExpandLimbs = false
    Config.LimbSize = 2
    Config.MaxDistance = 2000
    Config.Comprehensive = false
    Config.UpdateRate = 3
    Config.VisualStyle = "Transparent"
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
    Config.CharacterMap = {}
end

return Module