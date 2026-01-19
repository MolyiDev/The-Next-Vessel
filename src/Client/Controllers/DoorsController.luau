local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local OPEN_TWEEN_INFO = TweenInfo.new(2, Enum.EasingStyle.Back, Enum.EasingDirection.InOut)
local CLOSE_TWEEN_INFO = TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.InOut)

local function getOriginCFrame(door: BasePart): CFrame
	local origin = door:GetAttribute("OriginalCFrame") :: CFrame

	if not origin then
		origin = door.CFrame
		door:SetAttribute("OriginalCFrame", origin)
	end

	return origin
end

local function animateDoor(door: BasePart, twInfo: TweenInfo, targetCFrame: CFrame)
	TweenService:Create(door, twInfo, {
		CFrame = targetCFrame,
	}):Play()
end

local function isDoorClosed(door: BasePart)
	return door:GetAttribute("IsClosed")
end

local function openDoor(door: BasePart, angle: number, time: number?)
	local origin = getOriginCFrame(door)
	local pivot = door.PivotOffset

	local target = origin * pivot * CFrame.Angles(0, math.rad(angle), 0) * pivot:Inverse()

	local tweenInfo = if time
		then TweenInfo.new(time, Enum.EasingStyle.Back, Enum.EasingDirection.InOut)
		else OPEN_TWEEN_INFO

	animateDoor(door, tweenInfo, target)
	door:SetAttribute("IsClosed", false)
end

local function closeDoor(door: BasePart, time: number?)
	local origin = getOriginCFrame(door)

	local tweenInfo = if time
		then TweenInfo.new(time, Enum.EasingStyle.Back, Enum.EasingDirection.InOut)
		else OPEN_TWEEN_INFO

	animateDoor(door, tweenInfo, origin)
	door:SetAttribute("IsClosed", true)
end

local DoorsController = {}

function DoorsController.Open(time: number?)
	local doors = CollectionService:GetTagged("Door")

	for _, door in doors do
		if not isDoorClosed(door) then continue end

		local angle = (door.Name == "DoorRight") and -90 or 90
		openDoor(door, angle, time)
	end
end

function DoorsController.Close(time: number?)
	local doors = CollectionService:GetTagged("Door")

	for _, door in doors do
		if isDoorClosed(door) then continue end

		closeDoor(door, time)
	end
end

function DoorsController.Toggle(time: number?)
	local doors = CollectionService:GetTagged("Door")

	for _, door in doors do
		if isDoorClosed(door) then
			local angle = (door.Name == "DoorRight") and -90 or 90
			openDoor(door, angle, time)
		else
			closeDoor(door, time)
		end
	end
end

function DoorsController.IsClosed()
	local doors = CollectionService:GetTagged("Door")

	for _, door in doors do
		if isDoorClosed(door) then return true end
	end

	return false
end

return DoorsController
