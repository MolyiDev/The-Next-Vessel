local ReplicatedFirst = game:GetService("ReplicatedFirst")
local StarterGui = game:GetService("StarterGui")

ReplicatedFirst:RemoveDefaultLoadingScreen()

task.spawn(function()
	local success = false

	while not success do
		success = pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
		end)

		if not success then task.wait() end
	end
end)
