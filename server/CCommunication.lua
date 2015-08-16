class 'CCommunication'

function CCommunication:__init()
	Network:Subscribe("AskServerForInventory", self, self.AskServerForInventory) -- CClientInventory
	Network:Subscribe("SetPlayerInJob", self, self.SetPlayerInJob) -- CClientJobSelection
	Network:Subscribe("UseItem", self, self.UseItem) -- CClientInventory
	Network:Subscribe("DropItem", self, self.DropItem) -- CClientInventory
	Network:Subscribe("SendItemToEntity", self, self.SendItemToEntity) -- CClientInventory
	Network:Subscribe("SendItemToPlayer", self, self.SendItemToPlayer) -- CClientInventory
	Network:Subscribe("SetItemPrice", self, self.SetItemPrice) -- CClientBusinessDialog
	Network:Subscribe("AskServerForDeliveryJobs", self, self.AskServerForDeliveryJobs) -- CClientDeliveryJob
	Network:Subscribe("ActivateDeliveryJobForPlayer", self, self.ActivateDeliveryJobForPlayer) -- CClientDeliveryJob
	
	Network:Subscribe("AskServerForMyCurrentJob", self, self.AskServerForMyCurrentJob)
	
	Events:Subscribe("PostTick", self, self.UpdateClientSideValues)
	
	self.tickTimer = Timer()
end

function CCommunication:UpdateClientSideValues()
	if self.tickTimer:GetSeconds() > 1 then	
		self.tickTimer:Restart()
	end
end

function CCommunication.SendEventMessage(player, message)
	Network:Send(player, "AddMessage", message)
end

function CCommunication.SendEventMessageToAll(message)
	Network:Broadcast("AddMessage", message)
end

function CCommunication.SendProgressBarUpdate(player, value)
	Network:Send(player, "UpdateProgressBar", value)
end

function CCommunication.SendHotspots(value)
	Network:Broadcast("Hotspots", value)
end

function CCommunication.AddHouseHotspot(value)
	Network:Broadcast("AddHouseHotspot", value)
end

function CCommunication.AddBusinessHotspot(value)
	Network:Broadcast("AddBusinessHotspot", value)
end

function CCommunication:AskServerForMyCurrentJob(args)
	local playerId = args[1]
	local source = args[2]
	
	local player = Player.GetById(playerId)
	local cPlayer = entityManager:GetPlayer()[player:GetId()]
	
	print(cPlayer:GetJob():GetName())
	
	if cPlayer:GetJob():GetName() == "Courier Service" and source == "Courier Service" then
		Network:Send(player, "ProceedJobDialog", { "Courier Service" })
	elseif cPlayer:GetJob():GetName() == "Police" and source == "Police" then
		Network:Send(player, "ProceedJobDialog", { "Police" })
	end
end

function CCommunication:ActivateDeliveryJobForPlayer(args)
	local player = Player.GetById(args[1])
	local cDelivery = entityManager:GetDelivery()[args[2]]
	
	if player:GetVehicle() ~= nil then
		local cPlayer = entityManager:GetPlayer()[player:GetId()]
		print(":"..cDelivery:GetName())
		cPlayer:SetDeliveryJob(cDelivery)
		
		local tableConstruction = {}
		tableConstruction.id = args[2]
		tableConstruction.name = cDelivery:GetName()
		tableConstruction.totalPay = cDelivery:GetTotalPay()
		tableConstruction.totalDistance = cDelivery:GetTotalDistance()
		tableConstruction.points = {}
		
		for idPoint, data in pairs(cDelivery:GetPoints(args[2])) do
			tableConstruction.points[idPoint] = {}
			tableConstruction.points[idPoint].name = cDelivery:GetPoints()[idPoint].name
			tableConstruction.points[idPoint].vector = cDelivery:GetPoints()[idPoint].vector
		end
		
		Network:Send(player, "AddDeliveryToHUD", tableConstruction)
	else
		CCommunication.SendEventMessage(player, "You need to be in a vehicle!")
	end
end

