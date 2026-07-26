-- ============================================================
-- Pouncing.exe | Loader v1.1
-- Modular HvH Script for Roblox
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
	local success, result = pcall(function()
		return game:HttpGet(url, true)
	end)
	if success then
		return result
	else
		warn("[Pouncing] Failed to fetch: " .. url .. " | " .. tostring(result))
		return nil
	end
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

print("[Pouncing.exe] Initializing...")

-- Load utilities
local Utils = LoadModule("utils/core")
if Utils then
	ModuleManager.Modules["Utils"] = Utils
	print("[Pouncing] Utils registered")
else
	warn("[Pouncing] Utils failed to load")
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

print("[Pouncing] GUI built successfully")

-- Notification
local NF = Instance.new("Frame")
NF.Size = UDim2.new(0, 280, 0, 44)
NF.Position = UDim2.new(1, 20, 1, -60)
NF.BackgroundColor3 = Color3.fromRGB(35, 20, 30)
NF.BorderSizePixel = 0
NF.Parent = ScreenGui

local NS = Instance.new("UIStroke")
NS.Color = Color3.fromRGB(255, 105, 180)
NS.Thickness = 1.5
NS.Parent = NF

local NC = Instance.new("UICorner")
NC.CornerRadius = UDim.new(0, 8)
NC.Parent = NF

local NT = Instance.new("TextLabel")
NT.Size = UDim2.new(1, -10, 1, 0)
NT.Position = UDim2.new(0, 5, 0, 0)
NT.BackgroundTransparency = 1
NT.Text = "🐾 Pouncing.exe loaded | RightShift to toggle"
NT.TextColor3 = Color3.fromRGB(255, 182, 193)
NT.TextSize = 12
NT.Font = Enum.Font.GothamSemibold
NT.Parent = NF

TweenService:Create(NF, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
	Position = UDim2.new(1, -300, 1, -60)
}):Play()

task.delay(4, function()
	TweenService:Create(NF, TweenInfo.new(0.5), {
		Position = UDim2.new(1, 20, 1, -60)
	}):Play()
	task.delay(0.6, function() NF:Destroy() end)
end)

print("[Pouncing.exe] Ready!")

getfenv()["Pouncing"] = {
	Manager = ModuleManager,
	GUI = ScreenGui,
	Window = MainWindow
}