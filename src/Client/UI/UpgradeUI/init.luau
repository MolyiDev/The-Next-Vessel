local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local scaleNumber = require(StarterPlayer.StarterPlayerScripts.Client.UI.Components.scaleNumber)
local Fluid = require(ReplicatedStorage.Shared.Utils.Fluid)

export type UpgradeUIParams = {
	SelectedCard: (upgrade: number) -> (),
}

export type SpawnCardParams = {
	Id: number,
	Name: string,
	Description: string,
	GradientColor: ColorSequence,
	Image: string,
}

export type UpgradeUIReturn = {
	UI: any,
	SpawnCard: (params: SpawnCardParams) -> (),
	Disappear: () -> (),
	Appear: () -> (),
}

local create = Fluid.create
local source = Fluid.source
local derive = Fluid.derive
local spring = Fluid.spring

local function lerpColor(c1: Color3, c2: Color3, alpha: number): Color3
	return Color3.new(c1.R + (c2.R - c1.R) * alpha, c1.G + (c2.G - c1.G) * alpha, c1.B + (c2.B - c1.B) * alpha)
end

return function(params: UpgradeUIParams): UpgradeUIReturn
	local transparencyTarget = source(1)
	local transparency = spring(transparencyTarget, 20, 0.8)
	local strokeTransparency = derive(function()
		local t = transparency()
		return math.min(1, t / 0.85)
	end)
	local cards = source({})
	local maxTextSize = scaleNumber(38)
	local sliceScale = scaleNumber(2)

	local function upgradeButton(data: SpawnCardParams)
		local defaultGradient = data.GradientColor
		local darkGradient = ColorSequence.new(
			lerpColor(data.GradientColor.Keypoints[1].Value, Color3.new(), 0.2),
			lerpColor(data.GradientColor.Keypoints[2].Value, Color3.new(), 0.2)
		)

		local gradient = source(defaultGradient)

		local function enter()
			gradient(darkGradient)
		end

		local function leave()
			gradient(defaultGradient)
		end

		local function activate()
			gradient(defaultGradient)
			params.SelectedCard(data.Id)
		end

		return create("ImageButton")({
			Name = "Upgrade",
			BackgroundTransparency = 1,
			Image = "rbxassetid://121546511572946",
			ImageTransparency = transparency,
			Position = UDim2.fromScale(0.403856, 0.347583),
			ResampleMode = Enum.ResamplerMode.Pixelated,
			ScaleType = Enum.ScaleType.Slice,
			Size = UDim2.fromScale(0.22, 0.5),
			SliceCenter = Rect.new(24, 24, 24, 24),
			SliceScale = sliceScale,
			MouseEnter = enter,
			MouseLeave = leave,
			SelectionGained = enter,
			SelectionLost = leave,
			Activated = activate,

			create("ImageLabel")({
				Name = "Photo",
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Image = data.Image,
				ImageTransparency = transparency,
				Position = UDim2.fromScale(0.5, 0.08),
				Size = UDim2.fromScale(0.521, 0.407),
				ResampleMode = Enum.ResamplerMode.Pixelated,
				ScaleType = Enum.ScaleType.Fit,

				create("UIAspectRatioConstraint")({}),
			}),

			create("TextLabel")({
				Name = "Name",
				AnchorPoint = Vector2.new(0.5, 0),
				AutoLocalize = false,
				BackgroundTransparency = 1,
				FontFace = Font.new(
					"rbxasset://fonts/families/Fondamento.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Position = UDim2.fromScale(0.5, 0.526173),
				RichText = true,
				Size = UDim2.fromScale(0.9, 0.1),
				Text = data.Name,
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				TextTransparency = transparency,

				create("UIStroke")({
					LineJoinMode = Enum.LineJoinMode.Bevel,
					StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
					Thickness = 0.07,
					Transparency = strokeTransparency,
				}),
			}),

			create("TextLabel")({
				Name = "Description",
				AnchorPoint = Vector2.new(0.5, 1),
				AutoLocalize = false,
				BackgroundTransparency = 1,
				FontFace = Font.new("rbxasset://fonts/families/Fondamento.json"),
				Position = UDim2.fromScale(0.5, 0.98),
				RichText = true,
				Size = UDim2.fromScale(0.9, 0.34),
				Text = data.Description,
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				TextYAlignment = Enum.TextYAlignment.Top,
				TextTransparency = transparency,

				create("UIStroke")({
					LineJoinMode = Enum.LineJoinMode.Bevel,
					StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
					Thickness = 0.07,
					Transparency = strokeTransparency,
				}),

				create("UITextSizeConstraint")({
					MaxTextSize = maxTextSize,
				}),
			}),

			create("UIGradient")({
				Color = gradient,
				Rotation = 90,
			}),
		})
	end

	local ui = create("ScreenGui")({
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

			Fluid.for_values(cards, function(cardData)
				return upgradeButton(cardData)
			end),

			create("UIListLayout")({
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				Padding = UDim.new(0.0156331, 0),
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),
		}),
	})

	return {
		UI = ui,
		SpawnCard = function(cardParams)
			local current = cards()
			local new = table.clone(current)
			new[#new + 1] = cardParams
			cards(new)
		end,
		Appear = function()
			transparencyTarget(0)
		end,
		Disappear = function()
			transparencyTarget(1)
			task.delay(0.6, function()
				cards({})
			end)
		end,
	}
end
