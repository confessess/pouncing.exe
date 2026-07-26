
# ============================================================
# 2. UTILS/CORE.LUA - Shared utilities
# ============================================================
utils = '''-- ============================================================
-- Pouncing.exe | Utils Core
-- Shared utilities for all modules
-- ============================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Utils = {}

-- ============================================================
-- Drawing Helpers
-- ============================================================

function Utils.MakeDrawing(type, props)
    local success, obj = pcall(Drawing.new, type)
    if not success or not obj then return nil end
    for k, v in pairs(props or {}) do
        pcall(function() obj[k] = v end)
    end
    return obj
end

function Utils.SetDrawing(obj, key, value)
    if obj then
        pcall(function() obj[key] = value end)
    end
end

function Utils.RemoveDrawing(obj)
    if obj then
        pcall(function() obj:Remove() end)
    end
end

-- ============================================================
-- World-to-Screen
-- ============================================================

function Utils.W2S(position)
    local success, x, y, z = pcall(function()
        local v = Camera:WorldToViewportPoint(position)
        return v.X, v.Y, v.Z
    end)
    if success and z and z > 0 then
        return Vector2.new(x, y), true, z
    end
    return Vector2.new(-999, -999), false, 0
end

-- ============================================================
-- Character Helpers
-- ============================================================

function Utils.GetCharacter(player)
    return player and player.Character
end

function Utils.GetHumanoid(character)
    return character and character:FindFirstChildOfClass("Humanoid")
end

function Utils.GetRootPart(character)
    return character and (character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso"))
end

function Utils.IsAlive(character)
    local hum = Utils.GetHumanoid(character)
    return hum and hum.Health > 0
end

function Utils.GetTeam(player)
    return player and player.Team
end

function Utils.IsTeammate(player)
    if not LocalPlayer.Team or not player.Team then return false end
    return player.Team == LocalPlayer.Team
end

function Utils.GetDistance(position)
    return (position - Camera.CFrame.Position).Magnitude
end

-- ============================================================
-- Box Calculations
-- ============================================================

function Utils.GetBoxData(character)
    local root = Utils.GetRootPart(character)
    if not root then return nil end

    local success, extents = pcall(function() return character:GetExtentsSize() end)
    if not success or not extents then return nil end

    local size = extents * 1.1
    local topPos = root.Position + Vector3.new(0, size.Y / 2, 0)
    local botPos = root.Position - Vector3.new(0, size.Y / 2, 0)

    local topScr, topVis, topZ = Utils.W2S(topPos)
    local botScr, botVis, botZ = Utils.W2S(botPos)

    if (not topVis and not botVis) or topZ <= 0 or botZ <= 0 then return nil end

    local h = math.abs(botScr.Y - topScr.Y)
    local w = h * 0.6
    if h <= 1 or w <= 1 then return nil end

    return {
        TL = Vector2.new(topScr.X - w / 2, topScr.Y),
        BR = Vector2.new(topScr.X + w / 2, botScr.Y),
        Size = Vector2.new(w, h),
        Center = Vector2.new(topScr.X, (topScr.Y + botScr.Y) / 2),
        Pos = root.Position,
        Extents = extents
    }
end

function Utils.Get3DCorners(character)
    local root = Utils.GetRootPart(character)
    if not root then return nil end

    local success, extents = pcall(function() return character:GetExtentsSize() end)
    if not success or not extents then return nil end

    local p = root.Position
    local hx, hy, hz = extents.X / 2, extents.Y / 2, extents.Z / 2

    local corners = {
        p + Vector3.new(-hx, -hy, -hz), p + Vector3.new(hx, -hy, -hz),
        p + Vector3.new(hx, -hy, hz), p + Vector3.new(-hx, -hy, hz),
        p + Vector3.new(-hx, hy, -hz), p + Vector3.new(hx, hy, -hz),
        p + Vector3.new(hx, hy, hz), p + Vector3.new(-hx, hy, hz)
    }

    local screenCorners = {}
    for i = 1, 8 do
        local sp, vis, z = Utils.W2S(corners[i])
        if not vis or z <= 0 then return nil end
        screenCorners[i] = sp
    end
    return screenCorners
end

Utils.Box3DEdges = {
    {1,2},{2,3},{3,4},{4,1},
    {5,6},{6,7},{7,8},{8,5},
    {1,5},{2,6},{3,7},{4,8}
}

-- ============================================================
-- Skeleton Data
-- ============================================================

Utils.SkeletonConnections = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
    {"Torso", "Left Arm"}, {"Torso", "Right Arm"}, {"Torso", "Left Leg"}, {"Torso", "Right Leg"}, {"Torso", "Head"}
}

-- ============================================================
-- Tween Helpers
-- ============================================================

function Utils.Tween(obj, props, duration, style, direction)
    duration = duration or 0.3
    style = style or Enum.EasingStyle.Quad
    direction = direction or Enum.EasingDirection.Out
    TweenService:Create(obj, TweenInfo.new(duration, style, direction), props):Play()
end

-- ============================================================
-- Input Helpers
-- ============================================================

function Utils.DragFrame(frame, handle)
    handle = handle or frame
    local dragging = false
    local dragStart = nil
    local startPos = nil

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
            dragStart = nil
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ============================================================
-- Color Helpers
-- ============================================================

function Utils.LerpColor(a, b, t)
    return Color3.new(
        a.R + (b.R - a.R) * t,
        a.G + (b.G - a.G) * t,
        a.B + (b.B - a.B) * t
    )
end

function Utils.ColorToHex(color)
    return string.format("#%02X%02X%02X",
        math.floor(color.R * 255),
        math.floor(color.G * 255),
        math.floor(color.B * 255)
    )
end

-- ============================================================
-- Player Events
-- ============================================================

function Utils.OnPlayerAdded(callback)
    for _, p in pairs(Players:GetPlayers()) do
        task.spawn(function() callback(p) end)
    end
    return Players.PlayerAdded:Connect(callback)
end

function Utils.OnPlayerRemoving(callback)
    return Players.PlayerRemoving:Connect(callback)
end

function Utils.OnCharacterAdded(player, callback)
    if player.Character then
        task.spawn(function() callback(player.Character) end)
    end
    return player.CharacterAdded:Connect(callback)
end

return Utils
'''

with open(f"{output_dir}/utils/core.lua", "w") as f:
    f.write(utils)

print("utils/core.lua written")
