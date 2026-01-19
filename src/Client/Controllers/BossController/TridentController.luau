local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Promise = require(ReplicatedStorage.Shared.Utils.Promise)
local TCharacter = require(ReplicatedStorage.Types.TCharacter)

local Trident = CollectionService:GetTagged("DemonTrident")[1] :: BasePart

local TRIDENT_SPEED = 160
local TRIDENT_VISUAL_OFFSET = CFrame.fromEulerAnglesYXZ(math.rad(-90), 0, 0)
local DEFAULT_POSITION = Trident.CFrame

local TridentController = {}
local currentThrowResolver: ((any) -> ())? = nil

function TridentController.Throw(speed: number?)
	speed = speed or TRIDENT_SPEED

	return Promise.new(function(resolve, reject, onCancel)
		local targetChar = Players.LocalPlayer.Character :: TCharacter.TCharacter
		local head = targetChar and targetChar:FindFirstChild("Head") :: BasePart

		if not head then
			reject("Missing Trident or Character")
			return
		end

		currentThrowResolver = resolve

		local currentPosition = Trident.Position
		local connection = nil

		local function cleanup()
			if connection then connection:Disconnect() end
			currentThrowResolver = nil
		end

		onCancel(cleanup)

		connection = RunService.Heartbeat:Connect(function(DeltaTime)
			if not Trident.Parent then
				cleanup()
				return
			end

			local TargetPosition = head.Position
			local Direction = (TargetPosition - currentPosition).Unit
			local StepDistance = TRIDENT_SPEED * DeltaTime

			local RayParams = RaycastParams.new()
			RayParams.FilterDescendantsInstances = { Trident }
			RayParams.FilterType = Enum.RaycastFilterType.Exclude

			local RayResult = Workspace:Raycast(currentPosition, Direction * StepDistance, RayParams)

			if RayResult then
				Trident.CFrame = CFrame.lookAt(RayResult.Position, RayResult.Position + Direction)
					* TRIDENT_VISUAL_OFFSET

				local HitModel = RayResult.Instance:FindFirstAncestorOfClass("Model")

				if HitModel and HitModel == targetChar then
					cleanup()
					resolve("Hit")
				else
					cleanup()
					resolve("Wall")
				end

				return
			end

			currentPosition = currentPosition + (Direction * StepDistance)
			Trident.CFrame = CFrame.lookAt(currentPosition, TargetPosition) * TRIDENT_VISUAL_OFFSET
		end)
	end)
end

function TridentController.ForceParry()
	if not currentThrowResolver then return end
	currentThrowResolver("Parried")
	currentThrowResolver = nil
end

function TridentController.Reset()
	Trident.CFrame = DEFAULT_POSITION
end

return TridentController
