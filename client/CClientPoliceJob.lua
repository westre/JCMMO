class 'CClientPoliceJob'

function CClientPoliceJob:__init()
	self.active = false
	self.curItemIdSelected = nil
	
	self.window = Window.Create()
	self.window:SetSizeRel(Vector2(0.5, 0.5))
	self.window:SetPositionRel(Vector2(0.5, 0.5) - self.window:GetSizeRel() / 2)
	self.window:SetTitle("Police Job")
	self.window:SetVisible(self.active)
	self.window:Subscribe("WindowClosed", self, self.WindowClosed)
	self.window:DisableResizing()

	self.tabs = TabControl.Create(self.window)
	self.tabs:SetDock(GwenPosition.Fill)
	self.tabs:SetTabStripPosition(GwenPosition.Top)
	
	-- INVENTORY --
	local inventoryTab = self.tabs:AddPage("Objective")
	local inventoryPage = inventoryTab:GetPage()
	
	self.headerLabel = Label.Create(inventoryPage)
	self.headerLabel:SetDock(GwenPosition.Fill)
	self.headerLabel:SetText("Your objective is to catch criminals and detain them. The only way to detain them is to kill them at the moment. Catching high value targets will of course give high rewards in return. See the Citizen Database (next tab) for the wanted level of each citizen.")
	self.headerLabel:SetWrap(true)
	
	inventoryTab = self.tabs:AddPage("Citizen Database")
	inventoryPage = inventoryTab:GetPage()
	
	inventoryPageScrollControl = ScrollControl.Create(inventoryPage)
	inventoryPageScrollControl:SetDock(GwenPosition.Fill)

	self.inventoryPageList = SortedList.Create(inventoryPageScrollControl)
	self.inventoryPageList:SetDock(GwenPosition.Fill)
	self.inventoryPageList:SetMargin(Vector2(4, 4), Vector2(4, 4))
	self.inventoryPageList:AddColumn("Player ID", 64)
	self.inventoryPageList:AddColumn("Name")
	self.inventoryPageList:AddColumn("Wanted Lvl", 64)
	self.inventoryPageList:AddColumn("Distance", 64)
	self.inventoryPageList:Subscribe("RowSelected", self, self.RowSelected)
	self.inventoryPageList:SetButtonsVisible(true)
	
	self.acceptButton = Button.Create(inventoryPageScrollControl)
	self.acceptButton:SetText("Hmm... *scratches beard* yeah, I like this criminal scum!")
	self.acceptButton:SetDock(GwenPosition.Bottom)
	self.acceptButton:Subscribe("Press", self, self.AcceptButton)
	self.acceptButton:SetSize(Vector2(0, 25))
	self.acceptButton:SetEnabled(false)
	
	Events:Subscribe("CharPress", self, self.CharPress)
	Events:Subscribe("LocalPlayerInput", self, self.LocalPlayerInput) -- disable player input
	
	Network:Subscribe("ProceedJobDialog", self, self.ProceedJobDialog) 
end

function CClientPoliceJob:ProceedJobDialog(args)
	local jobString = args[1]
	
	if jobString == "Police" then
		self.inventoryPageList:Clear()		
		Network:Send("AskServerForDeliveryJobs", { LocalPlayer:GetId() }) -- playerId, entityType, businessId, houseId
		self:SetActive(true)
	end
end

function CClientPoliceJob:CharPress(args)
	local key = args.character
	
	if key == "j" then
		if not self:GetActive() then
			Network:Send("AskServerForMyCurrentJob", { LocalPlayer:GetId(), "Police" })
		else
			self:SetActive(false)
			self.acceptButton:SetEnabled(false)
		end
	end
end

function CClientPoliceJob:AcceptButton()
	
end

function CClientPoliceJob:GetActive()
	return self.active
end

function CClientPoliceJob:SetActive(state)
	self.active = state
	self.window:SetVisible(self.active)
	Mouse:SetVisible(self.active)
end

function CClientPoliceJob:LocalPlayerInput(args)
	if self:GetActive() and Game:GetState() == GUIState.Game then
		return false
	end
end

function CClientPoliceJob:WindowClosed(args)
    self.inventoryPageList:Clear()
	self:SetActive(false)
	
	self.acceptButton:SetEnabled(false)
end

function CClientPoliceJob:SendToWindowClosed(args)
	self.sendToWindowActive = false
end

function CClientPoliceJob:RowSelected(args)
	self.acceptButton:SetEnabled(true)

	local id = self.inventoryPageList:GetSelectedRow():GetCellText(0)
	self.curItemIdSelected = id
end

cClientPoliceJob = CClientPoliceJob()