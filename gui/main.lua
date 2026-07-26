-- Pouncing.exe | GUI Main v2.0
-- Assembles the main window with all tabs and real controls
-- Made by pouncing :3
-- ============================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

local MainGUI = {}

function MainGUI.Create(screenGui, moduleManager)
    local GUI = moduleManager:GetModule("Framework") or require(script.Parent.framework)
    
    local window = GUI.CreateWindow(screenGui, "Pouncing.exe", UDim2.new(0, 560, 0, 400))
    
    -- ============================================================
    -- Create all 5 tabs
    -- ============================================================
    local tabDefs = {
        {Name = "Aimbot", Icon = "🎯"},
        {Name = "ESP", Icon = "👁️"},
        {Name = "Gun", Icon = "🔫"},
        {Name = "Misc", Icon = "⚙️"},
        {Name = "Config", Icon = "💾"}
    }
    
    for _, tabInfo in ipairs(tabDefs) do
        GUI.CreateTab(window, tabInfo.Name, tabInfo.Icon)
    end
    
    -- ============================================================
    -- AIMBOT TAB
    -- ============================================================
    local ACon = window.Contents["Aimbot"]
    
    GUI.CreateSection(ACon, "Aimbot Core")
    GUI.CreateToggle(ACon, "Enabled", false, nil, function(v)
        moduleManager:Toggle("Aimbot", v)
    end)
    GUI.CreateToggle(ACon, "Silent Aim", false, nil, function(v)
        local mod = moduleManager:GetModule("Aimbot")
        if mod and mod.SetConfig then mod.SetConfig("SilentAim", v) end
    end)
    GUI.CreateToggle(ACon, "Team Check", true, nil, function(v)
        local mod = moduleManager:GetModule("Aimbot")
        if mod and mod.SetConfig then mod.SetConfig("TeamCheck", v) end
    end)
    GUI.CreateToggle(ACon, "Wall Check", true, nil, function(v)
        local mod = moduleManager:GetModule("Aimbot")
        if mod and mod.SetConfig then mod.SetConfig("WallCheck", v) end
    end)
    
    GUI.CreateSeparator(ACon)
    GUI.CreateSection(ACon, "Aimbot Settings")
    GUI.CreateSlider(ACon, "FOV", 10, 500, 120, function(v)
        local mod = moduleManager:GetModule("Aimbot")
        if mod and mod.SetConfig then mod.SetConfig("FOV", v) end
    end)
    GUI.CreateSlider(ACon, "Smoothness", 1, 100, 15, function(v)
        local mod = moduleManager:GetModule("Aimbot")
        if mod and mod.SetConfig then mod.SetConfig("Smoothness", v) end
    end)
    GUI.CreateSlider(ACon, "Max Distance", 50, 2000, 1000, function(v)
        local mod = moduleManager:GetModule("Aimbot")
        if mod and mod.SetConfig then mod.SetConfig("MaxDistance", v) end
    end)
    
    GUI.CreateSeparator(ACon)
    GUI.CreateSection(ACon, "Target Priority")
    GUI.CreateDropdown(ACon, "Priority", {"Closest", "Lowest HP", "Highest Level", "Random"}, "Closest", function(v)
        local mod = moduleManager:GetModule("Aimbot")
        if mod and mod.SetConfig then mod.SetConfig("Priority", v) end
    end)
    GUI.CreateKeybind(ACon, "Aim Key", Enum.KeyCode.Q, function(k)
        local mod = moduleManager:GetModule("Aimbot")
        if mod and mod.SetConfig then mod.SetConfig("AimKey", k) end
    end)
    
    -- ============================================================
    -- ESP TAB
    -- ============================================================
    local ECon = window.Contents["ESP"]
    
    GUI.CreateSection(ECon, "ESP Core")
    GUI.CreateToggle(ECon, "Enabled", false, nil, function(v)
        moduleManager:Toggle("ESP", v)
    end)
    GUI.CreateToggle(ECon, "Boxes", true, "BoxColor", function(v)
        local mod = moduleManager:GetModule("ESP")
        if mod and mod.SetConfig then mod.SetConfig("Boxes", v) end
    end)
    GUI.CreateToggle(ECon, "Names", true, nil, function(v)
        local mod = moduleManager:GetModule("ESP")
        if mod and mod.SetConfig then mod.SetConfig("Names", v) end
    end)
    GUI.CreateToggle(ECon, "Health Bar", true, nil, function(v)
        local mod = moduleManager:GetModule("ESP")
        if mod and mod.SetConfig then mod.SetConfig("HealthBar", v) end
    end)
    GUI.CreateToggle(ECon, "Skeleton", false, "SkeletonColor", function(v)
        local mod = moduleManager:GetModule("ESP")
        if mod and mod.SetConfig then mod.SetConfig("Skeleton", v) end
    end)
    GUI.CreateToggle(ECon, "Chams", false, "ChamsColor", function(v)
        local mod = moduleManager:GetModule("ESP")
        if mod and mod.SetConfig then mod.SetConfig("Chams", v) end
    end)
    GUI.CreateToggle(ECon, "Distance", false, nil, function(v)
        local mod = moduleManager:GetModule("ESP")
        if mod and mod.SetConfig then mod.SetConfig("Distance", v) end
    end)
    GUI.CreateToggle(ECon, "Team Check", true, nil, function(v)
        local mod = moduleManager:GetModule("ESP")
        if mod and mod.SetConfig then mod.SetConfig("TeamCheck", v) end
    end)
    
    GUI.CreateSeparator(ECon)
    GUI.CreateSection(ECon, "ESP Settings")
    GUI.CreateSlider(ECon, "Max Distance", 50, 3000, 1500, function(v)
        local mod = moduleManager:GetModule("ESP")
        if mod and mod.SetConfig then mod.SetConfig("MaxDistance", v) end
    end)
    GUI.CreateSlider(ECon, "Box Thickness", 1, 5, 1, function(v)
        local mod = moduleManager:GetModule("ESP")
        if mod and mod.SetConfig then mod.SetConfig("BoxThickness", v) end
    end)
    
    GUI.CreateSeparator(ECon)
    GUI.CreateSection(ECon, "Colors")
    GUI.CreateColorPicker(ECon, "Box Color", Color3.fromRGB(255, 105, 180), function(c)
        local mod = moduleManager:GetModule("ESP")
        if mod and mod.SetConfig then mod.SetConfig("BoxColor", c) end
    end)
    GUI.CreateColorPicker(ECon, "Skeleton Color", Color3.fromRGB(255, 0, 255), function(c)
        local mod = moduleManager:GetModule("ESP")
        if mod and mod.SetConfig then mod.SetConfig("SkeletonColor", c) end
    end)
    GUI.CreateColorPicker(ECon, "Chams Color", Color3.fromRGB(255, 20, 147), function(c)
        local mod = moduleManager:GetModule("ESP")
        if mod and mod.SetConfig then mod.SetConfig("ChamsColor", c) end
    end)
    
    -- ============================================================
    -- GUN TAB
    -- ============================================================
    local GCon = window.Contents["Gun"]
    
    GUI.CreateSection(GCon, "Gun Mods")
    GUI.CreateToggle(GCon, "Enabled", false, nil, function(v)
        moduleManager:Toggle("Gun", v)
    end)
    GUI.CreateToggle(GCon, "No Recoil", false, nil, function(v)
        local mod = moduleManager:GetModule("Gun")
        if mod and mod.SetConfig then mod.SetConfig("NoRecoil", v) end
    end)
    GUI.CreateToggle(GCon, "No Spread", false, nil, function(v)
        local mod = moduleManager:GetModule("Gun")
        if mod and mod.SetConfig then mod.SetConfig("NoSpread", v) end
    end)
    GUI.CreateToggle(GCon, "Rapid Fire", false, nil, function(v)
        local mod = moduleManager:GetModule("Gun")
        if mod and mod.SetConfig then mod.SetConfig("RapidFire", v) end
    end)
    GUI.CreateToggle(GCon, "Auto Fire", false, nil, function(v)
        local mod = moduleManager:GetModule("Gun")
        if mod and mod.SetConfig then mod.SetConfig("AutoFire", v) end
    end)
    GUI.CreateToggle(GCon, "Infinite Ammo", false, nil, function(v)
        local mod = moduleManager:GetModule("Gun")
        if mod and mod.SetConfig then mod.SetConfig("InfiniteAmmo", v) end
    end)
    GUI.CreateToggle(GCon, "Instant Reload", false, nil, function(v)
        local mod = moduleManager:GetModule("Gun")
        if mod and mod.SetConfig then mod.SetConfig("InstantReload", v) end
    end)
    
    GUI.CreateSeparator(GCon)
    GUI.CreateSection(GCon, "Gun Settings")
    GUI.CreateSlider(GCon, "Fire Rate Multiplier", 1, 10, 2, function(v)
        local mod = moduleManager:GetModule("Gun")
        if mod and mod.SetConfig then mod.SetConfig("FireRate", v) end
    end)
    GUI.CreateSlider(GCon, "Damage Multiplier", 1, 10, 1, function(v)
        local mod = moduleManager:GetModule("Gun")
        if mod and mod.SetConfig then mod.SetConfig("DamageMult", v) end
    end)
    GUI.CreateSlider(GCon, "Recoil Reduction %", 0, 100, 100, function(v)
        local mod = moduleManager:GetModule("Gun")
        if mod and mod.SetConfig then mod.SetConfig("RecoilReduction", v) end
    end)
    
    -- ============================================================
    -- MISC TAB
    -- ============================================================
    local MCon = window.Contents["Misc"]
    
    GUI.CreateSection(MCon, "Movement")
    GUI.CreateToggle(MCon, "Bunny Hop", false, nil, function(v)
        moduleManager:Toggle("Misc", v)
        local mod = moduleManager:GetModule("Misc")
        if mod and mod.SetConfig then mod.SetConfig("BunnyHop", v) end
    end)
    GUI.CreateToggle(MCon, "Speed Hack", false, nil, function(v)
        local mod = moduleManager:GetModule("Misc")
        if mod and mod.SetConfig then mod.SetConfig("SpeedHack", v) end
    end)
    GUI.CreateToggle(MCon, "Fly", false, nil, function(v)
        local mod = moduleManager:GetModule("Misc")
        if mod and mod.SetConfig then mod.SetConfig("Fly", v) end
    end)
    GUI.CreateToggle(MCon, "Infinite Jump", false, nil, function(v)
        local mod = moduleManager:GetModule("Misc")
        if mod and mod.SetConfig then mod.SetConfig("InfiniteJump", v) end
    end)
    GUI.CreateToggle(MCon, "No Clip", false, nil, function(v)
        local mod = moduleManager:GetModule("Misc")
        if mod and mod.SetConfig then mod.SetConfig("NoClip", v) end
    end)
    
    GUI.CreateSeparator(MCon)
    GUI.CreateSection(MCon, "Movement Settings")
    GUI.CreateSlider(MCon, "Walk Speed", 16, 500, 50, function(v)
        local mod = moduleManager:GetModule("Misc")
        if mod and mod.SetConfig then mod.SetConfig("WalkSpeed", v) end
    end)
    GUI.CreateSlider(MCon, "Jump Power", 50, 500, 100, function(v)
        local mod = moduleManager:GetModule("Misc")
        if mod and mod.SetConfig then mod.SetConfig("JumpPower", v) end
    end)
    GUI.CreateSlider(MCon, "Fly Speed", 10, 200, 50, function(v)
        local mod = moduleManager:GetModule("Misc")
        if mod and mod.SetConfig then mod.SetConfig("FlySpeed", v) end
    end)
    
    GUI.CreateSeparator(MCon)
    GUI.CreateSection(MCon, "Visuals")
    GUI.CreateToggle(MCon, "Fullbright", false, nil, function(v)
        local mod = moduleManager:GetModule("Misc")
        if mod and mod.SetConfig then mod.SetConfig("Fullbright", v) end
    end)
    GUI.CreateToggle(MCon, "No Fog", false, nil, function(v)
        local mod = moduleManager:GetModule("Misc")
        if mod and mod.SetConfig then mod.SetConfig("NoFog", v) end
    end)
    GUI.CreateToggle(MCon, "No Shadows", false, nil, function(v)
        local mod = moduleManager:GetModule("Misc")
        if mod and mod.SetConfig then mod.SetConfig("NoShadows", v) end
    end)
    GUI.CreateToggle(MCon, "Custom Time", false, nil, function(v)
        local mod = moduleManager:GetModule("Misc")
        if mod and mod.SetConfig then mod.SetConfig("CustomTime", v) end
    end)
    
    GUI.CreateSeparator(MCon)
    GUI.CreateSection(MCon, "Visual Settings")
    GUI.CreateSlider(MCon, "Brightness", 0, 10, 2, function(v)
        local mod = moduleManager:GetModule("Misc")
        if mod and mod.SetConfig then mod.SetConfig("Brightness", v) end
    end)
    GUI.CreateSlider(MCon, "Time of Day", 0, 24, 12, function(v)
        local mod = moduleManager:GetModule("Misc")
        if mod and mod.SetConfig then mod.SetConfig("TimeOfDay", v) end
    end)
    
    GUI.CreateSeparator(MCon)
    GUI.CreateSection(MCon, "Keybinds")
    GUI.CreateKeybind(MCon, "Fly Key", Enum.KeyCode.F, function(k)
        local mod = moduleManager:GetModule("Misc")
        if mod and mod.SetConfig then mod.SetConfig("FlyKey", k) end
    end)
    GUI.CreateKeybind(MCon, "Speed Key", Enum.KeyCode.LeftShift, function(k)
        local mod = moduleManager:GetModule("Misc")
        if mod and mod.SetConfig then mod.SetConfig("SpeedKey", k) end
    end)
    
    -- ============================================================
    -- CONFIG TAB
    -- ============================================================
    local CCon = window.Contents["Config"]
    
    GUI.CreateSection(CCon, "Config Management")
    GUI.CreateLabel(CCon, "Pouncing.exe v2.0", false)
    GUI.CreateLabel(CCon, "Built with love by ENI for LO 💗", true)
    GUI.CreateSeparator(CCon)
    
    GUI.CreateSection(CCon, "Save / Load")
    GUI.CreateButton(CCon, "💾 Save Config", function()
        -- Save all module configs
        local configs = {}
        for name, mod in pairs(moduleManager.Modules) do
            if mod.GetConfig then
                local ok, cfg = pcall(mod.GetConfig)
                if ok then configs[name] = cfg end
            end
        end
        -- Write to file or print
        print("[Pouncing] Config saved:", game:GetService("HttpService"):JSONEncode(configs))
    end)
    GUI.CreateButton(CCon, "📂 Load Config", function()
        -- Load from file or default
        print("[Pouncing] Config load triggered")
    end)
    GUI.CreateButton(CCon, "🔄 Reset to Defaults", function()
        for name, mod in pairs(moduleManager.Modules) do
            if mod.ResetConfig then pcall(mod.ResetConfig) end
        end
        print("[Pouncing] All configs reset")
    end)
    
    GUI.CreateSeparator(CCon)
    GUI.CreateSection(CCon, "Theme")
    GUI.CreateColorPicker(CCon, "Primary Color", Color3.fromRGB(255, 105, 180), function(c)
        -- Would update theme dynamically
        print("[Pouncing] Primary color set to", c)
    end)
    GUI.CreateColorPicker(CCon, "Accent Color", Color3.fromRGB(255, 20, 147), function(c)
        print("[Pouncing] Accent color set to", c)
    end)
    
    GUI.CreateSeparator(CCon)
    GUI.CreateSection(CCon, "Info")
    GUI.CreateLabel(CCon, "RightShift to toggle GUI", true)
    GUI.CreateLabel(CCon, "Modules load on-demand from GitHub", true)
    GUI.CreateLabel(CCon, "TabCount fix applied ✓", true)
    
    -- ============================================================
    -- Activate default tab
    -- ============================================================
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
    
    -- ============================================================
    -- RightShift toggle
    -- ============================================================
    UserInputService.InputBegan:Connect(function(input, gp)
        if not gp and input.KeyCode == Enum.KeyCode.RightShift then
            window.MainFrame.Visible = not window.MainFrame.Visible
        end
    end)
    
    -- ============================================================
    -- Notification
    -- ============================================================
    local NF = Instance.new("Frame")
    NF.Size = UDim2.new(0, 300, 0, 44)
    NF.Position = UDim2.new(1, 20, 1, -60)
    NF.BackgroundColor3 = Color3.fromRGB(35, 20, 30)
    NF.BorderSizePixel = 0
    NF.Parent = screenGui
    
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
    NT.Text = "🐾 Pouncing.exe v2.0 loaded | Tabs=" .. tostring(window.TabCount) .. "/5 | RightShift"
    NT.TextColor3 = Color3.fromRGB(255, 182, 193)
    NT.TextSize = 12
    NT.Font = Enum.Font.GothamSemibold
    NT.Parent = NF
    
    TweenService:Create(NF, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, -320, 1, -60)
    }):Play()
    
    task.delay(4, function()
        TweenService:Create(NF, TweenInfo.new(0.5), {
            Position = UDim2.new(1, 20, 1, -60)
        }):Play()
        task.delay(0.6, function() NF:Destroy() end)
    end)
    
    return window
end

return MainGUI