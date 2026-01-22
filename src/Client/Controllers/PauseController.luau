local UserInputService = game:GetService("UserInputService")

local PauseController = {}

UserInputService.InputBegan:Connect(function(input, gp)
	if gp or input.KeyCode ~= Enum.KeyCode.P then return end
end)

return PauseController
