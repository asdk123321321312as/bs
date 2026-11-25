--[[  KittenScript for Blox Strike
      Camera FOV · Auto BunnyHop · SkinChanger
      Toggle menu: RightShift
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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

local visualPage = addTab("Visuals", "◈")
local movePage = addTab("Movement", "⇅")
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
			local b = create("TextButton", {
				Size = UDim2.new(1, 0, 0, 27),
				BackgroundColor3 = option == value and C.Panel or C.Element,
				AutoButtonColor = false,
				Font = Enum.Font.Gotham,
				TextSize = 11,
				TextColor3 = option == value and C.AccentDeep or C.Text,
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = "   " .. option,
				ZIndex = 61,
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
	end)

	return {
		Set = function(v)
			if type(v) ~= "string" then v = tostring(v) end
			value = v
			label.Text = v
		end,
		Get = function() return value end,
		Close = close,
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
	makeDropdown(movePage, "Режим", { "Auto", "Hold" }, "Auto", function(v) Bhop.Mode = v end)

	section(movePage, "Инфо")
	makeLabel(movePage, "Auto — прыгает сам при касании земли.\nHold — только пока зажата кнопка прыжка.\nJump на колесо и стрейфы A/D держат скорость.")
end

---------------------------------------------------------------------------
-- Вкладка Skins — скинченджер
---------------------------------------------------------------------------
local Skins = {
	Root = nil,
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
				list[#list + 1] = skinFolder.Name
			end
			table.sort(list)
			Skins.Selections[weaponFolder.Name] = (#list > 0) and list or { "Default" }
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
	if sel and sel ~= "Default" then
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
	if not selection or selection == "Default" then return end
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
	if not selection or selection == "Default" then return end
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

		local function knifeSubstitute()
			if not Skins.KnifeEnabled then return nil end
			return Skins.KnifeModel, Skins.Selections[Skins.KnifeModel] or "Vanilla"
		end

		local originalGetCameraModel = skinLib.GetCameraModel
		Skins.Originals.GetCameraModel = originalGetCameraModel
		skinLib.GetCameraModel = function(w, sk, ...)
			if Skins.KnifeEnabled and w and isBaseKnife(w) then
				local newKnife, newSkin = knifeSubstitute()
				local ok, result = pcall(originalGetCameraModel, newKnife, newSkin, ...)
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
				local newKnife, newSkin = knifeSubstitute()
				local ok, result = pcall(originalGetCharacterModel, newKnife, newSkin, ...)
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
				local newKnife, newSkin = knifeSubstitute()
				local ok, result = pcall(originalViewmodelNew, viewmodelClass, newKnife, newSkin, ...)
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
					local selection = Skins.Gloves[model] or "Default"
					local ok, result = pcall(originalGetGloves, model, selection)
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
-- UI скинченджера
---------------------------------------------------------------------------
local skinHandles, knifeHandles, gloveHandles = {}, {}, {}

do
	section(skinPage, "Скины оружия")

	if not Skins.Root then
		makeLabel(skinPage, "ReplicatedStorage.Assets.Skins не найден — скинченджер не активен.")
	else
		makeToggle(skinPage, "Включить скины оружия", false, function(v)
			Skins.Enabled = v
			if v then
				task.spawn(ApplySkin)
				notify("Skins", "Скины оружия включены")
			end
		end)

		local weaponNames = {}
		for weapon in pairs(Skins.Selections) do
			if not table.find(KNIFE_MODELS, weapon) and not table.find(EXTRA_GLOVES, weapon) then
				weaponNames[#weaponNames + 1] = weapon
			end
		end
		table.sort(weaponNames)

		for _, weapon in ipairs(weaponNames) do
			local list = Skins.Selections[weapon]
			Skins.Selections[weapon] = list[1]
			skinHandles[weapon] = makeDropdown(skinPage, weapon, list, list[1], function(v)
				Skins.Selections[weapon] = v
			end)
		end
	end

	section(skinPage, "Ножи")

	if Skins.Supported then
		makeToggle(skinPage, "Включить смену ножей", false, function(v)
			Skins.KnifeEnabled = v
			UpdateInventoryNames()
			if v then notify("Skins", "Смена ножей включена") end
		end)
		makeDropdown(skinPage, "Модель ножа", KNIFE_MODELS, Skins.KnifeModel, function(v)
			Skins.KnifeModel = v
			UpdateInventoryNames()
		end)
		for _, knife in ipairs(KNIFE_MODELS) do
			local list = Skins.Selections[knife]
			if list then
				Skins.Selections[knife] = list[1]
				knifeHandles[knife] = makeDropdown(skinPage, "Скин: " .. knife, list, list[1], function(v)
					Skins.Selections[knife] = v
				end)
			end
		end
	else
		makeLabel(skinPage, "Смена ножей недоступна на этом экзекьюторе (нужен hookfunction).")
	end

	section(skinPage, "Перчатки")

	if #Skins.GloveFolders > 0 then
		local gloveModels = {}
		for _, folder in ipairs(Skins.GloveFolders) do
			local list = { "Default" }
			for _, skin in ipairs(folder:GetChildren()) do
				list[#list + 1] = skin.Name
			end
			Skins.GloveSelections[folder.Name] = list
			Skins.Gloves[folder.Name] = "Default"
			gloveModels[#gloveModels + 1] = folder.Name
		end
		table.sort(gloveModels)
		Skins.GloveModel = gloveModels[1]

		makeToggle(skinPage, "Включить смену перчаток", false, function(v)
			Skins.GloveEnabled = v
			if v then
				task.spawn(ApplyGloves)
				notify("Skins", "Смена перчаток включена")
			end
		end)
		makeDropdown(skinPage, "Модель перчаток", gloveModels, gloveModels[1], function(v)
			Skins.GloveModel = v
		end)
		for _, glove in ipairs(gloveModels) do
			local list = Skins.GloveSelections[glove]
			gloveHandles[glove] = makeDropdown(skinPage, "Скин: " .. glove, list, list[1], function(v)
				Skins.Gloves[glove] = v
			end)
		end
	else
		makeLabel(skinPage, "Папки перчаток не найдены.")
	end

	section(skinPage, "Конфиг")

	makeButton(skinPage, "Force Apply Now", function()
		pcall(ApplySkin)
		pcall(ApplyGloves)
		notify("Skins", "Скины применены принудительно")
	end)

	makeButton(skinPage, "Reset All Skins", function()
		for weapon, list in pairs(Skins.Selections) do
			local first = (type(list) == "table") and list[1] or list
			if first then
				Skins.Selections[weapon] = first
				local handle = skinHandles[weapon] or knifeHandles[weapon]
				if handle then pcall(function() handle:Set(first) end) end
			end
		end
		for glove, list in pairs(Skins.GloveSelections) do
			Skins.Gloves[glove] = "Default"
			local handle = gloveHandles[glove]
			if handle then pcall(function() handle:Set("Default") end) end
			pcall(function() handle:Set(list[1] or "Default") end)
		end
		pcall(ApplySkin)
		pcall(ApplyGloves)
		notify("Skins", "Все скины сброшены")
	end)

	makeLabel(skinPage, "Скины накатываются на текущий вьюмодель каждые 0.5 с. Ножи подменяются на уровне модуля Viewmodel, поэтому чужая модель видна сразу после перезахода в бой.")
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

---------------------------------------------------------------------------
-- Unload
---------------------------------------------------------------------------
function gui:Unload()
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
	local camera = workspace.CurrentCamera
	if camera and Fov.Original then camera.FieldOfView = Fov.Original end
	for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
	screen:Destroy()
	if env.KittenScript == gui then env.KittenScript = nil end
end
env.KittenScript = gui

switchTab("Visuals")
notify("KittenScript", "Загружено. RightShift — меню.")
