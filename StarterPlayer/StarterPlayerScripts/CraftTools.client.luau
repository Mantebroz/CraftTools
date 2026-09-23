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
panel.Size = UDim2.fromOffset(190, 128)
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

local auditButton = Instance.new("TextButton")
auditButton.Name = "OpenAudit"
auditButton.Position = UDim2.fromOffset(8, 82)
auditButton.Size = UDim2.new(1, -16, 0, 38)
auditButton.BackgroundColor3 = Color3.fromRGB(54, 62, 65)
auditButton.BorderSizePixel = 0
auditButton.Font = Enum.Font.GothamMedium
auditButton.Text = "Auditoria"
auditButton.TextColor3 = Color3.fromRGB(238, 243, 242)
auditButton.TextSize = 13
auditButton.Parent = panel

local auditButtonCorner = Instance.new("UICorner")
auditButtonCorner.CornerRadius = UDim.new(0, 6)
auditButtonCorner.Parent = auditButton

local auditPanel = Instance.new("Frame")
auditPanel.Name = "AuditPanel"
auditPanel.AnchorPoint = Vector2.new(1, 0)
auditPanel.Position = UDim2.new(1, -12, 0, 58)
auditPanel.Size = UDim2.new(1, -24, 1, -116)
auditPanel.BackgroundColor3 = Color3.fromRGB(27, 31, 34)
auditPanel.BorderSizePixel = 0
auditPanel.Visible = false
auditPanel.Parent = gui

local auditSize = Instance.new("UISizeConstraint")
auditSize.MaxSize = Vector2.new(340, 500)
auditSize.Parent = auditPanel

local auditCorner = Instance.new("UICorner")
auditCorner.CornerRadius = UDim.new(0, 8)
auditCorner.Parent = auditPanel

local auditStroke = Instance.new("UIStroke")
auditStroke.Color = Color3.fromRGB(76, 88, 90)
auditStroke.Thickness = 1
auditStroke.Parent = auditPanel

local auditTitle = Instance.new("TextLabel")
auditTitle.Position = UDim2.fromOffset(12, 8)
auditTitle.Size = UDim2.new(1, -64, 0, 24)
auditTitle.BackgroundTransparency = 1
auditTitle.Font = Enum.Font.GothamBold
auditTitle.Text = "Auditoria"
auditTitle.TextColor3 = Color3.fromRGB(232, 238, 237)
auditTitle.TextSize = 15
auditTitle.TextXAlignment = Enum.TextXAlignment.Left
auditTitle.Parent = auditPanel

local backButton = Instance.new("TextButton")
backButton.Name = "Back"
backButton.AnchorPoint = Vector2.new(1, 0)
backButton.Position = UDim2.new(1, -8, 0, 7)
backButton.Size = UDim2.fromOffset(36, 28)
backButton.BackgroundColor3 = Color3.fromRGB(54, 62, 65)
backButton.BorderSizePixel = 0
backButton.Font = Enum.Font.GothamBold
backButton.Text = "<"
backButton.TextColor3 = Color3.fromRGB(238, 243, 242)
backButton.TextSize = 18
backButton.Parent = auditPanel

local backCorner = Instance.new("UICorner")
backCorner.CornerRadius = UDim.new(0, 5)
backCorner.Parent = backButton

local actions = Instance.new("ScrollingFrame")
actions.Name = "Actions"
actions.Position = UDim2.fromOffset(8, 42)
actions.Size = UDim2.new(1, -16, 1, -147)
actions.BackgroundTransparency = 1
actions.BorderSizePixel = 0
actions.ScrollBarThickness = 4
actions.CanvasSize = UDim2.new()
actions.AutomaticCanvasSize = Enum.AutomaticSize.Y
actions.Parent = auditPanel

local actionsLayout = Instance.new("UIListLayout")
actionsLayout.Padding = UDim.new(0, 6)
actionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
actionsLayout.Parent = actions

local auditStatus = Instance.new("TextLabel")
auditStatus.Name = "Status"
auditStatus.Position = UDim2.new(0, 10, 1, -98)
auditStatus.Size = UDim2.new(1, -20, 0, 90)
auditStatus.BackgroundColor3 = Color3.fromRGB(42, 49, 52)
auditStatus.BorderSizePixel = 0
auditStatus.Font = Enum.Font.Gotham
auditStatus.Text = "Listo"
auditStatus.TextColor3 = Color3.fromRGB(225, 235, 232)
auditStatus.TextSize = 12
auditStatus.TextWrapped = true
auditStatus.TextXAlignment = Enum.TextXAlignment.Left
auditStatus.TextYAlignment = Enum.TextYAlignment.Top
auditStatus.Parent = auditPanel

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 5)
statusCorner.Parent = auditStatus

