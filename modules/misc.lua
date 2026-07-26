
# ============================================================
# 8. MODULES/MISC.LUA - Misc Features Module
# ============================================================
misc = '''-- ============================================================
-- Pouncing.exe | Misc Module
-- Movement, visual, and combat tweaks
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ============================================================
-- Config
-- ============================================================

local Config = {
    Enabled = false,
    
    -- Movement
    BunnyHop = false,
    AutoStrafe = false,
    SpeedHack = false,
    SpeedMultiplier = 1.5,
    
    -- Combat
    AntiAim = false,
    FastSwitch = false,
    
    -- Visual
    Fullbright = false,
    NoFog = false,
    
    -- Internal
    Connections = {},
    OriginalValues = {},
    State = {
        Jumping = false,
        StrafeDir = 1,
        LastSwitch = 0
    }
}

-- ============================================================
-- Bunny Hop
-- ============================================================

local function DoBunnyHop()
    if not Config.BunnyHop then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        if hum.FloorMaterial ~= Enum.Material.Air then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
            Config.State.Jumping = true
        end
    end
end

-- ============================================================
-- Auto Strafe
-- ============================================================

local function DoAutoStrafe()
    if not Config.AutoStrafe then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    if hum.FloorMaterial == Enum.Material.Air and Config.State.Jumping then
        local mousePos = UserInputService:GetMouseLocation()
        local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        local delta = mousePos.X - screenCenter.X
        
        if math.abs(delta) > 10 then
            Config.State.StrafeDir = delta > 0 and 1 or -1
        end
        
        local strafeForce = root.CFrame.RightVector * Config.State.StrafeDir * 3
        root.Velocity = Vector3.new(strafeForce.X, root.Velocity.Y, strafeForce.Z)
    else
        Config.State.Jumping = false
    end
end

-- ============================================================
-- Speed Hack
-- ============================================================

local function DoSpeedHack()
    if not Config.SpeedHack then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    
    if Config.OriginalValues.WalkSpeed == nil then
        Config.OriginalValues.WalkSpeed = hum.WalkSpeed
    end
    
    hum.WalkSpeed = Config.OriginalValues.WalkSpeed * Config.SpeedMultiplier
end

local function ResetSpeed()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    
    if Config.OriginalValues.WalkSpeed ~= nil then
        hum.WalkSpeed = Config.OriginalValues.WalkSpeed
    end
end

-- ============================================================
-- Anti-Aim
-- ============================================================

local function DoAntiAim()
    if not Config.AntiAim then return end
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    -- Jitter aim — rapidly rotate torso to break hit registration
    local jitter = math.random(-90, 90)
    root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(jitter), 0)
end

-- ============================================================
-- Fast Switch
-- ============================================================

local function DoFastSwitch()
    if not Config.FastSwitch then return end
    local char = LocalPlayer.Character
    if not char then return end
    
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return end
    
    -- Reduce equip cooldowns
    for _, tool in pairs(backpack:GetChildren()) do
        if tool:IsA("Tool") then
            local cd = tool:FindFirstChild("Cooldown") or tool:FindFirstChild("EquipCooldown")
            if cd and cd:IsA("NumberValue") then
                if Config.OriginalValues[tool] == nil then
                    Config.OriginalValues[tool] = cd.Value
                end
                cd.Value = 0
            end
        end
    end
end

-- ============================================================
-- Fullbright
-- ============================================================

local function DoFullbright()
    if not Config.Fullbright then return end
    
    if Config.OriginalValues.Brightness == nil then
        Config.OriginalValues.Brightness = Lighting.Brightness
        Config.OriginalValues.GlobalShadows = Lighting.GlobalShadows
        Config.OriginalValues.Ambient = Lighting.Ambient
        Config.OriginalValues.OutdoorAmbient = Lighting.OutdoorAmbient
    end
    
    Lighting.Brightness = 2
    Lighting.GlobalShadows = false
    Lighting.Ambient = Color3.fromRGB(255, 255, 255)
    Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
end

local function ResetLighting()
    if Config.OriginalValues.Brightness ~= nil then
        Lighting.Brightness = Config.OriginalValues.Brightness
        Lighting.GlobalShadows = Config.OriginalValues.GlobalShadows
        Lighting.Ambient = Config.OriginalValues.Ambient
        Lighting.OutdoorAmbient = Config.OriginalValues.OutdoorAmbient
    end
end

-- ============================================================
-- No Fog
-- ============================================================

local function DoNoFog()
    if not Config.NoFog then return end
    
    if Config.OriginalValues.FogStart == nil then
        Config.OriginalValues.FogStart = Lighting.FogStart
        Config.OriginalValues.FogEnd = Lighting.FogEnd
        Config.OriginalValues.FogColor = Lighting.FogColor
    end
    
    Lighting.FogStart = 0
    Lighting.FogEnd = 999999
    Lighting.FogColor = Color3.fromRGB(255, 255, 255)
end

local function ResetFog()
    if Config.OriginalValues.FogStart ~= nil then
        Lighting.FogStart = Config.OriginalValues.FogStart
        Lighting.FogEnd = Config.OriginalValues.FogEnd
        Lighting.FogColor = Config.OriginalValues.FogColor
    end
end

-- ============================================================
-- Render Loop
-- ============================================================

local RenderConnection = nil

local function OnRenderStep()
    DoBunnyHop()
    DoAutoStrafe()
    DoSpeedHack()
    DoAntiAim()
    DoFastSwitch()
    DoFullbright()
    DoNoFog()
end

-- ============================================================
-- Module Interface
-- ============================================================

local Module = {}

function Module.Init()
    -- Character respawn handler
    LocalPlayer.CharacterAdded:Connect(function(char)
        task.wait(0.3)
        Config.OriginalValues.WalkSpeed = nil
        if Config.Enabled then
            if Config.SpeedHack then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    Config.OriginalValues.WalkSpeed = hum.WalkSpeed
                end
            end
        end
    end)
end

function Module.Enable()
    Config.Enabled = true
    
    if not RenderConnection then
        RenderConnection = RunService.RenderStepped:Connect(OnRenderStep)
    end
    
    -- Save original values
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and Config.OriginalValues.WalkSpeed == nil then
            Config.OriginalValues.WalkSpeed = hum.WalkSpeed
        end
    end
    
    if Config.OriginalValues.Brightness == nil then
        Config.OriginalValues.Brightness = Lighting.Brightness
        Config.OriginalValues.GlobalShadows = Lighting.GlobalShadows
        Config.OriginalValues.Ambient = Lighting.Ambient
        Config.OriginalValues.OutdoorAmbient = Lighting.OutdoorAmbient
        Config.OriginalValues.FogStart = Lighting.FogStart
        Config.OriginalValues.FogEnd = Lighting.FogEnd
        Config.OriginalValues.FogColor = Lighting.FogColor
    end
end

function Module.Disable()
    Config.Enabled = false
    Config.State.Jumping = false
    
    if RenderConnection then
        RenderConnection:Disconnect()
        RenderConnection = nil
    end
    
    -- Reset everything
    ResetSpeed()
    ResetLighting()
    ResetFog()
    
    -- Reset tool cooldowns
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, tool in pairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and Config.OriginalValues[tool] ~= nil then
                local cd = tool:FindFirstChild("Cooldown") or tool:FindFirstChild("EquipCooldown")
                if cd and cd:IsA("NumberValue") then
                    cd.Value = Config.OriginalValues[tool]
                end
            end
        end
    end
end

function Module.SetConfig(key, value)
    if key == "BunnyHop" then
        Config.BunnyHop = value
    elseif key == "AutoStrafe" then
        Config.AutoStrafe = value
    elseif key == "SpeedHack" then
        Config.SpeedHack = value
        if not value then ResetSpeed() end
    elseif key == "AntiAim" then
        Config.AntiAim = value
    elseif key == "FastSwitch" then
        Config.FastSwitch = value
        if not value then
            local backpack = LocalPlayer:FindFirstChild("Backpack")
            if backpack then
                for _, tool in pairs(backpack:GetChildren()) do
                    if tool:IsA("Tool") and Config.OriginalValues[tool] ~= nil then
                        local cd = tool:FindFirstChild("Cooldown") or tool:FindFirstChild("EquipCooldown")
                        if cd and cd:IsA("NumberValue") then
                            cd.Value = Config.OriginalValues[tool]
                        end
                    end
                end
            end
        end
    elseif key == "Fullbright" then
        Config.Fullbright = value
        if not value then ResetLighting() end
    elseif key == "NoFog" then
        Config.NoFog = value
        if not value then ResetFog() end
    elseif key == "SpeedMultiplier" then
        Config.SpeedMultiplier = math.clamp(value, 1, 5)
    end
end

function Module.GetConfig()
    return Config
end

return Module
'''

with open(f"{output_dir}/modules/misc.lua", "w") as f:
    f.write(misc)

print("modules/misc.lua written")
