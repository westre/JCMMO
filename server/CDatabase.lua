class 'CDatabase'

function CDatabase:__init()
	--[[SQL:Execute("DROP TABLE IF EXISTS player;")
	SQL:Execute("DROP TABLE IF EXISTS inventory;")
	SQL:Execute("DROP TABLE IF EXISTS inventory_item;")
	SQL:Execute("DROP TABLE IF EXISTS item;")
	SQL:Execute("DROP TABLE IF EXISTS item_assembly;")
	SQL:Execute("DROP TABLE IF EXISTS dropped_inventory_item;")
	SQL:Execute("DROP TABLE IF EXISTS faction;")
	SQL:Execute("DROP TABLE IF EXISTS house;")
	SQL:Execute("DROP TABLE IF EXISTS business;")
	SQL:Execute("DROP TABLE IF EXISTS vehicle;")]]--
	
    SQL:Execute("CREATE TABLE IF NOT EXISTS player (id INTEGER PRIMARY KEY, name TEXT, inventory_id INTEGER, job_id INTEGER DEFAULT -1, faction_id INTEGER DEFAULT -1, experience INTEGER DEFAULT 350);") -- player can only have 1 inventory
	
	SQL:Execute("CREATE TABLE IF NOT EXISTS inventory (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, max_weight INTEGER);") -- inventories are defined in here
	SQL:Execute("CREATE TABLE IF NOT EXISTS inventory_item (inventory_id INTEGER, item_id INTEGER, amount INTEGER, price INTEGER DEFAULT 0, second_price INTEGER DEFAULT 0, PRIMARY KEY (inventory_id, item_id));") -- items linked to inventory
	SQL:Execute("CREATE TABLE IF NOT EXISTS item (id INTEGER PRIMARY KEY, name TEXT, description TEXT, weight INTEGER, item_assembly_id INTEGER);") -- item definition, links to item assembly table
	SQL:Execute("CREATE TABLE IF NOT EXISTS item_assembly (id INTEGER, key TEXT, value INTEGER, PRIMARY KEY (id, key));") -- assembly of the item
	
	SQL:Execute("CREATE TABLE IF NOT EXISTS dropped_inventory_item (id INTEGER PRIMARY KEY AUTOINCREMENT, inventory_item_id INTEGER, owner_player_id INTEGER, pos_x REAL, pos_y REAL, pos_z REAL, amount INTEGER);")
	
	SQL:Execute("CREATE TABLE IF NOT EXISTS faction (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, description TEXT, leader_player_id INTEGER, public INTEGER DEFAULT 0);")
	
	SQL:Execute("CREATE TABLE IF NOT EXISTS house (id INTEGER PRIMARY KEY AUTOINCREMENT, inventory_id INTEGER, name TEXT, pos_x REAL, pos_y REAL, pos_z REAL, owner_player_id INTEGER, public INTEGER DEFAULT 0);")
	
	SQL:Execute("CREATE TABLE IF NOT EXISTS business (id INTEGER PRIMARY KEY AUTOINCREMENT, inventory_id INTEGER, name TEXT, pos_x REAL, pos_y REAL, pos_z REAL, owner_player_id INTEGER, public INTEGER DEFAULT 0);")
	
	SQL:Execute("CREATE TABLE IF NOT EXISTS vehicle (id INTEGER PRIMARY KEY, inventory_id INTEGER, pos_x REAL, pos_y REAL, pos_z REAL, rot_x REAL, rot_y REAL, rot_z REAL, modelid REAL, owner_player_id INTEGER, public INTEGER DEFAULT 0);")
	
	local command = SQL:Command("INSERT OR REPLACE INTO item_assembly (id, key, value) VALUES (?, ?, ?);")
	command:Bind(1, 1)
	command:Bind(2, "add_health")
	command:Bind(3, 50)
	command:Execute()
	
	command = SQL:Command("INSERT OR REPLACE INTO item_assembly (id, key, value) VALUES (?, ?, ?);")
	command:Bind(1, 1)
	command:Bind(2, "add_money")
	command:Bind(3, 500)
	command:Execute()
	
	command = SQL:Command("INSERT OR REPLACE INTO item_assembly (id, key, value) VALUES (?, ?, ?);")
	command:Bind(1, 2)
	command:Bind(2, "add_vehicle_fuel")
	command:Bind(3, 2)
	command:Execute()
	
	command = SQL:Command("INSERT OR REPLACE INTO item (id, name, description, weight, item_assembly_id) VALUES (?, ?, ?, ?, ?);")
	command:Bind(1, 1)
	command:Bind(2, "Candy bar")
	command:Bind(3, "Candy bar for your stomach! VERY WERY NAUFTI")
	command:Bind(4, 2)
	command:Bind(5, 1) -- FK to item_assembly
	command:Execute()
	
	command = SQL:Command("INSERT OR REPLACE INTO item (id, name, description, weight, item_assembly_id) VALUES (?, ?, ?, ?, ?);")
	command:Bind(1, 2)
	command:Bind(2, "Pluto bar")
	command:Bind(3, "Also a candy bar, look same permissions!")
	command:Bind(4, 2)
	command:Bind(5, 1) -- FK to item_assembly
	command:Execute()
	
	command = SQL:Command("INSERT OR REPLACE INTO item (id, name, description, weight, item_assembly_id) VALUES (?, ?, ?, ?, ?);")
	command:Bind(1, 3)
	command:Bind(2, "Gallon of Petrol")
	command:Bind(3, "Do not drink, only your vehicle of choice should drink this")
	command:Bind(4, 10)
	command:Bind(5, 2) -- FK to item_assembly
	command:Execute()
	
	command = SQL:Command("CREATE INDEX IF NOT EXISTS inventorySpeedUpIndex ON inventory_item (inventory_id)")
	command:Execute()
