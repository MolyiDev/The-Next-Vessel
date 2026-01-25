local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local Signal = require(ReplicatedStorage.Packages.Signal)
local HealthController = require(script.Parent.HealthController)
local MouseController = require(script.Parent.MouseController)
local Fluid = require(ReplicatedStorage.Shared.Utils.Fluid)
local UpgradeUI = require(StarterPlayer.StarterPlayerScripts.Client.UI.UpgradeUI)
local ERarity = require(ReplicatedStorage.Types.Enums.ERarity)
local EUpgrades = require(ReplicatedStorage.Types.Enums.EUpgrades)
local Promise = require(ReplicatedStorage.Shared.Utils.Promise)
local EAssets = require(ReplicatedStorage.Types.Enums.EAssets)

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Type: Percent (0.1 = 10%) or Flat (20 = +20)
local UPGRADE_SCALING = {
	[EUpgrades.Power] = { Type = "Flat", Amount = 1 },
	[EUpgrades.Health] = { Type = "Flat", Amount = 10 },
	[EUpgrades.Projectiles] = { Type = "Flat", Amount = 1 },
	[EUpgrades.Bounces] = { Type = "Flat", Amount = 1 },
	[EUpgrades.SlowTime] = { Type = "Percent", Amount = 0.10 },
	[EUpgrades.ProjectilesRegen] = { Type = "Percent", Amount = 0.10 },
}

local UPGRADES_NAME = {
	[EUpgrades.Power] = "Power",
	[EUpgrades.Health] = "Vitality",
	[EUpgrades.Projectiles] = "Projectiles",
	[EUpgrades.ProjectilesRegen] = "Projectiles Regen",
	[EUpgrades.Dash] = "Dash",
	[EUpgrades.DashGod] = "Dash God",
	[EUpgrades.Parry] = "Parry",
	[EUpgrades.Bounces] = "Bounces",
	[EUpgrades.TargetGod] = "Target God",
}

local UPGRADES_DESCRIPTION = {
	[EUpgrades.TargetGod] = "Automatically target the next enemy when the current one dies.",
	[EUpgrades.Power] = "Increases your attack damage.\n<font color='#FFA500'>Damage:</font> %s",
	[EUpgrades.Health] = "Increases your maximum health.\n<font color='#00FF7F'>Max Health:</font> %s",
	[EUpgrades.Projectiles] = "Increases the amount of projectiles you regenerate per cycle.\n<font color='#FFA500'>Amount:</font> %s",
	[EUpgrades.ProjectilesRegen] = "Reduces the time it takes to regenerate projectiles.\n<font color='#00FFFF'>Cooldown:</font> %s",
	[EUpgrades.Bounces] = "Attacks bounce to nearby enemies.\n<font color='#FFA500'>Bounces:</font> %s",
	[EUpgrades.SlowTime] = "Slows down enemies and projectiles.\n<font color='#00FFFF'>Duration:</font> %s",
	[EUpgrades.Dash] = "Unlocks <font color='#00FFFF'><b>Dash [Q]</b></font>.\nDash to become <b>invulnerable</b>. Move through projectiles to capture them.",
	[EUpgrades.DashGod] = "Allows you to change direction while dashing.",
	[EUpgrades.Parry] = "Unlocks <font color='#00FFFF'><b>Parry [Right Click]</b></font>.\nReflect damage back at enemies.",
}

local UPGRADES_IMAGES = {
	[EUpgrades.Power] = EAssets.PowerIcon,
	[EUpgrades.Health] = EAssets.HealthIcon,
	[EUpgrades.Projectiles] = EAssets.ProjectilesIcon,
	[EUpgrades.ProjectilesRegen] = EAssets.ProjectilesRegenIcon,
	[EUpgrades.Bounces] = EAssets.BouncesIcon,
	[EUpgrades.Dash] = EAssets.DashIcon,
	[EUpgrades.DashGod] = EAssets.DashGodIcon,
	[EUpgrades.Parry] = EAssets.ParryIcon,
	[EUpgrades.SlowTime] = EAssets.SlowTimeIcon,
	[EUpgrades.TargetGod] = EAssets.TargetGodIcon,
}

