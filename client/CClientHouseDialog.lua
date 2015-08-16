class 'CClientHouseDialog'

function CClientHouseDialog:__init()
	self.active = false
	
	self.curItemIdSelected = nil
	self.curHotspotId = nil
	
	self.window = Window.Create()
	self.window:SetSizeRel(Vector2(0.75, 0.75))
	self.window:SetPositionRel(Vector2(0.5, 0.5) - self.window:GetSizeRel() / 2)
	self.window:SetTitle("House Inventory")
	self.window:SetVisible(self.active)
	self.window:Subscribe("WindowClosed", self, self.WindowClosed)
	self.window:DisableResizing()

	-- INVENTORY --
	local inventoryPageScrollControl = ScrollControl.Create(self.window)
	inventoryPageScrollControl:SetDock(GwenPosition.Fill)
	inventoryPageScrollControl:SetMargin(Vector2(4, 4), Vector2(4, 4))
	
	self.headerLabel = Label.Create(inventoryPageScrollControl)
	self.headerLabel:SetDock(GwenPosition.Top)
	self.headerLabel:SetMargin(Vector2(4, 4), Vector2(4, 4))
	self.headerLabel:SetText("undefined")
	
	self.inventoryPageList = SortedList.Create(inventoryPageScrollControl)
	self.inventoryPageList:SetDock(GwenPosition.Fill)
	self.inventoryPageList:SetMargin(Vector2(4, 4), Vector2(4, 4))
	self.inventoryPageList:AddColumn("ID", 64)
	self.inventoryPageList:AddColumn("Name")
	self.inventoryPageList:AddColumn("Amount", 64)
	self.inventoryPageList:AddColumn("Weight", 64)
	self.inventoryPageList:Subscribe("RowSelected", self, self.RowSelected)
	self.inventoryPageList:SetButtonsVisible(true)

	local inventoryItemInfo = Window.Create(inventoryPageScrollControl)
	inventoryItemInfo:SetClosable(false)
	inventoryItemInfo:SetTitle("Item Information")
	inventoryItemInfo:SetDock(GwenPosition.Right)
	inventoryItemInfo:DisableResizing()
	inventoryItemInfo:SetSize(Vector2(250, 0))	
	inventoryItemInfo:SetMargin(Vector2(4, 4), Vector2(20, 50))
	
	self.inventoryItemLabel = Label.Create(inventoryItemInfo)
	self.inventoryItemLabel:SetDock(GwenPosition.Fill)
	self.inventoryItemLabel:SetMargin(Vector2(4, 4), Vector2(4, 4))
	self.inventoryItemLabel:SetText("")
	self.inventoryItemLabel:SetWrap(true)
	
	self.sendAmount = TextBoxNumeric.Create(inventoryItemInfo)
	self.sendAmount:SetPosition(Vector2(0, 380))
	self.sendAmount:SetSize(Vector2(50, 25))
	
	self.sendToButton = Button.Create(inventoryItemInfo)
	self.sendToButton:SetText("Send to inventory")
	self.sendToButton:SetPosition(Vector2(50, 380))
	self.sendToButton:SetSize(Vector2(200, 25))
	self.sendToButton:Subscribe("Press", self, self.SendToButton)
	self.sendToButton:SetEnabled(false)
	-- END OF INVENTORY --
	
	Events:Subscribe("LocalPlayerInput", self, self.LocalPlayerInput) -- disable player input
	Events:Subscribe("CharPress", self, self.CharPress)
	
	Network:Subscribe("UpdateHouseInventoryScreen", self, self.UpdateHouseInventoryScreen) 
end

function CClientHouseDialog:SendToButton()
	Network:Send("SendItemToPlayer", { fromEntityId = self.curHotspotId, toPlayerId = LocalPlayer:GetId(), amount = self.sendAmount:GetValue(), itemId = self.curItemIdSelected, state = "house" })
	
	self.inventoryPageList:Clear()
	self.sendToButton:SetEnabled(false)
	Network:Send("AskServerForInventory", { LocalPlayer:GetId(), "house", self.curHotspotId })
end

function CClientHouseDialog:WindowClosed(args)
    self.inventoryPageList:Clear()
	self.inventoryItemLabel:SetText("")
	self:SetActive(false)
	
	self.sendToButton:SetEnabled(false)
end

function CClientHouseDialog:RowSelected(args)
	self.sendToButton:SetEnabled(true)
	
	local id = self.inventoryPageList:GetSelectedRow():GetCellText(0)
	self.curItemIdSelected = id
    print("ID: " .. self.inventoryPageList:GetSelectedRow():GetCellText(0))
	
	local desc = inventoryContents[id].name .. "\n\n" .. inventoryContents[id].description .. "\n\nWeight: " .. inventoryContents[id].weight .. "\n\nAbilities:\n"
	
	for key, value in pairs(inventoryContents[id].assembly) do
		desc = desc .. key .. ": " .. value .. "\n"
	end

	self.inventoryItemLabel:SetText(desc)
end

function CClientHouseDialog:CharPress(args)
	local key = args.character
	
	if key == "h" then
		for _, hotspot in ipairs(cClientHotspot:GetHouseHotspot()) do
			if hotspot.position:Distance2D(LocalPlayer:GetPosition()) <= 5 then
				if not self:GetActive() then
					self.inventoryPageList:Clear()
					self.curHotspotId = hotspot.id
					Chat:Print("near house: " .. hotspot.id,Color(255,255,255))
					Network:Send("AskServerForInventory", { LocalPlayer:GetId(), "house", hotspot.id }) -- playerId, entityType, businessId, houseId
					self:SetActive(true)
				else
					self:SetActive(false)
					self.sendToButton:SetEnabled(false)
				end
				break
			end
		end
	end
end

function CClientHouseDialog:LocalPlayerInput(args)
	if self:GetActive() and Game:GetState() == GUIState.Game then
		return false
	end
end

function CClientHouseDialog:GetActive()
	return self.active
end

function CClientHouseDialog:SetActive(state)
	self.active = state
	self.window:SetVisible(self.active)
	Mouse:SetVisible(self.active)
end

function CClientHouseDialog:UpdateHouseInventoryScreen(args)
	inventoryName = args.inventoryName
	inventoryMaxWeight = args.inventoryMaxWeight
	inventoryContents = args.inventoryContents
	
	for id, cItem in pairs(inventoryContents) do
		local item = self.inventoryPageList:AddItem(tostring(id))
		item:SetCellText(1, cItem.name)
		item:SetCellText(2, tostring(cItem.amount))
		item:SetCellText(3, tostring(cItem.totalWeight))
	end
	
	self.headerLabel:SetText("You are currently holding: " .. inventoryName .. " which has a maximum supported weight of " .. inventoryMaxWeight)
end

cClientHouseDialog = CClientHouseDialog()