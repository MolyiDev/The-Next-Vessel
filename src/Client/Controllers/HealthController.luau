local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.Packages.Signal)

local Health = 0
local MaxHealth = 0
local IsDead = false

local HealthController = {}
HealthController.Died = Signal.new()
HealthController.Revived = Signal.new()
HealthController.Damaged = Signal.new() :: Signal.Signal<number> -- damage
HealthController.HealthChanged = Signal.new() :: Signal.Signal<number, number> -- old, new
HealthController.MaxHealthChanged = Signal.new() :: Signal.Signal<number, number> -- old, new

function HealthController.GetHealth()
	return Health
end

function HealthController.GetMaxHealth()
	return MaxHealth
end

function HealthController.SetHealth(value: number)
	HealthController.HealthChanged:Fire(Health, value)

	if value <= 0 then
		IsDead = true
		HealthController.Died:Fire()
	end

	Health = math.clamp(value, 0, MaxHealth)
end

function HealthController.SetMaxHealth(value: number)
	HealthController.MaxHealthChanged:Fire(MaxHealth, value)
	MaxHealth = value
end

function HealthController.Damage(value: number)
	local health = Health - value
	HealthController.SetHealth(health)
end

function HealthController.Heal(value: number)
	local health = Health + value
	HealthController.SetHealth(health)
end

function HealthController.Revive()
	IsDead = false
	Health = MaxHealth
	HealthController.Revived:Fire()
end

function HealthController.Kill()
	HealthController.SetHealth(0)
end

function HealthController.IsDead()
	return IsDead
end

return HealthController
