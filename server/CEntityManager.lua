class 'CEntityManager'

function CEntityManager:__init()
    self.players = {} -- key = internal playerId, value = CPlayer
	self.offlinePlayers = {} -- key = steamId, value = COfflinePlayer
	self.inventories = {} -- key = inventoryId, value = CInventory
	self.itemBlueprints = {} -- key = itemBlueprintId, value = CItemBlueprint
	self.vehicles = {} -- key = autoincrement manually, value = CVehicle
	self.jobs = {} -- key = autoincrement manually, value = CJob
	self.levels = {} -- key = autoincrement manually, value = CLevel
	self.houses = {} -- key = autoincrement manually, value = CHouse
	self.droppedItems = {} -- key = staticObjectId, value = CDroppedItem
	self.businesses = {} -- key = autoincrement manually, value = CBusiness
	self.deliveries = {} -- key = table.insert, value = CDelivery
end

function CEntityManager:GetPlayer()
	return self.players
end

function CEntityManager:GetDelivery()
	return self.deliveries
end

function CEntityManager:GetOfflinePlayer()
	return self.offlinePlayers
end

function CEntityManager:GetInventory()
	return self.inventories
end

function CEntityManager:GetVehicle()
	return self.vehicles
end

function CEntityManager:GetItemBlueprint()
	return self.itemBlueprints
end

function CEntityManager:GetJob()
	return self.jobs
end

function CEntityManager:GetLevel()
	return self.levels
end

function CEntityManager:GetHouse()
	return self.houses
end

function CEntityManager:GetBusiness()
	return self.businesses
end

function CEntityManager:GetDroppedItem()
	return self.droppedItems
end

function CEntityManager:OutputInventoryTrees()
	for inventoryId, cInventory in pairs(self.inventories) do
		print("------------------------------")
		print(cInventory:GetId() .. " | " .. cInventory:GetName() .. " | " .. cInventory:GetMaxWeight())
		for itemId, cItem in pairs(cInventory:GetItem()) do
			print("|_ " .. cItem:GetItemBlueprint():GetId() .. " | " .. cItem:GetItemBlueprint():GetName() .. " | " .. cItem:GetItemBlueprint():GetDescription() .. " | " .. cItem:GetAmount())
			for key, value in pairs(cItem:GetItemBlueprint():GetAbility()) do
				print("|__ " .. key .. " | " .. value)
			end
		end
	end
end


-- TYPECAST STRINGS TO INT!!!!!!!!!!!!

