class 'CCommand'

function CCommand:__init()
    Events:Subscribe("PlayerChat", self, self.CommandMessage)
end

function CCommand:CommandMessage(args)
    local msg = args.text
	local split_msg = msg:split(" ")
    local player = args.player

    -- If the string is't a command, we're not interested!
    if msg:sub(1, 1) ~= "/" then
        return true
    end    
	
	if split_msg[1] == "/random" then
		local randomVector = locations.weaponPart[math.random(1, #locations.weaponPart)]
		player:SetPosition(randomVector)
	end
	
	if split_msg[1] == "/fueldepot" then
		local randomVector = locations.fuelDepots[math.random(1, #locations.fuelDepots)]
		player:SetPosition(randomVector)
	end
	
	if split_msg[1] == "/gasholder" then
		local randomVector = locations.gasHolders[math.random(1, #locations.gasHolders)]
		player:SetPosition(randomVector)
	end
	
	if split_msg[1] == "/petrolpump" then
		local randomVector = locations.petrolPumps[math.random(1, #locations.petrolPumps)]
		player:SetPosition(randomVector)
	end
	
	if split_msg[1] == "/give" then
		local cPlayer = entityManager:GetPlayer()[player:GetId()]
		
		local item = CItem(entityManager:GetItemBlueprint()[1], 50, -1, -1)
		cPlayer:GetInventory():AddItem(item)
	end
	
	if split_msg[1] == "/msg" then
		CCommunication.SendEventMessage(player, "Hello there!")
		
		local cPlayer = entityManager:GetPlayer()[player:GetId()]
		cPlayer:UpdateProgressBar()
	end
	
	if split_msg[1] == "/house" then
		CCommunication.SendEventMessage(player, "CREATED HAUSE")
		
		local returnedId, cInventory = database:CreateNewHouse("Test Haus", player:GetPosition(), player:GetSteamId().id, "house inv", 5000)
		print("return: " .. returnedId)
		
		entityManager:GetHouse()[returnedId] = CHouse(returnedId, "Test Haus", player:GetPosition(), 0, player:GetName(), player:GetSteamId().id, cInventory)
		CCommunication.AddHouseHotspot(
			{ 
				id = returnedId,
				name = entityManager:GetHouse()[returnedId]:GetName(),
				position = player:GetPosition(),
				entity = "house",
				ownerId = player:GetSteamId().id 
			}
		)
	end
	
	if split_msg[1] == "/business" then
		CCommunication.SendEventMessage(player, "CREATED BUSINESS")
		
		local returnedId, cInventory = database:CreateNewBusiness("Test Business", player:GetPosition(), player:GetSteamId().id, "test inv", 5000)
		print("return: " .. returnedId)
		
		entityManager:GetBusiness()[returnedId] = CBusiness(returnedId, "Test Business", player:GetPosition(), 0, player:GetName(), player:GetSteamId().id, cInventory)
		CCommunication.AddBusinessHotspot(
			{ 
				id = returnedId,
				name = entityManager:GetBusiness()[returnedId]:GetName(),
				position = player:GetPosition(),
				entity = "business",
				ownerId = player:GetSteamId().id 
			}
		)
	end
	
	if split_msg[1] == "/vehicle" then
		CCommunication.SendEventMessage(player, "CREATED vehicle")

		local vehicle = Vehicle.Create(46, player:GetPosition(), Angle(0, 0, 0))
		
		-- vehicle, playerId, posVector, rotVector, inventoryName, inventoryWeight
		local returnedId, cInventory = database:CreateNewVehicle(vehicle, player:GetSteamId().id, vehicle:GetPosition(), vehicle:GetAngle(), "veh inv", 20)
		print("return: " .. returnedId)
		
		entityManager:GetVehicle()[returnedId] = CVehicle(vehicle, cInventory, player:GetSteamId().id)
	end
	
	if split_msg[1] == "/have" then
		local cPlayer = entityManager:GetPlayer()[player:GetId()]

		local cInventory = cPlayer:GetInventory()
		print(cInventory:GetId() .. " | " .. cInventory:GetName() .. " | " .. cInventory:GetMaxWeight())
		for itemId, cItem in pairs(cInventory:GetItem()) do
			print("|_ " .. cItem:GetItemBlueprint():GetId() .. " | " .. cItem:GetItemBlueprint():GetName() .. " | " .. cItem:GetItemBlueprint():GetDescription() .. " | " .. cItem:GetAmount())
			for key, value in pairs(cItem:GetItemBlueprint():GetAbility()) do
				print("|__ " .. key .. " | " .. value)
			end
		end
	end
	
	if split_msg[1] == "/vehinv" then
		local vehicleId = player:GetVehicle():GetId()
	end
	
	if split_msg[1] == "/veh" then
		Vehicle.Create(81, player:GetPosition(), Angle(0, 0, 0))
	end
	
	if split_msg[1] == "/veh2" then
		Vehicle.Create(46, player:GetPosition(), Angle(0, 0, 0))
	end
	
	if split_msg[1] == "/obj" then
		local path = "geo.cbb.eez/go152-a.lod"
		StaticObject.Create(args.player:GetPosition(), Angle(0, 0, 0), path)
	end
	
	if split_msg[1] == "/savepos" then
		local file = io.open("positions.txt", "a")
		
		if player:InVehicle() == false then
			file:write("Vector3(" .. player:GetPosition().x .. ", " .. player:GetPosition().y .. ", " .. player:GetPosition().z .. "), Angle(" .. player:GetAngle().x .. ", " .. player:GetAngle().y .. ", " .. player:GetAngle().z .. ")\n")
			file:close()
		else
			local vehicle = player:GetVehicle()
			file:write("Vector3(" .. vehicle:GetPosition().x .. ", " .. vehicle:GetPosition().y .. ", " .. vehicle:GetPosition().z .. "), Angle(" .. vehicle:GetAngle().x .. ", " .. vehicle:GetAngle().y .. ", " .. vehicle:GetAngle().z .. ")\n")
			file:close()
		end
		
		player:SendChatMessage("Written to file", Color(255, 255, 255))
	end
	
    return false
end

cCommand = CCommand()