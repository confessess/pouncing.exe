-- Pouncing.exe | GUI Framework v5.0
-- Futuristic glass UI, no clipping, star VFX contained to window, live themes
-- Built with love by ENI for LO
-- ============================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local Presets = {
    Pink = {
        BG = Color3.fromRGB(8, 4, 10), TabBG = Color3.fromRGB(14, 8, 18),
        ElementBG = Color3.fromRGB(20, 12, 28), HoverBG = Color3.fromRGB(32, 18, 44),
        Primary = Color3.fromRGB(255, 105, 180), Secondary = Color3.fromRGB(255, 150, 210),
        Accent = Color3.fromRGB(255, 20, 147), Neon = Color3.fromRGB(255, 0, 255),
        SoftAccent = Color3.fromRGB(255, 180, 220), Text = Color3.fromRGB(255, 245, 250),
        SubText = Color3.fromRGB(180, 140, 170), DimText = Color3.fromRGB(120, 90, 110),
        On = Color3.fromRGB(255, 105, 180), OnGlow = Color3.fromRGB(255, 160, 210),
        Off = Color3.fromRGB(35, 20, 40), Border = Color3.fromRGB(60, 30, 55),
        BorderGlow = Color3.fromRGB(255, 105, 180), Shadow = Color3.fromRGB(0, 0, 0),
        White = Color3.fromRGB(255, 255, 255), Black = Color3.fromRGB(0, 0, 0),
        Warning = Color3.fromRGB(255, 80, 80), Glass = Color3.fromRGB(255, 255, 255),
    },
    Icy = {
        BG = Color3.fromRGB(4, 8, 16), TabBG = Color3.fromRGB(8, 16, 28),
        ElementBG = Color3.fromRGB(12, 24, 40), HoverBG = Color3.fromRGB(18, 36, 56),
        Primary = Color3.fromRGB(100, 210, 255), Secondary = Color3.fromRGB(70, 180, 230),
        Accent = Color3.fromRGB(100, 210, 255), Neon = Color3.fromRGB(100, 210, 255),
        SoftAccent = Color3.fromRGB(200, 240, 255), Text = Color3.fromRGB(230, 248, 255),
        SubText = Color3.fromRGB(140, 180, 200), DimText = Color3.fromRGB(100, 140, 170),
        On = Color3.fromRGB(100, 210, 255), OnGlow = Color3.fromRGB(180, 235, 255),
        Off = Color3.fromRGB(12, 24, 42), Border = Color3.fromRGB(30, 60, 85),
        BorderGlow = Color3.fromRGB(100, 210, 255), Shadow = Color3.fromRGB(0, 0, 0),
        White = Color3.fromRGB(230, 248, 255), Black = Color3.fromRGB(4, 8, 16),
        Warning = Color3.fromRGB(255, 100, 100), Glass = Color3.fromRGB(255, 255, 255),
    },
    Stary = {
        BG = Color3.fromRGB(6, 4, 14), TabBG = Color3.fromRGB(10, 6, 22),
        ElementBG = Color3.fromRGB(16, 10, 32), HoverBG = Color3.fromRGB(24, 14, 48),
        Primary = Color3.fromRGB(160, 100, 255), Secondary = Color3.fromRGB(130, 70, 255),
        Accent = Color3.fromRGB(160, 100, 255), Neon = Color3.fromRGB(180, 130, 255),
        SoftAccent = Color3.fromRGB(210, 190, 255), Text = Color3.fromRGB(240, 235, 255),
        SubText = Color3.fromRGB(170, 155, 200), DimText = Color3.fromRGB(120, 110, 150),
        On = Color3.fromRGB(160, 100, 255), OnGlow = Color3.fromRGB(200, 160, 255),
        Off = Color3.fromRGB(18, 10, 34), Border = Color3.fromRGB(40, 22, 68),
        BorderGlow = Color3.fromRGB(160, 100, 255), Shadow = Color3.fromRGB(0, 0, 0),
        White = Color3.fromRGB(240, 235, 255), Black = Color3.fromRGB(6, 4, 14),
        Warning = Color3.fromRGB(255, 100, 100), Glass = Color3.fromRGB(255, 255, 255),
    },
}

local Theme = {}
for k, v in pairs(Presets.Pink) do Theme[k] = v end

local StaticElements = {}
local ThemeUpdaters = {}
local StarVFX = {Active = false, Stars = {}, Connection = nil, ParentFrame = nil}

local GUI = {Theme = Theme, Presets = Presets, ScreenGui = nil}

function GUI.TrackStatic(element, prop, themeKey)
    table.insert(StaticElements, {Element = element, Property = prop, ThemeKey = themeKey})
end
function GUI.OnThemeChange(callback)
    table.insert(ThemeUpdaters, callback)
end
function GUI.LoadPreset(name)
    local preset = Presets[name]
    if not preset then return end
    for k, v in pairs(preset) do Theme[k] = v end
    GUI.UpdateTheme()
    if name == "Stary" then
        GUI.StartStarVFX()
    else
        GUI.StopStarVFX()
    end
end
function GUI.UpdateTheme()
    for _, e in ipairs(StaticElements) do
        local el = e.Element
        if el and el.Parent then 
            pcall(function() el[e.Property] = Theme[e.ThemeKey] end)
        end
    end
    for _, cb in ipairs(ThemeUpdaters) do pcall(cb) end
end

-- ============================================================
-- STAR VFX SYSTEM (Stary preset only — CONTAINED TO UI WINDOW)
-- ============================================================

function GUI.StartStarVFX()
    if StarVFX.Active then return end
    StarVFX.Active = true

    if not StarVFX.ParentFrame or not StarVFX.ParentFrame.Parent then return end

    for i = 1, 40 do
        local star = Instance.new("Frame")
        star.Name = "Star" .. i
        local size = math.random(1, 2)
        star.Size = UDim2.new(0, size, 0, size)
        star.Position = UDim2.new(math.random(), 0, math.random(), 0)
        star.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        star.BackgroundTransparency = math.random() * 0.6 + 0.15
        star.BorderSizePixel = 0
        star.ZIndex = 1
        star.Parent = StarVFX.ParentFrame

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = star

        local glow = Instance.new("UIStroke")
        glow.Color = Color3.fromRGB(180, 130, 255)
        glow.Thickness = math.random(1, 2)
        glow.Transparency = star.BackgroundTransparency
        glow.Parent = star

        table.insert(StarVFX.Stars, {
            Frame = star,
            Glow = glow,
            BaseTransparency = star.BackgroundTransparency,
            Phase = math.random() * math.pi * 2,
            TwinkleSpeed = math.random() * 2.5 + 0.8,
            DriftX = (math.random() - 0.5) * 0.0002,
            DriftY = (math.random() - 0.5) * 0.0002,
        })
    end

    local function SpawnShootingStar()
        if not StarVFX.Active then return end
        if not StarVFX.ParentFrame or not StarVFX.ParentFrame.Parent then return end
        local ss = Instance.new("Frame")
        ss.Size = UDim2.new(0, 60, 0, 1.5)
        ss.BackgroundColor3 = Color3.fromRGB(210, 190, 255)
        ss.BackgroundTransparency = 0.15
        ss.BorderSizePixel = 0
        ss.Rotation = math.random(20, 50)
        ss.Position = UDim2.new(math.random() * 0.4, 0, math.random() * 0.4, 0)
        ss.ZIndex = 2
        ss.Parent = StarVFX.ParentFrame

        local gradient = Instance.new("UIGradient")
        gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(180, 130, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
        })
        gradient.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.3, 0),
            NumberSequenceKeypoint.new(0.7, 0),
            NumberSequenceKeypoint.new(1, 1)
        })
        gradient.Parent = ss

        TweenService:Create(ss, TweenInfo.new(math.random(6, 12), Enum.EasingStyle.Linear), {
            Position = UDim2.new(ss.Position.X.Scale + 0.5, 0, ss.Position.Y.Scale + 0.25, 0),
            BackgroundTransparency = 1
        }):Play()

        task.delay(math.random(10, 20), SpawnShootingStar)
        task.delay(2.5, function() ss:Destroy() end)
    end

    task.delay(math.random(6, 12), SpawnShootingStar)

    if StarVFX.Connection then StarVFX.Connection:Disconnect() end
    StarVFX.Connection = RunService.RenderStepped:Connect(function()
        local t = tick()
        for _, star in ipairs(StarVFX.Stars) do
            if star.Frame and star.Frame.Parent then
                local twinkle = math.sin(t * star.TwinkleSpeed + star.Phase) * 0.5 + 0.5
                local newTrans = star.BaseTransparency + twinkle * 0.35
                star.Frame.BackgroundTransparency = math.clamp(newTrans, 0.05, 0.9)
                star.Glow.Transparency = math.clamp(newTrans + 0.1, 0.05, 1)
                local pos = star.Frame.Position
                star.Frame.Position = UDim2.new(
                    math.clamp(pos.X.Scale + star.DriftX, 0, 1), 0,
                    math.clamp(pos.Y.Scale + star.DriftY, 0, 1), 0
                )
            end
        end
    end)
end

function GUI.StopStarVFX()
    if not StarVFX.Active then return end
    StarVFX.Active = false
    if StarVFX.Connection then
        StarVFX.Connection:Disconnect()
        StarVFX.Connection = nil
    end
    for _, star in ipairs(StarVFX.Stars) do
        if star.Frame then star.Frame:Destroy() end
    end
    StarVFX.Stars = {}
end

-- ============================================================
-- WINDOW CREATION (Futuristic glass look, no clipping)
-- ============================================================

