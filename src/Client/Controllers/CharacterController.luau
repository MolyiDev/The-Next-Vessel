local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Ignis = require(ReplicatedStorage.Packages.Ignis)
local TCharacter = require(ReplicatedStorage.Types.TCharacter)

local function disableTransparency(part: Instance)
	if not part:IsA("BasePart") then return end

	if part.Name == "Head" then
		part:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(function()
			part.LocalTransparencyModifier = 1
		end)
		part.LocalTransparencyModifier = 1
	else
		part:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(function()
			part.LocalTransparencyModifier = 0
		end)
		part.LocalTransparencyModifier = 0
	end
end

local childAddedConnection: RBXScriptConnection?

local CharacterController = {}

function CharacterController.OnCharacterAdded(character: TCharacter.TCharacter)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)

	if childAddedConnection then
		childAddedConnection:Disconnect()
		childAddedConnection = nil
	end

	for _, child in character:getChildren() do
		disableTransparency(child)
	end

	childAddedConnection = character.ChildAdded:Connect(function(part)
		disableTransparency(part)
	end)
end

return Ignis.Register(CharacterController)
