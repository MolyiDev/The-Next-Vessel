local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweensController = require(script.Parent.TweensController)
local Ignis = require(ReplicatedStorage.Packages.Ignis)
local ECameraFovs = require(ReplicatedStorage.Types.Enums.ECameraFovs)
local EDirections = require(ReplicatedStorage.Types.Enums.EDirections)
local EMovementJumps = require(ReplicatedStorage.Types.Enums.Movement.EMovementJumps)
local EMovementSpeeds = require(ReplicatedStorage.Types.Enums.Movement.EMovementSpeeds)
local TCharacter = require(ReplicatedStorage.Types.TCharacter)

local FADE_OUT = 0.4
local FADE_IN = 0.4
local LIMIT = 1.32
local WALK_ANIM_SPEED = 1.35
local RUN_ANIM_SPEED = 2

local AnimationsFolder = ReplicatedStorage.Animations
local RunAnimationsFolder = AnimationsFolder.Running
local WalkAnimationsFolder = AnimationsFolder.Walking

local IdleAnim = AnimationsFolder.Idle :: Animation
local RunFrontAnim = RunAnimationsFolder.RunFront :: Animation
local WalkFrontAnim = WalkAnimationsFolder.WalkFront :: Animation
local WalkFrontLeftAnim = WalkAnimationsFolder.WalkFrontLeft :: Animation
local WalkFrontRightAnim = WalkAnimationsFolder.WalkFrontRight :: Animation
local WalkBackAnim = WalkAnimationsFolder.WalkBack :: Animation
local WalkBackLeftAnim = WalkAnimationsFolder.WalkBackLeft :: Animation
local WalkBackRightAnim = WalkAnimationsFolder.WalkBackRight :: Animation
local WalkLeftAnim = WalkAnimationsFolder.WalkLeft :: Animation
local WalkRightAnim = WalkAnimationsFolder.WalkRight :: Animation

local RunFront: AnimationTrack
local WalkFront: AnimationTrack
local WalkFrontLeft: AnimationTrack
local WalkFrontRight: AnimationTrack
local WalkBack: AnimationTrack
local WalkBackLeft: AnimationTrack
local WalkBackRight: AnimationTrack
local WalkLeft: AnimationTrack
local WalkRight: AnimationTrack

local WalkAnimations: { [Vector3]: AnimationTrack } = {}

local Character: TCharacter.TCharacter
local PrevAnimation: AnimationTrack?
local PrevAnimationStop: number = 0
local PrevAnimationTimePosition: number = 0
local ShiftTouched: boolean = false

local MovementController = {}

local function WorldMovingDirection(direction: Vector3): Vector3
	if direction == Vector3.zero then return direction end

	local angle = math.atan2(direction.X, -direction.Z)
	local quarterTurn = math.pi / 4
	angle = -math.round(angle / quarterTurn) * quarterTurn
	local newX = math.round(-math.sin(angle))
	local newZ = math.round(-math.cos(angle))
	if math.abs(newX) <= 1e-10 then newX = 0 end
	if math.abs(newZ) <= 1e-10 then newZ = 0 end

	return Vector3.new(newX, 0, newZ)
end

local function StopAllAnimations(fadeOut: number)
	PrevAnimationStop = tick()
	PrevAnimationTimePosition = if PrevAnimation then PrevAnimation.TimePosition else 0

	RunFront:Stop(fadeOut)
	WalkFront:Stop(fadeOut)
	WalkFrontLeft:Stop(fadeOut)
	WalkFrontRight:Stop(fadeOut)
	WalkBack:Stop(fadeOut)
	WalkBackLeft:Stop(fadeOut)
	WalkBackRight:Stop(fadeOut)
	WalkLeft:Stop(fadeOut)
	WalkRight:Stop(fadeOut)
end

local function GetAnimTime(): number
	local timeTick = tick() - PrevAnimationStop
	if not PrevAnimation or timeTick > FADE_OUT then return 0 end

	local result = PrevAnimationTimePosition + timeTick
	if result > LIMIT then
		result = result - LIMIT
	elseif result < 0 then
		result = LIMIT - math.abs(result)
	end

	return result
