-- Pouncing.exe | Loader v1.3 — Detailed diagnostics + cleanup

-- Kill any existing Pouncing guis
local CoreGui = game:GetService("CoreGui")
for _, child in pairs(CoreGui:GetChildren()) do
	if child.Name:find("Pouncing") then
		child:Destroy()
	end
end
if gethui then
	for _, child in pairs(gethui():GetChildren()) do
		if child.Name:find("Pouncing") then
			child:Destroy()
		end
	end
end

-- Run-once guard
if _G._PouncingRunning then
	return
end
_G._PouncingRunning = true

local TweenService = game:GetService("TweenService")
local BASE_URL = "https://raw.githubusercontent.com/confessess/pouncing.exe/main/"

local function Fetch(url)
	local s,r = pcall(function() return game:HttpGet(url,true) end)
	return s and r or nil
end

local function Load(path)
	local src = Fetch(BASE_URL..path..".lua")
	if not src then return nil, "fetch_fail" end
	local fn,err = loadstring(src,path)
	if not fn then return nil, "loadstring_fail:"..tostring(err) end
	local ok,res = pcall(fn)
	if not ok then return nil, "pcall_fail:"..tostring(res) end
	return res, "ok"
end

-- Visual tracker
local sg = Instance.new("ScreenGui")
sg.Name = "PouncingStepsV13"
sg.ResetOnSpawn = false
sg.Parent = CoreGui

local stepY = 20
local function Step(color, text)
	local f = Instance.new("Frame")
	f.Size = UDim2.new(0, 550, 0, 24)
	f.Position = UDim2.new(0, 20, 0, stepY)
	f.BackgroundColor3 = color
	f.BorderSizePixel = 0
	f.Parent = sg
	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(1, -10, 1, 0)
	t.Position = UDim2.new(0, 5, 0, 0)
	t.BackgroundTransparency = 1
	t.Text = text
	t.TextColor3 = Color3.new(1,1,1)
	t.TextSize = 12
	t.Font = Enum.Font.GothamBold
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.Parent = f
	stepY = stepY + 28
end

Step(Color3.fromRGB(80,80,80), "v1.3: Loader started")

-- Utils
Step(Color3.fromRGB(120,120,120), "Loading utils...")
local Utils, uErr = Load("utils/core")
if not Utils then
	Step(Color3.fromRGB(255,0,0), "Utils FAIL: "..tostring(uErr))
	return
end
Step(Color3.fromRGB(0,255,0), "Utils OK (type="..typeof(Utils)..")")

-- Framework
Step(Color3.fromRGB(120,120,120), "Loading framework...")
local GUI, gErr = Load("gui/framework")
if not GUI then
	Step(Color3.fromRGB(255,0,0), "Framework FAIL: "..tostring(gErr))
	return
end
Step(Color3.fromRGB(0,255,0), "Framework OK (type="..typeof(GUI)..")")

-- Main GUI — DETAILED
Step(Color3.fromRGB(120,120,120), "Loading main...")
local Main, mErr = Load("gui/main")
if not Main then
	Step(Color3.fromRGB(255,0,0), "Main FAIL: "..tostring(mErr))
	return
end
Step(Color3.fromRGB(0,255,0), "Main OK (type="..typeof(Main)..")")

-- Check Main.Create
Step(Color3.fromRGB(120,120,120), "Checking Main.Create...")
if typeof(Main) ~= "table" then
	Step(Color3.fromRGB(255,0,0), "Main is not a table! type="..typeof(Main))
	return
end
if not Main.Create then
	Step(Color3.fromRGB(255,0,0), "Main.Create is nil!")
	return
end
if typeof(Main.Create) ~= "function" then
	Step(Color3.fromRGB(255,0,0), "Main.Create is not a function! type="..typeof(Main.Create))
	return
end
Step(Color3.fromRGB(0,255,0), "Main.Create is a function")

-- Build manager
local Manager = {
	Modules = {Utils = Utils, Framework = GUI},
	GetModule = function(self,n) return self.Modules[n] end,
	Toggle = function(self,name,state)
		if not self.Modules[name] then
			local mod, err = Load("modules/"..name:lower())
			if mod then
				if mod.Init then pcall(mod.Init) end
				self.Modules[name] = mod
			end
		end
		local m = self.Modules[name]
		if m then
			if state and m.Enable then pcall(m.Enable) end
			if not state and m.Disable then pcall(m.Disable) end
		end
	end,
	UnloadAll = function() end
}

-- Build GUI
Step(Color3.fromRGB(120,120,120), "Calling Main.Create...")
local ok, win = pcall(function()
	return Main.Create(sg, Manager)
end)
if not ok then
	Step(Color3.fromRGB(255,0,0), "Main.Create CRASHED: "..tostring(win))
	return
end
if not win then
	Step(Color3.fromRGB(255,0,0), "Main.Create returned nil!")
	return
end
Step(Color3.fromRGB(0,255,0), "GUI built! type="..typeof(win))

-- Check window
if typeof(win) == "table" and win.MainFrame then
	Step(Color3.fromRGB(0,255,0), "MainFrame exists, Visible="..tostring(win.MainFrame.Visible))
else
	Step(Color3.fromRGB(255,100,0), "Warning: no MainFrame in window")
end

-- Done
Step(Color3.fromRGB(255,255,0), "DONE! RightShift to toggle")

-- Notification
local NF = Instance.new("Frame")
NF.Size = UDim2.new(0, 280, 0, 40)
NF.Position = UDim2.new(1, -300, 1, -60)
NF.BackgroundColor3 = Color3.fromRGB(35, 20, 30)
NF.BorderSizePixel = 0
NF.Parent = sg
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
NT.Text = "🐾 Pouncing.exe loaded!"
NT.TextColor3 = Color3.fromRGB(255, 182, 193)
NT.TextSize = 12
NT.Font = Enum.Font.GothamSemibold
NT.Parent = NF