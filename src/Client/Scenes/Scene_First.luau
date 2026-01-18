local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local Workspace = game:GetService("Workspace")
local DialogueController = require(StarterPlayer.StarterPlayerScripts.Client.Controllers.DialogueController)
local DoorsController = require(StarterPlayer.StarterPlayerScripts.Client.Controllers.DoorsController)
local HealthController = require(StarterPlayer.StarterPlayerScripts.Client.Controllers.HealthController)
local SceneController = require(script.Parent.Parent.Controllers.SceneController)
local TorchesController = require(StarterPlayer.StarterPlayerScripts.Client.Controllers.TorchesController)
local Ignis = require(ReplicatedStorage.Packages.Ignis)
local Promise = require(ReplicatedStorage.Shared.Utils.Promise)
local ECharacters = require(ReplicatedStorage.Types.Enums.ECharacters)
local EDialogue = require(ReplicatedStorage.Types.Enums.EDialogue)
local EScenes = require(ReplicatedStorage.Types.Enums.EScenes)
local TCharacter = require(ReplicatedStorage.Types.TCharacter)

local Player = Players.LocalPlayer
local EnterCollider = CollectionService:GetTagged("EnterCollider")[1] :: BasePart
local OvParams = OverlapParams.new()
OvParams.FilterType = Enum.RaycastFilterType.Include

local CurrentPromise: Promise.Promise?

local function CheckCollision()
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

local Scene_First = {}
Scene_First.IsActive = false

function Scene_First.OnCharacterAdded(character: TCharacter.TCharacter)
	-- If there is no promise then there is no while loop, then we don't need the params.
	if not CurrentPromise then return end
	OvParams.FilterDescendantsInstances = { character }
end

local function WaitForPlayerEnter()
	return Promise.new(function(resolve, _, onCancel)
		local thread = task.spawn(function()
			while true do
				if CheckCollision() then
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

local function LightTorchesSequence()
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

function Scene_First.Start()
	Scene_First.IsActive = true
	SceneController.CurrentScene = EScenes.First
	SceneController.ResetFunction = Scene_First.Restart

	Scene_First.CurrentPromise = Promise.new(function(resolve)
		DoorsController.Open()

		resolve()
	end)
		:andThen(function()
			local character = Player.Character
			if character then OvParams.FilterDescendantsInstances = { character } end

			return WaitForPlayerEnter()
		end)
		:andThen(function()
			DoorsController.Close()
			return Promise.delay(1)
		end)
		:andThen(function()
			return LightTorchesSequence()
		end)
		:andThen(function()
			return DialogueController.Talk({ Id = ECharacters.Hero, Dialogue = EDialogue.First_Hero_0 })
		end)
		:andThen(function()
			return DialogueController.Talk({ Id = ECharacters.DemonKing, Dialogue = EDialogue.First_DemonKing_0 })
		end)
		:andThen(function()
			-- Throw trident and kill the player
			HealthController.SetHealth(0)
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
			return DialogueController.Talk({ Id = ECharacters.God, Dialogue = EDialogue.First_White_4 })
		end)
		:andThen(function()
			HealthController.Revive()
			SceneController.OnSceneChanged:Fire(EScenes.First, EScenes.Second)
		end)
		:catch(function(err)
			warn("Scene First Interrupted or Failed:", err)
		end)
end

function Scene_First.Stop()
	Scene_First.IsActive = false

	if CurrentPromise then
		CurrentPromise:cancel()
		CurrentPromise = nil
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

SceneController.OnGameStarted:Connect(function()
	Scene_First.Start()
end)

return Ignis.Register(Scene_First)
