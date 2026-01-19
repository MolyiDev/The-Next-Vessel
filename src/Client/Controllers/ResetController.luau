local HealthController = require(script.Parent.HealthController)
local SceneController = require(script.Parent.SceneController)

local resetBindable = Instance.new("BindableEvent")

resetBindable.Event:Connect(function()
	if HealthController.IsDead() then
		SceneController.Restart()
	else
		HealthController.Kill()
	end
end)

while true do
	local success, _ = pcall(function()
		game:GetService("StarterGui"):SetCore("ResetButtonCallback", resetBindable)
	end)

	if success then break end
	task.wait()
end

return nil
