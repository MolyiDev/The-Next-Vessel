local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Ignis = require(ReplicatedStorage.Packages.Ignis)
local Signal = require(ReplicatedStorage.Packages.Signal)
local ELocations = require(ReplicatedStorage.Types.Enums.ELocations)
local EScenes = require(ReplicatedStorage.Types.Enums.EScenes)
local CameraController = require(script.Parent.CameraController)
local HealthController = require(script.Parent.HealthController)
local TweensController = require(script.Parent.TweensController)
local TCharacter = require(ReplicatedStorage.Types.TCharacter)

local Player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local InputBeganConnection: RBXScriptConnection?
local SoulRealmPart = CollectionService:GetTagged("SoulRealmPart")[1] :: BasePart

local function startCharacter(character: TCharacter.TCharacter)
	character.Humanoid.AutoRotate = true
	CameraController.HideMouse()
	CameraController.LockCamera()
	TweensController.SetImmobile(false, 0.01)
end

local SceneController = {}
SceneController.OnGameStarted = Signal.new()
SceneController.OnSceneChanged = Signal.new() :: Signal.Signal<number, number> -- oldScene, newScene
SceneController.CurrentScene = EScenes.Starting
SceneController.ResetFunction = nil :: (() -> ())?

function SceneController.Teleport(location: number)
	local character = Player.Character :: TCharacter.TCharacter

	if location == ELocations.SoulRealm then
		if character then character.Humanoid.AutoRotate = false end
		Camera.Focus = SoulRealmPart
		CameraController.UnlockCamera()
		CameraController.Update()
		TweensController.SetImmobile(false, 0.01)
	elseif character then
		Camera.Focus = character.Head
		startCharacter(character)
		CameraController.Update()
	end
end

function SceneController.IsGameStarted(): boolean
	return SceneController.CurrentScene > 0
end

SceneController.OnCharacterAdded = function(character: TCharacter.TCharacter)
	-- Game has already started
	if SceneController.IsGameStarted then
		startCharacter(character)
		return
	end

	if InputBeganConnection then
		InputBeganConnection:Disconnect()
		InputBeganConnection = nil
	end

	-- The game has not started.
	character.Humanoid.AutoRotate = false
	TweensController.SetImmobile(true, 0.01)

	InputBeganConnection = UserInputService.InputBegan:Connect(function(input, gp)
		if gp or input.KeyCode ~= Enum.KeyCode.F then return end

		if InputBeganConnection then
			InputBeganConnection:Disconnect()
			InputBeganConnection = nil
		end

		startCharacter(character)

		SceneController.OnGameStarted:Fire()

		SceneController.OnSceneChanged:Fire(SceneController.CurrentScene, EScenes.First)
		SceneController.CurrentScene = EScenes.First
	end)
end

HealthController.Died:Connect(function()
	if SceneController.CurrentScene <= 0 or not SceneController.ResetFunction then return end
	SceneController.ResetFunction()
	SceneController.Teleport(ELocations.SoulRealm)
end)

HealthController.Revived:Connect(function()
	local character = Player.Character
	if not character then return end
	local head = character:FindFirstChild("Head")
	if not head then return end
end)

return Ignis.Register(SceneController)
