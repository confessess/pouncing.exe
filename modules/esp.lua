-- Pouncing.exe | ESP Module
-- Modular player ESP with full feature set
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Try to get utils from environment
local Utils = getfenv()["PouncingUtils"]

-- Fallback inline utils if not available
if not Utils then
    Utils = {}
    function Utils.MakeDrawing(type, props)
        local s, obj = pcall(Drawing.new, type)
        if not s or not obj then return nil end
        for k, v in pairs(props or {}) do pcall(function() obj[k] = v end) end
        return obj
    end
    function Utils.SetDrawing(obj, key, value)
        if obj then pcall(function() obj[key] = value end) end
    end
    function Utils.RemoveDrawing(obj)
        if obj then pcall(function() obj:Remove() end) end
    end
    function Utils.W2S(position)
        local s, x, y, z = pcall(function()
            local v = Camera:WorldToViewportPoint(position)
            return v.X, v.Y, v.Z
        end)
        if s and z and z > 0 then return Vector2.new(x, y), true, z end
        return Vector2.new(-999, -999), false, 0
    end
    function Utils.GetBoxData(character)
        local root = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso")
        if not root then return nil end
        local s, extents = pcall(function() return character:GetExtentsSize() end)
        if not s or not extents then return nil end
        local size = extents * 1.1
        local topPos = root.Position + Vector3.new(0, size.Y / 2, 0)
        local botPos = root.Position - Vector3.new(0, size.Y / 2, 0)
        local topScr, topVis, topZ = Utils.W2S(topPos)
        local botScr, botVis, botZ = Utils.W2S(botPos)
        if (not topVis and not botVis) or topZ <= 0 or botZ <= 0 then return nil end
        local h = math.abs(botScr.Y - topScr.Y)
        local w = h * 0.6
        if h <= 1 or w <= 1 then return nil end
        return {
            TL = Vector2.new(topScr.X - w / 2, topScr.Y),
            BR = Vector2.new(topScr.X + w / 2, botScr.Y),
            Size = Vector2.new(w, h),
            Center = Vector2.new(topScr.X, (topScr.Y + botScr.Y) / 2),
            Pos = root.Position,
            Extents = extents
        }
    end
    function Utils.Get3DCorners(character)
        local root = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso")
        if not root then return nil end
        local s, extents = pcall(function() return character:GetExtentsSize() end)
        if not s or not extents then return nil end
        local p = root.Position
        local hx, hy, hz = extents.X / 2, extents.Y / 2, extents.Z / 2
        local corners = {
            p + Vector3.new(-hx, -hy, -hz), p + Vector3.new(hx, -hy, -hz),
            p + Vector3.new(hx, -hy, hz), p + Vector3.new(-hx, -hy, hz),
            p + Vector3.new(-hx, hy, -hz), p + Vector3.new(hx, hy, -hz),
            p + Vector3.new(hx, hy, hz), p + Vector3.new(-hx, hy, hz)
        }
        local screenCorners = {}
        for i = 1, 8 do
            local sp, vis, z = Utils.W2S(corners[i])
            if not vis or z <= 0 then return nil end
            screenCorners[i] = sp
        end
        return screenCorners
    end
    Utils.Box3DEdges = {
        {1,2},{2,3},{3,4},{4,1},{5,6},{6,7},{7,8},{8,5},{1,5},{2,6},{3,7},{4,8}
    }
    Utils.SkeletonConnections = {
        {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
        {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
        {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
        {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
        {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
        {"Torso", "Left Arm"}, {"Torso", "Right Arm"}, {"Torso", "Left Leg"}, {"Torso", "Right Leg"}, {"Torso", "Head"}
    }
end

-- ============================================================
-- Module Config
-- ============================================================

local ESP = {
    Enabled = false,
    Boxes = false,
    Box3D = false,
    Names = false,
    Distance = false,
    Health = false,
    Skeleton = false,
    Chams = false,
    TeamCheck = false,
    MaxDistance = 2000,

    Colors = {
        Box = Color3.fromRGB(255, 105, 180),
        Name = Color3.fromRGB(255, 255, 255),
        Distance = Color3.fromRGB(200, 200, 200),
        Health = Color3.fromRGB(0, 255, 100),
        Skeleton = Color3.fromRGB(255, 255, 255),
        ChamsFill = Color3.fromRGB(255, 105, 180),
        ChamsOutline = Color3.fromRGB(255, 255, 255)
    }
}

-- ============================================================
-- Drawing Objects Storage
-- ============================================================

local DrawingObjects = {}
local RenderConnection = nil
local PlayerAddedConnection = nil
local PlayerRemovingConnection = nil

-- ============================================================
-- Player Drawing Init / Cleanup
-- ============================================================

local function InitPlayer(player)
    if player == LocalPlayer or DrawingObjects[player] then return end

    local skel = {}
    for i = 1, #Utils.SkeletonConnections do
        table.insert(skel, Utils.MakeDrawing("Line", {Visible = false, Thickness = 1.5, Color = ESP.Colors.Skeleton, Transparency = 0.8}))
        table.insert(skel, Utils.MakeDrawing("Line", {Visible = false, Thickness = 3, Color = Color3.fromRGB(0,0,0), Transparency = 0.5}))
    end

    local b3d = {}
    local b3do = {}
    for i = 1, 12 do
        table.insert(b3d, Utils.MakeDrawing("Line", {Visible = false, Thickness = 1.5, Color = ESP.Colors.Box, Transparency = 0.9}))
        table.insert(b3do, Utils.MakeDrawing("Line", {Visible = false, Thickness = 3, Color = Color3.fromRGB(0,0,0), Transparency = 0.5}))
    end

    DrawingObjects[player] = {
        Box = Utils.MakeDrawing("Square", {Visible = false, Thickness = 1.5, Color = ESP.Colors.Box, Transparency = 0.9, Filled = false}),
        BoxO = Utils.MakeDrawing("Square", {Visible = false, Thickness = 3, Color = Color3.fromRGB(0,0,0), Transparency = 0.5, Filled = false}),
        B3D = b3d, B3DO = b3do,
        Name = Utils.MakeDrawing("Text", {Visible = false, Text = player.Name, Size = 13, Center = true, Outline = true, OutlineColor = Color3.fromRGB(0,0,0), Color = ESP.Colors.Name}),
        HB = Utils.MakeDrawing("Square", {Visible = false, Thickness = 1, Filled = true, Color = ESP.Colors.Health}),
        HBO = Utils.MakeDrawing("Square", {Visible = false, Thickness = 1, Filled = true, Color = Color3.fromRGB(0,0,0)}),
        HT = Utils.MakeDrawing("Text", {Visible = false, Text = "100", Size = 11, Center = false, Outline = true, OutlineColor = Color3.fromRGB(0,0,0), Color = Color3.fromRGB(255,255,255)}),
        Skel = skel,
        Dist = Utils.MakeDrawing("Text", {Visible = false, Text = "", Size = 11, Center = true, Outline = true, OutlineColor = Color3.fromRGB(0,0,0), Color = ESP.Colors.Distance})
    }
end

local function ClearPlayer(player)
    if not DrawingObjects[player] then return end
    for k, v in pairs(DrawingObjects[player]) do
        if k == "Skel" or k == "B3D" or k == "B3DO" then
            for _, o in pairs(v) do Utils.RemoveDrawing(o) end
        else
            Utils.RemoveDrawing(v)
        end
    end
    DrawingObjects[player] = nil

    local char = player.Character
    if char then
        local h = char:FindFirstChild("Pouncing_Highlight")
        if h then h:Destroy() end
    end
end

local function HideAll(o)
    Utils.SetDrawing(o.Box, "Visible", false)
    Utils.SetDrawing(o.BoxO, "Visible", false)
    Utils.SetDrawing(o.Name, "Visible", false)
    Utils.SetDrawing(o.Dist, "Visible", false)
    Utils.SetDrawing(o.HB, "Visible", false)
    Utils.SetDrawing(o.HBO, "Visible", false)
    Utils.SetDrawing(o.HT, "Visible", false)
    for _, l in pairs(o.Skel) do Utils.SetDrawing(l, "Visible", false) end
    for _, l in pairs(o.B3D) do Utils.SetDrawing(l, "Visible", false) end
    for _, l in pairs(o.B3DO) do Utils.SetDrawing(l, "Visible", false) end
end

-- ============================================================
-- Per-Player Update
-- ============================================================

local function UpdatePlayer(player)
    if player == LocalPlayer then return end
    local o = DrawingObjects[player]
    if not o then return end

    local char = player.Character
    if not char then HideAll(o) return end

    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")

    if not hum or not root or hum.Health <= 0 then HideAll(o) return end

    if ESP.TeamCheck and LocalPlayer.Team and player.Team == LocalPlayer.Team then HideAll(o) return end

    local dist = (root.Position - Camera.CFrame.Position).Magnitude
    if dist > ESP.MaxDistance then HideAll(o) return end

    local box = Utils.GetBoxData(char)
    if not box then HideAll(o) return end

    -- 2D Box
    if ESP.Boxes and not ESP.Box3D and ESP.Enabled then
        Utils.SetDrawing(o.Box, "Size", box.Size)
        Utils.SetDrawing(o.Box, "Position", box.TL)
        Utils.SetDrawing(o.Box, "Color", ESP.Colors.Box)
        Utils.SetDrawing(o.Box, "Visible", true)
        Utils.SetDrawing(o.BoxO, "Size", box.Size)
        Utils.SetDrawing(o.BoxO, "Position", box.TL)
        Utils.SetDrawing(o.BoxO, "Visible", true)
    else
        Utils.SetDrawing(o.Box, "Visible", false)
        Utils.SetDrawing(o.BoxO, "Visible", false)
    end

    -- 3D Box
    if ESP.Boxes and ESP.Box3D and ESP.Enabled then
        local c = Utils.Get3DCorners(char)
        if c then
            for i, e in ipairs(Utils.Box3DEdges) do
                Utils.SetDrawing(o.B3D[i], "From", c[e[1]])
                Utils.SetDrawing(o.B3D[i], "To", c[e[2]])
                Utils.SetDrawing(o.B3D[i], "Color", ESP.Colors.Box)
                Utils.SetDrawing(o.B3D[i], "Visible", true)
                Utils.SetDrawing(o.B3DO[i], "From", c[e[1]])
                Utils.SetDrawing(o.B3DO[i], "To", c[e[2]])
                Utils.SetDrawing(o.B3DO[i], "Visible", true)
            end
        else
            for _, l in pairs(o.B3D) do Utils.SetDrawing(l, "Visible", false) end
            for _, l in pairs(o.B3DO) do Utils.SetDrawing(l, "Visible", false) end
        end
    else
        for _, l in pairs(o.B3D) do Utils.SetDrawing(l, "Visible", false) end
        for _, l in pairs(o.B3DO) do Utils.SetDrawing(l, "Visible", false) end
    end

    -- Names
    if ESP.Names and ESP.Enabled then
        Utils.SetDrawing(o.Name, "Position", Vector2.new(box.Center.X, box.TL.Y - 16))
        Utils.SetDrawing(o.Name, "Text", player.Name)
        Utils.SetDrawing(o.Name, "Color", ESP.Colors.Name)
        Utils.SetDrawing(o.Name, "Visible", true)
    else
        Utils.SetDrawing(o.Name, "Visible", false)
    end

    -- Distance
    if ESP.Distance and ESP.Enabled then
        Utils.SetDrawing(o.Dist, "Position", Vector2.new(box.Center.X, box.BR.Y + 4))
        Utils.SetDrawing(o.Dist, "Text", math.floor(dist) .. "m")
        Utils.SetDrawing(o.Dist, "Color", ESP.Colors.Distance)
        Utils.SetDrawing(o.Dist, "Visible", true)
    else
        Utils.SetDrawing(o.Dist, "Visible", false)
    end

    -- Health
    if ESP.Health and ESP.Enabled then
        local ok = pcall(function()
            local mh = hum.MaxHealth
            local ch = hum.Health
            if not mh or mh <= 0 or not ch or ch < 0 then
                Utils.SetDrawing(o.HB, "Visible", false)
                Utils.SetDrawing(o.HBO, "Visible", false)
                Utils.SetDrawing(o.HT, "Visible", false)
                return
            end

            local pct = math.clamp(ch / mh, 0, 1)
            local bh = math.max(box.Size.Y * pct, 2)
            local bw = 4

            if box.Size.Y <= 0 then
                Utils.SetDrawing(o.HB, "Visible", false)
                Utils.SetDrawing(o.HBO, "Visible", false)
                Utils.SetDrawing(o.HT, "Visible", false)
                return
            end

            Utils.SetDrawing(o.HBO, "Size", Vector2.new(bw + 2, box.Size.Y + 2))
            Utils.SetDrawing(o.HBO, "Position", Vector2.new(box.TL.X - bw - 6, box.TL.Y - 1))
            Utils.SetDrawing(o.HBO, "Visible", true)

            Utils.SetDrawing(o.HB, "Size", Vector2.new(bw, bh))
            Utils.SetDrawing(o.HB, "Position", Vector2.new(box.TL.X - bw - 5, box.BR.Y - bh))

            local fullColor = ESP.Colors.Health
            local emptyColor = Color3.fromRGB(255, 0, 0)
            local healthColor = emptyColor:Lerp(fullColor, pct)
            Utils.SetDrawing(o.HB, "Color", healthColor)
            Utils.SetDrawing(o.HB, "Visible", true)

            Utils.SetDrawing(o.HT, "Position", Vector2.new(box.TL.X - bw - 28, box.BR.Y - bh - 6))
            Utils.SetDrawing(o.HT, "Text", math.floor(ch))
            Utils.SetDrawing(o.HT, "Visible", true)
        end)
        if not ok then
            Utils.SetDrawing(o.HB, "Visible", false)
            Utils.SetDrawing(o.HBO, "Visible", false)
            Utils.SetDrawing(o.HT, "Visible", false)
        end
    else
        Utils.SetDrawing(o.HB, "Visible", false)
        Utils.SetDrawing(o.HBO, "Visible", false)
        Utils.SetDrawing(o.HT, "Visible", false)
    end

    -- Skeleton
    if ESP.Skeleton and ESP.Enabled then
        local idx = 1
        for _, conn in ipairs(Utils.SkeletonConnections) do
            local p1 = char:FindFirstChild(conn[1])
            local p2 = char:FindFirstChild(conn[2])
            local line = o.Skel[idx]
            local outline = o.Skel[idx + 1]
            idx = idx + 2

            if p1 and p2 and line and outline then
                local s1, v1 = Utils.W2S(p1.Position)
                local s2, v2 = Utils.W2S(p2.Position)
                if v1 and v2 then
                    Utils.SetDrawing(line, "From", s1)
                    Utils.SetDrawing(line, "To", s2)
                    Utils.SetDrawing(line, "Color", ESP.Colors.Skeleton)
                    Utils.SetDrawing(line, "Visible", true)
                    Utils.SetDrawing(outline, "From", s1)
                    Utils.SetDrawing(outline, "To", s2)
                    Utils.SetDrawing(outline, "Visible", true)
                else
                    Utils.SetDrawing(line, "Visible", false)
                    Utils.SetDrawing(outline, "Visible", false)
                end
            else
                if line then Utils.SetDrawing(line, "Visible", false) end
                if outline then Utils.SetDrawing(outline, "Visible", false) end
            end
        end
    else
        for _, l in pairs(o.Skel) do Utils.SetDrawing(l, "Visible", false) end
    end

    -- Chams
    if ESP.Chams and ESP.Enabled then
        local hl = char:FindFirstChild("Pouncing_Highlight")
        if not hl then
            hl = Instance.new("Highlight")
            hl.Name = "Pouncing_Highlight"
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.Parent = char
        end
        hl.FillColor = ESP.Colors.ChamsFill
        hl.OutlineColor = ESP.Colors.ChamsOutline
        hl.FillTransparency = 0.6
        hl.OutlineTransparency = 0.2
        hl.Enabled = true
    else
        local hl = char:FindFirstChild("Pouncing_Highlight")
        if hl then hl.Enabled = false end
    end
end

-- ============================================================
-- Render Loop
-- ============================================================

local function ESPUpdate()
    if not ESP.Enabled then
        for player, o in pairs(DrawingObjects) do
            HideAll(o)
            local c = player.Character
            if c then local h = c:FindFirstChild("Pouncing_Highlight"); if h then h.Enabled = false end end
        end
        return
    end

    for _, p in pairs(Players:GetPlayers()) do
        pcall(function() UpdatePlayer(p) end)
    end
end

-- ============================================================
-- Module Interface
-- ============================================================

local Module = {}

function Module.Init(manager)
    -- Pre-init all current players
    for _, p in pairs(Players:GetPlayers()) do
        InitPlayer(p)
    end

    -- Listen for new players
    PlayerAddedConnection = Players.PlayerAdded:Connect(function(p)
        InitPlayer(p)
        p.CharacterAdded:Connect(function()
            task.wait(0.1)
            if ESP.Chams then
                local hl = Instance.new("Highlight")
                hl.Name = "Pouncing_Highlight"
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.Parent = p.Character
            end
        end)
    end)

    PlayerRemovingConnection = Players.PlayerRemoving:Connect(ClearPlayer)
end

function Module.Enable()
    ESP.Enabled = true
    if not RenderConnection then
        RenderConnection = RunService.RenderStepped:Connect(ESPUpdate)
    end
end

function Module.Disable()
    ESP.Enabled = false
    if RenderConnection then
        RenderConnection:Disconnect()
        RenderConnection = nil
    end
    -- Hide everything
    for player, o in pairs(DrawingObjects) do
        HideAll(o)
        local c = player.Character
        if c then
            local h = c:FindFirstChild("Pouncing_Highlight")
            if h then h.Enabled = false end
        end
    end
end

function Module.SetConfig(key, value)
    if key:sub(1, 6) == "Color_" then
        local colorKey = key:sub(7)
        if ESP.Colors[colorKey] then
            ESP.Colors[colorKey] = value
        end
    elseif key == "MaxDistance" then
        ESP.MaxDistance = value
    elseif key == "TeamCheck" then
        ESP.TeamCheck = value
    elseif ESP[key] ~= nil then
        ESP[key] = value
    end
end

function Module.GetConfig()
    return ESP
end

return Module
'''

with open(f"{output_dir}/modules/esp.lua", "w") as f:
    f.write(module_esp)

print("modules/esp.lua written")
