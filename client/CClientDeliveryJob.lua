class 'CClientDeliveryJob'

function CClientDeliveryJob:__init()
	self.active = false
	self.curJobId = nil
	self.overflow = false
	
	self.window = Window.Create()
	self.window:SetSizeRel(Vector2(0.75, 0.75))
	self.window:SetPositionRel(Vector2(0.5, 0.5) - self.window:GetSizeRel() / 2)
	self.window:SetTitle("Job Management")
	self.window:SetVisible(self.active)
	self.window:Subscribe("WindowClosed", self, self.WindowClosed)
	self.window:DisableResizing()

	-- INVENTORY --
	local inventoryPageScrollControl = ScrollControl.Create(self.window)
	inventoryPageScrollControl:SetDock(GwenPosition.Fill)
	--inventoryPageScrollControl:SetMargin(Vector2(4, 4), Vector2(4, 4))
	
	self.inventoryPageList = SortedList.Create(inventoryPageScrollControl)
	self.inventoryPageList:SetDock(GwenPosition.Fill)
	self.inventoryPageList:AddColumn("ID", 64)
	self.inventoryPageList:AddColumn("Route")
	self.inventoryPageList:AddColumn("Drop Points", 128)
	self.inventoryPageList:AddColumn("Total Length", 128)
	self.inventoryPageList:AddColumn("Total Pay", 128)
	self.inventoryPageList:Subscribe("RowSelected", self, self.RowSelected)
	self.inventoryPageList:SetButtonsVisible(true)
	
	self.acceptButton = Button.Create(inventoryPageScrollControl)
	self.acceptButton:SetText("Hmm... *scratches beard* yeah, I like this route and I would like to embark on a journey no man has ever attempted.")
	self.acceptButton:SetDock(GwenPosition.Bottom)
	self.acceptButton:Subscribe("Press", self, self.AcceptButton)
	self.acceptButton:SetSize(Vector2(0, 25))
	self.acceptButton:SetEnabled(false)
	-- END OF INVENTORY --
	
	
	Events:Subscribe("LocalPlayerInput", self, self.LocalPlayerInput) -- disable player input
	Events:Subscribe("CharPress", self, self.CharPress)
	
	Network:Subscribe("UpdateDeliveryJobsScreen", self, self.UpdateDeliveryJobsScreen) 
	Network:Subscribe("ProceedJobDialog", self, self.ProceedJobDialog) 
end

function CClientDeliveryJob:ProceedJobDialog(args)
	local jobString = args[1]

	if jobString == "Courier Service" then
		self.inventoryPageList:Clear()		
		Network:Send("AskServerForDeliveryJobs", { LocalPlayer:GetId() }) -- playerId, entityType, businessId, houseId
		self:SetActive(true)
		self.overflow = true
	end
end

function CClientDeliveryJob:UpdateDeliveryJobsScreen(args)
	for id, receivedTable in pairs(args) do
		local routeString = ""
		local totalDistance = 0
		
		for pointId, pointData in pairs(receivedTable.points) do
			local distance = 0
			if receivedTable.points[pointId - 1] ~= nil then
				distance = Vector3.Distance(receivedTable.points[pointId - 1].vector, pointData.vector)
				distance = distance / 1000 -- convert to KM
				distance = string.format("%.2f", distance) -- to 2 decimals
				totalDistance = totalDistance + distance
			else
				distance = string.format("%.2f", 0)
			end

			routeString = routeString .. pointData.name .. " (" .. totalDistance .. " km) (+" .. distance .. " km)\n"
		end
		
		routeString = table.count(receivedTable.points) .. " destinations (total of " .. totalDistance .. " km)\n" .. routeString
		
		local item = self.inventoryPageList:AddItem(tostring(id))
		item:SetCellText(1, receivedTable.name)
		item:SetCellText(2, tostring(#receivedTable.points))
		item:SetCellText(3, totalDistance .. " km")
		
		local pay = totalDistance * 10 * #receivedTable.points
		pay = string.format("%.0f", pay)
		
		item:SetCellText(4, "$" .. pay)
		item:SetToolTip(routeString)
	end
end

function CClientDeliveryJob:AcceptButton()
    Network:Send("ActivateDeliveryJobForPlayer", { LocalPlayer:GetId(), self.curJobId })
end

function CClientDeliveryJob:WindowClosed(args)
    self.inventoryPageList:Clear()
	self:SetActive(false)
	self.overflow = false
end

function CClientDeliveryJob:RowSelected(args)
	local id = self.inventoryPageList:GetSelectedRow():GetCellText(0)
	self.curJobId = tonumber(id)
	
	self.acceptButton:SetEnabled(true)
end

function CClientDeliveryJob:CharPress(args)
	local key = args.character
	
	if key == "j" then
		if not self:GetActive() then
			Network:Send("AskServerForMyCurrentJob", { LocalPlayer:GetId(), "Courier Service" })
			Chat:Print("hmm",Color(0,0,0))
		else
			self:SetActive(false)
			self.acceptButton:SetEnabled(false)
			self.overflow = false
			Chat:Print("ok",Color(0,0,0))
		end
	end
end

function CClientDeliveryJob:LocalPlayerInput(args)
	if self:GetActive() and Game:GetState() == GUIState.Game then
		return false
	end
end

function CClientDeliveryJob:GetActive()
	return self.active
end

function CClientDeliveryJob:SetActive(state)
	self.active = state
	self.window:SetVisible(self.active)
	Mouse:SetVisible(self.active)
end

cClientDeliveryJob = CClientDeliveryJob()