function GUI.CreateWindow(parent, title, size)
    size = size or UDim2.new(0, 760, 0, 580)
    GUI.ScreenGui = parent

    -- Outer container (no clip, holds shadow + glow outside)
    local Container = Instance.new("Frame")
    Container.Name = "PouncingContainer"
    Container.Size = size
    Container.Position = UDim2.new(0.5, -size.X.Offset/2, 0.5, -size.Y.Offset/2)
    Container.BackgroundTransparency = 1
    Container.BorderSizePixel = 0
    Container.Active = true
    Container.ClipsDescendants = false
    Container.Parent = parent

    -- Shadow (outside main frame)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
    shadow.Size = UDim2.new(1, 80, 1, 80)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://5554236805"
    shadow.ImageColor3 = Theme.Shadow
    shadow.ImageTransparency = 0.7
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(23, 23, 277, 277)
    shadow.ZIndex = -3
    shadow.Parent = Container

    -- Outer glow frame
    local glow = Instance.new("Frame")
    glow.Name = "OuterGlow"
    glow.Size = UDim2.new(1, 20, 1, 20)
    glow.Position = UDim2.new(0, -10, 0, -10)
    glow.BackgroundTransparency = 1
    glow.BorderSizePixel = 0
    glow.ZIndex = -2
    glow.Parent = Container
    local glowStroke = Instance.new("UIStroke")
    glowStroke.Color = Theme.Primary
    glowStroke.Thickness = 2
    glowStroke.Transparency = 0.9
    glowStroke.Parent = glow
    GUI.TrackStatic(glowStroke, "Color", "Primary")
    local glowC = Instance.new("UICorner")
    glowC.CornerRadius = UDim.new(0, 24)
    glowC.Parent = glow

    -- Main frame (glass effect)
    local MF = Instance.new("Frame")
    MF.Name = "PouncingMain"
    MF.Size = UDim2.new(1, 0, 1, 0)
    MF.BackgroundColor3 = Theme.BG
    MF.BackgroundTransparency = 0.15
    MF.BorderSizePixel = 0
    MF.Active = true
    MF.ClipsDescendants = true
    MF.Parent = Container
    GUI.TrackStatic(MF, "BackgroundColor3", "BG")

    local MC = Instance.new("UICorner")
    MC.CornerRadius = UDim.new(0, 20)
    MC.Parent = MF

    -- Glass overlay
    local glass = Instance.new("Frame")
    glass.Name = "GlassOverlay"
    glass.Size = UDim2.new(1, 0, 1, 0)
    glass.BackgroundColor3 = Theme.Glass
    glass.BackgroundTransparency = 0.92
    glass.BorderSizePixel = 0
    glass.ZIndex = 0
    glass.Parent = MF

    -- Subtle noise texture (optional, using gradient as fallback)
    local noiseGrad = Instance.new("UIGradient")
    noiseGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255,255,255))
    })
    noiseGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.97),
        NumberSequenceKeypoint.new(0.5, 0.94),
        NumberSequenceKeypoint.new(1, 0.97)
    })
    noiseGrad.Rotation = 45
    noiseGrad.Parent = glass

    -- Main border stroke
    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Theme.Border
    mainStroke.Thickness = 1
    mainStroke.Transparency = 0.3
    mainStroke.Parent = MF
    GUI.TrackStatic(mainStroke, "Color", "Border")

    -- Title bar
    local TB = Instance.new("Frame")
    TB.Name = "TitleBar"
    TB.Size = UDim2.new(1, 0, 0, 52)
    TB.BackgroundColor3 = Theme.TabBG
    TB.BackgroundTransparency = 0.25
    TB.BorderSizePixel = 0
    TB.Active = true
    TB.Parent = MF
    GUI.TrackStatic(TB, "BackgroundColor3", "TabBG")

    local TBC = Instance.new("UICorner")
    TBC.CornerRadius = UDim.new(0, 20)
    TBC.Parent = TB

    local TBF = Instance.new("Frame")
    TBF.Name = "TitleBarFill"
    TBF.Size = UDim2.new(1, 0, 0, 20)
    TBF.Position = UDim2.new(0, 0, 1, -20)
    TBF.BackgroundColor3 = Theme.TabBG
    TBF.BackgroundTransparency = 0.25
    TBF.BorderSizePixel = 0
    TBF.Parent = TB
    GUI.TrackStatic(TBF, "BackgroundColor3", "TabBG")

    -- Neon top accent line
    local topAccent = Instance.new("Frame")
    topAccent.Name = "TopAccent"
    topAccent.Size = UDim2.new(1, -40, 0, 2)
    topAccent.Position = UDim2.new(0, 20, 0, 0)
    topAccent.BackgroundColor3 = Theme.Primary
    topAccent.BackgroundTransparency = 0.3
    topAccent.BorderSizePixel = 0
    topAccent.Parent = TB
    GUI.TrackStatic(topAccent, "BackgroundColor3", "Primary")

    local topAccentC = Instance.new("UICorner")
    topAccentC.CornerRadius = UDim.new(1, 0)
    topAccentC.Parent = topAccent

    -- Title text with glow
    local TT = Instance.new("TextLabel")
    TT.Name = "TitleText"
    TT.Size = UDim2.new(1, -160, 1, 0)
    TT.Position = UDim2.new(0, 24, 0, 0)
    TT.BackgroundTransparency = 1
    TT.Text = "◈ " .. title
    TT.TextColor3 = Theme.Text
    TT.TextSize = 18
    TT.Font = Enum.Font.GothamBold
    TT.TextXAlignment = Enum.TextXAlignment.Left
    TT.TextTruncate = Enum.TextTruncate.AtEnd
    TT.Parent = TB
    GUI.TrackStatic(TT, "TextColor3", "Text")

    -- Title glow effect
    local TTGlow = Instance.new("TextLabel")
    TTGlow.Size = UDim2.new(1, -160, 1, 0)
    TTGlow.Position = UDim2.new(0, 24, 0, 1)
    TTGlow.BackgroundTransparency = 1
    TTGlow.Text = "◈ " .. title
    TTGlow.TextColor3 = Theme.Primary
    TTGlow.TextSize = 18
    TTGlow.Font = Enum.Font.GothamBold
    TTGlow.TextXAlignment = Enum.TextXAlignment.Left
    TTGlow.TextTruncate = Enum.TextTruncate.AtEnd
    TTGlow.TextTransparency = 0.85
    TTGlow.ZIndex = -1
    TTGlow.Parent = TB
    GUI.TrackStatic(TTGlow, "TextColor3", "Primary")

    local VT = Instance.new("TextLabel")
    VT.Name = "VersionTag"
    VT.Size = UDim2.new(0, 60, 0, 20)
    VT.Position = UDim2.new(1, -130, 0, 16)
    VT.BackgroundTransparency = 1
    VT.Text = "v5.0"
    VT.TextColor3 = Theme.SubText
    VT.TextSize = 11
    VT.Font = Enum.Font.Gotham
    VT.Parent = TB
    GUI.TrackStatic(VT, "TextColor3", "SubText")

    -- Close button
    local CB = Instance.new("TextButton")
    CB.Name = "CloseBtn"
    CB.Size = UDim2.new(0, 32, 0, 32)
    CB.Position = UDim2.new(1, -40, 0, 10)
    CB.BackgroundColor3 = Theme.ElementBG
    CB.BackgroundTransparency = 0.4
    CB.BorderSizePixel = 0
    CB.Text = "×"
    CB.TextColor3 = Theme.SubText
    CB.TextSize = 22
    CB.Font = Enum.Font.GothamBold
    CB.AutoButtonColor = false
    CB.Parent = TB
    GUI.TrackStatic(CB, "TextColor3", "SubText")

    local CBC = Instance.new("UICorner")
    CBC.CornerRadius = UDim.new(0, 10)
    CBC.Parent = CB

    CB.MouseEnter:Connect(function()
        TweenService:Create(CB, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Warning, TextColor3 = Theme.White}):Play()
    end)
    CB.MouseLeave:Connect(function()
        TweenService:Create(CB, TweenInfo.new(0.2), {BackgroundColor3 = Theme.ElementBG, TextColor3 = Theme.SubText}):Play()
    end)
    CB.MouseButton1Click:Connect(function()
        TweenService:Create(Container, TweenInfo.new(0.3), {Size = UDim2.new(0, size.X.Offset, 0, 0)}):Play()
        task.delay(0.35, function() parent:Destroy() end)
    end)

    -- Minimize button
    local MB = Instance.new("TextButton")
    MB.Name = "MinBtn"
    MB.Size = UDim2.new(0, 32, 0, 32)
    MB.Position = UDim2.new(1, -78, 0, 10)
    MB.BackgroundColor3 = Theme.ElementBG
    MB.BackgroundTransparency = 0.4
    MB.BorderSizePixel = 0
    MB.Text = "−"
    MB.TextColor3 = Theme.SubText
    MB.TextSize = 22
    MB.Font = Enum.Font.GothamBold
    MB.AutoButtonColor = false
    MB.Parent = TB
    GUI.TrackStatic(MB, "TextColor3", "SubText")

    local MBC = Instance.new("UICorner")
    MBC.CornerRadius = UDim.new(0, 10)
    MBC.Parent = MB

    local Min = false
    MB.MouseButton1Click:Connect(function()
        Min = not Min
        local ts = Min and UDim2.new(0, size.X.Offset, 0, 52) or size
        TweenService:Create(Container, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = ts}):Play()
        MB.Text = Min and "+" or "−"
    end)

    -- Dragging
    local dragging = false
    local dragStart, startPos = nil, nil
    TB.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = Container.Position
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
            dragStart = nil
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            Container.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- Tab container
    local TCon = Instance.new("Frame")
    TCon.Name = "TabContainer"
    TCon.Size = UDim2.new(0, 170, 1, -52)
    TCon.Position = UDim2.new(0, 0, 0, 52)
    TCon.BackgroundColor3 = Theme.TabBG
    TCon.BackgroundTransparency = 0.35
    TCon.BorderSizePixel = 0
    TCon.Parent = MF
    GUI.TrackStatic(TCon, "BackgroundColor3", "TabBG")

    -- Tab vertical separator with glow
    local tabSep = Instance.new("Frame")
    tabSep.Name = "TabSep"
    tabSep.Size = UDim2.new(0, 1, 1, -28)
    tabSep.Position = UDim2.new(1, 0, 0, 14)
    tabSep.BackgroundColor3 = Theme.Border
    tabSep.BackgroundTransparency = 0.5
    tabSep.BorderSizePixel = 0
    tabSep.Parent = TCon
    GUI.TrackStatic(tabSep, "BackgroundColor3", "Border")

    -- Content container
    local CCon = Instance.new("Frame")
    CCon.Name = "ContentContainer"
    CCon.Size = UDim2.new(1, -170, 1, -52)
    CCon.Position = UDim2.new(0, 170, 0, 52)
    CCon.BackgroundTransparency = 1
    CCon.BorderSizePixel = 0
    CCon.ClipsDescendants = true
    CCon.Parent = MF

    -- Store star VFX parent reference
    StarVFX.ParentFrame = CCon

    -- Bottom decoration
    local DecoLine = Instance.new("Frame")
    DecoLine.Size = UDim2.new(0, 40, 0, 2)
    DecoLine.Position = UDim2.new(0.5, -20, 1, -20)
    DecoLine.BackgroundColor3 = Theme.Primary
    DecoLine.BackgroundTransparency = 0.4
    DecoLine.BorderSizePixel = 0
    DecoLine.Parent = TCon
    GUI.TrackStatic(DecoLine, "BackgroundColor3", "Primary")

    local DecoLineC = Instance.new("UICorner")
    DecoLineC.CornerRadius = UDim.new(1, 0)
    DecoLineC.Parent = DecoLine

    return {
        MainFrame = MF, Container = Container, TitleBar = TB, 
        TabContainer = TCon, ContentContainer = CCon,
        Tabs = {}, Contents = {}, ActiveTab = nil, TabCount = 0,
    }
