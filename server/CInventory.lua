class 'CInventory'

function CInventory:__init(id, name, maxWeight)
    self.id = id
	self.name = name
	self.maxWeight = maxWeight
	
	self.items = {} -- key = cItem:GetId(), value = CItem
end

function CInventory:GetId()
	return self.id
end

function CInventory:GetName()
	return self.name
end

function CInventory:GetMaxWeight()
	return self.maxWeight
end

function CInventory:AddItem(item)
	local command = SQL:Command("INSERT OR REPLACE INTO inventory_item (inventory_id, item_id, amount, price, second_price) VALUES (?, ?, ?, ?, ?);")
	command:Bind(1, self.id)
	command:Bind(2, item:GetItemBlueprint():GetId())
	
	if self.items[item:GetItemBlueprint():GetId()] == nil then
		self.items[item:GetItemBlueprint():GetId()] = item
		command:Bind(3, item:GetAmount())
		command:Bind(4, item:GetPrice())
		command:Bind(5, item:GetSecondPrice())
	else
		local updatedItem = self.items[item:GetItemBlueprint():GetId()]
		updatedItem:SetAmount(item:GetAmount() + updatedItem:GetAmount())
		command:Bind(3, updatedItem:GetAmount())
		command:Bind(4, updatedItem:GetPrice())
		command:Bind(5, updatedItem:GetSecondPrice())
	end

	command:Execute()
end

function CInventory:DeleteItem(item)
	print("now: ")
	for id, cItem in pairs(self.items) do
		print("- " .. cItem:GetItemBlueprint():GetName())
	end
	self.items[item] = nil
	
	print("after: ")
	for id, cItem in pairs(self.items) do
		print("- " .. cItem:GetItemBlueprint():GetName())
	end
end

function CInventory:GetItem()
	return self.items
end