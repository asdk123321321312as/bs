local CONFIG = {
    Accent    = Color3.fromRGB(140, 110, 255),
    AccentDim = Color3.fromRGB(44, 34, 92),
    Keybind   = Enum.KeyCode.Z,
    Version   = "2.0.1",
}

-- окружение без прямого вызова getgenv
local env = _G
do
    local g = rawget(_G, "getgenv")
    if type(g) == "function" then
        local ok, res = pcall(g)
        if ok and type(res) == "table" then env = res end
    end
end

do
    local prev = env.SleepScript
    if type(prev) == "table" and type(prev.Unload) == "function" then
        pcall(prev.Unload)
    end
    env.SleepScript = nil
end

local booted, bootErr = xpcall(function()

local cloneref   = cloneref or function(x) return x end
local gethui     = gethui or function() return game:GetService("CoreGui") end
local hasDrawing = type(Drawing) == "table" and type(Drawing.new) == "function"

local Players           = cloneref(game:GetService("Players"))
local RunService        = cloneref(game:GetService("RunService"))
local UIS               = cloneref(game:GetService("UserInputService"))
local TweenService      = cloneref(game:GetService("TweenService"))
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local Lighting          = cloneref(game:GetService("Lighting"))
local Workspace         = cloneref(workspace)
local lp                = Players.LocalPlayer

local S = {
    espEnabled = false,
    simpleMode = false,
    style = "corner",
    thickness = 1,
    showDist = true,
    hpMode = "bar",
    teamCheck = true,
    showBots = true,
    showLocal = false,
    maxDist = 2000,
    colorStatic = Color3.fromRGB(235, 235, 245),
    colorHidden = Color3.fromRGB(195, 195, 210),
    bhop = false,
    noAirSpread = false,
    fovEnabled = false,
    fovValue = 90,
    knife = nil,
    skin = nil,
    swapKnife = false,
    holdSkin = true,
}

local TEXT_SIZE = 13
local CORNER_SIZE = 9
local GHOST_TIME = 9

local selfRead = false
local dead = false
local connections = {}
local function track(c) table.insert(connections, c) return c end

local function notify(text, dur)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "SleepScript", Text = text, Duration = dur or 3,
        })
    end)
end

--==============================================================
--  ПЕРСОНАЖИ
--==============================================================
local CharacterResolver
pcall(function()
    CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
end)

local charMap = {}
local modelOwner = {}

local function charsFolder()
    return Workspace:FindFirstChild("Characters")
end

local function rootOf(char)
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
        or char:FindFirstChild("UpperTorso")
        or char:FindFirstChild("Torso")
        or char.PrimaryPart
end

local function eachCandidate(cb)
    local folder = charsFolder()
    if folder then
        for _, m in ipairs(folder:GetChildren()) do
            if m:IsA("Model") then cb(m) end
        end
    end
    for _, c in ipairs(Workspace:GetChildren()) do
        if c ~= folder and (c:IsA("Folder") or c:IsA("Model")) then
            local kids = c:GetChildren()
            if #kids <= 400 then
                for _, m in ipairs(kids) do
                    if m:IsA("Model") and (modelOwner[m] or m:FindFirstChildOfClass("Humanoid")) then
                        cb(m)
                    end
                end
            end
        end
    end
end

local OWNER_KEYS = { "UserId", "UserID", "Player", "Owner", "PlayerName", "OwnerName", "Username", "Name" }

local function ownerFromAttributes(model)
    for _, key in ipairs(OWNER_KEYS) do
        local v = model:GetAttribute(key)
        if typeof(v) == "number" then
            local p = Players:GetPlayerByUserId(v)
            if p then return p end
        elseif typeof(v) == "string" then
            local p = Players:FindFirstChild(v)
            if p then return p end
            local id = tonumber(v)
            if id then
                p = Players:GetPlayerByUserId(id)
                if p then return p end
            end
        elseif typeof(v) == "Instance" then
            if v:IsA("Player") then return v end
        end
    end
    local ov = model:FindFirstChild("Player") or model:FindFirstChild("Owner")
    if ov and ov:IsA("ObjectValue") and ov.Value and ov.Value:IsA("Player") then
        return ov.Value
    end
    return nil
end

local function refreshOwners()
    local map = {}
    local plrs = Players:GetPlayers()
    eachCandidate(function(m)
        local owner = ownerFromAttributes(m)
        if not owner then owner = Players:FindFirstChild(m.Name) end
        if not owner then
            for _, p in ipairs(plrs) do
                if #p.Name > 2 and m.Name:find(p.Name, 1, true) then
                    owner = p
                    break
                end
            end
        end
        if owner then map[m] = owner end
    end)
    if lp.Character and lp.Character.Parent then map[lp.Character] = lp end
    modelOwner = map
end

task.spawn(function()
    while not dead and task.wait(0.4) do
        pcall(refreshOwners)
    end
end)

task.spawn(function()
    while not dead and task.wait(0.4) do
        local folder = charsFolder()
        local new = {}
        if folder then
            for _, m in ipairs(folder:GetChildren()) do
                if m:IsA("Model") then new[m.Name] = m end
            end
        end
        charMap = new
    end
end)

local function resolveChar(plr)
    if not plr then return nil end
    if CharacterResolver and CharacterResolver.getPlayerCharacter then
        local ok, c = pcall(CharacterResolver.getPlayerCharacter, plr)
        if ok and c and c.Parent and rootOf(c) then return c end
    end
    local c = plr.Character
    if c and c.Parent and rootOf(c) then return c end
    for m, o in pairs(modelOwner) do
        if o == plr and m.Parent then return m end
    end
    local m = charMap[plr.Name]
    if m and m.Parent then return m end
    return nil
end

local myCache, myCacheAt = nil, 0

local function myChar()
    if myCache and myCache.Parent and os.clock() - myCacheAt < 0.2 then return myCache end
    local c = nil
    if lp.Character and lp.Character.Parent and rootOf(lp.Character) then
        c = lp.Character
    else
        for m, o in pairs(modelOwner) do
            if o == lp and m.Parent then c = m break end
        end
        if not c then
            local folder = charsFolder()
            local m = folder and folder:FindFirstChild(lp.Name)
            if m then c = m end
        end
    end
    myCache, myCacheAt = c, os.clock()
    return c
end

local function myHum()
    local c = myChar()
    return c and c:FindFirstChildOfClass("Humanoid") or nil
end

local function isDead(char)
    if not char then return true end
    if char:GetAttribute("Dead") == true then return true end
    local hp = tonumber(char:GetAttribute("Health"))
    if hp and hp <= 0 then return true end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health <= 0 then return true end
    return false
end

local function teamOf(plr)
    if not plr then return nil end
    local t = plr:GetAttribute("Team")
    if typeof(t) == "string" then return t end
    if plr.Team then return plr.Team.Name end
    return nil
end

local function teamOfModel(model, owner)
    local t = teamOf(owner)
    if t then return t end
    if model then
        local mt = model:GetAttribute("Team")
        if typeof(mt) == "string" then return mt end
    end
    return nil
end

--==============================================================
--  КАМЕРА / FOV
--==============================================================
local camera = Workspace.CurrentCamera
local fovOriginal = camera and camera.FieldOfView or 70

local function applyFov()
    local cam = camera or Workspace.CurrentCamera
    if not cam then return end
    pcall(function() cam.FieldOfView = S.fovEnabled and S.fovValue or fovOriginal end)
end

track(RunService.RenderStepped:Connect(function()
    if not S.fovEnabled then return end
    local cam = camera or Workspace.CurrentCamera
    if not cam then return end
    if math.abs(cam.FieldOfView - S.fovValue) > 0.4 then
        pcall(function() cam.FieldOfView = S.fovValue end)
    end
end))

