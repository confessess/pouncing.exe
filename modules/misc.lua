-- Pouncing.exe | Misc Module v2.1
-- Movement, visual, combat tweaks + fly, noclip, anti-afk
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Config = {
    Enabled = false, BunnyHop = false, AutoStrafe = false, SpeedHack = false, Fly = false,
    InfiniteJump = false, NoClip = false, AntiAFK = false, AntiAim = false, FastSwitch = false,
    Fullbright = false, NoFog = false, NoShadows = false, CustomTime = false,
    WalkSpeed = 50, JumpPower = 100, FlySpeed = 50, FlyKey = Enum.KeyCode.F,
    SpeedKey = Enum.KeyCode.LeftShift, NoClipKey = Enum.KeyCode.N,
    Brightness = 2, TimeOfDay = 12,
    Connections = {}, OriginalValues = {},
    State = {Jumping = false, StrafeDir = 1, LastSwitch = 0, Flying = false, NoClipping = false, FlyBodyGyro = nil, FlyBodyVelocity = nil}
}

local function DoBunnyHop()
    if not Config.BunnyHop then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        if hum.FloorMaterial ~= Enum.Material.Air then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
            Config.State.Jumping = true
        end
    end
end

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
        if math.abs(delta) > 10 then Config.State.StrafeDir = delta > 0 and 1 or -1 end
        local strafeForce = root.CFrame.RightVector * Config.State.StrafeDir * 3
        root.Velocity = Vector3.new(strafeForce.X, root.Velocity.Y, strafeForce.Z)
    else
        Config.State.Jumping = false
    end
end

local function DoSpeedHack()
    if not Config.SpeedHack then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if Config.OriginalValues.WalkSpeed == nil then Config.OriginalValues.WalkSpeed = hum.WalkSpeed end
    local speed = Config.WalkSpeed
    if UserInputService:IsKeyDown(Config.SpeedKey) then speed = speed * 1.5 end
    hum.WalkSpeed = speed
end

local function ResetSpeed()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if Config.OriginalValues.WalkSpeed ~= nil then hum.WalkSpeed = Config.OriginalValues.WalkSpeed end
end

local function StartFly()
    if Config.State.Flying then return end
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = true end
    Config.State.FlyBodyGyro = Instance.new("BodyGyro")
    Config.State.FlyBodyGyro.P = 9e4
    Config.State.FlyBodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    Config.State.FlyBodyGyro.CFrame = root.CFrame
    Config.State.FlyBodyGyro.Parent = root
    Config.State.FlyBodyVelocity = Instance.new("BodyVelocity")
    Config.State.FlyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
    Config.State.FlyBodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    Config.State.FlyBodyVelocity.Parent = root
    Config.State.Flying = true
end

local function StopFly()
    if not Config.State.Flying then return end
    if Config.State.FlyBodyGyro then Config.State.FlyBodyGyro:Destroy(); Config.State.FlyBodyGyro = nil end
    if Config.State.FlyBodyVelocity then Config.State.FlyBodyVelocity:Destroy(); Config.State.FlyBodyVelocity = nil end
    local char = LocalPlayer.Character
    if char then local hum = char:FindFirstChildOfClass("Humanoid"); if hum then hum.PlatformStand = false end end
    Config.State.Flying = false
end