local statusPadding = Instance.new("UIPadding")
statusPadding.PaddingLeft = UDim.new(0, 8)
statusPadding.PaddingRight = UDim.new(0, 8)
statusPadding.PaddingTop = UDim.new(0, 6)
statusPadding.Parent = auditStatus

auditButton.Activated:Connect(function()
	panel.Visible = false
	auditPanel.Visible = true
end)
backButton.Activated:Connect(function()
	auditPanel.Visible = false
	panel.Visible = true
end)

local auditBusy = false
local armedAction = nil
local armedUntil = 0

local function report(message)
	print("CraftTools audit: " .. message)
	if gui.Parent then
		auditStatus.Text = message
	end
end

local function getModule(parent, name)
	local scriptObject = parent and parent:FindFirstChild(name)
	if not scriptObject then
		error(name .. " no encontrado")
	end
	local ok, result = pcall(require, scriptObject)
	if not ok then
		error(name .. " no disponible: " .. tostring(result))
	end
	return result
end

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local modules = ReplicatedStorage:WaitForChild("Modules")
local managers = ReplicatedStorage:WaitForChild("Managers")

local function getRemote(name)
	local remote = remotes:FindFirstChild(name)
	if not remote or not remote:IsA("RemoteEvent") then
		error(name .. " no disponible")
	end
	return remote
end

local function getSelectedStack()
	local inventory = getModule(modules, "Inventory")
	local stack, slot = inventory.GetSelectedHotbarItem()
	if type(slot) ~= "number" or not stack or not stack.Id then
		error("Selecciona un item real en el hotbar")
	end
	return inventory, stack, slot
end

local function snapshotInventory(inventory)
	local totals = {}
	for slot = 1, inventory.MaxSlots or 0 do
		local stack = inventory.Stacks[slot]
		if stack and stack.Id then
			totals[stack.Id] = (totals[stack.Id] or 0) + (stack.Amount or 1)
		end
	end
	return totals
end

local function countDrops(id)
	local drops = workspace:FindFirstChild("Drops")
	local amount = 0
	if drops then
		for _, drop in drops:GetChildren() do
			if drop:GetAttribute("id") == id then
				amount += drop:GetAttribute("amount") or 1
			end
		end
	end
	return amount
end

local function makeAuditAction(label, confirmation, callback)
	local button = Instance.new("TextButton")
	button.Name = label:gsub("%W", "")
	button.Size = UDim2.new(1, -5, 0, 42)
	button.BackgroundColor3 = Color3.fromRGB(54, 62, 65)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamMedium
	button.Text = label
	button.TextColor3 = Color3.fromRGB(238, 243, 242)
	button.TextSize = 13
	button.Parent = actions

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 5)
	buttonCorner.Parent = button

	button.Activated:Connect(function()
		if auditBusy then
			report("Espera a que termine la prueba actual")
			return
		end
		if enabled then
			report("Desactiva Wall hack antes de auditar")
			return
		end
		if confirmation then
			if armedAction ~= label or os.clock() > armedUntil then
				armedAction = label
				armedUntil = os.clock() + 6
				report(confirmation .. " Pulsa otra vez para confirmar.")
				return
			end
		end
		armedAction = nil
		auditBusy = true
		report(label .. ": ejecutando...")
		task.spawn(function()
			local ok, result = pcall(callback)
			auditBusy = false
			report(ok and result or (label .. ": " .. tostring(result)))
		end)
	end)
end

makeAuditAction("Doble drop", "Puede soltar el stack seleccionado.", function()
	local inventory, stack, slot = getSelectedStack()
	local id = stack.Id
	local beforeInventory = snapshotInventory(inventory)[id] or 0
	local beforeDrops = countDrops(id)
	local drop = getRemote("PlayerDrop")
	drop:FireServer(slot)
	drop:FireServer(slot)
	task.wait(2)
	local removed = beforeInventory - (snapshotInventory(inventory)[id] or 0)
	local spawned = countDrops(id) - beforeDrops
	if spawned > removed then
		return string.format("POSIBLE DUPLICACION %s: inventario -%d, drops +%d. Verifica con otro cliente.", id, removed, spawned)
	end
	return string.format("Doble drop %s: inventario -%d, drops +%d. Sin duplicacion observable.", id, removed, spawned)
end)

makeAuditAction("Oferta repetida", "Requiere un trade activo; lo cancelara al terminar.", function()
	local _, _, slot = getSelectedStack()
	local inventoryUi = playerGui:FindFirstChild("InventoryUI")
	local tradeFrame = inventoryUi and inventoryUi:FindFirstChild("TradeFrame")
	if not tradeFrame or not tradeFrame.Visible then
		error("Abre primero un trade con otro jugador")
	end
	local trade = getRemote("PlayerTrade")
	local echoes = 0
	local connection = trade.OnClientEvent:Connect(function(action, actor)
		if action == 1 and actor == player then
			echoes += 1
		end
	end)
	trade:FireServer(1, slot)
	trade:FireServer(1, slot)
	task.wait(1.5)
	connection:Disconnect()
	trade:FireServer(-2)
	return string.format("Oferta repetida: %d confirmaciones del servidor; trade cancelado. Dos ofertas no prueban duplicacion hasta finalizar y comparar inventarios.", echoes)
end)

