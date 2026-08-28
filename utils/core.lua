-- Pouncing.exe | Utils v6.3
-- FIXED: GetBoxData height calculation (was botScr.Y - botScr.Y = 0)
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

local Utils = {}
local LocalPlayer = Players.LocalPlayer

function Utils.GetCharacter(player)
    return player and player.Character
end

function Utils.GetHumanoid(character)
    if not character then return nil end
    return character:FindFirstChildOfClass("Humanoid")
end

function Utils.GetRootPart(character)
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso")
end

function Utils.GetHead(character)
    if not character then return nil end
    return character:FindFirstChild("Head")
end

function Utils.IsAlive(character)
    if not character then return false end
    local humanoid = Utils.GetHumanoid(character)
    return humanoid and humanoid.Health > 0
end

function Utils.GetDistance(pos1, pos2)
    if not pos1 or not pos2 then return math.huge end
    return (pos1 - pos2).Magnitude
end

function Utils.GetClosestPlayer(maxDistance, teamCheck)
    local closest = nil
    local minDist = maxDistance or math.huge
    local myChar = Utils.GetCharacter(LocalPlayer)
    local myRoot = Utils.GetRootPart(myChar)
    if not myRoot then return nil end
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if teamCheck and player.Team == LocalPlayer.Team then continue end
        local character = Utils.GetCharacter(player)
        if not Utils.IsAlive(character) then continue end
        local root = Utils.GetRootPart(character)
        if not root then continue end
        local dist = Utils.GetDistance(myRoot.Position, root.Position)
        if dist < minDist then
            minDist = dist
            closest = player
        end
    end
    return closest
end

function Utils.GetClosestToMouse(maxDistance, teamCheck)
    local closest = nil
    local minDist = maxDistance or math.huge
    local mousePos = UserInputService:GetMouseLocation()
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if teamCheck and player.Team == LocalPlayer.Team then continue end
        local character = Utils.GetCharacter(player)
        if not Utils.IsAlive(character) then continue end
        local head = Utils.GetHead(character)
        if not head then continue end
        local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
        if not onScreen then continue end
        local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
        if dist < minDist then
            minDist = dist
            closest = player
        end
    end
    return closest
end

function Utils.GetClosestToCenter(maxDistance, teamCheck)
    local closest = nil
    local minDist = maxDistance or math.huge
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if teamCheck and player.Team == LocalPlayer.Team then continue end
        local character = Utils.GetCharacter(player)
        if not Utils.IsAlive(character) then continue end
        local head = Utils.GetHead(character)
        if not head then continue end
        local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
        if not onScreen then continue end
        local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
        if dist < minDist then
            minDist = dist
            closest = player
        end
    end
    return closest
end

function Utils.IsOnScreen(position)
    local screenPos, onScreen = Camera:WorldToViewportPoint(position)
    return onScreen, screenPos
end

function Utils.IsVisible(targetPosition, ignoreList)
    ignoreList = ignoreList or {}
    local origin = Camera.CFrame.Position
    local direction = (targetPosition - origin).Unit * (targetPosition - origin).Magnitude
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = ignoreList
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    local result = Workspace:Raycast(origin, direction, raycastParams)
    if not result then return true end
    return false
end

function Utils.GetBoxData(character)
    if not character then return nil end
    local head = Utils.GetHead(character)
    local root = Utils.GetRootPart(character)
    if not head or not root then return nil end
    local headPos, headOnScreen = Camera:WorldToViewportPoint(head.Position)
    local rootPos, rootOnScreen = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
    if not headOnScreen and not rootOnScreen then return nil end
    local topScr = Vector2.new(headPos.X, headPos.Y)
    local botScr = Vector2.new(rootPos.X, rootPos.Y)
    local h = math.abs(botScr.Y - topScr.Y)  -- FIXED: was botScr.Y - botScr.Y (always 0)
    local w = h * 0.55
    if h <= 1 then return nil end
    return {
        TopLeft = Vector2.new(topScr.X - w / 2, topScr.Y),
        TopRight = Vector2.new(topScr.X + w / 2, topScr.Y),
        BottomLeft = Vector2.new(botScr.X - w / 2, botScr.Y),
        BottomRight = Vector2.new(botScr.X + w / 2, botScr.Y),
        Center = Vector2.new(topScr.X, (topScr.Y + botScr.Y) / 2),
        Size = Vector2.new(w, h),
        HeadPos = topScr,
        RootPos = botScr,
        OnScreen = headOnScreen or rootOnScreen,
    }