track(Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    if Workspace.CurrentCamera then
        camera = Workspace.CurrentCamera
        applyFov()
    end
end))

--==============================================================
--  UI БАЗА
--==============================================================
local function new(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do inst[k] = v end
    if parent then inst.Parent = parent end
    return inst
end

local function tw(inst, time, props, style, dir)
    local t = TweenService:Create(inst, TweenInfo.new(time or 0.15, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
    t:Play()
    return t
end

local gui = new("ScreenGui", {
    Name = "SleepScript",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 9999,
}, gethui())

local blur = new("BlurEffect", { Name = "SleepBlur", Size = 0, Enabled = true }, Lighting)

local glow = new("Frame", {
    Size = UDim2.fromOffset(512, 380),
    Position = UDim2.new(0.5, -256, 0.5, -190),
    BackgroundColor3 = CONFIG.Accent,
    BackgroundTransparency = 0.94,
    BorderSizePixel = 0,
    ZIndex = 0,
}, gui)
new("UICorner", { CornerRadius = UDim.new(0, 26) }, glow)

local main = new("Frame", {
    Size = UDim2.fromOffset(496, 364),
    Position = UDim2.new(0.5, -248, 0.5, -182),
    BackgroundColor3 = Color3.fromRGB(7, 7, 10),
    BorderSizePixel = 0,
    ClipsDescendants = true,
    ZIndex = 1,
}, gui)
new("UICorner", { CornerRadius = UDim.new(0, 16) }, main)
new("UIStroke", { Color = Color3.fromRGB(60, 52, 90), Transparency = 0.35, Thickness = 1 }, main)

local mainScale = new("UIScale", { Scale = 1 }, main)

local header = new("Frame", {
    Size = UDim2.new(1, 0, 0, 56),
    BackgroundColor3 = Color3.fromRGB(11, 11, 15),
    BorderSizePixel = 0,
    ZIndex = 2,
}, main)
new("UICorner", { CornerRadius = UDim.new(0, 16) }, header)
new("Frame", {
    Size = UDim2.new(1, 0, 0, 16), Position = UDim2.new(0, 0, 1, -16),
    BackgroundColor3 = Color3.fromRGB(11, 11, 15), BorderSizePixel = 0,
}, header)

local topLine = new("Frame", {
    Size = UDim2.new(1, 0, 0, 2),
    BackgroundColor3 = CONFIG.Accent,
    BorderSizePixel = 0,
    ZIndex = 5,
}, header)
local tlGrad = new("UIGradient", {
    Color = ColorSequence.new(Color3.fromRGB(50, 34, 110), CONFIG.Accent, Color3.fromRGB(50, 34, 110)),
}, topLine)
tlGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 1),
    NumberSequenceKeypoint.new(0.5, 0.15),
    NumberSequenceKeypoint.new(1, 1),
})

new("TextLabel", {
    Text = "Sleep",
    Font = Enum.Font.GothamBold,
    TextSize = 20,
    TextColor3 = Color3.fromRGB(255, 255, 255),
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(18, 10),
    Size = UDim2.fromOffset(140, 24),
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 3,
}, header)

new("TextLabel", {
    Text = "blox strike",
    Font = Enum.Font.Gotham,
    TextSize = 11,
    TextColor3 = Color3.fromRGB(110, 110, 130),
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(82, 15),
    Size = UDim2.fromOffset(200, 16),
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 3,
}, header)

new("TextLabel", {
    Text = "v" .. CONFIG.Version,
    Font = Enum.Font.GothamMedium,
    TextSize = 10,
    TextColor3 = CONFIG.Accent,
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(18, 32),
    Size = UDim2.fromOffset(80, 14),
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 3,
}, header)

local function headerButton(x, symbol, cb)
    local b = new("TextButton", {
        Text = symbol,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = Color3.fromRGB(165, 165, 185),
        BackgroundColor3 = Color3.fromRGB(21, 21, 29),
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Position = UDim2.new(1, x, 0, 16),
        Size = UDim2.fromOffset(24, 24),
        ZIndex = 4,
    }, header)
    new("UICorner", { CornerRadius = UDim.new(0, 7) }, b)
    b.MouseEnter:Connect(function()
        tw(b, 0.14, { BackgroundColor3 = Color3.fromRGB(36, 30, 58), TextColor3 = Color3.fromRGB(255, 255, 255) })
    end)
    b.MouseLeave:Connect(function()
        tw(b, 0.14, { BackgroundColor3 = Color3.fromRGB(21, 21, 29), TextColor3 = Color3.fromRGB(165, 165, 185) })
    end)
    b.MouseButton1Click:Connect(cb)
    return b
end

local function makeDraggable(frame, handle)
    local dragging, dragStart, startPos
    track(handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end))
    track(UIS.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local d = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end))
    track(UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))
end

makeDraggable(main, header)

--==============================================================
--  ОТКРЫТИЕ / ЗАКРЫТИЕ
--==============================================================
local opened = true

local function syncGlow()
    glow.Position = UDim2.new(main.Position.X.Scale, main.Position.X.Offset - 8,
        main.Position.Y.Scale, main.Position.Y.Offset - 8)
end
track(main:GetPropertyChangedSignal("Position"):Connect(syncGlow))

