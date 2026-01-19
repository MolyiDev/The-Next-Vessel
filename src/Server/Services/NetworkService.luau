local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local NetworkObjects = CollectionService:GetTagged("ClientNetwork")

local NetworkService = {}

local function setNetwork(player: Player, objects: { BasePart })
	for _, object in objects do
		if object:IsA("BasePart") and object:CanSetNetworkOwnership() then object:SetNetworkOwner(player) end

		for _, descendant in object:GetDescendants() do
			if not descendant:IsA("BasePart") or not descendant:CanSetNetworkOwnership() then continue end
			descendant:SetNetworkOwner(player)
		end
	end
end

Players.PlayerAdded:Connect(function(player)
	setNetwork(player, NetworkObjects)
end)

return NetworkService
