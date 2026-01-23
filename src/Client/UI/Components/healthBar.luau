local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Fluid = require(ReplicatedStorage.Shared.Utils.Fluid)
local create = Fluid.create
local derive = Fluid.derive

local ANIM_DELAY = 0.25
local TWEEN_INFO = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

type HealthBarProps = {
	Transparency: Fluid.Source<number>,
	LayoutOrder: number?,
}

return function(Props: HealthBarProps)
	local transparency = Props.Transparency
	local strokeTransparency = derive(function()
		local t = transparency()
		return math.min(1, t / 0.85)
	end)

	local CurrentHealthVal = 100
	local MaxHealthVal = 100

	local DamageTask: thread? = nil
	local HealingTask: thread? = nil
	local HealingTween: Tween? = nil

	local DamageBar = create("Frame")({
		Name = "DamageBar",
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = transparency,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 1,
	})

	local HealingBar = create("Frame")({
		Name = "HealingBar",
		BackgroundColor3 = Color3.fromRGB(90, 255, 100),
		BackgroundTransparency = transparency,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 2,
	})

	local MainBar = create("Frame")({
		Name = "MainBar",
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = transparency,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 3,

		create("UIGradient")({
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 17, 73)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 10, 50)),
			}),
		}),
	})

	local TextLabel = create("TextLabel")({
		Name = "HealthText",
		BackgroundTransparency = 1,
		FontFace = Font.new("rbxassetid://12187371840", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0, 0),
		Text = "100 / 100",
		TextColor3 = Color3.new(1, 1, 1),
		TextScaled = true,
		TextTransparency = transparency,
		ZIndex = 5,

		create("UIStroke")({
			StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
			Thickness = 0.08,
			Transparency = strokeTransparency,
		}),
	})

	local function UpdateText()
		TextLabel.Text = math.floor(CurrentHealthVal) .. " / " .. math.floor(MaxHealthVal)
	end

	local Frame = create("Frame")({
		Name = "HealthBarContainer",
		BackgroundColor3 = Color3.fromRGB(20, 20, 20),
		BackgroundTransparency = transparency,
		BorderSizePixel = 0,
		LayoutOrder = Props.LayoutOrder or 1,
		Size = UDim2.fromScale(1, 0.175),
		ClipsDescendants = true,

		create("UIStroke")({
			LineJoinMode = Enum.LineJoinMode.Bevel,
			StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
			Transparency = strokeTransparency,
			Thickness = 0.1,
		}),

		create("UICorner")({ CornerRadius = UDim.new(0.2, 0) }),

		DamageBar,
		HealingBar,
		MainBar,
		TextLabel,
	})

	return {
		Frame = Frame,

		SetMaxHealth = function(NewMax: number)
			MaxHealthVal = NewMax
			UpdateText()
			local Alpha = math.clamp(CurrentHealthVal / MaxHealthVal, 0, 1)
			MainBar.Size = UDim2.fromScale(Alpha, 1)
			DamageBar.Size = UDim2.fromScale(Alpha, 1)
			HealingBar.Size = UDim2.fromScale(Alpha, 1)
		end,

		SetCurrentHealth = function(NewHealth: number)
			CurrentHealthVal = math.clamp(NewHealth, 0, MaxHealthVal)
			UpdateText()

			local CurrentVisual = MainBar.Size.X.Scale
			local TargetScale = CurrentHealthVal / MaxHealthVal

			if TargetScale < CurrentVisual then
				local DebrisScale = math.max(CurrentVisual, HealingBar.Size.X.Scale)
				MainBar.Size = UDim2.fromScale(TargetScale, 1)
				DamageBar.Size = UDim2.fromScale(DebrisScale, 1)
				HealingBar.Size = UDim2.fromScale(TargetScale, 1)

				if HealingTask then task.cancel(HealingTask) end
				if HealingTween then HealingTween:Cancel() end

				if DamageTask then task.cancel(DamageTask) end
				DamageTask = task.delay(ANIM_DELAY, function()
					TweenService:Create(DamageBar, TWEEN_INFO, { Size = UDim2.fromScale(TargetScale, 1) }):Play()
				end)
			elseif TargetScale > CurrentVisual then
				HealingBar.Size = UDim2.fromScale(TargetScale, 1)
				DamageBar.Size = UDim2.fromScale(TargetScale, 1)
				if DamageTask then task.cancel(DamageTask) end

				if HealingTask then task.cancel(HealingTask) end
				HealingTask = task.delay(ANIM_DELAY, function()
					HealingTween = TweenService:Create(MainBar, TWEEN_INFO, { Size = UDim2.fromScale(TargetScale, 1) })
					if HealingTween then HealingTween:Play() end
				end)
			end
		end,
	}
end
