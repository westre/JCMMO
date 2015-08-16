class 'CGame'

function CGame:__init()
	Events:Subscribe("ModulesLoad", self, self.ModuleLoad)
	Events:Subscribe("ModuleUnload", self, self.ModuleUnload)
	Events:Subscribe("PlayerJoin", self, self.PlayerJoin)
	Events:Subscribe("PlayerQuit", self, self.PlayerQuit)
	Events:Subscribe("PlayerSpawn", self, self.PlayerSpawn)
	Events:Subscribe("PlayerEnterVehicle", self, self.EnterVehicle)
end

function CGame:ModuleLoad()
	entityManager = CEntityManager()
	database = CDatabase()
	
	-- needs to load in this order!
	entityManager:LoadAllItems()
	entityManager:LoadAllInventories()
	entityManager:LoadAllPlayers()
	entityManager:LoadAllDroppedItems()
	entityManager:LoadAllHouses()
	entityManager:LoadAllBusinesses()
	
	entityManager:RandomizeLoot()
	
	--entityManager:InitializeFuelPumps() -- ONLY 1st USE!
	--entityManager:InitializeVehicles() -- ONLY 1st USE!
	entityManager:InitializeDeliveries()
	
	--entityManager:OutputInventoryTrees()
	--database:Output()
	
	entityManager:GetJob()[1] = CJob(1, "Courier Service", "Delivers all kind of things to households and businesses!", "Brings goods to households and businesses")
	entityManager:GetJob()[1]:SetSpawn(Vector3(-9200.4580078125, 229.40693664551, 9649.1884765625))
	entityManager:GetJob()[2] = CJob(2, "Police", "Bring order and censorship!", "Arrests wanted players\nInspects deliveries\nResponds to emergency calls")
	entityManager:GetJob()[2]:SetSpawn(Vector3(-9200.4580078125, 229.40693664551, 9649.1884765625))
	entityManager:GetJob()[3] = CJob(3, "Medical Job", "Revive and heal those filthy peasants!", "Responds to emergency calls")
	entityManager:GetJob()[3]:SetSpawn(Vector3(-9200.4580078125, 229.40693664551, 9649.1884765625))
	entityManager:GetJob()[4] = CJob(4, "Transport Job", "Export and import that shit!", "Regional deliveries\nTransregional deliveries\nInterregional deliveries\nCan overload goods (illegal)")
	entityManager:GetJob()[4]:SetSpawn(Vector3(-9200.4580078125, 229.40693664551, 9649.1884765625))
	entityManager:GetJob()[5] = CJob(5, "Drug Job", "420 blaze it faggot.", "Sells drugs to people (illegal)")
	entityManager:GetJob()[5]:SetSpawn(Vector3(-9200.4580078125, 229.40693664551, 9649.1884765625))
	entityManager:GetJob()[6] = CJob(6, "Robber Job", "Rob people, who know you might find a dollah here and there!", "Robs pocket cash (illegal)\nCan rob stores (illegal)\nCan rob businesses (illegal)")
	entityManager:GetJob()[6]:SetSpawn(Vector3(-9200.4580078125, 229.40693664551, 9649.1884765625))
	entityManager:GetJob()[7] = CJob(7, "Car Jacker Job", "Jack some cars and sell them!", "Jacks cars (illegal)\nExports stolen cars (illegal)")
	entityManager:GetJob()[7]:SetSpawn(Vector3(-9200.4580078125, 229.40693664551, 9649.1884765625))
	
	entityManager:GetLevel()[1] = CLevel(1)
	entityManager:GetLevel()[1]:SetNeededExperience(0)
	entityManager:GetLevel()[2] = CLevel(2)
	entityManager:GetLevel()[2]:SetNeededExperience(500)
	entityManager:GetLevel()[3] = CLevel(3)
	entityManager:GetLevel()[3]:SetNeededExperience(1250)
	
	for player in Server:GetPlayers() do
		local successful = database:AttemptPlayer(player)
		local cPlayer = CPlayer(player)	
		local playerData = database:GetPlayerData(player:GetSteamId().id)

		local inventory = entityManager:GetInventory()[tonumber(playerData[1].inventory_id)]
		cPlayer:SetInventory(inventory)
		cPlayer:SetExperience(tonumber(playerData[1].experience)) -- all results are strings
		
		if successful then
			player:SendChatMessage("[pInventory] Inventory loaded.", Color(128, 0, 128))
		else
			player:SendChatMessage("[pInventory] Inventory created. Press 'F6' for your inventory.", Color(128, 0, 128))
		end
		
		for index = 1, table.count(entityManager:GetLevel()) - 1, 1 do
			if cPlayer:GetExperience() >= entityManager:GetLevel()[index]:GetNeededExperience() and cPlayer:GetExperience() <= entityManager:GetLevel()[index+1]:GetNeededExperience() then
				cPlayer:SetLevel(entityManager:GetLevel()[index])
			end
		end
		
		if cPlayer:GetLevel() == nil then
			cPlayer:SetLevel(entityManager:GetLevel()[table.count(entityManager:GetLevel())])
		end
		
		if tonumber(playerData[1].job_id) ~= -1 then
			CCommunication.ShowJobSelectionScreen(player)
			--local jobId = tonumber(playerData[1].job_id)
			--cPlayer:SetJob(entityManager:GetJob()[jobId])
		else
			CCommunication.ShowJobSelectionScreen(player)
		end
		
		-- newly joined players need to have their clientside tables updated!
		for _, droppedItem in pairs(entityManager:GetDroppedItem()) do
			Network:Send(player, "AddItem",
				{
					id = droppedItem:GetItemBlueprint():GetId(),
					name = droppedItem:GetItemBlueprint():GetName(),
					amount = droppedItem:GetAmount(),
					weight = droppedItem:GetItemBlueprint():GetWeight(),
					owner = droppedItem:GetOwner(),
					position = droppedItem:GetStaticObject():GetPosition()
				}
			)
		end 
		
		for _, house in pairs(entityManager:GetHouse()) do
			CCommunication.AddHouseHotspot(
				{ 
					id = house:GetId(),
					name = house:GetName(),
					position = house:GetPosition(),
					entity = "house",
					ownerId = house:GetOwnerId()
				}
			)
		end 
		
		for _, business in pairs(entityManager:GetBusiness()) do
			CCommunication.AddBusinessHotspot(
				{ 
					id = business:GetId(),
					name = business:GetName(),
					position = business:GetPosition(),
					entity = "business",
					ownerId = business:GetOwnerId()
				}
			)
		end 
	
		entityManager:GetPlayer()[player:GetId()] = cPlayer
	end

	DefaultWorld:SetTime(12)
