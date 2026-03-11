--[[
    ███╗   ██╗███████╗██╗  ██╗██╗   ██╗███████╗    ██╗   ██╗██╗
    ████╗  ██║██╔════╝╚██╗██╔╝██║   ██║██╔════╝    ██║   ██║██║
    ██╔██╗ ██║█████╗   ╚███╔╝ ██║   ██║███████╗    ██║   ██║██║
    ██║╚██╗██║██╔══╝   ██╔██╗ ██║   ██║╚════██║    ██║   ██║██║
    ██║ ╚████║███████╗██╔╝ ██╗╚██████╔╝███████║    ╚██████╔╝██║
    ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝     ╚═════╝ ╚═╝

    NexusUI — Roblox UI Library
    Version: 2.0.0
    Author: NexusUI Team
    Description: A feature-rich, animated UI library for Roblox exploits
]]

-- ============================================================
--  SERVICES
-- ============================================================
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local CoreGui          = game:GetService("CoreGui")
local Players          = game:GetService("Players")
local LocalPlayer      = Players.LocalPlayer

-- ============================================================
--  LIBRARY TABLE
-- ============================================================
local NexusUI = {}
NexusUI.__index = NexusUI
NexusUI.Version = "2.0.0"
NexusUI.Windows = {}
NexusUI.Connections = {}
NexusUI.Flags = {}          -- Global flag storage for all elements
NexusUI.Theme = {
    -- Base colours
    Background     = Color3.fromRGB(10,  12,  22),
    Surface        = Color3.fromRGB(15,  18,  32),
    Panel          = Color3.fromRGB(20,  24,  42),
    Header         = Color3.fromRGB(12,  15,  28),

    -- Accents
    Accent         = Color3.fromRGB(74,  240, 255),
    AccentDark     = Color3.fromRGB(30,  140, 160),
    AccentSecond   = Color3.fromRGB(168, 85,  247),
    Danger         = Color3.fromRGB(255, 74,  106),
    Success        = Color3.fromRGB(74,  255, 160),
    Warning        = Color3.fromRGB(255, 184, 74),

    -- Text
    TextPrimary    = Color3.fromRGB(232, 244, 255),
    TextSecondary  = Color3.fromRGB(122, 155, 191),
    TextMuted      = Color3.fromRGB(61,  84,  112),

    -- Elements
    Toggle_On      = Color3.fromRGB(74,  240, 255),
    Toggle_Off     = Color3.fromRGB(40,  48,  72),
    Slider_Fill    = Color3.fromRGB(74,  240, 255),
    Slider_Back    = Color3.fromRGB(25,  30,  52),
    Input_Back     = Color3.fromRGB(18,  22,  38),
    Dropdown_Back  = Color3.fromRGB(18,  22,  38),
    Button_Default = Color3.fromRGB(25,  30,  52),
    Button_Hover   = Color3.fromRGB(40,  48,  80),
    Divider        = Color3.fromRGB(30,  38,  65),
    ScrollBar      = Color3.fromRGB(74,  240, 255),
}

-- ============================================================
--  UTILITY FUNCTIONS
-- ============================================================
local Util = {}

-- Tween helper
function Util.Tween(instance, props, duration, style, direction)
    style     = style     or Enum.EasingStyle.Quart
    direction = direction or Enum.EasingDirection.Out
    local info = TweenInfo.new(duration or 0.25, style, direction)
    local t    = TweenService:Create(instance, info, props)
    t:Play()
    return t
end

-- Ripple effect on click
function Util.Ripple(parent, colour)
    colour = colour or NexusUI.Theme.Accent
    local circle = Instance.new("Frame")
    circle.Size            = UDim2.new(0, 0, 0, 0)
    circle.AnchorPoint     = Vector2.new(0.5, 0.5)
    circle.Position        = UDim2.new(0.5, 0, 0.5, 0)
    circle.BackgroundColor3 = colour
    circle.BackgroundTransparency = 0.6
    circle.BorderSizePixel = 0
    circle.ZIndex          = parent.ZIndex + 10
    circle.Parent          = parent
    Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)

    local size = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y) * 2.5
    Util.Tween(circle, {
        Size = UDim2.new(0, size, 0, size),
        BackgroundTransparency = 1,
    }, 0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    task.delay(0.6, function() circle:Destroy() end)
end

-- Make a Frame draggable
function Util.MakeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragStart, startPos = false, nil, nil

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = input.Position
            startPos  = frame.Position
        end
    end)
    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- Create UICorner
function Util.Corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

