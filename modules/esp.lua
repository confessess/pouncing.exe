-- Pouncing.exe | ESP Module v6.3
-- FIXED: GetBoxData height calc (was botScr.Y - botScr.Y = 0), improved character handling
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

local ESP = {
    Enabled = false,
    Boxes = false,
    Box3D = false,
    Tracers = false,
    Names = false,
    Health = false,
    Distance = false,
    Chams = false,
    Skeleton = false,
    TeamCheck = false,
    MaxDistance = 1000,
    BoxColor = Color3.fromRGB(255, 80, 160),
    TracerColor = Color3.fromRGB(255, 80, 160),
    NameColor = Color3.fromRGB(255, 255, 255),
    HealthColor = Color3.fromRGB(0, 255, 100),
    DistanceColor = Color3.fromRGB(200, 200, 200),
    SkeletonColor = Color3.fromRGB(255, 80, 160),
    BoxThickness = 1,
    TracerThickness = 1,
    SkeletonThickness = 1,
    TextSize = 13,
    Font = Drawing.Fonts.Plex,
    TracerOrigin = "Bottom",
    BoxFilled = false,
    BoxFillTransparency = 0.7,
    ShowTeam = false,
    ShowLocalPlayer = false,
    HighlightFillColor = Color3.fromRGB(255, 80, 160),
    HighlightOutlineColor = Color3.fromRGB(255, 255, 255),
    HighlightFillTransparency = 0.5,
    HighlightOutlineTransparency = 0,
}

local PlayerObjects = {}
local PlayerAddedConnection = nil
local PlayerRemovingConnection = nil
local RenderConnection = nil

local Utils = nil
local function GetUtils()
    if Utils then return Utils end
    local success, result = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/confessess/pouncing.exe/main/utils/core.lua"))()
    end)
    if success and result then
        Utils = result
        return Utils
    end
    return nil
end

if not Utils then
    Utils = GetUtils()
end

if not Utils then
    Utils = {}
    function Utils.GetCharacter(player)
        return player and player.Character
    end
    function Utils.GetHumanoid(character)
        if not character then return nil end
        return character:FindFirstChildOfClass("Humanoid")
    end
    function Utils.GetRootPart(character)
        if not character then return nil end
        return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso")
    end
    function Utils.GetHead(character)
        if not character then return nil end
        return character:FindFirstChild("Head")
    end
    function Utils.IsAlive(character)
        if not character then return false end
        local humanoid = Utils.GetHumanoid(character)
        return humanoid and humanoid.Health > 0
    end
    function Utils.GetDistance(pos1, pos2)
        if not pos1 or not pos2 then return math.huge end
        return (pos1 - pos2).Magnitude
    end
    function Utils.WorldToScreen(position)
        local pos, onScreen = Camera:WorldToViewportPoint(position)
        return Vector2.new(pos.X, pos.Y), onScreen, pos.Z
    end
    function Utils.GetBoxData(character)
        if not character then return nil end
        local head = Utils.GetHead(character)
        local root = Utils.GetRootPart(character)
        if not head or not root then return nil end
        local headPos, headOnScreen = Camera:WorldToViewportPoint(head.Position)
        local rootPos, rootOnScreen = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
        if not headOnScreen and not rootOnScreen then return nil end
        local topScr = Vector2.new(headPos.X, headPos.Y)
        local botScr = Vector2.new(rootPos.X, rootPos.Y)
        local h = math.abs(botScr.Y - topScr.Y)  -- FIXED: was botScr.Y - botScr.Y (always 0)
        local w = h * 0.55
        if h <= 1 then return nil end
        return {
            TopLeft = Vector2.new(topScr.X - w / 2, topScr.Y),
            TopRight = Vector2.new(topScr.X + w / 2, topScr.Y),
            BottomLeft = Vector2.new(botScr.X - w / 2, botScr.Y),
            BottomRight = Vector2.new(botScr.X + w / 2, botScr.Y),
            Center = Vector2.new(topScr.X, (topScr.Y + botScr.Y) / 2),
            Size = Vector2.new(w, h),
            HeadPos = topScr,
            RootPos = botScr,
            OnScreen = headOnScreen or rootOnScreen,
        }
    end
    function Utils.Get3DCorners(character)
        if not character then return nil end
        local root = Utils.GetRootPart(character)
        if not root then return nil end
        local size = character:GetExtentsSize()
        local cf = root.CFrame
        local corners = {}
        for x = -1, 1, 2 do
            for y = -1, 1, 2 do
                for z = -1, 1, 2 do
                    local corner = cf * CFrame.new(size.X / 2 * x, size.Y / 2 * y, size.Z / 2 * z)
                    local pos, onScreen = Camera:WorldToViewportPoint(corner.Position)
                    table.insert(corners, {Position = Vector2.new(pos.X, pos.Y), OnScreen = onScreen, Depth = pos.Z})
                end
            end
        end
        return corners
    end
    function Utils.IsTeammate(player)
        local LocalPlayer = Players.LocalPlayer
        return player.Team == LocalPlayer.Team
    end
    function Utils.GetHealth(character)
        local humanoid = Utils.GetHumanoid(character)
        if humanoid then
            return humanoid.Health, humanoid.MaxHealth
        end
        return 0, 100
    end
