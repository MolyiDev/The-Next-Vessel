local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local ELocations = require(ReplicatedStorage.Types.Enums.ELocations)
local TCharacter = require(ReplicatedStorage.Types.TCharacter)
local CameraController = require(script.Parent.CameraController)
local MouseController = require(script.Parent.MouseController)
local TweensController = require(script.Parent.TweensController)

local Player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local SoulRealmCamera = CollectionService:GetTagged("SoulRealmCamera")[1] :: BasePart

local TeleportController = {}

function TeleportController.Teleport(location: number)
	local character = Player.Character :: TCharacter.TCharacter

	if location == ELocations.SoulRealm then
		CameraController.EnableCinematicCamera()
		Camera.CameraSubject = SoulRealmCamera
		CameraController.UnlockCamera()
		TweensController.SetImmobile(false, 0.01)
	elseif character then
		CameraController.DisableCinematicCamera()
		MouseController.HideMouse()
		CameraController.LockCamera()
		TweensController.SetImmobile(false, 0.01)
	end
end

function TeleportController.CharacterTeleport() end

return TeleportController