local STACKABLE_UPGRADES = {
	[EUpgrades.Power] = true,
	[EUpgrades.Health] = true,
	[EUpgrades.SlowTime] = true,
	[EUpgrades.Bounces] = true,
	[EUpgrades.Projectiles] = true,
	[EUpgrades.ProjectilesRegen] = true,
}

local UPGRADES_LIST = {
	EUpgrades.Power,
	EUpgrades.Health,
	EUpgrades.Projectiles,
	EUpgrades.ProjectilesRegen,
	EUpgrades.Bounces,
	EUpgrades.Dash,
	EUpgrades.DashGod,
	EUpgrades.Parry,
	EUpgrades.SlowTime,
	EUpgrades.TargetGod,
}

local UPGRADE_DEPENDENCIES = {
	[EUpgrades.DashGod] = EUpgrades.Dash,
	[EUpgrades.Bounces] = EUpgrades.TargetGod,
}

local UPGRADES_RARITIES = {
	[EUpgrades.Power] = ERarity.Common,
	[EUpgrades.Health] = ERarity.Common,
	[EUpgrades.Projectiles] = ERarity.Common,
	[EUpgrades.ProjectilesRegen] = ERarity.Common,
	[EUpgrades.Bounces] = ERarity.Uncommon,
	[EUpgrades.Dash] = ERarity.Uncommon,
	[EUpgrades.Parry] = ERarity.Uncommon,
	[EUpgrades.DashGod] = ERarity.Rare,
	[EUpgrades.SlowTime] = ERarity.Epic,
	[EUpgrades.TargetGod] = ERarity.Epic,
}

local RARITY_COLORS = {
	[ERarity.Common] = ColorSequence.new(Color3.fromRGB(52, 255, 204), Color3.fromRGB(15, 99, 81)),
	[ERarity.Uncommon] = ColorSequence.new(Color3.fromRGB(12, 255, 255), Color3.fromRGB(4, 50, 99)),
	[ERarity.Rare] = ColorSequence.new(Color3.fromRGB(255, 5, 255), Color3.fromRGB(84, 6, 99)),
	[ERarity.Epic] = ColorSequence.new(Color3.fromRGB(255, 238, 0), Color3.fromRGB(99, 87, 0)),
}

local UpgradesController = {}
UpgradesController.OnUpgradesChanged = Signal.new() :: Signal.Signal<number, number, boolean>
local OwnedUpgrades: { [number]: number } = {}
local CurrentPromise: Promise.Promise?
local UI: UpgradeUI.UpgradeUIReturn
local OnUpgradeSelected: ((upgradeId: number) -> ())?

Fluid.mount(function()
	UI = UpgradeUI({
		SelectedCard = function(upgradeId)
			if OnUpgradeSelected then OnUpgradeSelected(upgradeId) end
			MouseController.HideMouse()
		end,
	})
	return UI.UI
end, PlayerGui)

local function formatStat(value: number, type: string): string
	if type == "Percent" then return string.format("%.0f%%", value * 100) end
	return tostring(value)
end

local function getDescription(upgradeId: number, currentLevel: number): string
	local template = UPGRADES_DESCRIPTION[upgradeId] or "No description."
	local scaling = UPGRADE_SCALING[upgradeId]

	if scaling then
		local nextLevel = currentLevel + 1
		local curVal = formatStat(currentLevel * scaling.Amount, scaling.Type)
		local nextVal = formatStat(nextLevel * scaling.Amount, scaling.Type)

		local statChange = string.format("<font color='#00FF7F'><b>%s -> %s</b></font>", curVal, nextVal)

		return string.format(template, statChange)
	end

	return template
