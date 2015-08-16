class 'CHouse'

function CHouse:__init(id, name, position, public, ownerName, ownerId, inventory)
    self.id = id
	self.name = name
	self.visitors = {}
	self.position = position
	self.public = public
	self.ownerName = ownerName
	self.ownerId = ownerId
	self.inventory = inventory
end

function CHouse:GetName()
	return self.name
end

function CHouse:GetId()
	return self.id
end

function CHouse:GetPosition()
	return self.position
end

function CHouse:GetVisitors()
	return self.visitors
end

function CHouse:GetPublic()
	return self.public
end

function CHouse:GetOwnerName()
	return self.ownerName
end

function CHouse:GetOwnerId()
	return self.ownerId
end

function CHouse:GetInventory()
	return self.inventory
end