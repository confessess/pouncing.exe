-- Pouncing.exe | Hitbox Expander Module v1.0
-- Expand player hitboxes for easier targeting
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local Config = {
    Enabled = false, TeamCheck = false, ShowExpanded = true,
    HeadSize = 5, TorsoSize = 3, Transparency = 0.9,
    OriginalSizes = {}, ExpandedParts = {}
}

local function IsTeammate(player)
    if not LocalPlayer.Team or not player.Team then return false end
    return player.Team == LocalPlayer.Team
end

local function ExpandHitbox(character)
    if not character then return end
    local head = character:FindFirstChild("Head")
    if head and head:IsA("BasePart") then
        if not Config.OriginalSizes[head] then Config.OriginalSizes[head] = head.Size end
        local newSize = Vector3.new(Config.HeadSize, Config.HeadSize, Config.HeadSize)
        head.Size = newSize
        if Config.ShowExpanded then
            head.Transparency = Config.Transparency
            head.Material = Enum.Material.Neon
            head.Color = Color3.fromRGB(255, 105, 180)
        end
    end
    local torsoNames = {"UpperTorso", "LowerTorso", "Torso", "HumanoidRootPart"}
    for _, name in ipairs(torsoNames) do
        local part = character:FindFirstChild(name)
        if part and part:IsA("BasePart") then
            if not Config.OriginalSizes[part] then Config.OriginalSizes[part] = part.Size end
            local newSize = Vector3.new(Config.TorsoSize, Config.TorsoSize, Config.TorsoSize)
            part.Size = newSize
            if Config.ShowExpanded then
                part.Transparency = Config.Transparency
                part.Material = Enum.Material.Neon
                part.Color = Color3.fromRGB(255, 20, 147)
            end
        end
    end
end

local function RestoreHitbox(character)
    if not character then return end
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") and Config.OriginalSizes[part] then
            part.Size = Config.OriginalSizes[part]
            part.Transparency = 0
            part.Material = Enum.Material.Plastic
            part.Color = Color3.fromRGB(163, 162, 165)
        end
    end
end

local function UpdatePlayer(player)
    if player == LocalPlayer then return end
    if Config.TeamCheck and IsTeammate(player) then return end
    local character = player.Character
    if not character then return end
    local hum = character:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end
    ExpandHitbox(character)
end

local function UpdateAll()
    if not Config.Enabled then return end
    for _, player in pairs(Players:GetPlayers()) do
        pcall(function() UpdatePlayer(player) end)
    end
end

local RenderConnection = nil

local Module = {}

function Module.Init(manager)
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(char)
            if Config.Enabled then task.wait(0.5); pcall(function() UpdatePlayer(player) end) end
        end)
    end)
    for _, player in pairs(Players:GetPlayers()) do
        if player.Character then
            player.CharacterAdded:Connect(function(char)
                if Config.Enabled then task.wait(0.5); pcall(function() UpdatePlayer(player) end) end
            end)
        end
    end
end

function Module.Enable()
    Config.Enabled = true
    UpdateAll()
    if not RenderConnection then RenderConnection = RunService.RenderStepped:Connect(UpdateAll) end
end

function Module.Disable()
    Config.Enabled = false
    if RenderConnection then RenderConnection:Disconnect(); RenderConnection = nil end
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then pcall(function() RestoreHitbox(player.Character) end) end
    end
    Config.OriginalSizes = {}
end

function Module.SetConfig(key, value)
    if key == "TeamCheck" then Config.TeamCheck = value; if Config.Enabled then UpdateAll() end
    elseif key == "ShowExpanded" then Config.ShowExpanded = value; if Config.Enabled then UpdateAll() end
    elseif key == "HeadSize" then Config.HeadSize = value; if Config.Enabled then UpdateAll() end
    elseif key == "TorsoSize" then Config.TorsoSize = value; if Config.Enabled then UpdateAll() end
    elseif key == "Transparency" then Config.Transparency = value; if Config.Enabled then UpdateAll() end
    end
end

function Module.GetConfig() return Config end

function Module.ResetConfig()
    Config.Enabled = false; Config.TeamCheck = false; Config.ShowExpanded = true
    Config.HeadSize = 5; Config.TorsoSize = 3; Config.Transparency = 0.9; Config.OriginalSizes = {}
end

return Module