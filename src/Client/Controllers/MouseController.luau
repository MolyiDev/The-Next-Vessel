local UserInputService = game:GetService("UserInputService")

local MouseController = {}
MouseController.IsMouseActive = true

function MouseController.HideMouse()
	UserInputService.MouseIconEnabled = false
end

function MouseController.ShowMouse()
	UserInputService.MouseIconEnabled = true
end

function MouseController.ToggleMouse()
	if MouseController.IsMouseActive then
		MouseController.HideMouse()
	else
		MouseController.ShowMouse()
	end
end

return MouseController
