local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")

local player = Players.LocalPlayer
local guiParent = player:WaitForChild("PlayerGui")
local previous = guiParent:FindFirstChild("CraftToolsBlocktopia")
if previous then previous:Destroy() end

local events = ReplicatedStorage:WaitForChild("Events")
local modules = ReplicatedStorage:WaitForChild("Modules")
local blockModule = require(modules:WaitForChild("BlockModule"))
local lockModule = require(modules:WaitForChild("LockModule"))
local state = { anti = false, jump = false, owner = false, wrench = false, damage = false, wall = false, breakOne = false }
local connections = {}
local disabledScripts = {}
local changedParts = {}
local changedLocks = {}
local touchStates = {}
local originalOwner = nil
local originalOwnerCheck = lockModule.IsPlayerOwnerOrAdminOfTile
local originalLockedCheck = lockModule.IsTileLocked
local busyBreaking = false
local lastJump = 0

local gui = Instance.new("ScreenGui")
gui.Name = "CraftToolsBlocktopia"
gui.ResetOnSpawn = false
gui.DisplayOrder = 30
gui.Parent = guiParent

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(1, 0)
panel.Position = UDim2.new(1, -10, 0, 50)
panel.Size = UDim2.new(0, 260, 1, -65)
panel.BackgroundColor3 = Color3.fromRGB(25, 30, 32)
panel.BorderSizePixel = 0
panel.Parent = gui

local maxSize = Instance.new("UISizeConstraint")
maxSize.MaxSize = Vector2.new(260, 510)
maxSize.Parent = panel

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 7)
panelCorner.Parent = panel

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(10, 7)
title.Size = UDim2.new(1, -50, 0, 28)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.Text = "BLOCKTOPIA tests"
title.TextColor3 = Color3.fromRGB(237, 243, 241)
title.TextSize = 15
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local close = Instance.new("TextButton")
close.Name = "Close"
close.AnchorPoint = Vector2.new(1, 0)
close.Position = UDim2.new(1, -7, 0, 7)
close.Size = UDim2.fromOffset(30, 28)
close.BackgroundColor3 = Color3.fromRGB(65, 73, 75)
close.BorderSizePixel = 0
close.Font = Enum.Font.GothamBold
close.Text = "X"
close.TextColor3 = Color3.fromRGB(255, 255, 255)
close.TextSize = 13
close.Parent = panel

local scroll = Instance.new("ScrollingFrame")
scroll.Position = UDim2.fromOffset(8, 43)
scroll.Size = UDim2.new(1, -16, 1, -111)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.new()
scroll.Parent = panel

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 5)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scroll

local status = Instance.new("TextLabel")
status.Position = UDim2.new(0, 8, 1, -62)
status.Size = UDim2.new(1, -16, 0, 54)
status.BackgroundColor3 = Color3.fromRGB(43, 50, 52)
status.BorderSizePixel = 0
status.Font = Enum.Font.Gotham
status.Text = "Listo"
status.TextColor3 = Color3.fromRGB(222, 235, 231)
status.TextSize = 12
status.TextWrapped = true
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextYAlignment = Enum.TextYAlignment.Center
status.Parent = panel

local statusPadding = Instance.new("UIPadding")
statusPadding.PaddingLeft = UDim.new(0, 8)
statusPadding.PaddingRight = UDim.new(0, 8)
statusPadding.Parent = status

local function report(message)
	print("Blocktopia tests: " .. message)
	if gui.Parent then status.Text = message end
end

local function characterParts()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return character, humanoid, root
end

local function makeButton(label, callback)
	local button = Instance.new("TextButton")
	button.Name = label:gsub("%W", "")
	button.Size = UDim2.new(1, -5, 0, 40)
	button.BackgroundColor3 = Color3.fromRGB(56, 66, 68)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamMedium
	button.Text = label
	button.TextColor3 = Color3.fromRGB(236, 242, 240)
	button.TextSize = 13
	button.Parent = scroll
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 5)
	corner.Parent = button
	button.Activated:Connect(callback)
	return button
end

local function makeToggle(label, key, onChange)
	local button
	button = makeButton(label, function()
		state[key] = not state[key]
		local ok, result = pcall(onChange, state[key])
		if not ok then
			state[key] = false
			report(label .. ": " .. tostring(result))
		elseif result then
			report(result)
		end
		button.Text = label .. (state[key] and "  ON" or "  OFF")
		button.BackgroundColor3 = state[key] and Color3.fromRGB(29, 122, 91) or Color3.fromRGB(56, 66, 68)
	end)
	button.Text = label .. "  OFF"
	return button
end