function CCommunication:AskServerForDeliveryJobs(args)
	local player = Player.GetById(args[1])
	local tableConstruction = {}
		
	for id, cDelivery in pairs(entityManager:GetDelivery()) do
		tableConstruction[id] = {}
		tableConstruction[id].name = cDelivery:GetName()
		tableConstruction[id].points = {}
		
		for idPoint, data in pairs(cDelivery:GetPoints(id)) do
			tableConstruction[id].points[idPoint] = {}
			tableConstruction[id].points[idPoint].name = cDelivery:GetPoints()[idPoint].name
			tableConstruction[id].points[idPoint].vector = cDelivery:GetPoints()[idPoint].vector
		end
	end
		
	Network:Send(player, "UpdateDeliveryJobsScreen", tableConstruction)
end

function CCommunication:SetItemPrice(args)
	local inventoryId = args.invId
	local itemId = args.itemId
	local price = args.price
	local state = args.state
	local entityId = args.entityId

	local cEntity = entityManager:GetBusiness()[tonumber(entityId)]
	
	if state == "first" then
		local secondPrice = cEntity:GetInventory():GetItem()[itemId]:GetSecondPrice()
		if price < secondPrice then
			return
		end
		
		local command = SQL:Command("UPDATE inventory_item SET price = ? WHERE item_id = ? AND inventory_id = ?")
		command:Bind(1, price)
		command:Bind(2, itemId)
		command:Bind(3, inventoryId)
		command:Execute()
		cEntity:GetInventory():GetItem()[itemId]:SetPrice(tonumber(price))
	elseif state == "second" then
		local firstPrice = cEntity:GetInventory():GetItem()[itemId]:GetPrice()
		
		if price > firstPrice then
			return
		end
		
		local command = SQL:Command("UPDATE inventory_item SET second_price = ? WHERE item_id = ? AND inventory_id = ?")
		command:Bind(1, price)
		command:Bind(2, itemId)
		command:Bind(3, inventoryId)
		command:Execute()
		cEntity:GetInventory():GetItem()[itemId]:SetSecondPrice(tonumber(price))
	end
end

function CCommunication:SendItemToEntity(args)
	local playerId = args.fromPlayerId
	local toEntityId = args.toEntityId
	local amount = args.amount
	local itemId = args.itemId
	local state = args.state
	
	
	local cPlayer = entityManager:GetPlayer()[playerId]
	local cEntity = nil
	if state == "business" then
		cEntity = entityManager:GetBusiness()[tonumber(toEntityId)]
	elseif state == "house" then
		cEntity = entityManager:GetHouse()[tonumber(toEntityId)]
	elseif state == "vehicle" then
		cEntity = entityManager:GetVehicle()[tonumber(toEntityId)]
	end
	
	cPlayer:GetInventory():GetItem()[itemId]:SetAmount(cPlayer:GetInventory():GetItem()[itemId]:GetAmount() - amount)
	
	local command = SQL:Command("UPDATE inventory_item SET amount = ? WHERE item_id = ? AND inventory_id = ?")
	command:Bind(1, cPlayer:GetInventory():GetItem()[itemId]:GetAmount())
	command:Bind(2, itemId)
	command:Bind(3, cPlayer:GetInventory():GetId())
	command:Execute()
	
	if cEntity:GetInventory():GetItem()[itemId] == nil then -- item doesnt exist, thus create it!
		local item = CItem(entityManager:GetItemBlueprint()[tonumber(itemId)], amount, -1, -1)
		cEntity:GetInventory():AddItem(item)
	else
		cEntity:GetInventory():GetItem()[itemId]:SetAmount(cEntity:GetInventory():GetItem()[itemId]:GetAmount() + amount)
	end
	
	command = SQL:Command("UPDATE inventory_item SET amount = ? WHERE item_id = ? AND inventory_id = ?")
	command:Bind(1, cEntity:GetInventory():GetItem()[itemId]:GetAmount())
	command:Bind(2, itemId)
	command:Bind(3, cEntity:GetInventory():GetId())
	command:Execute()
	
	print("Received: pid: sent")
end

