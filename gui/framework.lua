-- Pouncing.exe | GUI Framework v2.3
-- Cute Pink Neon UI Components
-- HSV Wheel: accurate mouse tracking, dense dot rendering
-- Added: Click-outside-to-close + Escape-to-close + better picker positioning
-- ============================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- ============================================================
-- Color Palette — Cute Pink Neon
-- ============================================================

local Theme = {
    BG = Color3.fromRGB(22, 12, 20),
    TabBG = Color3.fromRGB(30, 18, 28),
    ElementBG = Color3.fromRGB(35, 22, 32),
    HoverBG = Color3.fromRGB(45, 28, 42),
    Primary = Color3.fromRGB(255, 105, 180),
    Secondary = Color3.fromRGB(255, 182, 193),
    Accent = Color3.fromRGB(255, 20, 147),
    Neon = Color3.fromRGB(255, 0, 255),
    SoftPink = Color3.fromRGB(255, 160, 200),
    Text = Color3.fromRGB(255, 240, 245),
    SubText = Color3.fromRGB(200, 160, 180),
    DimText = Color3.fromRGB(150, 120, 140),
    On = Color3.fromRGB(255, 105, 180),
    OnGlow = Color3.fromRGB(255, 150, 210),
    Off = Color3.fromRGB(60, 40, 55),
    Border = Color3.fromRGB(60, 35, 55),
    BorderGlow = Color3.fromRGB(255, 105, 180),
    Shadow = Color3.fromRGB(0, 0, 0),
    White = Color3.fromRGB(255, 255, 255),
    Black = Color3.fromRGB(0, 0, 0),
}

local GUI = {}
GUI.Theme = Theme

-- ============================================================
-- CreateWindow — Main Draggable Window
-- ============================================================