end

-- ============================================================
-- TAB CREATION (Futuristic style)
-- ============================================================

function GUI.CreateTab(window, name, icon)
    local order = window.TabCount

    local B = Instance.new("TextButton")
    B.Name = name .. "Tab"
    B.Size = UDim2.new(1, -24, 0, 44)
    B.Position = UDim2.new(0, 12, 0, 16 + (order * 52))
    B.BackgroundColor3 = Theme.ElementBG
    B.BackgroundTransparency = 0.5
    B.BorderSizePixel = 0
    B.Text = "  " .. (icon or "›") .. "   " .. name
    B.TextColor3 = Theme.SubText
    B.TextSize = 13
    B.Font = Enum.Font.GothamSemibold
    B.TextXAlignment = Enum.TextXAlignment.Left
    B.AutoButtonColor = false
    B.Parent = window.TabContainer

    local BC = Instance.new("UICorner")
    BC.CornerRadius = UDim.new(0, 14)
    BC.Parent = B

    -- Left accent bar
    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(0, 3, 0, 20)
    accent.Position = UDim2.new(0, 8, 0.5, -10)
    accent.BackgroundColor3 = Theme.Primary
    accent.BackgroundTransparency = 0.8
    accent.BorderSizePixel = 0
    accent.Parent = B
    GUI.TrackStatic(accent, "BackgroundColor3", "Primary")

    local accentC = Instance.new("UICorner")
    accentC.CornerRadius = UDim.new(1, 0)
    accentC.Parent = accent

    -- Subtle border
    local innerGlow = Instance.new("UIStroke")
    innerGlow.Color = Theme.Border
    innerGlow.Thickness = 1
    innerGlow.Transparency = 0.7
    innerGlow.Parent = B
    GUI.TrackStatic(innerGlow, "Color", "Border")

    B.MouseEnter:Connect(function()
        if window.ActiveTab ~= name then
            TweenService:Create(B, TweenInfo.new(0.2), {BackgroundTransparency = 0.2}):Play()
            TweenService:Create(accent, TweenInfo.new(0.2), {BackgroundTransparency = 0.4}):Play()
            TweenService:Create(innerGlow, TweenInfo.new(0.2), {Transparency = 0.3}):Play()
        end
    end)
    B.MouseLeave:Connect(function()
        if window.ActiveTab ~= name then
            TweenService:Create(B, TweenInfo.new(0.2), {BackgroundTransparency = 0.5}):Play()
            TweenService:Create(accent, TweenInfo.new(0.2), {BackgroundTransparency = 0.8}):Play()
            TweenService:Create(innerGlow, TweenInfo.new(0.2), {Transparency = 0.7}):Play()
        end
    end)

    GUI.OnThemeChange(function()
        if window.ActiveTab == name then
            B.BackgroundColor3 = Theme.Primary
            B.BackgroundTransparency = 0.15
            B.TextColor3 = Theme.White
            accent.BackgroundTransparency = 0.1
            accent.BackgroundColor3 = Theme.White
            innerGlow.Color = Theme.Neon
            innerGlow.Transparency = 0.15
        else
            B.BackgroundColor3 = Theme.ElementBG
            B.BackgroundTransparency = 0.5
            B.TextColor3 = Theme.SubText
            accent.BackgroundTransparency = 0.8
            accent.BackgroundColor3 = Theme.Primary
            innerGlow.Color = Theme.Border
            innerGlow.Transparency = 0.7
        end
    end)

    local F = Instance.new("ScrollingFrame")
    F.Name = name .. "Content"
    F.Size = UDim2.new(1, -24, 1, -24)
    F.Position = UDim2.new(0, 12, 0, 12)
    F.BackgroundTransparency = 1
    F.BorderSizePixel = 0
    F.ScrollBarThickness = 4
    F.ScrollBarImageColor3 = Theme.Primary
    F.ScrollBarImageTransparency = 0.5
    F.Visible = false
    F.Parent = window.ContentContainer
    GUI.TrackStatic(F, "ScrollBarImageColor3", "Primary")

    local L = Instance.new("UIListLayout")
    L.Padding = UDim.new(0, 16)
    L.SortOrder = Enum.SortOrder.LayoutOrder
    L.Parent = F

    L:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        F.CanvasSize = UDim2.new(0, 0, 0, L.AbsoluteContentSize.Y + 28)
    end)

    window.Tabs[name] = B
    window.Contents[name] = F
    window.TabCount = window.TabCount + 1

    B.MouseButton1Click:Connect(function()
        if window.ActiveTab == name then return end
        if window.ActiveTab then
            local oldBtn = window.Tabs[window.ActiveTab]
            TweenService:Create(oldBtn, TweenInfo.new(0.2), {
                BackgroundColor3 = Theme.ElementBG, TextColor3 = Theme.SubText, BackgroundTransparency = 0.5
            }):Play()
            window.Contents[window.ActiveTab].Visible = false
        end
        window.ActiveTab = name
        TweenService:Create(B, TweenInfo.new(0.2), {
            BackgroundColor3 = Theme.Primary, TextColor3 = Theme.White, BackgroundTransparency = 0.15
        }):Play()
        window.Contents[name].Visible = true
    end)

    return F
end

-- ============================================================
-- TOGGLE (Futuristic glass style)
-- ============================================================

