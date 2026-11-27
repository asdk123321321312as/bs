--[[  KittenScript for Blox Strike
      Camera FOV · Auto BunnyHop · ESP · SkinChanger
      Toggle menu: RightShift
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local env = (getgenv and getgenv()) or shared

if env.KittenScript and type(env.KittenScript.Unload) == "function" then
	pcall(function() env.KittenScript:Unload() end)
end

---------------------------------------------------------------------------
-- Палитра: нежно-розовый / белый
---------------------------------------------------------------------------
local C = {
	BgTop      = Color3.fromRGB(255, 246, 250),
	BgBottom   = Color3.fromRGB(255, 214, 232),
	Panel      = Color3.fromRGB(255, 236, 244),
	Element    = Color3.fromRGB(255, 250, 252),
	Hover      = Color3.fromRGB(255, 255, 255),
	Stroke     = Color3.fromRGB(255, 182, 209),
	Accent     = Color3.fromRGB(255, 111, 165),
	AccentDeep = Color3.fromRGB(226, 62, 130),
	Text       = Color3.fromRGB(74, 44, 58),
	Dim        = Color3.fromRGB(168, 124, 144),
	Off        = Color3.fromRGB(240, 215, 226),
	White      = Color3.fromRGB(255, 255, 255),
}

local Connections = {}
local function bind(signal, fn)
	local c = signal:Connect(fn)
	table.insert(Connections, c)
	return c
end

local function create(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props or {}) do pcall(function() o[k] = v end) end
	if parent then o.Parent = parent end
	return o
end

local function tween(obj, time, props, style, dir)
	local t = TweenService:Create(
		obj,
		TweenInfo.new(time, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out),
		props
	)
	t:Play()
	return t
end

local function corner(obj, r)
	create("UICorner", { CornerRadius = UDim.new(0, r or 10) }, obj)
end

local function stroke(obj, color, thickness, trans)
	return create("UIStroke", {
		Color = color or C.Stroke,
		Thickness = thickness or 1,
		Transparency = trans or 0.35,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, obj)
end

local Persist = { autosave = true, queue = function() end }

---------------------------------------------------------------------------
-- ScreenGui
---------------------------------------------------------------------------
local gui = { Toggled = true }
local screen = create("ScreenGui", {
	Name = "KittenScript",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 9999,
}, LocalPlayer:WaitForChild("PlayerGui"))

---------------------------------------------------------------------------
-- Уведомления
---------------------------------------------------------------------------
local notifyHolder = create("Frame", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -20, 0, 20),
	Size = UDim2.fromOffset(258, 10),
	BackgroundTransparency = 1,
}, screen)
create("UIListLayout", { Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder }, notifyHolder)

local function notify(titleText, body)
	local card = create("Frame", {
		Size = UDim2.new(1, 0, 0, 56),
		BackgroundColor3 = C.White,
		BackgroundTransparency = 1,
	}, notifyHolder)
	corner(card, 14)
	stroke(card, C.Stroke, 1, 0.35)
	create("Frame", { Size = UDim2.new(0, 3, 1, -16), Position = UDim2.fromOffset(0, 8), BackgroundColor3 = C.Accent, BorderSizePixel = 0 }, card)
	local t = create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(13, 8),
		Size = UDim2.new(1, -22, 0, 16),
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = C.AccentDeep,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = titleText,
	}, card)
	local b = create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(13, 26),
		Size = UDim2.new(1, -22, 0, 22),
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextColor3 = C.Dim,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Text = body,
	}, card)
	tween(card, 0.22, { BackgroundTransparency = 0.03 })
	task.delay(4, function()
		pcall(function()
			tween(card, 0.25, { BackgroundTransparency = 1 })
			tween(t, 0.25, { TextTransparency = 1 })
			tween(b, 0.25, { TextTransparency = 1 })
			task.wait(0.3)
			card:Destroy()
		end)
	end)
end

---------------------------------------------------------------------------
-- Мини-кнопка
---------------------------------------------------------------------------
local mini = create("TextButton", {
	Size = UDim2.fromOffset(120, 34),
	Position = UDim2.new(0, 20, 0, 20),
	BackgroundColor3 = C.White,
	AutoButtonColor = false,
	Text = "",
	Visible = false,
}, screen)
corner(mini, 17)
stroke(mini, C.Accent, 1, 0.35)
create("TextLabel", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	TextSize = 13,
	TextColor3 = C.AccentDeep,
	Text = "Kitten",
}, mini)
create("Frame", { Size = UDim2.new(0, 4, 1, -12), Position = UDim2.fromOffset(0, 6), BackgroundColor3 = C.Accent, BorderSizePixel = 0 }, mini)

---------------------------------------------------------------------------
-- Тень + окно
---------------------------------------------------------------------------
local shadow = create("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(616, 436),
	BackgroundColor3 = Color3.fromRGB(120, 60, 90),
	BackgroundTransparency = 0.82,
	BorderSizePixel = 0,
}, screen)
corner(shadow, 30)

local main = create("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(600, 420),
	BackgroundColor3 = C.BgTop,
	BorderSizePixel = 0,
	ClipsDescendants = true,
}, screen)
corner(main, 22)
stroke(main, C.Stroke, 1, 0.1)
create("UIGradient", {
	Rotation = 90,
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, C.BgTop),
		ColorSequenceKeypoint.new(1, C.BgBottom),
	}),
}, main)
local mainScale = create("UIScale", { Scale = 1 }, main)

local function syncShadow()
	shadow.Position = main.Position
	shadow.Size = UDim2.fromOffset(main.AbsoluteSize.X + 16, main.AbsoluteSize.Y + 16)
	shadow.Visible = main.Visible
end
bind(main:GetPropertyChangedSignal("Position"), syncShadow)
bind(main:GetPropertyChangedSignal("AbsoluteSize"), syncShadow)

create("Frame", {
	Size = UDim2.new(1, 0, 0, 3),
	BackgroundColor3 = C.Accent,
	BorderSizePixel = 0,
	BackgroundTransparency = 0.25,
}, main)

local header = create("Frame", {
	Size = UDim2.new(1, 0, 0, 58),
	BackgroundTransparency = 1,
}, main)

create("TextLabel", {
	Position = UDim2.fromOffset(22, 10),
	Size = UDim2.new(0, 260, 0, 24),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBlack,
	TextSize = 18,
	TextColor3 = C.AccentDeep,
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "KittenScript",
}, header)

create("TextLabel", {
	Position = UDim2.fromOffset(23, 34),
	Size = UDim2.new(0, 280, 0, 14),
	BackgroundTransparency = 1,
	Font = Enum.Font.Gotham,
	TextSize = 10,
	TextColor3 = C.Dim,
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "blox strike   ·   RightShift",
}, header)

local closeButton = create("TextButton", {
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -18, 0.5, 0),
	Size = UDim2.fromOffset(28, 28),
	BackgroundColor3 = C.White,
	BackgroundTransparency = 0.2,
	AutoButtonColor = false,
	Text = "",
}, header)
corner(closeButton, 10)
stroke(closeButton, C.Stroke, 1, 0.5)
create("Frame", { Size = UDim2.fromOffset(10, 1.7), Position = UDim2.fromOffset(9, 13), Rotation = 45, BackgroundColor3 = C.Text, BorderSizePixel = 0 }, closeButton)
create("Frame", { Size = UDim2.fromOffset(10, 1.7), Position = UDim2.fromOffset(9, 13), Rotation = -45, BackgroundColor3 = C.Text, BorderSizePixel = 0 }, closeButton)

create("Frame", {
	Position = UDim2.fromOffset(18, 58),
	Size = UDim2.new(1, -36, 0, 1),
	BackgroundColor3 = C.Stroke,
	BorderSizePixel = 0,
	BackgroundTransparency = 0.45,
}, main)

do
	local dragging, startPos, startInput = false, nil, nil
	bind(header.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			startPos = main.Position
			startInput = input.Position
		end
	end)
	bind(UserInputService.InputChanged, function(input)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - startInput
			main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
	bind(UserInputService.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
end

local sidebar = create("Frame", {
	Position = UDim2.fromOffset(18, 72),
	Size = UDim2.new(0, 146, 1, -90),
	BackgroundColor3 = C.Panel,
	BackgroundTransparency = 0.25,
	BorderSizePixel = 0,
}, main)
corner(sidebar, 14)
create("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }, sidebar)
create("UIPadding", { PaddingTop = UDim.new(0, 9), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, sidebar)

local content = create("Frame", {
	Position = UDim2.fromOffset(178, 72),
	Size = UDim2.new(1, -196, 1, -90),
	BackgroundTransparency = 1,
	ClipsDescendants = true,
}, main)

local Tabs, CurrentTab = {}, nil

local function switchTab(name)
	if CurrentTab == name then return end
	CurrentTab = name
	for tabName, data in pairs(Tabs) do
		local active = tabName == name
		tween(data.Button, 0.2, { BackgroundColor3 = active and C.White or C.Panel })
		tween(data.Bar, 0.2, { BackgroundTransparency = active and 0 or 1 })
		tween(data.Label, 0.2, { TextColor3 = active and C.AccentDeep or C.Dim })
		tween(data.Icon, 0.2, { TextColor3 = active and C.Accent or C.Dim, TextTransparency = active and 0 or 0.35 })
		if active then
			data.Group.Visible = true
			data.Group.Position = UDim2.fromOffset(14, 0)
			data.Group.GroupTransparency = 0.55
			tween(data.Group, 0.26, { GroupTransparency = 0, Position = UDim2.fromOffset(0, 0) })
		else
			data.Group.GroupTransparency = math.min(data.Group.GroupTransparency, 0.98)
			tween(data.Group, 0.16, { Position = UDim2.fromOffset(14, 0) })
			task.delay(0.17, function()
				if CurrentTab ~= tabName then data.Group.Visible = false end
			end)
		end
	end
end

local function addTab(name, iconText)
	local btn = create("TextButton", {
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundColor3 = C.Panel,
		BackgroundTransparency = 0.25,
		AutoButtonColor = false,
		Text = "",
	}, sidebar)
	btn.LayoutOrder = #sidebar:GetChildren()
	corner(btn, 11)

	local bar = create("Frame", {
		Size = UDim2.new(0, 3, 1, -18),
		Position = UDim2.fromOffset(0, 9),
		BackgroundColor3 = C.Accent,
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
	}, btn)
	corner(bar, 2)

	local icon = create("TextLabel", {
		Position = UDim2.fromOffset(13, 0),
		Size = UDim2.fromOffset(14, 38),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = C.Dim,
		TextTransparency = 0.35,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = iconText,
	}, btn)

	local label = create("TextLabel", {
		Position = UDim2.fromOffset(33, 0),
		Size = UDim2.new(1, -39, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		TextColor3 = C.Dim,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = name,
	}, btn)

	local group = create("CanvasGroup", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		GroupTransparency = 0,
		Visible = false,
	}, content)

	local scroll = create("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = C.Accent,
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, group)
	create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, scroll)
	create("UIPadding", { PaddingRight = UDim.new(0, 12), PaddingBottom = UDim.new(0, 16) }, scroll)

	btn.MouseButton1Click:Connect(function() switchTab(name) end)
	btn.MouseEnter:Connect(function()
		if CurrentTab ~= name then tween(btn, 0.18, { BackgroundColor3 = C.Hover, BackgroundTransparency = 0 }) end
	end)
	btn.MouseLeave:Connect(function()
		if CurrentTab ~= name then tween(btn, 0.18, { BackgroundColor3 = C.Panel, BackgroundTransparency = 0.25 }) end
	end)

	Tabs[name] = { Button = btn, Bar = bar, Label = label, Icon = icon, Group = group, Scroll = scroll }
	return scroll
end

local visualPage = addTab("Visuals", "◈")
local movePage = addTab("Movement", "⇅")
local espPage = addTab("ESP", "◉")
local skinPage = addTab("Skins", "✦")

---------------------------------------------------------------------------
-- Элементы UI
---------------------------------------------------------------------------
local function section(parent, text)
	return create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 10,
		TextColor3 = C.AccentDeep,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = string.upper(text),
	}, parent)
end

local function makeLabel(parent, text)
	return create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		TextSize = 10,
		TextColor3 = C.Dim,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = text,
	}, parent)
