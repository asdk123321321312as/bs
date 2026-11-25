--[[  KittenScript for Blox Strike
      SkinChanger (ножи / перчатки / оружие) · Camera FOV · Auto BunnyHop
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

---------------------------------------------------------------------------
-- Палитра: мягкий фиолетовый
---------------------------------------------------------------------------
local C = {
	BgTop      = Color3.fromRGB(219, 200, 255),
	BgBottom   = Color3.fromRGB(184, 158, 240),
	Panel      = Color3.fromRGB(233, 221, 255),
	Element    = Color3.fromRGB(243, 235, 255),
	Hover      = Color3.fromRGB(255, 255, 255),
	Stroke     = Color3.fromRGB(150, 116, 222),
	Accent     = Color3.fromRGB(123, 77, 224),
	AccentSoft = Color3.fromRGB(168, 132, 245),
	Text       = Color3.fromRGB(52, 34, 82),
	Dim        = Color3.fromRGB(108, 84, 148),
	Off        = Color3.fromRGB(199, 183, 231),
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

local function tween(obj, time, props, style)
	local t = TweenService:Create(obj, TweenInfo.new(time, style or Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

local function corner(obj, r)
	create("UICorner", { CornerRadius = UDim.new(0, r or 8) }, obj)
end

local function stroke(obj, color, thickness, trans)
	return create("UIStroke", {
		Color = color or C.Stroke,
		Thickness = thickness or 1,
		Transparency = trans or 0.45,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, obj)
end

local function chevron(parent, color)
	local holder = create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(11, 7),
		BackgroundTransparency = 1,
	}, parent)
	create("Frame", {
		Size = UDim2.fromOffset(6, 1.7),
		Position = UDim2.fromOffset(0, 3),
		Rotation = 40,
		BackgroundColor3 = color or C.Accent,
		BorderSizePixel = 0,
	}, holder)
	create("Frame", {
		Size = UDim2.fromOffset(6, 1.7),
		Position = UDim2.fromOffset(5, 3),
		Rotation = -40,
		BackgroundColor3 = color or C.Accent,
		BorderSizePixel = 0,
	}, holder)
end

---------------------------------------------------------------------------
-- Root
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
	Position = UDim2.new(1, -18, 0, 18),
	Size = UDim2.fromOffset(264, 10),
	BackgroundTransparency = 1,
}, screen)
create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, notifyHolder)

local function notify(titleText, body)
	local card = create("Frame", {
		Size = UDim2.new(1, 0, 0, 56),
		BackgroundColor3 = C.Panel,
		BackgroundTransparency = 0.05,
	}, notifyHolder)
	corner(card, 10)
	stroke(card, C.Accent, 1, 0.4)
	create("Frame", {
		Size = UDim2.new(0, 3, 1, -16),
		Position = UDim2.fromOffset(0, 8),
		BackgroundColor3 = C.Accent,
		BorderSizePixel = 0,
	}, card)
	create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 8),
		Size = UDim2.new(1, -22, 0, 16),
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = C.Accent,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = titleText,
	}, card)
	local bodyLabel = create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 26),
		Size = UDim2.new(1, -22, 0, 24),
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextColor3 = C.Dim,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Text = body,
	}, card)
	task.delay(4, function()
		pcall(function()
			tween(card, 0.25, { BackgroundTransparency = 1 })
			tween(bodyLabel, 0.25, { TextTransparency = 1 })
			task.wait(0.3)
			card:Destroy()
		end)
	end)
end

---------------------------------------------------------------------------
-- Мини-кнопка
---------------------------------------------------------------------------
local mini = create("TextButton", {
	Size = UDim2.fromOffset(122, 32),
	Position = UDim2.new(0, 18, 0, 18),
	BackgroundColor3 = C.Panel,
	AutoButtonColor = false,
	Text = "",
	Visible = false,
}, screen)
corner(mini, 16)
stroke(mini, C.Accent, 1, 0.4)
create("TextLabel", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	TextSize = 13,
	TextColor3 = C.Accent,
	Text = "Kitten",
}, mini)
create("Frame", {
	Size = UDim2.new(0, 4, 1, -12),
	Position = UDim2.fromOffset(0, 6),
	BackgroundColor3 = C.Accent,
	BorderSizePixel = 0,
}, mini)

---------------------------------------------------------------------------
-- Окно
---------------------------------------------------------------------------
local main = create("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(600, 420),
	BackgroundColor3 = C.BgTop,
	BorderSizePixel = 0,
	ClipsDescendants = true,
}, screen)
corner(main, 14)
stroke(main, C.Stroke, 1, 0.15)
create("UIGradient", {
	Rotation = 90,
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, C.BgTop),
		ColorSequenceKeypoint.new(1, C.BgBottom),
	}),
}, main)

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

