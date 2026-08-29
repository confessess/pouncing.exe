-- Pouncing.exe | GUI Main v7.5
-- Fixed: Robust error handling in ApplyPresetVisibility, auto-apply on dropdown change
-- Added: Debug output option, pcall wrappers on all visibility updates
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

    -- ============================================================
    -- DYNAMIC UI STATE
    -- ============================================================
    local ActivePreset = "Universal"
    local TaggedControls = {}
    local TaggedTabs = {}
    local AllTabNames = {"Aimbot", "ESP", "Gun", "Misc", "Hitbox", "Da Hood", "Settings"}
    local DebugGUI = false

    local function TagControl(frame, presets)
        if not frame then return end
        table.insert(TaggedControls, {
            frame = frame,
            presets = presets or {"all"}
        })
    end

    local function TagTab(name, button, content, presets)
        TaggedTabs[name] = {
            name = name,
            button = button,
            content = content,
            presets = presets or {"all"}
        }
    end

    local function ShouldShowForPreset(presets)
        for _, p in ipairs(presets) do
            if p == "all" then return true end
            if p == ActivePreset then return true end
            if p == "not_arsenal" and ActivePreset ~= "Arsenal" then return true end
            if p == "aim" and (ActivePreset == "Arsenal" or ActivePreset == "Da Hood" or ActivePreset == "Zee Hood" or ActivePreset == "Universal") then return true end
            if p == "gun" and (ActivePreset == "Arsenal" or ActivePreset == "Universal") then return true end
        end
        return false
    end

    local function RefreshAllCanvasSizes()
        if not window or not window.Contents then return end
        for _, content in pairs(window.Contents) do
            if content and content.Parent then
                local layout = content:FindFirstChildOfClass("UIListLayout")
                if layout then
                    content.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 24)
                end
            end
        end
    end

    local function ApplyPresetVisibility(presetName)
        local ok, err = pcall(function()
            if not presetName then return end
            if not window then
                if DebugGUI then warn("[Pouncing] ApplyPresetVisibility: window not initialized yet") end
                return
            end
            ActivePreset = presetName
            if DebugGUI then print("[Pouncing] UI refreshing for preset: " .. presetName) end

            -- Update controls
            for _, item in ipairs(TaggedControls) do
                local show = ShouldShowForPreset(item.presets)
                if item.frame and typeof(item.frame) == "Instance" then
                    item.frame.Visible = show
                end
            end

            -- Update tabs
            local visibleTabs = {}
            for name, tab in pairs(TaggedTabs) do
                local show = ShouldShowForPreset(tab.presets)
                if tab.button and typeof(tab.button) == "Instance" then
                    tab.button.Visible = show
                end
                if tab.content and typeof(tab.content) == "Instance" then
                    if not show then
                        tab.content.Visible = false
                    end
                end
                if show then
                    table.insert(visibleTabs, name)
                end
            end

            -- Switch active tab if current one is hidden
            if window.ActiveTab and TaggedTabs[window.ActiveTab] then
                local currentTab = TaggedTabs[window.ActiveTab]
                if currentTab and not ShouldShowForPreset(currentTab.presets) then
                    for _, name in ipairs(AllTabNames) do
                        local t = TaggedTabs[name]
                        if t and ShouldShowForPreset(t.presets) then
                            if window.Tabs and window.Tabs[name] then
                                for _, tabBtn in pairs(window.Tabs) do
                                    if tabBtn and typeof(tabBtn) == "Instance" then
                                        TweenService:Create(tabBtn, TweenInfo.new(0.2), {
                                            BackgroundColor3 = GUI.Theme.ElementBG, BackgroundTransparency = 0.45
                                        }):Play()
                                    end
                                end
                                TweenService:Create(window.Tabs[name], TweenInfo.new(0.2), {
                                    BackgroundColor3 = GUI.Theme.Primary, BackgroundTransparency = 0.1
                                }):Play()
                            end
                            if window.Contents then
                                for _, content in pairs(window.Contents) do
                                    if content and typeof(content) == "Instance" then
                                        content.Visible = false
                                    end
                                end
                            end
                            if window.Contents[name] and typeof(window.Contents[name]) == "Instance" then
                                window.Contents[name].Visible = true
                            end
                            window.ActiveTab = name
                            break
                        end
                    end
                end
            end

            task.delay(0.05, RefreshAllCanvasSizes)
        end)
        if not ok and DebugGUI then
            warn("[Pouncing] ApplyPresetVisibility error: " .. tostring(err))
        end
    end

    local window = GUI.CreateWindow(screenGui, "Pouncing.exe", UDim2.new(0, 780, 0, 600))

    -- ============================================================
    -- CREATE TABS
    -- ============================================================
    local tabDefs = {
        {Name = "Aimbot", Icon = "", Presets = {"all"}},
        {Name = "ESP", Icon = "", Presets = {"all"}},
        {Name = "Gun", Icon = "", Presets = {"Arsenal", "Universal"}},
        {Name = "Misc", Icon = "", Presets = {"all"}},
        {Name = "Hitbox", Icon = "", Presets = {"Da Hood", "Zee Hood", "Universal"}},
        {Name = "Da Hood", Icon = "", Presets = {"Da Hood", "Zee Hood"}},
        {Name = "Settings", Icon = "", Presets = {"all"}}
    }
    for _, tabInfo in ipairs(tabDefs) do
        GUI.CreateTab(window, tabInfo.Name, tabInfo.Icon)
        TagTab(tabInfo.Name, window.Tabs[tabInfo.Name], window.Contents[tabInfo.Name], tabInfo.Presets)
    end

    -- ============================================================
    -- AIMBOT TAB
    -- ============================================================
    local ACon = window.Contents["Aimbot"]

    local coreSection = GUI.CreateSection(ACon, "Aimbot Core")
    TagControl(coreSection, {"all"})

    local aimEnabledToggle = GUI.CreateToggle(ACon, "Enabled", false, nil, function(v)
        moduleManager:Toggle("Aimbot", v)
    end)
    TagControl(aimEnabledToggle, {"all"})

    local silentAimToggle = GUI.CreateToggle(ACon, "Silent Aim", false, nil, function(v)
        local mod = moduleManager:GetModule("Aimbot")
        if mod and mod.SetConfig then mod.SetConfig("SilentAim", v) end
    end)
    TagControl(silentAimToggle, {"aim"})

    -- Arsenal-only: Hitbox Expand
    local hitboxExpandToggle = GUI.CreateToggle(ACon, "Hitbox Expand", true, nil, function(v)
        local mod = moduleManager:GetModule("Aimbot")
        if mod and mod.SetConfig then mod.SetConfig("ArsenalHitboxExpand", v) end
    end)
    TagControl(hitboxExpandToggle, {"Arsenal"})

    -- Arsenal-only: Hitbox Size
    local hitboxSizeSlider = GUI.CreateSlider(ACon, "Hitbox Size", 1, 25, 13, function(v)
        local mod = moduleManager:GetModule("Aimbot")
        if mod and mod.SetConfig then mod.SetConfig("ArsenalHitboxSize", v) end
    end)
    TagControl(hitboxSizeSlider, {"Arsenal"})

    -- Non-Arsenal controls
    local legitModeToggle = GUI.CreateToggle(ACon, "Legit Mode", false, nil, function(v)
        local mod = moduleManager:GetModule("Aimbot")
        if mod and mod.SetConfig then mod.SetConfig("LegitMode", v) end
    end)
    TagControl(legitModeToggle, {"not_arsenal"})

    local hitChanceSlider = GUI.CreateSlider(ACon, "Hit Chance %", 0, 100, 100, function(v)
        local mod = moduleManager:GetModule("Aimbot")
        if mod and mod.SetConfig then mod.SetConfig("HitChance", v) end
    end)
    TagControl(hitChanceSlider, {"not_arsenal"})

    local legitThresholdSlider = GUI.CreateSlider(ACon, "Legit Threshold", 5, 100, 30, function(v)
        local mod = moduleManager:GetModule("Aimbot")
        if mod and mod.SetConfig then mod.SetConfig("LegitThreshold", v) end
    end)
    TagControl(legitThresholdSlider, {"not_arsenal"})

    local snapDurationSlider = GUI.CreateSlider(ACon, "Snap Duration (frames)", 1, 10, 2, function(v)
        local mod = moduleManager:GetModule("Aimbot")
        if mod and mod.SetConfig then mod.SetConfig("SnapDuration", v) end
    end)
    TagControl(snapDurationSlider, {"not_arsenal"})

    -- Universal controls
    local triggerbotToggle = GUI.CreateToggle(ACon, "Triggerbot", false, nil, function(v)
        local mod = moduleManager:GetModule("Aimbot")
        if mod and mod.SetConfig then mod.SetConfig("Triggerbot", v) end
    end)
    TagControl(triggerbotToggle, {"all"})

    local teamCheckToggle = GUI.CreateToggle(ACon, "Team Check", false, nil, function(v)
        local mod = moduleManager:GetModule("Aimbot")
        if mod and mod.SetConfig then mod.SetConfig("TeamCheck", v) end
    end)
    TagControl(teamCheckToggle, {"all"})

    local wallCheckToggle = GUI.CreateToggle(ACon, "Wall Check", true, nil, function(v)
        local mod = moduleManager:GetModule("Aimbot")
        if mod and mod.SetConfig then mod.SetConfig("WallCheck", v) end
    end)
    TagControl(wallCheckToggle, {"all"})

    local sep1 = GUI.CreateSeparator(ACon)
    TagControl(sep1, {"all"})

    local settingsSection = GUI.CreateSection(ACon, "Aimbot Settings")
    TagControl(settingsSection, {"all"})

    local fovSlider = GUI.CreateSlider(ACon, "FOV", 10, 100, 60, function(v)
        local mod = moduleManager:GetModule("Aimbot")
        if mod and mod.SetConfig then mod.SetConfig("FOV", v) end
    end)
    TagControl(fovSlider, {"all"})

    local fovColorPicker = GUI.CreateColorPicker(ACon, "FOV Circle Color", Color3.fromRGB(255, 105, 180))
    TagControl(fovColorPicker, {"all"})
    local fovColorBtn = GUI.CreateButton(ACon, "Set FOV Color", function()
        fovColorPicker:Open(function(c)
            local mod = moduleManager:GetModule("Aimbot")
            if mod and mod.SetConfig then mod.SetConfig("FOVColor", c) end
        end, Color3.fromRGB(255, 105, 180))
    end)
    TagControl(fovColorBtn, {"all"})

    local smoothnessSlider = GUI.CreateSlider(ACon, "Smoothness", 0, 100, 15, function(v)
        local mod = moduleManager:GetModule("Aimbot")
        if mod and mod.SetConfig then mod.SetConfig("Smoothness", v) end
    end)
    TagControl(smoothnessSlider, {"not_arsenal"})

    local maxDistSlider = GUI.CreateSlider(ACon, "Max Distance", 50, 2000, 1000, function(v)
        local mod = moduleManager:GetModule("Aimbot")
        if mod and mod.SetConfig then mod.SetConfig("MaxDistance", v) end
    end)
    TagControl(maxDistSlider, {"all"})

    local triggerDelaySlider = GUI.CreateSlider(ACon, "Trigger Delay (ms)", 0, 500, 50, function(v)
        local mod = moduleManager:GetModule("Aimbot")
        if mod and mod.SetConfig then mod.SetConfig("TriggerDelay", v) end
    end)
    TagControl(triggerDelaySlider, {"all"})

    local sep2 = GUI.CreateSeparator(ACon)
    TagControl(sep2, {"all"})

    local extrasSection = GUI.CreateSection(ACon, "Aimbot Extras")
    TagControl(extrasSection, {"not_arsenal"})

    local predictionToggle = GUI.CreateToggle(ACon, "Prediction", false, nil, function(v)
        local mod = moduleManager:GetModule("Aimbot")
        if mod and mod.SetConfig then mod.SetConfig("Prediction", v) end
    end)
    TagControl(predictionToggle, {"not_arsenal"})

    local sep3 = GUI.CreateSeparator(ACon)
    TagControl(sep3, {"all"})

    local prioritySection = GUI.CreateSection(ACon, "Target Priority")
    TagControl(prioritySection, {"all"})

    local priorityDropdown = GUI.CreateDropdown(ACon, "Priority", {"Closest to Mouse", "Closest to Player", "Lowest HP", "Highest HP", "Random"}, "Closest to Mouse", function(v)
        local mod = moduleManager:GetModule("Aimbot")
        if mod and mod.SetConfig then mod.SetConfig("Priority", v) end
    end)
    TagControl(priorityDropdown, {"all"})

    local targetPartDropdown = GUI.CreateDropdown(ACon, "Target Part", {"Head", "Torso", "HumanoidRootPart", "Random"}, "Head", function(v)
        local mod = moduleManager:GetModule("Aimbot")
        if mod and mod.SetConfig then mod.SetConfig("TargetPart", v) end
    end)
    TagControl(targetPartDropdown, {"all"})

    local aimKeyBind = GUI.CreateKeybind(ACon, "Aim Key", Enum.KeyCode.Q, function(k)
        local mod = moduleManager:GetModule("Aimbot")
        if mod and mod.SetConfig then mod.SetConfig("AimKey", k) end
    end)
    TagControl(aimKeyBind, {"all"})

    local sep4 = GUI.CreateSeparator(ACon)
    TagControl(sep4, {"all"})

    local behaviorSection = GUI.CreateSection(ACon, "Aimbot Behavior")
    TagControl(behaviorSection, {"all"})

    local toggleModeToggle = GUI.CreateToggle(ACon, "Toggle Mode", false, nil, function(v)
        local mod = moduleManager:GetModule("Aimbot")
        if mod and mod.SetConfig then mod.SetConfig("ToggleMode", v) end
    end)
    TagControl(toggleModeToggle, {"all"})

    local stickyTargetToggle = GUI.CreateToggle(ACon, "Sticky Target", false, nil, function(v)
        local mod = moduleManager:GetModule("Aimbot")
        if mod and mod.SetConfig then mod.SetConfig("StickyTarget", v) end
    end)
    TagControl(stickyTargetToggle, {"all"})

    local sep5 = GUI.CreateSeparator(ACon)
    TagControl(sep5, {"all"})

    local debugSection = GUI.CreateSection(ACon, "Debug")
    TagControl(debugSection, {"all"})

    local debugModeToggle = GUI.CreateToggle(ACon, "Debug Mode", false, nil, function(v)
        local mod = moduleManager:GetModule("Aimbot")
        if mod and mod.SetConfig then mod.SetConfig("DebugMode", v) end
    end)
    TagControl(debugModeToggle, {"all"})

    local remoteSpyToggle = GUI.CreateToggle(ACon, "Remote Spy", false, nil, function(v)
        local mod = moduleManager:GetModule("Aimbot")
        if mod and mod.SetConfig then mod.SetConfig("RemoteSpy", v) end
    end)
    TagControl(remoteSpyToggle, {"all"})

    -- ============================================================
    -- ESP TAB
    -- ============================================================
    local ECon = window.Contents["ESP"]

    local espSection = GUI.CreateSection(ECon, "ESP Core")
    TagControl(espSection, {"all"})

    local espEnabledToggle = GUI.CreateToggle(ECon, "Enabled", false, nil, function(v)
        moduleManager:Toggle("ESP", v)
    end)
    TagControl(espEnabledToggle, {"all"})

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

    for _, cp in pairs(colorPickers) do
        TagControl(cp, {"all"})
    end

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
        TagControl(row, {"all"})
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

    local weaponNamesToggle = GUI.CreateToggle(ECon, "Weapon Names", false, nil, function(v)
        local mod = moduleManager:GetModule("ESP")
        if mod and mod.SetConfig then mod.SetConfig("WeaponNames", v) end
    end)
    TagControl(weaponNamesToggle, {"all"})

    MakeESPToggle("Team Check", false, nil, "TeamCheck")

    local espSep1 = GUI.CreateSeparator(ECon)
    TagControl(espSep1, {"all"})

    local espSettingsSection = GUI.CreateSection(ECon, "ESP Settings")
    TagControl(espSettingsSection, {"all"})

    local espMaxDistSlider = GUI.CreateSlider(ECon, "Max Distance", 50, 3000, 1500, function(v)
        local mod = moduleManager:GetModule("ESP")
        if mod and mod.SetConfig then mod.SetConfig("MaxDistance", v) end
    end)
    TagControl(espMaxDistSlider, {"all"})

    local boxThicknessSlider = GUI.CreateSlider(ECon, "Box Thickness", 1, 5, 1, function(v)
        local mod = moduleManager:GetModule("ESP")
        if mod and mod.SetConfig then mod.SetConfig("BoxThickness", v) end
    end)
    TagControl(boxThicknessSlider, {"all"})

    local tracerOriginSlider = GUI.CreateSlider(ECon, "Tracer Origin", 0, 100, 50, function(v)
        local mod = moduleManager:GetModule("ESP")
        if mod and mod.SetConfig then mod.SetConfig("TracerOrigin", v / 100) end
    end)
    TagControl(tracerOriginSlider, {"all"})

    local headDotThicknessSlider = GUI.CreateSlider(ECon, "Head Dot Thickness", 1, 8, 1, function(v)
        local mod = moduleManager:GetModule("ESP")
        if mod and mod.SetConfig then mod.SetConfig("HeadDotThickness", v) end
    end)
    TagControl(headDotThicknessSlider, {"all"})

    local headDotSizeSlider = GUI.CreateSlider(ECon, "Head Dot Size", 20, 200, 50, function(v)
        local mod = moduleManager:GetModule("ESP")
        if mod and mod.SetConfig then mod.SetConfig("HeadDotSize", v / 100) end
    end)
    TagControl(headDotSizeSlider, {"all"})

    -- ============================================================
    -- GUN TAB
    -- ============================================================
    local GCon = window.Contents["Gun"]

    local gunSection = GUI.CreateSection(GCon, "Gun Mods")
    TagControl(gunSection, {"gun"})

    local gunEnabledToggle = GUI.CreateToggle(GCon, "Enabled", false, nil, function(v)
        moduleManager:Toggle("Gun", v)
    end)
    TagControl(gunEnabledToggle, {"gun"})

    local noRecoilToggle = GUI.CreateToggle(GCon, "No Recoil", false, nil, function(v)
        local mod = moduleManager:GetModule("Gun")
        if mod and mod.SetConfig then mod.SetConfig("NoRecoil", v) end
    end)
    TagControl(noRecoilToggle, {"gun"})

    local noSpreadToggle = GUI.CreateToggle(GCon, "No Spread", false, nil, function(v)
        local mod = moduleManager:GetModule("Gun")
        if mod and mod.SetConfig then mod.SetConfig("NoSpread", v) end
    end)
    TagControl(noSpreadToggle, {"gun"})

    local rapidFireToggle = GUI.CreateToggle(GCon, "Rapid Fire", false, nil, function(v)
        local mod = moduleManager:GetModule("Gun")
        if mod and mod.SetConfig then mod.SetConfig("RapidFire", v) end
    end)
    TagControl(rapidFireToggle, {"gun"})

    local autoFireToggle = GUI.CreateToggle(GCon, "Auto Fire", false, nil, function(v)
        local mod = moduleManager:GetModule("Gun")
        if mod and mod.SetConfig then mod.SetConfig("AutoFire", v) end
    end)
    TagControl(autoFireToggle, {"gun"})

    local infiniteAmmoToggle = GUI.CreateToggle(GCon, "Infinite Ammo", false, nil, function(v)
        local mod = moduleManager:GetModule("Gun")
        if mod and mod.SetConfig then mod.SetConfig("InfiniteAmmo", v) end
    end)
    TagControl(infiniteAmmoToggle, {"gun"})

    local instantReloadToggle = GUI.CreateToggle(GCon, "Instant Reload", false, nil, function(v)
        local mod = moduleManager:GetModule("Gun")
        if mod and mod.SetConfig then mod.SetConfig("InstantReload", v) end
    end)
    TagControl(instantReloadToggle, {"gun"})

    local alwaysHeadshotToggle = GUI.CreateToggle(GCon, "Always Headshot", false, nil, function(v)
        local mod = moduleManager:GetModule("Gun")
        if mod and mod.SetConfig then mod.SetConfig("AlwaysHeadshot", v) end
    end)
    TagControl(alwaysHeadshotToggle, {"gun"})

    local gunSep1 = GUI.CreateSeparator(GCon)
    TagControl(gunSep1, {"gun"})

    local gunSettingsSection = GUI.CreateSection(GCon, "Gun Settings")
    TagControl(gunSettingsSection, {"gun"})

    local fireRateSlider = GUI.CreateSlider(GCon, "Fire Rate Multiplier", 1, 10, 2, function(v)
        local mod = moduleManager:GetModule("Gun")
        if mod and mod.SetConfig then mod.SetConfig("FireRate", v) end
    end)
    TagControl(fireRateSlider, {"gun"})

    local damageMultSlider = GUI.CreateSlider(GCon, "Damage Multiplier", 1, 10, 1, function(v)
        local mod = moduleManager:GetModule("Gun")
        if mod and mod.SetConfig then mod.SetConfig("DamageMult", v) end
    end)
    TagControl(damageMultSlider, {"gun"})

    local recoilReductionSlider = GUI.CreateSlider(GCon, "Recoil Reduction %", 0, 100, 100, function(v)
        local mod = moduleManager:GetModule("Gun")
        if mod and mod.SetConfig then mod.SetConfig("RecoilReduction", v) end
    end)
    TagControl(recoilReductionSlider, {"gun"})

    -- ============================================================
    -- MISC TAB
    -- ============================================================
    local MCon = window.Contents["Misc"]

    local miscMoveSection = GUI.CreateSection(MCon, "Movement")
    TagControl(miscMoveSection, {"all"})

    local miscEnabledToggle = GUI.CreateToggle(MCon, "Enabled", false, nil, function(v)
        moduleManager:Toggle("Misc", v)
    end)
    TagControl(miscEnabledToggle, {"all"})

    local bunnyHopToggle = GUI.CreateToggle(MCon, "Bunny Hop", false, nil, function(v)
        local mod = moduleManager:GetModule("Misc")
        if mod and mod.SetConfig then mod.SetConfig("BunnyHop", v) end
    end)
    TagControl(bunnyHopToggle, {"all"})

    local autoStrafeToggle = GUI.CreateToggle(MCon, "Auto Strafe", false, nil, function(v)
        local mod = moduleManager:GetModule("Misc")
        if mod and mod.SetConfig then mod.SetConfig("AutoStrafe", v) end
    end)
    TagControl(autoStrafeToggle, {"all"})

    local speedHackToggle = GUI.CreateToggle(MCon, "Speed Hack", false, nil, function(v)
        local mod = moduleManager:GetModule("Misc")
        if mod and mod.SetConfig then mod.SetConfig("SpeedHack", v) end
    end)
    TagControl(speedHackToggle, {"all"})

    local flyToggle = GUI.CreateToggle(MCon, "Fly", false, nil, function(v)
        local mod = moduleManager:GetModule("Misc")
        if mod and mod.SetConfig then mod.SetConfig("Fly", v) end
    end)
    TagControl(flyToggle, {"all"})

    local flyDropdown, flyGetSelected = GUI.CreateDropdown(MCon, "Fly Method", {"Tween", "Velocity", "CFrame"}, "Tween", function(v)
        local mod = moduleManager:GetModule("Misc")
        if mod and mod.SetConfig then mod.SetConfig("FlyMethod", v) end
    end)
    TagControl(flyDropdown, {"all"})

    local infiniteJumpToggle = GUI.CreateToggle(MCon, "Infinite Jump", false, nil, function(v)
        local mod = moduleManager:GetModule("Misc")
        if mod and mod.SetConfig then mod.SetConfig("InfiniteJump", v) end
    end)
    TagControl(infiniteJumpToggle, {"all"})

    local noClipToggle = GUI.CreateToggle(MCon, "No Clip", false, nil, function(v)
        local mod = moduleManager:GetModule("Misc")
        if mod and mod.SetConfig then mod.SetConfig("NoClip", v) end
    end)
    TagControl(noClipToggle, {"all"})

    local antiAFKToggle = GUI.CreateToggle(MCon, "Anti-AFK", false, nil, function(v)
        local mod = moduleManager:GetModule("Misc")
        if mod and mod.SetConfig then mod.SetConfig("AntiAFK", v) end
    end)
    TagControl(antiAFKToggle, {"all"})

    local antiAimToggle = GUI.CreateToggle(MCon, "Anti Aim", false, nil, function(v)
        local mod = moduleManager:GetModule("Misc")
        if mod and mod.SetConfig then mod.SetConfig("AntiAim", v) end
    end)
    TagControl(antiAimToggle, {"all"})

    local miscSep1 = GUI.CreateSeparator(MCon)
    TagControl(miscSep1, {"all"})

    local miscMoveSettingsSection = GUI.CreateSection(MCon, "Movement Settings")
    TagControl(miscMoveSettingsSection, {"all"})

    local walkSpeedSlider = GUI.CreateSliderWithInput(MCon, "Walk Speed", 16, 500, 50, function(v)
        local mod = moduleManager:GetModule("Misc")
        if mod and mod.SetConfig then mod.SetConfig("WalkSpeed", v) end
    end)
    TagControl(walkSpeedSlider, {"all"})

    local jumpPowerSlider = GUI.CreateSliderWithInput(MCon, "Jump Power", 50, 500, 100, function(v)
        local mod = moduleManager:GetModule("Misc")
        if mod and mod.SetConfig then mod.SetConfig("JumpPower", v) end
    end)
    TagControl(jumpPowerSlider, {"all"})

    local flySpeedSlider = GUI.CreateSliderWithInput(MCon, "Fly Speed", 10, 500, 50, function(v)
        local mod = moduleManager:GetModule("Misc")
        if mod and mod.SetConfig then mod.SetConfig("FlySpeed", v) end
    end)
    TagControl(flySpeedSlider, {"all"})

    local miscSep2 = GUI.CreateSeparator(MCon)
    TagControl(miscSep2, {"all"})

    local miscVisualsSection = GUI.CreateSection(MCon, "Visuals")
    TagControl(miscVisualsSection, {"all"})

    local fullbrightToggle = GUI.CreateToggle(MCon, "Fullbright", false, nil, function(v)
        local mod = moduleManager:GetModule("Misc")
        if mod and mod.SetConfig then mod.SetConfig("Fullbright", v) end
    end)
    TagControl(fullbrightToggle, {"all"})

    local noFogToggle = GUI.CreateToggle(MCon, "No Fog", false, nil, function(v)
        local mod = moduleManager:GetModule("Misc")
        if mod and mod.SetConfig then mod.SetConfig("NoFog", v) end
    end)
    TagControl(noFogToggle, {"all"})

    local noShadowsToggle = GUI.CreateToggle(MCon, "No Shadows", false, nil, function(v)
        local mod = moduleManager:GetModule("Misc")
        if mod and mod.SetConfig then mod.SetConfig("NoShadows", v) end
    end)
    TagControl(noShadowsToggle, {"all"})

    local customTimeToggle = GUI.CreateToggle(MCon, "Custom Time", false, nil, function(v)
        local mod = moduleManager:GetModule("Misc")
        if mod and mod.SetConfig then mod.SetConfig("CustomTime", v) end
    end)
    TagControl(customTimeToggle, {"all"})

    local miscSep3 = GUI.CreateSeparator(MCon)
    TagControl(miscSep3, {"all"})

    local miscVisualSettingsSection = GUI.CreateSection(MCon, "Visual Settings")
    TagControl(miscVisualSettingsSection, {"all"})

    local brightnessSlider = GUI.CreateSlider(MCon, "Brightness", 0, 10, 2, function(v)
        local mod = moduleManager:GetModule("Misc")
        if mod and mod.SetConfig then mod.SetConfig("Brightness", v) end
    end)
    TagControl(brightnessSlider, {"all"})

    local timeOfDaySlider = GUI.CreateSlider(MCon, "Time of Day", 0, 24, 12, function(v)
        local mod = moduleManager:GetModule("Misc")
        if mod and mod.SetConfig then mod.SetConfig("TimeOfDay", v) end
    end)
    TagControl(timeOfDaySlider, {"all"})

    local miscSep4 = GUI.CreateSeparator(MCon)
    TagControl(miscSep4, {"all"})

    local miscKeybindsSection = GUI.CreateSection(MCon, "Keybinds")
    TagControl(miscKeybindsSection, {"all"})

    local flyKeyBind = GUI.CreateKeybind(MCon, "Fly Key", Enum.KeyCode.F, function(k)
        local mod = moduleManager:GetModule("Misc")
        if mod and mod.SetConfig then mod.SetConfig("FlyKey", k) end
    end)
    TagControl(flyKeyBind, {"all"})

    local speedKeyBind = GUI.CreateKeybind(MCon, "Speed Key", Enum.KeyCode.LeftShift, function(k)
        local mod = moduleManager:GetModule("Misc")
        if mod and mod.SetConfig then mod.SetConfig("SpeedKey", k) end
    end)
    TagControl(speedKeyBind, {"all"})

    local noClipKeyBind = GUI.CreateKeybind(MCon, "NoClip Key", Enum.KeyCode.N, function(k)
        local mod = moduleManager:GetModule("Misc")
        if mod and mod.SetConfig then mod.SetConfig("NoClipKey", k) end
    end)
    TagControl(noClipKeyBind, {"all"})

    -- ============================================================
    -- HITBOX TAB
    -- ============================================================
    local HCon = window.Contents["Hitbox"]

    local hitboxSection = GUI.CreateSection(HCon, "Hitbox Expander")
    TagControl(hitboxSection, {"Da Hood", "Zee Hood", "Universal"})

    local hitboxEnabledToggle = GUI.CreateToggle(HCon, "Enabled", false, nil, function(v)
        moduleManager:Toggle("Hitbox", v)
    end)
    TagControl(hitboxEnabledToggle, {"Da Hood", "Zee Hood", "Universal"})

    local hitboxTeamCheckToggle = GUI.CreateToggle(HCon, "Team Check", false, nil, function(v)
        local mod = moduleManager:GetModule("Hitbox")
        if mod and mod.SetConfig then mod.SetConfig("TeamCheck", v) end
    end)
    TagControl(hitboxTeamCheckToggle, {"Da Hood", "Zee Hood", "Universal"})

    local hitboxShowToggle = GUI.CreateToggle(HCon, "Show Expanded", true, nil, function(v)
        local mod = moduleManager:GetModule("Hitbox")
        if mod and mod.SetConfig then mod.SetConfig("ShowExpanded", v) end
    end)
    TagControl(hitboxShowToggle, {"Da Hood", "Zee Hood", "Universal"})

    local hitboxCompToggle = GUI.CreateToggle(HCon, "Comprehensive Mode", false, nil, function(v)
        local mod = moduleManager:GetModule("Hitbox")
        if mod and mod.SetConfig then mod.SetConfig("Comprehensive", v) end
    end)
    TagControl(hitboxCompToggle, {"Da Hood", "Zee Hood", "Universal"})

    local hitboxStyleDropdown = GUI.CreateDropdown(HCon, "Visual Style", {"Transparent", "Outline", "Glow", "Wireframe"}, "Transparent", function(v)
        local mod = moduleManager:GetModule("Hitbox")
        if mod and mod.SetConfig then mod.SetConfig("VisualStyle", v) end
    end)
    TagControl(hitboxStyleDropdown, {"Da Hood", "Zee Hood", "Universal"})

    local hitboxColorPicker = GUI.CreateColorPicker(HCon, "Visual Color", Color3.fromRGB(255, 105, 180))
    TagControl(hitboxColorPicker, {"Da Hood", "Zee Hood", "Universal"})
    local hitboxColorBtn = GUI.CreateButton(HCon, "Set Visual Color", function()
        hitboxColorPicker:Open(function(c)
            local mod = moduleManager:GetModule("Hitbox")
            if mod and mod.SetConfig then mod.SetConfig("VisualColor", c) end
        end, Color3.fromRGB(255, 105, 180))
    end)
    TagControl(hitboxColorBtn, {"Da Hood", "Zee Hood", "Universal"})

    local hitboxSep1 = GUI.CreateSeparator(HCon)
    TagControl(hitboxSep1, {"Da Hood", "Zee Hood", "Universal"})

    local hitboxSettingsSection = GUI.CreateSection(HCon, "Expansion Settings")
    TagControl(hitboxSettingsSection, {"Da Hood", "Zee Hood", "Universal"})

    local hitboxTargetDropdown = GUI.CreateDropdown(HCon, "Target Parts", {"Head", "Torso", "HumanoidRootPart", "Head + Torso", "Head + HRP", "All Major"}, "Head", function(v)
        local mod = moduleManager:GetModule("Hitbox")
        if mod and mod.SetConfig then mod.SetConfig("TargetParts", v) end
    end)
    TagControl(hitboxTargetDropdown, {"Da Hood", "Zee Hood", "Universal"})

    local hitboxSizeSlider = GUI.CreateSlider(HCon, "Hitbox Size", 1, 25, 5, function(v)
        local mod = moduleManager:GetModule("Hitbox")
        if mod and mod.SetConfig then mod.SetConfig("HitboxSize", v) end
    end)
    TagControl(hitboxSizeSlider, {"Da Hood", "Zee Hood", "Universal"})

    local hitboxTransSlider = GUI.CreateSlider(HCon, "Transparency", 0, 100, 85, function(v)
        local mod = moduleManager:GetModule("Hitbox")
        if mod and mod.SetConfig then mod.SetConfig("Transparency", v / 100) end
    end)
    TagControl(hitboxTransSlider, {"Da Hood", "Zee Hood", "Universal"})

    local hitboxMaxDistSlider = GUI.CreateSlider(HCon, "Max Distance", 100, 5000, 2000, function(v)
        local mod = moduleManager:GetModule("Hitbox")
        if mod and mod.SetConfig then mod.SetConfig("MaxDistance", v) end
    end)
    TagControl(hitboxMaxDistSlider, {"Da Hood", "Zee Hood", "Universal"})

    local hitboxUpdateSlider = GUI.CreateSlider(HCon, "Update Rate", 1, 10, 2, function(v)
        local mod = moduleManager:GetModule("Hitbox")
        if mod and mod.SetConfig then mod.SetConfig("UpdateRate", v) end
    end)
    TagControl(hitboxUpdateSlider, {"Da Hood", "Zee Hood", "Universal"})

    -- ============================================================
    -- DA HOOD EXTRAS TAB
    -- ============================================================
    local DCon = window.Contents["Da Hood"]

    local dhSection = GUI.CreateSection(DCon, "Da Hood Tools")
    TagControl(dhSection, {"Da Hood", "Zee Hood"})

    local dhEnabledToggle = GUI.CreateToggle(DCon, "Enabled", false, nil, function(v)
        moduleManager:Toggle("DaHoodExtras", v)
    end)
    TagControl(dhEnabledToggle, {"Da Hood", "Zee Hood"})

    local dhKnockToggle = GUI.CreateToggle(DCon, "Knock Check", false, nil, function(v)
        local mod = moduleManager:GetModule("DaHoodExtras")
        if mod and mod.SetConfig then mod.SetConfig("KnockCheck", v) end
    end)
    TagControl(dhKnockToggle, {"Da Hood", "Zee Hood"})

    local dhAutoStompToggle = GUI.CreateToggle(DCon, "Auto Stomp", false, nil, function(v)
        local mod = moduleManager:GetModule("DaHoodExtras")
        if mod and mod.SetConfig then mod.SetConfig("AutoStomp", v) end
    end)
    TagControl(dhAutoStompToggle, {"Da Hood", "Zee Hood"})

    local dhAntiStompToggle = GUI.CreateToggle(DCon, "Anti Stomp", false, nil, function(v)
        local mod = moduleManager:GetModule("DaHoodExtras")
        if mod and mod.SetConfig then mod.SetConfig("AntiStomp", v) end
    end)
    TagControl(dhAntiStompToggle, {"Da Hood", "Zee Hood"})

    local dhAutoDropToggle = GUI.CreateToggle(DCon, "Auto Drop", false, nil, function(v)
        local mod = moduleManager:GetModule("DaHoodExtras")
        if mod and mod.SetConfig then mod.SetConfig("AutoDrop", v) end
    end)
    TagControl(dhAutoDropToggle, {"Da Hood", "Zee Hood"})

    local dhAntiBagToggle = GUI.CreateToggle(DCon, "Anti Bag", false, nil, function(v)
        local mod = moduleManager:GetModule("DaHoodExtras")
        if mod and mod.SetConfig then mod.SetConfig("AntiBag", v) end
    end)
    TagControl(dhAntiBagToggle, {"Da Hood", "Zee Hood"})

    local dhAntiGrabToggle = GUI.CreateToggle(DCon, "Anti Grab", false, nil, function(v)
        local mod = moduleManager:GetModule("DaHoodExtras")
        if mod and mod.SetConfig then mod.SetConfig("AntiGrab", v) end
    end)
    TagControl(dhAntiGrabToggle, {"Da Hood", "Zee Hood"})

    local dhAntiSlowToggle = GUI.CreateToggle(DCon, "Anti Slow", false, nil, function(v)
        local mod = moduleManager:GetModule("DaHoodExtras")
        if mod and mod.SetConfig then mod.SetConfig("AntiSlow", v) end
    end)
    TagControl(dhAntiSlowToggle, {"Da Hood", "Zee Hood"})

    local dhAntiFlingToggle = GUI.CreateToggle(DCon, "Anti Fling", false, nil, function(v)
        local mod = moduleManager:GetModule("DaHoodExtras")
        if mod and mod.SetConfig then mod.SetConfig("AntiFling", v) end
    end)
    TagControl(dhAntiFlingToggle, {"Da Hood", "Zee Hood"})

    local dhCashAuraToggle = GUI.CreateToggle(DCon, "Cash Aura", false, nil, function(v)
        local mod = moduleManager:GetModule("DaHoodExtras")
        if mod and mod.SetConfig then mod.SetConfig("CashAura", v) end
    end)
    TagControl(dhCashAuraToggle, {"Da Hood", "Zee Hood"})

    local dhCashAuraDistSlider = GUI.CreateSlider(DCon, "Cash Aura Distance", 5, 100, 20, function(v)
        local mod = moduleManager:GetModule("DaHoodExtras")
        if mod and mod.SetConfig then mod.SetConfig("CashAuraDist", v) end
    end)
    TagControl(dhCashAuraDistSlider, {"Da Hood", "Zee Hood"})

    local dhAutoBlockToggle = GUI.CreateToggle(DCon, "Auto Block", false, nil, function(v)
        local mod = moduleManager:GetModule("DaHoodExtras")
        if mod and mod.SetConfig then mod.SetConfig("AutoBlock", v) end
    end)
    TagControl(dhAutoBlockToggle, {"Da Hood", "Zee Hood"})

    local dhAntiLockToggle = GUI.CreateToggle(DCon, "Anti Lock", false, nil, function(v)
        local mod = moduleManager:GetModule("DaHoodExtras")
        if mod and mod.SetConfig then mod.SetConfig("AntiLock", v) end
    end)
    TagControl(dhAntiLockToggle, {"Da Hood", "Zee Hood"})

    -- ============================================================
    -- SETTINGS TAB
    -- ============================================================
    local SCon = window.Contents["Settings"]

    local presetSection = GUI.CreateSection(SCon, "Game Preset")
    TagControl(presetSection, {"all"})

    local detectedLabel = GUI.CreateLabel(SCon, "Detected Game: " .. gameName)
    TagControl(detectedLabel, {"all"})

    local presetDropdown, getPreset = GUI.CreateDropdown(SCon, "Manual Override", {"Auto-Detect", "Arsenal", "Da Hood", "Zee Hood", "Universal"}, "Auto-Detect", function(v)
        if v == "Auto-Detect" then
            selectedPreset = gameName
        else
            selectedPreset = v
        end
        detectedLabel.Text = "Active Preset: " .. selectedPreset
        if DebugGUI then print("[Pouncing] Manual preset selected: " .. selectedPreset) end
        -- Auto-apply on dropdown change
        ApplyPresetVisibility(selectedPreset)
    end)
    TagControl(presetDropdown, {"all"})

    local presetStatus = GUI.CreateLabel(SCon, "Preset Status: Ready")
    TagControl(presetStatus, {"all"})

    GUI.CreateButton(SCon, "Load Selected Preset", function()
        local presetName = selectedPreset
        if presetName == "Auto-Detect" then presetName = gameName end

        presetStatus.Text = "Preset Status: Fetching " .. presetName .. "..."
        presetStatus.TextColor3 = Color3.fromRGB(255, 200, 0)

        local baseUrl = "https://raw.githubusercontent.com/confessess/pouncing.exe/main/games/"
        local presetUrl = baseUrl .. "universal.lua"
        if presetName == "Arsenal" then
            presetUrl = baseUrl .. "arsenal.lua"
        elseif presetName == "Da Hood" or presetName == "Zee Hood" then
            presetUrl = baseUrl .. "da_hood.lua"
        end

        presetUrl = presetUrl .. "?t=" .. tostring(tick())

        local fetchOk, source = pcall(function()
            return game:HttpGet(presetUrl, true)
        end)

        if not fetchOk or not source or source == "" then
            presetStatus.Text = "Preset Status: Config file missing — UI applied for " .. presetName
            presetStatus.TextColor3 = Color3.fromRGB(255, 150, 50)
            if DebugGUI then warn("[Pouncing] Preset config not found: " .. presetUrl .. " | " .. tostring(source)) end
            ApplyPresetVisibility(presetName)
            return
        end

        local loadOk, loadErr = pcall(function()
            local presetFunc = loadstring(source)
            if not presetFunc then
                error("Failed to compile preset script")
            end
            local presetEnv = setmetatable({}, {__index = getfenv()})
            setfenv(presetFunc, presetEnv)
            local presetResult = presetFunc()
            if type(presetResult) == "table" then
                for k, v in pairs(presetResult) do
                    local mod = moduleManager:GetModule("Aimbot")
                    if mod and mod.SetConfig then
                        mod.SetConfig(k, v)
                    end
                end
            end
        end)

        if not loadOk then
            presetStatus.Text = "Preset Status: Error loading " .. presetName .. " config"
            presetStatus.TextColor3 = Color3.fromRGB(255, 50, 50)
            warn("[Pouncing] Preset load error: " .. tostring(loadErr))
        else
            presetStatus.Text = "Preset Status: " .. presetName .. " loaded successfully"
            presetStatus.TextColor3 = Color3.fromRGB(50, 255, 100)
        end

        ApplyPresetVisibility(presetName)
    end)

    local sepPreset = GUI.CreateSeparator(SCon)
    TagControl(sepPreset, {"all"})

    local themeSection = GUI.CreateSection(SCon, "Theme")
    TagControl(themeSection, {"all"})

    local themeDropdown = GUI.CreateDropdown(SCon, "Theme", {"Neon Pink", "Neon Red", "Neon Blue", "Neon Green", "Neon Purple", "Neon Orange", "Neon White", "Dark"}, "Neon Pink", function(v)
        local themeMap = {
            ["Neon Pink"] = {Primary = Color3.fromRGB(255, 105, 180), Secondary = Color3.fromRGB(255, 20, 147), Accent = Color3.fromRGB(255, 182, 193)},
            ["Neon Red"] = {Primary = Color3.fromRGB(255, 50, 50), Secondary = Color3.fromRGB(200, 0, 0), Accent = Color3.fromRGB(255, 100, 100)},
            ["Neon Blue"] = {Primary = Color3.fromRGB(50, 150, 255), Secondary = Color3.fromRGB(0, 100, 200), Accent = Color3.fromRGB(100, 180, 255)},
            ["Neon Green"] = {Primary = Color3.fromRGB(50, 255, 100), Secondary = Color3.fromRGB(0, 200, 50), Accent = Color3.fromRGB(100, 255, 150)},
            ["Neon Purple"] = {Primary = Color3.fromRGB(180, 50, 255), Secondary = Color3.fromRGB(130, 0, 200), Accent = Color3.fromRGB(200, 100, 255)},
            ["Neon Orange"] = {Primary = Color3.fromRGB(255, 150, 50), Secondary = Color3.fromRGB(200, 100, 0), Accent = Color3.fromRGB(255, 180, 100)},
            ["Neon White"] = {Primary = Color3.fromRGB(255, 255, 255), Secondary = Color3.fromRGB(200, 200, 200), Accent = Color3.fromRGB(240, 240, 240)},
            ["Dark"] = {Primary = Color3.fromRGB(100, 100, 100), Secondary = Color3.fromRGB(70, 70, 70), Accent = Color3.fromRGB(130, 130, 130)},
        }
        local t = themeMap[v]
        if t then
            GUI.SetTheme(t.Primary, t.Secondary, t.Accent)
        end
    end)
    TagControl(themeDropdown, {"all"})

    local sepTheme = GUI.CreateSeparator(SCon)
    TagControl(sepTheme, {"all"})

    local uiSection = GUI.CreateSection(SCon, "UI Settings")
    TagControl(uiSection, {"all"})

    local uiToggleKeyBind = GUI.CreateKeybind(SCon, "UI Toggle Key", uiToggleKey, function(k)
        uiToggleKey = k
    end)
    TagControl(uiToggleKeyBind, {"all"})

    local debugToggle = GUI.CreateToggle(SCon, "Debug Output", false, nil, function(v)
        DebugGUI = v
    end)
    TagControl(debugToggle, {"all"})

    local unloadBtn = GUI.CreateButton(SCon, "Unload Script", function()
        moduleManager:UnloadAll()
        screenGui:Destroy()
    end)
    TagControl(unloadBtn, {"all"})

    -- ============================================================
    -- INITIAL PRESET APPLICATION
    -- ============================================================
    task.delay(0.1, function()
        if window and window.Tabs and window.Contents then
            ApplyPresetVisibility(gameName)
        else
            if DebugGUI then warn("[Pouncing] Delayed preset apply skipped — window not ready") end
        end
    end)

    -- ============================================================
    -- UI TOGGLE KEY
    -- ============================================================
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == uiToggleKey then
            screenGui.Enabled = not screenGui.Enabled
        end
    end)

    return window
end

return MainGUI