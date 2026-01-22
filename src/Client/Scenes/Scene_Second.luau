local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BossProjectilesController = require(script.Parent.Parent.Controllers.BossController.BossProjectilesController)
local TimeController = require(script.Parent.Parent.Controllers.TimeController)
local TweensController = require(script.Parent.Parent.Controllers.TweensController)
local FlamesController = require(script.Parent.Parent.Controllers.FlamesController)
local HealthController = require(script.Parent.Parent.Controllers.HealthController)
local TeleportController = require(script.Parent.Parent.Controllers.TeleportController)
local UpgradesController = require(script.Parent.Parent.Controllers.UpgradesController)
local DoorsController = require(script.Parent.Parent.Controllers.DoorsController)
local TorchesController = require(script.Parent.Parent.Controllers.TorchesController)
local DialogueController = require(script.Parent.Parent.Controllers.DialogueController)
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

local Scene_Second = {} :: Scene
Scene_Second.IsActive = false
Scene_Second.ShouldRestart = true
Scene_Second.CurrentPromise = nil :: Promise.Promise?
Scene_Second.SelectedUpgrade = nil

function Scene_Second.CharacterDied()
	return Scene_Second.ShouldRestart
end

function Scene_Second.Start()
	Scene_Second.IsActive = true
	Scene_Second.ShouldRestart = true

	Scene_Second.CurrentPromise = Promise.new(function(resolve, _, _)
		TorchesController.LightAll()
		TweensController.SetImmobile(true)
		DoorsController.PlayCloseSound()
		resolve()
	end)
		:andThen(function()
			return Promise.delay(0.5)
		end)
		:andThen(function()
			return DialogueController.Talk({ Id = ECharacters.Hero, Dialogue = EDialogue.Second_Hero_0 })
		end)
		:andThen(function()
			return DialogueController.Talk({ Id = ECharacters.DemonKing, Dialogue = EDialogue.Second_DemonKing_0 })
		end)
		:andThen(function()
			Scene_Second.ShouldRestart = false
			BossProjectilesController.ShootFirst()

			return Promise.delay(0.2):andThen(function()
				-- Slow down time and wait for the player to react
				TimeController.Slow(0.2, 1)

				if UpgradesController.HasUpgrade(EUpgrades.Dash) then
					-- If the player has a dash, show the key 'Q' in screen and say to the player that they can dash.
					-- Wait for the player to dash
				elseif UpgradesController.HasUpgrade(EUpgrades.Parry) then
					-- If the player has a parry, show the key 'Right click' in the screen and say to the player that they can parry
					-- Wait for the player to parry
				end
			end)
		end)
		:andThen(function()
			TimeController.Resume(1)
			-- If the player reacted to the quick action
			if not HealthController.IsDead() then
				return DialogueController.Talk({ Id = ECharacters.DemonKing, Dialogue = EDialogue.Second_DemonKing_1 })
			end

			-- If the player didn't react to the quick action.
			return DialogueController.Talk({ Id = ECharacters.DemonKing, Dialogue = EDialogue.Second_DemonKing_2 })
				:andThen(function()
					TeleportController.Teleport(ELocations.SoulRealm)
					return Promise.delay(1)
				end)
				:andThen(function()
					FlamesController.Appear(EFlames.WhiteFlame)
					return Promise.delay(0.5)
				end)
				:andThen(function()
					return DialogueController.Talk({ Id = ECharacters.God, Dialogue = EDialogue.White_EarlyDeath })
				end)
				:andThen(function()
					FlamesController.Dissapear()
					return Promise.delay(0.5)
				end)
				:andThen(function()
					Scene_Second.Restart()
				end)
		end)
		:andThen(function()
			-- Wait until the player dies in the battle vs the demon king
		end)
		:andThen(function()
			-- When the player dies:
			TeleportController.Teleport(ELocations.SoulRealm)
			return Promise.delay(1)
		end)
		:andThen(function()
			FlamesController.Appear(EFlames.WhiteFlame)
			return Promise.delay(0.5)
		end)
		:andThen(function()
			return DialogueController.Talk({ Id = ECharacters.God, Dialogue = EDialogue.Second_White_0 })
		end)
		:andThen(function()
			return UpgradesController.Show({ EUpgrades.Dash }, true)
		end)
		:andThen(function(upgradeId: number)
			Scene_Second.SelectedUpgrade = upgradeId
			return DialogueController.Talk({ Id = ECharacters.God, Dialogue = EDialogue.Second_White_1 })
		end)
		:andThen(function()
			FlamesController.Dissapear()
			return Promise.delay(0.5)
		end)
		:andThen(function()
			HealthController.Revive()
			Scene_Second.ShouldRestart = true
			Scene_Second.IsActive = false
			Scene_Second.SelectedUpgrade = nil

			return EScenes.Third
		end)
		:catch(function(err)
			warn(`[Scene_Second] Error: {err}`)
		end)

	return Scene_Second.CurrentPromise :: Promise.Promise
end

function Scene_Second.Stop()
	Scene_Second.IsActive = false

	DoorsController.Close(0)
	TorchesController.UnlightAll(0)
	FlamesController.Dissapear()

	if Scene_Second.SelectedUpgrade then
		UpgradesController.RemoveUpgrade(Scene_Second.SelectedUpgrade)
		Scene_Second.SelectedUpgrade = nil
	end

	if Scene_Second.CurrentPromise then
		Scene_Second.CurrentPromise:cancel()
		Scene_Second.CurrentPromise = nil
	end
end

function Scene_Second.Restart()
	Scene_Second.Stop()

	HealthController.Revive()

	Scene_Second.Start()
end

return Scene_Second