local title = create("TextLabel", {
	Position = UDim2.fromOffset(20, 10),
	Size = UDim2.new(0, 260, 0, 24),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBlack,
	TextSize = 18,
	TextColor3 = C.Text,
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "KittenScript",
}, header)

create("TextLabel", {
	Position = UDim2.fromOffset(21, 34),
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
	Position = UDim2.new(1, -16, 0.5, 0),
	Size = UDim2.fromOffset(28, 28),
	BackgroundColor3 = C.Element,
	AutoButtonColor = false,
	Text = "",
}, header)
corner(closeButton, 8)
create("Frame", { Size = UDim2.fromOffset(10, 1.7), Position = UDim2.fromOffset(9, 13), Rotation = 45, BackgroundColor3 = C.Text, BorderSizePixel = 0 }, closeButton)
create("Frame", { Size = UDim2.fromOffset(10, 1.7), Position = UDim2.fromOffset(9, 13), Rotation = -45, BackgroundColor3 = C.Text, BorderSizePixel = 0 }, closeButton)

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
	Position = UDim2.fromOffset(16, 68),
	Size = UDim2.new(0, 152, 1, -84),
	BackgroundColor3 = C.Panel,
	BackgroundTransparency = 0.15,
	BorderSizePixel = 0,
}, main)
corner(sidebar, 10)
stroke(sidebar, C.Stroke, 1, 0.6)
create("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }, sidebar)
create("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, sidebar)

local content = create("Frame", {
	Position = UDim2.fromOffset(184, 68),
	Size = UDim2.new(1, -200, 1, -84),
	BackgroundTransparency = 1,
	ClipsDescendants = true,
}, main)

local Tabs, TabOrder, CurrentTab = {}, {}, nil
local openPopups = {}

local function closeAllPopups()
	for _, popup in ipairs(table.clone(openPopups)) do
		pcall(function() popup:Destroy() end)
	end
	table.clear(openPopups)
end

local function switchTab(name)
	if CurrentTab == name then return end
	closeAllPopups()
	CurrentTab = name
	for tabName, data in pairs(Tabs) do
		local active = tabName == name
		tween(data.Button, 0.18, { BackgroundColor3 = active and C.Hover or C.Panel })
		tween(data.Bar, 0.18, { BackgroundTransparency = active and 0 or 1 })
		tween(data.Label, 0.18, { TextColor3 = active and C.Accent or C.Dim })
		if active then
			data.Group.Visible = true
			data.Group.Position = UDim2.fromOffset(12, 0)
			tween(data.Group, 0.2, { Position = UDim2.fromOffset(0, 0) })
		else
			tween(data.Group, 0.14, { Position = UDim2.fromOffset(12, 0) })
			task.delay(0.15, function()
				if CurrentTab ~= tabName then data.Group.Visible = false end
			end)
		end
	end
end

local function addTab(name)
	local btn = create("TextButton", {
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = C.Panel,
		BackgroundTransparency = 0.15,
		AutoButtonColor = false,
		Text = "",
	}, sidebar)
	btn.LayoutOrder = #TabOrder + 1
	table.insert(TabOrder, btn)

	local bar = create("Frame", {
		Size = UDim2.new(0, 3, 1, -16),
		Position = UDim2.fromOffset(0, 8),
		BackgroundColor3 = C.Accent,
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
	}, btn)
	corner(bar, 2)

	local label = create("TextLabel", {
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -20, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextColor3 = C.Dim,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = name,
	}, btn)

	local group = create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
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
	create("UIListLayout", { Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder }, scroll)
	create("UIPadding", { PaddingRight = UDim.new(0, 14), PaddingBottom = UDim.new(0, 14) }, scroll)

	btn.MouseButton1Click:Connect(function() switchTab(name) end)
	btn.MouseEnter:Connect(function()
		if CurrentTab ~= name then tween(btn, 0.15, { BackgroundColor3 = C.Hover, BackgroundTransparency = 0 }) end
	end)
	btn.MouseLeave:Connect(function()
		if CurrentTab ~= name then tween(btn, 0.15, { BackgroundColor3 = C.Panel, BackgroundTransparency = 0.15 }) end
	end)

	Tabs[name] = { Button = btn, Bar = bar, Label = label, Group = group, Scroll = scroll }
	return scroll
end

local skinPage = addTab("Skins")
local visualPage = addTab("Visuals")
local movePage = addTab("Movement")

---------------------------------------------------------------------------
-- Элементы
---------------------------------------------------------------------------
local function section(parent, text)
	return create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		TextColor3 = C.Accent,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = string.upper(text),
	}, parent)
