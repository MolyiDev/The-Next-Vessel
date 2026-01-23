local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local HealthController = require(script.Parent.HealthController)
local Fluid = require(ReplicatedStorage.Shared.Utils.Fluid)
local HotbarUI = require(StarterPlayer.StarterPlayerScripts.Client.UI.HotbarUI)

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local HotbarController = {}
local UI: HotbarUI.HotbarUIReturn

Fluid.mount(function()
	UI = HotbarUI()
	return UI.UI
end, PlayerGui)

function HotbarController.Appear()
	UI.Appear()
end

function HotbarController.Disappear()
	UI.Disappear()
end

HealthController.OnDamaged:Connect(function(_, new)
	-- TODO: Make a sound.
	print("damage", new)
	UI.SetCurrentHealth(new)
end)

HealthController.OnHealed:Connect(function(_, new)
	UI.SetCurrentHealth(new)
end)

HealthController.OnMaxHealthChanged:Connect(function(_, new)
	UI.SetMaxHealth(new)
end)

return HotbarController
