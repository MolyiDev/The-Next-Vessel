local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local TargetController = require(StarterPlayer.StarterPlayerScripts.Client.Controllers.TargetController)
local Signal = require(ReplicatedStorage.Packages.Signal)
local TimeController = require(script.Parent.Parent.Controllers.TimeController)
local AbilitiesController = require(script.Parent.Parent.Controllers.AbilitiesController)
local EnemiesController = require(script.Parent.Parent.Controllers.EnemiesController)
local HotbarController = require(script.Parent.Parent.Controllers.HotbarController)
local BossSpawnController = require(script.Parent.Parent.Controllers.BossController.BossSpawnController)
local BossLifebarController = require(script.Parent.Parent.Controllers.BossController.BossLifebarController)
local BossController = require(script.Parent.Parent.Controllers.BossController)
local TweensController = require(script.Parent.Parent.Controllers.TweensController)
local FlamesController = require(script.Parent.Parent.Controllers.FlamesController)
local HealthController = require(script.Parent.Parent.Controllers.HealthController)
local TeleportController = require(script.Parent.Parent.Controllers.TeleportController)
local UpgradesController = require(script.Parent.Parent.Controllers.UpgradesController)
local DoorsController = require(script.Parent.Parent.Controllers.DoorsController)
local TorchesController = require(script.Parent.Parent.Controllers.TorchesController)
local DialogueController = require(script.Parent.Parent.Controllers.DialogueController)
local ProjectileController = require(script.Parent.Parent.Controllers.ProjectileController)
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

local SpawnLowPos = (CollectionService:GetTagged("ProjectilesSpawnLow")[1] :: BasePart).Position
local SpawnHighPos = (CollectionService:GetTagged("ProjectilesSpawnHigh")[1] :: BasePart).Position

local Scene_Second = {} :: Scene
Scene_Second.IsActive = false
Scene_Second.ShouldRestart = true
Scene_Second.CurrentPromise = nil :: Promise.Promise?
Scene_Second.SelectedUpgrade = nil
Scene_Second.Corruption = 0

function Scene_Second.CharacterDied()
	return Scene_Second.ShouldRestart
end