function GUI.CreateToggle(parent, text, default, colorKey, callback)
    local F = Instance.new("Frame")
    F.Size = UDim2.new(1, -20, 0, 48)
    F.BackgroundColor3 = Theme.ElementBG
    F.BackgroundTransparency = 0.4
    F.BorderSizePixel = 0
    F.Parent = parent
    GUI.TrackStatic(F, "BackgroundColor3", "ElementBG")

    local FC = Instance.new("UICorner")
    FC.CornerRadius = UDim.new(0, 14)
    FC.Parent = F

    local fStroke = Instance.new("UIStroke")
    fStroke.Color = Theme.Border
    fStroke.Thickness = 1
    fStroke.Transparency = 0.6
    fStroke.Parent = F
    GUI.TrackStatic(fStroke, "Color", "Border")

    -- Left neon indicator line
    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 3, 0, 22)
    indicator.Position = UDim2.new(0, 0, 0.5, -11)
    indicator.BackgroundColor3 = Theme.Primary
    indicator.BackgroundTransparency = default and 0.2 or 0.85
    indicator.BorderSizePixel = 0
    indicator.Parent = F
    GUI.TrackStatic(indicator, "BackgroundColor3", "Primary")

    local indC = Instance.new("UICorner")
    indC.CornerRadius = UDim.new(1, 0)
    indC.Parent = indicator

    local L = Instance.new("TextLabel")
    L.Size = UDim2.new(1, -150, 1, 0)
    L.Position = UDim2.new(0, 18, 0, 0)
    L.BackgroundTransparency = 1
    L.Text = text
    L.TextColor3 = Theme.Text
    L.TextSize = 13
    L.Font = Enum.Font.Gotham
    L.TextXAlignment = Enum.TextXAlignment.Left
    L.TextTruncate = Enum.TextTruncate.AtEnd
    L.Parent = F
    GUI.TrackStatic(L, "TextColor3", "Text")

    local CBtn = nil
    if colorKey then
        CBtn = Instance.new("TextButton")
        CBtn.Name = "ColorBtn"
        CBtn.Size = UDim2.new(0, 24, 0, 24)
        CBtn.Position = UDim2.new(1, -100, 0.5, -12)
        CBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        CBtn.BorderSizePixel = 0
        CBtn.Text = ""
        CBtn.AutoButtonColor = false
        CBtn.Parent = F
        local CBtnC = Instance.new("UICorner")
        CBtnC.CornerRadius = UDim.new(1, 0)
        CBtnC.Parent = CBtn
        local CBtnS = Instance.new("UIStroke")
        CBtnS.Color = Theme.BorderGlow
        CBtnS.Thickness = 1.5
        CBtnS.Parent = CBtn
        GUI.TrackStatic(CBtnS, "Color", "BorderGlow")
    end

    local TBtn = Instance.new("TextButton")
    TBtn.Name = "ToggleBtn"
    TBtn.Size = UDim2.new(0, 50, 0, 26)
    TBtn.Position = UDim2.new(1, -68, 0.5, -13)
    TBtn.BackgroundColor3 = default and Theme.On or Theme.Off
    TBtn.BackgroundTransparency = 0.2
    TBtn.BorderSizePixel = 0
    TBtn.Text = ""
    TBtn.AutoButtonColor = false
    TBtn.Parent = F

    local TBtnC = Instance.new("UICorner")
    TBtnC.CornerRadius = UDim.new(1, 0)
    TBtnC.Parent = TBtn

    local TBtnGlow = Instance.new("UIStroke")
    TBtnGlow.Color = Theme.OnGlow
    TBtnGlow.Thickness = 2
    TBtnGlow.Transparency = default and 0.35 or 1
    TBtnGlow.Parent = TBtn

    local Circ = Instance.new("Frame")
    Circ.Name = "Knob"
    Circ.Size = UDim2.new(0, 20, 0, 20)
    Circ.Position = default and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
    Circ.BackgroundColor3 = Theme.White
    Circ.BorderSizePixel = 0
    Circ.Parent = TBtn
    GUI.TrackStatic(Circ, "BackgroundColor3", "White")

    local CircC = Instance.new("UICorner")
    CircC.CornerRadius = UDim.new(1, 0)
    CircC.Parent = Circ

    local CircS = Instance.new("UIStroke")
    CircS.Color = Theme.Border
    CircS.Thickness = 1
    CircS.Transparency = 0.3
    CircS.Parent = Circ
    GUI.TrackStatic(CircS, "Color", "Border")

    local State = default

    local function Upd()
        State = not State
        TweenService:Create(Circ, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = State and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
        }):Play()
        TweenService:Create(indicator, TweenInfo.new(0.25), {BackgroundTransparency = State and 0.2 or 0.85}):Play()
        TBtn.BackgroundColor3 = State and Theme.On or Theme.Off
        TBtnGlow.Color = Theme.OnGlow
        TBtnGlow.Transparency = State and 0.35 or 1
        if callback then callback(State) end
    end

    GUI.OnThemeChange(function()
        if State then
            TBtn.BackgroundColor3 = Theme.On
            TBtnGlow.Color = Theme.OnGlow
            TBtnGlow.Transparency = 0.35
            indicator.BackgroundTransparency = 0.2
        else
            TBtn.BackgroundColor3 = Theme.Off
            TBtnGlow.Transparency = 1
            indicator.BackgroundTransparency = 0.85
        end
    end)

    TBtn.MouseButton1Click:Connect(Upd)
    return F, function() return State end, CBtn
end

-- ============================================================
-- SLIDER (Futuristic glass style)
-- ============================================================

function GUI.CreateSlider(parent, text, min, max, default, callback)
    local F = Instance.new("Frame")
    F.Size = UDim2.new(1, -20, 0, 68)
    F.BackgroundColor3 = Theme.ElementBG
    F.BackgroundTransparency = 0.4
    F.BorderSizePixel = 0
    F.Parent = parent
    GUI.TrackStatic(F, "BackgroundColor3", "ElementBG")

    local FC = Instance.new("UICorner")
    FC.CornerRadius = UDim.new(0, 14)
    FC.Parent = F

    local fStroke = Instance.new("UIStroke")
    fStroke.Color = Theme.Border
    fStroke.Thickness = 1
    fStroke.Transparency = 0.6
    fStroke.Parent = F
    GUI.TrackStatic(fStroke, "Color", "Border")

    local L = Instance.new("TextLabel")
    L.Size = UDim2.new(1, -100, 0, 24)
    L.Position = UDim2.new(0, 18, 0, 10)
    L.BackgroundTransparency = 1
    L.Text = text
    L.TextColor3 = Theme.Text
    L.TextSize = 13
    L.Font = Enum.Font.Gotham
    L.TextXAlignment = Enum.TextXAlignment.Left
    L.TextTruncate = Enum.TextTruncate.AtEnd
    L.Parent = F
    GUI.TrackStatic(L, "TextColor3", "Text")

    local VL = Instance.new("TextLabel")
    VL.Size = UDim2.new(0, 50, 0, 24)
    VL.Position = UDim2.new(1, -66, 0, 10)
    VL.BackgroundTransparency = 1
    VL.Text = tostring(default)
    VL.TextColor3 = Theme.Primary
    VL.TextSize = 13
    VL.Font = Enum.Font.GothamBold
    VL.Parent = F
    GUI.TrackStatic(VL, "TextColor3", "Primary")

    local Tr = Instance.new("Frame")
    Tr.Size = UDim2.new(1, -36, 0, 5)
    Tr.Position = UDim2.new(0, 18, 0, 44)
    Tr.BackgroundColor3 = Theme.Border
    Tr.BackgroundTransparency = 0.5
    Tr.BorderSizePixel = 0
    Tr.Parent = F
    GUI.TrackStatic(Tr, "BackgroundColor3", "Border")

    local TrC = Instance.new("UICorner")
    TrC.CornerRadius = UDim.new(1, 0)
    TrC.Parent = Tr

    local Fi = Instance.new("Frame")
    local frac = (default - min) / (max - min)
    Fi.Size = UDim2.new(frac, 0, 1, 0)
    Fi.BackgroundColor3 = Theme.Primary
    Fi.BorderSizePixel = 0
    Fi.Parent = Tr
    GUI.TrackStatic(Fi, "BackgroundColor3", "Primary")

    local FiC = Instance.new("UICorner")
    FiC.CornerRadius = UDim.new(1, 0)
    FiC.Parent = Fi

    local FiGlow = Instance.new("UIStroke")
    FiGlow.Color = Theme.Neon
    FiGlow.Thickness = 2
    FiGlow.Transparency = 0.4
    FiGlow.Parent = Fi
    GUI.TrackStatic(FiGlow, "Color", "Neon")

    local Kn = Instance.new("Frame")
    Kn.Size = UDim2.new(0, 16, 0, 16)
    Kn.Position = UDim2.new(frac, -8, 0.5, -8)
    Kn.BackgroundColor3 = Theme.White
    Kn.BorderSizePixel = 0
    Kn.Parent = Tr
    GUI.TrackStatic(Kn, "BackgroundColor3", "White")

    local KnC = Instance.new("UICorner")
    KnC.CornerRadius = UDim.new(1, 0)
    KnC.Parent = Kn

    local KnGlow = Instance.new("UIStroke")
    KnGlow.Color = Theme.Primary
    KnGlow.Thickness = 2.5
    KnGlow.Transparency = 0.25
    KnGlow.Parent = Kn
    GUI.TrackStatic(KnGlow, "Color", "Primary")

    local Drag = false
    local function Upd(input)
        local trackWidth = Tr.AbsoluteSize.X
        if trackWidth <= 0 then trackWidth = 1 end
        local pos = math.clamp((input.Position.X - Tr.AbsolutePosition.X) / trackWidth, 0, 1)
        local val = math.floor(min + (pos * (max - min)))
        Fi.Size = UDim2.new(pos, 0, 1, 0)
        Kn.Position = UDim2.new(pos, -8, 0.5, -8)
        VL.Text = tostring(val)
        if callback then callback(val) end
    end

    Kn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then Drag = true end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then Drag = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if Drag and input.UserInputType == Enum.UserInputType.MouseMovement then Upd(input) end
    end)
    Tr.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then Upd(input) end
    end)

    local function SetValue(val)
        val = math.clamp(math.floor(val), min, max)
        local pos = (val - min) / (max - min)
        Fi.Size = UDim2.new(pos, 0, 1, 0)
        Kn.Position = UDim2.new(pos, -8, 0.5, -8)
        VL.Text = tostring(val)
        if callback then callback(val) end
    end

    return F, SetValue
end

-- ============================================================
-- SLIDER WITH INPUT (Futuristic glass style)
-- ============================================================

