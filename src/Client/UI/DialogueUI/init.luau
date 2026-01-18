local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fluid = require(ReplicatedStorage.Shared.Utils.Fluid)

local create = Fluid.create

return function()
	local transparency = source(0)

	return create("ScreenGui")({
		Name = "DialogueUI",
		ClipToDeviceSafeArea = false,
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,

		create("Frame")({
			Name = "Container",
			AnchorPoint = Vector2.new(0.5, 1),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.98),
			Size = UDim2.fromScale(0.52, 0.2),

			create("ImageLabel")({
				Name = "Border",
				BackgroundTransparency = 1,
				Image = "rbxassetid://112173964841374",
				ResampleMode = Enum.ResamplerMode.Pixelated,
				ScaleType = Enum.ScaleType.Slice,
				Size = UDim2.fromScale(1, 1),
				SliceCenter = Rect.new(24, 24, 24, 24),
				SliceScale = 2,
				ZIndex = 0,

				create("UIGradient")({
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.new(0.0980392, 0.0980392, 0.0980392)),
						ColorSequenceKeypoint.new(1, Color3.new(0.247059, 0.247059, 0.247059)),
					}),
					Rotation = -90,
				}),
			}),

			create("TextLabel")({
				Name = "Dialogue",
				AnchorPoint = Vector2.new(0.5, 0.5),
				AutoLocalize = false,
				BackgroundTransparency = 1,
				FontFace = Font.new("rbxassetid://12187371840", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
				Position = UDim2.fromScale(0.5, 0.51),
				RichText = true,
				Size = UDim2.fromScale(0.95, 0.56),
				Text = "",
				TextColor3 = Color3.new(1, 1, 1),
				TextSize = 30,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,

				create("UIStroke")({
					LineJoinMode = Enum.LineJoinMode.Bevel,
					StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
					Thickness = 0.021,
				}),
			}),

			create("TextLabel")({
				Name = "Name",
				AnchorPoint = Vector2.new(0.5, 0),
				AutoLocalize = false,
				BackgroundTransparency = 1,
				FontFace = Font.new("rbxassetid://12187371840", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
				Position = UDim2.fromScale(0.5, 0.02),
				RichText = true,
				Size = UDim2.fromScale(0.95, 0.2),
				Text = "Name",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,

				create("UIStroke")({
					LineJoinMode = Enum.LineJoinMode.Bevel,
					StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
					Thickness = 0.07,
				}),
			}),

			create("TextLabel")({
				Name = "Next",
				AnchorPoint = Vector2.new(0.5, 1),
				AutoLocalize = false,
				BackgroundTransparency = 1,
				FontFace = Font.new("rbxassetid://12187371840", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
				Position = UDim2.fromScale(0.5, 0.93),
				RichText = true,
				Size = UDim2.fromScale(0.95, 0.15),
				Text = "next...",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,

				create("UIStroke")({
					LineJoinMode = Enum.LineJoinMode.Bevel,
					StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
					Thickness = 0.07,
				}),
			}),
		}),
	})
end
