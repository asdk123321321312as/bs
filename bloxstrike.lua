local CONFIG = {
    Accent    = Color3.fromRGB(140, 110, 255),
    AccentDim = Color3.fromRGB(44, 34, 92),
    Keybind   = Enum.KeyCode.Z,
    Version   = "2.5",
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
local hasDrawing = type(Drawing) == "table" and type(Drawing.new) == "function"

local Players           = cloneref(game:GetService("Players"))
local RunService        = cloneref(game:GetService("RunService"))
local UIS               = cloneref(game:GetService("UserInputService"))
local VIM               = cloneref(game:GetService("VirtualInputManager"))
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
    trigger = "space",
    unanchor = false,
    noAirSpread = false,
    fovEnabled = false,
    fovValue = 90,
    weapon = nil,
    skin = nil,
    swapWeapon = false,
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

local function humOf(char)
    if not char then return nil end
    local h = char:FindFirstChild("Humanoid")
    if h and h:IsA("Humanoid") then return h end
    h = char:FindFirstChildOfClass("Humanoid")
    if h then return h end
    h = char:FindFirstChild("Humanoid", true)
    if h and h:IsA("Humanoid") then return h end
    return nil
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
                    if m:IsA("Model") and (modelOwner[m] or humOf(m)) then
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
    return humOf(myChar())
end

local function isDead(char)
    if not char then return true end
    if char:GetAttribute("Dead") == true then return true end
    local hp = tonumber(char:GetAttribute("Health"))
    if hp and hp <= 0 then return true end
    local hum = humOf(char)
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

local function gatherParts(model, skipBlocked)
    local parts = {}
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("BasePart") and d.Transparency < 0.95 then
            if not (skipBlocked and BLOCKED_PARTS[d.Name]) then
                local mag = d.Size.Magnitude
                if mag > 0 and mag <= 16 then
                    parts[#parts + 1] = d
                    if #parts >= 60 then break end
                end
            end
        end
    end
    return parts
end

local partCache = {}

local function cachedParts(model)
    local e = partCache[model]
    local now = os.clock()
    if e and now - e.t < 0.5 then return e.parts end
    local parts = gatherParts(model, true)
    if #parts == 0 then parts = gatherParts(model, false) end
    partCache[model] = { t = now, parts = parts }
    return parts
end

local function buildBounds(model, root)
    local anchorPos = root and root.Position
    local parts = cachedParts(model)
    if #parts == 0 then return nil end

    local anchorPart, bestVol = nil, 0
    for _, p in ipairs(parts) do
        if p.Parent and (not anchorPos or (p.Position - anchorPos).Magnitude <= 6) then
            local v = p.Size.X * p.Size.Y * p.Size.Z
            if v > bestVol then anchorPart, bestVol = p, v end
        end
    end
    if not anchorPart then return nil end
    local ap = anchorPart.Position

    local mn, mx
    for _, p in ipairs(parts) do
        if p.Parent and (p.Position - ap).Magnitude <= 4.5 then
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
    partCache[model] = nil
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

    local hum = humOf(char)
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

local function ownerOf(model)
    local o = modelOwner[model]
    if o then return o end
    o = Players:FindFirstChild(model.Name)
    if o then return o end
    local name = model.Name
    for _, p in ipairs(Players:GetPlayers()) do
        if #p.Name > 2 and name:find(p.Name, 1, true) then return p end
    end
    return nil
end

task.spawn(function()
    while not dead and task.wait(0.15) do
        local list = {}
        pcall(function()
            local folder = charsFolder()
            if folder then
                for _, m in ipairs(folder:GetChildren()) do
                    if m:IsA("Model") then list[m] = true end
                end
            end
            for _, c in ipairs(Workspace:GetChildren()) do
                if c ~= folder and (c:IsA("Folder") or c:IsA("Model")) then
                    local kids = c:GetChildren()
                    if #kids <= 400 then
                        for _, m in ipairs(kids) do
                            if m:IsA("Model") and humOf(m) then list[m] = true end
                        end
                    end
                end
            end
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
        local owner = ownerOf(model)
        local skip = false

        if not model.Parent then
            skip = true
        elseif owner == lp then
            skip = not S.showLocal
        elseif not owner then
            skip = not S.showBots
        elseif S.teamCheck and myTeam then
            local t = teamOfModel(model, owner)
            if t and t == myTeam then skip = true end
        end

        if skip then
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
            local owner = ownerOf(m)
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
--  ПРЫЖОК
--==============================================================
local lastState = "-"
local jumpCount = 0
local failCount = 0

local bh = {
    mode = "auto",
    interval = 0.33,
    nextAt = 0,
    lastY = 0,
    peak = 0,
    pending = 0,
    fails = 0,
    wheelArmed = 0,
}

local hop = { active = false, start = 0, dur = 0.4, height = 5.2, baseY = 0, model = nil }

local groundParams = RaycastParams.new()
groundParams.FilterType = Enum.RaycastFilterType.Exclude
groundParams.IgnoreWater = true
local groundRes, groundAt = false, 0

local function grounded(char, root, hum)
    if not root then return false end
    if root.Anchored then return true end
    local now = os.clock()
    if now - groundAt < 0.05 then return groundRes end
    groundAt = now
    local res = false
    if hum then
        local ok, st = pcall(function() return hum:GetState() end)
        if ok and (st == Enum.HumanoidStateType.Jumping or st == Enum.HumanoidStateType.Freefall) then
            res = false
        else
            local ok2, mat = pcall(function() return hum.FloorMaterial end)
            if ok2 and mat and mat ~= Enum.Material.Air then res = true end
        end
    end
    if not res and root.AssemblyLinearVelocity.Y <= 3 then
        groundParams.FilterDescendantsInstances = { char }
        res = Workspace:Raycast(root.Position, Vector3.new(0, -6, 0), groundParams) ~= nil
    end
    groundRes = res
    return res
end

local function hopStep(now)
    if not hop.active then return end
    local model = hop.model
    if not model or not model.Parent then
        hop.active = false
        return
    end
    local t = math.clamp((now - hop.start) / hop.dur, 0, 1)
    local want = hop.height * 4 * (t - t * t)
    local ok, piv = pcall(function() return model:GetPivot() end)
    if not ok then
        hop.active = false
        return
    end
    local py = piv.Position.Y
    if py < hop.baseY or math.abs(py - hop.baseY) < 0.2 then hop.baseY = py end
    pcall(function() model:PivotTo(piv + Vector3.new(0, want, 0)) end)
    if t >= 1 then hop.active = false end
end

local renderBound = false
if typeof(RunService.BindToRenderStep) == "function" then
    renderBound = pcall(function()
        RunService:BindToRenderStep("SleepHop", 2000, function()
            if dead or not hop.active then return end
            pcall(hopStep, os.clock())
        end)
    end)
end

local function pressSpace()
    if typeof(keypress) == "function" then
        pcall(keypress, Enum.KeyCode.Space, 0.04)
        return
    end
    if typeof(keydown) == "function" and typeof(keyup) == "function" then
        pcall(keydown, Enum.KeyCode.Space)
        task.delay(0.04, function() pcall(keyup, Enum.KeyCode.Space) end)
        return
    end
    pcall(function() VIM:SendKeyEvent(true, Enum.KeyCode.Space, false) end)
    task.delay(0.04, function()
        pcall(function() VIM:SendKeyEvent(false, Enum.KeyCode.Space, false) end)
    end)
end

local function doJump(now, root, hum)
    local mode = (bh.mode == "auto") and "hum" or bh.mode
    local char = myChar()

    if mode == "hum" then
        if hum then
            pcall(function() hum.Jump = true end)
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
        end
        pressSpace()
    elseif mode == "vel" then
        if root.Anchored then pcall(function() root.Anchored = false end) end
        local v = root.AssemblyLinearVelocity
        pcall(function() root.AssemblyLinearVelocity = Vector3.new(v.X, math.max(v.Y, 55), v.Z) end)
        pressSpace()
    else
        local v = root.AssemblyLinearVelocity
        if not root.Anchored then
            pcall(function() root.AssemblyLinearVelocity = Vector3.new(v.X, math.max(v.Y, 45), v.Z) end)
        end
        hop.active = true
        hop.start = now
        hop.baseY = root.Position.Y
        hop.model = char
    end

    if S.trigger == "wheel" then bh.wheelArmed = 0 end

    bh.pending = now
    bh.lastY = root.Position.Y
    bh.peak = 0
    jumpCount += 1
    lastState = "прыжок/" .. mode
end

local function bhopTick()
    if not S.bhop then
        hop.active = false
        return
    end

    local now = os.clock()
    if not renderBound then hopStep(now) end

    local char = myChar()
    local root = char and rootOf(char)
    local hum = humOf(char)

    if bh.pending > 0 and root then
        local dy = root.Position.Y - bh.lastY
        if dy > bh.peak then bh.peak = dy end
        if now - bh.pending > 0.3 then
            bh.pending = 0
            if bh.peak < 0.6 then
                failCount += 1
                bh.fails += 1
                if bh.mode == "auto" or bh.mode == "hum" then
                    if bh.fails >= 2 then
                        bh.mode = "vel"
                        bh.fails = 0
                        lastState = "переход: vel"
                    end
                elseif bh.mode == "vel" then
                    if bh.fails >= 3 then
                        bh.mode = "hop"
                        bh.fails = 0
                        lastState = "переход: hop"
                    end
                elseif bh.mode == "hop" then
                    if bh.fails >= 2 then
                        bh.fails = 0
                        hop.height = math.min(hop.height + 2, 18)
                        lastState = "высота " .. string.format("%.1f", hop.height)
                    end
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

    if not grounded(char, root, hum) then
        lastState = "в воздухе"
        return
    end

    bh.nextAt = now + bh.interval
    doJump(now, root, hum)
end

track(RunService.RenderStepped:Connect(function()
    if dead then return end
    pcall(bhopTick)
end))

track(UIS.InputChanged:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseWheel then return end
    if input.Position.Z < 0 then
        bh.wheelArmed = os.clock()
        bh.nextAt = 0
    end
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

local KNIFE_WORDS = {
    "knife", "karambit", "bayonet", "lightsaber", "dagger", "talon", "butterfly",
    "falchion", "bowie", "stiletto", "ursus", "nomad", "skeleton", "paracord",
    "survival", "huntsman", "navaja", "flip", "gut", "m9", "shadow", "classic",
}
local GLOVE_WORDS = { "glove", "hands", "wraps", "arm" }
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

local function matchesName(vmName, weapon)
    if not weapon or not vmName then return false end
    if vmName == weapon then return true end
    local a, b = norm(vmName), norm(weapon)
    if a == "" or b == "" then return false end
    return a:find(b, 1, true) ~= nil or b:find(a, 1, true) ~= nil
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

local function skinTargets(weapon)
    local cat = categoryOf(weapon)
    local out, seen = {}, {}
    local function push(m)
        if m and m:IsA("Model") and not seen[m] then
            seen[m] = true
            out[#out + 1] = m
        end
    end
    local cam = camera or Workspace.CurrentCamera
    if cam then
        for _, o in ipairs(cam:GetChildren()) do
            if o:IsA("Model") then
                if cat == "gloves" then
                    local n = string.lower(o.Name)
                    if n:find("glove", 1, true) or n:find("arm", 1, true) or n:find("hand", 1, true) then
                        push(o)
                    end
                elseif matchesName(o.Name, weapon) then
                    push(o)
                end
            end
        end
        if #out == 0 and cat ~= "gloves" then
            local wanted = partNamesOf()
            for _, o in ipairs(cam:GetChildren()) do
                if o:IsA("Model") then
                    for _, p in ipairs(o:GetDescendants()) do
                        if p:IsA("BasePart") and wanted[norm(p.Name)] then
                            push(o)
                            break
                        end
                    end
                end
            end
        end
    end
    if cat == "gloves" then push(myChar()) end
    return out
end

local function findPart(vm, name)
    local low = norm(name)
    local fuzzy
    for _, p in ipairs(vm:GetDescendants()) do
        if p:IsA("BasePart") then
            local pn = norm(p.Name)
            if pn == low and low ~= "" then return p end
            if not fuzzy and low ~= "" and (pn:find(low, 1, true) or low:find(pn, 1, true)) then
                fuzzy = p
            end
        end
    end
    return fuzzy
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

    local parts = {}
    for _, p in ipairs(vm:GetDescendants()) do
        if p:IsA("BasePart") then parts[#parts + 1] = p end
    end
    if #parts == 0 then return nil end

    local refs = {}
    local used = {}
    for _, sa in ipairs(sources) do
        local part = findPart(vm, sa.Name)
        if part and not used[part] then
            used[part] = true
            refs[#refs + 1] = putSurface(part, sa)
        end
    end

    if #refs == 0 then
        table.sort(parts, function(a, b) return a.Name < b.Name end)
        for i, sa in ipairs(sources) do
            local part = parts[i]
            if not part then break end
            refs[#refs + 1] = putSurface(part, sa)
        end
    end

    if #refs == 0 then return nil end
    return refs
end

local applied = setmetatable({}, { __mode = "k" })

local function applyToTarget(vm)
    if not S.weapon or not S.skin or not vm or not vm.Parent then return false end
    local sig = S.weapon .. "|" .. S.skin
    local rec = applied[vm]
    if rec and rec.sig == sig then
        local alive = true
        for _, sa in ipairs(rec.refs) do
            if not sa.Parent then alive = false break end
        end
        if alive then return true end
    end
    local refs = applySkinTo(vm, S.weapon, S.skin)
    if not refs then return false end
    applied[vm] = { sig = sig, refs = refs }
    return true
end

local function applySkin()
    if not S.weapon or not S.skin then return false end
    local ok = false
    for _, vm in ipairs(skinTargets(S.weapon)) do
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
--  ПОДМЕНА МОДЕЛИ
--==============================================================
local hookedEngine = false
local origWeaponNew, origGetCameraModel
local WeaponComponent, SkinsLib

local function findModule(name)
    for _, d in ipairs(ReplicatedStorage:GetChildren()) do
        if d:IsA("ModuleScript") and d.Name == name then return d end
    end
    for _, d in ipairs(ReplicatedStorage:GetChildren()) do
        if d:IsA("Folder") or d:IsA("ModuleScript") then
            local f = d:FindFirstChild(name, true)
            if f and f:IsA("ModuleScript") then return f end
        end
    end
    return nil
end

local function engineAlive()
    local c = myChar()
    if not c or c.Parent ~= charsFolder() then return false end
    return not isDead(c)
end

local function installEngineHooks()
    if hookedEngine or typeof(hookfunction) ~= "function" then return end

    pcall(function() WeaponComponent = findModule("WeaponComponent") end)
    pcall(function() SkinsLib = findModule("Skins") end)
    if not WeaponComponent or not SkinsLib then return end

    local ok1 = pcall(function()
        origWeaponNew = WeaponComponent.new
        WeaponComponent.new = function(p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, ...)
            if S.swapWeapon and S.weapon and p1 == lp and engineAlive()
                and categoryOf(p5) == categoryOf(S.weapon) then
                return origWeaponNew(p1, p2, p3, p4, S.weapon, S.skin or "Vanilla", 0.001, p8, p9, p10, p11, p12, ...)
            end
            return origWeaponNew(p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, ...)
        end
    end)

    local ok2 = pcall(function()
        origGetCameraModel = SkinsLib.GetCameraModel
        SkinsLib.GetCameraModel = function(weaponName, skinName, float, statTrack, nameTag, charm, stickers, team)
            if S.swapWeapon and S.weapon and engineAlive()
                and categoryOf(weaponName) == categoryOf(S.weapon) then
                local model = origGetCameraModel(S.weapon, S.skin or "Vanilla", 0.001, statTrack, nameTag, charm, stickers, team)
                if model then model.Name = S.weapon end
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
    while not dead and task.wait(0.6) do
        if S.swapWeapon then installEngineHooks() end
        if S.holdSkin and S.skin and S.weapon then
            for _, vm in ipairs(skinTargets(S.weapon)) do
                applyToTarget(vm)
            end
        end
    end
end)

--==============================================================
--  ДИАГНОСТИКА
--==============================================================
local function diagnose()
    local out = {}
    table.insert(out, "state: " .. tostring(lastState))
    table.insert(out, "режим: " .. bh.mode .. " интервал: " .. string.format("%.2f", bh.interval))
    table.insert(out, "триггер: " .. tostring(S.trigger))
    table.insert(out, "rise: " .. string.format("%.2f", bh.peak))
    table.insert(out, "прыжков: " .. tostring(jumpCount) .. " провалов: " .. tostring(failCount))
    table.insert(out, "Оружие: " .. tostring(S.weapon) .. " / " .. tostring(S.skin))
    table.insert(out, "Скинов в базе: " .. tostring(#weaponList()))
    table.insert(out, "SkinsFolder: " .. tostring(SkinsFolder))
    table.insert(out, "WeaponComponent: " .. tostring(findModule("WeaponComponent")))
    table.insert(out, "SkinsLib: " .. tostring(findModule("Skins")))
    local ch = myChar()
    local root = ch and rootOf(ch)
    if root then
        table.insert(out, "anchored: " .. tostring(root.Anchored))
        table.insert(out, "y: " .. tostring(root.Position.Y))
        table.insert(out, "velY: " .. tostring(root.AssemblyLinearVelocity.Y))
        table.insert(out, "grounded: " .. tostring(groundRes))
    end
    local hum = myHum()
    if hum then
        local ok, st = pcall(function() return hum:GetState() end)
        table.insert(out, "humState: " .. tostring(ok and st or "err"))
        local ok2, mat = pcall(function() return hum.FloorMaterial end)
        table.insert(out, "floor: " .. tostring(ok2 and mat or "err"))
    end
    local text = table.concat(out, "\n")
    print("[SleepScript] ДИАГНОСТИКА\n" .. text)
    if setclipboard then pcall(setclipboard, text) end
    notify("Диагностика скопирована")
end

local function dumpSelf()
    local char = myChar()
    if not char then notify("Персонаж не найден") return end
    local out = { "char: " .. char.Name .. " [" .. char.ClassName .. "]", "humOf: " .. tostring(humOf(char)) }
    for _, d in ipairs(char:GetDescendants()) do
        local extra = ""
        if d:IsA("BasePart") then
            extra = string.format(" anch=%s trans=%.2f pos=%s", tostring(d.Anchored), d.Transparency, tostring(d.Position))
        end
        table.insert(out, ("%s [%s]%s"):format(d.Name, d.ClassName, extra))
    end
    local text = table.concat(out, "\n")
    print("[SleepScript] ПЕРСОНАЖ\n" .. text)
    if setclipboard then pcall(setclipboard, text) end
    notify("Дамп персонажа скопирован")
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

local function dumpCamera()
    local cam = camera or Workspace.CurrentCamera
    if not cam then notify("Камеры нет") return end
    local out = {}
    for _, o in ipairs(cam:GetChildren()) do
        if o:IsA("Model") then
            table.insert(out, o.Name .. " [" .. o.ClassName .. "] kids=" .. #o:GetChildren())
            for _, d in ipairs(o:GetDescendants()) do
                if d:IsA("BasePart") then table.insert(out, "   " .. d.Name) end
            end
        end
    end
    local text = table.concat(out, "\n")
    print("[SleepScript] КАМЕРА\n" .. text)
    if setclipboard then pcall(setclipboard, text) end
    notify("Дамп камеры скопирован")
end

local function dumpSkins()
    local out = {}
    table.insert(out, "SkinsFolder: " .. tostring(SkinsFolder))
    table.insert(out, "weapons: " .. tostring(#weaponList()))
    if SkinsFolder then
        local n = 0
        for _, f in ipairs(SkinsFolder:GetChildren()) do
            n += 1
            if n > 30 then break end
            local skins = 0
            for _, s in ipairs(f:GetChildren()) do
                if (s:IsA("Folder") or s:IsA("Model")) and skinWorks(s) then skins += 1 end
            end
            table.insert(out, f.Name .. " [" .. f.ClassName .. "] skins=" .. skins)
        end
    end
    local w = S.weapon and SkinsFolder and SkinsFolder:FindFirstChild(S.weapon)
    if w then
        table.insert(out, "-- выбранное: " .. S.weapon)
        for _, s in ipairs(w:GetChildren()) do
            if s:IsA("Folder") or s:IsA("Model") then
                local wear = wearOf(s)
                table.insert(out, s.Name .. " [" .. s.ClassName .. "] wear=" .. tostring(wear and wear.Name))
                if wear then
                    for _, d in ipairs(wear:GetDescendants()) do
                        if d:IsA("SurfaceAppearance") then table.insert(out, "    sa " .. d.Name) end
                    end
                end
            end
        end
    end
    local text = table.concat(out, "\n")
    print("[SleepScript] СКИНЫ\n" .. text)
    if setclipboard then pcall(setclipboard, text) end
    notify("Дамп скинов скопирован")
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
toggle(movePage, "Автобхоп", false, function(v)
    S.bhop = v
    bh.mode = S.unanchor and "vel" or "auto"
    bh.fails = 0
    bh.nextAt = 0
    bh.pending = 0
    bh.wheelArmed = 0
    hop.height = 5.2
end)
chips(movePage, {
    { name = "Пробел (зажать)", value = "space" },
    { name = "Колесо вниз", value = "wheel" },
    { name = "Оба", value = "both" },
}, S.trigger, function(v) S.trigger = v end, 3)
slider(movePage, "Интервал", 18, 60, 33, function(v) bh.interval = v / 100 end)
toggle(movePage, "Только скорость (без Humanoid)", false, function(v)
    S.unanchor = v
    bh.mode = v and "vel" or "auto"
    bh.fails = 0
end)

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
    while not dead and task.wait(0.2) do
        if not S.bhop then
            dbgLabel.Text = "бхоп выключен"
            continue
        end
        dbgLabel.Text = string.format("режим:%s триг:%s инт:%.2f подъём:%.1f прыжков:%d сбоев:%d %s",
            bh.mode, S.trigger, bh.interval, bh.peak, jumpCount, failCount, lastState)
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

--==============================================================
--  СТРАНИЦА СКИНОВ
--==============================================================
local MAX_ROWS = 80
local skinCat = "all"
local refreshWeapons

section(skinPage, "оружие и перчатки")
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

local weaponBox = listBox(skinPage, 132)
local skinBox = listBox(skinPage, 132)

local function refreshSkins()
    local list = skinList(S.weapon)
    S.skin = list[1]
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
    if S.weapon and not table.find(list, S.weapon) then
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

section(skinPage, "скин")
button(skinPage, "Применить скин", function()
    if not S.weapon then notify("Выбери оружие") return end
    if not S.skin then notify("Выбери скин") return end
    task.spawn(function()
        for vm in pairs(applied) do applied[vm] = nil end
        local ok = false
        for _ = 1, 8 do
            if dead then break end
            if applySkin() then ok = true break end
            task.wait(0.12)
        end
        notify(ok and "Скин применён" or "Модель не найдена — попробуй в руках")
    end)
end)
button(skinPage, "Сбросить скин", function()
    resetSkins()
    notify("Скины сброшены")
end)
toggle(skinPage, "Держать скин", true, function(v) S.holdSkin = v end)
toggle(skinPage, "Подменять модель (по категории)", false, function(v)
    S.swapWeapon = v
    if v then
        installEngineHooks()
        notify(hookedEngine and "Подмена включена" or "Хуки недоступны")
    else
        removeEngineHooks()
    end
end)

section(miscPage, "служебное")
button(miscPage, "Диагностика (F9)", diagnose)
button(miscPage, "Дамп персонажа", dumpSelf)
button(miscPage, "Дамп структуры", dumpStructure)
button(miscPage, "Дамп моделей камеры", dumpCamera)
button(miscPage, "Дамп скинов", dumpSkins)
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
--  СБОР СПИСКА ОРУЖИЯ
--==============================================================
task.spawn(function()
    for _ = 1, 80 do
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
    end
end)

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
    if renderBound then pcall(function() RunService:UnbindFromRenderStep("SleepHop") end) end
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
