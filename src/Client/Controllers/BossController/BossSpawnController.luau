local Players = game:GetService("Players")
local ProjectileController = require(script.Parent.Parent.ProjectileController)
local EnemiesController = require(script.Parent.Parent.EnemiesController)
local BossController = require(script.Parent)

local Player = Players.LocalPlayer

local BossSpawnController = {}

function BossSpawnController.ProjectilesAtSceneStart(damage: number, speedMultiplier: number?)
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
		ProjectileController.ESender.Enemy,
		damage
	)

	-- right
	ProjectileController.AddProjectileMissile(
		bossPosition,
		bossPosition + bossCf.RightVector,
		character.PrimaryPart,
		120 * speedMultiplier,
		2.5,
		ProjectileController.ESender.Enemy,
		damage
	)

	-- up
	ProjectileController.AddProjectileMissile(
		bossPosition,
		bossPosition + bossCf.UpVector,
		character.PrimaryPart,
		120 * speedMultiplier,
		2.5,
		ProjectileController.ESender.Enemy,
		damage
	)

	-- up left
	ProjectileController.AddProjectileMissile(
		bossPosition,
		bossPosition + (bossCf.UpVector - bossCf.RightVector).Unit,
		character.PrimaryPart,
		120 * speedMultiplier,
		2.5,
		ProjectileController.ESender.Enemy,
		damage
	)

	-- up right
	ProjectileController.AddProjectileMissile(
		bossPosition,
		bossPosition + (bossCf.UpVector + bossCf.RightVector).Unit,
		character.PrimaryPart,
		120 * speedMultiplier,
		2.5,
		ProjectileController.ESender.Enemy,
		damage
	)
end

function BossSpawnController.EnemiesRadial(damage: number, health: number, speedMultiplier: number?)
	speedMultiplier = speedMultiplier or 1
	local bossCf = BossController.GetCFrame()
	local bossPosition = bossCf.Position - bossCf.LookVector
	bossCf -= bossCf.LookVector
	local character = Player.Character

	if not character then return end

	-- left
	EnemiesController.SpawnEnemy(bossPosition, bossPosition - bossCf.RightVector, 15, 2.5, damage, health)

	-- right
	EnemiesController.SpawnEnemy(bossPosition, bossPosition + bossCf.RightVector, 15, 2.5, damage, health)

	-- up
	EnemiesController.SpawnEnemy(bossPosition, bossPosition + bossCf.UpVector, 15, 2.5, damage, health)

	-- up left
	EnemiesController.SpawnEnemy(bossPosition, bossPosition + bossCf.UpVector, 15, 2.5, damage, health)

	-- up right
	EnemiesController.SpawnEnemy(bossPosition, bossPosition + bossCf.UpVector, 15, 2.5, damage, health)
end

return BossSpawnController
