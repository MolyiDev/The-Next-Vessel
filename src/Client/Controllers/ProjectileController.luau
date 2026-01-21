local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Ignis = require(ReplicatedStorage.Packages.Ignis)
local BossController = require(script.Parent.BossController)
local DashController = require(script.Parent.DashController)
local HealthController = require(script.Parent.HealthController)
local ParryController = require(script.Parent.ParryController)
local SoundsController = require(script.Parent.SoundsController)
local jecs = require(ReplicatedStorage.Packages.jecs)
local Components = require(ReplicatedStorage.Shared.ECS.Components)
local WorldRef = require(ReplicatedStorage.Shared.ECS.References.WorldRef)
local Tags = require(ReplicatedStorage.Shared.ECS.Tags)
local World = require(ReplicatedStorage.Shared.ECS.Worlds.World)
local ObjectPooler = require(ReplicatedStorage.Shared.Utils.ObjectPooler)
local ESounds = require(ReplicatedStorage.Types.Enums.ESounds)
local TCharacter = require(ReplicatedStorage.Types.TCharacter)

type Projectile = {
	Sphere: {
		Root: {
			Sparks: ParticleEmitter,
			Glow: ParticleEmitter,
			Trail: Trail,
			TrailAttachment0: Attachment,
			TrailAttachment1: Attachment,
		} & Bone,
	} & BasePart,
} & Model

local PARRY_STRENGTH = 4

local Player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local ProjectileModel = ReplicatedStorage:WaitForChild("Models"):WaitForChild("Projectile") :: Projectile
local ProjectilesZone = CollectionService:GetTagged("ProjectilesZone")[1] :: BasePart
local ProjectilePool = ObjectPooler.new(ProjectileModel, 200, 50, ObjectPooler.ReturnBoneModel, Workspace.Projectiles)
local RayParams = RaycastParams.new()
RayParams.FilterType = Enum.RaycastFilterType.Exclude

local ProjectileController = {}

function ProjectileController.OnCharacterAdded(character: TCharacter.TCharacter)
	RayParams.FilterDescendantsInstances = { character, ProjectilesZone, BossController.GetRig() }
end

function ProjectileController.AddProjectile(initialPos: Vector3, targetPos: Vector3, speed: number, radius: number)
	local model = ProjectilePool:Get() :: Projectile
	local projectileEntity = WorldRef:EntityRef(model)

	model.Sphere.Root.Trail.Enabled = true

	jecs.bulk_insert(World, projectileEntity, {
		Components.CFrame,
		Components.Direction,
		Components.Speed,
		Components.Radius,
		Components.Model,
		Components.Bone,
		Tags.Projectile,
	}, {
		CFrame.new(initialPos, targetPos),
		(targetPos - initialPos).Unit,
		speed,
		radius,
		model,
		model.Sphere.Root,
	})
end

function ProjectileController.RemoveProjectile(projectileEntity: jecs.Entity)
	local model = World:get(projectileEntity, Components.Model) :: Projectile
	WorldRef:Nuke(model, projectileEntity)
	model.Sphere.Root.Trail.Enabled = false
	ProjectilePool:Return(model)
end

