-- Pouncing.exe | Aimbot Module v5.0
-- Lock-on, silent aim, triggerbot, toggle, sticky target
-- Silent Aim: Post-execution FindPartOnRay + Raycast + __namecall + Mouse.Hit
-- Arsenal-ready: lets original raycast run, then replaces miss with target hit
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

local Utils = getfenv()["PouncingUtils"]

local Config = {
    Enabled = false,
    SilentAim = false,
    Triggerbot = false,
    TeamCheck = false,
    WallCheck = false,
    FOV = 120,
    Smoothness = 15,
    MaxDistance = 1000,
    TriggerDelay = 50,
    TargetPart = "Head",
    Priority = "Closest to Mouse",
    AimKey = Enum.KeyCode.Q,
    Prediction = false,
    ToggleMode = false,
    StickyTarget = false,

    -- Silent Aim
    HitChance = 100,
    LegitMode = false,
    LegitThreshold = 30,
    WeaponOnly = false,

    -- Visuals
    FOVColor = Color3.fromRGB(255, 105, 180),
    ShowFOV = true,

    -- Internal
    CurrentTarget = nil,
    LastTriggerTime = 0,
    Aiming = false,
    StickyLostTime = 0,
    StickyGracePeriod = 0.6,
    LastClickTime = 0,
}

local RenderConnection = nil
local InputBeganConnection = nil
local InputEndedConnection = nil

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
    return math.tan(fovAngle) / math.tan(camFov) * (Camera.ViewportSize.Y / 2)
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

local function GetSilentAimTarget()
    if not Config.SilentAim or not Config.Enabled then return nil end

    -- Hit chance check
    if Config.HitChance < 100 and math.random(1, 100) > Config.HitChance then
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

        -- Legit mode: only redirect if already close to crosshair
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
-- Silent Aim: POST-EXECUTION FindPartOnRay Handler
-- This is the KEY for Arsenal: let the raycast run, then replace miss with target
-- ============================================================

local function SilentAimFindPartOnRayPostHandler(result, ray, methodName, ...)
    if not Config.SilentAim or not Config.Enabled then return nil end

    local target = GetSilentAimTarget()
    if not target or not target.Part then return nil end

    -- result is a table from the original function: {part, position, normal, ...}
    local hitPart = result[1]

    -- If we already hit a valid enemy part, don't override
    if hitPart and hitPart:IsA("BasePart") then
        local hitModel = hitPart:FindFirstAncestorOfClass("Model")
        if hitModel and hitModel ~= LocalPlayer.Character then
            local hitPlayer = Players:GetPlayerFromCharacter(hitModel)
            if hitPlayer and (not Config.TeamCheck or not IsTeammate(hitPlayer)) then
                return nil -- already hitting an enemy, let it through
            end
        end
    end

    -- Replace miss / wall / teammate hit with target
    local aimPos = target.Position
    local normal = (ray.Origin - aimPos).Unit

    return {target.Part, aimPos, normal}
end

-- ============================================================
-- Silent Aim: Raycast Handler (pre-execution)
-- ============================================================

local function SilentAimRaycastHandler(origin, direction, params)
    if not Config.SilentAim or not Config.Enabled then return nil end

    local target = GetSilentAimTarget()
    if not target or not target.Part then return nil end

    local aimPos = target.Position
    return origin, aimPos - origin, params
end

-- ============================================================
-- Silent Aim: Mouse.Hit / Mouse.Target __index Handler
-- ============================================================

local function SilentAimIndexHandler(self_obj, key)
    if not Config.SilentAim or not Config.Enabled then return nil end
    if self_obj ~= Mouse then return nil end

    local target = GetSilentAimTarget()
    if not target or not target.Part then return nil end

    if key == "Hit" then
        return CFrame.new(target.Position)
    elseif key == "Target" then
        return target.Part
    elseif key == "TargetSurface" then
        return Enum.NormalId.Top
    end

    return nil
end

-- ============================================================
-- Silent Aim: __namecall Deep Scan Handler
-- ============================================================

local function IsHitPosition(pos)
    local camPos = Camera.CFrame.Position
    local d = (pos - camPos).Magnitude
    return d > 0.5 and d < Config.MaxDistance * 2
end

local function DeepScanAndReplace(t, targetPos, targetPart)
    if type(t) ~= "table" then return false end
    local modified = false

    for k, v in pairs(t) do
        local vt = typeof(v)

        if vt == "Vector3" then
            if IsHitPosition(v) then
                t[k] = targetPos
                modified = true
            end
        elseif vt == "CFrame" then
            if IsHitPosition(v.Position) then
                t[k] = CFrame.new(targetPos)
                modified = true
            end
        elseif vt == "Ray" then
            t[k] = Ray.new(v.Origin, targetPos - v.Origin)
            modified = true
        elseif vt == "Instance" and v:IsA("BasePart") then
            local vm = v:FindFirstAncestorOfClass("Model")
            if vm and vm ~= LocalPlayer.Character then
                t[k] = targetPart
                modified = true
            end
        elseif vt == "table" then
            if DeepScanAndReplace(v, targetPos, targetPart) then
                modified = true
            end
        elseif vt == "string" then
            if v:lower():match("torso") or v:lower():match("body") or v:lower():match("limb") or v:lower():match("arm") or v:lower():match("leg") then
                t[k] = targetPart.Name
                modified = true
            end
        end
    end

    return modified
