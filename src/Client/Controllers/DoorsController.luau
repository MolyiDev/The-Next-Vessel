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

local function openDoor(door: BasePart, angle: number)
	local origin = getOriginCFrame(door)
	local pivot = door.PivotOffset

	local target = origin * pivot * CFrame.Angles(0, math.rad(angle), 0) * pivot:Inverse()

	animateDoor(door, OPEN_TWEEN_INFO, target)
	door:SetAttribute("IsClosed", false)
end

local function closeDoor(door: BasePart)
	local origin = getOriginCFrame(door)

	animateDoor(door, CLOSE_TWEEN_INFO, origin)
	door:SetAttribute("IsClosed", true)
end

local DoorsController = {}

function DoorsController.Open()
	local doors = CollectionService:GetTagged("Door")

	for _, door in doors do
		if not isDoorClosed(door) then continue end

		local angle = (door.Name == "DoorRight") and -90 or 90
		openDoor(door, angle)
	end
end

function DoorsController.Close()
	local doors = CollectionService:GetTagged("Door")

	for _, door in doors do
		if isDoorClosed(door) then continue end

		closeDoor(door)
	end
end

function DoorsController.Toggle()
	local doors = CollectionService:GetTagged("Door")

	for _, door in doors do
		if isDoorClosed(door) then
			local angle = (door.Name == "DoorRight") and -90 or 90
			openDoor(door, angle)
		else
			closeDoor(door)
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
