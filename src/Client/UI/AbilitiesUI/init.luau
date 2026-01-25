local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local scaleNumber = require(StarterPlayer.StarterPlayerScripts.Client.UI.Components.scaleNumber)
local Fluid = require(ReplicatedStorage.Shared.Utils.Fluid)
local Tools = require(ReplicatedStorage.Shared.Utils.Tools)
local EAssets = require(ReplicatedStorage.Types.Enums.EAssets)

local create = Fluid.create
local derive = Fluid.derive
local source = Fluid.source
local spring = Fluid.spring
local for_values = Fluid.for_values

type Ability = {
	Icon: string,
	Key: string,
	Cooldown: Fluid.Source<number>,
	Amount: Fluid.Source<number>?,
	LayoutOrder: number,
}

export type AbilitiesUIReturn = {
	UI: any,
	AddAbility: (abilityImage: string, keyImage: string, canStack: boolean) -> number,
	RemoveAbility: (id: number) -> (),
	SetCooldown: (id: number, progress: number) -> (),
	SetAmount: (id: number, amount: number) -> (),
	Appear: () -> (),
	Disappear: () -> (),
}

local function getCooldownTransparency(progress: number)
	if progress <= 0 then return NumberSequence.new(1) end
	local cutoff = math.clamp(1 - progress, 0.001, 0.999)
	return NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(cutoff, 0),
		NumberSequenceKeypoint.new(cutoff + 0.001, 1),
		NumberSequenceKeypoint.new(1, 1),
	})
end

local function abilityComponent(
	props: Ability,
	globalTransparency: Fluid.Source<number>,
	sliceScale: Fluid.Source<number>,
	strokeScale: Fluid.Source<number>
)
	local sweepTransparency = derive(function()
		return getCooldownTransparency(props.Cooldown())
	end)

	local timerVisible = derive(function()
		return props.Cooldown() > 0 and globalTransparency() < 1
	end)

	local timerBgTransparency = derive(function()
		return 0.5 + (0.5 * globalTransparency())
	end)

	local strokeTransparency = derive(function()
		return math.min(1, globalTransparency() / 0.85)
	end)

	return create("Frame")({
		Name = "Ability",
		BackgroundTransparency = 1,
		LayoutOrder = props.LayoutOrder,
		Size = UDim2.fromScale(0.957, 0.958),

		create("ImageLabel")({
			Name = "Background",
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Image = EAssets.AbilityBackground,
			ImageColor3 = Color3.fromRGB(60, 60, 60),
			ImageTransparency = globalTransparency,
			Position = UDim2.fromScale(0.5, 0.5),
			ResampleMode = Enum.ResamplerMode.Pixelated,
			ScaleType = Enum.ScaleType.Slice,
			Size = UDim2.fromScale(1, 1),
			SliceCenter = Rect.new(24, 24, 24, 24),
			SliceScale = sliceScale,
			ZIndex = 1,

			create("ImageLabel")({
				Name = "Icon",
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Image = props.Icon,
				ImageTransparency = globalTransparency,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.7, 0.7),
				ZIndex = 2,
			}),
		}),

		create("Frame")({
			Name = "Timer",
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = timerBgTransparency,
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.85, 0.85),
			Visible = timerVisible,
			ZIndex = 3,

			create("UIGradient")({
				Rotation = -90,
				Transparency = sweepTransparency,
			}),
		}),

		create("ImageLabel")({
			Name = "Key",
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Image = props.Key,
			ImageTransparency = globalTransparency,
			Position = UDim2.fromScale(0.5, 0),
			ResampleMode = Enum.ResamplerMode.Pixelated,
			ScaleType = Enum.ScaleType.Fit,
			Size = UDim2.fromScale(0.4, 0.4),
			ZIndex = 4,
		}),

		create("UIAspectRatioConstraint")({}),

		if props.Amount
			then create("Frame")({
				Name = "QuantityContainer",
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				ZIndex = 5,

				create("TextLabel")({
					Name = "Quantity",
					AnchorPoint = Vector2.new(0.5, 1),
					BackgroundTransparency = 1,
					FontFace = Tools.FONT_SILKSCREEN_BOLD,
					Position = UDim2.fromScale(0.5, 0.95),
					RichText = true,
					Size = UDim2.fromScale(0.6, 0.4),
					Text = derive(function()
						return tostring(props.Amount())
					end),
					TextColor3 = Color3.new(1, 1, 1),
					TextTransparency = globalTransparency,
					TextScaled = true,
					TextYAlignment = Enum.TextYAlignment.Bottom,
					ZIndex = 5,
					create("UIStroke")({ Thickness = strokeScale, Transparency = strokeTransparency }),
				}),
			})
			else nil,
	})
end

return function(): AbilitiesUIReturn
	local transparencyTarget = source(1)
	local transparency = spring(transparencyTarget, 10, 0.8)

	local sliceScale = scaleNumber(2)
	local strokeScale = scaleNumber(2)
	local abilitiesMap = source({} :: { [number]: Ability })
	local nextId = 0

	local ui = create("ScreenGui")({
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
			Position = UDim2.fromScale(0.005, 0.975),
			Size = UDim2.fromScale(0.065, 0.116),

			create("UIListLayout")({
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				Padding = UDim.new(0.064, 0),
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Bottom,
			}),

			for_values(abilitiesMap, function(abilityData)
				return abilityComponent(abilityData, transparency, sliceScale, strokeScale)
			end),
		}),
	})

	return {
		UI = ui,

		AddAbility = function(icon: string, key: string, canStack: boolean)
			nextId += 1
			local id = nextId
			local current = abilitiesMap()

			local newEntry: Ability = {
				Icon = icon,
				Key = key,
				Cooldown = source(0),
				Amount = if canStack then source(0) else nil,
				LayoutOrder = id,
			}

			local newMap = table.clone(current)
			newMap[id] = newEntry
			abilitiesMap(newMap)

			return id
		end,

		RemoveAbility = function(id: number)
			local current = abilitiesMap()
			if not current[id] then return end

			local newMap = table.clone(current)
			newMap[id] = nil
			abilitiesMap(newMap)
		end,

		SetCooldown = function(id: number, progress: number)
			local current = abilitiesMap()
			local ability = current[id]
			if ability then ability.Cooldown(progress) end
		end,

		SetAmount = function(id: number, amount: number)
			local current = abilitiesMap()
			local ability = current[id]
			if ability and ability.Amount then ability.Amount(amount) end
		end,

		Appear = function()
			transparencyTarget(0)
		end,
		Disappear = function()
			transparencyTarget(1)
		end,
	}
end
