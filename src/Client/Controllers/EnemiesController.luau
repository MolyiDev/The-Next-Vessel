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
local jecs = require(ReplicatedStorage.Packages.jecs)
local Components = require(ReplicatedStorage.Shared.ECS.Components)
local WorldRef = require(ReplicatedStorage.Shared.ECS.References.WorldRef)
local Tags = require(ReplicatedStorage.Shared.ECS.Tags)
local World = require(ReplicatedStorage.Shared.ECS.Worlds.World)
local ObjectPooler = require(ReplicatedStorage.Shared.Utils.ObjectPooler)
local SpatialHash = require(ReplicatedStorage.Shared.Utils.SpatialHash)
local TCharacter = require(ReplicatedStorage.Types.TCharacter)
local TimeController = require(script.Parent.TimeController)

type Spirit = {} & Attachment

type SpiritBreak = {
	Shatter1: ParticleEmitter,
	Shatter2: ParticleEmitter,
	SpiritBreak: Sound,
} & Attachment

local TURN_STRENGTH = 4
local SEPARATION_RADIUS = 6
local SEPARATION_FORCE = 1.5
local MAX_ENEMIES = 40
local WALL_MARGIN = 2

local Player = Players.LocalPlayer

local SpiritModel = ReplicatedStorage:WaitForChild("Effects"):WaitForChild("Spirit") :: Spirit
local SpiritBreakEffect = ReplicatedStorage:WaitForChild("Effects"):WaitForChild("SpiritBreak") :: SpiritBreak
local SpiritPool = ObjectPooler.new(SpiritModel, 200, 50, ObjectPooler.ReturnCF, Workspace.Spirits)
local ProjectilesZone = CollectionService:GetTagged("ProjectilesZone")[1] :: BasePart

local RayParams = RaycastParams.new()
RayParams.FilterType = Enum.RaycastFilterType.Exclude

local EnemiesController = {}
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
	damage: number?,
	health: number?
)
	if EnemiesController.EnemiesCount >= MAX_ENEMIES then return end

	local model = SpiritPool:Get() :: Spirit
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
		Tags.Enemy,
	}, {
		CFrame.new(initialPos, targetPos),
		(targetPos - initialPos).Unit,
		speed,
		radius,
		model,
		health or 1,
		damage or 1,
	})
end

local function destroy(enemyEntity: jecs.Entity, model: Spirit)
	EnemiesController.SpatialHash:Remove(enemyEntity)
	WorldRef:Nuke(model, enemyEntity)
	SpiritPool:Return(model)
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
		EnemiesController.BreakEnemy(entity)
	else
		World:set(entity, Components.Health, newHealth)
		-- Optional: Visual feedback for hit (flash white, etc.)
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

		-- 1. Prediction (Intercept logic)
		local toPlayer = characterPos - currentPos
		local distToPlayer = toPlayer.Magnitude
		-- Calculate how far ahead to look. Cap it (e.g., 1.5s) so they don't aim at infinity.
		local lookAhead = math.clamp(distToPlayer / speed, 0, 1.5)
		local predictedPos = characterPos + (characterVel * lookAhead)

		-- 2. Spirit Drift (Perpendicular Sine Wave)
		-- Uses entity ID as a seed so they don't all wave in sync
		local waveFreq = 3
		local waveAmp = 8 -- How wide they drift (in studs)
		local timeOffset = entity / 5 -- Pseudo-random offset based on Entity ID

		-- Calculate a vector to the right of the target direction
		local rawDirToTarget = (predictedPos - currentPos).Unit
		local rightVec = rawDirToTarget:Cross(Vector3.yAxis)
		local driftOffset = rightVec * math.sin((os.clock() * waveFreq) + timeOffset) * waveAmp

		-- Final Target Direction
		local finalTargetPos = predictedPos + driftOffset

		local separationVec = Vector3.zero
		local neighbors = 0

		-- Query neighbors within SEPARATION_RADIUS
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

				if dist < 0.1 then dist = 0.1 end -- Prevent division by zero

				-- The closer they are, the stronger the push away
				local pushStrength = (1 - (dist / SEPARATION_RADIUS)) * SEPARATION_FORCE
				separationVec -= (toNeighbor / dist) * pushStrength
				neighbors += 1
			end
		)

		local targetDir = (finalTargetPos - currentPos).Unit
		if neighbors > 0 then targetDir = (targetDir + separationVec).Unit end

		-- Steering
		local currentDir = direction
		local dynamicTurnSpeed = TURN_STRENGTH + (speed / 40)
		local newDir = currentDir:Lerp(targetDir, math.clamp(dt * dynamicTurnSpeed, 0, 1)).Unit

		-- Update Direction for physics
		direction = newDir
		World:set(entity, Components.Direction, newDir)

		-- Calculate proposed movement
		local displacement = direction * speed * dt

		-- [NEW] 4. Wall Collision Check (Raycast)
		-- Cast a ray forward from the center + radius to see if we are about to hit a wall
		local castDistance = (radius + displacement.Magnitude) + WALL_MARGIN
		local castDir = direction * castDistance
		local rayResult = Workspace:Raycast(currentPos, castDir, RayParams)

		if rayResult then
			local normal = rayResult.Normal
			local dot = displacement:Dot(normal)

			if dot < 0 then
				-- Slide along the wall
				displacement = displacement - (normal * dot)

				-- [CHANGED] Push away from the wall to prevent touching/clipping
				-- This adds a constant "repulsion" velocity away from the surface
				displacement += normal * 0.2

				-- Adjust future direction
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
			-- I-Frame (Dash)
		elseif distToPath < radius then
			HealthController.Damage(World:get(entity, Components.Damage) or 0)
			KnockbackController.Knockback(direction, 1500)
			-- Do not 'continue', allow them to move so they don't get stuck inside player
		end

		-- Update Position
		local newPos = currentPos + displacement
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
