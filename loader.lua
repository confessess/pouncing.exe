-- Pouncing.exe | Modular Loader v2.0
-- Fetches framework + main from GitHub, loads modules on-demand
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

local BASE_URL = "https://raw.githubusercontent.com/confessess/pouncing.exe/main/"

-- ============================================================
-- GUI Protection
-- ============================================================
local function ProtectGui(Gui)
    if syn and syn.protect_gui then
        syn.protect_gui(Gui)
        Gui.Parent = CoreGui
    elseif gethui then
        Gui.Parent = gethui()
    else
        Gui.Parent = CoreGui
    end
end

-- ============================================================
-- HTTP Fetch with cache busting
-- ============================================================
local function Fetch(url)
    local busted = url .. "?t=" .. tostring(tick())
    local success, result = pcall(function()
        return game:HttpGet(busted, true)
    end)
    if success then
        return result
    else
        warn("[Pouncing] Failed to fetch: " .. url .. " | " .. tostring(result))
        return nil
    end
end

-- ============================================================
-- Module Loader
-- ============================================================
local function LoadModule(path)
    local url = BASE_URL .. path .. ".lua"
    local source = Fetch(url)
    if not source then return nil end

    local fn, err = loadstring(source, path)
    if not fn then
        warn("[Pouncing] Syntax error in " .. path .. ": " .. tostring(err))
        return nil
    end

    local success, result = pcall(fn)
    if not success then
        warn("[Pouncing] Runtime error in " .. path .. ": " .. tostring(result))
        return nil
    end

    return result
end

-- ============================================================
-- Module Manager
-- ============================================================
local ModuleManager = {
    Modules = {},
    Active = {},
    _gui = nil
}

function ModuleManager:RegisterGUI(gui)
    self._gui = gui
end

function ModuleManager:GetGUI()
    return self._gui
end

function ModuleManager:Load(name, path)
    if self.Modules[name] then
        return self.Modules[name]
    end

    local mod = LoadModule(path or ("modules/" .. name:lower()))
    if mod then
        if mod.Init then
            local ok, err = pcall(mod.Init, self)
            if not ok then
                warn("[Pouncing] Init failed for " .. name .. ": " .. tostring(err))
            end
        end
        self.Modules[name] = mod
        print("[Pouncing] Loaded module: " .. name)
    else
        warn("[Pouncing] Could not load module: " .. name)
    end

    return mod
end

function ModuleManager:Toggle(name, state, path)
    local mod = self:Load(name, path)
    if not mod then
        return false
    end

    if state then
        if mod.Enable then
            local ok, err = pcall(mod.Enable)
            if not ok then
                warn("[Pouncing] Enable failed for " .. name .. ": " .. tostring(err))
                return false
            end
        end
        self.Active[name] = true
        print("[Pouncing] Enabled: " .. name)
    else
        if mod.Disable then
            local ok, err = pcall(mod.Disable)
            if not ok then
                warn("[Pouncing] Disable failed for " .. name .. ": " .. tostring(err))
            end
        end
        self.Active[name] = nil
        print("[Pouncing] Disabled: " .. name)
    end

    return true
end

function ModuleManager:IsActive(name)
    return self.Active[name] == true
end

function ModuleManager:GetModule(name)
    return self.Modules[name]
end

function ModuleManager:UnloadAll()
    for name, _ in pairs(self.Active) do
        self:Toggle(name, false)
    end
    self.Modules = {}
    self.Active = {}
end

-- ============================================================
-- Boot Sequence
-- ============================================================
print("[Pouncing.exe] Initializing v2.0...")

-- Load utilities
local Utils = LoadModule("utils/core")
if Utils then
    ModuleManager.Modules["Utils"] = Utils
    print("[Pouncing] Utils registered")
else
    warn("[Pouncing] Utils failed to load — continuing without")
end

-- Load GUI Framework
local GUIFramework = LoadModule("gui/framework")
if not GUIFramework then
    warn("[Pouncing] CRITICAL: GUI Framework failed to load!")
    return
end
ModuleManager.Modules["Framework"] = GUIFramework
print("[Pouncing] Framework registered")

-- Load Main GUI
local GUIMain = LoadModule("gui/main")
if not GUIMain then
    warn("[Pouncing] CRITICAL: GUI Main failed to load!")
    return
end

-- Build the GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PouncingExe_" .. tostring(math.random(1000, 9999))
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ProtectGui(ScreenGui)

ModuleManager:RegisterGUI(ScreenGui)

local ok, MainWindow = pcall(function()
    return GUIMain.Create(ScreenGui, ModuleManager)
end)

if not ok then
    warn("[Pouncing] CRITICAL: GUIMain.Create crashed: " .. tostring(MainWindow))
    return
end

if not MainWindow then
    warn("[Pouncing] CRITICAL: GUIMain.Create returned nil!")
    return
end

print("[Pouncing] GUI built successfully | Tabs=" .. tostring(MainWindow.TabCount) .. "/5")

