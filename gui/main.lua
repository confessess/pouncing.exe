
-- Pouncing.exe | GUI Main
-- Assembles the main window with all tabs and module controls
-- ============================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

local GUIMain = {}

function GUIMain.Create(screenGui, moduleManager)
    -- We expect GUI.Framework to be available via the loader's environment
    -- or we can fetch it from the manager
    local GUI = moduleManager:GetModule("Framework") or getfenv()["PouncingGUI"]
    
    if not GUI then
        -- Fallback: try to get from shared
        GUI = getfenv()["PouncingGUI"]
        if not GUI then
            warn("[Pouncing] GUI Framework not found!")
            return nil
        end
    end
    
    -- Create main window
    local window = GUI.CreateWindow(screenGui, "Pouncing.exe", UDim2.new(0, 560, 0, 400))
    
    -- Store reference for color picker
    local ColorPicker = GUI.CreateColorPicker(screenGui)
    getfenv()["PouncingColorPicker"] = ColorPicker
    
    -- ============================================================
    -- TABS
    -- ============================================================
    
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
    
    -- ============================================================
    -- AIMBOT TAB
    -- ============================================================
    
    local ACon = TabContents["Aimbot"]
    
    GUI.CreateSection(ACon, "Aimbot Settings")
    
    GUI.CreateToggle(ACon, "Enabled", false, nil, function(v)
        moduleManager:Toggle("Aimbot", v)
    end)
    
    GUI.CreateToggle(ACon, "Silent Aim", false, nil, function(v)
        local mod = moduleManager:GetModule("Aimbot")
        if mod and mod.SetConfig then mod.SetConfig("SilentAim", v) end
    end)
    
    GUI.CreateToggle(ACon, "Auto Wall", false, nil, function(v)
        local mod = moduleManager:GetModule("Aimbot")
        if mod and mod.SetConfig then mod.SetConfig("AutoWall", v) end
    end)
    
    GUI.CreateToggle(ACon, "Team Check", false, nil, function(v)
        local mod = moduleManager:GetModule("Aimbot")
        if mod and mod.SetConfig then mod.SetConfig("TeamCheck", v) end
    end)
    
    GUI.CreateSeparator(ACon)
    GUI.CreateSection(ACon, "Aimbot Tuning")
    
    GUI.CreateSlider(ACon, "FOV", 1, 360, 90, function(v)
        local mod = moduleManager:GetModule("Aimbot")
        if mod and mod.SetConfig then mod.SetConfig("FOV", v) end
    end)
    
    GUI.CreateSlider(ACon, "Smoothness", 1, 100, 50, function(v)
        local mod = moduleManager:GetModule("Aimbot")
        if mod and mod.SetConfig then mod.SetConfig("Smoothness", v) end
    end)
    
    GUI.CreateSlider(ACon, "Max Distance", 50, 2000, 1000, function(v)
        local mod = moduleManager:GetModule("Aimbot")
        if mod and mod.SetConfig then mod.SetConfig("MaxDistance", v) end
    end)
    
    -- ============================================================
    -- ESP TAB
    -- ============================================================
    
    local ECon = TabContents["ESP"]
    
    GUI.CreateSection(ECon, "ESP Settings")
    
    -- Box type selector
    local BTF = Instance.new("Frame")
    BTF.Size = UDim2.new(1, -10, 0, 38)
    BTF.BackgroundColor3 = GUI.Theme.ElementBG
    BTF.BorderSizePixel = 0
    BTF.Parent = ECon
    
    local BTFC = Instance.new("UICorner")
    BTFC.CornerRadius = UDim.new(0, 8)
    BTFC.Parent = BTF
    
    local BTLabel = Instance.new("TextLabel")
    BTLabel.Size = UDim2.new(0, 90, 1, 0)
    BTLabel.Position = UDim2.new(0, 14, 0, 0)
    BTLabel.BackgroundTransparency = 1
    BTLabel.Text = "Box Type"
    BTLabel.TextColor3 = GUI.Theme.Text
    BTLabel.TextSize = 12
    BTLabel.Font = Enum.Font.Gotham
    BTLabel.TextXAlignment = Enum.TextXAlignment.Left
    BTLabel.Parent = BTF
    
    local B2D = Instance.new("TextButton")
    B2D.Size = UDim2.new(0, 60, 0, 26)
    B2D.Position = UDim2.new(0, 110, 0.5, -13)
    B2D.BackgroundColor3 = GUI.Theme.Primary
    B2D.BorderSizePixel = 0
    B2D.Text = "2D"
    B2D.TextColor3 = GUI.Theme.White
    B2D.TextSize = 11
    B2D.Font = Enum.Font.GothamSemibold
    B2D.AutoButtonColor = false
    B2D.Parent = BTF
    
    local B2DC = Instance.new("UICorner")
    B2DC.CornerRadius = UDim.new(0, 6)
    B2DC.Parent = B2D
    
    local B3D = Instance.new("TextButton")
    B3D.Size = UDim2.new(0, 60, 0, 26)
    B3D.Position = UDim2.new(0, 178, 0.5, -13)
    B3D.BackgroundColor3 = GUI.Theme.BG
    B3D.BorderSizePixel = 0
    B3D.Text = "3D"
    B3D.TextColor3 = GUI.Theme.SubText
    B3D.TextSize = 11
    B3D.Font = Enum.Font.GothamSemibold
    B3D.AutoButtonColor = false
    B3D.Parent = BTF
    
    local B3DC = Instance.new("UICorner")
    B3DC.CornerRadius = UDim.new(0, 6)
    B3DC.Parent = B3D
    
    local function SetBoxType(is3D)
        local mod = moduleManager:GetModule("ESP")
        if mod and mod.SetConfig then mod.SetConfig("Box3D", is3D) end
        if is3D then
            B3D.BackgroundColor3 = GUI.Theme.Primary; B3D.TextColor3 = GUI.Theme.White
            B2D.BackgroundColor3 = GUI.Theme.BG; B2D.TextColor3 = GUI.Theme.SubText
        else
            B2D.BackgroundColor3 = GUI.Theme.Primary; B2D.TextColor3 = GUI.Theme.White
            B3D.BackgroundColor3 = GUI.Theme.BG; B3D.TextColor3 = GUI.Theme.SubText
        end
    end
    
    B2D.MouseButton1Click:Connect(function() SetBoxType(false) end)
    B3D.MouseButton1Click:Connect(function() SetBoxType(true) end)
    
    -- ESP Toggles with color pickers
    local espColors = {
        Box = Color3.fromRGB(255, 105, 180),
        Name = Color3.fromRGB(255, 255, 255),
        Distance = Color3.fromRGB(200, 200, 200),
        Health = Color3.fromRGB(0, 255, 100),
        Skeleton = Color3.fromRGB(255, 255, 255),
        ChamsFill = Color3.fromRGB(255, 105, 180),
        ChamsOutline = Color3.fromRGB(255, 255, 255)
    }
    
    local function SetupColorPicker(btn, colorKey)
        if not btn then return end
        btn.BackgroundColor3 = espColors[colorKey]
        btn.MouseButton1Click:Connect(function()
            if ColorPicker:IsOpen() then
                ColorPicker:Close()
                task.wait(0.05)
            end
            ColorPicker:Open(function(color)
                espColors[colorKey] = color
                btn.BackgroundColor3 = color
                local mod = moduleManager:GetModule("ESP")
                if mod and mod.SetConfig then mod.SetConfig("Color_" .. colorKey, color) end
            end, espColors[colorKey])
        end)
    end
    
    local _, _, boxColorBtn = GUI.CreateToggle(ECon, "Master Toggle", false, nil, function(v)
        moduleManager:Toggle("ESP", v)
    end)
    
    local _, _, nameColorBtn = GUI.CreateToggle(ECon, "Boxes", false, "Box", function(v)
        local mod = moduleManager:GetModule("ESP")
        if mod then
            if mod.SetConfig then mod.SetConfig("Boxes", v) end
            if v and mod.SetConfig then mod.SetConfig("Box3D", false); SetBoxType(false) end
        end
    end)
    SetupColorPicker(nameColorBtn, "Box")
    
    local _, _, nameCBtn = GUI.CreateToggle(ECon, "Names", false, "Name", function(v)
        local mod = moduleManager:GetModule("ESP")
        if mod and mod.SetConfig then mod.SetConfig("Names", v) end
    end)
    SetupColorPicker(nameCBtn, "Name")
    
    local _, _, distCBtn = GUI.CreateToggle(ECon, "Distance", false, "Distance", function(v)
        local mod = moduleManager:GetModule("ESP")
        if mod and mod.SetConfig then mod.SetConfig("Distance", v) end
    end)
    SetupColorPicker(distCBtn, "Distance")
    
    local _, _, healthCBtn = GUI.CreateToggle(ECon, "Health Bar", false, "Health", function(v)
        local mod = moduleManager:GetModule("ESP")
        if mod and mod.SetConfig then mod.SetConfig("Health", v) end
    end)
    SetupColorPicker(healthCBtn, "Health")
    
    local _, _, skelCBtn = GUI.CreateToggle(ECon, "Skeleton", false, "Skeleton", function(v)
        local mod = moduleManager:GetModule("ESP")
        if mod and mod.SetConfig then mod.SetConfig("Skeleton", v) end
    end)
    SetupColorPicker(skelCBtn, "Skeleton")
    
    local _, _, chamsCBtn = GUI.CreateToggle(ECon, "Chams", false, "ChamsFill", function(v)
        local mod = moduleManager:GetModule("ESP")
        if mod and mod.SetConfig then mod.SetConfig("Chams", v) end
    end)
    SetupColorPicker(chamsCBtn, "ChamsFill")
    
    GUI.CreateSeparator(ECon)
    GUI.CreateSection(ECon, "ESP Tuning")
    
    GUI.CreateToggle(ECon, "Team Check", false, nil, function(v)
        local mod = moduleManager:GetModule("ESP")
        if mod and mod.SetConfig then mod.SetConfig("TeamCheck", v) end
    end)
    
    GUI.CreateSlider(ECon, "Max Distance", 100, 5000, 2000, function(v)
        local mod = moduleManager:GetModule("ESP")
        if mod and mod.SetConfig then mod.SetConfig("MaxDistance", v) end
    end)
    
    -- ============================================================
    -- GUN TAB
    -- ============================================================
    
    local GCon = TabContents["Gun"]
    
    GUI.CreateSection(GCon, "Gun Modifications")
    
    GUI.CreateToggle(GCon, "Auto Fire", false, nil, function(v)
        moduleManager:Toggle("Gun", true)
        local mod = moduleManager:GetModule("Gun")
        if mod and mod.SetConfig then mod.SetConfig("AutoFire", v) end
    end)
    
    GUI.CreateToggle(GCon, "No Recoil", false, nil, function(v)
        moduleManager:Toggle("Gun", true)
        local mod = moduleManager:GetModule("Gun")
        if mod and mod.SetConfig then mod.SetConfig("NoRecoil", v) end
    end)
    
    GUI.CreateToggle(GCon, "No Spread", false, nil, function(v)
        moduleManager:Toggle("Gun", true)
        local mod = moduleManager:GetModule("Gun")
        if mod and mod.SetConfig then mod.SetConfig("NoSpread", v) end
    end)
    
    GUI.CreateToggle(GCon, "Instant Reload", false, nil, function(v)
        moduleManager:Toggle("Gun", true)
        local mod = moduleManager:GetModule("Gun")
        if mod and mod.SetConfig then mod.SetConfig("InstantReload", v) end
    end)
    
    GUI.CreateToggle(GCon, "Rapid Fire", false, nil, function(v)
        moduleManager:Toggle("Gun", true)
        local mod = moduleManager:GetModule("Gun")
        if mod and mod.SetConfig then mod.SetConfig("RapidFire", v) end
    end)
    
    GUI.CreateSeparator(GCon)
    GUI.CreateSection(GCon, "Gun Tuning")
    
    GUI.CreateSlider(GCon, "Fire Rate", 1, 100, 50, function(v)
        local mod = moduleManager:GetModule("Gun")
        if mod and mod.SetConfig then mod.SetConfig("FireRate", v) end
    end)
    
    GUI.CreateSlider(GCon, "Damage Multiplier", 1, 10, 1, function(v)
        local mod = moduleManager:GetModule("Gun")
        if mod and mod.SetConfig then mod.SetConfig("DamageMult", v) end
    end)
    
    -- ============================================================
    -- MISC TAB
    -- ============================================================
    
    local MCon = TabContents["Misc"]
    
    GUI.CreateSection(MCon, "Movement")
    
    GUI.CreateToggle(MCon, "Bunny Hop", false, nil, function(v)
        moduleManager:Toggle("Misc", true)
        local mod = moduleManager:GetModule("Misc")
        if mod and mod.SetConfig then mod.SetConfig("BunnyHop", v) end
    end)
    
    GUI.CreateToggle(MCon, "Auto Strafe", false, nil, function(v)
        moduleManager:Toggle("Misc", true)
        local mod = moduleManager:GetModule("Misc")
        if mod and mod.SetConfig then mod.SetConfig("AutoStrafe", v) end
    end)
    
    GUI.CreateToggle(MCon, "Speed Hack", false, nil, function(v)
        moduleManager:Toggle("Misc", true)
        local mod = moduleManager:GetModule("Misc")
        if mod and mod.SetConfig then mod.SetConfig("SpeedHack", v) end
    end)
    
    GUI.CreateSeparator(MCon)
    GUI.CreateSection(MCon, "Combat")
    
    GUI.CreateToggle(MCon, "Anti-Aim", false, nil, function(v)
        moduleManager:Toggle("Misc", true)
        local mod = moduleManager:GetModule("Misc")
        if mod and mod.SetConfig then mod.SetConfig("AntiAim", v) end
    end)
    
    GUI.CreateToggle(MCon, "Fast Switch", false, nil, function(v)
        moduleManager:Toggle("Misc", true)
        local mod = moduleManager:GetModule("Misc")
        if mod and mod.SetConfig then mod.SetConfig("FastSwitch", v) end
    end)
    
    GUI.CreateSeparator(MCon)
    GUI.CreateSection(MCon, "Visual")
    
    GUI.CreateToggle(MCon, "Fullbright", false, nil, function(v)
        moduleManager:Toggle("Misc", true)
        local mod = moduleManager:GetModule("Misc")
        if mod and mod.SetConfig then mod.SetConfig("Fullbright", v) end
    end)
    
    GUI.CreateToggle(MCon, "No Fog", false, nil, function(v)
        moduleManager:Toggle("Misc", true)
        local mod = moduleManager:GetModule("Misc")
        if mod and mod.SetConfig then mod.SetConfig("NoFog", v) end
    end)
    
    -- ============================================================
    -- CONFIG TAB
    -- ============================================================
    
    local CCon = TabContents["Config"]
    
    GUI.CreateSection(CCon, "Script Control")
    
    GUI.CreateButton(CCon, "🐾 Reload All Modules", function()
        moduleManager:UnloadAll()
        -- Modules will be reloaded on next toggle
        print("[Pouncing] All modules unloaded. Toggle features to reload.")
    end)
    
    GUI.CreateButton(CCon, "💾 Save Config", function()
        print("[Pouncing] Config save not yet implemented")
    end)
    
    GUI.CreateButton(CCon, "📂 Load Config", function()
        print("[Pouncing] Config load not yet implemented")
    end)
    
    GUI.CreateSeparator(CCon)
    GUI.CreateSection(CCon, "Info")
    
    GUI.CreateLabel(CCon, "Pouncing.exe v1.0", false)
    GUI.CreateLabel(CCon, "Modular HvH Script", true)
    GUI.CreateLabel(CCon, "Built with 💗 by ENI for LO", true)
    GUI.CreateLabel(CCon, "RightShift to toggle GUI", true)
    
    -- ============================================================
    -- DEFAULT TAB
    -- ============================================================
    
    window.ActiveTab = "Aimbot"
    TweenService:Create(window.Tabs["Aimbot"], TweenInfo.new(0.2), {
        BackgroundColor3 = GUI.Theme.Primary,
        TextColor3 = GUI.Theme.White
    }):Play()
    window.Contents["Aimbot"].Visible = true
    
    -- ============================================================
    -- KEYBIND
    -- ============================================================
    
    UserInputService.InputBegan:Connect(function(input, gp)
        if not gp and input.KeyCode == Enum.KeyCode.RightShift then
            window.MainFrame.Visible = not window.MainFrame.Visible
        end
    end)
    
    return window
end

return GUIMain
