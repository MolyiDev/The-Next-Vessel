local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local UserGameSettings = UserSettings():GetService("UserGameSettings")
local Ignis = require(ReplicatedStorage.Packages.Ignis)
local ECameraFovs = require(ReplicatedStorage.Types.Enums.ECameraFovs)
local TCharacter = require(ReplicatedStorage.Types.TCharacter)

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()
local Camera = Workspace.CurrentCamera

Camera.FieldOfView = ECameraFovs.Default
Camera.CameraType = Enum.CameraType.Scriptable

local CameraYaw = 0
local CameraPitch = 0
local RandomPitch = 0
local RandomRoll = 0
local MouseDrift = 0
local OscX = 0
local SwayYaw = 0
local VelTilt = 0

local CameraSensitivity = 0.15
local MaxOffset = 25

local Config = {
	Idle = { Threshold = 0.1, Freq = 13, Amp = 15 },
	Walk = { Threshold = 10, Freq = 15, Amp = 17 },
	Run = { Threshold = 18, Freq = 16, Amp = 18 },
}

local Humanoid: Humanoid
local HumanoidRootPart: BasePart

local CameraController = {}
CameraController.MouseActive = true
CameraController.CameraLocked = false

function CameraController.HideMouse()
	UserInputService.MouseIconEnabled = false
end

function CameraController.ShowMouse()
	UserInputService.MouseIconEnabled = true
end

function CameraController.ToggleMouse()
	if CameraController.MouseActive then
		CameraController.HideMouse()
	else
		CameraController.ShowMouse()
	end
end

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

local function randomizeOffset(magnitude: number, positionInfluence: Vector3, rotationInfluence: Vector3)
	-- Random position
	local positionOffset: Vector3 =
		Vector3.new(math.random(-1, 1) * magnitude, math.random(-1, 1) * magnitude, math.random(-1, 1) * magnitude)
	positionOffset *= positionInfluence

	-- Random rotation
	local rotationOffset: Vector3 =
		Vector3.new(math.random(-1, 1) * magnitude, math.random(-1, 1) * magnitude, math.random(-1, 1) * magnitude)
	rotationOffset *= rotationInfluence

	-- Combine into CFrame
	local offsetCF: CFrame = CFrame.new(positionOffset)
		* CFrame.Angles(math.rad(rotationOffset.X), math.rad(rotationOffset.Y), math.rad(rotationOffset.Z))
	return offsetCF
end

-- Should take the next values:
--
-- Magnitude
-- How vigorous the shake will be; how far in each direaction the camera can shake
-- Higher number, more strength
--
-- Roughness
-- Determines how 'rough' the shaking will be
-- Higher number = smoother, lower number = sharper
-- The time, in secods, each jut in a direction will take
--
-- Duration
-- How long the shake will last, in secods
--
-- PositionInfluence
-- How much the shake will affect each positional axis
-- Relative to world
--
-- RotationInfluence
-- How much the shake will affect each positional axis
-- Relative to world
--
-- FadeOut
-- The amount the Magnitude will fade out by along the duration of the shake (substracted each frame)
-- Higher number = faster fade out
function CameraController.Shake(
	magnitude: number,
	roughness: number,
	duration: number,
	positionInfluence: Vector3,
	rotationInfluence: Vector3,
	fadeOut: number
)
	local magnitudeCopy: number = magnitude
	local startTime = os.clock()

	repeat
		-- Get a random offsetted CFrame based on CameraShake.new values
		local offsetCF: CFrame = randomizeOffset(magnitude, positionInfluence, rotationInfluence)

		RunService.RenderStepped:Wait()
		local beforeCF = Camera.CFrame
		local goalCF = beforeCF * offsetCF

		local lerpStart = os.clock()

		repeat
			goalCF = beforeCF * offsetCF
			Camera.CFrame = Camera.CFrame:Lerp(goalCF, 0.5)
			RunService.RenderStepped:Wait()
		until os.clock() - lerpStart >= roughness / 100

		magnitude = math.clamp(magnitude - fadeOut, 0, magnitudeCopy)

	until os.clock() - startTime >= duration
end

local Connection: RBXScriptConnection

local function Lerp(a: number, b: number, t: number)
	return a + (b - a) * t
end

