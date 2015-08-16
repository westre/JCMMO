class 'CClientAuctionHouse'

function CClientAuctionHouse:__init()
	self.active = false

	self.window = Window.Create()
	self.window:SetSizeRel(Vector2(0.75, 0.75))
	self.window:SetPositionRel(Vector2(0.5, 0.5) - self.window:GetSizeRel() / 2)
	self.window:SetTitle("Auction House")
	self.window:SetVisible(self.active)
	self.window:Subscribe("WindowClosed", self, self.WindowClosed)
	
	self.tabs = TabControl.Create(self.window)
	self.tabs:SetDock(GwenPosition.Fill)
	self.tabs:SetTabStripPosition(GwenPosition.Top)
	
	-- BUY --
	local auctionTab = self.tabs:AddPage("Bid and Buy")
	local auctionPage = auctionTab:GetPage()

	--local auctionScrollControl = ScrollControl.Create(auctionPage)
	--auctionScrollControl:SetDock(GwenPosition.Fill)
	
	self.auctionPageList = SortedList.Create(auctionPage)
	self.auctionPageList:SetDock(GwenPosition.Fill)
	self.auctionPageList:AddColumn("Item")
	self.auctionPageList:AddColumn("Time Left", 128)
	self.auctionPageList:AddColumn("Seller", 128)
	self.auctionPageList:AddColumn("Current Bid", 128)
	self.auctionPageList:Subscribe("RowSelected", self, self.RowSelected)
	self.auctionPageList:SetButtonsVisible(true)
	
	local actionBar = Window.Create(auctionPage)
	actionBar:SetClosable(false)
	actionBar:SetTitle("Actions")
	actionBar:SetDock(GwenPosition.Bottom)
	actionBar:SetSize(Vector2(0, 50))	
	
	self.yourMoneyLabel = Label.Create(actionBar)
	self.yourMoneyLabel:SetSizeRel(Vector2(1, 1))
	self.yourMoneyLabel:SetText("Your money: " .. LocalPlayer:GetMoney())
	
	self.bidLabel = Label.Create(actionBar)
	self.bidLabel:SetPosition(Vector2(300, 0))
	self.bidLabel:SetText("Your bid: ")
	
	self.bidBox = TextBoxNumeric.Create(actionBar)
	self.bidBox:SetPosition(Vector2(360, 0))
	self.bidBox:SetSize(Vector2(200, 15))
	
	self.bidButton = Button.Create(actionBar)
	self.bidButton:SetText("Bid")
	self.bidButton:SetPosition(Vector2(700, 0))
	self.bidButton:SetSize(Vector2(100, 18))
	
	self.buyoutButton = Button.Create(actionBar)
	self.buyoutButton:SetText("Buyout")
	self.buyoutButton:SetPosition(Vector2(810, 0))
	self.buyoutButton:SetSize(Vector2(100, 18))
	
	-- END OF BUY --
	
	self.tabs:AddPage("Sell")
	
	Events:Subscribe("KeyUp", self, self.KeyUp)
	Events:Subscribe("LocalPlayerInput", self, self.LocalPlayerInput) -- disable player input
end

function CClientAuctionHouse:GetActive()
	return self.active
end

function CClientAuctionHouse:SetActive(state)
	self.active = state
	self.window:SetVisible(self.active)
	Mouse:SetVisible(self.active)
end

function CClientAuctionHouse:KeyUp(args)
	if args.key == VirtualKey.F5 then
		if self:GetActive() == false then
			--Network:Send("AskServerForInventory", { LocalPlayer:GetId() })
		else
			self.auctionPageList:Clear()
		end
		self:SetActive(not self:GetActive())
	end
end

function CClientAuctionHouse:LocalPlayerInput(args)
	if self:GetActive() and Game:GetState() == GUIState.Game then
		return false
	end
end


function CClientAuctionHouse:WindowClosed(args)
    self.auctionPageList:Clear()
	self:SetActive(false)
end

function CClientAuctionHouse:RowSelected(args)
	local id = self.inventoryPageList:GetSelectedRow():GetCellText(0)
    print("ID: " .. self.inventoryPageList:GetSelectedRow():GetCellText(0))
	
	local desc = inventoryContents[id].name .. "\n\n" .. inventoryContents[id].description .. "\n\nWeight: " .. inventoryContents[id].weight .. "\n\nAbilities:\n"
	
	for key, value in pairs(inventoryContents[id].assembly) do
		desc = desc .. key .. ": " .. value .. "\n"
	end

	self.inventoryItemLabel:SetText(desc)
end

cClientAuctionHouse = CClientAuctionHouse()