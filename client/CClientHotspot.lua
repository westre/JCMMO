class 'CClientHotspot'

function CClientHotspot:__init()
	self.houseHotspots = {}
	self.houseDesignatedParent = {}
	
	self.businessHotspots = {}
	self.businessDesignatedParent = {}
	
	Network:Subscribe("AddHouseHotspot", self, self.AddHouseHotspot)
	Network:Subscribe("AddBusinessHotspot", self, self.AddBusinessHotspot)
	Events:Subscribe("Render", self, self.Render)
end

function CClientHotspot:GetHouseHotspot()
	return self.houseHotspots
end

function CClientHotspot:GetBusinessHotspot()
	return self.businessHotspots
end

function CClientHotspot:AddHouseHotspot(args)
	table.insert(self.houseHotspots, args)
	
	local newHotspot = args
	local foundParent = false
	
	for _, nearbyHotspot in ipairs(self.houseHotspots) do
		if newHotspot ~= nearbyHotspot and Vector3.Distance(newHotspot.position, nearbyHotspot.position) <= 50 then
			foundParent = true
			Chat:Print("Found one a parent!", Color(255, 255, 255))
			
			if self.houseDesignatedParent[nearbyHotspot.id] ~= nil and newHotspot.id ~= nearbyHotspot.id then
				self.houseDesignatedParent[nearbyHotspot.id].children[newHotspot.id] = newHotspot
				
				Chat:Print("Child ID " .. newHotspot.id .. " linked to Parent ID " .. nearbyHotspot.id, Color(255, 255, 255))
			end
		end
	end
	
	if not foundParent then
		self.houseDesignatedParent[newHotspot.id] = {}
		self.houseDesignatedParent[newHotspot.id].owner = newHotspot
		self.houseDesignatedParent[newHotspot.id].children = {}
		Chat:Print("Created new parent", Color(255, 255, 255))
	end
end

function CClientHotspot:AddBusinessHotspot(args)
	table.insert(self.businessHotspots, args)
	
	local newHotspot = args
	local foundParent = false
	
	for _, nearbyHotspot in ipairs(self.businessHotspots) do
		if newHotspot ~= nearbyHotspot and Vector3.Distance(newHotspot.position, nearbyHotspot.position) <= 50 then
			foundParent = true
			Chat:Print("Found one a parent!", Color(255, 255, 255))
			
			if self.businessDesignatedParent[nearbyHotspot.id] ~= nil and newHotspot.id ~= nearbyHotspot.id then
				self.businessDesignatedParent[nearbyHotspot.id].children[newHotspot.id] = newHotspot
				
				Chat:Print("Child ID " .. newHotspot.id .. " linked to Parent ID " .. nearbyHotspot.id, Color(255, 255, 255))
			end
		end
	end
	
	if not foundParent then
		self.businessDesignatedParent[newHotspot.id] = {}
		self.businessDesignatedParent[newHotspot.id].owner = newHotspot
		self.businessDesignatedParent[newHotspot.id].children = {}
		Chat:Print("Created new parent", Color(255, 255, 255))
	end
end


