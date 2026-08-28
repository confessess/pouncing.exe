
# ============================================================
# 9. README.md - Setup Instructions
# ============================================================
# 🐾 Pouncing.exe

A modular Roblox script with a cute pink neon GUI. Built for loadstring deployment from GitHub.

## 📁 Repo Structure

```
pouncing.exe/
├── loader.lua              # Main entry point — this is what users execute
├── gui/
│   ├── framework.lua       # Pink neon UI components (toggles, sliders, color picker, etc.)
│   └── main.lua            # Assembles the main window with all tabs
├── modules/
│   ├── esp.lua             # Player ESP (boxes, names, health, skeleton, chams)
│   ├── aimbot.lua          # Aimbot with silent aim, FOV circle, smoothness
│   ├── gun.lua             # Gun mods (no recoil, no spread, rapid fire, auto fire)
│   └── misc.lua            # Movement & visual tweaks (bunny hop, speed, fullbright, no fog)
└── utils/
    └── core.lua            # Shared utilities (W2S, drawing helpers, player events)
```

## 🚀 Quick Start

### 1. Push to GitHub

Create a **public** repo (or make the files public) and push everything:

```bash
git init
git add .
git commit -m "Initial Pouncing.exe release"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/pouncing.exe.git
git push -u origin main
```

### 2. Update the Base URL

Open `loader.lua` and change this line to your actual GitHub username:

```lua
local BASE_URL = "https://raw.githubusercontent.com/YOUR_USERNAME/pouncing.exe/main/"
```

### 3. Get the Raw URLs

Once pushed, your raw URLs will look like:

```
https://raw.githubusercontent.com/YOUR_USERNAME/pouncing.exe/main/loader.lua
https://raw.githubusercontent.com/YOUR_USERNAME/pouncing.exe/main/gui/framework.lua
https://raw.githubusercontent.com/YOUR_USERNAME/pouncing.exe/main/modules/esp.lua
...
```

### 4. Execute in Roblox

Users run this single line in their executor:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_USERNAME/pouncing.exe/main/loader.lua"))()
```

## 🎨 Theme

| Token | Color | Hex |
|-------|-------|-----|
| Background | Deep warm black | `#160C14` |
| Primary | Hot pink | `#FF69B4` |
| Secondary | Light pink | `#FFB6C1` |
| Accent | Deep pink | `#FF1493` |
| Neon | Magenta | `#FF00FF` |
| Text | Lavender blush | `#FFF0F5` |

## 🛠️ Module API

Every module in `modules/` exports this interface:

```lua
return {
    Init = function() end,        -- One-time setup
    Enable = function() end,      -- Start the feature
    Disable = function() end,       -- Stop and cleanup
    SetConfig = function(key, value) end,
    GetConfig = function() return {} end
}
```

## 📝 Notes

- The loader uses `game:HttpGet()` which is standard in Roblox script executors (Synapse X, KRNL, Fluxus, etc.)
- Modules are fetched on-demand when toggled in the GUI — no wasted bandwidth
- Each module cleans up its own `RenderStepped` connections on disable
- RightShift toggles the GUI visibility
- The color picker is HSV-based with a dot-wheel + brightness slider

## 💗 Credits

Made and produced by Pouncing :3.
