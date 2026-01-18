local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Ignis = require(ReplicatedStorage.Packages.Ignis)
local TCharacter = require(ReplicatedStorage.Types.TCharacter)

local Player = Players.LocalPlayer

local CharacterEvents = {}

local characterAdded = Ignis.RegisterLifecycle("OnCharacterAdded") :: Ignis.Lifecycle<TCharacter.TCharacter>
local characterRemoving = Ignis.RegisterLifecycle("OnCharacterRemoving") :: Ignis.Lifecycle<TCharacter.TCharacter>

function CharacterEvents.OnStart()
	if Player.Character then characterAdded:FireSync(Player.Character) end

	Player.CharacterAdded:Connect(function(character)
		characterAdded:FireSync(character)
	end)

	Player.CharacterRemoving:Connect(function(character)
		characterRemoving:FireSync(character)
	end)
end

return Ignis.Register(CharacterEvents)
