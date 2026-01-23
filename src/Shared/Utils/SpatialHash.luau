local ReplicatedStorage = game:GetService("ReplicatedStorage")
local jecs = require(ReplicatedStorage.Packages.jecs)

--==[ Types ]==--
export type EntityId = jecs.Entity
export type Bucket = { EntityId }
export type Buckets = { [number]: Bucket }

export type RecordPoint = { x: number, y: number, z: number, shape: number }
export type RecordSphere = { x: number, y: number, z: number, radius: number, shape: number }
export type RecordAABB = { x: number, y: number, z: number, halfx: number, halfy: number, halfz: number, shape: number }

export type Records = { [EntityId]: RecordPoint | RecordSphere | RecordAABB }
export type RecordInfo = { hash: number, index: number, coarseHash: number, coarseIndex: number }
export type RecordsInfo = { [EntityId]: RecordInfo }

export type SpatialHashStatic = {
	new: (cellSize: number?, coarseFactor: number?) -> SpatialHash,
	QueryAABBAsPoints: (
		minX: number,
		minY: number,
		minZ: number,
		maxX: number,
		maxY: number,
		maxZ: number,
		size: number,
		func: (EntityId) -> (),
		buckets: Buckets,
		records: Records
	) -> (),
	QuerySphereAsPoints: (
		cx: number,
		cy: number,
		cz: number,
		radius: number,
		size: number,
		func: (EntityId) -> (),
		buckets: Buckets,
		records: Records
	) -> (),
	QueryAABB: (
		minX: number,
		minY: number,
		minZ: number,
		maxX: number,
		maxY: number,
		maxZ: number,
		size: number,
		func: (EntityId) -> (),
		buckets: Buckets,
		records: Records
	) -> (),
	QuerySphere: (
		cx: number,
		cy: number,
		cz: number,
		radius: number,
		size: number,
		func: (EntityId) -> (),
		buckets: Buckets,
		records: Records
	) -> (),
}

export type SpatialHash = {
	CELL_SIZE: number,
	COARSE_FACTOR: number,
	COARSE_SIZE: number,

	Records: Records,
	RecordsInfo: RecordsInfo,
	FineBuckets: Buckets,
	CoarseBuckets: Buckets,

	Reset: (self: SpatialHash, cellSize: number?, coarseFactor: number?) -> (),

	AddPoint: (self: SpatialHash, entity: EntityId, position: vector) -> (),
	AddAABB: (self: SpatialHash, entity: EntityId, position: vector, halfSize: vector) -> (),
	AddSphere: (self: SpatialHash, entity: EntityId, position: vector | Vector3, radius: number) -> (),
	AddAABBRecursively: (self: SpatialHash, entity: EntityId, position: vector, halfSize: vector) -> (),
	AddSphereRecursively: (self: SpatialHash, entity: EntityId, position: vector, radius: number) -> (),

	Update: (self: SpatialHash, entity: EntityId, position: vector | Vector3) -> (),

	Remove: (self: SpatialHash, entity: EntityId) -> (),
	RemoveRecursively: (self: SpatialHash, entity: EntityId) -> (),

	QueryAABBAsPoints: (
		self: SpatialHash,
		minX: number,
		minY: number,
		minZ: number,
		maxX: number,
		maxY: number,
		maxZ: number,
		func: (EntityId) -> ()
	) -> (),
	QuerySphereAsPoints: (
		self: SpatialHash,
		cx: number,
		cy: number,
		cz: number,
		radius: number,
		func: (EntityId) -> ()
	) -> (),
	QueryAABB: (
		self: SpatialHash,
		minX: number,
		minY: number,
		minZ: number,
		maxX: number,
		maxY: number,
		maxZ: number,
		func: (EntityId) -> ()
	) -> (),
	QuerySphere: (self: SpatialHash, cx: number, cy: number, cz: number, radius: number, func: (EntityId) -> ()) -> (),
}

--==[ Defaults ]==--
local CELL_SIZE_DEFAULT: number = 5
local COARSE_FACTOR_DEFAULT: number = 32
local ERelation = table.freeze({
	Outside = 0,
	Inside = 1,
	Intersect = 2,
})
local EShape = table.freeze({
	Point = 0,
	Sphere = 1,
	AABB = 2,
})

