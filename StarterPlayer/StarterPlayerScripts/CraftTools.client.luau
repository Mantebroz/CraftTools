-- Install as a LocalScript, or load this file from its raw GitHub URL.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local previousGui = playerGui:FindFirstChild("CraftTools")
if previousGui then previousGui:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "CraftTools"
gui.ResetOnSpawn = false
gui.DisplayOrder = 20
gui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(1, 0)
panel.Position = UDim2.new(1, -12, 0, 58)
panel.Size = UDim2.fromOffset(178, 242)
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
local noclipEnabled = makeToggle("Noclip", 4)

local addItemButton = Instance.new("TextButton")
addItemButton.Name = "AddRandomItem"
addItemButton.LayoutOrder = 5
addItemButton.Size = UDim2.new(1, 0, 0, 42)
addItemButton.BackgroundColor3 = Color3.fromRGB(117, 71, 51)
addItemButton.BorderSizePixel = 0
addItemButton.Font = Enum.Font.GothamMedium
addItemButton.Text = "Add random item"
addItemButton.TextColor3 = Color3.fromRGB(248, 241, 236)
addItemButton.TextSize = 13
addItemButton.Parent = panel

local addItemCorner = Instance.new("UICorner")
addItemCorner.CornerRadius = UDim.new(0, 6)
addItemCorner.Parent = addItemButton

local status = Instance.new("TextLabel")
status.Name = "Status"
status.LayoutOrder = 6
status.Size = UDim2.new(1, 0, 0, 16)
status.BackgroundTransparency = 1
status.Font = Enum.Font.Gotham
status.Text = "Local test items: 0"
status.TextColor3 = Color3.fromRGB(183, 196, 194)
status.TextSize = 11
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = panel

local originalCollision = {}
local function restoreCollision()
	for part, canCollide in pairs(originalCollision) do
		if part.Parent then part.CanCollide = canCollide end
		originalCollision[part] = nil
	end
end

local noclipConnection = RunService.Stepped:Connect(function()
	if not gui.Parent then
		restoreCollision()
		return
	end
	if not noclipEnabled() then
		restoreCollision()
		return
	end
	local tiles = workspace:FindFirstChild("Tiles")
	if not tiles then return end
	for _, part in tiles:GetDescendants() do
		if part:IsA("BasePart") then
			if originalCollision[part] == nil then
				originalCollision[part] = part.CanCollide
			end
			part.CanCollide = false
		end
	end
end)

local random = Random.new()
local itemChoices = {
	{ name = "Ruby Block", color = Color3.fromRGB(215, 72, 77), shape = Enum.PartType.Block },
	{ name = "Mint Orb", color = Color3.fromRGB(69, 190, 151), shape = Enum.PartType.Ball },
	{ name = "Gold Block", color = Color3.fromRGB(232, 177, 56), shape = Enum.PartType.Block },
	{ name = "Sky Orb", color = Color3.fromRGB(82, 161, 228), shape = Enum.PartType.Ball },
}
local addedCount = 0

addItemButton.Activated:Connect(function()
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		status.Text = "Backpack unavailable"
		return
	end
	local choice = itemChoices[random:NextInteger(1, #itemChoices)]
	local tool = Instance.new("Tool")
	tool.Name = choice.name
	tool.ToolTip = "CraftTools local test item"
	tool.CanBeDropped = false

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(1, 1, 1)
	handle.Shape = choice.shape
	handle.Color = choice.color
	handle.CanCollide = false
	handle.CanTouch = false
	handle.Massless = true
	handle.Parent = tool
	tool.Parent = backpack

	addedCount += 1
	status.Text = choice.name .. " (local) #" .. addedCount
end)

local activeInputs = {}
local function isPointer(input)
	return input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseButton1
end

UserInputService.InputBegan:Connect(function(input, processed)
	if gui.Parent and isPointer(input) and not processed and teleportEnabled() then
		activeInputs[input] = Vector2.new(input.Position.X, input.Position.Y)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	local start = activeInputs[input]
	activeInputs[input] = nil
	if not gui.Parent or not start or not teleportEnabled() then return end

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
	local destination = Vector3.new(point.X, point.Y, root.Position.Z)
	character:PivotTo(character:GetPivot() + (destination - root.Position))
	root.AssemblyLinearVelocity = Vector3.zero
end)

UserInputService.JumpRequest:Connect(function()
	if not gui.Parent or not infiniteJumpEnabled() then return end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then return end
	local jumpSpeed = humanoid.UseJumpPower and humanoid.JumpPower
		or math.sqrt(2 * workspace.Gravity * humanoid.JumpHeight)
	local velocity = root.AssemblyLinearVelocity
	humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	root.AssemblyLinearVelocity = Vector3.new(velocity.X, jumpSpeed, 0)
end)

gui.Destroying:Connect(function()
	noclipConnection:Disconnect()
	restoreCollision()
end)
