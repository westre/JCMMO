class 'CPlayer'

function CPlayer:__init(player)
    self.player = player
	self.inventory = nil
	self.experience = nil
	self.level = nil
	self.job = nil
	
	-- job specifics
	self.jobDelivery = nil
	
	Chat:Broadcast("New player created: " .. self.player:GetName(), Color(255, 255, 255))
end

function CPlayer:SetInventory(inventory)
	self.inventory = inventory
end

function CPlayer:SetJob(args)
	self.job = args
end

function CPlayer:GetJob()
	return self.job
end

function CPlayer:SetDeliveryJob(args)
	self.jobDelivery = args
end

function CPlayer:GetDeliveryJob()
	return self.jobDelivery
end

function CPlayer:GetInventory()
	return self.inventory
end

function CPlayer:GetPlayer()
	return self.player
end

function CPlayer:SetExperience(xp)
	self.experience = xp
end

function CPlayer:GetExperience()
	return self.experience
end

function CPlayer:GetNextLevel()
	if entityManager:GetLevel()[self:GetLevel():GetLevel() + 1] ~= nil then
		return entityManager:GetLevel()[self:GetLevel():GetLevel() + 1]
	else
		local tempLevel = CLevel(-1)
		tempLevel:SetNeededExperience(99999999)
		return tempLevel
	end
	
end

function CPlayer:UpdateProgressBar()
	local curExp = self:GetExperience()
	local nextExp = self:GetNextLevel():GetNeededExperience()
	
	local percentage = curExp / nextExp * 100
	
	print("has: " .. curExp .. ", needed: " .. nextExp .. "perc: " .. percentage)
	local text = "Level " .. self:GetLevel():GetLevel() .. " [" .. curExp .. "/" .. nextExp .. "] (" .. percentage .. "%)"
	
	CCommunication.SendProgressBarUpdate(self.player, { value = percentage, stringText = text })
end

function CPlayer:SetLevel(level)
	self.level = level
end

function CPlayer:GetLevel()
	return self.level
end

function CPlayer:Save()
	print("invId: " .. self.inventory:GetId())
	print("jobid: " ..self.job:GetId())
	print("invId: -1")
	print("xp: " ..self.experience)
	print("name: " ..self.player:GetName())
	print("sid: " ..self.player:GetSteamId().id)
	
	local command = SQL:Command("UPDATE player SET inventory_id = ?, job_id = ?, faction_id = ?, experience = ?, name = ? WHERE id = ?")
	command:Bind(1, self.inventory:GetId())
	command:Bind(2, self.job:GetId())
	command:Bind(3, -1)
	command:Bind(4, self.experience)
	command:Bind(5, self.player:GetName())
	command:Bind(6, self.player:GetSteamId().id)
	command:Execute()
	
	print("saved playar")
end