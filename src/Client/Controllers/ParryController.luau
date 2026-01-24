local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Signal = require(ReplicatedStorage.Packages.Signal)
local CameraController = require(script.Parent.CameraController)
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
ParryController.OnParryUsed = Signal.new()
ParryController.IsCharging = false
ParryController.ChargeStartTime = 0
ParryController.PressTime = 0
ParryController.ReleaseTime = 0
ParryController.StoredMultiplier = BASE_MULTIPLIER
ParryController.CurrentTarget = nil :: BasePart?

local ChargeTask: thread?
local ResumeTask: thread?

function ParryController.IsParrying()
	local timeNow = time()
	local isPressParry = (timeNow - ParryController.PressTime) <= PARRY_DURATION
	local isReleaseParry = (timeNow - ParryController.ReleaseTime) <= PARRY_DURATION

	return isPressParry or isReleaseParry
end

function ParryController.GetChargeMultiplier()
	return ParryController.StoredMultiplier
end

function ParryController.SuccessfulParry(wasBreaked: boolean?)
	local timeNow = time()

	ParryController.PressTime = timeNow
	ParryController.ReleaseTime = timeNow - PARRY_COOLDOWN - 0.1

	if not wasBreaked then
		SoundsController.PlayCharacter(ESounds.Parry)

		if ResumeTask then task.cancel(ResumeTask) end

		TimeController.Stop()

		ResumeTask = task.delay(0.075, function()
			TimeController.Resume()
			ResumeTask = nil
		end)
	end

	CameraController.Shake(2, 1, 0.8, Vector3.new(0.2, 0.2, 0.2), Vector3.zero, 0.2)
end

UserInputService.InputBegan:Connect(function(input, gp)
	if gp or input.UserInputType ~= Enum.UserInputType.MouseButton2 then return end
	if not UpgradesController.HasUpgrade(EUpgrades.Parry) then return end

	local timeNow = time()

	if (timeNow - ParryController.ReleaseTime) < PARRY_COOLDOWN then return end
	if (timeNow - ParryController.PressTime) < (PARRY_DURATION + PARRY_COOLDOWN) then return end

	ParryController.PressTime = timeNow
	if ChargeTask then task.cancel(ChargeTask) end

	ChargeTask = task.delay(PARRY_DURATION, function()
		ParryController.IsCharging = true
		ParryController.ChargeStartTime = time()
		-- TODO: Play "Charge" Loop Animation/Sound
	end)
end)

UserInputService.InputEnded:Connect(function(input, gp)
	if gp or input.UserInputType ~= Enum.UserInputType.MouseButton2 then return end
	if not UpgradesController.HasUpgrade(EUpgrades.Parry) then return end

	if ChargeTask then
		task.cancel(ChargeTask)
		ChargeTask = nil
	end

	if not ParryController.IsCharging then
		ParryController.ReleaseTime = time()
		return
	end

	local duration = time() - ParryController.ChargeStartTime
	local alpha = math.clamp(duration / FULL_CHARGE_TIME, 0, 1)

	ParryController.StoredMultiplier = BASE_MULTIPLIER + (alpha * (MAX_MULTIPLIER - BASE_MULTIPLIER))
	ParryController.IsCharging = false
	ParryController.ReleaseTime = time()

	-- TODO: Play "Swing" Animation
	-- TODO: Stop Charge Sound, Play Swing Sound
end)

return ParryController
