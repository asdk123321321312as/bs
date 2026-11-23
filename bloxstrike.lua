--!nocheck
--[[
    SleepScript • Blox Strike
    ---------------------------------------------------------------
    ESP, автобхоп, no air spread, FOV, скинченджер ножей.
    Меню: Z. Выгрузка: кнопка в меню или getgenv().SleepScript.Unload()
]]

local CONFIG = {
    Accent    = Color3.fromRGB(140, 110, 255),
    AccentDim = Color3.fromRGB(44, 34, 92),
    Keybind   = Enum.KeyCode.Z,
    Version   = "1.1",
}

if getgenv().SleepScript then pcall(function() getgenv().SleepScript.Unload() end) end

local booted, bootErr = pcall(function()

local cloneref   = cloneref or function(x) return x end
local gethui     = gethui or function() return game:GetService("CoreGui") end
local hasDrawing = Drawing ~= nil and Drawing.new ~= nil

local Players           = cloneref(game:GetService("Players"))
local RunService        = cloneref(game:GetService("RunService"))
local UIS               = cloneref(game:GetService("UserInputService"))
local TweenService      = cloneref(game:GetService("TweenService"))
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local Lighting          = cloneref(game:GetService("Lighting"))
local Workspace         = cloneref(workspace)
local lp                = Players.LocalPlayer

local TEAMS = { "Terrorists", "Counter-Terrorists" }

local S = {
    espEnabled = false,
    style = "corner",
    thickness = 1,
    cornerSize = 9,
    textSize = 13,
    showDist = true,
    distUnit = "m",
    hpMode = "bar",
    tracer = false,
    teamCheck = true,
    maxDist = 500,
    colorStatic = Color3.fromRGB(235, 235, 245),
    colorHidden = Color3.fromRGB(150, 150, 165),
    bhop = false,
    bhopAggro = false,
    noAirSpread = false,
    fovEnabled = false,
    fovValue = 90,
    knife = nil,
    skin = nil,
    customKnife = false,
    holdSkin = true,
}

local selfRead = false
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
--  ПЕРСОНАЖИ (папка переразрешается каждый раз)
--==============================================================
local Characters = nil

local function chars()
    if Characters and Characters.Parent then return Characters end
    Characters = Workspace:FindFirstChild("Characters")
    return Characters
end

local function teamOf(plr)
    local attr = plr:GetAttribute("Team")
    if typeof(attr) == "string" then
        local low = string.lower(attr)
        if string.find(low, "counter", 1, true) then return "CT" end
        if string.find(low, "terror", 1, true) then return "T" end
    end
    local team = plr.Team
    if typeof(team) == "Instance" then
        local low = string.lower(team.Name)
        if string.find(low, "counter", 1, true) then return "CT" end
        if string.find(low, "terror", 1, true) then return "T" end
    end
    local c = chars()
    if c then
        for _, t in ipairs(TEAMS) do
            local f = c:FindFirstChild(t)
            if f and f:FindFirstChild(plr.Name) then
                return (t == "Terrorists") and "T" or "CT"
            end
        end
    end
    return nil
end

local function getChar(plr)
    if not plr then return nil end
    local ch = plr.Character
    if ch and ch.Parent and ch:FindFirstChildOfClass("Humanoid") then return ch end

    local c = chars()
    if c then
        for _, t in ipairs(TEAMS) do
            local f = c:FindFirstChild(t)
            local m = f and f:FindFirstChild(plr.Name)
            if m and m:FindFirstChildOfClass("Humanoid") then return m end
        end
        local direct = c:FindFirstChild(plr.Name)
        if direct and direct:FindFirstChildOfClass("Humanoid") then return direct end
    end

    if ch and ch.Parent then return ch end
    return nil
end

local function rootOf(char)
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
        or char:FindFirstChild("UpperTorso")
        or char:FindFirstChild("Torso")
        or char.PrimaryPart
end

local groundParams = RaycastParams.new()
groundParams.FilterType = Enum.RaycastFilterType.Exclude
groundParams.IgnoreWater = true

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

headerButton(-32, "×", function() if getgenv().SleepScript then getgenv().SleepScript.Unload() end end)
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
--  ESP
--==============================================================
local ESP = { objects = {} }
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
    rec.box = add(sq(false))
    rec.hpBg = add(sq(true))
    rec.hp = add(sq(true))
    rec.name = add(Drawing.new("Text"))
    rec.dist = add(Drawing.new("Text"))
    rec.tracer = add(Drawing.new("Line"))
    for _, t in ipairs({ rec.name, rec.dist }) do
        t.Center = true
        t.Outline = true
        t.Font = FONT
        t.OutlineColor = Color3.fromRGB(0, 0, 0)
    end
    for i = 1, 8 do rec.corners[i] = add(sq(false)) end
    return rec
end

local function hide(rec)
    rec.box.Filled = false
    for i = 1, #rec.all do rec.all[i].Visible = false end
end

local function bindPlayer(plr)
    if ESP.objects[plr] then return end
    ESP.objects[plr] = { rec = newRec() }
end

local function unbindPlayer(plr)
    local e = ESP.objects[plr]
    if not e then return end
    for _, o in ipairs(e.rec.all) do pcall(function() o:Remove() end) end
    ESP.objects[plr] = nil
end

for _, p in ipairs(Players:GetPlayers()) do bindPlayer(p) end
track(Players.PlayerAdded:Connect(bindPlayer))
track(Players.PlayerRemoving:Connect(unbindPlayer))

local rayParams = RaycastParams.new()
rayParams.IgnoreWater = true
local visState, visClock = {}, {}

local function colorFor(visible, frac)
    if not visible then return S.colorHidden end
    if S.colorMode == "health" then
        return Color3.fromRGB(230, 70, 70):Lerp(Color3.fromRGB(90, 220, 120), frac)
    end
    return S.colorStatic
end

local function put(s, x, y, w, h, col)
    s.Color = col
    s.Thickness = S.thickness
    s.Position = Vector2.new(x, y)
    s.Size = Vector2.new(w, h)
    s.Visible = true
end

local function drawBox(rec, x, y, w, h, col)
    local t = S.thickness
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
    local c = math.clamp(S.cornerSize, 3, math.min(w / 2, h / 2))
    put(rec.corners[1], x, y, c, t, col)
    put(rec.corners[2], x, y, t, c, col)
    put(rec.corners[3], x + w - c, y, c, t, col)
    put(rec.corners[4], x + w - t, y, t, c, col)
    put(rec.corners[5], x, y + h - t, c, t, col)
    put(rec.corners[6], x, y + h - c, t, c, col)
    put(rec.corners[7], x + w - c, y + h - t, c, t, col)
    put(rec.corners[8], x + w - t, y + h - c, t, c, col)
end

local function frameUpdate()
    if not S.espEnabled or not hasDrawing then return end
    local cam = camera or Workspace.CurrentCamera
    if not cam then return end

    local camPos = cam.CFrame.Position
    local vp = cam.ViewportSize
    local cx = vp.X / 2
    local now = os.clock()
    local my = getChar(lp)
    local myTeam = teamOf(lp)

    for plr, entry in pairs(ESP.objects) do
        local rec = entry.rec
        if plr == lp then
            hide(rec)
            continue
        end

        local char = getChar(plr)
        if not char then
            hide(rec)
            continue
        end

        local hum = char:FindFirstChildOfClass("Humanoid")
        if (hum and hum.Health <= 0) or char:GetAttribute("Dead") == true then
            hide(rec)
            continue
        end

        if S.teamCheck and myTeam and teamOf(plr) == myTeam then
            hide(rec)
            continue
        end

        local root = rootOf(char)
        if not root then
            hide(rec)
            continue
        end

        local head = char:FindFirstChild("Head") or root
        local dist = (camPos - root.Position).Magnitude
        if dist > S.maxDist then
            hide(rec)
            continue
        end

        local sTop, onTop = cam:WorldToViewportPoint(head.Position + Vector3.new(0, 1.1, 0))
        local sBot, onBot = cam:WorldToViewportPoint(root.Position - Vector3.new(0, 3.1, 0))
        if not (onTop and onBot) or sTop.Z <= 0 or sBot.Z <= 0 or sBot.Y <= sTop.Y then
            hide(rec)
            continue
        end

        local h = sBot.Y - sTop.Y
        local w = h * 0.45
        local x = sTop.X - w / 2
        local y = sTop.Y

        if not visClock[plr] or now - visClock[plr] > 0.12 then
            visClock[plr] = now
            rayParams.FilterDescendantsInstances = { char, my }
            local hit = Workspace:Raycast(camPos, head.Position - camPos, rayParams)
            visState[plr] = (hit == nil or hit.Instance:IsDescendantOf(char))
        end

        local frac = hum and math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1) or 1
        local col = colorFor(visState[plr] ~= false, frac)

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
        else
            rec.hpBg.Visible = false
            rec.hp.Visible = false
        end

        rec.name.Text = plr.Name
        rec.name.Size = S.textSize
        rec.name.Color = col
        rec.name.Position = Vector2.new(x + w / 2, y - S.textSize - 3)
        rec.name.Visible = true

        if S.showDist then
            rec.dist.Text = (S.distUnit == "m")
                and string.format("%d m", math.floor(dist / 3.5))
                or string.format("%d st", math.floor(dist))
            rec.dist.Size = S.textSize - 1
            rec.dist.Color = col
            rec.dist.Position = Vector2.new(x + w / 2, y + h + 3)
            rec.dist.Visible = true
        else
            rec.dist.Visible = false
        end

        if S.tracer then
            rec.tracer.From = Vector2.new(cx, vp.Y)
            rec.tracer.To = Vector2.new(x + w / 2, y + h)
            rec.tracer.Color = CONFIG.Accent
            rec.tracer.Thickness = S.thickness
            rec.tracer.Visible = true
        else
            rec.tracer.Visible = false
        end
    end