local function setAntiCheat(active)
	if active then
		local scripts = {
			player:FindFirstChild("PlayerScripts") and player.PlayerScripts:FindFirstChild("MacroDetection"),
			player.Character and player.Character:FindFirstChild("Anticheat_Local"),
		}
		local count = 0
		for _, scriptObject in scripts do
			if scriptObject and scriptObject:IsA("LocalScript") and not scriptObject.Disabled then
				disabledScripts[scriptObject] = true
				scriptObject.Disabled = true
				count += 1
			end
		end
		return count .. " scripts locales desactivados"
	end
	for scriptObject in pairs(disabledScripts) do
		if scriptObject.Parent then scriptObject.Disabled = false end
		disabledScripts[scriptObject] = nil
	end
end

local function applyOwner(active)
	local worldData = workspace:FindFirstChild("WorldData")
	local worldOwner = worldData and worldData:FindFirstChild("WorldOwner")
	if active then
		if worldOwner then
			originalOwner = worldOwner.Value
			worldOwner.Value = player.Name
		end
		lockModule.IsPlayerOwnerOrAdminOfTile = function() return true end
		lockModule.IsTileLocked = function() return false end
		for _, lock in CollectionService:GetTagged("Lock") do
			if changedLocks[lock] == nil then changedLocks[lock] = lock:GetAttribute("LockOwner") end
			lock:SetAttribute("LockOwner", player.UserId)
		end
		return "Owner local activo; permisos servidor en prueba"
	end
	if worldOwner and worldOwner.Value == player.Name and originalOwner then worldOwner.Value = originalOwner end
	originalOwner = nil
	if lockModule.IsPlayerOwnerOrAdminOfTile ~= originalOwnerCheck then lockModule.IsPlayerOwnerOrAdminOfTile = originalOwnerCheck end
	if lockModule.IsTileLocked ~= originalLockedCheck then lockModule.IsTileLocked = originalLockedCheck end
	for lock, owner in pairs(changedLocks) do
		if lock.Parent then lock:SetAttribute("LockOwner", owner) end
		changedLocks[lock] = nil
	end
end

local function restoreCollisions()
	for part, collision in pairs(changedParts) do
		if part.Parent then part.CanCollide = collision end
		changedParts[part] = nil
	end
end

local function restoreTouch()
	for part, canTouch in pairs(touchStates) do
		if part.Parent then part.CanTouch = canTouch end
		touchStates[part] = nil
	end
end

makeToggle("Anticheat local", "anti", setAntiCheat)
makeToggle("Saltos infinitos", "jump", function() end)
makeToggle("Modo owner", "owner", applyOwner)
makeToggle("Wrench libre", "wrench", function(active)
	return active and "Toca un objeto para solicitar wrench" or nil
end)
makeToggle("No damage", "damage", function(active)
	if not active then restoreTouch() end
end)
makeToggle("Wall hack", "wall", function(active)
	if not active then restoreCollisions() end
end)
makeToggle("1 hit break", "breakOne", function(active)
	return active and "Toca un bloque para probar golpe rapido" or nil
end)

local itemInput = Instance.new("TextBox")
itemInput.Name = "ItemName"
itemInput.Size = UDim2.new(1, -5, 0, 38)
itemInput.BackgroundColor3 = Color3.fromRGB(44, 53, 55)
itemInput.BorderSizePixel = 0
itemInput.Font = Enum.Font.Gotham
itemInput.PlaceholderText = "Nombre o ID del objeto"
itemInput.Text = ""
itemInput.TextColor3 = Color3.fromRGB(245, 245, 245)
itemInput.TextSize = 13
itemInput.ClearTextOnFocus = false
itemInput.Parent = scroll

makeButton("Solicitar objeto", function()
	local query = itemInput.Text:lower():gsub("^%s+", ""):gsub("%s+$", "")
	if query == "" then return report("Escribe un nombre o ID") end
	local found = nil
	local direct = blockModule.blocks[tonumber(query) or query]
	if type(direct) == "table" then found = direct end
	if not found then
		for _, block in pairs(blockModule.blocks) do
			if type(block) == "table" and type(block.Name) == "string" and block.Name:lower() == query then
				found = block
				break
			end
		end
	end
	if not found or not found.Name then return report("Objeto no presente en BlockCatalog") end
	local getBlock = events:FindFirstChild("GetBlock")
	if not getBlock then return report("GetBlock no disponible") end
	getBlock:FireServer(found.Name)
	report("GetBlock enviado: " .. found.Name .. ". Verifica el inventario.")
end)

local function forceJump()
	if not state.jump or os.clock() - lastJump < 0.1 then return end
	local _, humanoid, root = characterParts()
	if not humanoid or not root or humanoid.Health <= 0 then return end
	lastJump = os.clock()
	local impulse = math.sqrt(2 * workspace.Gravity * math.max(humanoid.JumpHeight, 7.2))
	local velocity = root.AssemblyLinearVelocity
	root.AssemblyLinearVelocity = Vector3.new(velocity.X, impulse, velocity.Z)
	humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
