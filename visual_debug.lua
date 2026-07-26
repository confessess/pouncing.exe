-- Pouncing.exe | VISUAL DEBUG v3

local CoreGui = game:GetService("CoreGui")
local BASE_URL = "https://raw.githubusercontent.com/confessess/pouncing.exe/main/"

local sg = Instance.new("ScreenGui")
sg.Name = "PouncingDebugV3"
sg.ResetOnSpawn = false
if syn and syn.protect_gui then syn.protect_gui(sg) sg.Parent = CoreGui
elseif gethui then sg.Parent = gethui()
else sg.Parent = CoreGui end

local function Box(color, text, y)
	local f = Instance.new("Frame")
	f.Size = UDim2.new(0, 600, 0, 26)
	f.Position = UDim2.new(0, 20, 0, 20 + y)
	f.BackgroundColor3 = color
	f.BorderSizePixel = 0
	f.Parent = sg
	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(1, -10, 1, 0)
	t.Position = UDim2.new(0, 5, 0, 0)
	t.BackgroundTransparency = 1
	t.Text = text
	t.TextColor3 = Color3.new(1,1,1)
	t.TextSize = 12
	t.Font = Enum.Font.Gotham
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.Parent = f
end

Box(Color3.fromRGB(255,0,0), "1: ScreenGui OK", 0)

local url = BASE_URL .. "gui/framework.lua"
local ok, src = pcall(function() return game:HttpGet(url, true) end)
if not ok then Box(Color3.fromRGB(150,0,0), "2: HttpGet FAIL: "..tostring(src), 28) return end
if not src then Box(Color3.fromRGB(150,0,0), "2: HttpGet nil", 28) return end

Box(Color3.fromRGB(0,255,0), "2: Fetched "..tostring(#src).." bytes", 28)

-- Show last line
local lines = {}
for line in src:gmatch("[^
]+") do table.insert(lines, line) end
local last = lines[#lines] or "(empty)"
Box(Color3.fromRGB(0,200,0), "Last line: "..last, 56)

-- Show second to last
local last2 = lines[#lines-1] or "(none)"
Box(Color3.fromRGB(0,180,0), "2nd last: "..last2, 84)

local fn, err = loadstring(src, "framework")
if not fn then Box(Color3.fromRGB(0,150,0), "3: loadstring FAIL: "..tostring(err), 112) return end
Box(Color3.fromRGB(0,0,255), "3: loadstring OK", 112)

local ok2, res = pcall(fn)
Box(Color3.fromRGB(0,0,200), "4: pcall ok="..tostring(ok2).." type="..typeof(res), 140)
if not ok2 then Box(Color3.fromRGB(0,0,150), "4: ERROR: "..tostring(res), 168) return end
if not res then Box(Color3.fromRGB(0,0,150), "4: res is nil!", 168) return end

Box(Color3.fromRGB(255,255,0), "5: SUCCESS! res has "..tostring(#res).." keys", 168)