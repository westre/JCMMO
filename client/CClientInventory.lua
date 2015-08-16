class 'CClientInventory'

function CClientInventory:__init()
	self.active = false
	self.curItemIdSelected = nil
	
	self.window = Window.Create()
	self.window:SetSizeRel(Vector2(0.75, 0.75))
	self.window:SetPositionRel(Vector2(0.5, 0.5) - self.window:GetSizeRel() / 2)
	self.window:SetTitle("Character Inventory")
	self.window:SetVisible(self.active)
	self.window:Subscribe("WindowClosed", self, self.WindowClosed)
	self.window:DisableResizing()
	
	self.tabs = TabControl.Create(self.window)
	self.tabs:SetDock(GwenPosition.Fill)
	self.tabs:SetTabStripPosition(GwenPosition.Top)
	
	-- INVENTORY --
	local inventoryTab = self.tabs:AddPage("Inventory")
	local inventoryPage = inventoryTab:GetPage()

	local inventoryPageScrollControl = ScrollControl.Create(inventoryPage)
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
	
	self.useButton = Button.Create(inventoryItemInfo)
	self.useButton:SetText("Use")
	self.useButton:SetPosition(Vector2(0, 305))
	self.useButton:SetSize(Vector2(250, 25))
	self.useButton:Subscribe("Press", self, self.UseButton)
	self.useButton:SetEnabled(false)
	
	self.dropAmount = TextBoxNumeric.Create(inventoryItemInfo)
	self.dropAmount:SetPosition(Vector2(0, 330))
	self.dropAmount:SetSize(Vector2(50, 25))
	
	self.dropButton = Button.Create(inventoryItemInfo)
	self.dropButton:SetText("Drop")
	self.dropButton:SetPosition(Vector2(50, 330))
	self.dropButton:SetSize(Vector2(200, 25))
	self.dropButton:Subscribe("Press", self, self.DropButton)
	self.dropButton:SetEnabled(false)
	
	self.sendAmount = TextBoxNumeric.Create(inventoryItemInfo)
	self.sendAmount:SetPosition(Vector2(0, 355))
	self.sendAmount:SetSize(Vector2(50, 25))
	
	self.sendToButton = Button.Create(inventoryItemInfo)
	self.sendToButton:SetText("Send To")
	self.sendToButton:SetPosition(Vector2(50, 355))
	self.sendToButton:SetSize(Vector2(200, 25))
	self.sendToButton:Subscribe("Press", self, self.SendToButton)
	self.sendToButton:SetEnabled(false)
	-- END OF INVENTORY --
	
	self.tabs:AddPage("Help")
	
	-- SEND TO DIALOG --
	self.sendToWindowActive = false
	
	self.sendToWindow = Window.Create()
	self.sendToWindow:SetSizeRel(Vector2(0.2, 0.3))
	self.sendToWindow:SetPositionRel(Vector2(0.5, 0.5) - self.sendToWindow:GetSizeRel() / 2)
	self.sendToWindow:SetTitle("Send Item To")
	self.sendToWindow:SetVisible(self.sendToWindowActive)
	self.sendToWindow:Subscribe("WindowClosed", self, self.SendToWindowClosed)
	self.sendToWindow:DisableResizing()
	
	local sendToWindowScroll = ScrollControl.Create(self.sendToWindow)
	sendToWindowScroll:SetDock(GwenPosition.Fill)
	
	self.sendToListBox = ListBox.Create(sendToWindowScroll)
	self.sendToListBox:SetPosition(Vector2(0, 0))
	self.sendToListBox:SetSizeRel(Vector2(1, 1))
	self.sendToListBox:SetDock(GwenPosition.Fill)
	
	self.sendToListBoxButton = Button.Create(sendToWindowScroll)
	self.sendToListBoxButton:SetText("Send")
	self.sendToListBoxButton:SetSize(Vector2(0, 25))	
	self.sendToListBoxButton:SetDock(GwenPosition.Bottom)
	self.sendToListBoxButton:Subscribe("Press", self, self.SendToEntityButton)
	-- END OF SENT TO DIALOG --
	
	Events:Subscribe("KeyUp", self, self.KeyUp)
	Events:Subscribe("LocalPlayerInput", self, self.LocalPlayerInput) -- disable player input
	
	Network:Subscribe("UpdateInventoryScreen", self, self.UpdateInventoryScreen) 
end

function CClientInventory:UseButton()
	local id = self.inventoryPageList:GetSelectedRow():GetCellText(0)
	Network:Send("UseItem", { playerId = LocalPlayer:GetId(), itemId = id })
	
	-- refresh!
	self:Refresh()
end

