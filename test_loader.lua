-- Pouncing.exe | MINIMAL TEST — just builds GUI, no modules

local CoreGui = game:GetService("CoreGui")
local BASE_URL = "https://raw.githubusercontent.com/confessess/pouncing.exe/main/"

local function Fetch(url)
	local s,r = pcall(function() return game:HttpGet(url,true) end)
	if s then print("[TEST] OK: "..url.." ("..tostring(#r).." bytes)") return r end
	print("[TEST] FAIL: "..url.." -> "..tostring(r))
	return nil
end

local function Load(path)
	local src = Fetch(BASE_URL..path..".lua")
	if not src then return nil end
	local fn,err = loadstring(src,path)
	if not fn then print("[TEST] SYNTAX: "..path.." -> "..tostring(err)) return nil end
	local ok,res = pcall(fn)
	if not ok then print("[TEST] RUNTIME: "..path.." -> "..tostring(res)) return nil end
	print("[TEST] LOADED: "..path)
	return res
end

print("[TEST] === Start ===")

local GUI = Load("gui/framework")
if not GUI then print("[TEST] framework missing, aborting") return end

local Main = Load("gui/main")
if not Main then print("[TEST] main missing, aborting") return end

print("[TEST] Creating ScreenGui...")
local sg = Instance.new("ScreenGui")
sg.Name = "PouncingTest"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
if syn and syn.protect_gui then syn.protect_gui(sg) sg.Parent = CoreGui
elseif gethui then sg.Parent = gethui()
else sg.Parent = CoreGui end

print("[TEST] Calling Main.Create...")
local fakeManager = {
	Modules = {Framework = GUI},
	GetModule = function(self,n) return self.Modules[n] end,
	Toggle = function() end,
	UnloadAll = function() end
}
local ok,win = pcall(function() return Main.Create(sg, fakeManager) end)
if not ok then
	print("[TEST] Main.Create CRASHED: "..tostring(win))
	return
end
if not win then
	print("[TEST] Main.Create returned nil")
	return
end

print("[TEST] GUI built! Window = "..tostring(win))
print("[TEST] === Done ===")