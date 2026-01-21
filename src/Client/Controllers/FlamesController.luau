local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundsController = require(script.Parent.SoundsController)
local EFlames = require(ReplicatedStorage.Types.Enums.EFlames)
local ESounds = require(ReplicatedStorage.Types.Enums.ESounds)

local FLAME_ATTACHMENTS = {
	[EFlames.WhiteFlame] = ReplicatedStorage:WaitForChild("Effects"):WaitForChild("WhiteFlame") :: Attachment,
	[EFlames.RedFlame] = ReplicatedStorage:WaitForChild("Effects"):WaitForChild("RedFlame") :: Attachment,
}

local SoulRealmFlame = CollectionService:GetTagged("SoulRealmFlame")[1] :: Attachment

local currentFlame: Attachment?

local FlamesController = {}
FlamesController.CurrentFlame = nil :: number?

function FlamesController.Appear(flameId: number)
	FlamesController.Dissapear()

	local flame = FLAME_ATTACHMENTS[flameId]
	if not flame then return end

	local clone = flame:Clone()
	clone.Parent = SoulRealmFlame
	SoundsController.Play(ESounds.IgniteFlame, clone)
	currentFlame = clone
end

function FlamesController.Dissapear()
	if not currentFlame then return end
	local copy = currentFlame
	currentFlame = nil
	for _, particle in copy:GetChildren() do
		if not particle:IsA("ParticleEmitter") then continue end
		particle.Enabled = false
	end

	task.delay(2, function()
		copy:Destroy()
	end)
end

return FlamesController
