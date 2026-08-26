-- Pouncing.exe | Aimbot Module v2.1
-- Lock-on, silent aim, and triggerbot functionality
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Config = {
    Enabled = false,
    SilentAim = false,
    Triggerbot = false,
    TeamCheck = false,
    WallCheck = false,
    FOV = 90,
    Smoothness = 50,
    MaxDistance = 1000,
    TriggerDelay = 50,
    TargetPart = "Head",
    Priority = "Closest",
    AimKey = Enum.UserInputType.MouseButton2,
    CurrentTarget = nil,
    LastTriggerTime = 0,
    Aiming = false,
    SilentAimHooked = false
}

local SilentAimHooks = {}
local RenderConnection = nil
local InputBeganConnection = nil
local InputEndedConnection = nil

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
    if not LocalPlayer.Team or not player.Team then return false end
    return player.Team == LocalPlayer.Team
end

local function GetDistance(position)
    return (position - Camera.CFrame.Position).Magnitude
end

local function IsInFOV(targetPos)
    local screenPos, onScreen = Camera:WorldToViewportPoint(targetPos)
    if not onScreen then return false, math.huge end
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local distFromCenter = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
    local fovRadius = (Config.FOV / 360) * math.min(Camera.ViewportSize.X, Camera.ViewportSize.Y) * 0.5
    return distFromCenter <= fovRadius, distFromCenter
end

local function CanSee(targetPos, targetCharacter)
    if not Config.WallCheck then return true end
    local origin = Camera.CFrame.Position
    local direction = (targetPos - origin).Unit * (targetPos - origin).Magnitude
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    local result = Workspace:Raycast(origin, direction, raycastParams)
    if result then
        local hitModel = result.Instance:FindFirstAncestorOfClass("Model")
        if hitModel and hitModel == targetCharacter then return true end
        return false
    end
    return true
end

