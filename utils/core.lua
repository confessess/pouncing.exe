-- Pouncing.exe | Utils Core v3.0
-- Shared utilities + Unified Hook Manager
-- Added: FindPartOnRay hooks, __index hooks, handler priority system
-- ============================================================

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
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
-- UNIFIED HOOK MANAGER v3.0
-- ============================================================
local HookManager = {
    -- Raycast
    OriginalRaycast = nil,
    RaycastHandlers = {},

    -- FindPartOnRay family
    OriginalFindPartOnRay = nil,
    OriginalFindPartOnRayWithIgnoreList = nil,
    OriginalFindPartOnRayWithWhitelist = nil,
    FindPartOnRayHandlers = {},

    -- __namecall
    OriginalNamecall = nil,
    NamecallHandlers = {},
    Mt = nil,

    -- __index (for Mouse.Hit, Mouse.Target, etc.)
    OriginalIndex = nil,
    IndexHandlers = {},

    Hooked = false,
}

-- Priority-based handler iteration
local function GetSortedHandlers(handlerTable)
    local sorted = {}
    for name, data in pairs(handlerTable) do
        if type(data) == "table" and data.handler then
            table.insert(sorted, {name = name, handler = data.handler, priority = data.priority or 0})
        elseif type(data) == "function" then
            table.insert(sorted, {name = name, handler = data, priority = 0})
        end
    end
    table.sort(sorted, function(a, b) return a.priority > b.priority end)
    return sorted
end

-- Raycast handlers
function HookManager:RegisterRaycastHandler(name, handler, priority)
    self.RaycastHandlers[name] = {handler = handler, priority = priority or 0}
end
function HookManager:UnregisterRaycastHandler(name)
    self.RaycastHandlers[name] = nil
end

-- FindPartOnRay handlers
function HookManager:RegisterFindPartOnRayHandler(name, handler, priority)
    self.FindPartOnRayHandlers[name] = {handler = handler, priority = priority or 0}
end
function HookManager:UnregisterFindPartOnRayHandler(name)
    self.FindPartOnRayHandlers[name] = nil
end

-- Namecall handlers
function HookManager:RegisterNamecallHandler(name, handler, priority)
    self.NamecallHandlers[name] = {handler = handler, priority = priority or 0}
end
function HookManager:UnregisterNamecallHandler(name)
    self.NamecallHandlers[name] = nil
end

-- Index handlers
function HookManager:RegisterIndexHandler(name, handler, priority)
    self.IndexHandlers[name] = {handler = handler, priority = priority or 0}
end
function HookManager:UnregisterIndexHandler(name)
    self.IndexHandlers[name] = nil
end