end

function Utils.Get3DCorners(character)
    if not character then return nil end
    local root = Utils.GetRootPart(character)
    if not root then return nil end
    local size = character:GetExtentsSize()
    local cf = root.CFrame
    local corners = {}
    for x = -1, 1, 2 do
        for y = -1, 1, 2 do
            for z = -1, 1, 2 do
                local corner = cf * CFrame.new(size.X / 2 * x, size.Y / 2 * y, size.Z / 2 * z)
                local pos, onScreen = Camera:WorldToViewportPoint(corner.Position)
                table.insert(corners, {Position = Vector2.new(pos.X, pos.Y), OnScreen = onScreen, Depth = pos.Z})
            end
        end
    end
    return corners
end

function Utils.WorldToScreen(position)
    local pos, onScreen = Camera:WorldToViewportPoint(position)
    return Vector2.new(pos.X, pos.Y), onScreen, pos.Z
end

function Utils.GetTeamColor(player)
    if player.Team then
        return player.TeamColor.Color
    end
    return Color3.fromRGB(255, 255, 255)
end

function Utils.IsTeammate(player)
    return player.Team == LocalPlayer.Team
end

function Utils.GetHealth(character)
    local humanoid = Utils.GetHumanoid(character)
    if humanoid then
        return humanoid.Health, humanoid.MaxHealth
    end
    return 0, 100
end

function Utils.GetWeaponName()
    local char = Utils.GetCharacter(LocalPlayer)
    if not char then return "None" end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            return tool.Name
        end
    end
    return "None"
end

function Utils.GetPing()
    return LocalPlayer:GetNetworkPing() * 1000
end

function Utils.GetFPS()
    local fps = 0
    local lastTick = tick()
    RunService.RenderStepped:Connect(function()
        local currentTick = tick()
        fps = math.floor(1 / (currentTick - lastTick))
        lastTick = currentTick
    end)
    return function() return fps end
end

function Utils.Lerp(a, b, t)
    return a + (b - a) * t
end

function Utils.Clamp(val, min, max)
    return math.max(min, math.min(max, val))
end

