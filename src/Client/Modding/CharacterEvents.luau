local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Butler = require(ReplicatedStorage.Packages.Butler)
local Ignis = require(ReplicatedStorage.Packages.Ignis)
local jecs = require(ReplicatedStorage.Packages.jecs)
local Components = require(ReplicatedStorage.Shared.ECS.Components)
local WorldRef = require(ReplicatedStorage.Shared.ECS.References.WorldRef)
local Tags = require(ReplicatedStorage.Shared.ECS.Tags)
local World = require(ReplicatedStorage.Shared.ECS.Worlds.World)
local getCharacterEntityFromPlayer = require(ReplicatedStorage.Shared.Utils.Functions.getCharacterEntityFromPlayer)
local TCharacter = require(ReplicatedStorage.Types.TCharacter)

local Player = Players.LocalPlayer

local CharacterEvents = {}

local characterAdded =
	Ignis.RegisterLifecycle("OnCharacterAdded") :: Ignis.Lifecycle<TCharacter.TCharacter, jecs.Entity>
local characterRemoving =
	Ignis.RegisterLifecycle("OnCharacterRemoving") :: Ignis.Lifecycle<TCharacter.TCharacter, jecs.Entity>

function CharacterEvents.OnStart()
	local playerEntity = WorldRef:EntityRef(Player)
	local playerButler = Butler.new()

	jecs.bulk_insert(World, playerEntity, { Components.Player, Components.Butler, Components.Cleanup }, {
		Player,
		playerButler,
		function()
			if playerButler then playerButler:Destroy() end
		end,
	})

	local function dispatchCharacter(character: TCharacter.TCharacter)
		local characterEntity = WorldRef:EntityRef(character)
		local characterButler = Butler.new()

		local humanoid = character:WaitForChild("Humanoid") :: Humanoid

		jecs.bulk_insert(World, characterEntity, {
			Components.Model,
			Components.Butler,
			Components.Humanoid,
			Components.HumanoidRootPart,
			Components.Animator,
			Components.Cleanup,
			jecs.pair(jecs.ChildOf, playerEntity),
			Tags.Character,
		}, {
			character,
			characterButler,
			humanoid,
			character:WaitForChild("HumanoidRootPart"),
			humanoid:WaitForChild("Animator"),
			function()
				characterButler:Destroy()
			end,
		})

		characterAdded:Fire(character, characterEntity)
	end

	if Player.Character then dispatchCharacter(Player.Character :: any) end

	playerButler:Connect(Player.CharacterAdded, function(character)
		dispatchCharacter(character :: any)
	end)

	playerButler:Connect(Player.CharacterRemoving, function(character)
		local characterEntity = getCharacterEntityFromPlayer(Player)
		if not characterEntity then return end
		characterRemoving:Fire(character, characterEntity)
		WorldRef:Nuke(character, characterEntity)
	end)
end

return Ignis.Register(CharacterEvents)
