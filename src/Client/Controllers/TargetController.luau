local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local jecs = require(ReplicatedStorage.Packages.jecs)
local Components = require(ReplicatedStorage.Shared.ECS.Components)
local Tags = require(ReplicatedStorage.Shared.ECS.Tags)
local World = require(ReplicatedStorage.Shared.ECS.Worlds.World)
local Tools = require(ReplicatedStorage.Shared.Utils.Tools)

local SELECTION_THRESHOLD_PX = 80 -- How close (in pixels) you must click to the enemy
local MAX_SELECTION_DIST = 500 -- Max distance in studs to select
local DEFAULT_RADIUS = 2 -- Fallback radius
local RETICLE_SIZE_MULT = 2.5 -- Multiplier for the reticle size based on radius
local MIN_SIZE_PX = 10 -- Minimum size in pixels (so it doesn't vanish completely)
local MAX_SIZE_PX = 100 -- Maximum size in pixels (so it doesn't cover entire screen up close)
local ARROW_TARGET = "rbxassetid://129623063194632"
local HOVER_UPDATE_RATE = 0.05
local BASE_TRANSPARENCY = 0.25
local FADE_SPEED = 10

local Player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local ArrowsContainer = Tools.CreateGenericScreenGui("DamageNumbers")
ArrowsContainer.DisplayOrder = -1
ArrowsContainer.Parent = Player:WaitForChild("PlayerGui")

local CurrentTransparency = 1
local TargetTransparency = 1

--==[ UI ]==--
type Reticle = {
	Container: Frame,
	Corners: { ImageLabel },
	Visible: boolean,
}

local function CreateReticle(name: string, color: Color3): Reticle
	local container = Instance.new("Frame")
	container.Name = name
	container.Size = UDim2.fromOffset(100, 100)
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	container.BackgroundTransparency = 1
	container.Visible = false
	container.Parent = ArrowsContainer

	local corners = {}
	local rotations = { 0, 90, 180, 270 }

	local positions = {
		UDim2.fromScale(0, 0), -- topleft
		UDim2.fromScale(1, 0), -- topright
		UDim2.fromScale(1, 1), -- bottomright
		UDim2.fromScale(0, 1), -- bottomleft
	}

	-- same dirs
	local anchorPoints = {
		Vector2.new(0, 0),
		Vector2.new(1, 0),
		Vector2.new(1, 1),
		Vector2.new(0, 1),
	}

	for i = 1, 4 do
		local img = Instance.new("ImageLabel")
		img.Name = "Corner_" .. i
		img.Image = ARROW_TARGET
		img.ImageColor3 = color
		img.BackgroundTransparency = 1
		img.Size = UDim2.fromScale(0.3, 0.3)
		img.ImageTransparency = 1
		img.Position = positions[i]
		img.AnchorPoint = anchorPoints[i]
		img.Rotation = rotations[i]
		img.ResampleMode = Enum.ResamplerMode.Pixelated
		img.ScaleType = Enum.ScaleType.Fit
		img.Parent = container
		corners[#corners + 1] = img
	end

	return {
		Container = container,
		Corners = corners,
		Visible = false,
	}
end

local SelectedReticle = CreateReticle("SelectedReticle", Color3.fromRGB(255, 50, 50))
local HoverReticle = CreateReticle("HoverReticle", Color3.fromRGB(255, 255, 255))

--==[ Controller ]==--
local TargetController = {}
local CurrentTargetEntity: jecs.Entity?
local HoverTargetEntity: jecs.Entity? = nil

local SelectionStartTime = 0
local LastHoverCheck = 0

function TargetController.Appear()
	TargetTransparency = 0
end

function TargetController.Disappear()
	TargetTransparency = 1
end

function TargetController.GetTarget(): (jecs.Entity?, Vector3?)
	if not CurrentTargetEntity then return nil, nil end

	if not World:contains(CurrentTargetEntity) then
		TargetController.OnTargetDestroyed()
		return nil, nil
	end

	local cf = World:get(CurrentTargetEntity, Components.CFrame)
	if cf then return CurrentTargetEntity, cf.Position end

	TargetController.OnTargetDestroyed()
	return nil, nil
end

function TargetController.SwitchToNextTarget(oldTarget: jecs.Entity)
	if CurrentTargetEntity ~= oldTarget then return end

	local oldCF = World:get(oldTarget, Components.CFrame)
	local searchPos = if oldCF then oldCF.Position else Camera.CFrame.Position + (Camera.CFrame.LookVector * 10)

	local bestEntity = nil
	local bestDist = MAX_SELECTION_DIST

	for entity, cf in World:query(Components.CFrame, Tags.Enemy) do
		if entity == oldTarget then continue end

		local dist = (cf.Position - searchPos).Magnitude

		if dist > bestDist then continue end

		local _, onScreen = Camera:WorldToViewportPoint(cf.Position)
		if not onScreen then continue end

		bestDist = dist
		bestEntity = entity
	end

	if bestEntity then
		CurrentTargetEntity = bestEntity
		SelectionStartTime = os.clock()
		TargetController.Appear()
	else
		TargetController.OnTargetDestroyed()
	end
end

function TargetController.OnTargetDestroyed()
	CurrentTargetEntity = nil
	SelectedReticle.Container.Visible = false
end

local function GetClosestEntityToMouse(): jecs.Entity?
	local mousePos = UserInputService:GetMouseLocation()
	local bestEntity = nil
	local bestDist = SELECTION_THRESHOLD_PX

	for entity, cf in World:query(Components.CFrame, Tags.Enemy) do
		if entity == CurrentTargetEntity then continue end

		local worldPos = cf.Position
		local distToCamera = (worldPos - Camera.CFrame.Position).Magnitude

		if distToCamera > MAX_SELECTION_DIST then continue end

		local screenPos, onScreen = Camera:WorldToViewportPoint(worldPos)
		if not onScreen then continue end

		local distToMouse = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude

		if distToMouse < bestDist then
			bestDist = distToMouse
			bestEntity = entity
		end
	end

	return bestEntity
end

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.UserInputType ~= Enum.UserInputType.MouseWheel and input.KeyCode ~= Enum.KeyCode.E then return end
	local target = GetClosestEntityToMouse()
	if not target then return end

	CurrentTargetEntity = target
	SelectionStartTime = os.clock()

	HoverTargetEntity = nil
	HoverReticle.Container.Visible = false
	-- TODO: SOUND
end)

local function GetProjectedSize(dist: number, studs: number): number
	local viewportHeight = Camera.ViewportSize.Y
	local fov = math.rad(Camera.FieldOfView)

	local pixelSize = (studs * viewportHeight) / (2 * dist * math.tan(fov / 2))

	return math.clamp(pixelSize, MIN_SIZE_PX, MAX_SIZE_PX)
end

local function UpdateReticleVisuals(reticle: Reticle, entity: jecs.Entity, dt: number, isSelected: boolean)
	if CurrentTransparency >= 0.99 then
		reticle.Container.Visible = false
		return
	end

	local cf = World:get(entity, Components.CFrame)
	local radius = World:get(entity, Components.Radius) or DEFAULT_RADIUS

	if not cf then
		reticle.Container.Visible = false
		return
	end

	local worldPos = cf.Position
	local dist = (worldPos - Camera.CFrame.Position).Magnitude
	local screenPos, onScreen = Camera:WorldToViewportPoint(worldPos)

	if not onScreen then
		reticle.Container.Visible = false
		return
	end

	reticle.Container.Visible = true
	reticle.Container.Position = UDim2.fromOffset(screenPos.X, screenPos.Y)

	local finalAlpha = BASE_TRANSPARENCY + ((1 - BASE_TRANSPARENCY) * CurrentTransparency)
	for _, corner in reticle.Corners do
		corner.ImageTransparency = finalAlpha
	end

	local basePixelSize = GetProjectedSize(dist, radius * RETICLE_SIZE_MULT)

	if isSelected then
		local timeActive = os.clock() - SelectionStartTime

		local shrinkFactor = math.clamp(1 - (timeActive * 3), 0, 1)
		local animMultiplier = 1 + (1.5 * shrinkFactor)
		local currentSize = basePixelSize * animMultiplier

		reticle.Container.Size = UDim2.fromOffset(currentSize, currentSize)

		if shrinkFactor < 0.1 then
			local rotSpeed = 90
			reticle.Container.Rotation += rotSpeed * dt
		else
			reticle.Container.Rotation = 0
		end
	else
		reticle.Container.Size = UDim2.fromOffset(basePixelSize, basePixelSize)
		reticle.Container.Rotation = 0
	end
end

local function targetSystem(dt: number)
	if math.abs(CurrentTransparency - TargetTransparency) > 0.001 then
		CurrentTransparency = CurrentTransparency
			+ (TargetTransparency - CurrentTransparency) * math.min(dt * FADE_SPEED, 1)
	else
		CurrentTransparency = TargetTransparency
	end

	debug.profilebegin("Target")

	if os.clock() - LastHoverCheck > HOVER_UPDATE_RATE then
		HoverTargetEntity = GetClosestEntityToMouse()
		LastHoverCheck = os.clock()
	end

	if CurrentTargetEntity then
		if not World:contains(CurrentTargetEntity) or not World:has(CurrentTargetEntity, Tags.Enemy) then
			TargetController.OnTargetDestroyed()
		else
			UpdateReticleVisuals(SelectedReticle, CurrentTargetEntity, dt, true)
		end
	else
		SelectedReticle.Container.Visible = false
	end

	if HoverTargetEntity and HoverTargetEntity ~= CurrentTargetEntity then
		if World:contains(HoverTargetEntity) then
			UpdateReticleVisuals(HoverReticle, HoverTargetEntity, dt, false)
		else
			HoverTargetEntity = nil
			HoverReticle.Container.Visible = false
		end
	else
		HoverReticle.Container.Visible = false
		HoverTargetEntity = nil
	end

	debug.profileend()
end

RunService.PreSimulation:Connect(targetSystem)

return TargetController
