-- Pouncing.exe | Aimbot Module v2.5
-- Lock-on, silent aim, triggerbot, prediction, toggle mode, sticky target
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
    Smoothness = 15,
    MaxDistance = 1000,
    TriggerDelay = 50,
    TargetPart = "Head",
    Priority = "Closest",
    AimKey = Enum.KeyCode.Q,
    Prediction = false,
    ToggleMode = false,
    StickyTarget = false,
    CurrentTarget = nil,
    LastTriggerTime = 0,
    Aiming = false,
    SilentAimHooked = false,
    SilentAimAvailable = false,
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
-- Prediction
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

local function IsTargetValid(target)
    if not target then return false end
    if not target.Player or not target.Character then return false end
    if not IsAlive(target.Character) then return false end
    if Config.TeamCheck and IsTeammate(target.Player) then return false end
    local part = target.Character:FindFirstChild(target.Part.Name)
    if not part then return false end
    local dist = GetDistance(part.Position)
    if dist > Config.MaxDistance then return false end
    local inFOV = IsInFOV(part.Position)
    if not inFOV then return false end
    if not CanSee(part.Position, target.Character) then return false end
    return true
end

local function GetBestTarget()
    -- Sticky target: keep current if still valid
    if Config.StickyTarget and IsTargetValid(Config.CurrentTarget) then
        local part = Config.CurrentTarget.Character:FindFirstChild(Config.CurrentTarget.Part.Name)
        if part then
            Config.CurrentTarget.Part = part
            Config.CurrentTarget.Position = part.Position
            return Config.CurrentTarget
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
-- Aiming — 0 smoothness = instant snap
-- ============================================================

local function AimAt(target)
    if not target or not target.Part then return end
    local aimPos = PredictPosition(target)
    local targetCF = CFrame.new(Camera.CFrame.Position, aimPos)

    if Config.Smoothness <= 0 then
        Camera.CFrame = targetCF
    else
        local alpha = math.clamp((101 - Config.Smoothness) / 100, 0.005, 1.0)
        Camera.CFrame = Camera.CFrame:Lerp(targetCF, alpha)
    end
end

-- ============================================================
-- Silent Aim
-- ============================================================

