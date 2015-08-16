class 'CVehicle'

function CVehicle:__init(vehicle, inventory, ownerId)
	self.vehicle = vehicle
	self.inventory = inventory
	self.ownerId = ownerId
end

function CVehicle:GetVector()
	return self.vehicle:GetPosition()
end

function CVehicle:GetAngle()
	return self.vehicle:GetAngle()
end

function CVehicle:GetVehicleId()
	return self.vehicle:GetId()
end

function CVehicle:GetVehicle()
	return self.vehicle
end

function CVehicle:Remove()
	if self.vehicle ~= nil then
		self.vehicle:Remove()
	end
end

function CVehicle:GetInventory()
	return self.inventory
end

function CVehicle:GetOwnerId()
	return self.ownerId
end


