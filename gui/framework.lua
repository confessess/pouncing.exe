
output_dir = "/mnt/agents/output/pouncing.exe"

# ============================================================
# 3. GUI/FRAMEWORK.LUA - Pink Neon UI Components
# ============================================================
framework = '''-- ============================================================
-- Pouncing.exe | GUI Framework
-- Cute Pink Neon UI Components
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
    -- Backgrounds
    BG = Color3.fromRGB(22, 12, 20),
    TabBG = Color3.fromRGB(30, 18, 28),
    ElementBG = Color3.fromRGB(35, 22, 32),
    HoverBG = Color3.fromRGB(45, 28, 42),
    
    -- Pinks
    Primary = Color3.fromRGB(255, 105, 180),      -- Hot Pink
    Secondary = Color3.fromRGB(255, 182, 193),      -- Light Pink
    Accent = Color3.fromRGB(255, 20, 147),          -- Deep Pink
    Neon = Color3.fromRGB(255, 0, 255),             -- Magenta
    SoftPink = Color3.fromRGB(255, 160, 200),       -- Soft Pink
    
    -- Text
    Text = Color3.fromRGB(255, 240, 245),           -- Lavender Blush
    SubText = Color3.fromRGB(200, 160, 180),        -- Muted Pink
    DimText = Color3.fromRGB(150, 120, 140),        -- Dim Pink
    
    -- States
    On = Color3.fromRGB(255, 105, 180),             -- Toggle On
    OnGlow = Color3.fromRGB(255, 150, 210),         -- Toggle Glow
    Off = Color3.fromRGB(60, 40, 55),               -- Toggle Off
    Border = Color3.fromRGB(60, 35, 55),            -- Borders
    BorderGlow = Color3.fromRGB(255, 105, 180),     -- Neon Border
    
    -- Utility
    Shadow = Color3.fromRGB(0, 0, 0),
    White = Color3.fromRGB(255, 255, 255),
    Black = Color3.fromRGB(0, 0, 0),
}

local GUI = {}
GUI.Theme = Theme

-- ============================================================
-- Internal: Glow Effect
-- ============================================================

local function AddGlow(parent, color, thickness)
    thickness = thickness or 1.5
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Theme.BorderGlow
    stroke.Thickness = thickness
    stroke.Transparency = 0.3
    stroke.Parent = parent
    return stroke
end

local function AddSoftShadow(parent)
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
    shadow.ZIndex = parent.ZIndex - 1
    shadow.Parent = parent
    return shadow
end

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
    
    -- Rounded corners
    local MC = Instance.new("UICorner")
    MC.CornerRadius = UDim.new(0, 14)
    MC.Parent = MF
    
    -- Neon border glow
    local border = Instance.new("UIStroke")
    border.Color = Theme.BorderGlow
    border.Thickness = 1.2
    border.Transparency = 0.4
    border.Parent = MF
    
    -- Outer glow frame
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
    
    -- Soft shadow
    AddSoftShadow(MF)
    
    -- Title Bar
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
    
    -- Bottom fill to hide corner gap
    local TBF = Instance.new("Frame")
    TBF.Size = UDim2.new(1, 0, 0, 12)
    TBF.Position = UDim2.new(0, 0, 1, -12)
    TBF.BackgroundColor3 = Theme.TabBG
    TBF.BorderSizePixel = 0
    TBF.Parent = TB
    
    -- Title text with paw
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
    
    -- Version
    local VT = Instance.new("TextLabel")
    VT.Size = UDim2.new(0, 60, 0, 20)
    VT.Position = UDim2.new(1, -75, 0, 10)
    VT.BackgroundTransparency = 1
    VT.Text = "v1.0"
    VT.TextColor3 = Theme.SubText
    VT.TextSize = 11
    VT.Font = Enum.Font.Gotham
    VT.Parent = TB
    
    -- Close button
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
    
    -- Minimize button
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
    
    -- Drag functionality
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
    
    -- Tab Container (Left Sidebar)
    local TCon = Instance.new("Frame")
    TCon.Name = "TabContainer"
    TCon.Size = UDim2.new(0, 130, 1, -40)
    TCon.Position = UDim2.new(0, 0, 0, 40)
    TCon.BackgroundColor3 = Theme.TabBG
    TCon.BorderSizePixel = 0
    TCon.Parent = MF
    
    -- Content Container
    local CCon = Instance.new("Frame")
    CCon.Name = "ContentContainer"
    CCon.Size = UDim2.new(1, -130, 1, -40)
    CCon.Position = UDim2.new(0, 130, 0, 40)
    CCon.BackgroundTransparency = 1
    CCon.BorderSizePixel = 0
    CCon.Parent = MF
    
    -- Decorative paw print at bottom of sidebar
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

-- ============================================================
-- CreateTab
-- ============================================================

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
    
    -- Hover effect
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
    
    -- Content frame
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
    
    -- Tab switch logic
    B.MouseButton1Click:Connect(function()
        if window.ActiveTab == name then return end
        
        -- Deactivate old
        if window.ActiveTab then
            local oldBtn = window.Tabs[window.ActiveTab]
            TweenService:Create(oldBtn, TweenInfo.new(0.2), {
                BackgroundColor3 = Theme.BG,
                TextColor3 = Theme.SubText
            }):Play()
            window.Contents[window.ActiveTab].Visible = false
        end
        
        -- Activate new
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
-- CreateToggle — Cute Pink Toggle
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
    
    -- Subtle border
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
    
    -- Color picker button (optional)
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
    
    -- Toggle button
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
    
    -- Toggle glow when on
    local TBtnGlow = Instance.new("UIStroke")
    TBtnGlow.Color = Theme.OnGlow
    TBtnGlow.Thickness = 2
    TBtnGlow.Transparency = default and 0.5 or 1
    TBtnGlow.Parent = TBtn
    
    -- Circle knob
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
    
    -- Knob shadow
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
-- CreateSlider — Pink Neon Slider
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
    
    -- Track
    local Tr = Instance.new("Frame")
    Tr.Size = UDim2.new(1, -28, 0, 5)
    Tr.Position = UDim2.new(0, 14, 0, 38)
    Tr.BackgroundColor3 = Theme.Border
    Tr.BorderSizePixel = 0
    Tr.Parent = F
    
    local TrC = Instance.new("UICorner")
    TrC.CornerRadius = UDim.new(1, 0)
    TrC.Parent = Tr
    
    -- Fill with gradient
    local Fi = Instance.new("Frame")
    local frac = (default - min) / (max - min)
    Fi.Size = UDim2.new(frac, 0, 1, 0)
    Fi.BackgroundColor3 = Theme.Primary
    Fi.BorderSizePixel = 0
    Fi.Parent = Tr
    
    local FiC = Instance.new("UICorner")
    FiC.CornerRadius = UDim.new(1, 0)
    FiC.Parent = Fi
    
    -- Fill glow
    local FiGlow = Instance.new("UIStroke")
    FiGlow.Color = Theme.Neon
    FiGlow.Thickness = 2
    FiGlow.Transparency = 0.6
    FiGlow.Parent = Fi
    
    -- Knob
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

function GUI.CreateDropdown(parent, text, options, callback)
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
    
    local selected = options[1] or "None"
    
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
    
    DBtn.MouseButton1Click:Connect(function()
        open = not open
        if open then
            if dropFrame then dropFrame:Destroy() end
            dropFrame = Instance.new("Frame")
            dropFrame.Size = UDim2.new(0, 100, 0, math.min(#options * 28, 140))
            dropFrame.Position = UDim2.new(0, 0, 1, 4)
            dropFrame.BackgroundColor3 = Theme.BG
            dropFrame.BorderSizePixel = 0
            dropFrame.ZIndex = 50
            dropFrame.Parent = DBtn
            
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
            scroll.ZIndex = 51
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
                optBtn.ZIndex = 52
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
-- CreateColorPicker — Pink Themed HSV Wheel
-- ============================================================

function GUI.CreateColorPicker(parent, callback)
    local CWFrame = Instance.new("Frame")
    CWFrame.Name = "ColorPicker"
    CWFrame.Size = UDim2.new(0, 260, 0, 300)
    CWFrame.BackgroundColor3 = Theme.BG
    CWFrame.BorderSizePixel = 0
    CWFrame.Visible = false
    CWFrame.ZIndex = 200
    CWFrame.Parent = parent
    
    local CWC = Instance.new("UICorner")
    CWC.CornerRadius = UDim.new(0, 12)
    CWC.Parent = CWFrame
    
    local CWS = Instance.new("UIStroke")
    CWS.Color = Theme.BorderGlow
    CWS.Thickness = 1.5
    CWS.Parent = CWFrame
    
    local CWTitle = Instance.new("TextLabel")
    CWTitle.Size = UDim2.new(1, -40, 0, 28)
    CWTitle.Position = UDim2.new(0, 14, 0, 8)
    CWTitle.BackgroundTransparency = 1
    CWTitle.Text = "🎨 Color Picker"
    CWTitle.TextColor3 = Theme.Text
    CWTitle.TextSize = 13
    CWTitle.Font = Enum.Font.GothamBold
    CWTitle.TextXAlignment = Enum.TextXAlignment.Left
    CWTitle.ZIndex = 201
    CWTitle.Parent = CWFrame
    
    local CWClose = Instance.new("TextButton")
    CWClose.Size = UDim2.new(0, 26, 0, 26)
    CWClose.Position = UDim2.new(1, -32, 0, 8)
    CWClose.BackgroundTransparency = 1
    CWClose.Text = "×"
    CWClose.TextColor3 = Theme.SubText
    CWClose.TextSize = 20
    CWClose.Font = Enum.Font.GothamBold
    CWClose.ZIndex = 201
    CWClose.Parent = CWFrame
    
    -- Wheel container
    local WheelContainer = Instance.new("TextButton")
    WheelContainer.Name = "WheelContainer"
    WheelContainer.Size = UDim2.new(0, 170, 0, 170)
    WheelContainer.Position = UDim2.new(0.5, -85, 0, 38)
    WheelContainer.BackgroundColor3 = Color3.fromRGB(20, 12, 18)
    WheelContainer.BorderSizePixel = 0
    WheelContainer.Text = ""
    WheelContainer.AutoButtonColor = false
    WheelContainer.ZIndex = 201
    WheelContainer.Parent = CWFrame
    
    local WheelOC = Instance.new("UICorner")
    WheelOC.CornerRadius = UDim.new(1, 0)
    WheelOC.Parent = WheelContainer
    
    local WheelBorder = Instance.new("UIStroke")
    WheelBorder.Color = Theme.BorderGlow
    WheelBorder.Thickness = 2
    WheelBorder.Parent = WheelContainer
    
    -- Generate HSV dots (fallback method, reliable)
    local ringConfig = {
        {count = 1,  sat = 0.0, size = 14, radius = 0.00},
        {count = 14, sat = 0.18, size = 11, radius = 0.08},
        {count = 28, sat = 0.35, size = 10, radius = 0.15},
        {count = 42, sat = 0.50, size = 9,  radius = 0.22},
        {count = 56, sat = 0.65, size = 8,  radius = 0.29},
        {count = 70, sat = 0.80, size = 7,  radius = 0.36},
        {count = 84, sat = 0.92, size = 6,  radius = 0.43},
        {count = 96, sat = 1.0,  size = 5,  radius = 0.50},
    }
    
    for _, cfg in ipairs(ringConfig) do
        for i = 0, cfg.count - 1 do
            local angle = (i / cfg.count) * math.pi * 2 - math.pi / 2
            local dot = Instance.new("Frame")
            dot.Size = UDim2.new(0, cfg.size, 0, cfg.size)
            dot.Position = UDim2.new(
                0.5 + math.cos(angle) * cfg.radius - cfg.size / 340,
                0,
                0.5 + math.sin(angle) * cfg.radius - cfg.size / 340,
                0
            )
            dot.BackgroundColor3 = Color3.fromHSV(i / cfg.count, cfg.sat, 1)
            dot.BorderSizePixel = 0
            dot.ZIndex = 202
            dot.Parent = WheelContainer
            local dotC = Instance.new("UICorner")
            dotC.CornerRadius = UDim.new(1, 0)
            dotC.Parent = dot
        end
    end
    
    -- Selector dot
    local SelDot = Instance.new("Frame")
    SelDot.Name = "SelDot"
    SelDot.Size = UDim2.new(0, 14, 0, 14)
    SelDot.Position = UDim2.new(0.5, -7, 0.5, -7)
    SelDot.BackgroundColor3 = Theme.White
    SelDot.BorderSizePixel = 0
    SelDot.ZIndex = 203
    SelDot.Parent = WheelContainer
    
    local SelDotC = Instance.new("UICorner")
    SelDotC.CornerRadius = UDim.new(1, 0)
    SelDotC.Parent = SelDot
    
    local SelDotStroke = Instance.new("UIStroke")
    SelDotStroke.Color = Theme.Black
    SelDotStroke.Thickness = 2
    SelDotStroke.Parent = SelDot
    
    -- Brightness slider
    local BrightLabel = Instance.new("TextLabel")
    BrightLabel.Size = UDim2.new(0, 80, 0, 16)
    BrightLabel.Position = UDim2.new(0, 14, 0, 216)
    BrightLabel.BackgroundTransparency = 1
    BrightLabel.Text = "Brightness"
    BrightLabel.TextColor3 = Theme.SubText
    BrightLabel.TextSize = 10
    BrightLabel.Font = Enum.Font.Gotham
    BrightLabel.ZIndex = 201
    BrightLabel.Parent = CWFrame
    
    local BTrack = Instance.new("Frame")
    BTrack.Size = UDim2.new(1, -28, 0, 8)
    BTrack.Position = UDim2.new(0, 14, 0, 234)
    BTrack.BackgroundColor3 = Theme.Border
    BTrack.BorderSizePixel = 0
    BTrack.ZIndex = 201
    BTrack.Parent = CWFrame
    
    local BTC = Instance.new("UICorner")
    BTC.CornerRadius = UDim.new(1, 0)
    BTC.Parent = BTrack
    
    local BFill = Instance.new("Frame")
    BFill.Size = UDim2.new(1, 0, 1, 0)
    BFill.BackgroundColor3 = Theme.White
    BFill.BorderSizePixel = 0
    BFill.ZIndex = 201
    BFill.Parent = BTrack
    
    local BFC = Instance.new("UICorner")
    BFC.CornerRadius = UDim.new(1, 0)
    BFC.Parent = BFill
    
    local BKnob = Instance.new("TextButton")
    BKnob.Size = UDim2.new(0, 16, 0, 16)
    BKnob.Position = UDim2.new(1, -8, 0.5, -8)
    BKnob.BackgroundColor3 = Theme.White
    BKnob.BorderSizePixel = 2
    BKnob.BorderColor3 = Theme.Black
    BKnob.Text = ""
    BKnob.AutoButtonColor = false
    BKnob.ZIndex = 202
    BKnob.Parent = BTrack
    
    local BKC = Instance.new("UICorner")
    BKC.CornerRadius = UDim.new(1, 0)
    BKC.Parent = BKnob
    
    local BKnobGlow = Instance.new("UIStroke")
    BKnobGlow.Color = Theme.Primary
    BKnobGlow.Thickness = 2
    BKnobGlow.Parent = BKnob
    
    -- Preview
    local PLabel = Instance.new("TextLabel")
    PLabel.Size = UDim2.new(0, 60, 0, 16)
    PLabel.Position = UDim2.new(0, 14, 0, 250)
    PLabel.BackgroundTransparency = 1
    PLabel.Text = "Preview"
    PLabel.TextColor3 = Theme.SubText
    PLabel.TextSize = 10
    PLabel.Font = Enum.Font.Gotham
    PLabel.ZIndex = 201
    PLabel.Parent = CWFrame
    
    local PBox = Instance.new("Frame")
    PBox.Size = UDim2.new(0, 60, 0, 22)
    PBox.Position = UDim2.new(0, 14, 0, 266)
    PBox.BackgroundColor3 = Theme.White
    PBox.BorderSizePixel = 0
    PBox.ZIndex = 201
    PBox.Parent = CWFrame
    
    local PBC = Instance.new("UICorner")
    PBC.CornerRadius = UDim.new(0, 6)
    PBC.Parent = PBox
    
    local PBS = Instance.new("UIStroke")
    PBS.Color = Theme.BorderGlow
    PBS.Thickness = 1.5
    PBS.Parent = PBox
    
    -- Color state
    local CWHue, CWSat, CWVal = 0, 1, 1
    local CWCallback = nil
    local CWOpen = false
    
    local function GetWheelLocalMouse()
        local mousePos = UserInputService:GetMouseLocation()
        local absPos = WheelContainer.AbsolutePosition
        return mousePos.X - absPos.X, mousePos.Y - absPos.Y
    end
    
    local function UpdateWheel(localX, localY)
        local cx, cy = 85, 85
        local relX = localX - cx
        local relY = localY - cy
        local maxDist = 82
        local dotRadius = 7
        local effectiveMaxDist = maxDist - dotRadius - 2
        local dist = math.sqrt(relX^2 + relY^2)
        
        if dist > effectiveMaxDist then
            local scale = effectiveMaxDist / dist
            relX = relX * scale
            relY = relY * scale
            dist = effectiveMaxDist
        end
        
        local angle = math.atan2(relY, relX) + math.pi / 2
        if angle < 0 then angle = angle + 2 * math.pi end
        CWHue = angle / (2 * math.pi)
        CWSat = math.clamp(dist / effectiveMaxDist, 0, 1)
        
        SelDot.Position = UDim2.new(0.5, relX - 7, 0.5, relY - 7)
        
        local color = Color3.fromHSV(CWHue, CWSat, CWVal)
        SelDot.BackgroundColor3 = color
        PBox.BackgroundColor3 = color
        if CWCallback then CWCallback(color) end
    end
    
    local function UpdateBright(input)
        local trackAbsPos = BTrack.AbsolutePosition
        local trackAbsSize = BTrack.AbsoluteSize
        local pos = math.clamp((input.Position.X - trackAbsPos.X) / trackAbsSize.X, 0, 1)
        CWVal = pos
        BFill.Size = UDim2.new(pos, 0, 1, 0)
        BKnob.Position = UDim2.new(pos, -8, 0.5, -8)
        
        local color = Color3.fromHSV(CWHue, CWSat, CWVal)
        PBox.BackgroundColor3 = color
        SelDot.BackgroundColor3 = color
        if CWCallback then CWCallback(color) end
    end
    
    local WDrag = false
    local BDrag = false
    
    WheelContainer.MouseButton1Down:Connect(function()
        WDrag = true
        local lx, ly = GetWheelLocalMouse()
        UpdateWheel(lx, ly)
    end)
    
    BTrack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            BDrag = true
            UpdateBright(input)
        end
    end)
    
    BKnob.MouseButton1Down:Connect(function()
        BDrag = true
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            WDrag = false
            BDrag = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if WDrag and input.UserInputType == Enum.UserInputType.MouseMovement then
            local lx, ly = GetWheelLocalMouse()
            UpdateWheel(lx, ly)
        end
        if BDrag and input.UserInputType == Enum.UserInputType.MouseMovement then
            UpdateBright(input)
        end
    end)
    
    CWClose.MouseButton1Click:Connect(function()
        CWFrame.Visible = false
        CWOpen = false
    end)
    
    -- Public interface
    local Picker = {}
    
    function Picker:Open(setCallback, defaultColor)
        CWCallback = setCallback
        if defaultColor then
            local h, s, v = Color3.toHSV(defaultColor)
            CWHue, CWSat, CWVal = h, s, v
            SelDot.BackgroundColor3 = defaultColor
            PBox.BackgroundColor3 = defaultColor
            BFill.Size = UDim2.new(v, 0, 1, 0)
            BKnob.Position = UDim2.new(v, -8, 0.5, -8)
        end
        CWFrame.Visible = true
        CWOpen = true
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

-- ============================================================
-- CreateSeparator — Cute divider
-- ============================================================

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
-- CreateSection — Grouped container
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
'''

with open(f"{output_dir}/gui/framework.lua", "w") as f:
    f.write(framework)

print("gui/framework.lua written")