end

local function row(parent, height)
	local r = create("Frame", {
		Size = UDim2.new(1, 0, 0, height or 36),
		BackgroundColor3 = C.Element,
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
	}, parent)
	corner(r, 8)
	stroke(r, C.Stroke, 1, 0.75)
	return r
end

local function makeToggle(parent, text, default, callback)
	local r = row(parent, 36)
	local label = create("TextLabel", {
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -68, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		TextColor3 = C.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = text,
	}, r)
	local pill = create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(38, 20),
		BackgroundColor3 = default and C.Accent or C.Off,
		BorderSizePixel = 0,
	}, r)
	corner(pill, 10)
	local knob = create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = default and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
		Size = UDim2.fromOffset(16, 16),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
	}, pill)
	corner(knob, 8)

	local state = default
	local function paint()
		tween(pill, 0.16, { BackgroundColor3 = state and C.Accent or C.Off })
		tween(knob, 0.16, {
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
	local r = row(parent, 48)
	create("TextLabel", {
		Position = UDim2.fromOffset(12, 7),
		Size = UDim2.new(1, -70, 0, 16),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		TextColor3 = C.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = text,
	}, r)
	local valueLabel = create("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 7, 0),
		Size = UDim2.fromOffset(64, 16),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = C.Accent,
		TextXAlignment = Enum.TextXAlignment.Right,
		Text = tostring(default) .. (suffix or ""),
	}, r)

	local track = create("Frame", {
		Position = UDim2.fromOffset(12, 34),
		Size = UDim2.new(1, -24, 0, 5),
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
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
	}, track)
	corner(knob, 6)
	stroke(knob, C.Accent, 1.5, 0.2)

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

local function makeButton(parent, text, callback)
	local b = create("TextButton", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = C.Element,
		BackgroundTransparency = 0.1,
		AutoButtonColor = false,
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		TextColor3 = C.Text,
		Text = text,
	}, parent)
	corner(b, 8)
	stroke(b, C.Stroke, 1, 0.75)
	b.MouseEnter:Connect(function() tween(b, 0.15, { BackgroundColor3 = C.Hover, TextColor3 = C.Accent }) end)
	b.MouseLeave:Connect(function() tween(b, 0.15, { BackgroundColor3 = C.Element, TextColor3 = C.Text }) end)
	b.MouseButton1Click:Connect(callback)
	return b
end