function CEntityManager:LoadAllPlayers() -- update the offlineplayers every minute or whenever an online player exists the server?
	local query = SQL:Query("SELECT * FROM player")
	local result = query:Execute()
	
	if #result > 0 then
		for i = 1, #result do
			local cOfflinePlayer = COfflinePlayer(tonumber(result[i].id))
			
			local inventory = entityManager:GetInventory()[tonumber(result[i].inventory_id)]
			cOfflinePlayer:SetInventory(inventory)
			
			cOfflinePlayer:SetName(result[i].name)
			
			cOfflinePlayer:SetExperience(tonumber(result[i].experience))
			for index = 1, table.count(entityManager:GetLevel()) - 1, 1 do
				if cOfflinePlayer:GetExperience() >= entityManager:GetLevel()[index]:GetNeededExperience() and cOfflinePlayer:GetExperience() <= entityManager:GetLevel()[index+1]:GetNeededExperience() then
					cOfflinePlayer:SetLevel(entityManager:GetLevel()[index])
				end
			end
			
			if cOfflinePlayer:GetLevel() == nil then
				cOfflinePlayer:SetLevel(entityManager:GetLevel()[table.count(entityManager:GetLevel())])
			end
			
			entityManager:GetOfflinePlayer()[tonumber(result[i].id)] = cOfflinePlayer
		end
	end
	
	print("[JCMMO] " .. #result .. " offline players loaded")
end

function CEntityManager:InitializeFuelPumps()
	local transaction = SQL:Transaction()
	for _, vector in pairs(locations.petrolPumps) do	
		local returnedId, cInventory = database:CreateNewBusiness("Fuel Pump", vector, -1, "Petrol Pump Inventory", 100)
		
		local item = CItem(entityManager:GetItemBlueprint()[3], 50, -1, -1)
		item:SetPrice(50)
		item:SetSecondPrice(45)
		cInventory:AddItem(item)
		
		entityManager:GetBusiness()[returnedId] = CBusiness(returnedId, "Fuel Pump", vector, 1, "Shell Corporation", -1, cInventory)
		CCommunication.AddBusinessHotspot(
			{ 
				id = returnedId,
				name = entityManager:GetBusiness()[returnedId]:GetName(),
				position = vector,
				entity = "business",
				ownerId = -1
			}
		)
	end
	transaction:Commit()
end

function CEntityManager:InitializeVehicles()
	local policeSpawns = {
		[1] = { vector = Vector3(-9227.0693359375, 227.83074951172, 9615.755859375), angle = Angle(0.0001485073735239, 0.99997609853745, -0.0013341929297894) },
		[2] = { vector = Vector3(-9232.375, 227.83164978027, 9615.1455078125), angle = Angle(6.4593266870361e-005, 0.99976170063019, -0.001237771124579) },
		[3] = { vector = Vector3(-9242.490234375, 227.83497619629, 9615.6474609375), angle = Angle(9.8203010566067e-005, 0.99999701976776, 0.0023184379097074) },
		[4] = { vector = Vector3(-9249.57421875, 227.82711791992, 9625.1416015625), angle = Angle(-0.01259114779532, 0.96854776144028, -0.0029809710104018) },
		[5] = { vector = Vector3(-9250.142578125, 227.83444213867, 9637.3076171875), angle = Angle(-0.00012295255146455, 0.99966424703598, 0.009028603322804) },
		[6] = { vector = Vector3(-9262.4296875, 227.88151550293, 9640.595703125), angle = Angle(-0.0094192465767264, 0.7418926358223, 0.0093892868608236) },
		[7] = { vector = Vector3(-9271.552734375, 227.8348236084, 9623.279296875), angle = Angle(-0.00057069084141403, 0.032541383057833, -7.540792284999e-005) },
		[8] = { vector = Vector3(-9272.583984375, 227.61308288574, 9607.30859375), angle = Angle(-0.015520803630352, 0.031571950763464, -0.014644037932158) },		
		[9] = { vector = Vector3(-9272.998046875, 227.73927307129, 9585.7646484375), angle = Angle(-0.001975967315957, -0.0038464902900159, 0.018965553492308) },	
		[10] = { vector = Vector3(-9272.7705078125, 227.59918212891, 9560.087890625), angle = Angle(0.047503851354122, -0.005535801872611, -0.012532629072666) },	
	}
	
	local transaction = SQL:Transaction()
	for _, position in pairs(policeSpawns) do	
		local vehicle = Vehicle.Create(46, position.vector, position.angle)
		
		-- vehicle, playerId, posVector, rotVector, inventoryName, inventoryWeight
		local returnedId, cInventory = database:CreateNewVehicle(vehicle:GetId(), vehicle:GetModelId(), -1, position.vector, position.angle, "veh inv", 20)
		
		entityManager:GetVehicle()[vehicle:GetId()] = CVehicle(vehicle, cInventory, -1)
	end
	transaction:Commit()
end

function CEntityManager:InitializeDeliveries()
	if #entityManager:GetHouse() > 0 then
		for i = 1, 20, 1 do
			local delivery = CDelivery(i, "Test Delivery Route " .. i)
			local deliveryPoints = {}
			local houseTaken = {}
			
			local deliveryPointsCount = math.random(1, #entityManager:GetHouse())
			
			for index = 1, deliveryPointsCount, 1 do
				local houseId = math.random(#entityManager:GetHouse())
				local house = entityManager:GetHouse()[houseId]
				
				if houseTaken[house:GetId()] == nil then
					houseTaken[house:GetId()] = true
				
					deliveryPoints[index] = {}
					deliveryPoints[index].name = house:GetName()
					deliveryPoints[index].vector = house:GetPosition()
				end	
			end
			
			delivery:SetPoints(deliveryPoints)
			entityManager:GetDelivery()[i] = delivery
		end
	end
end

function CEntityManager:RandomizeLoot()
	local randomLootCount = 0
	
	local validItemIds = {}
	for id, _ in pairs(entityManager:GetItemBlueprint()) do
		table.insert(validItemIds, id)
	end
		
	local path = "geo.cbb.eez/go152-a.lod"
			
	for _, vector in pairs(locations.weaponPart) do
		local randomItemId = validItemIds[math.random(1, #validItemIds)]
		local object = StaticObject.Create(vector, Angle(0, 0, 0), path)
		entityManager:GetDroppedItem()[object:GetId()] = CDroppedItem(entityManager:GetItemBlueprint()[randomItemId], 1, object, "The World")
		randomLootCount = randomLootCount + 1
	end
	print("[JCMMO] " .. randomLootCount .. " random loot spawned")
	
	for _, vector in pairs(locations.cashStash) do
		local randomItemId = validItemIds[math.random(1, #validItemIds)]
		local object = StaticObject.Create(vector, Angle(0, 0, 0), path)
		entityManager:GetDroppedItem()[object:GetId()] = CDroppedItem(entityManager:GetItemBlueprint()[randomItemId], 1, object, "The World")
		randomLootCount = randomLootCount + 1
	end
	print("[JCMMO] " .. randomLootCount .. " random loot spawned")
	
	for _, vector in pairs(locations.armourPart) do
		local randomItemId = validItemIds[math.random(1, #validItemIds)]
		local object = StaticObject.Create(vector, Angle(0, 0, 0), path)
		entityManager:GetDroppedItem()[object:GetId()] = CDroppedItem(entityManager:GetItemBlueprint()[randomItemId], 1, object, "The World")
		randomLootCount = randomLootCount + 1
	end
	print("[JCMMO] " .. randomLootCount .. " random loot spawned")
	
	for _, vector in pairs(locations.vehiclePart) do
		local randomItemId = validItemIds[math.random(1, #validItemIds)]
		local object = StaticObject.Create(vector, Angle(0, 0, 0), path)
		entityManager:GetDroppedItem()[object:GetId()] = CDroppedItem(entityManager:GetItemBlueprint()[randomItemId], 1, object, "The World")
		randomLootCount = randomLootCount + 1
	end
	print("[JCMMO] " .. randomLootCount .. " random loot spawned")
end

function CEntityManager:LoadAllItems()
	local query = SQL:Query("SELECT * FROM item")
	local result = query:Execute()
	
	if #result > 0 then
		for i = 1, #result do
			local cItem = CItemBlueprint(result[i].id, result[i].name, result[i].description, result[i].weight, result[i].item_assembly_id)
			
			local queryItemAssembly = SQL:Query("SELECT * FROM item_assembly WHERE id = ?")
			queryItemAssembly:Bind(1, result[i].item_assembly_id)
			local itemAssemblyResult = queryItemAssembly:Execute()
			for j = 1, #itemAssemblyResult do
				cItem:GetAbility()[itemAssemblyResult[j].key] = itemAssemblyResult[j].value -- assign permissions to said item
			end
			
			self.itemBlueprints[tonumber(cItem:GetId())] = cItem
		end
	end
	
	print("[JCMMO] " .. #result .. " items loaded")
end

function CEntityManager:LoadAllDroppedItems()
	local query = SQL:Query("SELECT * FROM dropped_inventory_item")
	local result = query:Execute()
	
	if #result > 0 then
		for i = 1, #result do
			local path = "geo.cbb.eez/go152-a.lod"
			local vector = Vector3(tonumber(result[i].pos_x), tonumber(result[i].pos_y), tonumber(result[i].pos_z))
			local object = StaticObject.Create(vector, Angle(0, 0, 0), path)
			
			--print("blueprint requested: " .. entityManager:GetItemBlueprint()[tonumber(result[i].inventory_item_id)])
			entityManager:GetDroppedItem()[object:GetId()] = CDroppedItem(entityManager:GetItemBlueprint()[tonumber(result[i].inventory_item_id)], result[i].amount, object, entityManager:GetOfflinePlayer()[tonumber(result[i].owner_player_id)]:GetName()) -- tonumber because it's originally a string, also OFFLINEPLAYER
			--print("yes: " .. entityManager:GetDroppedItem()[object:GetId()]:GetItemBlueprint():GetId())
		end
	end
	
	print("[JCMMO] " .. #result .. " dropped items loaded")
end

function CEntityManager:LoadAllHouses()
	local query = SQL:Query("SELECT * FROM house")
	local result = query:Execute()
	
	if #result > 0 then
		for i = 1, #result do		
			local inventory = entityManager:GetInventory()[tonumber(result[i].inventory_id)]
			
			entityManager:GetHouse()[tonumber(result[i].id)] = CHouse(tonumber(result[i].id), result[i].name, Vector3(tonumber(result[i].pos_x), tonumber(result[i].pos_y), tonumber(result[i].pos_z)), tonumber(result[i].public), entityManager:GetOfflinePlayer()[tonumber(result[i].owner_player_id)]:GetName(), tonumber(result[i].owner_player_id), inventory)
			CCommunication.AddHouseHotspot(
				{ 
					id = tonumber(result[i].id),
					name = result[i].name,
					position = Vector3(tonumber(result[i].pos_x), tonumber(result[i].pos_y), tonumber(result[i].pos_z)),
					entity = "house",
					ownerId = tonumber(result[i].owner_player_id)
				}
			)
		end
	end
	
	print("[JCMMO] " .. #result .. " houses loaded")
end

function CEntityManager:LoadAllBusinesses()
	local query = SQL:Query("SELECT * FROM business")
	local result = query:Execute()
	
	if #result > 0 then
		for i = 1, #result do		
			local inventory = entityManager:GetInventory()[tonumber(result[i].inventory_id)]
			
			local playerName = nil
			if entityManager:GetOfflinePlayer()[tonumber(result[i].owner_player_id)] == nil then
				playerName = "world"
			else
				playerName = entityManager:GetOfflinePlayer()[tonumber(result[i].owner_player_id)]:GetName()
			end
			
			entityManager:GetBusiness()[tonumber(result[i].id)] = CBusiness(tonumber(result[i].id), result[i].name, Vector3(tonumber(result[i].pos_x), tonumber(result[i].pos_y), tonumber(result[i].pos_z)), tonumber(result[i].public), playerName, tonumber(result[i].owner_player_id), inventory)
			CCommunication.AddBusinessHotspot(
				{ 
					id = tonumber(result[i].id),
					name = result[i].name,
					position = Vector3(tonumber(result[i].pos_x), tonumber(result[i].pos_y), tonumber(result[i].pos_z)),
					entity = "business",
					ownerId = tonumber(result[i].owner_player_id)
				}
			)
		end
	end
	
	print("[JCMMO] " .. #result .. " businesses loaded")
end

function CEntityManager:LoadAllInventories()
	local query = SQL:Query("SELECT * FROM inventory")
	local inventoryResult = query:Execute()
	
	if #inventoryResult > 0 then
		local transaction = SQL:Transaction()
		for i = 1, #inventoryResult do		
			local cInventory = CInventory(inventoryResult[i].id, inventoryResult[i].name, inventoryResult[i].max_weight)
			
			-- going through all the items within that inventory
			local queryItems = SQL:Query("SELECT * FROM inventory_item WHERE inventory_id = ?")
			queryItems:Bind(1, inventoryResult[i].id)
			local itemsResult = queryItems:Execute()
			for j = 1, #itemsResult do
				local cItemBlueprint = entityManager:GetItemBlueprint()[tonumber(itemsResult[j].item_id)]
				local cItem = CItem(cItemBlueprint, itemsResult[j].amount, 0, 0)
							
				cInventory:AddItem(cItem)
			end
			
			self.inventories[tonumber(cInventory:GetId())] = cInventory			
		end
		transaction:Commit()
	end
	
	print("[JCMMO] " .. #inventoryResult .. " inventories loaded")
end