end

local function SilentAimNamecallHandler(args, method, self_obj)
    if not Config.SilentAim or not Config.Enabled then return args, false end

    local target = GetSilentAimTarget()
    if not target or not target.Part then return args, false end

    local aimPos = target.Position
    local modified = false

    for i = 1, #args do
        local arg = args[i]
        local argType = typeof(arg)

        if argType == "Vector3" then
            if IsHitPosition(arg) then
                args[i] = aimPos
                modified = true
            end
        elseif argType == "CFrame" then
            if IsHitPosition(arg.Position) then
                args[i] = CFrame.new(aimPos)
                modified = true
            end
        elseif argType == "Ray" then
            args[i] = Ray.new(arg.Origin, aimPos - arg.Origin)
            modified = true
        elseif argType == "Instance" and arg:IsA("BasePart") then
            local model = arg:FindFirstAncestorOfClass("Model")
            if model and model ~= LocalPlayer.Character then
                args[i] = target.Part
                modified = true
            end
        elseif argType == "table" then
            if DeepScanAndReplace(arg, aimPos, target.Part) then
                modified = true
            end
        elseif argType == "string" then
            if arg:lower():match("torso") or arg:lower():match("body") or arg:lower():match("limb") or arg:lower():match("arm") or arg:lower():match("leg") then
                args[i] = target.Part.Name
                modified = true
            end
        end
    end

    return args, modified
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
            -- Silent aim handles aiming via hooks
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
    if Config.SilentAim and Utils and Utils.HookManager then
        Utils.HookManager:RegisterFindPartOnRayPostHandler("Aimbot", SilentAimFindPartOnRayPostHandler, 10)
        Utils.HookManager:RegisterRaycastHandler("Aimbot", SilentAimRaycastHandler, 10)
        Utils.HookManager:RegisterNamecallHandler("Aimbot", SilentAimNamecallHandler, 10)
        Utils.HookManager:RegisterIndexHandler("Aimbot", SilentAimIndexHandler, 10)
        Utils.HookManager:Install()
    end
    if not RenderConnection then
        RenderConnection = RunService.RenderStepped:Connect(OnRenderStep)
    end
end

function Module.Disable()
    Config.Enabled = false
    Config.Aiming = false
    Config.CurrentTarget = nil
    Config.StickyLostTime = 0
    if Utils and Utils.HookManager then
        Utils.HookManager:UnregisterFindPartOnRayPostHandler("Aimbot")
        Utils.HookManager:UnregisterRaycastHandler("Aimbot")
        Utils.HookManager:UnregisterNamecallHandler("Aimbot")
        Utils.HookManager:UnregisterIndexHandler("Aimbot")
    end
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
        if Config.Enabled and Utils and Utils.HookManager then
            if value then
                Utils.HookManager:RegisterFindPartOnRayPostHandler("Aimbot", SilentAimFindPartOnRayPostHandler, 10)
                Utils.HookManager:RegisterRaycastHandler("Aimbot", SilentAimRaycastHandler, 10)
                Utils.HookManager:RegisterNamecallHandler("Aimbot", SilentAimNamecallHandler, 10)
                Utils.HookManager:RegisterIndexHandler("Aimbot", SilentAimIndexHandler, 10)
                Utils.HookManager:Install()
            else
                Utils.HookManager:UnregisterFindPartOnRayPostHandler("Aimbot")
                Utils.HookManager:UnregisterRaycastHandler("Aimbot")
                Utils.HookManager:UnregisterNamecallHandler("Aimbot")
                Utils.HookManager:UnregisterIndexHandler("Aimbot")
            end
        end
    elseif key == "Triggerbot" then Config.Triggerbot = value
    elseif key == "TeamCheck" then Config.TeamCheck = value
    elseif key == "WallCheck" then Config.WallCheck = value
    elseif key == "FOV" then Config.FOV = math.clamp(value, 10, 360)
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
    elseif key == "WeaponOnly" then Config.WeaponOnly = value
    elseif key == "FOVColor" then 
        Config.FOVColor = value
        if FOVCircle then FOVCircle.Color = value end
    elseif key == "ShowFOV" then Config.ShowFOV = value
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
    Config.FOV = 120
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
    Config.WeaponOnly = false
    Config.FOVColor = Color3.fromRGB(255, 105, 180)
    Config.ShowFOV = true
    if Utils and Utils.HookManager then
        Utils.HookManager:UnregisterFindPartOnRayPostHandler("Aimbot")
        Utils.HookManager:UnregisterRaycastHandler("Aimbot")
        Utils.HookManager:UnregisterNamecallHandler("Aimbot")
        Utils.HookManager:UnregisterIndexHandler("Aimbot")
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