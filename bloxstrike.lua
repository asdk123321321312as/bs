--[[  KittenScript for Blox Strike
      SkinChanger / Camera FOV / Auto BunnyHop
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
-- Палитра
---------------------------------------------------------------------------
local C = {
	Bg         = Color3.fromRGB(8, 8, 10),
	Panel      = Color3.fromRGB(14, 14, 18),
	Element    = Color3.fromRGB(20, 20, 26),
	Hover      = Color3.fromRGB(28, 27, 37),
	Stroke     = Color3.fromRGB(42, 35, 58),
	Accent     = Color3.fromRGB(185, 154, 255),
	AccentDeep = Color3.fromRGB(120, 84, 240),
	Text       = Color3.fromRGB(234, 231, 244),
	Dim        = Color3.fromRGB(138, 133, 156),
	Off        = Color3.fromRGB(38, 37, 46),
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
	local s = create("UIStroke", {
		Color = color or C.Stroke,
		Thickness = thickness or 1,
		Transparency = trans or 0.35,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, obj)
	return s
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
local function notify(title, text)
	local holder = screen:FindFirstChild("KittenNotify")
	if not holder then
		holder = create("Frame", {
			Name = "KittenNotify",
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -18, 0, 18),
			Size = UDim2.fromOffset(260, 10),
			BackgroundTransparency = 1,
		}, screen)
		create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, holder)
	end
	local card = create("Frame", {
		Size = UDim2.new(1, 0, 0, 54),
		BackgroundColor3 = C.Panel,
		BackgroundTransparency = 0.08,
	}, holder)
	corner(card, 10)
	stroke(card, C.Accent, 1, 0.6)
	create("Frame", { Size = UDim2.new(0, 3, 1, -14), Position = UDim2.fromOffset(0, 7), BackgroundColor3 = C.Accent, BorderSizePixel = 0 }, card)
	local t = create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 7),
		Size = UDim2.new(1, -20, 0, 16),
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = C.Accent,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = title,
	}, card)
	create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 25),
		Size = UDim2.new(1, -20, 0, 22),
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextColor3 = C.Dim,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Text = text,
	}, card)
	task.delay(4, function()
		pcall(function()
			tween(card, 0.25, { BackgroundTransparency = 1 })
			tween(t, 0.25, { TextTransparency = 1 })
			task.wait(0.3)
			card:Destroy()
		end)
	end)
end

---------------------------------------------------------------------------
-- Мини-кнопка (когда окно скрыто)
---------------------------------------------------------------------------
local mini = create("TextButton", {
	Name = "Mini",
	Size = UDim2.fromOffset(120, 32),
	Position = UDim2.new(0, 18, 0, 18),
	BackgroundColor3 = C.Panel,
	AutoButtonColor = false,
	Text = "",
	Visible = false,
}, screen)
corner(mini, 16)
stroke(mini, C.Accent, 1, 0.5)
local miniLabel = create("TextLabel", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	TextSize = 13,
	TextColor3 = C.Accent,
	Text = "Kitten",
}, mini)
create("Frame", { Size = UDim2.new(0, 4, 1, -12), Position = UDim2.fromOffset(0, 6), BackgroundColor3 = C.Accent, BorderSizePixel = 0 }, mini)

---------------------------------------------------------------------------
-- Главное окно
---------------------------------------------------------------------------
local main = create("Frame", {
	Name = "Main",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(580, 400),
	BackgroundColor3 = C.Bg,
	BorderSizePixel = 0,
	ClipsDescendants = true,
}, screen)
corner(main, 14)
stroke(main, C.Stroke, 1, 0.25)

local glow = create("Frame", {
	Size = UDim2.new(1, 0, 0, 2),
	BackgroundColor3 = C.Accent,
	BorderSizePixel = 0,
	BackgroundTransparency = 0.15,
}, main)
local glowGrad = create("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, C.AccentDeep),
		ColorSequenceKeypoint.new(0.5, C.Accent),
		ColorSequenceKeypoint.new(1, C.AccentDeep),
	}),
}, glow)

-- Шапка
local header = create("Frame", {
	Size = UDim2.new(1, 0, 0, 46),
	BackgroundTransparency = 1,
}, main)

