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

local blockFrame = Instance.new("CanvasGroup")
blockFrame.Size = UDim2.fromScale(1, 1)
blockFrame.BackgroundColor3 = Color3.new()
blockFrame.GroupTransparency = 1
blockFrame.Parent = screenGui

local blockText = Instance.new("TextLabel")
blockText.Position = UDim2.fromScale(0.5, 0.5)
blockText.Size = UDim2.fromScale(0.5, 0.2)
blockText.BackgroundColor3 = Color3.new()
blockText.BackgroundTransparency = 1
blockText.FontFace = Font.new("rbxasset://fonts/families/Fondamento.json")
blockText.TextScaled = true
blockText.RichText = true
blockText.Text = ""
blockText.TextColor3 = Color3.new(1, 1, 1)
blockText.TextStrokeTransparency = 0
blockText.AnchorPoint = Vector2.new(0.5, 0.5)
blockText.Parent = blockFrame

screenGui.Parent = Player:WaitForChild("PlayerGui") :: PlayerGui

local function tweenPromise(transparency: number)
	return Promise.new(function(resolve, _, onCancel)
		local tween = TweenService:Create(blockFrame, TWEEN_INFO, { GroupTransparency = transparency })
		tween:Play()

		local conn
		conn = tween.Completed:Connect(function()
			conn:Disconnect()
			resolve()
		end)

		onCancel(function()
			if conn then conn:Disconnect() end
			tween:Cancel()
			blockFrame.GroupTransparency = 1
		end)
	end)
end

function BlackoutController.Transparency(transparency: number)
	return tweenPromise(transparency)
end

function BlackoutController.Text(text: string)
	blockText.Text = text
end

return BlackoutController
