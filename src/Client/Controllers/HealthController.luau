local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundsController = require(script.Parent.SoundsController)
local Signal = require(ReplicatedStorage.Packages.Signal)
local ESounds = require(ReplicatedStorage.Types.Enums.ESounds)

local Health = 100
local MaxHealth = 100
local IsDead = false

local HealthController = {}
HealthController.OnDead = Signal.new()
HealthController.OnRevived = Signal.new()
HealthController.OnDamaged = Signal.new() :: Signal.Signal<number, number, number> -- old, new, damage amount
HealthController.OnHealed = Signal.new() :: Signal.Signal<number, number, number> -- old, new, heal amount
HealthController.OnHealthChanged = Signal.new() :: Signal.Signal<number, number> -- old, new
HealthController.OnMaxHealthChanged = Signal.new() :: Signal.Signal<number, number> -- old, new

function HealthController.GetHealth()
	return Health
end

function HealthController.GetMaxHealth()
	return MaxHealth
end

function HealthController.IsDead()
	return IsDead
end

function HealthController.SetHealth(value: number)
	local newHealth = math.clamp(value, 0, MaxHealth)

	if newHealth == Health then return end

	local oldHealth = Health
	local diff = newHealth - oldHealth

	Health = newHealth

	if newHealth <= 0 then
		if not IsDead then
			IsDead = true
			HealthController.OnDead:Fire()
		end
	end

	if diff < 0 then
		local damage = math.abs(diff)
		HealthController.OnDamaged:Fire(oldHealth, newHealth, damage)
		SoundsController.PlayCharacter(ESounds.PlayerDamaged)
	elseif diff > 0 then
		local healed = diff
		HealthController.OnHealed:Fire(oldHealth, newHealth, healed)
	end

	HealthController.OnHealthChanged:Fire(oldHealth, newHealth)
end

function HealthController.SetMaxHealth(value: number)
	HealthController.OnMaxHealthChanged:Fire(MaxHealth, value)
	MaxHealth = value
end

function HealthController.Damage(value: number)
	HealthController.SetHealth(Health - value)
end

function HealthController.Heal(value: number)
	HealthController.SetHealth(Health + value)
end

function HealthController.Revive()
	Health = MaxHealth

	if not IsDead then return end

	IsDead = false
	HealthController.OnRevived:Fire()
end

function HealthController.Kill()
	HealthController.SetHealth(0)
end

return HealthController
