-- Pouncing.exe | Gun Module v2.1
-- Weapon modifications and firing logic
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local Config = {
    Enabled = false, AutoFire = false, NoRecoil = false, NoSpread = false,
    InstantReload = false, RapidFire = false, InfiniteAmmo = false, AlwaysHeadshot = false,
    FireRate = 50, DamageMult = 1, RecoilReduction = 100,
    OriginalValues = {}, Connections = {}, AmmoHooks = {}, HeadshotHooked = false
}

local function GetCurrentTool()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Tool")
end

local function GetToolConfig(tool)
    if not tool then return nil end
    local configs = {tool:FindFirstChild("Configuration"), tool:FindFirstChild("Config"), tool:FindFirstChild("GunStats"), tool:FindFirstChild("Settings"), tool:FindFirstChild("Values")}
    for _, cfg in ipairs(configs) do if cfg then return cfg end end
    return tool
end

local function SaveOriginal(tool)
    if not tool or Config.OriginalValues[tool] then return end
    local cfg = GetToolConfig(tool)
    if not cfg then return end
    local saved = {}
    for _, child in pairs(cfg:GetChildren()) do
        if child:IsA("NumberValue") or child:IsA("IntValue") then saved[child.Name] = child.Value end
    end
    Config.OriginalValues[tool] = saved
end

local function RestoreOriginal(tool)
    if not tool or not Config.OriginalValues[tool] then return end
    local cfg = GetToolConfig(tool)
    if not cfg then return end
    for name, value in pairs(Config.OriginalValues[tool]) do
        local child = cfg:FindFirstChild(name)
        if child and (child:IsA("NumberValue") or child:IsA("IntValue")) then child.Value = value end
    end
    Config.OriginalValues[tool] = nil
end

local function ApplyGunMods(tool)
    if not tool then return end
    local cfg = GetToolConfig(tool)
    if not cfg then return end
    SaveOriginal(tool)
    local statMap = {Recoil = "NoRecoil", RecoilPower = "NoRecoil", RecoilX = "NoRecoil", RecoilY = "NoRecoil", Spread = "NoSpread", BulletSpread = "NoSpread", HipSpread = "NoSpread", ADSSpread = "NoSpread", ReloadTime = "InstantReload", ReloadSpeed = "InstantReload", ReloadDuration = "InstantReload", FireRate = "RapidFire", FireSpeed = "RapidFire", Firerate = "RapidFire", RPM = "RapidFire", Damage = "DamageMult", BaseDamage = "DamageMult", BulletDamage = "DamageMult"}
    for _, child in pairs(cfg:GetChildren()) do
        if child:IsA("NumberValue") or child:IsA("IntValue") then
            local modName = statMap[child.Name]
            if modName then
                if modName == "NoRecoil" and Config.NoRecoil then child.Value = 0
                elseif modName == "NoSpread" and Config.NoSpread then child.Value = 0
                elseif modName == "InstantReload" and Config.InstantReload then child.Value = 0.01
                elseif modName == "RapidFire" and Config.RapidFire then
                    local base = Config.OriginalValues[tool] and Config.OriginalValues[tool][child.Name] or child.Value
                    child.Value = base / math.max(Config.FireRate / 10, 1)
                elseif modName == "DamageMult" and Config.DamageMult > 1 then
                    local base = Config.OriginalValues[tool] and Config.OriginalValues[tool][child.Name] or child.Value
                    child.Value = base * Config.DamageMult
                end
            end
        end
    end
end

local function ResetGunMods(tool)
    if not tool then return end
    RestoreOriginal(tool)
end

local function SetupInfiniteAmmo()
    if not Config.InfiniteAmmo then return end
    local tool = GetCurrentTool()
    if not tool then return end
    local cfg = GetToolConfig(tool)
    if not cfg then return end
    for _, child in pairs(cfg:GetChildren()) do
        if child.Name:lower():match("ammo") or child.Name:lower():match("clip") or child.Name:lower():match("mag") then
            if child:IsA("NumberValue") or child:IsA("IntValue") then
                if not Config.AmmoHooks[child] then
                    Config.AmmoHooks[child] = child:GetPropertyChangedSignal("Value"):Connect(function()
                        if Config.Enabled and Config.InfiniteAmmo then child.Value = child.Value + 1 end
                    end)
                end
            end
        end
    end
end

local function RemoveInfiniteAmmo()
    for child, conn in pairs(Config.AmmoHooks) do conn:Disconnect() end
    Config.AmmoHooks = {}
end

local function SetupAlwaysHeadshot()
    if Config.HeadshotHooked then return end
    Config.HeadshotHooked = true
    local mt = getrawmetatable(game)
    if not mt then return end
    local oldNamecall = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if Config.Enabled and Config.AlwaysHeadshot then
            if method == "FireServer" or method == "InvokeServer" then
                local args = {...}
                if #args >= 2 and typeof(args[2]) == "Vector3" then
                    for _, player in pairs(Players:GetPlayers()) do
                        if player ~= LocalPlayer and player.Character then
                            local head = player.Character:FindFirstChild("Head")
                            if head then
                                local dist = (args[2] - head.Position).Magnitude
                                if dist < 10 then args[2] = head.Position; return oldNamecall(self, unpack(args)) end
                            end
                        end
                    end
                end
                if #args >= 2 and typeof(args[2]) == "string" then
                    if args[2]:lower():match("torso") or args[2]:lower():match("body") or args[2]:lower():match("limb") then
                        args[2] = "Head"
                        return oldNamecall(self, unpack(args))
                    end
                end
            end
        end
        return oldNamecall(self, ...)
    end)
    setreadonly(mt, true)
