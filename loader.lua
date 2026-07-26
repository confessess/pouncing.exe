-- Pouncing.exe | Inline Loader — self-contained, no external main.lua

-- Kill old instances
local CoreGui = game:GetService("CoreGui")
for _, c in pairs(CoreGui:GetChildren()) do
	if c.Name:find("Pouncing") then c:Destroy() end
end
if _G._PouncingRunning then return end
_G._PouncingRunning = true

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

-- Visual tracker
local sg = Instance.new("ScreenGui")
sg.Name = "PouncingInline"
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

Step(Color3.fromRGB(80,80,80), "Inline Loader started")

-- Load framework
Step(Color3.fromRGB(120,120,120), "Loading framework...")
local GUI = Load("gui/framework")
if not GUI then
	Step(Color3.fromRGB(255,0,0), "Framework FAIL")
	return
end
Step(Color3.fromRGB(0,255,0), "Framework OK")

-- INLINE main.lua — minimal, no external fetch
Step(Color3.fromRGB(120,120,120), "Building inline GUI...")

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local window = GUI.CreateWindow(sg, "Pouncing.exe", UDim2.new(0, 560, 0, 400))

local Tabs = {
	{Name = "Aimbot", Icon = "🎯"},
	{Name = "ESP", Icon = "👁️"},
	{Name = "Gun", Icon = "🔫"},
	{Name = "Misc", Icon = "⚙️"},
	{Name = "Config", Icon = "💾"}
}

local TabContents = {}
for _, tabInfo in ipairs(Tabs) do
	TabContents[tabInfo.Name] = GUI.CreateTab(window, tabInfo.Name, tabInfo.Icon)
end

-- Aimbot
local ACon = TabContents["Aimbot"]
GUI.CreateSection(ACon, "Aimbot")
GUI.CreateToggle(ACon, "Enabled", false, nil, function(v) end)

-- ESP
local ECon = TabContents["ESP"]
GUI.CreateSection(ECon, "ESP")
GUI.CreateToggle(ECon, "Enabled", false, nil, function(v) end)

-- Gun
local GCon = TabContents["Gun"]
GUI.CreateSection(GCon, "Gun")
GUI.CreateToggle(GCon, "Enabled", false, nil, function(v) end)

-- Misc
local MCon = TabContents["Misc"]
GUI.CreateSection(MCon, "Misc")
GUI.CreateToggle(MCon, "Enabled", false, nil, function(v) end)

-- Config
local CCon = TabContents["Config"]
GUI.CreateSection(CCon, "Config")
GUI.CreateLabel(CCon, "Pouncing.exe v1.0", false)
GUI.CreateLabel(CCon, "RightShift to toggle", true)

-- Default tab
window.ActiveTab = "Aimbot"
if window.Tabs["Aimbot"] then
	TweenService:Create(window.Tabs["Aimbot"], TweenInfo.new(0.2), {
		BackgroundColor3 = GUI.Theme.Primary,
		TextColor3 = GUI.Theme.White
	}):Play()
end
if window.Contents["Aimbot"] then
	window.Contents["Aimbot"].Visible = true
end

UserInputService.InputBegan:Connect(function(input, gp)
	if not gp and input.KeyCode == Enum.KeyCode.RightShift then
		window.MainFrame.Visible = not window.MainFrame.Visible
	end
end)

Step(Color3.fromRGB(0,255,0), "Inline GUI built!")
Step(Color3.fromRGB(255,255,0), "DONE! All 5 tabs ready")

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