function GUI.CreateWindow(parent, title, size)
    size = size or UDim2.new(0, 540, 0, 380)

    local MF = Instance.new("Frame")
    MF.Name = "PouncingMain"
    MF.Size = size
    MF.Position = UDim2.new(0.5, -size.X.Offset / 2, 0.5, -size.Y.Offset / 2)
    MF.BackgroundColor3 = Theme.BG
    MF.BorderSizePixel = 0
    MF.Active = true
    MF.ClipsDescendants = true
    MF.Parent = parent

    local MC = Instance.new("UICorner")
    MC.CornerRadius = UDim.new(0, 14)
    MC.Parent = MF

    local border = Instance.new("UIStroke")
    border.Color = Theme.BorderGlow
    border.Thickness = 1.2
    border.Transparency = 0.4
    border.Parent = MF

    local glow = Instance.new("Frame")
    glow.Name = "OuterGlow"
    glow.Size = UDim2.new(1, 6, 1, 6)
    glow.Position = UDim2.new(0, -3, 0, -3)
    glow.BackgroundTransparency = 1
    glow.BorderSizePixel = 0
    glow.ZIndex = -2
    glow.Parent = MF

    local glowStroke = Instance.new("UIStroke")
    glowStroke.Color = Theme.Primary
    glowStroke.Thickness = 2
    glowStroke.Transparency = 0.85
    glowStroke.Parent = glow

    local glowCorner = Instance.new("UICorner")
    glowCorner.CornerRadius = UDim.new(0, 16)
    glowCorner.Parent = glow

    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
    shadow.Size = UDim2.new(1, 30, 1, 30)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://5554236805"
    shadow.ImageColor3 = Theme.Shadow
    shadow.ImageTransparency = 0.7
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(23, 23, 277, 277)
    shadow.ZIndex = -1
    shadow.Parent = MF

    local TB = Instance.new("Frame")
    TB.Name = "TitleBar"
    TB.Size = UDim2.new(1, 0, 0, 40)
    TB.BackgroundColor3 = Theme.TabBG
    TB.BorderSizePixel = 0
    TB.Active = true
    TB.Parent = MF

    local TBC = Instance.new("UICorner")
    TBC.CornerRadius = UDim.new(0, 14)
    TBC.Parent = TB

    local TBF = Instance.new("Frame")
    TBF.Size = UDim2.new(1, 0, 0, 12)
    TBF.Position = UDim2.new(0, 0, 1, -12)
    TBF.BackgroundColor3 = Theme.TabBG
    TBF.BorderSizePixel = 0
    TBF.Parent = TB

    local TT = Instance.new("TextLabel")
    TT.Name = "TitleText"
    TT.Size = UDim2.new(1, -100, 1, 0)
    TT.Position = UDim2.new(0, 16, 0, 0)
    TT.BackgroundTransparency = 1
    TT.Text = "🐾 " .. title
    TT.TextColor3 = Theme.Text
    TT.TextSize = 15
    TT.Font = Enum.Font.GothamBold
    TT.TextXAlignment = Enum.TextXAlignment.Left
    TT.Parent = TB

    local VT = Instance.new("TextLabel")
    VT.Size = UDim2.new(0, 60, 0, 20)
    VT.Position = UDim2.new(1, -95, 0, 10)
    VT.BackgroundTransparency = 1
    VT.Text = "v2.3"
    VT.TextColor3 = Theme.SubText
    VT.TextSize = 11
    VT.Font = Enum.Font.Gotham
    VT.Parent = TB

    local CB = Instance.new("TextButton")
    CB.Name = "CloseBtn"
    CB.Size = UDim2.new(0, 32, 0, 32)
    CB.Position = UDim2.new(1, -36, 0, 4)
    CB.BackgroundTransparency = 1
    CB.Text = "×"
    CB.TextColor3 = Theme.SubText
    CB.TextSize = 22
    CB.Font = Enum.Font.GothamBold
    CB.Parent = TB

    CB.MouseEnter:Connect(function()
        TweenService:Create(CB, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(255, 100, 100)}):Play()
    end)
    CB.MouseLeave:Connect(function()
        TweenService:Create(CB, TweenInfo.new(0.2), {TextColor3 = Theme.SubText}):Play()
    end)
    CB.MouseButton1Click:Connect(function()
        TweenService:Create(MF, TweenInfo.new(0.3), {Size = UDim2.new(0, size.X.Offset, 0, 0)}):Play()
        task.delay(0.35, function() parent:Destroy() end)
    end)

    local MB = Instance.new("TextButton")
    MB.Name = "MinBtn"
    MB.Size = UDim2.new(0, 32, 0, 32)
    MB.Position = UDim2.new(1, -68, 0, 4)
    MB.BackgroundTransparency = 1
    MB.Text = "−"
    MB.TextColor3 = Theme.SubText
    MB.TextSize = 22
    MB.Font = Enum.Font.GothamBold
    MB.Parent = TB

    local Min = false
    MB.MouseButton1Click:Connect(function()
        Min = not Min
        local ts = Min and UDim2.new(0, size.X.Offset, 0, 40) or size
        TweenService:Create(MF, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = ts}):Play()
        MB.Text = Min and "+" or "−"
    end)

    local dragging = false
    local dragStart = nil
    local startPos = nil

    TB.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MF.Position
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
            MF.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    local TCon = Instance.new("Frame")
    TCon.Name = "TabContainer"
    TCon.Size = UDim2.new(0, 130, 1, -40)
    TCon.Position = UDim2.new(0, 0, 0, 40)
    TCon.BackgroundColor3 = Theme.TabBG
    TCon.BorderSizePixel = 0
    TCon.Parent = MF

    local CCon = Instance.new("Frame")
    CCon.Name = "ContentContainer"
    CCon.Size = UDim2.new(1, -130, 1, -40)
    CCon.Position = UDim2.new(0, 130, 0, 40)
    CCon.BackgroundTransparency = 1
    CCon.BorderSizePixel = 0
    CCon.Parent = MF

    local PawDeco = Instance.new("TextLabel")
    PawDeco.Size = UDim2.new(1, 0, 0, 30)
    PawDeco.Position = UDim2.new(0, 0, 1, -35)
    PawDeco.BackgroundTransparency = 1
    PawDeco.Text = "🐾"
    PawDeco.TextColor3 = Theme.Primary
    PawDeco.TextSize = 18
    PawDeco.Font = Enum.Font.GothamBold
    PawDeco.TextTransparency = 0.6
    PawDeco.Parent = TCon

    return {
        MainFrame = MF,
        TitleBar = TB,
        TabContainer = TCon,
        ContentContainer = CCon,
        Tabs = {},
        Contents = {},
        ActiveTab = nil,
        TabCount = 0
    }
end

-- ============================================================
-- CreateTab
-- ============================================================

function GUI.CreateTab(window, name, icon)
    local order = window.TabCount
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

    local BC = Instance.new("UICorner")
    BC.CornerRadius = UDim.new(0, 8)
    BC.Parent = B

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
    window.TabCount = window.TabCount + 1

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

-- ============================================================
-- CreateToggle
-- ============================================================

