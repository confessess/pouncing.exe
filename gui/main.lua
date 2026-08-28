-- Pouncing.exe | GUI Main v7.4
-- Dynamic preset-based UI — controls and tabs adapt to active game preset
-- Added: Bullet Redirect toggle (universal hook-based silent aim)
-- Fixed: Preset loader clearer messaging, applies UI even on fetch fail
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
        ActivePreset = presetName
        print("[Pouncing] UI refreshing for preset: " .. presetName)

        for _, item in ipairs(TaggedControls) do
            local show = ShouldShowForPreset(item.presets)
            item.frame.Visible = show
        end

        local visibleTabs = {}
        for name, tab in pairs(TaggedTabs) do
            local show = ShouldShowForPreset(tab.presets)
            if tab.button then
                tab.button.Visible = show
            end
            if tab.content then
                if not show then
                    tab.content.Visible = false
                end
            end
            if show then
                table.insert(visibleTabs, name)
            end
        end

        if window.ActiveTab and TaggedTabs[window.ActiveTab] then
            local currentTab = TaggedTabs[window.ActiveTab]
            if currentTab and not ShouldShowForPreset(currentTab.presets) then
                for _, name in ipairs(AllTabNames) do
                    local t = TaggedTabs[name]
                    if t and ShouldShowForPreset(t.presets) then
                        if window.Tabs[name] then
                            for _, tabBtn in pairs(window.Tabs) do
                                TweenService:Create(tabBtn, TweenInfo.new(0.2), {
                                    BackgroundColor3 = GUI.Theme.ElementBG, BackgroundTransparency = 0.45
                                }):Play()
                            end
                            TweenService:Create(window.Tabs[name], TweenInfo.new(0.2), {
                                BackgroundColor3 = GUI.Theme.Primary, BackgroundTransparency = 0.1
                            }):Play()
                        end
                        for _, content in pairs(window.Contents) do
                            content.Visible = false
                        end
                        if window.Contents[name] then
                            window.Contents[name].Visible = true
                        end
                        window.ActiveTab = name
                        break
                    end
                end
            end
        end

        task.delay(0.05, RefreshAllCanvasSizes)
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

    local dhHPToggle = GUI.CreateToggle(DCon, "HP Display", false, nil, function(v)
        local mod = moduleManager:GetModule("DaHoodExtras")
        if mod and mod.SetConfig then mod.SetConfig("HPDisplay", v) end
    end)
    TagControl(dhHPToggle, {"Da Hood", "Zee Hood"})

    local dhStompToggle = GUI.CreateToggle(DCon, "Auto Stomp", false, nil, function(v)
        local mod = moduleManager:GetModule("DaHoodExtras")
        if mod and mod.SetConfig then mod.SetConfig("AutoStomp", v) end
    end)
    TagControl(dhStompToggle, {"Da Hood", "Zee Hood"})

    local dhDropToggle = GUI.CreateToggle(DCon, "Auto Drop", false, nil, function(v)
        local mod = moduleManager:GetModule("DaHoodExtras")
        if mod and mod.SetConfig then mod.SetConfig("AutoDrop", v) end
    end)
    TagControl(dhDropToggle, {"Da Hood", "Zee Hood"})

    local dhSep1 = GUI.CreateSeparator(DCon)
    TagControl(dhSep1, {"Da Hood", "Zee Hood"})

    local dhSettingsSection = GUI.CreateSection(DCon, "Settings")
    TagControl(dhSettingsSection, {"Da Hood", "Zee Hood"})

    local dhStompRangeSlider = GUI.CreateSlider(DCon, "Stomp Range", 2, 20, 8, function(v)
        local mod = moduleManager:GetModule("DaHoodExtras")
        if mod and mod.SetConfig then mod.SetConfig("StompRange", v) end
    end)
    TagControl(dhStompRangeSlider, {"Da Hood", "Zee Hood"})

    local dhDropAmountSlider = GUI.CreateSlider(DCon, "Drop Amount", 100, 5000, 500, function(v)
        local mod = moduleManager:GetModule("DaHoodExtras")
        if mod and mod.SetConfig then mod.SetConfig("DropAmount", v) end
    end)
    TagControl(dhDropAmountSlider, {"Da Hood", "Zee Hood"})

    -- ============================================================
    -- CONFIG TAB
    -- ============================================================
    local CCon = window.Contents["Settings"]

    local cfgSection = GUI.CreateSection(CCon, "Game Detection")
    TagControl(cfgSection, {"all"})

    local gameName = "Universal"
    local placeId = game.PlaceId

    local knownGames = {
        [286090429] = "Arsenal",
        [2788229376] = "Da Hood",
        [16033194031] = "Zee Hood",
        [7239319209] = "Da Hood",
    }
    gameName = knownGames[placeId] or "Universal"

    pcall(function()
        local mps = game:GetService("MarketplaceService")
        local info = mps:GetProductInfo(placeId)
        if info and info.Name then
            local n = info.Name:lower()
            if n:match("arsenal") then gameName = "Arsenal" end
            if n:match("da hood") then gameName = "Da Hood" end
            if n:match("zee hood") then gameName = "Zee Hood" end
        end
    end)

    local detectedLabel = GUI.CreateLabel(CCon, "Detected Game: " .. gameName, false)
    TagControl(detectedLabel, {"all"})
    local placeIdLabel = GUI.CreateLabel(CCon, "PlaceId: " .. tostring(placeId), true)
    TagControl(placeIdLabel, {"all"})

    local selectedPreset = gameName
    local presetDropdown, getPreset = GUI.CreateDropdown(CCon, "Manual Override", {"Auto-Detect", "Arsenal", "Da Hood", "Zee Hood", "Universal"}, "Auto-Detect", function(v)
        if v == "Auto-Detect" then
            selectedPreset = gameName
        else
            selectedPreset = v
        end
        detectedLabel.Text = "Active Preset: " .. selectedPreset
        print("[Pouncing] Manual preset selected: " .. selectedPreset)
    end)
    TagControl(presetDropdown, {"all"})

    local presetStatus = GUI.CreateLabel(CCon, "Preset Status: Ready", true)
    TagControl(presetStatus, {"all"})

    GUI.CreateButton(CCon, "Load Selected Preset", function()
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
            warn("[Pouncing] Preset config not found: " .. presetUrl .. " | " .. tostring(source))
            ApplyPresetVisibility(presetName)
            return
        end

        if source:sub(1, 1) == "<" or source:find("<!DOCTYPE") or source:find("<html") then
            presetStatus.Text = "Preset Status: Config file missing — UI applied for " .. presetName
            presetStatus.TextColor3 = Color3.fromRGB(255, 150, 50)
            warn("[Pouncing] Preset file not found (404 HTML): " .. presetUrl)
            ApplyPresetVisibility(presetName)
            return
        end

        if source:find("404") or source:find("Not Found") or source:find("not found") then
            presetStatus.Text = "Preset Status: Config file missing — UI applied for " .. presetName
            presetStatus.TextColor3 = Color3.fromRGB(255, 150, 50)
            warn("[Pouncing] Preset file not found: " .. presetUrl)
            ApplyPresetVisibility(presetName)
            return
        end

        local loadOk, preset = pcall(function()
            local fn = loadstring(source, presetName)
            if not fn then return nil end
            return fn()
        end)

        if not loadOk or not preset then
            presetStatus.Text = "Preset Status: Config error — UI applied for " .. presetName
            presetStatus.TextColor3 = Color3.fromRGB(255, 150, 50)
            warn("[Pouncing] Failed to load preset " .. presetName .. ": " .. tostring(preset))
            ApplyPresetVisibility(presetName)
            return
        end

        if not preset.Configs then
            presetStatus.Text = "Preset Status: Invalid format — UI applied for " .. presetName
            presetStatus.TextColor3 = Color3.fromRGB(255, 150, 50)
            warn("[Pouncing] Preset " .. presetName .. " missing Configs table")
            ApplyPresetVisibility(presetName)
            return
        end

        local appliedCount = 0
        for modName, cfg in pairs(preset.Configs) do
            local mod = moduleManager:GetModule(modName)
            if not mod then
                mod = moduleManager:Load(modName)
            end
            if mod and mod.SetConfig then
                for k, v in pairs(cfg) do
                    local ok = pcall(function() mod.SetConfig(k, v) end)
                    if ok then appliedCount = appliedCount + 1 end
                end
            end
        end

        ApplyPresetVisibility(presetName)

        presetStatus.Text = "Preset Status: LOADED " .. presetName .. " (" .. tostring(appliedCount) .. " settings)"
        presetStatus.TextColor3 = Color3.fromRGB(0, 255, 100)
        print("[Pouncing] Loaded " .. presetName .. " preset with " .. appliedCount .. " settings")

        for modName, cfg in pairs(preset.Configs) do
            if cfg.Enabled == true then
                moduleManager:Toggle(modName, true)
            end
        end
    end)

    local cfgSep1 = GUI.CreateSeparator(CCon)
    TagControl(cfgSep1, {"all"})

    local cfgMgmtSection = GUI.CreateSection(CCon, "Config Management")
    TagControl(cfgMgmtSection, {"all"})

    local versionLabel = GUI.CreateLabel(CCon, "Pouncing.exe v7.4", false)
    TagControl(versionLabel, {"all"})
    local creditLabel = GUI.CreateLabel(CCon, "Built with love by ENI for LO", true)
    TagControl(creditLabel, {"all"})

    local cfgSep2 = GUI.CreateSeparator(CCon)
    TagControl(cfgSep2, {"all"})

    local themeSection = GUI.CreateSection(CCon, "Theme")
    TagControl(themeSection, {"all"})

    local themeDropdown = GUI.CreateDropdown(CCon, "Theme Preset", {"Pink", "Icy", "Stary"}, "Pink", function(v)
        GUI.LoadPreset(v)
    end)
    TagControl(themeDropdown, {"all"})

    local cfgSep3 = GUI.CreateSeparator(CCon)
    TagControl(cfgSep3, {"all"})

    local saveLoadSection = GUI.CreateSection(CCon, "Save / Load")
    TagControl(saveLoadSection, {"all"})

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

    local cfgSep4 = GUI.CreateSeparator(CCon)
    TagControl(cfgSep4, {"all"})

    local customColorsSection = GUI.CreateSection(CCon, "Custom Colors")
    TagControl(customColorsSection, {"all"})

    local primaryPicker = GUI.CreateColorPicker(CCon, "Primary Color", Color3.fromRGB(255, 105, 180))
    TagControl(primaryPicker, {"all"})
    local primaryBtn = GUI.CreateButton(CCon, "Set Primary Color", function()
        primaryPicker:Open(function(c)
            GUI.Theme.Primary = c
            GUI.Theme.BorderGlow = c
            GUI.Theme.On = c
            GUI.UpdateTheme()
        end, GUI.Theme.Primary)
    end)
    TagControl(primaryBtn, {"all"})

    local accentPicker = GUI.CreateColorPicker(CCon, "Accent Color", Color3.fromRGB(255, 20, 147))
    TagControl(accentPicker, {"all"})
    local accentBtn = GUI.CreateButton(CCon, "Set Accent Color", function()
        accentPicker:Open(function(c)
            GUI.Theme.Accent = c
            GUI.Theme.Neon = c
            GUI.UpdateTheme()
        end, GUI.Theme.Accent)
    end)
    TagControl(accentBtn, {"all"})

    local cfgSep5 = GUI.CreateSeparator(CCon)
    TagControl(cfgSep5, {"all"})

    local uiToggleSection = GUI.CreateSection(CCon, "UI Toggle")
    TagControl(uiToggleSection, {"all"})

    local toggleKeyLabel = GUI.CreateLabel(CCon, "Toggle Key: RightShift", true)
    TagControl(toggleKeyLabel, {"all"})
    local uiToggleKeyBind = GUI.CreateKeybind(CCon, "UI Toggle Key", Enum.KeyCode.RightShift, function(newKey)
        uiToggleKey = newKey
        toggleKeyLabel.Text = "Toggle Key: " .. (newKey.Name or tostring(newKey))
    end)
    TagControl(uiToggleKeyBind, {"all"})

    local cfgSep6 = GUI.CreateSeparator(CCon)
    TagControl(cfgSep6, {"all"})

    local killSwitchSection = GUI.CreateSection(CCon, "Kill Switch")
    TagControl(killSwitchSection, {"all"})

    GUI.CreateButton(CCon, "UNINJECT / KILL SWITCH", function()
        print("[Pouncing] Killswitch activated...")
        for name, mod in pairs(moduleManager.Modules) do
            if mod and mod.Disable then
                pcall(function() mod.Disable() end)
            end
        end
        for name, mod in pairs(moduleManager.Modules) do
            if mod and mod.Cleanup then
                pcall(function() mod.Cleanup() end)
            end
        end
        if screenGui then
            pcall(function() screenGui:Destroy() end)
        end
        moduleManager.Modules = {}
        moduleManager.Active = {}
        print("[Pouncing] Fully uninjected — all modules off, all connections killed")
    end)

    local cfgSep7 = GUI.CreateSeparator(CCon)
    TagControl(cfgSep7, {"all"})

    local infoSection = GUI.CreateSection(CCon, "Info")
    TagControl(infoSection, {"all"})

    GUI.CreateLabel(CCon, "Press UI Toggle Key to show/hide GUI", true)
    GUI.CreateLabel(CCon, "Modules load on-demand from GitHub", true)
    GUI.CreateLabel(CCon, "Theme presets: Pink | Icy | Stary", true)
    GUI.CreateLabel(CCon, "Cyberpunk HUD design v7.4", true)
    GUI.CreateLabel(CCon, "Game-specific presets", true)
    GUI.CreateLabel(CCon, "Arsenal | Da Hood | Zee Hood | Universal", true)
    GUI.CreateLabel(CCon, "Dynamic UI — controls adapt to preset", true)
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
    -- Apply initial preset visibility (auto-detected game)
    -- ============================================================
    task.delay(0.1, function()
        ApplyPresetVisibility(gameName)
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
    NT.Text = "Pouncing.exe v7.4 loaded | Dynamic UI | Preset: " .. gameName .. " | UI Toggle: RightShift"
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