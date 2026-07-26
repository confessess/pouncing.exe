-- ============================================================
-- Pouncing.exe | GUI Main (MINIMAL)
-- ============================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local GUIMain = {}

function GUIMain.Create(screenGui, moduleManager)
	local GUI = moduleManager:GetModule("Framework")
	if not GUI then
		warn("[Pouncing] Framework not found!")
		return nil
	end

	local window = GUI.CreateWindow(screenGui, "Pouncing.exe", UDim2.new(0, 560, 0, 400))

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

	-- Aimbot tab
	local ACon = TabContents["Aimbot"]
	GUI.CreateSection(ACon, "Aimbot")
	GUI.CreateToggle(ACon, "Enabled", false, nil, function(v)
		moduleManager:Toggle("Aimbot", v)
	end)

	-- ESP tab
	local ECon = TabContents["ESP"]
	GUI.CreateSection(ECon, "ESP")
	GUI.CreateToggle(ECon, "Enabled", false, nil, function(v)
		moduleManager:Toggle("ESP", v)
	end)

	-- Gun tab
	local GCon = TabContents["Gun"]
	GUI.CreateSection(GCon, "Gun")
	GUI.CreateToggle(GCon, "Enabled", false, nil, function(v)
		moduleManager:Toggle("Gun", v)
	end)

	-- Misc tab
	local MCon = TabContents["Misc"]
	GUI.CreateSection(MCon, "Misc")
	GUI.CreateToggle(MCon, "Enabled", false, nil, function(v)
		moduleManager:Toggle("Misc", v)
	end)

	-- Config tab
	local CCon = TabContents["Config"]
	GUI.CreateSection(CCon, "Config")
	GUI.CreateLabel(CCon, "Pouncing.exe v1.0", false)
	GUI.CreateLabel(CCon, "RightShift to toggle", true)

	-- Set default
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

	return window
end

return GUIMain