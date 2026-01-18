local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local FlamesController = require(script.Parent.Parent.Controllers.FlamesController)
local DialogueController = require(script.Parent.Parent.Controllers.DialogueController)
local DoorsController = require(script.Parent.Parent.Controllers.DoorsController)
local HealthController = require(script.Parent.Parent.Controllers.HealthController)
local TorchesController = require(script.Parent.Parent.Controllers.TorchesController)
local Promise = require(ReplicatedStorage.Shared.Utils.Promise)
local ECharacters = require(ReplicatedStorage.Types.Enums.ECharacters)
local EDialogue = require(ReplicatedStorage.Types.Enums.EDialogue)
local EFlames = require(ReplicatedStorage.Types.Enums.EFlames)
local EScenes = require(ReplicatedStorage.Types.Enums.EScenes)
local TCharacter = require(ReplicatedStorage.Types.TCharacter)
local TScene = require(ReplicatedStorage.Types.TScene)

local Player = Players.LocalPlayer
local EnterCollider = CollectionService:GetTagged("EnterCollider")[1] :: BasePart
local OvParams = OverlapParams.new()
OvParams.FilterType = Enum.RaycastFilterType.Include

local function checkCollision()
	local parts = Workspace:GetPartsInPart(EnterCollider, OvParams)

	for _, part in parts do
		-- If is not the player then continue
		local parent = part.Parent
		if not parent or not parent:HasTag("Player") then continue end

		-- If the player is dead then continue
		local humanoid = parent:FindFirstChild("Humanoid") :: Humanoid
		if not humanoid or humanoid.Health <= 0 then continue end

		-- Player found
		return true
	end

	return false
end

local function waitForPlayerEnter()
	return Promise.new(function(resolve, _, onCancel)
		local thread = task.spawn(function()
			while true do
				if checkCollision() then
					resolve()
					break
				end
				task.wait()
			end
		end)

		onCancel(function()
			task.cancel(thread)
		end)
	end)
end

local function lightTorchesSequence()
	return Promise.new(function(resolve, _, onCancel)
		local thread = task.spawn(function()
			for i = 1, TorchesController.ROWS do
				TorchesController.Light(i)
				task.wait(0.5)
			end
			resolve()
		end)

		onCancel(function()
			task.cancel(thread)
		end)
	end)
end

local Scene_First = {}
Scene_First.IsActive = false
Scene_First.ScriptedDeathActive = false
Scene_First.CurrentPromise = nil :: Promise.Promise?

function Scene_First.CharacterAdded(character: TCharacter.TCharacter)
	-- If there is no promise then there is no while loop, then we don't need the params.
	if not Scene_First.CurrentPromise or not Scene_First.IsActive then return end
	OvParams.FilterDescendantsInstances = { character }
end

function Scene_First.CharacterDied()
	-- Do not reset the scene if the death was scripted
	return Scene_First.ScriptedDeathActive
end

function Scene_First.Start()
	Scene_First.IsActive = true
	Scene_First.ScriptedDeathActive = false

	Scene_First.CurrentPromise = Promise.new(function(resolve)
		DoorsController.Open()
		resolve()
	end)
		:andThen(function()
			local character = Player.Character
			if character then OvParams.FilterDescendantsInstances = { character } end
			return waitForPlayerEnter()
		end)
		:andThen(function()
			DoorsController.Close()
			return Promise.delay(1)
		end)
		:andThen(function()
			return lightTorchesSequence()
		end)
		:andThen(function()
			return DialogueController.Talk({ Id = ECharacters.Hero, Dialogue = EDialogue.First_Hero_0 })
		end)
		:andThen(function()
			return DialogueController.Talk({ Id = ECharacters.DemonKing, Dialogue = EDialogue.First_DemonKing_0 })
		end)
		:andThen(function()
			-- Throw trident and kill the player
			Scene_First.ScriptedDeathActive = true
			HealthController.SetHealth(0)

			return Promise.delay(2)
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
			-- pick a wish
		end)
		:andThen(function()
			FlamesController.Dissapear()
			return DialogueController.Talk({ Id = ECharacters.God, Dialogue = EDialogue.First_White_4 })
		end)
		:andThen(function()
			HealthController.Revive()
			Scene_First.ScriptedDeathActive = false
			Scene_First.IsActive = false

			-- Go to the next scene
			return EScenes.Second
		end)
		:catch(function(err)
			warn("[Scene_First] Error:", err)
		end)

	return Scene_First.CurrentPromise
end

function Scene_First.Stop()
	Scene_First.IsActive = false
	Scene_First.ScriptedDeathActive = false

	if Scene_First.CurrentPromise then
		Scene_First.CurrentPromise:cancel()
		Scene_First.CurrentPromise = nil
	end
end

function Scene_First.Restart()
	Scene_First.Stop()

	DoorsController.Close()
	for i = 1, TorchesController.ROWS do
		TorchesController.Unlight(i)
	end

	Scene_First.Start()
end

return Scene_First :: TScene.TScene
