-- Install as a Script in ServerScriptService. Add collaborators' UserIds below.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local allowedUserIds = {
	-- [123456789] = true,
}

local remote = ReplicatedStorage:FindFirstChild("CraftToolsRemote")
if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = "CraftToolsRemote"
	remote.Parent = ReplicatedStorage
end

local lastTeleport = {}
local lastJump = {}

local function isAllowed(player)
	if RunService:IsStudio() then return true end
	if game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId then
		return true
	end
	return allowedUserIds[player.UserId] == true
end

local function validCoordinate(value)
	return type(value) == "number" and value == value and math.abs(value) <= 100000
end

remote.OnServerEvent:Connect(function(player, action, target)
	if not isAllowed(player) then return end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then return end

	local now = os.clock()
	if action == "teleport" then
		if typeof(target) ~= "Vector2" or not validCoordinate(target.X) or not validCoordinate(target.Y) then
			return
		end
		if now - (lastTeleport[player] or 0) < 0.15 then return end
		lastTeleport[player] = now

		local destination = Vector3.new(target.X, target.Y, root.Position.Z)
		character:PivotTo(character:GetPivot() + (destination - root.Position))
		root.AssemblyLinearVelocity = Vector3.zero
	elseif action == "jump" then
		if now - (lastJump[player] or 0) < 0.18 then return end
		lastJump[player] = now

		local jumpSpeed = humanoid.UseJumpPower and humanoid.JumpPower
			or math.sqrt(2 * workspace.Gravity * humanoid.JumpHeight)
		local velocity = root.AssemblyLinearVelocity
		root.AssemblyLinearVelocity = Vector3.new(velocity.X, jumpSpeed, 0)
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	lastTeleport[player] = nil
	lastJump[player] = nil
end)
