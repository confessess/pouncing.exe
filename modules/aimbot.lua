-- Pouncing.exe | Aimbot Module v3.0
-- Lock-on, silent aim, triggerbot, toggle, sticky target
-- Fixed: Sticky mode persistence, priority modes, smoothness curve
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
    Priority = "Closest to Mouse",
    AimKey = Enum.KeyCode.Q,
    Prediction = false,
    ToggleMode = false,
    StickyTarget = false,
    CurrentTarget = nil,
    LastTriggerTime = 0,
    Aiming = false,
    SilentAimHooked = false,
    -- Sticky grace tracking
    StickyLostTime = 0,
    StickyGracePeriod = 0.6,
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
-- Target part
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
    return part.Position + velocity * (travelTime + 0.05)
end

-- ============================================================
-- Target validation
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
    -- Relaxed validation for sticky mode: only check alive, team, distance
    -- Skip FOV and wall checks so target stays locked even if behind cover or off-screen briefly
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

-- ============================================================
-- Target selection
-- ============================================================

local function GetBestTarget()
    -- Sticky mode: try to keep current target with relaxed validation
    if Config.StickyTarget and Config.CurrentTarget then
        if IsTargetValidSticky(Config.CurrentTarget) then
            -- Update position and part reference
            local part = Config.CurrentTarget.Character:FindFirstChild(Config.CurrentTarget.Part.Name)
            if part then
                Config.CurrentTarget.Part = part
                Config.CurrentTarget.Position = part.Position
                Config.StickyLostTime = 0
                return Config.CurrentTarget
            end
        else
            -- Target failed sticky validation — start grace period
            if Config.StickyLostTime == 0 then
                Config.StickyLostTime = tick()
            elseif tick() - Config.StickyLostTime < Config.StickyGracePeriod then
                -- Within grace period: keep target but update position if possible
                local part = Config.CurrentTarget.Character:FindFirstChild(Config.CurrentTarget.Part.Name)
                if part then
                    Config.CurrentTarget.Part = part
                    Config.CurrentTarget.Position = part.Position
                    return Config.CurrentTarget
                end
            end
            -- Grace period expired or target completely gone
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
            -- Pure screen-space distance from crosshair
            score = fovDist
        elseif Config.Priority == "Closest to Player" then
            -- Pure world distance
            score = dist
        elseif Config.Priority == "Lowest HP" then
            -- Lowest health first, tiebreak with FOV distance
            if hum then
                score = hum.Health + (fovDist * 0.1)
            else
                score = fovDist
            end
        elseif Config.Priority == "Highest HP" then
            -- Highest health first (for finishers/assists)
            if hum then
                score = -hum.Health + (fovDist * 0.1)
            else
                score = fovDist
            end
        elseif Config.Priority == "Random" then
            score = math.random(1, 10000)
        else
            -- Default hybrid (closest to mouse weighted)
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
-- Lock-on aiming
-- ============================================================

local function AimAt(target)
    if not target or not target.Part then return end
    local aimPos = PredictPosition(target)
    local targetCF = CFrame.new(Camera.CFrame.Position, aimPos)

    if Config.Smoothness <= 0 then
        Camera.CFrame = targetCF
    else
        -- Exponential decay curve: 0 = instant, gentle ramp through mid-range
        local alpha = math.clamp(math.exp(-Config.Smoothness * 0.045), 0.002, 1)
        Camera.CFrame = Camera.CFrame:Lerp(targetCF, alpha)
    end
end

-- ============================================================
-- Silent Aim
-- ============================================================

local function SetupSilentAim()
    if Config.SilentAimHooked then return end
    Config.SilentAimHooked = true

    -- Hook 1: Workspace.Raycast (modern games)
    local oldRaycast = Workspace.Raycast
    SilentAimHooks.Raycast = oldRaycast
    Workspace.Raycast = function(self, origin, direction, params, ...)
        if Config.Enabled and Config.SilentAim and Config.CurrentTarget then
            local t = Config.CurrentTarget
            if t and t.Part then
                local camPos = Camera.CFrame.Position
                if (origin - camPos).Magnitude < 8 then
                    local aimPos = PredictPosition(t)
                    return oldRaycast(self, origin, aimPos - origin, params, ...)
                end
            end
        end
        return oldRaycast(self, origin, direction, params, ...)
    end

    -- Hook 2: __namecall (FireServer/InvokeServer)
    local ok, mt = pcall(getrawmetatable, game)
    if ok and mt then
        local oldNamecall = mt.__namecall
        if oldNamecall then
            SilentAimHooks.Namecall = oldNamecall
            setreadonly(mt, false)

            mt.__namecall = newcclosure(function(self, ...)
                local method = getnamecallmethod()
                if Config.Enabled and Config.SilentAim and Config.CurrentTarget then
                    if method == "FireServer" or method == "InvokeServer" then
                        local args = {...}
                        local t = Config.CurrentTarget
                        if not t or not t.Part then return oldNamecall(self, ...) end

                        local aimPos = PredictPosition(t)
                        local camPos = Camera.CFrame.Position
                        local modified = false

                        local function IsHitPos(pos)
                            local d = (pos - camPos).Magnitude
                            return d > 0.5 and d < Config.MaxDistance * 2
                        end

                        for i = 1, #args do
                            local arg = args[i]
                            local argType = typeof(arg)

                            if argType == "Vector3" then
                                if IsHitPos(arg) then
                                    args[i] = aimPos
                                    modified = true
                                end
                            elseif argType == "CFrame" then
                                if IsHitPos(arg.Position) then
                                    args[i] = CFrame.new(aimPos)
                                    modified = true
                                end
                            elseif argType == "Ray" then
                                args[i] = Ray.new(arg.Origin, aimPos - arg.Origin)
                                modified = true
                            elseif argType == "Instance" and arg:IsA("BasePart") then
                                local model = arg:FindFirstAncestorOfClass("Model")
                                if model and model ~= LocalPlayer.Character then
                                    args[i] = t.Part
                                    modified = true
                                end
                            elseif argType == "table" then
                                for k, v in pairs(arg) do
                                    local vt = typeof(v)
                                    if vt == "Vector3" and IsHitPos(v) then
                                        arg[k] = aimPos
                                        modified = true
                                    elseif vt == "CFrame" and IsHitPos(v.Position) then
                                        arg[k] = CFrame.new(aimPos)
                                        modified = true
                                    elseif vt == "Instance" and v:IsA("BasePart") then
                                        local vm = v:FindFirstAncestorOfClass("Model")
                                        if vm and vm ~= LocalPlayer.Character then
                                            arg[k] = t.Part
                                            modified = true
                                        end
                                    end
                                end
                            end
                        end

                        if modified then
                            return oldNamecall(self, unpack(args))
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
    if SilentAimHooks.Raycast then Workspace.Raycast = SilentAimHooks.Raycast end
    if SilentAimHooks.Namecall then
        local ok, mt = pcall(getrawmetatable, game)
        if ok and mt then
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
    Config.StickyLostTime = 0
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
    Config.Priority = "Mouse"
    Config.AimKey = Enum.KeyCode.Q
    Config.Prediction = false
    Config.ToggleMode = false
    Config.StickyTarget = false
    Config.CurrentTarget = nil
    Config.Aiming = false
    Config.StickyLostTime = 0
    RemoveSilentAim()
end

return Module