end

local function WalkAnimSpeed()
	return (Character.Humanoid.WalkSpeed * WALK_ANIM_SPEED) / 11
end

local function RunAnimSpeed()
	return (Character.Humanoid.WalkSpeed * RUN_ANIM_SPEED) / 26
end

local function MoveDirection()
	local Direction =
		WorldMovingDirection(Workspace.CurrentCamera.CFrame:VectorToObjectSpace(Character.Humanoid.MoveDirection))
	StopAllAnimations(FADE_OUT)
	if Direction == Vector3.zero or TweensController.IsImmobile then return end

	if ShiftTouched and Direction.Z ~= 1 then
		TweensController.SetCameraFov(ECameraFovs.Running, TweenInfo.new(1))
		TweensController.SetSpeed(EMovementSpeeds.Running, 1)
		TweensController.SetJump(EMovementJumps.Running, 1)
		RunFront:Play(FADE_IN, 1, RunAnimSpeed())
		RunFront.TimePosition = GetAnimTime()
		PrevAnimation = RunFront
	else
		TweensController.SetCameraFov(ECameraFovs.Default, TweenInfo.new(0.65))
		TweensController.SetSpeed(EMovementSpeeds.Default, 0.65)
		TweensController.SetJump(EMovementJumps.Default, 0.65)
		local Animation = WalkAnimations[Direction]
		Animation:Play(FADE_IN, 1, WalkAnimSpeed())
		Animation.TimePosition = GetAnimTime()
		PrevAnimation = Animation
	end
end

local Connections: { RBXScriptConnection } = {}

MovementController.OnCharacterRemoving = function()
	for _, connection in Connections do
		connection:Disconnect()
	end

	table.clear(Connections)
end

MovementController.OnCharacterAdded = function(character: TCharacter.TCharacter)
	Character = character
	local humanoid = Character:FindFirstChild("Humanoid") :: Humanoid
	if not humanoid then return warn(`Humanoid don't spawned.`) end
	local animator = humanoid:FindFirstChild("Animator") :: Animator
	if not animator then return warn(`Animator don't spawned.`) end

	-- Idle
	animator:LoadAnimation(IdleAnim):Play(0.1, 1, 0.65)

	-- Run animations
	RunFront = animator:LoadAnimation(RunFrontAnim)
	-- Walk animations
	WalkFront = animator:LoadAnimation(WalkFrontAnim)
	WalkFrontLeft = animator:LoadAnimation(WalkFrontLeftAnim)
	WalkFrontRight = animator:LoadAnimation(WalkFrontRightAnim)
	WalkBack = animator:LoadAnimation(WalkBackAnim)
	WalkBackLeft = animator:LoadAnimation(WalkBackLeftAnim)
	WalkBackRight = animator:LoadAnimation(WalkBackRightAnim)
	WalkLeft = animator:LoadAnimation(WalkLeftAnim)
	WalkRight = animator:LoadAnimation(WalkRightAnim)

	WalkAnimations[EDirections.Front] = WalkFront
	WalkAnimations[EDirections.FrontLeft] = WalkFrontLeft
	WalkAnimations[EDirections.FrontRight] = WalkFrontRight
	WalkAnimations[EDirections.Back] = WalkBack
	WalkAnimations[EDirections.BackLeft] = WalkBackLeft
	WalkAnimations[EDirections.BackRight] = WalkBackRight
	WalkAnimations[EDirections.BackLeft] = WalkBackLeft
	WalkAnimations[EDirections.BackRight] = WalkBackRight
	WalkAnimations[EDirections.Left] = WalkLeft
	WalkAnimations[EDirections.Right] = WalkRight

	Connections[#Connections + 1] = humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(MoveDirection)
	Connections[#Connections + 1] = humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(MoveDirection)

	humanoid.WalkSpeed = EMovementSpeeds.Default
	humanoid.JumpHeight = EMovementJumps.Default
end

return Ignis.Register(MovementController)
