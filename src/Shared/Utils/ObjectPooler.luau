export type ObjectPoolerAPI<T> = {
	Object: T,
	ReturnFunction: (object: T) -> (),
	Parent: Instance?,
	RepoolQuantity: number,
	Pool: { T },
	Get: (self: ObjectPoolerAPI<T>) -> T,
	Return: (self: ObjectPoolerAPI<T>, object: T) -> (),
	Repoblate: (self: ObjectPoolerAPI<T>, quantity: number) -> (),
}

local ObjectPoolerStatic = {}
ObjectPoolerStatic.IDLE_CF = CFrame.new(2 ^ 24, 2 ^ 24, 2 ^ 24)

local ObjectPooler = {}
ObjectPooler.__index = ObjectPooler

function ObjectPoolerStatic.new<T>(
	object: T,
	initialQuantity: number,
	repoolQuantity: number,
	returnFunction: (object: T) -> (),
	parent: Instance?
): ObjectPoolerAPI<T>
	local self = (setmetatable({}, ObjectPooler) :: any) :: ObjectPoolerAPI<T>
	self.Object = object
	self.ReturnFunction = returnFunction
	self.Parent = parent
	self.RepoolQuantity = repoolQuantity
	self.Pool = {}

	returnFunction(object)
	self:Repoblate(initialQuantity)
	return self
end

function ObjectPoolerStatic.ReturnBoneModel(object: any)
	object.PrimaryPart.Root.CFrame = ObjectPoolerStatic.IDLE_CF
end

function ObjectPoolerStatic.ReturnCF(object: any)
	object.CFrame = ObjectPoolerStatic.IDLE_CF
end

function ObjectPoolerStatic.ReturnUIObject(object: any)
	if not object.Visible then return end
	object.Visible = false
end

function ObjectPoolerStatic.ReturnParentNil(object: any)
	object.Parent = nil
end

function ObjectPoolerStatic.ReturnAdornee(object: any)
	object.Adornee = nil
end

function ObjectPooler.Repoblate<T>(self: ObjectPoolerAPI<T>, quantity: number)
	for _ = 1, quantity do
		local clone = (self.Object :: any):Clone()
		clone.Parent = self.Parent
		self.Pool[#self.Pool + 1] = clone
	end
end

function ObjectPooler.Get<T>(self: ObjectPoolerAPI<T>): T
	if #self.Pool == 0 then
		if self.RepoolQuantity == 0 then return nil :: any end
		self:Repoblate(self.RepoolQuantity)
	end

	return table.remove(self.Pool) :: T
end

function ObjectPooler.Return<T>(self: ObjectPoolerAPI<T>, object: T)
	self.Pool[#self.Pool + 1] = object
	self.ReturnFunction(object)
end

return ObjectPoolerStatic