function CCommunication:SendItemToPlayer(args)
	local entityId = args.fromEntityId
	local toPlayerId = args.toPlayerId
	local amount = args.amount
	local itemId = args.itemId
	local state = args.state
	
	print("Received: pid: " .. toPlayerId .. ", en: " .. entityId .. ", amount: " .. amount .. ", itemId: " .. itemId)
	
	local cEntity = nil
	if state == "business" then
		cEntity = entityManager:GetBusiness()[tonumber(entityId)]
		
		local player = Player.GetById(toPlayerId)
		if player:GetMoney() > cEntity:GetInventory():GetItem()[itemId]:GetPrice() * amount then
			player:SetMoney(player:GetMoney() - cEntity:GetInventory():GetItem()[itemId]:GetPrice() * amount)
			CCommunication.SendEventMessage(player, "[PURCHASE] $" .. (cEntity:GetInventory():GetItem()[itemId]:GetPrice() * amount) .. " has been subtracted from your account!")
		end
	elseif state == "house" then
		cEntity = entityManager:GetHouse()[tonumber(entityId)]
	elseif state == "vehicle" then
		cEntity = entityManager:GetVehicle()[tonumber(entityId)]
	end
	
	local cPlayer = entityManager:GetPlayer()[toPlayerId]
	
	local foundItem = cEntity:GetInventory():GetItem()[itemId]:GetItemBlueprint():GetId()
	
	if cEntity:GetInventory():GetItem()[itemId]:GetAmount() - amount < 0 or amount < 1 then 
		CCommunication.SendEventMessage(Player.GetById(toPlayerId), "Invalid amount!") 
		return 
	end
	
	cEntity:GetInventory():GetItem()[itemId]:SetAmount(cEntity:GetInventory():GetItem()[itemId]:GetAmount() - amount)
	
	if cEntity:GetInventory():GetItem()[itemId]:GetAmount() == 0 then 
		cEntity:GetInventory():DeleteItem(foundItem) 

		local command = SQL:Command("DELETE FROM inventory_item WHERE item_id = ? AND inventory_id = ?")
		command:Bind(1, itemId)
		command:Bind(2, cEntity:GetInventory():GetId())
		command:Execute()
	else
		local command = SQL:Command("UPDATE inventory_item SET amount = ? WHERE item_id = ? AND inventory_id = ?")
		command:Bind(1, cEntity:GetInventory():GetItem()[itemId]:GetAmount())
		command:Bind(2, itemId)
		command:Bind(3, cEntity:GetInventory():GetId())
		command:Execute()
	end
	
	if cPlayer:GetInventory():GetItem()[itemId] == nil then -- item doesnt exist, thus create it!
		local item = CItem(entityManager:GetItemBlueprint()[tonumber(itemId)], amount, -1, -1)
		cPlayer:GetInventory():AddItem(item)
	else
		cPlayer:GetInventory():GetItem()[itemId]:SetAmount(cPlayer:GetInventory():GetItem()[itemId]:GetAmount() + amount)
	end
	
	local command = SQL:Command("UPDATE inventory_item SET amount = ? WHERE item_id = ? AND inventory_id = ?")
	command:Bind(1, cPlayer:GetInventory():GetItem()[itemId]:GetAmount())
	command:Bind(2, itemId)
	command:Bind(3, cPlayer:GetInventory():GetId())
	command:Execute()
	
	print("Received: pid: sent")
end

function CCommunication:UseItem(args)
	local playerId = args.playerId
	local itemId = args.itemId
	
	local cPlayer = entityManager:GetPlayer()[playerId]
	cPlayer:GetInventory():GetItem()[itemId]:GetItemBlueprint():UseOnPlayer(cPlayer)
end

function CCommunication:DropItem(args)
	local playerId = args.playerId
	local itemId = args.itemId
	local amount = args.amount
	
	local player = Player.GetById(playerId)
	
	local command = SQL:Command("INSERT INTO dropped_inventory_item (inventory_item_id, owner_player_id, pos_x, pos_y, pos_z, amount) VALUES (?, ?, ?, ?, ?, ?)")
	command:Bind(1, itemId)
	command:Bind(2, player:GetSteamId().id)
	command:Bind(3, player:GetPosition().x)
	command:Bind(4, player:GetPosition().y)
	command:Bind(5, player:GetPosition().z)
	command:Bind(6, amount)
	command:Execute()
	
	local path = "geo.cbb.eez/go152-a.lod"
	local object = StaticObject.Create(player:GetPosition(), Angle(0, 0, 0), path)
	
	entityManager:GetDroppedItem()[object:GetId()] = CDroppedItem(entityManager:GetItemBlueprint()[tonumber(itemId)], amount, object, player:GetName()) -- tonumber because it's originally a string
	
	local droppedItem = entityManager:GetDroppedItem()[object:GetId()] -- :D
	
	Network:Broadcast("AddItem", 
		{
			id = droppedItem:GetItemBlueprint():GetId(),
			name = droppedItem:GetItemBlueprint():GetName(),
			amount = droppedItem:GetAmount(),
			weight = droppedItem:GetItemBlueprint():GetWeight(),
			owner = player:GetName(),
			position = player:GetPosition()
		}
	)
	
	local cPlayer = entityManager:GetPlayer()[playerId]
	
	cPlayer:GetInventory():GetItem()[itemId]:SetAmount(cPlayer:GetInventory():GetItem()[itemId]:GetAmount() - amount)
	
	local command = SQL:Command("UPDATE inventory_item SET amount = ? WHERE item_id = ?")
	command:Bind(1, cPlayer:GetInventory():GetItem()[itemId]:GetAmount())
	command:Bind(2, itemId)
	command:Execute()
	
	print("DROPPING")
