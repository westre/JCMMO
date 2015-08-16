class 'CAuctionHouse'

function CAuctionHouse:__init()
    self.items = {} -- key = itemId, value = CItem
end

function CAuctionHouse:GetLevel()
	return self.level
end

function CAuctionHouse:SetNeededExperience(experience)
	self.neededExp = experience
end

function CAuctionHouse:GetNeededExperience()
	return self.neededExp
end