-- ============================================================
-- Install all hooks
-- ============================================================
function HookManager:Install()
    if self.Hooked then return end
    self.Hooked = true

    local LocalPlayer = Players.LocalPlayer

    -- Raycast hook (direct function replacement)
    local oldRaycast = Workspace.Raycast
    self.OriginalRaycast = oldRaycast
    Workspace.Raycast = function(ws, origin, direction, params, ...)
        local finalOrigin, finalDirection, finalParams = origin, direction, params
        for _, entry in ipairs(GetSortedHandlers(self.RaycastHandlers)) do
            local ok, newOrigin, newDirection, newParams = pcall(entry.handler, finalOrigin, finalDirection, finalParams)
            if ok and newOrigin ~= nil then
                finalOrigin = newOrigin
                finalDirection = newDirection or finalDirection
                finalParams = newParams or finalParams
            end
        end
        return oldRaycast(ws, finalOrigin, finalDirection, finalParams, ...)
    end

    -- FindPartOnRay hooks
    local function HookFindPartOnRay(methodName, original)
        if not original then return nil end
        return function(ws, ray, ...)
            local finalRay = ray
            for _, entry in ipairs(GetSortedHandlers(self.FindPartOnRayHandlers)) do
                local ok, newRay = pcall(entry.handler, finalRay, methodName, ...)
                if ok and newRay ~= nil then
                    finalRay = newRay
                end
            end
            return original(ws, finalRay, ...)
        end
    end

    self.OriginalFindPartOnRay = Workspace.FindPartOnRay
    self.OriginalFindPartOnRayWithIgnoreList = Workspace.FindPartOnRayWithIgnoreList
    self.OriginalFindPartOnRayWithWhitelist = Workspace.FindPartOnRayWithWhitelist

    Workspace.FindPartOnRay = HookFindPartOnRay("FindPartOnRay", self.OriginalFindPartOnRay)
    Workspace.FindPartOnRayWithIgnoreList = HookFindPartOnRay("FindPartOnRayWithIgnoreList", self.OriginalFindPartOnRayWithIgnoreList)
    Workspace.FindPartOnRayWithWhitelist = HookFindPartOnRay("FindPartOnRayWithWhitelist", self.OriginalFindPartOnRayWithWhitelist)

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
                    for _, entry in ipairs(GetSortedHandlers(self.NamecallHandlers)) do
                        local ok, newArgs, wasModified = pcall(entry.handler, args, method, self_obj)
                        if ok and newArgs then
                            args = newArgs
                            if wasModified then modified = true end
                        end
                    end
                end

                -- Also catch FindPartOnRay via __namecall
                if method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist" then
                    local ray = args[1]
                    if ray and typeof(ray) == "Ray" then
                        local finalRay = ray
                        for _, entry in ipairs(GetSortedHandlers(self.FindPartOnRayHandlers)) do
                            local ok, newRay = pcall(entry.handler, finalRay, method, unpack(args, 2))
                            if ok and newRay ~= nil then
                                finalRay = newRay
                            end
                        end
                        if finalRay ~= ray then
                            args[1] = finalRay
                            modified = true
                        end
                    end
                end

                -- Catch Raycast via __namecall too
                if method == "Raycast" then
                    local origin = args[1]
                    local direction = args[2]
                    local params = args[3]
                    if origin and direction then
                        local finalOrigin, finalDirection, finalParams = origin, direction, params
                        for _, entry in ipairs(GetSortedHandlers(self.RaycastHandlers)) do
                            local ok, newOrigin, newDirection, newParams = pcall(entry.handler, finalOrigin, finalDirection, finalParams)
                            if ok and newOrigin ~= nil then
                                finalOrigin = newOrigin
                                finalDirection = newDirection or finalDirection
                                finalParams = newParams or finalParams
                            end
                        end
                        if finalOrigin ~= origin or finalDirection ~= direction then
                            args[1] = finalOrigin
                            args[2] = finalDirection
                            args[3] = finalParams
                            modified = true
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

    -- __index hook (for Mouse.Hit, Mouse.Target, etc.)
    local ok2, mt2 = pcall(getrawmetatable, game)
    if ok2 and mt2 then
        local oldIndex = mt2.__index
        if oldIndex then
            self.OriginalIndex = oldIndex
            setreadonly(mt2, false)
            mt2.__index = newcclosure(function(self_obj, key)
                for _, entry in ipairs(GetSortedHandlers(self.IndexHandlers)) do
                    local ok, result = pcall(entry.handler, self_obj, key)
                    if ok and result ~= nil then
                        return result
                    end
                end
                return oldIndex(self_obj, key)
            end)
            setreadonly(mt2, true)
        end
    end
end

function HookManager:Uninstall()
    if not self.Hooked then return end

    if self.OriginalRaycast then Workspace.Raycast = self.OriginalRaycast end
    if self.OriginalFindPartOnRay then Workspace.FindPartOnRay = self.OriginalFindPartOnRay end
    if self.OriginalFindPartOnRayWithIgnoreList then Workspace.FindPartOnRayWithIgnoreList = self.OriginalFindPartOnRayWithIgnoreList end
    if self.OriginalFindPartOnRayWithWhitelist then Workspace.FindPartOnRayWithWhitelist = self.OriginalFindPartOnRayWithWhitelist end

    if self.Mt and self.OriginalNamecall then
        setreadonly(self.Mt, false)
        self.Mt.__namecall = self.OriginalNamecall
        setreadonly(self.Mt, true)
    end

    if self.Mt and self.OriginalIndex then
        setreadonly(self.Mt, false)
        self.Mt.__index = self.OriginalIndex
        setreadonly(self.Mt, true)
    end

    self.Hooked = false
    self.OriginalRaycast = nil
    self.OriginalNamecall = nil
    self.OriginalIndex = nil
    self.Mt = nil
end

Utils.HookManager = HookManager

return Utils