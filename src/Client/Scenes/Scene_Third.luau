local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Promise = require(ReplicatedStorage.Shared.Utils.Promise)
local TScene = require(ReplicatedStorage.Types.TScene)

type Scene = {
	ShouldRestart: boolean,
	CurrentPromise: Promise.Promise?,
	SelectedUpgrade: number?,
	FastSpawn: boolean,
	Corruption: number,
} & TScene.TScene

local Scene_Third = {} :: Scene
Scene_Third.IsActive = false
Scene_Third.ShouldRestart = true
Scene_Third.CurrentPromise = nil :: Promise.Promise?
Scene_Third.SelectedUpgrade = nil
Scene_Third.Corruption = 0

function Scene_Third.CharacterDied()
	return Scene_Third.ShouldRestart
end

return Scene_Third
