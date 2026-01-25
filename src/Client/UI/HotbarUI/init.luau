-- src/Client/UI/HotbarUI/init.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local healthBar = require(StarterPlayer.StarterPlayerScripts.Client.UI.Components.healthBar)
local Fluid = require(ReplicatedStorage.Shared.Utils.Fluid)

export type HotbarUIReturn = {
	UI: any,
	SetMaxHealth: (newMax: number) -> (),
	SetCurrentHealth: (newHealth: number) -> (),
	Appear: () -> (),
	Disappear: () -> (),
	AddAbility: () -> (),
}

local create = Fluid.create
local source = Fluid.source
local spring = Fluid.spring

return function(): HotbarUIReturn
	local transparencyTarget = source(1)
	local transparency = spring(transparencyTarget, 10, 0.8)

	local BarComponent = healthBar({
		Transparency = transparency,
		LayoutOrder = 1,
	})

	local ui = create("ScreenGui")({
		Name = "HotbarGui",
		ClipToDeviceSafeArea = false,
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,

		create("Frame")({
			Name = "Container",
			AnchorPoint = Vector2.new(0.5, 1),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.97),
			Size = UDim2.fromScale(0.375, 0.225),

			create("UIListLayout")({
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				Padding = UDim.new(0.15, 0),
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Bottom,
			}),

			BarComponent.Frame,

			-- Abilities frame
			create("Frame")({
				Name = "Abilities",
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 0.2),
				create("UIListLayout")({
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					HorizontalFlex = Enum.UIFlexAlignment.SpaceEvenly,
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
				}),
				create("UIPadding")({ PaddingLeft = UDim.new(0.1, 0), PaddingRight = UDim.new(0.1, 0) }),
			}),
		}),
	})

	return {
		UI = ui,

		SetMaxHealth = BarComponent.SetMaxHealth,
		SetCurrentHealth = BarComponent.SetCurrentHealth,

		Appear = function()
			transparencyTarget(0)
		end,

		Disappear = function()
			transparencyTarget(1)
		end,

		AddAbility = function() end,
	}
end
