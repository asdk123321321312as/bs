local CONFIG = {
    Accent    = Color3.fromRGB(140, 110, 255),
    AccentDim = Color3.fromRGB(44, 34, 92),
    Keybind   = Enum.KeyCode.Z,
    Version   = "3.2",
}

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

local Players           = cloneref(game:GetService("Players"))
local RunService        = cloneref(game:GetService("RunService"))
local UIS               = cloneref(game:GetService("UserInputService"))
local CAS               = cloneref(game:GetService("ContextActionService"))
local VIM               = cloneref(game:GetService("VirtualInputManager"))
local TweenService      = cloneref(game:GetService("TweenService"))
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local Lighting          = cloneref(game:GetService("Lighting"))
local HttpService       = cloneref(game:GetService("HttpService"))
local Workspace         = cloneref(workspace)
local lp                = Players.LocalPlayer

local S = {
    bhop = false,
    trigger = "space",
    interval = 0.3,
    lift = false,
    fovEnabled = false,
    fovValue = 90,
    weapon = nil,
    skin = nil,
    swapWeapon = false,
    holdSkin = true,
}

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
--  СОХРАНЕНИЕ
--==============================================================
local SAVE_FILE = "SleepScript.json"
local saveAt = 0

local function canSave()
    return typeof(writefile) == "function" and typeof(readfile) == "function"
end

local SAVE_KEYS = { "bhop", "trigger", "interval", "lift", "fovEnabled", "fovValue", "swapWeapon", "holdSkin" }

local function saveConfig()
    if not canSave() then return end
    local data = {}
    for _, k in ipairs(SAVE_KEYS) do data[k] = S[k] end
    data.weapon = S.weapon
    data.skin = S.skin
    local ok, enc = pcall(function() return HttpService:JSONEncode(data) end)
    if ok and enc then pcall(writefile, SAVE_FILE, enc) end
end

local function queueSave()
    saveAt = os.clock() + 0.6
end

local function loadConfig()
    if not canSave() or typeof(isfile) ~= "function" or not isfile(SAVE_FILE) then return end
    local ok, raw = pcall(readfile, SAVE_FILE)
    if not ok or not raw then return end
    local ok2, data = pcall(function() return HttpService:JSONDecode(raw) end)
    if not ok2 or type(data) ~= "table" then return end
    for _, k in ipairs(SAVE_KEYS) do
        if type(data[k]) == type(S[k]) then S[k] = data[k] end
    end
    if type(data.weapon) == "string" then S.weapon = data.weapon end
    if type(data.skin) == "string" then S.skin = data.skin end
end

loadConfig()

task.spawn(function()
    while not dead do
        task.wait(0.5)
        if saveAt > 0 and os.clock() >= saveAt then
            saveAt = 0
            saveConfig()
        end
    end
end)

--==============================================================
--  ПЕРСОНАЖ
--==============================================================
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

local function humOf(char)
    if not char then return nil end
    local h = char:FindFirstChild("Humanoid")
    if h and h:IsA("Humanoid") then return h end
    h = char:FindFirstChildOfClass("Humanoid")
    if h then return h end
    return nil
end

local myCache, myCacheAt = nil, 0

local function myChar()
    if myCache and myCache.Parent and os.clock() - myCacheAt < 0.2 then return myCache end
    local c = nil
    if lp.Character and lp.Character.Parent and rootOf(lp.Character) then
        c = lp.Character
    else
        local folder = charsFolder()
        local m = folder and folder:FindFirstChild(lp.Name)
        if m then c = m end
    end
    myCache, myCacheAt = c, os.clock()
    return c
end

local function pivotY(char)
    if not char then return 0 end
    local ok, piv = pcall(function() return char:GetPivot() end)
    if ok and piv then return piv.Position.Y end
    local r = rootOf(char)
    return r and r.Position.Y or 0
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
--  UI
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

local function toggle(parent, text, default, cb)
    local r = new("Frame", { Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1 }, parent)
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
        queueSave()
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
        queueSave()
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
            queueSave()
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
            queueSave()
        end)
    end
    paint()
end

--==============================================================
--  СКИНЫ
--==============================================================
local Assets = ReplicatedStorage:FindFirstChild("Assets")
local SkinsFolder = Assets and Assets:FindFirstChild("Skins")

