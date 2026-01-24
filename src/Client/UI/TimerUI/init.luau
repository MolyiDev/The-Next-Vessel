local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fluid = require(ReplicatedStorage.Shared.Utils.Fluid)
local Tools = require(ReplicatedStorage.Shared.Utils.Tools)

export type TimerUIReturn = {
	UI: any,
	SetTime: (value: number) -> (),
}

local create = Fluid.create
local source = Fluid.source

local function formatTime(seconds: number): string
	local minutes = math.floor(seconds / 60)
	local secs = seconds % 60
	return string.format("%02d:%02d", minutes, secs)
end

return function(): TimerUIReturn
	local timerStr = source("00:00")

	local ui = create("ScreenGui")({
		Name = "TimerGui",
		ClipToDeviceSafeArea = false,
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,

		create("TextLabel")({
			Name = "Timer",
			AnchorPoint = Vector2.new(1, 0),
			BackgroundTransparency = 1,
			FontFace = Tools.FONT_SILKSCREEN_BOLD,
			Position = UDim2.fromScale(1, 0),
			Size = UDim2.fromScale(0.08, 0.065),
			Text = timerStr,
			TextColor3 = Color3.new(1, 1, 1),
			TextScaled = true,

			create("UITextSizeConstraint")({
				MaxTextSize = 35,
			}),

			create("UIStroke")({
				StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
				Thickness = 0.07,
			}),
		}),
	})

	return {
		UI = ui,
		SetTime = function(value: number)
			timerStr(formatTime(value))
		end,
	}
end