function Scene_Second.Start()
	HealthController.Revive()
	HotbarController.Appear()
	AbilitiesController.Appear()
	BossLifebarController.Appear()
	TargetController.Appear()
	TimeController.AppearTimer()

	Scene_Second.IsActive = true
	Scene_Second.ShouldRestart = true

	local heroDialogueStart = EDialogue[`Second_Hero_Start_{Scene_Second.Corruption}`]
	local demonDialogueStart = EDialogue[`Second_DemonKing_Start_{Scene_Second.Corruption}`]
	local demonDialogueFinish = EDialogue[`Second_DemonKing_Finish_{Scene_Second.Corruption}`]
	local whiteDialogueStart = EDialogue[`Second_White_Start_{Scene_Second.Corruption}`]
	local whiteDialogueFinish = EDialogue[`Second_White_Finish_{Scene_Second.Corruption}`]

	Scene_Second.CurrentPromise = Promise.new(function(resolve, _, _)
		TorchesController.LightAll(true)
		TweensController.SetImmobile(true)
		DoorsController.PlayCloseSound()
		resolve()
	end)
		:andThen(function()
			return Promise.delay(0.5)
		end)
		:andThen(function()
			return DialogueController.Talk({ Id = ECharacters.Hero, Dialogue = heroDialogueStart })
		end)
		:andThen(function()
			return DialogueController.Talk({ Id = ECharacters.DemonKing, Dialogue = demonDialogueStart })
		end)
		:andThen(function()
			return Promise.reject(EScenes.Third)
		end)
		:andThen(function()
			Scene_Second.ShouldRestart = false

			TimeController.PlayTimer()
			TweensController.SetImmobile(false)
			BossSpawnController.ProjectilesAtSceneStart(100)

			return Promise.new(function(resolve, _, onCancel)
				local bossDeadConnection: Signal.Connection?
				local characterDeadConnection: Signal.Connection?
				local thread: thread?

				local function disconnect()
					if bossDeadConnection then
						bossDeadConnection:Disconnect()
						bossDeadConnection = nil
					end

					if characterDeadConnection then
						characterDeadConnection:Disconnect()
						characterDeadConnection = nil
					end

					if thread then task.cancel(thread) end
				end

				thread = task.spawn(function()
					local directionCount = 20
					local angleStep = (math.pi * 2) / directionCount
					local angleOffset = angleStep / 2

					while true do
						task.wait(1)

						for i = 1, directionCount do
							local currentAngle = angleStep * i
							local direction = Vector3.new(math.cos(currentAngle), 0, math.sin(currentAngle))

							ProjectileController.AddProjectile(
								SpawnLowPos,
								((SpawnLowPos + direction) - SpawnLowPos).Unit,
								90,
								2.5,
								ProjectileController.ESender.Enemy,
								5,
								math.random(2, 6)
							)
						end

						task.wait(1)

						for i = 1, directionCount do
							local currentAngle = angleStep * i + angleOffset
							local direction = Vector3.new(math.cos(currentAngle), 0, math.sin(currentAngle))

							ProjectileController.AddProjectile(
								SpawnLowPos,
								((SpawnLowPos + direction) - SpawnLowPos).Unit,
								90,
								2.5,
								ProjectileController.ESender.Enemy,
								5,
								math.random(2, 6)
							)
						end

						task.wait(1)

						BossSpawnController.ProjectilesAtSceneThird(5, 0.8)
					end
				end)

				-- Wait until the player is dead because of the battle with the demon king.
				characterDeadConnection = HealthController.OnDead:Connect(function()
					disconnect()
					resolve("Character")
				end)

				-- Or if the player has winned vs the demonking then just change to the next scene
				bossDeadConnection = BossController.OnDead:Connect(function()
					disconnect()
					resolve("Boss")
				end)

				onCancel(disconnect)
			end)
		end)
		:andThen(function(dead: string)
			if dead == "Character" then
				--  The player dies
				return DialogueController.Talk({ Id = ECharacters.DemonKing, Dialogue = demonDialogueFinish })
			else
				--  The boss dies
				return Promise.reject(EScenes.Third)
			end
		end)
		:andThen(function()
			BossLifebarController.Disappear()
			HotbarController.Disappear()
			AbilitiesController.Disappear()
			TimeController.DisappearTimer()

			return TeleportController.Teleport(ELocations.SoulRealm):andThen(function()
				ProjectileController.Cleanup()
				EnemiesController.Cleanup()

				return Promise.delay(0.5)
			end)
		end)
		:andThen(function()
			FlamesController.Appear(EFlames.WhiteFlame)
			return Promise.delay(0.5)
		end)
		:andThen(function()
			return DialogueController.Talk({ Id = ECharacters.God, Dialogue = whiteDialogueStart })
		end)
		:andThen(function()
			local upgrades = {}

			return UpgradesController.Show(upgrades, true)
		end)
		:andThen(function(upgradeId: number)
			Scene_Second.SelectedUpgrade = upgradeId
			return DialogueController.Talk({ Id = ECharacters.God, Dialogue = whiteDialogueFinish })
		end)
		:andThen(function()
			FlamesController.Dissapear()
			return Promise.delay(0.5)
		end)
		:andThen(function()
			return EScenes.Second
		end)
		:catch(function(err)
			if err == EScenes.Third then return err end

			warn(`[Scene_Second] Error: {err}`)
		end)

	return Scene_Second.CurrentPromise :: Promise.Promise
end

function Scene_Second.Stop()
	Scene_Second.IsActive = false
	Scene_Second.ShouldRestart = true
	Scene_Second.SelectedUpgrade = nil

	DoorsController.Close(0)
	TorchesController.UnlightAll(0)
	FlamesController.Dissapear()
	HotbarController.Disappear()
	BossLifebarController.Disappear()
	AbilitiesController.Disappear()
	TimeController.DisappearTimer()
	TargetController.Disappear()
	Scene_Second.Corruption = math.min(Scene_Second.Corruption + 1, 5)

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
