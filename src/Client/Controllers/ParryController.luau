local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ESounds = require(ReplicatedStorage.Types.Enums.ESounds)
local SoundsController = require(script.Parent.SoundsController)
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
ParryController.ReleaseTime = 0
ParryController.StoredMultiplier = BASE_MULTIPLIER

function ParryController.IsParrying()
	return (time() - ParryController.ReleaseTime) <= PARRY_DURATION
end

function ParryController.GetChargeMultiplier()
	return ParryController.StoredMultiplier
end

function ParryController.StartCharge()
	if ParryController.IsCharging then return end
	if (time() - ParryController.ReleaseTime) < PARRY_COOLDOWN then return end

	ParryController.IsCharging = true
	ParryController.ChargeStartTime = time()
	-- TODO: Play "Charge" Loop Animation/Sound
end

function ParryController.ReleaseParry()
	if not ParryController.IsCharging then return end

	-- 1. Calculate charge based on how long we held it
	local duration = time() - ParryController.ChargeStartTime
	local alpha = math.clamp(duration / FULL_CHARGE_TIME, 0, 1)

	-- 2. Store the multiplier to be used if we hit something
	ParryController.StoredMultiplier = BASE_MULTIPLIER + (alpha * (MAX_MULTIPLIER - BASE_MULTIPLIER))

	-- 3. Change State: Stop Charging -> Start Parrying (Swing)
	ParryController.IsCharging = false
	ParryController.ReleaseTime = time()

	-- TODO: Play "Swing" Animation
	-- TODO: Stop Charge Sound, Play Swing Sound
end

function ParryController.SuccessfulParry()
	ParryController.LastParryTime = time()
	SoundsController.PlayCharacter(ESounds.Parry)
end

UserInputService.InputBegan:Connect(function(input, gp)
	if gp or input.UserInputType ~= Enum.UserInputType.MouseButton2 then return end
	-- if not UpgradesController.HasUpgrade(EUpgrades.Parry) then return end
	ParryController.StartCharge()
end)

UserInputService.InputEnded:Connect(function(input, gp)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then ParryController.ReleaseParry() end
end)

return ParryController