end

function CGame:ModuleUnload()
	for _, cVehicle in pairs(entityManager:GetVehicle()) do
		cVehicle:Remove()
		entityManager:GetVehicle()[cVehicle:GetVehicle():GetId()] = nil
	end 
	
	for _, cDroppedItem in pairs(entityManager:GetDroppedItem()) do
		cDroppedItem:GetStaticObject():Remove()
	end 
	
	for player in Server:GetPlayers() do
		entityManager:GetPlayer()[player:GetId()]:Save()
		entityManager:GetPlayer()[player:GetId()] = nil
	end
end

function CGame:PlayerJoin(args) -- also checkout entityManager:LoadAllPlayers!
	local player = args.player
	local successful = database:AttemptPlayer(player)
	local cPlayer = CPlayer(player)	
	local playerData = database:GetPlayerData(player:GetSteamId().id)

	local inventory = entityManager:GetInventory()[tonumber(playerData[1].inventory_id)]
	cPlayer:SetInventory(inventory)
	cPlayer:SetExperience(tonumber(playerData[1].experience)) -- all results are strings
	
	if successful then
		player:SendChatMessage("[pInventory] Inventory loaded.", Color(128, 0, 128))
	else
		player:SendChatMessage("[pInventory] Inventory created. Press 'F6' for your inventory.", Color(128, 0, 128))
	end
	
	for index = 1, table.count(entityManager:GetLevel()) - 1, 1 do
		if cPlayer:GetExperience() >= entityManager:GetLevel()[index]:GetNeededExperience() and cPlayer:GetExperience() <= entityManager:GetLevel()[index+1]:GetNeededExperience() then
			cPlayer:SetLevel(entityManager:GetLevel()[index])
		end
	end
	
	if cPlayer:GetLevel() == nil then
		cPlayer:SetLevel(entityManager:GetLevel()[table.count(entityManager:GetLevel())])
	end
	
	CCommunication.SendEventMessage(player, "Current level: " .. cPlayer:GetLevel():GetLevel()) -- lol...
	CCommunication.SendEventMessage(player, "Experience needed for next level: " .. cPlayer:GetNextLevel():GetNeededExperience())
	
	if tonumber(playerData[1].job_id) ~= -1 then
		local jobId = tonumber(playerData[1].job_id)
		cPlayer:SetJob(entityManager:GetJob()[jobId])
		CCommunication.SendEventMessage(player, "You are currently employed as: " .. entityManager:GetJob()[jobId]:GetName())
	else
		CCommunication.SendEventMessage(player, "You are not employed, please select a job.")
		CCommunication.ShowJobSelectionScreen(player)
	end
	
	-- newly joined players need to have their clientside tables updated!
	for _, droppedItem in pairs(entityManager:GetDroppedItem()) do
		Network:Send(player, "AddItem",
			{
				id = droppedItem:GetItemBlueprint():GetId(),
				name = droppedItem:GetItemBlueprint():GetName(),
				amount = droppedItem:GetAmount(),
				weight = droppedItem:GetItemBlueprint():GetWeight(),
				owner = droppedItem:GetOwner(),
				position = droppedItem:GetStaticObject():GetPosition()
			}
		)
	end 
	
	for _, house in pairs(entityManager:GetHouse()) do
		CCommunication.AddHouseHotspot(
			{ 
				id = house:GetId(),
				name = house:GetName(),
				position = house:GetPosition(),
				entity = "house",
				ownerId = house:GetOwnerId()
			}
		)
	end 
	
	for _, business in pairs(entityManager:GetBusiness()) do
		CCommunication.AddBusinessHotspot(
			{ 
				id = business:GetId(),
				name = business:GetName(),
				position = business:GetPosition(),
				entity = "business",
				ownerId = business:GetOwnerId()
			}
		)
	end 
	
	entityManager:GetPlayer()[player:GetId()] = cPlayer