--==[ Helpers ]==--
local bxor = bit32.bxor
local floor = math.floor
local max = math.max
local table_create = table.create
local table_clear = table.clear

-- Large primes for spatial hashing to minimize collisions
local P1 = 73856093
local P2 = 19349663
local P3 = 83492791

local function ihash(x: number, y: number, z: number): number
	return bxor(x * P1, y * P2, z * P3)
end

local function cellIndexSize(x: number, y: number, z: number, size: number): (number, number, number)
	return floor(x / size), floor(y / size), floor(z / size)
end

local function ensure(bags: { [number]: Bucket }, h: number): Bucket
	local b = bags[h]
	if b ~= nil then return b end

	local n = table_create(8) :: Bucket
	bags[h] = n
	return n
end

local function insertInfo(self: SpatialHash, entity: EntityId, x: number, y: number, z: number)
	local fix, fiy, fiz = cellIndexSize(x, y, z, self.CELL_SIZE)
	local cix, ciy, ciz = cellIndexSize(x, y, z, self.COARSE_SIZE)
	local fh, ch = ihash(fix, fiy, fiz), ihash(cix, ciy, ciz)

	local fb = ensure(self.FineBuckets, fh)
	fb[#fb + 1] = entity

	local cb = ensure(self.CoarseBuckets, ch)
	cb[#cb + 1] = entity

	local existing = self.RecordsInfo[entity]
	if existing then
		existing.hash = fh
		existing.index = #fb
		existing.coarseHash = ch
		existing.coarseIndex = #cb
	else
		self.RecordsInfo[entity] = { hash = fh, index = #fb, coarseHash = ch, coarseIndex = #cb }
	end
end

local function swapRemoveFine(self: SpatialHash, bags: { [number]: Bucket }, hash: number, idx: number)
	local b = bags[hash]
	if b == nil then return end

	local n = #b
	local last = b[n]

	if idx ~= n then
		b[idx] = last
		local li = self.RecordsInfo[last]
		if li then li.index = idx end
	end

	b[n] = nil
	if n - 1 == 0 then bags[hash] = nil end
end

local function swapRemoveCoarse(self: SpatialHash, bags: { [number]: Bucket }, h: number, idx: number)
	local b = bags[h]
	if b == nil then return end

	local n = #b
	local last = b[n]

	if idx ~= n then
		b[idx] = last
		local li = self.RecordsInfo[last]
		if li then li.coarseIndex = idx end
	end

	b[n] = nil
	if n - 1 == 0 then bags[h] = nil end
end

local function removeDual(self: SpatialHash, info: RecordInfo)
	swapRemoveFine(self, self.FineBuckets, info.hash, info.index)
	swapRemoveCoarse(self, self.CoarseBuckets, info.coarseHash, info.coarseIndex)
end

local function cellAABB(
	ix: number,
	iy: number,
	iz: number,
	size: number
): (number, number, number, number, number, number)
	local minx = ix * size
	local miny = iy * size
	local minz = iz * size
	return minx, minx + size, miny, miny + size, minz, minz + size
end

local function sphereAABBRelation(
	minx: number,
	maxx: number,
	miny: number,
	maxy: number,
	minz: number,
	maxz: number,
	cx: number,
	cy: number,
	cz: number,
	r2: number
): number
	-- outside if AABB is farther than r from sphere center
	local dx = 0
	if cx < minx then
		dx = minx - cx
	elseif cx > maxx then
		dx = cx - maxx
	end
	local dy = 0
	if cy < miny then
		dy = miny - cy
	elseif cy > maxy then
		dy = cy - maxy
	end
	local dz = 0
	if cz < minz then
		dz = minz - cz
	elseif cz > maxz then
		dz = cz - maxz
	end

	if dx * dx + dy * dy + dz * dz > r2 then return ERelation.Outside end

	-- inside if all eight corners inside the sphere
	local function inside(x: number, y: number, z: number): boolean
		local rx, ry, rz = x - cx, y - cy, z - cz
		return rx * rx + ry * ry + rz * rz <= r2
	end

	if
		inside(minx, miny, minz)
		and inside(minx, miny, maxz)
		and inside(minx, maxy, minz)
		and inside(minx, maxy, maxz)
		and inside(maxx, miny, minz)
		and inside(maxx, miny, maxz)
		and inside(maxx, maxy, minz)
		and inside(maxx, maxy, maxz)
	then
		return ERelation.Inside
	end

	return ERelation.Intersect
end

local function aabbRelation(
	minx: number,
	maxx: number,
	miny: number,
	maxy: number,
	minz: number,
	maxz: number,
	qminx: number,
	qmaxx: number,
	qminy: number,
	qmaxy: number,
	qminz: number,
	qmaxz: number
): number
	-- outside if disjoint
	if maxx < qminx or minx > qmaxx or maxy < qminy or miny > qmaxy or maxz < qminz or minz > qmaxz then
		return ERelation.Outside
	end
	-- inside if fully contained
	if minx >= qminx and maxx <= qmaxx and miny >= qminy and maxy <= qmaxy and minz >= qminz and maxz <= qmaxz then
		return ERelation.Inside
	end

	return ERelation.Intersect
end

local function pointInAABB(
	x: number,
	y: number,
	z: number,
	qminx: number,
	qmaxx: number,
	qminy: number,
	qmaxy: number,
	qminz: number,
	qmaxz: number
): boolean
	return x >= qminx and x <= qmaxx and y >= qminy and y <= qmaxy and z >= qminz and z <= qmaxz
end

local function pointInRadius(dx: number, dy: number, dz: number, r2: number): boolean
	return dx * dx + dy * dy + dz * dz <= r2
end

local function sphereVsAABB(
	cx: number,
	cy: number,
	cz: number,
	r2: number,
	qminx: number,
	qmaxx: number,
	qminy: number,
	qmaxy: number,
	qminz: number,
	qmaxz: number
): boolean
	local dx = 0
	if cx < qminx then
		dx = qminx - cx
	elseif cx > qmaxx then
		dx = cx - qmaxx
	end
	local dy = 0
	if cy < qminy then
		dy = qminy - cy
	elseif cy > qmaxy then
		dy = cy - qmaxy
	end
	local dz = 0
	if cz < qminz then
		dz = qminz - cz
	elseif cz > qmaxz then
		dz = cz - qmaxz
	end

	return dx * dx + dy * dy + dz * dz <= r2
end

local function aabbVsAABB(
	minx: number,
	maxx: number,
	miny: number,
	maxy: number,
	minz: number,
	maxz: number,
	qminx: number,
	qmaxx: number,
	qminy: number,
	qmaxy: number,
	qminz: number,
	qmaxz: number
): boolean
	return not (maxx < qminx or minx > qmaxx or maxy < qminy or miny > qmaxy or maxz < qminz or minz > qmaxz)
end

local function sphereVsSphere(
	ax: number,
	ay: number,
	az: number,
	ar: number,
	bx: number,
	by: number,
	bz: number,
	br: number
): boolean
	local dx, dy, dz = ax - bx, ay - by, az - bz
	return dx * dx + dy * dy + dz * dz <= (ar + br) * (ar + br)
end

local function pushUnique(bags: Buckets, h: number, e: EntityId)
	local b = ensure(bags, h)
	for i = 1, #b do
		if b[i] == e then return end
	end
	b[#b + 1] = e
end

local function removeAllLinear(self: SpatialHash, bags: Buckets, h: number, e: EntityId, isFine: boolean)
	local b = bags[h]
	if b == nil then return end

	local i = 1
	while i <= #b do
		if b[i] ~= e then
			i += 1
			continue
		end

		local n = #b
		local last = b[n]
		if i ~= n then
			b[i] = last
			local li = self.RecordsInfo[last]
			if li then
				if isFine and li.hash == h then li.index = i end
				if (not isFine) and li.coarseHash == h then li.coarseIndex = i end
			end
		end
		b[n] = nil
	end

	if #b == 0 then bags[h] = nil end
end

local function rangeSphere(cx: number, cy: number, cz: number, r: number, size: number)
	local minIx, minIy, minIz = cellIndexSize(cx - r, cy - r, cz - r, size)
	local maxIx, maxIy, maxIz = cellIndexSize(cx + r, cy + r, cz + r, size)
	return minIx, minIy, minIz, maxIx, maxIy, maxIz
end

local function rangeAABB(cx: number, cy: number, cz: number, hx: number, hy: number, hz: number, size: number)
	local minIx, minIy, minIz = cellIndexSize(cx - hx, cy - hy, cz - hz, size)
	local maxIx, maxIy, maxIz = cellIndexSize(cx + hx, cy + hy, cz + hz, size)
	return minIx, minIy, minIz, maxIx, maxIy, maxIz
end

--==[ SpatialHash ]==--
local SpatialHashStatic = {}
local SpatialHash = {}
SpatialHash.__index = SpatialHash

function SpatialHashStatic.new(cellSize: number?, coarseFactor: number?): SpatialHash
	local self = (setmetatable({}, SpatialHash) :: any) :: SpatialHash
	self.FineBuckets = {}
	self.CoarseBuckets = {}
	self.Records = {}
	self.RecordsInfo = {}

	self.CELL_SIZE = (cellSize and cellSize > 0) and cellSize or CELL_SIZE_DEFAULT
	self.COARSE_FACTOR = (coarseFactor and coarseFactor >= 2) and coarseFactor or COARSE_FACTOR_DEFAULT
	self.COARSE_SIZE = self.CELL_SIZE * self.COARSE_FACTOR

	return self
end

function SpatialHash.Reset(self: SpatialHash, cellSize: number?, coarseFactor: number?)
	if cellSize and cellSize > 0 then self.CELL_SIZE = cellSize end
	if coarseFactor and coarseFactor >= 2 then self.COARSE_FACTOR = coarseFactor end

	self.COARSE_SIZE = self.CELL_SIZE * self.COARSE_FACTOR

	table_clear(self.FineBuckets)
	table_clear(self.CoarseBuckets)
	table_clear(self.Records)
	table_clear(self.RecordsInfo)
end

function SpatialHash.AddPoint(self: SpatialHash, entity: EntityId, position: vector)
	if self.Records[entity] then return end
	self.Records[entity] = { x = position.x, y = position.y, z = position.z, shape = EShape.Point } :: RecordPoint
	insertInfo(self, entity, position.x, position.y, position.z)
end

function SpatialHash.AddAABB(self: SpatialHash, entity: EntityId, position: vector, halfSize: vector)
	if self.Records[entity] then return end
	self.Records[entity] = {
		x = position.x,
		y = position.y,
		z = position.z,
		halfx = halfSize.x,
		halfy = halfSize.y,
		halfz = halfSize.z,
		shape = EShape.AABB,
	} :: RecordAABB
	insertInfo(self, entity, position.x, position.y, position.z)
end

function SpatialHash.AddSphere(self: SpatialHash, entity: EntityId, position: vector | Vector3, radius: number)
	if self.Records[entity] then return end
	self.Records[entity] =
		{ x = position.x, y = position.y, z = position.z, radius = radius, shape = EShape.Sphere } :: RecordSphere
	insertInfo(self, entity, position.x, position.y, position.z)
end

function SpatialHash.AddAABBRecursively(self: SpatialHash, e: EntityId, pos: vector, halfSize: vector)
	if self.Records[e] then return end
	local hx, hy, hz = max(0, halfSize.x), max(0, halfSize.y), max(0, halfSize.z)
	self.Records[e] =
		{ x = pos.x, y = pos.y, z = pos.z, halfx = hx, halfy = hy, halfz = hz, shape = EShape.AABB } :: RecordAABB

	-- fine
	do
		local minIx, minIy, minIz, maxIx, maxIy, maxIz = rangeAABB(pos.x, pos.y, pos.z, hx, hy, hz, self.CELL_SIZE)
		for ix = minIx, maxIx do
			for iy = minIy, maxIy do
				for iz = minIz, maxIz do
					pushUnique(self.FineBuckets, ihash(ix, iy, iz), e)
				end
			end
		end
	end
	-- coarse
	do
		local minIx, minIy, minIz, maxIx, maxIy, maxIz = rangeAABB(pos.x, pos.y, pos.z, hx, hy, hz, self.COARSE_SIZE)
		for ix = minIx, maxIx do
			for iy = minIy, maxIy do
				for iz = minIz, maxIz do
					pushUnique(self.CoarseBuckets, ihash(ix, iy, iz), e)
				end
			end
		end
	end
end

function SpatialHash.AddSphereRecursively(self: SpatialHash, e: EntityId, pos: vector, radius: number)
	if self.Records[e] then return end
	if radius < 0 then radius = 0 end
	self.Records[e] = { x = pos.x, y = pos.y, z = pos.z, radius = radius, shape = EShape.Sphere } :: RecordSphere

	-- fine
	do
		local minIx, minIy, minIz, maxIx, maxIy, maxIz = rangeSphere(pos.x, pos.y, pos.z, radius, self.CELL_SIZE)
		for ix = minIx, maxIx do
			for iy = minIy, maxIy do
				for iz = minIz, maxIz do
					pushUnique(self.FineBuckets, ihash(ix, iy, iz), e)
				end
			end
		end
	end
	-- coarse
	do
		local minIx, minIy, minIz, maxIx, maxIy, maxIz = rangeSphere(pos.x, pos.y, pos.z, radius, self.COARSE_SIZE)
		for ix = minIx, maxIx do
			for iy = minIy, maxIy do
				for iz = minIz, maxIz do
					pushUnique(self.CoarseBuckets, ihash(ix, iy, iz), e)
				end
			end
		end
	end
end

function SpatialHash.Update(self: SpatialHash, entity: EntityId, position: vector)
	local record = self.Records[entity]
	if record == nil then return end
	local info = self.RecordsInfo[entity]
	if info == nil then return end

	local fix, fiy, fiz = cellIndexSize(position.x, position.y, position.z, self.CELL_SIZE)
	local cix, ciy, ciz = cellIndexSize(position.x, position.y, position.z, self.COARSE_SIZE)
	local fh, ch = ihash(fix, fiy, fiz), ihash(cix, ciy, ciz)

	if fh ~= info.hash or ch ~= info.coarseHash then
		removeDual(self, info)
		insertInfo(self, entity, position.x, position.y, position.z)
	else
		(record :: any).x = position.x;
		(record :: any).y = position.y;
		(record :: any).z = position.z
	end
end

function SpatialHash.Update3(self: SpatialHash, entity: EntityId, position: Vector3)
	local record = self.Records[entity]
	if record == nil then return end
	local info = self.RecordsInfo[entity]
	if info == nil then return end

	local fix, fiy, fiz = cellIndexSize(position.X, position.Y, position.Z, self.CELL_SIZE)
	local cix, ciy, ciz = cellIndexSize(position.X, position.Y, position.Z, self.COARSE_SIZE)
	local fh, ch = ihash(fix, fiy, fiz), ihash(cix, ciy, ciz)

	if fh ~= info.hash or ch ~= info.coarseHash then
		removeDual(self, info)
		insertInfo(self, entity, position.X, position.Y, position.Z)
	else
		(record :: any).x = position.X;
		(record :: any).y = position.Y;
		(record :: any).z = position.Z
	end
end

function SpatialHash.Remove(self: SpatialHash, entity: EntityId)
	local record = self.Records[entity]
	if record == nil then return end
	local info = self.RecordsInfo[entity]
	if info == nil then return end
	removeDual(self, info)

	self.Records[entity] = nil
	self.RecordsInfo[entity] = nil
end

function SpatialHash.RemoveRecursively(self: SpatialHash, entity: EntityId)
	local record = self.Records[entity]
	if record == nil then return end

	if record.shape == EShape.Sphere then
		local r = (record :: RecordSphere).radius
		-- fine
		do
			local minIx, minIy, minIz, maxIx, maxIy, maxIz =
				rangeSphere(record.x, record.y, record.z, r, self.CELL_SIZE)
			for ix = minIx, maxIx do
				for iy = minIy, maxIy do
					for iz = minIz, maxIz do
						removeAllLinear(self, self.FineBuckets, ihash(ix, iy, iz), entity, true)
					end
				end
			end
		end
		-- coarse
		do
			local minIx, minIy, minIz, maxIx, maxIy, maxIz =
				rangeSphere(record.x, record.y, record.z, r, self.COARSE_SIZE)
			for ix = minIx, maxIx do
				for iy = minIy, maxIy do
					for iz = minIz, maxIz do
						removeAllLinear(self, self.CoarseBuckets, ihash(ix, iy, iz), entity, false)
					end
				end
			end
		end
	elseif record.shape == EShape.AABB then
		local a = record :: RecordAABB
		-- fine
		do
			local minIx, minIy, minIz, maxIx, maxIy, maxIz =
				rangeAABB(record.x, record.y, record.z, a.halfx, a.halfy, a.halfz, self.CELL_SIZE)
			for ix = minIx, maxIx do
				for iy = minIy, maxIy do
					for iz = minIz, maxIz do
						removeAllLinear(self, self.FineBuckets, ihash(ix, iy, iz), entity, true)
					end
				end
			end
		end
		-- coarse
		do
			local minIx, minIy, minIz, maxIx, maxIy, maxIz =
				rangeAABB(record.x, record.y, record.z, a.halfx, a.halfy, a.halfz, self.COARSE_SIZE)
			for ix = minIx, maxIx do
				for iy = minIy, maxIy do
					for iz = minIz, maxIz do
						removeAllLinear(self, self.CoarseBuckets, ihash(ix, iy, iz), entity, false)
					end
				end
			end
		end
	else
		-- points
		return SpatialHash.Remove(self, entity)
	end

	self.Records[entity] = nil
	self.RecordsInfo[entity] = nil
end

--==[ Queries ]==--
function SpatialHashStatic.QueryAABB(
	minX: number,
	minY: number,
	minZ: number,
	maxX: number,
	maxY: number,
	maxZ: number,
	size: number,
	func: (EntityId) -> (),
	buckets: Buckets,
	records: Records
): ()
	if minX > maxX then
		minX, maxX = maxX, minX
	end
	if minY > maxY then
		minY, maxY = maxY, minY
	end
	if minZ > maxZ then
		minZ, maxZ = maxZ, minZ
	end

	local minIx, minIy, minIz = cellIndexSize(minX, minY, minZ, size)
	local maxIx, maxIy, maxIz = cellIndexSize(maxX, maxY, maxZ, size)

	for ix = minIx, maxIx do
		for iy = minIy, maxIy do
			for iz = minIz, maxIz do
				local hash = ihash(ix, iy, iz)
				local bucket = buckets[hash]
				if bucket == nil then continue end

				local cminx, cmaxx, cminy, cmaxy, cminz, cmaxz = cellAABB(ix, iy, iz, size)
				local rel = aabbRelation(cminx, cmaxx, cminy, cmaxy, cminz, cmaxz, minX, maxX, minY, maxY, minZ, maxZ)

				if rel == ERelation.Inside then
					for i = #bucket, 1, -1 do
						func(bucket[i])
					end
				elseif rel == ERelation.Intersect then
					for i = #bucket, 1, -1 do
						local entity = bucket[i]
						local rec = records[entity]
						if rec.shape == EShape.Point then
							if pointInAABB(rec.x, rec.y, rec.z, minX, maxX, minY, maxY, minZ, maxZ) then
								func(entity)
							end
						elseif rec.shape == EShape.Sphere then
							if
								sphereVsAABB(
									rec.x,
									rec.y,
									rec.z,
									(rec :: RecordSphere).radius ^ 2,
									minX,
									maxX,
									minY,
									maxY,
									minZ,
									maxZ
								)
							then
								func(entity)
							end
						else
							if
								aabbVsAABB(
									rec.x - (rec :: RecordAABB).halfx,
									rec.x + (rec :: RecordAABB).halfx,
									rec.y - (rec :: RecordAABB).halfy,
									rec.y + (rec :: RecordAABB).halfy,
									rec.z - (rec :: RecordAABB).halfz,
									rec.z + (rec :: RecordAABB).halfz,
									minX,
									maxX,
									minY,
									maxY,
									minZ,
									maxZ
								)
							then
								func(entity)
							end
						end
					end
				end
			end
		end
	end
end

function SpatialHashStatic.QuerySphere(
	cx: number,
	cy: number,
	cz: number,
	radius: number,
	size: number,
	func: (EntityId) -> (),
	buckets: Buckets,
	records: Records
): ()
	local r2 = radius * radius
	local minx, maxx = cx - radius, cx + radius
	local miny, maxy = cy - radius, cy + radius
	local minz, maxz = cz - radius, cz + radius

	local minIx, minIy, minIz = cellIndexSize(minx, miny, minz, size)
	local maxIx, maxIy, maxIz = cellIndexSize(maxx, maxy, maxz, size)

	for ix = minIx, maxIx do
		for iy = minIy, maxIy do
			for iz = minIz, maxIz do
				local hash = ihash(ix, iy, iz)
				local bucket = buckets[hash]
				if bucket == nil then continue end

				local cminx, cmaxx, cminy, cmaxy, cminz, cmaxz = cellAABB(ix, iy, iz, size)
				local rel = sphereAABBRelation(cminx, cmaxx, cminy, cmaxy, cminz, cmaxz, cx, cy, cz, r2)

				if rel == ERelation.Inside then
					for i = #bucket, 1, -1 do
						func(bucket[i])
					end
				elseif rel == ERelation.Intersect then
					for i = #bucket, 1, -1 do
						local entity = bucket[i]
						local rec = records[entity]

						if rec.shape == EShape.Point then
							if pointInRadius(rec.x - cx, rec.y - cy, rec.z - cz, r2) then func(entity) end
						elseif rec.shape == EShape.Sphere then
							if
								sphereVsSphere(rec.x, rec.y, rec.z, (rec :: RecordSphere).radius, cx, cy, cz, radius)
							then
								func(entity)
							end
						else
							if
								sphereVsAABB(
									cx,
									cy,
									cz,
									r2,
									rec.x - (rec :: RecordAABB).halfx,
									rec.x + (rec :: RecordAABB).halfx,
									rec.y - (rec :: RecordAABB).halfy,
									rec.y + (rec :: RecordAABB).halfy,
									rec.z - (rec :: RecordAABB).halfz,
									rec.z + (rec :: RecordAABB).halfz
								)
							then
								func(entity)
							end
						end
					end
				end
			end
		end
	end
end

function SpatialHashStatic.QueryAABBAsPoints(
	minX: number,
	minY: number,
	minZ: number,
	maxX: number,
	maxY: number,
	maxZ: number,
	size: number,
	func: (EntityId) -> (),
	buckets: Buckets,
	records: Records
): ()
	if minX > maxX then
		minX, maxX = maxX, minX
	end
	if minY > maxY then
		minY, maxY = maxY, minY
	end
	if minZ > maxZ then
		minZ, maxZ = maxZ, minZ
	end

	local minIx, minIy, minIz = cellIndexSize(minX, minY, minZ, size)
	local maxIx, maxIy, maxIz = cellIndexSize(maxX, maxY, maxZ, size)

	for ix = minIx, maxIx do
		for iy = minIy, maxIy do
			for iz = minIz, maxIz do
				local hash = ihash(ix, iy, iz)
				local bucket = buckets[hash]
				if bucket == nil then continue end

				local minx, maxx, miny, maxy, minz, maxz = cellAABB(ix, iy, iz, size)
				local rel = aabbRelation(minx, maxx, miny, maxy, minz, maxz, minX, maxX, minY, maxY, minZ, maxZ)

				if rel == ERelation.Inside then
					for i = #bucket, 1, -1 do
						func(bucket[i])
					end
				elseif rel == ERelation.Intersect then
					for i = #bucket, 1, -1 do
						local entity = bucket[i]
						local rec = records[entity] :: RecordPoint
						if pointInAABB(rec.x, rec.y, rec.z, minX, maxX, minY, maxY, minZ, maxZ) then func(entity) end
					end
				end
			end
		end
	end
end

function SpatialHashStatic.QuerySphereAsPoints(
	cx: number,
	cy: number,
	cz: number,
	radius: number,
	size: number,
	func: (EntityId) -> (),
	buckets: Buckets,
	records: Records
): ()
	local r2 = radius * radius
	local minx, maxx = cx - radius, cx + radius
	local miny, maxy = cy - radius, cy + radius
	local minz, maxz = cz - radius, cz + radius

	local minIx, minIy, minIz = cellIndexSize(minx, miny, minz, size)
	local maxIx, maxIy, maxIz = cellIndexSize(maxx, maxy, maxz, size)

	for ix = minIx, maxIx do
		for iy = minIy, maxIy do
			for iz = minIz, maxIz do
				local hash = ihash(ix, iy, iz)
				local bucket = buckets[hash]
				if bucket == nil then continue end

				local cminx, cmaxx, cminy, cmaxy, cminz, cmaxz = cellAABB(ix, iy, iz, size)
				local rel = sphereAABBRelation(cminx, cmaxx, cminy, cmaxy, cminz, cmaxz, cx, cy, cz, r2)

				if rel == ERelation.Inside then
					for i = #bucket, 1, -1 do
						func(bucket[i])
					end
				elseif rel == ERelation.Intersect then
					for i = #bucket, 1, -1 do
						local entity = bucket[i]
						local rec = records[entity]
						if pointInRadius(rec.x - cx, rec.y - cy, rec.z - cz, r2) then func(entity) end
					end
				end
			end
		end
	end
end

function SpatialHash.QueryAABB(
	self: SpatialHash,
	minX: number,
	minY: number,
	minZ: number,
	maxX: number,
	maxY: number,
	maxZ: number,
	func: (EntityId) -> ()
): ()
	if minX > maxX then
		minX, maxX = maxX, minX
	end
	if minY > maxY then
		minY, maxY = maxY, minY
	end
	if minZ > maxZ then
		minZ, maxZ = maxZ, minZ
	end

	local spanX, spanY, spanZ = maxX - minX, maxY - minY, maxZ - minZ
	local size: number
	local buckets: Buckets

	if spanX >= self.COARSE_SIZE * 4 or spanY >= self.COARSE_SIZE * 4 or spanZ >= self.COARSE_SIZE * 4 then
		size = self.COARSE_SIZE
		buckets = self.CoarseBuckets
	else
		size = self.CELL_SIZE
		buckets = self.FineBuckets
	end

	SpatialHashStatic.QueryAABB(minX, minY, minZ, maxX, maxY, maxZ, size, func, buckets, self.Records)
end

function SpatialHash.QuerySphere(
	self: SpatialHash,
	cx: number,
	cy: number,
	cz: number,
	radius: number,
	func: (EntityId) -> ()
): ()
	local size: number
	local buckets: Buckets

	if radius >= self.COARSE_SIZE * 4 then
		size = self.COARSE_SIZE
		buckets = self.CoarseBuckets
	else
		size = self.CELL_SIZE
		buckets = self.FineBuckets
	end

	SpatialHashStatic.QuerySphere(cx, cy, cz, radius, size, func, buckets, self.Records)
end

function SpatialHash.QueryAABBAsPoints(
	self: SpatialHash,
	minX: number,
	minY: number,
	minZ: number,
	maxX: number,
	maxY: number,
	maxZ: number,
	func: (EntityId) -> ()
): ()
	if minX > maxX then
		minX, maxX = maxX, minX
	end
	if minY > maxY then
		minY, maxY = maxY, minY
	end
	if minZ > maxZ then
		minZ, maxZ = maxZ, minZ
	end

	local spanX, spanY, spanZ = (maxX - minX), (maxY - minY), (maxZ - minZ)
	local size: number
	local buckets: Buckets

	if spanX >= self.COARSE_SIZE * 4 or spanY >= self.COARSE_SIZE * 4 or spanZ >= self.COARSE_SIZE * 4 then
		size = self.COARSE_SIZE
		buckets = self.CoarseBuckets
	else
		size = self.CELL_SIZE
		buckets = self.FineBuckets
	end

	SpatialHashStatic.QueryAABBAsPoints(minX, minY, minZ, maxX, maxY, maxZ, size, func, buckets, self.Records)
end

function SpatialHash.QuerySphereAsPoints(
	self: SpatialHash,
	cx: number,
	cy: number,
	cz: number,
	radius: number,
	func: (EntityId) -> ()
): ()
	local size: number
	local buckets: Buckets

	if radius >= self.COARSE_SIZE * 4 then
		size = self.COARSE_SIZE
		buckets = self.CoarseBuckets
	else
		size = self.CELL_SIZE
		buckets = self.FineBuckets
	end

	SpatialHashStatic.QuerySphereAsPoints(cx, cy, cz, radius, size, func, buckets, self.Records)
end

return SpatialHashStatic :: SpatialHashStatic
