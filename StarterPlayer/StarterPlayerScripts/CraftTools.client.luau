-- Install as a LocalScript in StarterPlayerScripts.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("CraftToolsRemote", 15)
if not remote then
	warn("CraftTools: install CraftTools.server.luau in ServerScriptService first")
	return
end

local gui = Instance.new("ScreenGui")
gui.Name = "CraftTools"
gui.ResetOnSpawn = false
gui.DisplayOrder = 20
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(1, 0)
panel.Position = UDim2.new(1, -12, 0, 58)
panel.Size = UDim2.fromOffset(178, 124)
panel.BackgroundColor3 = Color3.fromRGB(24, 29, 32)
panel.BorderSizePixel = 0
panel.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = panel

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(75, 88, 91)
stroke.Thickness = 1
stroke.Parent = panel

local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 8)
padding.PaddingRight = UDim.new(0, 8)
padding.PaddingTop = UDim.new(0, 7)
padding.Parent = panel

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 5)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = panel

local title = Instance.new("TextLabel")
title.Name = "Title"
title.LayoutOrder = 1
title.Size = UDim2.new(1, 0, 0, 18)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.Text = "CraftTools"
title.TextColor3 = Color3.fromRGB(232, 238, 237)
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local function makeToggle(name, order)
	local button = Instance.new("TextButton")
	button.Name = name .. "Toggle"
	button.LayoutOrder = order
	button.Size = UDim2.new(1, 0, 0, 42)
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Font = Enum.Font.GothamMedium
	button.TextSize = 13
	button.TextColor3 = Color3.fromRGB(238, 243, 242)
	button.Parent = panel

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 6)
	buttonCorner.Parent = button

	local enabled = false
	local function render()
		button.Text = name .. (enabled and "  ON" or "  OFF")
		button.BackgroundColor3 = enabled and Color3.fromRGB(32, 121, 105) or Color3.fromRGB(58, 65, 68)
	end
	button.Activated:Connect(function()
		enabled = not enabled
		render()
	end)
	render()
	return function() return enabled end
end

local teleportEnabled = makeToggle("Teleport", 2)
local infiniteJumpEnabled = makeToggle("Infinite jump", 3)

local activeInputs = {}
local function isPointer(input)
	return input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseButton1
end

UserInputService.InputBegan:Connect(function(input, processed)
	if isPointer(input) and not processed and teleportEnabled() then
		activeInputs[input] = Vector2.new(input.Position.X, input.Position.Y)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	local start = activeInputs[input]
	activeInputs[input] = nil
	if not start or not teleportEnabled() then return end

	local finish = Vector2.new(input.Position.X, input.Position.Y)
	if (finish - start).Magnitude > 16 then return end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local camera = workspace.CurrentCamera
	if not root or not camera then return end

	-- Intersect the touch ray with the player's current X/Y plane.
	local ray = camera:ScreenPointToRay(finish.X, finish.Y)
	if math.abs(ray.Direction.Z) < 0.001 then return end
	local distance = (root.Position.Z - ray.Origin.Z) / ray.Direction.Z
	if distance <= 0 then return end
	local point = ray.Origin + ray.Direction * distance
	remote:FireServer("teleport", Vector2.new(point.X, point.Y))
end)

UserInputService.JumpRequest:Connect(function()
	if infiniteJumpEnabled() then
		remote:FireServer("jump")
	end
end)
