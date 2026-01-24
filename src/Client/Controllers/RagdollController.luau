local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Ignis = require(ReplicatedStorage.Packages.Ignis)
local jecs = require(ReplicatedStorage.Packages.jecs)
local Components = require(ReplicatedStorage.Shared.ECS.Components)
local World = require(ReplicatedStorage.Shared.ECS.Worlds.World)
local TCharacter = require(ReplicatedStorage.Types.TCharacter)
local HealthController = require(script.Parent.HealthController)
local TweensController = require(script.Parent.TweensController)

local RAGDOLL_INSTANCE_NAMES = {
	["RagdollAttachment"] = true,
	["RagdollConstraint"] = true,
	["ColliderPart"] = true,
}

local RagdollController = {}
RagdollController.IsRagdoll = false

local Character: TCharacter.TCharacter?
local Humanoid: Humanoid?

local function CreateColliderPart(part: BasePart)
	if not part then return end

	local collider = Instance.new("Part")
	collider.Name = "ColliderPart"
	collider.Size = part.Size / 1.7
	collider.Massless = true
	collider.CFrame = part.CFrame
	collider.Transparency = 1

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = collider
	weld.Part1 = part
	weld.Parent = collider

	collider.Parent = part
end

local function ReplaceJoints()
	if not Character then return end

	for _, motor in ipairs(Character:GetDescendants()) do
		if not motor:IsA("Motor6D") then continue end

		motor.Enabled = false

		local a0 = Instance.new("Attachment")
		local a1 = Instance.new("Attachment")

		a0.CFrame = motor.C0
		a1.CFrame = motor.C1

		a0.Name = "RagdollAttachment"
		a1.Name = "RagdollAttachment"

		if motor.Part1 then CreateColliderPart(motor.Part1) end

		local socket = Instance.new("BallSocketConstraint")
		socket.Attachment0 = a0
		socket.Attachment1 = a1
		socket.Name = "RagdollConstraint"

		socket.Radius = 0.15
		socket.LimitsEnabled = true
		socket.TwistLimitsEnabled = false
		socket.MaxFrictionTorque = 0
		socket.Restitution = 0
		socket.UpperAngle = 90

		if motor.Name == "Neck" then
			socket.TwistLimitsEnabled = true
			socket.UpperAngle = 45
			socket.TwistLowerAngle = -70
			socket.TwistUpperAngle = 70
		end

		a0.Parent = motor.Part0
		a1.Parent = motor.Part1
		socket.Parent = motor.Parent
	end
end

local function ResetJoints()
	if not Character then return end

	for _, instance in ipairs(Character:GetDescendants()) do
		if RAGDOLL_INSTANCE_NAMES[instance.Name] then
			instance:Destroy()
		elseif instance:IsA("Motor6D") then
			instance.Enabled = true
		end
	end
end

function RagdollController.OnCharacterAdded(character: TCharacter.TCharacter, characterEntity: jecs.Entity)
	Character = character
	Humanoid = World:get(characterEntity, Components.Humanoid) :: Humanoid

	if not Humanoid then
		warn("Humanoid is nil")
		return
	end

	RagdollController.IsRagdoll = false
end

function RagdollController.Ragdoll()
	if RagdollController.IsRagdoll or not Humanoid then return end

	RagdollController.IsRagdoll = true

	Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	Humanoid.AutoRotate = false

	ReplaceJoints()

	if Character then Character:SetAttribute("LastRag", os.clock()) end
end

function RagdollController.Unragdoll()
	if not RagdollController.IsRagdoll or not Humanoid then return end

	RagdollController.IsRagdoll = false

	Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	Humanoid.AutoRotate = true

	ResetJoints()
end

HealthController.OnDead:Connect(function()
	TweensController.SetImmobile(true)
	RagdollController.Ragdoll()
end)

HealthController.OnRevived:Connect(function()
	RagdollController.Unragdoll()
end)

return Ignis.Register(RagdollController)
