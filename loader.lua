-- Pouncing.exe | Inline Loader v4 — CreateTab diagnostics

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

local sg = Instance.new("ScreenGui")
sg.Name = "PouncingV4"
sg.ResetOnSpawn = false
sg.Parent = CoreGui

-- Debug bar
local dbg = Instance.new("Frame")
dbg.Size = UDim2.new(0, 500, 0, 24)
dbg.Position = UDim2.new(0, 20, 0, 20)
dbg.BackgroundColor3 = Color3.fromRGB(80,80,80)
dbg.BorderSizePixel = 0
dbg.Parent = sg
local dbgt = Instance.new("TextLabel")
dbgt.Size = UDim2.new(1, -10, 1, 0)
dbgt.Position = UDim2.new(0, 5, 0, 0)
dbgt.BackgroundTransparency = 1
dbgt.Text = "Loading..."
dbgt.TextColor3 = Color3.new(1,1,1)
dbgt.TextSize = 12
dbgt.Font = Enum.Font.GothamBold
dbgt.TextXAlignment = Enum.TextXAlignment.Left
dbgt.Parent = dbg

local GUI = Load("gui/framework")
if not GUI then
	dbg.BackgroundColor3 = Color3.fromRGB(255,0,0)
	dbgt.Text = "Framework FAIL"
	return
end

dbg.BackgroundColor3 = Color3.fromRGB(0,255,0)
dbgt.Text = "Framework OK — type="..typeof(GUI).." has CreateTab="..tostring(GUI.CreateTab ~= nil)

local window = GUI.CreateWindow(sg, "Pouncing.exe", UDim2.new(0, 560, 0, 400))

-- Check window.Tabs before creating
dbgt.Text = "Window created. Tabs type="..typeof(window.Tabs).." count="..tostring(#window.Tabs)

-- Try ONE CreateTab with full diagnostics
local testOk, testResult = pcall(function()
	return GUI.CreateTab(window, "TEST", "X")
end)
if not testOk then
	dbg.BackgroundColor3 = Color3.fromRGB(255,0,0)
	dbgt.Text = "CreateTab CRASHED: "..tostring(testResult)
	return
end
if not testResult then
	dbg.BackgroundColor3 = Color3.fromRGB(255,100,0)
	dbgt.Text = "CreateTab returned nil!"
	return
end

dbg.BackgroundColor3 = Color3.fromRGB(0,255,0)
dbgt.Text = "CreateTab works! type="..typeof(testResult).." count="..tostring(#window.Tabs)

-- Now create all tabs
local Tabs = {
	{Name = "Aimbot", Icon = "🎯"},
	{Name = "ESP", Icon = "👁️"},
	{Name = "Gun", Icon = "🔫"},
	{Name = "Misc", Icon = "⚙️"},
	{Name = "Config", Icon = "💾"}
}

for _, tabInfo in ipairs(Tabs) do
	local ok, res = pcall(function()
		return GUI.CreateTab(window, tabInfo.Name, tabInfo.Icon)
	end)
end

dbgt.Text = "All tabs done. count="..tostring(#window.Tabs).."/5"

-- Build content
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local function BuildTab(name)
	local con = window.Contents[name]
	if not con then return end
	if name == "Aimbot" then
		GUI.CreateSection(con, "Aimbot")
		GUI.CreateToggle(con, "Enabled", false, nil, function(v) end)
	elseif name == "ESP" then
		GUI.CreateSection(con, "ESP")
		GUI.CreateToggle(con, "Enabled", false, nil, function(v) end)
	elseif name == "Gun" then
		GUI.CreateSection(con, "Gun")
		GUI.CreateToggle(con, "Enabled", false, nil, function(v) end)
	elseif name == "Misc" then
		GUI.CreateSection(con, "Misc")
		GUI.CreateToggle(con, "Enabled", false, nil, function(v) end)
	elseif name == "Config" then
		GUI.CreateSection(con, "Config")
		GUI.CreateLabel(con, "Pouncing.exe v1.0", false)
		GUI.CreateLabel(con, "RightShift to toggle", true)
	end
end

for _, tabInfo in ipairs(Tabs) do
	BuildTab(tabInfo.Name)
end

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