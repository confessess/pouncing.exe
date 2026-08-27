-- Pouncing.exe | Aimbot Module v2.4
-- Lock-on, silent aim, triggerbot, prediction, proper FOV
-- Silent aim: multi-layer (Raycast + FindPartOnRay* + __namecall with table scanning)
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
    FOV = 120,
    Smoothness = 50,
    MaxDistance = 1000,
    TriggerDelay = 50,
    TargetPart = "Head",
    Priority = "Closest",
    AimKey = Enum.KeyCode.Q,
    Prediction = false,
    CurrentTarget = nil,
    LastTriggerTime = 0,
    Aiming = false,
    SilentAimHooked = false,
}

local SilentAimHooks = {}
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
    if not LocalPlayer.Team or not player.Team then return false end
    return player.Team == LocalPlayer.Team
end

local function GetDistance(position)
    return (position - Camera.CFrame.Position).Magnitude
end

-- ============================================================
-- FOV: proper angular → pixel conversion
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
    local fovRadius = GetFOVRadiusPixels()
    return distFromCenter <= fovRadius, distFromCenter
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
-- Target part selection
-- ============================================================

local function GetTargetPart(character)
    if Config.TargetPart == "Random" then
        local parts = {"Head", "HumanoidRootPart", "UpperTorso", "Torso"}
        return character:FindFirstChild(parts[math.random(1, #parts)])
    end
    return character:FindFirstChild(Config.TargetPart)
        or character:FindFirstChild("Head")
        or character:FindFirstChild("HumanoidRootPart")
end

-- ============================================================
-- Prediction: simple velocity compensation
-- ============================================================

local function PredictPosition(target)
    if not Config.Prediction then return target.Part.Position end
    local part = target.Part
    local velocity = part.AssemblyLinearVelocity or part.Velocity or Vector3.new()
    local dist = (part.Position - Camera.CFrame.Position).Magnitude
    local bulletSpeed = 1000
    local travelTime = dist / bulletSpeed
    local ping = 0.05
    return part.Position + velocity * (travelTime + ping)
end

-- ============================================================
-- Target selection
-- ============================================================

local function GetBestTarget()
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

        local score = fovDist + (dist * 0.02)

        if Config.Priority == "Lowest HP" then
            local hum = GetHumanoid(character)
            if hum then score = score - (hum.MaxHealth - hum.Health) * 2 end
        elseif Config.Priority == "Highest Level" then
            local leaderstats = player:FindFirstChild("leaderstats")
            if leaderstats then
                for _, stat in pairs(leaderstats:GetChildren()) do
                    if stat:IsA("IntValue") or stat:IsA("NumberValue") then
                        score = score - stat.Value * 10
                        break
                    end
                end
            end
        elseif Config.Priority == "Random" then
            score = math.random(1, 10000)
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
-- Aiming
-- ============================================================

local function AimAt(target)
    if not target or not target.Part then return end
    local aimPos = PredictPosition(target)
    local targetCF = CFrame.new(Camera.CFrame.Position, aimPos)
    local alpha = (101 - Config.Smoothness) / 500
    alpha = math.clamp(alpha, 0.001, 0.5)
    Camera.CFrame = Camera.CFrame:Lerp(targetCF, alpha)
end

-- ============================================================
-- Silent Aim — Multi-layer
-- ============================================================

local function SetupSilentAim()
    if Config.SilentAimHooked then return end
    Config.SilentAimHooked = true

    -- ── Layer 1: Workspace.Raycast ──
    local oldRaycast = Workspace.Raycast
    SilentAimHooks.Raycast = oldRaycast
    Workspace.Raycast = function(self, origin, direction, params, ...)
        if Config.Enabled and Config.SilentAim and Config.CurrentTarget then
            local t = Config.CurrentTarget
            if t and t.Part then
                local aimPos = PredictPosition(t)
                local newDir = (aimPos - origin)
                return oldRaycast(self, origin, newDir, params, ...)
            end
        end
        return oldRaycast(self, origin, direction, params, ...)
    end

    -- ── Layer 2: FindPartOnRay variants ──
    local oldFindPartOnRay = Workspace.FindPartOnRay
    if oldFindPartOnRay then
        SilentAimHooks.FindPartOnRay = oldFindPartOnRay
        Workspace.FindPartOnRay = function(self, ray, ...)
            if Config.Enabled and Config.SilentAim and Config.CurrentTarget then
                local t = Config.CurrentTarget
                if t and t.Part then
                    local aimPos = PredictPosition(t)
                    local newDir = (aimPos - ray.Origin)
                    local newRay = Ray.new(ray.Origin, newDir)
                    return oldFindPartOnRay(self, newRay, ...)
                end
            end
            return oldFindPartOnRay(self, ray, ...)
        end
    end

    local oldFindPartOnRayWithIgnoreList = Workspace.FindPartOnRayWithIgnoreList
    if oldFindPartOnRayWithIgnoreList then
        SilentAimHooks.FindPartOnRayWithIgnoreList = oldFindPartOnRayWithIgnoreList
        Workspace.FindPartOnRayWithIgnoreList = function(self, ray, ignoreList, ...)
            if Config.Enabled and Config.SilentAim and Config.CurrentTarget then
                local t = Config.CurrentTarget
                if t and t.Part then
                    local aimPos = PredictPosition(t)
                    local newDir = (aimPos - ray.Origin)
                    local newRay = Ray.new(ray.Origin, newDir)
                    return oldFindPartOnRayWithIgnoreList(self, newRay, ignoreList, ...)
                end
            end
            return oldFindPartOnRayWithIgnoreList(self, ray, ignoreList, ...)
        end
    end

    local oldFindPartOnRayWithWhitelist = Workspace.FindPartOnRayWithWhitelist
    if oldFindPartOnRayWithWhitelist then
        SilentAimHooks.FindPartOnRayWithWhitelist = oldFindPartOnRayWithWhitelist
        Workspace.FindPartOnRayWithWhitelist = function(self, ray, whitelist, ...)
            if Config.Enabled and Config.SilentAim and Config.CurrentTarget then
                local t = Config.CurrentTarget
                if t and t.Part then
                    local aimPos = PredictPosition(t)
                    local newDir = (aimPos - ray.Origin)
                    local newRay = Ray.new(ray.Origin, newDir)
                    return oldFindPartOnRayWithWhitelist(self, newRay, whitelist, ...)
                end
            end
            return oldFindPartOnRayWithWhitelist(self, ray, whitelist, ...)
        end
    end

    -- ── Layer 3: __namecall (broad, scans tables, no name filter) ──
    local success, mt = pcall(getrawmetatable, game)
    if success and mt then
        local oldNamecall = mt.__namecall
        if oldNamecall then
            SilentAimHooks.Namecall = oldNamecall
            setreadonly(mt, false)

            mt.__namecall = newcclosure(function(self, ...)
                local method = getnamecallmethod()
                if Config.Enabled and Config.SilentAim and Config.CurrentTarget then
                    if method == "FireServer" or method == "InvokeServer" then
                        local args = {...}
                        local modified = false
                        local t = Config.CurrentTarget

                        if t and t.Part then
                            local aimPos = PredictPosition(t)
                            local camPos = Camera.CFrame.Position

                            local function IsLikelyAimPos(pos)
                                local dist = (pos - camPos).Magnitude
                                return dist > 1 and dist < Config.MaxDistance * 2
                            end

                            local function ProcessArg(arg, parentTbl, key)
                                local argType = typeof(arg)

                                if argType == "Vector3" then
                                    if IsLikelyAimPos(arg) then
                                        if parentTbl then parentTbl[key] = aimPos end
                                        return aimPos, true
                                    end
                                elseif argType == "CFrame" then
                                    if IsLikelyAimPos(arg.Position) then
                                        local newCF = CFrame.new(aimPos)
                                        if parentTbl then parentTbl[key] = newCF end
                                        return newCF, true
                                    end
                                elseif argType == "Instance" then
                                    if arg:IsA("BasePart") then
                                        -- Only replace if it's the player's own character part
                                        -- (some games send the shooter's arm as arg)
                                        local model = arg:FindFirstAncestorOfClass("Model")
                                        if model and model ~= t.Character then
                                            if parentTbl then parentTbl[key] = t.Part end
                                            return t.Part, true
                                        end
                                    end
                                elseif argType == "Ray" then
                                    local newDir = (aimPos - arg.Origin)
                                    local newRay = Ray.new(arg.Origin, newDir)
                                    if parentTbl then parentTbl[key] = newRay end
                                    return newRay, true
                                elseif argType == "table" then
                                    for k, v in pairs(arg) do
                                        local newV, didMod = ProcessArg(v, arg, k)
                                        if didMod then modified = true end
                                    end
                                end
                                return arg, false
                            end

                            for i = 1, #args do
                                local newArg, didMod = ProcessArg(args[i], args, i)
                                if didMod then modified = true end
                            end

                            if modified then
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
end

local function RemoveSilentAim()
    if not Config.SilentAimHooked then return end

    if SilentAimHooks.Raycast then
        Workspace.Raycast = SilentAimHooks.Raycast
    end
    if SilentAimHooks.FindPartOnRay then
        Workspace.FindPartOnRay = SilentAimHooks.FindPartOnRay
    end
    if SilentAimHooks.FindPartOnRayWithIgnoreList then
        Workspace.FindPartOnRayWithIgnoreList = SilentAimHooks.FindPartOnRayWithIgnoreList
    end
    if SilentAimHooks.FindPartOnRayWithWhitelist then
        Workspace.FindPartOnRayWithWhitelist = SilentAimHooks.FindPartOnRayWithWhitelist
    end
    if SilentAimHooks.Namecall then
        local success, mt = pcall(getrawmetatable, game)
        if success and mt then
            setreadonly(mt, false)
            mt.__namecall = SilentAimHooks.Namecall
            setreadonly(mt, true)
        end
    end

    SilentAimHooks = {}
    Config.SilentAimHooked = false
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
-- Visuals: FOV + Target circles
-- ============================================================

local FOVCircle = nil
local TargetCircle = nil

local function UpdateFOVCircle()
    if not FOVCircle then return end
    if Config.Enabled and Config.FOV < 360 then
        local radius = GetFOVRadiusPixels()
        FOVCircle.Visible = true
        FOVCircle.Radius = radius
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

-- ============================================================
-- Render loop
-- ============================================================

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

-- ============================================================
-- Module API
-- ============================================================

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
    if not RenderConnection then
        RenderConnection = RunService.RenderStepped:Connect(OnRenderStep)
    end
end

function Module.Disable()
    Config.Enabled = false
    Config.Aiming = false
    Config.CurrentTarget = nil
    RemoveSilentAim()
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
        if Config.Enabled then
            if value then SetupSilentAim() else RemoveSilentAim() end
        end
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
    elseif key == "Prediction" then Config.Prediction = value
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
    Config.Smoothness = 50
    Config.MaxDistance = 1000
    Config.TriggerDelay = 50
    Config.TargetPart = "Head"
    Config.Priority = "Closest"
    Config.AimKey = Enum.KeyCode.Q
    Config.Prediction = false
    Config.CurrentTarget = nil
    Config.Aiming = false
    RemoveSilentAim()
end

return Module