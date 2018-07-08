--[[
Apply surface friction to an entity, given the friction values on each axis.
]]

-- applying friction isn't just a normal subtract,
-- but rather the force opposes the direction of motion.
-- when positive: subtract, when negative: add
-- however, if it would go to zero, clamp it.
local abs_subtract = function(v, d)
	if v > 0 then
		return math.max(v - d, 0)
	else
		return math.min(v + d, 0)
	end
end
local sub = abs_subtract
-- scale is used to adjust the friction force based on the entity's weight,
-- as well as the time step under question (e.g. 0.1 seconds for per-tick).
-- ef is "entity friction", the friction value of the entity being slowed.
-- it doesn't have axes because to do so would have to consider friction etc.
local push_towards_zero_mut = function(velocity, friction, ef, scale)
	local v, f, s = velocity, friction, scale
	local x = sub(v.x, (f.fx * ef) * s)
	local y = sub(v.y, (f.fy * ef) * s)
	local z = sub(v.z, (f.fz * ef) * s)
	v.x = x
	v.y = y
	v.z = z
	return v
end

-- get entity friction and scale based on properties and step dtime.
local def_ef = 50	-- TODO: make configurable?
local def_weight = 5	-- not sure if the API doc's example is the true value for this
local get_scales = function(props, dtime)
	local ef = props.friction_surface or def_ef
	local weight = props.weight or def_weight
	local scale = dtime / weight
	return ef, weight
end

local i = {}
-- entity friction and weighting are retrieved from an already retrieved properties table.
-- returns the modified velocity after applying to the entity.
local apply = function(dtime, entity, props, frictionf)
	local ef, weight = get_scales(props, dtime)
	local vel = entity:get_velocity()
	local friction = frictionf(entity:get_pos(), props.collisionbox)
	push_towards_zero_mut(vel, friction, ef, scale)
	entity:set_velocity(vel)
	return vel
end
i.apply = apply



return i

