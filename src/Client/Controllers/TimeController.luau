local TimeController = {}

TimeController.FIXED_DELTA_TIME = 1 / 60

-- Each function should make the projectiles stop / slow down / faster / resume
-- Each function should make the player movement stop / slow down / faster / resume
-- Each function should make the player dash stop / slow down / faster / resume
-- Each function should make the player animations stop / slow down / faster / resume
-- Each function should make the player camerafov stop / slow down / faster / resume
-- Each function should make the player blur stop / slow down / faster / resume
-- Each function should make the player etc stop / slow down / faster / resume
-- Each function should make the boss animations stop / slow down / faster / resume
-- Each function should make the boss movement stop / slow down / faster / resume
-- Each function should make the particles effects of every object stop / slow down / faster / resume

function TimeController.Stop(tweenInfo: TweenInfo)
	-- Stop
end

function TimeController.Resume(tweenInfo: TweenInfo)
	-- Resume
end

function TimeController.Slow(value: number, tweenInfo: TweenInfo)
	-- Slow down time
	-- If tweenInfo time is 0 then make it instantaneously, if not then make it gradually slower.
end

function TimeController.Fast(value: number, tweenInfo: TweenInfo)
	-- make the time go more faster
	-- If tweenInfo is time is 0 then make it instantaneously, if not then make it gradually slower.
end

return TimeController