end

local LocalPlayer = Players.LocalPlayer

local function CreateDrawing(type, properties)
    local drawing = Drawing.new(type)
    for property, value in pairs(properties) do
        drawing[property] = value
    end
    return drawing
end

local function RemovePlayerObjects(player)
    local objects = PlayerObjects[player]
    if not objects then return end
    for _, obj in pairs(objects) do
        if typeof(obj) == "table" then
            for _, subObj in pairs(obj) do
                if subObj and subObj.Remove then
                    pcall(function() subObj:Remove() end)
                end
            end
        elseif obj and obj.Remove then
            pcall(function() obj:Remove() end)
        end
    end
    PlayerObjects[player] = nil
end

local function CreatePlayerObjects(player)
    if PlayerObjects[player] then return end
    PlayerObjects[player] = {
        Box = CreateDrawing("Square", {
            Visible = false,
            Thickness = ESP.BoxThickness,
            Color = ESP.BoxColor,
            Filled = ESP.BoxFilled,
            Transparency = ESP.BoxFillTransparency,
            ZIndex = 1,
        }),
        BoxOutline = CreateDrawing("Square", {
            Visible = false,
            Thickness = ESP.BoxThickness + 2,
            Color = Color3.fromRGB(0, 0, 0),
            Filled = false,
            Transparency = 1,
            ZIndex = 0,
        }),
        Tracer = CreateDrawing("Line", {
            Visible = false,
            Thickness = ESP.TracerThickness,
            Color = ESP.TracerColor,
            ZIndex = 1,
        }),
        TracerOutline = CreateDrawing("Line", {
            Visible = false,
            Thickness = ESP.TracerThickness + 2,
            Color = Color3.fromRGB(0, 0, 0),
            ZIndex = 0,
        }),
        Name = CreateDrawing("Text", {
            Visible = false,
            Text = player.Name,
            Size = ESP.TextSize,
            Font = ESP.Font,
            Color = ESP.NameColor,
            Outline = true,
            OutlineColor = Color3.fromRGB(0, 0, 0),
            Center = true,
            ZIndex = 2,
        }),
        Health = CreateDrawing("Text", {
            Visible = false,
            Text = "100",
            Size = ESP.TextSize - 2,
            Font = ESP.Font,
            Color = ESP.HealthColor,
            Outline = true,
            OutlineColor = Color3.fromRGB(0, 0, 0),
            Center = true,
            ZIndex = 2,
        }),
        Distance = CreateDrawing("Text", {
            Visible = false,
            Text = "0m",
            Size = ESP.TextSize - 2,
            Font = ESP.Font,
            Color = ESP.DistanceColor,
            Outline = true,
            OutlineColor = Color3.fromRGB(0, 0, 0),
            Center = true,
            ZIndex = 2,
        }),
        Box3D = {},
        Skeleton = {},
        Chams = nil,
    }
end

