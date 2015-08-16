class 'CItemBlueprint'

function CItemBlueprint:__init(id, name, description, weight, assemblyId)
    self.id = id
	self.name = name
	self.description = description
	self.weight = weight
	self.assemblyId = assemblyId
	self.abilities = {}
end

function CItemBlueprint:GetId()
	return self.id
end

function CItemBlueprint:GetName()
	return self.name
end

function CItemBlueprint:GetDescription()
	return self.description
end

function CItemBlueprint:GetWeight()
	return self.weight
end

function CItemBlueprint:GetAssemblyId()
	return self.assemblyId
end

function CItemBlueprint:GetAbility()
	return self.abilities
end

function CItemBlueprint:UseOnPlayer(cPlayer) -- no reference because items can be attached to ANYTHING
	local player = cPlayer:GetPlayer()
	
	for key, value in pairs(self.abilities) do
		if key == "add_health" then
			player:SetHealth(player:GetHealth() + tonumber(value))
			CCommunication.SendEventMessage(player, "Added health")
		elseif key == "add_money" then
			player:SetMoney(player:GetMoney() + tonumber(value))
			CCommunication.SendEventMessage(player, "Added money")
		end
	end
	
	cPlayer:GetInventory():GetItem()[self.id]:SetAmount(cPlayer:GetInventory():GetItem()[self.id]:GetAmount() - 1)
	
	local command = SQL:Command("UPDATE inventory_item SET amount = ? WHERE item_id = ? AND inventory_id = ?")
	command:Bind(1, cPlayer:GetInventory():GetItem()[self.id]:GetAmount())
	command:Bind(2, self.id)
	command:Bind(3, cPlayer:GetInventory():GetId())
	command:Execute()
end
