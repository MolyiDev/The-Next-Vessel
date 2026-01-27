local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Tools = require(ReplicatedStorage.Shared.Utils.Tools)

local BAR_COLOR = Color3.new(0.1, 0.1, 0.1)
local BAR_GAP = 0.001
local RAINBOW_SPEED = 0.4
local TWEEN_INFO = TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local FADE_INFO = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local XP_COLOR = Color3.new(0, 0.5, 1)

local RAINBOW_BASE_TIMES = { 0, 1 / 6, 2 / 6, 3 / 6, 4 / 6, 5 / 6, 1 }
local FILL_KEYPOINT_COUNT = #RAINBOW_BASE_TIMES -- 7
local TOTAL_KEYPOINT_COUNT = FILL_KEYPOINT_COUNT + 2 -- 9

local rainbowConnection: RBXScriptConnection?
local gradientChanging: { [UIGradient]: RBXScriptConnection } = {}

export type SoulsBarUI = {
	SetXP: (xp: number, maxXp: number) -> (),
	SetRainbow: (value: boolean) -> (),
	SetTextLevelUp: (value: boolean) -> (),
	Appear: () -> (),
	Disappear: () -> (),
}

function createBarGradient(percentage: number, fillColors: { Color3 }, emptyColor: Color3)
	local keypoints = {}

	local lastFillColor = fillColors[FILL_KEYPOINT_COUNT]

	for i = 1, FILL_KEYPOINT_COUNT do
		local baseTime = RAINBOW_BASE_TIMES[i]
		local color = fillColors[i]
		keypoints[#keypoints + 1] = ColorSequenceKeypoint.new(baseTime * percentage, color)
	end

	local gapTime = math.min(percentage + BAR_GAP, 1)
	local finalEmptyColor = emptyColor

	if percentage >= (1 - BAR_GAP) then
		gapTime = 1
		finalEmptyColor = lastFillColor
	end

	keypoints[#keypoints + 1] = ColorSequenceKeypoint.new(gapTime, finalEmptyColor)
	keypoints[#keypoints + 1] = ColorSequenceKeypoint.new(1, finalEmptyColor)

	return ColorSequence.new(keypoints)
end

local XP_COLORS_TABLE = {}
for _ = 1, FILL_KEYPOINT_COUNT do
	XP_COLORS_TABLE[#XP_COLORS_TABLE + 1] = XP_COLOR
end

local BAR_COLORS_TABLE = {}
for _ = 1, FILL_KEYPOINT_COUNT do
	BAR_COLORS_TABLE[#BAR_COLORS_TABLE + 1] = BAR_COLOR
end

local RAINBOW_COLORS_TABLE = {}
for _, time in ipairs(RAINBOW_BASE_TIMES) do
	RAINBOW_COLORS_TABLE[#RAINBOW_COLORS_TABLE + 1] = Color3.fromHSV(time, 1, 1)
end

local GRADIENT_COLOR_EMPTY = createBarGradient(0, BAR_COLORS_TABLE, BAR_COLOR)
local GRADIENT_COLOR_RAINBOW_FULL = createBarGradient(1, RAINBOW_COLORS_TABLE, BAR_COLOR)

function tweenGradient(
	gradient: UIGradient,
	tweenInfo: TweenInfo,
	finalGradient: ColorSequence,
	onComplete: (() -> ())?
)
	local connection = gradientChanging[gradient]
	if connection then connection:Disconnect() end

	local startGradient = gradient.Color.Keypoints

	if #startGradient ~= #finalGradient.Keypoints then
		gradient.Color = finalGradient
		if onComplete then onComplete() end
		return
	end

	local timeElapsed = 0

	connection = RunService.RenderStepped:Connect(function(dt)
		timeElapsed += dt

		if timeElapsed >= tweenInfo.Time then
			gradient.Color = finalGradient
			connection:Disconnect()
			gradientChanging[gradient] = nil
			if onComplete then onComplete() end
			return
		end

		local alpha = timeElapsed / tweenInfo.Time
		alpha = TweenService:GetValue(alpha, tweenInfo.EasingStyle, tweenInfo.EasingDirection)

		local newKeypoints = {}

		for i = 1, #startGradient do
			local startPoint = startGradient[i]
			local endPoint = finalGradient.Keypoints[i]

			local newColor = Tools.LerpColor(startPoint.Value, endPoint.Value, alpha)
			local newTime = Tools.Lerp(startPoint.Time, endPoint.Time, alpha)

			newKeypoints[#newKeypoints + 1] = ColorSequenceKeypoint.new(
				math.clamp(newTime, 0, 1),
				Color3.new(math.clamp(newColor.R, 0, 1), math.clamp(newColor.G, 0, 1), math.clamp(newColor.B, 0, 1))
			)
		end

		gradient.Color = ColorSequence.new(newKeypoints)
	end)

	gradientChanging[gradient] = connection
end

function SoulsBarUI(parent: PlayerGui | Frame)
	local screenGui = Tools.CreateGenericScreenGui("LevelBarUI")

	local levelBar = Instance.new("Frame")
	levelBar.Name = "SoulsBar"
	levelBar.AnchorPoint = Vector2.new(0.5, 1)
	levelBar.Position = UDim2.fromScale(0.5, 1)
	levelBar.Size = UDim2.fromScale(1, 0.01)
	levelBar.BackgroundTransparency = 1
	levelBar.Parent = screenGui

	local gradient = Instance.new("UIGradient")
	gradient.Color = GRADIENT_COLOR_EMPTY
	gradient.Parent = levelBar

	local stroke = Instance.new("UIStroke")
	stroke.LineJoinMode = Enum.LineJoinMode.Miter
	stroke.StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize
	stroke.Thickness = 0.25
	stroke.Transparency = 1
	stroke.Parent = levelBar

	local xFrame = Instance.new("Frame")
	xFrame.Name = "X"
	xFrame.AnchorPoint = Vector2.new(1, 1)
	xFrame.BackgroundTransparency = 1
	xFrame.Position = UDim2.fromScale(0.994786, 0.980741)
	xFrame.Size = UDim2.fromScale(0.3, 0.035)
	xFrame.Parent = screenGui

	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "TextLabel"
	textLabel.AnchorPoint = Vector2.new(1, 1)
	textLabel.BackgroundTransparency = 1
	textLabel.FontFace = Font.new("rbxassetid://12187371840", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
	textLabel.Position = UDim2.fromScale(1, 1)
	textLabel.RichText = true
	textLabel.Size = UDim2.fromScale(1, 1)
	textLabel.Text = "[X] to SACRIFICE Souls"
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextScaled = true
	textLabel.TextStrokeTransparency = 1
	textLabel.TextTransparency = 1
	textLabel.TextXAlignment = Enum.TextXAlignment.Right
	textLabel.Parent = xFrame

	screenGui.Parent = parent

	-- State tracking
	local isUiVisible = false
	local isTextActive = false

	local rainbowTime = 0
	local currentXPGradient = GRADIENT_COLOR_EMPTY

	local function startRainbowLoop()
		if rainbowConnection then return end

		rainbowConnection = RunService.RenderStepped:Connect(function(dt: number)
			rainbowTime += dt * RAINBOW_SPEED

			local newKeypoints = {}
			local lastHue = 0

			for _, baseTime in ipairs(RAINBOW_BASE_TIMES) do
				local hue = (baseTime - rainbowTime) % 1
				newKeypoints[#newKeypoints + 1] = ColorSequenceKeypoint.new(baseTime, Color3.fromHSV(hue, 1, 1))
				lastHue = hue
			end

			local lastColor = Color3.fromHSV(lastHue, 1, 1)
			newKeypoints[#newKeypoints + 1] = ColorSequenceKeypoint.new(1, lastColor)
			newKeypoints[#newKeypoints + 1] = ColorSequenceKeypoint.new(1, lastColor)

			gradient.Color = ColorSequence.new(newKeypoints)
		end)
	end

	local function updateTextState()
		local targetTransparency = (isUiVisible and isTextActive) and 0 or 1

		TweenService:Create(textLabel, FADE_INFO, {
			TextTransparency = targetTransparency,
			TextStrokeTransparency = targetTransparency,
		}):Play()
	end

	return {
		SetXP = function(xp: number, maxXp: number)
			if rainbowConnection then
				rainbowConnection:Disconnect()
				rainbowConnection = nil
			end
			rainbowTime = 0

			if #gradient.Color.Keypoints ~= TOTAL_KEYPOINT_COUNT then gradient.Color = GRADIENT_COLOR_EMPTY end

			local percentage = math.clamp(xp / maxXp, 0, 1)
			local finalGradient = createBarGradient(percentage, XP_COLORS_TABLE, BAR_COLOR)
			currentXPGradient = finalGradient

			tweenGradient(gradient, TWEEN_INFO, finalGradient, nil)
		end,

		SetTextLevelUp = function(value)
			isTextActive = value
			updateTextState()
		end,

		Appear = function()
			isUiVisible = true

			TweenService:Create(levelBar, FADE_INFO, { BackgroundTransparency = 0 }):Play()
			TweenService:Create(stroke, FADE_INFO, { Transparency = 0 }):Play()

			updateTextState()
		end,

		Disappear = function()
			isUiVisible = false

			TweenService:Create(levelBar, FADE_INFO, { BackgroundTransparency = 1 }):Play()
			TweenService:Create(stroke, FADE_INFO, { Transparency = 1 }):Play()

			updateTextState() -- This will force text to hide because isUiVisible is now false
		end,

		SetRainbow = function(value: boolean)
			if value then
				if rainbowConnection then return end

				local connection = gradientChanging[gradient]
				if connection then
					connection:Disconnect()
					gradientChanging[gradient] = nil
				end

				local currentPercentage = 0
				if #gradient.Color.Keypoints == TOTAL_KEYPOINT_COUNT then
					currentPercentage = gradient.Color.Keypoints[FILL_KEYPOINT_COUNT].Time
				else
					gradient.Color = GRADIENT_COLOR_EMPTY
					currentPercentage = 0
				end

				local partialRainbowGradient = createBarGradient(currentPercentage, RAINBOW_COLORS_TABLE, BAR_COLOR)

				gradient.Color = partialRainbowGradient
				tweenGradient(gradient, TWEEN_INFO, GRADIENT_COLOR_RAINBOW_FULL, function()
					startRainbowLoop()
				end)
			else
				if not rainbowConnection then return end

				rainbowConnection:Disconnect()
				rainbowConnection = nil
				rainbowTime = 0

				tweenGradient(gradient, TWEEN_INFO, currentXPGradient, nil)
			end
		end,
	} :: SoulsBarUI
end

return SoulsBarUI