local function UpdatePlayer(player)
    if not ESP.Enabled then return end
    if player == LocalPlayer and not ESP.ShowLocalPlayer then return end
    local objects = PlayerObjects[player]
    if not objects then return end
    local character = Utils.GetCharacter(player)
    if not character then
        for _, obj in pairs(objects) do
            if typeof(obj) == "table" then
                for _, subObj in pairs(obj) do
                    if subObj and subObj.Visible ~= nil then subObj.Visible = false end
                end
            elseif obj and obj.Visible ~= nil then
                obj.Visible = false
            end
        end
        return
    end
    if not Utils.IsAlive(character) then
        for _, obj in pairs(objects) do
            if typeof(obj) == "table" then
                for _, subObj in pairs(obj) do
                    if subObj and subObj.Visible ~= nil then subObj.Visible = false end
                end
            elseif obj and obj.Visible ~= nil then
                obj.Visible = false
            end
        end
        return
    end
    if ESP.TeamCheck and Utils.IsTeammate(player) then
        for _, obj in pairs(objects) do
            if typeof(obj) == "table" then
                for _, subObj in pairs(obj) do
                    if subObj and subObj.Visible ~= nil then subObj.Visible = false end
                end
            elseif obj and obj.Visible ~= nil then
                obj.Visible = false
            end
        end
        return
    end
    local root = Utils.GetRootPart(character)
    if not root then return end
    local distance = Utils.GetDistance(LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position or Vector3.new(), root.Position)
    if distance > ESP.MaxDistance then
        for _, obj in pairs(objects) do
            if typeof(obj) == "table" then
                for _, subObj in pairs(obj) do
                    if subObj and subObj.Visible ~= nil then subObj.Visible = false end
                end
            elseif obj and obj.Visible ~= nil then
                obj.Visible = false
            end
        end
        return
    end
    local boxData = Utils.GetBoxData(character)
    if not boxData then
        for _, obj in pairs(objects) do
            if typeof(obj) == "table" then
                for _, subObj in pairs(obj) do
                    if subObj and subObj.Visible ~= nil then subObj.Visible = false end
                end
            elseif obj and obj.Visible ~= nil then
                obj.Visible = false
            end
        end
        return
    end
    local color = ESP.BoxColor
    if player.Team then
        color = player.TeamColor.Color
    end
    if ESP.Boxes and not ESP.Box3D then
        objects.Box.Visible = true
        objects.BoxOutline.Visible = true
        objects.Box.Size = boxData.Size
        objects.Box.Position = boxData.TopLeft
        objects.Box.Color = color
        objects.Box.Thickness = ESP.BoxThickness
        objects.Box.Filled = ESP.BoxFilled
        objects.Box.Transparency = ESP.BoxFillTransparency
        objects.BoxOutline.Size = boxData.Size
        objects.BoxOutline.Position = boxData.TopLeft
        objects.BoxOutline.Thickness = ESP.BoxThickness + 2
    else
        objects.Box.Visible = false
        objects.BoxOutline.Visible = false
    end
    if ESP.Tracers then
        objects.Tracer.Visible = true
        objects.TracerOutline.Visible = true
        objects.Tracer.Color = ESP.TracerColor
        objects.Tracer.Thickness = ESP.TracerThickness
        local tracerStart = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
        if ESP.TracerOrigin == "Top" then
            tracerStart = Vector2.new(Camera.ViewportSize.X / 2, 0)
        elseif ESP.TracerOrigin == "Center" then
            tracerStart = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        elseif ESP.TracerOrigin == "Mouse" then
            tracerStart = game:GetService("UserInputService"):GetMouseLocation()
        end
        objects.Tracer.From = tracerStart
        objects.Tracer.To = boxData.Center
        objects.TracerOutline.From = tracerStart
        objects.TracerOutline.To = boxData.Center
        objects.TracerOutline.Thickness = ESP.TracerThickness + 2
    else
        objects.Tracer.Visible = false
        objects.TracerOutline.Visible = false
    end
    if ESP.Names then
        objects.Name.Visible = true
        objects.Name.Text = player.Name
        objects.Name.Size = ESP.TextSize
        objects.Name.Color = ESP.NameColor
        objects.Name.Position = Vector2.new(boxData.Center.X, boxData.TopLeft.Y - 18)
    else
        objects.Name.Visible = false
    end
    if ESP.Health then
        local health, maxHealth = Utils.GetHealth(character)
        local healthPercent = math.clamp(health / maxHealth, 0, 1)
        objects.Health.Visible = true
        objects.Health.Text = string.format("%.0f%%", healthPercent * 100)
        objects.Health.Size = ESP.TextSize - 2
        objects.Health.Color = ESP.HealthColor
        objects.Health.Position = Vector2.new(boxData.Center.X, boxData.BottomLeft.Y + 4)
    else
        objects.Health.Visible = false
    end
    if ESP.Distance then
        objects.Distance.Visible = true
        objects.Distance.Text = string.format("%.0fm", distance)
        objects.Distance.Size = ESP.TextSize - 2
        objects.Distance.Color = ESP.DistanceColor
        objects.Distance.Position = Vector2.new(boxData.Center.X, boxData.BottomLeft.Y + (ESP.Health and 18 or 4))
    else
        objects.Distance.Visible = false
    end
    if ESP.Box3D then
        local corners = Utils.Get3DCorners(character)
        if corners then
            local edges = {
                {1, 2}, {2, 4}, {4, 3}, {3, 1},
                {5, 6}, {6, 8}, {8, 7}, {7, 5},
                {1, 5}, {2, 6}, {3, 7}, {4, 8}
            }
            for i, edge in ipairs(edges) do
                local line = objects.Box3D[i]
                if not line then
                    line = CreateDrawing("Line", {
                        Visible = false,
                        Thickness = ESP.BoxThickness,
                        Color = color,
                        ZIndex = 1,
                    })
                    objects.Box3D[i] = line
                end
                local corner1 = corners[edge[1]]
                local corner2 = corners[edge[2]]
                if corner1 and corner2 and corner1.OnScreen and corner2.OnScreen then
                    line.Visible = true
                    line.From = corner1.Position
                    line.To = corner2.Position
                    line.Color = color
                    line.Thickness = ESP.BoxThickness
                else
                    line.Visible = false
                end
            end
            for i = #edges + 1, #objects.Box3D do
                if objects.Box3D[i] then
                    objects.Box3D[i].Visible = false
                end
            end
        end
    else
        for _, line in pairs(objects.Box3D) do
            if line then line.Visible = false end
        end
    end
    if ESP.Skeleton then
        local skeletonParts = {
            {"Head", "UpperTorso"},
            {"UpperTorso", "LowerTorso"},
            {"UpperTorso", "LeftUpperArm"},
            {"LeftUpperArm", "LeftLowerArm"},
            {"LeftLowerArm", "LeftHand"},
            {"UpperTorso", "RightUpperArm"},
            {"RightUpperArm", "RightLowerArm"},
            {"RightLowerArm", "RightHand"},
            {"LowerTorso", "LeftUpperLeg"},
            {"LeftUpperLeg", "LeftLowerLeg"},
            {"LeftLowerLeg", "LeftFoot"},
            {"LowerTorso", "RightUpperLeg"},
            {"RightUpperLeg", "RightLowerLeg"},
            {"RightLowerLeg", "RightFoot"},
        }
        local rigType = "R15"
        local humanoid = Utils.GetHumanoid(character)
        if humanoid then
            rigType = tostring(humanoid.RigType)
        end
        if rigType == "Enum.HumanoidRigType.R6" then
            skeletonParts = {
                {"Head", "Torso"},
                {"Torso", "Left Arm"},
                {"Left Arm", "Left Leg"},
                {"Torso", "Right Arm"},
                {"Right Arm", "Right Leg"},
                {"Torso", "Left Leg"},
                {"Torso", "Right Leg"},
            }
        end
        for i, partPair in ipairs(skeletonParts) do
            local line = objects.Skeleton[i]
            if not line then
                line = CreateDrawing("Line", {
                    Visible = false,
                    Thickness = ESP.SkeletonThickness,
                    Color = ESP.SkeletonColor,
                    ZIndex = 1,
                })
                objects.Skeleton[i] = line
            end
            local part1 = character:FindFirstChild(partPair[1])
            local part2 = character:FindFirstChild(partPair[2])
            if part1 and part2 then
                local pos1, onScreen1 = Camera:WorldToViewportPoint(part1.Position)
                local pos2, onScreen2 = Camera:WorldToViewportPoint(part2.Position)
                if onScreen1 and onScreen2 then
                    line.Visible = true
                    line.From = Vector2.new(pos1.X, pos1.Y)
                    line.To = Vector2.new(pos2.X, pos2.Y)
                    line.Color = ESP.SkeletonColor
                    line.Thickness = ESP.SkeletonThickness
                else
                    line.Visible = false
                end
            else
                line.Visible = false
            end
        end
        for i = #skeletonParts + 1, #objects.Skeleton do
            if objects.Skeleton[i] then
                objects.Skeleton[i].Visible = false
            end
        end
    else
        for _, line in pairs(objects.Skeleton) do
            if line then line.Visible = false end
        end
    end
    if ESP.Chams then
        if not objects.Chams or not objects.Chams.Parent then
            objects.Chams = Instance.new("Highlight")
            objects.Chams.Name = "Pouncing_ESP_Highlight"
            objects.Chams.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            objects.Chams.FillColor = ESP.HighlightFillColor
            objects.Chams.OutlineColor = ESP.HighlightOutlineColor
            objects.Chams.FillTransparency = ESP.HighlightFillTransparency
            objects.Chams.OutlineTransparency = ESP.HighlightOutlineTransparency
            objects.Chams.Parent = character
        end
        objects.Chams.Enabled = true
        objects.Chams.FillColor = ESP.HighlightFillColor
        objects.Chams.OutlineColor = ESP.HighlightOutlineColor
        objects.Chams.FillTransparency = ESP.HighlightFillTransparency
        objects.Chams.OutlineTransparency = ESP.HighlightOutlineTransparency
    else
        if objects.Chams then
            objects.Chams.Enabled = false
        end
    end
