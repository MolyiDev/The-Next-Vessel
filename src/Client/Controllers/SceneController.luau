local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Ignis = require(ReplicatedStorage.Packages.Ignis)
local Signal = require(ReplicatedStorage.Packages.Signal)
local EScenes = require(ReplicatedStorage.Types.Enums.EScenes)
local CameraController = require(script.Parent.CameraController)
local HealthController = require(script.Parent.HealthController)
local TweensController = require(script.Parent.TweensController)
local TCharacter = require(ReplicatedStorage.Types.TCharacter)
local TScene = require(ReplicatedStorage.Types.TScene)

local SCENE_MODULES: { [number]: TScene.TScene } = table.freeze({
	[EScenes.First] = require(script.Parent.Parent.Scenes.Scene_First),
	[EScenes.Second] = require(script.Parent.Parent.Scenes.Scene_Second),
})

local Player = Players.LocalPlayer

local ActiveSceneModule: TScene.TScene?
local InputBeganConnection: RBXScriptConnection?

local function startCharacter(character: TCharacter.TCharacter)
	character.Humanoid.AutoRotate = true
	CameraController.HideMouse()
	CameraController.LockCamera()
	TweensController.SetImmobile(false, 0.01)
end

local function getSceneModule(sceneId: number): TScene.TScene
	return SCENE_MODULES[sceneId]
end

local SceneController = {}
SceneController.OnGameStarted = Signal.new()
SceneController.OnSceneChanged = Signal.new() :: Signal.Signal<number, number> -- oldScene, newScene
SceneController.CurrentScene = EScenes.Starting

function SceneController.LoadScene(sceneId: number)
	if ActiveSceneModule and ActiveSceneModule.Stop then ActiveSceneModule.Stop() end

	local oldScene = SceneController.CurrentScene
	SceneController.CurrentScene = sceneId
	ActiveSceneModule = getSceneModule(sceneId)

	SceneController.OnSceneChanged:Fire(oldScene, sceneId)

	if not ActiveSceneModule or not ActiveSceneModule.Start then return end
	local scenePromise = ActiveSceneModule.Start()
	if not scenePromise then return end
	scenePromise:andThen(function(nextSceneId)
		if nextSceneId and type(nextSceneId) == "number" then SceneController.LoadScene(nextSceneId) end
	end)
end

function SceneController.IsGameStarted(): boolean
	return SceneController.CurrentScene > 0
end

function SceneController.Restart()
	if ActiveSceneModule and ActiveSceneModule.Restart then ActiveSceneModule.Restart() end
end

SceneController.OnCharacterAdded = function(character: TCharacter.TCharacter)
	if SceneController.IsGameStarted() then
		startCharacter(character)

		if ActiveSceneModule and ActiveSceneModule.CharacterAdded then ActiveSceneModule.CharacterAdded(character) end
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

		SceneController.LoadScene(EScenes.First)
	end)
end

HealthController.Died:Connect(function()
	if SceneController.CurrentScene <= 0 then return end

	if ActiveSceneModule and ActiveSceneModule.CharacterDied then
		local shouldRestart = ActiveSceneModule.CharacterDied()
		if not shouldRestart then return end
	end

	if ActiveSceneModule and ActiveSceneModule.Restart then ActiveSceneModule.Restart() end
end)

HealthController.Revived:Connect(function()
	local character = Player.Character :: TCharacter.TCharacter
	if not character then return end
	local camera = Workspace.CurrentCamera

	if SceneController.CurrentScene < EScenes.Third then
		local firstSpawn = CollectionService:GetTagged("FirstSpawn")[1] :: Attachment
		if firstSpawn then character.HumanoidRootPart.CFrame = firstSpawn.WorldCFrame end
	else
		local secondSpawn = CollectionService:GetTagged("SecondSpawn")[1] :: Attachment
		if secondSpawn then character.HumanoidRootPart.CFrame = secondSpawn.WorldCFrame end
	end

	camera.CameraSubject = character.Head
	camera.CFrame = character.Head.CFrame
	CameraController.UpdateRotation()

	startCharacter(character)
end)

return Ignis.Register(SceneController)
