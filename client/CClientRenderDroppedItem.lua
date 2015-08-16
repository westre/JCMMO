class 'CClientRenderDroppedItem'

function CClientRenderDroppedItem:__init()
	self.items = {}
	
	Network:Subscribe("AddItem", self, self.AddItem)
	Events:Subscribe("Render", self, self.Render)
end

function CClientRenderDroppedItem:AddItem(args)
	table.insert(self.items, args)
end

function CClientRenderDroppedItem:Render()
	if Game:GetState() ~= GUIState.Game then return end
	if LocalPlayer:GetWorld() ~= DefaultWorld then return end

	for _, item in pairs(self.items) do
		local distanceBetweenMeAndItem = item.position:Distance2D(Camera:GetPosition())
		
		if distanceBetweenMeAndItem <= 50 then
			local higherText = item.position + Vector3(-0.5, 2, 0)
			local vec2, success = Render:WorldToScreen(higherText)
			
			local objectVec2, successVec2 = Render:WorldToScreen(item.position + Vector3(0, 0.75, 0))	
			
			if success and successVec2 then
				Render:DrawLine(vec2, objectVec2, Color(0, 255, 0, 50))
				Render:DrawText(vec2, item.name .. " (ID " .. item.id .. ")\nAmount: " .. item.amount .. " | Weight: " .. item.weight .. "\nDropped by " .. item.owner, Color(255, 255, 255, 255), 12, 1.0)
			end
		end
	end
end

cClientRenderDroppedItem = CClientRenderDroppedItem()