end

local function ClearPlayer(player)
    RemovePlayerObjects(player)
end

local function InitPlayer(player)
    if player == LocalPlayer and not ESP.ShowLocalPlayer then return end
    CreatePlayerObjects(player)
    player.CharacterAdded:Connect(function(char)
        task.wait(0.1)
        if ESP.Chams then
            local objects = PlayerObjects[player]
            if objects then
                if objects.Chams then
                    pcall(function() objects.Chams:Destroy() end)
                end
                objects.Chams = Instance.new("Highlight")
                objects.Chams.Name = "Pouncing_ESP_Highlight"
                objects.Chams.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                objects.Chams.FillColor = ESP.HighlightFillColor
                objects.Chams.OutlineColor = ESP.HighlightOutlineColor
                objects.Chams.FillTransparency = ESP.HighlightFillTransparency
                objects.Chams.OutlineTransparency = ESP.HighlightOutlineTransparency
                objects.Chams.Parent = char
            end
        end
    end)
end

local Module = {}
Module.Name = "ESP"
Module.Description = "Extra Sensory Perception - See players through walls"
Module.Category = "Visual"
Module.Version = "6.3"
Module.Author = "Pouncing.exe"

function Module.Init(manager)
    for _, p in pairs(Players:GetPlayers()) do
        InitPlayer(p)
    end
    PlayerAddedConnection = Players.PlayerAdded:Connect(function(p)
        InitPlayer(p)
    end)
    PlayerRemovingConnection = Players.PlayerRemoving:Connect(ClearPlayer)
    RenderConnection = RunService.RenderStepped:Connect(function()
        if not ESP.Enabled then
            for _, objects in pairs(PlayerObjects) do
                for _, obj in pairs(objects) do
                    if typeof(obj) == "table" then
                        for _, subObj in pairs(obj) do
                            if subObj and subObj.Visible ~= nil then subObj.Visible = false end
                        end
                    elseif obj and obj.Visible ~= nil then
                        obj.Visible = false
                    elseif obj and typeof(obj) == "Instance" and obj:IsA("Highlight") then
                        obj.Enabled = false
                    end
                end
            end
            return
        end
        for _, player in ipairs(Players:GetPlayers()) do
            pcall(function() UpdatePlayer(player) end)
        end
    end)
