local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local previousGui = playerGui:FindFirstChild("CraftTools")
if previousGui then
	previousGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "CraftTools"
gui.ResetOnSpawn = false
gui.DisplayOrder = 20
gui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(1, 0)
panel.Position = UDim2.new(1, -12, 0, 58)
panel.Size = UDim2.fromOffset(190, 84)
panel.BackgroundColor3 = Color3.fromRGB(27, 31, 34)
panel.BorderSizePixel = 0
panel.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = panel

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(76, 88, 90)
stroke.Thickness = 1
stroke.Parent = panel

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Position = UDim2.fromOffset(12, 8)
title.Size = UDim2.new(1, -24, 0, 20)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.Text = "CraftTools"
title.TextColor3 = Color3.fromRGB(232, 238, 237)
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local toggle = Instance.new("TextButton")
toggle.Name = "WallHackToggle"
toggle.Position = UDim2.fromOffset(8, 35)
toggle.Size = UDim2.new(1, -16, 0, 40)
toggle.BackgroundColor3 = Color3.fromRGB(54, 62, 65)
toggle.BorderSizePixel = 0
toggle.AutoButtonColor = false
toggle.Font = Enum.Font.GothamMedium
toggle.Text = "Wall hack"
toggle.TextColor3 = Color3.fromRGB(238, 243, 242)
toggle.TextSize = 13
toggle.TextXAlignment = Enum.TextXAlignment.Left
toggle.Parent = panel

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 6)
toggleCorner.Parent = toggle

local togglePadding = Instance.new("UIPadding")
togglePadding.PaddingLeft = UDim.new(0, 10)
togglePadding.Parent = toggle

local switch = Instance.new("Frame")
switch.Name = "Switch"
switch.AnchorPoint = Vector2.new(1, 0.5)
switch.Position = UDim2.new(1, -10, 0.5, 0)
switch.Size = UDim2.fromOffset(38, 22)
switch.BorderSizePixel = 0
switch.Parent = toggle

local switchCorner = Instance.new("UICorner")
switchCorner.CornerRadius = UDim.new(1, 0)
switchCorner.Parent = switch

local knob = Instance.new("Frame")
knob.Name = "Knob"
knob.AnchorPoint = Vector2.new(0, 0.5)
knob.Size = UDim2.fromOffset(16, 16)
knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
knob.BorderSizePixel = 0
knob.Parent = switch

local knobCorner = Instance.new("UICorner")
knobCorner.CornerRadius = UDim.new(1, 0)
knobCorner.Parent = knob

local enabled = false
local aabbModule = nil
local originalSweep = nil
local patchedSweep = nil
local suspendedCorrections = {}

local function resumeCorrections()
	for connection in pairs(suspendedCorrections) do
		pcall(function()
			connection:Enable()
		end)
		suspendedCorrections[connection] = nil
	end
end

local function suspendCorrections(handlerScript)
	if type(getconnections) ~= "function" then
		warn("CraftTools: this client cannot inspect PlayerSetPosition connections")
		return
	end

	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local remote = remotes and remotes:FindFirstChild("PlayerSetPosition")
	if not remote then
		warn("CraftTools: PlayerSetPosition was not found")
		return
	end

	local found = false
	local ok, connections = pcall(getconnections, remote.OnClientEvent)
	if not ok or type(connections) ~= "table" then
		warn("CraftTools: PlayerSetPosition connections could not be inspected")
		return
	end

	for _, connection in ipairs(connections) do
		local identified, belongsToHandler = pcall(function()
			local callback = connection.Function
			return type(callback) == "function" and getfenv(callback).script == handlerScript
		end)
		if identified and belongsToHandler then
			found = true
			local disabled = pcall(function()
				if connection.Enabled ~= false then
					connection:Disable()
					suspendedCorrections[connection] = true
				end
			end)
			if not disabled then
				warn("CraftTools: PlayerSetPosition listener could not be disabled")
			end
		end
	end

	if not found then
		warn("CraftTools: PlayerMovementHandler correction listener was not identified")
	end
end

local function render()
	toggle:SetAttribute("Enabled", enabled)
	toggle.BackgroundColor3 = enabled and Color3.fromRGB(34, 94, 83) or Color3.fromRGB(54, 62, 65)
	switch.BackgroundColor3 = enabled and Color3.fromRGB(54, 176, 139) or Color3.fromRGB(104, 115, 118)
	knob.Position = enabled and UDim2.fromOffset(19, 11) or UDim2.fromOffset(3, 11)
end

local function stopWallHack()
	enabled = false
	resumeCorrections()
	if aabbModule and aabbModule.SweepAABB == patchedSweep then
		aabbModule.SweepAABB = originalSweep
	end
	aabbModule = nil
	originalSweep = nil
	patchedSweep = nil
	render()
end

local function startWallHack()
	local modules = ReplicatedStorage:FindFirstChild("Modules")
	local aabbScript = modules and modules:FindFirstChild("AABB")
	local playerScripts = player:FindFirstChild("PlayerScripts")
	local movementScript = playerScripts and playerScripts:FindFirstChild("PlayerMovement")
	local handlerScript = movementScript and movementScript:FindFirstChild("PlayerMovementHandler")
	if not aabbScript or not movementScript then
		warn("CraftTools: AABB or PlayerMovement was not found")
		return
	end

	local aabbOk, aabb = pcall(require, aabbScript)
	local movementOk, movement = pcall(require, movementScript)
	if not aabbOk or not movementOk or type(aabb) ~= "table" or type(aabb.SweepAABB) ~= "function"
		or type(movement) ~= "table" or not movement.Hitbox then
		warn("CraftTools: custom movement modules are not ready")
		return
	end

	aabbModule = aabb
	originalSweep = aabb.SweepAABB
	patchedSweep = function(position, size, tilePosition, tileSize, velocity)
		local contactTime, normal = originalSweep(position, size, tilePosition, tileSize, velocity)

		-- The game's movement handler calls this sweep for each 4.5-unit tile.
		-- Keep upward-facing contacts so floors still support the player.
		if enabled and position == movement.Position and size == movement.Hitbox.Size
			and tileSize == Vector3.new(4.5, 4.5, 0) and normal and normal[2] ~= 1 then
			return 1, nil
		end

		return contactTime, normal
	end

	aabb.SweepAABB = patchedSweep
	enabled = true
	if handlerScript then
		suspendCorrections(handlerScript)
	end
	render()
end

toggle.Activated:Connect(function()
	if enabled then
		stopWallHack()
	else
		startWallHack()
	end
end)

local respawnConnection = player.CharacterAdded:Connect(function()
	if enabled then
		stopWallHack()
	end
end)
gui.Destroying:Connect(function()
	respawnConnection:Disconnect()
	stopWallHack()
end)
render()
