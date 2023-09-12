local runService = game:GetService("RunService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")

local loadedModules = debug.getupvalue(getrawmetatable(require(replicatedStorage.Modules.Shared.ModuleLoader)).__index, 1).LoadedModules
local network = debug.getupvalue(getrawmetatable(loadedModules.Network).__index, 1)
local characters = debug.getupvalue(getmenv(replicatedStorage.BAC.Characters).NewChar, 1)

local client = players.LocalPlayer
local mouse = client:GetMouse()
local camera = workspace.CurrentCamera
local screenCenter = camera.ViewportSize / 2

local function drawObject(objectName: string, properties: table): unknown
	local object = Drawing.new(objectName)

	for index, property in properties do
		object[index] = property
	end

	return object
end

local function isOnEnemyTeam(player: Player): boolean
	if shared.config.teamCheck then
		local playerTeam = player.PermanentTeam.Value
		local clientTeam = client.PermanentTeam.Value

		return playerTeam ~= clientTeam
	end

	return true
end

local function isAlive(character: Instance): boolean
	local humanoid = character:FindFirstChild("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")

	if humanoid and rootPart then
		return humanoid.Health > 0
	end
end

local function calculateDistance(position: Vector2, mouse: Instance): number
	local newPosition = Vector2.new(position.X, position.Y)
	local newMousePosition = Vector2.new(mouse.X, mouse.Y)

	return (newPosition - newMousePosition).Magnitude
end

local function solveTrajectory(origin: CFrame, destination: Vector3): Vector3
	local newOrigin = CFrame.new(origin, destination)
	local modifiedOrigin = newOrigin * CFrame.new(0, 0, -(origin - destination).Magnitude)
	local trajectory = CFrame.new(modifiedOrigin.Position, modifiedOrigin * Vector3.new(math.random(-1000, 1000) / 150, math.random(-1000, 1000) / 150, 0))

	return trajectory.Position
end

local function getClosestToMouse(): Player
	local target = nil
	local maxDistance = shared.config.fieldOfView

	for player, character in characters do
		if isOnEnemyTeam(player) and isAlive(character) then
			local rootPartPosition = character.HumanoidRootPart.Position
			local screenPosition, onScreen = camera:WorldToViewportPoint(rootPartPosition)
			local distance = calculateDistance(screenPosition, mouse)

			if distance <= maxDistance and onScreen then
				maxDistance = distance
				target = character
			end
		end
	end

	return target
end

drawObject("Circle", {
	Position = screenCenter,
	Radius = shared.config.fieldOfView,
	Color = Color3.fromRGB(91, 67, 241),
	Thickness = 2,
	ZIndex = 2,
	Transparency = 1,
	Visible = true
})

local fireServer = network.FireServer
network.FireServer = function(...)
	if debug.info(2, "n") == "Shoot" then
		local args = {...}
		local target = getClosestToMouse()

		if target then
			local origin = args[3][1].OriginCFrame
			local trajectory = solveTrajectory(origin.Position, target[shared.config.hitPart].Position)

			args[3][1].OriginCFrame = CFrame.new(origin.Position, trajectory)
		end
	end

	return fireServer(...)
end