end

function Module.Enable()
    ESP.Enabled = true
    print("[Pouncing] ESP Enabled")
end

function Module.Disable()
    ESP.Enabled = false
    for _, objects in pairs(PlayerObjects) do
        for _, obj in pairs(objects) do
            if typeof(obj) == "table" then
                for _, subObj in pairs(obj) do
                    if subObj and subObj.Visible ~= nil then subObj.Visible = false end
                end
            elseif obj and obj.Visible ~= nil then
                obj.Visible = false
            elseif obj and typeof(obj) == "Instance" and obj:IsA("Highlight") then
                obj.Enabled = false
            end
        end
    end
    print("[Pouncing] ESP Disabled")
end

function Module.Toggle()
    if ESP.Enabled then
        Module.Disable()
    else
        Module.Enable()
    end
end

function Module.SetOption(option, value)
    if ESP[option] ~= nil then
        ESP[option] = value
        print("[Pouncing] ESP option '" .. tostring(option) .. "' set to: " .. tostring(value))
    else
        warn("[Pouncing] Unknown ESP option: " .. tostring(option))
    end
end

function Module.GetOption(option)
    return ESP[option]
end

function Module.GetState()
    return ESP.Enabled
end

function Module.Cleanup()
    if RenderConnection then
        RenderConnection:Disconnect()
        RenderConnection = nil
    end
    if PlayerAddedConnection then
        PlayerAddedConnection:Disconnect()
        PlayerAddedConnection = nil
    end
    if PlayerRemovingConnection then
        PlayerRemovingConnection:Disconnect()
        PlayerRemovingConnection = nil
    end
    for player, _ in pairs(PlayerObjects) do
        ClearPlayer(player)
    end
    PlayerObjects = {}
end

return Module