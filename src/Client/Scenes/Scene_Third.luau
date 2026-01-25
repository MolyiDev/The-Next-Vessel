local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local BossRagdollController = require(script.Parent.Parent.Controllers.BossController.BossRagdollController)
local BlackoutController = require(script.Parent.Parent.Controllers.BlackoutController)
local CameraController = require(script.Parent.Parent.Controllers.CameraController)
local BossController = require(script.Parent.Parent.Controllers.BossController)
local BossSpawnController = require(script.Parent.Parent.Controllers.BossController.BossSpawnController)
local HealthController = require(script.Parent.Parent.Controllers.HealthController)
local TweensController = require(script.Parent.Parent.Controllers.TweensController)
local DialogueController = require(script.Parent.Parent.Controllers.DialogueController)
local FlamesController = require(script.Parent.Parent.Controllers.FlamesController)
local TeleportController = require(script.Parent.Parent.Controllers.TeleportController)
local TorchesController = require(script.Parent.Parent.Controllers.TorchesController)
local SoundsController = require(script.Parent.Parent.Controllers.SoundsController)
local ProjectileController = require(script.Parent.Parent.Controllers.ProjectileController)
local Promise = require(ReplicatedStorage.Shared.Utils.Promise)
local ECharacters = require(ReplicatedStorage.Types.Enums.ECharacters)
local EDialogue = require(ReplicatedStorage.Types.Enums.EDialogue)
local EFlames = require(ReplicatedStorage.Types.Enums.EFlames)
local ELocations = require(ReplicatedStorage.Types.Enums.ELocations)
local ESounds = require(ReplicatedStorage.Types.Enums.ESounds)
local TCharacter = require(ReplicatedStorage.Types.TCharacter)
local TScene = require(ReplicatedStorage.Types.TScene)

local Player = Players.LocalPlayer

type Scene = {
	ShouldRestart: boolean,
	CurrentPromise: Promise.Promise?,
	Whispers: Sound?,
	SelectedUpgrade: number?,
	FastSpawn: boolean,
	Corruption: number,
} & TScene.TScene

local TWEEN_INFO = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

local WhiteFlame = ReplicatedStorage:WaitForChild("Effects"):WaitForChild("WhiteFlame") :: Attachment

local Scene_Third = {} :: Scene
Scene_Third.IsActive = false
Scene_Third.ShouldRestart = true
Scene_Third.CurrentPromise = nil :: Promise.Promise?
Scene_Third.Whispers = nil :: Sound?
Scene_Third.Corruption = 0