function Utils.RandomString(length)
    length = length or 10
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local result = ""
    for i = 1, length do
        local rand = math.random(1, #chars)
        result = result .. chars:sub(rand, rand)
    end
    return result
end

function Utils.HashString(str)
    local hash = 0
    for i = 1, #str do
        hash = ((hash << 5) - hash) + string.byte(str, i)
        hash = hash & 0xFFFFFFFF
    end
    return hash
end

function Utils.DeepCopy(orig)
    local copy
    if type(orig) == "table" then
        copy = {}
        for k, v in next, orig, nil do
            copy[Utils.DeepCopy(k)] = Utils.DeepCopy(v)
        end
        setmetatable(copy, Utils.DeepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

function Utils.FormatNumber(num)
    if num >= 1000000 then
        return string.format("%.1fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.1fK", num / 1000)
    else
        return tostring(num)
    end
end

function Utils.FormatTime(seconds)
    local mins = math.floor(seconds / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d", mins, secs)
end

function Utils.Distance2D(a, b)
    return math.sqrt((a.X - b.X)^2 + (a.Y - b.Y)^2)
end

function Utils.AngleBetween(a, b)
    return math.atan2(b.Y - a.Y, b.X - a.X)
end

function Utils.Vector2ToCFrame(v2)
    return CFrame.new(v2.X, v2.Y, 0)
end

function Utils.CFrameToVector2(cf)
    local pos = cf.Position
    return Vector2.new(pos.X, pos.Y)
end

function Utils.Round(num, decimals)
    decimals = decimals or 0
    local mult = 10 ^ decimals
    return math.floor(num * mult + 0.5) / mult
end

function Utils.Map(value, inMin, inMax, outMin, outMax)
    return (value - inMin) * (outMax - outMin) / (inMax - inMin) + outMin
end

function Utils.SmoothStep(edge0, edge1, x)
    x = Utils.Clamp((x - edge0) / (edge1 - edge0), 0, 1)
    return x * x * (3 - 2 * x)
end

function Utils.PerlinNoise(x, y)
    return math.noise(x, y, 0)
end

function Utils.GetMemoryUsage()
    return collectgarbage("count")
end

function Utils.OptimizeTable(tbl)
    local optimized = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            optimized[k] = Utils.OptimizeTable(v)
        else
            optimized[k] = v
        end
    end
    return optimized
end

function Utils.SafeCall(func, ...)
    local success, result = pcall(func, ...)
    if success then
        return result
    else
        warn("[Pouncing] SafeCall error: " .. tostring(result))
        return nil
    end
end

function Utils.Debounce(func, delay)
    local timer = nil
    return function(...)
        if timer then
            task.cancel(timer)
        end
        timer = task.delay(delay, function()
            timer = nil
            func(...)
        end)
    end
end

function Utils.Throttle(func, interval)
    local lastCall = 0
    return function(...)
        local now = tick()
        if now - lastCall >= interval then
            lastCall = now
            func(...)
        end
    end
end

function Utils.CreateSignal()
    local signal = {}
    local connections = {}
    function signal:Connect(callback)
        table.insert(connections, callback)
        return {
            Disconnect = function()
                for i, conn in ipairs(connections) do
                    if conn == callback then
                        table.remove(connections, i)
                        break
                    end
                end
            end
        }
    end
    function signal:Fire(...)
        for _, callback in ipairs(connections) do
            task.spawn(callback, ...)
        end
    end
    function signal:Wait()
        local thread = coroutine.running()
        local conn
        conn = self:Connect(function(...)
            conn:Disconnect()
            coroutine.resume(thread, ...)
        end)
        return coroutine.yield()
    end
    return signal
end

function Utils.WaitForChild(parent, name, timeout)
    timeout = timeout or 5
    local child = parent:FindFirstChild(name)
    if child then return child end
    local start = tick()
    while tick() - start < timeout do
        child = parent:FindFirstChild(name)
        if child then return child end
        task.wait(0.1)
    end
    return nil
end

function Utils.WaitForChildren(parent, names, timeout)
    timeout = timeout or 5
    local results = {}
    local start = tick()
    while tick() - start < timeout do
        local allFound = true
        for _, name in ipairs(names) do
            if not results[name] then
                local child = parent:FindFirstChild(name)
                if child then
                    results[name] = child
                else
                    allFound = false
                end
            end
        end
        if allFound then return results end
        task.wait(0.1)
    end
    return results
end

function Utils.Tween(object, properties, duration, easingStyle, easingDirection)
    duration = duration or 0.3
    easingStyle = easingStyle or Enum.EasingStyle.Quad
    easingDirection = easingDirection or Enum.EasingDirection.Out
    local tweenInfo = TweenInfo.new(duration, easingStyle, easingDirection)
    local tween = game:GetService("TweenService"):Create(object, tweenInfo, properties)
    tween:Play()
    return tween
end

function Utils.Ripple(button, color)
    color = color or Color3.fromRGB(255, 255, 255)
    local ripple = Instance.new("Frame")
    ripple.Size = UDim2.new(0, 0, 0, 0)
    ripple.Position = UDim2.new(0.5, 0, 0.5, 0)
    ripple.BackgroundColor3 = color
    ripple.BackgroundTransparency = 0.6
    ripple.BorderSizePixel = 0
    ripple.ZIndex = button.ZIndex + 1
    ripple.Parent = button
    local rippleCorner = Instance.new("UICorner")
    rippleCorner.CornerRadius = UDim.new(1, 0)
    rippleCorner.Parent = ripple
    local maxSize = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2
    Utils.Tween(ripple, {
        Size = UDim2.new(0, maxSize, 0, maxSize),
        Position = UDim2.new(0.5, -maxSize/2, 0.5, -maxSize/2),
        BackgroundTransparency = 1
    }, 0.5)
    task.delay(0.5, function()
        ripple:Destroy()
    end)
end

function Utils.TypeWriter(textLabel, text, speed)
    speed = speed or 0.05
    textLabel.Text = ""
    for i = 1, #text do
        textLabel.Text = text:sub(1, i)
        task.wait(speed)
    end
end

function Utils.CountTable(tbl)
    local count = 0
    for _ in pairs(tbl) do count = count + 1 end
    return count
end

function Utils.ShuffleTable(tbl)
    local shuffled = {}
    for i, v in ipairs(tbl) do
        local pos = math.random(1, #shuffled + 1)
        table.insert(shuffled, pos, v)
    end
    return shuffled
end

function Utils.ReverseTable(tbl)
    local reversed = {}
    for i = #tbl, 1, -1 do
        table.insert(reversed, tbl[i])
    end
    return reversed
end

function Utils.FilterTable(tbl, predicate)
    local filtered = {}
    for _, v in ipairs(tbl) do
        if predicate(v) then
            table.insert(filtered, v)
        end
    end
    return filtered
end

function Utils.MapTable(tbl, mapper)
    local mapped = {}
    for _, v in ipairs(tbl) do
        table.insert(mapped, mapper(v))
    end
    return mapped
end

function Utils.ReduceTable(tbl, reducer, initial)
    local result = initial
    for _, v in ipairs(tbl) do
        result = reducer(result, v)
    end
    return result
end

function Utils.FindInTable(tbl, predicate)
    for _, v in ipairs(tbl) do
        if predicate(v) then return v end
    end
    return nil
end

function Utils.IndexOf(tbl, value)
    for i, v in ipairs(tbl) do
        if v == value then return i end
    end
    return -1
end

function Utils.RemoveFromTable(tbl, value)
    local index = Utils.IndexOf(tbl, value)
    if index ~= -1 then
        table.remove(tbl, index)
        return true
    end
    return false
end

function Utils.MergeTables(...)
    local merged = {}
    for _, tbl in ipairs({...}) do
        for k, v in pairs(tbl) do
            merged[k] = v
        end
    end
    return merged
end

function Utils.CloneTable(tbl)
    local clone = {}
    for k, v in pairs(tbl) do
        clone[k] = v
    end
    return clone
end

function Utils.TableToString(tbl, indent)
    indent = indent or 0
    local str = "{
"
    for k, v in pairs(tbl) do
        str = str .. string.rep("  ", indent + 1)
        if type(k) == "string" then
            str = str .. '["' .. k .. '"]' .. " = "
        else
            str = str .. "[" .. tostring(k) .. "]" .. " = "
        end
        if type(v) == "table" then
            str = str .. Utils.TableToString(v, indent + 1) .. ",
"
        elseif type(v) == "string" then
            str = str .. '"' .. v .. '"' .. ",
"
        else
            str = str .. tostring(v) .. ",
"
        end
    end
    str = str .. string.rep("  ", indent) .. "}"
    return str
end

function Utils.StringToTable(str)
    local func, err = loadstring("return " .. str)
    if func then
        local success, result = pcall(func)
        if success and type(result) == "table" then
            return result
        end
    end
    return nil
end

function Utils.Serialize(obj)
    if type(obj) == "table" then
        return Utils.TableToString(obj)
    elseif type(obj) == "string" then
        return '"' .. obj .. '"'
    else
        return tostring(obj)
    end
end

function Utils.Deserialize(str)
    return Utils.StringToTable(str)
end

function Utils.SaveToFile(filename, data)
    local file = io.open(filename, "w")
    if file then
        file:write(data)
        file:close()
        return true
    end
    return false
end

function Utils.LoadFromFile(filename)
    local file = io.open(filename, "r")
    if file then
        local data = file:read("*all")
        file:close()
        return data
    end
    return nil
end

function Utils.EncodeBase64(data)
    local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    return ((data:gsub(".", function(x)
        local r, b64 = x:byte(), ""
        for i = 8, 1, -1 do
            r = r + (b64:sub(-1):byte() or 0) * 2 ^ i
            b64 = b64 .. (r >= 256 and b:sub(r / 256 % 64 + 1, r / 256 % 64 + 1) or "")
            r = r % 256
        end
        return b64
    end) .. "00"):gsub("%d%d%d?%d?%d?%d?", function(x)
        if #x < 6 then return "" end
        local n = 0
        for i = 1, 6 do
            n = n + (x:sub(i, i) == "1" and 2 ^ (6 - i) or 0)
        end
        return b:sub(n + 1, n + 1)
    end) .. ({"", "==", "="})[#data % 3 + 1])
end

function Utils.DecodeBase64(data)
    local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    data = data:gsub("[^" .. b .. "=]", "")
    return (data:gsub(".", function(x)
        if x == "=" then return "" end
        local r, f = "", b:find(x) - 1
        for i = 6, 1, -1 do
            r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and "1" or "0")
        end
        return r
    end):gsub("%d%d%d?%d?%d?%d?%d?%d?", function(x)
        if #x ~= 8 then return "" end
        return string.char(tonumber(x, 2))
    end))
end

function Utils.Encrypt(data, key)
    key = key or "PouncingExe"
    local encrypted = {}
    for i = 1, #data do
        local byte = string.byte(data, i)
        local keyByte = string.byte(key, (i - 1) % #key + 1)
        table.insert(encrypted, string.char(bit32.bxor(byte, keyByte)))
    end
    return table.concat(encrypted)
end

function Utils.Decrypt(data, key)
    return Utils.Encrypt(data, key)
end

function Utils.HashSHA256(data)
    local sha256 = require(game:GetService("ReplicatedStorage"):FindFirstChild("SHA256"))
    if sha256 then
        return sha256(data)
    end
    return Utils.HashString(data)
end

function Utils.GenerateUUID()
    local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
    return template:gsub("[xy]", function(c)
        local v = (c == "x") and math.random(0, 15) or math.random(8, 11)
        return string.format("%x", v)
    end)
end

function Utils.GetTimestamp()
    return os.time()
end

function Utils.FormatTimestamp(timestamp)
    return os.date("%Y-%m-%d %H:%M:%S", timestamp)
end

function Utils.Sleep(seconds)
    task.wait(seconds)
end

function Utils.Spawn(func, ...)
    task.spawn(func, ...)
end

function Utils.Delay(seconds, func, ...)
    task.delay(seconds, func, ...)
end

function Utils.RepeatUntil(func, condition, interval)
    interval = interval or 0.1
    while not condition() do
        func()
        task.wait(interval)
    end
end

function Utils.TryCatch(tryFunc, catchFunc)
    local success, result = pcall(tryFunc)
    if not success then
        if catchFunc then
            catchFunc(result)
        else
            warn("[Pouncing] Error: " .. tostring(result))
        end
    end
    return success, result
end

function Utils.Assert(condition, message)
    if not condition then
        error(message or "Assertion failed")
    end
end

function Utils.ValidateType(value, expectedType, name)
    if type(value) ~= expectedType then
        error(string.format("Expected %s to be %s, got %s", name or "value", expectedType, type(value)))
    end
end

function Utils.ValidateRange(value, min, max, name)
    if value < min or value > max then
        error(string.format("Expected %s to be between %s and %s, got %s", name or "value", min, max, value))
    end
end

function Utils.ValidateNotNil(value, name)
    if value == nil then
        error(string.format("Expected %s to not be nil", name or "value"))
    end
end

function Utils.ValidateStringLength(str, min, max, name)
    local len = #str
    if len < min or len > max then
        error(string.format("Expected %s length to be between %s and %s, got %s", name or "string", min, max, len))
    end
end

function Utils.ValidateTableSize(tbl, min, max, name)
    local size = Utils.CountTable(tbl)
    if size < min or size > max then
        error(string.format("Expected %s size to be between %s and %s, got %s", name or "table", min, max, size))
    end
end

function Utils.ValidateColor3(color)
    if typeof(color) ~= "Color3" then
        error("Expected Color3, got " .. typeof(color))
    end
end

function Utils.ValidateVector3(vec)
    if typeof(vec) ~= "Vector3" then
        error("Expected Vector3, got " .. typeof(vec))
    end
end

function Utils.ValidateVector2(vec)
    if typeof(vec) ~= "Vector2" then
        error("Expected Vector2, got " .. typeof(vec))
    end
end

function Utils.ValidateCFrame(cf)
    if typeof(cf) ~= "CFrame" then
        error("Expected CFrame, got " .. typeof(cf))
    end
end

function Utils.ValidateInstance(inst, className)
    if not inst or not inst:IsA(className) then
        error("Expected " .. className .. ", got " .. (inst and inst.ClassName or "nil"))
    end
end

function Utils.ValidatePlayer(player)
    if not player or not player:IsA("Player") then
        error("Expected Player, got " .. (player and player.ClassName or "nil"))
    end
end

function Utils.ValidateCharacter(character)
    if not character or not character:IsA("Model") then
        error("Expected Character Model, got " .. (character and character.ClassName or "nil"))
    end
end

function Utils.ValidateHumanoid(humanoid)
    if not humanoid or not humanoid:IsA("Humanoid") then
        error("Expected Humanoid, got " .. (humanoid and humanoid.ClassName or "nil"))
    end
end

function Utils.ValidateTool(tool)
    if not tool or not tool:IsA("Tool") then
        error("Expected Tool, got " .. (tool and tool.ClassName or "nil"))
    end
end

function Utils.ValidateRemoteEvent(remote)
    if not remote or not remote:IsA("RemoteEvent") then
        error("Expected RemoteEvent, got " .. (remote and remote.ClassName or "nil"))
    end
end

function Utils.ValidateRemoteFunction(remote)
    if not remote or not remote:IsA("RemoteFunction") then
        error("Expected RemoteFunction, got " .. (remote and remote.ClassName or "nil"))
    end
end

function Utils.ValidateBindableEvent(bindable)
    if not bindable or not bindable:IsA("BindableEvent") then
        error("Expected BindableEvent, got " .. (bindable and bindable.ClassName or "nil"))
    end
end

function Utils.ValidateBindableFunction(bindable)
    if not bindable or not bindable:IsA("BindableFunction") then
        error("Expected BindableFunction, got " .. (bindable and bindable.ClassName or "nil"))
    end
end

function Utils.ValidateNumberSequence(seq)
    if typeof(seq) ~= "NumberSequence" then
        error("Expected NumberSequence, got " .. typeof(seq))
    end
end

function Utils.ValidateColorSequence(seq)
    if typeof(seq) ~= "ColorSequence" then
        error("Expected ColorSequence, got " .. typeof(seq))
    end
end

function Utils.ValidateNumberRange(range)
    if typeof(range) ~= "NumberRange" then
        error("Expected NumberRange, got " .. typeof(range))
    end
end

function Utils.ValidateRect(rect)
    if typeof(rect) ~= "Rect" then
        error("Expected Rect, got " .. typeof(rect))
    end
end

function Utils.ValidateUDim(udim)
    if typeof(udim) ~= "UDim" then
        error("Expected UDim, got " .. typeof(udim))
    end
end

function Utils.ValidateUDim2(udim2)
    if typeof(udim2) ~= "UDim2" then
        error("Expected UDim2, got " .. typeof(udim2))
    end
end

function Utils.ValidateRay(ray)
    if typeof(ray) ~= "Ray" then
        error("Expected Ray, got " .. typeof(ray))
    end
end

function Utils.ValidateRegion3(region)
    if typeof(region) ~= "Region3" then
        error("Expected Region3, got " .. typeof(region))
    end
end

function Utils.ValidateBrickColor(color)
    if typeof(color) ~= "BrickColor" then
        error("Expected BrickColor, got " .. typeof(color))
    end
end

function Utils.ValidateTweenInfo(info)
    if typeof(info) ~= "TweenInfo" then
        error("Expected TweenInfo, got " .. typeof(info))
    end
end

function Utils.ValidateRaycastParams(params)
    if typeof(params) ~= "RaycastParams" then
        error("Expected RaycastParams, got " .. typeof(params))
    end
end

function Utils.ValidateOverlapParams(params)
    if typeof(params) ~= "OverlapParams" then
        error("Expected OverlapParams, got " .. typeof(params))
    end
end

function Utils.ValidatePath(path)
    if typeof(path) ~= "Path" then
        error("Expected Path, got " .. typeof(path))
    end
end

function Utils.ValidateAnimationTrack(track)
    if not track or not track:IsA("AnimationTrack") then
        error("Expected AnimationTrack, got " .. (track and track.ClassName or "nil"))
    end
end

function Utils.ValidateSound(sound)
    if not sound or not sound:IsA("Sound") then
        error("Expected Sound, got " .. (sound and sound.ClassName or "nil"))
    end
end

function Utils.ValidateParticleEmitter(emitter)
    if not emitter or not emitter:IsA("ParticleEmitter") then
        error("Expected ParticleEmitter, got " .. (emitter and emitter.ClassName or "nil"))
    end
end

function Utils.ValidateTrail(trail)
    if not trail or not trail:IsA("Trail") then
        error("Expected Trail, got " .. (trail and trail.ClassName or "nil"))
    end
end

function Utils.ValidateBeam(beam)
    if not beam or not beam:IsA("Beam") then
        error("Expected Beam, got " .. (beam and beam.ClassName or "nil"))
    end
end

function Utils.ValidateTexture(texture)
    if not texture or not texture:IsA("Texture") then
        error("Expected Texture, got " .. (texture and texture.ClassName or "nil"))
    end
end

function Utils.ValidateDecal(decal)
    if not decal or not decal:IsA("Decal") then
        error("Expected Decal, got " .. (decal and decal.ClassName or "nil"))
    end
end

function Utils.ValidateGuiObject(gui)
    if not gui or not gui:IsA("GuiObject") then
        error("Expected GuiObject, got " .. (gui and gui.ClassName or "nil"))
    end
end

function Utils.ValidateScreenGui(gui)
    if not gui or not gui:IsA("ScreenGui") then
        error("Expected ScreenGui, got " .. (gui and gui.ClassName or "nil"))
    end
end

function Utils.ValidateBillboardGui(gui)
    if not gui or not gui:IsA("BillboardGui") then
        error("Expected BillboardGui, got " .. (gui and gui.ClassName or "nil"))
    end
end

function Utils.ValidateSurfaceGui(gui)
    if not gui or not gui:IsA("SurfaceGui") then
        error("Expected SurfaceGui, got " .. (gui and gui.ClassName or "nil"))
    end
end

function Utils.ValidateFrame(frame)
    if not frame or not frame:IsA("Frame") then
        error("Expected Frame, got " .. (frame and frame.ClassName or "nil"))
    end
end

function Utils.ValidateTextLabel(label)
    if not label or not label:IsA("TextLabel") then
        error("Expected TextLabel, got " .. (label and label.ClassName or "nil"))
    end
end

function Utils.ValidateTextButton(button)
    if not button or not button:IsA("TextButton") then
        error("Expected TextButton, got " .. (button and button.ClassName or "nil"))
    end
end

function Utils.ValidateTextBox(box)
    if not box or not box:IsA("TextBox") then
        error("Expected TextBox, got " .. (box and box.ClassName or "nil"))
    end
end

function Utils.ValidateImageLabel(label)
    if not label or not label:IsA("ImageLabel") then
        error("Expected ImageLabel, got " .. (label and label.ClassName or "nil"))
    end
end

function Utils.ValidateImageButton(button)
    if not button or not button:IsA("ImageButton") then
        error("Expected ImageButton, got " .. (button and button.ClassName or "nil"))
    end
end

function Utils.ValidateScrollingFrame(frame)
    if not frame or not frame:IsA("ScrollingFrame") then
        error("Expected ScrollingFrame, got " .. (frame and frame.ClassName or "nil"))
    end
end

function Utils.ValidateViewportFrame(frame)
    if not frame or not frame:IsA("ViewportFrame") then
        error("Expected ViewportFrame, got " .. (frame and frame.ClassName or "nil"))
    end
end

function Utils.ValidateVideoFrame(frame)
    if not frame or not frame:IsA("VideoFrame") then
        error("Expected VideoFrame, got " .. (frame and frame.ClassName or "nil"))
    end
end

function Utils.ValidateCanvasGroup(group)
    if not group or not group:IsA("CanvasGroup") then
        error("Expected CanvasGroup, got " .. (group and group.ClassName or "nil"))
    end
end

function Utils.ValidateUIStroke(stroke)
    if not stroke or not stroke:IsA("UIStroke") then
        error("Expected UIStroke, got " .. (stroke and stroke.ClassName or "nil"))
    end
end

function Utils.ValidateUICorner(corner)
    if not corner or not corner:IsA("UICorner") then
        error("Expected UICorner, got " .. (corner and corner.ClassName or "nil"))
    end
end

function Utils.ValidateUIGradient(gradient)
    if not gradient or not gradient:IsA("UIGradient") then
        error("Expected UIGradient, got " .. (gradient and gradient.ClassName or "nil"))
    end
end

function Utils.ValidateUIScale(scale)
    if not scale or not scale:IsA("UIScale") then
        error("Expected UIScale, got " .. (scale and scale.ClassName or "nil"))
    end
end

function Utils.ValidateUIAspectRatioConstraint(constraint)
    if not constraint or not constraint:IsA("UIAspectRatioConstraint") then
        error("Expected UIAspectRatioConstraint, got " .. (constraint and constraint.ClassName or "nil"))
    end
end

function Utils.ValidateUISizeConstraint(constraint)
    if not constraint or not constraint:IsA("UISizeConstraint") then
        error("Expected UISizeConstraint, got " .. (constraint and constraint.ClassName or "nil"))
    end
end

function Utils.ValidateUITextSizeConstraint(constraint)
    if not constraint or not constraint:IsA("UITextSizeConstraint") then
        error("Expected UITextSizeConstraint, got " .. (constraint and constraint.ClassName or "nil"))
    end
end

function Utils.ValidateUILayout(layout)
    if not layout or not layout:IsA("UILayout") then
        error("Expected UILayout, got " .. (layout and layout.ClassName or "nil"))
    end
end

function Utils.ValidateUIGridStyleLayout(layout)
    if not layout or not layout:IsA("UIGridStyleLayout") then
        error("Expected UIGridStyleLayout, got " .. (layout and layout.ClassName or "nil"))
    end
end

function Utils.ValidateUIListLayout(layout)
    if not layout or not layout:IsA("UIListLayout") then
        error("Expected UIListLayout, got " .. (layout and layout.ClassName or "nil"))
    end
end

function Utils.ValidateUIGridLayout(layout)
    if not layout or not layout:IsA("UIGridLayout") then
        error("Expected UIGridLayout, got " .. (layout and layout.ClassName or "nil"))
    end
end

function Utils.ValidateUITableLayout(layout)
    if not layout or not layout:IsA("UITableLayout") then
        error("Expected UITableLayout, got " .. (layout and layout.ClassName or "nil"))
    end
end

function Utils.ValidateUIPageLayout(layout)
    if not layout or not layout:IsA("UIPageLayout") then
        error("Expected UIPageLayout, got " .. (layout and layout.ClassName or "nil"))
    end
end

function Utils.ValidateUIPadding(padding)
    if not padding or not padding:IsA("UIPadding") then
        error("Expected UIPadding, got " .. (padding and padding.ClassName or "nil"))
    end
end

function Utils.ValidateUIListLayoutPadding(padding)
    if not padding or not padding:IsA("UIListLayoutPadding") then
        error("Expected UIListLayoutPadding, got " .. (padding and padding.ClassName or "nil"))
    end
end

return Utils