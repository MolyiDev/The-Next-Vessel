local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Ignis = require(ReplicatedStorage.Packages.Ignis)
local DashController = require(script.Parent.DashController)
local HealthController = require(script.Parent.HealthController)
local KnockbackController = require(script.Parent.KnockbackController)
local SoundsController = require(script.Parent.SoundsController)
local TargetController = require(script.Parent.TargetController)
local jecs = require(ReplicatedStorage.Packages.jecs)
local Components = require(ReplicatedStorage.Shared.ECS.Components)
local WorldRef = require(ReplicatedStorage.Shared.ECS.References.WorldRef)
local Tags = require(ReplicatedStorage.Shared.ECS.Tags)
local World = require(ReplicatedStorage.Shared.ECS.Worlds.World)
local ObjectPooler = require(ReplicatedStorage.Shared.Utils.ObjectPooler)
local SpatialHash = require(ReplicatedStorage.Shared.Utils.SpatialHash)
local EUpgrades = require(ReplicatedStorage.Types.Enums.EUpgrades)
local TCharacter = require(ReplicatedStorage.Types.TCharacter)
local TimeController = require(script.Parent.TimeController)
local UpgradesController = require(script.Parent.UpgradesController)

type Spirit = {} & Attachment

type SpiritBreak = {
	Shatter1: ParticleEmitter,
	Shatter2: ParticleEmitter,
	SpiritBreak: Sound,
} & Attachment

local DOWN_VECTOR = Vector3.yAxis * -50
local TURN_STRENGTH = 4
local SEPARATION_RADIUS = 6
local SEPARATION_FORCE = 1.5
local MAX_ENEMIES = 40
local WALL_MARGIN = 2
local MIN_GROUND_HEIGHT = 4

local Player = Players.LocalPlayer

local SpiritBreakEffect = ReplicatedStorage:WaitForChild("Effects"):WaitForChild("SpiritBreak") :: SpiritBreak

local SpiritGreenModel = ReplicatedStorage:WaitForChild("Effects"):WaitForChild("SpiritGreen") :: Spirit
local SpiritBlueModel = ReplicatedStorage:WaitForChild("Effects"):WaitForChild("SpiritBlue") :: Spirit
local SpiritYellowModel = ReplicatedStorage:WaitForChild("Effects"):WaitForChild("SpiritYellow") :: Spirit
local SpiritPurpleModel = ReplicatedStorage:WaitForChild("Effects"):WaitForChild("SpiritPurple") :: Spirit

local SpiritGreenPool = ObjectPooler.new(SpiritGreenModel, 30, 10, ObjectPooler.ReturnCF, Workspace.Spirits)
local SpiritBluePool = ObjectPooler.new(SpiritBlueModel, 30, 10, ObjectPooler.ReturnCF, Workspace.Spirits)
local SpiritYellowPool = ObjectPooler.new(SpiritYellowModel, 30, 10, ObjectPooler.ReturnCF, Workspace.Spirits)
local SpiritPurplePool = ObjectPooler.new(SpiritPurpleModel, 30, 10, ObjectPooler.ReturnCF, Workspace.Spirits)

local ProjectilesZone = CollectionService:GetTagged("ProjectilesZone")[1] :: BasePart

local RayParams = RaycastParams.new()
RayParams.FilterType = Enum.RaycastFilterType.Exclude

local EnemiesController = {}
EnemiesController.EEnemyType = {
	Green = 0, -- Normal
	Blue = 1, -- Damage and speed increased x2
	Yellow = 2, -- Health and Damage and speed increased x3
	Purple = 3, -- Health and Damage and Speed increased x4
}
EnemiesController.EnemiesCount = 0
EnemiesController.SpatialHash = SpatialHash.new()

function EnemiesController.OnCharacterAdded(character: TCharacter.TCharacter)
	RayParams.FilterDescendantsInstances = { character, ProjectilesZone }
end

