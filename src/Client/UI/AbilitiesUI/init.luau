local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fluid = require(ReplicatedStorage.Shared.Utils.Fluid)

local create = Fluid.create

type AbilitiesUIReturn = {
	AddAbility: (abilityImage: string, keyImage: string, canStack: boolean) -> number,
	RemoveAbility: (index: number) -> (),
	SetCooldown: (index: number, cd: number) -> (),
	ResetAllCooldowns: () -> (),
	ResetCooldowns: (index: number) -> (),
	SetStack: (index: number, stack: number) -> (),

	-- Start cooldown
	AbilityUsed: (index: number) -> (),
}

return function()
	local function ability()
		create("Frame")({
			Name = "Ability",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(0.956938, 0.957854),

			create("ImageLabel")({
				Name = "Ability",
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Image = "rbxassetid://72008670363476",
				ImageColor3 = Color3.fromRGB(60, 60, 60),
				Position = UDim2.fromScale(0.5, 0.5),
				ResampleMode = Enum.ResamplerMode.Pixelated,
				ScaleType = Enum.ScaleType.Slice,
				Size = UDim2.fromScale(1, 1),
				SliceCenter = Rect.new(24, 24, 24, 24),
				SliceScale = 2,
				ZIndex = 0,

				create("ImageLabel")({
					Name = "Image",
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Image = "rbxassetid://119823473015159",
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromScale(0.9, 0.9),
				}),
			}),

			create("Frame")({
				Name = "Timer",
				AnchorPoint = Vector2.new(0, 1),
				BackgroundColor3 = Color3.new(1, 1, 1),
				BorderColor3 = Color3.new(),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0, 1),
				Size = UDim2.fromScale(1, 1),

				create("UIGradient")({
					Rotation = -90,
					Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 0.6),
						NumberSequenceKeypoint.new(0.5, 0.6),
						NumberSequenceKeypoint.new(0.501, 1),
						NumberSequenceKeypoint.new(1, 1),
					}),
				}),
			}),

			create("ImageLabel")({
				Name = "Key",
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Image = "rbxassetid://74858030379993",
				Position = UDim2.fromScale(0.5, 0.1),
				ResampleMode = Enum.ResamplerMode.Pixelated,
				ScaleType = Enum.ScaleType.Fit,
				Size = UDim2.fromScale(0.35, 0.35),
				ZIndex = 2,
			}),

			create("UIAspectRatioConstraint")({}),

			create("TextLabel")({
				Name = "Quantity",
				AnchorPoint = Vector2.new(0.5, 1),
				BackgroundTransparency = 1,
				FontFace = Font.new(
					"rbxasset://fonts/families/Fondamento.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Position = UDim2.fromScale(0.5, 0.95),
				RichText = true,
				Size = UDim2.fromScale(0.6, 0.4),
				Text = "1",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				TextYAlignment = Enum.TextYAlignment.Bottom,
				ZIndex = 2,

				create("UIStroke")({
					LineJoinMode = Enum.LineJoinMode.Miter,
					Thickness = 2,
				}),
			}),
		})
	end

	return create("ScreenGui")({
		Name = "AbilitiesUI",
		ClipToDeviceSafeArea = false,
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,

		create("Frame")({
			Name = "Container",
			AnchorPoint = Vector2.new(0, 1),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.00500001, 0.991),
			Size = UDim2.fromScale(0.0653125, 0.116),

			create("UIListLayout")({
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0.0637959, 0),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		}),
	})
end
