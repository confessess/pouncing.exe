-- Pouncing.exe | Universal Game Preset
-- Default fallback for any game not specifically configured
-- ============================================================

local UniversalPreset = {
    Name = "Universal",
    PlaceId = 0, -- matches any

    Configs = {
        Aimbot = {
            Enabled = false,
            SilentAim = false,
            Triggerbot = false,
            TeamCheck = false,
            WallCheck = false,
            FOV = 60,
            Smoothness = 15,
            MaxDistance = 1000,
            TargetPart = "Head",
            Priority = "Closest to Mouse",
            HitChance = 100,
            SnapDuration = 2,
        },
        ESP = {
            Enabled = false,
            Boxes = false,
            Names = false,
            Health = false,
            TeamCheck = false,
            MaxDistance = 2000,
        },
        Gun = {
            Enabled = false,
            AutoFire = false,
            NoRecoil = false,
            NoSpread = false,
            RapidFire = false,
            FireRate = 2,
        },
        Hitbox = {
            Enabled = false,
            TeamCheck = false,
            HitboxSize = 5,
            TargetParts = "Head",
            MaxDistance = 2000,
            ShowExpanded = true,
        },
        Misc = {
            Enabled = false,
            SpeedHack = false,
            WalkSpeed = 50,
            Fly = false,
            FlySpeed = 50,
            BunnyHop = false,
            AntiAim = false,
        },
    },

    ExtraModules = {},

    TabOrder = {"Aimbot", "ESP", "Gun", "Hitbox", "Misc", "Settings"},

    Description = "Default preset for unsupported games. Adjust settings manually.",
}

return UniversalPreset