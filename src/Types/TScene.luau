local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TCharacter = require(script.Parent.TCharacter)
local Promise = require(ReplicatedStorage.Shared.Utils.Promise)

export type TScene = {
	IsActive: boolean,
	Start: () -> Promise.Promise,
	Stop: () -> (),
	Restart: () -> (),
	CharacterAdded: (character: TCharacter.TCharacter) -> (),
	CharacterDied: () -> boolean?,
}

return nil
