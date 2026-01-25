local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BossController = require(script.Parent)
local Ignis = require(ReplicatedStorage.Packages.Ignis)
local TCharacter = require(ReplicatedStorage.Types.TCharacter)

local RAGDOLL_INSTANCE_NAMES = {
	["RagdollAttachment"] = true,
	["RagdollConstraint"] = true,
	["ColliderPart"] = true,
}

local BossRagdollController = {}
BossRagdollController.IsRagdoll = false

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

local function ReplaceJoints(character: TCharacter.TCharacter)
	for _, motor in ipairs(character:GetDescendants()) do
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

local function ResetJoints(character: TCharacter.TCharacter)
	for _, instance in ipairs(character:GetDescendants()) do
		if RAGDOLL_INSTANCE_NAMES[instance.Name] then
			instance:Destroy()
		elseif instance:IsA("Motor6D") then
			instance.Enabled = true
		end
	end
end

function BossRagdollController.Ragdoll()
	if BossRagdollController.IsRagdoll then return end
	local character = BossController.GetRig()
	if not character then return end
	local humanoid = character:FindFirstChild("Humanoid") :: Humanoid
	if not humanoid then return end

	BossRagdollController.IsRagdoll = true

	humanoid:ChangeState(Enum.HumanoidStateType.Physics)

	ReplaceJoints(character)

	if character then character:SetAttribute("LastRag", os.clock()) end
end

function BossRagdollController.Unragdoll()
	if not BossRagdollController.IsRagdoll then return end
	local character = BossController.GetRig()
	if not character then return end
	local humanoid = character:FindFirstChild("Humanoid") :: Humanoid
	if not humanoid then return end

	BossRagdollController.IsRagdoll = false

	humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)

	ResetJoints(character)
end

return Ignis.Register(BossRagdollController)
