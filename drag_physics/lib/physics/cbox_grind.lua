--[[
Minetest will simply zero out motion along an axis when an entity hits a node.
In order to see which node's being touched in this case,
we need to probe just outside the entity's cbox boundaries.
We do this by protuding the corners on each face of the cbox by a small amount
(the x's are the protuded points, c's are the original cbox vertices):
   x---------------x
   |               |
x--c---------------c--x
|  |               |  |
|  |               |  |
|  |               |  |
|  |               |  |
|  |               |  |
x--c---------------c--x
   |               |
   x---------------x
Now imagine that in 3D.
A side of the cbox will be pressed right up against a wall when colliding;
we have to sample just beyond it to see the node that is presenting the barrier.
We only sample at the corners of the cbox to cut down on getnode calls;
this approximation may yield surprises on objects larger than two nodes.
]]

-- the offset value used to reach into the next block.
-- should be small but not too small, so as to not cause rounding errors.
local tiny = 0.01



-- work out the ordering of passed coordinates from the given dimension/face.
local facex = function(protrude, a, b)
	return protrude, a, b
end
local facey = function(protrude, a, b)
	return a, protrude, b
end
local facez = function(protrude, a, b)
	return a, b, protrude
end
local facemap = {
	xmin = facex,
	xmax = facex,
	ymin = facey,
	ymax = facey,
	zmin = facez,
	zmax = facez,
}

-- this thing has slightly too many arguments...
-- work out the coordinates of a single protruded face and read data
local sample_grind_face = function(mk, getnode, face, protrude, amin, amax, bmin, bmax)
	local mapf = facemap[face]
	local get = function(face, sign, ...) return getnode(face, sign, mapf(...)) end
	local albl = get(face, "--", protrude, amin, bmin)
	local ahbl = get(face, "+-", protrude, amax, bmin)
	local albh = get(face, "-+", protrude, amin, bmax)
	local ahbh = get(face, "++", protrude, amax, bmax)
	return mk(face, albl, ahbl, albh, ahbh)
end

--[[
cbox is in usual MT format,
e.g. an array of six offset numbers:
{ xmin, ymin, zmin, xmax, ymax, zmax }
The ordering of min/max relative to each other is NOT checked.
The funcs table provides functions to sample the desired data at a given point,
as well as to compose the desired resulting structure.
]]
local sample_grind_points = function(funcs)
	local getnode = funcs.getnode
	assert(type(getnode) == "function")
	local mkface = funcs.mkface
	assert(type(mkface) == "function")
	local mkcube = funcs.mkcube
	assert(type(mkcube) == "function")

	return function(bpos, cbox)
		local m, g = mkface, getnode
		local s = function(...)
			return sample_grind_face(m, g, ...)
		end

		local bx, by, bz = unwrap(bpos)
		local c = cbox
		local xmin, ymin, zmin = bx + c[1], by + c[2], bz + c[3]
		local xmax, ymax, zmax = bx + c[4], by + c[5], bz + c[6]
		local protrude

		local sxmin = s("xmin", xmin - tiny, ymin, ymax, zmin, zmax)
		local sxmax = s("xmax", xmax + tiny, ymin, ymax, zmin, zmax)
		local symin = s("ymin", ymin - tiny, xmin, xmax, zmin, zmax)
		local symax = s("ymax", ymax + tiny, xmin, xmax, zmin, zmax)
		local szmin = s("zmin", zmin - tiny, xmin, xmax, ymin, ymax)
		local szmax = s("zmax", zmax + tiny, xmin, xmax, ymin, ymax)
		return mkcube(sxmin, sxmax, symin, symax, szmin, szmax)
	end
end

return sample_grind_points

