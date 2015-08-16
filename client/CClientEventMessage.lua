class 'CClientEventMessage'

function CClientEventMessage:__init()
	self.list = {}
	
	Events:Subscribe("Render", self, self.Render)
	
	Network:Subscribe("AddMessage", self, self.AddMessage) 
end

function CClientEventMessage:AddMessage(message) 
	local data = {}
	data.time = os.clock()
	data.message = message
	table.insert(self.list, data)
end

function CClientEventMessage:Render()
	local center_hint = Vector2( Render.Width - 5, Render.Height / 2 )
	local height_offset = 0
	
	for i, v in ipairs(self.list) do
        if os.clock() - v.time < 15 then
			local text_width = Render:GetTextWidth( v.message )
            local text_height = Render:GetTextHeight( v.message )
			
			local pos = center_hint + Vector2( -text_width, height_offset )
			
			local shadow_colour = Color(20, 20, 20, 128)

            Render:DrawText(pos + Vector2( 1, 1 ), v.message, shadow_colour)
			Render:DrawText(pos, v.message, Color(255, 255, 255), TextSize.Default)
			
			height_offset = height_offset + text_height + 10
        else
            table.remove(self.list, i)
		end
	end
end


cClientEventMessage = CClientEventMessage()