RunService.Heartbeat:Connect(function(dt: number)
	local character = Player.Character
	local characterPos = if character then character.PrimaryPart.Position else nil
	local bossRig = BossController.GetRig()
	local bossRoot = if bossRig then bossRig.PrimaryPart else nil

	-- Query Loop
	for entity, cf, direction, speed, radius in
		World:query(Components.CFrame, Components.Direction, Components.Speed, Components.Radius)
	do
		local currentPos = cf.Position

		-- ================================================================================
		-- 1. GENERIC HOMING LOGIC (Applies to everyone)
		-- ================================================================================
		local target = World:get(entity, Components.Target) :: BasePart

		if target and target.Parent then
			local targetPos = target.Position
			local currentDir = direction
			local targetDir = (targetPos - currentPos).Unit

			-- [FIX] Dynamic Homing:
			-- We scale the turn strength by speed. Faster ball = Sharper turn required.
			-- Base strength (4) + Speed Bonus.
			local dynamicTurnSpeed = PARRY_STRENGTH + (speed / 40)

			local newDir = currentDir:Lerp(targetDir, math.clamp(dt * dynamicTurnSpeed, 0, 1)).Unit
			World:set(entity, Components.Direction, newDir)
			direction = newDir -- Update local var for movement calc
		end

		-- Calculate Displacement
		local displacement = direction * speed * dt
		local newPos = currentPos + displacement

		-- ================================================================================
		-- 2. BOSS INTERACTION (If Player Parried)
		-- ================================================================================
		if World:has(entity, Tags.Parried) and bossRoot then
			-- Check distance to Boss
			if (newPos - bossRoot.Position).Magnitude < 6 then
				if BossController.CanParryProjectile(speed) then
					-- :: BOSS PARRIES ::
					World:remove(entity, Tags.Parried) -- Reset tag

					if character then
						-- Target Player
						World:set(entity, Components.Target, character.PrimaryPart)

						-- Initial reflect direction towards player
						local dirToPlayer = (characterPos - newPos).Unit
						World:set(entity, Components.Direction, dirToPlayer)
					else
						World:set(entity, Components.Direction, -direction)
					end

					-- Increase Speed & Push forward slightly
					World:set(entity, Components.Speed, speed * 1.1)
					World:set(entity, Components.CFrame, CFrame.new(newPos + (direction * 2)))

					SoundsController.PlayBoss(ESounds.Parry)
				else
					-- :: BOSS HIT ::
					BossController.Damage(1)
					ProjectileController.RemoveProjectile(entity)
				end
				continue
			end
		end

		-- ================================================================================
		-- 3. PLAYER INTERACTION (If Boss Threw)
		-- ================================================================================
		if characterPos and not World:has(entity, Tags.Parried) then
			-- Math: Find the closest point on the line segment (current -> new) to the player
			local toPlayer = characterPos - currentPos
			local segLenSq = displacement.Magnitude * displacement.Magnitude

			-- 't' determines where on the line the closest point is (0 = start, 1 = end)
			local t = if segLenSq > 0 then toPlayer:Dot(displacement) / segLenSq else 0
			local clampedT = math.clamp(t, 0, 1)

			local closestPointOnPath = currentPos + (displacement * clampedT)
			local distToPath = (characterPos - closestPointOnPath).Magnitude

			-- A. Parry Check (Wider Radius)
			if distToPath < (radius * 3) and ParryController.IsParrying() then
				local camLook = Camera.CFrame.LookVector

				local speedMult = ParryController.GetChargeMultiplier()

				World:add(entity, Tags.Parried)
				if bossRoot then World:set(entity, Components.Target, bossRoot) end

				World:set(entity, Components.Direction, camLook)
				World:set(entity, Components.Speed, speed * speedMult)

				-- Move ball to the point of impact + offset, to ensure visual clarity
				local impactPos = closestPointOnPath
				World:set(entity, Components.CFrame, CFrame.new(impactPos + (camLook * 3)))

				ParryController.SuccessfulParry()
				continue
			end

			-- B. Damage Check (Strict Radius)
			if distToPath < radius then
				if not DashController.IsDashing() then
					HealthController.Damage(1)
					ProjectileController.RemoveProjectile(entity)
					continue
				end
			end
		end

		-- ================================================================================
		-- 4. STANDARD CHECKS
		-- ================================================================================

		-- Bounds Check
		local relPos = ProjectilesZone.CFrame:PointToObjectSpace(newPos)
		local size = ProjectilesZone.Size
		if math.abs(relPos.X) > size.X / 2 or math.abs(relPos.Y) > size.Y / 2 or math.abs(relPos.Z) > size.Z / 2 then
			print("out of area")
			ProjectileController.RemoveProjectile(entity)
			continue
		end

		-- Wall Check
		-- local rayResult = workspace:Raycast(currentPos, displacement, RayParams)
		-- if rayResult then
		-- 	ProjectileController.RemoveProjectile(entity)
		-- 	continue
		-- end

		-- Update Position
		local newCF = CFrame.new(newPos, newPos + direction)
		World:set(entity, Components.CFrame, newCF)
	end

	-- Visual Update
	for _, bone, cf in World:query(Components.Bone, Components.CFrame, Tags.Projectile) do
		bone.CFrame = cf
	end
end)
return Ignis.Register(ProjectileController)
