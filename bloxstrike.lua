--[[  KittenScript for Blox Strike
      SkinChanger (по системе twistedk1d) · Camera FOV · Auto BunnyHop
      Toggle menu: RightShift
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local ContextActionService = game:GetService("ContextActionService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local env = (getgenv and getgenv()) or shared

if env.KittenScript and type(env.KittenScript.Unload) == "function" then
	pcall(function() env.KittenScript:Unload() end)
end

local RS = ReplicatedStorage
local CAS = ContextActionService

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
	for k, v in pairs(props or {}) do o[k] = v end
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

local glow = create("Frame", {
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

local function hint(parent, text, height)
	return create("TextLabel", {
		Size = UDim2.new(1, 0, 0, height or 16),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		TextSize = 10,
		TextColor3 = C.Dim,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
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
	local label = create("TextLabel", {
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
		local width = math.max(190, r.AbsoluteSize.X)
		local x = math.clamp(pos.X, 8, math.max(8, main.AbsoluteSize.X - width - 8))
		popup = create("Frame", {
			Position = UDim2.fromOffset(x, pos.Y + r.AbsoluteSize.Y + 5),
			Size = UDim2.fromOffset(width, searchable and 202 or 182),
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
-- Данные скинов (как в оригинале twistedk1d)
---------------------------------------------------------------------------
local Characters = workspace:WaitForChild("Characters")

local scriptRunning = false
local selectedKnife = "Butterfly Knife"
local spawned = false
local inspecting = false
local swinging = false
local lastAttackTime = 0

local ATTACK_COOLDOWN = 1
local ACTION_INSPECT = "KittenInspectKnife"
local ACTION_ATTACK = "KittenAttackKnife"

local knives = {
	["Karambit"] = { Offset = CFrame.new(0, -1.5, 1.5) },
	["Butterfly Knife"] = { Offset = CFrame.new(0, -1.5, 1.5) },
	["M9 Bayonet"] = { Offset = CFrame.new(0, -1.5, 1) },
	["Flip Knife"] = { Offset = CFrame.new(0, -1.5, 1.25) },
	["Gut Knife"] = { Offset = CFrame.new(0, -1.5, 0.5) },
}

local vm, animator
local equipAnim, idleAnim, inspectAnim
local HeavySwingAnim, Swing1Anim, Swing2Anim

local function getCamera()
	return workspace.CurrentCamera
end

local function isAlive()
	local t = Characters:FindFirstChild("Terrorists")
	local ct = Characters:FindFirstChild("Counter-Terrorists")
	return (t and t:FindFirstChild(LocalPlayer.Name)) or (ct and ct:FindFirstChild(LocalPlayer.Name))
end

local function getKnifeInCamera()
	local camera = getCamera()
	return camera and (camera:FindFirstChild("T Knife") or camera:FindFirstChild("CT Knife"))
end

local function cleanPart(part)
	if not part:IsA("BasePart") then return end
	part.CanCollide = false
	part.Anchored = false
	part.CastShadow = false
	part.CanTouch = false
	part.CanQuery = false
end

local function hideOriginalKnife(knife)
	for _, part in ipairs(knife:GetDescendants()) do
		if part:IsA("BasePart") or part:IsA("MeshPart") then
			part.Transparency = 1
		end
		if part:IsA("Texture") then
			part.Transparency = 1
		end
	end
end

local function playSound(folder, name)
	local sounds = RS:FindFirstChild("Sounds")
	local weaponSounds = sounds and sounds:FindFirstChild(selectedKnife)
	if not weaponSounds then return end
	pcall(function()
		local sound = weaponSounds:WaitForChild(folder):WaitForChild(name):Clone()
		sound.Parent = getCamera()
		sound:Play()
		sound.Ended:Once(function() sound:Destroy() end)
		return sound
	end)
end

local function attachAsset(folder, armPartName, assetModelName, finalName, offset)
	local targetArm = vm and vm:FindFirstChild(armPartName)
	if not targetArm or not folder then return end
	local source = folder:FindFirstChild(assetModelName)
	if not source then return end
	local assetMesh = source:Clone()
	cleanPart(assetMesh)
	assetMesh.Name = finalName
	assetMesh.Parent = targetArm
	local motor = create("Motor6D", { Part0 = targetArm, Part1 = assetMesh, C0 = offset }, targetArm)
	motor.Name = finalName .. "Motor"
end

local function handleAction(actionName, inputState)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	if not spawned or not animator or not isAlive() then
		return Enum.ContextActionResult.Pass
	end

	if actionName == ACTION_INSPECT then
		if (equipAnim and equipAnim.IsPlaying) or inspecting or swinging then
			return Enum.ContextActionResult.Pass
		end
		inspecting = true
		if idleAnim then idleAnim:Stop() end
		if inspectAnim then
			inspectAnim:Play()
			inspectAnim.Stopped:Once(function() inspecting = false end)
		end
	elseif actionName == ACTION_ATTACK then
		local now = os.clock()
		if (equipAnim and equipAnim.IsPlaying) or (now - lastAttackTime < ATTACK_COOLDOWN) then
			return Enum.ContextActionResult.Pass
		end
		lastAttackTime = now
		if inspecting then
			inspecting = false
			if inspectAnim then inspectAnim:Stop() end
		end
		swinging = true
		if idleAnim then idleAnim:Stop() end
		local pool = { HeavySwingAnim, Swing1Anim, Swing2Anim }
		local chosen = pool[math.random(1, #pool)]
		if chosen then
			local folder = (chosen == HeavySwingAnim and "HitOne") or (chosen == Swing1Anim and "HitTwo") or "HitThree"
			chosen:Play()
			local s = playSound(folder, "1")
			if s then s.Volume = 5 end
			chosen.Stopped:Once(function() swinging = false end)
		else
			swinging = false
		end
	end
	return Enum.ContextActionResult.Pass
end

local function removeViewmodel()
	spawned = false
	pcall(function()
		CAS:UnbindAction(ACTION_INSPECT)
		CAS:UnbindAction(ACTION_ATTACK)
	end)
	if vm then
		pcall(function() vm:Destroy() end)
		vm = nil
	end
	animator = nil
	inspecting = false
	swinging = false
end

local function spawnViewmodel()
	if spawned or not scriptRunning then return end
	local myModel = isAlive()
	local camera = getCamera()
	if not myModel or not camera then return end
	if not knives[selectedKnife] then return end

	local weapons = RS:FindFirstChild("Assets") and RS.Assets:FindFirstChild("Weapons")
	local knifeTemplate = weapons and weapons:FindFirstChild(selectedKnife)
	local cameraTemplate = knifeTemplate and knifeTemplate:FindFirstChild("Camera")
	if not cameraTemplate then
		notify("Нож", "Модель " .. selectedKnife .. " не найдена")
		return
	end

	spawned = true
	vm = cameraTemplate:Clone()
	vm.Name = selectedKnife
	for _, part in ipairs(vm:GetDescendants()) do cleanPart(part) end
	vm.Parent = camera

	local original = getKnifeInCamera()
	if original and original ~= vm then hideOriginalKnife(original) end

	if myModel.Parent and myModel.Parent.Name == "Terrorists" then
		local gloves = weapons:FindFirstChild("T Glove")
		attachAsset(gloves, "Left Arm", "Left Arm", "Glove", CFrame.new(0, 0, -1.5))
		attachAsset(gloves, "Right Arm", "Right Arm", "Glove", CFrame.new(0, 0, -1.5))
	else
		local assets = RS.Assets
		local sleeves = assets:FindFirstChild("Sleeves") and assets.Sleeves:FindFirstChild("IDF")
		local ctGloves = weapons:FindFirstChild("CT Glove")
		attachAsset(sleeves, "Left Arm", "Left Arm", "Sleeve", CFrame.new(0, 0, 0.5))
		attachAsset(ctGloves, "Left Arm", "Left Arm", "Glove", CFrame.new(0, 0, -1.5))
		attachAsset(sleeves, "Right Arm", "Right Arm", "Sleeve", CFrame.new(0, 0, 0.5))
		attachAsset(ctGloves, "Right Arm", "Right Arm", "Glove", CFrame.new(0, 0, -1.5))
	end

	local animController = vm:FindFirstChildOfClass("AnimationController") or vm:FindFirstChildOfClass("Animator")
	animator = animController and (animController:FindFirstChildWhichIsA("Animator") or animController)

	local animFolder = RS.Assets:FindFirstChild("WeaponAnimations")
	animFolder = animFolder and animFolder:FindFirstChild(selectedKnife)
	animFolder = animFolder and animFolder:FindFirstChild("CameraAnimations")

	if animator and animFolder then
		local function load(name)
			local asset = animFolder:FindFirstChild(name)
			if not asset then return nil end
			local ok, track = pcall(function() return animator:LoadAnimation(asset) end)
			return ok and track or nil
		end
		equipAnim = load("Equip")
		idleAnim = load("Idle")
		inspectAnim = load("Inspect")
		HeavySwingAnim = load("Heavy Swing")
		Swing1Anim = load("Swing1")
		Swing2Anim = load("Swing2")
	end

	local offset = knives[selectedKnife].Offset
	if vm.PrimaryPart then
		vm:SetPrimaryPartCFrame(camera.CFrame * CFrame.new(0, -1.5, 5))
		tween(vm.PrimaryPart, 0.2, { CFrame = camera.CFrame * offset })
	end

	if equipAnim then equipAnim:Play() end
	playSound("Equip", "1")

	CAS:BindAction(ACTION_INSPECT, handleAction, false, Enum.KeyCode.F)
	CAS:BindAction(ACTION_ATTACK, handleAction, false, Enum.UserInputType.MouseButton1)
end

bind(RunService.RenderStepped, function()
	local camera = getCamera()
	if not scriptRunning or not vm or not vm.PrimaryPart or not camera then return end
	vm.PrimaryPart.CFrame = camera.CFrame * knives[selectedKnife].Offset
	if not (equipAnim and equipAnim.IsPlaying) and not inspecting and not swinging then
		if idleAnim and not idleAnim.IsPlaying then idleAnim:Play() end
	end
end)

task.spawn(function()
	while screen.Parent do
		local living = isAlive()
		local current = getKnifeInCamera()
		if scriptRunning and living and current and not spawned then
			pcall(spawnViewmodel)
		elseif (not scriptRunning or not current or not living) and spawned then
			pcall(removeViewmodel)
		end
		task.wait(0.1)
	end
end)

---------------------------------------------------------------------------
-- Скинчейнджер (логика twistedk1d)
---------------------------------------------------------------------------
local SkinChangerEnabled = false
local SelectedSkins = {}
local WEAR = "Factory New"

local CT_ONLY = {
	["USP-S"] = true, ["Five-SeveN"] = true, ["MP9"] = true,
	["FAMAS"] = true, ["M4A1-S"] = true, ["M4A4"] = true, ["AUG"] = true,
}

local SHARED = {
	["P250"] = true, ["Desert Eagle"] = true, ["Dual Berettas"] = true,
	["Negev"] = true, ["P90"] = true, ["Nova"] = true, ["XM1014"] = true,
	["AWP"] = true, ["SSG 08"] = true,
}

local KNIVES = {
	["Karambit"] = true, ["Butterfly Knife"] = true, ["M9 Bayonet"] = true,
	["Flip Knife"] = true, ["Gut Knife"] = true, ["T Knife"] = true, ["CT Knife"] = true,
}

local GLOVES = { ["Sports Gloves"] = true }

local IgnoreFolders = {
	["HE Grenade"] = true, ["Incendiary Grenade"] = true, ["Molotov"] = true,
	["Smoke Grenade"] = true, ["Flashbang"] = true, ["Decoy Grenade"] = true,
	["C4"] = true, ["CT Glove"] = true, ["T Glove"] = true,
}

local SkinsFolder

local function applyWeaponSkin(model)
	local camera = getCamera()
	if not model or not camera or not SkinChangerEnabled or not isAlive() then return end
	local skinName = SelectedSkins[model.Name]
	if not skinName or not SkinsFolder then return end

	pcall(function()
		local skinFolder = SkinsFolder:FindFirstChild(model.Name)
		if not skinFolder then return end
		local skinType = skinFolder:FindFirstChild(skinName)
		local sourceFolder = skinType and skinType:FindFirstChild("Camera") and skinType.Camera:FindFirstChild(WEAR)
		if not sourceFolder then return end

		for _, obj in ipairs(camera:GetChildren()) do
			if obj:FindFirstChild("Left Arm") or obj:FindFirstChild("Right Arm") then
				local gloveFolder = SkinsFolder:FindFirstChild("Sports Gloves")
				local gloveSkin = gloveFolder and gloveFolder:FindFirstChild(SelectedSkins["Sports Gloves"] or "")
				local gloveSource = gloveSkin and gloveSkin:FindFirstChild("Camera") and gloveSkin.Camera:FindFirstChild(WEAR)
				if gloveSource then
					for _, side in ipairs({ "Left Arm", "Right Arm" }) do
						local arm = obj:FindFirstChild(side)
						local src = gloveSource:FindFirstChild(side)
						if arm and src then
							local gloveMesh = arm:FindFirstChild("Glove")
							if gloveMesh then
								local existing = gloveMesh:FindFirstChildOfClass("SurfaceAppearance")
								if existing then existing:Destroy() end
								local clone = src:Clone()
								clone.Name = "SurfaceAppearance"
								clone.Parent = gloveMesh
							end
						end
					end
				end
			end
		end

		if not GLOVES[model.Name] then
			local weaponFolder = model:FindFirstChild("Weapon")
			if weaponFolder then
				for _, part in ipairs(weaponFolder:GetDescendants()) do
					if part:IsA("BasePart") then
						local newSkin = sourceFolder:FindFirstChild(part.Name)
						if newSkin then
							local existing = part:FindFirstChildOfClass("SurfaceAppearance")
							if existing then existing:Destroy() end
							local clone = newSkin:Clone()
							clone.Name = "SurfaceAppearance"
							clone.Parent = part
						end
					end
				end
			end
		end

		model:SetAttribute("SkinApplied", skinName)
	end)
end

local function refreshSkins()
	local camera = getCamera()
	if not camera then return end
	for _, obj in ipairs(camera:GetChildren()) do
		obj:SetAttribute("SkinApplied", nil)
		applyWeaponSkin(obj)
	end
end

---------------------------------------------------------------------------
-- Вкладка Skins
---------------------------------------------------------------------------
do
	section(skinPage, "Кастомный нож")
	makeToggle(skinPage, "Включить кастомный нож", false, function(v)
		scriptRunning = v
		if not v then pcall(removeViewmodel) end
	end)

	local knifeList = {}
	for name in pairs(knives) do table.insert(knifeList, name) end
	table.sort(knifeList)

	makeDropdown(skinPage, selectedKnife, knifeList, selectedKnife, false, function(name)
		selectedKnife = name
		if spawned then pcall(removeViewmodel) end
	end)
	hint(skinPage, "F — осмотр, ЛКМ — взмах.", 16)

	section(skinPage, "Скинчейнджер")
	makeToggle(skinPage, "Включить скинчейнджер", false, function(v)
		SkinChangerEnabled = v
		if not v then
			local camera = getCamera()
			if camera then
				for _, obj in ipairs(camera:GetChildren()) do
					obj:SetAttribute("SkinApplied", nil)
				end
			end
		else
			task.defer(refreshSkins)
		end
	end)

	local function buildSkinDropdowns(parent, list)
		for weaponName in pairs(list) do
			local folder = SkinsFolder and SkinsFolder:FindFirstChild(weaponName)
			if folder then
				local options = {}
				for _, skin in ipairs(folder:GetChildren()) do
					table.insert(options, skin.Name)
				end
				table.sort(options)
				if not SelectedSkins[weaponName] then SelectedSkins[weaponName] = options[1] end
				makeDropdown(parent, weaponName, options, SelectedSkins[weaponName] or "—", true, function(skin)
					SelectedSkins[weaponName] = skin
					refreshSkins()
				end)
			end
		end
	end

	task.spawn(function()
		local assets = RS:WaitForChild("Assets", 60)
		SkinsFolder = assets and assets:WaitForChild("Skins", 30)
		if not SkinsFolder then
			hint(skinPage, "Папка скинов не найдена.", 20)
			return
		end

		pcall(function()
			RS.Assets.Weapons.Karambit.Camera.ViewmodelLight.Transparency = 1
		end)

		section(skinPage, "Скины ножей")
		buildSkinDropdowns(skinPage, KNIVES)

		section(skinPage, "Перчатки")
		buildSkinDropdowns(skinPage, GLOVES)

		section(skinPage, "CT оружие")
		buildSkinDropdowns(skinPage, CT_ONLY)

		section(skinPage, "T / общее оружие")
		buildSkinDropdowns(skinPage, SHARED)

		local rest = {}
		for _, folder in ipairs(SkinsFolder:GetChildren()) do
			local n = folder.Name
			if not IgnoreFolders[n] and not KNIVES[n] and not GLOVES[n] and not CT_ONLY[n] and not SHARED[n] then
				rest[n] = true
			end
		end
		if next(rest) then
			section(skinPage, "Остальное")
			buildSkinDropdowns(skinPage, rest)
		end
	end)

	local camera = getCamera()
	if camera then
		bind(camera.ChildAdded, function(obj)
			if not SkinChangerEnabled or not isAlive() then return end
			task.wait(0.1)
			applyWeaponSkin(obj)
		end)
	end
	bind(workspace:GetPropertyChangedSignal("CurrentCamera"), function()
		local cam = getCamera()
		if cam then
			bind(cam.ChildAdded, function(obj)
				if not SkinChangerEnabled or not isAlive() then return end
				task.wait(0.1)
				applyWeaponSkin(obj)
			end)
		end
	end)

	task.spawn(function()
		while screen.Parent do
			task.wait(0.5)
			if SkinChangerEnabled and isAlive() then
				local cam = getCamera()
				if cam then
					for _, obj in ipairs(cam:GetChildren()) do
						if SelectedSkins[obj.Name] and obj:GetAttribute("SkinApplied") ~= SelectedSkins[obj.Name] then
							applyWeaponSkin(obj)
						end
					end
				end
			end
		end
	end)
end

---------------------------------------------------------------------------
-- Вкладка Visuals (только FOV)
---------------------------------------------------------------------------
local Fov = { Enabled = false, Value = 90, Original = nil }

do
	section(visualPage, "Камера")
	makeToggle(visualPage, "Включить FOV", false, function(v)
		Fov.Enabled = v
		local camera = getCamera()
		if v and camera then
			Fov.Original = camera.FieldOfView
		elseif camera and Fov.Original then
			camera.FieldOfView = Fov.Original
		end
	end)
	makeSlider(visualPage, "Значение FOV", 60, 130, 90, "", function(v) Fov.Value = v end)

	bind(RunService.RenderStepped, function()
		local camera = getCamera()
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
		local classes = RS:FindFirstChild("Classes")
		local movement = RS:FindFirstChild("MovementV2")
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
	hint(movePage, "Auto — прыгает сам при касании земли.\nHold — только пока зажата кнопка прыжка.\nJump на колесо и стрейфы A/D держат скорость.", 64)
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
	pcall(removeViewmodel)
	local camera = getCamera()
	if camera and Fov.Original then camera.FieldOfView = Fov.Original end
	for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
	screen:Destroy()
	if env.KittenScript == gui then env.KittenScript = nil end
end
env.KittenScript = gui

switchTab("Skins")
notify("KittenScript", "Загружено. RightShift — меню.")
