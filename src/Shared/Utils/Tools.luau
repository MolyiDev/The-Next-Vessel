local Tools = {}
Tools.FONT_SILKSCREEN_BOLD = Font.new("rbxassetid://12187371840", Enum.FontWeight.Bold, Enum.FontStyle.Normal)

function Tools.WorldMovingDirection(direction: Vector3)
	if direction == Vector3.zero then return direction end

	local angle = math.atan2(direction.X, -direction.Z)
	local quarterTurn = math.pi / 4
	angle = -math.round(angle / quarterTurn) * quarterTurn
	local newX = math.round(-math.sin(angle))
	local newZ = math.round(-math.cos(angle))
	if math.abs(newX) <= 1e-10 then newX = 0 end
	if math.abs(newZ) <= 1e-10 then newZ = 0 end

	return Vector3.new(newX, 0, newZ)
end

function Tools.Lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

function Tools.DarkenColor(color: Color3, factor: number): Color3
	return color:Lerp(Color3.new(), factor)
end

function Tools.LightenColor(color: Color3, factor: number): Color3
	return color:Lerp(Color3.new(1, 1, 1), factor)
end

function Tools.CreateGenericScreenGui(name: string)
	local screenGui = Instance.new("ScreenGui")
	screenGui.ClipToDeviceSafeArea = false
	screenGui.ScreenInsets = Enum.ScreenInsets.None
	screenGui.IgnoreGuiInset = true
	screenGui.ResetOnSpawn = false
	screenGui.Name = name
	return screenGui
end

return Tools
