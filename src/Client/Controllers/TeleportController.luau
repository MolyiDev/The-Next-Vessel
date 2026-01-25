local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local BlackoutController = require(script.Parent.BlackoutController)
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

	return BlackoutController.Transparency(0):andThen(function()
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

			Camera.CFrame = CFrame.new(Camera.CameraSubject.Position :: any) * CFrame.Angles(0, math.rad(-90), 0)
		end

		return BlackoutController.Transparency(1)
	end)
end

return TeleportController
