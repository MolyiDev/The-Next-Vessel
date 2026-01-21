local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local SoundsController = require(script.Parent.SoundsController)
local Ignis = require(ReplicatedStorage.Packages.Ignis)

local AnimatorConnection: RBXScriptConnection?
local EffectsGroup = SoundService:WaitForChild("Effects") :: SoundGroup
local FootstepsSounds = ReplicatedStorage:WaitForChild("Sounds"):WaitForChild("Footsteps") :: { [string]: Sound }
local AnimationNames = {
	Run = true,
	Walk = true,
}

local MIN_TREMOLO = 0.65
local MAX_TREMOLO = 0.95
local MIN_SPEED = 0.94
local MAX_SPEED = 1.06

local FootstepsController = {}

function FootstepsController.OnCharacterAdded(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart") :: BasePart
	local animator = humanoid:WaitForChild("Animator") :: Animator
	if not humanoid or not humanoidRootPart or not animator then
		warn(`Humanoid or RootPart or Animator don't spawned.`)
		return
	end

	if AnimatorConnection then
		AnimatorConnection:Disconnect()
		AnimatorConnection = nil
		return
	end

	AnimatorConnection = animator.AnimationPlayed:Connect(function(animationTrack: AnimationTrack)
		if not AnimationNames[animationTrack.Animation.Name] then return end

		local Connection = animationTrack:GetMarkerReachedSignal("Footstep"):Connect(function()
			local MaterialName = humanoid.FloorMaterial.Name
			if MaterialName == "Air" then return end
			local Sounds = FootstepsSounds[MaterialName]:GetChildren()
			local SelectedSound = Sounds[math.random(1, #Sounds)]:Clone() :: Sound
			SelectedSound.Parent = humanoidRootPart
			SelectedSound.SoundGroup = EffectsGroup
			local randomSpeed = math.random() * (MAX_SPEED - MIN_SPEED) + MIN_SPEED
			SelectedSound.PlaybackSpeed = math.round(randomSpeed * 1000) / 1000

			local tremoloSound = Instance.new("TremoloSoundEffect")
			local randomTremolo = math.random() * (MAX_TREMOLO - MIN_TREMOLO) + MIN_TREMOLO
			tremoloSound.Depth = math.round(randomTremolo * 1000) / 1000
			tremoloSound.Parent = SelectedSound
			local id = SoundsController.AddSound(SelectedSound)

			SelectedSound.Ended:Once(function()
				SoundsController.RemoveSound(id)
				SelectedSound:Destroy()
			end)

			SelectedSound:Play()
		end)

		animationTrack.Stopped:Once(function()
			Connection:Disconnect()
		end)
	end)
end

function FootstepsController.OnCharacterRemoving()
	if not AnimatorConnection then return end
	AnimatorConnection:Disconnect()
	AnimatorConnection = nil
end

return Ignis.Register(FootstepsController)