local function GetTargetPart(character)
    if Config.TargetPart == "Random" then
        local parts = {"Head", "HumanoidRootPart", "UpperTorso", "Torso"}
        return character:FindFirstChild(parts[math.random(1, #parts)])
    end
    return character:FindFirstChild(Config.TargetPart) or character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
end

local function GetBestTarget()
    local bestTarget = nil
    local bestScore = math.huge
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if Config.TeamCheck and IsTeammate(player) then continue end
        local character = GetCharacter(player)
        if not character then continue end
        if not IsAlive(character) then continue end
        local targetPart = GetTargetPart(character)
        if not targetPart then continue end
        local targetPos = targetPart.Position
        local dist = GetDistance(targetPos)
        if dist > Config.MaxDistance then continue end
        local inFOV, fovDist = IsInFOV(targetPos)
        if not inFOV then continue end
        if not CanSee(targetPos, character) then continue end
        local score = fovDist + (dist * 0.01)
        if Config.Priority == "Lowest HP" then
            local hum = GetHumanoid(character)
            if hum then score = score - (1000 - hum.Health) * 10 end
        elseif Config.Priority == "Highest Level" then
            local leaderstats = player:FindFirstChild("leaderstats")
            if leaderstats then
                for _, stat in pairs(leaderstats:GetChildren()) do
                    if stat:IsA("IntValue") or stat:IsA("NumberValue") then
                        score = score - stat.Value * 100
                        break
                    end
                end
            end
        elseif Config.Priority == "Random" then
            score = math.random(1, 10000)
        end
        if score < bestScore then
            bestScore = score
            bestTarget = {Player = player, Character = character, Part = targetPart, Position = targetPos, Distance = dist}
        end
    end
    return bestTarget
end

local function AimAt(target)
    if not target or not target.Part then return end
    local targetCF = CFrame.new(Camera.CFrame.Position, target.Part.Position)
    local smoothFactor = Config.Smoothness / 100
    if smoothFactor >= 0.99 then
        Camera.CFrame = targetCF
    else
        Camera.CFrame = Camera.CFrame:Lerp(targetCF, smoothFactor * 0.15)
    end
end

local function SetupSilentAim()
    if Config.SilentAimHooked then return end
    Config.SilentAimHooked = true
    local oldRaycast = Workspace.Raycast
    SilentAimHooks.Raycast = oldRaycast
    Workspace.Raycast = function(self, origin, direction, params, ...)
        if Config.Enabled and Config.SilentAim and Config.CurrentTarget then
            local target = Config.CurrentTarget
            if target and target.Part then
                local newDirection = (target.Part.Position - origin).Unit * direction.Magnitude
                return oldRaycast(self, origin, newDirection, params, ...)
            end
        end
        return oldRaycast(self, origin, direction, params, ...)
    end
    local oldFindPartOnRay = Workspace.FindPartOnRay
    if oldFindPartOnRay then
        SilentAimHooks.FindPartOnRay = oldFindPartOnRay
        Workspace.FindPartOnRay = function(self, ray, ignore, ...)
            if Config.Enabled and Config.SilentAim and Config.CurrentTarget then
                local target = Config.CurrentTarget
                if target and target.Part then
                    local newDirection = (target.Part.Position - ray.Origin).Unit * ray.Direction.Magnitude
                    local newRay = Ray.new(ray.Origin, newDirection)
                    return oldFindPartOnRay(self, newRay, ignore, ...)
                end
            end
            return oldFindPartOnRay(self, ray, ignore, ...)
        end
    end
    local mt = getrawmetatable(game)
    if mt then
        local oldNamecall = mt.__namecall
        SilentAimHooks.Namecall = oldNamecall
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if Config.Enabled and Config.SilentAim and Config.CurrentTarget then
                if method == "FireServer" or method == "InvokeServer" then
                    local args = {...}
                    if #args >= 1 and typeof(args[1]) == "Vector3" then
                        local target = Config.CurrentTarget
                        if target and target.Part then
                            args[1] = target.Part.Position
                            return oldNamecall(self, unpack(args))
                        end
                    end
                    if #args >= 1 and typeof(args[1]) == "CFrame" then
                        local target = Config.CurrentTarget
                        if target and target.Part then
                            args[1] = CFrame.new(target.Part.Position)
                            return oldNamecall(self, unpack(args))
                        end
                    end
                end
            end
            return oldNamecall(self, ...)
        end)
        setreadonly(mt, true)
    end
end

local function RemoveSilentAim()
    if not Config.SilentAimHooked then return end
    if SilentAimHooks.Raycast then Workspace.Raycast = SilentAimHooks.Raycast end
    if SilentAimHooks.FindPartOnRay then Workspace.FindPartOnRay = SilentAimHooks.FindPartOnRay end
    if SilentAimHooks.Namecall then
        local mt = getrawmetatable(game)
        if mt then setreadonly(mt, false); mt.__namecall = SilentAimHooks.Namecall; setreadonly(mt, true) end
    end
    SilentAimHooks = {}
    Config.SilentAimHooked = false
end

local function IsTargetUnderCrosshair()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local ray = Camera:ViewportPointToRay(center.X, center.Y)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    local result = Workspace:Raycast(ray.Origin, ray.Direction * Config.MaxDistance, raycastParams)
    if result then
        local hitModel = result.Instance:FindFirstAncestorOfClass("Model")
        if hitModel then
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character == hitModel then
                    if Config.TeamCheck and IsTeammate(player) then return false end
                    local hum = GetHumanoid(hitModel)
                    return hum and hum.Health > 0
                end
            end
        end
    end
    return false
end

local function DoTriggerbot()
    if not Config.Triggerbot then return end
    local now = tick()
    if now - Config.LastTriggerTime < (Config.TriggerDelay / 1000) then return end
    if IsTargetUnderCrosshair() then
        Config.LastTriggerTime = now
        pcall(function() mouse1click() end)
    end
end

local FOVCircle = nil
local TargetCircle = nil

local function UpdateFOVCircle()
    if not FOVCircle then return end
    if Config.Enabled and Config.FOV < 360 then
        local fovRadius = (Config.FOV / 360) * math.min(Camera.ViewportSize.X, Camera.ViewportSize.Y) * 0.5
        FOVCircle.Visible = true
        FOVCircle.Radius = fovRadius
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
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

local function OnRenderStep()
    if not Config.Enabled then
        Config.CurrentTarget = nil
        if FOVCircle then FOVCircle.Visible = false end
        if TargetCircle then TargetCircle.Visible = false end
        return
    end
    local target = GetBestTarget()
    Config.CurrentTarget = target
    if target then
        if Config.SilentAim then
        elseif Config.Aiming then
            AimAt(target)
        end
        if Config.Triggerbot then DoTriggerbot() end
    end
    UpdateFOVCircle()
    UpdateTargetCircle()
end

local function OnInputBegan(input, gp)
    if gp then return end
    if input.UserInputType == Config.AimKey or input.KeyCode == Config.AimKey then
        Config.Aiming = true
    end
end

local function OnInputEnded(input, gp)
    if gp then return end
    if input.UserInputType == Config.AimKey or input.KeyCode == Config.AimKey then
        Config.Aiming = false
    end
end

local Module = {}

function Module.Init(manager)
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Visible = false
    FOVCircle.Thickness = 1.5
    FOVCircle.Color = Color3.fromRGB(255, 105, 180)
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
    if Config.SilentAim then SetupSilentAim() end
    if not RenderConnection then RenderConnection = RunService.RenderStepped:Connect(OnRenderStep) end
end

function Module.Disable()
    Config.Enabled = false
    Config.Aiming = false
    Config.CurrentTarget = nil
    RemoveSilentAim()
    if RenderConnection then RenderConnection:Disconnect(); RenderConnection = nil end
    if FOVCircle then FOVCircle.Visible = false end
    if TargetCircle then TargetCircle.Visible = false end
end

function Module.SetConfig(key, value)
    if key == "SilentAim" then
        Config.SilentAim = value
        if Config.Enabled then if value then SetupSilentAim() else RemoveSilentAim() end end
    elseif key == "Triggerbot" then Config.Triggerbot = value
    elseif key == "TeamCheck" then Config.TeamCheck = value
    elseif key == "WallCheck" then Config.WallCheck = value
    elseif key == "FOV" then Config.FOV = value
    elseif key == "Smoothness" then Config.Smoothness = value
    elseif key == "MaxDistance" then Config.MaxDistance = value
    elseif key == "TriggerDelay" then Config.TriggerDelay = value
    elseif key == "TargetPart" then Config.TargetPart = value
    elseif key == "Priority" then Config.Priority = value
    elseif key == "AimKey" then Config.AimKey = value
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
    Config.FOV = 90
    Config.Smoothness = 50
    Config.MaxDistance = 1000
    Config.TriggerDelay = 50
    Config.TargetPart = "Head"
    Config.Priority = "Closest"
    Config.AimKey = Enum.UserInputType.MouseButton2
end

return Module