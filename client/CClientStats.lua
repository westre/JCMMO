class 'CClientStats'

function CClientStats:__init()
	self.progressBar = ProgressBar.Create()
	self.progressBar:SetAutoLabel(false)
	self.progressBar:SetText("500/500")
	self.progressBar:SetValue(0.5)
	self.progressBar:SetSize(Vector2(Render.Width - 200, 15))
	self.progressBar:SetPosition(Vector2(0, Render.Height - self.progressBar:GetSize().y))
	self.progressBar:SetTextColor(Color(65, 105, 225))
	
	Network:Subscribe("UpdateProgressBar", self, self.UpdateProgressBar) 
	
	Events:Subscribe("Render", self, self.Render)
end

function CClientStats:UpdateProgressBar(value)
	self.progressBar:SetValue(value.value)
	self.progressBar:SetText(value.stringText)
end

function CClientStats:Render()
	Render:FillArea(Vector2(30, Render.Height - 43.5), Vector2(500, 20), Color(0, 0, 0, 64))
	Render:FillArea(Vector2(30, Render.Height - 43.5), Vector2(10, 20), Color(144, 238, 144, 64))
	Render:DrawText(Vector2(50, Render.Height - 40), "Level: 5 | Money: " .. LocalPlayer:GetMoney(), Color(255, 255, 255))
end

cClientStats = CClientStats()