local function UpdateCamera(dt: number)
	dt *= 60

	UserInputService.MouseBehavior = CameraController.CameraLocked and Enum.MouseBehavior.LockCenter
		or Enum.MouseBehavior.Default

	if Humanoid.AutoRotate then
		local velocity = HumanoidRootPart.AssemblyAngularVelocity
		local speed = Vector3.new(velocity.x, 0, velocity.z).magnitude

		local freq = 0
		local amp = 0

		if speed > Config.Run.Threshold then
			freq = Config.Run.Freq
			amp = Config.Run.Amp
		elseif speed > Config.Walk.Threshold then
			freq = Config.Walk.Freq
			amp = Config.Walk.Amp
		elseif speed > Config.Idle.Threshold then
			freq = Config.Idle.Freq
			amp = Config.Idle.Amp
		end

		RandomPitch = Lerp(
			RandomPitch,
			math.cos(tick() * 0.5 * math.random(10, 15)) * ((math.random(5, 200) / 200) * dt),
			0.05 * dt
		)

		RandomRoll =
			Lerp(RandomRoll, math.cos(tick() * 0.5 * math.random(5, 10)) * ((math.random(2, 10) / 200) * dt), 0.05 * dt)

		local walkSpeed = math.max(Humanoid.WalkSpeed, 0.01)

		VelTilt = math.clamp(
			Lerp(VelTilt, Camera.CFrame:VectorToObjectSpace(velocity / walkSpeed).x * 0.08, 0.1 * dt),
			-0.35,
			0.2
		)

		MouseDrift = Lerp(MouseDrift, math.clamp(UserInputService:GetMouseDelta().X, -5, 5), 0.25 * dt)
		OscX = Lerp(OscX, (math.sin(tick() * freq) / 5) * math.min(1, amp / 10), 0.25 * dt)

		if speed > 1 then
			SwayYaw = Lerp(SwayYaw, math.cos(tick() * 0.5 * math.floor(freq)) * (freq / 200), 0.25 * dt)
		else
			SwayYaw = Lerp(SwayYaw, 0, 0.05 * dt)
		end

		Camera.CFrame = Camera.CFrame
				* CFrame.fromEulerAnglesXYZ(0, 0, math.rad(MouseDrift))
				* CFrame.fromEulerAnglesXYZ(math.rad(OscX * dt), math.rad(SwayYaw * dt), VelTilt)
				* CFrame.Angles(0, 0, math.rad(OscX * dt * (speed / 5)))
				* CFrame.fromEulerAnglesXYZ(math.rad(RandomPitch), math.rad(RandomRoll), math.rad(RandomRoll * 10))
			+ Humanoid.CameraOffset

		local mouseDelta = UserInputService:GetMouseDelta()
		local mouseSensitivity = UserGameSettings.MouseSensitivity

		CameraYaw = CameraYaw + math.rad(mouseDelta.x * 0.25 * mouseSensitivity * -1)
		CameraPitch =
			math.clamp(CameraPitch + math.rad(mouseDelta.y * 0.25 * mouseSensitivity * -1), math.rad(-75), math.rad(75))

		Camera.Focus = CFrame.new((Camera.CameraSubject :: BasePart).Position)

		Camera.CFrame = Camera.Focus * CFrame.fromEulerAnglesYXZ(CameraPitch, CameraYaw, 0) * CFrame.new(0, 0.75, -0.1)

		local _, y, _ = Camera.CFrame:ToOrientation()
		HumanoidRootPart.CFrame = CFrame.new(HumanoidRootPart.Position) * CFrame.Angles(0, y, 0)

		return
	end

	local viewportSize = Camera.ViewportSize

	local OffsetX = ((Mouse.X - viewportSize.X / 2) / (viewportSize.X / 2)) * MaxOffset
	local OffsetY = ((Mouse.Y - viewportSize.Y / 2) / (viewportSize.Y / 2)) * MaxOffset

	Camera.Focus = Camera.CameraSubject.CFrame
	Camera.CFrame = Camera.Focus
		* CFrame.Angles(math.rad(-OffsetY * CameraSensitivity), math.rad(-OffsetX * CameraSensitivity), 0)
		* CFrame.new(0, 0.75, -0.1)

	CameraController.UpdateRotation()

	Camera.CFrame = Camera.CFrame + Humanoid.CameraOffset
end

function CameraController.Update()
	UpdateCamera(1 / 60)
end

CameraController.OnCharacterAdded = function(character: TCharacter.TCharacter)
	Humanoid = character.Humanoid
	HumanoidRootPart = character.HumanoidRootPart

	local firstSpawn = CollectionService:GetTagged("FirstSpawn")[1] :: Attachment
	if firstSpawn then character.HumanoidRootPart.CFrame = firstSpawn.WorldCFrame end

	Camera.CameraSubject = character.Head
	Camera.CFrame = character.Head.CFrame

	Connection = RunService.PreRender:Connect(UpdateCamera)
end

CameraController.OnCharacterRemoving = function()
	if Connection then Connection:Disconnect() end
end

return Ignis.Register(CameraController)
