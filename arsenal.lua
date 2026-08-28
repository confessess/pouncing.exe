-- Pouncing.exe | Arsenal Game Preset
-- Optimized configs and modules for Arsenal (PlaceId: 286090429)
-- ============================================================

local ArsenalPreset = {
    Name = "Arsenal",
    PlaceId = 286090429,

    -- Module configs optimized for Arsenal
    Configs = {
        Aimbot = {
            Enabled = false,
            SilentAim = true,
            Triggerbot = false,
            TeamCheck = false,
            WallCheck = false,
            FOV = 50,
            Smoothness = 10,
            MaxDistance = 800,
            TargetPart = "Head",
            Priority = "Closest to Mouse",
            HitChance = 100,
            SnapDuration = 3,
            ArsenalMode = true,
        },
        ESP = {
            Enabled = false,
            Boxes = true,
            Names = true,
            Health = true,
            TeamCheck = false,
            MaxDistance = 1500,
        },
        Gun = {
            Enabled = false,
            NoRecoil = true,
            NoSpread = true,
            RapidFire = true,
            FireRate = 3,
        },
        Hitbox = {
            Enabled = false,
            TeamCheck = false,
            HitboxSize = 3,
            TargetParts = "Head",
            MaxDistance = 1000,
            ShowExpanded = true,
        },
        Misc = {
            Enabled = false,
            SpeedHack = false,
            WalkSpeed = 35,
            Fly = false,
            FlySpeed = 50,
        },
    },

    -- Arsenal-specific modules (loaded in addition to universal)
    ExtraModules = {
        -- "arsenal_esp" = custom ESP for Arsenal's unique character system
        -- "auto_vote" = auto vote for maps
    },

    -- Tab order / visibility
    TabOrder = {"Aimbot", "ESP", "Gun", "Hitbox", "Misc", "Settings"},

    Description = "Server-authoritative FPS. Silent Aim uses Camera Snap. Hitbox limited to Head only.",
}

return ArsenalPreset