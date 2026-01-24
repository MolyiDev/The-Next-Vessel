local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Ignis = require(ReplicatedStorage.Packages.Ignis)
local BossController = require(script.Parent.BossController)
local DashController = require(script.Parent.DashController)
local EnemiesController = require(script.Parent.EnemiesController)
local FloatingNumbersController = require(script.Parent.FloatingNumbersController)
local HealthController = require(script.Parent.HealthController)
local KnockbackController = require(script.Parent.KnockbackController)
local ParryController = require(script.Parent.ParryController)
local SoundsController = require(script.Parent.SoundsController)
local TargetController = require(script.Parent.TargetController)
local TimeController = require(script.Parent.TimeController)
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

type SpellBreak = {
	Shatter1: ParticleEmitter,
	Shatter2: ParticleEmitter,
	SpellBreak: Sound,
} & Attachment

local PARRY_STRENGTH = 4
local MAX_PROJECTILES = 80
local SENDER_PLAYER_SPHERE_COLOR = Color3.fromRGB(1, 122, 173)
local SENDER_PLAYER_EFFECT_COLOR = ColorSequence.new(Color3.fromRGB(12, 255, 239))
local SENDER_ENEMY_SPHERE_COLOR = Color3.fromRGB(173, 0, 66)
local SENDER_ENEMY_EFFECT_COLOR = ColorSequence.new(Color3.new(1, 0, 0))

local Player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local ProjectileModel = ReplicatedStorage:WaitForChild("Models"):WaitForChild("Projectile") :: Projectile
local ProjectileBreakEffect = ReplicatedStorage:WaitForChild("Effects"):WaitForChild("SpellBreak") :: SpellBreak
local ProjectilesZone = CollectionService:GetTagged("ProjectilesZone")[1] :: BasePart
local ProjectilePool = ObjectPooler.new(ProjectileModel, 80, 1, ObjectPooler.ReturnBoneModel, Workspace.Projectiles)

local RayParams = RaycastParams.new()
RayParams.FilterType = Enum.RaycastFilterType.Exclude

local ProjectileController = {}
ProjectileController.ESender = {
	Player = 0,
	Enemy = 1,
}
ProjectileController.ProjectileCount = 0
ProjectileController.ProjectilesSpawnLow = CollectionService:GetTagged("ProjectilesSpawnLow")[1] :: BasePart
ProjectileController.ProjectilesSpawnHigh = CollectionService:GetTagged("ProjectilesSpawnHigh")[1] :: BasePart

function ProjectileController.OnCharacterAdded(character: TCharacter.TCharacter)
	RayParams.FilterDescendantsInstances = { character, ProjectilesZone, BossController.GetRig() }
end