local KNIFE_WORDS = {
    "knife", "karambit", "bayonet", "lightsaber", "dagger", "talon", "butterfly",
    "falchion", "bowie", "stiletto", "ursus", "nomad", "skeleton", "paracord",
    "survival", "huntsman", "navaja", "flip", "gut", "m9", "shadow", "classic",
}
local GLOVE_WORDS = { "glove", "hands", "wraps" }
local PISTOL_WORDS = { "pistol", "glock", "usp", "p250", "deagle", "desert", "revolver", "tec", "five", "cz", "dual", "beretta" }
local RIFLE_WORDS = { "rifle", "ak", "m4", "famas", "galil", "aug", "scar", "sg" }
local SMG_WORDS = { "smg", "mp", "p90", "ump", "mac", "bizon" }
local SHOT_WORDS = { "shotgun", "nova", "xm", "sawed", "mag" }
local SNIPE_WORDS = { "sniper", "awp", "ssg", "scout", "g3sg" }

local function hasWord(low, words)
    for _, w in ipairs(words) do
        if low:find(w, 1, true) then return true end
    end
    return false
end

local function categoryOf(name)
    if type(name) ~= "string" then return "other" end
    local low = string.lower(name)
    if hasWord(low, KNIFE_WORDS) then return "knife" end
    if hasWord(low, GLOVE_WORDS) then return "gloves" end
    if hasWord(low, PISTOL_WORDS) then return "pistol" end
    if hasWord(low, RIFLE_WORDS) then return "rifle" end
    if hasWord(low, SMG_WORDS) then return "smg" end
    if hasWord(low, SHOT_WORDS) then return "shotgun" end
    if hasWord(low, SNIPE_WORDS) then return "sniper" end
    return "other"
end

local function norm(s)
    return string.lower((tostring(s):gsub("[^%w]", "")))
end

local function matchesName(vmName, weapon)
    if not weapon or not vmName then return false end
    if vmName == weapon then return true end
    local a, b = norm(vmName), norm(weapon)
    if a == "" or b == "" then return false end
    return a:find(b, 1, true) ~= nil or b:find(a, 1, true) ~= nil
end

local WEAR_ORDER = { "factorynew", "minimalwear", "fieldtested", "wellworn", "battlescarred" }

local function firstSurface(inst)
    if not inst then return nil end
    for _, d in ipairs(inst:GetDescendants()) do
        if d:IsA("SurfaceAppearance") then return d end
    end
    return nil
end

local function wearOf(skin)
    local camFolder = skin:FindFirstChild("Camera")
    local root = camFolder or skin
    local folders = {}
    for _, c in ipairs(root:GetChildren()) do
        if c:IsA("Folder") or c:IsA("Model") then folders[c] = norm(c.Name) end
    end
    for _, w in ipairs(WEAR_ORDER) do
        for f, n in pairs(folders) do
            if n == w then return f end
        end
    end
    for f, n in pairs(folders) do
        if n:find("wear", 1, true) or n:find("factory", 1, true) then return f end
    end
    for f in pairs(folders) do
        if firstSurface(f) then return f end
    end
    if firstSurface(skin) then return skin end
    return nil
end

local function skinWorks(skin)
    if skin.Name:find("PATTERN") then return false end
    return firstSurface(skin) ~= nil
end

local weaponCache = nil

local function weaponList()
    return weaponCache or {}
end

local function skinList(weapon)
    local out = {}
    if not SkinsFolder or not weapon then return out end
    local f = SkinsFolder:FindFirstChild(weapon)
    if not f then return out end
    for _, s in ipairs(f:GetChildren()) do
        if (s:IsA("Folder") or s:IsA("Model")) and skinWorks(s) then table.insert(out, s.Name) end
    end
    table.sort(out)
    return out
end

local function isGloveName(n)
    return n:find("glove", 1, true) ~= nil or n:find("mitt", 1, true) ~= nil
end

local function isArmName(n)
    return n:find("arm", 1, true) ~= nil
        or n:find("hand", 1, true) ~= nil
        or n:find("sleeve", 1, true) ~= nil
        or isGloveName(n)
end