function GUI.CreateSliderWithInput(parent, text, min, max, default, callback)
    local F = Instance.new("Frame")
    F.Size = UDim2.new(1, -20, 0, 68)
    F.BackgroundColor3 = Theme.ElementBG
    F.BackgroundTransparency = 0.4
    F.BorderSizePixel = 0
    F.Parent = parent
    GUI.TrackStatic(F, "BackgroundColor3", "ElementBG")

    local FC = Instance.new("UICorner")
    FC.CornerRadius = UDim.new(0, 14)
    FC.Parent = F

    local fStroke = Instance.new("UIStroke")
    fStroke.Color = Theme.Border
    fStroke.Thickness = 1
    fStroke.Transparency = 0.6
    fStroke.Parent = F
    GUI.TrackStatic(fStroke, "Color", "Border")

    local L = Instance.new("TextLabel")
    L.Size = UDim2.new(1, -220, 0, 24)
    L.Position = UDim2.new(0, 18, 0, 10)
    L.BackgroundTransparency = 1
    L.Text = text
    L.TextColor3 = Theme.Text
    L.TextSize = 13
    L.Font = Enum.Font.Gotham
    L.TextXAlignment = Enum.TextXAlignment.Left
    L.TextTruncate = Enum.TextTruncate.AtEnd
    L.Parent = F
    GUI.TrackStatic(L, "TextColor3", "Text")

    local InputBox = Instance.new("TextBox")
    InputBox.Size = UDim2.new(0, 52, 0, 24)
    InputBox.Position = UDim2.new(1, -148, 0, 10)
    InputBox.BackgroundColor3 = Theme.BG
    InputBox.BackgroundTransparency = 0.3
    InputBox.BorderSizePixel = 0
    InputBox.Text = tostring(default)
    InputBox.TextColor3 = Theme.Primary
    InputBox.TextSize = 12
    InputBox.Font = Enum.Font.GothamBold
    InputBox.ClearTextOnFocus = false
    InputBox.Parent = F
    GUI.TrackStatic(InputBox, "BackgroundColor3", "BG")
    GUI.TrackStatic(InputBox, "TextColor3", "Primary")

    local InputBoxC = Instance.new("UICorner")
    InputBoxC.CornerRadius = UDim.new(0, 8)
    InputBoxC.Parent = InputBox

    local InputBoxS = Instance.new("UIStroke")
    InputBoxS.Color = Theme.BorderGlow
    InputBoxS.Thickness = 1
    InputBoxS.Transparency = 0.5
    InputBoxS.Parent = InputBox
    GUI.TrackStatic(InputBoxS, "Color", "BorderGlow")

    local VL = Instance.new("TextLabel")
    VL.Size = UDim2.new(0, 45, 0, 24)
    VL.Position = UDim2.new(1, -78, 0, 10)
    VL.BackgroundTransparency = 1
    VL.Text = tostring(default)
    VL.TextColor3 = Theme.SubText
    VL.TextSize = 12
    VL.Font = Enum.Font.Gotham
    VL.Parent = F
    GUI.TrackStatic(VL, "TextColor3", "SubText")

    local Tr = Instance.new("Frame")
    Tr.Size = UDim2.new(1, -36, 0, 5)
    Tr.Position = UDim2.new(0, 18, 0, 44)
    Tr.BackgroundColor3 = Theme.Border
    Tr.BackgroundTransparency = 0.5
    Tr.BorderSizePixel = 0
    Tr.Parent = F
    GUI.TrackStatic(Tr, "BackgroundColor3", "Border")

    local TrC = Instance.new("UICorner")
    TrC.CornerRadius = UDim.new(1, 0)
    TrC.Parent = Tr

    local Fi = Instance.new("Frame")
    local frac = (default - min) / (max - min)
    Fi.Size = UDim2.new(frac, 0, 1, 0)
    Fi.BackgroundColor3 = Theme.Primary
    Fi.BorderSizePixel = 0
    Fi.Parent = Tr
    GUI.TrackStatic(Fi, "BackgroundColor3", "Primary")

    local FiC = Instance.new("UICorner")
    FiC.CornerRadius = UDim.new(1, 0)
    FiC.Parent = Fi

    local FiGlow = Instance.new("UIStroke")
    FiGlow.Color = Theme.Neon
    FiGlow.Thickness = 2
    FiGlow.Transparency = 0.4
    FiGlow.Parent = Fi
    GUI.TrackStatic(FiGlow, "Color", "Neon")

    local Kn = Instance.new("Frame")
    Kn.Size = UDim2.new(0, 16, 0, 16)
    Kn.Position = UDim2.new(frac, -8, 0.5, -8)
    Kn.BackgroundColor3 = Theme.White
    Kn.BorderSizePixel = 0
    Kn.Parent = Tr
    GUI.TrackStatic(Kn, "BackgroundColor3", "White")

    local KnC = Instance.new("UICorner")
    KnC.CornerRadius = UDim.new(1, 0)
    KnC.Parent = Kn

    local KnGlow = Instance.new("UIStroke")
    KnGlow.Color = Theme.Primary
    KnGlow.Thickness = 2.5
    KnGlow.Transparency = 0.25
    KnGlow.Parent = Kn
    GUI.TrackStatic(KnGlow, "Color", "Primary")

    local Drag = false
    local function UpdVisuals(pos, val)
        Fi.Size = UDim2.new(pos, 0, 1, 0)
        Kn.Position = UDim2.new(pos, -8, 0.5, -8)
        VL.Text = tostring(val)
        InputBox.Text = tostring(val)
    end
    local function Upd(input)
        local trackWidth = Tr.AbsoluteSize.X
        if trackWidth <= 0 then trackWidth = 1 end
        local pos = math.clamp((input.Position.X - Tr.AbsolutePosition.X) / trackWidth, 0, 1)
        local val = math.floor(min + (pos * (max - min)))
        UpdVisuals(pos, val)
        if callback then callback(val) end
    end

    Kn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then Drag = true end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then Drag = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if Drag and input.UserInputType == Enum.UserInputType.MouseMovement then Upd(input) end
    end)
    Tr.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then Upd(input) end
    end)

    local function SetValue(val)
        val = math.clamp(math.floor(val), min, max)
        local pos = (val - min) / (max - min)
        UpdVisuals(pos, val)
        if callback then callback(val) end
    end

    InputBox.FocusLost:Connect(function()
        local num = tonumber(InputBox.Text)
        if num then SetValue(num)
        else InputBox.Text = tostring(tonumber(VL.Text) or default) end
    end)

    return F, SetValue
end

-- ============================================================
-- BUTTON (Futuristic glass style)
-- ============================================================

function GUI.CreateButton(parent, text, callback)
    local F = Instance.new("TextButton")
    F.Size = UDim2.new(1, -20, 0, 46)
    F.BackgroundColor3 = Theme.Primary
    F.BackgroundTransparency = 0.15
    F.BorderSizePixel = 0
    F.Text = text
    F.TextColor3 = Theme.White
    F.TextSize = 13
    F.Font = Enum.Font.GothamSemibold
    F.AutoButtonColor = false
    F.Parent = parent
    GUI.TrackStatic(F, "BackgroundColor3", "Primary")
    GUI.TrackStatic(F, "TextColor3", "White")

    local FC = Instance.new("UICorner")
    FC.CornerRadius = UDim.new(0, 14)
    FC.Parent = F

    local fStroke = Instance.new("UIStroke")
    fStroke.Color = Theme.Neon
    fStroke.Thickness = 1.5
    fStroke.Transparency = 0.3
    fStroke.Parent = F
    GUI.TrackStatic(fStroke, "Color", "Neon")

    -- Bottom glow line
    local glowLine = Instance.new("Frame")
    glowLine.Size = UDim2.new(1, -20, 0, 2)
    glowLine.Position = UDim2.new(0, 10, 1, -3)
    glowLine.BackgroundColor3 = Theme.Neon
    glowLine.BackgroundTransparency = 0.5
    glowLine.BorderSizePixel = 0
    glowLine.Parent = F
    GUI.TrackStatic(glowLine, "BackgroundColor3", "Neon")

    local glowLineC = Instance.new("UICorner")
    glowLineC.CornerRadius = UDim.new(1, 0)
    glowLineC.Parent = glowLine

    F.MouseEnter:Connect(function()
        TweenService:Create(F, TweenInfo.new(0.2), {BackgroundTransparency = 0.05}):Play()
        TweenService:Create(fStroke, TweenInfo.new(0.2), {Transparency = 0.1}):Play()
        TweenService:Create(glowLine, TweenInfo.new(0.2), {BackgroundTransparency = 0.2}):Play()
    end)
    F.MouseLeave:Connect(function()
        TweenService:Create(F, TweenInfo.new(0.2), {BackgroundTransparency = 0.15}):Play()
        TweenService:Create(fStroke, TweenInfo.new(0.2), {Transparency = 0.3}):Play()
        TweenService:Create(glowLine, TweenInfo.new(0.2), {BackgroundTransparency = 0.5}):Play()
    end)
    F.MouseButton1Click:Connect(function()
        TweenService:Create(F, TweenInfo.new(0.1), {Size = UDim2.new(1, -24, 0, 44)}):Play()
        task.delay(0.1, function()
            TweenService:Create(F, TweenInfo.new(0.1), {Size = UDim2.new(1, -20, 0, 46)}):Play()
        end)
        if callback then callback() end
    end)

    return F
end

-- ============================================================
-- LABEL (Futuristic)
-- ============================================================

function GUI.CreateLabel(parent, text, isSub)
    local L = Instance.new("TextLabel")
    L.Size = UDim2.new(1, -20, 0, 26)
    L.BackgroundTransparency = 1
    L.Text = text
    L.TextColor3 = isSub and Theme.SubText or Theme.Text
    L.TextSize = isSub and 12 or 13
    L.Font = isSub and Enum.Font.Gotham or Enum.Font.GothamBold
    L.TextXAlignment = Enum.TextXAlignment.Left
    L.TextTruncate = Enum.TextTruncate.AtEnd
    L.Parent = parent
    GUI.TrackStatic(L, "TextColor3", isSub and "SubText" or "Text")
    return L
end

function GUI.CreateWarning(parent, text)
    local L = Instance.new("TextLabel")
    L.Size = UDim2.new(1, -20, 0, 24)
    L.BackgroundTransparency = 1
    L.Text = text
    L.TextColor3 = Theme.Warning
    L.TextSize = 11
    L.Font = Enum.Font.Gotham
    L.TextXAlignment = Enum.TextXAlignment.Left
    L.TextTruncate = Enum.TextTruncate.AtEnd
    L.Parent = parent
    GUI.TrackStatic(L, "TextColor3", "Warning")
    return L