end

local function row(parent, height)
	local r = create("Frame", {
		Size = UDim2.new(1, 0, 0, height or 38),
		BackgroundColor3 = C.Element,
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
	}, parent)
	corner(r, 12)
	stroke(r, C.Stroke, 1, 0.6)
	return r
end

local function makeToggle(parent, text, default, callback)
	local r = row(parent, 38)
	create("TextLabel", {
		Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(1, -70, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		TextColor3 = C.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = text,
	}, r)
	local pill = create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -13, 0.5, 0),
		Size = UDim2.fromOffset(38, 20),
		BackgroundColor3 = default and C.Accent or C.Off,
		BorderSizePixel = 0,
	}, r)
	corner(pill, 10)
	local knob = create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = default and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
		Size = UDim2.fromOffset(16, 16),
		BackgroundColor3 = C.White,
		BorderSizePixel = 0,
	}, pill)
	corner(knob, 8)

	local state = default
	local function paint()
		tween(pill, 0.2, { BackgroundColor3 = state and C.Accent or C.Off })
		tween(knob, 0.2, {
			Position = state and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
		})
	end

	local clickable = create("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "" }, r)
	clickable.MouseButton1Click:Connect(function()
		state = not state
		paint()
		callback(state)
	end)
	return { Set = function(v) state = v paint() callback(v) end, Get = function() return state end }
end

local function makeSlider(parent, text, min, max, default, suffix, callback)
	local r = row(parent, 50)
	create("TextLabel", {
		Position = UDim2.fromOffset(14, 8),
		Size = UDim2.new(1, -72, 0, 16),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		TextColor3 = C.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = text,
	}, r)
	local valueLabel = create("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -13, 8, 0),
		Size = UDim2.fromOffset(62, 16),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = C.AccentDeep,
		TextXAlignment = Enum.TextXAlignment.Right,
		Text = tostring(default) .. (suffix or ""),
	}, r)

	local track = create("Frame", {
		Position = UDim2.fromOffset(14, 36),
		Size = UDim2.new(1, -28, 0, 5),
		BackgroundColor3 = C.Off,
		BorderSizePixel = 0,
	}, r)
	corner(track, 3)
	local fill = create("Frame", {
		Size = UDim2.fromScale((default - min) / (max - min), 1),
		BackgroundColor3 = C.Accent,
		BorderSizePixel = 0,
	}, track)
	corner(fill, 3)
	local knob = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new((default - min) / (max - min), 0, 0.5, 0),
		Size = UDim2.fromOffset(12, 12),
		BackgroundColor3 = C.White,
		BorderSizePixel = 0,
	}, track)
	corner(knob, 6)
	stroke(knob, C.Accent, 1.5, 0.1)

	local value = default
	local function set(v)
		if type(v) ~= "number" then v = value end
		v = math.clamp(math.floor(v + 0.5), min, max)
		value = v
		local alpha = (v - min) / (max - min)
		fill.Size = UDim2.fromScale(alpha, 1)
		knob.Position = UDim2.new(alpha, 0, 0.5, 0)
		valueLabel.Text = tostring(v) .. (suffix or "")
		callback(v)
	end

	local dragging = false
	local function update(input)
		local pos = (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
		set(min + (max - min) * math.clamp(pos, 0, 1))
	end
	bind(track.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			update(input)
		end
	end)
	bind(UserInputService.InputChanged, function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			update(input)
		end
	end)
	bind(UserInputService.InputEnded, function() dragging = false end)

	return { Set = function(v) set(v) end, Get = function() return value end }
end

local openPopups = {}
local function makeDropdown(parent, text, options, default, callback)
	local title = tostring(text or "")
	local r = row(parent, 38)
	local label = create("TextLabel", {
		Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(1, -42, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		TextColor3 = C.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = title,
	}, r)
	local chev = create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(10, 6),
		BackgroundTransparency = 1,
	}, r)
	create("Frame", { Size = UDim2.fromOffset(6, 1.6), Position = UDim2.fromOffset(0, 2), Rotation = 40, BackgroundColor3 = C.AccentDeep, BorderSizePixel = 0 }, chev)
	create("Frame", { Size = UDim2.fromOffset(6, 1.6), Position = UDim2.fromOffset(5, 2), Rotation = -40, BackgroundColor3 = C.AccentDeep, BorderSizePixel = 0 }, chev)

	local clickable = create("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "" }, r)
	local value = default
	local popup, open = nil, false
	local ROW_H, MAX_H = 29, 212

	local function close()
		if not open then return end
		open = false
		for i, p in ipairs(openPopups) do
			if p == popup then table.remove(openPopups, i) break end
		end
		local p = popup
		popup = nil
		pcall(function() p:Destroy() end)
	end

	clickable.MouseButton1Click:Connect(function()
		if open then close() return end
		for _, p in ipairs(table.clone(openPopups)) do pcall(function() p:Destroy() end) end
		table.clear(openPopups)
		open = true
		local pos = r.AbsolutePosition - main.AbsolutePosition
		local width = math.max(160, r.AbsoluteSize.X)
		local x = math.clamp(pos.X, 8, math.max(8, main.AbsoluteSize.X - width - 8))
		local listH = math.min(#options * ROW_H + 12, MAX_H)
		local y = pos.Y + r.AbsoluteSize.Y + 5
		if y + listH > main.AbsoluteSize.Y - 8 then
			y = math.max(8, pos.Y - listH - 5)
		end
		popup = create("Frame", {
			Position = UDim2.fromOffset(x, y),
			Size = UDim2.fromOffset(width, listH),
			BackgroundColor3 = C.White,
			ZIndex = 60,
		}, main)
		corner(popup, 12)
		stroke(popup, C.Stroke, 1, 0.15)
		table.insert(openPopups, popup)

		local list = create("ScrollingFrame", {
			Position = UDim2.fromOffset(6, 6),
			Size = UDim2.new(1, -12, 1, -12),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = C.Accent,
			ZIndex = 61,
		}, popup)
		create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, list)

		for _, option in ipairs(options) do
			local optText = tostring(option)
			local b = create("TextButton", {
				Size = UDim2.new(1, 0, 0, 27),
				BackgroundColor3 = option == value and C.Panel or C.Element,
				AutoButtonColor = false,
				Font = Enum.Font.Gotham,
				TextSize = 11,
				TextColor3 = option == value and C.AccentDeep or C.Text,
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = "   " .. optText,
				ZIndex = 61,
			}, list)
			corner(b, 7)
			b.MouseEnter:Connect(function() tween(b, 0.12, { BackgroundColor3 = C.Hover }) end)
			b.MouseLeave:Connect(function()
				tween(b, 0.12, { BackgroundColor3 = option == value and C.Panel or C.Element })
			end)
			b.MouseButton1Click:Connect(function()
				value = option
				label.Text = optText
				callback(option)
				close()
			end)
		end
	end)

	return {
		Set = function(v)
			if type(v) == "table" then v = v[1] end
			if type(v) == "string" and v ~= "" then
				value = v
				label.Text = v
			else
				value = nil
				label.Text = title
			end
		end,
		Reset = function()
			value = nil
			label.Text = title
		end,
		Get = function() return value end,
		Title = function() return title end,
		Close = close,
		Row = r,
	}
end

local function makeButton(parent, text, callback)
	local r = row(parent, 34)
	r.BackgroundColor3 = C.Accent
	r.BackgroundTransparency = 0.08
	local l = create("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = C.White,
		Text = text,
	}, r)
	local clickable = create("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "" }, r)
	clickable.MouseEnter:Connect(function() tween(r, 0.15, { BackgroundTransparency = 0 }) end)
	clickable.MouseLeave:Connect(function() tween(r, 0.15, { BackgroundTransparency = 0.08 }) end)
	clickable.MouseButton1Click:Connect(function()
		tween(l, 0.1, { TextTransparency = 0.4 })
		task.delay(0.1, function() tween(l, 0.15, { TextTransparency = 0 }) end)
		callback()
	end)
	return r
end

local function makeSearch(parent, placeholder, onChanged)
	local r = row(parent, 32)
	local box = create("TextBox", {
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -24, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextColor3 = C.Text,
		PlaceholderColor3 = C.Dim,
		PlaceholderText = placeholder,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "",
		ClearTextOnFocus = false,
	}, r)
	box:GetPropertyChangedSignal("Text"):Connect(function()
		onChanged(box.Text)
	end)
	return box
end

local function makeColor(parent, text, default, callback)
	local r = row(parent, 38)
	create("TextLabel", {
		Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(1, -70, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		TextColor3 = C.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = text,
	}, r)
	local swatch = create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -13, 0.5, 0),
		Size = UDim2.fromOffset(40, 20),
		BackgroundColor3 = default,
		BorderSizePixel = 0,
	}, r)
	corner(swatch, 6)
	stroke(swatch, C.Stroke, 1, 0.4)

	local clickable = create("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "" }, r)
	local value = default
	local popup, open = nil, false
	local rSlider, gSlider, bSlider

	local function close()
		if not open then return end
		open = false
		for i, p in ipairs(openPopups) do
			if p == popup then table.remove(openPopups, i) break end
		end
		local p = popup
		popup = nil
		rSlider, gSlider, bSlider = nil, nil, nil
		pcall(function() p:Destroy() end)
	end

	local function commit(col)
		value = col
		swatch.BackgroundColor3 = col
		callback(col)
	end

	clickable.MouseButton1Click:Connect(function()
		if open then close() return end
		for _, p in ipairs(table.clone(openPopups)) do pcall(function() p:Destroy() end) end
		table.clear(openPopups)
		open = true
		local pos = r.AbsolutePosition - main.AbsolutePosition
		local width = 210
		local x = math.clamp(pos.X, 8, math.max(8, main.AbsoluteSize.X - width - 8))
		local popupH = 178
		local y = pos.Y + r.AbsoluteSize.Y + 5
		if y + popupH > main.AbsoluteSize.Y - 8 then
			y = math.max(8, pos.Y - popupH - 5)
		end
		popup = create("Frame", {
			Position = UDim2.fromOffset(x, y),
			Size = UDim2.fromOffset(width, popupH),
			BackgroundColor3 = C.White,
			ZIndex = 60,
		}, main)
		corner(popup, 12)
		stroke(popup, C.Stroke, 1, 0.15)
		table.insert(openPopups, popup)
		create("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, popup)
		create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, popup)

		local function chan(letter, index)
			local current = ({ value.R, value.G, value.B })[index] * 255
			return makeSlider(popup, letter, 0, 255, math.floor(current + 0.5), "", function(v)
				local c = Color3.new(value.R, value.G, value.B)
				if index == 1 then c = Color3.fromRGB(v, math.floor(value.G * 255), math.floor(value.B * 255))
				elseif index == 2 then c = Color3.fromRGB(math.floor(value.R * 255), v, math.floor(value.B * 255))
				else c = Color3.fromRGB(math.floor(value.R * 255), math.floor(value.G * 255), v) end
				commit(c)
			end)
		end
		rSlider = chan("R", 1)
		gSlider = chan("G", 2)
		bSlider = chan("B", 3)
	end)

	return {
		Get = function() return value end,
		Set = function(col)
			if typeof(col) ~= "Color3" then return end
			value = col
			swatch.BackgroundColor3 = col
			if rSlider then pcall(function() rSlider:Set(col.R * 255) end) end
			if gSlider then pcall(function() gSlider:Set(col.G * 255) end) end
			if bSlider then pcall(function() bSlider:Set(col.B * 255) end) end
			callback(col)
		end,
	}
end

---------------------------------------------------------------------------
-- Под-вкладки (для разбиения Skins)
---------------------------------------------------------------------------
local function makeSubTabs(host, names)
	local bar = create("Frame", {
		Size = UDim2.new(1, -12, 0, 30),
		BackgroundColor3 = C.Panel,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
	}, host)
	corner(bar, 10)
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	}, bar)
	create("UIPadding", { PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) }, bar)

	local hostArea = create("Frame", {
		Position = UDim2.fromOffset(0, 36),
		Size = UDim2.new(1, 0, 1, -36),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
	}, host)

	local pages, current = {}, nil

	local function show(name)
		if current == name then return end
		current = name
		for n, d in pairs(pages) do
			local active = n == name
			tween(d.Button, 0.18, { BackgroundColor3 = active and C.White or C.Panel })
			tween(d.Label, 0.18, { TextColor3 = active and C.AccentDeep or C.Dim })
			if active then
				d.Page.Visible = true
				d.Page.GroupTransparency = 0.5
				tween(d.Page, 0.2, { GroupTransparency = 0 })
			else
				d.Page.Visible = false
			end
		end
	end

	for i, name in ipairs(names) do
		local b = create("TextButton", {
			Size = UDim2.new(1 / #names, -6, 1, -8),
			BackgroundColor3 = C.Panel,
			AutoButtonColor = false,
			Text = "",
		}, bar)
		b.LayoutOrder = i
		corner(b, 7)
		local l = create("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamMedium,
			TextSize = 11,
			TextColor3 = C.Dim,
			Text = name,
		}, b)
		local page = create("CanvasGroup", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			GroupTransparency = 0,
			Visible = false,
		}, hostArea)
		local scroll = create("ScrollingFrame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = C.Accent,
			ScrollingDirection = Enum.ScrollingDirection.Y,
		}, page)
		create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, scroll)
		create("UIPadding", { PaddingRight = UDim.new(0, 12), PaddingBottom = UDim.new(0, 16) }, scroll)

		b.MouseButton1Click:Connect(function() show(name) end)
		pages[name] = { Button = b, Label = l, Page = page, Scroll = scroll }
	end

	show(names[1])
	return pages, show