local function SetupSilentAim()
    if Config.SilentAimHooked then return end
    Config.SilentAimHooked = true

    -- ── Layer 1: Workspace.Raycast ──
    -- Only redirect rays that originate from the camera (weapon rays)
    local oldRaycast = Workspace.Raycast
    SilentAimHooks.Raycast = oldRaycast
    Workspace.Raycast = function(self, origin, direction, params, ...)
        if Config.Enabled and Config.SilentAim and Config.CurrentTarget then
            local t = Config.CurrentTarget
            if t and t.Part then
                -- Only weapon rays originate from camera
                local camPos = Camera.CFrame.Position
                if (origin - camPos).Magnitude < 5 then
                    local aimPos = PredictPosition(t)
                    local newDir = (aimPos - origin)
                    return oldRaycast(self, origin, newDir, params, ...)
                end
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
                    local camPos = Camera.CFrame.Position
                    if (ray.Origin - camPos).Magnitude < 5 then
                        local aimPos = PredictPosition(t)
                        local newDir = (aimPos - ray.Origin)
                        local newRay = Ray.new(ray.Origin, newDir)
                        return oldFindPartOnRay(self, newRay, ...)
                    end
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
                    local camPos = Camera.CFrame.Position
                    if (ray.Origin - camPos).Magnitude < 5 then
                        local aimPos = PredictPosition(t)
                        local newDir = (aimPos - ray.Origin)
                        local newRay = Ray.new(ray.Origin, newDir)
                        return oldFindPartOnRayWithIgnoreList(self, newRay, ignoreList, ...)
                    end
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
                    local camPos = Camera.CFrame.Position
                    if (ray.Origin - camPos).Magnitude < 5 then
                        local aimPos = PredictPosition(t)
                        local newDir = (aimPos - ray.Origin)
                        local newRay = Ray.new(ray.Origin, newDir)
                        return oldFindPartOnRayWithWhitelist(self, newRay, whitelist, ...)
                    end
                end
            end
            return oldFindPartOnRayWithWhitelist(self, ray, whitelist, ...)
        end
    end

    -- ── Layer 3: __namecall ──
    local hasNewcclosure = typeof(newcclosure) == "function"
    local hasGetnamecallmethod = typeof(getnamecallmethod) == "function"
    local hasGetrawmetatable = typeof(getrawmetatable) == "function"
    local hasSetreadonly = typeof(setreadonly) == "function"

    if hasGetrawmetatable and hasSetreadonly then
        local success, mt = pcall(getrawmetatable, game)
        if success and mt then
            local oldNamecall = mt.__namecall
            if oldNamecall then
                SilentAimHooks.Namecall = oldNamecall
                setreadonly(mt, false)

                local function ProcessArg(arg, parentTbl, key, depth)
                    depth = depth or 0
                    if depth > 3 then return arg, false end

                    local argType = typeof(arg)
                    local t = Config.CurrentTarget
                    if not t or not t.Part then return arg, false end
                    local aimPos = PredictPosition(t)
                    local camPos = Camera.CFrame.Position

                    if argType == "Vector3" then
                        local dist = (arg - camPos).Magnitude
                        if dist > 1 and dist < Config.MaxDistance * 3 then
                            if parentTbl then parentTbl[key] = aimPos end
                            return aimPos, true
                        end
                    elseif argType == "CFrame" then
                        local dist = (arg.Position - camPos).Magnitude
                        if dist > 1 and dist < Config.MaxDistance * 3 then
                            local newCF = CFrame.new(aimPos)
                            if parentTbl then parentTbl[key] = newCF end
                            return newCF, true
                        end
                    elseif argType == "Instance" then
                        if arg:IsA("BasePart") then
                            local model = arg:FindFirstAncestorOfClass("Model")
                            if model and model ~= t.Character and model ~= LocalPlayer.Character then
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
                        local modified = false
                        for k, v in pairs(arg) do
                            local newV, didMod = ProcessArg(v, arg, k, depth + 1)
                            if didMod then modified = true end
                        end
                        return arg, modified
                    end
                    return arg, false
                end

                if hasNewcclosure and hasGetnamecallmethod then
                    mt.__namecall = newcclosure(function(self, ...)
                        local method = getnamecallmethod()
                        if Config.Enabled and Config.SilentAim and Config.CurrentTarget then
                            if method == "FireServer" or method == "InvokeServer" then
                                local args = {...}
                                local modified = false
                                for i = 1, #args do
                                    local _, didMod = ProcessArg(args[i], args, i, 0)
                                    if didMod then modified = true end
                                end
                                if modified then
                                    return oldNamecall(self, unpack(args))
                                end
                            end
                        end
                        return oldNamecall(self, ...)
                    end)
                else
                    -- Fallback: raw hook without newcclosure
                    mt.__namecall = function(self, ...)
                        local method = getnamecallmethod()
                        if Config.Enabled and Config.SilentAim and Config.CurrentTarget then
                            if method == "FireServer" or method == "InvokeServer" then
                                local args = {...}
                                local modified = false
                                for i = 1, #args do
                                    local _, didMod = ProcessArg(args[i], args, i, 0)
                                    if didMod then modified = true end
                                end
                                if modified then
                                    return oldNamecall(self, unpack(args))
                                end
                            end
                        end
                        return oldNamecall(self, ...)
                    end
                end

                setreadonly(mt, true)
                Config.SilentAimAvailable = true
            end
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
    Config.SilentAimAvailable = false
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
    if Config.Enabled then
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
    elseif key == "ToggleMode" then
        Config.ToggleMode = value
        if not value then Config.Aiming = false end
    elseif key == "StickyTarget" then Config.StickyTarget = value
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
    Config.Priority = "Closest"
    Config.AimKey = Enum.KeyCode.Q
    Config.Prediction = false
    Config.ToggleMode = false
    Config.StickyTarget = false
    Config.CurrentTarget = nil
    Config.Aiming = false
    RemoveSilentAim()
end

return Module