end

table.insert(connections, UserInputService.JumpRequest:Connect(forceJump))
local jumpEvent = events:FindFirstChild("Jump")
if jumpEvent and jumpEvent:IsA("BindableEvent") then
	table.insert(connections, jumpEvent.Event:Connect(forceJump))
end

table.insert(connections, RunService.Heartbeat:Connect(function()
	if not gui.Parent then return end
	if state.anti then setAntiCheat(true) end
	if state.damage then
		local character, humanoid = characterParts()
		if humanoid and humanoid.Health > 0 and humanoid.Health < humanoid.MaxHealth then
			humanoid.Health = humanoid.MaxHealth
		end
		local second = character and character:FindFirstChild("HumanoidSecond")
		if second and touchStates[second] == nil then touchStates[second] = second.CanTouch end
		if second then second.CanTouch = false end
	end
end))

local overlap = OverlapParams.new()
overlap.FilterType = Enum.RaycastFilterType.Exclude
overlap.MaxParts = 160
table.insert(connections, RunService.Stepped:Connect(function()
	if not state.wall then return end
	local character, _, root = characterParts()
	if not character or not root then return end
	overlap.FilterDescendantsInstances = { character }
	local near = {}
	local feet = root.Position.Y - root.Size.Y / 2
	for _, part in workspace:GetPartBoundsInBox(CFrame.new(root.Position), Vector3.new(18, 18, 8), overlap) do
		local model = part:FindFirstAncestorWhichIsA("Model")
		if part:IsA("BasePart") and model and CollectionService:HasTag(model, "Block") then
			local top = part.Position.Y + part.Size.Y / 2
			local supports = math.abs(top - feet) < 0.65 and math.abs(part.Position.X - root.Position.X) < (part.Size.X + root.Size.X) / 2
			if not supports then
				near[part] = true
				if changedParts[part] == nil then changedParts[part] = part.CanCollide end
				part.CanCollide = false
			end
		end
	end
	for part, collision in pairs(changedParts) do
		if not near[part] then
			if part.Parent then part.CanCollide = collision end
			changedParts[part] = nil
		end
	end
end))

local function targetModel(input)
	local camera = workspace.CurrentCamera
	if not camera then return nil end
	local ray = camera:ScreenPointToRay(input.Position.X, input.Position.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character }
	local hit = workspace:Raycast(ray.Origin, ray.Direction * 250, params)
	if not hit then return nil end
	local model = hit.Instance:FindFirstAncestorWhichIsA("Model")
	return model
end

table.insert(connections, UserInputService.InputBegan:Connect(function(input, processed)
	if processed or not gui.Parent then return end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
	local model = targetModel(input)
	if not model then return end
	if state.wrench and (CollectionService:HasTag(model, "CreateWrench") or CollectionService:HasTag(model, "PlayerWrench")) then
		local remote = events:FindFirstChild("RequestWrench")
		if remote then
			task.spawn(function()
				local ok, result = pcall(function() return remote:InvokeServer(model) end)
				report(ok and ("Wrench respondio: " .. tostring(result)) or "Wrench rechazado")
			end)
		end
	elseif state.breakOne and CollectionService:HasTag(model, "Block") and not busyBreaking then
		local remote = events:FindFirstChild("PunchBlock")
		if not remote then return end
		local blockId = model:GetAttribute("DefaultName") or model.Name
		local index = blockModule.invertedBlocks[blockId] or tonumber(blockId)
		local block = index and blockModule.blocks[index]
		local punches = math.clamp(tonumber(block and block.PunchesNeeded) or 8, 1, 25)
		busyBreaking = true
		task.spawn(function()
			for _ = 1, punches do
				if not gui.Parent or not state.breakOne or not model.Parent then break end
				remote:FireServer(model)
				task.wait(0.045)
			end
			busyBreaking = false
			report("PunchBlock enviado " .. punches .. " veces; comprueba el bloque")
		end)
	end
end))

table.insert(connections, CollectionService:GetInstanceAddedSignal("Lock"):Connect(function(lock)
	if not state.owner then return end
	if changedLocks[lock] == nil then changedLocks[lock] = lock:GetAttribute("LockOwner") end
	lock:SetAttribute("LockOwner", player.UserId)
end))

gui.Destroying:Connect(function()
	for _, connection in connections do connection:Disconnect() end
	for key in pairs(state) do state[key] = false end
	setAntiCheat(false)
	applyOwner(false)
	restoreCollisions()
	restoreTouch()
end)
close.Activated:Connect(function() gui:Destroy() end)
