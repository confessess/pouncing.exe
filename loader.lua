-- Pouncing.exe | Inline Loader — FIXED tab counting

local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

for _, c in pairs(CoreGui:GetChildren()) do
	if c.Name:find("Pouncing") then c:Destroy() end
end
if _G._PouncingRunning then return end
_G._PouncingRunning = true

local Theme = {
	BG = Color3.fromRGB(22, 12, 20),
	TabBG = Color3.fromRGB(30, 18, 28),
	ElementBG = Color3.fromRGB(35, 22, 32),
	HoverBG = Color3.fromRGB(45, 28, 42),
	Primary = Color3.fromRGB(255, 105, 180),
	Secondary = Color3.fromRGB(255, 182, 193),
	Accent = Color3.fromRGB(255, 20, 147),
	Neon = Color3.fromRGB(255, 0, 255),
	Text = Color3.fromRGB(255, 240, 245),
	SubText = Color3.fromRGB(200, 160, 180),
	On = Color3.fromRGB(255, 105, 180),
	OnGlow = Color3.fromRGB(255, 150, 210),
	Off = Color3.fromRGB(60, 40, 55),
	Border = Color3.fromRGB(60, 35, 55),
	BorderGlow = Color3.fromRGB(255, 105, 180),
	White = Color3.fromRGB(255, 255, 255),
}

local GUI = {}
GUI.Theme = Theme

function GUI.CreateWindow(parent, title, size)
	size = size or UDim2.new(0, 540, 0, 380)
	local MF = Instance.new("Frame")
	MF.Name = "PouncingMain"
	MF.Size = size
	MF.Position = UDim2.new(0.5, -size.X.Offset/2, 0.5, -size.Y.Offset/2)
	MF.BackgroundColor3 = Theme.BG
	MF.BorderSizePixel = 0
	MF.Active = true
	MF.ClipsDescendants = true
	MF.Parent = parent

	Instance.new("UICorner").Parent = MF

	local border = Instance.new("UIStroke")
	border.Color = Theme.BorderGlow
	border.Thickness = 1.2
	border.Transparency = 0.4
	border.Parent = MF

	local TB = Instance.new("Frame")
	TB.Size = UDim2.new(1, 0, 0, 40)
	TB.BackgroundColor3 = Theme.TabBG
	TB.BorderSizePixel = 0
	TB.Parent = MF

	local TT = Instance.new("TextLabel")
	TT.Size = UDim2.new(1, -100, 1, 0)
	TT.Position = UDim2.new(0, 16, 0, 0)
	TT.BackgroundTransparency = 1
	TT.Text = "🐾 " .. title
	TT.TextColor3 = Theme.Text
	TT.TextSize = 15
	TT.Font = Enum.Font.GothamBold
	TT.TextXAlignment = Enum.TextXAlignment.Left
	TT.Parent = TB

	local TCon = Instance.new("Frame")
	TCon.Size = UDim2.new(0, 130, 1, -40)
	TCon.Position = UDim2.new(0, 0, 0, 40)
	TCon.BackgroundColor3 = Theme.TabBG
	TCon.BorderSizePixel = 0
	TCon.Parent = MF

	local CCon = Instance.new("Frame")
	CCon.Size = UDim2.new(1, -130, 1, -40)
	CCon.Position = UDim2.new(0, 130, 0, 40)
	CCon.BackgroundTransparency = 1
	CCon.BorderSizePixel = 0
	CCon.Parent = MF

	return {
		MainFrame = MF,
		TabContainer = TCon,
		ContentContainer = CCon,
		Tabs = {},
		Contents = {},
		ActiveTab = nil,
		TabCount = 0  -- FIXED: numeric counter
	}
end

