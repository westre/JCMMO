class 'CClientBusinessDialog'

function CClientBusinessDialog:__init()
	self.active = false
	
	self.curItemIdSelected = nil
	self.curHotspotId = nil
	self.curHotspotOwner = nil
	
	self.window = Window.Create()
	self.window:SetSizeRel(Vector2(0.75, 0.75))
	self.window:SetPositionRel(Vector2(0.5, 0.5) - self.window:GetSizeRel() / 2)
	self.window:SetTitle("Business Inventory")
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
	self.inventoryPageList:AddColumn("Price", 64)
	self.inventoryPageList:AddColumn("Discount", 64)
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
	
	self.priceAmount = TextBoxNumeric.Create(inventoryItemInfo)
	self.priceAmount:SetPosition(Vector2(0, 330))
	self.priceAmount:SetSize(Vector2(50, 25))
	
	self.priceButton = Button.Create(inventoryItemInfo)
	self.priceButton:SetText("Set Price")
	self.priceButton:SetPosition(Vector2(50, 330))
	self.priceButton:SetSize(Vector2(200, 25))
	self.priceButton:Subscribe("Press", self, self.SetPrice)
	self.priceButton:SetEnabled(false)
	
	self.secondPriceAmount = TextBoxNumeric.Create(inventoryItemInfo)
	self.secondPriceAmount:SetPosition(Vector2(0, 355))
	self.secondPriceAmount:SetSize(Vector2(50, 25))
	
	self.secondPriceButton = Button.Create(inventoryItemInfo)
	self.secondPriceButton:SetText("Set Discount Price")
	self.secondPriceButton:SetPosition(Vector2(50, 355))
	self.secondPriceButton:SetSize(Vector2(200, 25))
	self.secondPriceButton:Subscribe("Press", self, self.SetSecondPrice)
	self.secondPriceButton:SetEnabled(false)
	
	self.sendAmount = TextBoxNumeric.Create(inventoryItemInfo)
	self.sendAmount:SetPosition(Vector2(0, 380))
	self.sendAmount:SetSize(Vector2(50, 25))
	
	self.sendToButton = Button.Create(inventoryItemInfo)
	self.sendToButton:SetText("undefined")
	self.sendToButton:SetPosition(Vector2(50, 380))
	self.sendToButton:SetSize(Vector2(200, 25))
	self.sendToButton:Subscribe("Press", self, self.SendToButton)
	self.sendToButton:SetEnabled(false)
	
	self.priceButton:SetVisible(false)
	self.priceAmount:SetVisible(false)
	self.secondPriceAmount:SetVisible(false)
	self.secondPriceButton:SetVisible(false)
	-- END OF INVENTORY --
	
	Events:Subscribe("LocalPlayerInput", self, self.LocalPlayerInput) -- disable player input
	Events:Subscribe("CharPress", self, self.CharPress)
	
	Network:Subscribe("UpdateBusinessInventoryScreen", self, self.UpdateBusinessInventoryScreen) 
end

function CClientBusinessDialog:SetPrice()
	Network:Send("SetItemPrice", { invId = inventoryId, itemId = self.curItemIdSelected, price = self.priceAmount:GetValue(), state = "first", entityId = self.curHotspotId })
	
	self.inventoryPageList:Clear()
	self.sendToButton:SetEnabled(false)
	Network:Send("AskServerForInventory", { LocalPlayer:GetId(), "business", self.curHotspotId })
end

function CClientBusinessDialog:SetSecondPrice()
	Network:Send("SetItemPrice", { invId = inventoryId, itemId = self.curItemIdSelected, price = self.secondPriceAmount:GetValue(), state = "second", entityId = self.curHotspotId })
	
	self.inventoryPageList:Clear()
	self.sendToButton:SetEnabled(false)
	Network:Send("AskServerForInventory", { LocalPlayer:GetId(), "business", self.curHotspotId })
end

function CClientBusinessDialog:SendToButton()
	Network:Send("SendItemToPlayer", { fromEntityId = self.curHotspotId, toPlayerId = LocalPlayer:GetId(), amount = self.sendAmount:GetValue(), itemId = self.curItemIdSelected, state = "business" })
	
	self.inventoryPageList:Clear()
	self.sendToButton:SetEnabled(false)
	Network:Send("AskServerForInventory", { LocalPlayer:GetId(), "business", self.curHotspotId })
end

function CClientBusinessDialog:WindowClosed(args)
    self.inventoryPageList:Clear()
	self.inventoryItemLabel:SetText("")
	self.sendToButton:SetEnabled(false)
	self:SetActive(false)
end

