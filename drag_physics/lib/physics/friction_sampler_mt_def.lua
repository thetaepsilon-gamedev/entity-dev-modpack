--[[
An implementation of the frictionf needed for the friction cbox sampler
(see friction_sampler_impl.lua),
i.e. a function taking x/y/z coordinates and returning a friction value.
This requires a function mapping x/y/z to just a node name,
and a function which returns the definition table for that node name.
(simplest implementation of this would be:
function(n) return minetest.registered_nodes[n] end).
The definition lookup is allowed to return nil,
in which case the node is assumed to have zero friction.
]]



--[[
DOC:
This function serves as documentation for how to specify friction in node definitions.
]]
local default = 50
local process_def = function(def)
	-- inspect the definition to see if it deines surface_friction
	local d = def.surface_friction
	if d then return d end

	-- walkable defines if entities will collide,
	-- so if this is explicitly set to false then assume no friction
	if def.walkable == false then return 0 end

	-- nothing else? fall back to default
	return default
end



local mk_frictionf = function(nsampler, nlookup)
	assert(type(nsampler) == "function")
	assert(type(nlookup) == "function")
	return function(x, y, z)
		local n = nsampler(x, y, z)
		local def = nlookup(n)
		if def == nil then
			return 0
		else
			return process_def(def)
		end
	end
end



return mk_frictionf