end

---------------------------------------------------------------------------
-- Вкладка Visuals (FOV) — не мешает оптике
---------------------------------------------------------------------------
local Fov = { Enabled = false, Value = 90, Original = nil }
local fovToggle, fovSlider
local scopeRef = nil

local function isScoped()
	local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
	if not playerGui then return false end
	if scopeRef and scopeRef.Parent then
		return scopeRef.Visible == true
	end
	local ok, scope = pcall(function() return playerGui.MainGui.Gameplay.Middle.SniperScope end)
	if ok and scope then
		scopeRef = scope
		return scope.Visible == true
	end
	return false
end

do
	section(visualPage, "Камера")
	fovToggle = makeToggle(visualPage, "Включить FOV", false, function(v)
		Fov.Enabled = v
		local camera = workspace.CurrentCamera
		if v then
			if camera and not isScoped() then Fov.Original = camera.FieldOfView end
		elseif camera and Fov.Original then
			camera.FieldOfView = Fov.Original
		end
		Persist.queue()
	end)
	fovSlider = makeSlider(visualPage, "Значение FOV", 60, 130, 90, "", function(v)
		Fov.Value = v
		Persist.queue()
	end)
	makeLabel(visualPage, "При взгляде в оптику FOV отдаётся игре — зум AWP и снайперок работает как обычно.")

	bind(RunService.RenderStepped, function()
		local camera = workspace.CurrentCamera
		if not (Fov.Enabled and camera) then return end
		if isScoped() then return end
		if Fov.Original == nil then Fov.Original = camera.FieldOfView end
		if math.abs(camera.FieldOfView - Fov.Value) > 0.05 then
			camera.FieldOfView = Fov.Value
		end
	end)
end

---------------------------------------------------------------------------
-- Вкладка Movement
---------------------------------------------------------------------------
local Bhop = { Enabled = false, Mode = "Auto", Delay = 0, MovingOnly = false, CrouchJump = false, PauseWithMenu = false, Hooked = false }
local BhopState = { Module = nil, Buttons = nil, Original = nil, Wrapper = nil, LastDown = false, GroundSince = nil }
local bhopToggle, bhopModeDropdown

local function crouchJump()
	if not VirtualInputManager then return end
	pcall(function()
		VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game)
		task.delay(0.25, function()
			pcall(function() VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game) end)
		end)
	end)
end

local function bhopAllowed(character)
	if not Bhop.Enabled then return false end
	if GuiService.MenuIsOpen then return false end
	if UserInputService:GetFocusedTextBox() then return false end
	if LocalPlayer:GetAttribute("IsPlayerChatting") == true then return false end
	if Bhop.PauseWithMenu and gui.Toggled then return false end
	if not character or character.IsDestroyed then return false end
	if character.Character ~= LocalPlayer.Character then return false end
	return true
end

local function installBhop()
	if BhopState.Wrapper then return true end
	local ok = pcall(function()
		local classes = ReplicatedStorage:FindFirstChild("Classes")
		local movement = ReplicatedStorage:FindFirstChild("MovementV2")
		assert(classes and movement, "modules missing")
		local module = require(classes:FindFirstChild("Character"))
		local buttons = require(movement:FindFirstChild("Buttons"))
		assert(type(module.SampleInput) == "function", "SampleInput missing")
		BhopState.Module, BhopState.Buttons = module, buttons
		BhopState.Original = module.SampleInput
		BhopState.Wrapper = function(character, context, ...)
			local input = BhopState.Original(character, context, ...)
			if not input or type(input) ~= "table" then return input end
			local success, result = pcall(function()
				if not bhopAllowed(character) then
					BhopState.GroundSince = nil
					BhopState.LastDown = false
					return input
				end
				local state = context and context.State
				if not state then return input end
				local now = context.ScheduledServerTime or os.clock()
				if state.OnGround then
					BhopState.GroundSince = BhopState.GroundSince or now
				else
					BhopState.GroundSince = nil
				end
				local wants = Bhop.Mode == "Auto" or character.JumpInputDown == true
					or BhopState.Buttons.has(input.Buttons, BhopState.Buttons.Jump)
				if not wants or (Bhop.MovingOnly and input.Move.Magnitude < 0.05) then
					BhopState.LastDown = BhopState.Buttons.has(input.Buttons, BhopState.Buttons.Jump)
					return input
				end
				local jump = state.OnGround == true and not BhopState.LastDown
					and BhopState.GroundSince ~= nil
					and (now - BhopState.GroundSince) >= (Bhop.Delay / 1000)
				local modified = table.clone(input)
				modified.Buttons = BhopState.Buttons.with(input.Buttons, BhopState.Buttons.Jump, jump)
				BhopState.LastDown = jump
				if jump and Bhop.CrouchJump then crouchJump() end
				return modified
			end)
			if success then return result end
			return input
		end
		module.SampleInput = BhopState.Wrapper
	end)
	return ok
end

task.spawn(function()
	for _ = 1, 180 do
		if installBhop() then
			Bhop.Hooked = true
			return
		end
		task.wait(0.5)
	end
end)

bind(RunService.Heartbeat, function()
	if not Bhop.Enabled or Bhop.Hooked then return end
	if GuiService.MenuIsOpen or UserInputService:GetFocusedTextBox() then return end
	if Bhop.PauseWithMenu and gui.Toggled then return end
	local character = LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end
	if humanoid.FloorMaterial == Enum.Material.Air then return end
	if Bhop.MovingOnly and humanoid.MoveDirection.Magnitude < 0.05 then return end
	humanoid.Jump = true
	if VirtualInputManager then
		pcall(function()
			VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
			VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
			VirtualInputManager:SendMouseWheelEvent(0, 0, 1, false)
		end)
	end
	if Bhop.CrouchJump then crouchJump() end
end)

do
	section(movePage, "Auto BunnyHop")
	bhopToggle = makeToggle(movePage, "Включить Auto BunnyHop", false, function(v)
		Bhop.Enabled = v
		if v and not Bhop.Hooked then
			notify("BHop", "Резервный режим — хук ещё не готов")
		end
		Persist.queue()
	end)
	bhopModeDropdown = makeDropdown(movePage, "Режим", { "Auto", "Hold" }, "Auto", function(v)
		Bhop.Mode = v
		Persist.queue()
	end)

	section(movePage, "Инфо")
	makeLabel(movePage, "Auto — прыгает сам при касании земли.\nHold — только пока зажата кнопка прыжка.\nJump на колесо и стрейфы A/D держат скорость.")
end

---------------------------------------------------------------------------
-- ESP: конфиг
---------------------------------------------------------------------------
local ESP = {
	Enabled = false,
	TeamCheck = true,
	Box = {
		Enabled = false, Type = "2D",
		ColorA = Color3.fromRGB(255, 255, 255), ColorB = Color3.fromRGB(0, 200, 255),
		FillGradient = false,
		FillA = Color3.fromRGB(255, 50, 50), FillB = Color3.fromRGB(50, 50, 255),
		FillRotation = false, RotationSpeed = 2,
	},
	Health = { Enabled = false, Top = Color3.fromRGB(0, 255, 0), Bottom = Color3.fromRGB(255, 0, 0) },
	HealthText = { Enabled = false, Color = Color3.new(1, 1, 1), Size = 12 },
	Name = { Enabled = false, Color = Color3.new(1, 1, 1), Size = 13 },
	Distance = { Enabled = false, Color = Color3.new(1, 1, 1), Size = 13 },
	Weapon = { Enabled = false, Color = Color3.new(1, 1, 1), Size = 13 },
	Tracer = { Enabled = false, ColorA = Color3.new(1, 1, 1), ColorB = Color3.fromRGB(255, 0, 128), From = "Bottom" },
	Skeleton = { Enabled = false, ColorA = Color3.new(1, 1, 1), ColorB = Color3.fromRGB(0, 255, 255), Thickness = 2 },
	Circle = { Enabled = false, Color = Color3.fromRGB(255, 200, 0) },
}

local espObjects = {}
local espCharacters = {}
local rotAngle = 0

local abs, huge, floor, clamp, sin, cos, pi, pi2 = math.abs, math.huge, math.floor, math.clamp, math.sin, math.cos, math.pi, math.pi * 2
local lerpColor = function(a, b, t)
	return Color3.new(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t)
end

local SKELETON_R6 = { { "Head", "Torso" }, { "Torso", "Left Arm" }, { "Torso", "Right Arm" }, { "Torso", "Left Leg" }, { "Torso", "Right Leg" } }
local SKELETON_R15 = {
	{ "Head", "UpperTorso" }, { "UpperTorso", "LowerTorso" },
	{ "UpperTorso", "LeftUpperArm" }, { "LeftUpperArm", "LeftLowerArm" }, { "LeftLowerArm", "LeftHand" },
	{ "UpperTorso", "RightUpperArm" }, { "RightUpperArm", "RightLowerArm" }, { "RightLowerArm", "RightHand" },
	{ "LowerTorso", "LeftUpperLeg" }, { "LeftUpperLeg", "LeftLowerLeg" }, { "LeftLowerLeg", "LeftFoot" },
	{ "LowerTorso", "RightUpperLeg" }, { "RightUpperLeg", "RightLowerLeg" }, { "RightLowerLeg", "RightFoot" },
}
local AABB_CORNER_SIGNS = { { 0, 0, 0 }, { 1, 0, 0 }, { 0, 1, 0 }, { 1, 1, 0 }, { 0, 0, 1 }, { 1, 0, 1 }, { 0, 1, 1 }, { 1, 1, 1 } }
local BOX_3D_EDGES = { { 1, 2 }, { 2, 4 }, { 4, 3 }, { 3, 1 }, { 5, 6 }, { 6, 8 }, { 8, 7 }, { 7, 5 }, { 1, 5 }, { 2, 6 }, { 3, 7 }, { 4, 8 } }

local BASE_DIST, BASE_W, BASE_H = 20, 86, 155
local MAX_FILL_LINES = 400
local MAX_HP_SEGMENTS = 12
local GRAD_STEPS = 4

