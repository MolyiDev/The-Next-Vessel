local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TimeController = require(script.Parent.TimeController)
local jecs = require(ReplicatedStorage.Packages.jecs)
local Components = require(ReplicatedStorage.Shared.ECS.Components)
local WorldRef = require(ReplicatedStorage.Shared.ECS.References.WorldRef)
local World = require(ReplicatedStorage.Shared.ECS.Worlds.World)
local ObjectPooler = require(ReplicatedStorage.Shared.Utils.ObjectPooler)
local Tools = require(ReplicatedStorage.Shared.Utils.Tools)

local GRAVITY = Vector3.new(0, 10, 0)

local Player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local DamageContainer = Tools.CreateGenericScreenGui("DamageNumbers")
DamageContainer.DisplayOrder = -1
DamageContainer.Parent = Player:WaitForChild("PlayerGui")

local LabelTemplate = Instance.new("TextLabel")
LabelTemplate.AnchorPoint = Vector2.new(0.5, 0.5)
LabelTemplate.Size = UDim2.fromScale(0.025, 0.025)
LabelTemplate.BackgroundTransparency = 1
LabelTemplate.FontFace = Tools.FONT_SILKSCREEN_BOLD
LabelTemplate.TextStrokeTransparency = 0
LabelTemplate.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
LabelTemplate.TextScaled = true
LabelTemplate.Visible = false

local LabelsPool = ObjectPooler.new(LabelTemplate, 100, 10, ObjectPooler.ReturnUIObject, DamageContainer)

local FloatingNumbersController = {}
FloatingNumbersController.ENumberType = {
	DamageEnemy = 0,
	HealedEnemy = 1,
	Crit = 2,
	Heal = 3,
}

function FloatingNumbersController.Add(position: Vector3, amount: number, type: number)
	local label = LabelsPool:Get()

	if type == FloatingNumbersController.ENumberType.DamageEnemy then
		label.Text = `{math.floor(amount * 10) / 10}`
		label.TextColor3 = Color3.new(1, 1, 1)
	elseif type == FloatingNumbersController.ENumberType.HealedEnemy then
		label.Text = `+{math.floor(amount * 10) / 10}`
		label.TextColor3 = Color3.new(1, 0.5, 0.5)
	elseif type == FloatingNumbersController.ENumberType.Heal then
		label.Text = `+{math.floor(amount * 10) / 10}`
		label.TextColor3 = Color3.new(0, 1, 0)
	else
		label.Text = `{math.floor(amount * 10) / 10}`
		label.TextColor3 = Color3.new(1, 0, 0)
	end

	local labelEntity = WorldRef:EntityRef(label)

	jecs.bulk_insert(World, labelEntity, {
		Components.TextLabel,
		Components.WorldPos,
		Components.Velocity,
		Components.LifeTime,
		Components.MaxLife,
	}, {
		label,
		position + Vector3.new(0, 2, 0),
		Vector3.new(math.random(-1, 1), 5, math.random(-1, 1)), -- Float up/scatter
		0,
		1,
	})
end

local function damageSystem(rawDt: number)
	local dt = TimeController.GetDeltaTime(rawDt)
	if dt <= 0.001 then return end

	local GravityDT = GRAVITY * dt

	for entity, textLabel, worldPos, velocity, lifeTime, maxLife in
		World
			:query(
				Components.TextLabel,
				Components.WorldPos,
				Components.Velocity,
				Components.LifeTime,
				Components.MaxLife
			)
			:cached()
	do
		lifeTime += dt

		if lifeTime >= maxLife then
			World:delete(entity)
			LabelsPool:Return(textLabel)
			continue
		end

		worldPos += velocity * dt
		velocity -= GravityDT

		World:set(entity, Components.LifeTime, lifeTime)
		World:set(entity, Components.WorldPos, worldPos)
		World:set(entity, Components.Velocity, velocity)

		local vector, onScreen = Camera:WorldToViewportPoint(worldPos)

		if onScreen then
			textLabel.Position = UDim2.fromOffset(vector.X, vector.Y)

			local alpha = lifeTime / maxLife
			textLabel.TextTransparency = alpha

			if not textLabel.Visible then textLabel.Visible = true end
		elseif textLabel.Visible then
			textLabel.Visible = false
		end
	end
end

RunService.PreSimulation:Connect(damageSystem)

return FloatingNumbersController
