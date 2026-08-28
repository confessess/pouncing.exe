-- Pouncing.exe | Da Hood / Zee Hood Preset v1.0
-- Optimized for hood games: lock-on aimbot + ESP + hitbox
-- ============================================================

return {
    Configs = {
        Aimbot = {
            Enabled = true,
            SilentAim = false,
            BulletRedirect = false,
            ArsenalMode = false,
            TeamCheck = true,
            WallCheck = true,
            FOV = 80,
            Smoothness = 10,
            MaxDistance = 500,
            TargetPart = "Head",
            Priority = "Closest to Mouse",
            ShowFOV = true,
            Triggerbot = false,
            ToggleMode = false,
            StickyTarget = true,
        },
        ESP = {
            Enabled = true,
            Boxes = true,
            Names = true,
            Health = true,
            TeamCheck = true,
            MaxDistance = 1000,
            BoxThickness = 1,
        },
        Hitbox = {
            Enabled = false,
            TeamCheck = true,
            ShowExpanded = true,
            HitboxSize = 5,
            TargetParts = "Head",
            Transparency = 0.85,
            MaxDistance = 2000,
            UpdateRate = 2,
            Comprehensive = false,
            VisualStyle = "Transparent",
            VisualColor = Color3.fromRGB(255, 105, 180),
        },
        DaHoodExtras = {
            Enabled = false,
            KnockCheck = true,
            HPDisplay = true,
            AutoStomp = false,
            AutoDrop = false,
            StompRange = 8,
            DropAmount = 500,
        },
    }
}