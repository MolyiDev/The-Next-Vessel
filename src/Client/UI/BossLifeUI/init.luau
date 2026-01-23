local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Fluid = require(ReplicatedStorage.Shared.Utils.Fluid)

export type BossLifeUIReturn = {
	UI: any,
	SetMaxHealth: (newMax: number) -> (),
	SetCurrentHealth: (newHealth: number) -> (),
	Appear: () -> (),
	Disappear: () -> (),
}

local ANIM_DELAY = 0.25
local TWEEN_INFO = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local create = Fluid.create
local source = Fluid.source
local derive = Fluid.derive
local spring = Fluid.spring

return function(): BossLifeUIReturn
	local transparencyTarget = source(1)
	local transparency = spring(transparencyTarget, 10, 0.8)
	local strokeTransparency = derive(function()
		local t = transparency()
		return math.min(1, t / 0.85)
	end)

	local currentHealthVal = 100
	local maxHealthVal = 100

	local damageTask: thread? = nil
	local healingTask: thread? = nil
	local healingTween: Tween? = nil

	local damageBar = create("Frame")({
		Name = "DamageBar",
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = transparency,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 1,
	})

	local healingBar = create("Frame")({
		Name = "HealingBar",
		BackgroundColor3 = Color3.fromRGB(90, 255, 100),
		BackgroundTransparency = transparency,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 2,
	})

	local mainBar = create("Frame")({
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

	local textLabel = create("TextLabel")({
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

	local function updateText()
		textLabel.Text = math.floor(currentHealthVal) .. " / " .. math.floor(maxHealthVal)
	end

	-- 3. Construct the UI Tree
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

			create("Frame")({
				Name = "HealthBarContainer",
				BackgroundColor3 = Color3.fromRGB(20, 20, 20),
				BackgroundTransparency = transparency,
				BorderSizePixel = 0,
				LayoutOrder = 1,
				Size = UDim2.fromScale(1, 0.175),
				ClipsDescendants = true,

				create("UIStroke")({
					LineJoinMode = Enum.LineJoinMode.Bevel,
					StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
					Transparency = strokeTransparency,
					Thickness = 0.1,
				}),

				create("UICorner")({ CornerRadius = UDim.new(0.2, 0) }),

				damageBar,
				healingBar,
				mainBar,
				textLabel,
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

		Appear = function()
			transparencyTarget(0)
		end,
		Disappear = function()
			transparencyTarget(1)
		end,
	}
end
