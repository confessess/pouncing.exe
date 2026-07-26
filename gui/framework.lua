-- ============================================================
-- Pouncing.exe | GUI Framework
-- Cute Pink Neon UI Components
-- ============================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

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
    VT.Text = "v1.0"
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
        ActiveTab = nil
    }
end

function GUI.CreateTab(window, name, icon)
    local order = #window.Tabs
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