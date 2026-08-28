-- Pouncing.exe | Universal Preset v1.0
-- Safe defaults for any game
-- ============================================================

return {
    Configs = {
        Aimbot = {
            Enabled = false,
            SilentAim = false,
            BulletRedirect = false,
            ArsenalMode = false,
            ArsenalHitboxExpand = false,
            TeamCheck = true,
            WallCheck = true,
            FOV = 60,
            Smoothness = 15,
            MaxDistance = 1000,
            TargetPart = "Head",
            Priority = "Closest to Mouse",
            ShowFOV = true,
            Triggerbot = false,
        },
        ESP = {
            Enabled = false,
            TeamCheck = true,
            MaxDistance = 1500,
            BoxThickness = 1,
        },
        Misc = {
            Enabled = false,
            WalkSpeed = 50,
            JumpPower = 100,
            FlySpeed = 50,
            FlyMethod = "Tween",
        },
    }
}