class 'CBusiness'

function CBusiness:__init(id, name, position, public, ownerName, ownerId, inventory)
    self.id = id
	self.name = name
	self.visitors = {}
	self.position = position
	self.public = public
	self.ownerName = ownerName
	self.ownerId = ownerId
	self.inventory = inventory
end

function CBusiness:GetName()
	return self.name
end

function CBusiness:GetId()
	return self.id
end

function CBusiness:GetPosition()
	return self.position
end

function CBusiness:GetVisitors()
	return self.visitors
end

function CBusiness:GetPublic()
	return self.public
end

function CBusiness:GetOwnerName()
	return self.ownerName
end

function CBusiness:GetOwnerId()
	return self.ownerId
end

function CBusiness:GetInventory()
	return self.inventory
end