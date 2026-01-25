local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Ignis = require(ReplicatedStorage.Packages.Ignis)
local Fluid = require(ReplicatedStorage.Shared.Utils.Fluid)
local EAssets = require(ReplicatedStorage.Types.Enums.EAssets)
local EUpgrades = require(ReplicatedStorage.Types.Enums.EUpgrades)
local AbilitiesUI = require(script.Parent.Parent.UI.AbilitiesUI)
local DashController = require(script.Parent.DashController)
local ParryController = require(script.Parent.ParryController)
local TimeController = require(script.Parent.TimeController)
local UpgradesController = require(script.Parent.UpgradesController)

local AbilitiesController = {}
local AbilityIds = {
	Projectile = 0,
	Dash = 0,
	Parry = 0,
	SlowTime = 0,
}

local SlowTime = {
	Cooldown = 15,
	Duration = 2,
	LastUse = 0,
}

local UI: AbilitiesUI.AbilitiesUIReturn

Fluid.mount(function()
	UI = AbilitiesUI()
	return UI.UI
end, Players.LocalPlayer:WaitForChild("PlayerGui"))

function AbilitiesController.Update()
	if not UI then return end

	local ammo = DashController.StoredProjectiles or 0
	UI.SetAmount(AbilityIds.Projectile, ammo)

	local maxProjectiles = 1 + UpgradesController.GetUpgradeLevel(EUpgrades.Projectiles)
	if ammo < maxProjectiles then
		local current = DashController.AutoProjectilesCurrentCooldown
		local max = DashController.CurrentMaxRegenTime or 2
		if max > 0 then UI.SetCooldown(AbilityIds.Projectile, current / max) end
	else
		UI.SetCooldown(AbilityIds.Projectile, 0)
	end

	if AbilityIds.Dash ~= 0 then
		local dashTime = DashController.LastDashTime
		local dashCD = 1.5
		local timeSince = time() - dashTime
		if timeSince < dashCD then
			UI.SetCooldown(AbilityIds.Dash, 1 - (timeSince / dashCD))
		else
			UI.SetCooldown(AbilityIds.Dash, 0)
		end
	end

	if AbilityIds.Parry ~= 0 then
		local releaseTime = ParryController.ReleaseTime
		local parryCD = 0.2
		local timeSince = time() - releaseTime
		if timeSince < parryCD then
			UI.SetCooldown(AbilityIds.Parry, 1 - (timeSince / parryCD))
		else
			UI.SetCooldown(AbilityIds.Parry, 0)
		end
	end

	if AbilityIds.SlowTime ~= 0 then
		local timeSince = time() - SlowTime.LastUse
		if timeSince < SlowTime.Cooldown then
			UI.SetCooldown(AbilityIds.SlowTime, 1 - (timeSince / SlowTime.Cooldown))
		else
			UI.SetCooldown(AbilityIds.SlowTime, 0)
		end
	end
end

function AbilitiesController.AddDash()
	AbilityIds.Dash = UI.AddAbility(EAssets.DashIcon, EAssets.KeyQ, false)
end

function AbilitiesController.AddParry()
	AbilityIds.Parry = UI.AddAbility(EAssets.ParryIcon, EAssets.KeyRightClick, false)
end

function AbilitiesController.AddSlowTime()
	AbilityIds.SlowTime = UI.AddAbility(EAssets.ReflexesIcon, EAssets.Key1, false)
end

AbilityIds.Projectile = UI.AddAbility(EAssets.ProjectileIcon, EAssets.KeyLeftClick, true)

UpgradesController.OnUpgradesChanged:Connect(function(id, level, isAdded)
	if isAdded then
		if id == EUpgrades.Dash and AbilityIds.Dash == 0 then
			AbilitiesController.AddDash()
		elseif id == EUpgrades.Parry and AbilityIds.Parry == 0 then
			AbilitiesController.AddParry()
		elseif id == EUpgrades.SlowTime and AbilityIds.SlowTime == 0 then
			AbilitiesController.AddSlowTime()
		end
	else
		if id == EUpgrades.Dash and level == 0 then
			UI.RemoveAbility(AbilityIds.Dash)
			AbilityIds.Dash = 0
		elseif id == EUpgrades.Parry and level == 0 then
			UI.RemoveAbility(AbilityIds.Parry)
			AbilityIds.Parry = 0
		elseif id == EUpgrades.SlowTime and level == 0 then
			UI.RemoveAbility(AbilityIds.SlowTime)
			AbilityIds.SlowTime = 0
		end
	end
end)

function AbilitiesController.Appear()
	UI.Appear()
end

function AbilitiesController.Disappear()
	UI.Disappear()
end

RunService.Heartbeat:Connect(function()
	AbilitiesController.Update()
end)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp or input.KeyCode ~= Enum.KeyCode.One then return end
	if AbilityIds.SlowTime == 0 then return end

	local timeNow = time()
	if (timeNow - SlowTime.LastUse) < SlowTime.Cooldown then return end

	SlowTime.LastUse = timeNow

	local level = UpgradesController.GetUpgradeLevel(EUpgrades.SlowTime)
	local duration = SlowTime.Duration * (1 + (level * 0.1))

	TimeController.Slow(0.2, duration)
end)

return Ignis.Register(AbilitiesController)
