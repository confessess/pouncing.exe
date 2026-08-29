-- Pouncing.exe | Utils Core v3.4
-- Shared utilities + Unified Hook Manager
-- CRITICAL FIX: __namecall hook now calls getnamecallmethod() FIRST
-- Uses unpack (not table.unpack) for Lua 5.1 compatibility
-- Only repacks args when modified; passes ... directly for unmodified calls
-- ============================================================

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local Camera = Workspace.CurrentCamera

local Utils = {}

function Utils.W2S(position)
    local point, onScreen = Camera:WorldToViewportPoint(position)
    return Vector2.new(point.X, point.Y), onScreen, point.Z
end

function Utils.Dist(a, b)
    return (a - b).Magnitude
end

function Utils.Raycast(origin, direction, ignoreList)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = ignoreList or {}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    return Workspace:Raycast(origin, direction, raycastParams)
end

function Utils.NewDrawing(type, props)
    local d = Drawing.new(type)
    for k, v in pairs(props or {}) do
        d[k] = v
    end
    return d
end

function Utils.SetDrawing(obj, key, value)
    if obj then
        local ok = pcall(function()
            obj[key] = value
        end)
        return ok
    end
    return false
end

function Utils.RemoveDrawing(obj)
    if obj then
        pcall(function()
            obj:Remove()
        end)
    end
end

function Utils.MakeDrawing(type, props)
    return Utils.NewDrawing(type, props)
end

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

Utils.Box3DEdges = {
    {1,2},{2,3},{3,4},{4,1},
    {5,6},{6,7},{7,8},{8,5},
    {1,5},{2,6},{3,7},{4,8}
}

Utils.SkeletonConnections = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
    {"Torso", "Left Arm"}, {"Torso", "Right Arm"}, {"Torso", "Left Leg"}, {"Torso", "Right Leg"}, {"Torso", "Head"}
}

-- ============================================================
-- UNIFIED HOOK MANAGER v3.4
-- CRITICAL: __namecall calls getnamecallmethod() FIRST
-- Uses unpack (global) not table.unpack
-- Only repacks when modified
-- ============================================================
local HookManager = {
    OriginalRaycast = nil,
    RaycastHandlers = {},
    OriginalFindPartOnRay = nil,
    OriginalFindPartOnRayWithIgnoreList = nil,
    OriginalFindPartOnRayWithWhitelist = nil,
    FindPartOnRayHandlers = {},
    OriginalNamecall = nil,
    NamecallHandlers = {},
    Mt = nil,
    Hooked = false,
}

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

function HookManager:RegisterRaycastHandler(name, handler, priority)
    self.RaycastHandlers[name] = {handler = handler, priority = priority or 0}
end
function HookManager:UnregisterRaycastHandler(name)
    self.RaycastHandlers[name] = nil
end

function HookManager:RegisterFindPartOnRayHandler(name, handler, priority)
    self.FindPartOnRayHandlers[name] = {handler = handler, priority = priority or 0}
end
function HookManager:UnregisterFindPartOnRayHandler(name)
    self.FindPartOnRayHandlers[name] = nil
end

function HookManager:RegisterNamecallHandler(name, handler, priority)
    self.NamecallHandlers[name] = {handler = handler, priority = priority or 0}
end
function HookManager:UnregisterNamecallHandler(name)
    self.NamecallHandlers[name] = nil
end

