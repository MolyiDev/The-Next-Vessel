local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ESounds = require(ReplicatedStorage.Types.Enums.ESounds)
local SoundsController = require(script.Parent.SoundsController)

local OPEN_TIME = 0.9
local CLOSE_TIME = 0.7
local EASING_STYLE = Enum.EasingStyle.Back
local OPEN_EASING_DIRECTION = Enum.EasingDirection.Out
local CLOSE_EASING_DIRECTION = Enum.EasingDirection.In

local ActiveAnimations: { [Model]: RBXScriptConnection } = {}

local function getOriginPivot(door: Model): CFrame
	local origin = door:GetAttribute("OriginalPivot") :: CFrame

	if not origin then
		origin = door:GetPivot()
		door:SetAttribute("OriginalPivot", origin)
	end

	return origin
end

local function animateDoor(
	door: Model,
	targetCFrame: CFrame,
	duration: number,
	easingStyle: Enum.EasingStyle,
	easingDirection: Enum.EasingDirection
)
	if ActiveAnimations[door] then
		ActiveAnimations[door]:Disconnect()
		ActiveAnimations[door] = nil
	end

	local startCFrame = door:GetPivot()
	local elapsed = 0

	local connection
	connection = RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		local alpha = math.min(elapsed / duration, 1)

		local easedAlpha = TweenService:GetValue(alpha, easingStyle, easingDirection)
		local currentCFrame = startCFrame:Lerp(targetCFrame, easedAlpha)

		door:PivotTo(currentCFrame)

		if alpha >= 1 then
			connection:Disconnect()
			ActiveAnimations[door] = nil
		end
	end)

	ActiveAnimations[door] = connection
end

local function isDoorClosed(door: BasePart)
	return door:GetAttribute("IsClosed")
end

local function openDoor(door: Model, angle: number, time: number?)
	local origin = getOriginPivot(door)
	local target = origin * CFrame.Angles(0, math.rad(angle), 0)

	animateDoor(door, target, time or OPEN_TIME, EASING_STYLE, OPEN_EASING_DIRECTION)
	door:SetAttribute("IsClosed", false)
end

local function closeDoor(door: Model, time: number?)
	local origin = getOriginPivot(door)

	animateDoor(door, origin, time or CLOSE_TIME, EASING_STYLE, CLOSE_EASING_DIRECTION)
	door:SetAttribute("IsClosed", true)
end

local DoorsController = {}

function DoorsController.Open(time: number?)
	local doors = CollectionService:GetTagged("Door")
	local parent: Instance

	for _, door in doors do
		if not isDoorClosed(door) then continue end

		parent = door.Parent
		local angle = (door.Name == "DoorRight") and -80 or 80
		openDoor(door, angle, time)
	end

	if parent then SoundsController.Play(ESounds.OpenDoor, parent) end
end

function DoorsController.Close(time: number?)
	local doors = CollectionService:GetTagged("Door")
	local parent: Instance

	for _, door in doors do
		if isDoorClosed(door) then continue end

		parent = door.Parent
		closeDoor(door, time)
	end

	if parent then SoundsController.Play(ESounds.CloseDoor, parent) end
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

function DoorsController.PlayCloseSound()
	local door = CollectionService:GetTagged("Door")[1]
	if door and door.Parent then SoundsController.Play(ESounds.CloseDoor, door.Parent) end
end

function DoorsController.PlayOpenSound()
	local door = CollectionService:GetTagged("Door")[1]
	if door and door.Parent then SoundsController.Play(ESounds.OpenDoor, door.Parent) end
end

return DoorsController
