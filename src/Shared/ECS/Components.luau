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
	Target = jecs.component() :: jecs.Id<BasePart>,
	Direction = jecs.component() :: jecs.Id<Vector3>,
	Speed = jecs.component() :: jecs.Id<number>,
	Radius = jecs.component() :: jecs.Id<number>,
	Bone = jecs.component() :: jecs.Id<Bone>,

	-- Cleanup
	Cleanup = jecs.component() :: jecs.Id<(entity: jecs.Entity) -> ()>,
	Butler = jecs.component() :: jecs.Id<Butler.Butler>,
}

-- Names
for key, component in Components :: { [string]: jecs.Entity } do
	jecs.meta(component, jecs.Name, key)
end

return table.freeze(Components)
