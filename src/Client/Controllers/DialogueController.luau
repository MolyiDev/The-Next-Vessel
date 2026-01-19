local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")
local DialogueUI = require(StarterPlayer.StarterPlayerScripts.Client.UI.DialogueUI)
local Butler = require(ReplicatedStorage.Packages.Butler)
local Fluid = require(ReplicatedStorage.Shared.Utils.Fluid)
local Promise = require(ReplicatedStorage.Shared.Utils.Promise)
local ECharacters = require(ReplicatedStorage.Types.Enums.ECharacters)

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local TalkSoundsFolder = ReplicatedStorage:WaitForChild("Sounds"):WaitForChild("Talk") :: Folder

local BASE_SPEED = 0.04
local BASE_PITCH = 1.0
local PITCH_VAR = 0.05
local FADE_TIME = 0.4
local INPUT_KEY = Enum.KeyCode.F

export type Dialogue = {
	Id: number,
	Dialogue: string,
	Name: string?,
	Image: string?,
	Sound: Sound?,
}

local CHARACTERS: { [number]: { Name: string, NameColor: Color3, Image: string, Sound: Sound } } = {
	[ECharacters.Hero] = {
		Name = "Hero",
		NameColor = Color3.fromRGB(255, 247, 0),
		Image = "rbxassetid://72889430595307",
		Sound = TalkSoundsFolder:WaitForChild("Hero") :: Sound,
	},
	[ECharacters.God] = {
		Name = "God",
		NameColor = Color3.fromRGB(255, 255, 255),
		Image = "rbxassetid://93063863161723",
		Sound = TalkSoundsFolder:WaitForChild("God") :: Sound,
	},
	[ECharacters.DemonKing] = {
		Name = "Demon King",
		NameColor = Color3.fromRGB(255, 3, 83),
		Image = "rbxassetid://93063863161723",
		Sound = TalkSoundsFolder:WaitForChild("DemonKing") :: Sound,
	},
	[ECharacters.DemonGod] = {
		Name = "Demon God",
		NameColor = Color3.fromRGB(70, 0, 1),
		Image = "rbxassetid://93063863161723",
		Sound = TalkSoundsFolder:WaitForChild("DemonGod") :: Sound,
	},
}

local Dialogue = {}
local CurrentPromise: Promise.Promise?
local CurrentButler: Butler.Butler?
local UI: DialogueUI.DialogueUIReturn

Fluid.mount(function()
	UI = DialogueUI()
	return UI.UI
end, PlayerGui)

local function ParseRichText(rawText: string)
	local cleanText = ""
	local commands = {}
	local currentIndex = 0

	local pos = 1
	while pos <= #rawText do
		local startTag, endTag = string.find(rawText, "<[^>]+>", pos)

		if not startTag or not endTag then
			cleanText = cleanText .. string.sub(rawText, pos)
			break
		end

		local preText = string.sub(rawText, pos, startTag - 1)
		cleanText = cleanText .. preText
		currentIndex = currentIndex + (utf8.len(preText) :: number)

		local tagContent = string.sub(rawText, startTag + 1, endTag - 1)
		local tagName = string.match(tagContent, "^/?(%w+)") :: string

		-- Whitelist standard Roblox RichText tags so we don't treat them as commands
		local isRichText = table.find({ "b", "i", "u", "s", "font", "stroke", "sc", "br" }, tagName)

		if isRichText then
			cleanText = cleanText .. string.sub(rawText, startTag, endTag)
		else
			local args = {}
			for k, v in string.gmatch(tagContent, "(%w+)=[\"']([^\"']+)[\"']") do
				args[k] = tonumber(v) or v
			end

			local isClosing = string.sub(tagContent, 1, 1) == "/"

			if not commands[currentIndex + 1] then commands[currentIndex + 1] = {} end
			table.insert(commands[currentIndex + 1], {
				Name = tagName,
				Args = args,
				IsClosing = isClosing,
			})
		end

		pos = endTag + 1
	end

	return cleanText, commands
end

