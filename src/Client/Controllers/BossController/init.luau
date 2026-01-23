local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Signal = require(ReplicatedStorage.Packages.Signal)
local jecs = require(ReplicatedStorage.Packages.jecs)
local Components = require(ReplicatedStorage.Shared.ECS.Components)
local WorldRef = require(ReplicatedStorage.Shared.ECS.References.WorldRef)
local Tags = require(ReplicatedStorage.Shared.ECS.Tags)
local World = require(ReplicatedStorage.Shared.ECS.Worlds.World)
local TCharacter = require(ReplicatedStorage.Types.TCharacter)

local FlyIdleAnim = ReplicatedStorage:WaitForChild("Animations"):WaitForChild("FlyIdle") :: Animation

local BossR6 = CollectionService:GetTagged("Boss")[1] :: TCharacter.TCharacter
local Humanoid = BossR6 and BossR6:WaitForChild("Humanoid") :: Humanoid
local HumanoidRootPart = BossR6 and BossR6:WaitForChild("HumanoidRootPart") :: BasePart
local Animator = Humanoid and Humanoid:WaitForChild("Animator") :: Animator

local BossEntity = WorldRef:EntityRef(BossR6)
jecs.bulk_insert(World, BossEntity, { Components.CFrame, Tags.Enemy }, { HumanoidRootPart.CFrame })

local DEFAULT_POSITION = HumanoidRootPart.CFrame

local Player = Players.LocalPlayer

local FlyIdle = Animator:LoadAnimation(FlyIdleAnim)
FlyIdle:Play(0.1, 1, 0.75)

local Health = 100
local MaxHealth = 100
local IsDead = false

local BossController = {}
BossController.OnDead = Signal.new()
BossController.OnDamaged = Signal.new() :: Signal.Signal<number, number, number> -- old, new damage
BossController.OnHealed = Signal.new() :: Signal.Signal<number, number, number> -- old, new, heal
BossController.OnHealthChanged = Signal.new() :: Signal.Signal<number, number> -- old, new
BossController.OnMaxHealthChanged = Signal.new() :: Signal.Signal<number, number> -- old, new
BossController.Difficulty = 20

function BossController.Reset()
	HumanoidRootPart.CFrame = DEFAULT_POSITION
	BossController.Health = MaxHealth
	IsDead = false
	Health = MaxHealth
end

function BossController.GetPosition(): Vector3
	return BossR6.HumanoidRootPart.Position
end

function BossController.GetCFrame(): CFrame
	return BossR6.HumanoidRootPart.CFrame
end

function BossController.GetRoot(): BasePart
	return BossR6.HumanoidRootPart
end

function BossController.GetRig()
	return BossR6
end

function BossController.GetHealth()
	return Health
end

function BossController.GetMaxHealth()
	return Health
end

function BossController.IsDead()
	return IsDead
end

function BossController.CanParryProjectile(speed: number)
	-- Example: (Difficulty * 15) / Speed
	-- If Diff 5, Speed 50  -> (75/50)  = 1.5 (150% chance - Guaranteed)
	-- If Diff 5, Speed 100 -> (75/100) = 0.75 (75% chance)
	-- If Diff 1, Speed 100 -> (15/100) = 0.15 (15% chance)

	local parryChance = (BossController.Difficulty * 15) / math.max(speed, 1)

	parryChance = math.clamp(parryChance, 0.1, 0.95)
	local canParry = math.random() < parryChance

	return canParry
end

function BossController.SuccessfulParry() end

function BossController.SetHealth(value: number)
	local newHealth = math.clamp(value, 0, MaxHealth)

	if newHealth == Health then return end

	local oldHealth = Health
	local diff = newHealth - oldHealth

	Health = newHealth

	if newHealth <= 0 then
		if not IsDead then
			IsDead = true
			BossController.OnDead:Fire()
		end
	end

	if diff < 0 then
		local damage = math.abs(diff)
		BossController.OnDamaged:Fire(oldHealth, newHealth, damage)
	elseif diff > 0 then
		local healed = diff
		BossController.OnHealed:Fire(oldHealth, newHealth, healed)
	end

	BossController.OnHealthChanged:Fire(oldHealth, newHealth)
end

function BossController.Damage(value: number)
	BossController.SetHealth(Health - value)
end

function BossController.Heal(value: number)
	BossController.SetHealth(Health + value)
end

function BossController.Kill()
	BossController.SetHealth(0)
end

RunService.Heartbeat:Connect(function()
	local character = Player.Character
	if not character then return end
	local rootPart = character.PrimaryPart
	if not rootPart then return end

	local origin = BossR6.HumanoidRootPart.Position
	local lookAt = Vector3.new(rootPart.Position.X, origin.Y, rootPart.Position.Z)

	BossR6.HumanoidRootPart.CFrame = CFrame.lookAt(origin, lookAt)
end)

return BossController