function EnemiesController.SpawnEnemy(
	initialPos: Vector3,
	targetPos: Vector3,
	speed: number,
	radius: number,
	type: number,
	damage: number?,
	health: number?
)
	if EnemiesController.EnemiesCount >= MAX_ENEMIES then return end

	local model: Spirit

	if type == EnemiesController.EEnemyType.Green then
		model = SpiritGreenPool:Get()
	elseif type == EnemiesController.EEnemyType.Blue then
		model = SpiritBluePool:Get()
		speed = (speed or 1) * 1.5
		damage = (damage or 1) * 1.5
	elseif type == EnemiesController.EEnemyType.Yellow then
		model = SpiritYellowPool:Get()
		speed = (speed or 1) * 1.75
		damage = (damage or 1) * 1.75
		health = (health or 1) * 2
	else
		model = SpiritPurplePool:Get()
		speed = (speed or 1) * 2
		damage = (damage or 1) * 2
		health = (health or 1) * 3
	end

	local enemyEntity = WorldRef:EntityRef(model)
	EnemiesController.EnemiesCount += 1
	EnemiesController.SpatialHash:AddSphere(enemyEntity, initialPos, radius)

	jecs.bulk_insert(World, enemyEntity, {
		Components.CFrame,
		Components.Direction,
		Components.Speed,
		Components.Radius,
		Components.Attachment,
		Components.Health,
		Components.Damage,
		Components.Type,
		Tags.Enemy,
	}, {
		CFrame.new(initialPos, targetPos),
		(targetPos - initialPos).Unit,
		speed,
		radius,
		model,
		health,
		damage,
		type,
	})
end

local function destroy(enemyEntity: jecs.Entity, model: Spirit)
	local type = World:get(enemyEntity, Components.Type)
	EnemiesController.SpatialHash:Remove(enemyEntity)
	WorldRef:Nuke(model, enemyEntity)

	if type == EnemiesController.EEnemyType.Green then
		SpiritGreenPool:Return(model)
	elseif type == EnemiesController.EEnemyType.Blue then
		SpiritBluePool:Return(model)
	elseif type == EnemiesController.EEnemyType.Yellow then
		SpiritYellowPool:Return(model)
	else
		SpiritPurplePool:Return(model)
	end

	EnemiesController.EnemiesCount -= 1
end

function EnemiesController.RemoveEnemy(enemyEntity: jecs.Entity)
	local model = World:get(enemyEntity, Components.Attachment) :: Spirit
	destroy(enemyEntity, model)
end

function EnemiesController.BreakEnemy(enemyEntity: jecs.Entity)
	local model = World:get(enemyEntity, Components.Attachment) :: Spirit

	local clone = SpiritBreakEffect:Clone()
	local id = SoundsController.AddSound(clone.SpiritBreak)
	clone.SpiritBreak.Ended:Once(function()
		clone:Destroy()
		SoundsController.RemoveSound(id)
	end)

	clone.CFrame = model.CFrame
	clone.Parent = Workspace.Temporal

	clone.Shatter1:Emit(20)
	clone.Shatter2:Emit(20)
	clone.SpiritBreak:Play()

	destroy(enemyEntity, model)
end

function EnemiesController.Cleanup()
	for entity, attachment in World:query(Components.Attachment, Tags.Enemy) do
		destroy(entity, attachment)
	end
end

function EnemiesController.HitEnemy(entity: jecs.Entity, damage: number)
	if not World:has(entity, Tags.Enemy) then return end

	local currentHealth = World:get(entity, Components.Health) or 1
	local newHealth = currentHealth - damage

	if newHealth <= 0 then
		local currentTarget, _ = TargetController.GetTarget()

		if currentTarget == entity and UpgradesController.HasUpgrade(EUpgrades.TargetGod) then
			TargetController.SwitchToNextTarget(entity)
		end

		EnemiesController.BreakEnemy(entity)
	else
		World:set(entity, Components.Health, newHealth)
	end
end