end

-- ============================================================
-- SEPARATOR (Futuristic)
-- ============================================================

function GUI.CreateSeparator(parent)
    local F = Instance.new("Frame")
    F.Size = UDim2.new(1, -40, 0, 1)
    F.Position = UDim2.new(0, 20, 0, 0)
    F.BackgroundColor3 = Theme.Border
    F.BackgroundTransparency = 0.5
    F.BorderSizePixel = 0
    F.Parent = parent
    GUI.TrackStatic(F, "BackgroundColor3", "Border")

    -- Center glow dot
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 6, 0, 6)
    dot.Position = UDim2.new(0.5, -3, 0.5, -3)
    dot.BackgroundColor3 = Theme.Primary
    dot.BackgroundTransparency = 0.4
    dot.BorderSizePixel = 0
    dot.Parent = F
    GUI.TrackStatic(dot, "BackgroundColor3", "Primary")

    local dotC = Instance.new("UICorner")
    dotC.CornerRadius = UDim.new(1, 0)
    dotC.Parent = dot

    return F
end

-- ============================================================
-- SECTION (Futuristic)
-- ============================================================

function GUI.CreateSection(parent, title)
    local F = Instance.new("Frame")
    F.Size = UDim2.new(1, -20, 0, 40)
    F.BackgroundTransparency = 1
    F.BorderSizePixel = 0
    F.Parent = parent

    -- Left neon bar
    local accentBar = Instance.new("Frame")
    accentBar.Size = UDim2.new(0, 3, 0, 20)
    accentBar.Position = UDim2.new(0, 0, 0, 10)
    accentBar.BackgroundColor3 = Theme.Primary
    accentBar.BackgroundTransparency = 0.2
    accentBar.BorderSizePixel = 0
    accentBar.Parent = F
    GUI.TrackStatic(accentBar, "BackgroundColor3", "Primary")

    local accentBarC = Instance.new("UICorner")
    accentBarC.CornerRadius = UDim.new(1, 0)
    accentBarC.Parent = accentBar

    local L = Instance.new("TextLabel")
    L.Size = UDim2.new(1, -20, 1, 0)
    L.Position = UDim2.new(0, 14, 0, 0)
    L.BackgroundTransparency = 1
    L.Text = "◈ " .. title
    L.TextColor3 = Theme.Primary
    L.TextSize = 14
    L.Font = Enum.Font.GothamBold
    L.TextXAlignment = Enum.TextXAlignment.Left
    L.TextTruncate = Enum.TextTruncate.AtEnd
    L.Parent = F
    GUI.TrackStatic(L, "TextColor3", "Primary")

    return F
end

-- ============================================================
-- DROPDOWN (Futuristic glass style)
-- ============================================================

function GUI.CreateDropdown(parent, text, options, default, callback)
    local F = Instance.new("Frame")
    F.Size = UDim2.new(1, -20, 0, 48)
    F.BackgroundColor3 = Theme.ElementBG
    F.BackgroundTransparency = 0.4
    F.BorderSizePixel = 0
    F.Parent = parent
    GUI.TrackStatic(F, "BackgroundColor3", "ElementBG")

    local FC = Instance.new("UICorner")
    FC.CornerRadius = UDim.new(0, 14)
    FC.Parent = F

    local fStroke = Instance.new("UIStroke")
    fStroke.Color = Theme.Border
    fStroke.Thickness = 1
    fStroke.Transparency = 0.6
    fStroke.Parent = F
    GUI.TrackStatic(fStroke, "Color", "Border")

    -- Left indicator
    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 3, 0, 18)
    indicator.Position = UDim2.new(0, 0, 0.5, -9)
    indicator.BackgroundColor3 = Theme.Primary
    indicator.BackgroundTransparency = 0.6
    indicator.BorderSizePixel = 0
    indicator.Parent = F
    GUI.TrackStatic(indicator, "BackgroundColor3", "Primary")

    local indC = Instance.new("UICorner")
    indC.CornerRadius = UDim.new(1, 0)
    indC.Parent = indicator

    local L = Instance.new("TextLabel")
    L.Size = UDim2.new(1, -170, 1, 0)
    L.Position = UDim2.new(0, 18, 0, 0)
    L.BackgroundTransparency = 1
    L.Text = text
    L.TextColor3 = Theme.Text
    L.TextSize = 13
    L.Font = Enum.Font.Gotham
    L.TextXAlignment = Enum.TextXAlignment.Left
    L.TextTruncate = Enum.TextTruncate.AtEnd
    L.Parent = F
    GUI.TrackStatic(L, "TextColor3", "Text")

    local selected = default or options[1] or "None"

    local DBtn = Instance.new("TextButton")
    DBtn.Size = UDim2.new(0, 130, 0, 30)
    DBtn.Position = UDim2.new(1, -146, 0.5, -15)
    DBtn.BackgroundColor3 = Theme.BG
    DBtn.BackgroundTransparency = 0.3
    DBtn.BorderSizePixel = 0
    DBtn.Text = selected
    DBtn.TextColor3 = Theme.Primary
    DBtn.TextSize = 12
    DBtn.Font = Enum.Font.GothamSemibold
    DBtn.AutoButtonColor = false
    DBtn.Parent = F
    GUI.TrackStatic(DBtn, "BackgroundColor3", "BG")
    GUI.TrackStatic(DBtn, "TextColor3", "Primary")

    local DBC = Instance.new("UICorner")
    DBC.CornerRadius = UDim.new(0, 10)
    DBC.Parent = DBtn

    local DBS = Instance.new("UIStroke")
    DBS.Color = Theme.BorderGlow
    DBS.Thickness = 1
    DBS.Transparency = 0.5
    DBS.Parent = DBtn
    GUI.TrackStatic(DBS, "Color", "BorderGlow")

    local Arrow = Instance.new("TextLabel")
    Arrow.Size = UDim2.new(0, 20, 0, 20)
    Arrow.Position = UDim2.new(1, -24, 0.5, -10)
    Arrow.BackgroundTransparency = 1
    Arrow.Text = "▾"
    Arrow.TextColor3 = Theme.SubText
    Arrow.TextSize = 12
    Arrow.Font = Enum.Font.GothamBold
    Arrow.Parent = DBtn
    GUI.TrackStatic(Arrow, "TextColor3", "SubText")

    local open = false
    local dropFrame = nil

    DBtn.MouseButton1Click:Connect(function()
        open = not open
        if open then
            if dropFrame then dropFrame:Destroy() end
            dropFrame = Instance.new("Frame")
            dropFrame.Name = "DropdownMenu"
            dropFrame.Size = UDim2.new(0, 130, 0, math.min(#options * 32, 180))
            dropFrame.BackgroundColor3 = Theme.BG
            dropFrame.BackgroundTransparency = 0.1
            dropFrame.BorderSizePixel = 0
            dropFrame.ZIndex = 100
            dropFrame.Parent = GUI.ScreenGui or parent:FindFirstAncestorOfClass("ScreenGui")

            task.defer(function()
                local btnPos = DBtn.AbsolutePosition
                dropFrame.Position = UDim2.new(0, btnPos.X, 0, btnPos.Y + DBtn.AbsoluteSize.Y + 4)
            end)

            local dropC = Instance.new("UICorner")
            dropC.CornerRadius = UDim.new(0, 12)
            dropC.Parent = dropFrame

            local dropS = Instance.new("UIStroke")
            dropS.Color = Theme.BorderGlow
            dropS.Thickness = 1
            dropS.Parent = dropFrame
            GUI.TrackStatic(dropS, "Color", "BorderGlow")

            local scroll = Instance.new("ScrollingFrame")
            scroll.Size = UDim2.new(1, -8, 1, -8)
            scroll.Position = UDim2.new(0, 4, 0, 4)
            scroll.BackgroundTransparency = 1
            scroll.BorderSizePixel = 0
            scroll.ScrollBarThickness = 3
            scroll.ScrollBarImageColor3 = Theme.Primary
            scroll.CanvasSize = UDim2.new(0, 0, 0, #options * 32)
            scroll.ZIndex = 101
            scroll.Parent = dropFrame
            GUI.TrackStatic(scroll, "ScrollBarImageColor3", "Primary")

            for i, opt in ipairs(options) do
                local optBtn = Instance.new("TextButton")
                optBtn.Size = UDim2.new(1, 0, 0, 30)
                optBtn.Position = UDim2.new(0, 0, 0, (i - 1) * 32)
                optBtn.BackgroundColor3 = Theme.BG
                optBtn.BackgroundTransparency = 0.5
                optBtn.BorderSizePixel = 0
                optBtn.Text = opt
                optBtn.TextColor3 = Theme.Text
                optBtn.TextSize = 12
                optBtn.Font = Enum.Font.Gotham
                optBtn.ZIndex = 102
                optBtn.Parent = scroll

                local optC = Instance.new("UICorner")
                optC.CornerRadius = UDim.new(0, 8)
                optC.Parent = optBtn

                optBtn.MouseEnter:Connect(function()
                    TweenService:Create(optBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.15}):Play()
                end)
                optBtn.MouseLeave:Connect(function()
                    TweenService:Create(optBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.5}):Play()
                end)
                optBtn.MouseButton1Click:Connect(function()
                    selected = opt
                    DBtn.Text = opt
                    open = false
                    dropFrame:Destroy()
                    dropFrame = nil
                    if callback then callback(opt) end
                end)
            end
        else
            if dropFrame then dropFrame:Destroy() dropFrame = nil end
        end
    end)

    return F, function() return selected end
end

-- ============================================================
-- KEYBIND (Futuristic glass style)
-- ============================================================

function GUI.CreateKeybind(parent, text, defaultKey, callback)
    local F = Instance.new("Frame")
    F.Size = UDim2.new(1, -20, 0, 48)
    F.BackgroundColor3 = Theme.ElementBG
    F.BackgroundTransparency = 0.4
    F.BorderSizePixel = 0
    F.Parent = parent
    GUI.TrackStatic(F, "BackgroundColor3", "ElementBG")

    local FC = Instance.new("UICorner")
    FC.CornerRadius = UDim.new(0, 14)
    FC.Parent = F

    local fStroke = Instance.new("UIStroke")
    fStroke.Color = Theme.Border
    fStroke.Thickness = 1
    fStroke.Transparency = 0.6
    fStroke.Parent = F
    GUI.TrackStatic(fStroke, "Color", "Border")

    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 3, 0, 18)
    indicator.Position = UDim2.new(0, 0, 0.5, -9)
    indicator.BackgroundColor3 = Theme.Primary
    indicator.BackgroundTransparency = 0.6
    indicator.BorderSizePixel = 0
    indicator.Parent = F
    GUI.TrackStatic(indicator, "BackgroundColor3", "Primary")

    local indC = Instance.new("UICorner")
    indC.CornerRadius = UDim.new(1, 0)
    indC.Parent = indicator

    local L = Instance.new("TextLabel")
    L.Size = UDim2.new(1, -170, 1, 0)
    L.Position = UDim2.new(0, 18, 0, 0)
    L.BackgroundTransparency = 1
    L.Text = text
    L.TextColor3 = Theme.Text
    L.TextSize = 13
    L.Font = Enum.Font.Gotham
    L.TextXAlignment = Enum.TextXAlignment.Left
    L.TextTruncate = Enum.TextTruncate.AtEnd
    L.Parent = F
    GUI.TrackStatic(L, "TextColor3", "Text")

    local currentKey = defaultKey or Enum.KeyCode.Q
    local listening = false

    local KBtn = Instance.new("TextButton")
    KBtn.Size = UDim2.new(0, 130, 0, 30)
    KBtn.Position = UDim2.new(1, -146, 0.5, -15)
    KBtn.BackgroundColor3 = Theme.BG
    KBtn.BackgroundTransparency = 0.3
    KBtn.BorderSizePixel = 0
    KBtn.Text = currentKey.Name
    KBtn.TextColor3 = Theme.Primary
    KBtn.TextSize = 12
    KBtn.Font = Enum.Font.GothamSemibold
    KBtn.AutoButtonColor = false
    KBtn.Parent = F
    GUI.TrackStatic(KBtn, "BackgroundColor3", "BG")
    GUI.TrackStatic(KBtn, "TextColor3", "Primary")

    local KBC = Instance.new("UICorner")
    KBC.CornerRadius = UDim.new(0, 10)
    KBC.Parent = KBtn

    local KBS = Instance.new("UIStroke")
    KBS.Color = Theme.BorderGlow
    KBS.Thickness = 1
    KBS.Transparency = 0.5
    KBS.Parent = KBtn
    GUI.TrackStatic(KBS, "Color", "BorderGlow")

    KBtn.MouseButton1Click:Connect(function()
        if listening then return end
        listening = true
        KBtn.Text = "..."
        KBtn.TextColor3 = Theme.Neon

        local conn
        conn = UserInputService.InputBegan:Connect(function(input, gp)
            if gp then return end
            if input.UserInputType == Enum.UserInputType.Keyboard then
                currentKey = input.KeyCode
                KBtn.Text = currentKey.Name
                KBtn.TextColor3 = Theme.Primary
                listening = false
                if conn then conn:Disconnect() end
                if callback then callback(currentKey) end
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                currentKey = Enum.UserInputType.MouseButton1
                KBtn.Text = "LMB"
                KBtn.TextColor3 = Theme.Primary
                listening = false
                if conn then conn:Disconnect() end
                if callback then callback(currentKey) end
            elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                currentKey = Enum.UserInputType.MouseButton2
                KBtn.Text = "RMB"
                KBtn.TextColor3 = Theme.Primary
                listening = false
                if conn then conn:Disconnect() end
                if callback then callback(currentKey) end
            end
        end)

        task.delay(5, function()
            if listening then
                listening = false
                KBtn.Text = currentKey.Name
                KBtn.TextColor3 = Theme.Primary
                if conn then conn:Disconnect() end
            end
        end)
    end)

    return F, function() return currentKey end