local function DoFly()
    if not Config.Fly then return end
    if not Config.State.Flying then return end
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local speed = Config.FlySpeed
    local velocity = Vector3.new(0, 0, 0)
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then velocity = velocity + (Camera.CFrame.LookVector * speed) end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then velocity = velocity - (Camera.CFrame.LookVector * speed) end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then velocity = velocity - (Camera.CFrame.RightVector * speed) end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then velocity = velocity + (Camera.CFrame.RightVector * speed) end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then velocity = velocity + Vector3.new(0, speed, 0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then velocity = velocity - Vector3.new(0, speed, 0) end
    if Config.State.FlyBodyVelocity then Config.State.FlyBodyVelocity.Velocity = velocity end
    if Config.State.FlyBodyGyro then Config.State.FlyBodyGyro.CFrame = Camera.CFrame end
end

local function DoInfiniteJump()
    if not Config.InfiniteJump then return end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        local char = LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        if hum.FloorMaterial == Enum.Material.Air then
            root.Velocity = Vector3.new(root.Velocity.X, Config.JumpPower, root.Velocity.Z)
        end
    end
end

local function DoNoClip()
    if not Config.NoClip then return end
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then part.CanCollide = false end
    end
end

local function ResetNoClip()
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then part.CanCollide = true end
    end
end

local function SetupAntiAFK()
    if Config.Connections.AntiAFK then return end
    Config.Connections.AntiAFK = LocalPlayer.Idled:Connect(function()
        if Config.AntiAFK then
            VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
            task.wait(1)
            VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
        end
    end)
end

local function DoAntiAim()
    if not Config.AntiAim then return end
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local jitter = math.random(-90, 90)
    root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(jitter), 0)
end

local function DoFastSwitch()
    if not Config.FastSwitch then return end
    local char = LocalPlayer.Character
    if not char then return end
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return end
    for _, tool in pairs(backpack:GetChildren()) do
        if tool:IsA("Tool") then
            local cd = tool:FindFirstChild("Cooldown") or tool:FindFirstChild("EquipCooldown")
            if cd and cd:IsA("NumberValue") then
                if Config.OriginalValues[tool] == nil then Config.OriginalValues[tool] = cd.Value end
                cd.Value = 0
            end
        end
    end
end

local function DoFullbright()
    if not Config.Fullbright then return end
    if Config.OriginalValues.Brightness == nil then
        Config.OriginalValues.Brightness = Lighting.Brightness
        Config.OriginalValues.GlobalShadows = Lighting.GlobalShadows
        Config.OriginalValues.Ambient = Lighting.Ambient
        Config.OriginalValues.OutdoorAmbient = Lighting.OutdoorAmbient
    end
    Lighting.Brightness = Config.Brightness
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

local function DoNoShadows()
    if not Config.NoShadows then return end
    for _, v in pairs(Lighting:GetDescendants()) do if v:IsA("ShadowMap") then v.Enabled = false end end
    Lighting.GlobalShadows = false
end

local function DoCustomTime()
    if not Config.CustomTime then return end
    Lighting.ClockTime = Config.TimeOfDay
end

local function OnInputBegan(input, gp)
    if gp then return end
    if input.KeyCode == Config.FlyKey then
        if Config.Fly then
            if Config.State.Flying then StopFly() else StartFly() end
        end
    end
    if input.KeyCode == Config.NoClipKey then
        if Config.NoClip then Config.State.NoClipping = not Config.State.NoClipping end
    end
end

local RenderConnection = nil

local function OnRenderStep()
    DoBunnyHop(); DoAutoStrafe(); DoSpeedHack(); DoFly(); DoInfiniteJump(); DoAntiAim(); DoFastSwitch(); DoFullbright(); DoNoFog(); DoNoShadows(); DoCustomTime()
    if Config.State.NoClipping then DoNoClip() end
end

local Module = {}

function Module.Init()
    LocalPlayer.CharacterAdded:Connect(function(char)
        task.wait(0.3)
        Config.OriginalValues.WalkSpeed = nil
        Config.State.Flying = false
        Config.State.NoClipping = false
        Config.State.FlyBodyGyro = nil
        Config.State.FlyBodyVelocity = nil
        if Config.Enabled then
            if Config.SpeedHack then local hum = char:FindFirstChildOfClass("Humanoid"); if hum then Config.OriginalValues.WalkSpeed = hum.WalkSpeed end end
        end
    end)
end

