local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweensController = require(script.Parent.TweensController)
local Ignis = require(ReplicatedStorage.Packages.Ignis)
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

local Character: TCharacter.TCharacter
local PrevAnimation: AnimationTrack?
local PrevAnimationStop: number = 0
local PrevAnimationTimePosition: number = 0
local ShiftTouched: boolean = false

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
	return (Character.Humanoid.WalkSpeed * WALK_ANIM_SPEED) / EMovementSpeeds.Default
end

local function runAnimSpeed()
	return (Character.Humanoid.WalkSpeed * RUN_ANIM_SPEED) / EMovementSpeeds.Running
end

local function moveDirection()
	local Direction = Tools.WorldMovingDirection(
		Character.HumanoidRootPart.CFrame:VectorToObjectSpace(Character.Humanoid.MoveDirection)
	)
	stopAllAnimations(FADE_OUT)
	if Direction == Vector3.zero or TweensController.IsImmobile then return end

	if ShiftTouched and Direction.Z ~= 1 then
		TweensController.SetCameraFov(ECameraFovs.Running, TweenInfo.new(1))
		TweensController.SetSpeed(EMovementSpeeds.Running, 1)
		TweensController.SetJump(EMovementJumps.Running, 1)
		Run:Play(FADE_IN, 1, runAnimSpeed())
		if PrevAnimation == Run then Run.TimePosition = getAnimTime() end
		PrevAnimation = Run
	else
		TweensController.SetCameraFov(ECameraFovs.Default, TweenInfo.new(0.65))
		TweensController.SetSpeed(EMovementSpeeds.Default, 0.65)
		TweensController.SetJump(EMovementJumps.Default, 0.65)
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

	animator:LoadAnimation(IdleAnim):Play(0.1, 1, 0.65)
	Run = animator:LoadAnimation(RunAnim)
	Walk = animator:LoadAnimation(WalkAnim)

	Connections[#Connections + 1] = humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(moveDirection)
	Connections[#Connections + 1] = humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(moveDirection)
	Connections[#Connections + 1] = UserInputService.InputBegan:Connect(handleRunning)
	Connections[#Connections + 1] = UserInputService.InputEnded:Connect(handleRunning)

	humanoid.WalkSpeed = EMovementSpeeds.Default
	humanoid.JumpHeight = EMovementJumps.Default
end

return Ignis.Register(MovementController)
