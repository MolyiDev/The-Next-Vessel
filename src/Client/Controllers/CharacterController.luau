local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundsController = require(script.Parent.SoundsController)
local Ignis = require(ReplicatedStorage.Packages.Ignis)
local jecs = require(ReplicatedStorage.Packages.jecs)
local Components = require(ReplicatedStorage.Shared.ECS.Components)
local World = require(ReplicatedStorage.Shared.ECS.Worlds.World)
local ESounds = require(ReplicatedStorage.Types.Enums.ESounds)

local CharacterController = {}

function CharacterController.OnCharacterAdded(_, characterEntity: jecs.Entity)
	local humanoid = World:get(characterEntity, Components.Humanoid)
	local butler = World:get(characterEntity, Components.Butler)
	if not humanoid or not butler then
		warn("Humanoid / Butler are nil")
		return
	end

	humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

	butler:Connect(humanoid.StateChanged, function(old, new)
		if new ~= Enum.HumanoidStateType.Jumping then return end
		SoundsController.PlayCharacter(ESounds.PlayerJump)
	end)
end

return Ignis.Register(CharacterController)
