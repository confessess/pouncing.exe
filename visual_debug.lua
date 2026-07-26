-- Pouncing.exe | VISUAL DEBUG — colored frames show boot progress

local CoreGui = game:GetService("CoreGui")
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

local sg = Instance.new("ScreenGui")
sg.Name = "PouncingVisualDebug"
sg.ResetOnSpawn = false
if syn and syn.protect_gui then syn.protect_gui(sg) sg.Parent = CoreGui
elseif gethui then sg.Parent = gethui()
else sg.Parent = CoreGui end

local function StatusFrame(color, text, yOffset)
	local f = Instance.new("Frame")
	f.Size = UDim2.new(0, 300, 0, 30)
	f.Position = UDim2.new(0, 20, 0, 20 + yOffset)
	f.BackgroundColor3 = color
	f.BorderSizePixel = 0
	f.Parent = sg
	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(1, 0, 1, 0)
	t.BackgroundTransparency = 1
	t.Text = text
	t.TextColor3 = Color3.new(1,1,1)
	t.TextSize = 14
	t.Font = Enum.Font.GothamBold
	t.Parent = f
	return f
end

-- Step 1: ScreenGui works
StatusFrame(Color3.fromRGB(255,0,0), "STEP 1: ScreenGui OK", 0)

-- Step 2: Load framework
local GUI = Load("gui/framework")
if not GUI then
	StatusFrame(Color3.fromRGB(100,0,0), "STEP 2 FAILED: Framework", 35)
	return
end
StatusFrame(Color3.fromRGB(0,255,0), "STEP 2: Framework loaded", 35)

-- Step 3: Load main
local Main = Load("gui/main")
if not Main then
	StatusFrame(Color3.fromRGB(0,100,0), "STEP 3 FAILED: Main GUI", 70)
	return
end
StatusFrame(Color3.fromRGB(0,0,255), "STEP 3: Main loaded", 70)

-- Step 4: Build GUI
local Manager = {
	Modules = {Framework = GUI},
	GetModule = function(self,n) return self.Modules[n] end,
	Toggle = function() end,
	UnloadAll = function() end
}

local ok,win = pcall(function() return Main.Create(sg, Manager) end)
if not ok or not win then
	StatusFrame(Color3.fromRGB(0,0,100), "STEP 4 FAILED: Create crashed/nil", 105)
	return
end

StatusFrame(Color3.fromRGB(255,255,0), "STEP 4: GUI built! All OK", 105)

-- Step 5: Check window properties
local props = ""
if typeof(win) == "table" then
	if win.MainFrame then
		props = "MF:V="..tostring(win.MainFrame.Visible).." S="..tostring(win.MainFrame.Size)
	else
		props = "NO MainFrame"
	end
else
	props = "win is "..typeof(win)
end
StatusFrame(Color3.fromRGB(255,0,255), "STEP 5: "..props, 140)