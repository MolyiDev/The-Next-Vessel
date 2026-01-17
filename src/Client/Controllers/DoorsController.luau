local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local OPEN_TWEEN_INFO = TweenInfo.new(3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local CLOSE_TWEEN_INFO = TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.In)

local function animateDoor(door: BasePart, twInfo: TweenInfo, angle: number)
	local pivot = door.PivotOffset
	local cf = door.CFrame * pivot * CFrame.Angles(0, math.rad(angle), 0) * pivot:Inverse()
	TweenService:Create(door, twInfo, {
		CFrame = cf,
	}):Play()
end

local function isDoorClosed(door: BasePart)
	return door:GetAttribute("IsClosed") or true
end

local function openDoor(door: BasePart)
	animateDoor(door, OPEN_TWEEN_INFO, 90)
end

local function closeDoor(door: BasePart)
	animateDoor(door, CLOSE_TWEEN_INFO, -90)
end

local DoorsController = {}

function DoorsController.Open()
	local doors = CollectionService:GetTagged("Door")

	for _, door in doors do
		if not isDoorClosed(door) then continue end
		openDoor(door)
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
			openDoor(door)
		else
			closeDoor(door)
		end
	end
end

return DoorsController
