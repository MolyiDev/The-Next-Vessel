local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HealthController = require(script.Parent.HealthController)
local TweensController = require(script.Parent.TweensController)
local Ignis = require(ReplicatedStorage.Packages.Ignis)
local Tools = require(ReplicatedStorage.Shared.Utils.Tools)
local EDirections = require(ReplicatedStorage.Types.Enums.EDirections)
local UpgradesController = require(script.Parent.UpgradesController)
local EUpgrades = require(ReplicatedStorage.Types.Enums.EUpgrades)
local TCharacter = require(ReplicatedStorage.Types.TCharacter)

local DASH_DURATION = 0.5
local DASH_INITIAL_SPEED = 70
local DASH_FINAL_SPEED = 25
local DASH_COOLDOWN = 2.5

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
DashController.LastDashTime = 0

local CurrentAnimations: { AnimationTrack } = {}

local BodyVelocity: BodyVelocity
local Character: TCharacter.TCharacter
local Connection: RBXScriptConnection?

local TimeElapsed = 0
local Direction = Vector3.zero

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

	TweensController.SetImmobile(false, 0.01)
end

local function getMoveDirection(): Vector3
	if not Character then return Vector3.zero end

	local rootCF = Character.HumanoidRootPart.CFrame
	local look = rootCF.LookVector
	local right = rootCF.RightVector

	if Direction == EDirections.Front then
		return look
	elseif Direction == EDirections.FrontLeft then
		return look - right
	elseif Direction == EDirections.FrontRight then
		return look + right
	elseif Direction == EDirections.Back then
		return -look
	elseif Direction == EDirections.BackLeft then
		return -look - right
	elseif Direction == EDirections.BackRight then
		return -look + right
	elseif Direction == EDirections.Left then
		return -right
	elseif Direction == EDirections.Right then
		return right
	end

	return -look
end

local function update(dt: number)
	if not Character then
		stopDash()
		return
	end

	TimeElapsed += dt

	if TimeElapsed >= DASH_DURATION then
		stopDash()
		return
	end

	local progress = math.clamp(TimeElapsed / DASH_DURATION, 0, 1)
	local speed = Tools.Lerp(DASH_INITIAL_SPEED, DASH_FINAL_SPEED, progress)
	local moveDirection = getMoveDirection().Unit

	if BodyVelocity then BodyVelocity.Velocity = moveDirection * speed end
end

function DashController.IsDashing()
	return (time() - DashController.LastDashTime) <= DASH_DURATION
end

function DashController.OnCharacterAdded(character: TCharacter.TCharacter)
	local humanoid = character:FindFirstChild("Humanoid") :: Humanoid
	if not humanoid then return end
	local animator = humanoid:FindFirstChild("Animator") :: Animator
	if not animator then return end

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

	DashController.LastDashTime = time()

	BodyVelocity = Instance.new("BodyVelocity")
	BodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge)
	BodyVelocity.Velocity = Vector3.zero
	BodyVelocity.Parent = Character.HumanoidRootPart

	TimeElapsed = 0
	Direction = Tools.WorldMovingDirection(
		Character.HumanoidRootPart.CFrame:VectorToObjectSpace(Character.Humanoid.MoveDirection)
	)
	if Direction == Vector3.zero then Direction = EDirections.Back end

	local animations = DashAnimations[Direction]
	if not animations then return end

	for _, anim in animations do
		anim:Play(0.2)
		CurrentAnimations[#CurrentAnimations + 1] = anim
	end

	TweensController.SetImmobile(true, 0.01)
	Connection = RunService.Heartbeat:Connect(update)
end

UserInputService.InputBegan:Connect(function(input, gp)
	if gp or input.KeyCode ~= Enum.KeyCode.Q then return end
	-- if not UpgradesController.HasUpgrade(EUpgrades.Dash) then return end
	DashController.Dash()
end)

return Ignis.Register(DashController)
