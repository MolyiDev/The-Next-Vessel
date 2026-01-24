local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TimeController = require(script.Parent.Parent.TimeController)
local ProjectileController = require(script.Parent.Parent.ProjectileController)
local EnemiesController = require(script.Parent.Parent.EnemiesController)
local BossController = require(script.Parent)

local Player = Players.LocalPlayer

local BossSpawnController = {}
local nextSpawnTime = 0

function BossSpawnController.ProjectilesAtSceneStart(damage: number, speedMultiplier: number?)
	speedMultiplier = speedMultiplier or 1
	local bossCf = BossController.GetCFrame()
	local bossPosition = bossCf.Position - bossCf.LookVector
	bossCf -= bossCf.LookVector
	local character = Player.Character

	if not character then return end

	local directions = {
		(bossPosition - bossCf.RightVector) - bossPosition, -- left
		(bossPosition + bossCf.RightVector) - bossPosition, -- right
		(bossPosition + bossCf.UpVector) - bossPosition, -- up
		(bossPosition + (bossCf.UpVector - bossCf.RightVector).Unit) - bossPosition, -- up left
		(bossPosition + (bossCf.UpVector + bossCf.RightVector).Unit) - bossPosition, -- up right
	}

	for _, dir in directions do
		ProjectileController.AddProjectileMissile(
			bossPosition,
			dir.Unit,
			character.PrimaryPart,
			120 * speedMultiplier :: any,
			2.5,
			ProjectileController.ESender.Enemy,
			damage
		)
	end
end

function BossSpawnController.EnemiesRadial(
	damage: number,
	health: number,
	speedMultiplier: number?,
	allowedTypes: { number }?
)
	speedMultiplier = speedMultiplier or 1
	local bossCf = BossController.GetCFrame()
	local bossPosition = bossCf.Position - bossCf.LookVector
	bossCf -= bossCf.LookVector
	local character = Player.Character

	if not character then return end

	local function getType()
		if allowedTypes and #allowedTypes > 0 then return allowedTypes[math.random(1, #allowedTypes)] end
		return math.random(0, 3)
	end

	local targets = {
		bossPosition - bossCf.RightVector, -- left
		bossPosition + bossCf.RightVector, -- right
		(bossPosition + (bossCf.UpVector - bossCf.RightVector).Unit), -- up left
		(bossPosition + (bossCf.UpVector + bossCf.RightVector).Unit), -- up right
		bossPosition + bossCf.UpVector, -- up
	}

	for _, targetPos in targets do
		EnemiesController.SpawnEnemy(bossPosition, targetPos, 15, 2.5, getType(), damage, health)
	end
end

function BossSpawnController.HandleSpawning()
	local currentMinute = math.floor(TimeController.Timer / 60)
	local interval = 10
	local types = { 0 } -- green

	if currentMinute == 0 then
		-- 00:00 -> 01:00: green, every 10s
		interval = 10
		types = { 0 }
	elseif currentMinute == 1 then
		-- 01:00 -> 02:00: green + blue, every 8s
		interval = 8
		types = { 0, 1 }
	elseif currentMinute == 2 then
		-- 02:00 -> 03:00: blue + yellow, every 6s
		interval = 6
		types = { 1, 2 }
	elseif currentMinute >= 3 and currentMinute < 5 then
		-- 03:00 -> 05:00: yellow + purple every 4s
		interval = 4
		types = { 2, 3 }
	elseif currentMinute >= 5 then
		-- 05:00+: purple every 8s
		interval = 8
		types = { 3 }
	end

	BossSpawnController.EnemiesRadial(15, 30, 1, types)

	nextSpawnTime = TimeController.Timer + interval
end

RunService.Heartbeat:Connect(function()
	if TimeController.Timer >= nextSpawnTime then BossSpawnController.HandleSpawning() end
end)

return BossSpawnController
