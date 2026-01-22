local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TimeController = require(script.Parent.TimeController)
local TweensController = require(script.Parent.TweensController)
local Ignis = require(ReplicatedStorage.Packages.Ignis)
local jecs = require(ReplicatedStorage.Packages.jecs)
local Components = require(ReplicatedStorage.Shared.ECS.Components)
local World = require(ReplicatedStorage.Shared.ECS.Worlds.World)
local Tools = require(ReplicatedStorage.Shared.Utils.Tools)
local ECameraFovs = require(ReplicatedStorage.Types.Enums.ECameraFovs)
local EMovementJumps = require(ReplicatedStorage.Types.Enums.Movement.EMovementJumps)
local EMovementSpeeds = require(ReplicatedStorage.Types.Enums.Movement.EMovementSpeeds)
local TCharacter = require(ReplicatedStorage.Types.TCharacter)

local FADE_OUT = 0.4
local FADE_IN = 0.4
local LIMIT = 1.32
local WALK_ANIM_SPEED = 1
local RUN_ANIM_SPEED = 1

local AnimationsFolder = ReplicatedStorage.Animations

local IdleAnim = AnimationsFolder.Idle :: Animation
local RunAnim = AnimationsFolder.Run :: Animation
local WalkAnim = AnimationsFolder.Walk :: Animation

local Run: AnimationTrack
local Walk: AnimationTrack
local Idle: AnimationTrack

local Character: TCharacter.TCharacter
local PrevAnimation: AnimationTrack?
local PrevAnimationStop: number = 0
local PrevAnimationTimePosition: number = 0
local ShiftTouched: boolean = false

local CurrentBaseSpeed = EMovementSpeeds.Default
local CurrentBaseJump = EMovementJumps.Default

local MovementController = {}

local function stopAllAnimations(fadeOut: number)
	PrevAnimationStop = tick()
	PrevAnimationTimePosition = if PrevAnimation then PrevAnimation.TimePosition else 0

	Run:Stop(fadeOut)
	Walk:Stop(fadeOut)
end

local function getAnimTime(): number
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

local function walkAnimSpeed()
	return ((Character.Humanoid.WalkSpeed * WALK_ANIM_SPEED) / EMovementSpeeds.Default) * TimeController.TimeScale
end

local function runAnimSpeed()
	return ((Character.Humanoid.WalkSpeed * RUN_ANIM_SPEED) / EMovementSpeeds.Running) * TimeController.TimeScale
end

local function updateSpeeds()
	if not Character then return end
	local humanoid = Character:FindFirstChild("Humanoid") :: Humanoid
	if not humanoid then return end

	humanoid.WalkSpeed = CurrentBaseSpeed * TimeController.TimeScale
	humanoid.JumpHeight = CurrentBaseJump * TimeController.TimeScale

	if Run and Run.IsPlaying then Run:AdjustSpeed(runAnimSpeed()) end
	if Walk and Walk.IsPlaying then Walk:AdjustSpeed(walkAnimSpeed()) end
	if Idle and Idle.IsPlaying then Idle:AdjustSpeed(0.65 * TimeController.TimeScale) end
end

local function moveDirection()
	local Direction = Tools.WorldMovingDirection(
		Character.HumanoidRootPart.CFrame:VectorToObjectSpace(Character.Humanoid.MoveDirection)
	)
	stopAllAnimations(FADE_OUT)
	if Direction == Vector3.zero or TweensController.IsImmobile then return end

	if ShiftTouched and Direction.Z ~= 1 then
		CurrentBaseSpeed = EMovementSpeeds.Running
		CurrentBaseJump = EMovementJumps.Running
		TweensController.SetCameraFov(ECameraFovs.Running, TweenInfo.new(1))
		TweensController.SetSpeed(CurrentBaseSpeed * TimeController.TimeScale, 1)
		TweensController.SetJump(CurrentBaseJump * TimeController.TimeScale, 1)
		Run:Play(FADE_IN, 1, runAnimSpeed())
		if PrevAnimation == Run then Run.TimePosition = getAnimTime() end
		PrevAnimation = Run
	else
		CurrentBaseSpeed = EMovementSpeeds.Default
		CurrentBaseJump = EMovementJumps.Default
		TweensController.SetCameraFov(ECameraFovs.Default, TweenInfo.new(0.65))
		TweensController.SetSpeed(CurrentBaseSpeed * TimeController.TimeScale, 0.65)
		TweensController.SetJump(CurrentBaseJump * TimeController.TimeScale, 0.65)
		Walk:Play(FADE_IN, 1, walkAnimSpeed())
		if PrevAnimation == Walk then Walk.TimePosition = getAnimTime() end
		PrevAnimation = Walk
	end
end

local function handleRunning(input: InputObject)
	if input.KeyCode ~= Enum.KeyCode.LeftShift then return end

	if input.UserInputState == Enum.UserInputState.Begin then
		ShiftTouched = true
	else
		ShiftTouched = false
	end

	moveDirection()
end

MovementController.OnCharacterAdded = function(character: TCharacter.TCharacter, characterEntity: jecs.Entity)
	local butler = World:get(characterEntity, Components.Butler)
	local humanoid = World:get(characterEntity, Components.Humanoid)
	local animator = World:get(characterEntity, Components.Animator)

	if not humanoid or not animator or not butler then
		warn("Humanoid / HumanoidRootPart / Butler are nil")
		return
	end

	Character = character

	Idle = animator:LoadAnimation(IdleAnim)
	Idle:Play(0.1, 1, 0.65)

	Run = animator:LoadAnimation(RunAnim)
	Walk = animator:LoadAnimation(WalkAnim)

	butler:Connect(humanoid:GetPropertyChangedSignal("MoveDirection"), moveDirection)
	butler:Connect(humanoid:GetPropertyChangedSignal("WalkSpeed"), moveDirection)
	butler:Connect(UserInputService.InputBegan, handleRunning)
	butler:Connect(UserInputService.InputEnded, handleRunning)
	butler:Connect(TimeController.TimeScaleChanged :: any, updateSpeeds)

	humanoid.WalkSpeed = EMovementSpeeds.Default
	humanoid.JumpHeight = EMovementJumps.Default
end

return Ignis.Register(MovementController)
