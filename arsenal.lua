-- Pouncing.exe | Arsenal Preset
-- Auto-configures modules for Arsenal gameplay
-- ============================================================

return {
    Configs = {
        Aimbot = {
            Enabled = true,
            SilentAim = true,
            ArsenalMode = true,
            TeamCheck = true,
            WallCheck = false,
            FOV = 80,
            MaxDistance = 1500,
            HitChance = 100,
            TargetPart = "Head",
            Priority = "Closest to Mouse",
            ArsenalHitboxExpand = true,
            ArsenalHitboxSize = 15,
            ShowFOV = true,
            DebugMode = false,
        },
        Gun = {
            Enabled = true,
            ArsenalMode = true,
            NoRecoil = true,
            NoSpread = true,
            RapidFire = true,
            FireRate = 80,
            AlwaysHeadshot = true,
            InstantReload = true,
            InfiniteAmmo = true,
            AutoFire = false,
        },
        ESP = {
            Enabled = true,
            Boxes = true,
            Names = true,
            Health = true,
            TeamCheck = true,
            MaxDistance = 2000,
        },
        Misc = {
            Enabled = false,
        },
    }
}