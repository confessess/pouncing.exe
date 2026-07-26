-- Pouncing.exe | Loader v1.2 — Run Once Guard + Visual Steps

if getfenv()["_PouncingRunning"] then
	return
end
getfenv()["_PouncingRunning"] = true

local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local BASE_URL = "https://raw.githubusercontent.com/confessess/pouncing.exe/main/"

local function Fetch(url)
	local s,r = pcall(function() return game:HttpGet(url,true) end)
	return s and r or nil
end

local function Load(path)
	local src = Fetch(BASE_URL..path..".lua")
	if not src then return nil end
	local fn,err = loadstring(src,path)
	if not fn then return nil end
	local ok,res = pcall(fn)
	return ok and res or nil
end

-- Visual step tracker
local sg = Instance.new("ScreenGui")
sg.Name = "PouncingSteps"
sg.ResetOnSpawn = false
if syn and syn.protect_gui then syn.protect_gui(sg) sg.Parent = CoreGui
elseif gethui then sg.Parent = gethui()
else sg.Parent = CoreGui end

local stepY = 20
local function Step(color, text)
	local f = Instance.new("Frame")
	f.Size = UDim2.new(0, 500, 0, 24)
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

Step(Color3.fromRGB(100,100,100), "STEP 0: Loader started")

-- Load utils
Step(Color3.fromRGB(150,150,150), "STEP 1: Loading utils...")
local Utils = Load("utils/core")
if not Utils then
	Step(Color3.fromRGB(255,0,0), "STEP 1 FAIL: Utils")
	return
end
Step(Color3.fromRGB(0,255,0), "STEP 1: Utils OK")

-- Load framework
Step(Color3.fromRGB(150,150,150), "STEP 2: Loading framework...")
local GUI = Load("gui/framework")
if not GUI then
	Step(Color3.fromRGB(255,0,0), "STEP 2 FAIL: Framework")
	return
end
Step(Color3.fromRGB(0,255,0), "STEP 2: Framework OK")

-- Load main
Step(Color3.fromRGB(150,150,150), "STEP 3: Loading main...")
local Main = Load("gui/main")
if not Main then
	Step(Color3.fromRGB(255,0,0), "STEP 3 FAIL: Main")
	return
end
Step(Color3.fromRGB(0,255,0), "STEP 3: Main OK")

-- Build manager
local Manager = {
	Modules = {Utils = Utils, Framework = GUI},
	GetModule = function(self,n) return self.Modules[n] end,
	Toggle = function(self,name,state)
		if not self.Modules[name] then
			local mod = Load("modules/"..name:lower())
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
Step(Color3.fromRGB(150,150,150), "STEP 4: Building GUI...")
local ok, win = pcall(function() return Main.Create(sg, Manager) end)
if not ok then
	Step(Color3.fromRGB(255,0,0), "STEP 4 FAIL: Crash: "..tostring(win))
	return
end
if not win then
	Step(Color3.fromRGB(255,0,0), "STEP 4 FAIL: Returned nil")
	return
end
Step(Color3.fromRGB(0,255,0), "STEP 4: GUI built!")

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