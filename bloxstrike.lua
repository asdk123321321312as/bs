--[[  KittenScript for Blox Strike
      SkinChanger (по системе SleepScript) · Camera FOV · Auto BunnyHop
      Toggle menu: RightShift
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = workspace
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

local skinPage = addTab("Skins", "✦")
local visualPage = addTab("Visuals", "◈")
local movePage = addTab("Movement", "⇅")

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

local function makeButton(parent, text, callback, primary)
	local b = create("TextButton", {
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = primary and C.Accent or C.Element,
		BackgroundTransparency = primary and 0 or 0.15,
		AutoButtonColor = false,
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		TextColor3 = primary and C.White or C.Text,
		Text = text,
	}, parent)
	corner(b, 12)
	if not primary then stroke(b, C.Stroke, 1, 0.6) end
	b.MouseEnter:Connect(function()
		tween(b, 0.18, primary and { BackgroundColor3 = C.AccentDeep } or { BackgroundColor3 = C.Hover, TextColor3 = C.AccentDeep })
	end)
	b.MouseLeave:Connect(function()
		tween(b, 0.18, primary and { BackgroundColor3 = C.Accent } or { BackgroundColor3 = C.Element, TextColor3 = C.Text })
	end)
	b.MouseButton1Click:Connect(callback)
	return b
end

local openPopups = {}
local function makeDropdown(parent, text, options, default, searchable, callback)
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
		Text = text,
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
	local popup, list, search, open = nil, nil, nil, false

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

	local function build(filter)
		if not list then return end
		for _, child in ipairs(list:GetChildren()) do
			if child:IsA("TextButton") then child:Destroy() end
		end
		local count = 0
		for _, option in ipairs(options) do
			if not filter or filter == "" or string.find(string.lower(option), string.lower(filter), 1, true) then
				count += 1
				local b = create("TextButton", {
					Size = UDim2.new(1, 0, 0, 27),
					BackgroundColor3 = option == value and C.Panel or C.Element,
					AutoButtonColor = false,
					Font = Enum.Font.Gotham,
					TextSize = 11,
					TextColor3 = option == value and C.AccentDeep or C.Text,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
					Text = "   " .. option,
				}, list)
				corner(b, 7)
				b.MouseEnter:Connect(function() tween(b, 0.12, { BackgroundColor3 = C.Hover }) end)
				b.MouseLeave:Connect(function()
					tween(b, 0.12, { BackgroundColor3 = option == value and C.Panel or C.Element })
				end)
				b.MouseButton1Click:Connect(function()
					value = option
					label.Text = option
					callback(option)
					close()
				end)
			end
		end
		list.CanvasSize = UDim2.new(0, 0, 0, count * 29 + 6)
	end

	clickable.MouseButton1Click:Connect(function()
		if open then close() return end
		for _, p in ipairs(table.clone(openPopups)) do pcall(function() p:Destroy() end) end
		table.clear(openPopups)
		if #options == 0 then
			notify("Пусто", "Список ещё не загружен")
			return
		end
		open = true
		local pos = r.AbsolutePosition - main.AbsolutePosition
		local width = math.max(200, r.AbsoluteSize.X)
		local x = math.clamp(pos.X, 8, math.max(8, main.AbsoluteSize.X - width - 8))
		popup = create("Frame", {
			Position = UDim2.fromOffset(x, pos.Y + r.AbsoluteSize.Y + 5),
			Size = UDim2.fromOffset(width, 210),
			BackgroundColor3 = C.White,
			BackgroundTransparency = 0.02,
			ZIndex = 60,
		}, main)
		corner(popup, 12)
		stroke(popup, C.Stroke, 1, 0.15)
		table.insert(openPopups, popup)

		if searchable then
			search = create("TextBox", {
				Position = UDim2.fromOffset(6, 6),
				Size = UDim2.new(1, -12, 0, 27),
				BackgroundColor3 = C.Element,
				Font = Enum.Font.Gotham,
				TextSize = 11,
				TextColor3 = C.Text,
				PlaceholderText = "Поиск...",
				PlaceholderColor3 = C.Dim,
				Text = "",
				ClearTextOnFocus = false,
				ZIndex = 61,
			}, popup)
			corner(search, 7)
			search:GetPropertyChangedSignal("Text"):Connect(function() build(search.Text) end)
		end

		list = create("ScrollingFrame", {
			Position = UDim2.fromOffset(6, searchable and 37 or 6),
			Size = UDim2.new(1, -12, 1, searchable and -43 or -12),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(),
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = C.Accent,
			ZIndex = 61,
		}, popup)
		create("UIListLayout", { Padding = UDim.new(0, 2) }, list)
		build("")
	end)

	return {
		Set = function(v)
			if type(v) ~= "string" then v = tostring(v) end
			value = v
			label.Text = v
		end,
		Get = function() return value end,
		SetOptions = function(o)
			if type(o) ~= "table" then o = {} end
			options = o
			if open then build(search and search.Text or "") end
		end,
		Close = close,
	}
end

---------------------------------------------------------------------------
-- Скинчейнджер (система SleepScript)
---------------------------------------------------------------------------
local WEAPONS = {
	"AK-47", "M4A1", "M4A4", "M4A1-S", "AWP", "SSG-08", "AUG", "SG-553", "FAMAS",
	"Galil", "SCAR-20", "G3SG1", "MP9", "MAC-10", "MP7", "MP5", "UMP-45", "P90",
	"PP-Bizon", "Nova", "XM1014", "MAG-7", "Sawed-Off", "M249", "Negev", "Glock",
	"Glock-18", "USP", "USP-S", "P2000", "P250", "Five-SeveN", "Tec-9", "CZ75",
	"Dual Berettas", "Desert Eagle", "Deagle", "R8 Revolver", "M1911", "Revolver",
}
local KNIVES = {
	"Karambit", "Butterfly Knife", "Butterfly", "M9 Bayonet", "Bayonet", "Flip Knife",
	"Flip", "Gut Knife", "Gut", "Huntsman Knife", "Falchion Knife", "Bowie Knife",
	"Shadow Daggers", "Skeleton Knife", "Skeleton", "Nomad Knife", "Paracord Knife",
	"Survival Knife", "Ursus Knife", "Stiletto Knife", "Talon Knife", "Classic Knife",
	"Kukri Knife", "Knife",
}
local GLOVES = {
	"Sports Gloves", "Driver Gloves", "Hand Wraps", "Specialist Gloves", "Moto Gloves",
	"Bloodhound Gloves", "Broken Fang Gloves", "Hydra Gloves", "Operator Gloves",
	"Gloves", "Default Gloves",
}

local BUILTIN_SKINS = {
	["★ Gold"] = { Color = Color3.fromRGB(255, 202, 84), Material = "Metal" },
	["★ Chrome"] = { Color = Color3.fromRGB(226, 230, 240), Material = "Metal", Reflectance = 0.5 },
	["★ Carbon"] = { Color = Color3.fromRGB(28, 28, 32), Material = "Metal" },
	["★ Fade"] = { Color = Color3.fromRGB(255, 130, 195), Material = "SmoothPlastic" },
	["★ Crimson"] = { Color = Color3.fromRGB(185, 28, 42), Material = "Metal" },
	["★ Neon Purple"] = { Color = Color3.fromRGB(168, 96, 255), Material = "Neon" },
	["★ Neon Blue"] = { Color = Color3.fromRGB(70, 170, 255), Material = "Neon" },
	["★ Neon Green"] = { Color = Color3.fromRGB(80, 255, 150), Material = "Neon" },
	["★ Toxic"] = { Color = Color3.fromRGB(190, 255, 60), Material = "Neon" },
	["★ Obsidian"] = { Color = Color3.fromRGB(12, 12, 16), Material = "Glass", Reflectance = 0.4 },
	["★ Frost"] = { Color = Color3.fromRGB(180, 230, 255), Material = "Ice", Reflectance = 0.3 },
	["★ Sand"] = { Color = Color3.fromRGB(214, 188, 140), Material = "Sand" },
	["★ White"] = { Color = Color3.fromRGB(245, 245, 250), Material = "SmoothPlastic" },
}

local Skin = {
	Enabled = false,
	Assignments = {},
	Library = {},
	Tracked = {},
	Desired = {},
	Originals = {},
	HiddenSA = {},
	Detected = "-",
	Parts = 0,
}

local function clean(s)
	return (s:lower():gsub("[%s_%-%.]", ""))
end

local ALL_NAMES = {}
for _, t in ipairs({ WEAPONS, KNIVES, GLOVES }) do
	for _, n in ipairs(t) do
		ALL_NAMES[#ALL_NAMES + 1] = n
	end
end

local function detectWeapon(model)
	if not model then return nil end
	local names = { model.Name }
	for _, d in ipairs(model:GetChildren()) do
		names[#names + 1] = d.Name
	end
	for _, n in ipairs(names) do
		local c = clean(n)
		for _, w in ipairs(ALL_NAMES) do
			local cw = clean(w)
			if #cw >= 3 and (c == cw or c:find(cw, 1, true)) then return w end
		end
	end
end

local function buildLibrary()
	Skin.Library = {}
	local seen = {}
	local function add(name, id)
		if not id or type(id) ~= "string" or id == "" then return end
		if seen[id] then return end
		seen[id] = true
		local key = name
		if Skin.Library[key] then key = name .. " #" .. tostring(math.random(1000, 9999)) end
		Skin.Library[key] = id
	end
	local n = 0
	for _, d in ipairs(ReplicatedStorage:GetDescendants()) do
		n = n + 1
		if n > 50000 then break end
		local id
		if d:IsA("Decal") or d:IsA("Texture") then
			id = d.Texture
		elseif d:IsA("ImageLabel") or d:IsA("ImageButton") then
			id = d.Image
		elseif d:IsA("SurfaceAppearance") then
			id = d.ColorMap
		elseif d:IsA("MeshPart") then
			id = d.TextureID
		elseif d:IsA("StringValue") then
			local v = d.Value
			if type(v) == "string" and (v:find("rbxassetid") or v:find("asset/?id=")) then id = v end
		end
		if id then add(d.Name, id) end
	end
	local total = 0
	for _ in pairs(Skin.Library) do total = total + 1 end
	return total
end

local function skinOptions()
	local o = { "None" }
	local k = {}
	for key in pairs(BUILTIN_SKINS) do k[#k + 1] = key end
	table.sort(k)
	for _, key in ipairs(k) do o[#o + 1] = key end
	local g = {}
	for key in pairs(Skin.Library) do g[#g + 1] = key end
	table.sort(g)
	for _, key in ipairs(g) do o[#o + 1] = key end
	return o
end

local function clearSkinChildren(part)
	for _, c in ipairs(part:GetChildren()) do
		if c.Name:sub(1, 9) == "KittenSkin" then c:Destroy() end
	end
end

local function hideSA(part)
	local sa = part:FindFirstChildOfClass("SurfaceAppearance")
	if sa and not Skin.HiddenSA[part] then
		Skin.HiddenSA[part] = sa
		sa.Parent = nil
	end
end

local function restoreSA(part)
	local sa = Skin.HiddenSA[part]
	if sa then
		pcall(function() sa.Parent = part end)
		Skin.HiddenSA[part] = nil
	end
end

local function applyTexture(part, id)
	if not id or id == "" then
		clearSkinChildren(part)
		restoreSA(part)
		return
	end
	hideSA(part)
	if part:IsA("MeshPart") then pcall(function() part.TextureID = id end) end
	local sm = part:FindFirstChildOfClass("SpecialMesh")
	if sm then pcall(function() sm.TextureId = id end) end
	if not part:IsA("MeshPart") and not sm then
		for i, f in ipairs({ "Front", "Back", "Left", "Right", "Top", "Bottom" }) do
			local t = part:FindFirstChild("KittenSkin" .. i)
			if not t then
				t = create("Texture", {
					Name = "KittenSkin" .. i,
					Face = Enum.NormalId[f],
					StudsPerTileU = 1,
					StudsPerTileV = 1,
				}, part)
			end
			t.Texture = id
		end
	end
end

local function assignmentFor(model)
	local det = detectWeapon(model)
	if det and Skin.Assignments[det] then return Skin.Assignments[det] end
	if Skin.Assignments["*"] then return Skin.Assignments["*"] end
	return nil
end

local function stylePart(part, model)
	if not part:IsA("BasePart") then return end
	local skinName = assignmentFor(model)
	if not skinName or skinName == "None" then return end
	if not Skin.Originals[part] then
		Skin.Originals[part] = {
			Material = part.Material,
			Color = part.Color,
			Reflectance = part.Reflectance,
			TextureID = part:IsA("MeshPart") and part.TextureID or nil,
		}
	end

	local color, material, texture
	local b = BUILTIN_SKINS[skinName]
	if b then
		color = b.Color
		if b.Material then material = Enum.Material[b.Material] end
	else
		local id = Skin.Library[skinName]
		if id then
			texture = id
			color = Color3.new(1, 1, 1)
		end
	end

	if texture then applyTexture(part, texture) else clearSkinChildren(part) restoreSA(part) end
	if color then part.Color = color end
	if material then part.Material = material end

	Skin.Desired[part] = { Color = color, Material = material, Texture = texture, Skin = skinName }
end

local function restorePart(part)
	local o = Skin.Originals[part]
	if o then
		pcall(function()
			part.Material = o.Material
			part.Color = o.Color
			part.Reflectance = o.Reflectance
			if o.TextureID and part:IsA("MeshPart") then part.TextureID = o.TextureID end
		end)
	end
	clearSkinChildren(part)
	restoreSA(part)
	Skin.Desired[part] = nil
end

local function isViewModel(m)
	if not m:IsA("Model") then return false end
	if m.Parent == Workspace.CurrentCamera then return true end
	local n = m.Name:lower()
	return n:find("view") or n:find("worldmodel") or n:find("arms") or n:find("hands")
		or n:find("weapon") or n:find("fps") or n:find("tool")
end

local function collectParts()
	local out = {}
	local cam = Workspace.CurrentCamera
	local camPos = cam and cam.CFrame.Position
	local function push(part, model)
		out[#out + 1] = { part = part, model = model }
	end

	if cam then
		for _, c in ipairs(cam:GetChildren()) do
			if c:IsA("BasePart") then
				push(c, c)
			elseif c:IsA("Model") or c:IsA("Folder") then
				for _, d in ipairs(c:GetDescendants()) do
					if d:IsA("BasePart") then push(d, c) end
				end
			end
		end
	end
	for _, c in ipairs(Workspace:GetChildren()) do
		if isViewModel(c) then
			for _, d in ipairs(c:GetDescendants()) do
				if d:IsA("BasePart") then push(d, c) end
			end
		end
	end
	if camPos then
		for _, c in ipairs(Workspace:GetChildren()) do
			if c:IsA("Model") and not isViewModel(c) and not Players:GetPlayerFromCharacter(c) then
				local ok, ext = pcall(function() return c:GetExtentsSize() end)
				if ok and ext and ext.Magnitude < 30 then
					local parts, near = {}, false
					for _, d in ipairs(c:GetDescendants()) do
						if d:IsA("BasePart") then
							parts[#parts + 1] = d
							if not near and (d.Position - camPos).Magnitude < 14 then near = true end
						end
					end
					if near and #parts <= 60 then
						for _, d in ipairs(parts) do push(d, c) end
					end
				end
			end
		end
	end
	return out
end

local function scanForParts()
	if not Skin.Enabled then return end
	local list = collectParts()
	Skin.Parts = #list
	for _, e in ipairs(list) do
		Skin.Tracked[e.part] = true
		local det = detectWeapon(e.model)
		if det then Skin.Detected = det end
		stylePart(e.part, e.model)
	end
end

local function restyleAll()
	for part in pairs(Skin.Desired) do
		if not part.Parent then
			Skin.Desired[part] = nil
			Skin.Tracked[part] = nil
			Skin.Originals[part] = nil
		end
	end
	if Skin.Enabled then scanForParts() end
end

local function clearAll()
	for part in pairs(Skin.Originals) do
		if part and part.Parent then restorePart(part) end
	end
	Skin.Originals, Skin.Desired, Skin.Tracked = {}, {}, {}
end

local function enforceDesired()
	if not Skin.Enabled then return end
	for part, d in pairs(Skin.Desired) do
		if part.Parent then
			if d.Color and part.Color ~= d.Color then part.Color = d.Color end
			if d.Material and part.Material ~= d.Material then part.Material = d.Material end
			if d.Texture and part:IsA("MeshPart") and part.TextureID ~= d.Texture then
				pcall(function() part.TextureID = d.Texture end)
			end
		end
	end
end

bind(Workspace:GetPropertyChangedSignal("CurrentCamera"), function()
	Skin.Tracked, Skin.Desired = {}, {}
	if Skin.Enabled then scanForParts() end
end)

---------------------------------------------------------------------------
-- Вкладка Skins
---------------------------------------------------------------------------
do
	local status = makeLabel(skinPage, "detected: -   |   parts: 0   |   game skins: 0")
	local function updStatus()
		local n = 0
		for _ in pairs(Skin.Library) do n = n + 1 end
		status.Text = string.format("detected: %s   |   parts: %d   |   game skins: %d", Skin.Detected, Skin.Parts, n)
	end

	makeToggle(skinPage, "Включить скинчейнджер", false, function(v)
		Skin.Enabled = v
		if v then
			scanForParts()
			notify("Skin", "отслежено " .. Skin.Parts .. " частей")
		else
			clearAll()
		end
		updStatus()
	end)

	section(skinPage, "Оружие и скин")
	local weaponOptions = { "Auto (всё)" }
	for _, w in ipairs(WEAPONS) do weaponOptions[#weaponOptions + 1] = w end
	for _, k in ipairs(KNIVES) do weaponOptions[#weaponOptions + 1] = k end
	for _, g in ipairs(GLOVES) do weaponOptions[#weaponOptions + 1] = g end

	local weaponDropdown = makeDropdown(skinPage, "Auto (всё)", weaponOptions, "Auto (всё)", true, function() end)
	local skinDropdown = makeDropdown(skinPage, "★ Gold", skinOptions(), "★ Gold", true, function() end)

	makeButton(skinPage, "ПРИМЕНИТЬ СКИН", function()
		local w = weaponDropdown.Get()
		local s = skinDropdown.Get()
		local key = (w == "Auto (всё)") and "*" or w
		Skin.Assignments[key] = s
		if not Skin.Enabled then
			Skin.Enabled = true
			notify("Skin", "скинчейнджер включён")
		end
		scanForParts()
		restyleAll()
		updStatus()
		if skinListLabel then skinListLabel.Text = "" end
		updList()
		notify("Skin", w .. " → " .. s)
	end, true)

	makeButton(skinPage, "Убрать скин с этого оружия", function()
		local w = weaponDropdown.Get()
		local key = (w == "Auto (всё)") and "*" or w
		Skin.Assignments[key] = nil
		clearAll()
		restyleAll()
		updList()
		notify("Skin", "убрано: " .. w)
	end)

	makeButton(skinPage, "Пересканировать скины игры", function()
		local n = buildLibrary()
		skinDropdown.SetOptions(skinOptions())
		updStatus()
		notify("Skin", "найдено " .. n .. " скинов в файлах")
	end)

	section(skinPage, "Назначения")
	local skinListLabel
	local function updList()
		if not skinListLabel then return end
		local parts = {}
		for k, v in pairs(Skin.Assignments) do
			parts[#parts + 1] = (k == "*" and "ВСЁ" or k) .. " → " .. v
		end
		table.sort(parts)
		skinListLabel.Text = #parts > 0 and table.concat(parts, "\n") or "пусто"
	end
	skinListLabel = makeLabel(skinPage, "пусто")

	bind(RunService.Heartbeat, function()
		local timer = os.clock()
		if timer < (skinPage.timer or 0) then return end
		skinPage.timer = timer + 0.25
		if Skin.Enabled then pcall(scanForParts) end
		pcall(enforceDesired)
		pcall(updStatus)
		pcall(updList)
	end)

	updStatus()
end

---------------------------------------------------------------------------
-- Вкладка Visuals (FOV)
---------------------------------------------------------------------------
local Fov = { Enabled = false, Value = 90, Original = nil }

do
	section(visualPage, "Камера")
	makeToggle(visualPage, "Включить FOV", false, function(v)
		Fov.Enabled = v
		local camera = workspace.CurrentCamera
		if v and camera then
			Fov.Original = camera.FieldOfView
		elseif camera and Fov.Original then
			camera.FieldOfView = Fov.Original
		end
	end)
	makeSlider(visualPage, "Значение FOV", 60, 130, 90, "", function(v) Fov.Value = v end)

	bind(RunService.RenderStepped, function()
		local camera = workspace.CurrentCamera
		if Fov.Enabled and camera and math.abs(camera.FieldOfView - Fov.Value) > 0.05 then
			camera.FieldOfView = Fov.Value
		end
	end)
end

---------------------------------------------------------------------------
-- Вкладка Movement
---------------------------------------------------------------------------
local Bhop = { Enabled = false, Mode = "Auto", Delay = 0, MovingOnly = false, CrouchJump = false, PauseWithMenu = false, Hooked = false }
local BhopState = { Module = nil, Buttons = nil, Original = nil, Wrapper = nil, LastDown = false, GroundSince = nil }

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
	makeToggle(movePage, "Включить Auto BunnyHop", false, function(v)
		Bhop.Enabled = v
		if v and not Bhop.Hooked then
			notify("BHop", "Резервный режим — хук ещё не готов")
		end
	end)
	makeDropdown(movePage, "Режим", { "Auto", "Hold" }, "Auto", false, function(v) Bhop.Mode = v end)

	section(movePage, "Инфо")
	makeLabel(movePage, "Auto — прыгает сам при касании земли.\nHold — только пока зажата кнопка прыжка.\nJump на колесо и стрейфы A/D держат скорость.")
end

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

---------------------------------------------------------------------------
-- Unload
---------------------------------------------------------------------------
function gui:Unload()
	if BhopState.Module and BhopState.Module.SampleInput == BhopState.Wrapper then
		BhopState.Module.SampleInput = BhopState.Original
	end
	pcall(clearAll)
	local camera = workspace.CurrentCamera
	if camera and Fov.Original then camera.FieldOfView = Fov.Original end
	for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
	screen:Destroy()
	if env.KittenScript == gui then env.KittenScript = nil end
end
env.KittenScript = gui

switchTab("Skins")
notify("KittenScript", "Загружено. RightShift — меню.")