local function spawnProjectileInternal(
	initialPos: Vector3,
	direction: Vector3,
	target: (BasePart | Attachment)?,
	speed: number,
	radius: number,
	sender: number,
	damage: number,
	health: number
)
	if sender ~= ProjectileController.ESender.Player and ProjectileController.ProjectileCount >= MAX_PROJECTILES then
		return
	end

	local model = ProjectilePool:Get() :: Projectile
	local projectileEntity = WorldRef:EntityRef(model)
	local root = model.Sphere.Root
	local initialCF = CFrame.lookAt(initialPos, direction)

	local components: { any } = {
		Components.CFrame,
		Components.Direction,
		Components.Speed,
		Components.Radius,
		Components.Model,
		Components.Bone,
		Components.Health,
		Components.Damage,
		Components.Sender,
	}

	local values: { any } = {
		initialCF,
		direction,
		speed,
		radius,
		model,
		root,
		health,
		damage,
		sender,
	}

	if target then
		components[#components + 1] = Components.Target
		values[#values + 1] = target
	end

	components[#components + 1] = Tags.Projectile

	local isPlayer = sender == ProjectileController.ESender.Player
	local sphereColor = if isPlayer then SENDER_PLAYER_SPHERE_COLOR else SENDER_ENEMY_SPHERE_COLOR
	local effectColor = if isPlayer then SENDER_PLAYER_EFFECT_COLOR else SENDER_ENEMY_EFFECT_COLOR
	local safeTag = if isPlayer then Tags.SafePlayer else Tags.SafeEnemy

	model.Sphere.Color = sphereColor
	root.Glow.Color = effectColor
	root.Sparks.Color = effectColor
	root.Trail.Color = effectColor

	components[#components + 1] = safeTag

	root.CFrame = initialCF

	task.defer(function()
		model.Sphere.Root.Trail.Enabled = true
	end)

	ProjectileController.ProjectileCount += 1

	jecs.bulk_insert(World, projectileEntity, components, values)
end

function ProjectileController.AddProjectile(
	initialPos: Vector3,
	direction: Vector3,
	speed: number,
	radius: number,
	sender: number,
	damage: number?,
	health: number?
)
	spawnProjectileInternal(initialPos, direction, nil, speed, radius, sender, damage or 0, health or 1)
end

function ProjectileController.AddProjectileMissile(
	initialPos: Vector3,
	direction: Vector3,
	target: BasePart | Attachment,
	speed: number,
	radius: number,
	sender: number,
	damage: number?,
	health: number?
)
	spawnProjectileInternal(initialPos, direction, target, speed, radius, sender, damage or 0, health or 1)
end

local function destroy(projectileEntity: jecs.Entity, model: Projectile)
	model.Sphere.Root.Trail.Enabled = false

	WorldRef:Nuke(model, projectileEntity)
	ProjectileController.ProjectileCount -= 1

	task.defer(function()
		ProjectilePool:Return(model)
	end)
end

function ProjectileController.RemoveProjectile(projectileEntity: jecs.Entity)
	local model = World:get(projectileEntity, Components.Model) :: Projectile
	if not model then return end
	destroy(projectileEntity, model)
end

function ProjectileController.BreakProjectile(projectileEntity: jecs.Entity)
	local model = World:get(projectileEntity, Components.Model) :: Projectile
	local sender = World:get(projectileEntity, Components.Sender) :: number
	if not model or not sender then return end

	local senderColor = if sender == ProjectileController.ESender.Player
		then SENDER_PLAYER_EFFECT_COLOR
		else SENDER_ENEMY_EFFECT_COLOR

	local clone = ProjectileBreakEffect:Clone()
	local id = SoundsController.AddSound(clone.SpellBreak)
	clone.SpellBreak.Ended:Once(function()
		clone:Destroy()
		SoundsController.RemoveSound(id)
	end)

	clone.CFrame = model.Sphere.Root.CFrame
	clone.Parent = Workspace.Temporal

	clone.Shatter1.Color = senderColor
	clone.Shatter2.Color = senderColor

	clone.Shatter1:Emit(15)
	clone.Shatter2:Emit(15)
	clone.SpellBreak:Play()

	destroy(projectileEntity, model)
end

function ProjectileController.Cleanup()
	for entity in World:query(Tags.Projectile) do
		ProjectileController.RemoveProjectile(entity)
	end
end

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

	local root = if Player.Character then Player.Character.PrimaryPart else nil
	if not root then return end

	if not DashController.UseAmmo() then return end

	local startPos = root.Position + root.CFrame.LookVector * 3
	local dir = Workspace.CurrentCamera.CFrame.LookVector
	local speed = 90
	local radius = 2.5
	local dmg = 1
	local health = 1

	ProjectileController.AddProjectile(startPos, dir, speed, radius, ProjectileController.ESender.Player, dmg, health)

	SoundsController.PlayCharacter(ESounds.MagicShoot)
end)

RunService.Heartbeat:Connect(function(rawDt: number)
	local dt = TimeController.GetDeltaTime(rawDt)
	if dt <= 0.001 then return end

	debug.profilebegin("Projectiles")

	local character = Player.Character
	local characterPos = if character and character.PrimaryPart then character.PrimaryPart.Position else nil
	local bossRig = BossController.GetRig()
	local bossRoot = if bossRig then bossRig.PrimaryPart else nil

	local currentTargetEnt = TargetController.GetTarget()
	local currentTargetInstance = nil

	if currentTargetEnt then
		currentTargetInstance = World:get(currentTargetEnt, Components.Attachment)
			or World:get(currentTargetEnt, Components.Model)
			or World:get(currentTargetEnt, Components.Bone)
	end

	-- Logic update
	for entity, cf, direction, speed, radius in
		World:query(Components.CFrame, Components.Direction, Components.Speed, Components.Radius, Tags.Projectile)
	do
		local currentPos = cf.Position

		if World:has(entity, Tags.SafePlayer) then
			if currentTargetInstance then
				World:set(entity, Components.Target, currentTargetInstance :: any)
			else
				World:remove(entity, Components.Target)
			end
		end

		local target = World:get(entity, Components.Target) :: BasePart

		-- Target turn
		if target and target.Parent then
			local targetPos: Vector3
			if target:IsA("Attachment") then
				targetPos = target.WorldPosition
			elseif target:IsA("BasePart") then
				targetPos = target.Position
			elseif target:IsA("Model") then
				targetPos = if target.PrimaryPart then target.PrimaryPart.Position else target:GetPivot().Position
			end

			local currentDir = direction
			local targetDir = (targetPos - currentPos).Unit
			local dynamicTurnSpeed = PARRY_STRENGTH + (speed / 40)

			local newDir = currentDir:Lerp(targetDir, math.clamp(dt * dynamicTurnSpeed, 0, 1)).Unit
			World:set(entity, Components.Direction, newDir)
			direction = newDir
		end

		local displacement = direction * speed * dt
		local newPos = currentPos + displacement
		local segLenSq = displacement.Magnitude * displacement.Magnitude
		local dmg = World:get(entity, Components.Damage) or 0

		local hitEnemy = false
		if not World:has(entity, Tags.SafeEnemy) then -- Only player projectiles hit enemies
			EnemiesController.SpatialHash:QuerySphereAsPoints(
				newPos.X,
				newPos.Y,
				newPos.Z,
				radius * 2,
				function(enemyEntity)
					if hitEnemy then return end -- Only hit one enemy per frame per projectile

					local enemyCF = World:get(enemyEntity, Components.CFrame)
					local enemyRadius = World:get(enemyEntity, Components.Radius) or 2
					if not enemyCF then return end

					-- Verify exact distance since Hash is coarse/broadphase
					local distSq = (enemyCF.Position - newPos).Magnitude ^ 2
					local combinedRadius = radius + enemyRadius

					if distSq <= combinedRadius * combinedRadius then
						hitEnemy = true

						EnemiesController.HitEnemy(enemyEntity, dmg)

						FloatingNumbersController.Add(
							enemyCF.Position,
							dmg,
							FloatingNumbersController.ENumberType.DamageEnemy
						)

						-- Visual break
						ProjectileController.BreakProjectile(entity)
					end
				end
			)
		end

		-- Boss parry / damage
		if (World:has(entity, Tags.SafePlayer)) and bossRoot then
			local toBoss = bossRoot.Position - currentPos

			local t = if segLenSq > 0 then toBoss:Dot(displacement) / segLenSq else 0
			local clampedT = math.clamp(t, 0, 1)
			local closestPoint = currentPos + (displacement * clampedT)

			if (closestPoint - bossRoot.Position).Magnitude < 6 then
				if BossController.CanParryProjectile(speed) then
					local health = (World:get(entity, Components.Health) or 0) - 1

					if health <= 0 then
						ProjectileController.BreakProjectile(entity)
						continue
					end

					FloatingNumbersController.Add(currentPos, 1, FloatingNumbersController.ENumberType.DamageEnemy)

					World:set(entity, Components.Health, health - 1)
					World:remove(entity, Tags.SafePlayer)
					World:add(entity, Tags.SafeEnemy)

					local model = World:get(entity, Components.Model) :: Projectile
					if model then
						model.Sphere.Color = SENDER_ENEMY_SPHERE_COLOR
						model.Sphere.Root.Glow.Color = SENDER_ENEMY_EFFECT_COLOR
						model.Sphere.Root.Sparks.Color = SENDER_ENEMY_EFFECT_COLOR
						model.Sphere.Root.Trail.Color = SENDER_ENEMY_EFFECT_COLOR
					end

					if character then
						World:set(entity, Components.Target, character.PrimaryPart)
						local dirToPlayer = (characterPos - newPos).Unit
						World:set(entity, Components.Direction, dirToPlayer)
					else
						World:set(entity, Components.Direction, -direction)
					end

					World:set(entity, Components.Speed, speed * 1.1)
					World:set(entity, Components.CFrame, CFrame.new(closestPoint + (direction * 2)))

					SoundsController.Play(ESounds.Parry, bossRig)
				else
					BossController.Damage(World:get(entity, Components.Damage) or 0)
					ProjectileController.RemoveProjectile(entity)
				end

				continue
			end
		end

		-- Character parry / damage / dash
		if characterPos and not World:has(entity, Tags.SafePlayer) then
			local toPlayer = characterPos - currentPos

			local t = if segLenSq > 0 then toPlayer:Dot(displacement) / segLenSq else 0
			local clampedT = math.clamp(t, 0, 1)

			local closestPointOnPath = currentPos + (displacement * clampedT)
			local distToPath = (characterPos - closestPointOnPath).Magnitude

			if distToPath < (radius * 2.5) then
				if ParryController.IsParrying() then
					local health = (World:get(entity, Components.Health) or 0) - 1

					if health <= 0 then
						ProjectileController.BreakProjectile(entity)
						ParryController.SuccessfulParry(true)
						continue
					end

					FloatingNumbersController.Add(currentPos, 1, FloatingNumbersController.ENumberType.DamageEnemy)

					World:set(entity, Components.Health, health - 1)

					local camLook = Camera.CFrame.LookVector
					local speedMult = ParryController.GetChargeMultiplier()
					local targetEntity, targetPos = TargetController.GetTarget()

					World:add(entity, Tags.SafePlayer)
					World:remove(entity, Tags.SafeEnemy)

					if targetEntity then
						local targetAttach = World:get(targetEntity, Components.Attachment)
						if targetAttach then
							World:set(entity, Components.Target, targetAttach)
							local dirToTarget = (targetPos - currentPos).Unit
							World:set(entity, Components.Direction, dirToTarget)
						else
							World:set(entity, Components.Direction, camLook)
						end
					elseif bossRoot then
						World:set(entity, Components.Target, bossRoot)
						World:set(entity, Components.Direction, camLook)
					else
						World:set(entity, Components.Direction, camLook)
					end

					World:set(entity, Components.Speed, speed * speedMult)

					local impactPos = closestPointOnPath
					World:set(entity, Components.CFrame, CFrame.new(impactPos + (camLook * 3)))

					local model = World:get(entity, Components.Model) :: Projectile
					if model then
						model.Sphere.Color = SENDER_PLAYER_SPHERE_COLOR
						model.Sphere.Root.Glow.Color = SENDER_PLAYER_EFFECT_COLOR
						model.Sphere.Root.Sparks.Color = SENDER_PLAYER_EFFECT_COLOR
						model.Sphere.Root.Trail.Color = SENDER_PLAYER_EFFECT_COLOR
					end

					ParryController.SuccessfulParry()
					continue
				elseif DashController.IsDashing() then
					DashController.AddAmmo()
					ProjectileController.RemoveProjectile(entity)
					continue
				end
			end

			if distToPath < radius then
				HealthController.Damage(World:get(entity, Components.Damage) or 0)
				KnockbackController.Knockback(direction, 1500)
				ProjectileController.RemoveProjectile(entity)
				continue
			end
		end

		-- Bounds Check
		local relPos = ProjectilesZone.CFrame:PointToObjectSpace(newPos)
		local size = ProjectilesZone.Size
		if math.abs(relPos.X) > size.X / 2 or math.abs(relPos.Y) > size.Y / 2 or math.abs(relPos.Z) > size.Z / 2 then
			ProjectileController.RemoveProjectile(entity)
			continue
		end

		-- Wall Check
		local rayResult = workspace:Raycast(currentPos, displacement, RayParams)
		if rayResult and not rayResult.Instance:HasTag("ProjectileSafe") then
			if target then
				local currentHealth = World:get(entity, Components.Health) or 1
				local newHealth = currentHealth - 1

				if newHealth <= 0 then
					ProjectileController.BreakProjectile(entity)
					continue
				end

				-- Reflection Formula: r = d - 2(d • n)n
				local normal = rayResult.Normal
				local reflectedDir = direction - (2 * direction:Dot(normal) * normal)

				World:set(entity, Components.Health, newHealth)
				World:set(entity, Components.Direction, reflectedDir)

				local impactPos = rayResult.Position + (normal * 0.1)
				World:set(entity, Components.CFrame, CFrame.lookAt(impactPos, impactPos + reflectedDir))
			else
				ProjectileController.BreakProjectile(entity)
			end

			continue
		end

		-- Update Position
		local newCF = CFrame.new(newPos, newPos + direction)
		World:set(entity, Components.CFrame, newCF)
	end

	-- Visual Update
	for _, bone, cf in World:query(Components.Bone, Components.CFrame, Tags.Projectile) do
		bone.CFrame = cf
	end

	debug.profileend()
end)

return Ignis.Register(ProjectileController)
