-- Pouncing.exe | Modular Loader v5.0
-- Fetches framework + main from GitHub, loads modules on-demand
-- Built with love by ENI for LO
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

local BASE_URL = "https://raw.githubusercontent.com/confessess/pouncing.exe/main/"

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

local function Fetch(url)
    local busted = url .. "?t=" .. tostring(tick())
    local success, result = pcall(function()
        return game:HttpGet(busted, true)
    end)
    if success then return result end
    warn("[Pouncing] Failed to fetch: " .. url .. " | " .. tostring(result))
    return nil
end

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
    if self.Modules[name] then return self.Modules[name] end
    local mod = LoadModule(path or ("modules/" .. name:lower()))
    if mod then
        if mod.Init then
            local ok, err = pcall(mod.Init, self)
            if not ok then warn("[Pouncing] Init failed for " .. name .. ": " .. tostring(err)) end
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
    if not mod then return false end
    if state then
        if mod.Enable then
            local ok, err = pcall(mod.Enable)
            if not ok then warn("[Pouncing] Enable failed for " .. name .. ": " .. tostring(err)) return false end
        end
        self.Active[name] = true
        print("[Pouncing] Enabled: " .. name)
    else
        if mod.Disable then
            local ok, err = pcall(mod.Disable)
            if not ok then warn("[Pouncing] Disable failed for " .. name .. ": " .. tostring(err)) end
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
    for name, _ in pairs(self.Active) do self:Toggle(name, false) end
    self.Modules = {}
    self.Active = {}
end

print("[Pouncing.exe] Initializing v5.0...")

local Utils = LoadModule("utils/core")
if Utils then
    getfenv()["PouncingUtils"] = Utils
    ModuleManager.Modules["Utils"] = Utils
    print("[Pouncing] Utils loaded")
else
    warn("[Pouncing] Utils failed to load")
end

local GUIFramework = LoadModule("gui/framework")
if not GUIFramework then
    warn("[Pouncing] CRITICAL: GUI Framework failed to load!")
    return
end
ModuleManager.Modules["Framework"] = GUIFramework
print("[Pouncing] Framework loaded")

local GUIMain = LoadModule("gui/main")
if not GUIMain then
    warn("[Pouncing] CRITICAL: GUI Main failed to load!")
    return
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PouncingExe_" .. tostring(math.random(1000, 9999))
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ProtectGui(ScreenGui)

ModuleManager:RegisterGUI(ScreenGui)

local ok, MainWindow = pcall(function()
    return GUIMain.Create(ScreenGui, ModuleManager)
end)

if not ok or not MainWindow then
    warn("[Pouncing] CRITICAL: GUI build failed: " .. tostring(MainWindow))
    return
end

print("[Pouncing] GUI built | Tabs=" .. tostring(MainWindow.TabCount) .. "/6")

getfenv()["Pouncing"] = {
    Manager = ModuleManager,
    GUI = ScreenGui,
    Window = MainWindow
}

print("[Pouncing.exe] Ready! v5.0 | RightShift to toggle |")