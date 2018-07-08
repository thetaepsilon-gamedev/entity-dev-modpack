--[[
Implementation functions for cbox_grind (see appropriate lua file)
which do the calculations for surface friction.
]]
local mk_sampler = mtrequire("ds2.minetest.drag_physics.cbox_grind")
local m_util = mtrequire("ds2.minetest.drag_physics.cbox_grind_util")
local mkcube = m_util.mkcube_collect

-- the getnode sampling defers to another function to read the friction value
-- (this is MT-specific so not configured here).
-- the face and sign arguments are not relevant, as below they will be averaged.
local mk_getnode = function(frictionf)
	assert(type(frictionf) == "function")
	return function(face, sign, x, y, z)
		return frictionf(x, y, z)
	end
end

-- mkface performs the arithmetic mean of the four corners.
-- this isn't a perfect representation of friction,
-- but it suffices for small enough objects.
local mkface = function(face, ll, hl, lh, hh)
	return (ll + hl + lh + hh) / 4
end

local impl = {
	mkface = mkface,
	mkcube = mkcube,
}
local mk_sampler = function(frictionf)
	impl.getnode = mk_getnode(frictionf)
	return mk_sampler(impl)
end

return mk_sampler

