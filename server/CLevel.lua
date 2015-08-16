class 'CLevel'

function CLevel:__init(level)
    self.level = level
	self.neededExp = -1
end

function CLevel:GetLevel()
	return self.level
end

function CLevel:SetNeededExperience(experience)
	self.neededExp = experience
end

function CLevel:GetNeededExperience()
	return self.neededExp
end