function GUI.CreateToggle(parent, text, default, colorKey, callback)
    local F = Instance.new("Frame")
    F.Size = UDim2.new(1, -10, 0, 38)
    F.BackgroundColor3 = Theme.ElementBG
    F.BorderSizePixel = 0
    F.Parent = parent

    local FC = Instance.new("UICorner")
    FC.CornerRadius = UDim.new(0, 8)
    FC.Parent = F

    local fStroke = Instance.new("UIStroke")
    fStroke.Color = Theme.Border
    fStroke.Thickness = 1
    fStroke.Transparency = 0.5
    fStroke.Parent = F

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

    local CBtn = nil
    if colorKey then
        CBtn = Instance.new("TextButton")
        CBtn.Name = "ColorBtn"
        CBtn.Size = UDim2.new(0, 22, 0, 22)
        CBtn.Position = UDim2.new(1, -84, 0.5, -11)
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
    end

    local TBtn = Instance.new("TextButton")
    TBtn.Name = "ToggleBtn"
    TBtn.Size = UDim2.new(0, 44, 0, 22)
    TBtn.Position = UDim2.new(1, -56, 0.5, -11)
    TBtn.BackgroundColor3 = default and Theme.On or Theme.Off
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
    TBtnGlow.Transparency = default and 0.5 or 1
    TBtnGlow.Parent = TBtn

    local Circ = Instance.new("Frame")
    Circ.Name = "Knob"
    Circ.Size = UDim2.new(0, 18, 0, 18)
    Circ.Position = default and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
    Circ.BackgroundColor3 = Theme.White
    Circ.BorderSizePixel = 0
    Circ.Parent = TBtn

    local CircC = Instance.new("UICorner")
    CircC.CornerRadius = UDim.new(1, 0)
    CircC.Parent = Circ

    local CircS = Instance.new("UIStroke")
    CircS.Color = Theme.Border
    CircS.Thickness = 1
    CircS.Transparency = 0.3
    CircS.Parent = Circ

    local State = default

    local function Upd()
        State = not State
        TweenService:Create(Circ, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = State and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
        }):Play()
        TweenService:Create(TBtn, TweenInfo.new(0.25), {
            BackgroundColor3 = State and Theme.On or Theme.Off
        }):Play()
        TweenService:Create(TBtnGlow, TweenInfo.new(0.25), {
            Transparency = State and 0.5 or 1
        }):Play()
        if callback then callback(State) end
    end

    TBtn.MouseButton1Click:Connect(Upd)

    return F, function() return State end, CBtn
end

-- ============================================================
-- CreateSlider
-- ============================================================

function GUI.CreateSlider(parent, text, min, max, default, callback)
    local F = Instance.new("Frame")
    F.Size = UDim2.new(1, -10, 0, 56)
    F.BackgroundColor3 = Theme.ElementBG
    F.BorderSizePixel = 0
    F.Parent = parent

    local FC = Instance.new("UICorner")
    FC.CornerRadius = UDim.new(0, 8)
    FC.Parent = F

    local fStroke = Instance.new("UIStroke")
    fStroke.Color = Theme.Border
    fStroke.Thickness = 1
    fStroke.Transparency = 0.5
    fStroke.Parent = F

    local L = Instance.new("TextLabel")
    L.Size = UDim2.new(1, -70, 0, 22)
    L.Position = UDim2.new(0, 14, 0, 6)
    L.BackgroundTransparency = 1
    L.Text = text
    L.TextColor3 = Theme.Text
    L.TextSize = 12
    L.Font = Enum.Font.Gotham
    L.TextXAlignment = Enum.TextXAlignment.Left
    L.Parent = F

    local VL = Instance.new("TextLabel")
    VL.Size = UDim2.new(0, 50, 0, 22)
    VL.Position = UDim2.new(1, -60, 0, 6)
    VL.BackgroundTransparency = 1
    VL.Text = tostring(default)
    VL.TextColor3 = Theme.Primary
    VL.TextSize = 12
    VL.Font = Enum.Font.GothamBold
    VL.Parent = F

    local Tr = Instance.new("Frame")
    Tr.Size = UDim2.new(1, -28, 0, 5)
    Tr.Position = UDim2.new(0, 14, 0, 38)
    Tr.BackgroundColor3 = Theme.Border
    Tr.BorderSizePixel = 0
    Tr.Parent = F

    local TrC = Instance.new("UICorner")
    TrC.CornerRadius = UDim.new(1, 0)
    TrC.Parent = Tr

    local Fi = Instance.new("Frame")
    local frac = (default - min) / (max - min)
    Fi.Size = UDim2.new(frac, 0, 1, 0)
    Fi.BackgroundColor3 = Theme.Primary
    Fi.BorderSizePixel = 0
    Fi.Parent = Tr

    local FiC = Instance.new("UICorner")
    FiC.CornerRadius = UDim.new(1, 0)
    FiC.Parent = Fi

    local FiGlow = Instance.new("UIStroke")
    FiGlow.Color = Theme.Neon
    FiGlow.Thickness = 2
    FiGlow.Transparency = 0.6
    FiGlow.Parent = Fi

    local Kn = Instance.new("Frame")
    Kn.Size = UDim2.new(0, 14, 0, 14)
    Kn.Position = UDim2.new(frac, -7, 0.5, -7)
    Kn.BackgroundColor3 = Theme.White
    Kn.BorderSizePixel = 0
    Kn.Parent = Tr

    local KnC = Instance.new("UICorner")
    KnC.CornerRadius = UDim.new(1, 0)
    KnC.Parent = Kn

    local KnGlow = Instance.new("UIStroke")
    KnGlow.Color = Theme.Primary
    KnGlow.Thickness = 2
    KnGlow.Transparency = 0.4
    KnGlow.Parent = Kn

    local Drag = false

    local function Upd(input)
        local pos = math.clamp((input.Position.X - Tr.AbsolutePosition.X) / Tr.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + (pos * (max - min)))
        Fi.Size = UDim2.new(pos, 0, 1, 0)
        Kn.Position = UDim2.new(pos, -7, 0.5, -7)
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

    return F
