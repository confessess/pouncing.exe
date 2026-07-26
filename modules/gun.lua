-- Pouncing.exe | Gun Module
-- Weapon modifications and firing logic
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ============================================================
-- Config
-- ============================================================

local Config = {
    Enabled = false,
    AutoFire = false,
    NoRecoil = false,
    NoSpread = false,
    InstantReload = false,
    RapidFire = false,
    FireRate = 50,
    DamageMult = 1,

    -- Internal
    OriginalValues = {},
    Connections = {}
}

-- ============================================================
-- Weapon Detection
-- ============================================================

local function GetCurrentTool()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Tool")
end

local function GetToolConfig(tool)
    if not tool then return nil end
    -- Common gun config locations in Roblox games
    local configs = {
        tool:FindFirstChild("Configuration"),
        tool:FindFirstChild("Config"),
        tool:FindFirstChild("GunStats"),
        tool:FindFirstChild("Settings"),
        tool:FindFirstChild("Values")
    }
    for _, cfg in ipairs(configs) do
        if cfg then return cfg end
    end
    return tool
end

local function SaveOriginal(tool)
    if not tool or Config.OriginalValues[tool] then return end
    local cfg = GetToolConfig(tool)
    if not cfg then return end

    local saved = {}
    for _, child in pairs(cfg:GetChildren()) do
        if child:IsA("NumberValue") or child:IsA("IntValue") then
            saved[child.Name] = child.Value
        end
    end
    Config.OriginalValues[tool] = saved
end

local function RestoreOriginal(tool)
    if not tool or not Config.OriginalValues[tool] then return end
    local cfg = GetToolConfig(tool)
    if not cfg then return end

    for name, value in pairs(Config.OriginalValues[tool]) do
        local child = cfg:FindFirstChild(name)
        if child and (child:IsA("NumberValue") or child:IsA("IntValue")) then
            child.Value = value
        end
    end
    Config.OriginalValues[tool] = nil
end

-- ============================================================
-- Gun Mods
-- ============================================================

local function ApplyGunMods(tool)
    if not tool then return end
    local cfg = GetToolConfig(tool)
    if not cfg then return end

    SaveOriginal(tool)

    -- Common stat names across games
    local statMap = {
        Recoil = "NoRecoil",
        RecoilPower = "NoRecoil",
        Spread = "NoSpread",
        BulletSpread = "NoSpread",
        ReloadTime = "InstantReload",
        ReloadSpeed = "InstantReload",
        FireRate = "RapidFire",
        FireSpeed = "RapidFire",
        Damage = "DamageMult"
    }

    for _, child in pairs(cfg:GetChildren()) do
        if child:IsA("NumberValue") or child:IsA("IntValue") then
            local modName = statMap[child.Name]
            if modName then
                if modName == "NoRecoil" and Config.NoRecoil then
                    child.Value = 0
                elseif modName == "NoSpread" and Config.NoSpread then
                    child.Value = 0
                elseif modName == "InstantReload" and Config.InstantReload then
                    child.Value = 0.01
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

-- ============================================================
-- Auto Fire
-- ============================================================

local AutoFireConn = nil
local MouseDown = false

local function OnAutoFire()
    if not Config.AutoFire or not MouseDown then return end
    local tool = GetCurrentTool()
    if not tool then return end

    -- Trigger tool activation
    pcall(function()
        if tool:FindFirstChild("RemoteEvent") then
            tool.RemoteEvent:FireServer(Mouse.Hit.Position)
        elseif tool:FindFirstChild("Fire") then
            tool.Fire:FireServer(Mouse.Hit.Position)
        else
            tool:Activate()
        end
    end)
end

local function OnInputBegan(input, gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        MouseDown = true
    end
end

local function OnInputEnded(input, gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        MouseDown = false
    end
end

-- ============================================================
-- Tool Events
-- ============================================================

local ToolEquippedConn = nil
local ToolUnequippedConn = nil

local function OnToolEquipped(tool)
    if Config.Enabled then
        ApplyGunMods(tool)
    end
end

local function OnToolUnequipped(tool)
    ResetGunMods(tool)
end

local function SetupToolEvents()
    local char = LocalPlayer.Character
    if not char then return end

    if ToolEquippedConn then ToolEquippedConn:Disconnect() end
    if ToolUnequippedConn then ToolUnequippedConn:Disconnect() end

    ToolEquippedConn = char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            OnToolEquipped(child)
        end
    end)

    ToolUnequippedConn = char.ChildRemoved:Connect(function(child)
        if child:IsA("Tool") then
            OnToolUnequipped(child)
        end
    end)

    -- Apply to currently equipped tool
    local current = GetCurrentTool()
    if current then
        OnToolEquipped(current)
    end
end

-- ============================================================
-- Module Interface
-- ============================================================

local Module = {}

function Module.Init()
    -- Setup character events
    if LocalPlayer.Character then
        SetupToolEvents()
    end

    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.5)
        SetupToolEvents()
    end)
end

function Module.Enable()
    Config.Enabled = true

    -- Apply to current tool
    local tool = GetCurrentTool()
    if tool then
        ApplyGunMods(tool)
    end

    -- Auto fire
    if Config.AutoFire and not AutoFireConn then
        AutoFireConn = RunService.RenderStepped:Connect(OnAutoFire)
    end

    -- Input handling
    if not Config.Connections.InputBegan then
        Config.Connections.InputBegan = UserInputService.InputBegan:Connect(OnInputBegan)
        Config.Connections.InputEnded = UserInputService.InputEnded:Connect(OnInputEnded)
    end
end

function Module.Disable()
    Config.Enabled = false
    MouseDown = false

    -- Reset all tools
    for tool, _ in pairs(Config.OriginalValues) do
        ResetGunMods(tool)
    end

    -- Disconnect auto fire
    if AutoFireConn then
        AutoFireConn:Disconnect()
        AutoFireConn = nil
    end

    -- Disconnect inputs
    for name, conn in pairs(Config.Connections) do
        conn:Disconnect()
    end
    Config.Connections = {}
end

function Module.SetConfig(key, value)
    if key == "AutoFire" then
        Config.AutoFire = value
        if Config.Enabled then
            if value and not AutoFireConn then
                AutoFireConn = RunService.RenderStepped:Connect(OnAutoFire)
            elseif not value and AutoFireConn then
                AutoFireConn:Disconnect()
                AutoFireConn = nil
            end
        end
    elseif key == "NoRecoil" then
        Config.NoRecoil = value
    elseif key == "NoSpread" then
        Config.NoSpread = value
    elseif key == "InstantReload" then
        Config.InstantReload = value
    elseif key == "RapidFire" then
        Config.RapidFire = value
    elseif key == "FireRate" then
        Config.FireRate = value
    elseif key == "DamageMult" then
        Config.DamageMult = value
    end

    -- Re-apply if enabled
    if Config.Enabled then
        local tool = GetCurrentTool()
        if tool then
            ApplyGunMods(tool)
        end
    end
end

function Module.GetConfig()
    return Config
end

return Module