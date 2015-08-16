class 'CJob'

function CJob:__init(id, jobName, jobDescription, jobFeatures)
	self.id = id
    self.jobName = jobName
	self.jobDescription = jobDescription
	self.jobFeatures = jobFeatures
	self.members = {}
	self.spawnPoint = nil
end

function CJob:GetId()
	return self.id
end

function CJob:GetName()
	return self.jobName
end

function CJob:GetDescription()
	return self.jobDescription
end

function CJob:GetFeatures()
	return self.jobFeatures
end

function CJob:GetMembers()
	return self.members
end

function CJob:GetMemberCount()
	local count = 0
	for key, value in pairs(self.members) do
		count = count + 1
	end
	return count
end

function CJob:AddMember(cPlayer)
	self.members[cPlayer:GetPlayer():GetId()] = cPlayer

	Chat:Broadcast(cPlayer:GetPlayer():GetName() .. " has been added to team " .. self.jobName .. " team count: " .. self:GetMemberCount(), Color(255, 255, 255))
end

function CJob:ClearMembers()
	for key, cPlayer in pairs(self.members) do
		self.members[key] = nil
	end
end

function CJob:DelMember(cPlayer)
	self.members[cPlayer:GetPlayer():GetId()] = nil

	Chat:Broadcast(cPlayer:GetPlayer():GetName() .. " has been removed from team " .. self.jobName .. " team count: " .. self:GetMemberCount(), Color(255, 255, 255))
end

function CJob:SetSpawn(spawnPoint)
	self.spawnPoint = spawnPoint
end

function CJob:GetSpawn()
	return self.spawnPoint
end
