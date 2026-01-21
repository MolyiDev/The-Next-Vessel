local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TCharacter = require(ReplicatedStorage.Types.TCharacter)
local HealthController = require(script.Parent.HealthController)

local BossR6 = CollectionService:GetTagged("Boss")[1] :: TCharacter.TCharacter
local Humanoid = BossR6 and BossR6:WaitForChild("Humanoid") :: Humanoid
local HumanoidRootPart = BossR6 and BossR6:WaitForChild("HumanoidRootPart") :: BasePart
local Animator = Humanoid and Humanoid:WaitForChild("Animator") :: Animator

local ATTACK_RANGE = 12
local ACTION_COOLDOWN = 1.5
local DEFAULT_POSITION = (BossR6.PrimaryPart :: any).CFrame
local ANIMATIONS = {
	Attack = "rbxassetid://0",
	Block = "rbxassetid://0",
	Dodge = "rbxassetid://0",
	Harden = "rbxassetid://0",
}

local Player = Players.LocalPlayer
local IsActing = false
local ActiveTracks: { [string]: AnimationTrack } = {}

for name, id in pairs(ANIMATIONS) do
	local anim = Instance.new("Animation")
	anim.AnimationId = id
	ActiveTracks[name] = Animator:LoadAnimation(anim)
end

local function playAnim(name: string)
	local track = ActiveTracks[name]
	if track then track:Play() end
end

local function faceTarget(targetRoot: BasePart)
	if Humanoid.WalkSpeed <= 0 then return end

	local origin = BossR6.HumanoidRootPart.Position
	local lookAt = Vector3.new(targetRoot.Position.X, origin.Y, targetRoot.Position.Z)

	BossR6.HumanoidRootPart.CFrame = CFrame.lookAt(origin, lookAt)
end

local BossController = {}
BossController.IsActive = false
BossController.Difficulty = 20

local Health = 100
local MaxHealth = 100

function BossController.Harden()
	if IsActing then return end
	IsActing = true

	--

	task.wait(0.5)
	IsActing = false
end

function BossController.Attack()
	if IsActing then return end
	IsActing = true

	--

	task.wait(0.8)
	IsActing = false
end

function BossController.Block()
	if IsActing then return end
	IsActing = true

	--

	task.wait(1.5)
	IsActing = false
end

function BossController.Parry()
	if IsActing then return end
	IsActing = true

	task.wait(0.4)
	IsActing = false
end

function BossController.Dodge()
	if IsActing then return end
	IsActing = true

	task.wait(0.5)
	IsActing = false
end

function BossController.Start()
	task.spawn(function()
		while BossR6.Parent and BossController.Health > 0 do
			local character = Player.Character
			local targetRoot = character and character:FindFirstChild("HumanoidRootPart")

			if not targetRoot or HealthController.IsDead() then
				BossR6.Humanoid:MoveTo(BossR6.HumanoidRootPart.Position)
				task.wait(1)
				continue
			end

			local Dist = (targetRoot.Position - BossR6.HumanoidRootPart.Position).Magnitude

			if Dist <= ATTACK_RANGE then
				BossR6.Humanoid:MoveTo(BossR6.HumanoidRootPart.Position)
				faceTarget(targetRoot)

				if not IsActing then
					local Roll = math.random()

					if Roll < 0.60 then
						BossController.Attack()
					elseif Roll < 0.75 then
						BossController.Block()
					elseif Roll < 0.85 then
						BossController.Dodge()
					else
						BossController.Harden()
					end

					task.wait(ACTION_COOLDOWN)
				end
			else
				BossR6.Humanoid:MoveTo(targetRoot.Position)
			end

			task.wait(0.25)
		end
	end)
end

function BossController.Stop()
	BossController.IsActive = false
	Humanoid:MoveTo(HumanoidRootPart.Position)
end

function BossController.Reset()
	HumanoidRootPart.CFrame = DEFAULT_POSITION
	BossController.Health = 100
	IsActing = false
end

function BossController.SetImmobilize(value: boolean)
	BossR6.Humanoid.WalkSpeed = value and 0 or 16
end

function BossController.IsImmobilized()
	return BossR6.Humanoid.WalkSpeed == 0
end

function BossController.GetCurrentPosition(): Vector3
	return BossR6.HumanoidRootPart.Position
end

function BossController.GetRig()
	return BossR6
end

function BossController.CanParryProjectile(speed: number)
	-- Base logic:
	-- 1. High difficulty = Higher base chance.
	-- 2. High speed = Divides the chance (making it harder).

	-- Example Formula: (Difficulty * 15) / Speed
	-- If Diff 5, Speed 50  -> (75/50)  = 1.5 (150% chance - Guaranteed)
	-- If Diff 5, Speed 100 -> (75/100) = 0.75 (75% chance)
	-- If Diff 1, Speed 100 -> (15/100) = 0.15 (15% chance)

	local parryChance = (BossController.Difficulty * 15) / math.max(speed, 1)

	-- Clamp chance to ensure it's never impossible or fully guaranteed if you want randomness
	parryChance = math.clamp(parryChance, 0.1, 0.95)
	local canParry = math.random() < parryChance
	-- print("CanParry:", canParry)

	return true --canParry
end

function BossController.SuccessfulParry() end

function BossController.Damage(value: number)
	print("damageBoss")
	Health = math.max(Health - value, 0)
end

return BossController
