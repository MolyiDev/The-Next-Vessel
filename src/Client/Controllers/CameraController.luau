local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local UserGameSettings = UserSettings():GetService("UserGameSettings")
local DashController = require(script.Parent.DashController)
local TimeController = require(script.Parent.TimeController)
local Ignis = require(ReplicatedStorage.Packages.Ignis)
local jecs = require(ReplicatedStorage.Packages.jecs)
local Components = require(ReplicatedStorage.Shared.ECS.Components)
local World = require(ReplicatedStorage.Shared.ECS.Worlds.World)
local Tools = require(ReplicatedStorage.Shared.Utils.Tools)
local ECameraFovs = require(ReplicatedStorage.Types.Enums.ECameraFovs)
local EDirections = require(ReplicatedStorage.Types.Enums.EDirections)
local TCharacter = require(ReplicatedStorage.Types.TCharacter)

type ShakeInstance = {
	Magnitude: number,
	Roughness: number,
	Duration: number,
	FadeOut: number,
	PosInf: Vector3,
	RotInf: Vector3,
	StartTime: number,
	Seed: number,
}

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()
local Camera = Workspace.CurrentCamera

local CameraYaw = 0
local CameraPitch = 0
local RandomPitch = 0
local RandomRoll = 0
local MouseDrift = 0
local OscX = 0
local SwayYaw = 0
local VelTilt = 0

local AccumulatedTime = 0

local CameraSensitivity = 0.15
local MaxOffset = 25

local Config = {
	Idle = { Threshold = 0.1, Freq = 13, Amp = 15 },
	Walk = { Threshold = 10, Freq = 15, Amp = 17 },
	Run = { Threshold = 18, Freq = 16, Amp = 18 },
}

local ActiveShakes: { ShakeInstance } = {}

local Humanoid: Humanoid
local HumanoidRootPart: BasePart

local CameraController = {}
CameraController.CameraLocked = false

function CameraController.LockCamera()
	CameraController.CameraLocked = true
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
end

function CameraController.UnlockCamera()
	CameraController.CameraLocked = false
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
end

function CameraController.ToggleCameraLock()
	if CameraController.CameraLocked then
		CameraController.UnlockCamera()
	else
		CameraController.LockCamera()
	end
end

function CameraController.UpdateRotation()
	local rx, ry, _ = Camera.CFrame:ToEulerAnglesYXZ()
	CameraPitch = rx
	CameraYaw = ry
end

function CameraController.Shake(
	magnitude: number,
	roughness: number,
	duration: number,
	positionInfluence: Vector3?,
	rotationInfluence: Vector3?,
	fadeOut: number?
)
	ActiveShakes[#ActiveShakes + 1] = {
		Magnitude = magnitude,
		Roughness = roughness,
		Duration = duration,
		FadeOut = fadeOut or 0,
		PosInf = positionInfluence or Vector3.new(0.1, 0.1, 0.1),
		RotInf = rotationInfluence or Vector3.new(1, 1, 1),
		StartTime = AccumulatedTime,
		Seed = math.random() * 1000,
	}
end

local function computeShakeOffset(): CFrame
	local now = AccumulatedTime
	local totalPos = Vector3.zero
	local totalRot = Vector3.zero

	for i = #ActiveShakes, 1, -1 do
		local shake = ActiveShakes[i]
		if not shake then table.remove(ActiveShakes, i) end

		local elapsed = now - shake.StartTime

		if elapsed >= shake.Duration then
			table.remove(ActiveShakes, i)
			continue
		end

		local alpha = 1 - (elapsed / shake.Duration)
		local currentMag = shake.Magnitude * alpha

		local freq = 4 / math.max(shake.Roughness, 0.01)
		local t = now * freq

		local nX = (math.noise(t, shake.Seed, 1) * 2)
		local nY = (math.noise(t, shake.Seed, 2) * 2)
		local nZ = (math.noise(t, shake.Seed, 3) * 2)

		local pX = (math.noise(t, shake.Seed, 4) * 2)
		local pY = (math.noise(t, shake.Seed, 5) * 2)
		local pZ = (math.noise(t, shake.Seed, 6) * 2)

		totalRot += Vector3.new(nX, nY, nZ) * shake.RotInf * currentMag
		totalPos += Vector3.new(pX, pY, pZ) * shake.PosInf * currentMag
	end

	return CFrame.new(totalPos) * CFrame.Angles(math.rad(totalRot.X), math.rad(totalRot.Y), math.rad(totalRot.Z))
end