local title = create("TextLabel", {
	Position = UDim2.fromOffset(18, 0),
	Size = UDim2.new(0, 220, 1, 0),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBlack,
	TextSize = 19,
	TextColor3 = C.Text,
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "KittenScript",
}, header)
create("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, C.Accent),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
	}),
}, title)

create("TextLabel", {
	Position = UDim2.fromOffset(18, 24),
	Size = UDim2.new(0, 260, 0, 14),
	BackgroundTransparency = 1,
	Font = Enum.Font.Gotham,
	TextSize = 10,
	TextColor3 = C.Dim,
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "blox strike  •  RightShift",
}, header)

local function headerButton(text, xOffset, fn)
	local b = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, xOffset, 0.5, 0),
		Size = UDim2.fromOffset(26, 26),
		BackgroundColor3 = C.Element,
		AutoButtonColor = false,
		Text = text,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = C.Dim,
	}, header)
	corner(b, 7)
	b.MouseEnter:Connect(function() tween(b, 0.15, { BackgroundColor3 = C.Hover, TextColor3 = C.Accent }) end)
	b.MouseLeave:Connect(function() tween(b, 0.15, { BackgroundColor3 = C.Element, TextColor3 = C.Dim }) end)
	b.MouseButton1Click:Connect(fn)
	return b
end

headerButton("✕", -14, function()
	gui.Toggled = false
	main.Visible = false
	mini.Visible = true
end)

-- Перетаскивание
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

-- Сайдбар
local sidebar = create("Frame", {
	Position = UDim2.fromOffset(14, 54),
	Size = UDim2.new(0, 140, 1, -68),
	BackgroundColor3 = C.Panel,
	BorderSizePixel = 0,
}, main)
corner(sidebar, 10)

local content = create("Frame", {
	Position = UDim2.fromOffset(166, 54),
	Size = UDim2.new(1, -180, 1, -68),
	BackgroundTransparency = 1,
	ClipsDescendants = true,
}, main)

local Tabs = {}
local CurrentTab = nil

local function switchTab(name)
	if CurrentTab == name then return end
	CurrentTab = name
	for tabName, data in pairs(Tabs) do
		local active = tabName == name
		tween(data.Button, 0.18, { BackgroundColor3 = active and C.Element or C.Panel })
		tween(data.Bar, 0.18, { BackgroundTransparency = active and 0 or 1 })
		tween(data.Button.TextLabel, 0.18, { TextColor3 = active and C.Accent or C.Dim })
		if active then
			data.Group.Visible = true
			data.Group.Position = UDim2.fromOffset(14, 0)
			tween(data.Group, 0.22, { GroupTransparency = 0, Position = UDim2.fromOffset(0, 0) })
		else
			tween(data.Group, 0.16, { GroupTransparency = 1, Position = UDim2.fromOffset(active and 0 or 14, 0) })
			task.delay(0.17, function()
				if CurrentTab ~= tabName then data.Group.Visible = false end
			end)
		end
	end
end

local function addTab(name, iconText)
	local btn = create("TextButton", {
		Size = UDim2.new(1, -16, 0, 34),
		Position = UDim2.fromOffset(8, 8 + (#sidebar:GetChildren() - 1) * 0),
		BackgroundColor3 = C.Panel,
		AutoButtonColor = false,
		Text = "   " .. name,
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextColor3 = C.Dim,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, sidebar)
	btn.LayoutOrder = #sidebar:GetChildren()
	local bar = create("Frame", {
		Size = UDim2.new(0, 3, 1, -14),
		Position = UDim2.fromOffset(0, 7),
		BackgroundColor3 = C.Accent,
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
	}, btn)
	corner(bar, 2)
	create("TextLabel", {
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.fromOffset(16, 34),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = C.AccentDeep,
		Text = iconText,
	}, btn)

	local group = create("CanvasGroup", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		GroupTransparency = 1,
		Visible = false,
	}, content)
	local scroll = create("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = C.AccentDeep,
	}, group)
	create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, scroll)
	create("UIPadding", { PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) }, scroll)

	btn.MouseButton1Click:Connect(function() switchTab(name) end)
	btn.MouseEnter:Connect(function()
		if CurrentTab ~= name then tween(btn, 0.15, { BackgroundColor3 = C.Hover }) end
	end)
	btn.MouseLeave:Connect(function()
		if CurrentTab ~= name then tween(btn, 0.15, { BackgroundColor3 = C.Panel }) end
	end)

	Tabs[name] = { Button = btn, Bar = bar, Group = group, Scroll = scroll }
	return scroll