makeAuditAction("Reclamo repetido", "Puede consumir el reclamo diario disponible.", function()
	local inventory = getModule(modules, "Inventory")
	local before = snapshotInventory(inventory)
	local gemUpdates = 0
	local itemUpdates = 0
	local gemConnection = getRemote("PlayerSetGems").OnClientEvent:Connect(function()
		gemUpdates += 1
	end)
	local itemConnection = getRemote("InventorySetItem").OnClientEvent:Connect(function()
		itemUpdates += 1
	end)
	local custom = getRemote("CustomFunctionRemote")
	custom:FireServer("CompleteDailyQuest")
	custom:FireServer("CompleteDailyQuest")
	task.wait(2)
	gemConnection:Disconnect()
	itemConnection:Disconnect()
	local gained = 0
	for id, amount in pairs(snapshotInventory(inventory)) do
		gained += math.max(0, amount - (before[id] or 0))
	end
	return string.format("Reclamo doble: +%d items observados, %d cambios de gemas, %d slots actualizados. Compara con la recompensa normal.", gained, gemUpdates, itemUpdates)
end)

makeAuditAction("Colocar distante", "Puede consumir una unidad del tile seleccionado.", function()
	local inventory, stack, slot = getSelectedStack()
	local items = getModule(managers, "ItemsManager")
	local world = getModule(managers, "WorldManager")
	local playerScripts = player:FindFirstChild("PlayerScripts")
	local movement = getModule(playerScripts, "PlayerMovement")
	local itemData = items.RequestItemData(stack.Id)
	if not itemData or not itemData.Tile then
		error("Selecciona un item que sea un bloque")
	end
	local tileType = itemData.Tile.Type or 1
	local x = math.floor(movement.Position.X / 4.5 + 0.5)
	local y = math.floor(movement.Position.Y / 4.5 + 0.5)
	local reach = math.max(2, tonumber((movement.Attributes or {}).BuildReach) or 2)
	local worldMin = workspace:GetAttribute("WorldMin")
	local worldMax = workspace:GetAttribute("WorldMax")
	local targetX = nil
	for distance = math.ceil(reach) + 3, math.ceil(reach) + 12 do
		for _, direction in { 1, -1 } do
			local candidate = x + distance * direction
			if (not worldMin or candidate >= worldMin.X) and (not worldMax or candidate <= worldMax.X)
				and not world.GetTile(candidate, y, tileType) then
				targetX = candidate
				break
			end
		end
		if targetX then break end
	end
	if not targetX then
		error("No encontre una celda vacia fuera de alcance")
	end
	local before = snapshotInventory(inventory)[stack.Id] or 0
	getRemote("PlayerPlaceItem"):FireServer(Vector2.new(targetX, y), slot)
	task.wait(2)
	local placed = world.GetTile(targetX, y, tileType)
	local after = snapshotInventory(inventory)[stack.Id] or 0
	return string.format("Celda (%d,%d): %s; inventario %d -> %d. Si el bloque persiste para otro cliente, falta validar alcance en servidor.", targetX, y, tostring(placed), before, after)
end)

makeAuditAction("Slots invalidos", nil, function()
	local inventory = getModule(modules, "Inventory")
	if type(inventory.MaxSlots) ~= "number" then
		error("Inventario no inicializado")
	end
	local before = snapshotInventory(inventory)
	local drop = getRemote("PlayerDrop")
	local trash = getRemote("PlayerItemTrash")
	for _, slot in { 0, inventory.MaxSlots + 1 } do
		drop:FireServer(slot)
		trash:FireServer(slot)
	end
	task.wait(2)
	local changed = 0
	local after = snapshotInventory(inventory)
	for id, amount in pairs(before) do
		if amount ~= (after[id] or 0) then changed += 1 end
	end
	for id in pairs(after) do
		if before[id] == nil then changed += 1 end
	end
	return string.format("4 llamadas con slots invalidos; %d tipos de item cambiaron. Sin cambio no confirma ausencia de errores de servidor.", changed)
end)

makeAuditAction("Dano negativo", "Puede alterar la salud del personaje.", function()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		error("Humanoid no disponible")
	end
	local before = humanoid.Health
	getRemote("PlayerHurtMe"):FireServer(-1)
	task.wait(1)
	local after = humanoid.Health
	return string.format("Dano -1: salud %.1f -> %.1f. Un aumento persistente indicaria falta de validacion del valor.", before, after)
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