local function viewmodel()
    local cam = camera or Workspace.CurrentCamera
    if not cam then return nil end
    local camPos = cam.CFrame.Position
    local best, bestScore = nil, 0
    for _, o in ipairs(cam:GetChildren()) do
        if o:IsA("Model") then
            local score = 0
            for _, p in ipairs(o:GetDescendants()) do
                if p:IsA("BasePart") and p.Transparency < 0.95 and (p.Position - camPos).Magnitude < 9 then
                    score += 1
                end
            end
            if score > bestScore then
                best, bestScore = o, score
            end
        end
    end
    if bestScore >= 1 then return best end
    return nil
end

local function partNamesOf()
    local set = {}
    local folder = SkinsFolder and S.weapon and SkinsFolder:FindFirstChild(S.weapon)
    local obj = folder and S.skin and folder:FindFirstChild(S.skin)
    if not obj then return set end
    local wear = wearOf(obj)
    if not wear then return set end
    for _, d in ipairs(wear:GetDescendants()) do
        if d:IsA("SurfaceAppearance") then set[norm(d.Name)] = true end
    end
    return set
end

-- модель перчаток: по именам частей скина, по имени, по слову glove
local function gloveModel()
    local cam = camera or Workspace.CurrentCamera
    if not cam then return nil end
    local wanted = partNamesOf()
    local best, bestScore = nil, 0

    for _, o in ipairs(cam:GetChildren()) do
        if o:IsA("Model") then
            local score = 0
            local n = norm(o.Name)
            if S.weapon and matchesName(o.Name, S.weapon) then score += 10 end
            if n:find("glove", 1, true) then score += 8 end
            if n:find("arm", 1, true) then score += 2 end
            for _, p in ipairs(o:GetDescendants()) do
                if p:IsA("BasePart") then
                    local pn = norm(p.Name)
                    if wanted[pn] then score += 5 end
                    if isGloveName(pn) then score += 4 end
                    if pn:find("strap", 1, true) or pn:find("buckle", 1, true) or pn:find("finger", 1, true) then
                        score += 2
                    end
                end
            end
            if score > bestScore then
                best, bestScore = o, score
            end
        end
    end
    if bestScore >= 4 then return best end
    return nil
end

local pinnedGlove = nil

local function findPart(vm, name)
    local exact = vm:FindFirstChild(name, true)
    if exact and exact:IsA("BasePart") then return exact end
    local low = norm(name)
    if low == "" then return nil end
    for _, p in ipairs(vm:GetDescendants()) do
        if p:IsA("BasePart") and norm(p.Name) == low then return p end
    end
    return nil
end

local function putSurface(part, sa)
    local old = part:FindFirstChildOfClass("SurfaceAppearance")
    if old then pcall(function() old:Destroy() end) end
    local clone = sa:Clone()
    clone.Name = "SurfaceAppearance"
    clone.Parent = part
    return clone
end

