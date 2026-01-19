local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local CameraController = require(script.Parent.CameraController)
local Fluid = require(ReplicatedStorage.Shared.Utils.Fluid)
local UpgradeUI = require(StarterPlayer.StarterPlayerScripts.Client.UI.UpgradeUI)
local ERarity = require(ReplicatedStorage.Types.Enums.ERarity)
local EUpgrades = require(ReplicatedStorage.Types.Enums.EUpgrades)
local Promise = require(ReplicatedStorage.Shared.Utils.Promise)

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local UPGRADES_NAME = {
	[EUpgrades.Strength] = "Strength",
	[EUpgrades.Speed] = "Speed",
	[EUpgrades.Health] = "Health",
	[EUpgrades.Dodge] = "Dodge",
	[EUpgrades.Parry] = "Parry",
	[EUpgrades.Block] = "Block",
	[EUpgrades.PoisonResistance] = "Poison Resistance",
	[EUpgrades.AbilityBreak] = "Ability Break",
}

local UPGRADES_DESCRIPTION = {
	[EUpgrades.Strength] = "Increases your raw power.\nDeals <font color='#00FF7F'><b>+20%</b></font> extra damage.",
	[EUpgrades.Speed] = "Cripples the Demon King.\nHe becomes <font color='#FF5555'><b>10%</b></font> slower with reduced <b>Dodge/Parry</b> rates.",
	[EUpgrades.Health] = "Fortifies your vitality.\nIncreases maximum health by <font color='#00FF7F'><b>+20%</b></font>.",
	[EUpgrades.Dodge] = "Unlocks <font color='#00FFFF'><b>Dodge</b></font> ability.\nPress <font color='#FFD700'><b>[Q]</b></font> to become momentarily <b>invulnerable</b> while moving.",
	[EUpgrades.Parry] = "Unlocks <font color='#00FFFF'><b>Parry</b></font> ability.\nPress <font color='#FFD700'><b>[F]</b></font> just before being hit to <b>deflect</b> the attack.",
	[EUpgrades.Block] = "Unlocks <font color='#00FFFF'><b>Block</b></font> recovery.\nAutomatically blocks if a Parry fails, reducing damage by <font color='#FF5555'><b>50%</b></font>.",
	[EUpgrades.PoisonResistance] = "Builds immunity.\nGrants permanent resistance to <font color='#A020F0'><b>Poison</b></font> effects.",
	[EUpgrades.AbilityBreak] = "Shatters defenses.\nDestroys the <font color='#FF5555'><b>Demon King's</b></font> hardened skin, allowing attacks to penetrate.",
}

local UPGRADES_IMAGES = {
	[EUpgrades.Strength] = "rbxassetid://114904268719029",
	[EUpgrades.Speed] = "rbxassetid://85090421547668",
	[EUpgrades.Health] = "rbxassetid://135331490511011",
	[EUpgrades.Dodge] = "rbxassetid://131468682765264",
	[EUpgrades.Parry] = "rbxassetid://71534864279945",
	[EUpgrades.Block] = "rbxassetid://128112310338378",
	[EUpgrades.PoisonResistance] = "rbxassetid://125789700898819",
	[EUpgrades.AbilityBreak] = "",
}

local STACKABLE_UPGRADES = {
	[EUpgrades.Strength] = true,
	[EUpgrades.Speed] = true,
	[EUpgrades.Health] = true,
}

local UPGRADES_LIST = {
	EUpgrades.Strength,
	EUpgrades.Speed,
	EUpgrades.Health,
	EUpgrades.Dodge,
	EUpgrades.Parry,
	EUpgrades.Block,
	EUpgrades.PoisonResistance,
	EUpgrades.AbilityBreak,
}

local UPGRADES_RARITIES = {
	[EUpgrades.Strength] = ERarity.Common,
	[EUpgrades.Speed] = ERarity.Common,
	[EUpgrades.Health] = ERarity.Common,
	[EUpgrades.Dodge] = ERarity.Uncommon,
	[EUpgrades.Parry] = ERarity.Uncommon,
	[EUpgrades.Block] = ERarity.Rare,
	[EUpgrades.PoisonResistance] = ERarity.Rare,
	[EUpgrades.AbilityBreak] = ERarity.Epic,
}

local RARITY_COLORS = {
	[ERarity.Common] = ColorSequence.new(Color3.fromRGB(52, 255, 204), Color3.fromRGB(15, 99, 81)),
	[ERarity.Uncommon] = ColorSequence.new(Color3.fromRGB(12, 255, 255), Color3.fromRGB(4, 50, 99)),
	[ERarity.Rare] = ColorSequence.new(Color3.fromRGB(255, 5, 255), Color3.fromRGB(84, 6, 99)),
	[ERarity.Epic] = ColorSequence.new(Color3.fromRGB(255, 238, 0), Color3.fromRGB(99, 87, 0)),
}

local UpgradesController = {}
local OwnedUpgrades: { number } = {}
local CurrentPromise: Promise.Promise?
local UI: UpgradeUI.UpgradeUIReturn
local OnUpgradeSelected: ((upgradeId: number) -> ())?

Fluid.mount(function()
	UI = UpgradeUI({
		SelectedCard = function(upgradeId)
			if OnUpgradeSelected then OnUpgradeSelected(upgradeId) end
			CameraController.HideMouse()
		end,
	})
	return UI.UI
end, PlayerGui)

local function fillUpgrades(inputUpgrades: { number }?): { number }
	local result = inputUpgrades and table.clone(inputUpgrades) or {}

	if #result >= 4 then return result end

	local ownedLookup = {}
	for _, id in OwnedUpgrades do
		ownedLookup[id] = true
	end

	local candidates = {}

	for _, upgradeId in UPGRADES_LIST do
		if table.find(result, upgradeId) then continue end

		local isStackable = STACKABLE_UPGRADES[upgradeId]
		local isOwned = ownedLookup[upgradeId]

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

function UpgradesController.Show(upgrades: { number }?, fill: boolean?): Promise.Promise
	if CurrentPromise then CurrentPromise:cancel() end
	CameraController.ShowMouse()

	local upgradesList: { number }
	if fill then
		upgradesList = fillUpgrades(upgrades)
	else
		upgradesList = upgrades or {}
	end

	CurrentPromise = Promise.new(function(resolve, _, onCancel)
		OnUpgradeSelected = function(id: number)
			print(id)
			resolve(id)
		end

		for _, upgradeId in upgradesList do
			local rarity = UPGRADES_RARITIES[upgradeId]
			local color = RARITY_COLORS[rarity] or ColorSequence.new(Color3.new(1, 1, 1))

			UI.SpawnCard({
				Id = upgradeId,
				Name = UPGRADES_NAME[upgradeId],
				Description = UPGRADES_DESCRIPTION[upgradeId],
				GradientColor = color,
				Image = UPGRADES_IMAGES[upgradeId],
			})
		end

		UI.Appear()

		onCancel(function()
			UI.Disappear()
		end)
	end):finally(function()
		print("finally")
		if UI then UI.Disappear() end
		OnUpgradeSelected = nil
		CurrentPromise = nil
	end)

	return CurrentPromise :: Promise.Promise
end

return UpgradesController
