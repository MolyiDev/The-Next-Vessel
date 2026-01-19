local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local HealthController = require(script.Parent.HealthController)
local Ignis = require(ReplicatedStorage.Packages.Ignis)
local Promise = require(ReplicatedStorage.Shared.Utils.Promise)
local TCharacter = require(ReplicatedStorage.Types.TCharacter)

local EnterCollider = CollectionService:GetTagged("EnterCollider")[1] :: BasePart
local OvParams = OverlapParams.new()
OvParams.FilterType = Enum.RaycastFilterType.Include

local function checkCollision(collider: BasePart, params: OverlapParams)
	if HealthController.IsDead() then return false end

	local parts = Workspace:GetPartsInPart(collider, params)

	for _, part in parts do
		-- If is not the player then continue
		local parent = part.Parent
		if not parent or not parent:HasTag("Player") then continue end

		-- If the player is dead then continue
		local humanoid = parent:FindFirstChild("Humanoid") :: Humanoid
		if not humanoid then continue end

		-- Player found
		return true
	end

	return false
end

local ColliderController = {}
ColliderController.EnterCollider = EnterCollider

function ColliderController.WaitForPlayer(collider: BasePart)
	return Promise.new(function(resolve, _, onCancel)
		local thread = task.spawn(function()
			while true do
				if checkCollision(collider, OvParams) then
					resolve()
					break
				end
				task.wait()
			end
		end)

		onCancel(function()
			task.cancel(thread)
		end)
	end)
end

function ColliderController.OnCharacterAdded(character: TCharacter.TCharacter)
	OvParams.FilterDescendantsInstances = { character }
end

return Ignis.Register(ColliderController)
