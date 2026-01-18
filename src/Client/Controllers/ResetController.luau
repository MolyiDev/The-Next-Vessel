local HealthController = require(script.Parent.HealthController)

local resetBindable = Instance.new("BindableEvent")

resetBindable.Event:Connect(function()
	HealthController.SetHealth(0)
end)

while true do
	local success, _ = pcall(function()
		game:GetService("StarterGui"):SetCore("ResetButtonCallback", resetBindable)
	end)

	if success then break end
	task.wait()
end

return nil
