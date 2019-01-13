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
local unwrap = mtrequire("ds2.minetest.vectorextras.unwrap")

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
local sample_grind_face = function(mk, getnode, mk_extradata_face, face, protrude, amin, amax, bmin, bmax)
	local mapf = facemap[face]
	local get = function(face, sign, ...) return getnode(face, sign, mapf(...)) end

	-- we actually contract the coordinates slightly inside the face corners.
	-- the reason for this is that MT sometimes gives unexpected results
	-- if the cbox corners exactly line up on the boundary between nodes.
	local t = tiny
	amin = amin + t
	amax = amax - t
	bmin = bmin + t
	bmax = bmax - t

	-- x* variables are extradata.
	-- a and b refer to a and b axes (which vary depending on the face,
	-- e.g. for Y+/- faces they would be x and z).
	-- l and h refer to lower and higher along the preceding axis.
	local albl, xalbl = get(face, "--", protrude, amin, bmin)
	local ahbl, xahbl = get(face, "+-", protrude, amax, bmin)
	local albh, xalbh = get(face, "-+", protrude, amin, bmax)
	local ahbh, xahbh = get(face, "++", protrude, amax, bmax)

	local friction_face = mk(face, albl, ahbl, albh, ahbh)
	local extradata_face =
		mk_extradata_face(face, xalbl, xahbl, xalbh, xahbh)

	return friction_face, extradata_face
end







--[[
cbox is in usual MT format,
e.g. an array of six offset numbers:
{ xmin, ymin, zmin, xmax, ymax, zmax }
The ordering of min/max relative to each other is NOT checked.
The funcs table provides functions to sample the desired data at a given point,
as well as to compose the desired resulting structure.
]]
local nilfunc = function() return nil end
local mk_contact_point_grind_sampler = function(funcs)
	-- composers for the returned friction data.
	local getnode = funcs.getnode
	assert(type(getnode) == "function")
	local mkface = funcs.mkface
	assert(type(mkface) == "function")
	local mkcube = funcs.mkcube
	assert(type(mkcube) == "function")

	-- same but for extradata, if any.
	-- mk_extradata_face is called with a face identifier
	-- (see below in the s(...) calls) and extradata for the four corners;
	-- for the corner ordering see above in sample_grind_face().
	local mkxface = funcs.mk_extradata_face or nilfunc
	-- mk_extradata_cube is called with the six extradata faces,
	-- where the "extradata faces" are whatever mk_extradata_face() returns.
	-- the ordering of these faces is like that of minetest collision boxes;
	-- see e.g. the call to mkcube() near the end of the function below.
	local mkxcube = funcs.mk_extradata_cube or nilfunc
	assert(type(mkxface) == "function")
	assert(type(mkxcube) == "function")


	local m, g, x = mkface, getnode, mkxface
	local s = function(...)
		return sample_grind_face(m, g, x, ...)
	end

	return function(bpos, cbox)
		local bx, by, bz = unwrap(bpos)
		local c = cbox
		local xmin, ymin, zmin = bx + c[1], by + c[2], bz + c[3]
		local xmax, ymax, zmax = bx + c[4], by + c[5], bz + c[6]
		local protrude

		local t = tiny
		-- note that the corners are also shrunk in slightly on the protuded face.
		-- this is to avoid catching in weird ways on top of surfaces.
		local h = tiny
		local hxmin = xmin + h
		local hymin = ymin + h
		local hzmin = zmin + h
		local hxmax = xmax - h
		local hymax = ymax - h
		local hzmax = zmax - h

		local sxmin, exmin = s("xmin", xmin - t, hymin, hymax, hzmin, hzmax)
		local sxmax, exmax = s("xmax", xmax + t, hymin, hymax, hzmin, hzmax)
		local symin, eymin = s("ymin", ymin - t, hxmin, hxmax, hzmin, hzmax)
		local symax, eymax = s("ymax", ymax + t, hxmin, hxmax, hzmin, hzmax)
		local szmin, ezmin = s("zmin", zmin - t, hxmin, hxmax, hymin, hymax)
		local szmax, ezmax = s("zmax", zmax + t, hxmin, hxmax, hymin, hymax)

		-- preserve cbox-like ordering
		local friction_data =
			mkcube(sxmin, symin, szmin, sxmax, symax, szmax)
		local extradata_cube =
			mkxcube(exmin, eymin, ezmin, exmax, eymax, ezmax)
		return friction_data, extradata_cube
	end
end

return mk_contact_point_grind_sampler