-- Create UIStroke
function Util.Stroke(parent, colour, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color        = colour or NexusUI.Theme.Accent
    s.Thickness    = thickness or 1
    s.Transparency = transparency or 0.7
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

-- Create text label quickly
function Util.Label(parent, text, size, colour, bold, xalign)
    local l = Instance.new("TextLabel")
    l.Text              = text
    l.TextSize          = size  or 14
    l.TextColor3        = colour or NexusUI.Theme.TextPrimary
    l.Font              = bold and Enum.Font.GothamBold or Enum.Font.Gotham
    l.TextXAlignment    = xalign or Enum.TextXAlignment.Left
    l.BackgroundTransparency = 1
    l.Size              = UDim2.new(1, 0, 1, 0)
    l.Parent            = parent
    return l
end

-- Padding helper
function Util.Padding(parent, top, bottom, left, right)
    local p = Instance.new("UIPadding")
    p.PaddingTop    = UDim.new(0, top    or 0)
    p.PaddingBottom = UDim.new(0, bottom or 0)
    p.PaddingLeft   = UDim.new(0, left   or 0)
    p.PaddingRight  = UDim.new(0, right  or 0)
    p.Parent = parent
    return p
end

-- ============================================================
--  NOTIFICATION SYSTEM
-- ============================================================
local NotifHolder do
    NotifHolder = Instance.new("ScreenGui")
    NotifHolder.Name            = "NexusUI_Notifs"
    NotifHolder.ResetOnSpawn    = false
    NotifHolder.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
    NotifHolder.IgnoreGuiInset  = true
    pcall(function() NotifHolder.Parent = CoreGui end)

    local holder = Instance.new("Frame")
    holder.Name              = "Holder"
    holder.Size              = UDim2.new(0, 300, 1, 0)
    holder.Position          = UDim2.new(1, -315, 0, 0)
    holder.BackgroundTransparency = 1
    holder.Parent            = NotifHolder

    local list = Instance.new("UIListLayout")
    list.SortOrder       = Enum.SortOrder.LayoutOrder
    list.VerticalAlignment = Enum.VerticalAlignment.Bottom
    list.Padding         = UDim.new(0, 8)
    list.Parent          = holder

    Util.Padding(holder, 0, 16, 0, 0)
    NotifHolder._holder = holder
end

function NexusUI:Notify(options)
    options = options or {}
    local title    = options.Title    or "NexusUI"
    local message  = options.Message  or ""
    local duration = options.Duration or 4
    local ntype    = options.Type     or "Info"   -- Info | Success | Warning | Error

    local typeColour = ({
        Info    = NexusUI.Theme.Accent,
        Success = NexusUI.Theme.Success,
        Warning = NexusUI.Theme.Warning,
        Error   = NexusUI.Theme.Danger,
    })[ntype] or NexusUI.Theme.Accent

    local typeIcon = ({
        Info    = "ℹ",
        Success = "✔",
        Warning = "⚠",
        Error   = "✖",
    })[ntype] or "ℹ"

    -- Card
    local card = Instance.new("Frame")
    card.Name                  = "Notification"
    card.Size                  = UDim2.new(1, 0, 0, 80)
    card.BackgroundColor3      = NexusUI.Theme.Surface
    card.BackgroundTransparency = 0.05
    card.BorderSizePixel       = 0
    card.ClipsDescendants      = true
    card.Parent                = NotifHolder._holder
    Util.Corner(card, 10)
    Util.Stroke(card, typeColour, 1, 0.5)

    -- Accent bar
    local bar = Instance.new("Frame")
    bar.Size             = UDim2.new(0, 4, 1, 0)
    bar.BackgroundColor3 = typeColour
    bar.BorderSizePixel  = 0
    bar.Parent           = card
    Util.Corner(bar, 4)

    -- Icon
    local icon = Instance.new("TextLabel")
    icon.Size                  = UDim2.new(0, 32, 0, 32)
    icon.Position              = UDim2.new(0, 14, 0.5, -16)
    icon.Text                  = typeIcon
    icon.TextSize              = 18
    icon.TextColor3            = typeColour
    icon.Font                  = Enum.Font.GothamBold
    icon.BackgroundColor3      = typeColour
    icon.BackgroundTransparency = 0.85
    icon.TextXAlignment        = Enum.TextXAlignment.Center
    icon.Parent                = card
    Util.Corner(icon, 8)

    -- Title
    local titleL = Instance.new("TextLabel")
    titleL.Size             = UDim2.new(1, -70, 0, 22)
    titleL.Position         = UDim2.new(0, 58, 0, 12)
    titleL.Text             = title
    titleL.TextSize         = 14
    titleL.Font             = Enum.Font.GothamBold
    titleL.TextColor3       = NexusUI.Theme.TextPrimary
    titleL.TextXAlignment   = Enum.TextXAlignment.Left
    titleL.BackgroundTransparency = 1
    titleL.Parent           = card

    -- Message
    local msgL = Instance.new("TextLabel")
    msgL.Size             = UDim2.new(1, -70, 0, 32)
    msgL.Position         = UDim2.new(0, 58, 0, 34)
    msgL.Text             = message
    msgL.TextSize         = 12
    msgL.Font             = Enum.Font.Gotham
    msgL.TextColor3       = NexusUI.Theme.TextSecondary
    msgL.TextXAlignment   = Enum.TextXAlignment.Left
    msgL.TextWrapped      = true
    msgL.BackgroundTransparency = 1
    msgL.Parent           = card

    -- Progress bar
    local prog = Instance.new("Frame")
    prog.Size             = UDim2.new(1, -8, 0, 2)
    prog.Position         = UDim2.new(0, 4, 1, -4)
    prog.BackgroundColor3 = typeColour
    prog.BorderSizePixel  = 0
    prog.Parent           = card
    Util.Corner(prog, 2)

    -- Slide in
    card.Position = UDim2.new(1, 10, 0, 0)
    Util.Tween(card, { Position = UDim2.new(0, 0, 0, 0) }, 0.35, Enum.EasingStyle.Back)

    -- Progress countdown
    Util.Tween(prog, { Size = UDim2.new(0, 0, 0, 2) }, duration, Enum.EasingStyle.Linear)

    -- Auto remove
    task.delay(duration, function()
        Util.Tween(card, { Position = UDim2.new(1, 10, 0, 0) }, 0.3)
        task.delay(0.35, function() card:Destroy() end)
    end)

    return card
end

-- ============================================================
--  WINDOW
-- ============================================================
function NexusUI:CreateWindow(options)
    options = options or {}
    local title    = options.Title    or "NexusUI"
    local subtitle = options.Subtitle or "v2.0.0"
    local size     = options.Size     or Vector2.new(560, 420)
    local position = options.Position or UDim2.new(0.5, -size.X/2, 0.5, -size.Y/2)

    -- Root ScreenGui
    local gui = Instance.new("ScreenGui")
    gui.Name           = "NexusUI_" .. title
    gui.ResetOnSpawn   = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset = true
    pcall(function() gui.Parent = CoreGui end)

    -- Main frame
    local main = Instance.new("Frame")
    main.Name             = "Main"
    main.Size             = UDim2.new(0, size.X, 0, size.Y)
    main.Position         = position
    main.BackgroundColor3 = NexusUI.Theme.Background
    main.BorderSizePixel  = 0
    main.ClipsDescendants = false
    main.Parent           = gui
    Util.Corner(main, 12)
    Util.Stroke(main, NexusUI.Theme.Accent, 1, 0.6)

    -- Shadow
    local shadow = Instance.new("ImageLabel")
    shadow.Name  = "Shadow"
    shadow.Size  = UDim2.new(1, 40, 1, 40)
    shadow.Position = UDim2.new(0, -20, 0, -10)
    shadow.Image = "rbxassetid://5554236805"
    shadow.ImageColor3 = NexusUI.Theme.Accent
    shadow.ImageTransparency = 0.88
    shadow.BackgroundTransparency = 1
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(23, 23, 277, 277)
    shadow.ZIndex = main.ZIndex - 1
    shadow.Parent = main

    -- Header
    local header = Instance.new("Frame")
    header.Name             = "Header"
    header.Size             = UDim2.new(1, 0, 0, 48)
    header.BackgroundColor3 = NexusUI.Theme.Header
    header.BorderSizePixel  = 0
    header.Parent           = main
    Util.Corner(header, 12)

    -- Header bottom mask (hide bottom radius)
    local headerMask = Instance.new("Frame")
    headerMask.Size             = UDim2.new(1, 0, 0, 12)
    headerMask.Position         = UDim2.new(0, 0, 1, -12)
    headerMask.BackgroundColor3 = NexusUI.Theme.Header
    headerMask.BorderSizePixel  = 0
    headerMask.Parent           = header

    -- Accent line under header
    local accentLine = Instance.new("Frame")
    accentLine.Size             = UDim2.new(1, 0, 0, 1)
    accentLine.Position         = UDim2.new(0, 0, 1, 0)
    accentLine.BackgroundColor3 = NexusUI.Theme.Accent
    accentLine.BackgroundTransparency = 0.5
    accentLine.BorderSizePixel  = 0
    accentLine.Parent           = header

    -- Logo dot
    local dot = Instance.new("Frame")
    dot.Size             = UDim2.new(0, 8, 0, 8)
    dot.Position         = UDim2.new(0, 16, 0.5, -4)
    dot.BackgroundColor3 = NexusUI.Theme.Accent
    dot.BorderSizePixel  = 0
    dot.Parent           = header
    Util.Corner(dot, 4)

    -- Title text
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size             = UDim2.new(0, 200, 1, 0)
    titleLabel.Position         = UDim2.new(0, 32, 0, 0)
    titleLabel.Text             = title
    titleLabel.TextSize         = 16
    titleLabel.Font             = Enum.Font.GothamBold
    titleLabel.TextColor3       = NexusUI.Theme.TextPrimary
    titleLabel.TextXAlignment   = Enum.TextXAlignment.Left
    titleLabel.BackgroundTransparency = 1
    titleLabel.Parent           = header

    -- Subtitle
    local subLabel = Instance.new("TextLabel")
    subLabel.Size             = UDim2.new(0, 160, 1, 0)
    subLabel.Position         = UDim2.new(0, 150, 0, 0)
    subLabel.Text             = subtitle
    subLabel.TextSize         = 11
    subLabel.Font             = Enum.Font.Gotham
    subLabel.TextColor3       = NexusUI.Theme.TextMuted
    subLabel.TextXAlignment   = Enum.TextXAlignment.Left
    subLabel.BackgroundTransparency = 1
    subLabel.Parent           = header

    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size             = UDim2.new(0, 28, 0, 28)
    closeBtn.Position         = UDim2.new(1, -38, 0.5, -14)
    closeBtn.Text             = "✕"
    closeBtn.TextSize         = 13
    closeBtn.Font             = Enum.Font.GothamBold
    closeBtn.TextColor3       = NexusUI.Theme.TextSecondary
    closeBtn.BackgroundColor3 = NexusUI.Theme.Panel
    closeBtn.BorderSizePixel  = 0
    closeBtn.Parent           = header
    Util.Corner(closeBtn, 6)

    closeBtn.MouseEnter:Connect(function()
        Util.Tween(closeBtn, { TextColor3 = NexusUI.Theme.Danger, BackgroundColor3 = Color3.fromRGB(60,20,30) }, 0.15)
    end)
    closeBtn.MouseLeave:Connect(function()
        Util.Tween(closeBtn, { TextColor3 = NexusUI.Theme.TextSecondary, BackgroundColor3 = NexusUI.Theme.Panel }, 0.15)
    end)
    closeBtn.MouseButton1Click:Connect(function()
        Util.Ripple(closeBtn, NexusUI.Theme.Danger)
        Util.Tween(main, { Size = UDim2.new(0, size.X, 0, 0), Position = UDim2.new(main.Position.X.Scale, main.Position.X.Offset, main.Position.Y.Scale, main.Position.Y.Offset + size.Y/2) }, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        task.delay(0.4, function() gui:Destroy() end)
    end)

    -- Minimise button
    local minBtn = Instance.new("TextButton")
    minBtn.Size             = UDim2.new(0, 28, 0, 28)
    minBtn.Position         = UDim2.new(1, -72, 0.5, -14)
    minBtn.Text             = "−"
    minBtn.TextSize         = 18
    minBtn.Font             = Enum.Font.GothamBold
    minBtn.TextColor3       = NexusUI.Theme.TextSecondary
    minBtn.BackgroundColor3 = NexusUI.Theme.Panel
    minBtn.BorderSizePixel  = 0
    minBtn.Parent           = header
    Util.Corner(minBtn, 6)

    local minimised = false
    minBtn.MouseEnter:Connect(function()
        Util.Tween(minBtn, { TextColor3 = NexusUI.Theme.Accent }, 0.15)
    end)
    minBtn.MouseLeave:Connect(function()
        Util.Tween(minBtn, { TextColor3 = NexusUI.Theme.TextSecondary }, 0.15)
    end)
    minBtn.MouseButton1Click:Connect(function()
        minimised = not minimised
        if minimised then
            Util.Tween(main, { Size = UDim2.new(0, size.X, 0, 48) }, 0.3, Enum.EasingStyle.Quart)
        else
            Util.Tween(main, { Size = UDim2.new(0, size.X, 0, size.Y) }, 0.3, Enum.EasingStyle.Back)
        end
    end)

    -- Body
    local body = Instance.new("Frame")
    body.Name             = "Body"
    body.Size             = UDim2.new(1, 0, 1, -48)
    body.Position         = UDim2.new(0, 0, 0, 48)
    body.BackgroundTransparency = 1
    body.ClipsDescendants = true
    body.Parent           = main

    -- Tab bar
    local tabBar = Instance.new("Frame")
    tabBar.Name             = "TabBar"
    tabBar.Size             = UDim2.new(0, 140, 1, 0)
    tabBar.BackgroundColor3 = NexusUI.Theme.Panel
    tabBar.BorderSizePixel  = 0
    tabBar.Parent           = body

    -- TabBar bottom-left radius mask
    local tabMask = Instance.new("Frame")
    tabMask.Size             = UDim2.new(1, 0, 0, 12)
    tabMask.Position         = UDim2.new(0, 0, 1, -12)
    tabMask.BackgroundColor3 = NexusUI.Theme.Panel
    tabMask.BorderSizePixel  = 0
    tabMask.Parent           = tabBar

    local tabList = Instance.new("UIListLayout")
    tabList.SortOrder = Enum.SortOrder.LayoutOrder
    tabList.Padding   = UDim.new(0, 2)
    tabList.Parent    = tabBar
    Util.Padding(tabBar, 8, 8, 8, 8)

    -- Content area
    local contentArea = Instance.new("Frame")
    contentArea.Name             = "ContentArea"
    contentArea.Size             = UDim2.new(1, -140, 1, 0)
    contentArea.Position         = UDim2.new(0, 140, 0, 0)
    contentArea.BackgroundTransparency = 1
    contentArea.ClipsDescendants = true
    contentArea.Parent           = body

    -- Dragging
    Util.MakeDraggable(main, header)

    -- Animate in
    main.Size     = UDim2.new(0, size.X, 0, 0)
    main.Position = UDim2.new(position.X.Scale, position.X.Offset, position.Y.Scale, position.Y.Offset + size.Y/2)
    Util.Tween(main, {
        Size     = UDim2.new(0, size.X, 0, size.Y),
        Position = position,
    }, 0.4, Enum.EasingStyle.Back)

    -- Window object
    local Window = {}
    Window._gui         = gui
    Window._main        = main
    Window._tabBar      = tabBar
    Window._contentArea = contentArea
    Window._tabs        = {}
    Window._activeTab   = nil

    -- --------------------------------------------------------
    --  ADD TAB
    -- --------------------------------------------------------
    function Window:AddTab(name, icon)
        icon = icon or "☰"

        -- Container page
        local page = Instance.new("ScrollingFrame")
        page.Name                        = name
        page.Size                        = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency      = 1
        page.BorderSizePixel             = 0
        page.ScrollBarThickness          = 3
        page.ScrollBarImageColor3        = NexusUI.Theme.Accent
        page.ScrollBarImageTransparency  = 0.5
        page.CanvasSize                  = UDim2.new(0, 0, 0, 0)
        page.AutomaticCanvasSize         = Enum.AutomaticSize.Y
        page.Visible                     = false
        page.Parent                      = contentArea

        local pageList = Instance.new("UIListLayout")
        pageList.SortOrder = Enum.SortOrder.LayoutOrder
        pageList.Padding   = UDim.new(0, 6)
        pageList.Parent    = page
        Util.Padding(page, 10, 10, 12, 12)

        -- Tab button
        local btn = Instance.new("TextButton")
        btn.Size             = UDim2.new(1, 0, 0, 36)
        btn.BackgroundColor3 = NexusUI.Theme.Panel
        btn.BackgroundTransparency = 1
        btn.Text             = ""
        btn.BorderSizePixel  = 0
        btn.Parent           = tabBar
        Util.Corner(btn, 8)

        local btnIcon = Instance.new("TextLabel")
        btnIcon.Size             = UDim2.new(0, 24, 1, 0)
        btnIcon.Position         = UDim2.new(0, 8, 0, 0)
        btnIcon.Text             = icon
        btnIcon.TextSize         = 15
        btnIcon.Font             = Enum.Font.GothamBold
        btnIcon.TextColor3       = NexusUI.Theme.TextMuted
        btnIcon.BackgroundTransparency = 1
        btnIcon.Parent           = btn

        local btnLabel = Instance.new("TextLabel")
        btnLabel.Size             = UDim2.new(1, -36, 1, 0)
        btnLabel.Position         = UDim2.new(0, 36, 0, 0)
        btnLabel.Text             = name
        btnLabel.TextSize         = 13
        btnLabel.Font             = Enum.Font.Gotham
        btnLabel.TextColor3       = NexusUI.Theme.TextMuted
        btnLabel.TextXAlignment   = Enum.TextXAlignment.Left
        btnLabel.BackgroundTransparency = 1
        btnLabel.Parent           = btn

        -- Active indicator
        local indicator = Instance.new("Frame")
        indicator.Size             = UDim2.new(0, 3, 0, 18)
        indicator.Position         = UDim2.new(0, 0, 0.5, -9)
        indicator.BackgroundColor3 = NexusUI.Theme.Accent
        indicator.BackgroundTransparency = 1
        indicator.BorderSizePixel  = 0
        indicator.Parent           = btn
        Util.Corner(indicator, 2)

        local function activate()
            -- Deactivate all
            for _, t in ipairs(self._tabs) do
                t.page.Visible = false
                Util.Tween(t.btn, { BackgroundTransparency = 1 }, 0.15)
                Util.Tween(t.label, { TextColor3 = NexusUI.Theme.TextMuted, Font = Enum.Font.Gotham }, 0.15)
                Util.Tween(t.icon, { TextColor3 = NexusUI.Theme.TextMuted }, 0.15)
                Util.Tween(t.indicator, { BackgroundTransparency = 1 }, 0.15)
            end
            -- Activate this
            page.Visible = true
            Util.Tween(btn, { BackgroundTransparency = 0.85 }, 0.15)
            Util.Tween(btnLabel, { TextColor3 = NexusUI.Theme.Accent }, 0.15)
            Util.Tween(btnIcon, { TextColor3 = NexusUI.Theme.Accent }, 0.15)
            Util.Tween(indicator, { BackgroundTransparency = 0 }, 0.15)
            self._activeTab = name
        end

        btn.MouseButton1Click:Connect(function()
            Util.Ripple(btn, NexusUI.Theme.Accent)
            activate()
        end)

        btn.MouseEnter:Connect(function()
            if self._activeTab ~= name then
                Util.Tween(btn, { BackgroundTransparency = 0.92 }, 0.15)
                Util.Tween(btnLabel, { TextColor3 = NexusUI.Theme.TextSecondary }, 0.15)
            end
        end)
        btn.MouseLeave:Connect(function()
            if self._activeTab ~= name then
                Util.Tween(btn, { BackgroundTransparency = 1 }, 0.15)
                Util.Tween(btnLabel, { TextColor3 = NexusUI.Theme.TextMuted }, 0.15)
            end
        end)

        local tabEntry = {
            page      = page,
            btn       = btn,
            label     = btnLabel,
            icon      = btnIcon,
            indicator = indicator,
        }
        table.insert(self._tabs, tabEntry)

        -- Auto-activate first tab
        if #self._tabs == 1 then activate() end

        -- Tab section object
        local Tab = {}
        Tab._page     = page
        Tab._layout   = pageList
        Tab._window   = self

        -- ----------------------------------------------------
        --  SECTION
        -- ----------------------------------------------------
        function Tab:AddSection(sectionName)
            local sectionFrame = Instance.new("Frame")
            sectionFrame.Size             = UDim2.new(1, 0, 0, 28)
            sectionFrame.AutomaticSize    = Enum.AutomaticSize.Y
            sectionFrame.BackgroundTransparency = 1
            sectionFrame.BorderSizePixel  = 0
            sectionFrame.Parent           = page

            -- Section label
            local secLabel = Instance.new("TextLabel")
            secLabel.Size             = UDim2.new(1, -8, 0, 20)
            secLabel.Position         = UDim2.new(0, 4, 0, 4)
            secLabel.Text             = string.upper(sectionName)
            secLabel.TextSize         = 10
            secLabel.Font             = Enum.Font.GothamBold
            secLabel.TextColor3       = NexusUI.Theme.Accent
            secLabel.TextXAlignment   = Enum.TextXAlignment.Left
            secLabel.BackgroundTransparency = 1
            secLabel.Parent           = sectionFrame

            -- Divider line
            local divLine = Instance.new("Frame")
            divLine.Size             = UDim2.new(1, -8, 0, 1)
            divLine.Position         = UDim2.new(0, 4, 0, 26)
            divLine.BackgroundColor3 = NexusUI.Theme.Divider
            divLine.BorderSizePixel  = 0
            divLine.Parent           = sectionFrame

            -- Item list under section
            local itemList = Instance.new("UIListLayout")
            itemList.SortOrder = Enum.SortOrder.LayoutOrder
            itemList.Padding   = UDim.new(0, 4)
            itemList.Parent    = sectionFrame

            local Section = {}
            Section._frame = sectionFrame

            -- --------------------------------------------------
            --  TOGGLE
            -- --------------------------------------------------
            function Section:AddToggle(opts)
                opts = opts or {}
                local label   = opts.Name    or "Toggle"
                local default = opts.Default or false
                local flag    = opts.Flag    or label
                local callback = opts.Callback or function() end

                NexusUI.Flags[flag] = default

                local row = Instance.new("Frame")
                row.Size             = UDim2.new(1, 0, 0, 38)
                row.BackgroundColor3 = NexusUI.Theme.Surface
                row.BorderSizePixel  = 0
                row.Parent           = sectionFrame
                Util.Corner(row, 8)
                Util.Stroke(row, NexusUI.Theme.Divider, 1, 0.2)

                local lbl = Instance.new("TextLabel")
                lbl.Size             = UDim2.new(1, -60, 1, 0)
                lbl.Position         = UDim2.new(0, 12, 0, 0)
                lbl.Text             = label
                lbl.TextSize         = 14
                lbl.Font             = Enum.Font.Gotham
                lbl.TextColor3       = NexusUI.Theme.TextPrimary
                lbl.TextXAlignment   = Enum.TextXAlignment.Left
                lbl.BackgroundTransparency = 1
                lbl.Parent           = row

                local track = Instance.new("Frame")
                track.Size             = UDim2.new(0, 42, 0, 22)
                track.Position         = UDim2.new(1, -54, 0.5, -11)
                track.BackgroundColor3 = default and NexusUI.Theme.Toggle_On or NexusUI.Theme.Toggle_Off
                track.BorderSizePixel  = 0
                track.Parent           = row
                Util.Corner(track, 11)

                local thumb = Instance.new("Frame")
                thumb.Size             = UDim2.new(0, 16, 0, 16)
                thumb.Position         = default and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
                thumb.BackgroundColor3 = Color3.new(1,1,1)
                thumb.BorderSizePixel  = 0
                thumb.Parent           = track
                Util.Corner(thumb, 8)

                local state = default
                local clickable = Instance.new("TextButton")
                clickable.Size             = UDim2.new(1, 0, 1, 0)
                clickable.BackgroundTransparency = 1
                clickable.Text             = ""
                clickable.Parent           = row

                clickable.MouseButton1Click:Connect(function()
                    state = not state
                    NexusUI.Flags[flag] = state
                    Util.Ripple(row, NexusUI.Theme.Accent)
                    Util.Tween(track, { BackgroundColor3 = state and NexusUI.Theme.Toggle_On or NexusUI.Theme.Toggle_Off }, 0.2)
                    Util.Tween(thumb, { Position = state and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8) }, 0.2, Enum.EasingStyle.Back)
                    pcall(callback, state)
                end)

                local Toggle = {}
                function Toggle:Set(val)
                    state = val
                    NexusUI.Flags[flag] = val
                    Util.Tween(track, { BackgroundColor3 = val and NexusUI.Theme.Toggle_On or NexusUI.Theme.Toggle_Off }, 0.2)
                    Util.Tween(thumb, { Position = val and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8) }, 0.2)
                    pcall(callback, val)
                end
                function Toggle:Get() return state end
                return Toggle
            end

            -- --------------------------------------------------
            --  SLIDER
            -- --------------------------------------------------
            function Section:AddSlider(opts)
                opts = opts or {}
                local label   = opts.Name    or "Slider"
                local min     = opts.Min     or 0
                local max     = opts.Max     or 100
                local default = opts.Default or min
                local flag    = opts.Flag    or label
                local suffix  = opts.Suffix  or ""
                local callback = opts.Callback or function() end

                NexusUI.Flags[flag] = default

                local row = Instance.new("Frame")
                row.Size             = UDim2.new(1, 0, 0, 52)
                row.BackgroundColor3 = NexusUI.Theme.Surface
                row.BorderSizePixel  = 0
                row.Parent           = sectionFrame
                Util.Corner(row, 8)
                Util.Stroke(row, NexusUI.Theme.Divider, 1, 0.2)

                local lbl = Instance.new("TextLabel")
                lbl.Size             = UDim2.new(1, -70, 0, 22)
                lbl.Position         = UDim2.new(0, 12, 0, 6)
                lbl.Text             = label
                lbl.TextSize         = 14
                lbl.Font             = Enum.Font.Gotham
                lbl.TextColor3       = NexusUI.Theme.TextPrimary
                lbl.TextXAlignment   = Enum.TextXAlignment.Left
                lbl.BackgroundTransparency = 1
                lbl.Parent           = row

                local valLabel = Instance.new("TextLabel")
                valLabel.Size             = UDim2.new(0, 60, 0, 22)
                valLabel.Position         = UDim2.new(1, -70, 0, 6)
                valLabel.Text             = tostring(default) .. suffix
                valLabel.TextSize         = 13
                valLabel.Font             = Enum.Font.GothamBold
                valLabel.TextColor3       = NexusUI.Theme.Accent
                valLabel.TextXAlignment   = Enum.TextXAlignment.Right
                valLabel.BackgroundTransparency = 1
                valLabel.Parent           = row

                local track = Instance.new("Frame")
                track.Size             = UDim2.new(1, -24, 0, 6)
                track.Position         = UDim2.new(0, 12, 0, 36)
                track.BackgroundColor3 = NexusUI.Theme.Slider_Back
                track.BorderSizePixel  = 0
                track.Parent           = row
                Util.Corner(track, 3)

                local fill = Instance.new("Frame")
                fill.Size             = UDim2.new((default-min)/(max-min), 0, 1, 0)
                fill.BackgroundColor3 = NexusUI.Theme.Slider_Fill
                fill.BorderSizePixel  = 0
                fill.Parent           = track
                Util.Corner(fill, 3)

                -- Glow on fill
                local fillGlow = Instance.new("UIGradient")
                fillGlow.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, NexusUI.Theme.AccentDark),
                    ColorSequenceKeypoint.new(1, NexusUI.Theme.Accent),
                })
                fillGlow.Parent = fill

                local knob = Instance.new("Frame")
                knob.Size             = UDim2.new(0, 14, 0, 14)
                knob.AnchorPoint      = Vector2.new(0.5, 0.5)
                knob.Position         = UDim2.new((default-min)/(max-min), 0, 0.5, 0)
                knob.BackgroundColor3 = Color3.new(1,1,1)
                knob.BorderSizePixel  = 0
                knob.ZIndex           = row.ZIndex + 2
                knob.Parent           = track
                Util.Corner(knob, 7)
                Util.Stroke(knob, NexusUI.Theme.Accent, 2, 0)

                local dragging = false
                local current  = default

                local function update(x)
                    local abs  = track.AbsolutePosition.X
                    local wid  = track.AbsoluteSize.X
                    local pct  = math.clamp((x - abs) / wid, 0, 1)
                    local val  = math.floor(min + (max - min) * pct)
                    if val == current then return end
                    current = val
                    NexusUI.Flags[flag] = val
                    valLabel.Text = tostring(val) .. suffix
                    fill.Size  = UDim2.new(pct, 0, 1, 0)
                    knob.Position = UDim2.new(pct, 0, 0.5, 0)
                    pcall(callback, val)
                end

                track.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                        update(i.Position.X)
                        Util.Tween(knob, { Size = UDim2.new(0, 18, 0, 18) }, 0.1)
                    end
                end)
                UserInputService.InputEnded:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = false
                        Util.Tween(knob, { Size = UDim2.new(0, 14, 0, 14) }, 0.1)
                    end
                end)
                UserInputService.InputChanged:Connect(function(i)
                    if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                        update(i.Position.X)
                    end
                end)

                local Slider = {}
                function Slider:Set(val)
                    val = math.clamp(val, min, max)
                    current = val
                    NexusUI.Flags[flag] = val
                    local pct = (val-min)/(max-min)
                    valLabel.Text = tostring(val) .. suffix
                    Util.Tween(fill, { Size = UDim2.new(pct, 0, 1, 0) }, 0.15)
                    Util.Tween(knob, { Position = UDim2.new(pct, 0, 0.5, 0) }, 0.15)
                    pcall(callback, val)
                end
                function Slider:Get() return current end
                return Slider
            end

            -- --------------------------------------------------
            --  BUTTON
            -- --------------------------------------------------
            function Section:AddButton(opts)
                opts = opts or {}
                local label    = opts.Name     or "Button"
                local callback = opts.Callback or function() end
                local style    = opts.Style    or "Default"  -- Default | Danger | Success

                local styleColour = ({
                    Default = NexusUI.Theme.Accent,
                    Danger  = NexusUI.Theme.Danger,
                    Success = NexusUI.Theme.Success,
                })[style] or NexusUI.Theme.Accent

                local btn = Instance.new("TextButton")
                btn.Size             = UDim2.new(1, 0, 0, 36)
                btn.BackgroundColor3 = NexusUI.Theme.Button_Default
                btn.BorderSizePixel  = 0
                btn.Text             = ""
                btn.Parent           = sectionFrame
                Util.Corner(btn, 8)
                Util.Stroke(btn, styleColour, 1, 0.5)

                local lbl = Instance.new("TextLabel")
                lbl.Size             = UDim2.new(1, 0, 1, 0)
                lbl.Text             = label
                lbl.TextSize         = 14
                lbl.Font             = Enum.Font.GothamBold
                lbl.TextColor3       = styleColour
                lbl.BackgroundTransparency = 1
                lbl.Parent           = btn

                btn.MouseEnter:Connect(function()
                    Util.Tween(btn, { BackgroundColor3 = NexusUI.Theme.Button_Hover }, 0.15)
                    Util.Tween(lbl, { TextColor3 = Color3.new(1,1,1) }, 0.15)
                end)
                btn.MouseLeave:Connect(function()
                    Util.Tween(btn, { BackgroundColor3 = NexusUI.Theme.Button_Default }, 0.15)
                    Util.Tween(lbl, { TextColor3 = styleColour }, 0.15)
                end)
                btn.MouseButton1Click:Connect(function()
                    Util.Ripple(btn, styleColour)
                    pcall(callback)
                end)

                local Button = {}
                function Button:SetLabel(text) lbl.Text = text end
                return Button
            end

            -- --------------------------------------------------
            --  INPUT (TextBox)
            -- --------------------------------------------------
            function Section:AddInput(opts)
                opts = opts or {}
                local label    = opts.Name        or "Input"
                local placeholder = opts.Placeholder or "Enter text..."
                local default  = opts.Default     or ""
                local flag     = opts.Flag        or label
                local callback = opts.Callback    or function() end
                local isNumber = opts.NumberOnly  or false

                NexusUI.Flags[flag] = default

                local row = Instance.new("Frame")
                row.Size             = UDim2.new(1, 0, 0, 56)
                row.BackgroundColor3 = NexusUI.Theme.Surface
                row.BorderSizePixel  = 0
                row.Parent           = sectionFrame
                Util.Corner(row, 8)
                Util.Stroke(row, NexusUI.Theme.Divider, 1, 0.2)

                local lbl = Instance.new("TextLabel")
                lbl.Size             = UDim2.new(1, -16, 0, 20)
                lbl.Position         = UDim2.new(0, 12, 0, 6)
                lbl.Text             = label
                lbl.TextSize         = 12
                lbl.Font             = Enum.Font.GothamBold
                lbl.TextColor3       = NexusUI.Theme.TextSecondary
                lbl.TextXAlignment   = Enum.TextXAlignment.Left
                lbl.BackgroundTransparency = 1
                lbl.Parent           = row

                local inputFrame = Instance.new("Frame")
                inputFrame.Size             = UDim2.new(1, -24, 0, 26)
                inputFrame.Position         = UDim2.new(0, 12, 0, 24)
                inputFrame.BackgroundColor3 = NexusUI.Theme.Input_Back
                inputFrame.BorderSizePixel  = 0
                inputFrame.Parent           = row
                Util.Corner(inputFrame, 6)
                Util.Stroke(inputFrame, NexusUI.Theme.Divider, 1, 0.3)

                local tb = Instance.new("TextBox")
                tb.Size             = UDim2.new(1, -12, 1, 0)
                tb.Position         = UDim2.new(0, 8, 0, 0)
                tb.Text             = default
                tb.PlaceholderText  = placeholder
                tb.PlaceholderColor3 = NexusUI.Theme.TextMuted
                tb.TextSize         = 13
                tb.Font             = Enum.Font.Gotham
                tb.TextColor3       = NexusUI.Theme.TextPrimary
                tb.BackgroundTransparency = 1
                tb.ClearTextOnFocus = false
                tb.TextXAlignment   = Enum.TextXAlignment.Left
                tb.Parent           = inputFrame

                tb.Focused:Connect(function()
                    Util.Tween(inputFrame, { BackgroundColor3 = NexusUI.Theme.Surface }, 0.15)
                    Util.Stroke(inputFrame, NexusUI.Theme.Accent, 1, 0.3)
                end)
                tb.FocusLost:Connect(function(enter)
                    Util.Tween(inputFrame, { BackgroundColor3 = NexusUI.Theme.Input_Back }, 0.15)
                    local val = tb.Text
                    if isNumber then val = tonumber(val) or 0; tb.Text = tostring(val) end
                    NexusUI.Flags[flag] = val
                    if enter then pcall(callback, val) end
                end)

                local Input = {}
                function Input:Set(val) tb.Text = tostring(val); NexusUI.Flags[flag] = val end
                function Input:Get() return tb.Text end
                return Input
            end

            -- --------------------------------------------------
            --  DROPDOWN
            -- --------------------------------------------------
            function Section:AddDropdown(opts)
                opts = opts or {}
                local label    = opts.Name     or "Dropdown"
                local items    = opts.Items    or {}
                local default  = opts.Default  or items[1]
                local flag     = opts.Flag     or label
                local callback = opts.Callback or function() end

                NexusUI.Flags[flag] = default

                local selected = default
                local open     = false

                local row = Instance.new("Frame")
                row.Size             = UDim2.new(1, 0, 0, 38)
                row.BackgroundColor3 = NexusUI.Theme.Surface
                row.BorderSizePixel  = 0
                row.ClipsDescendants = false
                row.Parent           = sectionFrame
                Util.Corner(row, 8)
                Util.Stroke(row, NexusUI.Theme.Divider, 1, 0.2)

                local lbl = Instance.new("TextLabel")
                lbl.Size             = UDim2.new(1, -50, 1, 0)
                lbl.Position         = UDim2.new(0, 12, 0, 0)
                lbl.Text             = label .. ":  " .. tostring(selected)
                lbl.TextSize         = 14
                lbl.Font             = Enum.Font.Gotham
                lbl.TextColor3       = NexusUI.Theme.TextPrimary
                lbl.TextXAlignment   = Enum.TextXAlignment.Left
                lbl.BackgroundTransparency = 1
                lbl.Parent           = row

                local arrow = Instance.new("TextLabel")
                arrow.Size             = UDim2.new(0, 30, 1, 0)
                arrow.Position         = UDim2.new(1, -36, 0, 0)
                arrow.Text             = "▾"
                arrow.TextSize         = 14
                arrow.Font             = Enum.Font.GothamBold
                arrow.TextColor3       = NexusUI.Theme.Accent
                arrow.BackgroundTransparency = 1
                arrow.Parent           = row

                -- Dropdown list
                local listFrame = Instance.new("Frame")
                listFrame.Size             = UDim2.new(1, 0, 0, 0)
                listFrame.Position         = UDim2.new(0, 0, 1, 4)
                listFrame.BackgroundColor3 = NexusUI.Theme.Dropdown_Back
                listFrame.BorderSizePixel  = 0
                listFrame.ClipsDescendants = true
                listFrame.ZIndex           = row.ZIndex + 5
                listFrame.Parent           = row
                Util.Corner(listFrame, 8)
                Util.Stroke(listFrame, NexusUI.Theme.Accent, 1, 0.6)

                local listLayout = Instance.new("UIListLayout")
                listLayout.SortOrder = Enum.SortOrder.LayoutOrder
                listLayout.Parent    = listFrame
                Util.Padding(listFrame, 4, 4, 4, 4)

                for _, item in ipairs(items) do
                    local optBtn = Instance.new("TextButton")
                    optBtn.Size             = UDim2.new(1, 0, 0, 30)
                    optBtn.BackgroundColor3 = NexusUI.Theme.Dropdown_Back
                    optBtn.BackgroundTransparency = 1
                    optBtn.Text             = tostring(item)
                    optBtn.TextSize         = 13
                    optBtn.Font             = Enum.Font.Gotham
                    optBtn.TextColor3       = NexusUI.Theme.TextSecondary
                    optBtn.ZIndex           = listFrame.ZIndex + 1
                    optBtn.Parent           = listFrame
                    Util.Corner(optBtn, 6)

                    optBtn.MouseEnter:Connect(function()
                        Util.Tween(optBtn, { BackgroundTransparency = 0.85, TextColor3 = NexusUI.Theme.TextPrimary }, 0.1)
                    end)
                    optBtn.MouseLeave:Connect(function()
                        Util.Tween(optBtn, { BackgroundTransparency = 1, TextColor3 = NexusUI.Theme.TextSecondary }, 0.1)
                    end)
                    optBtn.MouseButton1Click:Connect(function()
                        selected = item
                        NexusUI.Flags[flag] = item
                        lbl.Text = label .. ":  " .. tostring(item)
                        pcall(callback, item)
                        -- close
                        open = false
                        Util.Tween(listFrame, { Size = UDim2.new(1, 0, 0, 0) }, 0.2)
                        Util.Tween(arrow, { Rotation = 0 }, 0.2)
                    end)
                end

                local clickable = Instance.new("TextButton")
                clickable.Size             = UDim2.new(1, 0, 1, 0)
                clickable.BackgroundTransparency = 1
                clickable.Text             = ""
                clickable.ZIndex           = row.ZIndex + 1
                clickable.Parent           = row

                clickable.MouseButton1Click:Connect(function()
                    open = not open
                    local itemCount = #items
                    local targetH   = open and math.min(itemCount * 30 + 8, 160) or 0
                    Util.Tween(listFrame, { Size = UDim2.new(1, 0, 0, targetH) }, 0.25, Enum.EasingStyle.Back)
                    Util.Tween(arrow, { Rotation = open and 180 or 0 }, 0.2)
                end)

                local Dropdown = {}
                function Dropdown:Set(val)
                    selected = val
                    NexusUI.Flags[flag] = val
                    lbl.Text = label .. ":  " .. tostring(val)
                    pcall(callback, val)
                end
                function Dropdown:Get() return selected end
                function Dropdown:Refresh(newItems)
                    for _, c in ipairs(listFrame:GetChildren()) do
                        if c:IsA("TextButton") then c:Destroy() end
                    end
                    items = newItems
                end
                return Dropdown
            end

            -- --------------------------------------------------
            --  KEYBIND
            -- --------------------------------------------------
            function Section:AddKeybind(opts)
                opts = opts or {}
                local label    = opts.Name    or "Keybind"
                local default  = opts.Default or Enum.KeyCode.RightShift
                local flag     = opts.Flag    or label
                local callback = opts.Callback or function() end

                NexusUI.Flags[flag] = default
                local currentKey = default
                local listening  = false

                local row = Instance.new("Frame")
                row.Size             = UDim2.new(1, 0, 0, 38)
                row.BackgroundColor3 = NexusUI.Theme.Surface
                row.BorderSizePixel  = 0
                row.Parent           = sectionFrame
                Util.Corner(row, 8)
                Util.Stroke(row, NexusUI.Theme.Divider, 1, 0.2)

                local lbl = Instance.new("TextLabel")
                lbl.Size             = UDim2.new(1, -100, 1, 0)
                lbl.Position         = UDim2.new(0, 12, 0, 0)
                lbl.Text             = label
                lbl.TextSize         = 14
                lbl.Font             = Enum.Font.Gotham
                lbl.TextColor3       = NexusUI.Theme.TextPrimary
                lbl.TextXAlignment   = Enum.TextXAlignment.Left
                lbl.BackgroundTransparency = 1
                lbl.Parent           = row

                local keyBtn = Instance.new("TextButton")
                keyBtn.Size             = UDim2.new(0, 80, 0, 26)
                keyBtn.Position         = UDim2.new(1, -90, 0.5, -13)
                keyBtn.BackgroundColor3 = NexusUI.Theme.Panel
                keyBtn.BorderSizePixel  = 0
                keyBtn.Text             = tostring(currentKey.Name)
                keyBtn.TextSize         = 12
                keyBtn.Font             = Enum.Font.GothamBold
                keyBtn.TextColor3       = NexusUI.Theme.Accent
                keyBtn.Parent           = row
                Util.Corner(keyBtn, 6)
                Util.Stroke(keyBtn, NexusUI.Theme.Accent, 1, 0.5)

                keyBtn.MouseButton1Click:Connect(function()
                    listening = true
                    keyBtn.Text      = "..."
                    keyBtn.TextColor3 = NexusUI.Theme.Warning
                end)

                UserInputService.InputBegan:Connect(function(input, gp)
                    if gp then return end
                    if listening and input.UserInputType == Enum.UserInputType.Keyboard then
                        currentKey = input.KeyCode
                        NexusUI.Flags[flag] = currentKey
                        keyBtn.Text       = currentKey.Name
                        keyBtn.TextColor3 = NexusUI.Theme.Accent
                        listening = false
                    elseif not listening and input.KeyCode == currentKey then
                        pcall(callback, currentKey)
                    end
                end)

                local Keybind = {}
                function Keybind:Set(key) currentKey = key; NexusUI.Flags[flag] = key; keyBtn.Text = key.Name end
                function Keybind:Get() return currentKey end
                return Keybind
            end

            -- --------------------------------------------------
            --  COLOR PICKER  (basic RGB sliders)
            -- --------------------------------------------------
            function Section:AddColorPicker(opts)
                opts = opts or {}
                local label    = opts.Name     or "Color"
                local default  = opts.Default  or Color3.fromRGB(74,240,255)
                local flag     = opts.Flag     or label
                local callback = opts.Callback or function() end

                NexusUI.Flags[flag] = default
                local r,g,b = default.R*255, default.G*255, default.B*255

                local row = Instance.new("Frame")
                row.Size             = UDim2.new(1, 0, 0, 130)
                row.BackgroundColor3 = NexusUI.Theme.Surface
                row.BorderSizePixel  = 0
                row.Parent           = sectionFrame
                Util.Corner(row, 8)
                Util.Stroke(row, NexusUI.Theme.Divider, 1, 0.2)

                local lbl = Instance.new("TextLabel")
                lbl.Size             = UDim2.new(1, -60, 0, 26)
                lbl.Position         = UDim2.new(0, 12, 0, 6)
                lbl.Text             = label
                lbl.TextSize         = 14
                lbl.Font             = Enum.Font.Gotham
                lbl.TextColor3       = NexusUI.Theme.TextPrimary
                lbl.TextXAlignment   = Enum.TextXAlignment.Left
                lbl.BackgroundTransparency = 1
                lbl.Parent           = row

                -- Preview swatch
                local swatch = Instance.new("Frame")
                swatch.Size             = UDim2.new(0, 36, 0, 22)
                swatch.Position         = UDim2.new(1, -48, 0, 8)
                swatch.BackgroundColor3 = default
                swatch.BorderSizePixel  = 0
                swatch.Parent           = row
                Util.Corner(swatch, 6)
                Util.Stroke(swatch, Color3.new(1,1,1), 1, 0.7)

                local function makeChannel(channelName, yOff, colour, getVal, setVal)
                    local channelLabel = Instance.new("TextLabel")
                    channelLabel.Size             = UDim2.new(0, 16, 0, 16)
                    channelLabel.Position         = UDim2.new(0, 12, 0, yOff)
                    channelLabel.Text             = channelName
                    channelLabel.TextSize         = 11
                    channelLabel.Font             = Enum.Font.GothamBold
                    channelLabel.TextColor3       = colour
                    channelLabel.BackgroundTransparency = 1
                    channelLabel.Parent           = row

                    local track = Instance.new("Frame")
                    track.Size             = UDim2.new(1, -68, 0, 8)
                    track.Position         = UDim2.new(0, 28, 0, yOff+4)
                    track.BackgroundColor3 = NexusUI.Theme.Slider_Back
                    track.BorderSizePixel  = 0
                    track.Parent           = row
                    Util.Corner(track, 4)

                    local fill = Instance.new("Frame")
                    fill.Size             = UDim2.new(getVal()/255, 0, 1, 0)
                    fill.BackgroundColor3 = colour
                    fill.BorderSizePixel  = 0
                    fill.Parent           = track
                    Util.Corner(fill, 4)

                    local valLbl = Instance.new("TextLabel")
                    valLbl.Size             = UDim2.new(0, 32, 0, 16)
                    valLbl.Position         = UDim2.new(1, -38, 0, yOff)
                    valLbl.Text             = tostring(math.floor(getVal()))
                    valLbl.TextSize         = 11
                    valLbl.Font             = Enum.Font.Gotham
                    valLbl.TextColor3       = NexusUI.Theme.TextSecondary
                    valLbl.BackgroundTransparency = 1
                    valLbl.TextXAlignment   = Enum.TextXAlignment.Right
                    valLbl.Parent           = row

                    local dragging = false
                    track.InputBegan:Connect(function(i)
                        if i.UserInputType == Enum.UserInputType.MouseButton1 then
                            dragging = true
                        end
                    end)
                    UserInputService.InputEnded:Connect(function(i)
                        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
                    end)
                    UserInputService.InputChanged:Connect(function(i)
                        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                            local pct = math.clamp((i.Position.X - track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
                            local val = pct * 255
                            setVal(val)
                            fill.Size = UDim2.new(pct,0,1,0)
                            valLbl.Text = tostring(math.floor(val))
                            swatch.BackgroundColor3 = Color3.fromRGB(r,g,b)
                            local col = Color3.fromRGB(r,g,b)
                            NexusUI.Flags[flag] = col
                            pcall(callback, col)
                        end
                    end)
                end

                makeChannel("R", 34, Color3.fromRGB(255,80,80),   function() return r end, function(v) r=v end)
                makeChannel("G", 62, Color3.fromRGB(80,255,140),  function() return g end, function(v) g=v end)
                makeChannel("B", 90, Color3.fromRGB(80,160,255),  function() return b end, function(v) b=v end)

                local ColorPicker = {}
                function ColorPicker:Set(col)
                    r,g,b = col.R*255, col.G*255, col.B*255
                    swatch.BackgroundColor3 = col
                    NexusUI.Flags[flag] = col
                    pcall(callback, col)
                end
                function ColorPicker:Get() return Color3.fromRGB(r,g,b) end
                return ColorPicker
            end

            -- --------------------------------------------------
            --  LABEL
            -- --------------------------------------------------
            function Section:AddLabel(text, colour)
                local lbl = Instance.new("TextLabel")
                lbl.Size             = UDim2.new(1, 0, 0, 24)
                lbl.Text             = text
                lbl.TextSize         = 13
                lbl.Font             = Enum.Font.Gotham
                lbl.TextColor3       = colour or NexusUI.Theme.TextSecondary
                lbl.TextXAlignment   = Enum.TextXAlignment.Left
                lbl.BackgroundTransparency = 1
                lbl.Parent           = sectionFrame

                local Label = {}
                function Label:Set(newText) lbl.Text = newText end
                function Label:SetColor(c)  lbl.TextColor3 = c  end
                return Label
            end

            -- --------------------------------------------------
            --  PARAGRAPH
            -- --------------------------------------------------
            function Section:AddParagraph(title, body)
                local frame = Instance.new("Frame")
                frame.Size             = UDim2.new(1, 0, 0, 0)
                frame.AutomaticSize    = Enum.AutomaticSize.Y
                frame.BackgroundColor3 = NexusUI.Theme.Surface
                frame.BorderSizePixel  = 0
                frame.Parent           = sectionFrame
                Util.Corner(frame, 8)
                Util.Stroke(frame, NexusUI.Theme.Divider, 1, 0.2)
                Util.Padding(frame, 10, 10, 12, 12)

                local tLbl = Instance.new("TextLabel")
                tLbl.Size             = UDim2.new(1, 0, 0, 18)
                tLbl.Text             = title
                tLbl.TextSize         = 13
                tLbl.Font             = Enum.Font.GothamBold
                tLbl.TextColor3       = NexusUI.Theme.Accent
                tLbl.TextXAlignment   = Enum.TextXAlignment.Left
                tLbl.BackgroundTransparency = 1
                tLbl.Parent           = frame

                local bLbl = Instance.new("TextLabel")
                bLbl.Size             = UDim2.new(1, 0, 0, 0)
                bLbl.Position         = UDim2.new(0, 0, 0, 22)
                bLbl.AutomaticSize    = Enum.AutomaticSize.Y
                bLbl.Text             = body
                bLbl.TextSize         = 12
                bLbl.Font             = Enum.Font.Gotham
                bLbl.TextColor3       = NexusUI.Theme.TextSecondary
                bLbl.TextXAlignment   = Enum.TextXAlignment.Left
                bLbl.TextWrapped      = true
                bLbl.BackgroundTransparency = 1
                bLbl.Parent           = frame

                return { SetTitle = function(_,t) tLbl.Text=t end, SetBody = function(_,b) bLbl.Text=b end }
            end

            return Section
        end  -- AddSection

        return Tab
    end  -- AddTab

    table.insert(NexusUI.Windows, Window)
    return Window
end

-- ============================================================
--  DESTROY ALL
-- ============================================================
function NexusUI:DestroyAll()
    for _, win in ipairs(self.Windows) do
        pcall(function() win._gui:Destroy() end)
    end
    self.Windows = {}
    self.Flags   = {}
    if NotifHolder then pcall(function() NotifHolder:Destroy() end) end
end

return NexusUI