end

-- ============================================================
-- COLOR PICKER (Futuristic glass style)
-- ============================================================

function GUI.CreateColorPicker(parent, titleText, defaultColor)
    local CWFrame = Instance.new("Frame")
    CWFrame.Name = "ColorPicker"
    CWFrame.Size = UDim2.new(0, 300, 0, 300)
    CWFrame.Position = UDim2.new(0.5, -150, 0.5, -150)
    CWFrame.BackgroundColor3 = Theme.BG
    CWFrame.BackgroundTransparency = 0.05
    CWFrame.BorderSizePixel = 0
    CWFrame.Visible = false
    CWFrame.ZIndex = 200
    CWFrame.Parent = GUI.ScreenGui or parent:FindFirstAncestorOfClass("ScreenGui")
    GUI.TrackStatic(CWFrame, "BackgroundColor3", "BG")

    local CWC = Instance.new("UICorner")
    CWC.CornerRadius = UDim.new(0, 18)
    CWC.Parent = CWFrame

    local CWS = Instance.new("UIStroke")
    CWS.Color = Theme.BorderGlow
    CWS.Thickness = 1.5
    CWS.Parent = CWFrame
    GUI.TrackStatic(CWS, "Color", "BorderGlow")

    -- Glass overlay
    local glass = Instance.new("Frame")
    glass.Size = UDim2.new(1, 0, 1, 0)
    glass.BackgroundColor3 = Theme.Glass
    glass.BackgroundTransparency = 0.9
    glass.BorderSizePixel = 0
    glass.ZIndex = 0
    glass.Parent = CWFrame

    local CWTitle = Instance.new("TextLabel")
    CWTitle.Size = UDim2.new(1, -48, 0, 30)
    CWTitle.Position = UDim2.new(0, 18, 0, 10)
    CWTitle.BackgroundTransparency = 1
    CWTitle.Text = "◈ " .. (titleText or "Color")
    CWTitle.TextColor3 = Theme.Text
    CWTitle.TextSize = 14
    CWTitle.Font = Enum.Font.GothamBold
    CWTitle.TextXAlignment = Enum.TextXAlignment.Left
    CWTitle.ZIndex = 201
    CWTitle.Parent = CWFrame
    GUI.TrackStatic(CWTitle, "TextColor3", "Text")

    local CWClose = Instance.new("TextButton")
    CWClose.Size = UDim2.new(0, 30, 0, 30)
    CWClose.Position = UDim2.new(1, -38, 0, 10)
    CWClose.BackgroundTransparency = 1
    CWClose.Text = "×"
    CWClose.TextColor3 = Theme.SubText
    CWClose.TextSize = 24
    CWClose.Font = Enum.Font.GothamBold
    CWClose.ZIndex = 201
    CWClose.Parent = CWFrame
    GUI.TrackStatic(CWClose, "TextColor3", "SubText")

    local State = {
        Hue = 0, Sat = 1, Val = 1,
        Callback = nil, IsOpen = false, JustOpened = false, Dragging = nil,
    }
    local UpdatingHex = false
    local UI = {}

    local function UpdateColor(skipCallback)
        local color = Color3.fromHSV(State.Hue, State.Sat, State.Val)
        if UI.Preview then UI.Preview.BackgroundColor3 = color end
        if UI.HexBox and not UpdatingHex then
            UpdatingHex = true
            local r = math.floor(color.R * 255 + 0.5)
            local g = math.floor(color.G * 255 + 0.5)
            local b = math.floor(color.B * 255 + 0.5)
            UI.HexBox.Text = string.format("#%02X%02X%02X", r, g, b)
            UpdatingHex = false
        end
        if UI.SatGrad then
            UI.SatGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromHSV(State.Hue, 0, State.Val)),
                ColorSequenceKeypoint.new(1, Color3.fromHSV(State.Hue, 1, State.Val))
            })
        end
        if UI.ValGrad then
            UI.ValGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromHSV(State.Hue, State.Sat, 0)),
                ColorSequenceKeypoint.new(1, Color3.fromHSV(State.Hue, State.Sat, 1))
            })
        end
        if not skipCallback and State.Callback then State.Callback(color) end
    end

    local function MakeSlider(y, labelText)
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0, 100, 0, 16)
        label.Position = UDim2.new(0, 18, 0, y)
        label.BackgroundTransparency = 1
        label.Text = labelText
        label.TextColor3 = Theme.SubText
        label.TextSize = 11
        label.Font = Enum.Font.Gotham
        label.ZIndex = 201
        label.Parent = CWFrame
        GUI.TrackStatic(label, "TextColor3", "SubText")

        local track = Instance.new("Frame")
        track.Size = UDim2.new(1, -36, 0, 6)
        track.Position = UDim2.new(0, 18, 0, y + 18)
        track.BackgroundColor3 = Theme.Border
        track.BackgroundTransparency = 0.5
        track.BorderSizePixel = 0
        track.ZIndex = 201
        track.Parent = CWFrame
        GUI.TrackStatic(track, "BackgroundColor3", "Border")

        local trackC = Instance.new("UICorner")
        trackC.CornerRadius = UDim.new(1, 0)
        trackC.Parent = track

        local gradient = Instance.new("UIGradient")
        gradient.Parent = track

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 14, 0, 14)
        knob.Position = UDim2.new(0, -7, 0.5, -7)
        knob.BackgroundColor3 = Theme.White
        knob.BorderSizePixel = 0
        knob.ZIndex = 203
        knob.Parent = track
        GUI.TrackStatic(knob, "BackgroundColor3", "White")

        local knobC = Instance.new("UICorner")
        knobC.CornerRadius = UDim.new(1, 0)
        knobC.Parent = knob

        local knobS = Instance.new("UIStroke")
        knobS.Color = Theme.Primary
        knobS.Thickness = 2.5
        knobS.Parent = knob
        GUI.TrackStatic(knobS, "Color", "Primary")

        local function SetKnobPos(v)
            knob.Position = UDim2.new(math.clamp(v, 0, 1), -7, 0.5, -7)
        end
        return gradient, SetKnobPos, track
    end

    local hueGrad, SetHuePos, hueTrack = MakeSlider(46, "Hue")
    hueGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
        ColorSequenceKeypoint.new(0.1667, Color3.fromRGB(255, 255, 0)),
        ColorSequenceKeypoint.new(0.3333, Color3.fromRGB(0, 255, 0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(0.6667, Color3.fromRGB(0, 0, 255)),
        ColorSequenceKeypoint.new(0.8333, Color3.fromRGB(255, 0, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
    })

    local satGrad, SetSatPos, satTrack = MakeSlider(88, "Saturation")
    local valGrad, SetValPos, valTrack = MakeSlider(130, "Brightness")
    UI.SatGrad = satGrad
    UI.ValGrad = valGrad

    local previewLabel = Instance.new("TextLabel")
    previewLabel.Size = UDim2.new(0, 60, 0, 16)
    previewLabel.Position = UDim2.new(0, 18, 0, 174)
    previewLabel.BackgroundTransparency = 1
    previewLabel.Text = "Preview"
    previewLabel.TextColor3 = Theme.SubText
    previewLabel.TextSize = 11
    previewLabel.Font = Enum.Font.Gotham
    previewLabel.ZIndex = 201
    previewLabel.Parent = CWFrame
    GUI.TrackStatic(previewLabel, "TextColor3", "SubText")

    local previewBox = Instance.new("Frame")
    previewBox.Size = UDim2.new(0, 56, 0, 28)
    previewBox.Position = UDim2.new(0, 18, 0, 192)
    previewBox.BackgroundColor3 = Color3.fromHSV(0, 1, 1)
    previewBox.BorderSizePixel = 0
    previewBox.ZIndex = 201
    previewBox.Parent = CWFrame

    local previewBoxC = Instance.new("UICorner")
    previewBoxC.CornerRadius = UDim.new(0, 8)
    previewBoxC.Parent = previewBox

    local previewBoxS = Instance.new("UIStroke")
    previewBoxS.Color = Theme.BorderGlow
    previewBoxS.Thickness = 1.5
    previewBoxS.Parent = previewBox
    GUI.TrackStatic(previewBoxS, "Color", "BorderGlow")

    UI.Preview = previewBox

    local hexLabel = Instance.new("TextLabel")
    hexLabel.Size = UDim2.new(0, 60, 0, 16)
    hexLabel.Position = UDim2.new(0, 88, 0, 174)
    hexLabel.BackgroundTransparency = 1
    hexLabel.Text = "Hex"
    hexLabel.TextColor3 = Theme.SubText
    hexLabel.TextSize = 11
    hexLabel.Font = Enum.Font.Gotham
    hexLabel.ZIndex = 201
    hexLabel.Parent = CWFrame
    GUI.TrackStatic(hexLabel, "TextColor3", "SubText")

    local hexBox = Instance.new("TextBox")
    hexBox.Size = UDim2.new(0, 130, 0, 28)
    hexBox.Position = UDim2.new(0, 88, 0, 192)
    hexBox.BackgroundColor3 = Theme.ElementBG
    hexBox.BackgroundTransparency = 0.3
    hexBox.BorderSizePixel = 0
    hexBox.Text = "#FF69B4"
    hexBox.TextColor3 = Theme.Text
    hexBox.TextSize = 12
    hexBox.Font = Enum.Font.Gotham
    hexBox.ClearTextOnFocus = false
    hexBox.ZIndex = 201
    hexBox.Parent = CWFrame
    GUI.TrackStatic(hexBox, "BackgroundColor3", "ElementBG")
    GUI.TrackStatic(hexBox, "TextColor3", "Text")

    local hexBoxC = Instance.new("UICorner")
    hexBoxC.CornerRadius = UDim.new(0, 8)
    hexBoxC.Parent = hexBox

    local hexBoxS = Instance.new("UIStroke")
    hexBoxS.Color = Theme.Border
    hexBoxS.Thickness = 1
    hexBoxS.Parent = hexBox
    GUI.TrackStatic(hexBoxS, "Color", "Border")

    UI.HexBox = hexBox

    local function GetSliderPos(track)
        local size = track.AbsoluteSize.X
        if size <= 0 then return nil end
        local mousePos = UserInputService:GetMouseLocation()
        return math.clamp((mousePos.X - track.AbsolutePosition.X) / size, 0, 1)
    end

    local function EnsureVisibleColor()
        if State.Sat < 0.05 then
            State.Sat = 0.5
            SetSatPos(0.5)
        end
    end

    local dragConn = nil
    local function StartDrag(which)
        State.Dragging = which
        if dragConn then dragConn:Disconnect() end
        dragConn = RunService.RenderStepped:Connect(function()
            if State.Dragging == "hue" then
                local pos = GetSliderPos(hueTrack)
                if pos then State.Hue = pos; SetHuePos(pos); EnsureVisibleColor(); UpdateColor() end
            elseif State.Dragging == "sat" then
                local pos = GetSliderPos(satTrack)
                if pos then State.Sat = pos; SetSatPos(pos); UpdateColor() end
            elseif State.Dragging == "val" then
                local pos = GetSliderPos(valTrack)
                if pos then State.Val = pos; SetValPos(pos); UpdateColor() end
            end
        end)
    end

    local function EndDrag()
        State.Dragging = nil
        if dragConn then dragConn:Disconnect() dragConn = nil end
    end

    hueTrack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then StartDrag("hue") end
    end)
    satTrack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then StartDrag("sat") end
    end)
    valTrack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then StartDrag("val") end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then EndDrag() end
    end)

    local function ParseHex()
        local text = hexBox.Text:gsub("#", ""):upper()
        if #text == 3 then
            text = text:sub(1,1):rep(2) .. text:sub(2,2):rep(2) .. text:sub(3,3):rep(2)
        end
        if #text ~= 6 then return nil end
        local r = tonumber(text:sub(1,2), 16)
        local g = tonumber(text:sub(3,4), 16)
        local b = tonumber(text:sub(5,6), 16)
        if not r or not g or not b then return nil end
        return Color3.fromRGB(r, g, b)
    end

    local function ApplyHexColor()
        local color = ParseHex()
        if not color then
            hexBoxS.Color = Color3.fromRGB(255, 80, 80)
            task.delay(0.3, function() hexBoxS.Color = Theme.Border end)
            return
        end
        local h, s, v = Color3.toHSV(color)
        State.Hue, State.Sat, State.Val = h, s, v
        SetHuePos(h)
        SetSatPos(s)
        SetValPos(v)
        UpdateColor()
        hexBoxS.Color = Color3.fromRGB(80, 255, 80)
        task.delay(0.3, function() hexBoxS.Color = Theme.Border end)
    end

    hexBox.FocusLost:Connect(ApplyHexColor)

    local hexTypingConn = nil
    hexBox:GetPropertyChangedSignal("Text"):Connect(function()
        if UpdatingHex then return end
        if hexTypingConn then hexTypingConn:Disconnect() end
        hexTypingConn = task.delay(0.5, function()
            hexTypingConn = nil
            ApplyHexColor()
        end)
    end)

    CWClose.MouseButton1Click:Connect(function()
        CWFrame.Visible = false
        State.IsOpen = false
        EndDrag()
    end)

    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if State.JustOpened then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 and State.IsOpen then
            local mousePos = UserInputService:GetMouseLocation()
            local framePos = CWFrame.AbsolutePosition
            local frameSize = CWFrame.AbsoluteSize
            if mousePos.X < framePos.X or mousePos.X > framePos.X + frameSize.X or
               mousePos.Y < framePos.Y or mousePos.Y > framePos.Y + frameSize.Y then
                CWFrame.Visible = false
                State.IsOpen = false
                EndDrag()
            end
        end
    end)

    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.Escape and State.IsOpen then
            CWFrame.Visible = false
            State.IsOpen = false
            EndDrag()
        end
    end)

    local Picker = {}
    function Picker:Open(setCallback, setDefaultColor)
        State.Callback = setCallback
        if setDefaultColor then
            local h, s, v = Color3.toHSV(setDefaultColor)
            State.Hue, State.Sat, State.Val = h, s, v
        end
        SetHuePos(State.Hue)
        SetSatPos(State.Sat)
        SetValPos(State.Val)
        UpdateColor(true)
        CWFrame.Visible = true
        State.IsOpen = true
        State.JustOpened = true
        task.delay(0.2, function() State.JustOpened = false end)
    end
    function Picker:Close()
        CWFrame.Visible = false
        State.IsOpen = false
        EndDrag()
    end
    function Picker:IsOpen() return State.IsOpen end
    function Picker:GetFrame() return CWFrame end
    return Picker
end

return GUI