-- Pouncing.exe | DEBUG Loader v2

local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local BASE_URL = "https://raw.githubusercontent.com/confessess/pouncing.exe/main/"

local function Fetch(url)
	local s,r = pcall(function() return game:HttpGet(url,true) end)
	if s then return r end
	warn("[DEBUG] FETCH FAIL: "..url.." -> "..tostring(r))
	return nil
end

local function Load(path)
	local src = Fetch(BASE_URL..path..".lua")
	if not src then warn("[DEBUG] No source for "..path) return nil end
	local fn,err = loadstring(src,path)
	if not fn then warn("[DEBUG] SYNTAX: "..path.." -> "..tostring(err)) return nil end
	local ok,res = pcall(fn)
	if not ok then warn("[DEBUG] RUNTIME: "..path.." -> "..tostring(res)) return nil end
	warn("[DEBUG] LOADED: "..path)
	return res
end

warn("[DEBUG] === Boot ===")

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PouncingDebug"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
if syn and syn.protect_gui then syn.protect_gui(ScreenGui) ScreenGui.Parent = CoreGui
elseif gethui then ScreenGui.Parent = gethui()
else ScreenGui.Parent = CoreGui end

-- TEST: Bright red frame to confirm ScreenGui works
local TestFrame = Instance.new("Frame")
TestFrame.Size = UDim2.new(0, 100, 0, 100)
TestFrame.Position = UDim2.new(0, 50, 0, 50)
TestFrame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
TestFrame.BorderSizePixel = 0
TestFrame.Parent = ScreenGui
warn("[DEBUG] Red test frame created")

-- Load framework
warn("[DEBUG] Loading framework...")
local GUI = Load("gui/framework")
if not GUI then warn("[DEBUG] Framework failed!") return end

-- Load main
warn("[DEBUG] Loading main...")
local Main = Load("gui/main")
if not Main then warn("[DEBUG] Main failed!") return end

-- Build manager
local Manager = {
	Modules = {Framework = GUI},
	GetModule = function(self,n) return self.Modules[n] end,
	Toggle = function(self,name,state)
		warn("[DEBUG] Toggle: "..name.." = "..tostring(state))
		if not self.Modules[name] then
			local mod = Load("modules/"..name:lower())
			if mod then self.Modules[name] = mod end
		end
		local m = self.Modules[name]
		if m and state and m.Enable then m.Enable() end
		if m and not state and m.Disable then m.Disable() end
	end,
	UnloadAll = function() end
}

-- Build GUI
warn("[DEBUG] Building GUI...")
local ok,win = pcall(function() return Main.Create(ScreenGui, Manager) end)
if not ok then warn("[DEBUG] Main.Create CRASHED: "..tostring(win)) return end
if not win then warn("[DEBUG] Main.Create returned nil!") return end

warn("[DEBUG] GUI built! Type: "..tostring(typeof(win)))
if typeof(win) == "table" then
	warn("[DEBUG] win.MainFrame = "..tostring(win.MainFrame))
	if win.MainFrame then
		warn("[DEBUG] MainFrame.Visible = "..tostring(win.MainFrame.Visible))
		warn("[DEBUG] MainFrame.Size = "..tostring(win.MainFrame.Size))
		warn("[DEBUG] MainFrame.Position = "..tostring(win.MainFrame.Position))
		warn("[DEBUG] MainFrame.Parent = "..tostring(win.MainFrame.Parent))
	end
end

warn("[DEBUG] === Done ===")