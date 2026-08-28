-- Pouncing.exe | Game Detector
-- Detects current game and returns appropriate preset
-- ============================================================

local GameDetector = {}

-- Known game PlaceIds
local KnownGames = {
    [286090429] = "Arsenal",           -- Arsenal
    [2788229376] = "Da Hood",          -- Da Hood
    [16033194031] = "Zee Hood",        -- Zee Hood (common copy)
    [7239319209] = "Ohio",             -- Ohio / Da Hood variant
    [12109643] = "Fencing",            -- Fencing
    [142823291] = "Murder Mystery 2",  -- MM2
    [1962086868] = "Tower of Hell",    -- ToH
    [3101667897] = "Legends of Speed", -- LoS
}

function GameDetector.Detect()
    local placeId = game.PlaceId
    local gameName = KnownGames[placeId]

    if gameName then
        return gameName, placeId
    end

    -- Try to detect by game name
    local marketplaceService = game:GetService("MarketplaceService")
    local success, info = pcall(function()
        return marketplaceService:GetProductInfo(placeId)
    end)

    if success and info then
        local name = info.Name or ""
        name = name:lower()

        if name:match("arsenal") then return "Arsenal", placeId end
        if name:match("da hood") then return "Da Hood", placeId end
        if name:match("zee hood") then return "Zee Hood", placeId end
        if name:match("ohio") then return "Da Hood", placeId end
        if name:match("murder") then return "Murder Mystery 2", placeId end
        if name:match("fencing") then return "Fencing", placeId end
    end

    return "Universal", placeId
end

function GameDetector.GetPresetName()
    local name, _ = GameDetector.Detect()
    return name
end

function GameDetector.IsKnownGame()
    local name, _ = GameDetector.Detect()
    return name ~= "Universal"
end

return GameDetector