class 'CItem'

function CItem:__init(itemBlueprint, amount, price, discountPrice) -- subclass of CItemBlueprint
    self.itemBlueprint = itemBlueprint
	self.amount = amount
	
	self.price = price
	self.discountPrice = discountPrice
end

function CItem:GetItemBlueprint()
	return self.itemBlueprint
end

function CItem:SetAmount(amount)
	self.amount = amount
end

function CItem:GetAmount()
	return self.amount
end

function CItem:SetPrice(price)
	self.price = price
end

function CItem:GetPrice()
	return self.price
end

function CItem:SetSecondPrice(price)
	self.discountPrice = price
end

function CItem:GetSecondPrice()
	return self.discountPrice
end