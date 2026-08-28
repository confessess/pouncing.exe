-- Pouncing.exe | Utils Core v2.0
-- Shared utilities + Unified Hook Manager for collision-free __namecall/Raycast
-- ============================================================

local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

local Utils = {}

-- W2S (World to Screen)
function Utils.W2S(position)
    local point, onScreen = Camera:WorldToViewportPoint(position)
    return Vector2.new(point.X, point.Y), onScreen, point.Z
end

-- Distance between two positions
function Utils.Dist(a, b)
    return (a - b).Magnitude
end

-- Raycast with ignore list
function Utils.Raycast(origin, direction, ignoreList)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = ignoreList or {}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    return Workspace:Raycast(origin, direction, raycastParams)
end

-- Create Drawing object with props
function Utils.NewDrawing(type, props)
    local d = Drawing.new(type)
    for k, v in pairs(props or {}) do
        d[k] = v
    end
    return d
end

-- Safe drawing property set
function Utils.SetDrawing(obj, key, value)
    if obj then
        local ok = pcall(function()
            obj[key] = value
        end)
        return ok
    end
    return false
end

-- Safe drawing remove
function Utils.RemoveDrawing(obj)
    if obj then
        pcall(function()
            obj:Remove()
        end)
    end
end

-- Make Drawing helper (alias for compatibility)
function Utils.MakeDrawing(type, props)
    return Utils.NewDrawing(type, props)
end

-- Get box data for ESP
function Utils.GetBoxData(character)
    local root = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso")
    if not root then return nil end
    local s, extents = pcall(function() return character:GetExtentsSize() end)
    if not s or not extents then return nil end
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

-- Get 3D corners for 3D box ESP
function Utils.Get3DCorners(character)
    local root = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso")
    if not root then return nil end
    local s, extents = pcall(function() return character:GetExtentsSize() end)
    if not s or not extents then return nil end
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

-- 3D box edge connections
Utils.Box3DEdges = {
    {1,2},{2,3},{3,4},{4,1},
    {5,6},{6,7},{7,8},{8,5},
    {1,5},{2,6},{3,7},{4,8}
}

-- Skeleton bone connections
Utils.SkeletonConnections = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
    {"Torso", "Left Arm"}, {"Torso", "Right Arm"}, {"Torso", "Left Leg"}, {"Torso", "Right Leg"}, {"Torso", "Head"}
}

-- ============================================================
-- UNIFIED HOOK MANAGER
-- Allows multiple modules to hook __namecall / Raycast safely
-- ============================================================
local HookManager = {
    OriginalNamecall = nil,
    OriginalRaycast = nil,
    NamecallHandlers = {},
    RaycastHandlers = {},
    Hooked = false,
    Mt = nil
}

function HookManager:RegisterNamecallHandler(name, handler)
    self.NamecallHandlers[name] = handler
end

function HookManager:UnregisterNamecallHandler(name)
    self.NamecallHandlers[name] = nil
end

function HookManager:RegisterRaycastHandler(name, handler)
    self.RaycastHandlers[name] = handler
end

function HookManager:UnregisterRaycastHandler(name)
    self.RaycastHandlers[name] = nil
end

function HookManager:Install()
    if self.Hooked then return end
    self.Hooked = true

    -- Raycast hook
    local oldRaycast = Workspace.Raycast
    self.OriginalRaycast = oldRaycast
    Workspace.Raycast = function(ws, origin, direction, params, ...)
        local finalOrigin, finalDirection, finalParams = origin, direction, params
        for _, handler in pairs(self.RaycastHandlers) do
            local ok, newOrigin, newDirection, newParams = pcall(handler, finalOrigin, finalDirection, finalParams)
            if ok and newOrigin ~= nil then
                finalOrigin = newOrigin
                finalDirection = newDirection or finalDirection
                finalParams = newParams or finalParams
            end
        end
        return oldRaycast(ws, finalOrigin, finalDirection, finalParams, ...)
    end

    -- __namecall hook
    local ok, mt = pcall(getrawmetatable, game)
    if ok and mt then
        self.Mt = mt
        local oldNamecall = mt.__namecall
        if oldNamecall then
            self.OriginalNamecall = oldNamecall
            setreadonly(mt, false)
            mt.__namecall = newcclosure(function(self_obj, ...)
                local method = getnamecallmethod()
                local args = {...}
                local modified = false

                if method == "FireServer" or method == "InvokeServer" then
                    for _, handler in pairs(self.NamecallHandlers) do
                        local ok, newArgs, wasModified = pcall(handler, args, method, self_obj)
                        if ok and newArgs then
                            args = newArgs
                            if wasModified then modified = true end
                        end
                    end
                end

                if modified then
                    return oldNamecall(self_obj, unpack(args))
                else
                    return oldNamecall(self_obj, ...)
                end
            end)
            setreadonly(mt, true)
        end
    end
end

function HookManager:Uninstall()
    if not self.Hooked then return end
    if self.OriginalRaycast then Workspace.Raycast = self.OriginalRaycast end
    if self.Mt and self.OriginalNamecall then
        setreadonly(self.Mt, false)
        self.Mt.__namecall = self.OriginalNamecall
        setreadonly(self.Mt, true)
    end
    self.Hooked = false
    self.OriginalRaycast = nil
    self.OriginalNamecall = nil
    self.Mt = nil
end

Utils.HookManager = HookManager

return Utils