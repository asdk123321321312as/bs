--[[
    ╔══════════════════════════════════════════════════════════╗
    ║   VENICE  •  TSB / UNIVERSAL                 [ v6 ]      ║
    ╠══════════════════════════════════════════════════════════╣
    ║   RightShift = скрыть UI     Z = свернуть     K = kill   ║
    ║   X = Take the L                                         ║
    ╚══════════════════════════════════════════════════════════╝
]]

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting     = game:GetService("Lighting")
local Stats        = game:GetService("Stats")
local Workspace    = game:GetService("Workspace")

local LP = Players.LocalPlayer
local function log(m) print("[VENICE] " .. tostring(m)) end

local function new(class, props)
    local o = Instance.new(class)
    local parent
    for k, v in pairs(props or {}) do
        if k == "Parent" then parent = v
        else pcall(function() o[k] = v end) end
    end
    if parent then o.Parent = parent end
    return o
end
local function corner(o, r) return new("UICorner", {CornerRadius = UDim.new(0, r), Parent = o}) end

pcall(function()
    local old = game:GetService("CoreGui"):FindFirstChild("VeniceTSB")
    if old then old:Destroy() end
end)
pcall(function()
    local pg = LP:FindFirstChild("PlayerGui")
    local old = pg and pg:FindFirstChild("VeniceTSB")
    if old then old:Destroy() end
end)

_G.VeniceSpeedVal = 40
_G.VeniceStick = true

local Theme = {
    Bg = Color3.fromRGB(12,12,16), Panel = Color3.fromRGB(26,26,34), Panel2 = Color3.fromRGB(40,40,52),
    Accent = Color3.fromRGB(158,122,255), Accent2 = Color3.fromRGB(96,205,255),
    Text = Color3.fromRGB(240,240,250), Sub = Color3.fromRGB(150,150,172), Stroke = Color3.fromRGB(60,60,76),
}