RunService.Heartbeat:Connect(function(rawDt: number)
	local dt = TimeController.GetDeltaTime(rawDt)
	if dt <= 0.001 then return end

	debug.profilebegin("Enemies")

	local character = Player.Character
	local rootPart = if character then character.PrimaryPart else nil
	local characterPos = if rootPart then rootPart.Position else nil
	local characterVel = if rootPart then rootPart.AssemblyLinearVelocity else Vector3.zero

	-- Logic Update
	for entity, cf, direction, speed, radius in
		World:query(Components.CFrame, Components.Direction, Components.Speed, Components.Radius, Tags.Enemy)
	do
		local currentPos = cf.Position
		if not characterPos then continue end

		local toPlayer = characterPos - currentPos
		local distToPlayer = toPlayer.Magnitude
		local lookAhead = math.clamp(distToPlayer / speed, 0, 1.5)
		local predictedPos = characterPos + (characterVel * lookAhead)

		local waveFreq = 3
		local waveAmp = 8
		local timeOffset = entity / 5

		local rawDirToTarget = (predictedPos - currentPos).Unit
		local rightVec = rawDirToTarget:Cross(Vector3.yAxis)
		local driftOffset = rightVec * math.sin((os.clock() * waveFreq) + timeOffset) * waveAmp

		local finalTargetPos = predictedPos + driftOffset

		local separationVec = Vector3.zero
		local neighbors = 0

		EnemiesController.SpatialHash:QuerySphereAsPoints(
			currentPos.X,
			currentPos.Y,
			currentPos.Z,
			SEPARATION_RADIUS,
			function(neighborEntity)
				if neighborEntity == entity then return end

				local neighborCF = World:get(neighborEntity, Components.CFrame)
				if not neighborCF then return end

				local toNeighbor = neighborCF.Position - currentPos
				local dist = toNeighbor.Magnitude

				if dist < 0.1 then dist = 0.1 end

				local pushStrength = (1 - (dist / SEPARATION_RADIUS)) * SEPARATION_FORCE
				separationVec -= (toNeighbor / dist) * pushStrength
				neighbors += 1
			end
		)

		local targetDir = (finalTargetPos - currentPos).Unit
		if neighbors > 0 then targetDir = (targetDir + separationVec).Unit end

		local currentDir = direction
		local dynamicTurnSpeed = TURN_STRENGTH + (speed / 40)
		local newDir = currentDir:Lerp(targetDir, math.clamp(dt * dynamicTurnSpeed, 0, 1)).Unit

		direction = newDir
		World:set(entity, Components.Direction, newDir)

		local displacement = direction * speed * dt

		local castDistance = (radius + displacement.Magnitude) + WALL_MARGIN
		local castDir = direction * castDistance
		local rayResult = Workspace:Raycast(currentPos, castDir, RayParams)

		if rayResult then
			local normal = rayResult.Normal
			local dot = displacement:Dot(normal)

			if dot < 0 then
				displacement = displacement - (normal * dot)
				displacement += normal * 0.2

				local slideDir = direction - (normal * direction:Dot(normal))
				if slideDir.Magnitude > 0.01 then
					direction = slideDir.Unit
					World:set(entity, Components.Direction, direction)
				end
			end
		end

		-- Player Collision / Damage Logic
		local segLenSq = displacement.Magnitude * displacement.Magnitude
		local toPlayerVec = characterPos - currentPos

		local t = if segLenSq > 0 then toPlayerVec:Dot(displacement) / segLenSq else 0
		local clampedT = math.clamp(t, 0, 1)

		local closestPoint = currentPos + (displacement * clampedT)
		local distToPath = (characterPos - closestPoint).Magnitude

		if distToPath < (radius * 3) and DashController.IsDashing() then
			-- Invulnerable
		elseif distToPath < radius then
			HealthController.Damage(World:get(entity, Components.Damage) or 0)
			KnockbackController.Knockback(direction, 1500)
		end

		local newPos = currentPos + displacement

		local groundRay = Workspace:Raycast(newPos, DOWN_VECTOR, RayParams)

		if groundRay then
			local floorY = groundRay.Position.Y

			if (newPos.Y - floorY) < MIN_GROUND_HEIGHT then
				newPos = Vector3.new(newPos.X, floorY + MIN_GROUND_HEIGHT, newPos.Z)

				if direction.Y < 0 then
					local flatDir = Vector3.new(direction.X, 0, direction.Z)
					if flatDir.Magnitude > 0.001 then
						direction = flatDir.Unit
						World:set(entity, Components.Direction, direction)
					end
				end
			end
		end

		local newCF = CFrame.new(newPos, newPos + direction)
		World:set(entity, Components.CFrame, newCF)
		EnemiesController.SpatialHash:Update(entity, newPos)
	end

	-- Visual Update
	for _, attachment, cf in World:query(Components.Attachment, Components.CFrame, Tags.Enemy) do
		attachment.CFrame = cf
	end

	debug.profileend()
end)

return Ignis.Register(EnemiesController)