function GUI.CreateTab(window, name, icon)
	local order = window.TabCount  -- FIXED: use counter instead of #window.Tabs
	local B = Instance.new("TextButton")
	B.Name = name .. "Tab"
	B.Size = UDim2.new(1, -14, 0, 36)
	B.Position = UDim2.new(0, 7, 0, 10 + (order * 42))
	B.BackgroundColor3 = Theme.BG
	B.BorderSizePixel = 0
	B.Text = "  " .. (icon or "•") .. "  " .. name
	B.TextColor3 = Theme.SubText
	B.TextSize = 12
	B.Font = Enum.Font.GothamSemibold
	B.TextXAlignment = Enum.TextXAlignment.Left
	B.Parent = window.TabContainer

	Instance.new("UICorner").Parent = B

	B.MouseEnter:Connect(function()
		if window.ActiveTab ~= name then
			TweenService:Create(B, TweenInfo.new(0.2), {BackgroundColor3 = Theme.HoverBG}):Play()
		end
	end)
	B.MouseLeave:Connect(function()
		if window.ActiveTab ~= name then
			TweenService:Create(B, TweenInfo.new(0.2), {BackgroundColor3 = Theme.BG}):Play()
		end
	end)

	local F = Instance.new("ScrollingFrame")
	F.Name = name .. "Content"
	F.Size = UDim2.new(1, -12, 1, -12)
	F.Position = UDim2.new(0, 6, 0, 6)
	F.BackgroundTransparency = 1
	F.BorderSizePixel = 0
	F.ScrollBarThickness = 3
	F.ScrollBarImageColor3 = Theme.Primary
	F.Visible = false
	F.Parent = window.ContentContainer

	local L = Instance.new("UIListLayout")
	L.Padding = UDim.new(0, 10)
	L.SortOrder = Enum.SortOrder.LayoutOrder
	L.Parent = F

	L:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		F.CanvasSize = UDim2.new(0, 0, 0, L.AbsoluteContentSize.Y + 15)
	end)

	window.Tabs[name] = B
	window.Contents[name] = F
	window.TabCount = window.TabCount + 1  -- FIXED: increment counter

	B.MouseButton1Click:Connect(function()
		if window.ActiveTab == name then return end
		if window.ActiveTab then
			local oldBtn = window.Tabs[window.ActiveTab]
			TweenService:Create(oldBtn, TweenInfo.new(0.2), {
				BackgroundColor3 = Theme.BG,
				TextColor3 = Theme.SubText
			}):Play()
			window.Contents[window.ActiveTab].Visible = false
		end
		window.ActiveTab = name
		TweenService:Create(B, TweenInfo.new(0.2), {
			BackgroundColor3 = Theme.Primary,
			TextColor3 = Theme.White
		}):Play()
		window.Contents[name].Visible = true
	end)

	return F
end

function GUI.CreateToggle(parent, text, default, colorKey, callback)
	local F = Instance.new("Frame")
	F.Size = UDim2.new(1, -10, 0, 38)
	F.BackgroundColor3 = Theme.ElementBG
	F.BorderSizePixel = 0
	F.Parent = parent
	Instance.new("UICorner").Parent = F

	local L = Instance.new("TextLabel")
	L.Size = UDim2.new(1, -110, 1, 0)
	L.Position = UDim2.new(0, 14, 0, 0)
	L.BackgroundTransparency = 1
	L.Text = text
	L.TextColor3 = Theme.Text
	L.TextSize = 12
	L.Font = Enum.Font.Gotham
	L.TextXAlignment = Enum.TextXAlignment.Left
	L.Parent = F

	local TBtn = Instance.new("TextButton")
	TBtn.Size = UDim2.new(0, 44, 0, 22)
	TBtn.Position = UDim2.new(1, -56, 0.5, -11)
	TBtn.BackgroundColor3 = default and Theme.On or Theme.Off
	TBtn.BorderSizePixel = 0
	TBtn.Text = ""
	TBtn.AutoButtonColor = false
	TBtn.Parent = F
	Instance.new("UICorner").Parent = TBtn

	local Circ = Instance.new("Frame")
	Circ.Size = UDim2.new(0, 18, 0, 18)
	Circ.Position = default and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
	Circ.BackgroundColor3 = Theme.White
	Circ.BorderSizePixel = 0
	Circ.Parent = TBtn
	Instance.new("UICorner").Parent = Circ

	local State = default
	TBtn.MouseButton1Click:Connect(function()
		State = not State
		TweenService:Create(Circ, TweenInfo.new(0.25), {
			Position = State and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
		}):Play()
		TweenService:Create(TBtn, TweenInfo.new(0.25), {
			BackgroundColor3 = State and Theme.On or Theme.Off
		}):Play()
		if callback then callback(State) end
	end)

	return F
