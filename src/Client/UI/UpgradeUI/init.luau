local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fluid = require(ReplicatedStorage.Shared.Utils.Fluid)

local create = Fluid.create

return function()
	create("ScreenGui")({
		Name = "UpgradeUI",
		ClipToDeviceSafeArea = false,
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,

		create("Frame")({
			Name = "Container",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),

			create("UIListLayout")({
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				Padding = UDim.new(0.0156331, 0),
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),

			create("ImageButton")({
				Name = "Upgrade",
				BackgroundTransparency = 1,
				Image = "rbxassetid://121546511572946",
				Position = UDim2.fromScale(0.403856, 0.347583),
				ResampleMode = Enum.ResamplerMode.Pixelated,
				ScaleType = Enum.ScaleType.Slice,
				Size = UDim2.fromScale(0.22, 0.5),
				SliceCenter = Rect.new(24, 24, 24, 24),
				SliceScale = 2,

				create("ImageLabel")({
					Name = "Photo",
					AnchorPoint = Vector2.new(0.5, 0),
					BackgroundColor3 = Color3.new(1, 1, 1),
					BorderColor3 = Color3.new(),
					BorderSizePixel = 0,
					Image = "rbxasset://textures/ui/GuiImagePlaceholder.png",
					Position = UDim2.fromScale(0.5, 0.08),
					Size = UDim2.fromScale(0.473732, 0.37037),

					create("UIAspectRatioConstraint")({}),
				}),

				create("TextLabel")({
					Name = "Name",
					AnchorPoint = Vector2.new(0.5, 0),
					AutoLocalize = false,
					BackgroundTransparency = 1,
					FontFace = Font.new(
						"rbxasset://fonts/families/SpecialElite.json",
						Enum.FontWeight.Bold,
						Enum.FontStyle.Normal
					),
					Position = UDim2.fromScale(0.5, 0.526173),
					RichText = true,
					Size = UDim2.fromScale(0.9, 0.1),
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
					Name = "Description",
					AnchorPoint = Vector2.new(0.5, 1),
					AutoLocalize = false,
					BackgroundTransparency = 1,
					FontFace = Font.new("rbxasset://fonts/families/SpecialElite.json"),
					Position = UDim2.fromScale(0.5, 0.98),
					RichText = true,
					Size = UDim2.fromScale(0.9, 0.35),
					Text = "",
					TextColor3 = Color3.new(1, 1, 1),
					TextScaled = true,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,

					create("UIStroke")({
						LineJoinMode = Enum.LineJoinMode.Bevel,
						StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
						Thickness = 0.07,
					}),

					create("UITextSizeConstraint")({
						MaxTextSize = 35,
					}),
				}),

				create("UIGradient")({
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.new(0.203922, 1, 0.8)),
						ColorSequenceKeypoint.new(1, Color3.new(0.0588235, 0.388235, 0.317647)),
					}),
					Rotation = 90,
				}),
			}),
		}),
	})
end
