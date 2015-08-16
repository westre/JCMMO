class 'CClientJobSelection'

function CClientJobSelection:__init()
	self.data = {}
	
	self.window = Window.Create()
	self.window:SetSizeRel(Vector2(0.5, 0.5))
	self.window:SetPositionRel(Vector2(0.25, 0.25))
	self.window:SetTitle("Job Selection")
	self.window:SetVisible(false)
	
	self.listBox = ListBox.Create(self.window)
	self.listBox:SetPosition(Vector2(0, 0))
	self.listBox:SetSizeRel(Vector2(0.5, 1))
	self.listBox:SetDock(GwenPosition.Fill)
	self.listBox:Subscribe("RowSelected", self, self.RowSelected)
	
	self.jobDescription = Window.Create(self.window)
	self.jobDescription:SetClosable(false)
	self.jobDescription:SetTitle("Job Description")
	self.jobDescription:SetDock(GwenPosition.Right)
	self.jobDescription:SetSizeRel(Vector2(0.5, 1))	
	
	self.jobDescriptionLabel = Label.Create(self.jobDescription)
	self.jobDescriptionLabel:SetText("")
	self.jobDescriptionLabel:SetSizeRel(Vector2(1, 1))	
	self.jobDescriptionLabel:SetWrap(true)
	
	self.jobEnlistButton = Button.Create(self.window)
	self.jobEnlistButton:SetText("Enlist")
	self.jobEnlistButton:SetSizeRel(Vector2(1, 0.1))	
	self.jobEnlistButton:SetDock(GwenPosition.Bottom)
	self.jobEnlistButton:Subscribe("Press", self, self.EnlistButton)

	Events:Subscribe("GameLoad", self, self.GameLoad)
	
	Network:Subscribe("UpdateJobSelectionScreen", self, self.UpdateJobSelectionScreen) 
end

function CClientJobSelection:UpdateJobSelectionScreen(argsTable)
	self.data = argsTable

	for id, receivedTable in pairs(argsTable) do
		local item = self.listBox:AddItem(tostring(receivedTable.name))
	end
	
	self.window:SetVisible(true)
	Mouse:SetVisible(true)
end

function CClientJobSelection:GameLoad()
	--self.window:SetVisible(true)
end

function CClientJobSelection:EnlistButton()
	local jobName = self.listBox:GetSelectedRow():GetCellText(0)
	
	for id, receivedTable in pairs(self.data) do
		if receivedTable.name == jobName then
			Network:Send("SetPlayerInJob", { id = LocalPlayer:GetId(), jobId = id })
			self.window:SetVisible(false)
			Mouse:SetVisible(false)
			break
		end
	end
end

function CClientJobSelection:RowSelected(args)
	local jobName = self.listBox:GetSelectedRow():GetCellText(0)
	
	for id, receivedTable in pairs(self.data) do
		if receivedTable.name == jobName then
			self.jobDescriptionLabel:SetText(receivedTable.name .. "\n\n" .. receivedTable.description .. "\n\nFeatures:\n" .. receivedTable.features)
			break
		end
	end
end

cClientJobSelection = CClientJobSelection()