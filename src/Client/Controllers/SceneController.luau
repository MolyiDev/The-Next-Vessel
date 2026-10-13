local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local BossController = require(script.Parent.BossController)
local Ignis = require(ReplicatedStorage.Packages.Ignis)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Promise = require(ReplicatedStorage.Shared.Utils.Promise)
local ELocations = require(ReplicatedStorage.Types.Enums.ELocations)
local EScenes = require(ReplicatedStorage.Types.Enums.EScenes)
local EUpgrades = require(ReplicatedStorage.Types.Enums.EUpgrades)
local CameraController = require(script.Parent.CameraController)
local DoorsController = require(script.Parent.DoorsController)
local EnemiesController = require(script.Parent.EnemiesController)
local HealthController = require(script.Parent.HealthController)
local MouseController = require(script.Parent.MouseController)
local ProjectileController = require(script.Parent.ProjectileController)
local TeleportController = require(script.Parent.TeleportController)
local TimeController = require(script.Parent.TimeController)
local TweensController = require(script.Parent.TweensController)
local UpgradesController = require(script.Parent.UpgradesController)
local TCharacter = require(ReplicatedStorage.Types.TCharacter)
local TScene = require(ReplicatedStorage.Types.TScene)

local SCENE_MODULES: { [number]: TScene.TScene } = table.freeze({
	[EScenes.First] = require(script.Parent.Parent.Scenes.Scene_First),
	[EScenes.Second] = require(script.Parent.Parent.Scenes.Scene_Second),
	[EScenes.Third] = require(script.Parent.Parent.Scenes.Scene_Third),
})

local Player = Players.LocalPlayer

local ActiveSceneModule: TScene.TScene?
local InputBeganConnection: RBXScriptConnection?

local function startCharacter(character: TCharacter.TCharacter)
	MouseController.HideMouse()
	CameraController.AutoRotate = true
	CameraController.DisableCinematicCamera()
	TweensController.SetImmobile(false)
end

local function resetGlobalState()
	TimeController.Resume(0)
	ProjectileController.Cleanup()
	EnemiesController.Cleanup()
	BossController.Reset()
	TweensController.SetImmobile(false)
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

	resetGlobalState()

	local oldScene = SceneController.CurrentScene
	SceneController.CurrentScene = sceneId
	ActiveSceneModule = getSceneModule(sceneId)

	SceneController.OnSceneChanged:Fire(oldScene, sceneId)

	if not ActiveSceneModule or not ActiveSceneModule.Start then return end
	ActiveSceneModule.Start():andThen(function(nextSceneId: number)
		if nextSceneId and type(nextSceneId) == "number" then SceneController.LoadScene(nextSceneId) end
	end)
end

function SceneController.IsGameStarted(): boolean
	return SceneController.CurrentScene > 0
end

function SceneController.Restart()
	resetGlobalState()
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
	local cameraSpawn = CollectionService:GetTagged("CameraSpawn")[1] :: BasePart
	CameraController.EnableCinematicCamera()
	Workspace.CurrentCamera.CameraSubject = cameraSpawn
	TweensController.SetImmobile(true)

	InputBeganConnection = UserInputService.InputBegan:Connect(function(input, gp)
		if gp or input.KeyCode ~= Enum.KeyCode.F then return end

		if InputBeganConnection then
			InputBeganConnection:Disconnect()
			InputBeganConnection = nil
		end

		Promise.new(function(resolve)
			SceneController.OnGameStarted:Fire()
			DoorsController.Open()

			CameraController.FlyTowardsCharacter(character):andThen(function()
				resolve()
			end)
		end)
			:andThen(function()
				return Promise.delay(0.5)
			end)
			:andThen(function()
				startCharacter(character)

				-- Test
				-- UpgradesController.AddUpgrade(EUpgrades.Dash)
				-- UpgradesController.AddUpgrade(EUpgrades.Parry)
				-- UpgradesController.AddUpgrade(EUpgrades.TargetGod)
				-- SceneController.LoadScene(EScenes.Second)

				-- Normal
				UpgradesController.AddUpgrade(EUpgrades.TargetGod)
				UpgradesController.AddUpgrade(EUpgrades.Parry)
				UpgradesController.AddUpgrade(EUpgrades.Dash)
				UpgradesController.AddUpgrade(EUpgrades.DashGod)
				SceneController.LoadScene(EScenes.Second)
			end)
	end)
end

HealthController.OnDead:Connect(function()
	if SceneController.CurrentScene <= 0 then return end

	if ActiveSceneModule and ActiveSceneModule.CharacterDied then
		local shouldRestart = ActiveSceneModule.CharacterDied()
		if not shouldRestart then return end
	end

	if ActiveSceneModule and ActiveSceneModule.Restart then ActiveSceneModule.Restart() end
end)

HealthController.OnRevived:Connect(function()
	local character = Player.Character :: TCharacter.TCharacter
	if not character then return end

	local spawn = CollectionService:GetTagged("Spawn")[1] :: Attachment
	if spawn then character.HumanoidRootPart.CFrame = spawn.WorldCFrame end

	TeleportController.Teleport(ELocations.Dungeon)
end)

return Ignis.Register(SceneController)