function CClientHotspot:Render()
	if Game:GetState() ~= GUIState.Game then return end
	if LocalPlayer:GetWorld() ~= DefaultWorld then return end

	for parentId, hierarchyTable in pairs(self.houseDesignatedParent) do	
		local distanceBetweenMeAndHotspotParent = hierarchyTable.owner.position:Distance2D(Camera:GetPosition())
		
		local length = table.count(hierarchyTable.children) + 1
			
		local totalX = hierarchyTable.owner.position.x
		local totalY = hierarchyTable.owner.position.y
		local totalZ = hierarchyTable.owner.position.z
		
		for _, child in pairs(hierarchyTable.children) do 
			totalX = totalX + child.position.x
			totalY = totalY + child.position.y
			totalZ = totalZ + child.position.z
		end

		local midX = totalX / length
		local midY = totalY / length
		local midZ = totalZ / length

		local midpointVector = Vector3(midX, midY, midZ)
		midpointVector = midpointVector + Vector3(0, 5, 0)  -- put the midpoint in higher altitude
		local midVector2, midVector2Success = Render:WorldToScreen(midpointVector)
		--midVector2 = midVector2 + Vector2(0, -100) -- put the midpoint in higher altitude
		
		if distanceBetweenMeAndHotspotParent >= 200 then
			--Chat:Print("X: " .. midpointVector.x .. ", Y: ".. midpointVector.y .. ", Z: " .. midpointVector.z .. ", len: " .. length, Color(255, 255, 255))
			if midVector2Success then
				local alpha = 1 - (distanceBetweenMeAndHotspotParent - 1024) / 1024 * 255 -- 2048 can be higher, so more distance for text to show up
				
				if alpha >= 1 then
					Render:DrawText(midVector2, length .. " house hotspots", Color(255, 255, 255, alpha), 16, 1.0)
				end
			end
		else
			local vec2, success = Render:WorldToScreen(hierarchyTable.owner.position)
			if success then
				Render:DrawText(vec2, hierarchyTable.owner.name .. " (parent)", Color(255, 255, 255, 255), 12, 1.0) -- parent position
				
				Render:DrawText(midVector2, length .. " house hotspots (vector midpoint)", Color(255, 255, 255, 255), 12, 1.0) -- mid point of parent's vector + all children's vector
				Render:DrawLine(vec2, midVector2, Color(0, 0, 255)) -- draw a line from parent to mid vector
			end	
			
			for _, child in pairs(hierarchyTable.children) do	
				local childVec2, childSuccess = Render:WorldToScreen(child.position)
				Render:DrawLine(midVector2, childVec2, Color(0, 255, 0)) -- draw then a line from mid point to all children

				if childSuccess then
					Render:DrawText(childVec2, child.name .. " (child)", Color(255, 255, 255, 255), 12, 1.0)
				end	
			end	
		end		
	end
	
	for parentId, hierarchyTable in pairs(self.businessDesignatedParent) do	
		local distanceBetweenMeAndHotspotParent = hierarchyTable.owner.position:Distance2D(Camera:GetPosition())
		
		local length = table.count(hierarchyTable.children) + 1
			
		local totalX = hierarchyTable.owner.position.x
		local totalY = hierarchyTable.owner.position.y
		local totalZ = hierarchyTable.owner.position.z
		
		for _, child in pairs(hierarchyTable.children) do 
			totalX = totalX + child.position.x
			totalY = totalY + child.position.y
			totalZ = totalZ + child.position.z
		end

		local midX = totalX / length
		local midY = totalY / length
		local midZ = totalZ / length

		local midpointVector = Vector3(midX, midY, midZ)
		midpointVector = midpointVector + Vector3(0, 5, 0)  -- put the midpoint in higher altitude
		local midVector2, midVector2Success = Render:WorldToScreen(midpointVector)
		--midVector2 = midVector2 + Vector2(0, -100) -- put the midpoint in higher altitude
		
		if distanceBetweenMeAndHotspotParent >= 200 then
			--Chat:Print("X: " .. midpointVector.x .. ", Y: ".. midpointVector.y .. ", Z: " .. midpointVector.z .. ", len: " .. length, Color(255, 255, 255))
			if midVector2Success then
				local alpha = 1 - (distanceBetweenMeAndHotspotParent - 1024) / 1024 * 255 -- 2048 can be higher, so more distance for text to show up
				
				if alpha >= 1 then
					Render:DrawText(midVector2, length .. " business hotspots", Color(255, 255, 255, alpha), 16, 1.0)
				end
			end
		else
			local vec2, success = Render:WorldToScreen(hierarchyTable.owner.position)
			if success then
				Render:DrawText(vec2, hierarchyTable.owner.name .. " (parent)", Color(255, 255, 255, 255), 12, 1.0) -- parent position
				
				Render:DrawText(midVector2, length .. " business hotspots (vector midpoint)", Color(255, 255, 255, 255), 12, 1.0) -- mid point of parent's vector + all children's vector
				Render:DrawLine(vec2, midVector2, Color(0, 0, 255)) -- draw a line from parent to mid vector
			end	
			
			for _, child in pairs(hierarchyTable.children) do	
				local childVec2, childSuccess = Render:WorldToScreen(child.position)
				Render:DrawLine(midVector2, childVec2, Color(0, 255, 0)) -- draw then a line from mid point to all children

				if childSuccess then
					Render:DrawText(childVec2, child.name .. " (child)", Color(255, 255, 255, 255), 12, 1.0)
				end	
			end	
		end		
	end
	
	--[[for _, receivedTable in ipairs(self.hotspots) do
		local distanceBetweenMeAndHotspot = receivedTable.position:Distance2D(Camera:GetPosition())
		local vec2, success = Render:WorldToScreen(receivedTable.position)

		if distanceBetweenMeAndHotspot >= 5 then
			local alpha = 1 - (distanceBetweenMeAndHotspot - 2048) / 2048 * 255 -- 2048 can be higher, so more distance for text to show up
			--Chat:Print("DIST: " .. distanceBetweenMeAndHotspot .. ", alpha: " .. alpha, Color(255, 255, 255))
			
			if success then
				Render:DrawText(vec2, receivedTable.name, Color(255, 255, 255, alpha), 12, 1.0)
			end	
		end	
	end]]--
end

cClientHotspot = CClientHotspot()