end

function CCommunication.ShowJobSelectionScreen(player)
	print("called: " .. table.count(entityManager:GetJob()))
	local tableConstruction = {}
		
	for id, cJob in pairs(entityManager:GetJob()) do
		tableConstruction[id] = {}
		tableConstruction[id].name = cJob:GetName()
		tableConstruction[id].description = cJob:GetDescription()
		tableConstruction[id].features = cJob:GetFeatures()
	end
		
	Network:Send(player, "UpdateJobSelectionScreen", tableConstruction)
end

function CCommunication:SetPlayerInJob(args)
	local playerId = args.id
	local jobId = args.jobId
	local job = entityManager:GetJob()[jobId]
	local cPlayer = entityManager:GetPlayer()[playerId]
	
	cPlayer:SetJob(job)
	cPlayer:GetPlayer():SetPosition(cPlayer:GetJob():GetSpawn())
	
	local command = SQL:Command("UPDATE player SET job_id = ? WHERE id = ?")
	command:Bind(1, jobId)
	command:Bind(2, cPlayer:GetPlayer():GetSteamId().id)
	command:Execute()
	
	CCommunication.SendEventMessage(cPlayer:GetPlayer(), "You have enlisted in a new job: " .. job:GetName())
end

function CCommunication:AskServerForInventory(args)
	local playerId = args[1]
	local state = args[2]
	local hotspotId = args[3]
	
	if state == "player" then
		local cPlayer = entityManager:GetPlayer()[playerId]
		local itemData = {}
		
		for _, cItem in pairs(cPlayer:GetInventory():GetItem()) do
			itemData[cItem:GetItemBlueprint():GetId()] = {}
			itemData[cItem:GetItemBlueprint():GetId()].name = cItem:GetItemBlueprint():GetName()
			itemData[cItem:GetItemBlueprint():GetId()].amount = cItem:GetAmount()
			itemData[cItem:GetItemBlueprint():GetId()].description = cItem:GetItemBlueprint():GetDescription()
			itemData[cItem:GetItemBlueprint():GetId()].weight = cItem:GetItemBlueprint():GetWeight()
			itemData[cItem:GetItemBlueprint():GetId()].totalWeight = cItem:GetAmount() * cItem:GetItemBlueprint():GetWeight()
			
			itemData[cItem:GetItemBlueprint():GetId()].assembly = {}
			for key, value in pairs(cItem:GetItemBlueprint():GetAbility()) do
				itemData[cItem:GetItemBlueprint():GetId()].assembly[key] = value
			end
		end
	
		Network:Send(Player.GetById(playerId), "UpdateInventoryScreen", 
		{ 	
			inventoryName = cPlayer:GetInventory():GetName(), 
			inventoryMaxWeight = cPlayer:GetInventory():GetMaxWeight(),
			inventoryContents = itemData
		})
	elseif state == "business" then
		local cBusiness = entityManager:GetBusiness()[hotspotId]
		local itemData = {}
		
		for _, cItem in pairs(cBusiness:GetInventory():GetItem()) do
			itemData[cItem:GetItemBlueprint():GetId()] = {}
			itemData[cItem:GetItemBlueprint():GetId()].name = cItem:GetItemBlueprint():GetName()
			itemData[cItem:GetItemBlueprint():GetId()].amount = cItem:GetAmount()
			itemData[cItem:GetItemBlueprint():GetId()].description = cItem:GetItemBlueprint():GetDescription()
			itemData[cItem:GetItemBlueprint():GetId()].weight = cItem:GetItemBlueprint():GetWeight()
			itemData[cItem:GetItemBlueprint():GetId()].totalWeight = cItem:GetAmount() * cItem:GetItemBlueprint():GetWeight()
			itemData[cItem:GetItemBlueprint():GetId()].price = cItem:GetPrice()
			itemData[cItem:GetItemBlueprint():GetId()].secondPrice = cItem:GetSecondPrice()
			
			itemData[cItem:GetItemBlueprint():GetId()].assembly = {}
			for key, value in pairs(cItem:GetItemBlueprint():GetAbility()) do
				itemData[cItem:GetItemBlueprint():GetId()].assembly[key] = value
			end
		end
	
		Network:Send(Player.GetById(playerId), "UpdateBusinessInventoryScreen", 
		{ 	
			inventoryId = cBusiness:GetInventory():GetId(),
			inventoryName = cBusiness:GetInventory():GetName(), 
			inventoryMaxWeight = cBusiness:GetInventory():GetMaxWeight(),
			inventoryContents = itemData
		})
	elseif state == "house" then
		local cHouse = entityManager:GetHouse()[hotspotId]
		local itemData = {}
		
		for _, cItem in pairs(cHouse:GetInventory():GetItem()) do
			itemData[cItem:GetItemBlueprint():GetId()] = {}
			itemData[cItem:GetItemBlueprint():GetId()].name = cItem:GetItemBlueprint():GetName()
			itemData[cItem:GetItemBlueprint():GetId()].amount = cItem:GetAmount()
			itemData[cItem:GetItemBlueprint():GetId()].description = cItem:GetItemBlueprint():GetDescription()
			itemData[cItem:GetItemBlueprint():GetId()].weight = cItem:GetItemBlueprint():GetWeight()
			itemData[cItem:GetItemBlueprint():GetId()].totalWeight = cItem:GetAmount() * cItem:GetItemBlueprint():GetWeight()
			
			itemData[cItem:GetItemBlueprint():GetId()].assembly = {}
			for key, value in pairs(cItem:GetItemBlueprint():GetAbility()) do
				itemData[cItem:GetItemBlueprint():GetId()].assembly[key] = value
			end
		end
	
		Network:Send(Player.GetById(playerId), "UpdateHouseInventoryScreen", 
		{ 	
			inventoryName = cHouse:GetInventory():GetName(), 
			inventoryMaxWeight = cHouse:GetInventory():GetMaxWeight(),
			inventoryContents = itemData
		})
	elseif state == "vehicle" then
		if entityManager:GetVehicle()[hotspotId] == nil then
			CCommunication.SendEventMessage(Player.GetById(playerId), "This vehicle doesn't have an inventory")
			return
		end
		
		local cVehicle = entityManager:GetVehicle()[hotspotId]
		local itemData = {}
		
		for _, cItem in pairs(cVehicle:GetInventory():GetItem()) do
			itemData[cItem:GetItemBlueprint():GetId()] = {}
			itemData[cItem:GetItemBlueprint():GetId()].name = cItem:GetItemBlueprint():GetName()
			itemData[cItem:GetItemBlueprint():GetId()].amount = cItem:GetAmount()
			itemData[cItem:GetItemBlueprint():GetId()].description = cItem:GetItemBlueprint():GetDescription()
			itemData[cItem:GetItemBlueprint():GetId()].weight = cItem:GetItemBlueprint():GetWeight()
			itemData[cItem:GetItemBlueprint():GetId()].totalWeight = cItem:GetAmount() * cItem:GetItemBlueprint():GetWeight()
			
			itemData[cItem:GetItemBlueprint():GetId()].assembly = {}
			for key, value in pairs(cItem:GetItemBlueprint():GetAbility()) do
				itemData[cItem:GetItemBlueprint():GetId()].assembly[key] = value
			end
		end
	
		Network:Send(Player.GetById(playerId), "UpdateVehicleInventoryScreen", 
		{ 	
			inventoryName = cVehicle:GetInventory():GetName(), 
			inventoryMaxWeight = cVehicle:GetInventory():GetMaxWeight(),
			inventoryContents = itemData
		})
	end
end

cCommunication = CCommunication()