function HookManager:Install()
    if self.Hooked then return end
    self.Hooked = true

    -- Raycast hook (direct function replacement) — PCALL WRAPPED
    local okRaycast, oldRaycast = pcall(function() return Workspace.Raycast end)
    if okRaycast and oldRaycast then
        self.OriginalRaycast = oldRaycast
        pcall(function()
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
        end)
    end

    -- FindPartOnRay hooks — PCALL WRAPPED
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

    local okFPR, oldFPR = pcall(function() return Workspace.FindPartOnRay end)
    local okFPRIL, oldFPRIL = pcall(function() return Workspace.FindPartOnRayWithIgnoreList end)
    local okFPRWL, oldFPRWL = pcall(function() return Workspace.FindPartOnRayWithWhitelist end)

    if okFPR and oldFPR then
        self.OriginalFindPartOnRay = oldFPR
        pcall(function() Workspace.FindPartOnRay = HookFindPartOnRay("FindPartOnRay", oldFPR) end)
    end
    if okFPRIL and oldFPRIL then
        self.OriginalFindPartOnRayWithIgnoreList = oldFPRIL
        pcall(function() Workspace.FindPartOnRayWithIgnoreList = HookFindPartOnRay("FindPartOnRayWithIgnoreList", oldFPRIL) end)
    end
    if okFPRWL and oldFPRWL then
        self.OriginalFindPartOnRayWithWhitelist = oldFPRWL
        pcall(function() Workspace.FindPartOnRayWithWhitelist = HookFindPartOnRay("FindPartOnRayWithWhitelist", oldFPRWL) end)
    end

    -- __namecall hook — CRITICAL: getnamecallmethod() called FIRST
    local ok, mt = pcall(getrawmetatable, game)
    if ok and mt then
        self.Mt = mt
        local oldNamecall = mt.__namecall
        if oldNamecall then
            self.OriginalNamecall = oldNamecall
            setreadonly(mt, false)
            mt.__namecall = function(self_obj, ...)
                -- CRITICAL: getnamecallmethod() MUST be called first
                local method = getnamecallmethod()
                if not method then
                    return oldNamecall(self_obj, ...)
                end

                -- Handle remotes
                if method == "FireServer" or method == "InvokeServer" then
                    local args = {...}
                    local modified = false
                    for _, entry in ipairs(GetSortedHandlers(self.NamecallHandlers)) do
                        local ok2, newArgs, wasModified = pcall(entry.handler, args, method, self_obj)
                        if ok2 and newArgs then
                            args = newArgs
                            if wasModified then modified = true end
                        end
                    end
                    if modified then
                        return oldNamecall(self_obj, unpack(args))
                    end
                end

                -- Catch FindPartOnRay via __namecall
                if method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist" then
                    local args = {...}
                    local ray = args[1]
                    if ray and typeof(ray) == "Ray" then
                        local finalRay = ray
                        for _, entry in ipairs(GetSortedHandlers(self.FindPartOnRayHandlers)) do
                            local ok2, newRay = pcall(entry.handler, finalRay, method, unpack(args, 2))
                            if ok2 and newRay ~= nil then
                                finalRay = newRay
                            end
                        end
                        if finalRay ~= ray then
                            args[1] = finalRay
                            return oldNamecall(self_obj, unpack(args))
                        end
                    end
                end

                -- Catch Raycast via __namecall
                if method == "Raycast" then
                    local args = {...}
                    local origin = args[1]
                    local direction = args[2]
                    local params = args[3]
                    if origin and direction then
                        local finalOrigin, finalDirection, finalParams = origin, direction, params
                        for _, entry in ipairs(GetSortedHandlers(self.RaycastHandlers)) do
                            local ok2, newOrigin, newDirection, newParams = pcall(entry.handler, finalOrigin, finalDirection, finalParams)
                            if ok2 and newOrigin ~= nil then
                                finalOrigin = newOrigin
                                finalDirection = newDirection or finalDirection
                                finalParams = newParams or finalParams
                            end
                        end
                        if finalOrigin ~= origin or finalDirection ~= direction then
                            args[1] = finalOrigin
                            args[2] = finalDirection
                            args[3] = finalParams
                            return oldNamecall(self_obj, unpack(args))
                        end
                    end
                end

                -- Unmodified — pass through with original varargs
                return oldNamecall(self_obj, ...)
            end
            setreadonly(mt, true)
        end
    end
end

function HookManager:Uninstall()
    if not self.Hooked then return end

    if self.OriginalRaycast then
        pcall(function() Workspace.Raycast = self.OriginalRaycast end)
    end
    if self.OriginalFindPartOnRay then
        pcall(function() Workspace.FindPartOnRay = self.OriginalFindPartOnRay end)
    end
    if self.OriginalFindPartOnRayWithIgnoreList then
        pcall(function() Workspace.FindPartOnRayWithIgnoreList = self.OriginalFindPartOnRayWithIgnoreList end)
    end
    if self.OriginalFindPartOnRayWithWhitelist then
        pcall(function() Workspace.FindPartOnRayWithWhitelist = self.OriginalFindPartOnRayWithWhitelist end)
    end

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