class 'CDroppedItem'

function CDroppedItem:__init(itemBlueprint, amount, object, owner) -- subclass of CItemBlueprint
    self.itemBlueprint = itemBlueprint
	self.amount = amount
	self.staticObject = object 
	self.owner = owner
end

function CDroppedItem:GetItemBlueprint()
	return self.itemBlueprint
end

function CDroppedItem:SetAmount(amount)
	self.amount = amount
end

function CDroppedItem:GetOwner()
	return self.owner
end

function CDroppedItem:GetStaticObject()
	return self.staticObject
end

function CDroppedItem:GetAmount()
	return self.amount
end