local function UpdateCamera(rawDt: number)
	local dt = TimeController.GetDeltaTime(rawDt)
	AccumulatedTime += dt -- Raw time for sine waves (correct)
	local scaledDt = dt * 60 -- Scaled time for Lerps

	UserInputService.MouseBehavior = CameraController.CameraLocked and Enum.MouseBehavior.LockCenter
		or Enum.MouseBehavior.Default

	local shakeCF = computeShakeOffset()

	if not Humanoid.AutoRotate then
		local viewportSize = Camera.ViewportSize
		local OffsetX = ((Mouse.X - viewportSize.X / 2) / (viewportSize.X / 2)) * MaxOffset
		local OffsetY = ((Mouse.Y - viewportSize.Y / 2) / (viewportSize.Y / 2)) * MaxOffset

		Camera.Focus = Camera.CameraSubject.CFrame
		Camera.CFrame = Camera.Focus
			* CFrame.Angles(math.rad(-OffsetY * CameraSensitivity), math.rad(-OffsetX * CameraSensitivity), 0)
			* shakeCF
			* CFrame.new(0, 0.75, -0.1)

		CameraController.UpdateRotation()
		Camera.CFrame = Camera.CFrame + Humanoid.CameraOffset
		return
	end

	local mouseDelta = UserInputService:GetMouseDelta()
	local mouseSensitivity = UserGameSettings.MouseSensitivity

	CameraYaw = CameraYaw + math.rad(mouseDelta.x * 0.25 * mouseSensitivity * -1)
	CameraPitch =
		math.clamp(CameraPitch + math.rad(mouseDelta.y * 0.25 * mouseSensitivity * -1), math.rad(-75), math.rad(75))

	Camera.Focus = CFrame.new((Camera.CameraSubject :: BasePart).Position)

	local baseCFrame = Camera.Focus * CFrame.fromEulerAnglesYXZ(CameraPitch, CameraYaw, 0) * CFrame.new(0, 0.75, -0.1)

	local velocity = HumanoidRootPart.AssemblyLinearVelocity
	local speed = Vector3.new(velocity.x, 0, velocity.z).Magnitude

	local freq = 0
	local amp = 0

	if speed > Config.Run.Threshold then
		freq = Config.Run.Freq
		amp = Config.Run.Amp
		speed = Config.Run.Threshold
		velocity = Vector3.new(
			math.min(velocity.x, Config.Run.Threshold),
			math.min(velocity.y, Config.Run.Threshold),
			math.min(velocity.z, Config.Run.Threshold)
		)
	elseif speed > Config.Walk.Threshold then
		freq = Config.Walk.Freq
		amp = Config.Walk.Amp
		speed = Config.Walk.Threshold
	elseif speed > Config.Idle.Threshold then
		freq = Config.Idle.Freq
		amp = Config.Idle.Amp
		speed = Config.Idle.Threshold
	end

	-- FIX 1: Clamp Max Alpha to 0.5.
	-- If FPS is low, we want the camera to "drag" slightly behind the target
	-- to smooth out the choppy sine wave steps, rather than snapping to them.
	local noiseAlpha = math.min(0.05 * scaledDt, 0.5)
	local movementAlpha = math.min(0.25 * scaledDt, 0.5)

	-- FIX 2: Removed `* scaledDt` from the magnitude (the multiplier after math.cos).
	-- Magnitude should be constant regardless of frame rate.
	RandomPitch = Tools.Lerp(
		RandomPitch,
		math.cos(AccumulatedTime * 0.5 * math.random(10, 15)) * (math.random(5, 200) / 200),
		noiseAlpha
	)
	RandomRoll = Tools.Lerp(
		RandomRoll,
		math.cos(AccumulatedTime * 0.5 * math.random(5, 10)) * (math.random(2, 10) / 200),
		noiseAlpha
	)

	local walkSpeed = math.max(Humanoid.WalkSpeed, 0.01)

	VelTilt = if DashController.IsDashing() and DashController.Direction == EDirections.Front
		then 0
		else math.clamp(
			Tools.Lerp(VelTilt, -Camera.CFrame:VectorToObjectSpace(velocity / walkSpeed).x * 0.08, 0.1 * scaledDt),
			-0.35,
			0.2
		)
	MouseDrift = Tools.Lerp(MouseDrift, math.clamp(UserInputService:GetMouseDelta().X, -5, 5), movementAlpha)

	local targetOscX = (math.sin(AccumulatedTime * freq) / 5) * math.min(1, amp / 10)
	OscX = Tools.Lerp(OscX, targetOscX, movementAlpha)

	if speed > 1 then
		local targetSway = math.cos(AccumulatedTime * 0.5 * math.floor(freq)) * (freq / 200)
		SwayYaw = Tools.Lerp(SwayYaw, targetSway, movementAlpha)
	else
		SwayYaw = Tools.Lerp(SwayYaw, 0, 0.05 * scaledDt)
	end

	Camera.CFrame = baseCFrame
			* CFrame.fromEulerAnglesXYZ(0, 0, math.rad(MouseDrift))
			* CFrame.fromEulerAnglesXYZ(math.rad(OscX), math.rad(SwayYaw), VelTilt)
			* CFrame.Angles(0, 0, math.rad(OscX * (speed / 5)))
			* CFrame.fromEulerAnglesXYZ(math.rad(RandomPitch), math.rad(RandomRoll), math.rad(RandomRoll * 10))
			* shakeCF
		+ Humanoid.CameraOffset

	local _, y, _ = Camera.CFrame:ToOrientation()
	HumanoidRootPart.CFrame = CFrame.new(HumanoidRootPart.Position) * CFrame.Angles(0, y, 0)
end

function CameraController.Update()
	UpdateCamera(1 / 60)
end

CameraController.OnCharacterAdded = function(character: TCharacter.TCharacter, characterEntity: jecs.Entity)
	local butler = World:get(characterEntity, Components.Butler)
	HumanoidRootPart = World:get(characterEntity, Components.HumanoidRootPart) :: BasePart
	Humanoid = World:get(characterEntity, Components.Humanoid) :: Humanoid
	if not Humanoid or not HumanoidRootPart or not butler then
		warn("Humanoid / HumanoidRootPart / Butler are nil")
		return
	end

	local firstSpawn = CollectionService:GetTagged("SecondSpawn")[1] :: Attachment
	if firstSpawn then HumanoidRootPart.CFrame = firstSpawn.WorldCFrame end

	Camera.CameraSubject = character.Head
	Camera.Focus = Camera.CameraSubject.CFrame
	Camera.CFrame = Camera.Focus
	Camera.FieldOfView = ECameraFovs.Default
	Camera.CameraType = Enum.CameraType.Scriptable

	butler:BindToRenderStep("FirstPerson", 0, UpdateCamera)
end

return Ignis.Register(CameraController)
