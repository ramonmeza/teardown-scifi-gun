--This script will run on all levels when mod is active.
--Modding documentation: http://teardowngame.com/modding
--API reference: http://teardowngame.com/modding/api.html

-- rof describes how fast the gun can shoot in seconds
-- rof_timer is used internally as a timer that triggers when it is at 0
-- shot_queue contains world positions where a shot has hit and needs to be exploded
-- explosion_size is self expanatory, should be in the range of [0.5, 4.0]
-- shot_has_exploded is a boolean that represents whether the current shot has exploded

--queue definition
Queue = {}

function Queue.new()
	--store index to first and last elements
	return { first = 0, last = -1 }
end

function Queue.push(queue, value)
	-- append to end
	local last = queue.last + 1
	queue.last = last
	queue[last] = value
end

function Queue.pop(queue)
	--remove from front
	local first = queue.first

	if first > queue.last then return -1 end

	local value = queue[first]
	queue[first] = nil
	queue.first = first + 1
	return value
end

function Queue.length(queue)
	return 1 + queue.last - queue.first
end

--functions
function init()
	--load media
	RegisterTool("scifi_gun", "Sci-Fi Gun", "MOD/data/vox/gun.vox")
	shot_sound = LoadSound("MOD/data/snd/shot.ogg")
	buildup_sound = LoadSound("MOD/data/snd/explosion_buildup.ogg")

	--initialize global vars
	SetBool("game.tool.scifi_gun.enabled", true)

	--initialize vars
	rof = 2
	rof_timer = 0
	shot_queue = Queue.new()
	explosion_size = 2.0
	shot_has_exploded = false
end


function tick(dt)
	if GetString("game.player.tool") == "scifi_gun" then
		DebugWatch("rof_time", rof_timer)

		--shoot
		if rof_timer <= 0 and InputDown("usetool") then
			rof_timer = rof
			local sticky = shoot_sticky()
			Queue.push(shot_queue, sticky)
			shot_has_exploded = false
		end

		--check to explode stuff
		local half_rof = rof / 2
		if Queue.length(shot_queue) > 0 and rof_timer < half_rof and not shot_has_exploded then
			explode_shot()
			shot_has_exploded = true
		end

		--decrement timers
		if rof_timer > 0 then
			rof_timer = rof_timer - dt
		end
	end
end


function update(dt)
end


function draw(dt)
end


function shoot_sticky()
	PlaySound(shot_sound)

	local camera = GetPlayerCameraTransform()
	local dir = TransformToParentVec(camera, Vec(0, 0, -1))
	local max_dist = 100
	local hit, dist, normal, shape = QueryRaycast(camera.pos, dir, max_dist)
	if not hit then
		dist = max_dist
	end

	local hit_point = VecAdd(camera.pos, VecScale(dir, dist))
	return hit_point
end

function explode_shot()
	PlaySound(buildup_sound)
	local hit_point = Queue.pop(shot_queue)
	Explosion(hit_point, explosion_size)
end
