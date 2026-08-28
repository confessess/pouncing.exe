-- Pouncing.exe | Aimbot Module v7.6
-- Silent Aim = Bullet Redirect via direct remote hooking + __namecall fallback
-- Arsenal-specific: hooks ALL remotes in ReplicatedStorage for hit detection
-- Hitbox: Malrand-style continuous expansion
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Utils = getfenv()["PouncingUtils"]

local Config = {
    Enabled = false,
    SilentAim = false,
    Triggerbot = false,
    TeamCheck = false,
    WallCheck = false,
    FOV = 60,
    Smoothness = 15,
    MaxDistance = 1000,
    TriggerDelay = 50,
    TargetPart = "Head",
    Priority = "Closest to Mouse",
    AimKey = Enum.KeyCode.Q,
    Prediction = false,
    ToggleMode = false,
    StickyTarget = false,

    -- Silent Aim settings
    HitChance = 100,
    LegitMode = false,
    LegitThreshold = 30,
    SnapDuration = 2,

    -- Arsenal Mode (legacy flag, no functional gating)
    ArsenalMode = false,

    -- Hitbox Expansion — Malrand exact
    ArsenalHitboxExpand = true,
    ArsenalHitboxSize = 13,
    ArsenalHitboxParts = {"RightUpperLeg", "LeftUpperLeg", "HeadHB", "HumanoidRootPart"},

    -- Visuals
    FOVColor = Color3.fromRGB(255, 105, 180),
    ShowFOV = true,

    -- Debug
    DebugMode = false,
    RemoteSpy = false,

    -- Internal
    CurrentTarget = nil,
    LastTriggerTime = 0,
    Aiming = false,
    StickyLostTime = 0,
    StickyGracePeriod = 0.6,
    LastClickTime = 0,
    SnapRestorePending = false,
    ArsenalOriginalSizes = {},
}

local RenderConnection = nil
local InputBeganConnection = nil
local InputEndedConnection = nil
local ArsenalHitboxThread = nil
local ArsenalHitboxRunning = false

-- Direct remote hooks storage
local DirectRemoteHooks = {}

-- ============================================================
-- Helpers
-- ============================================================

local function GetCharacter(player)
    return player and player.Character
end

local function GetHumanoid(character)
    return character and character:FindFirstChildOfClass("Humanoid")
end

local function IsAlive(character)
    local hum = GetHumanoid(character)
    return hum and hum.Health > 0
end

local function IsTeammate(player)
    if player == LocalPlayer then return true end
    if LocalPlayer.Team and player.Team and LocalPlayer.Team == player.Team then return true end
    if LocalPlayer.TeamColor and player.TeamColor and LocalPlayer.TeamColor == player.TeamColor then return true end
    return false
end

local function GetDistance(position)
    return (position - Camera.CFrame.Position).Magnitude
end

