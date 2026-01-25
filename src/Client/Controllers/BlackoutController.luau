local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Promise = require(ReplicatedStorage.Shared.Utils.Promise)
local Tools = require(ReplicatedStorage.Shared.Utils.Tools)

local TWEEN_INFO = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

local Player = Players.LocalPlayer

local BlackoutController = {}

local screenGui = Tools.CreateGenericScreenGui("Teleport")
screenGui.DisplayOrder = -1

local blockFrame = Instance.new("Frame")
blockFrame.Size = UDim2.fromScale(1, 1)
blockFrame.BackgroundColor3 = Color3.new()
blockFrame.Transparency = 1
blockFrame.Parent = screenGui

screenGui.Parent = Player:WaitForChild("PlayerGui") :: PlayerGui

local function tweenPromise(transparency: number)
	return Promise.new(function(resolve, _, onCancel)
		local tween = TweenService:Create(blockFrame, TWEEN_INFO, { Transparency = transparency })
		tween:Play()

		local conn
		conn = tween.Completed:Connect(function()
			conn:Disconnect()
			resolve()
		end)

		onCancel(function()
			if conn then conn:Disconnect() end
			tween:Cancel()
			blockFrame.Transparency = 1
		end)
	end)
end

function BlackoutController.Transparency(transparency: number)
	return tweenPromise(transparency)
end

return BlackoutController
