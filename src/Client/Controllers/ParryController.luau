local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ESounds = require(ReplicatedStorage.Types.Enums.ESounds)
local SoundsController = require(script.Parent.SoundsController)
local TimeController = require(script.Parent.TimeController)
local EUpgrades = require(ReplicatedStorage.Types.Enums.EUpgrades)
local UpgradesController = require(script.Parent.UpgradesController)

local FULL_CHARGE_TIME = 3.0
local PARRY_DURATION = 0.25
local PARRY_COOLDOWN = 0.2

local BASE_MULTIPLIER = 1.1
local MAX_MULTIPLIER = 2.5

local ParryController = {}
ParryController.IsCharging = false
ParryController.ChargeStartTime = 0
ParryController.PressTime = 0 -- Time of initial click (Defensive window)
ParryController.ReleaseTime = 0 -- Time of release swing (Offesive window)
ParryController.StoredMultiplier = BASE_MULTIPLIER

local ChargeTask: thread?

function ParryController.IsParrying()
	local timeNow = time()
	local isPressParry = (timeNow - ParryController.PressTime) <= PARRY_DURATION
	local isReleaseParry = (timeNow - ParryController.ReleaseTime) <= PARRY_DURATION

	return isPressParry or isReleaseParry
end

function ParryController.GetChargeMultiplier()
	return ParryController.StoredMultiplier
end

function ParryController.SuccessfulParry()
	local timeNow = time()

	-- 1. Reset the "Press" timer to NOW.
	-- This forces IsParrying() to return true for another PARRY_DURATION (0.25s).
	-- This allows automatic chaining against rapid-fire projectiles.
	ParryController.PressTime = timeNow

	-- 2. Optional: Reset ReleaseTime to clear any Cooldown restrictions for the next click
	-- Set it to a generic past time so (timeNow - ReleaseTime) > PARRY_COOLDOWN
	ParryController.ReleaseTime = timeNow - PARRY_COOLDOWN - 0.1

	SoundsController.PlayCharacter(ESounds.Parry)

	TimeController.Stop()
	task.delay(0.05, function()
		TimeController.Resume()
	end)
end

UserInputService.InputBegan:Connect(function(input, gp)
	if gp or input.UserInputType ~= Enum.UserInputType.MouseButton2 then return end
	-- if not UpgradesController.HasUpgrade(EUpgrades.Parry) then return end
	local timeNow = time()

	-- Cooldown check: Prevent spamming if we just finished a swing
	if (timeNow - ParryController.ReleaseTime) < PARRY_COOLDOWN then return end

	-- 1. Immediate Parry Response (Responsive)
	ParryController.PressTime = timeNow

	-- 2. Schedule Charge State
	-- If button is held past PARRY_DURATION, we switch to Charging state
	if ChargeTask then task.cancel(ChargeTask) end

	ChargeTask = task.delay(PARRY_DURATION, function()
		ParryController.IsCharging = true
		ParryController.ChargeStartTime = time()
		-- TODO: Play "Charge" Loop Animation/Sound
	end)
end)

UserInputService.InputEnded:Connect(function(input, gp)
	if gp or input.UserInputType ~= Enum.UserInputType.MouseButton2 then return end

	if ChargeTask then
		task.cancel(ChargeTask)
		ChargeTask = nil
	end

	-- If we were not charging yet, it was just a quick parry (Tap)
	if not ParryController.IsCharging then return end

	-- If we WERE charging, calculate multiplier and swing
	local duration = time() - ParryController.ChargeStartTime
	local alpha = math.clamp(duration / FULL_CHARGE_TIME, 0, 1)

	ParryController.StoredMultiplier = BASE_MULTIPLIER + (alpha * (MAX_MULTIPLIER - BASE_MULTIPLIER))
	ParryController.IsCharging = false
	ParryController.ReleaseTime = time() -- Triggers the "Swing" parry window

	-- TODO: Play "Swing" Animation
	-- TODO: Stop Charge Sound, Play Swing Sound
end)

return ParryController
