local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local HealthController = require(script.Parent.HealthController)
local MouseController = require(script.Parent.MouseController)
local Fluid = require(ReplicatedStorage.Shared.Utils.Fluid)
local UpgradeUI = require(StarterPlayer.StarterPlayerScripts.Client.UI.UpgradeUI)
local ERarity = require(ReplicatedStorage.Types.Enums.ERarity)
local EUpgrades = require(ReplicatedStorage.Types.Enums.EUpgrades)
local Promise = require(ReplicatedStorage.Shared.Utils.Promise)

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Type: 'Percent' (0.1 = 10%) or 'Flat' (20 = +20)
local UPGRADE_SCALING = {
	[EUpgrades.Power] = { Type = "Percent", Amount = 0.10 },
	[EUpgrades.Reflexes] = { Type = "Percent", Amount = 0.10 },
	[EUpgrades.Mana] = { Type = "Percent", Amount = 0.20 },
	[EUpgrades.Health] = { Type = "Flat", Amount = 20 },
	[EUpgrades.Poison] = { Type = "Percent", Amount = 0.20 },
	[EUpgrades.SlowTime] = { Type = "Percent", Amount = 0.10 },
}

local UPGRADES_NAME = {
	[EUpgrades.Power] = "Power",
	[EUpgrades.Reflexes] = "Reflexes",
	[EUpgrades.Health] = "Vitality",
	[EUpgrades.Dash] = "Dash",
	[EUpgrades.Parry] = "Parry",
	[EUpgrades.Antidote] = "Antidote",
	[EUpgrades.Mana] = "Mana Flow",
	[EUpgrades.Poison] = "Venomous Parry",
	[EUpgrades.ParryGod] = "Parry God",
}

local UPGRADES_DESCRIPTION = {
	[EUpgrades.Power] = "Increases raw power.\nDamage: %s",
	[EUpgrades.Reflexes] = "Heightens senses. Projectiles appear slower.\nSpeed Reduction: %s",
	[EUpgrades.Health] = "Fortifies vitality.\nMax Health: %s",
	[EUpgrades.Mana] = "Expands magical capacity.\nMana: %s",
	[EUpgrades.Poison] = "Parried projectiles become venomous.\nPoison Damage: %s",
	[EUpgrades.SlowTime] = "Temporarily slows time.\nDuration: %s",

	[EUpgrades.Antidote] = "Builds immunity.\nGrants permanent resistance to <font color='#A020F0'><b>Poison</b></font> effects.",
	[EUpgrades.Dash] = "Unlocks <font color='#00FFFF'><b>Dash [Q]</b></font>.\nBecome <b>invulnerable</b>. Dashes break projectiles, converting them into Health and Mana.",
	[EUpgrades.Parry] = "Unlocks <font color='#00FFFF'><b>Parry [F]</b></font>.\n<b>Deflect</b> incoming attacks. Hold to charge return speed.\n<font size='14'><i>Cannot parry Yellow projectiles.</i></font>",
	[EUpgrades.ParryGod] = "Mastery over defense.\nAllows you to <font color='#FFD700'><b>Parry Yellow Projectiles</b></font>.",
}

local UPGRADES_IMAGES = {
	[EUpgrades.Power] = "rbxassetid://114904268719029",
	[EUpgrades.Reflexes] = "rbxassetid://85090421547668",
	[EUpgrades.Health] = "rbxassetid://135331490511011",
	[EUpgrades.Dash] = "rbxassetid://131468682765264",
	[EUpgrades.Parry] = "rbxassetid://71534864279945",
	[EUpgrades.Antidote] = "rbxassetid://125789700898819",
	[EUpgrades.Poison] = "rbxassetid://125789700898819",
}

local STACKABLE_UPGRADES = {
	[EUpgrades.Power] = true,
	[EUpgrades.Reflexes] = true,
	[EUpgrades.Health] = true,
	[EUpgrades.Mana] = true,
	[EUpgrades.Poison] = true,
	[EUpgrades.SlowTime] = true,
}

local UPGRADES_LIST = {
	EUpgrades.Power,
	EUpgrades.Reflexes,
	EUpgrades.Health,
	EUpgrades.Dash,
	EUpgrades.Parry,
	EUpgrades.Antidote,
}

local UPGRADES_RARITIES = {
	[EUpgrades.Power] = ERarity.Common,
	[EUpgrades.Reflexes] = ERarity.Common,
	[EUpgrades.Health] = ERarity.Common,
	[EUpgrades.Dash] = ERarity.Uncommon,
	[EUpgrades.Parry] = ERarity.Uncommon,
	[EUpgrades.Antidote] = ERarity.Rare,
	[EUpgrades.SlowTime] = ERarity.Epic,
}

local RARITY_COLORS = {
	[ERarity.Common] = ColorSequence.new(Color3.fromRGB(52, 255, 204), Color3.fromRGB(15, 99, 81)),
	[ERarity.Uncommon] = ColorSequence.new(Color3.fromRGB(12, 255, 255), Color3.fromRGB(4, 50, 99)),
	[ERarity.Rare] = ColorSequence.new(Color3.fromRGB(255, 5, 255), Color3.fromRGB(84, 6, 99)),
	[ERarity.Epic] = ColorSequence.new(Color3.fromRGB(255, 238, 0), Color3.fromRGB(99, 87, 0)),
}

local UpgradesController = {}
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

	if upgradeId == EUpgrades.Health then
		local config = UPGRADE_SCALING[EUpgrades.Health]
		local amountToAdd = config.Amount
		local newMax = HealthController.GetMaxHealth() + amountToAdd
		HealthController.SetMaxHealth(newMax)
	elseif upgradeId == EUpgrades.Power then
		-- TODO: Update Damage multipliers
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

function UpgradesController.RemoveUpgrade(upgrade: number)
	local currentLevel = OwnedUpgrades[upgrade]
	if not currentLevel then return end

	if currentLevel > 1 then
		OwnedUpgrades[upgrade] = currentLevel - 1
	else
		OwnedUpgrades[upgrade] = nil
	end

	-- TODO: Remove data, like the 20% of the health added.
end

return UpgradesController
