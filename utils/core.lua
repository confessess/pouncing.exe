-- Pouncing.exe | Utils Core v3.8
-- Minimal __namecall hook using Rollimonster pattern
-- Always unpack(args) for ALL calls to avoid stack corruption
-- Only modifies ray methods when handlers are registered
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
-- UNIFIED HOOK MANAGER v3.8
-- Minimal __namecall — Rollimonster pattern
-- ALWAYS unpack(args) for ALL calls
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

    local ok, mt = pcall(getrawmetatable, game)
    if not ok or not mt then return end

    self.Mt = mt
    local oldNamecall = mt.__namecall
    if not oldNamecall then return end

    self.OriginalNamecall = oldNamecall
    setreadonly(mt, false)

    mt.__namecall = function(...)
        -- ABSOLUTE FIRST CALL
        local method = getnamecallmethod()
        if not method then
            return oldNamecall(unpack({...}))
        end

        local args = {...}
        local modified = false

        -- Only process ray methods and remotes
        local isRayMethod = method == "Raycast" or method:find("Ray") ~= nil
        local isRemote = method == "FireServer" or method == "InvokeServer"

        if isRayMethod then
            -- Raycast: args[1]=Workspace, args[2]=origin, args[3]=direction, args[4]=params
            -- FindPartOnRay: args[1]=Workspace, args[2]=ray, args[3+]=extra
            local origin, direction, params
            if method == "Raycast" then
                origin = args[2]
                direction = args[3]
                params = args[4]
            else
                -- FindPartOnRay variants
                local ray = args[2]
                if ray and typeof(ray) == "Ray" then
                    origin = ray.Origin
                    direction = ray.Direction
                end
            end

            if origin and direction then
                local finalOrigin, finalDirection, finalParams = origin, direction, params
                for _, entry in ipairs(GetSortedHandlers(self.RaycastHandlers)) do
                    local ok2, newOrigin, newDirection, newParams = pcall(entry.handler, finalOrigin, finalDirection, finalParams)
                    if ok2 and newOrigin ~= nil then
                        finalOrigin = newOrigin
                        finalDirection = newDirection or finalDirection
                        finalParams = newParams or finalParams
                        modified = true
                    end
                end
                for _, entry in ipairs(GetSortedHandlers(self.FindPartOnRayHandlers)) do
                    local ok2, newRay = pcall(entry.handler, Ray.new(finalOrigin, finalDirection), method)
                    if ok2 and newRay ~= nil and typeof(newRay) == "Ray" then
                        finalOrigin = newRay.Origin
                        finalDirection = newRay.Direction
                        modified = true
                    end
                end

                if modified then
                    if method == "Raycast" then
                        args[2] = finalOrigin
                        args[3] = finalDirection
                        args[4] = finalParams
                    else
                        args[2] = Ray.new(finalOrigin, finalDirection)
                    end
                end
            end
        end

        if isRemote then
            local self_obj = args[1]
            if typeof(self_obj) == "Instance" and (self_obj:IsA("RemoteEvent") or self_obj:IsA("RemoteFunction")) then
                local handlerArgs = {}
                for i = 2, #args do
                    handlerArgs[i - 1] = args[i]
                end
                for _, entry in ipairs(GetSortedHandlers(self.NamecallHandlers)) do
                    local ok2, newArgs, wasModified = pcall(entry.handler, handlerArgs, method, self_obj)
                    if ok2 and newArgs then
                        handlerArgs = newArgs
                        if wasModified then modified = true end
                    end
                end
                if modified then
                    for i = 2, #args do
                        args[i] = nil
                    end
                    for i, v in ipairs(handlerArgs) do
                        args[i + 1] = v
                    end
                end
            end
        end

        -- CRITICAL: Always use unpack(args) for ALL calls
        -- This matches Rollimonster's working pattern
        return oldNamecall(unpack(args))
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