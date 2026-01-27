local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TimeController = require(script.Parent.Parent.TimeController)
local ProjectileController = require(script.Parent.Parent.ProjectileController)
local EnemiesController = require(script.Parent.Parent.EnemiesController)
local BossController = require(script.Parent)

local Player = Players.LocalPlayer

local BossSpawnController = {}
local nextSpawnTime = 0

function BossSpawnController.ProjectilesAtSceneStart(damage: number, speedMultiplier: number?, sender: number?)
	speedMultiplier = speedMultiplier or 1
	sender = sender or ProjectileController.ESender.Enemy
	local bossCf = BossController.GetCFrame()
	local bossPosition = bossCf.Position - bossCf.LookVector * 3
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
			sender :: any,
			damage
		)
	end
end

function BossSpawnController.ProjectilesAtSceneThird(damage: number, speedMultiplier: number?)
	speedMultiplier = speedMultiplier or 1
	local bossCf = BossController.GetCFrame()
	local bossPosition = bossCf.Position - bossCf.LookVector * 3
	bossCf -= bossCf.LookVector
	local character = Player.Character

	if not character then return end

	local directions = {
		(bossPosition + bossCf.UpVector) - bossPosition, -- up
	}

	for _, dir in directions do
		ProjectileController.AddProjectileMissile(
			bossPosition,
			dir.Unit,
			character.PrimaryPart,
			120 * speedMultiplier :: any,
			2.5,
			ProjectileController.ESender.Enemy,
			damage,
			math.random(1, 6)
		)
	end
end

function BossSpawnController.EnemiesRadial(damage: number, health: number, quantity: number, allowedTypes: { number }?)
	local bossCf = BossController.GetCFrame()
	local bossPosition = bossCf.Position - bossCf.LookVector * 3
	bossCf -= bossCf.LookVector

	local character = Player.Character
	if not character then return end

	local function GetType()
		if allowedTypes and #allowedTypes > 0 then return allowedTypes[math.random(1, #allowedTypes)] end
		return math.random(0, 3)
	end

	local angleStep = (math.pi * 2) / quantity

	for i = 1, quantity do
		local currentAngle = angleStep * i
		local offsetVector = (bossCf.RightVector * math.cos(currentAngle)) + (bossCf.UpVector * math.sin(currentAngle))
		local targetPos = bossPosition + offsetVector

		EnemiesController.SpawnEnemy(bossPosition, targetPos, 15, 2.5, GetType(), damage, health)
	end
end

function BossSpawnController.HandleSpawning()
	local currentMinute = math.floor(TimeController.Timer / 60)
	local interval = 10
	local types = { 0 } -- green
	local quantity = 4

	if currentMinute == 0 then
		-- 00:00 -> 01:00: green, every 9s
		interval = 6
		types = { 0 }
		quantity = 4
	elseif currentMinute == 1 then
		-- 01:00 -> 02:00: green + blue, every 7s
		interval = 4
		types = { 0, 1 }
		quantity = 8
	elseif currentMinute == 2 then
		-- 02:00 -> 03:00: blue + yellow, every 5s
		interval = 3
		types = { 1, 2 }
		quantity = 12
	elseif currentMinute >= 3 and currentMinute < 4 then
		-- 03:00 -> 04:00: yellow + purple every 4s
		interval = 2
		types = { 2, 3 }
		quantity = 18
	elseif currentMinute >= 4 and currentMinute < 5 then
		-- 04:00 -> 05:00: purple every 4s
		interval = 2
		types = { 3 }
		quantity = 24
	elseif currentMinute >= 5 then
		-- 05:00+: purple every 6s
		interval = 1
		types = { 3 }
		quantity = 24
	end

	BossSpawnController.EnemiesRadial(10, 1, quantity, types)

	nextSpawnTime = TimeController.Timer + interval
end

RunService.Heartbeat:Connect(function()
	if not BossSpawnController.Enabled then return end
	if not TimeController.GameplayPaused and not TimeController.Paused and TimeController.Timer >= nextSpawnTime then
		BossSpawnController.HandleSpawning()
	end
end)

return BossSpawnController
