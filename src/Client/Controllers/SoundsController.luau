local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local BossController = require(script.Parent.BossController)
local TimeController = require(script.Parent.TimeController)
local Ignis = require(ReplicatedStorage.Packages.Ignis)
local IdGenerator = require(ReplicatedStorage.Shared.Utils.IdGenerator)
local ESounds = require(ReplicatedStorage.Types.Enums.ESounds)

type SoundData = { Sound: Sound, BaseSpeed: number }

local Player = Players.LocalPlayer
local SoundsFolder = ReplicatedStorage:WaitForChild("Sounds")

local SoundsController = {}
local IdGen = IdGenerator.new("Sounds", 0, 65535)
local Sounds: { [number]: SoundData } = {}
local ActiveSounds: { [number]: SoundData } = {}

for _, sound in SoundsFolder:GetDescendants() do
	if not sound:IsA("Sound") then continue end
	local id = ESounds[sound.Name]
	if not id then continue end
	Sounds[id] = { Sound = sound, BaseSpeed = sound.PlaybackSpeed }
end

function SoundsController.Play(soundId: number, parent: any)
	local data = Sounds[soundId]
	if not data then return end
	local id = IdGen:Generate()

	local clone = data.Sound:Clone()
	clone.Parent = parent
	clone.Ended:Once(function()
		ActiveSounds[id] = nil
		clone:Destroy()
	end)
	clone.PlaybackSpeed = data.BaseSpeed * TimeController.TimeScale
	ActiveSounds[id] = data
	clone:Play()
end

function SoundsController.PlayCharacter(soundId: number)
	SoundsController.Play(soundId, SoundService)
end

function SoundsController.PlayBoss(soundId: number)
	local rig = BossController.GetRig()
	if not rig then return end
	SoundsController.Play(soundId, rig.PrimaryPart)
end

function SoundsController.AddSound(sound: Sound): number
	local id = IdGen:Generate()
	ActiveSounds[id] = { Sound = sound, BaseSpeed = sound.PlaybackSpeed }
	return id
end

function SoundsController.RemoveSound(id: number)
	ActiveSounds[id] = nil
end

TimeController.TimeScaleChanged:Connect(function(scale)
	for _, data in ActiveSounds do
		if data.Sound then data.Sound.PlaybackSpeed = data.BaseSpeed * scale end
	end
end)

return Ignis.Register(SoundsController)