end

function CDatabase:AttemptPlayer(player)
	local query = SQL:Query("SELECT * FROM player WHERE id = ?")
    query:Bind(1, player:GetSteamId().id)
    local result = query:Execute()

	if #result > 0 then
		return true
	else
		-- whenever a player registers, also make 1 inventory for him
		local command = SQL:Command("INSERT INTO inventory (name, max_weight) VALUES (?, ?)")
		command:Bind(1, player:GetName() .. "'s inventory")
		command:Bind(2, 50)
		command:Execute()
	
		local countQuery = SQL:Query("SELECT * FROM inventory")
		local countResult = countQuery:Execute()
		
		local cInventory = CInventory(#countResult, player:GetName() .. "'s inventory", 50)
		
		command = SQL:Command("INSERT INTO player (id, name, inventory_id) VALUES (?, ?, ?)")
		command:Bind(1, player:GetSteamId().id)
		command:Bind(2, player:GetName())
		command:Bind(3, #countResult)
		command:Execute()
		
		entityManager:GetInventory()[cInventory:GetId()] = cInventory -- add to inventory pool!
		--print("POOL:: ID: " .. cInventory:GetId())
		--entityManager:OutputInventoryTrees()
		return false
	end
		
    --[[if #result > 0 then
        player:SetMoney( tonumber(result[1].money) )
    end]]--
end

function CDatabase:GetPlayerData(id)
	local query = SQL:Query("SELECT * FROM player WHERE id = ?")
    query:Bind(1, id)
    local result = query:Execute()

	if #result > 0 then
		return result;
	end
end


function CDatabase:CreateNewInventory(name, maxWeight)
	local command = SQL:Command("INSERT INTO inventory (name, max_weight) VALUES (?, ?)")
	command:Bind(1, name)
	command:Bind(2, maxWeight)
	command:Execute()
end

function CDatabase:CreateNewVehicle(vehicleId, modelId, playerId, posVector, rotVector, inventoryName, inventoryWeight)
	local command = SQL:Command("INSERT INTO inventory (name, max_weight) VALUES (?, ?)")
	command:Bind(1, inventoryName)
	command:Bind(2, inventoryWeight)
	command:Execute()
	
	local invCountQuery = SQL:Query("SELECT * FROM inventory")
	local invCountResult = invCountQuery:Execute()
	
	local cInventory = CInventory(#invCountResult, inventoryName, inventoryWeight)
	entityManager:GetInventory()[cInventory:GetId()] = cInventory -- add to inventory pool!
	
	command = SQL:Command("INSERT INTO vehicle (id, inventory_id, pos_x, pos_y, pos_z, rot_x, rot_y, rot_z, modelid, owner_player_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)")
	command:Bind(1, vehicleId)
	command:Bind(2, #invCountResult)
	command:Bind(3, posVector.x)
	command:Bind(4, posVector.y)
	command:Bind(5, posVector.z)
	command:Bind(6, rotVector.x)
	command:Bind(7, rotVector.y)
	command:Bind(8, rotVector.z)
	command:Bind(9, modelId)
	command:Bind(10, playerId)
	command:Execute()
	
	local countQuery = SQL:Query("SELECT * FROM vehicle")
	local countResult = countQuery:Execute()
	
	return #countResult, cInventory
end

function CDatabase:CreateNewHouse(name, posVector, playerId, inventoryName, inventoryWeight)
	local command = SQL:Command("INSERT INTO inventory (name, max_weight) VALUES (?, ?)")
	command:Bind(1, inventoryName)
	command:Bind(2, inventoryWeight)
	command:Execute()
	
	local invCountQuery = SQL:Query("SELECT * FROM inventory")
	local invCountResult = invCountQuery:Execute()
	
	local cInventory = CInventory(#invCountResult, inventoryName, inventoryWeight)
	entityManager:GetInventory()[cInventory:GetId()] = cInventory -- add to inventory pool!
	
	command = SQL:Command("INSERT INTO house (inventory_id, name, pos_x, pos_y, pos_z, owner_player_id) VALUES (?, ?, ?, ?, ?, ?)")
	command:Bind(1, #invCountResult)
	command:Bind(2, name)
	command:Bind(3, posVector.x)
	command:Bind(4, posVector.y)
	command:Bind(5, posVector.z)
	command:Bind(6, playerId)
	command:Execute()
	
	local countQuery = SQL:Query("SELECT * FROM house")
	local countResult = countQuery:Execute()
	
	return #countResult, cInventory
end

function CDatabase:CreateNewBusiness(name, posVector, playerId, inventoryName, inventoryWeight)
	-- whenever a business registers, also make 1 inventory for him
	local command = SQL:Command("INSERT INTO inventory (name, max_weight) VALUES (?, ?)")
	command:Bind(1, inventoryName)
	command:Bind(2, inventoryWeight)
	command:Execute()
	
	local invCountQuery = SQL:Query("SELECT * FROM inventory")
	local invCountResult = invCountQuery:Execute()
	
	local cInventory = CInventory(#invCountResult, inventoryName, inventoryWeight)
	entityManager:GetInventory()[cInventory:GetId()] = cInventory -- add to inventory pool!
	
	command = SQL:Command("INSERT INTO business (inventory_id, name, pos_x, pos_y, pos_z, owner_player_id) VALUES (?, ?, ?, ?, ?, ?)")
	command:Bind(1, #invCountResult)
	command:Bind(2, name)
	command:Bind(3, posVector.x)
	command:Bind(4, posVector.y)
	command:Bind(5, posVector.z)
	command:Bind(6, playerId)
	command:Execute()
	
	local countQuery = SQL:Query("SELECT * FROM business")
	local countResult = countQuery:Execute()
	
	return #countResult, cInventory
end

function CDatabase:GetInventoryData(id)
	local query = SQL:Query("SELECT * FROM inventory WHERE id = ?")
    query:Bind(1, id)
    local result = query:Execute()

	if #result > 0 then
		return result;
	end
end

function CDatabase:Output()
	local query = SQL:Query("SELECT * FROM player")
	local result = query:Execute()
	print("player count: " .. #result)
	if #result > 0 then
		for i = 1, #result do
			print("- " .. result[i].id .. " | " .. result[i].inventory_id)
		end
	end
	
	query = SQL:Query("SELECT * FROM inventory")
	result = query:Execute()
	print("inventory count: " .. #result)
	if #result > 0 then
		for i = 1, #result do
			print("- " .. result[i].id .. " | " .. result[i].name .. " | " .. result[i].max_weight)
		end
	end
	
	query = SQL:Query("SELECT * FROM inventory_item")
	result = query:Execute()
	print("inventory_item count: " .. #result)
	if #result > 0 then
		for i = 1, #result do
			print("- " .. result[i].inventory_id .. " | " .. result[i].item_id .. " | " .. result[i].amount)
		end
	end
	
	query = SQL:Query("SELECT * FROM item")
	result = query:Execute()
	print("item count: " .. #result)
	if #result > 0 then
		for i = 1, #result do
			print("- " .. result[i].id .. " | " .. result[i].name .. " | " .. result[i].description .. " | " .. result[i].weight .. " | " .. result[i].item_assembly_id)
		end
	end
	
	query = SQL:Query("SELECT * FROM item_assembly")
	result = query:Execute()
	print("item_assembly count: " .. #result)
	if #result > 0 then
		for i = 1, #result do
			print("- " .. result[i].id .. " | " .. result[i].key .. " | " .. result[i].value)
		end
	end
end

