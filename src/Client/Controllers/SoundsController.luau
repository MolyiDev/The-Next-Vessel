local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local BossController = require(script.Parent.BossController)
local Ignis = require(ReplicatedStorage.Packages.Ignis)
local ESounds = require(ReplicatedStorage.Types.Enums.ESounds)

local Player = Players.LocalPlayer

local SoundsFolder = ReplicatedStorage:WaitForChild("Sounds")

local SoundsController = {}
local Sounds: { [number]: Sound } = {}

for _, sound in SoundsFolder:GetDescendants() do
	if not sound:IsA("Sound") then continue end
	local id = ESounds[sound.Name]
	if not id then continue end
	Sounds[id] = sound
end

local function play(parent: any, soundId: number)
	local sound = Sounds[soundId]
	if not sound then return end
	local clone = sound:Clone()
	clone.Parent = parent
	clone.Ended:Once(function()
		clone:Destroy()
	end)
	clone:Play()
end

function SoundsController.PlayCharacter(soundId: number)
	play(SoundService, soundId)
end

function SoundsController.PlayBoss(soundId: number)
	local rig = BossController.GetRig()
	if not rig then return end
	play(rig.PrimaryPart, soundId)
end

return Ignis.Register(SoundsController)
