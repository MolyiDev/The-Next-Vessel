local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local Workspace = game:GetService("Workspace")
local TweensController = require(script.Parent.TweensController)
local TimerUI = require(StarterPlayer.StarterPlayerScripts.Client.UI.TimerUI)
local Ignis = require(ReplicatedStorage.Packages.Ignis)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Fluid = require(ReplicatedStorage.Shared.Utils.Fluid)
local Tools = require(ReplicatedStorage.Shared.Utils.Tools)

local DEFAULT_GRAVITY = 196.2

local TimeController = {}
TimeController.TimeScaleChanged = Signal.new()
TimeController.FIXED_DELTA_TIME = 1 / 60
TimeController.TimeScale = 1

TimeController.Timer = 0
TimeController.Checkpoint = 0
TimeController.IsBossVulnerable = false
TimeController.Paused = true
TimeController.GameplayPaused = false

local targetTimeScale = 1
local startScale = 1
local tweenDuration = 0
local tweenElapsed = 0
local isTweening = false

local UI: TimerUI.TimerUIReturn

Fluid.mount(function()
	UI = TimerUI()
	return UI.UI
end, Players.LocalPlayer:WaitForChild("PlayerGui"))

local function setTimeScale(value: number)
	TimeController.TimeScale = value
	Workspace.Gravity = DEFAULT_GRAVITY * (value * value)
	TimeController.TimeScaleChanged:Fire(value)
end

RunService.Heartbeat:Connect(function(dt)
	if isTweening then
		tweenElapsed += dt
		local alpha = math.clamp(tweenElapsed / tweenDuration, 0, 1)
		local current = Tools.Lerp(startScale, targetTimeScale, alpha)
		setTimeScale(current)
		if alpha >= 1 then isTweening = false end
	end

	if TimeController.Paused then return end

	if not TimeController.GameplayPaused then
		local delta = dt * TimeController.TimeScale
		TimeController.Timer += delta

		local currentMinute = math.floor(TimeController.Timer / 60)
		if currentMinute > math.floor(TimeController.Checkpoint / 60) then
			TimeController.Checkpoint = currentMinute * 60
		end
	end

	TimeController.IsBossVulnerable = TimeController.Timer >= 300
	UI.SetTime(TimeController.Timer)
end)

function TimeController.PlayTimer()
	TimeController.Paused = false
end

function TimeController.PauseTimer()
	TimeController.Paused = true
end

function TimeController.SetGameplayPaused(paused: boolean)
	if paused then
		TweensController.SetImmobile(true)
	else
		TweensController.SetImmobile(false)
	end

	TimeController.GameplayPaused = paused
end

function TimeController.AppearTimer()
	UI.Appear()
end

function TimeController.DisappearTimer()
	UI.Disappear()
end

function TimeController.ResetTimer()
	TimeController.Timer = TimeController.Checkpoint
	UI.SetTime(TimeController.Checkpoint)
end

function TimeController.TweenTimeScale(target: number, duration: number?)
	duration = duration or 0

	if duration <= 0 then
		isTweening = false
		setTimeScale(target)
		return
	end

	startScale = TimeController.TimeScale
	targetTimeScale = target
	tweenDuration = duration :: any
	tweenElapsed = 0
	isTweening = true
end

function TimeController.GetDeltaTime(dt: number)
	if TimeController.GameplayPaused then return 0 end
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
