local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ERarity = require(ReplicatedStorage.Types.Enums.ERarity)
local EUpgrades = require(ReplicatedStorage.Types.Enums.EUpgrades)

local DEFAULT_UPGRADES = {
	EUpgrades.Strength,
	EUpgrades.Speed,
	EUpgrades.Resistance,
}

local UPGRADES_NAME = {
	[EUpgrades.Strength] = "Strength",
	[EUpgrades.Speed] = "Speed",
	[EUpgrades.Resistance] = "Resistance",
	[EUpgrades.Dodge] = "Dodge",
	[EUpgrades.Parry] = "Parry",
	[EUpgrades.Block] = "Block",
	[EUpgrades.PoisonResistance] = "Poison Resistance",
	[EUpgrades.AbilityBreak] = "Ability Break",
}

local UPGRADES_DESCRIPTION = {
	[EUpgrades.Strength] = "Have +20% more damage.",
	[EUpgrades.Speed] = "The demon king will be 10% slower and have 5% less chances of dodging/parrying your attacks.",
	[EUpgrades.Resistance] = "Have +20% more health.",
	[EUpgrades.Dodge] = "Be able to dodge (Use Q to dodge).",
	[EUpgrades.Parry] = "Be able to parry (Use F to parry).",
	[EUpgrades.Block] = "Be able to block after parry (Use F to block, it gets activated after parry).",
	[EUpgrades.PoisonResistance] = "Be able to resist poison.",
	[EUpgrades.AbilityBreak] = "Grants the ability to destroy the hardened skin of the demon king.",
}

local UPGRADES_RARITIES = {
	[EUpgrades.Strength] = ERarity.Common,
	[EUpgrades.Speed] = ERarity.Common,
	[EUpgrades.Resistance] = ERarity.Common,
	[EUpgrades.Dodge] = ERarity.Uncommon,
	[EUpgrades.Parry] = ERarity.Uncommon,
	[EUpgrades.Block] = ERarity.Rare,
	[EUpgrades.PoisonResistance] = ERarity.Rare,
	[EUpgrades.AbilityBreak] = ERarity.Epic,
}

local UpgradesController = {}

function UpgradesController.Show(upgrades: { number })
	--
end

return UpgradesController
