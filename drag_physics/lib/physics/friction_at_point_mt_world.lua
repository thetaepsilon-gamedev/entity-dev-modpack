--[[
An implementation of the friction_at_point function,
needed for the friction cbox sampler
(see cbox_friction_vector_sampler.lua and cbox_grind.lua).
this a function taking x/y/z coordinates and returning a friction value.
This in turn requires a function mapping x/y/z to just a node name
(e.g. wrap minetest.get_node in a function returning just .name),
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

	-- liquids have a lower than average drag.
	-- this doesn't really simulate how fluids behave,
	-- but it's close enough for this.
	local l = def.liquidtype
	if (l == "source") or (l == "flowing") then
		return 10
	end

	-- walkable defines if entities will collide,
	-- so if this is explicitly set to false then assume air-like friction
	if def.walkable == false then return 0.02 end

	-- nothing else? fall back to default
	return default
end



local mk_mt_friction_at_point = function(nsampler, nlookup)
	assert(type(nsampler) == "function")
	assert(type(nlookup) == "function")

	local friction_at_point = function(x, y, z)
		local n = nsampler(x, y, z)
		local def = nlookup(n)

		local friction
		if def == nil then
			friction = 0
		else
			friction = process_def(def)
		end
		return friction, def
	end

	return friction_at_point
end



return mk_mt_friction_at_point