local function GetTargetPart(character)
    if Config.TargetPart == "Random" then
        local parts = {"Head", "HumanoidRootPart", "UpperTorso", "Torso"}
        return character:FindFirstChild(parts[math.random(1, #parts)])
    end
    return character:FindFirstChild(Config.TargetPart)
        or character:FindFirstChild("Head")
        or character:FindFirstChild("HumanoidRootPart")
end

local function PredictPosition(target)
    if not Config.Prediction then return target.Part.Position end
    local part = target.Part
    local velocity = part.AssemblyLinearVelocity or part.Velocity or Vector3.new()
    local dist = (part.Position - Camera.CFrame.Position).Magnitude
    local bulletSpeed = 1000
    local travelTime = dist / bulletSpeed
    return part.Position + velocity * (travelTime + 0.05)
end

-- ============================================================
-- FOV
-- ============================================================

local function GetFOVRadiusPixels()
    local fovAngle = math.rad(Config.FOV / 2)
    local camFov = math.rad(Camera.FieldOfView / 2)
    if camFov <= 0 then return 9999 end
    local radius = math.tan(fovAngle) / math.tan(camFov) * (Camera.ViewportSize.Y / 2)
    return math.min(radius, Camera.ViewportSize.Y * 0.8)
end

local function IsInFOV(targetPos)
    local screenPos, onScreen = Camera:WorldToViewportPoint(targetPos)
    if not onScreen then return false, math.huge end
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local distFromCenter = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
    return distFromCenter <= GetFOVRadiusPixels(), distFromCenter
end

-- ============================================================
-- Wall check
-- ============================================================

local function CanSee(targetPos, targetCharacter)
    if not Config.WallCheck then return true end
    local origin = Camera.CFrame.Position
    local direction = targetPos - origin
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    local result = Workspace:Raycast(origin, direction, raycastParams)
    if not result then return true end
    local hitModel = result.Instance:FindFirstAncestorOfClass("Model")
    return hitModel and hitModel == targetCharacter
end

-- ============================================================
-- Silent Aim: Target Selection
-- ============================================================

local CachedTarget = nil
local CachedTargetTime = 0

local function GetSilentAimTarget()
    if not Config.SilentAim or not Config.Enabled then return nil end

    if CachedTarget and (tick() - CachedTargetTime) < 0.016 then
        return CachedTarget
    end

    if Config.HitChance < 100 and math.random(1, 100) > Config.HitChance then
        CachedTarget = nil
        CachedTargetTime = tick()
        return nil
    end

    local bestTarget = nil
    local bestScore = math.huge

    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if Config.TeamCheck and IsTeammate(player) then continue end

        local character = GetCharacter(player)
        if not character or not IsAlive(character) then continue end

        local targetPart = GetTargetPart(character)
        if not targetPart then continue end

        local targetPos = PredictPosition({Part = targetPart, Player = player})
        local dist = GetDistance(targetPos)
        if dist > Config.MaxDistance then continue end

        local inFOV, fovDist = IsInFOV(targetPos)
        if not inFOV then continue end

        if not CanSee(targetPos, character) then continue end

        if Config.LegitMode and fovDist > Config.LegitThreshold then
            continue
        end

        if fovDist < bestScore then
            bestScore = fovDist
            bestTarget = {
                Player = player,
                Character = character,
                Part = targetPart,
                Position = targetPos,
                Distance = dist,
            }
        end
    end

    CachedTarget = bestTarget
    CachedTargetTime = tick()
    return bestTarget
end

-- ============================================================
-- Lock-on Aiming
-- ============================================================

local function AimAt(target)
    if not target or not target.Part then return end
    local aimPos = PredictPosition(target)
    local targetCF = CFrame.new(Camera.CFrame.Position, aimPos)

    if Config.Smoothness <= 0 then
        Camera.CFrame = targetCF
    else
        local alpha = math.clamp(math.exp(-Config.Smoothness * 0.045), 0.002, 1)
        Camera.CFrame = Camera.CFrame:Lerp(targetCF, alpha)
    end
end

-- ============================================================
-- NON-REDIRECT: Camera Snap (fallback when Silent Aim is off)
-- ============================================================

local function DoCameraSnap()
    if Config.SilentAim then return end
    if not Config.Enabled then return end
    if Config.Aiming then return end
    if Config.SnapRestorePending then return end

    local target = GetSilentAimTarget()
    if not target or not target.Part then return end

    local savedCF = Camera.CFrame
    local aimPos = target.Position

    Camera.CFrame = CFrame.new(Camera.CFrame.Position, aimPos)
    Config.SnapRestorePending = true

    local frames = math.clamp(Config.SnapDuration, 1, 10)
    task.defer(function()
        for i = 1, frames do
            RunService.RenderStepped:Wait()
        end
        if Config.Enabled then
            Camera.CFrame = savedCF
        end
        Config.SnapRestorePending = false
    end)
end

-- ============================================================
-- BULLET REDIRECT: Remote Argument Replacement
-- ============================================================

local function IsLikelyHitRemote(remoteName)
    local n = remoteName:lower()
    return n:find("hit") or n:find("damage") or n:find("bullet") or n:find("fire") 
        or n:find("shoot") or n:find("atk") or n:find("attack") or n:find("dmg")
        or n:find("ray") or n:find("cast") or n:find("proj") or n:find("register")
        or n:find("shot") or n:find("weapon")
end

local function IsEnemyPart(part)
    if not part or not part:IsA("BasePart") then return false end
    local model = part:FindFirstAncestorOfClass("Model")
    if not model or model == LocalPlayer.Character then return false end
    local plr = Players:GetPlayerFromCharacter(model)
    if not plr then return false end
    if Config.TeamCheck and IsTeammate(plr) then return false end
    return true
end

local function DeepScanAndReplace(t, targetPos, targetPart)
    if type(t) ~= "table" then return false end
    local modified = false

    for k, v in pairs(t) do
        local vt = typeof(v)

        if vt == "Vector3" then
            local dist = (v - Camera.CFrame.Position).Magnitude
            if dist > 0.5 and dist < Config.MaxDistance * 3 then
                t[k] = targetPos
                modified = true
            end
        elseif vt == "CFrame" then
            local dist = (v.Position - Camera.CFrame.Position).Magnitude
            if dist > 0.5 and dist < Config.MaxDistance * 3 then
                t[k] = CFrame.new(targetPos)
                modified = true
            end
        elseif vt == "Ray" then
            t[k] = Ray.new(v.Origin, targetPos - v.Origin)
            modified = true
        elseif vt == "Instance" and v:IsA("BasePart") then
            if IsEnemyPart(v) then
                t[k] = targetPart
                modified = true
            end
        elseif vt == "table" then
            if DeepScanAndReplace(v, targetPos, targetPart) then
                modified = true
            end
        elseif vt == "string" then
            if v:lower():match("torso") or v:lower():match("body") or v:lower():match("limb") 
               or v:lower():match("arm") or v:lower():match("leg") or v:lower():match("head") then
                t[k] = targetPart.Name
                modified = true
            end
        end
    end

    return modified
end

local function ProcessRemoteArgs(args, remoteName)
    if not Config.SilentAim or not Config.Enabled then return args, false end

    local target = GetSilentAimTarget()
    if not target or not target.Part then return args, false end

    local aimPos = target.Position
    local modified = false
    local isHitRemote = IsLikelyHitRemote(remoteName)

    -- REMOTE SPY: Log all remotes when enabled
    if Config.RemoteSpy then
        local argSummary = {}
        for i = 1, math.min(#args, 5) do
            local a = args[i]
            local t = typeof(a)
            if t == "Vector3" then
                table.insert(argSummary, "V3(" .. tostring(math.floor(a.X)) .. "," .. tostring(math.floor(a.Y)) .. "," .. tostring(math.floor(a.Z)) .. ")")
            elseif t == "CFrame" then
                table.insert(argSummary, "CF")
            elseif t == "Instance" then
                table.insert(argSummary, a.Name .. "(" .. a.ClassName .. ")")
            elseif t == "table" then
                table.insert(argSummary, "table[" .. tostring(#a) .. "]")
            else
                table.insert(argSummary, t .. ":" .. tostring(a):sub(1, 20))
            end
        end
        print("[RemoteSpy] " .. remoteName .. " | " .. table.concat(argSummary, " | "))
    end

    for i = 1, #args do
        local arg = args[i]
        local argType = typeof(arg)

        if argType == "Vector3" then
            local dist = (arg - Camera.CFrame.Position).Magnitude
            if dist > 0.5 and dist < Config.MaxDistance * 3 then
                args[i] = aimPos
                modified = true
            end
        elseif argType == "CFrame" then
            local dist = (arg.Position - Camera.CFrame.Position).Magnitude
            if dist > 0.5 and dist < Config.MaxDistance * 3 then
                args[i] = CFrame.new(aimPos)
                modified = true
            end
        elseif argType == "Ray" then
            args[i] = Ray.new(arg.Origin, aimPos - arg.Origin)
            modified = true
        elseif argType == "Instance" and arg:IsA("BasePart") then
            if IsEnemyPart(arg) then
                args[i] = target.Part
                modified = true
            end
        elseif argType == "table" then
            if DeepScanAndReplace(arg, aimPos, target.Part) then
                modified = true
            end
        elseif argType == "string" then
            if arg:lower():match("torso") or arg:lower():match("body") or arg:lower():match("limb") 
               or arg:lower():match("arm") or arg:lower():match("leg") or arg:lower():match("head") then
                args[i] = target.Part.Name
                modified = true
            end
        end
    end

    if modified and Config.DebugMode then
        print("[Pouncing Aimbot] Remote " .. remoteName .. " redirected to " .. target.Player.Name)
    end

    return args, modified
end

-- ============================================================
-- DIRECT REMOTE HOOKING
-- Hooks ALL RemoteEvents and RemoteFunctions in ReplicatedStorage
-- This bypasses __namecall entirely and works even if getrawmetatable fails
-- ============================================================

local function HookRemoteDirect(remote)
    if not remote or not (remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction")) then return end
    if DirectRemoteHooks[remote] then return end

    local remoteName = remote.Name
    local originalFire = remote.FireServer
    local originalInvoke = remote.InvokeServer

    DirectRemoteHooks[remote] = {
        originalFire = originalFire,
        originalInvoke = originalInvoke,
    }

    -- Hook FireServer (only for RemoteEvent)
    if remote:IsA("RemoteEvent") and originalFire then
        remote.FireServer = function(self_obj, ...)
            if not Config.SilentAim or not Config.Enabled then
                return originalFire(self_obj, ...)
            end
            local args = {...}
            local newArgs, modified = ProcessRemoteArgs(args, remoteName)
            if modified then
                return originalFire(self_obj, unpack(newArgs))
            end
            return originalFire(self_obj, ...)
        end
    end

    -- Hook InvokeServer (only for RemoteFunction)
    if remote:IsA("RemoteFunction") and originalInvoke then
        remote.InvokeServer = function(self_obj, ...)
            if not Config.SilentAim or not Config.Enabled then
                return originalInvoke(self_obj, ...)
            end
            local args = {...}
            local newArgs, modified = ProcessRemoteArgs(args, remoteName)
            if modified then
                return originalInvoke(self_obj, unpack(newArgs))
            end
            return originalInvoke(self_obj, ...)
        end
    end
end

local function UnhookAllRemotesDirect()
    for remote, hooks in pairs(DirectRemoteHooks) do
        if remote and remote.Parent then
            pcall(function()
                if remote:IsA("RemoteEvent") and hooks.originalFire then
                    remote.FireServer = hooks.originalFire
                end
                if remote:IsA("RemoteFunction") and hooks.originalInvoke then
                    remote.InvokeServer = hooks.originalInvoke
                end
            end)
        end
    end
    DirectRemoteHooks = {}
end

local function ScanAndHookRemotes()
    local count = 0
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            HookRemoteDirect(obj)
            count = count + 1
        end
    end
    if Config.DebugMode then
        print("[Pouncing Aimbot] Direct-hooked " .. tostring(count) .. " remotes")
    end
end

-- Also hook remotes that are added after initial scan
local RemoteAddedConnection = nil

local function StartRemoteScanner()
    ScanAndHookRemotes()
    if RemoteAddedConnection then return end
    RemoteAddedConnection = ReplicatedStorage.DescendantAdded:Connect(function(desc)
        if desc:IsA("RemoteEvent") or desc:IsA("RemoteFunction") then
            task.wait(0.1)
            HookRemoteDirect(desc)
            if Config.DebugMode then
                print("[Pouncing Aimbot] Late-hooked remote: " .. desc.Name)
            end
        end
    end)
end

local function StopRemoteScanner()
    if RemoteAddedConnection then
        RemoteAddedConnection:Disconnect()
        RemoteAddedConnection = nil
    end
    UnhookAllRemotesDirect()
end

-- ============================================================
-- FALLBACK: __namecall hook (for remotes not in ReplicatedStorage)
-- ============================================================

local function RedirectNamecallHandler(args, method, self_obj)
    if method ~= "FireServer" and method ~= "InvokeServer" then return args, false end

    local objType = typeof(self_obj)
    if objType ~= "Instance" then return args, false end
    if not (self_obj:IsA("RemoteEvent") or self_obj:IsA("RemoteFunction")) then return args, false end

    local remoteName = self_obj.Name
    local newArgs, modified = ProcessRemoteArgs(args, remoteName)
    return newArgs, modified
end

-- ============================================================
-- Raycast / FindPartOnRay hooks (for games that use them)
-- ============================================================

local function RedirectRaycastHandler(origin, direction, params)
    if not Config.SilentAim or not Config.Enabled then return nil end
    local target = GetSilentAimTarget()
    if not target or not target.Part then return nil end
    if Config.DebugMode then
        print("[Pouncing Aimbot] Raycast redirected to " .. target.Player.Name)
    end
    return origin, target.Position - origin, params
end

local function RedirectFindPartOnRayHandler(ray, methodName, ...)
    if not Config.SilentAim or not Config.Enabled then return nil end
    local target = GetSilentAimTarget()
    if not target or not target.Part then return nil end
    if Config.DebugMode then
        print("[Pouncing Aimbot] FindPartOnRay redirected to " .. target.Player.Name)
    end
    return Ray.new(ray.Origin, target.Position - ray.Origin)
end

-- ============================================================
-- HITBOX EXPANSION — Malrand Style
-- ============================================================

local function RestoreArsenalHitboxes(player)
    local sizes = Config.ArsenalOriginalSizes[player]
    if not sizes then return end
    local character = player.Character
    if character then
        for partName, originalData in pairs(sizes) do
            local part = character:FindFirstChild(partName)
            if part and part:IsA("BasePart") then
                part.Size = originalData.Size
                part.Transparency = originalData.Transparency
                part.CanCollide = originalData.CanCollide
            end
        end
    end
    Config.ArsenalOriginalSizes[player] = nil
end

local function ExpandArsenalHitboxes(player)
    if player == LocalPlayer then return end
    if Config.TeamCheck and IsTeammate(player) then
        RestoreArsenalHitboxes(player)
        return
    end

    local character = player.Character
    if not character then
        RestoreArsenalHitboxes(player)
        return
    end

    local hum = character:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then
        RestoreArsenalHitboxes(player)
        return
    end

    if not Config.ArsenalOriginalSizes[player] then
        Config.ArsenalOriginalSizes[player] = {}
    end

    for _, partName in ipairs(Config.ArsenalHitboxParts) do
        local part = character:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            if not Config.ArsenalOriginalSizes[player][partName] then
                Config.ArsenalOriginalSizes[player][partName] = {
                    Size = part.Size,
                    Transparency = part.Transparency,
                    CanCollide = part.CanCollide,
                }
            end
            part.CanCollide = false
            part.Transparency = 10
            part.Size = Vector3.new(Config.ArsenalHitboxSize, Config.ArsenalHitboxSize, Config.ArsenalHitboxSize)
        end
    end
end

local function ClearAllArsenalHitboxes()
    for player, _ in pairs(Config.ArsenalOriginalSizes) do
        RestoreArsenalHitboxes(player)
    end
    Config.ArsenalOriginalSizes = {}
end

local function OnArsenalHitboxLoop()
    if not Config.Enabled or not Config.ArsenalHitboxExpand then
        ClearAllArsenalHitboxes()
        return
    end

    for _, player in pairs(Players:GetPlayers()) do
        pcall(function() ExpandArsenalHitboxes(player) end)
    end
end

local function StartArsenalHitboxLoop()
    if ArsenalHitboxRunning then return end
    ArsenalHitboxRunning = true
    ArsenalHitboxThread = task.spawn(function()
        while ArsenalHitboxRunning do
            if Config.Enabled and Config.ArsenalHitboxExpand then
                OnArsenalHitboxLoop()
            else
                ClearAllArsenalHitboxes()
            end
            task.wait(1)
        end
        ArsenalHitboxRunning = false
        ArsenalHitboxThread = nil
    end)
end

local function StopArsenalHitboxLoop()
    ArsenalHitboxRunning = false
    ArsenalHitboxThread = nil
    ClearAllArsenalHitboxes()
end

-- ============================================================
-- Triggerbot
-- ============================================================

local function IsTargetUnderCrosshair()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local ray = Camera:ViewportPointToRay(center.X, center.Y)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    local result = Workspace:Raycast(ray.Origin, ray.Direction * Config.MaxDistance, raycastParams)
    if not result then return false end
    local hitModel = result.Instance:FindFirstAncestorOfClass("Model")
    if not hitModel then return false end
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character == hitModel then
            if Config.TeamCheck and IsTeammate(player) then return false end
            local hum = GetHumanoid(hitModel)
            return hum and hum.Health > 0
        end
    end
    return false
end

local function ClickMouse()
    if mouse1click then
        pcall(mouse1click)
    else
        local vim = game:GetService("VirtualInputManager")
        pcall(function()
            vim:SendMouseButtonEvent(0, 0, 0, true, game, 0)
            task.wait(0.01)
            vim:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        end)
    end
end

local function DoTriggerbot()
    if not Config.Triggerbot then return end
    local now = tick()
    if now - Config.LastTriggerTime < (Config.TriggerDelay / 1000) then return end
    if IsTargetUnderCrosshair() then
        Config.LastTriggerTime = now
        ClickMouse()
    end
end

-- ============================================================
-- Visuals
-- ============================================================

local FOVCircle = nil
local TargetCircle = nil

local function UpdateFOVCircle()
    if not FOVCircle then return end
    if Config.Enabled and Config.ShowFOV then
        local radius = GetFOVRadiusPixels()
        FOVCircle.Visible = true
        FOVCircle.Radius = radius
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        FOVCircle.Color = Config.FOVColor
    else
        FOVCircle.Visible = false
    end
end

local function UpdateTargetCircle()
    if not TargetCircle then return end
    if Config.Enabled and Config.CurrentTarget and Config.CurrentTarget.Part then
        local screenPos, onScreen = Camera:WorldToViewportPoint(Config.CurrentTarget.Part.Position)
        if onScreen then
            TargetCircle.Visible = true
            TargetCircle.Position = Vector2.new(screenPos.X, screenPos.Y)
        else
            TargetCircle.Visible = false
        end
    else
        TargetCircle.Visible = false
    end
end

-- ============================================================
-- Target Selection (Lock-on)
-- ============================================================

local function IsTargetValidStrict(target)
    if not target then return false end
    if not target.Player or not target.Character then return false end
    if not IsAlive(target.Character) then return false end
    if Config.TeamCheck and IsTeammate(target.Player) then return false end
    local part = target.Character:FindFirstChild(target.Part.Name)
    if not part then return false end
    local dist = GetDistance(part.Position)
    if dist > Config.MaxDistance then return false end
    local inFOV, _ = IsInFOV(part.Position)
    if not inFOV then return false end
    if not CanSee(part.Position, target.Character) then return false end
    return true
end

local function IsTargetValidSticky(target)
    if not target then return false end
    if not target.Player or not target.Character then return false end
    if not IsAlive(target.Character) then return false end
    if Config.TeamCheck and IsTeammate(target.Player) then return false end
    local part = target.Character:FindFirstChild(target.Part.Name)
    if not part then return false end
    local dist = GetDistance(part.Position)
    if dist > Config.MaxDistance then return false end
    return true
end

local function IsAimbotActive()
    return Config.Aiming or Config.SilentAim
end

local function GetBestTarget()
    if Config.Enabled and Config.StickyTarget and Config.CurrentTarget and IsAimbotActive() then
        if IsTargetValidSticky(Config.CurrentTarget) then
            local part = Config.CurrentTarget.Character:FindFirstChild(Config.CurrentTarget.Part.Name)
            if part then
                Config.CurrentTarget.Part = part
                Config.CurrentTarget.Position = part.Position
                Config.StickyLostTime = 0
                return Config.CurrentTarget
            end
        else
            if Config.StickyLostTime == 0 then
                Config.StickyLostTime = tick()
            elseif tick() - Config.StickyLostTime < Config.StickyGracePeriod then
                local part = Config.CurrentTarget.Character:FindFirstChild(Config.CurrentTarget.Part.Name)
                if part then
                    Config.CurrentTarget.Part = part
                    Config.CurrentTarget.Position = part.Position
                    return Config.CurrentTarget
                end
            end
            Config.CurrentTarget = nil
            Config.StickyLostTime = 0
        end
    end

    local bestTarget = nil
    local bestScore = math.huge

    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if Config.TeamCheck and IsTeammate(player) then continue end

        local character = GetCharacter(player)
        if not character or not IsAlive(character) then continue end

        local targetPart = GetTargetPart(character)
        if not targetPart then continue end

        local targetPos = targetPart.Position
        local dist = GetDistance(targetPos)
        if dist > Config.MaxDistance then continue end

        local inFOV, fovDist = IsInFOV(targetPos)
        if not inFOV then continue end

        if not CanSee(targetPos, character) then continue end

        local score = math.huge
        local hum = GetHumanoid(character)

        if Config.Priority == "Closest to Mouse" then
            score = fovDist
        elseif Config.Priority == "Closest to Player" then
            score = dist
        elseif Config.Priority == "Lowest HP" then
            if hum then
                score = hum.Health + (fovDist * 0.1)
            else
                score = fovDist
            end
        elseif Config.Priority == "Highest HP" then
            if hum then
                score = -hum.Health + (fovDist * 0.1)
            else
                score = fovDist
            end
        elseif Config.Priority == "Random" then
            score = math.random(1, 10000)
        else
            score = fovDist + (dist * 0.02)
        end

        if score < bestScore then
            bestScore = score
            bestTarget = {
                Player = player,
                Character = character,
                Part = targetPart,
                Position = targetPos,
                Distance = dist,
            }
        end
    end
    return bestTarget
end

-- ============================================================
-- Render loop
-- ============================================================

local function OnRenderStep()
    if not Config.Enabled then
        Config.CurrentTarget = nil
        Config.StickyLostTime = 0
        if FOVCircle then FOVCircle.Visible = false end
        if TargetCircle then TargetCircle.Visible = false end
        return
    end

    local target = GetBestTarget()
    Config.CurrentTarget = target

    if target then
        if Config.SilentAim then
            -- Silent aim uses remote hooks
        elseif Config.Aiming then
            AimAt(target)
        end

        if Config.Triggerbot then
            DoTriggerbot()
        end
    end

    UpdateFOVCircle()
    UpdateTargetCircle()
end

-- ============================================================
-- Input
-- ============================================================

local function OnInputBegan(input, gp)
    if gp then return end

    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        Config.LastClickTime = tick()
        if not Config.SilentAim then
            DoCameraSnap()
        end
    end

    if input.UserInputType == Config.AimKey or input.KeyCode == Config.AimKey then
        if Config.ToggleMode then
            Config.Aiming = not Config.Aiming
        else
            Config.Aiming = true
        end
    end
end

local function OnInputEnded(input, gp)
    if gp then return end
    if not Config.ToggleMode then
        if input.UserInputType == Config.AimKey or input.KeyCode == Config.AimKey then
            Config.Aiming = false
        end
    end
end

-- ============================================================
-- Module API
-- ============================================================

local Module = {}

function Module.Init()
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Visible = false
    FOVCircle.Thickness = 1.5
    FOVCircle.Color = Config.FOVColor
    FOVCircle.Transparency = 0.5
    FOVCircle.NumSides = 64
    FOVCircle.Filled = false

    TargetCircle = Drawing.new("Circle")
    TargetCircle.Visible = false
    TargetCircle.Thickness = 2
    TargetCircle.Color = Color3.fromRGB(255, 0, 255)
    TargetCircle.Transparency = 0.7
    TargetCircle.NumSides = 32
    TargetCircle.Filled = false
    TargetCircle.Radius = 8

    InputBeganConnection = UserInputService.InputBegan:Connect(OnInputBegan)
    InputEndedConnection = UserInputService.InputEnded:Connect(OnInputEnded)
end

function Module.Enable()
    Config.Enabled = true

    -- METHOD 1: Direct remote hooking (most reliable)
    StartRemoteScanner()

    -- METHOD 2: HookManager fallback (Raycast, FindPartOnRay, __namecall)
    if Utils and Utils.HookManager then
        Utils.HookManager:RegisterRaycastHandler("Aimbot", RedirectRaycastHandler, 10)
        Utils.HookManager:RegisterFindPartOnRayHandler("Aimbot", RedirectFindPartOnRayHandler, 10)
        Utils.HookManager:RegisterNamecallHandler("Aimbot", RedirectNamecallHandler, 10)
        local ok, err = pcall(function() Utils.HookManager:Install() end)
        if not ok and Config.DebugMode then
            warn("[Pouncing Aimbot] HookManager install failed: " .. tostring(err))
        end
    end

    if Config.ArsenalHitboxExpand then
        StartArsenalHitboxLoop()
    end

    if not RenderConnection then
        RenderConnection = RunService.RenderStepped:Connect(OnRenderStep)
    end

    if Config.DebugMode then
        print("[Pouncing Aimbot] Enabled. Direct remote hooks + HookManager fallback active.")
    end
end

function Module.Disable()
    Config.Enabled = false
    Config.Aiming = false
    Config.CurrentTarget = nil
    Config.StickyLostTime = 0
    Config.SnapRestorePending = false

    StopRemoteScanner()

    if Utils and Utils.HookManager then
        pcall(function()
            Utils.HookManager:UnregisterRaycastHandler("Aimbot")
            Utils.HookManager:UnregisterFindPartOnRayHandler("Aimbot")
            Utils.HookManager:UnregisterNamecallHandler("Aimbot")
        end)
    end

    StopArsenalHitboxLoop()

    if RenderConnection then
        RenderConnection:Disconnect()
        RenderConnection = nil
    end
    if FOVCircle then FOVCircle.Visible = false end
    if TargetCircle then TargetCircle.Visible = false end
end

function Module.SetConfig(key, value)
    if key == "SilentAim" then
        Config.SilentAim = value
        -- Re-scan remotes when toggling to ensure fresh hooks
        if value and Config.Enabled then
            StartRemoteScanner()
        end
    elseif key == "Triggerbot" then Config.Triggerbot = value
    elseif key == "TeamCheck" then Config.TeamCheck = value
    elseif key == "WallCheck" then Config.WallCheck = value
    elseif key == "FOV" then Config.FOV = math.clamp(value, 10, 100)
    elseif key == "Smoothness" then Config.Smoothness = math.clamp(value, 0, 100)
    elseif key == "MaxDistance" then Config.MaxDistance = math.clamp(value, 50, 5000)
    elseif key == "TriggerDelay" then Config.TriggerDelay = math.clamp(value, 0, 5000)
    elseif key == "TargetPart" then Config.TargetPart = value
    elseif key == "Priority" then Config.Priority = value
    elseif key == "AimKey" then Config.AimKey = value
    elseif key == "Prediction" then Config.Prediction = value
    elseif key == "ToggleMode" then
        Config.ToggleMode = value
        if not value then Config.Aiming = false end
    elseif key == "StickyTarget" then Config.StickyTarget = value
    elseif key == "HitChance" then Config.HitChance = math.clamp(value, 0, 100)
    elseif key == "LegitMode" then Config.LegitMode = value
    elseif key == "LegitThreshold" then Config.LegitThreshold = value
    elseif key == "SnapDuration" then Config.SnapDuration = math.clamp(value, 1, 10)
    elseif key == "ArsenalMode" then 
        Config.ArsenalMode = value
    elseif key == "ArsenalHitboxExpand" then
        Config.ArsenalHitboxExpand = value
        if Config.Enabled then
            if value then
                StartArsenalHitboxLoop()
            else
                StopArsenalHitboxLoop()
            end
        end
    elseif key == "ArsenalHitboxSize" then
        Config.ArsenalHitboxSize = math.clamp(value, 1, 25)
    elseif key == "FOVColor" then 
        Config.FOVColor = value
        if FOVCircle then FOVCircle.Color = value end
    elseif key == "ShowFOV" then Config.ShowFOV = value
    elseif key == "DebugMode" then Config.DebugMode = value
    elseif key == "RemoteSpy" then Config.RemoteSpy = value
    end
end

function Module.GetConfig()
    return Config
end

function Module.ResetConfig()
    Config.Enabled = false
    Config.SilentAim = false
    Config.Triggerbot = false
    Config.TeamCheck = false
    Config.WallCheck = false
    Config.FOV = 60
    Config.Smoothness = 15
    Config.MaxDistance = 1000
    Config.TriggerDelay = 50
    Config.TargetPart = "Head"
    Config.Priority = "Closest to Mouse"
    Config.AimKey = Enum.KeyCode.Q
    Config.Prediction = false
    Config.ToggleMode = false
    Config.StickyTarget = false
    Config.CurrentTarget = nil
    Config.Aiming = false
    Config.StickyLostTime = 0
    Config.HitChance = 100
    Config.LegitMode = false
    Config.LegitThreshold = 30
    Config.SnapDuration = 2
    Config.ArsenalMode = false
    Config.ArsenalHitboxExpand = true
    Config.ArsenalHitboxSize = 13
    Config.FOVColor = Color3.fromRGB(255, 105, 180)
    Config.ShowFOV = true
    Config.SnapRestorePending = false
    Config.DebugMode = false
    Config.RemoteSpy = false
    StopArsenalHitboxLoop()
    StopRemoteScanner()
    if Utils and Utils.HookManager then
        pcall(function()
            Utils.HookManager:UnregisterRaycastHandler("Aimbot")
            Utils.HookManager:UnregisterFindPartOnRayHandler("Aimbot")
            Utils.HookManager:UnregisterNamecallHandler("Aimbot")
        end)
    end
end

function Module.Cleanup()
    Module.Disable()
    if InputBeganConnection then InputBeganConnection:Disconnect(); InputBeganConnection = nil end
    if InputEndedConnection then InputEndedConnection:Disconnect(); InputEndedConnection = nil end
    if FOVCircle then FOVCircle:Remove(); FOVCircle = nil end
    if TargetCircle then TargetCircle:Remove(); TargetCircle = nil end
end

return Module