local function Main()
    local ScreenGui = new("ScreenGui", {Name = "VeniceTSB", ResetOnSpawn = false, IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 9999})
    if not pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end) or not ScreenGui.Parent then
        ScreenGui.Parent = LP:WaitForChild("PlayerGui")
    end

    local function toast(text)
        local t = new("TextLabel", {Parent = ScreenGui, AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0.02, 0), Size = UDim2.new(0, 320, 0, 34),
            BackgroundColor3 = Theme.Panel, BackgroundTransparency = 0.05, Text = tostring(text or ""),
            TextColor3 = Theme.Text, Font = Enum.Font.GothamMedium, TextSize = 13, BorderSizePixel = 0, ZIndex = 900})
        corner(t, 10)
        new("UIStroke", {Color = Theme.Accent, Transparency = 0.35, Parent = t})
        TweenService:Create(t, TweenInfo.new(0.25), {Position = UDim2.new(0.5, 0, 0.05, 0)}):Play()
        task.delay(1.7, function()
            local tw = TweenService:Create(t, TweenInfo.new(0.3), {Position = UDim2.new(0.5, 0, 0.02, 0), BackgroundTransparency = 1})
            tw:Play(); tw.Completed:Wait(); t:Destroy()
        end)
    end

    --======================== WINDOW ========================
    local W_FULL, W_MINI = UDim2.new(0, 600, 0, 410), UDim2.new(0, 600, 0, 44)
    local Window = new("Frame", {Parent = ScreenGui, AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 520, 0, 340),
        BackgroundColor3 = Theme.Bg, BorderSizePixel = 0, ClipsDescendants = true})
    corner(Window, 14)
    new("UIStroke", {Color = Theme.Accent, Thickness = 1.4, Transparency = 0.45, Parent = Window})

    local scaleObj = new("UIScale", {Parent = Window})
    local function fit()
        local vp = (Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize) or Vector2.new(1280, 720)
        scaleObj.Scale = math.min(1, (vp.X - 30) / 620, (vp.Y - 30) / 420)
    end
    fit()

    local TopBar = new("Frame", {Parent = Window, Size = UDim2.new(1, 0, 0, 44), BackgroundColor3 = Theme.Bg, BorderSizePixel = 0, ZIndex = 5})
    new("TextLabel", {Parent = TopBar, BackgroundTransparency = 1, Position = UDim2.new(0, 16, 0, 0), Size = UDim2.new(1, -130, 1, 0),
        Font = Enum.Font.GothamBold, Text = "VENICE  •  TSB", TextColor3 = Theme.Text, TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6})
    new("TextLabel", {Parent = TopBar, BackgroundTransparency = 1, Position = UDim2.new(0, 132, 0, 0), Size = UDim2.new(1, -210, 1, 0),
        Font = Enum.Font.Gotham, Text = "[Z] свернуть  •  [X] Take the L", TextColor3 = Theme.Sub, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6})
    new("Frame", {Parent = Window, Position = UDim2.new(0, 0, 0, 44), Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Theme.Stroke, BorderSizePixel = 0, ZIndex = 5})

    local function topButton(xOff, text, cb)
        local b = new("TextButton", {Parent = TopBar, Size = UDim2.new(0, 26, 0, 26), Position = UDim2.new(1, xOff, 0.5, -13),
            BackgroundColor3 = Theme.Panel2, Text = tostring(text or ""), TextColor3 = Theme.Text, Font = Enum.Font.GothamBold,
            TextSize = 14, AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 6})
        corner(b, 8)
        b.MouseButton1Click:Connect(function() pcall(cb) end)
        return b
    end

    local Sidebar = new("Frame", {Parent = Window, Position = UDim2.new(0, 10, 0, 54), Size = UDim2.new(0, 152, 1, -64),
        BackgroundColor3 = Theme.Panel, BorderSizePixel = 0, ZIndex = 2})
    corner(Sidebar, 10)
    new("UIListLayout", {Parent = Sidebar, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder})
    new("UIPadding", {Parent = Sidebar, PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)})

    local Content = new("Frame", {Parent = Window, Position = UDim2.new(0, 172, 0, 54), Size = UDim2.new(1, -184, 1, -64),
        BackgroundTransparency = 1, ZIndex = 2})

    local Pages, TabBtns = {}, {}
    local function makePage(name, order)
        local btn = new("TextButton", {Parent = Sidebar, Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = Theme.Panel,
            Text = tostring(name or ""), TextColor3 = Theme.Sub, Font = Enum.Font.GothamMedium, TextSize = 13,
            AutoButtonColor = false, BorderSizePixel = 0, LayoutOrder = order, ZIndex = 3})
        corner(btn, 8)
        local page = new("ScrollingFrame", {Parent = Content, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
            BorderSizePixel = 0, ScrollBarThickness = 3, CanvasSize = UDim2.new(0, 0, 0, 0), Visible = false, ZIndex = 2})
        pcall(function() page.ScrollBarColor = Theme.Accent end)
        new("UIListLayout", {Parent = page, Padding = UDim.new(0, 6)})
        new("UIPadding", {Parent = page, PaddingRight = UDim.new(0, 10), PaddingBottom = UDim.new(0, 12)})
        Pages[name], TabBtns[name] = page, btn
        btn.MouseButton1Click:Connect(function()
            for n, p in pairs(Pages) do
                p.Visible = (n == name)
                TabBtns[n].TextColor3 = (n == name) and Theme.Text or Theme.Sub
                TabBtns[n].BackgroundColor3 = (n == name) and Theme.Panel2 or Theme.Panel
            end
            page.Position = UDim2.new(0, 12, 0, 0)
            TweenService:Create(page, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                {Position = UDim2.new(0, 0, 0, 0)}):Play()
        end)
        return page
    end

    local minimized = false
    local function toggleMinimize()
        minimized = not minimized
        TweenService:Create(Window, TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            {Size = minimized and W_MINI or W_FULL}):Play()
        Sidebar.Visible = not minimized
        Content.Visible = not minimized
    end
    topButton(-38, "–", toggleMinimize)
    topButton(-68, "X", function() ScreenGui.Enabled = false end)

    --======================= COMPONENTS =====================
    local function section(parent, text)
        local f = new("Frame", {Parent = parent, Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1})
        new("TextLabel", {Parent = f, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Font = Enum.Font.GothamBold,
            Text = tostring(text or ""), TextColor3 = Theme.Accent, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left})
        return f
    end

    local function toggle(parent, text, default, callback)
        local f = new("Frame", {Parent = parent, Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = Theme.Panel, BorderSizePixel = 0})
        corner(f, 8)
        new("UIStroke", {Color = Theme.Stroke, Thickness = 1, Transparency = 0.5, Parent = f})
        new("TextLabel", {Parent = f, BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -70, 1, 0),
            Font = Enum.Font.Gotham, Text = tostring(text or ""), TextColor3 = Theme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left})
        local track = new("Frame", {Parent = f, Position = UDim2.new(1, -52, 0.5, -11), Size = UDim2.new(0, 40, 0, 22),
            BackgroundColor3 = Theme.Panel2, BorderSizePixel = 0})
        corner(track, 11)
        local knob = new("Frame", {Parent = track, Position = UDim2.new(0, 3, 0.5, -8), Size = UDim2.new(0, 16, 0, 16),
            BackgroundColor3 = Theme.Text, BorderSizePixel = 0, ZIndex = 2})
        corner(knob, 8)
        local btn = new("TextButton", {Parent = f, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", ZIndex = 3})
        local state = default and true or false
        local function render(anim)
            local pos = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
            local col = state and Theme.Accent or Theme.Panel2
            if anim then
                TweenService:Create(knob, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = pos}):Play()
                TweenService:Create(track, TweenInfo.new(0.18), {BackgroundColor3 = col}):Play()
            else knob.Position = pos; track.BackgroundColor3 = col end
        end
        render(false)
        btn.MouseButton1Click:Connect(function()
            state = not state; render(true)
            if callback then local ok, e = pcall(callback, state); if not ok then warn("[VENICE] toggle err: " .. tostring(e)) end end
        end)
        return {Set = function(v) state = v; render(true); if callback then pcall(callback, state) end end,
                Get = function() return state end}
    end

    local function button(parent, text, callback)
        local b = new("TextButton", {Parent = parent, Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = Theme.Panel,
            Text = tostring(text or ""), TextColor3 = Theme.Text, Font = Enum.Font.GothamMedium, TextSize = 13,
            AutoButtonColor = false, BorderSizePixel = 0})
        corner(b, 8)
        new("UIStroke", {Color = Theme.Stroke, Thickness = 1, Parent = b})
        b.MouseEnter:Connect(function() TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Panel2}):Play() end)
        b.MouseLeave:Connect(function() TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Panel}):Play() end)
        b.MouseButton1Click:Connect(function()
            TweenService:Create(b, TweenInfo.new(0.07), {BackgroundColor3 = Theme.Accent}):Play()
            task.delay(0.12, function() TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Panel}):Play() end)
            if callback then local ok, e = pcall(callback); if not ok then warn("[VENICE] button err: " .. tostring(e)) end end
        end)
        return b
    end

    local function slider(parent, text, min, max, default, callback)
        min, max, default = tonumber(min) or 0, tonumber(max) or 100, tonumber(default) or 0
        local f = new("Frame", {Parent = parent, Size = UDim2.new(1, 0, 0, 44), BackgroundColor3 = Theme.Panel, BorderSizePixel = 0})
        corner(f, 8)
        new("UIStroke", {Color = Theme.Stroke, Thickness = 1, Transparency = 0.5, Parent = f})
        new("TextLabel", {Parent = f, BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 5), Size = UDim2.new(1, -70, 0, 16),
            Font = Enum.Font.Gotham, Text = tostring(text or ""), TextColor3 = Theme.Text, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left})
        local val = new("TextLabel", {Parent = f, BackgroundTransparency = 1, Position = UDim2.new(1, -64, 0, 5), Size = UDim2.new(0, 52, 0, 16),
            Font = Enum.Font.GothamBold, Text = tostring(default), TextColor3 = Theme.Accent, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right})
        local track = new("Frame", {Parent = f, Position = UDim2.new(0, 12, 0, 28), Size = UDim2.new(1, -24, 0, 6),
            BackgroundColor3 = Theme.Panel2, BorderSizePixel = 0})
        corner(track, 3)
        local fill = new("Frame", {Parent = track, Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0})
        corner(fill, 3)
        local knob = new("Frame", {Parent = track, Position = UDim2.new(0, 0, 0.5, -7), Size = UDim2.new(0, 14, 0, 14),
            BackgroundColor3 = Theme.Text, BorderSizePixel = 0, ZIndex = 2})
        corner(knob, 7)
        local hit = new("TextButton", {Parent = track, Size = UDim2.new(1, 0, 0, 22), Position = UDim2.new(0, 0, 0.5, -11),
            BackgroundTransparency = 1, Text = ""})
        local dragging = false
        local function setFromX(x)
            local rel = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
            local v = math.floor((min + (max - min) * rel) * 100) / 100
            fill.Size = UDim2.new(rel, 0, 1, 0); knob.Position = UDim2.new(rel, 0, 0.5, -7); val.Text = tostring(v)
            if callback then pcall(callback, v) end
        end
        do local rel = math.clamp((default - min) / math.max(max - min, 1), 0, 1)
            fill.Size = UDim2.new(rel, 0, 1, 0); knob.Position = UDim2.new(rel, 0, 0.5, -7) end
        hit.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                dragging = true; setFromX(i.Position.X) end end)
        UIS.InputChanged:Connect(function(i)
            if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                setFromX(i.Position.X) end end)
        UIS.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
    end

    local function textbox(parent, placeholder, callback)
        local f = new("Frame", {Parent = parent, Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = Theme.Panel, BorderSizePixel = 0})
        corner(f, 8)
        new("UIStroke", {Color = Theme.Stroke, Thickness = 1, Parent = f})
        local tb = new("TextBox", {Parent = f, BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0),
            Size = UDim2.new(1, -24, 1, 0), Font = Enum.Font.Gotham, Text = "", PlaceholderText = tostring(placeholder or ""),
            PlaceholderColor3 = Theme.Sub, TextColor3 = Theme.Text, TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false})
        tb.FocusLost:Connect(function(e) if e and callback then pcall(callback, tb.Text) end end)
        return tb
    end

    --==================== DROPDOWN (фикс nil) ==============
    local function dropdown(parent, text, options, default, callback)
        options = (type(options) == "table") and options or {}
        local function first()
            local v = default
            if v == nil or v == "" then v = options[1] end
            if v == nil or v == "" then v = "—" end
            return tostring(v)
        end
        local f = new("Frame", {Parent = parent, Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = Theme.Panel, BorderSizePixel = 0})
        corner(f, 8)
        new("UIStroke", {Color = Theme.Stroke, Thickness = 1, Transparency = 0.5, Parent = f})
        new("TextLabel", {Parent = f, BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(0.5, 0, 1, 0),
            Font = Enum.Font.Gotham, Text = tostring(text or ""), TextColor3 = Theme.Text, TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left})
        local val = new("TextLabel", {Parent = f, BackgroundTransparency = 1, Position = UDim2.new(0.5, -12, 0, 0), Size = UDim2.new(0.5, -24, 1, 0),
            Font = Enum.Font.GothamMedium, Text = first(), TextColor3 = Theme.Accent,
            TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right})
        local btn = new("TextButton", {Parent = f, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = ""})
        local selected = first()
        local list
        local function close() if list then list:Destroy(); list = nil end end
        btn.MouseButton1Click:Connect(function()
            if list then close(); return end
            if #options == 0 then return end
            list = new("ScrollingFrame", {Parent = ScreenGui,
                Position = UDim2.fromOffset(f.AbsolutePosition.X, f.AbsolutePosition.Y + f.AbsoluteSize.Y + 4),
                Size = UDim2.fromOffset(f.AbsoluteSize.X, math.min(#options * 26 + 6, 170)),
                BackgroundColor3 = Theme.Panel2, BorderSizePixel = 0, ZIndex = 400, ScrollBarThickness = 3,
                CanvasSize = UDim2.new(0, 0, 0, 0)})
            corner(list, 8)
            new("UIStroke", {Color = Theme.Stroke, Parent = list})
            new("UIListLayout", {Parent = list, Padding = UDim.new(0, 1)})
            for _, opt in ipairs(options) do
                local ob = new("TextButton", {Parent = list, Size = UDim2.new(1, 0, 0, 25), BackgroundTransparency = 1,
                    Text = "  " .. tostring(opt or "?"), TextColor3 = Theme.Text, Font = Enum.Font.Gotham, TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false})
                ob.MouseEnter:Connect(function() ob.BackgroundTransparency = 0.85; ob.BackgroundColor3 = Theme.Accent end)
                ob.MouseLeave:Connect(function() ob.BackgroundTransparency = 1 end)
                ob.MouseButton1Click:Connect(function()
                    selected = tostring(opt or "—"); val.Text = selected; close()
                    if callback then pcall(callback, selected) end
                end)
            end
        end)
        return {
            Get = function() return selected end,
            Set = function(v) selected = tostring(v or "—"); val.Text = selected end,
            Refresh = function(o)
                options = (type(o) == "table") and o or {}
                local still = false
                for _, x in ipairs(options) do if x == selected then still = true end end
                if not still then selected = first() end
                val.Text = selected
            end,
        }
    end

    --========================= DRAG =========================
    do
        local dragging, dragStart, startPos
        TopBar.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                dragging = true; dragStart = i.Position; startPos = Window.Position
                i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then dragging = false end end)
            end
        end)
        UIS.InputChanged:Connect(function(i)
            if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                local d = i.Position - dragStart
                Window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end)
    end

    --===================== NO COOLDOWN ======================
    local NoCooldown = false
    pcall(function()
        local mt = getrawmetatable(game); local oi = mt.__index
        setreadonly(mt, false)
        local function hook(self, key)
            local v = oi(self, key)
            if NoCooldown and type(key) == "string" and string.find(string.lower(key), "cooldown") then
                if type(v) == "number" and v > 0 then return 0 end
            end
            return v
        end
        mt.__index = (newcclosure and newcclosure(hook)) or hook
        setreadonly(mt, true)
    end)
    task.spawn(function()
        while true do
            if NoCooldown then
                for _, root in ipairs({LP, LP.Character}) do
                    if root then
                        for _, v in ipairs(root:GetDescendants()) do
                            if (v:IsA("NumberValue") or v:IsA("IntValue")) and string.find(string.lower(v.Name), "cooldown") then
                                pcall(function() v.Value = 0 end)
                            end
                        end
                    end
                end
            end
            RunService.Heartbeat:Wait()
        end
    end)

    --======================== KILL ==========================
    local function killPlayer(plr)
        local char = plr and plr.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        task.spawn(function()
            for _ = 1, 60 do
                if not hum.Parent then break end
                pcall(function() hum.Health = 0; hum:SetAttribute("Health", 0) end)
                RunService.Heartbeat:Wait()
            end
        end)
    end

    --=============== ПРОЗРАЧНОСТЬ / КОЛЛИЗИИ ================
    local origTrans, origProps, origCollide = {}, {}, {}
    local invisible, headless, korblox, noclip = false, false, false, false
    local busy = false

    local function captureOrig(char)
        origTrans = {}
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("BasePart") or v:IsA("Decal") or v:IsA("Texture") then origTrans[v] = v.Transparency end
        end
    end
    local function hide(part, state)
        if origTrans[part] == nil then origTrans[part] = part.Transparency end
        part.Transparency = state and 1 or origTrans[part]
    end
    local function applyInvis(state)
        local char = LP.Character; if not char then return end
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("BasePart") or v:IsA("Decal") or v:IsA("Texture") then hide(v, state) end
        end
    end
    local function applyHeadless(state)
        local char = LP.Character; if not char then return end
        local head = char:FindFirstChild("Head"); if not head then return end
        hide(head, state)
        for _, d in ipairs(head:GetDescendants()) do
            if d:IsA("Decal") or d:IsA("BasePart") then hide(d, state) end
        end
    end

    --===================== NOCLIP ===========================
    local function applyNoclip(state)
        local char = LP.Character; if not char then return end
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("BasePart") then
                if state then
                    if origCollide[v] == nil then origCollide[v] = v.CanCollide end
                    v.CanCollide = false
                elseif origCollide[v] ~= nil then
                    v.CanCollide = origCollide[v]; origCollide[v] = nil
                end
            end
        end
    end
    local rayParams
    local function getRayParams(char)
        if not rayParams then
            rayParams = RaycastParams.new()
            if not pcall(function() rayParams.FilterType = Enum.RaycastFilterType.Exclude end) then
                pcall(function() rayParams.FilterType = Enum.RaycastFilterType.Blacklist end)
            end
        end
        rayParams.FilterDescendantsInstances = {char}
        return rayParams
    end

    --======================== KORBLOX ========================
    local function rightLegs(char)
        local out = {}
        for _, v in ipairs(char:GetChildren()) do
            if v:IsA("BasePart") then
                local n = string.lower(v.Name)
                if string.find(n, "right") and string.find(n, "leg") then table.insert(out, v) end
            end
        end
        return out
    end
    local function applyKorblox(state)
        local char = LP.Character; if not char then return end
        for _, part in ipairs(rightLegs(char)) do
            if origProps[part] == nil then
                local sm = part:FindFirstChildOfClass("SpecialMesh")
                origProps[part] = {Color = part.Color, Size = part.Size, Material = part.Material,
                    Tex = part:IsA("MeshPart") and part.TextureID or (sm and sm.TextureId or nil)}
            end
            local s = origProps[part]
            if state then
                local sm = part:FindFirstChildOfClass("SpecialMesh")
                if sm then pcall(function() sm.TextureId = "" end) end
                if part:IsA("MeshPart") then pcall(function() part.TextureID = "" end) end
                part.Color = Color3.fromRGB(0, 0, 0)
                part.Material = Enum.Material.Plastic
                part.Size = Vector3.new(s.Size.X * 0.55, s.Size.Y, s.Size.Z * 0.55)
            else
                part.Color = s.Color; part.Material = s.Material; part.Size = s.Size
                local sm = part:FindFirstChildOfClass("SpecialMesh")
                if sm and s.Tex then pcall(function() sm.TextureId = s.Tex end) end
                if part:IsA("MeshPart") and s.Tex then pcall(function() part.TextureID = s.Tex end) end
            end
        end
    end

    --===================== SKY / WEATHER ===================
    local savedSky, SkyObj, AtmoObj, CC, Bloom
    local function restoreSky()
        if not savedSky then return end
        for k, v in pairs(savedSky) do pcall(function() Lighting[k] = v end) end
        for _, o in ipairs({SkyObj, AtmoObj, CC, Bloom}) do if o then o:Destroy() end end
        SkyObj, AtmoObj, CC, Bloom, savedSky = nil, nil, nil, nil, nil
    end
    local SkyPresets = {
        ["Void"]     = {clock = 0,  amb = Color3.fromRGB(18,14,38), out = Color3.fromRGB(28,18,60),  top = Color3.fromRGB(70,45,140),  fog = Color3.fromRGB(10,8,26),  atmo = Color3.fromRGB(120,100,200)},
        ["Crimson"]  = {clock = 17, amb = Color3.fromRGB(50,15,15), out = Color3.fromRGB(80,25,20),  top = Color3.fromRGB(180,60,40),  fog = Color3.fromRGB(40,10,10),  atmo = Color3.fromRGB(200,90,60)},
        ["Neon"]     = {clock = 0,  amb = Color3.fromRGB(10,30,35), out = Color3.fromRGB(15,55,65),  top = Color3.fromRGB(40,200,220), fog = Color3.fromRGB(5,20,25),   atmo = Color3.fromRGB(80,220,230)},
        ["Midnight"] = {clock = 0,  amb = Color3.fromRGB(12,12,20), out = Color3.fromRGB(20,20,40),  top = Color3.fromRGB(40,40,90),   fog = Color3.fromRGB(8,8,18),    atmo = Color3.fromRGB(90,90,160)},
        ["Golden"]   = {clock = 6,  amb = Color3.fromRGB(60,45,25), out = Color3.fromRGB(90,70,40),  top = Color3.fromRGB(255,180,90), fog = Color3.fromRGB(70,50,25),  atmo = Color3.fromRGB(255,200,130)},
    }
    local function applySky(name)
        if not savedSky then
            savedSky = {ClockTime = Lighting.ClockTime, Brightness = Lighting.Brightness, Ambient = Lighting.Ambient,
                OutdoorAmbient = Lighting.OutdoorAmbient, ColorShift_Top = Lighting.ColorShift_Top,
                ColorShift_Bottom = Lighting.ColorShift_Bottom, FogColor = Lighting.FogColor,
                FogStart = Lighting.FogStart, FogEnd = Lighting.FogEnd, GlobalShadows = Lighting.GlobalShadows}
        end
        local p = SkyPresets[name]; if not p then return end
        Lighting.ClockTime = p.clock; Lighting.Brightness = 1.3
        Lighting.Ambient = p.amb; Lighting.OutdoorAmbient = p.out
        Lighting.ColorShift_Top = p.top; Lighting.ColorShift_Bottom = p.top
        Lighting.FogColor = p.fog; Lighting.FogStart = 0; Lighting.FogEnd = 1400
        if not SkyObj then SkyObj = new("Sky", {Parent = Lighting, Name = "VeniceSky", StarCount = 6000}) end
        if not AtmoObj then AtmoObj = new("Atmosphere", {Parent = Lighting, Name = "VeniceAtmo", Density = 0.38, Offset = 0.1, Glare = 0.25, Haze = 1.4}) end
        AtmoObj.Color = p.atmo; AtmoObj.Decay = p.fog
        if not CC then CC = new("ColorCorrectionEffect", {Parent = Lighting, Name = "VeniceCC", Brightness = 0.02, Contrast = 0.12, Saturation = 0.18}) end
        if not Bloom then Bloom = new("BloomEffect", {Parent = Lighting, Name = "VeniceBloom", Intensity = 0.9, Size = 22, Threshold = 1.1}) end
    end

    --====================== PARTICLES ======================
    local function clearParticles()
        local char = LP.Character; if not char then return end
        for _, v in ipairs(char:GetDescendants()) do if v.Name == "VeniceAttach" then v:Destroy() end end
    end
    local function buildParticles(kind)
        local char = LP.Character; if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
        clearParticles()
        local att = new("Attachment", {Name = "VeniceAttach", Parent = hrp})
        local pe = new("ParticleEmitter", {Parent = att, LightInfluence = 0.2, LightEmission = 0.8})
        if kind == "Aura" then
            pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
            pe.Color = ColorSequence.new(Theme.Accent, Theme.Accent2)
            pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1.4)})
            pe.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1)})
            pe.Lifetime = NumberRange.new(0.7, 1.3); pe.Rate = 70; pe.Speed = NumberRange.new(2, 6)
            pe.SpreadAngle = Vector2.new(180, 180); pe.Acceleration = Vector3.new(0, 4, 0)
        elseif kind == "Fire" then
            pe.Texture = "rbxasset://textures/particles/fire_main.dds"
            pe.Color = ColorSequence.new(Color3.fromRGB(255,180,60), Color3.fromRGB(255,60,20))
            pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 2.4)})
            pe.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1)})
            pe.Lifetime = NumberRange.new(0.5, 1.1); pe.Rate = 120; pe.Speed = NumberRange.new(3, 8)
            pe.SpreadAngle = Vector2.new(25, 25); pe.Acceleration = Vector3.new(0, 8, 0)
        elseif kind == "Lightning" then
            pe.Texture = "rbxasset://textures/particles/spark_main.dds"
            pe.Color = ColorSequence.new(Color3.fromRGB(140,200,255), Color3.new(1,1,1))
            pe.Size = NumberSequence.new(0.7); pe.Lifetime = NumberRange.new(0.2, 0.5); pe.Rate = 140
            pe.Speed = NumberRange.new(8, 18); pe.SpreadAngle = Vector2.new(180, 180); pe.Rotation = NumberRange.new(0, 360)
        elseif kind == "Void" then
            pe.Texture = "rbxasset://textures/particles/explosion01_implosion_main.dds"
            pe.Color = ColorSequence.new(Color3.fromRGB(90,40,180), Color3.fromRGB(20,0,50))
            pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1.5), NumberSequenceKeypoint.new(1, 3)})
            pe.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1)})
            pe.Lifetime = NumberRange.new(0.8, 1.6); pe.Rate = 45; pe.Speed = NumberRange.new(1, 4)
            pe.SpreadAngle = Vector2.new(180, 180)
        elseif kind == "Snow" then
            pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
            pe.Color = ColorSequence.new(Color3.new(1,1,1), Color3.fromRGB(200,220,255))
            pe.Size = NumberSequence.new(0.5); pe.Lifetime = NumberRange.new(1.5, 3); pe.Rate = 60
            pe.Speed = NumberRange.new(0.5, 2); pe.SpreadAngle = Vector2.new(180, 180); pe.Acceleration = Vector3.new(0, -3, 0)
        end
    end

    --====================== ANIMATIONS =====================
    local AnimList = {
        ["Take the L"] = "rbxassetid://124573621747512",
        ["R6 Dance 1"] = "rbxassetid://182435998",
        ["R6 Dance 2"] = "rbxassetid://182436842",
        ["R6 Dance 3"] = "rbxassetid://182437046",
        ["R6 Wave"]    = "rbxassetid://128777973",
        ["R6 Point"]   = "rbxassetid://128853357",
        ["R6 Cheer"]   = "rbxassetid://129423131",
        ["R6 Laugh"]   = "rbxassetid://129423030",
        ["R15 Dance"]  = "rbxassetid://507771019",
        ["R15 Wave"]   = "rbxassetid://507770239",
    }
    local lastTrack
    local function playAnim(id)
        local char = LP.Character; if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
        local animator = hum:FindFirstChildOfClass("Animator") or new("Animator", {Parent = hum})
        if lastTrack then pcall(function() lastTrack:Stop(0.15) end); lastTrack = nil end
        local anim = new("Animation", {AnimationId = tostring(id or ""), Parent = char})
        local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
        if not ok or not track then return end
        pcall(function() track.Priority = Enum.AnimationPriority.Action4; track.Looped = false end)
        track:Play(0.15)
        lastTrack = track
    end
    local function stopAnims()
        local char = LP.Character; if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
        local animator = hum:FindFirstChildOfClass("Animator"); if not animator then return end
        for _, t in ipairs(animator:GetPlayingAnimationTracks()) do pcall(function() t:Stop(0.2) end) end
        lastTrack = nil
    end

    --========================= STATS =======================
    local fps, ping, mem = 0, 0, 0
    do
        local frames, lastT = 0, tick()
        RunService.RenderStepped:Connect(function()
            frames = frames + 1
            if tick() - lastT >= 0.5 then fps = math.floor(frames / (tick() - lastT)); frames = 0; lastT = tick() end
        end)
        task.spawn(function()
            while true do
                pcall(function() ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
                pcall(function() mem = math.floor(Stats:GetTotalMemoryUsageMb()) end)
                task.wait(0.5)
            end
        end)
    end

    --======================== OVERLAY ======================
    local Overlay = new("Frame", {Parent = ScreenGui, Position = UDim2.new(0, 14, 0, 14), Size = UDim2.new(0, 160, 0, 84),
        BackgroundColor3 = Theme.Bg, BackgroundTransparency = 0.15, BorderSizePixel = 0, ZIndex = 500})
    corner(Overlay, 10)
    new("UIStroke", {Color = Theme.Accent, Thickness = 1, Transparency = 0.5, Parent = Overlay})
    new("UIListLayout", {Parent = Overlay, Padding = UDim.new(0, 2),
        HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center})
    new("TextLabel", {Parent = Overlay, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 16),
        Font = Enum.Font.GothamBold, Text = "VENICE", TextColor3 = Theme.Accent, TextSize = 11})
    local ovFps  = new("TextLabel", {Parent = Overlay, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 16),
        Font = Enum.Font.GothamMedium, Text = "FPS: 0", TextColor3 = Theme.Text, TextSize = 12})
    local ovPing = new("TextLabel", {Parent = Overlay, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 16),
        Font = Enum.Font.GothamMedium, Text = "PING: 0 ms", TextColor3 = Theme.Text, TextSize = 12})
    local ovMem  = new("TextLabel", {Parent = Overlay, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 16),
        Font = Enum.Font.GothamMedium, Text = "MEM: 0 MB", TextColor3 = Theme.Sub, TextSize = 11})
    do
        local oDrag, oStart, oPos
        Overlay.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                oDrag = true; oStart = i.Position; oPos = Overlay.Position end end)
        UIS.InputChanged:Connect(function(i)
            if oDrag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                local d = i.Position - oStart
                Overlay.Position = UDim2.new(oPos.X.Scale, oPos.X.Offset + d.X, oPos.Y.Scale, oPos.Y.Offset + d.Y) end end)
        UIS.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then oDrag = false end end)
    end
    task.spawn(function()
        while true do
            ovFps.Text = "FPS: " .. tostring(fps)
            ovPing.Text = "PING: " .. tostring(ping) .. " ms"
            ovMem.Text = "MEM: " .. tostring(mem) .. " MB"
            task.wait(0.25)
        end
    end)

    --======================= PS BOOST ======================
    local psSaved = {}
    local function psBoost(state)
        if state then
            pcall(function() settings().Rendering.QualityLevel = 1 end)
            psSaved.GlobalShadows = Lighting.GlobalShadows
            Lighting.GlobalShadows = false
            for _, v in ipairs(Lighting:GetChildren()) do
                if v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("DepthOfFieldEffect") then
                    if psSaved[v] == nil then psSaved[v] = v.Enabled end
                    v.Enabled = false
                end
            end
        else
            pcall(function() settings().Rendering.QualityLevel = 21 end)
            if psSaved.GlobalShadows ~= nil then Lighting.GlobalShadows = psSaved.GlobalShadows end
            for obj, en in pairs(psSaved) do
                if typeof(obj) == "Instance" and obj.Parent then pcall(function() obj.Enabled = en end) end
            end
        end
    end

    --======================= BUILD TABS ====================
    local combat  = makePage("Бой", 1)
    local visuals = makePage("Визуалы", 2)
    local player  = makePage("Игрок", 3)
    local statsP  = makePage("Статы", 4)

    section(combat, "СПОСОБНОСТИ")
    toggle(combat, "Без перезарядки (No Cooldown)", false, function(s) NoCooldown = s end)
    button(combat, "Включить No Cooldown", function() NoCooldown = true; toast("No Cooldown ON") end)

    section(combat, "УБИЙСТВО")
    local playerList = {}
    local targetDD
    local function refreshPlayers(updateDD)
        playerList = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP then table.insert(playerList, p.Name) end
        end
        if #playerList == 0 then table.insert(playerList, "нет игроков") end
        if updateDD and targetDD then targetDD.Refresh(playerList) end
    end
    refreshPlayers(false)
    targetDD = dropdown(combat, "Цель", playerList, playerList[1], function() end)
    button(combat, "Обновить список", function() refreshPlayers(true); toast("Список обновлён") end)
    button(combat, "УБИТЬ ВЫБРАННОГО", function()
        local plr = Players:FindFirstChild(targetDD.Get())
        if not plr then for _, p in ipairs(Players:GetPlayers()) do if p ~= LP then plr = p; break end end end
        if plr then killPlayer(plr); toast("Kill -> " .. plr.Name) else toast("Игрок не найден") end
    end)
    button(combat, "УБИТЬ ВСЕХ", function()
        local n = 0
        for _, p in ipairs(Players:GetPlayers()) do if p ~= LP then killPlayer(p); n = n + 1 end end
        toast("Kill all: " .. tostring(n))
    end)

    -- авто-обновление списка при входе/выходе игроков
    Players.PlayerAdded:Connect(function() task.wait(0.4); refreshPlayers(true) end)
    Players.PlayerRemoving:Connect(function() task.wait(0.2); refreshPlayers(true) end)

    section(visuals, "КАСТОМНОЕ НЕБО")
    local skyDD
    local skyToggle = toggle(visuals, "Включить небо", false, function(s)
        if s then applySky(skyDD.Get()) else restoreSky() end end)
    skyDD = dropdown(visuals, "Пресет", {"Void","Crimson","Neon","Midnight","Golden"}, "Void", function(n)
        if skyToggle.Get() then applySky(n) end end)

    section(visuals, "ПАРТИКЛЫ")
    local partDD
    local partToggle = toggle(visuals, "Включить партиклы", false, function(s)
        if s then buildParticles(partDD.Get()) else clearParticles() end end)
    partDD = dropdown(visuals, "Эффект", {"Aura","Fire","Lightning","Void","Snow"}, "Aura", function(k)
        if partToggle.Get() then buildParticles(k) end end)

    section(visuals, "АНИМАЦИИ")
    local animNames = {}
    for k in pairs(AnimList) do table.insert(animNames, k) end
    table.sort(animNames)
    local animDD = dropdown(visuals, "Анимация", animNames, "Take the L", function() end)
    button(visuals, "Проиграть выбранную", function() playAnim(AnimList[animDD.Get()]) end)
    button(visuals, "TAKE THE L  (клавиша X)", function() playAnim(AnimList["Take the L"]); toast("Take the L") end)
    button(visuals, "Остановить анимации", function() stopAnims() end)
    textbox(visuals, "Свой AnimationId (rbxassetid://...)", function(t)
        if t and t ~= "" then playAnim(t); toast("Анимация запущена") end end)

    section(player, "ПЕРСОНАЖ")
    toggle(player, "Headless (без головы)", false, function(s) headless = s; applyHeadless(s); toast("Headless: " .. tostring(s)) end)
    toggle(player, "Korblox (чёрная правая нога)", false, function(s) korblox = s; applyKorblox(s); toast("Korblox: " .. tostring(s)) end)

    section(player, "НЕВИДИМОСТЬ")
    toggle(player, "Невидимка", false, function(s) invisible = s; applyInvis(s); toast("Невидимка: " .. tostring(s)) end)

    section(player, "ПЕРЕМЕЩЕНИЕ")
    toggle(player, "Спидхак", false, function(s) _G.VeniceSpeed = s; toast("Спидхак: " .. tostring(s)) end)
    slider(player, "WalkSpeed", 16, 300, 40, function(v) _G.VeniceSpeedVal = v end)
    toggle(player, "Noclip (сквозь стены)", false, function(s) noclip = s; applyNoclip(s); toast("Noclip: " .. tostring(s)) end)
    toggle(player, "Прилипание к полу (noclip)", true, function(s) _G.VeniceStick = s end)
    toggle(player, "Infinite Jump", false, function(s) _G.VeniceInfJump = s end)
    button(player, "Респавн персонажа", function()
        local c = LP.Character
        if c then local h = c:FindFirstChildOfClass("Humanoid"); if h then h.Health = 0 end end
    end)

    section(statsP, "ИНТЕРФЕЙС")
    toggle(statsP, "Показывать оверлей", true, function(s) Overlay.Visible = s end)
    slider(statsP, "FOV", 40, 130, 70, function(v) _G.VeniceFOV = v end)
    toggle(statsP, "PS Boost", false, function(s) psBoost(s) end)

    --======================= ФИЗИКА / ШАГ ==================
    RunService.Stepped:Connect(function()
        local char = LP.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")

        if _G.VeniceSpeed and hum then
            hum.WalkSpeed = _G.VeniceSpeedVal or 40
        end

        if noclip then
            for _, v in pairs(char:GetDescendants()) do
                if v:IsA("BasePart") then
                    if origCollide[v] == nil then origCollide[v] = v.CanCollide end
                    v.CanCollide = false
                end
            end
            if _G.VeniceStick and hrp and hum and hum:GetState() ~= Enum.HumanoidStateType.Jumping then
                local res = Workspace:Raycast(hrp.Position, Vector3.new(0, -7, 0), getRayParams(char))
                if res then
                    local ty = res.Position.Y + 3
                    if hrp.Position.Y - ty > 0.2 then
                        hrp.CFrame = CFrame.new(hrp.Position.X, ty, hrp.Position.Z)
                    end
                end
            end
        end
    end)

    --======================= MAIN LOOPS ====================
    UIS.JumpRequest:Connect(function()
        if _G.VeniceInfJump and LP.Character then
            local h = LP.Character:FindFirstChildOfClass("Humanoid")
            if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end)

    local lastFit = 0
    task.spawn(function()
        while true do
            RunService.Heartbeat:Wait()
            local char = LP.Character
            if char and not busy then
                if invisible then applyInvis(true) end
                if headless then applyHeadless(true) end
                if korblox then applyKorblox(true) end
            end
            if _G.VeniceFOV and Workspace.CurrentCamera then Workspace.CurrentCamera.FieldOfView = _G.VeniceFOV end
            if tick() - lastFit > 1 then lastFit = tick(); fit() end
            for _, p in pairs(Pages) do
                local lay = p:FindFirstChildOfClass("UIListLayout")
                if lay then
                    local h = lay.AbsoluteContentSize.Y + 20
                    if math.abs(p.CanvasSize.Y.Offset - h) > 2 then p.CanvasSize = UDim2.new(0, 0, 0, h) end
                end
            end
        end
    end)

    local function onChar(char)
        busy = true
        task.wait(0.7)
        captureOrig(char)
        origProps, origCollide = {}, {}
        busy = false
        if invisible then applyInvis(true) end
        if headless then applyHeadless(true) end
        if korblox then applyKorblox(true) end
        if noclip then applyNoclip(true) end
        if partToggle.Get() then buildParticles(partDD.Get()) end
    end
    if LP.Character then task.spawn(onChar, LP.Character) end
    LP.CharacterAdded:Connect(onChar)

    --======================= KEYBINDS ======================
    UIS.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.RightShift then
            ScreenGui.Enabled = not ScreenGui.Enabled
        elseif input.KeyCode == Enum.KeyCode.Z then
            toggleMinimize()
        elseif input.KeyCode == Enum.KeyCode.X then
            playAnim(AnimList["Take the L"]); toast("Take the L")
        elseif input.KeyCode == Enum.KeyCode.K then
            for _, p in ipairs(Players:GetPlayers()) do if p ~= LP then killPlayer(p) end end
        end
    end)

    --========================= INTRO =======================
    combat.Visible = true
    TabBtns["Бой"].TextColor3 = Theme.Text
    TabBtns["Бой"].BackgroundColor3 = Theme.Panel2
    TweenService:Create(Window, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = W_FULL}):Play()
    toast("VENICE v6 загружен")
end

local ok, err = xpcall(Main, function(e) return tostring(e) .. "\n" .. debug.traceback() end)
if ok then log("готово") else warn("[VENICE] ФАТАЛЬНАЯ ОШИБКА:\n" .. tostring(err)) end