end

create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, sidebar)
create("UIPadding", { PaddingTop = UDim.new(0, 8) }, sidebar)

local skinPage = addTab("Skins", "✦")
local visualPage = addTab("Visuals", "◈")
local movePage = addTab("Movement", "⇅")

---------------------------------------------------------------------------
-- Элементы UI
---------------------------------------------------------------------------
local function section(parent, text)
	local l = create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		TextColor3 = C.Accent,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = string.upper(text),
	}, parent)
	return l
end

local function row(parent, height)
	local r = create("Frame", {
		Size = UDim2.new(1, 0, 0, height or 36),
		BackgroundColor3 = C.Element,
		BorderSizePixel = 0,
	}, parent)
	corner(r, 8)
	return r
end

local function makeToggle(parent, text, default, callback)
	local r = row(parent, 36)
	local label = create("TextLabel", {
		Position = UDim2.fromOffset(12, 0),
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
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(38, 20),
		BackgroundColor3 = default and C.AccentDeep or C.Off,
		BorderSizePixel = 0,
	}, r)
	corner(pill, 10)
	local knob = create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 2, 0.5, 0),
		Size = UDim2.fromOffset(16, 16),
		BackgroundColor3 = default and C.Accent or Color3.fromRGB(150, 148, 160),
		BorderSizePixel = 0,
	}, pill)
	corner(knob, 8)

	local state = default
	local function paint()
		tween(pill, 0.16, { BackgroundColor3 = state and C.AccentDeep or C.Off })
		tween(knob, 0.16, {
			Position = state and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
			BackgroundColor3 = state and C.Accent or Color3.fromRGB(150, 148, 160),
		})
		tween(label, 0.16, { TextColor3 = state and C.Text or C.Dim })
	end

	local clickable = create("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
	}, r)
	clickable.MouseButton1Click:Connect(function()
		state = not state
		paint()
		callback(state)
	end)
	return { Set = function(v) state = v paint() callback(v) end, Get = function() return state end }
end

local function makeSlider(parent, text, min, max, default, suffix, callback)
	local r = row(parent, 46)
	create("TextLabel", {
		Position = UDim2.fromOffset(12, 6),
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
		Position = UDim2.new(1, -12, 6, 0),
		Size = UDim2.fromOffset(60, 16),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = C.Accent,
		TextXAlignment = Enum.TextXAlignment.Right,
		Text = tostring(default) .. (suffix or ""),
	}, r)

	local track = create("Frame", {
		Position = UDim2.fromOffset(12, 32),
		Size = UDim2.new(1, -24, 0, 5),
		BackgroundColor3 = C.Off,
		BorderSizePixel = 0,
	}, r)
	corner(track, 3)
	local fill = create("Frame", {
		Size = UDim2.fromScale((default - min) / (max - min), 1),
		BackgroundColor3 = C.AccentDeep,
		BorderSizePixel = 0,
	}, track)
	corner(fill, 3)
	create("UIGradient", {
		Color = ColorSequence.new(C.AccentDeep, C.Accent),
	}, fill)
	local knob = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new((default - min) / (max - min), 0, 0.5, 0),
		Size = UDim2.fromOffset(12, 12),
		BackgroundColor3 = C.Accent,
		BorderSizePixel = 0,
	}, track)
	corner(knob, 6)

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
	bind(UserInputService.InputEnded, function()
		dragging = false
	end)

	return { Set = function(v) set(v) end, Get = function() return value end }
end

