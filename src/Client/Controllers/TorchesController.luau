local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

export type Torch = {
	Ignite: Sound,
	Loop: Sound,
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

local function lightTorch(torch: Torch)
	for _, particle in torch.Effects:GetChildren() do
		if not particle:IsA("ParticleEmitter") then continue end
		particle.Enabled = true
	end

	TweenService:Create(torch.Lights.NearLight, LIGHT_TWEEN_INFO, {
		Brightness = NEAR_LIGHT_BRIGTHNESS,
	}):Play()

	TweenService:Create(torch.Lights.FarLight, LIGHT_TWEEN_INFO, {
		Brightness = FAR_LIGHT_BRIGTHNESS,
	}):Play()

	torch.Ignite:Play()
	-- torch.Loop:Play()

	torch:SetAttribute("IsLighted", true)
end

local function unlightTorch(torch: Torch)
	for _, particle in torch.Effects:GetChildren() do
		if not particle:IsA("ParticleEmitter") then continue end
		particle.Enabled = false
	end

	TweenService:Create(torch.Lights.NearLight, UNLIGHT_TWEEN_INFO, {
		Brightness = 0,
	}):Play()

	TweenService:Create(torch.Lights.FarLight, UNLIGHT_TWEEN_INFO, {
		Brightness = 0,
	}):Play()

	torch.Ignite:Stop()
	torch.Loop:Stop()

	torch:SetAttribute("IsLighted", false)
end

local TorchesController = {}
TorchesController.ROWS = 7

function TorchesController.Light(row: number)
	local rowTorches = TorchesPerRow[row]
	if not rowTorches then return end

	for _, torch in rowTorches do
		if isTorchLighted(torch) then continue end
		lightTorch(torch)
	end
end

function TorchesController.Unlight(row: number)
	local rowTorches = TorchesPerRow[row]
	if not rowTorches then return end

	for _, torch in rowTorches do
		if not isTorchLighted(torch) then continue end
		unlightTorch(torch)
	end
end

function TorchesController.Toggle(row: number)
	local rowTorches = TorchesPerRow[row]
	if not rowTorches then return end

	for _, torch in rowTorches do
		if isTorchLighted(torch) then
			unlightTorch(torch)
		else
			lightTorch(torch)
		end
	end
end

return TorchesController
