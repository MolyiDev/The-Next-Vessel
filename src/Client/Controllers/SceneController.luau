local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Ignis = require(ReplicatedStorage.Packages.Ignis)
local Signal = require(ReplicatedStorage.Packages.Signal)
local EScenes = require(ReplicatedStorage.Types.Enums.EScenes)
local CameraController = require(script.Parent.CameraController)
local TCharacter = require(ReplicatedStorage.Types.TCharacter)

local InputBeganConnection: RBXScriptConnection?

local function startCharacter(character: TCharacter.TCharacter)
	CameraController.HideMouse()
	CameraController.LockCamera()
	character.Humanoid.AutoRotate = true
end

local SceneController = {}
SceneController.CurrentScene = EScenes.Starting
SceneController.IsGameStarted = false
SceneController.OnGameStarted = Signal.new()
SceneController.OnSceneChanged = Signal.new() :: Signal.Signal<number, number> -- oldScene, newScene

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

	InputBeganConnection = UserInputService.InputBegan:Connect(function(input, gp)
		if gp or input.KeyCode ~= Enum.KeyCode.F then return end

		if InputBeganConnection then
			InputBeganConnection:Disconnect()
			InputBeganConnection = nil
		end

		startCharacter(character)

		SceneController.OnGameStarted:Fire()
		SceneController.IsGameStarted = true

		SceneController.OnSceneChanged:Fire(SceneController.CurrentScene, EScenes.First)
		SceneController.CurrentScene = EScenes.First
	end)
end

return Ignis.Register(SceneController)
