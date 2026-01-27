local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")

local CameraController = require(script.Parent.CameraController)
local Ignis = require(ReplicatedStorage.Packages.Ignis)
local ESounds = require(ReplicatedStorage.Types.Enums.ESounds)
local EnemiesController = require(script.Parent.EnemiesController)
local HealthController = require(script.Parent.HealthController)
local SoundsController = require(script.Parent.SoundsController)
local UpgradesController = require(script.Parent.UpgradesController)
local TimeController = require(script.Parent.TimeController)
local SoulsBarUI = require(StarterPlayer.StarterPlayerScripts.Client.UI.SoulsBarUI)

local LevelsController = {}
LevelsController.CanLevelUp = true
LevelsController.CurrentSouls = 0
LevelsController.NeededSouls = 15
LevelsController.Level = 1
LevelsController.IsReadyToLevelUp = false

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local UI = SoulsBarUI(PlayerGui)
UI.SetXP(LevelsController.CurrentSouls, LevelsController.NeededSouls)

local function UpdateUI()
	UI.SetXP(LevelsController.CurrentSouls, LevelsController.NeededSouls)
end

function LevelsController.LevelUp()
	SoundsController.PlayCharacter(ESounds.LevelUp)
	LevelsController.IsReadyToLevelUp = false

	TimeController.SetGameplayPaused(true)

	LevelsController.CurrentSouls -= LevelsController.NeededSouls
	LevelsController.Level += 1

	LevelsController.NeededSouls = math.ceil(LevelsController.NeededSouls * 1.5)

	UpgradesController.Show({}, true):andThen(function()
		TimeController.SetGameplayPaused(false)
		CameraController.LockCamera()

		UI.SetRainbow(false)
		UI.SetTextLevelUp(false)
		UpdateUI()

		if LevelsController.CurrentSouls >= LevelsController.NeededSouls then
			LevelsController.IsReadyToLevelUp = true
			UI.SetRainbow(true)
			UI.SetTextLevelUp(true)
		end
	end)
end

function LevelsController.AddSoul()
	LevelsController.CurrentSouls += 1

	if LevelsController.CurrentSouls >= LevelsController.NeededSouls then
		if not LevelsController.IsReadyToLevelUp then
			LevelsController.IsReadyToLevelUp = true
			UI.SetRainbow(true)
			UI.SetTextLevelUp(true)
			SoundsController.PlayCharacter(ESounds.ReadyLevelUp)
		end
	else
		UpdateUI()
	end
end

function LevelsController.Appear()
	UI.Appear()
end

function LevelsController.Disappear()
	UI.Disappear()
end

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode ~= Enum.KeyCode.X then return end
	if not LevelsController.CanLevelUp then return end
	if HealthController.IsDead() then return end

	if LevelsController.IsReadyToLevelUp and not TimeController.GameplayPaused then LevelsController.LevelUp() end
end)

EnemiesController.OnEnemyDied:Connect(LevelsController.AddSoul)

return Ignis.Register(LevelsController)