end

function CGame:PlayerSpawn(args)
	local player = args.player

	player:SetPosition(Vector3(-9200.4580078125, 229.40693664551, 9649.1884765625))
	return false
end

function CGame:PlayerQuit(args)
	local player = args.player
	local cPlayer = entityManager:GetPlayer()[player:GetId()]
	
	if entityManager:GetOfflinePlayer()[player:GetId()] ~= nil then
		local cOfflinePlayer = entityManager:GetOfflinePlayer()[player:GetId()]
		cOfflinePlayer:SetExperience(cPlayer:GetExperience())
		cOfflinePlayer:SetName(cPlayer:GetPlayer():GetName())
		cOfflinePlayer:SetJob(cPlayer:GetJob())
		cOfflinePlayer:SetInventory(cPlayer:GetInventory())
	else
		entityManager:GetOfflinePlayer()[player:GetId()] = COfflinePlayer(player:GetName())
		
		local cOfflinePlayer = entityManager:GetOfflinePlayer()[player:GetId()]
		cOfflinePlayer:SetExperience(cPlayer:GetExperience())
		cOfflinePlayer:SetName(cPlayer:GetPlayer():GetName())
		cOfflinePlayer:SetJob(cPlayer:GetJob())
		cOfflinePlayer:SetInventory(cPlayer:GetInventory())
	end
	
	entityManager:GetPlayer()[player:GetId()]:Save()
	entityManager:GetPlayer()[player:GetId()] = nil
end

function CGame:EnterVehicle(args)
	local player = args.player
	local vehicle = args.vehicle
	local isDriver = args.is_driver
	local oldDriver = args.old_driver
	
	local cVehicle = entityManager:GetVehicle()[vehicle:GetId()]
	if cVehicle ~= nil then
		print("vehicleowner: " .. cVehicle:GetOwnerId())
	end
end

cGame = CGame()
