--[[
In minetest-specific code: provide definition lookup and node sampling,
based on minetest.registered_nodes and .get_node(), respectively.
]]
local mk_frictionf = mtrequire("ds2.minetest.drag_physics.friction_sampler_mt_def")
local mk_sampler = mtrequire("ds2.minetest.drag_physics.cbox_friction_vector_sampler")

-- throwaway allocations, whyyyyyy
local pos = {}
local getnodename = function(x, y, z)
	pos.x = x
	pos.y = y
	pos.z = z
	local node = minetest.get_node(pos)
	return node.name
end

local nlookup = function(n) return minetest.registered_nodes[n] end
local frictionf = mk_frictionf(getnodename, nlookup)

local i = {}
i.friction_sampler = mk_sampler(frictionf)
return i