-- Expose globally
getfenv()["Pouncing"] = {
    Manager = ModuleManager,
    GUI = ScreenGui,
    Window = MainWindow
}

print("[Pouncing.exe] Ready! v2.0 | RightShift to toggle")
'''

with open(f"{output_dir}/loader.lua", "w") as f:
    f.write(loader)

# ============================================================
# Also write stub modules so the repo is complete
# ============================================================

aimbot = '''-- Pouncing.exe | Aimbot Module
local Aimbot = {}

local Config = {
    Enabled = false,
    SilentAim = false,
    TeamCheck = true,
    WallCheck = true,
    FOV = 120,
    Smoothness = 15,
    MaxDistance = 1000,
    Priority = "Closest",
    AimKey = Enum.KeyCode.Q
}

function Aimbot.Init(manager)
    print("[Aimbot] Initialized")
end

function Aimbot.Enable()
    Config.Enabled = true
    print("[Aimbot] Enabled")
end

function Aimbot.Disable()
    Config.Enabled = false
    print("[Aimbot] Disabled")
end

function Aimbot.SetConfig(key, value)
    Config[key] = value
    print("[Aimbot] " .. tostring(key) .. " = " .. tostring(value))
end

function Aimbot.GetConfig()
    return Config
end

return Aimbot
'''

esp = '''-- Pouncing.exe | ESP Module
local ESP = {}

local Config = {
    Enabled = false,
    Boxes = true,
    Names = true,
    HealthBar = true,
    Skeleton = false,
    Chams = false,
    Distance = false,
    TeamCheck = true,
    MaxDistance = 1500,
    BoxThickness = 1,
    BoxColor = Color3.fromRGB(255, 105, 180),
    SkeletonColor = Color3.fromRGB(255, 0, 255),
    ChamsColor = Color3.fromRGB(255, 20, 147)
}

function ESP.Init(manager)
    print("[ESP] Initialized")
end

function ESP.Enable()
    Config.Enabled = true
    print("[ESP] Enabled")
end

function ESP.Disable()
    Config.Enabled = false
    print("[ESP] Disabled")
end

function ESP.SetConfig(key, value)
    Config[key] = value
    print("[ESP] " .. tostring(key) .. " = " .. tostring(value))
end

function ESP.GetConfig()
    return Config
end

return ESP
'''

gun = '''-- Pouncing.exe | Gun Module
local Gun = {}

local Config = {
    Enabled = false,
    NoRecoil = false,
    NoSpread = false,
    RapidFire = false,
    AutoFire = false,
    InfiniteAmmo = false,
    InstantReload = false,
    FireRate = 2,
    DamageMult = 1,
    RecoilReduction = 100
}

function Gun.Init(manager)
    print("[Gun] Initialized")
end

function Gun.Enable()
    Config.Enabled = true
    print("[Gun] Enabled")
end

function Gun.Disable()
    Config.Enabled = false
    print("[Gun] Disabled")
end

function Gun.SetConfig(key, value)
    Config[key] = value
    print("[Gun] " .. tostring(key) .. " = " .. tostring(value))
end

function Gun.GetConfig()
    return Config
end

return Gun
'''

misc = '''-- Pouncing.exe | Misc Module
local Misc = {}

local Config = {
    Enabled = false,
    BunnyHop = false,
    SpeedHack = false,
    Fly = false,
    InfiniteJump = false,
    NoClip = false,
    WalkSpeed = 50,
    JumpPower = 100,
    FlySpeed = 50,
    Fullbright = false,
    NoFog = false,
    NoShadows = false,
    CustomTime = false,
    Brightness = 2,
    TimeOfDay = 12,
    FlyKey = Enum.KeyCode.F,
    SpeedKey = Enum.KeyCode.LeftShift
}

function Misc.Init(manager)
    print("[Misc] Initialized")
end

function Misc.Enable()
    Config.Enabled = true
    print("[Misc] Enabled")
end

function Misc.Disable()
    Config.Enabled = false
    print("[Misc] Disabled")
end

function Misc.SetConfig(key, value)
    Config[key] = value
    print("[Misc] " .. tostring(key) .. " = " .. tostring(value))
end

function Misc.GetConfig()
    return Config
end

return Misc
'''

utils = '''-- Pouncing.exe | Utils Core
local Utils = {}

-- W2S (World to Screen)
function Utils.W2S(pos, camera)
    local point, onScreen = camera:WorldToViewportPoint(pos)
    return Vector2.new(point.X, point.Y), onScreen
end

-- Distance
function Utils.Dist(a, b)
    return (a - b).Magnitude
end

-- Raycast
function Utils.Raycast(origin, direction, ignoreList)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = ignoreList or {}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    return workspace:Raycast(origin, direction, raycastParams)
end

-- Drawing helpers
function Utils.NewDrawing(type, props)
    local d = Drawing.new(type)
    for k, v in pairs(props or {}) do
        d[k] = v
    end
    return d
end

return Utils