function Module.Enable()
    Config.Enabled = true
    if not RenderConnection then RenderConnection = RunService.RenderStepped:Connect(OnRenderStep) end
    if not Config.Connections.InputBegan then Config.Connections.InputBegan = UserInputService.InputBegan:Connect(OnInputBegan) end
    SetupAntiAFK()
    local char = LocalPlayer.Character
    if char then local hum = char:FindFirstChildOfClass("Humanoid"); if hum and Config.OriginalValues.WalkSpeed == nil then Config.OriginalValues.WalkSpeed = hum.WalkSpeed end end
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
    Config.State.NoClipping = false
    StopFly()
    ResetNoClip()
    if RenderConnection then RenderConnection:Disconnect(); RenderConnection = nil end
    ResetSpeed()
    ResetLighting()
    ResetFog()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, tool in pairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and Config.OriginalValues[tool] ~= nil then
                local cd = tool:FindFirstChild("Cooldown") or tool:FindFirstChild("EquipCooldown")
                if cd and cd:IsA("NumberValue") then cd.Value = Config.OriginalValues[tool] end
            end
        end
    end
end

function Module.SetConfig(key, value)
    if key == "BunnyHop" then Config.BunnyHop = value
    elseif key == "AutoStrafe" then Config.AutoStrafe = value
    elseif key == "SpeedHack" then Config.SpeedHack = value; if not value then ResetSpeed() end
    elseif key == "Fly" then Config.Fly = value; if not value then StopFly() end
    elseif key == "InfiniteJump" then Config.InfiniteJump = value
    elseif key == "NoClip" then Config.NoClip = value; if not value then Config.State.NoClipping = false; ResetNoClip() end
    elseif key == "AntiAFK" then Config.AntiAFK = value; if value then SetupAntiAFK() end
    elseif key == "AntiAim" then Config.AntiAim = value
    elseif key == "FastSwitch" then Config.FastSwitch = value; if not value then
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if backpack then
            for _, tool in pairs(backpack:GetChildren()) do
                if tool:IsA("Tool") and Config.OriginalValues[tool] ~= nil then
                    local cd = tool:FindFirstChild("Cooldown") or tool:FindFirstChild("EquipCooldown")
                    if cd and cd:IsA("NumberValue") then cd.Value = Config.OriginalValues[tool] end
                end
            end
        end
    end
    elseif key == "Fullbright" then Config.Fullbright = value; if not value then ResetLighting() end
    elseif key == "NoFog" then Config.NoFog = value; if not value then ResetFog() end
    elseif key == "NoShadows" then Config.NoShadows = value
    elseif key == "CustomTime" then Config.CustomTime = value
    elseif key == "WalkSpeed" then Config.WalkSpeed = value
    elseif key == "JumpPower" then Config.JumpPower = value
    elseif key == "FlySpeed" then Config.FlySpeed = value
    elseif key == "FlyKey" then Config.FlyKey = value
    elseif key == "SpeedKey" then Config.SpeedKey = value
    elseif key == "NoClipKey" then Config.NoClipKey = value
    elseif key == "Brightness" then Config.Brightness = value
    elseif key == "TimeOfDay" then Config.TimeOfDay = value
    end
end

function Module.GetConfig() return Config end

function Module.ResetConfig()
    Config.Enabled = false; Config.BunnyHop = false; Config.AutoStrafe = false; Config.SpeedHack = false; Config.Fly = false
    Config.InfiniteJump = false; Config.NoClip = false; Config.AntiAFK = false; Config.AntiAim = false; Config.FastSwitch = false
    Config.Fullbright = false; Config.NoFog = false; Config.NoShadows = false; Config.CustomTime = false
    Config.WalkSpeed = 50; Config.JumpPower = 100; Config.FlySpeed = 50; Config.FlyKey = Enum.KeyCode.F
    Config.SpeedKey = Enum.KeyCode.LeftShift; Config.NoClipKey = Enum.KeyCode.N; Config.Brightness = 2; Config.TimeOfDay = 12
end

return Module