-- Pouncing.exe | Utils Core v3.6
-- Shared utilities + Unified Hook Manager
-- CRITICAL FIXES:
--   1. __namecall uses ... signature — getnamecallmethod() called before ANY other operation
--   2. Removed ALL direct Workspace method replacements (caused CoreGui collisions)
--   3. IsCoreGuiCaller() — multi-strategy detection with fallback heuristics
--   4. Unmodified calls pass through with ... directly — zero repacking
--   5. Early return for non-handled methods before ANY work
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
-- COREGUI CALLER DETECTION v2
-- Multi-strategy detection to handle executor quirks
-- ============================================================
local function IsCoreGuiCaller()
    -- Strategy 1: getcallingscript() + ancestry walk
    local success, callingScript = pcall(getcallingscript)
    if success and callingScript and typeof(callingScript) == "Instance" then
        -- Direct CoreScript check
        if callingScript:IsA("CoreScript") then
            return true
        end
        -- Ancestry walk
        local current = callingScript.Parent
        while current do
            if current == game.CoreGui or current == game.CorePackages then
                return true
            end
            current = current.Parent
        end
    end

    -- Strategy 2: checkcallers() — some executors provide this
    if checkcaller then
        local ok, isCaller = pcall(checkcaller)
        if ok and isCaller then
            -- Our own code is the caller, not CoreGui
            return false
        end
    end

    -- Strategy 3: getfenv stack inspection — detect CoreGui in call stack
    local ok, env = pcall(getfenv, 3)
    if ok and env then
        local scriptRef = env.script
        if typeof(scriptRef) == "Instance" then
            if scriptRef:IsA("CoreScript") then
                return true
            end
            local current = scriptRef.Parent
            while current do
                if current == game.CoreGui or current == game.CorePackages then
                    return true
                end
                current = current.Parent
            end
        end
    end

    -- Strategy 4: Heuristic — if the call is on a CoreGui descendant, skip it
    -- This is a last resort and less reliable
    return false
end

-- ============================================================
-- UNIFIED HOOK MANAGER v3.6
-- Only __namecall hook — removed all direct Workspace replacements
-- ============================================================
local HookManager = {
    OriginalNamecall = nil,
    NamecallHandlers = {},
    RaycastHandlers = {},
    FindPartOnRayHandlers = {},
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

    -- __namecall hook — CRITICAL: ... signature, getnamecallmethod() FIRST
    local ok, mt = pcall(getrawmetatable, game)
    if not ok or not mt then return end

    self.Mt = mt
    local oldNamecall = mt.__namecall
    if not oldNamecall then return end

    self.OriginalNamecall = oldNamecall
    setreadonly(mt, false)

    mt.__namecall = function(...)
        -- ABSOLUTE FIRST CALL — zero operations before this
        local method = getnamecallmethod()
        if not method then
            return oldNamecall(...)
        end

        -- Fast-path: methods we NEVER touch — pass through immediately
        local methodLower = method:lower()
        local isRemote = (method == "FireServer" or method == "InvokeServer")
        local isRaycast = (method == "Raycast")
        local isFindPart = (method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist")

        if not isRemote and not isRaycast and not isFindPart then
            return oldNamecall(...)
        end

        -- Extract self_obj from varargs
        local self_obj = ...

        -- Skip ALL modifications for CoreGui/CoreScripts
        if IsCoreGuiCaller() then
            return oldNamecall(...)
        end

        -- Skip if self_obj is not an Instance (safety)
        if typeof(self_obj) ~= "Instance" then
            return oldNamecall(...)
        end

        -- ============================================================
        -- REMOTE HANDLING (FireServer / InvokeServer)
        -- ============================================================
        if isRemote then
            -- Only process RemoteEvent and RemoteFunction
            if not (self_obj:IsA("RemoteEvent") or self_obj:IsA("RemoteFunction")) then
                return oldNamecall(...)
            end

            local args = {...}
            table.remove(args, 1) -- remove self_obj
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
            else
                return oldNamecall(...)
            end
        end

        -- ============================================================
        -- FINDPARTONRAY HANDLING
        -- ============================================================
        if isFindPart then
            local args = {...}
            table.remove(args, 1) -- remove self_obj
            local ray = args[1]

            if not ray or typeof(ray) ~= "Ray" then
                return oldNamecall(...)
            end

            local modified = false
            for _, entry in ipairs(GetSortedHandlers(self.FindPartOnRayHandlers)) do
                local ok2, newRay = pcall(entry.handler, ray, method, unpack(args, 2))
                if ok2 and newRay ~= nil then
                    ray = newRay
                    modified = true
                end
            end

            if modified then
                args[1] = ray
                return oldNamecall(self_obj, unpack(args))
            else
                return oldNamecall(...)
            end
        end

        -- ============================================================
        -- RAYCAST HANDLING
        -- ============================================================
        if isRaycast then
            local args = {...}
            table.remove(args, 1) -- remove self_obj
            local origin = args[1]
            local direction = args[2]

            if not origin or not direction then
                return oldNamecall(...)
            end

            local modified = false
            local finalOrigin, finalDirection, finalParams = origin, direction, args[3]

            for _, entry in ipairs(GetSortedHandlers(self.RaycastHandlers)) do
                local ok2, newOrigin, newDirection, newParams = pcall(entry.handler, finalOrigin, finalDirection, finalParams)
                if ok2 and newOrigin ~= nil then
                    finalOrigin = newOrigin
                    finalDirection = newDirection or finalDirection
                    finalParams = newParams or finalParams
                    modified = true
                end
            end

            if modified then
                args[1] = finalOrigin
                args[2] = finalDirection
                args[3] = finalParams
                return oldNamecall(self_obj, unpack(args))
            else
                return oldNamecall(...)
            end
        end

        -- Fallback (should never reach here)
        return oldNamecall(...)
    end

    setreadonly(mt, true)
end

function HookManager:Uninstall()
    if not self.Hooked then return end

    if self.Mt and self.OriginalNamecall then
        setreadonly(self.Mt, false)
        self.Mt.__namecall = self.OriginalNamecall
        setreadonly(self.Mt, true)
    end

    self.Hooked = false
    self.OriginalNamecall = nil
    self.Mt = nil
end

Utils.HookManager = HookManager

return Utils