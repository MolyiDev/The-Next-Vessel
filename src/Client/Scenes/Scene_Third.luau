local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local HotbarController = require(StarterPlayer.StarterPlayerScripts.Client.Controllers.HotbarController)
local Signal = require(ReplicatedStorage.Packages.Signal)
local BossSpawnController = require(script.Parent.Parent.Controllers.BossController.BossSpawnController)
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

local Scene_Third = {} :: Scene
Scene_Third.IsActive = false
Scene_Third.ShouldRestart = true
Scene_Third.CurrentPromise = nil :: Promise.Promise?
Scene_Third.SelectedUpgrade = nil
Scene_Third.Corruption = 0

function Scene_Third.CharacterDied()
	return Scene_Third.ShouldRestart
end

function Scene_Third.Start()
	HealthController.Revive()
	HotbarController.Appear()

	Scene_Third.IsActive = true
	Scene_Third.ShouldRestart = true

	local heroDialogueStart = EDialogue[`Third_Hero_Start_{Scene_Third.Corruption}`]
	local demonDialogueStart = EDialogue[`Third_DemonKing_Start_{Scene_Third.Corruption}`]
	local demonDialogueFinish = EDialogue[`Third_DemonKing_Finish_{Scene_Third.Corruption}`]
	local whiteDialogueStart = EDialogue[`Third_White_Start_{Scene_Third.Corruption}`]
	local whiteDialogueFinish = EDialogue[`Third_White_Finish_{Scene_Third.Corruption}`]

	Scene_Third.CurrentPromise = Promise.new(function(resolve, _, _)
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
			Scene_Third.ShouldRestart = false

			TweensController.SetImmobile(false)
			BossSpawnController.ProjectilesAtSceneStart(20)

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
					-- Configuration
					local DirectionCount = 16
					local AngleStep = (math.pi * 2) / DirectionCount

					while true do
						task.wait(1)

						-- Loop through the count to calculate each angle
						for I = 1, DirectionCount do
							local CurrentAngle = AngleStep * I

							-- Convert angle to a direction vector (X, Z plane)
							local Direction = Vector3.new(math.cos(CurrentAngle), 0, math.sin(CurrentAngle))

							ProjectileController.AddProjectile(
								SpawnLowPos,
								SpawnLowPos + Direction,
								80,
								2.5,
								5,
								math.random(0, 6)
							)
						end

						task.wait(1)

						local Character = Players.LocalPlayer.Character
						if not Character then continue end

						-- Keeping your original homing shot logic if intended
						if Character and Character.PrimaryPart then BossSpawnController.EnemiesRadial(10, 1) end
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
				return EScenes.Fourth
			end
		end)
		:andThen(function()
			ProjectileController.Cleanup()
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
			return EScenes.Third
		end)
		:catch(function(err)
			warn(`[Scene_Third] Error: {err}`)
		end)

	return Scene_Third.CurrentPromise :: Promise.Promise
end

function Scene_Third.Stop()
	Scene_Third.IsActive = false
	Scene_Third.ShouldRestart = true
	Scene_Third.SelectedUpgrade = nil

	DoorsController.Close(0)
	TorchesController.UnlightAll(0)
	FlamesController.Dissapear()
	HotbarController.Disappear()
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