local partHalfExtentCache = setmetatable({}, { __mode = "k" })

local function get_part_half_extent(part)
	local cached = partHalfExtentCache[part]
	if not cached then
		local s = part.Size
		cached = { hx = s.X * 0.5, hy = s.Y * 0.5, hz = s.Z * 0.5 }
		partHalfExtentCache[part] = cached
	end
	return cached.hx, cached.hy, cached.hz
end

local function compute_world_aabb(parts)
	local x0, y0, z0 = huge, huge, huge
	local x1, y1, z1 = -huge, -huge, -huge
	for i = 1, #parts do
		local p = parts[i]
		local hx, hy, hz = get_part_half_extent(p)
		local px, py, pz, r00, r01, r02, r10, r11, r12, r20, r21, r22 = p.CFrame:GetComponents()
		local ex = abs(r00) * hx + abs(r01) * hy + abs(r02) * hz
		local ey = abs(r10) * hx + abs(r11) * hy + abs(r12) * hz
		local ez = abs(r20) * hx + abs(r21) * hy + abs(r22) * hz
		if px - ex < x0 then x0 = px - ex end
		if py - ey < y0 then y0 = py - ey end
		if pz - ez < z0 then z0 = pz - ez end
		if px + ex > x1 then x1 = px + ex end
		if py + ey > y1 then y1 = py + ey end
		if pz + ez > z1 then z1 = pz + ez end
	end
	if x0 == huge then return nil end
	return x0, y0, z0, x1, y1, z1
end

local function project_fixed_box(x0, y0, z0, x1, y1, z1)
	local camera = workspace.CurrentCamera
	if not camera then return nil, nil, false end
	local cx, cy, cz = (x0 + x1) * 0.5, (y0 + y1) * 0.5, (z0 + z1) * 0.5
	local sp, vis = camera:WorldToViewportPoint(Vector3.new(cx, cy, cz))
	if not vis and sp.Z <= 0 then return nil, nil, false end
	local depth = sp.Z
	if depth <= 0 then depth = 0.1 end
	local scale = BASE_DIST / depth
	local w = BASE_W * scale
	local h = BASE_H * scale
	local sx, sy = sp.X, sp.Y
	return Vector2.new(sx - w * 0.5, sy - h * 0.5), Vector2.new(sx + w * 0.5, sy + h * 0.5), true
end

local function project_aabb_corners_3d(x0, y0, z0, x1, y1, z1)
	local camera = workspace.CurrentCamera
	if not camera then return nil, false end
	local screen, on = {}, false
	for i = 1, 8 do
		local s = AABB_CORNER_SIGNS[i]
		local wx = (s[1] == 0) and x0 or x1
		local wy = (s[2] == 0) and y0 or y1
		local wz = (s[3] == 0) and z0 or z1
		local pos, vis = camera:WorldToViewportPoint(Vector3.new(wx, wy, wz))
		screen[i] = Vector2.new(pos.X, pos.Y)
		if vis then on = true end
	end
	return screen, on
end

