local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ColliderControler = require(script.Parent.Parent.Controllers.ColliderControler)
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
local TScene = require(ReplicatedStorage.Types.TScene)

type Scene = {
	ShouldRestart: boolean,
	CurrentPromise: Promise.Promise?,
	SelectedUpgrade: number?,
	FastSpawn: boolean,
	Corruption: number,
} & TScene.TScene

local Scene_Third = {} :: Scene
Scene_Third.IsActive = false
Scene_Third.ShouldRestart = true
Scene_Third.CurrentPromise = nil :: Promise.Promise?
Scene_Third.FastSpawn = false
Scene_Third.SelectedUpgrade = nil
Scene_Third.Corruption = 0

function Scene_Third.CharacterDied()
	return Scene_Third.ShouldRestart
end

function Scene_Third.Start()
	Scene_Third.IsActive = true
	Scene_Third.ShouldRestart = true

	if not Scene_Third.FastSpawn then
		Scene_Third.CurrentPromise = Promise.new(function(resolve, _, _)
			DoorsController.Open()
			resolve()
		end)
			:andThen(function()
				return ColliderControler.WaitForPlayer(ColliderControler.EnterCollider)
			end)
			:andThen(function()
				DoorsController.Close()
				return Promise.delay(1)
			end)
			:andThen(function()
				return TorchesController.LightAllTorchesInSequence(0.5)
			end)
	else
		Scene_Third.CurrentPromise = Promise.new(function(resolve)
			resolve()
		end)
	end

	local heroDialogueStart = EDialogue[`Third_Hero_Start_{Scene_Third.Corruption}`]
	local demonDialogueStart = EDialogue[`Third_DemonKing_Start_{Scene_Third.Corruption}`]
	local demonDialogueFinish = EDialogue[`Third_DemonKing_Finish_{Scene_Third.Corruption}`]
	local whiteDialogueStart = EDialogue[`Third_White_Start_{Scene_Third.Corruption}`]
	local whiteDialogueFinish = EDialogue[`Third_White_Finish_{Scene_Third.Corruption}`];

	(Scene_Third.CurrentPromise :: Promise.Promise)
		:andThen(function()
			return DialogueController.Talk({ Id = ECharacters.Hero, Dialogue = heroDialogueStart })
		end)
		:andThen(function()
			return DialogueController.Talk({ Id = ECharacters.DemonKing, Dialogue = demonDialogueStart })
		end)
		:andThen(function()
			Scene_Third.ShouldRestart = false
			-- Throw trident to the player
			-- Wait until the player is dead because of the battle with the demon king.
			-- Or if the player has winned vs the demonking then just change to the next scene
			-- return EScenes.Fourth
		end)
		:andThen(function()
			-- When the player dies
			return DialogueController.Talk({ Id = ECharacters.DemonKing, Dialogue = demonDialogueFinish })
		end)
		:andThen(function()
			TeleportController.Teleport(ELocations.SoulRealm)
			return Promise.delay(1)
		end)
		:andThen(function()
			FlamesController.Appear(EFlames.WhiteFlame)
			return Promise.delay(0.5)
		end)
		:andThen(function()
			return DialogueController.Talk({ Id = ECharacters.God, Dialogue = whiteDialogueStart })
		end)
		:andThen(function()
			-- Depending on the attacks that killed the player different wishes will appear on death:
			-- If the player died because of an attack that is deflectable and doesnt have the deflect then the wish 'Be able to deflect attacks' will appear
			-- If the player died because of an attack that is not deflectable and doesnt have the dodge then the wish 'Be able to dodge attacks' will appear
			-- If the player died while the boss was 'hardened' and doesnt have the ability to break the 'hardened skin' then the wish 'Be able to break harden' will appear
			-- If the player died because of the boss poison and doesnt have the poison resistance  then the wish 'Be able to withstand poison' will appear
			-- If the player died after failing a parry and doesnt have the ability to block then the wish 'Be able to block' will appear

			return UpgradesController.Show({}, true)
		end)
		:andThen(function(upgradeId: number)
			Scene_Third.SelectedUpgrade = upgradeId
			return DialogueController.Talk({ Id = ECharacters.God, Dialogue = whiteDialogueFinish })
		end)
		:andThen(function()
			FlamesController.Dissapear()
			return Promise.delay(0.5)
		end)
		:andThen(function()
			HealthController.Revive()
			Scene_Third.ShouldRestart = true
			Scene_Third.IsActive = false
			Scene_Third.SelectedUpgrade = nil

			return EScenes.Third
		end)
		:catch(function(err)
			warn(`[Scene_Third] Error: {err}`)
		end)

	return Scene_Third.CurrentPromise :: Promise.Promise
end

function Scene_Third.Stop()
	Scene_Third.IsActive = false

	DoorsController.Close(0)
	TorchesController.UnlightAll(0)
	FlamesController.Dissapear()
	Scene_Third.Corruption = math.min(Scene_Third.Corruption + 1, 5)

	if Scene_Third.SelectedUpgrade then
		UpgradesController.RemoveUpgrade(Scene_Third.SelectedUpgrade)
		Scene_Third.SelectedUpgrade = nil
	end

	if Scene_Third.CurrentPromise then
		Scene_Third.CurrentPromise:cancel()
		Scene_Third.CurrentPromise = nil
	end
end

function Scene_Third.Restart()
	Scene_Third.Stop()

	HealthController.Revive()

	Scene_Third.Start()
end

return Scene_Third
