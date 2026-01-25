local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HealthController = require(script.Parent.HealthController)
local SoundsController = require(script.Parent.SoundsController)
local TimeController = require(script.Parent.TimeController)
local TweensController = require(script.Parent.TweensController)
local Ignis = require(ReplicatedStorage.Packages.Ignis)
local Signal = require(ReplicatedStorage.Packages.Signal)
local jecs = require(ReplicatedStorage.Packages.jecs)
local Components = require(ReplicatedStorage.Shared.ECS.Components)
local World = require(ReplicatedStorage.Shared.ECS.Worlds.World)
local Tools = require(ReplicatedStorage.Shared.Utils.Tools)
local EDirections = require(ReplicatedStorage.Types.Enums.EDirections)
local ESounds = require(ReplicatedStorage.Types.Enums.ESounds)
local UpgradesController = require(script.Parent.UpgradesController)
local EUpgrades = require(ReplicatedStorage.Types.Enums.EUpgrades)
local EMovementJumps = require(ReplicatedStorage.Types.Enums.Movement.EMovementJumps)
local EMovementSpeeds = require(ReplicatedStorage.Types.Enums.Movement.EMovementSpeeds)
local TCharacter = require(ReplicatedStorage.Types.TCharacter)

local DASH_DURATION = 0.5
local DASH_INITIAL_SPEED = 70
local DASH_FINAL_SPEED = 25
local DASH_COOLDOWN = 1.5

local AnimationsFolder = ReplicatedStorage.Animations
local DashAnimationsFolder = AnimationsFolder.Dash

local DashFrontAnim = DashAnimationsFolder.DashFront :: Animation
local DashBackAnim = DashAnimationsFolder.DashBack :: Animation
local DashLeftAnim = DashAnimationsFolder.DashLeft :: Animation
local DashRightAnim = DashAnimationsFolder.DashRight :: Animation

local DashFront: AnimationTrack
local DashBack: AnimationTrack
local DashLeft: AnimationTrack
local DashRight: AnimationTrack

local DashAnimations: { [Vector3]: { AnimationTrack } } = {}

local DashController = {}
DashController.OnDashUsed = Signal.new()
DashController.OnProjectileShooted = Signal.new()
DashController.AutoProjectiles = 1
DashController.AutoProjectilesCooldown = 2
DashController.AutoProjectilesCurrentCooldown = 2
DashController.CurrentMaxRegenTime = 2
DashController.LastDashTime = 0
DashController.Direction = Vector3.zero
DashController.StoredProjectiles = 1

local CurrentAnimations: { AnimationTrack } = {}

local BodyVelocity: BodyVelocity
local Character: TCharacter.TCharacter
local Connection: RBXScriptConnection?
local TimeElapsed = 0

local function stopDash()
	if BodyVelocity then
		BodyVelocity:Destroy()
		BodyVelocity = nil :: any
	end

	if Connection then
		Connection:Disconnect()
		Connection = nil
	end

	for _, track in CurrentAnimations do
		track:Stop(0.2)
	end
	table.clear(CurrentAnimations)

	TweensController.SetImmobile(false)

	local isSprinting = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
	local targetSpeed = if isSprinting then EMovementSpeeds.Running else EMovementSpeeds.Default
	local targetJump = if isSprinting then EMovementJumps.Running else EMovementJumps.Default

	TweensController.SetSpeed(targetSpeed, 0)
	TweensController.SetJump(targetJump, 0)
end

local function updateDashAnimSpeed()
	for _, track in CurrentAnimations do
		track:AdjustSpeed(TimeController.TimeScale)
	end
end

local function getRawKeyInput(): Vector3
	local x = 0
	local z = 0

	if UserInputService:IsKeyDown(Enum.KeyCode.W) then
		z -= 1
	end

	if UserInputService:IsKeyDown(Enum.KeyCode.S) then
		z += 1
	end

	if UserInputService:IsKeyDown(Enum.KeyCode.A) then
		x -= 1
	end

	if UserInputService:IsKeyDown(Enum.KeyCode.D) then
		x += 1
	end

	return Vector3.new(x, 0, z)
end

local function getMoveDirection(): Vector3
	if not Character then return Vector3.zero end

	local rootCF = Character.HumanoidRootPart.CFrame
	local look = rootCF.LookVector
	local right = rootCF.RightVector
	local input = Vector3.zero

	local canSteer = not DashController.IsDashing() or UpgradesController.HasUpgrade(EUpgrades.DashGod)
	local rawInput = getRawKeyInput()

	if rawInput.Magnitude > 0 and canSteer then
		input = rawInput
	else
		local dashDir = DashController.Direction

		if dashDir == EDirections.Front then
			input = Vector3.new(0, 0, -1)
		elseif dashDir == EDirections.FrontLeft then
			input = Vector3.new(-1, 0, -1)
		elseif dashDir == EDirections.FrontRight then
			input = Vector3.new(1, 0, -1)
		elseif dashDir == EDirections.BackLeft then
			input = Vector3.new(-1, 0, 1)
		elseif dashDir == EDirections.BackRight then
			input = Vector3.new(1, 0, 1)
		elseif dashDir == EDirections.Left then
			input = Vector3.new(-1, 0, 0)
		elseif dashDir == EDirections.Right then
			input = Vector3.new(1, 0, 0)
		else
			input = Vector3.new(0, 0, 1)
		end
	end

	local worldDirection = (look * -input.Z) + (right * input.X)

	return worldDirection
