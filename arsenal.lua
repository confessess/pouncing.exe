-- Pouncing.exe | Arsenal Preset v1.2
-- Silent Aim = Bullet Redirect. No separate flag needed.
-- ============================================================

return {
    Configs = {
        Aimbot = {
            Enabled = true,
            SilentAim = true,           -- this IS bullet redirect now
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