function CClientBusinessDialog:RowSelected(args)
	local id = self.inventoryPageList:GetSelectedRow():GetCellText(0)
	self.curItemIdSelected = id
    print("ID: " .. self.inventoryPageList:GetSelectedRow():GetCellText(0))
	
	self.priceButton:SetEnabled(true)
	self.priceAmount:SetEnabled(true)
	self.secondPriceAmount:SetEnabled(true)
	self.secondPriceButton:SetEnabled(true)
						
	if inventoryContents[id].price < 0 and inventoryContents[id].secondPrice < 0 and self.curHotspotOwner ~= LocalPlayer:GetSteamId().id then
		self.sendToButton:SetEnabled(false)
	else
		self.sendToButton:SetEnabled(true)
	end
	
	local desc = inventoryContents[id].name .. "\n\n" .. inventoryContents[id].description .. "\n\nWeight: " .. inventoryContents[id].weight .. "\n\nAbilities:\n"
	
	for key, value in pairs(inventoryContents[id].assembly) do
		desc = desc .. key .. ": " .. value .. "\n"
	end

	self.inventoryItemLabel:SetText(desc)
end

function CClientBusinessDialog:CharPress(args)
	local key = args.character
	
	if key == "h" then
		for _, hotspot in ipairs(cClientHotspot:GetBusinessHotspot()) do
			if hotspot.position:Distance2D(LocalPlayer:GetPosition()) <= 5 then
				if not self:GetActive() then
					self.inventoryPageList:Clear()
					self.curHotspotId = hotspot.id
					self.curHotspotOwner = hotspot.ownerId
					Chat:Print("near business: " .. hotspot.id,Color(255,255,255))
					Network:Send("AskServerForInventory", { LocalPlayer:GetId(), "business", hotspot.id }) -- playerId, entityType, businessId, houseId
					
					if hotspot.ownerId == LocalPlayer:GetSteamId().id then
						self.sendToButton:SetText("Send to Inventory")
						self.priceButton:SetVisible(true)
						self.priceAmount:SetVisible(true)
						self.secondPriceAmount:SetVisible(true)
						self.secondPriceButton:SetVisible(true)
						self.priceButton:SetEnabled(false)
						self.priceAmount:SetEnabled(false)
						self.secondPriceAmount:SetEnabled(false)
						self.secondPriceButton:SetEnabled(false)
					else
						self.sendToButton:SetText("Buy Item")
						self.priceButton:SetVisible(false)
						self.priceAmount:SetVisible(false)
						self.secondPriceAmount:SetVisible(false)
						self.secondPriceButton:SetVisible(false)
					end
					
					self:SetActive(true)
				else
					self.priceButton:SetVisible(false)
					self.priceAmount:SetVisible(false)
					self.secondPriceAmount:SetVisible(false)
					self.secondPriceButton:SetVisible(false)
					self.sendToButton:SetEnabled(false)
					self:SetActive(false)
				end
				break
			end
		end
	end
end

function CClientBusinessDialog:LocalPlayerInput(args)
	if self:GetActive() and Game:GetState() == GUIState.Game then
		return false
	end
end

function CClientBusinessDialog:GetActive()
	return self.active
end

function CClientBusinessDialog:SetActive(state)
	self.active = state
	self.window:SetVisible(self.active)
	Mouse:SetVisible(self.active)
end

function CClientBusinessDialog:UpdateBusinessInventoryScreen(args)
	inventoryId = args.inventoryId
	inventoryName = args.inventoryName
	inventoryMaxWeight = args.inventoryMaxWeight
	inventoryContents = args.inventoryContents
	
	for id, cItem in pairs(inventoryContents) do
		local item = self.inventoryPageList:AddItem(tostring(id))
		item:SetCellText(1, cItem.name)
		item:SetCellText(2, tostring(cItem.amount))
		item:SetCellText(3, tostring(cItem.totalWeight))
		
		print("price: " .. cItem.price .. ", secprice: " .. cItem.secondPrice)
		
		if cItem.price >= 0 and cItem.secondPrice >= 0 then
			local percentage = (cItem.price - cItem.secondPrice) / cItem.price * 100
			item:SetCellText(4, tostring(cItem.secondPrice))
			item:SetCellText(5, "-" .. percentage .. "%")
			item:SetBackgroundEvenColor(Color(255, 140, 0))
			item:SetBackgroundOddColor(Color(255, 140, 0))
		elseif cItem.price >= 0 and cItem.secondPrice < 0 then
			item:SetCellText(4, tostring(cItem.price))
			item:SetCellText(5, "N/A")
		elseif cItem.price < 0 and cItem.secondPrice < 0 then
			item:SetCellText(4, "N/A")
			item:SetCellText(5, "N/A")
		else
			item:SetCellText(4, "WTF")
			item:SetCellText(5, "WTF")
		end
	end
	
	self.headerLabel:SetText("You are currently holding: " .. inventoryName .. " which has a maximum supported weight of " .. inventoryMaxWeight)
end

cClientBusinessDialog = CClientBusinessDialog()