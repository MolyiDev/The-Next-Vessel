local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local BossLifeUI = require(StarterPlayer.StarterPlayerScripts.Client.UI.BossLifeUI)
local BossController = require(script.Parent)
local Fluid = require(ReplicatedStorage.Shared.Utils.Fluid)

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local HotbarController = {}
local UI: BossLifeUI.BossLifeUIReturn

Fluid.mount(function()
	UI = BossLifeUI()
	return UI.UI
end, PlayerGui)

BossController.OnDamaged:Connect(function(_, new)
	-- TODO: Make a sound.
	UI.SetCurrentHealth(new)
end)

BossController.OnHealed:Connect(function(_, new)
	UI.SetCurrentHealth(new)
end)

BossController.OnMaxHealthChanged:Connect(function(_, new)
	UI.SetMaxHealth(new)
end)

return HotbarController
