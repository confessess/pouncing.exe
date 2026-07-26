
# ============================================================
# 6. MODULES/AIMBOT.LUA - Aimbot Module (structured placeholder)
# ============================================================
module_aimbot = '''-- ============================================================
-- Pouncing.exe | Aimbot Module
-- Lock-on and silent aim functionality
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Utils = getfenv()["PouncingUtils"]

-- ============================================================
-- Config
-- ============================================================

local Config = {
    Enabled = false,
    SilentAim = false,
    AutoWall = false,
    TeamCheck = false,
    FOV = 90,
    Smoothness = 50,
    MaxDistance = 1000,
    TargetPart = "Head",
    
    -- Internal
    CurrentTarget = nil,
    AimKey = Enum.UserInputType.MouseButton2
}

-- ============================================================
-- Targeting Logic
-- ============================================================

local function GetCharacter(player)
    return player and player.Character
end

local function GetHumanoid(character)
    return character and character:FindFirstChildOfClass("Humanoid")
end

local function GetRootPart(character)
    return character and (character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso"))
end

local function GetHead(character)
    return character and (character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart"))
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
    
    -- FOV radius based on config
    local fovRadius = (Config.FOV / 360) * math.min(Camera.ViewportSize.X, Camera.ViewportSize.Y) * 0.5
    
    return distFromCenter <= fovRadius, distFromCenter
end

local function CanSee(targetPos)
    if not Config.AutoWall then
        local origin = Camera.CFrame.Position
        local direction = (targetPos - origin).Unit * (targetPos - origin).Magnitude
        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
        
        local result = Workspace:Raycast(origin, direction, raycastParams)
        if result then
            return false
        end
    end
    return true
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
        
        local targetPart = Config.TargetPart == "Head" and GetHead(character) or GetRootPart(character)
        if not targetPart then continue end
        
        local targetPos = targetPart.Position
        local dist = GetDistance(targetPos)
        if dist > Config.MaxDistance then continue end
        
        local inFOV, fovDist = IsInFOV(targetPos)
        if not inFOV then continue end
        
        if not CanSee(targetPos) then continue end
        
        -- Score: closer FOV distance = better
        local score = fovDist + (dist * 0.01)
        if score < bestScore then
            bestScore = score
            bestTarget = {
                Player = player,
                Character = character,
                Part = targetPart,
                Position = targetPos,
                Distance = dist
            }
        end
    end
    
    return bestTarget
end

-- ============================================================
-- Aim Logic
-- ============================================================

local RenderConnection = nil
local Aiming = false

local function AimAt(target)
    if not target or not target.Part then return end
    
    local targetCF = CFrame.new(Camera.CFrame.Position, target.Part.Position)
    local smoothFactor = Config.Smoothness / 100
    
    if smoothFactor >= 0.99 then
        -- Instant snap
        Camera.CFrame = targetCF
    else
        -- Smooth interpolation
        local currentCF = Camera.CFrame
        local lerped = currentCF:Lerp(targetCF, smoothFactor * 0.15)
        Camera.CFrame = lerped
    end
end

local function SilentAimAt(target)
    -- Silent aim modifies bullet trajectory or raycast results
    -- This is game-dependent and requires hooking into the game's
    -- shooting mechanics. Placeholder implementation.
    if not target or not target.Part then return end
    
    -- Store target for external use
    Config.CurrentTarget = target
end

local function OnRenderStep()
    if not Config.Enabled then return end
    if not Aiming and not Config.SilentAim then return end
    
    local target = GetBestTarget()
    Config.CurrentTarget = target
    
    if target then
        if Config.SilentAim then
            SilentAimAt(target)
        elseif Aiming then
            AimAt(target)
        end
    end
end

-- ============================================================
-- FOV Circle Drawing
-- ============================================================

local FOVCircle = nil

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

-- ============================================================
-- Input Handling
-- ============================================================

local InputBeganConnection = nil
local InputEndedConnection = nil

local function OnInputBegan(input, gp)
    if gp then return end
    if input.UserInputType == Config.AimKey then
        Aiming = true
    end
end

local function OnInputEnded(input, gp)
    if gp then return end
    if input.UserInputType == Config.AimKey then
        Aiming = false
    end
end

-- ============================================================
-- Module Interface
-- ============================================================

local Module = {}

function Module.Init(manager)
    -- Create FOV circle
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Visible = false
    FOVCircle.Thickness = 1.5
    FOVCircle.Color = Color3.fromRGB(255, 105, 180)
    FOVCircle.Transparency = 0.5
    FOVCircle.NumSides = 64
    FOVCircle.Filled = false
    
    InputBeganConnection = UserInputService.InputBegan:Connect(OnInputBegan)
    InputEndedConnection = UserInputService.InputEnded:Connect(OnInputEnded)
end

function Module.Enable()
    Config.Enabled = true
    if not RenderConnection then
        RenderConnection = RunService.RenderStepped:Connect(function()
            OnRenderStep()
            UpdateFOVCircle()
        end)
    end
end

function Module.Disable()
    Config.Enabled = false
    Aiming = false
    Config.CurrentTarget = nil
    if RenderConnection then
        RenderConnection:Disconnect()
        RenderConnection = nil
    end
    if FOVCircle then
        FOVCircle.Visible = false
    end
end

function Module.SetConfig(key, value)
    if key == "SilentAim" then
        Config.SilentAim = value
    elseif key == "AutoWall" then
        Config.AutoWall = value
    elseif key == "TeamCheck" then
        Config.TeamCheck = value
    elseif key == "FOV" then
        Config.FOV = value
    elseif key == "Smoothness" then
        Config.Smoothness = value
    elseif key == "MaxDistance" then
        Config.MaxDistance = value
    end
end

function Module.GetConfig()
    return Config
end

return Module
'''

with open(f"{output_dir}/modules/aimbot.lua", "w") as f:
    f.write(module_aimbot)

print("modules/aimbot.lua written")
