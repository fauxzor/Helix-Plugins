
ITEM.name = "Hybrid Walkie Talkie"
ITEM.description = "A shiny simplex/duplex walkie talkie%s.\nIt is currently turned %s%s."
ITEM.hybrid = true
ITEM.walkietalkie = true

-- Inventory drawing
if (CLIENT) then
	function ITEM:PaintOver(item, w, h)
	
		if (item:GetData("enabled")) then
			surface.SetDrawColor(255, 255, 0, 100)
			surface.DrawRect(w - 14, h - 14, 8, 8)
		end
		
		if (item:GetData("active")) then
			surface.SetDrawColor(110, 200, 110, 255)
			surface.DrawRect(w - 14, h - 14, 8, 8)
		end
		
		if (item:GetData("silenced") and item:GetData("enabled")) then
			surface.SetDrawColor(255, 255/4, 110/2, 200)
			surface.DrawRect(w - 14, h - 11, 9, 2)
		end
		
		if (item:GetData("broadcast") and item:GetData("enabled")) then
			surface.SetDrawColor(255/4, 255, 110*2, 200)
			surface.DrawRect(w - 14, h - 18, 8, 2)
		end
		
		if (item:GetData("scanning") and item:GetData("enabled")) then
			surface.SetDrawColor(255,165, 0, 200)
			surface.DrawRect(w - 18, h - 14, 2, 8)
		end
		
		-- Hybrid stuff
		if item:GetData("enabled") and item.hybrid then
			surface.DrawCircle(w - 10*5.5, h - 10, 4,Color(220, 220, 220, 200))
			if item:GetData("duplex",false) then
				surface.DrawCircle(w - 10*4.25, h - 10, 4,Color(220, 220, 220, 200))
			end
		end
	end
end