local function ApplyFlicker(butler: Butler.Butler, baseText: string, options: string, speed: number)
	local parts = string.split(options, "|")
	if #parts < 2 then return end

	local lastUpdate = 0
	local idx = 1

	butler:Connect(RunService.Heartbeat, function()
		if os.clock() - lastUpdate > (speed or 0.1) then
			lastUpdate = os.clock()
			idx = (idx % #parts) + 1
			if UI then UI.Refs.Text.Text = string.gsub(baseText, parts[idx == 1 and 2 or 1], parts[idx]) end
		end
	end)
end

--// Public API

function Dialogue.Talk(dialogue: Dialogue): Promise.Promise
	if CurrentPromise and CurrentPromise:getStatus() == Promise.Status.Started then CurrentPromise:cancel() end

	CurrentPromise = Promise.new(function(resolve, _, onCancel)
		local butler = Butler.new()
		CurrentButler = butler

		onCancel(function()
			butler:Clean()
			if UI then UI.Disappear() end
		end)

		-- 1. Setup UI
		local charData = CHARACTERS[dialogue.Id]
		local refs = UI.Refs

		refs.Name.Text = tostring(dialogue.Name or charData.Name) -- You might want a display name map here
		refs.Name.TextColor3 = charData.NameColor
		refs.NextIndicator.Visible = false
		refs.Text.MaxVisibleGraphemes = 0

		-- 2. Parse & Fade In
		local cleanText, commands = ParseRichText(dialogue.Dialogue)
		refs.Text.Text = cleanText

		UI.Appear()
		task.wait(FADE_TIME)

		-- 3. Typewriter Loop
		local totalGraphemes = utf8.len(cleanText) :: number
		local currentGrapheme = 0
		local currentSpeed = BASE_SPEED
		local currentPitch = BASE_PITCH
		local isSkipped = false

		local inputConn
		inputConn = butler:Connect(UserInputService.InputBegan, function(input)
			if input.KeyCode == INPUT_KEY then
				isSkipped = true
				butler:Remove(inputConn)
			end
		end)

		while currentGrapheme < totalGraphemes do
			if isSkipped then
				refs.Text.MaxVisibleGraphemes = -1
				break
			end

			currentGrapheme += 1

			-- Apply commands (Speed, Pitch, Flicker)
			if commands[currentGrapheme] then
				for _, cmd in ipairs(commands[currentGrapheme]) do
					if cmd.Name == "speed" then
						currentSpeed = cmd.IsClosing and BASE_SPEED or (tonumber(cmd.Args.val) or BASE_SPEED)
					elseif cmd.Name == "pitch" then
						currentPitch = cmd.IsClosing and BASE_PITCH or (tonumber(cmd.Args.val) or BASE_PITCH)
					elseif cmd.Name == "flicker" then
						ApplyFlicker(butler, cleanText, cmd.Args.text :: string, tonumber(cmd.Args.speed) :: number)
					end
				end
			end

			refs.Text.MaxVisibleGraphemes = currentGrapheme
			local sound = dialogue.Sound or charData.Sound

			-- Play Sound
			if sound and currentGrapheme % 2 == 0 then
				local s = sound:Clone()
				s.Parent = UI.UI
				s.PlaybackSpeed = currentPitch + ((math.random() - 0.5) * PITCH_VAR)
				s:Play()
				game.Debris:AddItem(s, 1)
			end

			task.wait(currentSpeed)
		end

		-- 4. Wait for Continuation
		refs.NextIndicator.Visible = true

		local dotTask = task.spawn(function()
			while true do
				for i = 1, 3 do
					refs.NextIndicator.Text = "Press F to skip" .. string.rep(".", i)
					task.wait(0.5)
				end
			end
		end)
		butler:Add(function()
			task.cancel(dotTask)
		end)

		-- Wait for Input
		local finished = false
		butler:Connect(UserInputService.InputBegan, function(input)
			if input.KeyCode == INPUT_KEY then finished = true end
		end)

		while not finished do
			RunService.Heartbeat:Wait()
		end

		-- 5. Cleanup
		refs.NextIndicator.Visible = false
		UI.Disappear()
		task.wait(FADE_TIME)

		butler:Clean()
		resolve()
	end)

	return CurrentPromise :: Promise.Promise
end

function Dialogue.Stop(yield: boolean)
	if CurrentPromise then
		CurrentPromise:cancel()
		CurrentPromise = nil
	end

	if CurrentButler then
		CurrentButler:Clean()
		CurrentButler = nil
	end

	if UI then
		UI.Disappear()
		if yield then task.wait(FADE_TIME) end
	end
end

return Dialogue