end

function GUI.CreateButton(parent, text, callback)
	local F = Instance.new("TextButton")
	F.Size = UDim2.new(1, -10, 0, 36)
	F.BackgroundColor3 = Theme.Primary
	F.BorderSizePixel = 0
	F.Text = text
	F.TextColor3 = Theme.White
	F.TextSize = 12
	F.Font = Enum.Font.GothamSemibold
	F.AutoButtonColor = false
	F.Parent = parent
	Instance.new("UICorner").Parent = F
	F.MouseButton1Click:Connect(function()
		if callback then callback() end
	end)
	return F
end

function GUI.CreateLabel(parent, text, isSub)
	local L = Instance.new("TextLabel")
	L.Size = UDim2.new(1, -10, 0, 22)
	L.BackgroundTransparency = 1
	L.Text = text
	L.TextColor3 = isSub and Theme.SubText or Theme.Text
	L.TextSize = isSub and 11 or 12
	L.Font = isSub and Enum.Font.Gotham or Enum.Font.GothamBold
	L.TextXAlignment = Enum.TextXAlignment.Left
	L.Parent = parent
	return L
end

function GUI.CreateSection(parent, title)
	local F = Instance.new("Frame")
	F.Size = UDim2.new(1, -10, 0, 28)
	F.BackgroundTransparency = 1
	F.BorderSizePixel = 0
	F.Parent = parent
	local L = Instance.new("TextLabel")
	L.Size = UDim2.new(1, 0, 1, 0)
	L.BackgroundTransparency = 1
	L.Text = "✦ " .. title
	L.TextColor3 = Theme.Primary
	L.TextSize = 12
	L.Font = Enum.Font.GothamBold
	L.TextXAlignment = Enum.TextXAlignment.Left
	L.Parent = F
	return F
end

-- ============================================================
-- BUILD GUI
-- ============================================================
local sg = Instance.new("ScreenGui")
sg.Name = "PouncingFixed"
sg.ResetOnSpawn = false
sg.Parent = CoreGui

local window = GUI.CreateWindow(sg, "Pouncing.exe", UDim2.new(0, 560, 0, 400))

local Tabs = {
	{Name = "Aimbot", Icon = "🎯"},
	{Name = "ESP", Icon = "👁️"},
	{Name = "Gun", Icon = "🔫"},
	{Name = "Misc", Icon = "⚙️"},
	{Name = "Config", Icon = "💾"}
}

for _, tabInfo in ipairs(Tabs) do
	GUI.CreateTab(window, tabInfo.Name, tabInfo.Icon)
end

-- Aimbot
local ACon = window.Contents["Aimbot"]
GUI.CreateSection(ACon, "Aimbot")
GUI.CreateToggle(ACon, "Enabled", false, nil, function(v) end)

-- ESP
local ECon = window.Contents["ESP"]
GUI.CreateSection(ECon, "ESP")
GUI.CreateToggle(ECon, "Enabled", false, nil, function(v) end)

-- Gun
local GCon = window.Contents["Gun"]
GUI.CreateSection(GCon, "Gun")
GUI.CreateToggle(GCon, "Enabled", false, nil, function(v) end)

-- Misc
local MCon = window.Contents["Misc"]
GUI.CreateSection(MCon, "Misc")
GUI.CreateToggle(MCon, "Enabled", false, nil, function(v) end)

-- Config
local CCon = window.Contents["Config"]
GUI.CreateSection(CCon, "Config")
GUI.CreateLabel(CCon, "Pouncing.exe v1.0", false)
GUI.CreateLabel(CCon, "RightShift to toggle", true)

-- Default tab
window.ActiveTab = "Aimbot"
if window.Tabs["Aimbot"] then
	TweenService:Create(window.Tabs["Aimbot"], TweenInfo.new(0.2), {
		BackgroundColor3 = Theme.Primary,
		TextColor3 = Theme.White
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
NT.Text = "🐾 Pouncing.exe loaded! Tabs=" .. tostring(window.TabCount) .. "/5"
NT.TextColor3 = Color3.fromRGB(255, 182, 193)
NT.TextSize = 12
NT.Font = Enum.Font.GothamSemibold
NT.Parent = NF