local function makeDropdown(parent, text, options, default, searchable, callback)
	local r = row(parent, 36)
	local label = create("TextLabel", {
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -40, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		TextColor3 = C.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = text,
	}, r)
	chevron(r)
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
					Size = UDim2.new(1, 0, 0, 26),
					BackgroundColor3 = option == value and C.Hover or C.Element,
					AutoButtonColor = false,
					Font = Enum.Font.Gotham,
					TextSize = 11,
					TextColor3 = option == value and C.Accent or C.Text,
					TextXAlignment = Enum.TextXAlignment.Left,
					Text = "   " .. option,
				}, list)
				b.MouseEnter:Connect(function() tween(b, 0.1, { BackgroundColor3 = C.Hover }) end)
				b.MouseLeave:Connect(function()
					tween(b, 0.1, { BackgroundColor3 = option == value and C.Hover or C.Element })
				end)
				b.MouseButton1Click:Connect(function()
					value = option
					label.Text = option
					callback(option)
					close()
				end)
			end
		end
		list.CanvasSize = UDim2.new(0, 0, 0, count * 28 + 6)
	end

	clickable.MouseButton1Click:Connect(function()
		if open then close() return end
		closeAllPopups()
		if #options == 0 then
			notify("Пусто", "Список пока пуст — подожди загрузку игры")
			return
		end
		open = true
		local pos = r.AbsolutePosition - main.AbsolutePosition
		local width = math.max(190, r.AbsoluteSize.X)
		local x = math.clamp(pos.X, 8, math.max(8, main.AbsoluteSize.X - width - 8))
		popup = create("Frame", {
			Position = UDim2.fromOffset(x, pos.Y + r.AbsoluteSize.Y + 4),
			Size = UDim2.fromOffset(width, searchable and 200 or 180),
			BackgroundColor3 = C.Panel,
			ZIndex = 60,
		}, main)
		corner(popup, 8)
		stroke(popup, C.Stroke, 1, 0.2)
		table.insert(openPopups, popup)

		if searchable then
			search = create("TextBox", {
				Position = UDim2.fromOffset(6, 6),
				Size = UDim2.new(1, -12, 0, 26),
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
			corner(search, 6)
			search:GetPropertyChangedSignal("Text"):Connect(function() build(search.Text) end)
		end

		list = create("ScrollingFrame", {
			Position = UDim2.fromOffset(6, searchable and 36 or 6),
			Size = UDim2.new(1, -12, 1, searchable and -42 or -12),
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
		Set = function(v) value = v label.Text = v end,
		Get = function() return value end,
		SetOptions = function(newOptions)
			options = newOptions
			if open then build(search and search.Text or "") end
		end,
		Close = close,
	}
end

---------------------------------------------------------------------------
-- Ассеты
---------------------------------------------------------------------------
local Assets, Skins, WeaponAssets, Sleeves, WeaponAnims
local function refreshAssets()
	Assets = ReplicatedStorage:FindFirstChild("Assets")
	Skins = Assets and Assets:FindFirstChild("Skins")
	WeaponAssets = Assets and Assets:FindFirstChild("Weapons")
	Sleeves = Assets and Assets:FindFirstChild("Sleeves")
	WeaponAnims = Assets and Assets:FindFirstChild("WeaponAnimations")
end
refreshAssets()
task.spawn(function()
	for _ = 1, 90 do
		if Skins and WeaponAssets then return end
		refreshAssets()
		task.wait(1)
	end
end)

local skinRecords = setmetatable({}, { __mode = "k" })
local IGNORE = {
	["HE Grenade"] = true, ["Incendiary Grenade"] = true, ["Molotov"] = true,
	["Smoke Grenade"] = true, ["Flashbang"] = true, ["Decoy Grenade"] = true,
	["C4"] = true, ["CT Glove"] = true, ["T Glove"] = true, ["Sports Gloves"] = true,
}
local KnifeOffsets = {
	["Karambit"] = CFrame.new(0, -1.5, 1.5),
	["Butterfly Knife"] = CFrame.new(0, -1.5, 1.5),
	["M9 Bayonet"] = CFrame.new(0, -1.5, 1),
	["Flip Knife"] = CFrame.new(0, -1.5, 1.25),
	["Gut Knife"] = CFrame.new(0, -1.5, 0.5),
}
local wearList = { "Factory New", "Minimal Wear", "Field-Tested", "Well-Worn", "Battle-Scarred" }

local function restorePart(part)
	local rec = skinRecords[part]
	if not rec then return end
	skinRecords[part] = nil
	if rec.Applied and rec.Applied.Parent == part then rec.Applied:Destroy() end
	for _, original in ipairs(rec.Originals) do
		if part.Parent then original.Parent = part end
	end
end

local function restoreAllSkins()
	for part in pairs(skinRecords) do restorePart(part) end
end

local function paintModel(model, weapon, skinName, wear)
	if not Skins then return false end
	local weaponFolder = Skins:FindFirstChild(weapon)
	local skinFolder = weaponFolder and weaponFolder:FindFirstChild(skinName)
	local cameraFolder = skinFolder and skinFolder:FindFirstChild("Camera")
	local source = cameraFolder and cameraFolder:FindFirstChild(wear or "Factory New")
	if not source then return false end

	local target = model:FindFirstChild("Weapon") or model
	local key = weapon .. "|" .. skinName .. "|" .. tostring(wear)
	local painted = 0

	for _, part in ipairs(target:GetDescendants()) do
		if part:IsA("BasePart") then
			local paint = source:FindFirstChild(part.Name)
			local surface = paint and paint:FindFirstChildOfClass("SurfaceAppearance")
			if surface then
				local rec = skinRecords[part]
				if not (rec and rec.Key == key) then
					restorePart(part)
					local originals = {}
					for _, child in ipairs(part:GetChildren()) do
						if child:IsA("SurfaceAppearance") then
							table.insert(originals, child)
							child.Parent = nil
						end
					end
					local clone = surface:Clone()
					clone.Parent = part
					skinRecords[part] = { Key = key, Originals = originals, Applied = clone }
				end
				painted += 1
			end
		end
	end
	return painted > 0
end

local function paintGloves(model, skinName, wear)
	if not Skins then return end
	local folder = Skins:FindFirstChild("Sports Gloves")
	local skin = folder and folder:FindFirstChild(skinName)
	local cameraFolder = skin and skin:FindFirstChild("Camera")
	local source = cameraFolder and cameraFolder:FindFirstChild(wear or "Factory New")
	if not source then return end
	for _, side in ipairs({ "Left Arm", "Right Arm" }) do
		local arm = model:FindFirstChild(side)
		local glove = arm and arm:FindFirstChild("Glove")
		local paint = source:FindFirstChild(side)
		local surface = paint and paint:FindFirstChildOfClass("SurfaceAppearance")
		if glove and surface then
			local key = "glove|" .. skinName .. "|" .. tostring(wear)
			local rec = skinRecords[glove]
			if not (rec and rec.Key == key) then
				restorePart(glove)
				local originals = {}
				for _, child in ipairs(glove:GetChildren()) do
					if child:IsA("SurfaceAppearance") then
						table.insert(originals, child)
						child.Parent = nil
					end
				end
				local clone = surface:Clone()
				clone.Parent = glove
				skinRecords[glove] = { Key = key, Originals = originals, Applied = clone }
			end
		end
	end
end

---------------------------------------------------------------------------
-- Кастомный нож
---------------------------------------------------------------------------
local Knife = {
	Enabled = false,
	Model = "Butterfly Knife",
	Skin = nil,
	Wear = "Factory New",
	VM = nil,
	Idle = nil,
	Hidden = {},
	GloveSkin = nil,
	GloveWear = "Factory New",
}

local function isAlive()
	local chars = workspace:FindFirstChild("Characters")
	local t = chars and chars:FindFirstChild("Terrorists")
	local ct = chars and chars:FindFirstChild("Counter-Terrorists")
	return (t and t:FindFirstChild(LocalPlayer.Name)) or (ct and ct:FindFirstChild(LocalPlayer.Name))
end

local function cleanPart(part)
	if not part:IsA("BasePart") then return end
	part.CanCollide = false
	part.Anchored = false
	part.CastShadow = false
	part.CanTouch = false
	part.CanQuery = false
end

local function hideOriginalKnife()
	table.clear(Knife.Hidden)
	local camera = workspace.CurrentCamera
	if not camera then return end
	for _, name in ipairs({ "T Knife", "CT Knife" }) do
		local model = camera:FindFirstChild(name)
		if model then
			for _, part in ipairs(model:GetDescendants()) do
				if part:IsA("BasePart") or part:IsA("Texture") then
					Knife.Hidden[part] = part.Transparency
					part.Transparency = 1
				end
			end
		end
	end
end

local function restoreOriginalKnife()
	for part, transparency in pairs(Knife.Hidden) do
		if part.Parent then part.Transparency = transparency end
	end
	table.clear(Knife.Hidden)
end

local function attachGlove(arm, asset, name, offset)
	local mesh = asset:Clone()
	cleanPart(mesh)
	mesh.Name = name
	mesh.Parent = arm
	create("Motor6D", { Part0 = arm, Part1 = mesh, C0 = offset }, arm)
end

local function removeKnife()
	if Knife.VM then pcall(function() Knife.VM:Destroy() end) end
	Knife.VM, Knife.Idle = nil, nil
	restoreOriginalKnife()
	restoreAllSkins()
end

local function spawnKnife()
	if Knife.VM or not Knife.Enabled then return end
	local camera = workspace.CurrentCamera
	local template = WeaponAssets and WeaponAssets:FindFirstChild(Knife.Model)
	local cameraModel = template and template:FindFirstChild("Camera")
	if not camera or not cameraModel then
		notify("Нож", "Модель " .. tostring(Knife.Model) .. " недоступна")
		return
	end

	local model = cameraModel:Clone()
	model.Name = "KittenKnife"
	Knife.VM = model
	for _, part in ipairs(model:GetDescendants()) do cleanPart(part) end
	model.Parent = camera
	hideOriginalKnife()

	local character = isAlive()
	local isT = character and character.Parent and character.Parent.Name == "Terrorists"
	if isT then
		local gloves = WeaponAssets:FindFirstChild("T Glove")
		if gloves then
			for _, side in ipairs({ "Left Arm", "Right Arm" }) do
				local arm = model:FindFirstChild(side)
				local asset = gloves:FindFirstChild(side)
				if arm and asset then pcall(attachGlove, arm, asset, "Glove", CFrame.new(0, 0, -1.5)) end
			end
		end
	else
		local sleeveFolder = Sleeves and Sleeves:FindFirstChild("IDF")
		local gloves = WeaponAssets:FindFirstChild("CT Glove")
		for _, side in ipairs({ "Left Arm", "Right Arm" }) do
			local arm = model:FindFirstChild(side)
			if arm then
				local sleeve = sleeveFolder and sleeveFolder:FindFirstChild(side)
				if sleeve then pcall(attachGlove, arm, sleeve, "Sleeve", CFrame.new(0, 0, 0.5)) end
				local asset = gloves and gloves:FindFirstChild(side)
				if asset then pcall(attachGlove, arm, asset, "Glove", CFrame.new(0, 0, -1.5)) end
			end
		end
	end

	-- анимация покоя
	local controller = model:FindFirstChildOfClass("AnimationController") or model:FindFirstChildOfClass("Animator")
	local animator = controller and (controller:FindFirstChildWhichIsA("Animator") or controller)
	local animFolder = WeaponAnims and WeaponAnims:FindFirstChild(Knife.Model)
	animFolder = animFolder and animFolder:FindFirstChild("CameraAnimations")
	local idle = animFolder and animFolder:FindFirstChild("Idle")
	if animator and idle then
		local ok, track = pcall(function() return animator:LoadAnimation(idle) end)
		if ok and track then
			track.Looped = true
			track:Play()
			Knife.Idle = track
		end
	end

	local offset = KnifeOffsets[Knife.Model] or CFrame.new(0, -1.5, 1.5)
	if model.PrimaryPart then
		model:SetPrimaryPartCFrame(camera.CFrame * CFrame.new(0, -1.5, 5))
		tween(model.PrimaryPart, 0.22, { CFrame = camera.CFrame * offset })
	end

	-- скин и перчатки на свежую модель
	if Knife.Skin then
		task.defer(function()
			if Knife.VM == model then pcall(paintModel, model, Knife.Model, Knife.Skin, Knife.Wear) end
		end)
	end
	if Knife.GloveSkin then
		task.defer(function()
			if Knife.VM == model then pcall(paintGloves, model, Knife.GloveSkin, Knife.GloveWear) end
		end)
	end
end

bind(RunService.RenderStepped, function()
	local vm = Knife.VM
	local camera = workspace.CurrentCamera
	if not vm or not camera or not vm.PrimaryPart then return end
	vm.PrimaryPart.CFrame = camera.CFrame * (KnifeOffsets[Knife.Model] or CFrame.new(0, -1.5, 1.5))
	if Knife.Idle and not Knife.Idle.IsPlaying then Knife.Idle:Play() end
end)

task.spawn(function()
	while screen.Parent do
		task.wait(0.2)
		local alive = isAlive() ~= nil
		local hasKnife = (function()
			local camera = workspace.CurrentCamera
			return camera and (camera:FindFirstChild("T Knife") or camera:FindFirstChild("CT Knife")) ~= nil
		end)()
		if Knife.Enabled and alive and hasKnife and not Knife.VM then
			pcall(spawnKnife)
		elseif (not Knife.Enabled or not alive or not hasKnife) and Knife.VM then
			pcall(removeKnife)
		end
	end
end)

---------------------------------------------------------------------------
-- Вкладка Skins
---------------------------------------------------------------------------
local knifeSkinDropdown, weaponSkinDropdown
local weaponLoadout = {}
local weaponWear = "Factory New"

local function paintAllWeapons()
	local camera = workspace.CurrentCamera
	if not camera then return end
	for _, model in ipairs(camera:GetChildren()) do
		if model:IsA("Model") and model ~= Knife.VM and weaponLoadout[model.Name] then
			local sel = weaponLoadout[model.Name]
			pcall(paintModel, model, model.Name, sel.Skin, sel.Wear)
		end
	end
end

local function refreshWeapon()
	restoreAllSkins()
	paintAllWeapons()
	if Knife.VM then
		if Knife.Skin then pcall(paintModel, Knife.VM, Knife.Model, Knife.Skin, Knife.Wear) end
		if Knife.GloveSkin then pcall(paintGloves, Knife.VM, Knife.GloveSkin, Knife.GloveWear) end
	end
end

local function skinsOf(folderName)
	local out = {}
	local folder = Skins and Skins:FindFirstChild(folderName)
	if folder then
		for _, child in ipairs(folder:GetChildren()) do
			if child:IsA("Folder") and child:FindFirstChild("Camera") then table.insert(out, child.Name) end
		end
	end
	table.sort(out)
	return out
end

do
	section(skinPage, "Нож")
	makeToggle(skinPage, "Применить выбранный нож", false, function(v)
		Knife.Enabled = v
		if v then pcall(spawnKnife) else pcall(removeKnife) end
	end)

	local knifeModels = {}
	if WeaponAssets then
		for _, folder in ipairs(WeaponAssets:GetChildren()) do
			if folder:IsA("Folder") and folder:FindFirstChild("Camera") and not IGNORE[folder.Name] then
				table.insert(knifeModels, folder.Name)
			end
		end
	end
	table.sort(knifeModels)

	makeDropdown(skinPage, "Модель ножа", knifeModels, knifeModels[1] or "—", false, function(name)
		Knife.Model = name
		local list = skinsOf(name)
		knifeSkinDropdown:SetOptions(list)
		knifeSkinDropdown:Set(list[1] or "—")
		Knife.Skin = list[1]
		restoreAllSkins()
		if Knife.VM then
			pcall(removeKnife)
			task.wait(0.05)
			pcall(spawnKnife)
		end
	end)

	knifeSkinDropdown = makeDropdown(skinPage, "Скин ножа", {}, "—", true, function(skin)
		Knife.Skin = skin
		if Knife.VM then pcall(paintModel, Knife.VM, Knife.Model, skin, Knife.Wear) end
	end)
	makeDropdown(skinPage, "Износ ножа", wearList, "Factory New", false, function(wear)
		Knife.Wear = wear
		if Knife.VM and Knife.Skin then pcall(paintModel, Knife.VM, Knife.Model, Knife.Skin, wear) end
	end)

	section(skinPage, "Перчатки")
	makeDropdown(skinPage, "Скин перчаток", skinsOf("Sports Gloves"), "—", true, function(skin)
		Knife.GloveSkin = skin
		if Knife.VM then pcall(paintGloves, Knife.VM, skin, Knife.GloveWear) end
	end)

	section(skinPage, "Оружие")
	local weaponList = {}
	if Skins then
		for _, folder in ipairs(Skins:GetChildren()) do
			if folder:IsA("Folder") and not IGNORE[folder.Name] and not KnifeOffsets[folder.Name] then
				local sample = folder:GetChildren()[1]
				if sample and sample:FindFirstChild("Camera") then table.insert(weaponList, folder.Name) end
			end
		end
	end
	table.sort(weaponList)

	local weaponDropdown = makeDropdown(skinPage, "Оружие", weaponList, weaponList[1] or "—", true, function(name)
		local list = skinsOf(name)
		weaponSkinDropdown:SetOptions(list)
		weaponSkinDropdown:Set(list[1] or "—")
		weaponLoadout[name] = { Skin = list[1], Wear = weaponWear }
		refreshWeapon()
	end)

	weaponSkinDropdown = makeDropdown(skinPage, "Скин оружия", {}, "—", true, function(skin)
		local name = weaponDropdown:Get()
		if not name then return end
		weaponLoadout[name] = { Skin = skin, Wear = weaponWear }
		refreshWeapon()
	end)
	makeDropdown(skinPage, "Износ оружия", wearList, "Factory New", false, function(wear)
		weaponWear = wear
		local name = weaponDropdown:Get()
		if name and weaponLoadout[name] then
			weaponLoadout[name].Wear = wear
			refreshWeapon()
		end
	end)

	section(skinPage, "Управление")
	makeButton(skinPage, "Взять оружие в руках", function()
		local camera = workspace.CurrentCamera
		if not camera then return end
		for _, model in ipairs(camera:GetChildren()) do
			if model:IsA("Model") and model ~= Knife.VM and model:FindFirstChild("Weapon") and not KnifeOffsets[model.Name] then
				local list = skinsOf(model.Name)
				if #list > 0 then
					weaponDropdown:Set(model.Name)
					weaponSkinDropdown:SetOptions(list)
					weaponSkinDropdown:Set(list[1])
					weaponLoadout[model.Name] = { Skin = list[1], Wear = weaponWear }
					refreshWeapon()
					return
				end
			end
		end
		notify("Оружие", "В руках нет оружия со скинами")
	end)
	makeButton(skinPage, "Сбросить все скины", function()
		table.clear(weaponLoadout)
		Knife.Skin = nil
		Knife.GloveSkin = nil
		refreshWeapon()
		notify("KittenScript", "Все скины сброшены")
	end)

	-- инициализация
	if knifeModels[1] then
		Knife.Model = knifeModels[1]
		local list = skinsOf(knifeModels[1])
		knifeSkinDropdown:SetOptions(list)
		knifeSkinDropdown:Set(list[1] or "—")
		Knife.Skin = list[1]
	end
	if weaponList[1] then
		local list = skinsOf(weaponList[1])
		weaponSkinDropdown:SetOptions(list)
		weaponSkinDropdown:Set(list[1] or "—")
		weaponLoadout[weaponList[1]] = { Skin = list[1], Wear = weaponWear }
	end

	-- авто-обновление списков, когда ассеты догрузились
	task.spawn(function()
		for _ = 1, 90 do
			if #knifeModels > 0 then break end
			refreshAssets()
			if WeaponAssets then
				table.clear(knifeModels)
				for _, folder in ipairs(WeaponAssets:GetChildren()) do
					if folder:IsA("Folder") and folder:FindFirstChild("Camera") and not IGNORE[folder.Name] then
						table.insert(knifeModels, folder.Name)
					end
				end
				table.sort(knifeModels)
				local dropdownRef = nil
				-- повторно заполнить дропдаун модели ножа
				for _, d in ipairs({}) do end
			end
			task.wait(1)
		end
	end)

	-- переприменение на новые вьюмодели
	local function onCameraChild(model)
		if not model:IsA("Model") then return end
		task.wait(0.12)
		if model == Knife.VM then
			if Knife.Skin then pcall(paintModel, model, Knife.Model, Knife.Skin, Knife.Wear) end
			if Knife.GloveSkin then pcall(paintGloves, model, Knife.GloveSkin, Knife.GloveWear) end
		elseif weaponLoadout[model.Name] then
			local sel = weaponLoadout[model.Name]
			pcall(paintModel, model, model.Name, sel.Skin, sel.Wear)
		end
	end
	if workspace.CurrentCamera then
		bind(workspace.CurrentCamera.ChildAdded, onCameraChild)
	end
	bind(workspace:GetPropertyChangedSignal("CurrentCamera"), function()
		local camera = workspace.CurrentCamera
		if camera then bind(camera.ChildAdded, onCameraChild) end
	end)
end

---------------------------------------------------------------------------
-- Вкладка Visuals
---------------------------------------------------------------------------
local Fov = { Enabled = false, Value = 90, Original = nil, Circle = false, CircleSize = 120 }
local fovCircle = nil

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

	section(visualPage, "Круг FOV")
	makeToggle(visualPage, "Показать круг", false, function(v)
		Fov.Circle = v
		if not v and fovCircle then
			pcall(function() fovCircle:Remove() end)
			fovCircle = nil
		end
	end)
	makeSlider(visualPage, "Радиус круга", 40, 400, 120, " px", function(v) Fov.CircleSize = v end)

	bind(RunService.RenderStepped, function()
		local camera = workspace.CurrentCamera
		if Fov.Enabled and camera and math.abs(camera.FieldOfView - Fov.Value) > 0.05 then
			camera.FieldOfView = Fov.Value
		end
		if Fov.Circle and Drawing then
			if not fovCircle then
				local ok, circle = pcall(function()
					local c = Drawing.new("Circle")
					c.Thickness = 1.5
					c.NumSides = 64
					c.Color = C.Accent
					c.Filled = false
					c.Transparency = 0.9
					return c
				end)
				if ok then fovCircle = circle end
			end
			if fovCircle then
				local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
				fovCircle.Position = viewport / 2
				fovCircle.Radius = Fov.CircleSize
				fovCircle.Visible = Fov.Enabled
			end
		elseif fovCircle then
			fovCircle.Visible = false
		end
	end)
end

---------------------------------------------------------------------------
-- Вкладка Movement (логика бхопа без изменений)
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
	section(movePage, "Подсказка")
	create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 62),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextColor3 = C.Dim,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "Auto — прыгает сам при касании земли.\nHold — только пока зажата кнопка прыжка.\nJump на колесо + стрейфы A/D удерживают скорость.",
	}, movePage)
end

---------------------------------------------------------------------------
-- Открытие / закрытие
---------------------------------------------------------------------------
local function setMenu(state)
	gui.Toggled = state
	if state then
		mini.Visible = false
		main.Visible = true
		main.Size = UDim2.fromOffset(580, 406)
		tween(main, 0.22, { Size = UDim2.fromOffset(600, 420) })
	else
		closeAllPopups()
		main.Visible = false
		mini.Visible = true
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
	pcall(removeKnife)
	restoreAllSkins()
	local camera = workspace.CurrentCamera
	if camera and Fov.Original then camera.FieldOfView = Fov.Original end
	if fovCircle then pcall(function() fovCircle:Remove() end) end
	for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
	screen:Destroy()
	if env.KittenScript == gui then env.KittenScript = nil end
end
env.KittenScript = gui

switchTab("Skins")
notify("KittenScript", "Загружено. RightShift — меню.")
