local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Ignis = require(ReplicatedStorage.Packages.Ignis)
local ESounds = require(ReplicatedStorage.Types.Enums.ESounds)
local TCharacter = require(ReplicatedStorage.Types.TCharacter)

local SoundsController = {}
local Sounds: { [number]: Sound } = {}

function SoundsController.OnCharacterAdded(character: TCharacter.TCharacter)
	local primary = character.PrimaryPart
	if not primary then return end

	for _, sound in primary:GetChildren() do
		if not sound:IsA("Sound") then continue end
		local id = ESounds[sound.Name]
		if not id then continue end
		Sounds[id] = sound
	end
end

function SoundsController.Play(id: number)
	local sound = Sounds[id]
	if not sound then return end
	sound:Play()
end

return Ignis.Register(SoundsController)
