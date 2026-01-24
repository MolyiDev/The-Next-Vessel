local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Butler = require(ReplicatedStorage.Packages.Butler)
local jecs = require(ReplicatedStorage.Packages.jecs)

local Components = {
	-- Player
	Player = jecs.component() :: jecs.Id<Player>,
	Model = jecs.component() :: jecs.Id<Model>,
	Animator = jecs.component() :: jecs.Id<Animator>,
	Humanoid = jecs.component() :: jecs.Id<Humanoid>,
	HumanoidRootPart = jecs.component() :: jecs.Id<BasePart>,
	Sounds = jecs.component() :: jecs.Id<{ [number]: Sound }>,

	-- Projectiles
	CFrame = jecs.component() :: jecs.Id<CFrame>,
	Target = jecs.component() :: jecs.Id<BasePart | Attachment>,
	Direction = jecs.component() :: jecs.Id<Vector3>,
	Speed = jecs.component() :: jecs.Id<number>,
	Radius = jecs.component() :: jecs.Id<number>,
	Bone = jecs.component() :: jecs.Id<Bone>,
	Attachment = jecs.component() :: jecs.Id<Attachment>,
	Health = jecs.component() :: jecs.Id<number>,
	Damage = jecs.component() :: jecs.Id<number>,
	Type = jecs.component() :: jecs.Id<number>,
	Sender = jecs.component() :: jecs.Id<number>,

	-- Damage Numbers
	TextLabel = jecs.component() :: jecs.Id<TextLabel>,
	WorldPos = jecs.component() :: jecs.Id<Vector3>,
	Velocity = jecs.component() :: jecs.Id<number>,
	LifeTime = jecs.component() :: jecs.Id<number>,
	MaxLife = jecs.component() :: jecs.Id<number>,

	-- Target
	ImageLabel = jecs.component() :: jecs.Id<ImageLabel>,

	-- Cleanup
	Cleanup = jecs.component() :: jecs.Id<(entity: jecs.Entity) -> ()>,
	Butler = jecs.component() :: jecs.Id<Butler.Butler>,
}

-- Names
for key, component in Components :: { [string]: jecs.Entity } do
	jecs.meta(component, jecs.Name, key)
end

return table.freeze(Components)