end

local AutoFireConn = nil
local MouseDown = false

local function OnAutoFire()
    if not Config.AutoFire or not MouseDown then return end
    local tool = GetCurrentTool()
    if not tool then return end
    pcall(function()
        if tool:FindFirstChild("RemoteEvent") then tool.RemoteEvent:FireServer(Mouse.Hit.Position)
        elseif tool:FindFirstChild("Fire") then tool.Fire:FireServer(Mouse.Hit.Position)
        else tool:Activate() end
    end)
end

local ToolEquippedConn = nil
local ToolUnequippedConn = nil

local function OnToolEquipped(tool)
    if Config.Enabled then ApplyGunMods(tool); if Config.InfiniteAmmo then SetupInfiniteAmmo() end end
end

local function OnToolUnequipped(tool) ResetGunMods(tool) end

local function SetupToolEvents()
    local char = LocalPlayer.Character
    if not char then return end
    if ToolEquippedConn then ToolEquippedConn:Disconnect() end
    if ToolUnequippedConn then ToolUnequippedConn:Disconnect() end
    ToolEquippedConn = char.ChildAdded:Connect(function(child) if child:IsA("Tool") then OnToolEquipped(child) end end)
    ToolUnequippedConn = char.ChildRemoved:Connect(function(child) if child:IsA("Tool") then OnToolUnequipped(child) end end)
    local current = GetCurrentTool()
    if current then OnToolEquipped(current) end
end

local Module = {}

function Module.Init()
    if LocalPlayer.Character then SetupToolEvents() end
    LocalPlayer.CharacterAdded:Connect(function() task.wait(0.5); SetupToolEvents() end)
end

function Module.Enable()
    Config.Enabled = true
    local tool = GetCurrentTool()
    if tool then ApplyGunMods(tool) end
    if Config.AutoFire and not AutoFireConn then AutoFireConn = RunService.RenderStepped:Connect(OnAutoFire) end
    if Config.InfiniteAmmo then SetupInfiniteAmmo() end
    if Config.AlwaysHeadshot then SetupAlwaysHeadshot() end
    if not Config.Connections.InputBegan then
        Config.Connections.InputBegan = UserInputService.InputBegan:Connect(function(input, gp) if gp then return end; if input.UserInputType == Enum.UserInputType.MouseButton1 then MouseDown = true end end)
        Config.Connections.InputEnded = UserInputService.InputEnded:Connect(function(input, gp) if gp then return end; if input.UserInputType == Enum.UserInputType.MouseButton1 then MouseDown = false end end)
    end
end

function Module.Disable()
    Config.Enabled = false
    MouseDown = false
    for tool, _ in pairs(Config.OriginalValues) do ResetGunMods(tool) end
    RemoveInfiniteAmmo()
    if AutoFireConn then AutoFireConn:Disconnect(); AutoFireConn = nil end
    for name, conn in pairs(Config.Connections) do conn:Disconnect() end
    Config.Connections = {}
end

function Module.SetConfig(key, value)
    if key == "AutoFire" then Config.AutoFire = value; if Config.Enabled then if value and not AutoFireConn then AutoFireConn = RunService.RenderStepped:Connect(OnAutoFire) elseif not value and AutoFireConn then AutoFireConn:Disconnect(); AutoFireConn = nil end end
    elseif key == "NoRecoil" then Config.NoRecoil = value
    elseif key == "NoSpread" then Config.NoSpread = value
    elseif key == "InstantReload" then Config.InstantReload = value
    elseif key == "RapidFire" then Config.RapidFire = value
    elseif key == "InfiniteAmmo" then Config.InfiniteAmmo = value; if Config.Enabled then if value then SetupInfiniteAmmo() else RemoveInfiniteAmmo() end end
    elseif key == "AlwaysHeadshot" then Config.AlwaysHeadshot = value; if Config.Enabled and value then SetupAlwaysHeadshot() end
    elseif key == "FireRate" then Config.FireRate = value
    elseif key == "DamageMult" then Config.DamageMult = value
    elseif key == "RecoilReduction" then Config.RecoilReduction = value
    end
    if Config.Enabled then local tool = GetCurrentTool(); if tool then ApplyGunMods(tool) end end
end

function Module.GetConfig() return Config end

function Module.ResetConfig()
    Config.Enabled = false; Config.AutoFire = false; Config.NoRecoil = false; Config.NoSpread = false; Config.InstantReload = false
    Config.RapidFire = false; Config.InfiniteAmmo = false; Config.AlwaysHeadshot = false; Config.FireRate = 50; Config.DamageMult = 1; Config.RecoilReduction = 100
end

return Module