local function makeButton(parent, text, callback)
	local b = create("TextButton", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = C.Element,
		AutoButtonColor = false,
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		TextColor3 = C.Text,
		Text = text,
	}, parent)
	corner(b, 8)
	b.MouseEnter:Connect(function() tween(b, 0.15, { BackgroundColor3 = C.Hover, TextColor3 = C.Accent }) end)
	b.MouseLeave:Connect(function() tween(b, 0.15, { BackgroundColor3 = C.Element, TextColor3 = C.Text }) end)
	b.MouseButton1Click:Connect(callback)
	return b
end

-- Дропдаун с поиском (попап поверх окна)
local openPopups = {}
local function makeDropdown(parent, text, options, default, searchable, callback)
	local r = row(parent, 36)
	local label = create("TextLabel", {
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -44, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		TextColor3 = C.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = text,
	}, r)
	create("TextLabel", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(12, 12),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		TextColor3 = C.Accent,
		Text = "▾",
	}, r)
	local clickable = create("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "" }, r)

	local value = default
	local popup, list, search
	local open = false

	local function close()
		if not open then return end
		open = false
		for i, p in ipairs(openPopups) do if p == popup then table.remove(openPopups, i) break end end
		local p = popup
		popup = nil
		tween(p, 0.14, { BackgroundTransparency = 1 })
		task.wait(0.15)
		p:Destroy()
	end

	local function build(filter)
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
					Text = "  " .. option,
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
		list.CanvasSize = UDim2.new(0, 0, 0, count * 26 + 4)
	end

	clickable.MouseButton1Click:Connect(function()
		if open then close() return end
		for _, p in ipairs(table.clone(openPopups)) do
			-- закрыть другие
		end
		open = true
		local pos = r.AbsolutePosition - main.AbsolutePosition
		popup = create("Frame", {
			Position = UDim2.fromOffset(pos.X, pos.Y + r.AbsoluteSize.Y + 4),
			Size = UDim2.fromOffset(r.AbsoluteSize.X, searchable and 190 or 170),
			BackgroundColor3 = C.Panel,
			BackgroundTransparency = 1,
			ZIndex = 60,
		}, main)
		corner(popup, 8)
		stroke(popup, C.Stroke, 1, 0.3)
		tween(popup, 0.15, { BackgroundTransparency = 0 })
		table.insert(openPopups, popup)

		if searchable then
			search = create("TextBox", {
				Position = UDim2.fromOffset(6, 6),
				Size = UDim2.new(1, -12, 0, 24),
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
			Position = UDim2.fromOffset(6, searchable and 34 or 6),
			Size = UDim2.new(1, -12, 1, searchable and -40 or -12),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(),
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = C.AccentDeep,
			ZIndex = 61,
		}, popup)
		create("UIListLayout", { Padding = UDim.new(0, 2) }, list)
		build("")
	end)

	return {
		Set = function(v) value = v label.Text = v end,
		Get = function() return value end,
		SetOptions = function(list2)
			options = list2
			if open then build(search and search.Text or "") end
		end,
		Close = close,
	}
end

---------------------------------------------------------------------------
-- SkinChanger
---------------------------------------------------------------------------
local Skins = nil
local skinLoadout = {}
local skinRecords = setmetatable({}, { __mode = "k" })
local skinEnabled = false

local IGNORE = {
	["HE Grenade"] = true, ["Incendiary Grenade"] = true, ["Molotov"] = true,
	["Smoke Grenade"] = true, ["Flashbang"] = true, ["Decoy Grenade"] = true,
	["C4"] = true, ["CT Glove"] = true, ["T Glove"] = true,
}

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

local function applyGloves(model)
	local gloveFolder = Skins and Skins:FindFirstChild("Sports Gloves")
	local selection = skinLoadout["Sports Gloves"]
	if not gloveFolder or not selection then return end
	local skin = gloveFolder:FindFirstChild(selection.Skin)
	local cameraFolder = skin and skin:FindFirstChild("Camera")
	local source = cameraFolder and cameraFolder:FindFirstChild(selection.Wear)
	if not source then return end
	for _, side in ipairs({ "Left Arm", "Right Arm" }) do
		local arm = model:FindFirstChild(side)
		local glove = arm and arm:FindFirstChild("Glove")
		local paint = source:FindFirstChild(side)
		local surface = paint and paint:FindFirstChildOfClass("SurfaceAppearance")
		if glove and surface then
			local key = "glove:" .. selection.Skin .. ":" .. selection.Wear
			local rec = skinRecords[glove]
			if rec and rec.Key == key then continue end
			restorePart(glove)
			local originals = {}
			for _, child in ipairs(glove:GetChildren()) do
				if child:IsA("SurfaceAppearance") then table.insert(originals, child) child.Parent = nil end
			end
			local clone = surface:Clone()
			clone.Parent = glove
			skinRecords[glove] = { Key = key, Originals = originals, Applied = clone }
		end
	end
end

local function applyWeaponSkin(model)
	local weapon = model.Name
	local selection = skinLoadout[weapon]
	local weaponFolder = model:FindFirstChild("Weapon")
	if not selection or not weaponFolder or not Skins then return end
	local skinFolder = Skins:FindFirstChild(weapon)
	local skin = skinFolder and skinFolder:FindFirstChild(selection.Skin)
	local cameraFolder = skin and skin:FindFirstChild("Camera")
	local source = cameraFolder and cameraFolder:FindFirstChild(selection.Wear)
	if not source then return end
	local key = weapon .. ":" .. selection.Skin .. ":" .. selection.Wear
	for _, part in ipairs(weaponFolder:GetDescendants()) do
		if part:IsA("BasePart") then
			local paint = source:FindFirstChild(part.Name)
			local surface = paint and paint:FindFirstChildOfClass("SurfaceAppearance")
			if surface then
				local rec = skinRecords[part]
				if not (rec and rec.Key == key) then
					restorePart(part)
					local originals = {}
					for _, child in ipairs(part:GetChildren()) do
						if child:IsA("SurfaceAppearance") then table.insert(originals, child) child.Parent = nil end
					end
					local clone = surface:Clone()
					clone.Parent = part
					skinRecords[part] = { Key = key, Originals = originals, Applied = clone }
				end
			end
		end
	end
end

local function refreshSkins()
	if not skinEnabled then return end
	local camera = workspace.CurrentCamera
	if not camera then return end
	local alive = LocalPlayer.Character ~= nil
	if not alive then restoreAllSkins() return end
	for _, model in ipairs(camera:GetChildren()) do
		if model:IsA("Model") then
			if skinLoadout[model.Name] then
				pcall(applyWeaponSkin, model)
			elseif model:FindFirstChild("Left Arm") then
				pcall(applyGloves, model)
			end
		end
	end
end

local function buildSkinLists()
	Skins = ReplicatedStorage:FindFirstChild("Assets") and ReplicatedStorage.Assets:FindFirstChild("Skins")
	if not Skins then return nil, nil, nil end
	local knives, weapons = {}, {}
	for _, folder in ipairs(Skins:GetChildren()) do
		if folder:IsA("Folder") and not IGNORE[folder.Name] and folder.Name ~= "Sports Gloves" then
			local sample = folder:GetChildren()[1]
			if sample and sample:FindFirstChild("Camera") then
				local name = folder.Name
				if string.find(name, "Knife") or string.find(name, "Karambit")
					or string.find(name, "Bayonet") or name == "Flip" or string.find(name, "Gut") then
					table.insert(knives, name)
				else
					table.insert(weapons, name)
				end
			end
		end
	end
	table.sort(knives)
	table.sort(weapons)
	local all = {}
	for _, n in ipairs(knives) do table.insert(all, n) end
	for _, n in ipairs(weapons) do table.insert(all, n) end
	return all, knives, weapons
end

---------------------------------------------------------------------------
-- Вкладка Skins
---------------------------------------------------------------------------
do
	section(skinPage, "Скинчейнджер")
	makeToggle(skinPage, "Включить скинчейнджер", false, function(v)
		skinEnabled = v
		if not v then restoreAllSkins() end
	end)

	local wearList = { "Factory New", "Minimal Wear", "Field-Tested", "Well-Worn", "Battle-Scarred" }
	local weaponList, _, _ = buildSkinLists()
	weaponList = weaponList or {}

	local weaponDropdown, skinDropdown, wearDropdown

	section(skinPage, "Оружие")
	weaponDropdown = makeDropdown(skinPage, "Выберите оружие", weaponList, weaponList[1] or "AK-47", true, function(weapon)
		local folder = Skins and Skins:FindFirstChild(weapon)
		local list = {}
		if folder then
			for _, skin in ipairs(folder:GetChildren()) do
				if skin:IsA("Folder") and skin:FindFirstChild("Camera") then table.insert(list, skin.Name) end
			end
		end
		table.sort(list)
		skinDropdown:SetOptions(list)
		skinDropdown:Set(list[1] or "Original")
		skinLoadout[weapon] = { Skin = list[1], Wear = "Factory New" }
		restoreAllSkins()
		refreshSkins()
	end)

	skinDropdown = makeDropdown(skinPage, "Скин", {}, "—", true, function(skin)
		local weapon = weaponDropdown:Get()
		if not weapon then return end
		skinLoadout[weapon] = { Skin = skin, Wear = wearDropdown:Get() }
		restoreAllSkins()
		refreshSkins()
	end)

	wearDropdown = makeDropdown(skinPage, "Износ", wearList, "Factory New", false, function(wear)
		local weapon = weaponDropdown:Get()
		if not weapon then return end
		local current = skinLoadout[weapon]
		if current then
			current.Wear = wear
			restoreAllSkins()
			refreshSkins()
		end
	end)

	section(skinPage, "Перчатки")
	local gloveFolder = Skins and Skins:FindFirstChild("Sports Gloves")
	if gloveFolder then
		local gloveList = {}
		for _, skin in ipairs(gloveFolder:GetChildren()) do
			if skin:IsA("Folder") then table.insert(gloveList, skin.Name) end
		end
		table.sort(gloveList)
		makeDropdown(skinPage, "Перчатки", gloveList, gloveList[1] or "—", true, function(skin)
			skinLoadout["Sports Gloves"] = { Skin = skin, Wear = "Factory New" }
			restoreAllSkins()
			refreshSkins()
		end)
	else
		create("TextLabel", {
			Size = UDim2.new(1, 0, 0, 16),
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			TextSize = 11,
			TextColor3 = C.Dim,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = "Перчатки не найдены в этой версии игры.",
		}, skinPage)
	end

	section(skinPage, "Управление")
	makeButton(skinPage, "Сбросить все скины", function()
		table.clear(skinLoadout)
		restoreAllSkins()
		refreshSkins()
		notify("KittenScript", "Все скины сброшены")
	end)
	makeButton(skinPage, "Взять текущее оружие", function()
		local camera = workspace.CurrentCamera
		if not camera then return end
		for _, model in ipairs(camera:GetChildren()) do
			if model:IsA("Model") and skinLoadout[model.Name] == nil and model:FindFirstChild("Weapon") then
				weaponDropdown:Set(model.Name)
				local folder = Skins and Skins:FindFirstChild(model.Name)
				if folder then
					local list = {}
					for _, skin in ipairs(folder:GetChildren()) do
						if skin:IsA("Folder") then table.insert(list, skin.Name) end
					end
					table.sort(list)
					skinDropdown:SetOptions(list)
					skinDropdown:Set(list[1] or "—")
				end
				return
			end
		end
	end)

	task.spawn(function()
		while screen.Parent do
			task.wait(0.4)
			if skinEnabled then pcall(refreshSkins) end
		end
	end)
	if workspace.CurrentCamera then
		bind(workspace.CurrentCamera.ChildAdded, function(model)
			if skinEnabled and model:IsA("Model") then
				task.wait(0.1)
				pcall(refreshSkins)
			end
		end)
	end
	bind(workspace:GetPropertyChangedSignal("CurrentCamera"), function()
		local cam = workspace.CurrentCamera
		if cam then
			bind(cam.ChildAdded, function()
				if skinEnabled then task.wait(0.1) pcall(refreshSkins) end
			end)
		end
	end)
end

---------------------------------------------------------------------------
-- Вкладка Visuals (FOV)
---------------------------------------------------------------------------
local Fov = { Enabled = false, Value = 90, Original = nil, Circle = false, CircleSize = 120 }
local fovCircle = nil

do
	section(visualPage, "Камера")
	makeToggle(visualPage, "Включить FOV", false, function(v)
		Fov.Enabled = v
		local cam = workspace.CurrentCamera
		if v and cam then
			Fov.Original = cam.FieldOfView
		elseif cam and Fov.Original then
			cam.FieldOfView = Fov.Original
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
		local cam = workspace.CurrentCamera
		if Fov.Enabled and cam and math.abs(cam.FieldOfView - Fov.Value) > 0.05 then
			cam.FieldOfView = Fov.Value
		end
		if Fov.Circle and Drawing then
			if not fovCircle then
				local ok, circle = pcall(function()
					local c = Drawing.new("Circle")
					c.Thickness = 1.5
					c.NumSides = 64
					c.Color = C.Accent
					c.Filled = false
					c.Transparency = 0.85
					return c
				end)
				if ok then fovCircle = circle end
			end
			if fovCircle then
				local viewport = cam and cam.ViewportSize or Vector2.new(1920, 1080)
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
-- Вкладка Movement (Auto BunnyHop)
---------------------------------------------------------------------------
local Bhop = {
	Enabled = false,
	Mode = "Auto",
	Delay = 0,
	MovingOnly = false,
	CrouchJump = false,
	PauseWithMenu = true,
	Hooked = false,
}
local BhopState = { Module = nil, Buttons = nil, Original = nil, Wrapper = nil, LastDown = false, GroundSince = nil, Jumps = 0 }

local function crouchJump()
	if not VirtualInputManager then return end
	pcall(function()
		VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game)
		task.delay(0.25, function()
			pcall(function()
				VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game)
			end)
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
		local storage = ReplicatedStorage
		local classes = storage:FindFirstChild("Classes")
		local movement = storage:FindFirstChild("MovementV2")
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
				if jump then
					BhopState.Jumps += 1
					if Bhop.CrouchJump then crouchJump() end
				end
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
	Bhop.Hooked = false
end)

-- Фолбэк через VirtualInputManager / Humanoid.Jump
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
	local statusLabel = create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextColor3 = C.Dim,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "Прыжок вшивается в ввод игры — тайминг идеальный.",
	}, movePage)

	makeToggle(movePage, "Включить Auto BunnyHop", false, function(v)
		Bhop.Enabled = v
		if v and not Bhop.Hooked then
			notify("BHop", "Хук не установлен — работает резервный режим")
		end
	end)

	makeDropdown(movePage, "Режим", { "Auto", "Hold" }, "Auto", false, function(v) Bhop.Mode = v end)
	makeSlider(movePage, "Задержка прыжка", 0, 150, 0, " ms", function(v) Bhop.Delay = v end)
	makeToggle(movePage, "Только в движении", false, function(v) Bhop.MovingOnly = v end)
	makeToggle(movePage, "Крауч-прыжок (Ctrl)", false, function(v) Bhop.CrouchJump = v end)
	makeToggle(movePage, "Пауза при открытом меню", true, function(v) Bhop.PauseWithMenu = v end)

	section(movePage, "Инфо")
	create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 60),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextColor3 = C.Dim,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "Auto — прыгает сам при касании земли.\nHold — только пока зажата кнопка прыжка.\nПривяжите Jump на колесо и стрейфьте A/D — скорость держится.",
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
		main.Size = UDim2.fromOffset(560, 388)
		tween(main, 0.22, { Size = UDim2.fromOffset(580, 400) })
	else
		main.Visible = false
		mini.Visible = true
	end
end

mini.MouseButton1Click:Connect(function() setMenu(true) end)

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
	restoreAllSkins()
	local cam = workspace.CurrentCamera
	if cam and Fov.Original then cam.FieldOfView = Fov.Original end
	if fovCircle then pcall(function() fovCircle:Remove() end) end
	for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
	screen:Destroy()
	if env.KittenScript == gui then env.KittenScript = nil end
end
env.KittenScript = gui

switchTab("Skins")
notify("KittenScript", "Загружено. RightShift — меню.")
