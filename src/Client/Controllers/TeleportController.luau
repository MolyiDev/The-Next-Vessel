local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local ELocations = require(ReplicatedStorage.Types.Enums.ELocations)
local TCharacter = require(ReplicatedStorage.Types.TCharacter)
local CameraController = require(script.Parent.CameraController)
local TweensController = require(script.Parent.TweensController)

local Player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local SoulRealmCamera = CollectionService:GetTagged("SoulRealmCamera")[1] :: BasePart

local TeleportController = {}

function TeleportController.Teleport(location: number)
	local character = Player.Character :: TCharacter.TCharacter

	if location == ELocations.SoulRealm then
		if character then character.Humanoid.AutoRotate = false end
		Camera.CameraSubject = SoulRealmCamera
		CameraController.UnlockCamera()
		CameraController.Update()
		TweensController.SetImmobile(false, 0.01)
	elseif character then
		Camera.Focus = character.Head
		character.Humanoid.AutoRotate = true
		CameraController.HideMouse()
		CameraController.LockCamera()
		TweensController.SetImmobile(false, 0.01)
		CameraController.Update()
	end
end

function TeleportController.CharacterTeleport() end

return TeleportController