end

-- ============================================================
-- CreateButton
-- ============================================================

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

    local FC = Instance.new("UICorner")
    FC.CornerRadius = UDim.new(0, 8)
    FC.Parent = F

    local fStroke = Instance.new("UIStroke")
    fStroke.Color = Theme.Neon
    fStroke.Thickness = 1.5
    fStroke.Transparency = 0.4
    fStroke.Parent = F

    F.MouseEnter:Connect(function()
        TweenService:Create(F, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Accent}):Play()
        TweenService:Create(fStroke, TweenInfo.new(0.2), {Transparency = 0.2}):Play()
    end)
    F.MouseLeave:Connect(function()
        TweenService:Create(F, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Primary}):Play()
        TweenService:Create(fStroke, TweenInfo.new(0.2), {Transparency = 0.4}):Play()
    end)
    F.MouseButton1Click:Connect(function()
        TweenService:Create(F, TweenInfo.new(0.1), {Size = UDim2.new(1, -14, 0, 34)}):Play()
        task.delay(0.1, function()
            TweenService:Create(F, TweenInfo.new(0.1), {Size = UDim2.new(1, -10, 0, 36)}):Play()
        end)
        if callback then callback() end
    end)

    return F
end

-- ============================================================
-- CreateLabel
-- ============================================================

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

-- ============================================================
-- CreateDropdown
-- ============================================================