local function ensure_character_parts(instance, data)
	if data.partlist then return data.partlist end
	local list, index = {}, setmetatable({}, { __mode = "k" })
	local function add(p)
		if p:IsA("BasePart") and not index[p] then
			list[#list + 1] = p
			index[p] = #list
			local c = p:GetPropertyChangedSignal("Size"):Connect(function()
				partHalfExtentCache[p] = nil
			end)
			data.sizeConns = data.sizeConns or {}
			data.sizeConns[p] = c
		end
	end
	local function rem(p)
		local i = index[p]
		if not i then return end
		local last = #list
		local lp = list[last]
		list[i] = lp
		index[lp] = i
		list[last] = nil
		index[p] = nil
		if data.sizeConns and data.sizeConns[p] then
			data.sizeConns[p]:Disconnect()
			data.sizeConns[p] = nil
		end
	end
	if instance:IsA("Model") then
		for _, p in next, instance:GetDescendants() do add(p) end
		data.partConnAdd = instance.DescendantAdded:Connect(add)
		data.partConnRemove = instance.DescendantRemoving:Connect(rem)
	elseif instance:IsA("BasePart") then
		add(instance)
	end
	data.partlist = list
	return list
end

local function setupFillLines()
	local lines = {}
	for i = 1, MAX_FILL_LINES do
		local l = Drawing.new("Line")
		l.Thickness = 4
		l.Transparency = 0.3
		l.Visible = false
		lines[i] = l
	end
	return lines
end

local function drawFillGradient360(fillLines, x, y, w, h, colorA, colorB, angle)
	local dx, dy = cos(angle), sin(angle)
	local cx, cy = x + w * 0.5, y + h * 0.5
	local maxDot = math.max((abs(dx) * w + abs(dy) * h) * 0.5, 1)
	local targetRows = clamp(floor(h * 0.8), 15, MAX_FILL_LINES)
	local rowH = h / targetRows
	for i = 1, targetRows do
		local py = y + (i - 0.5) * rowH
		local dotL = ((x - cx) * dx + (py - cy) * dy) / maxDot
		local dotR = ((x + w - cx) * dx + (py - cy) * dy) / maxDot
		local tL = clamp(dotL * 0.5 + 0.5, 0, 1)
		local tR = clamp(dotR * 0.5 + 0.5, 0, 1)
		local line = fillLines[i]
		line.Color = lerpColor(colorA, colorB, (tL + tR) * 0.5)
		line.Thickness = clamp(rowH + 1.5, 2, 8)
		line.From = Vector2.new(x + 1, py)
		line.To = Vector2.new(x + w - 1, py)
		line.Visible = true
	end
	for i = targetRows + 1, #fillLines do fillLines[i].Visible = false end
end

local function drawBoxOutlineGradient(box, x, y, w, h, colorA, colorB, rotOff)
	local idx = 0
	local sides = { { x, y, x + w, y }, { x + w, y, x + w, y + h }, { x + w, y + h, x, y + h }, { x, y + h, x, y } }
	for si = 1, 4 do
		local s = sides[si]
		for step = 0, GRAD_STEPS - 1 do
			idx = idx + 1
			local tA, tB = step / GRAD_STEPS, (step + 1) / GRAD_STEPS
			local tMid = (((si - 1) / 4) + (tA / 4) + rotOff) % 1
			local line = box.grad_lines[idx]
			if line then
				line.From = Vector2.new(s[1] + (s[3] - s[1]) * tA, s[2] + (s[4] - s[2]) * tA)
				line.To = Vector2.new(s[1] + (s[3] - s[1]) * tB, s[2] + (s[4] - s[2]) * tB)
				line.Color = lerpColor(colorA, colorB, tMid)
				line.Visible = true
			end
		end
	end
	for i = idx + 1, #box.grad_lines do box.grad_lines[i].Visible = false end
end

local function hideBox(box)
	box.outline.Visible = false
	box.fill.Visible = false
	for _, l in ipairs(box.grad_lines) do l.Visible = false end
	for _, l in ipairs(box.fill_grad_lines) do l.Visible = false end
	for _, l in ipairs(box.corner_fill) do l.Visible = false end
	for _, l in ipairs(box.corner_outline) do l.Visible = false end
	for _, l in ipairs(box.box_3d_lines) do l.Visible = false end
end

local function mkLine(th)
	local l = Drawing.new("Line")
	l.Thickness = th
	l.Transparency = 1
	l.Visible = false
	return l
end

local function mkSq(th, filled)
	local s = Drawing.new("Square")
	s.Thickness = th
	s.Filled = filled
	s.Transparency = 1
	s.Visible = false
	return s
end

local function addESPObjects(instance)
	if espObjects[instance] then return end
	local data = {}

	data.box = {
		outline = mkSq(3, false), fill = mkSq(1, false),
		grad_lines = {}, fill_grad_lines = setupFillLines(),
		corner_fill = {}, corner_outline = {}, box_3d_lines = {},
	}
	for i = 1, 16 do data.box.grad_lines[i] = mkLine(1) end
	for i = 1, 8 do
		data.box.corner_fill[i] = mkLine(1)
		data.box.corner_outline[i] = mkLine(3)
	end
	for i = 1, 12 do data.box.box_3d_lines[i] = mkLine(2) end

	data.healthbar = { background = mkSq(1, true), segments = {} }
	data.healthbar.background.Color = Color3.new(0, 0, 0)
	data.healthbar.background.Transparency = 0.5
	for i = 1, MAX_HP_SEGMENTS do data.healthbar.segments[i] = mkLine(3) end

	data.healthtext = Drawing.new("Text")
	data.healthtext.Center = false
	data.healthtext.Outline = true
	data.healthtext.Font = 1
	data.healthtext.Transparency = 1
	data.healthtext.Visible = false

	data.name = Drawing.new("Text")
	data.name.Center = true
	data.name.Outline = true
	data.name.Font = 1
	data.name.Transparency = 1
	data.name.Visible = false

	data.distance = Drawing.new("Text")
	data.distance.Center = true
	data.distance.Outline = true
	data.distance.Font = 1
	data.distance.Transparency = 1
	data.distance.Visible = false

	data.tracer = { outline = mkLine(3), fill = mkLine(1) }

	local isR15 = instance:FindFirstChild("UpperTorso") ~= nil
	local bones = isR15 and SKELETON_R15 or SKELETON_R6
	data.skeleton = { lines = {}, bone_parts = {}, screenCache = {} }
	for i = 1, #bones do
		data.skeleton.lines[i] = mkLine(2)
		data.skeleton.bone_parts[i] = { instance:FindFirstChild(bones[i][1]), instance:FindFirstChild(bones[i][2]) }
	end

	data.weapon = Drawing.new("Text")
	data.weapon.Center = true
	data.weapon.Outline = true
	data.weapon.Font = 1
	data.weapon.Transparency = 1
	data.weapon.Visible = false

	data.circle = { lines = {}, trail = {}, glow = {}, alpha = 0, up = true, history = {}, segments = 32 }
	for i = 1, 32 do data.circle.lines[i] = mkLine(1.5) end
	for i = 1, 25 do
		data.circle.trail[i] = mkLine(2.5)
		data.circle.trail[i].Transparency = 0.4
		data.circle.glow[i] = mkLine(5)
		data.circle.glow[i].Transparency = 0.15
	end

	espObjects[instance] = data
end

local function removeESPObjects(instance)
	local data = espObjects[instance]
	if not data then return end
	espObjects[instance] = nil
	pcall(function()
		data.box.outline:Remove()
		data.box.fill:Remove()
		for _, l in ipairs(data.box.grad_lines) do l:Remove() end
		for _, l in ipairs(data.box.fill_grad_lines) do l:Remove() end
		for _, l in ipairs(data.box.corner_fill) do l:Remove() end
		for _, l in ipairs(data.box.corner_outline) do l:Remove() end
		for _, l in ipairs(data.box.box_3d_lines) do l:Remove() end
		data.healthbar.background:Remove()
		for _, s in ipairs(data.healthbar.segments) do s:Remove() end
		data.healthtext:Remove()
		data.name:Remove()
		data.distance:Remove()
		data.tracer.outline:Remove()
		data.tracer.fill:Remove()
		for _, l in ipairs(data.skeleton.lines) do l:Remove() end
		data.weapon:Remove()
		for _, l in ipairs(data.circle.lines) do l:Remove() end
		for _, l in ipairs(data.circle.trail) do l:Remove() end
		for _, l in ipairs(data.circle.glow) do l:Remove() end
		if data.partConnAdd then data.partConnAdd:Disconnect() end
		if data.partConnRemove then data.partConnRemove:Disconnect() end
		if data.sizeConns then
			for _, c in next, data.sizeConns do c:Disconnect() end
		end
	end)
end

local function hideAllESP(data)
	hideBox(data.box)
	data.healthbar.background.Visible = false
	for _, s in ipairs(data.healthbar.segments) do s.Visible = false end
	data.healthtext.Visible = false
	data.name.Visible = false
	data.distance.Visible = false
	data.tracer.outline.Visible = false
	data.tracer.fill.Visible = false
	for _, l in ipairs(data.skeleton.lines) do l.Visible = false end
	data.weapon.Visible = false
	for _, l in ipairs(data.circle.lines) do l.Visible = false end
	for _, l in ipairs(data.circle.trail) do l.Visible = false end
	for _, l in ipairs(data.circle.glow) do l.Visible = false end
end

local function hasVestDetails(character)
	local armor = character and character:FindFirstChild("CharacterArmor")
	return armor ~= nil and armor:FindFirstChild("VestDetails") ~= nil
end

local function isAlly(character)
	local myChar = LocalPlayer.Character
	if not myChar or not character then return false end
	return hasVestDetails(myChar) == hasVestDetails(character)
end

local weaponAttrCache, weaponNameCache = {}, {}
local function getWeaponName(player)
	if not player then return "None" end
	local attr = player:GetAttribute("CurrentEquipped")
	if attr ~= weaponAttrCache[player] then
		weaponAttrCache[player] = attr
		if attr then
			local ok, decoded = pcall(function() return HttpService:JSONDecode(attr) end)
			weaponNameCache[player] = (ok and decoded and decoded.Name) or "None"
		else
			weaponNameCache[player] = "None"
		end
	end
	return weaponNameCache[player] or "None"
end

local function cachedScreenPos(cache, part)
	local c = cache[part]
	if c then return c[1], c[2] end
	local camera = workspace.CurrentCamera
	if not camera then return Vector2.new(), false end
	local pos, vis = camera:WorldToViewportPoint(part.Position)
	local sp = Vector2.new(pos.X, pos.Y)
	cache[part] = { sp, vis }
	return sp, vis
end

---------------------------------------------------------------------------
-- ESP: отрисовка
---------------------------------------------------------------------------
bind(RunService.RenderStepped, function(dt)
	if ESP.Box.FillRotation then
		rotAngle = (rotAngle + dt * (ESP.Box.RotationSpeed or 2)) % pi2
	end
	local camera = workspace.CurrentCamera
	if not camera then return end
	local camPos = camera.CFrame.Position
	local viewport = camera.ViewportSize
	local rotOff = rotAngle / pi2

	for instance, data in next, espObjects do
		if not instance or not instance.Parent then
			removeESPObjects(instance)
			continue
		end
		if instance == LocalPlayer.Character or not ESP.Enabled then
			hideAllESP(data)
			continue
		end
		if instance:IsA("Model") and not instance.PrimaryPart then
			local head = instance:FindFirstChild("Head")
			if head then
				instance.PrimaryPart = head
			end
		end
		if ESP.TeamCheck and isAlly(instance) then
			hideAllESP(data)
			continue
		end
		local healthAttr = instance:GetAttribute("Health")
		local maxHealth = instance:GetAttribute("MaxHealth") or 100
		if instance:GetAttribute("Dead") == true or (healthAttr and healthAttr <= 0) then
			hideAllESP(data)
			continue
		end

		local wantBox = ESP.Box.Enabled and ESP.Box.Type ~= "Disabled"
		local wantHp = ESP.Health.Enabled
		local wantHpTxt = ESP.HealthText.Enabled
		local wantName = ESP.Name.Enabled
		local wantDist = ESP.Distance.Enabled
		local wantTracer = ESP.Tracer.Enabled
		local wantSkel = ESP.Skeleton.Enabled
		local wantWeapon = ESP.Weapon.Enabled
		local wantCircle = ESP.Circle.Enabled

		if not (wantBox or wantHp or wantHpTxt or wantName or wantDist or wantTracer or wantSkel or wantWeapon or wantCircle) then
			hideAllESP(data)
			continue
		end

		local parts = ensure_character_parts(instance, data)
		local min2, max2, onscreen
		local corners3d, on3d
		local x0, y0, z0, x1, y1, z1 = compute_world_aabb(parts)
		if x0 then
			min2, max2, onscreen = project_fixed_box(x0, y0, z0, x1, y1, z1)
			if wantBox and ESP.Box.Type == "3D" then
				corners3d, on3d = project_aabb_corners_3d(x0, y0, z0, x1, y1, z1)
			end
		end

		-- бокс
		if not (wantBox and onscreen and min2 and max2) then
			hideBox(data.box)
		else
			local x, y = min2.X, min2.Y
			local w, h = max2.X - min2.X, max2.Y - min2.Y
			local cA, cB = ESP.Box.ColorA, ESP.Box.ColorB
			local boxType = ESP.Box.Type
			if boxType == "2D" then
				if ESP.Box.FillGradient then
					drawFillGradient360(data.box.fill_grad_lines, x, y, w, h, ESP.Box.FillA, ESP.Box.FillB, rotAngle)
				else
					for _, l in ipairs(data.box.fill_grad_lines) do l.Visible = false end
				end
				drawBoxOutlineGradient(data.box, x, y, w, h, cA, cB, rotOff)
				data.box.outline.Visible = false
				data.box.fill.Visible = false
				for _, l in ipairs(data.box.corner_fill) do l.Visible = false end
				for _, l in ipairs(data.box.corner_outline) do l.Visible = false end
				for _, l in ipairs(data.box.box_3d_lines) do l.Visible = false end
			elseif boxType == "Corner" then
				for _, l in ipairs(data.box.grad_lines) do l.Visible = false end
				data.box.outline.Visible = false
				data.box.fill.Visible = false
				if ESP.Box.FillGradient then
					drawFillGradient360(data.box.fill_grad_lines, x, y, w, h, ESP.Box.FillA, ESP.Box.FillB, rotAngle)
				else
					for _, l in ipairs(data.box.fill_grad_lines) do l.Visible = false end
				end
				local len = math.min(w, h) * 0.25
				local corners = {
					{ Vector2.new(x, y), Vector2.new(x + len, y) },
					{ Vector2.new(x, y), Vector2.new(x, y + len) },
					{ Vector2.new(x + w - len, y), Vector2.new(x + w, y) },
					{ Vector2.new(x + w, y), Vector2.new(x + w, y + len) },
					{ Vector2.new(x, y + h), Vector2.new(x + len, y + h) },
					{ Vector2.new(x, y + h - len), Vector2.new(x, y + h) },
					{ Vector2.new(x + w - len, y + h), Vector2.new(x + w, y + h) },
					{ Vector2.new(x + w, y + h - len), Vector2.new(x + w, y + h) },
				}
				for i = 1, 8 do
					local t = (i - 1) / 8
					local col = lerpColor(cA, cB, t)
					data.box.corner_outline[i].From = corners[i][1]
					data.box.corner_outline[i].To = corners[i][2]
					data.box.corner_outline[i].Color = C.BgTop
					data.box.corner_outline[i].Visible = true
					data.box.corner_fill[i].From = corners[i][1]
					data.box.corner_fill[i].To = corners[i][2]
					data.box.corner_fill[i].Color = col
					data.box.corner_fill[i].Visible = true
				end
				for _, l in ipairs(data.box.box_3d_lines) do l.Visible = false end
			elseif boxType == "3D" then
				for _, l in ipairs(data.box.fill_grad_lines) do l.Visible = false end
				for _, l in ipairs(data.box.grad_lines) do l.Visible = false end
				data.box.outline.Visible = false
				data.box.fill.Visible = false
				for _, l in ipairs(data.box.corner_fill) do l.Visible = false end
				for _, l in ipairs(data.box.corner_outline) do l.Visible = false end
				if corners3d and #corners3d == 8 then
					for i = 1, 12 do
						local e = BOX_3D_EDGES[i]
						data.box.box_3d_lines[i].From = corners3d[e[1]]
						data.box.box_3d_lines[i].To = corners3d[e[2]]
						data.box.box_3d_lines[i].Color = lerpColor(cA, cB, (i - 1) / 12)
						data.box.box_3d_lines[i].Visible = on3d
					end
				else
					for _, l in ipairs(data.box.box_3d_lines) do l.Visible = false end
				end
			end
		end

		-- хп бар
		local bg = data.healthbar.background
		local segs = data.healthbar.segments
		if wantHp and onscreen and min2 and max2 and healthAttr then
			local x = min2.X - 6
			local y = min2.Y
			local w = 3
			local h = max2.Y - min2.Y
			local maxHp = maxHealth > 0 and maxHealth or 100
			local fraction = clamp(healthAttr / maxHp, 0, 1)
			bg.Position = Vector2.new(x - 1, y - 1)
			bg.Size = Vector2.new(w + 2, h + 2)
			bg.Visible = true
			local barHeight = h * fraction
			local startY = y + (h - barHeight)
			local active = clamp(floor(MAX_HP_SEGMENTS * fraction), 1, MAX_HP_SEGMENTS)
			local segH = barHeight / active
			for i = 1, MAX_HP_SEGMENTS do
				local segLine = segs[i]
				if i <= active then
					segLine.Color = lerpColor(ESP.Health.Bottom, ESP.Health.Top, (i - 0.5) / MAX_HP_SEGMENTS)
					local py1 = startY + (i - 1) * segH
					local py2 = startY + i * segH
					segLine.From = Vector2.new(x + w * 0.5, py1)
					segLine.To = Vector2.new(x + w * 0.5, py2)
					segLine.Thickness = w
					segLine.Visible = true
				else
					segLine.Visible = false
				end
			end
		else
			bg.Visible = false
			for _, s in ipairs(segs) do s.Visible = false end
		end

		-- хп текст
		if wantHpTxt and onscreen and min2 and max2 and healthAttr then
			local maxHp = maxHealth > 0 and maxHealth or 100
			data.healthtext.Text = tostring(floor(healthAttr + 0.5))
			data.healthtext.Size = ESP.HealthText.Size
			data.healthtext.Color = ESP.HealthText.Color
			data.healthtext.Position = Vector2.new(max2.X + 4, min2.Y + (max2.Y - min2.Y) * (1 - (healthAttr / maxHp)) - 4)
			data.healthtext.Visible = true
		else
			data.healthtext.Visible = false
		end

		-- ник
		if wantName and onscreen and min2 and max2 then
			data.name.Text = instance.Name
			data.name.Size = ESP.Name.Size
			data.name.Color = ESP.Name.Color
			data.name.Position = Vector2.new((min2.X + max2.X) * 0.5, min2.Y - 15)
			data.name.Visible = true
		else
			data.name.Visible = false
		end

		-- дистанция
		if wantDist and onscreen and min2 and max2 then
			local dist = 999
			if instance.PrimaryPart then
				dist = (camPos - instance.PrimaryPart.Position).Magnitude
			end
			data.distance.Text = tostring(floor(dist)) .. "m"
			data.distance.Size = ESP.Distance.Size
			data.distance.Color = ESP.Distance.Color
			data.distance.Position = Vector2.new((min2.X + max2.X) * 0.5, max2.Y + 2)
			data.distance.Visible = true
		else
			data.distance.Visible = false
		end

		-- оружие
		if wantWeapon and onscreen and min2 and max2 then
			if not data.player then data.player = Players:GetPlayerFromCharacter(instance) end
			local wn = data.player and getWeaponName(data.player) or "None"
			data.weapon.Text = "[" .. wn .. "]"
			data.weapon.Size = ESP.Weapon.Size
			data.weapon.Color = ESP.Weapon.Color
			data.weapon.Position = Vector2.new((min2.X + max2.X) * 0.5, max2.Y + 15)
			data.weapon.Visible = true
		else
			data.weapon.Visible = false
		end

		-- трассер
		if wantTracer and onscreen and min2 and max2 then
			local from
			if ESP.Tracer.From == "Mouse" then
				local ml = UserInputService:GetMouseLocation()
				from = Vector2.new(ml.X, ml.Y)
			elseif ESP.Tracer.From == "Top" then
				from = Vector2.new(viewport.X / 2, 0)
			elseif ESP.Tracer.From == "Center" then
				from = Vector2.new(viewport.X / 2, viewport.Y / 2)
			else
				from = Vector2.new(viewport.X / 2, viewport.Y)
			end
			local toPos = (min2 + max2) / 2
			local distT = 0
			if instance.PrimaryPart then
				distT = clamp((camPos - instance.PrimaryPart.Position).Magnitude / 200, 0, 1)
			end
			local col = lerpColor(ESP.Tracer.ColorA, ESP.Tracer.ColorB, distT)
			data.tracer.outline.From = from
			data.tracer.outline.To = toPos
			data.tracer.outline.Color = C.BgTop
			data.tracer.outline.Visible = true
			data.tracer.fill.From = from
			data.tracer.fill.To = toPos
			data.tracer.fill.Color = col
			data.tracer.fill.Visible = true
		else
			data.tracer.outline.Visible = false
			data.tracer.fill.Visible = false
		end

		-- скелет
		if wantSkel then
			local bp, lines, sc = data.skeleton.bone_parts, data.skeleton.lines, data.skeleton.screenCache
			for k in next, sc do sc[k] = nil end
			for i = 1, #bp do
				local pA, pB = bp[i][1], bp[i][2]
				local line = lines[i]
				if pA and pB and pA.Parent and pB.Parent then
					local posA, vA = cachedScreenPos(sc, pA)
					local posB, vB = cachedScreenPos(sc, pB)
					if vA or vB then
						line.From = posA
						line.To = posB
						line.Color = lerpColor(ESP.Skeleton.ColorA, ESP.Skeleton.ColorB, (i - 1) / #bp)
						line.Thickness = ESP.Skeleton.Thickness
						line.Visible = true
					else
						line.Visible = false
					end
				else
					line.Visible = false
				end
			end
		else
			for _, l in ipairs(data.skeleton.lines) do l.Visible = false end
		end

		-- кружок у земли
		local ct = data.circle
		local head = instance:FindFirstChild("Head")
		local root = instance.PrimaryPart or instance:FindFirstChild("HumanoidRootPart")
		if wantCircle and head and root then
			local speed = 2
			if ct.up then
				ct.alpha = math.min(ct.alpha + dt * speed, 1)
				if ct.alpha >= 1 then ct.up = false end
			else
				ct.alpha = math.max(ct.alpha - dt * speed, 0)
				if ct.alpha <= 0 then ct.up = true end
			end
			local footPos = root.Position - Vector3.new(0, (root.Size.Y * 0.8) + 1.2, 0)
			local headPos = head.Position + Vector3.new(0, 0.3, 0)
			local worldPos = footPos:Lerp(headPos, ct.alpha)
			table.insert(ct.history, 1, worldPos)
			if #ct.history > #ct.trail then table.remove(ct.history) end
			for i = 1, #ct.trail do
				local p1, p2 = ct.history[i], ct.history[i + 1]
				if p1 and p2 then
					local s1, v1 = camera:WorldToViewportPoint(p1)
					local s2, v2 = camera:WorldToViewportPoint(p2)
					if v1 or v2 then
						local fade = clamp(1 - (i / #ct.trail), 0.05, 1)
						ct.glow[i].From = Vector2.new(s1.X, s1.Y)
						ct.glow[i].To = Vector2.new(s2.X, s2.Y)
						ct.glow[i].Color = ESP.Circle.Color
						ct.glow[i].Transparency = fade * 0.35
						ct.glow[i].Visible = true
						ct.trail[i].From = Vector2.new(s1.X, s1.Y)
						ct.trail[i].To = Vector2.new(s2.X, s2.Y)
						ct.trail[i].Color = ESP.Circle.Color
						ct.trail[i].Transparency = fade * 0.85
						ct.trail[i].Visible = true
					else
						ct.trail[i].Visible = false
						ct.glow[i].Visible = false
					end
				else
					ct.trail[i].Visible = false
					ct.glow[i].Visible = false
				end
			end
			local R = 2.2
			for i = 1, ct.segments do
				local aA = pi2 * ((i - 1) / ct.segments)
				local aB = pi2 * (i / ct.segments)
				local wA = worldPos + Vector3.new(cos(aA) * R, 0, sin(aA) * R)
				local wB = worldPos + Vector3.new(cos(aB) * R, 0, sin(aB) * R)
				local sA, vA = camera:WorldToViewportPoint(wA)
				local sB, vB = camera:WorldToViewportPoint(wB)
				local line = ct.lines[i]
				if vA or vB then
					line.From = Vector2.new(sA.X, sA.Y)
					line.To = Vector2.new(sB.X, sB.Y)
					line.Color = ESP.Circle.Color
					line.Visible = true
				else
					line.Visible = false
				end
			end
		else
			for _, l in ipairs(ct.lines) do l.Visible = false end
			for _, l in ipairs(ct.trail) do l.Visible = false end
			for _, l in ipairs(ct.glow) do l.Visible = false end
		end
	end
end)

---------------------------------------------------------------------------
-- ESP: привязка к персонажам
---------------------------------------------------------------------------
local charactersFolder = workspace:FindFirstChild("Characters")
if not charactersFolder then
	task.spawn(function()
		charactersFolder = workspace:WaitForChild("Characters", 30)
	end)
end

local function addCharacter(character)
	if not character or espCharacters[character] or character == LocalPlayer.Character then return end
	if not (character:GetAttribute("Health") ~= nil or character:FindFirstChild("Head")) then return end
	espCharacters[character] = true
	addESPObjects(character)
end

local function removeCharacter(character)
	if not character then return end
	espCharacters[character] = nil
	removeESPObjects(character)
end

local function scanCharacters()
	if not charactersFolder then return end
	for _, obj in ipairs(charactersFolder:GetDescendants()) do
		if obj:IsA("Model") and obj:FindFirstChild("Head") then
			addCharacter(obj)
		end
	end
end

task.spawn(function()
	while not charactersFolder do task.wait(0.25) end
	scanCharacters()
	charactersFolder.DescendantAdded:Connect(function(desc)
		if desc:IsA("Model") then
			task.wait(0.1)
			addCharacter(desc)
		end
	end)
	charactersFolder.DescendantRemoving:Connect(function(desc)
		if desc:IsA("Model") then removeCharacter(desc) end
	end)
	Players.PlayerRemoving:Connect(function(player)
		if player.Character then removeCharacter(player.Character) end
	end)
	while true do
		task.wait(2)
		if ESP.Enabled then scanCharacters() end
	end
end)

---------------------------------------------------------------------------
-- ESP: UI
---------------------------------------------------------------------------
do
	section(espPage, "Основное")
	makeToggle(espPage, "Включить ESP", false, function(v)
		ESP.Enabled = v
		if v then
			scanCharacters()
			notify("ESP", "ESP включён")
		else
			for instance in next, espObjects do
				local data = espObjects[instance]
				if data then hideAllESP(data) end
			end
		end
		Persist.queue()
	end)
	makeToggle(espPage, "Проверка на союзников", true, function(v)
		ESP.TeamCheck = v
		Persist.queue()
	end)

	section(espPage, "Бокс")
	makeToggle(espPage, "Бокс", false, function(v) ESP.Box.Enabled = v end)
	makeDropdown(espPage, "Тип бокса", { "2D", "3D", "Corner", "Disabled" }, "2D", function(v) ESP.Box.Type = v end)
	makeColor(espPage, "Цвет A", ESP.Box.ColorA, function(c) ESP.Box.ColorA = c end)
	makeColor(espPage, "Цвет B", ESP.Box.ColorB, function(c) ESP.Box.ColorB = c end)
	makeToggle(espPage, "Заливка градиентом", false, function(v) ESP.Box.FillGradient = v end)
	makeColor(espPage, "Заливка A", ESP.Box.FillA, function(c) ESP.Box.FillA = c end)
	makeColor(espPage, "Заливка B", ESP.Box.FillB, function(c) ESP.Box.FillB = c end)
	makeToggle(espPage, "Вращение заливки", false, function(v) ESP.Box.FillRotation = v end)
	makeSlider(espPage, "Скорость вращения", 1, 10, 2, "x", function(v) ESP.Box.RotationSpeed = v end)

	section(espPage, "Здоровье")
	makeToggle(espPage, "Полоска HP", false, function(v) ESP.Health.Enabled = v end)
	makeColor(espPage, "HP сверху", ESP.Health.Top, function(c) ESP.Health.Top = c end)
	makeColor(espPage, "HP снизу", ESP.Health.Bottom, function(c) ESP.Health.Bottom = c end)
	makeToggle(espPage, "Текст HP", false, function(v) ESP.HealthText.Enabled = v end)
	makeColor(espPage, "Цвет текста HP", ESP.HealthText.Color, function(c) ESP.HealthText.Color = c end)
	makeSlider(espPage, "Размер текста HP", 8, 24, 12, "px", function(v) ESP.HealthText.Size = v end)

	section(espPage, "Информация")
	makeToggle(espPage, "Ник", false, function(v) ESP.Name.Enabled = v end)
	makeColor(espPage, "Цвет ника", ESP.Name.Color, function(c) ESP.Name.Color = c end)
	makeSlider(espPage, "Размер ника", 8, 24, 13, "px", function(v) ESP.Name.Size = v end)
	makeToggle(espPage, "Дистанция", false, function(v) ESP.Distance.Enabled = v end)
	makeColor(espPage, "Цвет дистанции", ESP.Distance.Color, function(c) ESP.Distance.Color = c end)
	makeSlider(espPage, "Размер дистанции", 8, 24, 13, "px", function(v) ESP.Distance.Size = v end)
	makeToggle(espPage, "Оружие", false, function(v) ESP.Weapon.Enabled = v end)
	makeColor(espPage, "Цвет оружия", ESP.Weapon.Color, function(c) ESP.Weapon.Color = c end)

	section(espPage, "Трассер")
	makeToggle(espPage, "Трассер", false, function(v) ESP.Tracer.Enabled = v end)
	makeColor(espPage, "Трассер A", ESP.Tracer.ColorA, function(c) ESP.Tracer.ColorA = c end)
	makeColor(espPage, "Трассер B", ESP.Tracer.ColorB, function(c) ESP.Tracer.ColorB = c end)
	makeDropdown(espPage, "Начало трассера", { "Bottom", "Top", "Center", "Mouse" }, "Bottom", function(v) ESP.Tracer.From = v end)

	section(espPage, "Скелет")
	makeToggle(espPage, "Скелет", false, function(v) ESP.Skeleton.Enabled = v end)
	makeColor(espPage, "Скелет A", ESP.Skeleton.ColorA, function(c) ESP.Skeleton.ColorA = c end)
	makeColor(espPage, "Скелет B", ESP.Skeleton.ColorB, function(c) ESP.Skeleton.ColorB = c end)
	makeSlider(espPage, "Толщина", 1, 6, 2, "px", function(v) ESP.Skeleton.Thickness = v end)

	section(espPage, "Кружок цели")
	makeToggle(espPage, "Кружок у земли", false, function(v) ESP.Circle.Enabled = v end)
	makeColor(espPage, "Цвет кружка", ESP.Circle.Color, function(c) ESP.Circle.Color = c end)
end

---------------------------------------------------------------------------
-- Skins: состояние и скинченджер
---------------------------------------------------------------------------
local Skins = {
	Root = nil,
	Lists = {},
	Selections = {},
	GloveSelections = {},
	GloveFolders = {},
	Enabled = false,
	KnifeEnabled = false,
	KnifeModel = "Skeleton Knife",
	GloveEnabled = false,
	GloveModel = nil,
	Gloves = {},
	Supported = true,
	Hooked = false,
	Modules = {},
	Originals = {},
}

do
	local ex = "Unknown"
	pcall(function()
		if type(identifyexecutor) == "function" then ex = select(1, identifyexecutor()) or "Unknown" end
	end)
	for _, name in ipairs({ "RonixExploit", "Xeno", "Solara" }) do
		if string.find(ex, name, 1, true) then Skins.Supported = false end
	end
end

pcall(function()
	Skins.Root = ReplicatedStorage:FindFirstChild("Assets") and ReplicatedStorage.Assets:FindFirstChild("Skins")
end)

if Skins.Root then
	pcall(function()
		for _, weaponFolder in ipairs(Skins.Root:GetChildren()) do
			local list = {}
			for _, skinFolder in ipairs(weaponFolder:GetChildren()) do
				if skinFolder.Name ~= "" then list[#list + 1] = skinFolder.Name end
			end
			table.sort(list)
			if #list == 0 then list = { "Default" } end
			Skins.Lists[weaponFolder.Name] = list
			Skins.Selections[weaponFolder.Name] = list[1]
		end
		for _, folder in ipairs(Skins.Root:GetChildren()) do
			local n = folder.Name
			local isGlove = (n:match("Glove") or n:match("Gloves") or n == "Hand Wraps")
			local isSideGlove = (n:match("T Glove") or n:match("CT Glove"))
			if isGlove and not isSideGlove then
				Skins.GloveFolders[#Skins.GloveFolders + 1] = folder
			end
		end
	end)
end

local BASE_KNIVES = { "CT Knife", "T Knife", "Knife" }
local KNIFE_MODELS = { "Karambit", "Butterfly Knife", "Flip Knife", "Gut Knife", "M9 Bayonet", "Skeleton Knife", "Stiletto Knife" }
local EXTRA_GLOVES = { "Driver Gloves", "Sports Gloves", "Operator Gloves", "Hand Wraps" }

local function isBaseKnife(w)
	if not w then return false end
	for _, k in ipairs(BASE_KNIVES) do
		if w == k then return true end
	end
	return false
end

local function SafeRequire(module)
	if not module then return nil end
	local ok, result = pcall(function() return require(module) end)
	if ok and type(result) == "table" then return result end
	return nil
end

local function UpdateInventoryNames()
	local invGui = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("MainGui")
	if not invGui then return end
	local gameplay = invGui:FindFirstChild("Gameplay")
	if not gameplay then return end
	local bottom = gameplay:FindFirstChild("Bottom")
	if not bottom then return end
	local inv = bottom:FindFirstChild("Inventory")
	if not inv then return end
	local meleeSlot = inv:FindFirstChild("Melee")
	if not (meleeSlot and Skins.KnifeEnabled) then return end
	local weapon = meleeSlot:FindFirstChild("Weapon")
	if not weapon then return end
	local weaponName = weapon:FindFirstChild("WeaponName")
	if not (weaponName and weaponName:IsA("TextLabel")) then return end
	local model = Skins.KnifeModel
	local sel = Skins.Selections[model]
	local star = utf8.char(9733)
	if type(sel) == "string" and sel ~= "Default" then
		weaponName.Text = star .. " " .. model .. " | " .. sel
	else
		weaponName.Text = star .. " " .. model
	end
end

local function GetWeaponModel()
	local camera = workspace.CurrentCamera
	if not camera then return nil end
	for _, child in ipairs(camera:GetChildren()) do
		if child:IsA("Model") and child.Name ~= "Arms" and child.Name ~= "Arms1" and child.Name ~= "Arms2" and child.Name ~= "Viewmodel" then
			return child
		end
	end
	return nil
end

local function ApplySkin()
	if not Skins.Root then return end
	local weaponModel = GetWeaponModel()
	if not weaponModel then return end
	local own = weaponModel.Name
	local target = own
	local allowed = false
	if isBaseKnife(own) then
		if Skins.KnifeEnabled then
			target = Skins.KnifeModel
			allowed = true
		end
	elseif Skins.Enabled then
		allowed = true
	end
	if not allowed then return end
	local selection = Skins.Selections[target]
	if type(selection) ~= "string" or selection == "Default" then return end
	local weaponFolder = Skins.Root:FindFirstChild(target)
	if not weaponFolder then return end
	local skinFolder = weaponFolder:FindFirstChild(selection)
	if not skinFolder then return end
	local cameraFolder = skinFolder:FindFirstChild("Camera")
	if not cameraFolder then return end
	local factoryNew = cameraFolder:FindFirstChild("Factory New")
	if not factoryNew then return end
	for _, appearance in ipairs(factoryNew:GetChildren()) do
		if appearance:IsA("SurfaceAppearance") then
			local part = weaponModel:FindFirstChild(appearance.Name, true)
			if part and (part:IsA("BasePart") or part:IsA("MeshPart")) then
				for _, old in ipairs(part:GetChildren()) do
					if old:IsA("SurfaceAppearance") then old:Destroy() end
				end
				appearance:Clone().Parent = part
			end
		end
	end
	UpdateInventoryNames()
end

local function ApplyGloves()
	if not Skins.GloveEnabled or not Skins.Root then return end
	local camera = workspace.CurrentCamera
	if not camera then return end
	local armsModel
	for _, child in ipairs(camera:GetChildren()) do
		if child:IsA("Model") and (child.Name:match("Arms") or child:FindFirstChild("Right Arm")) then
			armsModel = child
			break
		end
	end
	if not armsModel then return end
	local leftArm = armsModel:FindFirstChild("Left Arm")
	local rightArm = armsModel:FindFirstChild("Right Arm")
	if not (leftArm and rightArm) then return end
	local leftGlove = leftArm:FindFirstChild("Glove")
	local rightGlove = rightArm:FindFirstChild("Glove")
	if not (leftGlove and rightGlove) then return end
	for _, glovePart in ipairs({ leftGlove, rightGlove }) do
		for _, old in ipairs(glovePart:GetChildren()) do
			if old:IsA("SurfaceAppearance") then old:Destroy() end
		end
	end
	local model = Skins.GloveModel
	if not model then return end
	local selection = Skins.Gloves[model]
	if type(selection) ~= "string" or selection == "Default" then return end
	local gloveFolder = Skins.Root:FindFirstChild(model)
	if not gloveFolder then return end
	local variant = gloveFolder:FindFirstChild(selection)
	if not variant then return end
	local cameraFolder = variant:FindFirstChild("Camera")
	if not cameraFolder then return end
	local factoryNew = cameraFolder:FindFirstChild("Factory New")
	if not factoryNew then return end
	for _, appearance in ipairs(factoryNew:GetChildren()) do
		if appearance:IsA("SurfaceAppearance") then
			appearance:Clone().Parent = leftGlove
			appearance:Clone().Parent = rightGlove
		end
	end
end

local function InitSkinHooks()
	if not Skins.Supported or Skins.Hooked then return end
	pcall(function()
		local db = ReplicatedStorage:FindFirstChild("Database")
		local components = db and db:FindFirstChild("Components")
		local libraries = components and components:FindFirstChild("Libraries")
		local skinModule = libraries and libraries:FindFirstChild("Skins")
		local classes = ReplicatedStorage:FindFirstChild("Classes")
		local weaponComponent = classes and classes:FindFirstChild("WeaponComponent")
		local classFolder = weaponComponent and weaponComponent:FindFirstChild("Classes")
		local viewmodelModule = classFolder and classFolder:FindFirstChild("Viewmodel")
		if not skinModule or not viewmodelModule then return end
		local skinLib = SafeRequire(skinModule)
		local viewmodelLib = SafeRequire(viewmodelModule)
		if not skinLib or not viewmodelLib then return end
		Skins.Modules.Skins = skinLib
		Skins.Modules.Viewmodel = viewmodelLib

		local originalGetCameraModel = skinLib.GetCameraModel
		Skins.Originals.GetCameraModel = originalGetCameraModel
		skinLib.GetCameraModel = function(w, sk, ...)
			if Skins.KnifeEnabled and w and isBaseKnife(w) then
				local ok, result = pcall(originalGetCameraModel, Skins.KnifeModel, Skins.Selections[Skins.KnifeModel] or "Vanilla", ...)
				if ok and result then return result end
			end
			local ok, result = pcall(originalGetCameraModel, w, sk, ...)
			if ok then return result end
			return nil
		end

		local originalGetCharacterModel = skinLib.GetCharacterModel
		Skins.Originals.GetCharacterModel = originalGetCharacterModel
		skinLib.GetCharacterModel = function(w, sk, ...)
			if Skins.KnifeEnabled and w and isBaseKnife(w) then
				local ok, result = pcall(originalGetCharacterModel, Skins.KnifeModel, Skins.Selections[Skins.KnifeModel] or "Vanilla", ...)
				if ok and result then return result end
			end
			local ok, result = pcall(originalGetCharacterModel, w, sk, ...)
			if ok then return result end
			return nil
		end

		local originalViewmodelNew = viewmodelLib.new
		Skins.Originals.ViewmodelNew = originalViewmodelNew
		viewmodelLib.new = function(viewmodelClass, w, sk, ...)
			if Skins.KnifeEnabled and w and isBaseKnife(w) then
				local ok, result = pcall(originalViewmodelNew, viewmodelClass, Skins.KnifeModel, Skins.Selections[Skins.KnifeModel] or "Vanilla", ...)
				if ok and result then return result end
			end
			local ok, result = pcall(originalViewmodelNew, viewmodelClass, w, sk, ...)
			if ok then return result end
			return nil
		end

		if skinLib.GetGloves then
			local originalGetGloves = skinLib.GetGloves
			Skins.Originals.GetGloves = originalGetGloves
			skinLib.GetGloves = function(g, sk)
				if Skins.GloveEnabled and Skins.GloveModel then
					local model = Skins.GloveModel
					local ok, result = pcall(originalGetGloves, model, Skins.Gloves[model] or "Default")
					if ok and result then return result end
				end
				local ok, result = pcall(originalGetGloves, g, sk)
				if ok then return result end
				return nil
			end
		end

		Skins.Hooked = true
	end)
end

---------------------------------------------------------------------------
-- Skins: UI (под-вкладки)
---------------------------------------------------------------------------
local skinHandles, knifeHandles, gloveHandles, skinRows = {}, {}, {}, {}
local skinToggle, knifeToggle, gloveToggle, knifeModelDropdown, gloveModelDropdown

skinPage.Visible = false
local skinSubPages = makeSubTabs(Tabs.Skins.Group, { "Оружие", "Ножи", "Перчатки", "Конфиг" })
local weaponPage = skinSubPages["Оружие"].Scroll
local knifePage = skinSubPages["Ножи"].Scroll
local glovePage = skinSubPages["Перчатки"].Scroll
local configPage = skinSubPages["Конфиг"].Scroll

do
	section(weaponPage, "Скины оружия")

	if not Skins.Root then
		makeLabel(weaponPage, "ReplicatedStorage.Assets.Skins не найден — скинченджер не активен.")
	else
		skinToggle = makeToggle(weaponPage, "Включить скины оружия", false, function(v)
			Skins.Enabled = v
			if v then
				task.spawn(ApplySkin)
				notify("Skins", "Скины оружия включены")
			end
			Persist.queue()
		end)

		makeSearch(weaponPage, "Поиск оружия...", function(query)
			query = query:lower()
			for weapon, r in pairs(skinRows) do
				r.Visible = (query == "" or weapon:lower():find(query, 1, true) ~= nil)
			end
		end)

		local weaponNames = {}
		for weapon in pairs(Skins.Lists) do
			if not table.find(KNIFE_MODELS, weapon) and not table.find(EXTRA_GLOVES, weapon) then
				weaponNames[#weaponNames + 1] = weapon
			end
		end
		table.sort(weaponNames)

		for _, weapon in ipairs(weaponNames) do
			local list = Skins.Lists[weapon]
			if type(list) == "table" and #list > 0 then
				local current = Skins.Selections[weapon]
				if type(current) ~= "string" or not table.find(list, current) then current = list[1] end
				Skins.Selections[weapon] = current
				local handle = makeDropdown(weaponPage, weapon, list, current, function(v)
					Skins.Selections[weapon] = v
					Persist.queue()
				end)
				skinHandles[weapon] = handle
				skinRows[weapon] = handle.Row
			end
		end
	end

	section(knifePage, "Ножи")

	if Skins.Supported then
		knifeToggle = makeToggle(knifePage, "Включить смену ножей", false, function(v)
			Skins.KnifeEnabled = v
			UpdateInventoryNames()
			if v then notify("Skins", "Смена ножей включена") end
			Persist.queue()
		end)
		knifeModelDropdown = makeDropdown(knifePage, "Модель ножа", KNIFE_MODELS, Skins.KnifeModel, function(v)
			Skins.KnifeModel = v
			UpdateInventoryNames()
			Persist.queue()
		end)
		for _, knife in ipairs(KNIFE_MODELS) do
			local list = Skins.Lists[knife]
			if type(list) == "table" and #list > 0 then
				local current = Skins.Selections[knife]
				if type(current) ~= "string" or not table.find(list, current) then current = list[1] end
				Skins.Selections[knife] = current
				knifeHandles[knife] = makeDropdown(knifePage, "Скин: " .. knife, list, current, function(v)
					Skins.Selections[knife] = v
					Persist.queue()
				end)
			end
		end
	else
		makeLabel(knifePage, "Смена ножей недоступна на этом экзекьюторе (нужен hookfunction).")
	end

	section(glovePage, "Перчатки")

	if #Skins.GloveFolders > 0 then
		local gloveModels = {}
		for _, folder in ipairs(Skins.GloveFolders) do
			local list = { "Default" }
			for _, skin in ipairs(folder:GetChildren()) do
				if skin.Name ~= "" then list[#list + 1] = skin.Name end
			end
			Skins.GloveSelections[folder.Name] = list
			Skins.Gloves[folder.Name] = "Default"
			gloveModels[#gloveModels + 1] = folder.Name
		end
		table.sort(gloveModels)
		Skins.GloveModel = gloveModels[1]

		gloveToggle = makeToggle(glovePage, "Включить смену перчаток", false, function(v)
			Skins.GloveEnabled = v
			if v then
				task.spawn(ApplyGloves)
				notify("Skins", "Смена перчаток включена")
			end
			Persist.queue()
		end)
		gloveModelDropdown = makeDropdown(glovePage, "Модель перчаток", gloveModels, gloveModels[1], function(v)
			Skins.GloveModel = v
			Persist.queue()
		end)
		for _, glove in ipairs(gloveModels) do
			local list = Skins.GloveSelections[glove]
			gloveHandles[glove] = makeDropdown(glovePage, "Скин: " .. glove, list, list[1], function(v)
				Skins.Gloves[glove] = v
				Persist.queue()
			end)
		end
	else
		makeLabel(glovePage, "Папки перчаток не найдены.")
	end
end

---------------------------------------------------------------------------
-- Конфиг
---------------------------------------------------------------------------
local CONFIG_DIR = "KittenScript/BloxStrike"
local CONFIG_FILE = CONFIG_DIR .. "/config.json"
local hasFs = type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
local saveToken = 0

local function ensureDir()
	if type(isfolder) == "function" and type(makefolder) == "function" then
		if not isfolder(CONFIG_DIR) then pcall(makefolder, CONFIG_DIR) end
	end
end

local function collectConfig()
	local selections = {}
	for weapon, sel in pairs(Skins.Selections) do
		if type(sel) == "string" and sel ~= "" then selections[weapon] = sel end
	end
	local gloves = {}
	for glove, sel in pairs(Skins.Gloves) do
		if type(sel) == "string" and sel ~= "" then gloves[glove] = sel end
	end
	return {
		version = 4,
		skins = {
			enabled = Skins.Enabled,
			knifeEnabled = Skins.KnifeEnabled,
			knifeModel = Skins.KnifeModel,
			gloveEnabled = Skins.GloveEnabled,
			gloveModel = Skins.GloveModel,
			selections = selections,
			gloves = gloves,
		},
		settings = {
			fovEnabled = Fov.Enabled,
			fovValue = Fov.Value,
			bhopEnabled = Bhop.Enabled,
			bhopMode = Bhop.Mode,
		},
	}
end

local function saveConfig(silent)
	if not hasFs then
		if not silent then notify("Config", "Экзекьютор без writefile") end
		return false
	end
	local ok, encoded = pcall(function() return HttpService:JSONEncode(collectConfig()) end)
	if not ok or not encoded then return false end
	ensureDir()
	local wrote = pcall(writefile, CONFIG_FILE, encoded)
	if wrote and not silent then notify("Config", "Конфиг сохранён") end
	return wrote
end

local function coerceSkin(value, list)
	if type(value) == "table" then value = value[1] end
	if type(value) ~= "string" or value == "" then return nil end
	if list and not table.find(list, value) then return nil end
	return value
end

local function applyConfig(data)
	if type(data) ~= "table" then return end
	local s = data.skins or {}

	for weapon, raw in pairs(s.selections or {}) do
		local list = Skins.Lists[weapon]
		if type(list) == "table" and #list > 0 then
			local sel = coerceSkin(raw, list) or list[1]
			Skins.Selections[weapon] = sel
			local handle = skinHandles[weapon] or knifeHandles[weapon]
			if handle then pcall(function() handle:Set(sel) end) end
		end
	end
	for glove, raw in pairs(s.gloves or {}) do
		local list = Skins.GloveSelections[glove]
		if type(list) == "table" and #list > 0 then
			local sel = coerceSkin(raw, list) or "Default"
			Skins.Gloves[glove] = sel
			local handle = gloveHandles[glove]
			if handle then pcall(function() handle:Set(sel) end) end
		end
	end

	if type(s.knifeModel) == "string" and table.find(KNIFE_MODELS, s.knifeModel) then
		Skins.KnifeModel = s.knifeModel
		if knifeModelDropdown then pcall(function() knifeModelDropdown:Set(s.knifeModel) end) end
	end
	if type(s.gloveModel) == "string" and Skins.Gloves[s.gloveModel] and gloveModelDropdown then
		Skins.GloveModel = s.gloveModel
		pcall(function() gloveModelDropdown:Set(s.gloveModel) end)
	end

	if skinToggle then skinToggle:Set(s.enabled == true) end
	if knifeToggle then knifeToggle:Set(s.knifeEnabled == true) end
	if gloveToggle then gloveToggle:Set(s.gloveEnabled == true) end

	local st = data.settings or {}
	if type(st.fovValue) == "number" and fovSlider then fovSlider:Set(st.fovValue) end
	if fovToggle then fovToggle:Set(st.fovEnabled == true) end
	if type(st.bhopMode) == "string" and bhopModeDropdown then bhopModeDropdown:Set(st.bhopMode) end
	if bhopToggle then bhopToggle:Set(st.bhopEnabled == true) end

	UpdateInventoryNames()
	task.spawn(ApplySkin)
	task.spawn(ApplyGloves)
end

Persist.queue = function()
	if not (hasFs and Persist.autosave) then return end
	saveToken = saveToken + 1
	local token = saveToken
	task.delay(0.6, function()
		if token == saveToken then pcall(saveConfig, true) end
	end)
end

local function loadConfig(silent)
	if not hasFs then
		if not silent then notify("Config", "Экзекьютор без readfile") end
		return false
	end
	if not isfile(CONFIG_FILE) then
		if not silent then notify("Config", "Файл конфига не найден") end
		return false
	end
	local ok, raw = pcall(readfile, CONFIG_FILE)
	if not ok or not raw or raw == "" then return false end
	local decodedOk, data = pcall(function() return HttpService:JSONDecode(raw) end)
	if not decodedOk or type(data) ~= "table" then
		if not silent then notify("Config", "Конфиг повреждён") end
		return false
	end
	applyConfig(data)
	if not silent then notify("Config", "Конфиг загружен") end
	return true
end

local function resetConfig()
	for weapon, list in pairs(Skins.Lists) do
		local first = list[1]
		Skins.Selections[weapon] = first
		local handle = skinHandles[weapon] or knifeHandles[weapon]
		if handle then
			if first then
				pcall(function() handle:Set(first) end)
			else
				pcall(function() handle:Reset() end)
			end
		end
	end
	for glove in pairs(Skins.GloveSelections) do
		Skins.Gloves[glove] = "Default"
		local handle = gloveHandles[glove]
		if handle then pcall(function() handle:Set("Default") end) end
	end
	if skinToggle then skinToggle:Set(false) end
	if knifeToggle then knifeToggle:Set(false) end
	if gloveToggle then gloveToggle:Set(false) end
	pcall(ApplySkin)
	pcall(ApplyGloves)
	Persist.queue()
	notify("Config", "Настройки сброшены")
end

do
	section(configPage, "Сохранение")

	if hasFs then
		makeButton(configPage, "Save Config", function() saveConfig(false) end)
		makeButton(configPage, "Load Config", function() loadConfig(false) end)
		makeButton(configPage, "Reset All Skins", resetConfig)
		makeToggle(configPage, "Автосохранение", true, function(v)
			Persist.autosave = v
			if v then Persist.queue() end
		end)
		makeLabel(configPage, "Файл: " .. CONFIG_FILE .. "\nСкины, нож, перчатки, FOV и BHop пишутся автоматически при изменении.")
	else
		makeLabel(configPage, "Экзекьютор без файловых функций — сохранение недоступно.")
		makeButton(configPage, "Reset All Skins", resetConfig)
	end

	section(configPage, "Инфо")
	makeLabel(configPage, "Скины накатываются на вьюмодель каждые 0.5 с. Нож подменяется на уровне модуля Viewmodel, поэтому чужая модель видна сразу после респавна.")
end

task.spawn(function()
	if Skins.Supported then InitSkinHooks() end
	while true do
		pcall(function()
			if Skins.Enabled or Skins.KnifeEnabled then ApplySkin() end
			if Skins.GloveEnabled then ApplyGloves() end
		end)
		task.wait(0.5)
	end
end)

---------------------------------------------------------------------------
-- Открытие / закрытие
---------------------------------------------------------------------------
local function setMenu(state)
	gui.Toggled = state
	if state then
		mini.Visible = false
		main.Visible = true
		mainScale.Scale = 0.95
		tween(mainScale, 0.28, { Scale = 1 })
		syncShadow()
	else
		for _, popup in ipairs(table.clone(openPopups)) do pcall(function() popup:Destroy() end) end
		table.clear(openPopups)
		tween(mainScale, 0.18, { Scale = 0.95 })
		task.wait(0.16)
		main.Visible = false
		mini.Visible = true
		syncShadow()
	end
end

mini.MouseButton1Click:Connect(function() setMenu(true) end)
closeButton.MouseButton1Click:Connect(function() setMenu(false) end)

bind(UserInputService.InputBegan, function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.RightShift and not UserInputService:GetFocusedTextBox() then
		setMenu(not gui.Toggled)
	end
end)

task.defer(function()
	task.wait(0.4)
	pcall(loadConfig, true)
end)

---------------------------------------------------------------------------
-- Unload
---------------------------------------------------------------------------
function gui:Unload()
	pcall(saveConfig, true)
	if BhopState.Module and BhopState.Module.SampleInput == BhopState.Wrapper then
		BhopState.Module.SampleInput = BhopState.Original
	end
	local skinLib, viewmodelLib = Skins.Modules.Skins, Skins.Modules.Viewmodel
	if skinLib then
		if Skins.Originals.GetCameraModel then skinLib.GetCameraModel = Skins.Originals.GetCameraModel end
		if Skins.Originals.GetCharacterModel then skinLib.GetCharacterModel = Skins.Originals.GetCharacterModel end
		if Skins.Originals.GetGloves then skinLib.GetGloves = Skins.Originals.GetGloves end
	end
	if viewmodelLib and Skins.Originals.ViewmodelNew then
		viewmodelLib.new = Skins.Originals.ViewmodelNew
	end
	for instance in next, espObjects do removeESPObjects(instance) end
	local camera = workspace.CurrentCamera
	if camera and Fov.Original then camera.FieldOfView = Fov.Original end
	for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
	screen:Destroy()
	if env.KittenScript == gui then env.KittenScript = nil end
end
env.KittenScript = gui

switchTab("Visuals")
notify("KittenScript", "Загружено. RightShift — меню.")
