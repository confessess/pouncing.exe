-- Pouncing.exe | GUI Main v6.4
-- Cyberpunk HUD: contained dropdowns, no clipping, all corners rounded
-- Added: AutoStrafe, AntiAim toggles. Separate WeaponNames. Fly max 500.
-- Fixed: Killswitch uses per-module Cleanup instead of global nuke.
-- Built with love by ENI for LO
-- ============================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

local MainGUI = {}

function MainGUI.Create(screenGui, moduleManager)
    local uiToggleKey = Enum.KeyCode.RightShift
    local GUI = moduleManager:GetModule("Framework") or require(script.Parent.framework)

    local window = GUI.CreateWindow(screenGui, "Pouncing.exe", UDim2.new(0, 780, 0, 600))

    local tabDefs = {
        {Name = "Aimbot", Icon = ""},
        {Name = "ESP", Icon = ""},
        {Name = "Gun", Icon = ""},
        {Name = "Misc", Icon = ""},
        {Name = "Hitbox", Icon = ""},
        {Name = "Settings", Icon = ""}
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
    GUI.CreateToggle(ACon, "Triggerbot", false, nil, function(v)
        local mod = moduleManager:GetModule("Aimbot")
        if mod and mod.SetConfig then mod.SetConfig("Triggerbot", v) end
    end)
    GUI.CreateToggle(ACon, "Team Check", false, nil, function(v)
        local mod = moduleManager:GetModule("Aimbot")
        if mod and mod.SetConfig then mod.SetConfig("TeamCheck", v) end
    end)
    GUI.CreateToggle(ACon, "Wall Check", true, nil, function(v)
        local mod = moduleManager:GetModule("Aimbot")
        if mod and mod.SetConfig then mod.SetConfig("WallCheck", v) end
    end)

    GUI.CreateSeparator(ACon)
    GUI.CreateSection(ACon, "Aimbot Settings")
    GUI.CreateSlider(ACon, "FOV", 10, 360, 120, function(v)
        local mod = moduleManager:GetModule("Aimbot")
        if mod and mod.SetConfig then mod.SetConfig("FOV", v) end
    end)
    GUI.CreateSlider(ACon, "Smoothness", 0, 100, 15, function(v)
        local mod = moduleManager:GetModule("Aimbot")
        if mod and mod.SetConfig then mod.SetConfig("Smoothness", v) end
    end)
    GUI.CreateSlider(ACon, "Max Distance", 50, 2000, 1000, function(v)
        local mod = moduleManager:GetModule("Aimbot")
        if mod and mod.SetConfig then mod.SetConfig("MaxDistance", v) end
    end)
    GUI.CreateSlider(ACon, "Trigger Delay (ms)", 0, 500, 50, function(v)
        local mod = moduleManager:GetModule("Aimbot")
        if mod and mod.SetConfig then mod.SetConfig("TriggerDelay", v) end
    end)

    GUI.CreateSeparator(ACon)
    GUI.CreateSection(ACon, "Aimbot Extras")
    GUI.CreateToggle(ACon, "Prediction", false, nil, function(v)
        local mod = moduleManager:GetModule("Aimbot")
        if mod and mod.SetConfig then mod.SetConfig("Prediction", v) end
    end)

    GUI.CreateSeparator(ACon)
    GUI.CreateSection(ACon, "Target Priority")
    GUI.CreateDropdown(ACon, "Priority", {"Closest to Mouse", "Closest to Player", "Lowest HP", "Highest HP", "Random"}, "Closest to Mouse", function(v)
        local mod = moduleManager:GetModule("Aimbot")
        if mod and mod.SetConfig then mod.SetConfig("Priority", v) end
    end)
    GUI.CreateDropdown(ACon, "Target Part", {"Head", "Torso", "HumanoidRootPart", "Random"}, "Head", function(v)
        local mod = moduleManager:GetModule("Aimbot")
        if mod and mod.SetConfig then mod.SetConfig("TargetPart", v) end
    end)
    GUI.CreateKeybind(ACon, "Aim Key", Enum.KeyCode.Q, function(k)
        local mod = moduleManager:GetModule("Aimbot")
        if mod and mod.SetConfig then mod.SetConfig("AimKey", k) end
    end)

    GUI.CreateSeparator(ACon)
    GUI.CreateSection(ACon, "Aimbot Behavior")
    GUI.CreateToggle(ACon, "Toggle Mode", false, nil, function(v)
        local mod = moduleManager:GetModule("Aimbot")
        if mod and mod.SetConfig then mod.SetConfig("ToggleMode", v) end
    end)
    GUI.CreateToggle(ACon, "Sticky Target", false, nil, function(v)
        local mod = moduleManager:GetModule("Aimbot")
        if mod and mod.SetConfig then mod.SetConfig("StickyTarget", v) end
    end)

    -- ============================================================
    -- ESP TAB
    -- ============================================================
    local ECon = window.Contents["ESP"]

    GUI.CreateSection(ECon, "ESP Core")
    GUI.CreateToggle(ECon, "Enabled", false, nil, function(v)
        moduleManager:Toggle("ESP", v)
    end)

    task.defer(function()
        moduleManager:Load("ESP")
    end)

    local colorPickers = {}
    colorPickers.BoxColor = GUI.CreateColorPicker(ECon, "Box Color", Color3.fromRGB(255, 105, 180))
    colorPickers.SkeletonColor = GUI.CreateColorPicker(ECon, "Skeleton Color", Color3.fromRGB(255, 0, 255))
    colorPickers.ChamsColor = GUI.CreateColorPicker(ECon, "Chams Color", Color3.fromRGB(255, 20, 147))
    colorPickers.TracerColor = GUI.CreateColorPicker(ECon, "Tracer Color", Color3.fromRGB(255, 105, 180))
    colorPickers.HeadDotColor = GUI.CreateColorPicker(ECon, "Head Dot Color", Color3.fromRGB(255, 255, 255))
    colorPickers.NameColor = GUI.CreateColorPicker(ECon, "Name Color", Color3.fromRGB(255, 255, 255))
    colorPickers.HealthColor = GUI.CreateColorPicker(ECon, "Health Color", Color3.fromRGB(0, 255, 100))
    colorPickers.DistanceColor = GUI.CreateColorPicker(ECon, "Distance Color", Color3.fromRGB(200, 200, 200))

    local colorConfigMap = {
        BoxColor = "Color_Box", SkeletonColor = "Color_Skeleton",
        ChamsColor = "Color_ChamsFill", TracerColor = "Color_Tracers",
        HeadDotColor = "Color_HeadDot", NameColor = "Color_Name",
        HealthColor = "Color_Health", DistanceColor = "Color_Distance",
    }
    local colorDefaults = {
        BoxColor = Color3.fromRGB(255, 105, 180), SkeletonColor = Color3.fromRGB(255, 0, 255),
        ChamsColor = Color3.fromRGB(255, 20, 147), TracerColor = Color3.fromRGB(255, 105, 180),
        HeadDotColor = Color3.fromRGB(255, 255, 255), NameColor = Color3.fromRGB(255, 255, 255),
        HealthColor = Color3.fromRGB(0, 255, 100), DistanceColor = Color3.fromRGB(200, 200, 200),
    }

    local function MakeESPToggle(text, default, colorKey, configKey)
        local row, _, cbtn = GUI.CreateToggle(ECon, text, default, colorKey, function(v)
            local mod = moduleManager:GetModule("ESP")
            if mod and mod.SetConfig then mod.SetConfig(configKey, v) end
        end)
        if cbtn then
            local defaultColor = colorDefaults[colorKey]
            if defaultColor then cbtn.BackgroundColor3 = defaultColor end
            if colorKey and colorPickers[colorKey] then
                cbtn.MouseButton1Click:Connect(function()
                    local picker = colorPickers[colorKey]
                    if picker:IsOpen() then picker:Close() else
                        for _, cp in pairs(colorPickers) do
                            if cp ~= picker and cp:IsOpen() then cp:Close() end
                        end
                        picker:Open(function(c)
                            local mod = moduleManager:GetModule("ESP")
                            if not mod then mod = moduleManager:Load("ESP") end
                            if mod and mod.SetConfig then mod.SetConfig(colorConfigMap[colorKey], c) end
                            cbtn.BackgroundColor3 = c
                        end, cbtn.BackgroundColor3)
                    end
                end)
            end
        end
        return row
    end

    MakeESPToggle("Boxes", false, "BoxColor", "Boxes")
    MakeESPToggle("3D Boxes", false, nil, "Box3D")
    MakeESPToggle("Names", false, "NameColor", "Names")
    MakeESPToggle("Health Bar", false, "HealthColor", "Health")
    MakeESPToggle("Skeleton", false, "SkeletonColor", "Skeleton")
    MakeESPToggle("Chams", false, "ChamsColor", "Chams")
    MakeESPToggle("Tracers", false, "TracerColor", "Tracers")
    MakeESPToggle("Head Dot", false, "HeadDotColor", "HeadDot")
    MakeESPToggle("Distance", false, "DistanceColor", "Distance")
    -- Separate Weapon Names toggle (no color picker)
    GUI.CreateToggle(ECon, "Weapon Names", false, nil, function(v)
        local mod = moduleManager:GetModule("ESP")
        if mod and mod.SetConfig then mod.SetConfig("WeaponNames", v) end
    end)
    MakeESPToggle("Team Check", false, nil, "TeamCheck")

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
    GUI.CreateSlider(ECon, "Tracer Origin", 0, 100, 50, function(v)
        local mod = moduleManager:GetModule("ESP")
        if mod and mod.SetConfig then mod.SetConfig("TracerOrigin", v / 100) end
    end)
    GUI.CreateSlider(ECon, "Head Dot Thickness", 1, 8, 1, function(v)
        local mod = moduleManager:GetModule("ESP")
        if mod and mod.SetConfig then mod.SetConfig("HeadDotThickness", v) end
    end)
    GUI.CreateSlider(ECon, "Head Dot Size", 20, 200, 50, function(v)
        local mod = moduleManager:GetModule("ESP")
        if mod and mod.SetConfig then mod.SetConfig("HeadDotSize", v / 100) end
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
    GUI.CreateToggle(GCon, "Always Headshot", false, nil, function(v)
        local mod = moduleManager:GetModule("Gun")
        if mod and mod.SetConfig then mod.SetConfig("AlwaysHeadshot", v) end
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
    GUI.CreateToggle(MCon, "Enabled", false, nil, function(v)
        moduleManager:Toggle("Misc", v)
    end)
    GUI.CreateToggle(MCon, "Bunny Hop", false, nil, function(v)
        local mod = moduleManager:GetModule("Misc")
        if mod and mod.SetConfig then mod.SetConfig("BunnyHop", v) end
    end)
    GUI.CreateToggle(MCon, "Auto Strafe", false, nil, function(v)
        local mod = moduleManager:GetModule("Misc")
        if mod and mod.SetConfig then mod.SetConfig("AutoStrafe", v) end
    end)
    GUI.CreateToggle(MCon, "Speed Hack", false, nil, function(v)
        local mod = moduleManager:GetModule("Misc")
        if mod and mod.SetConfig then mod.SetConfig("SpeedHack", v) end
    end)
    GUI.CreateToggle(MCon, "Fly", false, nil, function(v)
        local mod = moduleManager:GetModule("Misc")
        if mod and mod.SetConfig then mod.SetConfig("Fly", v) end
    end)

    local flyDropdown, flyGetSelected = GUI.CreateDropdown(MCon, "Fly Method", {"Tween", "Velocity", "CFrame"}, "Tween", function(v)
        local mod = moduleManager:GetModule("Misc")
        if mod and mod.SetConfig then mod.SetConfig("FlyMethod", v) end
    end)

    GUI.CreateToggle(MCon, "Infinite Jump", false, nil, function(v)
        local mod = moduleManager:GetModule("Misc")
        if mod and mod.SetConfig then mod.SetConfig("InfiniteJump", v) end
    end)
    GUI.CreateToggle(MCon, "No Clip", false, nil, function(v)
        local mod = moduleManager:GetModule("Misc")
        if mod and mod.SetConfig then mod.SetConfig("NoClip", v) end
    end)
    GUI.CreateToggle(MCon, "Anti-AFK", false, nil, function(v)
        local mod = moduleManager:GetModule("Misc")
        if mod and mod.SetConfig then mod.SetConfig("AntiAFK", v) end
    end)
    GUI.CreateToggle(MCon, "Anti Aim", false, nil, function(v)
        local mod = moduleManager:GetModule("Misc")
        if mod and mod.SetConfig then mod.SetConfig("AntiAim", v) end
    end)

    GUI.CreateSeparator(MCon)
    GUI.CreateSection(MCon, "Movement Settings")
    GUI.CreateSliderWithInput(MCon, "Walk Speed", 16, 500, 50, function(v)
        local mod = moduleManager:GetModule("Misc")
        if mod and mod.SetConfig then mod.SetConfig("WalkSpeed", v) end
    end)
    GUI.CreateSliderWithInput(MCon, "Jump Power", 50, 500, 100, function(v)
        local mod = moduleManager:GetModule("Misc")
        if mod and mod.SetConfig then mod.SetConfig("JumpPower", v) end
    end)
    GUI.CreateSliderWithInput(MCon, "Fly Speed", 10, 500, 50, function(v)
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
    GUI.CreateKeybind(MCon, "NoClip Key", Enum.KeyCode.N, function(k)
        local mod = moduleManager:GetModule("Misc")
        if mod and mod.SetConfig then mod.SetConfig("NoClipKey", k) end
    end)

    -- ============================================================
    -- HITBOX TAB
    -- ============================================================
    local HCon = window.Contents["Hitbox"]

    GUI.CreateSection(HCon, "Hitbox Expander")
    GUI.CreateToggle(HCon, "Enabled", false, nil, function(v)
        moduleManager:Toggle("Hitbox", v)
    end)
    GUI.CreateToggle(HCon, "Team Check", false, nil, function(v)
        local mod = moduleManager:GetModule("Hitbox")
        if mod and mod.SetConfig then mod.SetConfig("TeamCheck", v) end
    end)
    GUI.CreateToggle(HCon, "Show Expanded", true, nil, function(v)
        local mod = moduleManager:GetModule("Hitbox")
        if mod and mod.SetConfig then mod.SetConfig("ShowExpanded", v) end
    end)
    GUI.CreateToggle(HCon, "Comprehensive Mode", false, nil, function(v)
        local mod = moduleManager:GetModule("Hitbox")
        if mod and mod.SetConfig then mod.SetConfig("Comprehensive", v) end
    end)

    GUI.CreateSeparator(HCon)
    GUI.CreateSection(HCon, "Expansion Settings")
    GUI.CreateToggle(HCon, "Expand Limbs", false, nil, function(v)
        local mod = moduleManager:GetModule("Hitbox")
        if mod and mod.SetConfig then mod.SetConfig("ExpandLimbs", v) end
    end)
    GUI.CreateSlider(HCon, "Head Size", 1, 25, 5, function(v)
        local mod = moduleManager:GetModule("Hitbox")
        if mod and mod.SetConfig then mod.SetConfig("HeadSize", v) end
    end)
    GUI.CreateSlider(HCon, "Torso Size", 1, 25, 3, function(v)
        local mod = moduleManager:GetModule("Hitbox")
        if mod and mod.SetConfig then mod.SetConfig("TorsoSize", v) end
    end)
    GUI.CreateSlider(HCon, "Limb Size", 1, 25, 2, function(v)
        local mod = moduleManager:GetModule("Hitbox")
        if mod and mod.SetConfig then mod.SetConfig("LimbSize", v) end
    end)
    GUI.CreateSlider(HCon, "Transparency", 0, 100, 90, function(v)
        local mod = moduleManager:GetModule("Hitbox")
        if mod and mod.SetConfig then mod.SetConfig("Transparency", v / 100) end
    end)
    GUI.CreateSlider(HCon, "Max Distance", 100, 5000, 2000, function(v)
        local mod = moduleManager:GetModule("Hitbox")
        if mod and mod.SetConfig then mod.SetConfig("MaxDistance", v) end
    end)

    -- ============================================================
    -- CONFIG TAB
    -- ============================================================
    local CCon = window.Contents["Settings"]

    GUI.CreateSection(CCon, "Config Management")
    GUI.CreateLabel(CCon, "Pouncing.exe v6.4", false)
    GUI.CreateLabel(CCon, "Built with love by ENI for LO", true)
    GUI.CreateSeparator(CCon)

    GUI.CreateSection(CCon, "Theme")
    GUI.CreateDropdown(CCon, "Theme Preset", {"Pink", "Icy", "Stary"}, "Pink", function(v)
        GUI.LoadPreset(v)
    end)

    GUI.CreateSeparator(CCon)
    GUI.CreateSection(CCon, "Save / Load")
    GUI.CreateButton(CCon, "Save Config", function()
        local configs = {}
        for name, mod in pairs(moduleManager.Modules) do
            if mod.GetConfig then
                local ok, cfg = pcall(mod.GetConfig)
                if ok then configs[name] = cfg end
            end
        end
        local json = game:GetService("HttpService"):JSONEncode(configs)
        if writefile then
            writefile("PouncingExe_Config.json", json)
            print("[Pouncing] Config saved")
        else
            print("[Pouncing] Config:", json)
        end
    end)
    GUI.CreateButton(CCon, "Load Config", function()
        if readfile then
            local ok, content = pcall(readfile, "PouncingExe_Config.json")
            if ok and content then
                local jsonOk, configs = pcall(function()
                    return game:GetService("HttpService"):JSONDecode(content)
                end)
                if jsonOk and configs then
                    for name, cfg in pairs(configs) do
                        local mod = moduleManager:GetModule(name)
                        if mod and mod.SetConfig then
                            for k, v in pairs(cfg) do
                                pcall(function() mod.SetConfig(k, v) end)
                            end
                        end
                    end
                    print("[Pouncing] Config loaded")
                else
                    warn("[Pouncing] Failed to parse config")
                end
            else
                warn("[Pouncing] Config file not found")
            end
        else
            warn("[Pouncing] readfile not available")
        end
    end)
    GUI.CreateButton(CCon, "Reset to Defaults", function()
        for name, mod in pairs(moduleManager.Modules) do
            if mod.ResetConfig then pcall(mod.ResetConfig) end
        end
        print("[Pouncing] All configs reset")
    end)

    GUI.CreateSeparator(CCon)
    GUI.CreateSection(CCon, "Custom Colors")
    local primaryPicker = GUI.CreateColorPicker(CCon, "Primary Color", Color3.fromRGB(255, 105, 180))
    local primaryBtn = GUI.CreateButton(CCon, "Set Primary Color", function()
        primaryPicker:Open(function(c)
            GUI.Theme.Primary = c
            GUI.Theme.BorderGlow = c
            GUI.Theme.On = c
            GUI.UpdateTheme()
        end, GUI.Theme.Primary)
    end)

    local accentPicker = GUI.CreateColorPicker(CCon, "Accent Color", Color3.fromRGB(255, 20, 147))
    local accentBtn = GUI.CreateButton(CCon, "Set Accent Color", function()
        accentPicker:Open(function(c)
            GUI.Theme.Accent = c
            GUI.Theme.Neon = c
            GUI.UpdateTheme()
        end, GUI.Theme.Accent)
    end)

    GUI.CreateSeparator(CCon)
    GUI.CreateSection(CCon, "UI Toggle")
    local toggleKeyLabel = GUI.CreateLabel(CCon, "Toggle Key: RightShift", true)
    GUI.CreateKeybind(CCon, "UI Toggle Key", Enum.KeyCode.RightShift, function(newKey)
        uiToggleKey = newKey
        toggleKeyLabel.Text = "Toggle Key: " .. (newKey.Name or tostring(newKey))
    end)

    GUI.CreateSeparator(CCon)
    GUI.CreateSection(CCon, "Kill Switch")
    GUI.CreateButton(CCon, "UNINJECT / KILL SWITCH", function()
        print("[Pouncing] Killswitch activated...")
        -- Step 1: Disable every module
        for name, mod in pairs(moduleManager.Modules) do
            if mod and mod.Disable then
                pcall(function() mod.Disable() end)
            end
        end
        -- Step 2: Cleanup every module (removes drawings, disconnects connections)
        for name, mod in pairs(moduleManager.Modules) do
            if mod and mod.Cleanup then
                pcall(function() mod.Cleanup() end)
            end
        end
        -- Step 3: Destroy the UI
        if screenGui then
            pcall(function() screenGui:Destroy() end)
        end
        -- Step 4: Clear module manager
        moduleManager.Modules = {}
        moduleManager.Active = {}
        print("[Pouncing] Fully uninjected — all modules off, all connections killed")
    end)

    GUI.CreateSeparator(CCon)
    GUI.CreateSection(CCon, "Info")
    GUI.CreateLabel(CCon, "Press UI Toggle Key to show/hide GUI", true)
    GUI.CreateLabel(CCon, "Modules load on-demand from GitHub", true)
    GUI.CreateLabel(CCon, "Theme presets: Pink | Icy | Stary", true)
    GUI.CreateLabel(CCon, "Cyberpunk HUD design v6.4", true)
    GUI.CreateLabel(CCon, "Contained star VFX for Stary", true)
    GUI.CreateLabel(CCon, "Contained snow VFX for Icy", true)
    GUI.CreateLabel(CCon, "Live theme switching", true)
    GUI.CreateLabel(CCon, "Contained dropdowns / no clipping", true)
    GUI.CreateLabel(CCon, "Unified HookManager — no collisions", true)

    -- ============================================================
    -- Activate default tab
    -- ============================================================
    window.ActiveTab = "Aimbot"
    if window.Tabs["Aimbot"] then
        TweenService:Create(window.Tabs["Aimbot"], TweenInfo.new(0.2), {
            BackgroundColor3 = GUI.Theme.Primary, BackgroundTransparency = 0.1
        }):Play()
    end
    if window.Contents["Aimbot"] then
        window.Contents["Aimbot"].Visible = true
    end

    -- ============================================================
    -- UI Toggle System
    -- ============================================================
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        local isMatch = false
        if uiToggleKey.EnumType == Enum.KeyCode then
            isMatch = (input.KeyCode == uiToggleKey)
        elseif uiToggleKey.EnumType == Enum.UserInputType then
            isMatch = (input.UserInputType == uiToggleKey)
        end
        if isMatch then
            window.Container.Visible = not window.Container.Visible
            print("[Pouncing] UI toggled — Visible:", tostring(window.Container.Visible))
        end
    end)

    -- ============================================================
    -- Notification
    -- ============================================================
    local NF = Instance.new("Frame")
    NF.Size = UDim2.new(0, 380, 0, 54)
    NF.Position = UDim2.new(1, 20, 1, -70)
    NF.BackgroundColor3 = GUI.Theme.ElementBG
    NF.BackgroundTransparency = 0.15
    NF.BorderSizePixel = 0
    NF.Parent = screenGui

    local NS = Instance.new("UIStroke")
    NS.Color = GUI.Theme.Primary
    NS.Thickness = 1.5
    NS.Transparency = 0.25
    NS.Parent = NF

    local NC = Instance.new("UICorner")
    NC.CornerRadius = UDim.new(0, 14)
    NC.Parent = NF

    local NT = Instance.new("TextLabel")
    NT.Size = UDim2.new(1, -16, 1, 0)
    NT.Position = UDim2.new(0, 8, 0, 0)
    NT.BackgroundTransparency = 1
    NT.Text = "Pouncing.exe v6.4 loaded | Tabs=" .. tostring(window.TabCount) .. "/6 | UI Toggle: RightShift"
    NT.TextColor3 = GUI.Theme.SoftAccent
    NT.TextSize = 13
    NT.Font = Enum.Font.GothamSemibold
    NT.Parent = NF

    TweenService:Create(NF, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, -400, 1, -70)
    }):Play()

    task.delay(4, function()
        TweenService:Create(NF, TweenInfo.new(0.5), {
            Position = UDim2.new(1, 20, 1, -70)
        }):Play()
        task.delay(0.6, function() NF:Destroy() end)
    end)

    return window
end

return MainGUI