local function applySkinTo(vm, weapon, skin)
    if not SkinsFolder or not vm or not vm.Parent then return nil end
    local folder = SkinsFolder:FindFirstChild(weapon)
    if not folder then return nil end
    local skinObj = folder:FindFirstChild(skin)
    if not skinObj then return nil end
    local wear = wearOf(skinObj)
    if not wear then return nil end

    local sources = {}
    for _, d in ipairs(wear:GetDescendants()) do
        if d:IsA("SurfaceAppearance") then sources[#sources + 1] = d end
    end
    if #sources == 0 then return nil end

    local gloves = categoryOf(weapon) == "gloves"
    local onCharacter = vm == myChar()
    local parts = {}
    for _, p in ipairs(vm:GetDescendants()) do
        if p:IsA("BasePart") then
            if gloves and onCharacter then
                if isArmName(norm(p.Name)) then parts[#parts + 1] = p end
            else
                parts[#parts + 1] = p
            end
        end
    end
    if #parts == 0 then
        for _, p in ipairs(vm:GetDescendants()) do
            if p:IsA("BasePart") then parts[#parts + 1] = p end
        end
    end
    if #parts == 0 then return nil end

    local refs = {}
    local used = {}
    for _, sa in ipairs(sources) do
        local part = findPart(vm, sa.Name)
        if part and not used[part] then
            used[part] = true
            local clone = putSurface(part, sa)
            refs[#refs + 1] = { part = part, sa = clone, map = clone.ColorMap }
        end
    end
    if #refs == 0 then
        table.sort(parts, function(a, b) return a.Name < b.Name end)
        for i, sa in ipairs(sources) do
            local part = parts[i]
            if not part then break end
            local clone = putSurface(part, sa)
            refs[#refs + 1] = { part = part, sa = clone, map = clone.ColorMap }
        end
    end
    if #refs == 0 then return nil end
    return refs
end

local applied = setmetatable({}, { __mode = "k" })
local lastAppliedName = "-"

local function targetsFor()
    local cat = categoryOf(S.weapon or "")
    local out = {}
    if cat == "gloves" then
        local g = (pinnedGlove and pinnedGlove.Parent) and pinnedGlove or gloveModel()
        if g then out[#out + 1] = g end
        local ch = myChar()
        if ch then out[#out + 1] = ch end
    else
        local vm = viewmodel()
        if vm then out[#out + 1] = vm end
    end
    return out
end

local function applyToTarget(vm)
    if not S.weapon or not S.skin or not vm or not vm.Parent then return false end
    local sig = S.weapon .. "|" .. S.skin
    local rec = applied[vm]
    if rec and rec.sig == sig then
        local alive = true
        for _, r in ipairs(rec.refs) do
            if not r.sa.Parent
                or r.part:FindFirstChildOfClass("SurfaceAppearance") ~= r.sa
                or r.sa.ColorMap ~= r.map then
                alive = false
                break
            end
        end
        if alive then return true end
    end
    local refs = applySkinTo(vm, S.weapon, S.skin)
    if not refs then return false end
    applied[vm] = { sig = sig, refs = refs }
    lastAppliedName = vm.Name
    return true
end

local function applySkin()
    if not S.weapon or not S.skin then return false end
    local ok = false
    for _, vm in ipairs(targetsFor()) do
        if applyToTarget(vm) then ok = true end
    end
    return ok
end

local function resetSkins()
    for vm in pairs(applied) do applied[vm] = nil end
    local cam = camera or Workspace.CurrentCamera
    if cam then
        for _, vm in ipairs(cam:GetChildren()) do
            if vm:IsA("Model") then
                for _, d in ipairs(vm:GetDescendants()) do
                    if d:IsA("SurfaceAppearance") then pcall(function() d:Destroy() end) end
                end
            end
        end
    end
    local ch = myChar()
    if ch then
        for _, d in ipairs(ch:GetDescendants()) do
            if d:IsA("SurfaceAppearance") then pcall(function() d:Destroy() end) end
        end
    end
end

--==============================================================
--  ХУКИ
--==============================================================
local hooked = false
local origWeaponNew, origGetCameraModel
local WeaponComponent, SkinsLib

local KNOWN = {
    WeaponComponent = { "Classes", "WeaponComponent" },
    Skins = { "Database", "Components", "Libraries", "Skins" },
}

local function findModule(name)
    local path = KNOWN[name]
    if path then
        local node = ReplicatedStorage
        for _, part in ipairs(path) do
            node = node and node:FindFirstChild(part)
        end
        if node and node:IsA("ModuleScript") then return node end
    end
    for _, d in ipairs(ReplicatedStorage:GetDescendants()) do
        if d:IsA("ModuleScript") and d.Name == name then return d end
    end
    return nil
end

local function installHooks()
    if hooked or typeof(hookfunction) ~= "function" then return end
    local wc = findModule("WeaponComponent")
    local sl = findModule("Skins")
    if wc then pcall(function() WeaponComponent = require(wc) end) end
    if sl then pcall(function() SkinsLib = require(sl) end) end
    if not WeaponComponent or not SkinsLib then return end
    if type(WeaponComponent.new) ~= "function" or type(SkinsLib.GetCameraModel) ~= "function" then return end

    local ok1 = pcall(function()
        origWeaponNew = WeaponComponent.new
        WeaponComponent.new = function(p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, ...)
            if S.weapon and p1 == lp and categoryOf(p5) == categoryOf(S.weapon) then
                local useWeapon = S.swapWeapon and S.weapon or p5
                return origWeaponNew(p1, p2, p3, p4, useWeapon, S.skin or p6, 0.001, p8, p9, p10, p11, p12, ...)
            end
            return origWeaponNew(p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, ...)
        end
    end)

    local ok2 = pcall(function()
        origGetCameraModel = SkinsLib.GetCameraModel
        SkinsLib.GetCameraModel = function(weaponName, skinName, float, statTrack, nameTag, charm, stickers, team)
            if S.weapon and categoryOf(weaponName) == categoryOf(S.weapon) then
                local useWeapon = S.swapWeapon and S.weapon or weaponName
                local useSkin = S.skin or skinName
                local model = origGetCameraModel(useWeapon, useSkin, 0.001, statTrack, nameTag, charm, stickers, team)
                if model then model.Name = useWeapon end
                return model
            end
            return origGetCameraModel(weaponName, skinName, float, statTrack, nameTag, charm, stickers, team)
        end
    end)

    hooked = ok1 or ok2
end

local function removeHooks()
    if not hooked then return end
    if WeaponComponent and origWeaponNew then pcall(function() WeaponComponent.new = origWeaponNew end) end
    if SkinsLib and origGetCameraModel then pcall(function() SkinsLib.GetCameraModel = origGetCameraModel end) end
    hooked = false
end

task.spawn(function()
    while not dead and task.wait(0.25) do
        if S.weapon and S.skin then installHooks() end
        if S.holdSkin and S.skin and S.weapon then
            pcall(applySkin)
        end
    end
end)

local watchedCam = nil
local function watchCamera()
    local cam = camera or Workspace.CurrentCamera
    if not cam or cam == watchedCam then return end
    watchedCam = cam
    track(cam.ChildAdded:Connect(function()
        if dead or not S.weapon or not S.skin then return end
        task.spawn(function()
            for _ = 1, 6 do
                if dead then break end
                if applySkin() then break end
                task.wait(0.1)
            end
        end)
    end))
end

task.spawn(function()
    while not dead do
        pcall(watchCamera)
        task.wait(1)
    end
end)

local function respawn()
    if dead then return end
    pinnedGlove = nil
    if S.weapon and S.skin then
        task.spawn(function()
            for _ = 1, 40 do
                if dead then break end
                applySkin()
                task.wait(0.1)
            end
        end)
    end
end

track(lp.CharacterAdded:Connect(function()
    task.wait(0.15)
    respawn()
end))

--==============================================================
--  ПРЫЖОК
--==============================================================
local controls
task.spawn(function()
    while not dead and not controls do
        pcall(function()
            local ps = lp:FindFirstChild("PlayerScripts")
            local pm = ps and ps:FindFirstChild("PlayerModule")
            if pm then controls = require(pm):GetControls() end
        end)
        task.wait(2)
    end
end)

local fakeInput = {
    KeyCode = Enum.KeyCode.Space,
    UserInputType = Enum.UserInputType.Keyboard,
    KeyState = Enum.UserInputState.Begin,
    UserInputState = Enum.UserInputState.Begin,
    Position = Vector3.zero,
    Delta = Vector3.zero,
}
fakeInput.IsA = function(_, class)
    return class == "InputObject" or class == "Instance" or class == "Object"
end

local jumpRemotes = {}
local casActions = {}
local scanAt = 0

local function scanChannels(force)
    local now = os.clock()
    if not force and now - scanAt < 6 then return end
    scanAt = now
    jumpRemotes, casActions = {}, {}

    local roots = { ReplicatedStorage, lp:FindFirstChild("PlayerScripts") }
    for _, root in ipairs(roots) do
        if root then
            local ok, desc = pcall(function() return root:GetDescendants() end)
            if ok then
                for _, d in ipairs(desc) do
                    if d:IsA("RemoteEvent") or d:IsA("UnreliableRemoteEvent") then
                        local n = string.lower(d.Name)
                        if n:find("jump", 1, true) or n:find("hop", 1, true) or n:find("leap", 1, true) then
                            jumpRemotes[#jumpRemotes + 1] = d
                        end
                    end
                end
            end
        end
    end

    local ok, info = pcall(function() return CAS:GetAllBoundActionInfo() end)
    if ok and type(info) == "table" then
        for name, data in pairs(info) do
            local types = type(data) == "table" and data.inputTypes
            if type(types) == "table" then
                for _, io in ipairs(types) do
                    if io.KeyCode == Enum.KeyCode.Space then
                        casActions[#casActions + 1] = { name = name, io = io }
                        break
                    end
                end
            end
        end
    end
end

local bh = { nextAt = 0, lastY = 0, peak = 0, pending = 0, fails = 0, wheelArmed = 0 }
local lastState = "-"
local lastChannels = "-"
local jumpCount = 0

local function attempt()
    local char = myChar()
    if not char then lastState = "нет персонажа" return end
    local root = rootOf(char)
    local hum = humOf(char)
    local notes = {}

    pcall(function() UIS.JumpRequest:Fire() end)
    notes[#notes + 1] = "jreq"

    if hum and hum.Health > 0 then
        pcall(function()
            if hum.UseJumpPower ~= true then hum.UseJumpPower = true end
            if hum.JumpPower < 1 then hum.JumpPower = 55 end
        end)
        pcall(function() hum.Jump = true end)
        notes[#notes + 1] = "hum"
    end

    for _, r in ipairs(jumpRemotes) do
        if r.Parent then
            task.spawn(function()
                pcall(function() r:FireServer() end)
                pcall(function() r:FireServer(true) end)
            end)
            notes[#notes + 1] = "remote"
        end
    end

    for _, a in ipairs(casActions) do
        pcall(function() CAS:CallAction(a.name, Enum.UserInputState.Begin, a.io) end)
        pcall(function() CAS:CallAction(a.name, Enum.UserInputState.End, a.io) end)
    end
    if #casActions > 0 then notes[#notes + 1] = "cas" end

    if controls then
        pcall(function() controls:OnInputBegan(fakeInput, false) end)
        notes[#notes + 1] = "ctrl"
    end

    pcall(function() UIS.InputBegan:Fire(fakeInput, false) end)
    notes[#notes + 1] = "sig"

    if typeof(keypress) == "function" then
        pcall(keypress, Enum.KeyCode.Space, 0.03)
    else
        pcall(function() VIM:SendKeyEvent(true, Enum.KeyCode.Space, false) end)
        task.delay(0.03, function()
            pcall(function() VIM:SendKeyEvent(false, Enum.KeyCode.Space, false) end)
        end)
    end
    notes[#notes + 1] = "key"

    if root then
        local v = root.AssemblyLinearVelocity
        if v.Y < 45 then
            if root.Anchored then pcall(function() root.Anchored = false end) end
            pcall(function() root.AssemblyLinearVelocity = Vector3.new(v.X, 52, v.Z) end)
            notes[#notes + 1] = "vel"
        end
        if S.lift then
            pcall(function() root.CFrame = root.CFrame + Vector3.new(0, 2.6, 0) end)
            local ok, piv = pcall(function() return char:GetPivot() end)
            if ok and piv then
                pcall(function() char:PivotTo(piv + Vector3.new(0, 2.6, 0)) end)
            end
            notes[#notes + 1] = "lift"
        end
    end

    lastChannels = table.concat(notes, "+")
    bh.pending = os.clock()
    bh.lastY = pivotY(char)
    bh.peak = 0
    jumpCount += 1
    lastState = "прыжок"
end

track(RunService.RenderStepped:Connect(function()
    if dead or not S.bhop then return end
    pcall(function()
        local now = os.clock()
        local char = myChar()

        if bh.pending > 0 and char then
            local dy = pivotY(char) - bh.lastY
            if dy > bh.peak then bh.peak = dy end
            if now - bh.pending > 0.3 then
                bh.pending = 0
                if bh.peak < 0.6 then
                    bh.fails += 1
                    if bh.fails >= 4 and not S.lift then
                        S.lift = true
                        lastState = "включён подъём"
                    end
                else
                    bh.fails = 0
                end
            end
        end

        local want
        if S.trigger == "space" then
            want = UIS:IsKeyDown(Enum.KeyCode.Space)
        elseif S.trigger == "wheel" then
            local dt = now - bh.wheelArmed
            want = dt > 0 and dt < 0.6
        else
            local dt = now - bh.wheelArmed
            want = UIS:IsKeyDown(Enum.KeyCode.Space) or (dt > 0 and dt < 0.6)
        end

        if not want then
            lastState = "ждём ввод"
            return
        end
        if now < bh.nextAt then return end

        bh.nextAt = now + S.interval
        scanChannels(false)
        attempt()
    end)
end))

track(UIS.InputChanged:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseWheel then return end
    if input.Position.Z < 0 then
        bh.wheelArmed = os.clock()
        bh.nextAt = 0
    end
end))

--==============================================================
--  СТРАНИЦЫ
--==============================================================
local skinPage = page("skin"); tabButton("Скины", "skin")
local movePage = page("move"); tabButton("Движение", "move")

local MAX_ROWS = 90
local skinCat = "all"
local refreshWeapons

section(skinPage, "категория")
chips(skinPage, {
    { name = "Всё", value = "all" },
    { name = "Ножи", value = "knife" },
    { name = "Пистолеты", value = "pistol" },
    { name = "Автоматы", value = "rifle" },
    { name = "ПП", value = "smg" },
    { name = "Дробовики", value = "shotgun" },
    { name = "Снайперки", value = "sniper" },
    { name = "Перчатки", value = "gloves" },
}, "all", function(v)
    skinCat = v
    if refreshWeapons then refreshWeapons() end
end, 4)

local filterBox = new("TextBox", {
    Size = UDim2.new(1, 0, 0, 26),
    BackgroundColor3 = Color3.fromRGB(16, 16, 22),
    BorderSizePixel = 0,
    Font = Enum.Font.Gotham,
    TextSize = 12,
    TextColor3 = Color3.fromRGB(220, 220, 232),
    PlaceholderText = "поиск",
    PlaceholderColor3 = Color3.fromRGB(110, 110, 128),
    Text = "",
    ClearTextOnFocus = false,
    TextXAlignment = Enum.TextXAlignment.Left,
}, skinPage)
new("UICorner", { CornerRadius = UDim.new(0, 7) }, filterBox)
new("UIPadding", { PaddingLeft = UDim.new(0, 8) }, filterBox)

section(skinPage, "оружие")
local weaponBox = listBox(skinPage, 120)
section(skinPage, "скин")
local skinBox = listBox(skinPage, 120)

local function refreshSkins()
    local list = skinList(S.weapon)
    if not S.skin or not table.find(list, S.skin) then S.skin = list[1] end
    fillList(skinBox, list, S.skin, function(v) S.skin = v end)
end

function refreshWeapons()
    local list = {}
    local q = string.lower(filterBox.Text or "")
    for _, name in ipairs(weaponList()) do
        local okCat = skinCat == "all" or categoryOf(name) == skinCat
        local okQ = q == "" or string.lower(name):find(q, 1, true) ~= nil
        if okCat and okQ then
            list[#list + 1] = name
            if #list >= MAX_ROWS then break end
        end
    end
    if S.weapon and #list > 0 and not table.find(list, S.weapon) then
        S.weapon = list[1]
        refreshSkins()
    end
    fillList(weaponBox, list, S.weapon, function(name)
        S.weapon = name
        refreshSkins()
    end)
    if not S.weapon and #list > 0 then
        S.weapon = list[1]
        refreshSkins()
    end
end

filterBox:GetPropertyChangedSignal("Text"):Connect(function()
    if refreshWeapons then refreshWeapons() end
end)

button(skinPage, "Применить сейчас", function()
    if not S.weapon then notify("Выбери оружие") return end
    if not S.skin then notify("Выбери скин") return end
    task.spawn(function()
        for vm in pairs(applied) do applied[vm] = nil end
        pinnedGlove = nil
        local ok = false
        for _ = 1, 10 do
            if dead then break end
            if applySkin() then ok = true break end
            task.wait(0.1)
        end
        notify(ok and "Скин применён" or "Модель не найдена — возьми в руки")
    end)
end)
button(skinPage, "Привязать перчатки", function()
    local g = gloveModel()
    if g then
        pinnedGlove = g
        for vm in pairs(applied) do applied[vm] = nil end
        notify("Привязано: " .. g.Name)
        if S.weapon and S.skin then applySkin() end
    else
        notify("Модель перчаток не найдена")
    end
end)
button(skinPage, "Сбросить", function()
    resetSkins()
    pinnedGlove = nil
    notify("Сброшено")
end)
toggle(skinPage, "Держать скин", S.holdSkin, function(v) S.holdSkin = v end)
toggle(skinPage, "Подменять модель", S.swapWeapon, function(v)
    S.swapWeapon = v
    if v then installHooks() end
end)

local status = new("TextLabel", {
    Text = "—",
    Font = Enum.Font.Code,
    TextSize = 11,
    TextColor3 = Color3.fromRGB(140, 140, 160),
    BackgroundColor3 = Color3.fromRGB(13, 13, 18),
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, 44),
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    TextWrapped = true,
}, skinPage)
new("UICorner", { CornerRadius = UDim.new(0, 8) }, status)
new("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingTop = UDim.new(0, 4) }, status)

task.spawn(function()
    while not dead and task.wait(0.4) do
        local vm = viewmodel()
        local gl = gloveModel()
        status.Text = string.format("в руках: %s\nперчатки: %s\nпривязано: %s | хуки: %s",
            vm and vm.Name or "-", gl and gl.Name or "-",
            pinnedGlove and pinnedGlove.Name or "-", tostring(hooked))
    end
end)

section(movePage, "автобхоп")
toggle(movePage, "Включить", S.bhop, function(v)
    S.bhop = v
    bh.nextAt = 0
    bh.pending = 0
    bh.fails = 0
    if v then scanChannels(true) end
end)
chips(movePage, {
    { name = "Пробел (зажать)", value = "space" },
    { name = "Колесо вниз", value = "wheel" },
    { name = "Оба", value = "both" },
}, S.trigger, function(v) S.trigger = v end, 3)
slider(movePage, "Интервал", 15, 60, math.floor(S.interval * 100), function(v) S.interval = v / 100 end)
toggle(movePage, "Подъём через CFrame", S.lift, function(v) S.lift = v end)
button(movePage, "Пересканировать каналы", function()
    scanChannels(true)
    notify("ремоутов " .. #jumpRemotes .. " | действий " .. #casActions)
end)

local dbg = new("TextLabel", {
    Text = "—",
    Font = Enum.Font.Code,
    TextSize = 11,
    TextColor3 = Color3.fromRGB(140, 140, 160),
    BackgroundColor3 = Color3.fromRGB(13, 13, 18),
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, 40),
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    TextWrapped = true,
}, movePage)
new("UICorner", { CornerRadius = UDim.new(0, 8) }, dbg)
new("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingTop = UDim.new(0, 4) }, dbg)

task.spawn(function()
    while not dead and task.wait(0.2) do
        if not S.bhop then
            dbg.Text = "выключено"
            continue
        end
        dbg.Text = string.format("rise %.1f | %d | %s | %s\nканалы: ремоутов %d, действий %d, контроллер %s",
            bh.peak, jumpCount, lastState, lastChannels,
            #jumpRemotes, #casActions, tostring(controls ~= nil))
    end
end)

section(movePage, "камера")
toggle(movePage, "Фиксация FOV", S.fovEnabled, function(v)
    if v and camera then fovOriginal = camera.FieldOfView end
    S.fovEnabled = v
    applyFov()
end)
slider(movePage, "FOV", 40, 120, S.fovValue, function(v)
    S.fovValue = v
    applyFov()
end)

track(UIS.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == CONFIG.Keybind then
        if opened then closeMenu() else openMenu() end
    end
end))

pages.skin.Visible = true
tabs.skin.TextColor3 = Color3.fromRGB(255, 255, 255)
tabs.skin.BackgroundColor3 = Color3.fromRGB(32, 25, 62)
tabBars.skin.Size = UDim2.new(0, 3, 0, 16)
tabBars.skin.Position = UDim2.new(0, 0, 0.5, -8)

task.spawn(function()
    for _ = 1, 100 do
        if SkinsFolder or dead then break end
        task.wait(0.5)
    end
    if dead or not SkinsFolder then return end
    local out = {}
    local n = 0
    for _, f in ipairs(SkinsFolder:GetChildren()) do
        if (f:IsA("Folder") or f:IsA("Model")) and not f.Name:find("PATTERN") then
            for _, s in ipairs(f:GetChildren()) do
                if (s:IsA("Folder") or s:IsA("Model")) and skinWorks(s) then
                    out[#out + 1] = f.Name
                    break
                end
            end
        end
        n += 1
        if n % 8 == 0 then task.wait() end
    end
    table.sort(out)
    weaponCache = out
    if not dead then
        refreshWeapons()
        refreshSkins()
        if S.weapon and S.skin then
            installHooks()
            task.spawn(function()
                for _ = 1, 8 do
                    if dead then break end
                    if applySkin() then break end
                    task.wait(0.2)
                end
            end)
        end
    end
end)

if S.fovEnabled then applyFov() end
if S.weapon and S.skin then installHooks() end

local function unload()
    saveConfig()
    dead = true
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    removeHooks()
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