function GUI.CreateDropdown(parent, text, options, default, callback)
    local F = Instance.new("Frame")
    F.Size = UDim2.new(1, -10, 0, 38)
    F.BackgroundColor3 = Theme.ElementBG
    F.BorderSizePixel = 0
    F.Parent = parent

    local FC = Instance.new("UICorner")
    FC.CornerRadius = UDim.new(0, 8)
    FC.Parent = F

    local fStroke = Instance.new("UIStroke")
    fStroke.Color = Theme.Border
    fStroke.Thickness = 1
    fStroke.Transparency = 0.5
    fStroke.Parent = F

    local L = Instance.new("TextLabel")
    L.Size = UDim2.new(1, -130, 1, 0)
    L.Position = UDim2.new(0, 14, 0, 0)
    L.BackgroundTransparency = 1
    L.Text = text
    L.TextColor3 = Theme.Text
    L.TextSize = 12
    L.Font = Enum.Font.Gotham
    L.TextXAlignment = Enum.TextXAlignment.Left
    L.Parent = F

    local selected = default or options[1] or "None"

    local DBtn = Instance.new("TextButton")
    DBtn.Size = UDim2.new(0, 100, 0, 26)
    DBtn.Position = UDim2.new(1, -110, 0.5, -13)
    DBtn.BackgroundColor3 = Theme.BG
    DBtn.BorderSizePixel = 0
    DBtn.Text = selected
    DBtn.TextColor3 = Theme.Primary
    DBtn.TextSize = 11
    DBtn.Font = Enum.Font.GothamSemibold
    DBtn.AutoButtonColor = false
    DBtn.Parent = F

    local DBC = Instance.new("UICorner")
    DBC.CornerRadius = UDim.new(0, 6)
    DBC.Parent = DBtn

    local DBS = Instance.new("UIStroke")
    DBS.Color = Theme.BorderGlow
    DBS.Thickness = 1
    DBS.Transparency = 0.5
    DBS.Parent = DBtn

    local open = false
    local dropFrame = nil

    local contentContainer = parent.Parent

    DBtn.MouseButton1Click:Connect(function()
        open = not open
        if open then
            if dropFrame then dropFrame:Destroy() end
            dropFrame = Instance.new("Frame")
            dropFrame.Size = UDim2.new(0, 100, 0, math.min(#options * 28, 140))
            dropFrame.BackgroundColor3 = Theme.BG
            dropFrame.BorderSizePixel = 0
            dropFrame.ZIndex = 100
            dropFrame.Parent = contentContainer

            task.defer(function()
                local btnPos = DBtn.AbsolutePosition
                local containerPos = contentContainer.AbsolutePosition
                dropFrame.Position = UDim2.new(
                    0, btnPos.X - containerPos.X,
                    0, btnPos.Y - containerPos.Y + DBtn.AbsoluteSize.Y + 4
                )
            end)

            local dropC = Instance.new("UICorner")
            dropC.CornerRadius = UDim.new(0, 6)
            dropC.Parent = dropFrame

            local dropS = Instance.new("UIStroke")
            dropS.Color = Theme.BorderGlow
            dropS.Thickness = 1
            dropS.Parent = dropFrame

            local scroll = Instance.new("ScrollingFrame")
            scroll.Size = UDim2.new(1, -4, 1, -4)
            scroll.Position = UDim2.new(0, 2, 0, 2)
            scroll.BackgroundTransparency = 1
            scroll.BorderSizePixel = 0
            scroll.ScrollBarThickness = 2
            scroll.ScrollBarImageColor3 = Theme.Primary
            scroll.CanvasSize = UDim2.new(0, 0, 0, #options * 28)
            scroll.ZIndex = 101
            scroll.Parent = dropFrame

            for i, opt in ipairs(options) do
                local optBtn = Instance.new("TextButton")
                optBtn.Size = UDim2.new(1, 0, 0, 26)
                optBtn.Position = UDim2.new(0, 0, 0, (i - 1) * 28)
                optBtn.BackgroundColor3 = Theme.BG
                optBtn.BorderSizePixel = 0
                optBtn.Text = opt
                optBtn.TextColor3 = Theme.Text
                optBtn.TextSize = 11
                optBtn.Font = Enum.Font.Gotham
                optBtn.ZIndex = 102
                optBtn.Parent = scroll

                optBtn.MouseEnter:Connect(function()
                    TweenService:Create(optBtn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.HoverBG}):Play()
                end)
                optBtn.MouseLeave:Connect(function()
                    TweenService:Create(optBtn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.BG}):Play()
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
-- CreateKeybind — Actually works
-- ============================================================

function GUI.CreateKeybind(parent, text, defaultKey, callback)
    local F = Instance.new("Frame")
    F.Size = UDim2.new(1, -10, 0, 38)
    F.BackgroundColor3 = Theme.ElementBG
    F.BorderSizePixel = 0
    F.Parent = parent

    local FC = Instance.new("UICorner")
    FC.CornerRadius = UDim.new(0, 8)
    FC.Parent = F

    local fStroke = Instance.new("UIStroke")
    fStroke.Color = Theme.Border
    fStroke.Thickness = 1
    fStroke.Transparency = 0.5
    fStroke.Parent = F

    local L = Instance.new("TextLabel")
    L.Size = UDim2.new(1, -130, 1, 0)
    L.Position = UDim2.new(0, 14, 0, 0)
    L.BackgroundTransparency = 1
    L.Text = text
    L.TextColor3 = Theme.Text
    L.TextSize = 12
    L.Font = Enum.Font.Gotham
    L.TextXAlignment = Enum.TextXAlignment.Left
    L.Parent = F

    local currentKey = defaultKey or Enum.KeyCode.Q
    local listening = false

    local KBtn = Instance.new("TextButton")
    KBtn.Size = UDim2.new(0, 100, 0, 26)
    KBtn.Position = UDim2.new(1, -110, 0.5, -13)
    KBtn.BackgroundColor3 = Theme.BG
    KBtn.BorderSizePixel = 0
    KBtn.Text = currentKey.Name
    KBtn.TextColor3 = Theme.Primary
    KBtn.TextSize = 11
    KBtn.Font = Enum.Font.GothamSemibold
    KBtn.AutoButtonColor = false
    KBtn.Parent = F

    local KBC = Instance.new("UICorner")
    KBC.CornerRadius = UDim.new(0, 6)
    KBC.Parent = KBtn

    local KBS = Instance.new("UIStroke")
    KBS.Color = Theme.BorderGlow
    KBS.Thickness = 1
    KBS.Transparency = 0.5
    KBS.Parent = KBtn

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
-- CreateColorPicker — Rainbow Sliders + Hex Input
-- No wheel, no mouse offset issues. Clean and accurate.
-- ============================================================

function GUI.CreateColorPicker(parent, titleText, defaultColor, callback)
    local CWFrame = Instance.new("Frame")
    CWFrame.Name = "ColorPicker"
    CWFrame.Size = UDim2.new(0, 260, 0, 260)
    CWFrame.Position = UDim2.new(0.5, -130, 0.5, -130)
    CWFrame.BackgroundColor3 = Theme.BG
    CWFrame.BorderSizePixel = 0
    CWFrame.Visible = false
    CWFrame.ZIndex = 200
    CWFrame.Parent = parent.Parent

    local CWC = Instance.new("UICorner")
    CWC.CornerRadius = UDim.new(0, 12)
    CWC.Parent = CWFrame

    local CWS = Instance.new("UIStroke")
    CWS.Color = Theme.BorderGlow
    CWS.Thickness = 1.5
    CWS.Parent = CWFrame

    local CWTitle = Instance.new("TextLabel")
    CWTitle.Size = UDim2.new(1, -40, 0, 26)
    CWTitle.Position = UDim2.new(0, 14, 0, 6)
    CWTitle.BackgroundTransparency = 1
    CWTitle.Text = "🎨 " .. (titleText or "Color")
    CWTitle.TextColor3 = Theme.Text
    CWTitle.TextSize = 13
    CWTitle.Font = Enum.Font.GothamBold
    CWTitle.TextXAlignment = Enum.TextXAlignment.Left
    CWTitle.ZIndex = 201
    CWTitle.Parent = CWFrame

    local CWClose = Instance.new("TextButton")
    CWClose.Size = UDim2.new(0, 26, 0, 26)
    CWClose.Position = UDim2.new(1, -32, 0, 6)
    CWClose.BackgroundTransparency = 1
    CWClose.Text = "×"
    CWClose.TextColor3 = Theme.SubText
    CWClose.TextSize = 20
    CWClose.Font = Enum.Font.GothamBold
    CWClose.ZIndex = 201
    CWClose.Parent = CWFrame

    -- State
    local CWHue, CWSat, CWVal = 0, 1, 1
    local CWCallback = nil
    local CWOpen = false
    local ActiveSlider = nil
    local JustOpened = false

    -- References set later
    local SetHueFunc, SetSatFunc, SetValFunc
    local previewBox, hexBox, satGrad, valGrad

    -- ============================================================
    -- UpdateColor: MUST be defined before any slider callbacks
    -- ============================================================
    local function UpdateColor()
        local color = Color3.fromHSV(CWHue, CWSat, CWVal)
        if previewBox then previewBox.BackgroundColor3 = color end
        if CWCallback then CWCallback(color) end

        if satGrad then
            satGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromHSV(CWHue, 0, CWVal)),
                ColorSequenceKeypoint.new(1, Color3.fromHSV(CWHue, 1, CWVal))
            })
        end
        if valGrad then
            valGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromHSV(CWHue, CWSat, 0)),
                ColorSequenceKeypoint.new(1, Color3.fromHSV(CWHue, CWSat, 1))
            })
        end

        if hexBox then
            local r = math.floor(color.R * 255)
            local g = math.floor(color.G * 255)
            local b = math.floor(color.B * 255)
            hexBox.Text = string.format("#%02X%02X%02X", r, g, b)
        end
    end

    -- ============================================================
    -- MakeSlider
    -- ============================================================
    local function MakeSlider(y, labelText, initVal, onChange)
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0, 100, 0, 14)
        label.Position = UDim2.new(0, 14, 0, y)
        label.BackgroundTransparency = 1
        label.Text = labelText
        label.TextColor3 = Theme.SubText
        label.TextSize = 10
        label.Font = Enum.Font.Gotham
        label.ZIndex = 201
        label.Parent = CWFrame

        local track = Instance.new("Frame")
        track.Size = UDim2.new(1, -28, 0, 5)
        track.Position = UDim2.new(0, 14, 0, y + 16)
        track.BackgroundColor3 = Theme.Border
        track.BorderSizePixel = 0
        track.ZIndex = 201
        track.Parent = CWFrame

        local trackC = Instance.new("UICorner")
        trackC.CornerRadius = UDim.new(1, 0)
        trackC.Parent = track

        local gradient = Instance.new("UIGradient")
        gradient.Parent = track

        local knob = Instance.new("TextButton")
        knob.Size = UDim2.new(0, 14, 0, 14)
        knob.Position = UDim2.new(initVal, -7, 0.5, -7)
        knob.BackgroundColor3 = Theme.White
        knob.BorderSizePixel = 0
        knob.Text = ""
        knob.AutoButtonColor = false
        knob.ZIndex = 203
        knob.Parent = track

        local knobC = Instance.new("UICorner")
        knobC.CornerRadius = UDim.new(1, 0)
        knobC.Parent = knob

        local knobS = Instance.new("UIStroke")
        knobS.Color = Theme.Primary
        knobS.Thickness = 2
        knobS.Parent = knob

        local function Upd(input)
            local pos = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            knob.Position = UDim2.new(pos, -7, 0.5, -7)
            if onChange then onChange(pos) end
        end

        knob.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                ActiveSlider = Upd
            end
        end)

        track.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                ActiveSlider = Upd
                Upd(input)
            end
        end)

        local function SetValue(v)
            knob.Position = UDim2.new(v, -7, 0.5, -7)
        end

        return gradient, SetValue
    end

    -- ============================================================
    -- Create sliders — callbacks now properly reference UpdateColor
    -- ============================================================
    local hueSequence = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
        ColorSequenceKeypoint.new(0.1667, Color3.fromRGB(255, 255, 0)),
        ColorSequenceKeypoint.new(0.3333, Color3.fromRGB(0, 255, 0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(0.6667, Color3.fromRGB(0, 0, 255)),
        ColorSequenceKeypoint.new(0.8333, Color3.fromRGB(255, 0, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
    })

    local hueGrad
    hueGrad, SetHueFunc = MakeSlider(38, "Hue", 0, function(v)
        CWHue = v
        UpdateColor()
    end)
    hueGrad.Color = hueSequence

    satGrad, SetSatFunc = MakeSlider(78, "Saturation", 1, function(v)
        CWSat = v
        UpdateColor()
    end)

    valGrad, SetValFunc = MakeSlider(118, "Brightness", 1, function(v)
        CWVal = v
        UpdateColor()
    end)

    -- ============================================================
    -- Preview box
    -- ============================================================
    local previewLabel = Instance.new("TextLabel")
    previewLabel.Size = UDim2.new(0, 60, 0, 14)
    previewLabel.Position = UDim2.new(0, 14, 0, 158)
    previewLabel.BackgroundTransparency = 1
    previewLabel.Text = "Preview"
    previewLabel.TextColor3 = Theme.SubText
    previewLabel.TextSize = 10
    previewLabel.Font = Enum.Font.Gotham
    previewLabel.ZIndex = 201
    previewLabel.Parent = CWFrame

    previewBox = Instance.new("Frame")
    previewBox.Size = UDim2.new(0, 50, 0, 24)
    previewBox.Position = UDim2.new(0, 14, 0, 174)
    previewBox.BackgroundColor3 = Color3.fromHSV(0, 1, 1)
    previewBox.BorderSizePixel = 0
    previewBox.ZIndex = 201
    previewBox.Parent = CWFrame

    local previewBoxC = Instance.new("UICorner")
    previewBoxC.CornerRadius = UDim.new(0, 6)
    previewBoxC.Parent = previewBox

    local previewBoxS = Instance.new("UIStroke")
    previewBoxS.Color = Theme.BorderGlow
    previewBoxS.Thickness = 1.5
    previewBoxS.Parent = previewBox

    -- ============================================================
    -- Hex input
    -- ============================================================
    local hexLabel = Instance.new("TextLabel")
    hexLabel.Size = UDim2.new(0, 60, 0, 14)
    hexLabel.Position = UDim2.new(0, 80, 0, 158)
    hexLabel.BackgroundTransparency = 1
    hexLabel.Text = "Hex"
    hexLabel.TextColor3 = Theme.SubText
    hexLabel.TextSize = 10
    hexLabel.Font = Enum.Font.Gotham
    hexLabel.ZIndex = 201
    hexLabel.Parent = CWFrame

    hexBox = Instance.new("TextBox")
    hexBox.Size = UDim2.new(0, 120, 0, 24)
    hexBox.Position = UDim2.new(0, 80, 0, 174)
    hexBox.BackgroundColor3 = Theme.ElementBG
    hexBox.BorderSizePixel = 0
    hexBox.Text = "#FF69B4"
    hexBox.TextColor3 = Theme.Text
    hexBox.TextSize = 11
    hexBox.Font = Enum.Font.Gotham
    hexBox.ClearTextOnFocus = false
    hexBox.ZIndex = 201
    hexBox.Parent = CWFrame

    local hexBoxC = Instance.new("UICorner")
    hexBoxC.CornerRadius = UDim.new(0, 6)
    hexBoxC.Parent = hexBox

    local hexBoxS = Instance.new("UIStroke")
    hexBoxS.Color = Theme.Border
    hexBoxS.Thickness = 1
    hexBoxS.Parent = hexBox

    -- ============================================================
    -- Hex → Sliders (bidirectional)
    -- ============================================================
    hexBox.FocusLost:Connect(function()
        local text = hexBox.Text:gsub("#", ""):upper()
        if #text == 3 then
            text = text:sub(1,1):rep(2) .. text:sub(2,2):rep(2) .. text:sub(3,3):rep(2)
        end
        if #text ~= 6 then
            hexBoxS.Color = Color3.fromRGB(255, 80, 80)
            task.delay(0.3, function() hexBoxS.Color = Theme.Border end)
            return
        end
        local r = tonumber(text:sub(1,2), 16)
        local g = tonumber(text:sub(3,4), 16)
        local b = tonumber(text:sub(5,6), 16)
        if not r or not g or not b then
            hexBoxS.Color = Color3.fromRGB(255, 80, 80)
            task.delay(0.3, function() hexBoxS.Color = Theme.Border end)
            return
        end
        local color = Color3.fromRGB(r, g, b)
        local h, s, v = Color3.toHSV(color)
        CWHue, CWSat, CWVal = h, s, v
        SetHueFunc(h)
        SetSatFunc(s)
        SetValFunc(v)
        UpdateColor()
        hexBoxS.Color = Color3.fromRGB(80, 255, 80)
        task.delay(0.3, function() hexBoxS.Color = Theme.Border end)
    end)

    -- ============================================================
    -- Global input handlers for drag + close
    -- ============================================================
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            ActiveSlider = nil
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if ActiveSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
            ActiveSlider(input)
        end
    end)

    CWClose.MouseButton1Click:Connect(function()
        CWFrame.Visible = false
        CWOpen = false
    end)

    -- Click outside to close
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if JustOpened then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 and CWOpen then
            local mousePos = UserInputService:GetMouseLocation()
            local framePos = CWFrame.AbsolutePosition
            local frameSize = CWFrame.AbsoluteSize
            if mousePos.X < framePos.X or mousePos.X > framePos.X + frameSize.X or
               mousePos.Y < framePos.Y or mousePos.Y > framePos.Y + frameSize.Y then
                CWFrame.Visible = false
                CWOpen = false
            end
        end
    end)

    -- Escape to close
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.Escape and CWOpen then
            CWFrame.Visible = false
            CWOpen = false
        end
    end)

    -- ============================================================
    -- Picker API
    -- ============================================================
    local Picker = {}

    function Picker:Open(setCallback, setDefaultColor)
        CWCallback = setCallback
        if setDefaultColor then
            local h, s, v = Color3.toHSV(setDefaultColor)
            CWHue, CWSat, CWVal = h, s, v
        end
        SetHueFunc(CWHue)
        SetSatFunc(CWSat)
        SetValFunc(CWVal)
        UpdateColor()
        CWFrame.Visible = true
        CWOpen = true
        JustOpened = true
        task.delay(0.15, function() JustOpened = false end)
    end

    function Picker:Close()
        CWFrame.Visible = false
        CWOpen = false
    end

    function Picker:IsOpen()
        return CWOpen
    end

    function Picker:GetFrame()
        return CWFrame
    end

    return Picker
end
function GUI.CreateSeparator(parent)
    local F = Instance.new("Frame")
    F.Size = UDim2.new(1, -20, 0, 1)
    F.Position = UDim2.new(0, 10, 0, 0)
    F.BackgroundColor3 = Theme.Border
    F.BorderSizePixel = 0
    F.BackgroundTransparency = 0.6
    F.Parent = parent
    return F
end

-- ============================================================
-- CreateSection
-- ============================================================

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

return GUI