end

local function update(rawDt: number)
	if not Character then
		stopDash()
		return
	end

	local dt = TimeController.GetDeltaTime(rawDt)
	TimeElapsed += dt

	if TimeElapsed >= DASH_DURATION then
		stopDash()
		return
	end

	local progress = math.clamp(TimeElapsed / DASH_DURATION, 0, 1)
	local speed = Tools.Lerp(DASH_INITIAL_SPEED, DASH_FINAL_SPEED, progress)
	local moveDirection = getMoveDirection().Unit

	if BodyVelocity then BodyVelocity.Velocity = moveDirection * speed * TimeController.TimeScale end
end

function DashController.AddAmmo()
	SoundsController.PlayCharacter(ESounds.MagicReload)
	DashController.StoredProjectiles += 1
end

function DashController.UseAmmo(): boolean
	if DashController.StoredProjectiles > 0 then
		DashController.StoredProjectiles -= 1
		return true
	end

	return false
end

function DashController.IsDashing()
	return (time() - DashController.LastDashTime) <= DASH_DURATION
end

function DashController.OnCharacterAdded(character: TCharacter.TCharacter, characterEntity: jecs.Entity)
	local humanoid = World:get(characterEntity, Components.Humanoid)
	local animator = World:get(characterEntity, Components.Animator)

	if not humanoid or not animator then
		warn("Humanoid / Animator are nil")
		return
	end

	Character = character

	DashFront = animator:LoadAnimation(DashFrontAnim)
	DashBack = animator:LoadAnimation(DashBackAnim)
	DashLeft = animator:LoadAnimation(DashLeftAnim)
	DashRight = animator:LoadAnimation(DashRightAnim)

	DashAnimations[EDirections.Front] = { DashFront }
	DashAnimations[EDirections.FrontLeft] = { DashFront, DashLeft }
	DashAnimations[EDirections.FrontRight] = { DashFront, DashRight }
	DashAnimations[EDirections.Back] = { DashBack }
	DashAnimations[EDirections.BackLeft] = { DashBack, DashLeft }
	DashAnimations[EDirections.BackRight] = { DashBack, DashRight }
	DashAnimations[EDirections.Left] = { DashLeft }
	DashAnimations[EDirections.Right] = { DashRight }
end

function DashController.OnCharacterRemoving()
	stopDash()
	Character = nil :: any
end

function DashController.Dash()
	if not Character or TweensController.IsImmobile or HealthController.IsDead() then return end
	if (time() - DashController.LastDashTime) < DASH_COOLDOWN then return end
	if Connection then return end

	SoundsController.PlayCharacter(ESounds.Dash)
	DashController.LastDashTime = time()

	BodyVelocity = Instance.new("BodyVelocity")
	BodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge)
	BodyVelocity.Velocity = Vector3.zero
	BodyVelocity.Parent = Character.HumanoidRootPart

	TimeElapsed = 0

	local rawInput = getRawKeyInput()
	DashController.Direction = Tools.WorldMovingDirection(rawInput)

	if DashController.Direction == Vector3.zero or rawInput.Magnitude == 0 then
		DashController.Direction = EDirections.Back
	end

	local animations = DashAnimations[DashController.Direction]
	if not animations then return end

	for _, anim in animations do
		anim:Play(0.2)
		anim:AdjustSpeed(TimeController.TimeScale)
		CurrentAnimations[#CurrentAnimations + 1] = anim
	end

	TweensController.SetImmobile(true, 0.01)
	Connection = RunService.Heartbeat:Connect(update)
end

TimeController.TimeScaleChanged:Connect(function()
	if Connection then updateDashAnimSpeed() end
end)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp or input.KeyCode ~= Enum.KeyCode.Q then return end
	if TweensController.IsImmobile or HealthController.IsDead() then return end
	if not UpgradesController.HasUpgrade(EUpgrades.Dash) then return end

	DashController.Dash()
end)

RunService.Heartbeat:Connect(function(dt: number)
	local maxProjectiles = 1 + UpgradesController.GetUpgradeLevel(EUpgrades.Projectiles)

	local regenSpeedLevel = UpgradesController.GetUpgradeLevel(EUpgrades.ProjectilesRegen)
	local cooldown = DashController.AutoProjectilesCooldown * (1 - (regenSpeedLevel * 0.1))
	DashController.CurrentMaxRegenTime = cooldown

	if DashController.StoredProjectiles < maxProjectiles then
		DashController.AutoProjectilesCurrentCooldown -= dt
		if DashController.AutoProjectilesCurrentCooldown <= 0 then
			DashController.AutoProjectilesCurrentCooldown = cooldown

			DashController.StoredProjectiles += 1
			if DashController.StoredProjectiles > maxProjectiles then
				DashController.StoredProjectiles = maxProjectiles
			end
		end
	else
		DashController.AutoProjectilesCurrentCooldown = cooldown
	end
end)

return Ignis.Register(DashController)
