local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TimeController = require(script.Parent.Parent.Controllers.TimeController)
local HotbarController = require(script.Parent.Parent.Controllers.HotbarController)
local AbilitiesController = require(script.Parent.Parent.Controllers.AbilitiesController)
local BossLifebarController = require(script.Parent.Parent.Controllers.BossController.BossLifebarController)
local TweensController = require(script.Parent.Parent.Controllers.TweensController)
local ColliderControler = require(script.Parent.Parent.Controllers.ColliderControler)
local UpgradesController = require(script.Parent.Parent.Controllers.UpgradesController)
local FlamesController = require(script.Parent.Parent.Controllers.FlamesController)
local DialogueController = require(script.Parent.Parent.Controllers.DialogueController)
local DoorsController = require(script.Parent.Parent.Controllers.DoorsController)
local HealthController = require(script.Parent.Parent.Controllers.HealthController)
local TorchesController = require(script.Parent.Parent.Controllers.TorchesController)
local TeleportController = require(script.Parent.Parent.Controllers.TeleportController)
local TridentController = require(script.Parent.Parent.Controllers.BossController.TridentController)
local BossSpawnController = require(script.Parent.Parent.Controllers.BossController.BossSpawnController)
local Promise = require(ReplicatedStorage.Shared.Utils.Promise)
local ECharacters = require(ReplicatedStorage.Types.Enums.ECharacters)
local EDialogue = require(ReplicatedStorage.Types.Enums.EDialogue)
local EFlames = require(ReplicatedStorage.Types.Enums.EFlames)
local ELocations = require(ReplicatedStorage.Types.Enums.ELocations)
local EScenes = require(ReplicatedStorage.Types.Enums.EScenes)
local EUpgrades = require(ReplicatedStorage.Types.Enums.EUpgrades)
local TScene = require(ReplicatedStorage.Types.TScene)

type Scene = {
	ShouldRestart: boolean,
	CurrentPromise: Promise.Promise?,
	SelectedUpgrade: number?,
} & TScene.TScene

local Scene_First = {} :: Scene
Scene_First.IsActive = false
Scene_First.ShouldRestart = true
Scene_First.CurrentPromise = nil
Scene_First.SelectedUpgrade = nil

function Scene_First.CharacterDied()
	-- Do not reset the scene if the death was scripted
	return Scene_First.ShouldRestart
end

function Scene_First.Start()
	HealthController.Revive()

	Scene_First.IsActive = true
	Scene_First.ShouldRestart = true
	Scene_First.SelectedUpgrade = nil

	Scene_First.CurrentPromise = Promise.new(function(resolve)
		DoorsController.Open()
		resolve()
	end)
		:andThen(function()
			TweensController.SetImmobile(true)
			DoorsController.Close()
			return Promise.delay(0.75)
		end)
		:andThen(function()
			return TorchesController.LightAllTorchesInSequence(0.5)
		end)
		:andThen(function()
			return DialogueController.Talk({ Id = ECharacters.Hero, Dialogue = EDialogue.First_Hero_0 })
		end)
		:andThen(function()
			return DialogueController.Talk({ Id = ECharacters.DemonKing, Dialogue = EDialogue.First_DemonKing_0 })
		end)
		:andThen(function()
			Scene_First.ShouldRestart = false
			BossSpawnController.ProjectilesAtSceneStart(100)
			return Promise.fromEvent(HealthController.OnDead :: any):andThen(function()
				return Promise.delay(1)
			end)
		end)
		:andThen(function()
			return TeleportController.Teleport(ELocations.SoulRealm):andThen(function()
				return Promise.delay(1)
			end)
		end)
		:andThen(function()
			return DialogueController.Talk({ Id = ECharacters.Hero, Dialogue = EDialogue.First_Hero_1 })
		end)
		:andThen(function()
			return DialogueController.Talk({ Id = ECharacters.Hero, Dialogue = EDialogue.First_Hero_2 })
		end)
		:andThen(function()
			return DialogueController.Talk({ Id = ECharacters.Hero, Dialogue = EDialogue.First_Hero_3 })
		end)
		:andThen(function()
			FlamesController.Appear(EFlames.WhiteFlame)
			return DialogueController.Talk({ Id = ECharacters.God, Dialogue = EDialogue.First_White_0 })
		end)
		:andThen(function()
			return DialogueController.Talk({ Id = ECharacters.God, Dialogue = EDialogue.First_White_1 })
		end)
		:andThen(function()
			return DialogueController.Talk({ Id = ECharacters.God, Dialogue = EDialogue.First_White_2 })
		end)
		:andThen(function()
			return DialogueController.Talk({ Id = ECharacters.God, Dialogue = EDialogue.First_White_3 })
		end)
		:andThen(function()
			return UpgradesController.Show({
				EUpgrades.Dash,
				EUpgrades.Parry,
			}, false)
		end)
		:andThen(function(upgradeId: number)
			Scene_First.SelectedUpgrade = upgradeId
			return DialogueController.Talk({ Id = ECharacters.God, Dialogue = EDialogue.First_White_4 })
		end)
		:andThen(function()
			FlamesController.Dissapear()
			return Promise.delay(1)
		end)
		:andThen(function()
			Scene_First.ShouldRestart = true
			Scene_First.IsActive = false
			Scene_First.SelectedUpgrade = nil

			return EScenes.Second
		end)
		:catch(function(err)
			warn("[Scene_First] Error:", err)
		end)

	return Scene_First.CurrentPromise :: Promise.Promise
end

function Scene_First.Stop()
	Scene_First.IsActive = false
	Scene_First.ShouldRestart = true

	DoorsController.Close(0)
	TorchesController.UnlightAll(0)
	FlamesController.Dissapear()
	TridentController.Reset()
	HotbarController.Disappear()
	AbilitiesController.Disappear()
	BossLifebarController.Disappear()
	TimeController.DisappearTimer()

	if Scene_First.SelectedUpgrade then
		UpgradesController.RemoveUpgrade(Scene_First.SelectedUpgrade)
		Scene_First.SelectedUpgrade = nil
	end

	if Scene_First.CurrentPromise then
		Scene_First.CurrentPromise:cancel()
		Scene_First.CurrentPromise = nil
	end
end

function Scene_First.Restart()
	Scene_First.Stop()

	HealthController.Revive()

	Scene_First.Start()
end

return Scene_First
