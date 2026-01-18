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
local TScene = require(ReplicatedStorage.Types.TScene)

local SCENE_MODULES: { [number]: TScene.TScene } = table.freeze({
	[EScenes.First] = require(script.Parent.Parent.Scenes.Scene_First),
	[EScenes.Second] = require(script.Parent.Parent.Scenes.Scene_Second),
})

local Player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local SoulRealmCamera = CollectionService:GetTagged("SoulRealmCamera")[1] :: BasePart

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

function SceneController.Teleport(location: number)
	local character = Player.Character :: TCharacter.TCharacter

	if location == ELocations.SoulRealm then
		if character then character.Humanoid.AutoRotate = false end
		Camera.CameraSubject = SoulRealmCamera
		CameraController.UnlockCamera()
		CameraController.Update()
		TweensController.SetImmobile(false, 0.01)
	elseif character then
		Camera.Focus = character.Head
		startCharacter(character)
		CameraController.Update()
	end
end

function SceneController.LoadScene(sceneId: number)
	if ActiveSceneModule and ActiveSceneModule.Stop then ActiveSceneModule.Stop() end

	local oldScene = SceneController.CurrentScene
	SceneController.CurrentScene = sceneId
	ActiveSceneModule = getSceneModule(sceneId)

	SceneController.OnSceneChanged:Fire(oldScene, sceneId)

	if not ActiveSceneModule or not ActiveSceneModule.Start then return end
	local scenePromise = ActiveSceneModule.Start()
	if not scenePromise then return end
end

function SceneController.IsGameStarted(): boolean
	return SceneController.CurrentScene > 0
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

	SceneController.Teleport(ELocations.SoulRealm)

	if ActiveSceneModule and ActiveSceneModule.CharacterDied then
		local handled = ActiveSceneModule.CharacterDied()
		if handled then return end
	end

	if ActiveSceneModule and ActiveSceneModule.Restart then ActiveSceneModule.Restart() end
end)

HealthController.Revived:Connect(function()
	local character = Player.Character :: TCharacter.TCharacter
	if not character then return end
	local camera = Workspace.CurrentCamera
	character.HumanoidRootPart.CFrame = CFrame.new(-5, 3, 0) * CFrame.Angles(0, math.rad(-90), 0)

	camera.CameraSubject = character.Head
	camera.CFrame = character.Head.CFrame
	CameraController.UpdateRotation()

	startCharacter(character)
end)

return Ignis.Register(SceneController)
