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

local initX, initY, _ = Camera.CFrame:ToEulerAngles(Enum.RotationOrder.XYZ)

local xRot = initY
local yRot = -initX
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
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
end

function CameraController.UnlockCamera()
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
end

function CameraController.ToggleCameraLock()
	if CameraController.CameraLocked then
		CameraController.UnlockCamera()
	else
		CameraController.LockCamera()
	end
end

local connection: RBXScriptConnection

local function Lerp(a: number, b: number, t: number)
	return a + (b - a) * t
end

local function updateCamera(dt: number)
	dt *= 60
	if CameraController.CameraLocked then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
	else
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end

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

		xRot = xRot + math.rad(mouseDelta.x * 0.25 * mouseSensitivity * -1)
		yRot = math.clamp(yRot + math.rad(mouseDelta.y * 0.25 * mouseSensitivity * -1), math.rad(-75), math.rad(75))

		Camera.Focus = CFrame.new((Camera.CameraSubject :: BasePart).Position)
		Camera.CFrame = Camera.Focus * CFrame.fromEulerAnglesYXZ(yRot, xRot, 0) * CFrame.new(0, 0.75, -0.1)

		local _, y, _ = Camera.CFrame:ToOrientation()
		HumanoidRootPart.CFrame = CFrame.new(HumanoidRootPart.Position) * CFrame.Angles(0, y, 0)
	else
		local viewportSize = Camera.ViewportSize

		local OffsetX = ((Mouse.X - viewportSize.X / 2) / (viewportSize.X / 2)) * MaxOffset
		local OffsetY = ((Mouse.Y - viewportSize.Y / 2) / (viewportSize.Y / 2)) * MaxOffset

		Camera.Focus = Camera.CameraSubject.CFrame
		Camera.CFrame = Camera.Focus
			* CFrame.Angles(math.rad(-OffsetY * CameraSensitivity), math.rad(-OffsetX * CameraSensitivity), 0)
	end

	Camera.CFrame = Camera.CFrame + Humanoid.CameraOffset
end

CameraController.OnCharacterAdded = function(character: TCharacter.TCharacter)
	Camera.CameraSubject = character.Head

	Humanoid = character.Humanoid
	HumanoidRootPart = character.HumanoidRootPart

	connection = RunService.PreRender:Connect(updateCamera)
end

CameraController.OnCharacterRemoving = function()
	connection:Disconnect()
end

return Ignis.Register(CameraController)