function Scene_Third.Start()
	HealthController.Revive()
	BossController.ParryEnabled = false

	Scene_Third.IsActive = true
	Scene_Third.ShouldRestart = true

	Scene_Third.CurrentPromise = Promise.new(function(resolve)
		TorchesController.LightAll(true)
		TweensController.SetImmobile(true)
		resolve()
	end)
		:andThen(function()
			return Promise.delay(2)
		end)
		:andThen(function()
			return DialogueController.Talk({ Id = ECharacters.DemonKing, Dialogue = EDialogue.Third_DemonKing_0 })
		end)
		:andThen(function()
			BossController.SetHealth(BossController.GetMaxHealth())
			return DialogueController.Talk({ Id = ECharacters.DemonKing, Dialogue = EDialogue.Third_DemonKing_1 })
		end)
		:andThen(function()
			return DialogueController.Talk({ Id = ECharacters.DemonKing, Dialogue = EDialogue.Third_DemonKing_2 })
		end)
		:andThen(function()
			return DialogueController.Talk({ Id = ECharacters.DemonKing, Dialogue = EDialogue.Third_DemonKing_3 })
		end)
		:andThen(function()
			return DialogueController.Talk({ Id = ECharacters.DemonKing, Dialogue = EDialogue.Third_DemonKing_4 })
		end)
		:andThen(function()
			Scene_Third.ShouldRestart = false
			return ProjectileController.ChargeProjectile(ProjectileController.ESender.Enemy, 4.5, 0.01, 18, 60, 1000)
				:andThen(function()
					return Promise.delay(3)
				end)
		end)
		:andThen(function()
			return TeleportController.Teleport(ELocations.SoulRealm):andThen(function()
				return Promise.delay(1)
			end)
		end)
		:andThen(function()
			return DialogueController.Talk({ Id = ECharacters.Hero, Dialogue = EDialogue.Third_Hero_0 })
		end)
		:andThen(function()
			return DialogueController.Talk({ Id = ECharacters.Hero, Dialogue = EDialogue.Third_Hero_1 })
		end)
		:andThen(function()
			return DialogueController.Talk({ Id = ECharacters.Hero, Dialogue = EDialogue.Third_Hero_2 })
		end)
		:andThen(function()
			return DialogueController.Talk({ Id = ECharacters.Hero, Dialogue = EDialogue.Third_Hero_3 })
		end)
		:andThen(function()
			return DialogueController.Talk({ Id = ECharacters.Hero, Dialogue = EDialogue.Third_Hero_4 })
		end)
		:andThen(function()
			return DialogueController.Talk({ Id = ECharacters.Hero, Dialogue = EDialogue.Third_Hero_5 })
		end)
		:andThen(function()
			Scene_Third.Whispers = SoundsController.Clone(ESounds.Whispers, SoundService)
			if Scene_Third.Whispers then
				Scene_Third.Whispers.Volume = 0
				Scene_Third.Whispers:Play()

				TweenService:Create(Scene_Third.Whispers, TWEEN_INFO, { Volume = 1.35 }):Play()
			end

			return Promise.delay(4)
		end)
		:andThen(function()
			return DialogueController.Talk({
				Name = "???",
				Id = ECharacters.DemonGod,
				Dialogue = EDialogue.Third_DemonGod_0,
			})
		end)
		:andThen(function()
			return DialogueController.Talk({ Id = ECharacters.Hero, Dialogue = EDialogue.Third_Hero_6 })
		end)
		:andThen(function()
			if Scene_Third.Whispers then
				local tween = TweenService:Create(Scene_Third.Whispers, TWEEN_INFO, { Volume = 0 })
				tween.Completed:Once(function()
					if Scene_Third.Whispers then Scene_Third.Whispers:Destroy() end
				end)
				tween:Play()
			end

			FlamesController.Appear(EFlames.RedFlame)
			return DialogueController.Talk({ Id = ECharacters.DemonGod, Dialogue = EDialogue.Third_DemonGod_1 })
		end)
		:andThen(function()
			return DialogueController.Talk({ Id = ECharacters.Hero, Dialogue = EDialogue.Third_Hero_7 })
		end)
		:andThen(function()
			return DialogueController.Talk({ Id = ECharacters.DemonGod, Dialogue = EDialogue.Third_DemonGod_2 })
		end)
		:andThen(function()
			return DialogueController.Talk({ Id = ECharacters.Hero, Dialogue = EDialogue.Third_Hero_8 })
		end)
		:andThen(function()
			return DialogueController.Talk({ Id = ECharacters.DemonGod, Dialogue = EDialogue.Third_DemonGod_3 })
		end)
		:andThen(function()
			return DialogueController.Talk({ Id = ECharacters.Hero, Dialogue = EDialogue.Third_Hero_9 })
		end)
		:andThen(function()
			return DialogueController.Talk({ Id = ECharacters.DemonGod, Dialogue = EDialogue.Third_DemonGod_4 })
		end)
		:andThen(function()
			local character = Player.Character :: TCharacter.TCharacter
			if character then character.Wings.Transparency = 0 end

			FlamesController.Dissapear()
			return Promise.delay(0.75)
		end)
		:andThen(function()
			HealthController.Revive()
			Scene_Third.ShouldRestart = true
			return Promise.delay(1)
		end)
		:andThen(function()
			return DialogueController.Talk({ Id = ECharacters.Hero, Dialogue = EDialogue.Third_Hero_10 })
		end)
		:andThen(function()
			return DialogueController.Talk({ Id = ECharacters.Hero, Dialogue = EDialogue.Third_Hero_11 })
		end)
		:andThen(function()
			return DialogueController.Talk({ Id = ECharacters.DemonGod, Dialogue = EDialogue.Third_DemonGod_5 })
		end)
		:andThen(function()
			return DialogueController.Talk({ Id = ECharacters.DemonKing, Dialogue = EDialogue.Third_DemonKing_5 })
		end)
		:andThen(function()
			-- player kills the demon king
			return ProjectileController.ChargeProjectile(
				ProjectileController.ESender.PlayerDemon,
				4.5,
				0.01,
				18,
				60,
				1000,
				true
			)
				:andThen(function()
					return Promise.fromEvent(BossController.OnDamaged :: any):andThen(function()
						BossController.GetRig().HumanoidRootPart.Anchored = false
						BossRagdollController.Ragdoll()
						return Promise.delay(1)
					end)
				end)
		end)
		:andThen(function()
			return BlackoutController.Transparency(0)
				:andThen(function()
					CameraController.AutoRotate = false

					local bossRig = BossController.GetRig()

					bossRig.HumanoidRootPart.Anchored = true
					BossRagdollController.Unragdoll()
					BossController.Reset()

					local camera = Workspace.CurrentCamera
					bossRig.Horns.Transparency = 1
					camera.CameraSubject = bossRig.PrimaryPart
					camera.CFrame = CFrame.new(camera.CameraSubject.Position :: any) * CFrame.Angles(0, math.rad(90), 0)

					local character = Player.Character :: TCharacter.TCharacter
					if character then
						local secondSpawn = CollectionService:GetTagged("SecondSpawn")[1] :: Attachment
						if secondSpawn then character.HumanoidRootPart.CFrame = secondSpawn.WorldCFrame end

						if character then character.Wings.Transparency = 1 end
					end

					return Promise.delay(1)
				end)
				:andThen(function()
					return BlackoutController.Transparency(1):andThen(function()
						return Promise.delay(1)
					end)
				end)
		end)
		:andThen(function()
			return DialogueController.Talk({
				Name = "New Hero",
				Id = ECharacters.Hero,
				Dialogue = EDialogue.Third_NewHero_0,
			})
		end)
		:andThen(function()
			return DialogueController.Talk({
				Name = "Old Hero",
				Id = ECharacters.DemonKing,
				Dialogue = EDialogue.Third_NewDemonKing_3,
			})
		end)
		:andThen(function()
			Scene_Third.ShouldRestart = false
			BossSpawnController.ProjectilesAtSceneStart(1000, 1, ProjectileController.ESender.PlayerDemon)
			return Promise.fromEvent(HealthController.OnDead :: any):andThen(function()
				return Promise.delay(2)
			end)
		end)
		:andThen(function()
			local whiteFlame = WhiteFlame:Clone()
			local root = if Player.Character then Player.Character.PrimaryPart else nil
			if root then whiteFlame.CFrame = root.CFrame + Vector3.yAxis * 3 end
			whiteFlame.Parent = Workspace

			SoundsController.Play(ESounds.IgniteFlame, whiteFlame)

			return Promise.delay(2)
		end)
		:andThen(function()
			return DialogueController.Talk({
				Name = "Old Hero",
				Id = ECharacters.DemonKing,
				Dialogue = EDialogue.Third_NewDemonKing_4,
			})
		end)
		:andThen(function()
			BlackoutController.Transparency(0)
				:andThen(function()
					Promise.delay(1)
				end)
				:andThen(function()
					-- TODO: CREDITS
				end)
		end)

	return Scene_Third.CurrentPromise :: Promise.Promise
end

function Scene_Third.CharacterDied()
	return Scene_Third.ShouldRestart
end

function Scene_Third.Stop()
	Scene_Third.IsActive = false
	Scene_Third.ShouldRestart = true
	if Scene_Third.Whispers then Scene_Third.Whispers:Destroy() end

	local character = Player.Character :: TCharacter.TCharacter
	if character then character.Wings.Transparency = 1 end

	BossController.GetRig().Horns.Transparency = 0

	CameraController.DisableCinematicCamera()

	FlamesController.Dissapear()
end

function Scene_Third.Restart()
	Scene_Third.Stop()

	HealthController.Revive()

	Scene_Third.Start()
end

return Scene_Third
