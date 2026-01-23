local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local FloatingNumbersController = require(script.Parent.Parent.FloatingNumbersController)
local BossLifeUI = require(StarterPlayer.StarterPlayerScripts.Client.UI.BossLifeUI)
local BossController = require(script.Parent)
local Fluid = require(ReplicatedStorage.Shared.Utils.Fluid)

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local BossLifebarController = {}
local UI: BossLifeUI.BossLifeUIReturn

Fluid.mount(function()
	UI = BossLifeUI()
	return UI.UI
end, PlayerGui)

function BossLifebarController.Appear()
	UI.Appear()
end

function BossLifebarController.Disappear()
	UI.Disappear()
end

BossController.OnDamaged:Connect(function(_, new, amount)
	-- TODO: Make a sound.
	UI.SetCurrentHealth(new)
	FloatingNumbersController.Add(
		BossController.GetPosition(),
		amount,
		FloatingNumbersController.ENumberType.DamageEnemy
	)
end)

BossController.OnHealed:Connect(function(_, new, amount)
	UI.SetCurrentHealth(new)
	FloatingNumbersController.Add(
		BossController.GetPosition(),
		amount,
		FloatingNumbersController.ENumberType.DamageEnemy
	)
end)

BossController.OnMaxHealthChanged:Connect(function(_, new)
	UI.SetMaxHealth(new)
end)

return BossLifebarController
