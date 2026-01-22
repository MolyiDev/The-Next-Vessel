local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local KnockbackController = {}

function KnockbackController.Knockback(direction: Vector3, force: number)
	local character = Player.Character
	if not character then return end
	local root = character.PrimaryPart
	if not root then return end
	root:ApplyImpulse(direction * force)
end

return KnockbackController