function CClientInventory:Refresh()
	self.inventoryPageList:Clear()
	self.inventoryItemLabel:SetText("")
	Network:Send("AskServerForInventory", { LocalPlayer:GetId(), "player", -1 })
	
	self.useButton:SetEnabled(false)
	self.dropButton:SetEnabled(false)
	self.sendToButton:SetEnabled(false)
end

function CClientInventory:DropButton()
	if self.dropAmount:GetValue() < 1 then 
		cClientEventMessage:AddMessage("Invalid amount") 
		return 
	end

	local id = self.inventoryPageList:GetSelectedRow():GetCellText(0)
	Network:Send("DropItem", { playerId = LocalPlayer:GetId(), itemId = id, amount = self.dropAmount:GetValue() })
	
	-- refresh!
	self:Refresh()
end

function CClientInventory:SendToEntityButton()
	local entity = self.sendToListBox:GetSelectedRow():GetName()
	
	Network:Send("SendItemToEntity", { fromPlayerId = LocalPlayer:GetId(), toEntityId = self.sendToListBox:GetSelectedRow():GetCellText(2), amount = self.sendAmount:GetValue(), itemId = self.curItemIdSelected, state = entity })
	
	self.sendToWindowActive = false
	self.sendToWindow:SetVisible(self.sendToWindowActive)
	
	-- refresh!
	self:Refresh()
end

function CClientInventory:SendToButton()
	if self.sendAmount:GetValue() < 1 then 
		cClientEventMessage:AddMessage("Invalid amount") 
		return 
	end
	
	local hasResult = false
	self.sendToWindowActive = true
	self.sendToWindow:SetVisible(self.sendToWindowActive)
	Mouse:SetVisible(self.sendToWindowActive)
	
	self.sendToListBox:Clear()
	
	if LocalPlayer:GetVehicle() ~= nil then
		local tableRow = self.sendToListBox:AddItem("Current seated vehicle" .. " (id " .. LocalPlayer:GetVehicle():GetId() .. ")")
		tableRow:SetColumnCount(3)
		tableRow:SetCellText(2, tostring(LocalPlayer:GetVehicle():GetId()))
		tableRow:SetName("vehicle")
		hasResult = true
	end
	
	for id, hotspot in pairs(cClientHotspot:GetBusinessHotspot()) do
		if tonumber(hotspot.ownerId) == tonumber(LocalPlayer:GetSteamId().id) and hotspot.entity == "business" then
			local tableRow = self.sendToListBox:AddItem("[B] " .. hotspot.name .. " (id " .. hotspot.id .. ")")
			tableRow:SetColumnCount(3)
			tableRow:SetCellText(2, tostring(hotspot.id))
			tableRow:SetName("business")
			hasResult = true
		end
	end
	
	for id, hotspot in pairs(cClientHotspot:GetHouseHotspot()) do
		if tonumber(hotspot.ownerId) == tonumber(LocalPlayer:GetSteamId().id) and hotspot.entity == "house" then
			local tableRow = self.sendToListBox:AddItem("[H] " .. hotspot.name .. " (id " .. hotspot.id .. ")")
			tableRow:SetColumnCount(3)
			tableRow:SetCellText(2, tostring(hotspot.id))
			tableRow:SetName("house")
			hasResult = true
		end
	end
	
	if not hasResult then
		self.sendToListBoxButton:SetEnabled(false)
	end
end

function CClientInventory:GetActive()
	return self.active
end

function CClientInventory:SetActive(state)
	self.active = state
	self.window:SetVisible(self.active)
	Mouse:SetVisible(self.active)
end

function CClientInventory:KeyUp(args)
	if args.key == VirtualKey.F6 then
		if self:GetActive() == false then
			Network:Send("AskServerForInventory", { LocalPlayer:GetId(), "player", -1 })
		else
			self.inventoryPageList:Clear()
			self.inventoryItemLabel:SetText("")
			
			self.useButton:SetEnabled(false)
			self.dropButton:SetEnabled(false)
			self.sendToButton:SetEnabled(false)
		end
		self:SetActive(not self:GetActive())
	end
end

function CClientInventory:LocalPlayerInput(args)
	if self:GetActive() and Game:GetState() == GUIState.Game then
		return false
	end
end

function CClientInventory:UpdateInventoryScreen(args)
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

function CClientInventory:WindowClosed(args)
    self.inventoryPageList:Clear()
	self.inventoryItemLabel:SetText("")
	self:SetActive(false)
	
	self.useButton:SetEnabled(false)
	self.dropButton:SetEnabled(false)
	self.sendToButton:SetEnabled(false)
end

function CClientInventory:SendToWindowClosed(args)
	self.sendToWindowActive = false
end

function CClientInventory:RowSelected(args)
	self.useButton:SetEnabled(true)
	self.dropButton:SetEnabled(true)
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

cClientInventory = CClientInventory()