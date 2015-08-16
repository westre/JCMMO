class 'CDelivery'

function CDelivery:__init(id, name)
	self.id = id
	self.name = name
	self.points = nil
end

function CDelivery:GetId()
	return self.id
end

function CDelivery:GetName()
	return self.name
end

function CDelivery:GetTotalDistance()
	local totalDistance = 0
	
	for pointId, pointData in pairs(self.points) do
		local distance = 0
		if self.points[pointId - 1] ~= nil then
			distance = Vector3.Distance(self.points[pointId - 1].vector, pointData.vector)
			distance = distance / 1000 -- convert to KM
			distance = string.format("%.2f", distance) -- to 2 decimals
			totalDistance = totalDistance + distance
		else
			distance = string.format("%.2f", 0)
		end
	end
	
	return totalDistance
end	

function CDelivery:GetTotalPay()
	local totalDistance = 0
	
	for pointId, pointData in pairs(self.points) do
		local distance = 0
		if self.points[pointId - 1] ~= nil then
			distance = Vector3.Distance(self.points[pointId - 1].vector, pointData.vector)
			distance = distance / 1000 -- convert to KM
			distance = string.format("%.2f", distance) -- to 2 decimals
			totalDistance = totalDistance + distance
		else
			distance = string.format("%.2f", 0)
		end
	end

	local pay = totalDistance * 10 * #self.points
	return pay
end

function CDelivery:SetPoints(points)
	self.points = points
end

function CDelivery:GetPoints()
	return self.points
end
