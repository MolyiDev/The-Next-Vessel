-- src/Client/UI/BossLifeUI/init.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local healthBar = require(StarterPlayer.StarterPlayerScripts.Client.UI.Components.healthBar)
local Fluid = require(ReplicatedStorage.Shared.Utils.Fluid)

export type BossLifeUIReturn = {
	UI: any,
	SetMaxHealth: (newMax: number) -> (),
	SetCurrentHealth: (newHealth: number) -> (),
	Appear: () -> (),
	Disappear: () -> (),
}

local create = Fluid.create
local source = Fluid.source
local spring = Fluid.spring

return function(): BossLifeUIReturn
	local transparencyTarget = source(1)
	local transparency = spring(transparencyTarget, 10, 0.8)

	local barComponent = healthBar({
		Transparency = transparency,
	})

	local ui = create("ScreenGui")({
		Name = "BossLifeUI",
		ClipToDeviceSafeArea = false,
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,

		create("Frame")({
			Name = "Container",
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.01),
			Size = UDim2.fromScale(0.6, 0.225),

			barComponent.Frame,
		}),
	})

	return {
		UI = ui,

		SetMaxHealth = barComponent.SetMaxHealth,
		SetCurrentHealth = barComponent.SetCurrentHealth,

		Appear = function()
			transparencyTarget(0)
		end,

		Disappear = function()
			transparencyTarget(1)
		end,
	}
end
