export type TCharacter = {
	Head: BasePart,
	HumanoidRootPart: BasePart,
	["Left Arm"]: BasePart,
	["Left Leg"]: BasePart,
	["Right Arm"]: BasePart,
	["Right Leg"]: BasePart,
	Torso: BasePart,
	Humanoid: THumanoid,
} & Model

export type THumanoid = {
	Animator: Animator,
} & Humanoid

return nil