end

local function fillUpgrades(inputUpgrades: { number }?): { number }
	local result = inputUpgrades and table.clone(inputUpgrades) or {}

	if #result >= 4 then return result end

	local candidates = {}

	for _, upgradeId in UPGRADES_LIST do
		if table.find(result, upgradeId) then continue end

		local requiredUpgrade = UPGRADE_DEPENDENCIES[upgradeId]
		if requiredUpgrade and not OwnedUpgrades[requiredUpgrade] then continue end

		local isStackable = STACKABLE_UPGRADES[upgradeId]
		local isOwned = OwnedUpgrades[upgradeId]

		if isStackable or not isOwned then candidates[#candidates + 1] = upgradeId end
	end

	for i = #candidates, 2, -1 do
		local j = math.random(i)
		candidates[i], candidates[j] = candidates[j], candidates[i]
	end

	for _, candidate in candidates do
		if #result >= 4 then break end
		result[#result + 1] = candidate
	end

	return result
end

function UpgradesController.AddUpgrade(upgradeId: number)
	local currentLevel = OwnedUpgrades[upgradeId] or 0
	OwnedUpgrades[upgradeId] = currentLevel + 1

	UpgradesController.OnUpgradesChanged:Fire(upgradeId, currentLevel + 1, true)

	if upgradeId == EUpgrades.Health then
		local config = UPGRADE_SCALING[EUpgrades.Health]
		local amountToAdd = config.Amount
		local newMax = HealthController.GetMaxHealth() + amountToAdd
		HealthController.SetMaxHealth(newMax)
	end
end

function UpgradesController.Show(upgrades: { number }?, fill: boolean?): Promise.Promise
	if CurrentPromise then CurrentPromise:cancel() end
	MouseController.ShowMouse()

	local upgradesList: { number }
	if fill then
		upgradesList = fillUpgrades(upgrades)
	else
		upgradesList = upgrades or {}
	end

	CurrentPromise = Promise.new(function(resolve, _, onCancel)
		OnUpgradeSelected = function(id: number)
			UpgradesController.AddUpgrade(id)
			resolve(id)
		end

		for _, upgradeId in upgradesList do
			local rarity = UPGRADES_RARITIES[upgradeId]
			local color = RARITY_COLORS[rarity] or ColorSequence.new(Color3.new(1, 1, 1))
			local currentLevel = OwnedUpgrades[upgradeId] or 0

			UI.SpawnCard({
				Id = upgradeId,
				Name = UPGRADES_NAME[upgradeId],
				Description = getDescription(upgradeId, currentLevel),
				GradientColor = color,
				Image = UPGRADES_IMAGES[upgradeId],
			})
		end

		UI.Appear()

		onCancel(function()
			UI.Disappear()
			OnUpgradeSelected = nil
			CurrentPromise = nil
		end)
	end):finally(function()
		if UI then UI.Disappear() end
		OnUpgradeSelected = nil
		CurrentPromise = nil
	end)

	return CurrentPromise :: Promise.Promise
end

function UpgradesController.GetUpgradeLevel(upgrade: number): number
	return OwnedUpgrades[upgrade] or 0
end

function UpgradesController.HasUpgrade(upgrade: number)
	return OwnedUpgrades[upgrade] ~= nil
end

function UpgradesController.RemoveUpgrade(upgradeId: number)
	local currentLevel = OwnedUpgrades[upgradeId]
	if not currentLevel then return end

	if currentLevel > 1 then
		OwnedUpgrades[upgradeId] = currentLevel - 1
		UpgradesController.OnUpgradesChanged:Fire(upgradeId, currentLevel - 1, true)
	else
		OwnedUpgrades[upgradeId] = nil
		UpgradesController.OnUpgradesChanged:Fire(upgradeId, 0, false)
	end

	-- TODO: Remove data, like the 20% of the health added.
end

return UpgradesController
