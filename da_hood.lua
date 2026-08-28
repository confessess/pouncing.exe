-- Pouncing.exe | Da Hood Game Preset
-- Optimized configs and modules for Da Hood (PlaceId: 2788229376)
-- ============================================================

local DaHoodPreset = {
    Name = "Da Hood",
    PlaceId = 2788229376,

    -- Module configs optimized for Da Hood
    Configs = {
        Aimbot = {
            Enabled = false,
            SilentAim = true,
            Triggerbot = false,
            TeamCheck = false,
            WallCheck = false,
            FOV = 80,
            Smoothness = 20,
            MaxDistance = 1200,
            TargetPart = "Head",
            Priority = "Closest to Mouse",
            HitChance = 100,
            SnapDuration = 2,
        },
        ESP = {
            Enabled = false,
            Boxes = true,
            Names = true,
            Health = true,
            WeaponNames = true,
            TeamCheck = false,
            MaxDistance = 2000,
        },
        Gun = {
            Enabled = false,
            AutoFire = true,
            NoRecoil = true,
            NoSpread = true,
            RapidFire = true,
            FireRate = 5,
        },
        Hitbox = {
            Enabled = false,
            TeamCheck = false,
            HitboxSize = 5,
            TargetParts = "Head + HRP",
            MaxDistance = 2000,
            ShowExpanded = true,
        },
        Misc = {
            Enabled = false,
            SpeedHack = true,
            WalkSpeed = 80,
            Fly = true,
            FlySpeed = 100,
            BunnyHop = false,
            AntiAim = false,
        },
    },

    -- Da Hood-specific modules
    ExtraModules = {
        -- "knock_check" = shows who's knocked/down
        -- "hp_checker" = displays player health above heads
        -- "auto_stomp" = auto stomp downed players
        -- "auto_drop" = auto drop cash
    },

    TabOrder = {"Aimbot", "ESP", "Gun", "Hitbox", "Misc", "Settings"},

    Description = "Street RP with client-trusted hit detection. Hitbox expander works well. Silent Aim via Mouse.Hit.",
}

return DaHoodPreset