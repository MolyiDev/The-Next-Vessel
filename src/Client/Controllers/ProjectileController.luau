local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Ignis = require(ReplicatedStorage.Packages.Ignis)
local BossController = require(script.Parent.BossController)
local DashController = require(script.Parent.DashController)
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
	if ProjectileController.ProjectileCount >= MAX_PROJECTILES then return end

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
	}

	local values: { any } = {
		initialCF,
		(direction - initialPos).Unit,
		speed,
		radius,
		model,
		root,
		health,
		damage,
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

	-- 4. Finalize
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
	destroy(projectileEntity, model)
end

function ProjectileController.BreakProjectile(projectileEntity: jecs.Entity)
	local model = World:get(projectileEntity, Components.Model) :: Projectile

	local clone = ProjectileBreakEffect:Clone()
	local id = SoundsController.AddSound(clone.SpellBreak)
	clone.SpellBreak.Ended:Once(function()
		clone:Destroy()
		SoundsController.RemoveSound(id)
	end)

	clone.CFrame = model.Sphere.Root.CFrame
	clone.Parent = Workspace.Temporal

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
	if not DashController.UseAmmo() then return end
	local targetEnt, targetPos = TargetController.GetTarget()
	local targetInstance = nil

	-- Try to find the physical part/attachment to home in on
	if targetEnt then
		targetInstance = World:get(targetEnt, Components.Attachment)
			or World:get(targetEnt, Components.Model)
			or World:get(targetEnt, Components.Bone)
	end

	if not targetInstance then return end
	local char = Player.Character
	if not char then return end

	local startPos = char.PrimaryPart.Position + Vector3.new(0, 2, 0)
	local dir = (targetPos - startPos).Unit

	ProjectileController.AddProjectileMissile(
		startPos,
		dir,
		targetInstance,
		90, -- Speed
		2.5, -- Radius
		ProjectileController.ESender.Player,
		20, -- Damage
		1 -- Health
	)

	-- SoundsController.PlayCharacter(ESounds.Parry) -- Placeholder sound
end)

RunService.Heartbeat:Connect(function(rawDt: number)
	local dt = TimeController.GetDeltaTime(rawDt)
	if dt <= 0.001 then return end

	debug.profilebegin("Projectiles")

	local character = Player.Character
	local characterPos = if character and character.PrimaryPart then character.PrimaryPart.Position else nil
	local bossRig = BossController.GetRig()
	local bossRoot = if bossRig then bossRig.PrimaryPart else nil

	-- Logic update
	for entity, cf, direction, speed, radius in
		World:query(Components.CFrame, Components.Direction, Components.Speed, Components.Radius, Tags.Projectile)
	do
		local currentPos = cf.Position
		local target = World:get(entity, Components.Target) :: BasePart

		-- Target turn
		if target and target.Parent then
			local targetPos: Vector3
			if target:IsA("Attachment") then
				targetPos = target.WorldPosition
			elseif target:IsA("BasePart") then
				targetPos = target.Position
			else
				targetPos = (target :: any).Position
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

		-- Boss parry / damage
		if (World:has(entity, Tags.Parried) or World:has(entity, Tags.SafePlayer)) and bossRoot then
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

					World:remove(entity, Tags.Parried)

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
		if characterPos and not World:has(entity, Tags.Parried) and not World:has(entity, Tags.SafePlayer) then
			local toPlayer = characterPos - currentPos

			local t = if segLenSq > 0 then toPlayer:Dot(displacement) / segLenSq else 0
			local clampedT = math.clamp(t, 0, 1)

			local closestPointOnPath = currentPos + (displacement * clampedT)
			local distToPath = (characterPos - closestPointOnPath).Magnitude

			if distToPath < (radius * 3) then
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

					World:add(entity, Tags.Parried)

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