end

track(RunService.RenderStepped:Connect(function() pcall(frameUpdate) end))

--==============================================================
--  АВТОБХОП
--==============================================================
local lastJump = 0

local function myHum()
    local c = getChar(lp)
    if not c then return nil end
    return c:FindFirstChildOfClass("Humanoid")
end

local function grounded(hum)
    local root = hum.RootPart or rootOf(hum.Parent)
    if not root then return false end
    groundParams.FilterDescendantsInstances = { hum.Parent }
    return Workspace:Raycast(root.Position, Vector3.new(0, -6, 0), groundParams) ~= nil
end

local function jump(hum)
    pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
    pcall(function() hum.Jump = true end)

    if S.bhopAggro then
        local root = hum.RootPart or rootOf(hum.Parent)
        if root then
            local power = hum.JumpPower
            if not hum.UseJumpPower then
                power = math.sqrt(2 * Workspace.Gravity * hum.JumpHeight)
            end
            if power and power > 0 then
                local v = root.AssemblyLinearVelocity
                if v.Y < power * 0.95 then
                    root.AssemblyLinearVelocity = Vector3.new(v.X, power, v.Z)
                end
            end
        end
    end
end

track(RunService.RenderStepped:Connect(function()
    if not S.bhop then return end
    if not UIS:IsKeyDown(Enum.KeyCode.Space) then return end
    local hum = myHum()
    if not hum or hum.Health <= 0 then return end

    selfRead = true
    local st = hum:GetState()
    selfRead = false
    if st == Enum.HumanoidStateType.Jumping or st == Enum.HumanoidStateType.Freefall then return end

    local now = os.clock()
    if now - lastJump < 0.06 then return end
    if S.bhopAggro and not grounded(hum) then return end

    lastJump = now
    jump(hum)
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
local Assets = ReplicatedStorage:WaitForChild("Assets", 20)
local Weapons = Assets and Assets:WaitForChild("Weapons", 20)
local SkinsFolder = Assets and Assets:WaitForChild("Skins", 20)
local WeaponAnims = Assets and Assets:FindFirstChild("WeaponAnimations")

local KNIFE_HINT = {
    "knife", "karambit", "bayonet", "dagger", "falchion", "bowie",
    "huntsman", "talon", "stiletto", "ursus", "navaja", "skeleton",
    "nomad", "paracord", "survival", "classic",
}

local function isKnifeName(name)
    local low = string.lower(name)
    for _, h in ipairs(KNIFE_HINT) do
        if string.find(low, h, 1, true) then return true end
    end
    return false
end

local function knifeList()
    local out = {}
    if SkinsFolder then
        for _, f in ipairs(SkinsFolder:GetChildren()) do
            if isKnifeName(f.Name) then table.insert(out, f.Name) end
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
    for _, s in ipairs(f:GetChildren()) do table.insert(out, s.Name) end
    table.sort(out)
    return out
end

local OFFSETS = {
    ["Karambit"]        = CFrame.new(0, -1.5, 1.5),
    ["Butterfly Knife"] = CFrame.new(0, -1.5, 1.5),
    ["M9 Bayonet"]      = CFrame.new(0, -1.5, 1),
    ["Flip Knife"]      = CFrame.new(0, -1.5, 1.25),
    ["Gut Knife"]       = CFrame.new(0, -1.5, 0.5),
}
local DEFAULT_OFFSET = CFrame.new(0, -1.5, 1.2)

local customVM, customIdle = nil, nil
local hiddenParts = {}

local function cam()
    return camera or Workspace.CurrentCamera
end

local function isKnifeVM(obj)
    if not obj:IsA("Model") then return false end
    local n = obj.Name
    return n == "T Knife" or n == "CT Knife" or n == "SleepKnife" or isKnifeName(n)
end

local function viewmodels()
    local out = {}
    local c = cam()
    if not c then return out end
    for _, o in ipairs(c:GetChildren()) do
        if isKnifeVM(o) then out[#out + 1] = o end
    end
    return out
end

local function hideOriginals()
    for _, vm in ipairs(viewmodels()) do
        if vm.Name ~= "SleepKnife" then
            for _, p in ipairs(vm:GetDescendants()) do
                if p:IsA("BasePart") and hiddenParts[p] == nil then
                    hiddenParts[p] = p.Transparency
                    p.Transparency = 1
                end
            end
        end
    end
end

local function showOriginals()
    for p, t in pairs(hiddenParts) do
        pcall(function() if p.Parent then p.Transparency = t end end)
    end
    hiddenParts = {}
end

local function clearCustom()
    if customIdle then pcall(function() customIdle:Stop() end) end
    customIdle = nil
    if customVM then pcall(function() customVM:Destroy() end) end
    customVM = nil
end

local function buildCustom(knife)
    clearCustom()
    if not Weapons or not knife then return false end
    local tpl = Weapons:FindFirstChild(knife)
    if not tpl then return false end
    local camTpl = tpl:FindFirstChild("Camera")
    if not camTpl then return false end

    local vm = camTpl:Clone()
    vm.Name = "SleepKnife"
    for _, d in ipairs(vm:GetDescendants()) do
        if d:IsA("BasePart") then
            d.CanCollide = false
            d.CanTouch = false
            d.CanQuery = false
            d.CastShadow = false
            d.Anchored = false
            d.Massless = true
        end
    end
    vm.Parent = cam()
    customVM = vm
    hideOriginals()

    pcall(function()
        local folder = WeaponAnims[knife].CameraAnimations
        local ac = vm:FindFirstChildOfClass("AnimationController") or vm:FindFirstChildOfClass("Animator")
        local animator = ac:FindFirstChildWhichIsA("Animator") or ac
        local idle = animator:LoadAnimation(folder.Idle)
        idle.Looped = true
        idle:Play()
        customIdle = idle
    end)
    return true
end

track(RunService.RenderStepped:Connect(function()
    if not customVM or not customVM.PrimaryPart then return end
    local c = cam()
    if not c then return end
    customVM.PrimaryPart.CFrame = c.CFrame * (OFFSETS[S.knife] or DEFAULT_OFFSET)
end))

local function applySkinTo(model, skinFolderName, skinName)
    if not SkinsFolder then return false end
    local skinRoot = SkinsFolder:FindFirstChild(skinFolderName)
    if not skinRoot then return false end
    local skinObj = skinRoot:FindFirstChild(skinName)
    if not skinObj then return false end
    local camFolder = skinObj:FindFirstChild("Camera")
    if not camFolder then return false end
    local wear = camFolder:FindFirstChild("Factory New") or camFolder:GetChildren()[1]
    if not wear then return false end

    local weaponFolder = model:FindFirstChild("Weapon")
    local pool = weaponFolder and weaponFolder:GetDescendants() or model:GetDescendants()

    local touched = 0
    for _, part in ipairs(pool) do
        if part:IsA("BasePart") then
            local src = wear:FindFirstChild(part.Name)
            if src then
                local ex = part:FindFirstChildOfClass("SurfaceAppearance")
                if ex then ex:Destroy() end
                if src:IsA("SurfaceAppearance") then
                    local c = src:Clone()
                    c.Name = "SurfaceAppearance"
                    c.Parent = part
                    touched += 1
                elseif src:IsA("Texture") then
                    local ex2 = part:FindFirstChildOfClass("Texture")
                    if ex2 then ex2:Destroy() end
                    local c = src:Clone()
                    c.Parent = part
                    touched += 1
                end
            end
        end
    end
    return touched > 0
end

-- ключ папки скина: имя модели, если у неё есть свои скины, иначе выбранный нож
local function skinKeyFor(model)
    if SkinsFolder and SkinsFolder:FindFirstChild(model.Name) then return model.Name end
    return S.knife
end

local function applySkin()
    if not S.skin then return false end
    local ok = false
    for _, vm in ipairs(viewmodels()) do
        local key = skinKeyFor(vm)
        if key then
            if applySkinTo(vm, key, S.skin) then ok = true end
        end
    end
    return ok
end

local function resetSkins()
    for _, vm in ipairs(viewmodels()) do
        for _, d in ipairs(vm:GetDescendants()) do
            if d:IsA("SurfaceAppearance") or d:IsA("Texture") then
                pcall(function() d:Destroy() end)
            end
        end
    end
end

task.spawn(function()
    while task.wait(0.4) do
        if S.customKnife and S.knife then
            if not customVM or not customVM.Parent then
                buildCustom(S.knife)
            else
                hideOriginals()
            end
        end
        if S.holdSkin and S.skin and S.knife then applySkin() end
    end
end)

--==============================================================
--  ДИАГНОСТИКА
--==============================================================
local function diagnose()
    local lines = {}
    local c = chars()
    table.insert(lines, "Characters: " .. tostring(c))
    if c then
        for _, t in ipairs(TEAMS) do
            local f = c:FindFirstChild(t)
            table.insert(lines, "  " .. t .. ": " .. (f and tostring(#f:GetChildren()) or "нет"))
        end
    end
    table.insert(lines, "lp.Character: " .. tostring(lp.Character))
    table.insert(lines, "Команда: " .. tostring(teamOf(lp)))
    local cc = cam()
    table.insert(lines, "Камера-дети: " .. (cc and tostring(#cc:GetChildren()) or "нет"))
    if cc then
        for _, o in ipairs(cc:GetChildren()) do
            if o:IsA("Model") then table.insert(lines, "  [M] " .. o.Name) end
        end
    end
    table.insert(lines, "Assets: " .. tostring(Assets))
    table.insert(lines, "Weapons: " .. (Weapons and tostring(#Weapons:GetChildren()) or "нет"))
    table.insert(lines, "Skins: " .. (SkinsFolder and tostring(#SkinsFolder:GetChildren()) or "нет"))
    table.insert(lines, "Ножей найдено: " .. tostring(#knifeList()))
    local text = table.concat(lines, "\n")
    print("[SleepScript] ДИАГНОСТИКА\n" .. text)
    if setclipboard then pcall(setclipboard, text) end
    notify("Диагностика: F9, скопирована в буфер")
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
toggle(visualPage, "Игнорировать своих", true, function(v) S.teamCheck = v end)
slider(visualPage, "Макс. дистанция", 100, 2000, 500, function(v) S.maxDist = v end)

section(visualPage, "форма")
chips(visualPage, {
    { name = "Уголки", value = "corner" },
    { name = "Бокс", value = "full" },
    { name = "Точка", value = "dot" },
}, S.style, function(v) S.style = v end, 3)
slider(visualPage, "Толщина", 1, 4, 1, function(v) S.thickness = v end)
slider(visualPage, "Размер уголков", 4, 24, 9, function(v) S.cornerSize = v end)

section(visualPage, "текст")
slider(visualPage, "Размер текста", 9, 22, 13, function(v) S.textSize = v end)
toggle(visualPage, "Дистанция", true, function(v) S.showDist = v end)
chips(visualPage, {
    { name = "Метры", value = "m" },
    { name = "Студы", value = "studs" },
}, S.distUnit, function(v) S.distUnit = v end, 2)

section(visualPage, "здоровье и луч")
toggle(visualPage, "Полоска HP", true, function(v) S.hpMode = v and "bar" or "off" end)
toggle(visualPage, "Трассер", false, function(v) S.tracer = v end)
chips(visualPage, {
    { name = "Белый", value = Color3.fromRGB(235, 235, 245) },
    { name = "Фиолет", value = Color3.fromRGB(160, 130, 255) },
    { name = "Лайм", value = Color3.fromRGB(160, 255, 90) },
    { name = "Красный", value = Color3.fromRGB(255, 90, 90) },
}, S.colorStatic, function(v) S.colorStatic = v end)

section(movePage, "бхоп")
toggle(movePage, "Автобхоп (держать пробел)", false, function(v) S.bhop = v end)
toggle(movePage, "Агрессивный (только с земли)", false, function(v) S.bhopAggro = v end)

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
local statusLabel = new("TextLabel", {
    Text = "Нож не выбран",
    Font = Enum.Font.Gotham,
    TextSize = 11,
    TextColor3 = Color3.fromRGB(140, 140, 160),
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 16),
    TextXAlignment = Enum.TextXAlignment.Left,
}, skinPage)

local function refreshSkins()
    local list = skinList(S.knife)
    S.skin = list[1]
    fillList(skinBox, list, S.skin, function(v) S.skin = v end)
    statusLabel.Text = string.format("%s • скинов: %d", tostring(S.knife), #list)
end

fillList(knifeBox, knifeList(), nil, function(name)
    S.knife = name
    refreshSkins()
    if S.customKnife then buildCustom(name) end
end)

section(skinPage, "скин")
button(skinPage, "Применить скин", function()
    if not S.knife then notify("Выбери нож") return end
    if not S.skin then notify("Выбери скин") return end
    notify(applySkin() and ("Скин: " .. S.skin) or "Нож не в руках")
end)
button(skinPage, "Сбросить скин", function()
    resetSkins()
    notify("Скин сброшен")
end)
toggle(skinPage, "Держать скин", true, function(v) S.holdSkin = v end)
toggle(skinPage, "Подменить модель ножа", false, function(v)
    S.customKnife = v
    if v then
        if S.knife then buildCustom(S.knife) else notify("Сначала выбери нож") end
    else
        clearCustom()
        showOriginals()
    end
end)

section(miscPage, "служебное")
button(miscPage, "Диагностика (F9)", diagnose)
button(miscPage, "Закрыть меню (Z)", function() closeMenu() end)
button(miscPage, "Выгрузить скрипт", function()
    if getgenv().SleepScript then getgenv().SleepScript.Unload() end
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
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    for plr in pairs(ESP.objects) do unbindPlayer(plr) end
    if hookedIndex and origIndex then pcall(function() hookmetamethod(game, "__index", origIndex) end) end
    if hookedNamecall and origNamecall then pcall(function() hookmetamethod(game, "__namecall", origNamecall) end) end
    clearCustom()
    showOriginals()
    if camera then pcall(function() camera.FieldOfView = fovOriginal end) end
    pcall(function() blur:Destroy() end)
    pcall(function() gui:Destroy() end)
    getgenv().SleepScript = nil
end

getgenv().SleepScript = { Unload = unload, Settings = S }

notify("SleepScript загружен. Z — меню")

end)

if not booted then
    warn("[SleepScript] ошибка запуска: " .. tostring(bootErr))
end
