local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundsController = require(script.Parent.SoundsController)
local Promise = require(ReplicatedStorage.Shared.Utils.Promise)
local ESounds = require(ReplicatedStorage.Types.Enums.ESounds)

export type Torch = {
	Effects: Attachment,
	Lights: {
		FarLight: PointLight,
		NearLight: PointLight,
	} & BasePart,
} & Model

local NEAR_LIGHT_BRIGTHNESS = 0.5
local FAR_LIGHT_BRIGTHNESS = 0.25

local LIGHT_TWEEN_INFO = TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local UNLIGHT_TWEEN_INFO = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In)

local Torches = CollectionService:GetTagged("Torch")
local TorchesPerRow: { [number]: { Torch } } = {}

for _, torch in Torches do
	local row = torch:GetAttribute("Row") :: number
	if not row then continue end
	local torchArray = TorchesPerRow[row]

	if not torchArray then
		torchArray = {}
		TorchesPerRow[row] = torchArray
	end

	torchArray[#torchArray + 1] = torch
end

local function isTorchLighted(torch: Torch)
	return torch:GetAttribute("IsLighted")
end

local function lightTorch(torch: Torch, time: number?, deafenSound: boolean?)
	for _, particle in torch.Effects:GetChildren() do
		if not particle:IsA("ParticleEmitter") then continue end
		particle.Enabled = true
	end

	local tweenInfo = if time
		then TweenInfo.new(time, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		else LIGHT_TWEEN_INFO

	TweenService:Create(torch.Lights.NearLight, tweenInfo, {
		Brightness = NEAR_LIGHT_BRIGTHNESS,
	}):Play()

	TweenService:Create(torch.Lights.FarLight, tweenInfo, {
		Brightness = FAR_LIGHT_BRIGTHNESS,
	}):Play()

	if not deafenSound then SoundsController.Play(ESounds.IgniteFlame, torch) end
	torch:SetAttribute("IsLighted", true)
end

local function unlightTorch(torch: Torch, time: number?)
	for _, particle in torch.Effects:GetChildren() do
		if not particle:IsA("ParticleEmitter") then continue end
		particle.Enabled = false
	end

	local tweenInfo = if time
		then TweenInfo.new(time, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		else UNLIGHT_TWEEN_INFO

	TweenService:Create(torch.Lights.NearLight, tweenInfo, {
		Brightness = 0,
	}):Play()

	TweenService:Create(torch.Lights.FarLight, tweenInfo, {
		Brightness = 0,
	}):Play()

	torch:SetAttribute("IsLighted", false)
end

local TorchesController = {}
TorchesController.ROWS = 4

function TorchesController.Light(row: number, time: number?, deafenSound: boolean?)
	local rowTorches = TorchesPerRow[row]
	if not rowTorches then return end

	for _, torch in rowTorches do
		if isTorchLighted(torch) then continue end
		lightTorch(torch, time, deafenSound)
	end
end

function TorchesController.Unlight(row: number, time: number?)
	local rowTorches = TorchesPerRow[row]
	if not rowTorches then return end

	for _, torch in rowTorches do
		if not isTorchLighted(torch) then continue end
		unlightTorch(torch, time)
	end
end

function TorchesController.LightAll(deafenSound: boolean?, time: number?)
	for i = 1, TorchesController.ROWS do
		TorchesController.Light(i, time, deafenSound)
	end
end

function TorchesController.UnlightAll(time: number?)
	for i = 1, TorchesController.ROWS do
		TorchesController.Unlight(i, time)
	end
end

function TorchesController.Toggle(row: number, time: number?)
	local rowTorches = TorchesPerRow[row]
	if not rowTorches then return end

	for _, torch in rowTorches do
		if isTorchLighted(torch) then
			unlightTorch(torch, time)
		else
			lightTorch(torch, time)
		end
	end
end

function TorchesController.LightAllTorchesInSequence(betweenSeconds: number)
	return Promise.new(function(resolve, _, onCancel)
		local thread = task.spawn(function()
			for i = 1, TorchesController.ROWS do
				TorchesController.Light(i)
				task.wait(betweenSeconds)
			end

			resolve()
		end)

		onCancel(function()
			task.cancel(thread)
		end)
	end)
end

return TorchesController
