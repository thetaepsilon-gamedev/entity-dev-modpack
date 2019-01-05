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

-- a little utility below to avoid divide by zeroes and infinities cropping up.
-- also incorporates velocity un-signing.
local abs = math.abs
local safediv = function(s, v)
	return (v == 0) and 0 or s / abs(v)
end

-- scale is used to adjust the friction force based on the entity's weight,
-- as well as the time step under question (e.g. 0.1 seconds for per-tick).
-- ef is "entity friction", the friction value of the entity being slowed.
-- it doesn't have axes because to do so would have to consider friction etc.
local push_towards_zero_mut = function(velocity, friction, ef, scale)
	local v, f, s = velocity, friction, scale
	-- motion along each axis is slowed by friction on the other two.
	-- e.g. Y-axis motion can be slowed by friction on the X and Z sides.
	-- slowdown is also proportional to current velocity.
	-- this should really in future also take into account normal force...
	local x = sub(v.x, ((f.fy + f.fz) * ef) * safediv(s, v.x))
	local y = sub(v.y, ((f.fx + f.fz) * ef) * safediv(s, v.y))
	local z = sub(v.z, ((f.fx + f.fy) * ef) * safediv(s, v.z))
	v.x = x
	v.y = y
	v.z = z
	return v
end

-- get entity friction and scale based on properties and step dtime.
local def_ef = 50	-- TODO: make configurable?
local def_weight = 5	-- not sure if the API doc's example is the true value for this
local tweak = 30	-- value played around with during development
local get_scales = function(props, dtime)
	local ef = props.friction_surface or def_ef
	local weight = props.weight or def_weight
	local scale = (dtime / weight) * tweak
	return ef, scale
end

local i = {}
-- entity friction and weighting are retrieved from an already retrieved properties table.
-- returns the modified velocity after applying to the entity.
local apply = function(dtime, entity, props, frictionf)
	local ef, scale = get_scales(props, dtime)
	local vel = entity:get_velocity()
	local friction = frictionf(entity:get_pos(), props.collisionbox)
	push_towards_zero_mut(vel, friction, ef, scale)
	entity:set_velocity(vel)
	return vel
end
i.apply = apply



return i

