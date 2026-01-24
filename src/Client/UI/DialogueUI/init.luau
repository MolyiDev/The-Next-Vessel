local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local scaleNumber = require(StarterPlayer.StarterPlayerScripts.Client.UI.Components.scaleNumber)
local Fluid = require(ReplicatedStorage.Shared.Utils.Fluid)
local EAssets = require(ReplicatedStorage.Types.Enums.EAssets)

export type DialogueUIReturn = {
	UI: any,
	Appear: () -> (),
	Disappear: () -> (),
	Refs: {
		Name: TextLabel,
		Text: TextLabel,
		NextIndicator: TextLabel,
	},
}

local create = Fluid.create
local source = Fluid.source
local derive = Fluid.derive
local spring = Fluid.spring

return function(): DialogueUIReturn
	local transparencyTarget = source(1)
	local transparency = spring(transparencyTarget, 20, 0.8)
	local strokeTransparency = derive(function()
		local t = transparency()
		return math.min(1, t / 0.85)
	end)
	local textSize = scaleNumber(38)
	local sliceScale = scaleNumber(2)
	local strokeName = scaleNumber(2)
	local strokeOther = scaleNumber(1.5)

	local nameLabel = create("TextLabel")({
		Name = "Name",
		AnchorPoint = Vector2.new(0.5, 0),
		AutoLocalize = false,
		BackgroundTransparency = 1,
		FontFace = Font.new("rbxasset://fonts/families/Fondamento.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
		Position = UDim2.fromScale(0.5, 0.06),
		RichText = true,
		Size = UDim2.fromScale(0.95, 0.2),
		Text = "Name",
		TextColor3 = Color3.new(1, 1, 1),
		TextScaled = true,
		TextTransparency = transparency,

		create("UIStroke")({
			LineJoinMode = Enum.LineJoinMode.Bevel,
			Thickness = strokeName,
			Transparency = strokeTransparency,
		}),
	})

	local dialogueLabel = create("TextLabel")({
		Name = "Dialogue",
		AnchorPoint = Vector2.new(0.5, 0.5),
		AutoLocalize = false,
		BackgroundTransparency = 1,
		FontFace = Font.new("rbxasset://fonts/families/Fondamento.json"),
		Position = UDim2.fromScale(0.5, 0.525),
		RichText = true,
		Size = UDim2.fromScale(0.95, 0.53),
		Text = "",
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = textSize,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextTransparency = transparency,

		create("UIStroke")({
			LineJoinMode = Enum.LineJoinMode.Bevel,
			Thickness = strokeOther,
			Transparency = strokeTransparency,
		}),
	})

	local nextIndicatorLabel = create("TextLabel")({
		Name = "Next",
		AnchorPoint = Vector2.new(0.5, 1),
		AutoLocalize = false,
		BackgroundTransparency = 1,
		FontFace = Font.new("rbxasset://fonts/families/Fondamento.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
		Position = UDim2.fromScale(0.5, 0.93),
		RichText = true,
		Size = UDim2.fromScale(0.95, 0.15),
		Text = "Press F to skip...",
		TextColor3 = Color3.new(1, 1, 1),
		TextScaled = true,
		TextTransparency = transparency,

		create("UIStroke")({
			LineJoinMode = Enum.LineJoinMode.Bevel,
			Thickness = strokeOther,
			Transparency = strokeTransparency,
		}),
	})

	local ui = create("ScreenGui")({
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
			Position = UDim2.fromScale(0.5, 0.94),
			Size = UDim2.fromScale(0.5, 0.2),

			create("ImageLabel")({
				Name = "Border",
				BackgroundTransparency = 1,
				Image = EAssets.DialogueBackground,
				ImageTransparency = transparency,
				ResampleMode = Enum.ResamplerMode.Pixelated,
				ScaleType = Enum.ScaleType.Slice,
				Size = UDim2.fromScale(1, 1),
				SliceCenter = Rect.new(24, 24, 24, 24),
				SliceScale = sliceScale,
				ZIndex = 0,

				create("UIGradient")({
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.new()),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 40, 40)),
					}),
					Rotation = -90,
				}),
			}),

			nameLabel,
			dialogueLabel,
			nextIndicatorLabel,
		}),
	})

	return {
		UI = ui,
		Appear = function()
			transparencyTarget(0)
		end,
		Disappear = function()
			transparencyTarget(1)
		end,
		Refs = {
			Name = nameLabel,
			Text = dialogueLabel,
			NextIndicator = nextIndicatorLabel,
		},
	}
end
