local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Ignis = require(ReplicatedStorage.Packages.Ignis)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Tools = require(ReplicatedStorage.Shared.Utils.Tools)

local DEFAULT_GRAVITY = 196.2

local TimeController = {}
TimeController.TimeScaleChanged = Signal.new()
TimeController.FIXED_DELTA_TIME = 1 / 60
TimeController.TimeScale = 1

local targetTimeScale = 1
local startScale = 1
local tweenDuration = 0
local tweenElapsed = 0
local isTweening = false
local tweenStyle = Enum.EasingStyle.Quad
local tweenDir = Enum.EasingDirection.Out

local function setTimeScale(value: number)
	TimeController.TimeScale = value

	-- Adjust Physics Gravity: g' = g * s^2
	-- This keeps the jump height constant while extending the duration.
	-- If we didn't do this, lower gravity would result in higher jumps if velocity wasn't scaled.
	Workspace.Gravity = DEFAULT_GRAVITY * (value * value)

	TimeController.TimeScaleChanged:Fire(value)
end

RunService.Heartbeat:Connect(function(dt)
	if not isTweening then return end

	tweenElapsed += dt
	local alpha = math.clamp(tweenElapsed / tweenDuration, 0, 1)

	-- We use TweenService's GetValue for the easing math, or a simple lerp if preferred.
	-- Since we want to avoid TweenService instances, we can simple Lerp or use a helper.
	-- For simplicity in this loop, we'll use linear or simple curve if Tools has it,
	-- but here acts as a standard Lerp for robustness.

	local current = Tools.Lerp(startScale, targetTimeScale, alpha)
	setTimeScale(current)

	if alpha >= 1 then isTweening = false end
end)

function TimeController.TweenTimeScale(target: number, duration: number?)
	duration = duration or 0

	if duration <= 0 then
		isTweening = false
		setTimeScale(target)
		return
	end

	startScale = TimeController.TimeScale
	targetTimeScale = target
	tweenDuration = duration
	tweenElapsed = 0
	isTweening = true
end

function TimeController.GetDeltaTime(dt: number)
	return dt * TimeController.TimeScale
end

function TimeController.Stop(duration: number?)
	TimeController.TweenTimeScale(0, duration)
end

function TimeController.Resume(duration: number?)
	TimeController.TweenTimeScale(1, duration)
end

function TimeController.Slow(target: number, duration: number?)
	TimeController.TweenTimeScale(math.clamp(target, 0, 0.99), duration)
end

function TimeController.Fast(target: number, duration: number?)
	TimeController.TweenTimeScale(math.max(target, 1.01), duration)
end

return Ignis.Register(TimeController)