local function openMenu()
    if opened then return end
    opened = true
    local p = main.Position
    main.Visible = true
    glow.Visible = true
    main.BackgroundTransparency = 1
    mainScale.Scale = 0.9
    main.Position = p + UDim2.fromOffset(0, 16)
    tw(main, 0.24, { BackgroundTransparency = 0, Position = p })
    tw(glow, 0.24, { BackgroundTransparency = 0.94 })
    tw(mainScale, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
    tw(blur, 0.25, { Size = 10 })
end

local function closeMenu()
    if not opened then return end
    opened = false
    local p = main.Position
    tw(main, 0.2, { BackgroundTransparency = 1, Position = p + UDim2.fromOffset(0, 16) })
    tw(glow, 0.2, { BackgroundTransparency = 1 })
    tw(mainScale, 0.2, { Scale = 0.9 })
    tw(blur, 0.2, { Size = 0 })
    task.delay(0.21, function()
        if opened then return end
        main.Visible = false
        glow.Visible = false
        main.Position = p
        main.BackgroundTransparency = 0
        mainScale.Scale = 1
    end)
end

headerButton(-32, "×", function() if env.SleepScript then env.SleepScript.Unload() end end)
headerButton(-60, "—", function() closeMenu() end)

--==============================================================
--  КОМПОНЕНТЫ
--==============================================================
local sidebar = new("Frame", {
    Size = UDim2.new(0, 118, 1, -56),
    Position = UDim2.fromOffset(0, 56),
    BackgroundColor3 = Color3.fromRGB(9, 9, 13),
    BorderSizePixel = 0,
}, main)
new("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }, sidebar)
new("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9) }, sidebar)

local content = new("Frame", {
    Size = UDim2.new(1, -118, 1, -80),
    Position = UDim2.fromOffset(118, 56),
    BackgroundTransparency = 1,
}, main)
new("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 14) }, content)

local footer = new("Frame", {
    Size = UDim2.new(1, -118, 0, 24),
    Position = UDim2.new(0, 118, 1, -24),
    BackgroundColor3 = Color3.fromRGB(9, 9, 13),
    BorderSizePixel = 0,
}, main)
new("TextLabel", {
    Text = "Z — меню",
    Font = Enum.Font.Gotham,
    TextSize = 10,
    TextColor3 = Color3.fromRGB(90, 90, 108),
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(12, 4),
    Size = UDim2.new(1, -24, 0, 16),
    TextXAlignment = Enum.TextXAlignment.Left,
}, footer)

local pages, tabs, tabBars = {}, {}, {}
local function page(name)
    local f = new("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = CONFIG.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
    }, content)
    new("UIListLayout", { Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder }, f)
    pages[name] = f
    return f
end

local function tabButton(label, key)
    local b = new("TextButton", {
        Text = label,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextColor3 = Color3.fromRGB(138, 138, 156),
        BackgroundColor3 = Color3.fromRGB(16, 16, 22),
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Size = UDim2.new(1, 0, 0, 30),
    }, sidebar)
    new("UICorner", { CornerRadius = UDim.new(0, 8) }, b)

    local bar = new("Frame", {
        Size = UDim2.new(0, 3, 0, 0),
        Position = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3 = CONFIG.Accent,
        BorderSizePixel = 0,
    }, b)
    new("UICorner", { CornerRadius = UDim.new(1, 0) }, bar)

    tabs[key], tabBars[key] = b, bar

    b.MouseEnter:Connect(function()
        if not pages[key].Visible then tw(b, 0.14, { BackgroundColor3 = Color3.fromRGB(24, 24, 34) }) end
    end)
    b.MouseLeave:Connect(function()
        if not pages[key].Visible then tw(b, 0.14, { BackgroundColor3 = Color3.fromRGB(16, 16, 22) }) end
    end)
    b.MouseButton1Click:Connect(function()
        for k, p in pairs(pages) do p.Visible = (k == key) end
        for k, t in pairs(tabs) do
            tw(t, 0.16, {
                TextColor3 = (k == key) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(138, 138, 156),
                BackgroundColor3 = (k == key) and Color3.fromRGB(32, 25, 62) or Color3.fromRGB(16, 16, 22),
            })
            local bb = tabBars[k]
            if k == key then
                tw(bb, 0.18, { Size = UDim2.new(0, 3, 0, 16), Position = UDim2.new(0, 0, 0.5, -8) })
            else
                tw(bb, 0.18, { Size = UDim2.new(0, 3, 0, 0), Position = UDim2.new(0, 0, 0.5, 0) })
            end
        end
        local pg = pages[key]
        if pg then
            pg.Position = UDim2.fromOffset(10, 0)
            tw(pg, 0.2, { Position = UDim2.fromOffset(0, 0) })
        end
    end)
    return b
end

local function section(parent, text)
    new("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Color3.fromRGB(26, 26, 36),
        BorderSizePixel = 0,
    }, parent)
    return new("TextLabel", {
        Text = string.upper(text),
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextColor3 = CONFIG.Accent,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 16),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, parent)
end

local function row(parent)
    return new("Frame", { Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1 }, parent)
end

local function toggle(parent, text, default, cb)
    local r = row(parent)
    new("TextLabel", {
        Text = text, Font = Enum.Font.Gotham, TextSize = 13,
        TextColor3 = Color3.fromRGB(208, 208, 222), BackgroundTransparency = 1,
        Size = UDim2.new(1, -44, 1, 0), TextXAlignment = Enum.TextXAlignment.Left,
    }, r)
    local pill = new("Frame", {
        Size = UDim2.fromOffset(34, 18), Position = UDim2.new(1, -34, 0.5, -9),
        BackgroundColor3 = Color3.fromRGB(34, 34, 44), BorderSizePixel = 0,
    }, r)
    new("UICorner", { CornerRadius = UDim.new(1, 0) }, pill)
    local knob = new("Frame", {
        Size = UDim2.fromOffset(14, 14), Position = UDim2.fromOffset(2, 2),
        BackgroundColor3 = Color3.fromRGB(212, 212, 226), BorderSizePixel = 0,
    }, pill)
    new("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)

    local state = default
    local function render(instant)
        local info = TweenInfo.new(instant and 0 or 0.16, Enum.EasingStyle.Quad)
        TweenService:Create(knob, info, { Position = state and UDim2.fromOffset(18, 2) or UDim2.fromOffset(2, 2) }):Play()
        TweenService:Create(pill, info, { BackgroundColor3 = state and CONFIG.Accent or Color3.fromRGB(34, 34, 44) }):Play()
    end
    render(true)

    local function set(v)
        if state == v then return end
        state = v
        render()
        cb(v)
    end
    pill.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            set(not state)
        end
    end)
    return { set = set, get = function() return state end }
end

local function slider(parent, text, min, max, default, cb)
    local holder = new("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1 }, parent)
    new("TextLabel", {
        Text = text, Font = Enum.Font.Gotham, TextSize = 13,
        TextColor3 = Color3.fromRGB(208, 208, 222), BackgroundTransparency = 1,
        Size = UDim2.new(1, -60, 0, 18), TextXAlignment = Enum.TextXAlignment.Left,
    }, holder)
    local valueLabel = new("TextLabel", {
        Text = tostring(default), Font = Enum.Font.GothamMedium, TextSize = 12,
        TextColor3 = CONFIG.Accent, BackgroundTransparency = 1,
        Size = UDim2.fromOffset(56, 18), Position = UDim2.new(1, -56, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Right,
    }, holder)
    local trackF = new("Frame", {
        Size = UDim2.new(1, 0, 0, 5), Position = UDim2.fromOffset(0, 26),
        BackgroundColor3 = Color3.fromRGB(30, 30, 40), BorderSizePixel = 0,
    }, holder)
    new("UICorner", { CornerRadius = UDim.new(1, 0) }, trackF)
    local fill = new("Frame", {
        Size = UDim2.fromScale((default - min) / (max - min), 1),
        BackgroundColor3 = CONFIG.Accent, BorderSizePixel = 0,
    }, trackF)
    new("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)

    local value = default
    local function apply(px)
        local rel = math.clamp((px - trackF.AbsolutePosition.X) / trackF.AbsoluteSize.X, 0, 1)
        value = math.floor(min + rel * (max - min) + 0.5)
        fill.Size = UDim2.fromScale(rel, 1)
        valueLabel.Text = tostring(value)
        cb(value)
    end
    trackF.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            apply(i.Position.X)
            local conn
            conn = UIS.InputChanged:Connect(function(m)
                if m.UserInputType == Enum.UserInputType.MouseMovement or m.UserInputType == Enum.UserInputType.Touch then
                    apply(m.Position.X)
                end
            end)
            UIS.InputEnded:Connect(function(e)
                if e.UserInputType == Enum.UserInputType.MouseButton1 or e.UserInputType == Enum.UserInputType.Touch then
                    if conn then conn:Disconnect() end
                end
            end)
        end
    end)
    return { set = function(v) value = v end, get = function() return value end }
end

local function button(parent, text, cb)
    local b = new("TextButton", {
        Text = text, Font = Enum.Font.GothamMedium, TextSize = 13,
        TextColor3 = Color3.fromRGB(230, 230, 242),
        BackgroundColor3 = Color3.fromRGB(20, 20, 28), BorderSizePixel = 0,
        AutoButtonColor = false, Size = UDim2.new(1, 0, 0, 30),
    }, parent)
    new("UICorner", { CornerRadius = UDim.new(0, 8) }, b)
    b.MouseEnter:Connect(function() tw(b, 0.14, { BackgroundColor3 = CONFIG.AccentDim }) end)
    b.MouseLeave:Connect(function() tw(b, 0.14, { BackgroundColor3 = Color3.fromRGB(20, 20, 28) }) end)
    b.MouseButton1Click:Connect(cb)
    return b
end

local function chips(parent, items, current, cb, perRow)
    local cols = perRow or 4
    local grid = new("Frame", {
        Size = UDim2.new(1, 0, 0, math.ceil(#items / cols) * 26),
        BackgroundTransparency = 1,
    }, parent)
    new("UIGridLayout", {
        CellSize = UDim2.new(1 / cols, -3, 0, 22),
        CellPadding = UDim2.new(0, 3, 0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, grid)
    local made = {}
    local function paint(animate)
        for value, b in pairs(made) do
            local target = (value == current) and CONFIG.AccentDim or Color3.fromRGB(22, 22, 30)
            if animate then tw(b, 0.15, { BackgroundColor3 = target }) else b.BackgroundColor3 = target end
        end
    end
    for i, item in ipairs(items) do
        local b = new("TextButton", {
            Text = item.name,
            Font = Enum.Font.GothamMedium,
            TextSize = 11,
            TextColor3 = item.color or Color3.fromRGB(202, 202, 218),
            BackgroundColor3 = Color3.fromRGB(22, 22, 30),
            BorderSizePixel = 0,
            AutoButtonColor = false,
            LayoutOrder = i,
        }, grid)
        new("UICorner", { CornerRadius = UDim.new(0, 6) }, b)
        made[item.value] = b
        b.MouseEnter:Connect(function()
            if item.value ~= current then tw(b, 0.12, { BackgroundColor3 = Color3.fromRGB(32, 32, 44) }) end
        end)
        b.MouseLeave:Connect(function()
            if item.value ~= current then tw(b, 0.12, { BackgroundColor3 = Color3.fromRGB(22, 22, 30) }) end
        end)
        b.MouseButton1Click:Connect(function()
            current = item.value
            paint(true)
            cb(item.value)
        end)
    end
    paint(false)
    return grid
end

local function listBox(parent, height)
    local frame = new("ScrollingFrame", {
        Size = UDim2.new(1, 0, 0, height or 118),
        BackgroundColor3 = Color3.fromRGB(13, 13, 18),
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = CONFIG.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, parent)
    new("UICorner", { CornerRadius = UDim.new(0, 8) }, frame)
    new("UIStroke", { Color = Color3.fromRGB(38, 34, 58), Transparency = 0.5, Thickness = 1 }, frame)
    local list = new("Frame", { Size = UDim2.new(1, -8, 0, 0), Position = UDim2.fromOffset(4, 4), BackgroundTransparency = 1 }, frame)
    new("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, list)
    new("UIPadding", { PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 2) }, list)
    return list
end

local function fillList(list, items, current, cb)
    for _, c in ipairs(list:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    local made = {}
    local function paint()
        for v, b in pairs(made) do
            b.BackgroundColor3 = (v == current) and CONFIG.AccentDim or Color3.fromRGB(19, 19, 26)
            b.TextColor3 = (v == current) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(196, 196, 212)
        end
    end
    for i, name in ipairs(items) do
        local b = new("TextButton", {
            Text = name,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextColor3 = Color3.fromRGB(196, 196, 212),
            BackgroundColor3 = Color3.fromRGB(19, 19, 26),
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Size = UDim2.new(1, 0, 0, 24),
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = i,
        }, list)
        new("UICorner", { CornerRadius = UDim.new(0, 6) }, b)
        new("UIPadding", { PaddingLeft = UDim.new(0, 8) }, b)
        made[name] = b
        b.MouseEnter:Connect(function()
            if name ~= current then b.BackgroundColor3 = Color3.fromRGB(28, 28, 38) end
        end)
        b.MouseLeave:Connect(paint)
        b.MouseButton1Click:Connect(function()
            current = name
            paint()
            cb(name)
        end)
    end
    paint()
end

--==============================================================
--  ГЕОМЕТРИЯ
--==============================================================
local BLOCKED_PARTS = {
    HumanoidRootPart = true, RootPart = true, Root = true,
    Hitbox = true, HitBox = true, HitboxPart = true, HitPart = true,
    Collision = true, Collider = true, CollisionBox = true,
}

local function visualFor(char, owner)
    if not char then return nil end
    for _, d in ipairs(char:GetChildren()) do
        if d:IsA("Model") then
            local n = 0
            for _, p in ipairs(d:GetDescendants()) do
                if p:IsA("BasePart") and p.Transparency < 0.95 then
                    n += 1
                    if n >= 3 then return d end
                end
            end
        end
    end
    local cam = camera or Workspace.CurrentCamera
    if cam then
        for _, d in ipairs(cam:GetChildren()) do
            if d:IsA("Model") then
                if owner and d.Name:find(owner.Name, 1, true) then return d end
                if d.Name == char.Name then return d end
            end
        end
    end
    return nil
end

local function buildBounds(model, root)
    local anchorPos = root and root.Position
    local parts = {}
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("BasePart") and d.Transparency < 0.95 and not BLOCKED_PARTS[d.Name] then
            local mag = d.Size.Magnitude
            if mag > 0 and mag <= 16 and (not anchorPos or (d.Position - anchorPos).Magnitude <= 6) then
                parts[#parts + 1] = d
                if #parts >= 60 then break end
            end
        end
    end
    if #parts == 0 then return nil end

    local anchorPart, bestVol = nil, 0
    for _, p in ipairs(parts) do
        local v = p.Size.X * p.Size.Y * p.Size.Z
        if v > bestVol then anchorPart, bestVol = p, v end
    end
    if not anchorPart then return nil end
    local ap = anchorPart.Position

    local mn, mx
    for _, p in ipairs(parts) do
        if (p.Position - ap).Magnitude <= 4.5 then
            local a, b = p.Position - p.Size * 0.5, p.Position + p.Size * 0.5
            if mn then
                mn = Vector3.new(math.min(mn.X, a.X), math.min(mn.Y, a.Y), math.min(mn.Z, a.Z))
                mx = Vector3.new(math.max(mx.X, b.X), math.max(mx.Y, b.Y), math.max(mx.Z, b.Z))
            else
                mn, mx = a, b
            end
        end
    end
    return mn, mx
end

local function projectBounds(cam, mn, mx)
    local minX, minY, maxX, maxY
    for i = 0, 7 do
        local c = Vector3.new(
            (i % 2 == 0) and mn.X or mx.X,
            (i % 4 < 2) and mn.Y or mx.Y,
            (i < 4) and mn.Z or mx.Z
        )
        local sp, on = cam:WorldToViewportPoint(c)
        if on and sp.Z > 0 then
            minX = math.min(minX or sp.X, sp.X)
            maxX = math.max(maxX or sp.X, sp.X)
            minY = math.min(minY or sp.Y, sp.Y)
            maxY = math.max(maxY or sp.Y, sp.Y)
        end
    end
    if not minX then return nil end
    return minX, minY, maxX, maxY
end

--==============================================================
--  ESP
--==============================================================
local FONT = (Drawing and Drawing.Fonts and Drawing.Fonts.UI) or 2

local function sq(filled)
    local o = Drawing.new("Square")
    o.Filled = filled
    o.Visible = false
    o.Thickness = 1
    return o
end

local function newRec()
    local rec = { all = {}, corners = {} }
    local function add(o) rec.all[#rec.all + 1] = o return o end
    rec.outline = add(sq(false))
    rec.box = add(sq(false))
    rec.hpBg = add(sq(true))
    rec.hp = add(sq(true))
    rec.name = add(Drawing.new("Text"))
    rec.dist = add(Drawing.new("Text"))
    rec.hpText = add(Drawing.new("Text"))
    for _, t in ipairs({ rec.name, rec.dist, rec.hpText }) do
        t.Center = true
        t.Outline = true
        t.Font = FONT
        t.OutlineColor = Color3.fromRGB(0, 0, 0)
    end
    for i = 1, 8 do rec.corners[i] = add(sq(false)) end
    return rec
end

local recs = {}

local function recFor(model)
    local r = recs[model]
    if not r then
        r = newRec()
        recs[model] = r
    end
    return r
end

local function dropRec(model)
    local r = recs[model]
    if not r then return end
    for _, o in ipairs(r.all) do pcall(function() o:Remove() end) end
    recs[model] = nil
end

local function hide(rec)
    rec.box.Filled = false
    for i = 1, #rec.all do rec.all[i].Visible = false end
    rec.lastW = nil
    rec.lastH = nil
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true
local visState, visClock = {}, {}

local function put(s, x, y, w, h, col)
    s.Color = col
    s.Thickness = S.thickness
    s.Position = Vector2.new(x, y)
    s.Size = Vector2.new(w, h)
    s.Visible = true
end

local function drawBox(rec, x, y, w, h, col)
    local t = S.thickness
    put(rec.outline, x - 1, y - 1, w + 2, h + 2, Color3.fromRGB(0, 0, 0))
    rec.outline.Thickness = t + 1

    if S.style == "none" then
        rec.box.Visible = false
        return
    end
    if S.style == "full" then
        rec.box.Filled = false
        put(rec.box, x, y, w, h, col)
        return
    end
    if S.style == "dot" then
        rec.box.Filled = true
        put(rec.box, x + w / 2 - 3, y + h / 2 - 3, 6, 6, col)
        rec.box.Filled = false
        return
    end
    local c = math.clamp(CORNER_SIZE, 3, math.min(w / 2, h / 2))
    put(rec.corners[1], x, y, c, t, col)
    put(rec.corners[2], x, y, t, c, col)
    put(rec.corners[3], x + w - c, y, c, t, col)
    put(rec.corners[4], x + w - t, y, t, c, col)
    put(rec.corners[5], x, y + h - t, c, t, col)
    put(rec.corners[6], x, y + h - c, t, c, col)
    put(rec.corners[7], x + w - c, y + h - t, c, t, col)
    put(rec.corners[8], x + w - t, y + h - c, t, c, col)
end

local function drawTarget(rec, cam, camPos, char, geom, label, my, now, key)
    if not char or isDead(char) then hide(rec) return end

    local root = rootOf(char)
    if not root then hide(rec) return end

    local dist = (camPos - root.Position).Magnitude
    if dist > S.maxDist then hide(rec) return end

    rec.lastPos = root.Position
    rec.lastSeen = now
    rec.label = label

    local x, y, w, h, topPos
    local mn, mx = buildBounds(geom or char, root)

    if mn then
        local bx1, by1, bx2, by2 = projectBounds(cam, mn, mx)
        if not bx1 then hide(rec) return end
        local rawW, rawH = bx2 - bx1, by2 - by1
        if rawH > 0 and rawW > 0 and (rawH / rawW) < 9 then
            if rec.lastH then
                rec.lastH = rec.lastH + (rawH - rec.lastH) * 0.45
                rec.lastW = rec.lastW + (rawW - rec.lastW) * 0.45
            else
                rec.lastH, rec.lastW = rawH, rawW
            end
            h = math.max(rec.lastH, 2)
            w = math.max(rec.lastW, 2)
            x = (bx1 + bx2) / 2 - w / 2
            y = (by1 + by2) / 2 - h / 2
            topPos = Vector3.new((mn.X + mx.X) / 2, mx.Y, (mn.Z + mx.Z) / 2)
        else
            mn = nil
        end
    end

    if not mn then
        local head = char:FindFirstChild("Head")
        topPos = head
            and (head.Position + Vector3.new(0, head.Size.Y * 0.5 + 0.4, 0))
            or (root.Position + Vector3.new(0, 2.6, 0))
        local botPos = root.Position - Vector3.new(0, 2.8, 0)

        local sTop, onTop = cam:WorldToViewportPoint(topPos)
        local sBot, onBot = cam:WorldToViewportPoint(botPos)
        if not (onTop and onBot) or sTop.Z <= 0 or sBot.Z <= 0 or sBot.Y <= sTop.Y then
            hide(rec)
            return
        end
        local rawH = sBot.Y - sTop.Y
        local rawW = rawH * 0.42
        if rec.lastH then
            rec.lastH = rec.lastH + (rawH - rec.lastH) * 0.45
            rec.lastW = rec.lastW + (rawW - rec.lastW) * 0.45
        else
            rec.lastH, rec.lastW = rawH, rawW
        end
        h = math.max(rec.lastH, 2)
        w = math.max(rec.lastW, 2)
        x = sTop.X - w / 2
        y = sTop.Y
    end

    if not visClock[key] or now - visClock[key] > 0.15 then
        visClock[key] = now
        local filter = { char }
        if my and my ~= char then table.insert(filter, my) end
        local camNow = camera or Workspace.CurrentCamera
        if camNow then table.insert(filter, camNow) end
        rayParams.FilterDescendantsInstances = filter
        local hit = Workspace:Raycast(camPos, topPos - camPos, rayParams)
        visState[key] = (hit == nil
            or hit.Instance:IsDescendantOf(char)
            or (camNow ~= nil and hit.Instance:IsDescendantOf(camNow)))
    end

    local hum = char:FindFirstChildOfClass("Humanoid")
    local hp = hum and hum.Health or tonumber(char:GetAttribute("Health")) or 100
    local maxHp = hum and math.max(hum.MaxHealth, 1) or 100
    local frac = math.clamp(hp / maxHp, 0, 1)
    local col = (visState[key] == false) and S.colorHidden or S.colorStatic

    drawBox(rec, x, y, w, h, col)

    if S.hpMode == "bar" then
        rec.hpBg.Position = Vector2.new(x - 6, y)
        rec.hpBg.Size = Vector2.new(3, h)
        rec.hpBg.Color = Color3.fromRGB(20, 20, 26)
        rec.hpBg.Visible = true
        rec.hp.Position = Vector2.new(x - 6, y + h * (1 - frac))
        rec.hp.Size = Vector2.new(3, h * frac)
        rec.hp.Color = Color3.fromRGB(90, 220, 120):Lerp(Color3.fromRGB(230, 70, 70), 1 - frac)
        rec.hp.Visible = true
        rec.hpText.Visible = false
    elseif S.hpMode == "text" then
        rec.hpBg.Visible = false
        rec.hp.Visible = false
        rec.hpText.Text = tostring(math.floor(hp))
        rec.hpText.Size = TEXT_SIZE
        rec.hpText.Color = Color3.fromRGB(90, 220, 120):Lerp(Color3.fromRGB(230, 70, 70), 1 - frac)
        rec.hpText.Position = Vector2.new(x + w / 2, y + h + 3)
        rec.hpText.Visible = true
    else
        rec.hpBg.Visible = false
        rec.hp.Visible = false
        rec.hpText.Visible = false
    end

    if label then
        rec.name.Text = label
        rec.name.Size = TEXT_SIZE
        rec.name.Color = col
        rec.name.Position = Vector2.new(x + w / 2, y - TEXT_SIZE - 3)
        rec.name.Visible = true
    else
        rec.name.Visible = false
    end

    if S.showDist then
        rec.dist.Text = string.format("%d m", math.floor(dist / 3.5))
        rec.dist.Size = TEXT_SIZE - 1
        rec.dist.Color = col
        rec.dist.Position = Vector2.new(x + w / 2, y + h + (S.hpMode == "text" and 17 or 3))
        rec.dist.Visible = true
    else
        rec.dist.Visible = false
    end
end

local function drawGhost(rec, cam, camPos, pos, label)
    local mn = pos + Vector3.new(-0.85, -2.7, -0.85)
    local mx = pos + Vector3.new(0.85, 2.5, 0.85)
    local bx1, by1, bx2, by2 = projectBounds(cam, mn, mx)
    if not bx1 then hide(rec) return end

    local w = math.max(bx2 - bx1, 2)
    local h = math.max(by2 - by1, 2)
    local x = (bx1 + bx2) / 2 - w / 2
    local y = (by1 + by2) / 2 - h / 2
    local col = S.colorHidden

    drawBox(rec, x, y, w, h, col)
    rec.hpBg.Visible = false
    rec.hp.Visible = false
    rec.hpText.Visible = false

    rec.name.Text = (label or "?") .. " · last"
    rec.name.Size = TEXT_SIZE
    rec.name.Color = col
    rec.name.Position = Vector2.new(x + w / 2, y - TEXT_SIZE - 3)
    rec.name.Visible = true

    if S.showDist then
        rec.dist.Text = string.format("%d m", math.floor((camPos - pos).Magnitude / 3.5))
        rec.dist.Size = TEXT_SIZE - 1
        rec.dist.Color = col
        rec.dist.Position = Vector2.new(x + w / 2, y + h + 3)
        rec.dist.Visible = true
    else
        rec.dist.Visible = false
    end
end

local targets = {}

task.spawn(function()
    while not dead and task.wait(0.2) do
        local list = {}
        pcall(function()
            eachCandidate(function(m)
                if modelOwner[m] or m:GetAttribute("Bot") == true then
                    list[m] = true
                end
            end)
        end)
        targets = list
    end
end)

local function frameUpdate()
    if dead or not S.espEnabled or not hasDrawing or S.simpleMode then return end
    local cam = camera or Workspace.CurrentCamera
    if not cam then return end

    local camPos = cam.CFrame.Position
    local now = os.clock()
    local my = myChar()
    local myTeam = teamOf(lp)

    for model in pairs(targets) do
        local rec = recFor(model)
        local owner = modelOwner[model]
        local skip = false

        if owner == lp and not S.showLocal then
            skip = true
        elseif not owner and not S.showBots then
            skip = true
        elseif S.teamCheck and myTeam then
            local t = teamOfModel(model, owner)
            if t and t == myTeam then skip = true end
        end

        if skip or not model.Parent then
            hide(rec)
            rec.lastPos = nil
        else
            drawTarget(rec, cam, camPos, model, visualFor(model, owner), owner and owner.Name or "BOT", my, now, model)
        end
    end

    for model, rec in pairs(recs) do
        if not targets[model] then
            if rec.lastPos and (now - (rec.lastSeen or 0)) < GHOST_TIME then
                drawGhost(rec, cam, camPos, rec.lastPos, rec.label)
            else
                dropRec(model)
                visState[model] = nil
                visClock[model] = nil
            end
        end
    end
end

track(RunService.RenderStepped:Connect(function()
    if dead then return end
    pcall(frameUpdate)
end))

--==============================================================
--  ПРОСТОЙ РЕЖИМ
--==============================================================
local guiEsp = {}

local function updateGuiEsp()
    if not (S.espEnabled and S.simpleMode) then
        for m, t in pairs(guiEsp) do
            pcall(function() t.hl:Destroy() end)
            pcall(function() t.bg:Destroy() end)
        end
        guiEsp = {}
        return
    end

    local my = myChar()
    local myTeam = teamOf(lp)
    local wanted = {}

    for m in pairs(targets) do
        if m.Parent and m ~= my and not isDead(m) then
            local owner = modelOwner[m]
            local ok = true
            if owner == lp then
                ok = false
            elseif not owner then
                ok = S.showBots
            elseif S.teamCheck and myTeam then
                local t = teamOfModel(m, owner)
                if t and t == myTeam then ok = false end
            end
            if ok then wanted[m] = owner end
        end
    end

    for m, t in pairs(guiEsp) do
        if not wanted[m] or not m.Parent then
            pcall(function() t.hl:Destroy() end)
            pcall(function() t.bg:Destroy() end)
            guiEsp[m] = nil
        end
    end

    for m, owner in pairs(wanted) do
        local geom = visualFor(m, owner) or m
        local t = guiEsp[m]
        if not t then
            local hl = Instance.new("Highlight")
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.FillTransparency = 0.72
            hl.OutlineTransparency = 0
            hl.FillColor = S.colorStatic
            hl.OutlineColor = S.colorStatic
            hl.Parent = gui

            local bg = Instance.new("BillboardGui")
            bg.Size = UDim2.fromOffset(140, 34)
            bg.StudsOffsetWorldSpace = Vector3.new(0, 1.2, 0)
            bg.AlwaysOnTop = true
            bg.LightInfluence = 0
            bg.Parent = gui

            local txt = Instance.new("TextLabel")
            txt.Size = UDim2.fromScale(1, 1)
            txt.BackgroundTransparency = 1
            txt.Font = Enum.Font.GothamBold
            txt.TextSize = TEXT_SIZE
            txt.TextColor3 = S.colorStatic
            txt.TextStrokeTransparency = 0.4
            txt.Parent = bg

            t = { hl = hl, bg = bg, txt = txt }
            guiEsp[m] = t
        end
        t.hl.Adornee = geom
        t.hl.FillColor = S.colorStatic
        t.hl.OutlineColor = S.colorStatic
        t.bg.Adornee = geom
        t.txt.TextColor3 = S.colorStatic
        t.txt.Text = owner and owner.Name or "BOT"
    end
end

task.spawn(function()
    while not dead and task.wait(0.2) do
        pcall(updateGuiEsp)
    end
end)

--==============================================================
--  АВТОБХОП
--==============================================================
local lastJump = 0
local jumpCount = 0
local lastState = "-"

local function realState(hum)
    selfRead = true
    local ok, st = pcall(function() return hum:GetState() end)
    selfRead = false
    if ok then return st end
    return nil
end

track(RunService.RenderStepped:Connect(function()
    if dead or not S.bhop then return end
    if not UIS:IsKeyDown(Enum.KeyCode.Space) then
        lastState = "no key"
        return
    end

    local char = myChar()
    if not char then lastState = "no char" return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then lastState = "no hum" return end

    local st = realState(hum)
    lastState = tostring(st):gsub("Enum.HumanoidStateType.", "")
    if st == Enum.HumanoidStateType.Jumping or st == Enum.HumanoidStateType.Freefall then
        return
    end

    local now = os.clock()
    if now - lastJump < 0.06 then return end

    lastJump = now
    jumpCount += 1
    pcall(function() hum.Jump = true end)
end))

--==============================================================
--  NO AIR SPREAD
--==============================================================
local origIndex, origNamecall
local hookedIndex, hookedNamecall = false, false

if typeof(hookmetamethod) == "function" then
    hookedIndex = pcall(function()
        origIndex = hookmetamethod(game, "__index", function(self, key)
            if key == "FloorMaterial" and S.noAirSpread and not selfRead then
                if rawequal(self, myHum()) then
                    local real = origIndex(self, key)
                    if real == Enum.Material.Air then return Enum.Material.Plastic end
                    return real
                end
            end
            return origIndex(self, key)
        end)
    end)
end

if typeof(hookmetamethod) == "function" and typeof(getnamecallmethod) == "function" then
    hookedNamecall = pcall(function()
        origNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if method == "GetState" and S.noAirSpread and not selfRead then
                if rawequal(self, myHum()) then
                    local st = origNamecall(self, ...)
                    if st == Enum.HumanoidStateType.Freefall or st == Enum.HumanoidStateType.Jumping then
                        return Enum.HumanoidStateType.Running
                    end
                    return st
                end
            end
            return origNamecall(self, ...)
        end)
    end)
end

--==============================================================
--  СКИНЧЕНДЖЕР
--==============================================================
local Assets = ReplicatedStorage:FindFirstChild("Assets")
local SkinsFolder = Assets and Assets:FindFirstChild("Skins")
if not SkinsFolder then
    task.spawn(function()
        local ok, a = pcall(function() return ReplicatedStorage:WaitForChild("Assets", 25) end)
        if ok and a then
            Assets = a
            SkinsFolder = a:FindFirstChild("Skins") or a:WaitForChild("Skins", 25)
        end
    end)
end

local KNIFE_WORDS = { "knife", "karambit", "bayonet", "lightsaber" }

local function isKnife(name)
    if type(name) ~= "string" then return false end
    local low = string.lower(name)
    if low:find("zeus", 1, true) then return false end
    for _, w in ipairs(KNIFE_WORDS) do
        if low:find(w, 1, true) then return true end
    end
    return false
end

local WEAR_ORDER = { "Factory New", "Minimal Wear", "Field-Tested", "Well-Worn", "Battle-Scarred" }

local function wearOf(skin)
    local camFolder = skin:FindFirstChild("Camera")
    if not camFolder then return nil end
    for _, w in ipairs(WEAR_ORDER) do
        local f = camFolder:FindFirstChild(w)
        if f then return f end
    end
    return camFolder:GetChildren()[1]
end

local function skinWorks(skin)
    if skin.Name:find("PATTERN") then return false end
    local wear = wearOf(skin)
    if not wear then return false end
    for _, c in ipairs(wear:GetChildren()) do
        if c:IsA("SurfaceAppearance") then return true end
    end
    return false
end

local function knifeList()
    local out = {}
    if SkinsFolder then
        for _, f in ipairs(SkinsFolder:GetChildren()) do
            if isKnife(f.Name) then table.insert(out, f.Name) end
        end
    end
    table.sort(out)
    return out
end

local function skinList(knife)
    local out = {}
    if not SkinsFolder or not knife then return out end
    local f = SkinsFolder:FindFirstChild(knife)
    if not f then return out end
    for _, s in ipairs(f:GetChildren()) do
        if s:IsA("Folder") and skinWorks(s) then table.insert(out, s.Name) end
    end
    table.sort(out)
    return out
end

local function knifeViewmodels()
    local out = {}
    local c = camera or Workspace.CurrentCamera
    if not c then return out end
    for _, o in ipairs(c:GetChildren()) do
        if o:IsA("Model") and isKnife(o.Name) and o:FindFirstChild("Weapon") then
            out[#out + 1] = o
        end
    end
    return out
end

local function applySkinTo(vm, knife, skin)
    if not SkinsFolder or not vm then return false end
    local folder = SkinsFolder:FindFirstChild(knife)
    if not folder then return false end
    local skinObj = folder:FindFirstChild(skin)
    if not skinObj then return false end
    local wear = wearOf(skinObj)
    if not wear then return false end

    local touched = 0
    for _, sa in ipairs(wear:GetChildren()) do
        if sa:IsA("SurfaceAppearance") then
            local part = vm:FindFirstChild(sa.Name, true)
            if part and part:IsA("BasePart") then
                local old = part:FindFirstChildOfClass("SurfaceAppearance")
                if old then pcall(function() old:Destroy() end) end
                local clone = sa:Clone()
                clone.Name = "SurfaceAppearance"
                clone.Parent = part
                touched += 1
            end
        end
    end
    return touched > 0
end

local function applySkin()
    if not S.knife or not S.skin then return false end
    local ok = false
    for _, vm in ipairs(knifeViewmodels()) do
        if applySkinTo(vm, S.knife, S.skin) then ok = true end
    end
    return ok
end

local function resetSkins()
    for _, vm in ipairs(knifeViewmodels()) do
        for _, d in ipairs(vm:GetDescendants()) do
            if d:IsA("SurfaceAppearance") then pcall(function() d:Destroy() end) end
        end
    end
end

--==============================================================
--  ПОДМЕНА МОДЕЛИ НОЖА
--==============================================================
local hookedEngine = false
local origWeaponNew, origGetCameraModel
local WeaponComponent, SkinsLib

local function engineAlive()
    local c = myChar()
    if not c or c.Parent ~= charsFolder() then return false end
    return not isDead(c)
end

local function installEngineHooks()
    if hookedEngine or typeof(hookfunction) ~= "function" then return end

    pcall(function() WeaponComponent = require(ReplicatedStorage.Classes.WeaponComponent) end)
    pcall(function() SkinsLib = require(ReplicatedStorage.Database.Components.Libraries.Skins) end)
    if not WeaponComponent or not SkinsLib then return end

    local ok1 = pcall(function()
        origWeaponNew = WeaponComponent.new
        WeaponComponent.new = function(p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, ...)
            if S.swapKnife and S.knife and p1 == lp and engineAlive() and isKnife(p5) then
                return origWeaponNew(p1, p2, p3, p4, S.knife, S.skin or "Vanilla", 0.001, p8, p9, p10, p11, p12, ...)
            end
            return origWeaponNew(p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, ...)
        end
    end)

    local ok2 = pcall(function()
        origGetCameraModel = SkinsLib.GetCameraModel
        SkinsLib.GetCameraModel = function(weaponName, skinName, float, statTrack, nameTag, charm, stickers, team)
            if S.swapKnife and S.knife and isKnife(weaponName) and engineAlive() then
                local model = origGetCameraModel(S.knife, S.skin or "Vanilla", 0.001, statTrack, nameTag, charm, stickers, team)
                if model then model.Name = S.knife end
                return model
            end
            return origGetCameraModel(weaponName, skinName, float, statTrack, nameTag, charm, stickers, team)
        end
    end)

    hookedEngine = ok1 or ok2
end

local function removeEngineHooks()
    if not hookedEngine then return end
    if WeaponComponent and origWeaponNew then pcall(function() WeaponComponent.new = origWeaponNew end) end
    if SkinsLib and origGetCameraModel then pcall(function() SkinsLib.GetCameraModel = origGetCameraModel end) end
    hookedEngine = false
end

task.spawn(function()
    while not dead and task.wait(0.5) do
        if S.swapKnife then installEngineHooks() end
        if S.holdSkin and S.skin and S.knife then applySkin() end
    end
end)

--==============================================================
--  ДИАГНОСТИКА
--==============================================================
local function diagnose()
    local out = {}
    table.insert(out, "Drawing: " .. tostring(hasDrawing))
    table.insert(out, "Целей: " .. tostring((function() local n = 0 for _ in pairs(targets) do n += 1 end return n end)()))
    table.insert(out, "Мой персонаж: " .. tostring(myChar()))
    table.insert(out, "state: " .. tostring(lastState))
    table.insert(out, "Прыжков: " .. tostring(jumpCount))
    local hum = myHum()
    if hum then
        table.insert(out, "hum state: " .. tostring(realState(hum)))
        table.insert(out, "floor: " .. tostring(hum.FloorMaterial))
        local root = hum.RootPart or rootOf(hum.Parent)
        if root then
            table.insert(out, "anchored: " .. tostring(root.Anchored))
            table.insert(out, "y: " .. tostring(root.Position.Y))
        end
    end
    local text = table.concat(out, "\n")
    print("[SleepScript] ДИАГНОСТИКА\n" .. text)
    if setclipboard then pcall(setclipboard, text) end
    notify("Диагностика скопирована")
end

local function dumpStructure()
    local out = {}
    local n = 0
    for _, c in ipairs(Workspace:GetChildren()) do
        n += 1
        if n > 60 then break end
        local extra = ""
        if c:IsA("Folder") or c:IsA("Model") then extra = " kids=" .. tostring(#c:GetChildren()) end
        table.insert(out, c.Name .. " [" .. c.ClassName .. "]" .. extra)
    end
    local text = table.concat(out, "\n")
    print("[SleepScript] СТРУКТУРА\n" .. text)
    if setclipboard then pcall(setclipboard, text) end
    notify("Структура скопирована")
end

--==============================================================
--  СТРАНИЦЫ
--==============================================================
local visualPage = page("visual"); tabButton("Визуал", "visual")
local movePage   = page("move");   tabButton("Движение", "move")
local skinPage   = page("skin");   tabButton("Скины", "skin")
local miscPage   = page("misc");   tabButton("Прочее", "misc")

section(visualPage, "основа")
toggle(visualPage, "Включить ESP", false, function(v)
    S.espEnabled = v
    if v and not hasDrawing then notify("Нет Drawing API") end
end)
toggle(visualPage, "Простой режим (подсветка)", false, function(v) S.simpleMode = v end)
toggle(visualPage, "Игнорировать своих", true, function(v) S.teamCheck = v end)
toggle(visualPage, "Показывать ботов", true, function(v) S.showBots = v end)
toggle(visualPage, "Показывать себя", false, function(v) S.showLocal = v end)
slider(visualPage, "Макс. дистанция", 100, 5000, 2000, function(v) S.maxDist = v end)

section(visualPage, "вид")
chips(visualPage, {
    { name = "Уголки", value = "corner" },
    { name = "Бокс", value = "full" },
    { name = "Точка", value = "dot" },
    { name = "Нет", value = "none" },
}, S.style, function(v) S.style = v end)
slider(visualPage, "Толщина", 1, 4, 1, function(v) S.thickness = v end)
toggle(visualPage, "Дистанция", true, function(v) S.showDist = v end)
chips(visualPage, {
    { name = "HP: полоска", value = "bar" },
    { name = "HP: цифры", value = "text" },
    { name = "HP: нет", value = "off" },
}, S.hpMode, function(v) S.hpMode = v end, 3)

local PALETTE = {
    { name = "Белый", c = Color3.fromRGB(235, 235, 245) },
    { name = "Фиолет", c = Color3.fromRGB(160, 130, 255) },
    { name = "Циан", c = Color3.fromRGB(80, 225, 255) },
    { name = "Лайм", c = Color3.fromRGB(160, 255, 90) },
    { name = "Красный", c = Color3.fromRGB(255, 90, 90) },
    { name = "Оранж", c = Color3.fromRGB(255, 160, 70) },
    { name = "Розовый", c = Color3.fromRGB(255, 120, 210) },
    { name = "Синий", c = Color3.fromRGB(100, 145, 255) },
}
local palItems = {}
for _, p in ipairs(PALETTE) do table.insert(palItems, { name = p.name, value = p.c, color = p.c }) end

section(visualPage, "цвет")
chips(visualPage, palItems, S.colorStatic, function(v) S.colorStatic = v end)
section(visualPage, "цвет за стеной")
chips(visualPage, palItems, S.colorHidden, function(v) S.colorHidden = v end)

section(movePage, "бхоп")
toggle(movePage, "Автобхоп (держать пробел)", false, function(v) S.bhop = v end)

local dbgLabel = new("TextLabel", {
    Text = "—",
    Font = Enum.Font.Code,
    TextSize = 11,
    TextColor3 = Color3.fromRGB(140, 140, 160),
    BackgroundColor3 = Color3.fromRGB(13, 13, 18),
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, 30),
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    TextWrapped = true,
}, movePage)
new("UICorner", { CornerRadius = UDim.new(0, 8) }, dbgLabel)
new("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingTop = UDim.new(0, 4) }, dbgLabel)

task.spawn(function()
    while not dead and task.wait(0.15) do
        if not S.bhop then
            dbgLabel.Text = "бхоп выключен"
            continue
        end
        dbgLabel.Text = string.format("state:%s jumps:%d space:%s",
            lastState, jumpCount, tostring(UIS:IsKeyDown(Enum.KeyCode.Space)))
    end
end)

section(movePage, "точность")
toggle(movePage, "Убрать разброс в полёте", false, function(v) S.noAirSpread = v end)

section(movePage, "камера")
toggle(movePage, "Фиксация FOV", false, function(v)
    if v and camera then fovOriginal = camera.FieldOfView end
    S.fovEnabled = v
    applyFov()
end)
slider(movePage, "FOV", 40, 120, 90, function(v)
    S.fovValue = v
    applyFov()
end)

section(skinPage, "нож")
local knifeBox = listBox(skinPage, 104)
local skinBox = listBox(skinPage, 104)

local function refreshSkins()
    local list = skinList(S.knife)
    S.skin = list[1]
    fillList(skinBox, list, S.skin, function(v) S.skin = v end)
end

fillList(knifeBox, knifeList(), nil, function(name)
    S.knife = name
    refreshSkins()
end)

section(skinPage, "скин")
button(skinPage, "Применить скин", function()
    if not S.knife then notify("Выбери нож") return end
    if not S.skin then notify("Выбери скин") return end
    applySkin()
end)
button(skinPage, "Сбросить скин", function()
    resetSkins()
    notify("Скин сброшен")
end)
toggle(skinPage, "Держать скин", true, function(v) S.holdSkin = v end)
toggle(skinPage, "Подменять модель ножа", false, function(v)
    S.swapKnife = v
    if v then
        installEngineHooks()
        notify(hookedEngine and "Подмена включена" or "Хуки недоступны")
    else
        removeEngineHooks()
    end
end)

section(miscPage, "служебное")
button(miscPage, "Диагностика (F9)", diagnose)
button(miscPage, "Дамп структуры", dumpStructure)
button(miscPage, "Закрыть меню (Z)", function() closeMenu() end)
button(miscPage, "Выгрузить скрипт", function()
    if env.SleepScript then env.SleepScript.Unload() end
end)

track(UIS.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == CONFIG.Keybind then
        if opened then closeMenu() else openMenu() end
    end
end))

pages.visual.Visible = true
tabs.visual.TextColor3 = Color3.fromRGB(255, 255, 255)
tabs.visual.BackgroundColor3 = Color3.fromRGB(32, 25, 62)
tabBars.visual.Size = UDim2.new(0, 3, 0, 16)
tabBars.visual.Position = UDim2.new(0, 0, 0.5, -8)

--==============================================================
--  ВЫГРУЗКА
--==============================================================
local function unload()
    dead = true
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    for model in pairs(recs) do dropRec(model) end
    for _, t in pairs(guiEsp) do
        pcall(function() t.hl:Destroy() end)
        pcall(function() t.bg:Destroy() end)
    end
    guiEsp = {}
    if hookedIndex and origIndex then pcall(function() hookmetamethod(game, "__index", origIndex) end) end
    if hookedNamecall and origNamecall then pcall(function() hookmetamethod(game, "__namecall", origNamecall) end) end
    removeEngineHooks()
    if camera then pcall(function() camera.FieldOfView = fovOriginal end) end
    pcall(function() blur:Destroy() end)
    pcall(function() gui:Destroy() end)
    env.SleepScript = nil
end

env.SleepScript = { Unload = unload, Settings = S }

notify("SleepScript загружен. Z — меню")

end, function(err)
    return tostring(err) .. "\n" .. debug.traceback()
end)

if not booted then
    warn("[SleepScript] ОШИБКА:\n" .. tostring(bootErr))
end
