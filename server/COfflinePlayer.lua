class 'COfflinePlayer'

function COfflinePlayer:__init(steamId)
	self.steamId = steamId
	self.name = nil
	self.inventory = nil
	self.experience = nil
	self.level = nil
	self.job = nil
end

function COfflinePlayer:GetSteamId()
	return self.steamId
end

function COfflinePlayer:SetInventory(inventory)
	self.inventory = inventory
end

function COfflinePlayer:SetJob(args)
	self.job = args
end

function COfflinePlayer:GetJob()
	return self.job
end

function COfflinePlayer:SetName(args)
	self.name = args
end

function COfflinePlayer:GetName()
	return self.name
end

function COfflinePlayer:GetInventory()
	return self.inventory
end

function COfflinePlayer:SetExperience(xp)
	self.experience = xp
end

function COfflinePlayer:GetExperience()
	return self.experience
end

function COfflinePlayer:GetNextLevel()
	if entityManager:GetLevel()[self:GetLevel():GetLevel() + 1] ~= nil then
		return entityManager:GetLevel()[self:GetLevel():GetLevel() + 1]
	else
		local tempLevel = CLevel(-1)
		tempLevel:SetNeededExperience(99999999)
		return tempLevel
	end
	
end

function COfflinePlayer:SetLevel(level)
	self.level = level
end

function COfflinePlayer:GetLevel()
	return self.level
end