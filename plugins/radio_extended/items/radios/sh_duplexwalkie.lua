
ITEM.name = "Duplex Walkie Talkie"
ITEM.description = "A shiny duplex walkie talkie%s.\nIt is currently turned %s%s."

ITEM.duplex = true
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
	end
end

ITEM.functions.Synchronize = {
	OnRun = function(itemTable)
		--print(itemTable.radiotypes)
		local character = itemTable.player:GetCharacter()
		local inventory = character:GetInventory()
		
		local radios = inventory:GetItemsByUniqueID("handheld_radio", true)
		--
		for _,curtype in pairs(itemTable.radiotypes) do
			local current = inventory:GetItemsByUniqueID(curtype, true)
			if (#current > 0) then 
				for k,v in pairs(current) do radios[#radios+1] = v end
			end
		end

		if !itemTable:GetData("enabled") then 
			itemTable:SetData("enabled", true)
		end
		
		if (!itemTable:GetData("active")) then -- if the current radio is on...
			-- first deactivates all other active radios
			for k, v in ipairs(radios) do
				if (v != itemTable and v:GetData("enabled", false) and v:GetData("active",false)) then
					v:SetData("active",false)
					--bCanToggle = false
					--break
				end
			end
			
			itemTable:SetData("active",true)
			character:SetData("frequency",itemTable:GetData("frequency","100.0"))
			character:SetData("channel",itemTable:GetData("channel","1"))
		end
		
		return false
	end
}