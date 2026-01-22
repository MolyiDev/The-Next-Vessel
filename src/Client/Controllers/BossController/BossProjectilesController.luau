local Players = game:GetService("Players")
local ProjectileController = require(script.Parent.Parent.ProjectileController)
local BossController = require(script.Parent)

local Player = Players.LocalPlayer

local BossProjectilesController = {}

function BossProjectilesController.ShootFirst(damage: number, speedMultiplier: number?)
	speedMultiplier = speedMultiplier or 1
	local bossCf = BossController.GetCFrame()
	local bossPosition = bossCf.Position - bossCf.LookVector
	bossCf -= bossCf.LookVector
	local character = Player.Character

	if not character then return end

	-- left
	ProjectileController.AddProjectileMissile(
		bossPosition,
		bossPosition - bossCf.RightVector,
		character.PrimaryPart,
		120 * speedMultiplier,
		2.5,
		damage
	)

	-- right
	ProjectileController.AddProjectileMissile(
		bossPosition,
		bossPosition + bossCf.RightVector,
		character.PrimaryPart,
		120 * speedMultiplier,
		2.5,
		damage
	)

	-- up
	ProjectileController.AddProjectileMissile(
		bossPosition,
		bossPosition + bossCf.UpVector,
		character.PrimaryPart,
		120 * speedMultiplier,
		2.5,
		damage
	)

	-- up left
	ProjectileController.AddProjectileMissile(
		bossPosition,
		bossPosition + (bossCf.UpVector - bossCf.RightVector).Unit,
		character.PrimaryPart,
		120 * speedMultiplier,
		2.5,
		damage
	)

	-- up right
	ProjectileController.AddProjectileMissile(
		bossPosition,
		bossPosition + (bossCf.UpVector + bossCf.RightVector).Unit,
		character.PrimaryPart,
		120 * speedMultiplier,
		2.5,
		damage
	)
end

return BossProjectilesController
