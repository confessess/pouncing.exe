-- Pouncing.exe | Arsenal Preset v1.0
-- Optimized for Arsenal: bullet redirect silent aim + hitbox expand
-- ============================================================

return {
    Configs = {
        Aimbot = {
            Enabled = true,
            SilentAim = true,
            BulletRedirect = true,
            ArsenalMode = true,
            ArsenalHitboxExpand = true,
            ArsenalHitboxSize = 13,
            TeamCheck = true,
            WallCheck = false,
            FOV = 60,
            MaxDistance = 1000,
            TargetPart = "Head",
            Priority = "Closest to Mouse",
            HitChance = 100,
            ShowFOV = true,
            Triggerbot = false,
            ToggleMode = false,
            StickyTarget = false,
        },
        ESP = {
            Enabled = true,
            Boxes = true,
            Names = true,
            Health = true,
            TeamCheck = true,
            MaxDistance = 1500,
            BoxThickness = 1,
        },
        Gun = {
            Enabled = true,
            NoRecoil = true,
            NoSpread = true,
            RapidFire = false,
            AutoFire = false,
            FireRate = 2,
            DamageMult = 1,
            RecoilReduction = 100,
        },
    }
}