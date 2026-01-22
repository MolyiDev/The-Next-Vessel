local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Fluid = require(ReplicatedStorage.Shared.Utils.Fluid)

export type HotbarUIReturn = {
	UI: any,
	SetMaxHealth: (newMax: number) -> (),
	SetCurrentHealth: (newHealth: number) -> (),
	AddAbility: () -> (),
}

local ANIM_DELAY = 0.25
local TWEEN_INFO = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local create = Fluid.create

local function Ability()
	return create("Frame")({
		Name = "Ability",
		BackgroundColor3 = Color3.new(),
		BorderColor3 = Color3.new(),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(0.165, 1),

		create("ImageLabel")({
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Image = "rbxassetid://80313538698330",
			Position = UDim2.fromScale(0.5, 0.5),
			ResampleMode = Enum.ResamplerMode.Pixelated,
			ScaleType = Enum.ScaleType.Fit,
			Size = UDim2.fromScale(1, 1),
		}),

		create("UIStroke")({
			LineJoinMode = Enum.LineJoinMode.Bevel,
			StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
			Thickness = 0.0475,
		}),

		create("UIAspectRatioConstraint")({
			Name = "UIAspectRatioConstraint",
			DominantAxis = Enum.DominantAxis.Height,
		}),

		create("Frame")({
			Name = "Key",
			AnchorPoint = Vector2.new(0.5, 1),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 1.2),
			Size = UDim2.fromScale(0.45, 0.45),

			create("ImageLabel")({
				Name = "ImageLabel",
				BackgroundTransparency = 1,
				Image = "rbxasset://textures/ui/GuiImagePlaceholder.png",
				Size = UDim2.fromScale(1, 1),
				Visible = false,
			}),

			create("TextLabel")({
				Name = "TextLabel",
				BackgroundTransparency = 1,
				FontFace = Font.new("rbxassetid://12187371840", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
				Size = UDim2.fromScale(1, 1),
				Text = "1",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,

				create("UIStroke")({
					Name = "UIStroke",
					StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
					Thickness = 0.08,
				}),
			}),
		}),
	})
end

return function(): HotbarUIReturn
	-- State Variables
	local currentHealthVal = 100
	local maxHealthVal = 100

	-- Animation State
	local damageTask: thread? = nil
	local healingTask: thread? = nil
	local healingTween: Tween? = nil -- Store tween to cancel it cleanly

	-- 1. Create the bars explicitly first so we can reference them
	local damageBar = create("Frame")({
		Name = "DamageBar",
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 1, -- Bottom layer (White catch-up)
	})

	local healingBar = create("Frame")({
		Name = "HealingBar",
		BackgroundColor3 = Color3.fromRGB(90, 255, 100),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 2, -- Middle layer (Green prediction)
	})

	local mainBar = create("Frame")({
		Name = "MainBar",
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 3, -- Top layer (Red actual health)

		create("UIGradient")({
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 17, 73)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 10, 50)),
			}),
		}),
	})

	local textLabel = create("TextLabel")({
		Name = "HealthText",
		BackgroundTransparency = 1,
		FontFace = Font.new("rbxassetid://12187371840", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0, 0),
		Text = "100 / 100",
		TextColor3 = Color3.new(1, 1, 1),
		TextScaled = true,
		ZIndex = 5,

		create("UIStroke")({
			StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
			Thickness = 0.08,
		}),
	})

	local function updateText()
		textLabel.Text = math.floor(currentHealthVal) .. " / " .. math.floor(maxHealthVal)
	end

	-- 3. Construct the UI Tree
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
			Position = UDim2.fromScale(0.5, 0.965),
			Size = UDim2.fromScale(0.375, 0.225),

			create("UIListLayout")({
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				Padding = UDim.new(0.15, 0),
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Bottom,
			}),

			create("Frame")({
				Name = "HealthBarContainer",
				BackgroundColor3 = Color3.fromRGB(20, 20, 20),
				BorderSizePixel = 0,
				LayoutOrder = 1,
				Size = UDim2.fromScale(1, 0.175),
				ClipsDescendants = true,

				create("UIStroke")({
					LineJoinMode = Enum.LineJoinMode.Bevel,
					StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
					Thickness = 0.1,
				}),

				create("UICorner")({ CornerRadius = UDim.new(0.2, 0) }),

				damageBar,
				healingBar,
				mainBar,
				textLabel,
			}),

			-- Abilities frame (placeholder)
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

		SetMaxHealth = function(newMax: number)
			maxHealthVal = newMax
			updateText()
			local alpha = math.clamp(currentHealthVal / maxHealthVal, 0, 1)
			mainBar.Size = UDim2.fromScale(alpha, 1)
			damageBar.Size = UDim2.fromScale(alpha, 1)
			healingBar.Size = UDim2.fromScale(alpha, 1)
		end,

		SetCurrentHealth = function(newHealth: number)
			currentHealthVal = math.clamp(newHealth, 0, maxHealthVal)
			updateText()

			local currentVisual = mainBar.Size.X.Scale
			local targetScale = currentHealthVal / maxHealthVal

			if targetScale < currentVisual then
				local debrisScale = math.max(currentVisual, healingBar.Size.X.Scale)
				mainBar.Size = UDim2.fromScale(targetScale, 1)
				damageBar.Size = UDim2.fromScale(debrisScale, 1)
				healingBar.Size = UDim2.fromScale(targetScale, 1)

				if healingTask then task.cancel(healingTask) end
				if healingTween then healingTween:Cancel() end

				if damageTask then task.cancel(damageTask) end
				damageTask = task.delay(ANIM_DELAY, function()
					TweenService:Create(damageBar, TWEEN_INFO, { Size = UDim2.fromScale(targetScale, 1) }):Play()
				end)
			elseif targetScale > currentVisual then
				healingBar.Size = UDim2.fromScale(targetScale, 1)
				damageBar.Size = UDim2.fromScale(targetScale, 1)
				if damageTask then task.cancel(damageTask) end

				if healingTask then task.cancel(healingTask) end
				healingTask = task.delay(ANIM_DELAY, function()
					healingTween = TweenService:Create(mainBar, TWEEN_INFO, { Size = UDim2.fromScale(targetScale, 1) })
					healingTween:Play()
				end)
			end
		end,

		AddAbility = function() end,
	}
end
