
ITEM.name = "Long Range Radio"
ITEM.model = Model("models/deadbodies/dead_male_civilian_radio.mdl")
ITEM.description = "A shiny handheld radio with a frequency tuner.\nIt is currently turned %s%s."
ITEM.cost = 50
ITEM.classes = {CLASS_EMP, CLASS_EOW}
ITEM.flag = "v"

local radioTypes = {"longrange","walkietalkie","duplexradio"}

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

function ITEM:GetDescription()
	local enabled = self:GetData("enabled")
	local ret = string.format(self.description, enabled and "on" or "off", enabled and (" and tuned to " .. self:GetData("frequency", "100.0") .. " MHz") or "")
	
	if enabled then
		if self:GetData("scanning", false) and enabled then
			ret = ret.."\nYou are listening to all channels on this frequency."
		end
		local defCh = "CH"..self:GetData("channel","1")
		local adStr = self:GetData("ch"..self:GetData("channel","1").."name",defCh)
		ret = ret.."\nIt is set to channel "..self:GetData("channel","1")..( (adStr != defCh) and ", known as "..adStr.."." or ".")
	end
	if (self:GetData("silenced") and enabled) then
		ret = ret .. " \nRadio tones are currently silenced."
	end
	if self:GetData("active") then
		local brdcastStr = ", and broadcasting on all channels!"
		ret = string.format("%s \nYou are transmitting on this radio%s", ret, self:GetData("broadcast") and brdcastStr or ".")
	end
	
	return ret
end

function ITEM.postHooks.drop(item, status)
	item:SetData("enabled", false)
	item:SetData("active",false)
	item:SetData("broadcast",false)
end

ITEM.functions.Broadcast = {
	OnRun = function(itemTable)
		
		local character = itemTable.player:GetCharacter()
		local inventory = character:GetInventory()
		
		local radios = inventory:GetItemsByUniqueID("handheld_radio", true)
		--local radioTypes = {"walkietalkie","longrange"}
		for _,curtype in pairs(radioTypes) do
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
					v:SetData("broadcast",false)
					--bCanToggle = false
					--break
				end
			end
			
			itemTable:SetData("active",true)
			character:SetData("frequency",itemTable:GetData("frequency","100.0"))
			character:SetData("channel",itemTable:GetData("channel","1"))
		end
		
		-- Toggles broadcasting
		itemTable:SetData("broadcast", !itemTable:GetData("broadcast", false))
		
		if itemTable:GetData("broadcast") then
			itemTable.player:NotifyLocalized("You are now broadcasting over all channels on "..itemTable:GetData("frequency","100.0").." MHz.")
		else
			itemTable.player:NotifyLocalized("You are no longer broadcasting over all channels.")
		end
		
		return false
	end,
	
	OnCanRun = function(itemTable)
		local bAllowed = ix.config.Get("broadcastLevel",1)
		if !ix.config.Get("allowBroadcast",true) then
			return false
		elseif bAllowed >= 1 then
			return true
		-- elseif bAllowed > 1 then
			-- return true
		end
		
	end
}

ITEM.functions.Frequency = {
	OnRun = function(itemTable)
	
		local character = itemTable.player:GetCharacter()
		local inventory = character:GetInventory()
		
		local radios = inventory:GetItemsByUniqueID("handheld_radio", true)
		--local radioTypes = {"walkietalkie","longrange"}
		for _,curtype in pairs(radioTypes) do
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
		--if (itemTable:GetData("enabled") and itemTable:GetData("active")) then
		netstream.Start(itemTable.player, "Frequency", itemTable:GetData("frequency", "100.0"))
		--else
		--	netstream.Start(itemTable, "Frequency", itemTable:GetData("frequency", "000.0"))
		--end

		return false
	end
}

ITEM.functions.Channel = {
	OnRun = function(itemTable)
	
		local character = itemTable.player:GetCharacter()
		local inventory = character:GetInventory()
		
		local radios = inventory:GetItemsByUniqueID("handheld_radio", true)
		--local radioTypes = {"walkietalkie","longrange"}
		for _,curtype in pairs(radioTypes) do
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
		
		local tab = {}
		for k,v in pairs({"1","2","3","4"}) do
			tab[k] = itemTable:GetData("ch"..v.."name","CH"..v)
			-- if tab[k] != "CH"..v then 
				-- tab[k] = "("..v..") "..tab[k]
			-- end
		end
		
		netstream.Start(itemTable.player, "Channel", tab)
		
		return false
	end
}

-- ITEM.functions.ChannelRename = {
	
	-- OnRun = function(itemTable)
	
		-- -- If it's not active, make it so
		-- local character = itemTable.player:GetCharacter()
		-- local inventory = character:GetInventory()
		
		-- local radios = inventory:GetItemsByUniqueID("handheld_radio", true)
		-- local radioTypes = {"walkietalkie","longrange"}
		-- for _,curtype in pairs(radioTypes) do
			-- local current = inventory:GetItemsByUniqueID(curtype, true)
			-- if (#current > 0) then 
				-- for k,v in pairs(current) do radios[#radios+1] = v end
			-- end
		-- end
		
		-- if !itemTable:GetData("enabled") then 
			-- itemTable:SetData("enabled", true)
		-- end
			
		-- if (!itemTable:GetData("active")) then -- if the current radio is on...
			-- -- first deactivates all other active radios
			-- for k, v in ipairs(radios) do
				-- if (v != itemTable and v:GetData("enabled", false) and v:GetData("active",false)) then
					-- v:SetData("active",false)
					-- v:SetData("broadcast",false)
					-- --bCanToggle = false
					-- --break
				-- end
			-- end
			
			-- itemTable:SetData("active",true)
			-- character:SetData("frequency",itemTable:GetData("frequency","100.0"))
			-- character:SetData("channel",itemTable:GetData("channel","1"))
		-- end
		
		-- local tab = {}
		-- for k,v in pairs({"1","2","3","4"}) do
			-- tab[k] = itemTable:GetData("ch"..v.."name","CH"..v)
		-- end
		
		-- netstream.Start(itemTable.player, "ChannelRename", tab)
		-- return false
	-- end
-- }

ITEM.functions.Silence = {
	OnRun = function(itemTable)
		--netstream.Start(itemTable.player, "Frequency", itemTable:GetData("silenced", "000.0"))
		if (itemTable:GetData("enabled")) then
			itemTable:SetData("silenced", !itemTable:GetData("silenced", false))
			if itemTable:GetData("silenced") then
				itemTable.player:NotifyLocalized("You silenced the radio.")
			else
				itemTable.player:NotifyLocalized("You unsilenced the radio.")
			end
		end
		return false
	end
}

ITEM.functions.Listen = {
	OnRun = function(itemTable)
		-- If it's not active, make it so
		local character = itemTable.player:GetCharacter()
		local inventory = character:GetInventory()
		
		local radios = inventory:GetItemsByUniqueID("handheld_radio", true)
		--local radioTypes = {"walkietalkie","longrange"}
		for _,curtype in pairs(radioTypes) do
			local current = inventory:GetItemsByUniqueID(curtype, true)
			if (#current > 0) then 
				for k,v in pairs(current) do radios[#radios+1] = v end
			end
		end
		
		if !itemTable:GetData("enabled") then 
			itemTable:SetData("enabled", true)
		end
		
		local keepScanning = false		
		for k, v in ipairs(radios) do
			if (v != itemTable and v:GetData("enabled", false)) then
				if v:GetData("scanning",false) then
					keepScanning = true
				end
				if v:GetData("active",false) then
					character:SetData("frequency",v:GetData("frequency","100.0"))
				end
			end
		end
	
		itemTable:SetData("scanning", !itemTable:GetData("scanning", false))

		-- Sets up item and character level scanning
		if (itemTable:GetData("scanning",false)) then
			itemTable:SetData("scanning",true)
			character:SetData("scanning",true)
			--itemTable:SetData("broadcast",false)
			--character:SetData("channel",itemTable:GetData("channel","1"))
			itemTable.player:NotifyLocalized("You are now listening to all channels on "..itemTable:GetData("frequency","100.0").." MHz.")
		else
			character:SetData("scanning",keepScanning)
			itemTable:SetData("scanning",false)
			itemTable.player:NotifyLocalized("You are no longer listening to all channels.")
		end
		
		return false
	end
}

ITEM.functions.Toggle = {
	OnRun = function(itemTable)
		local character = itemTable.player:GetCharacter()
		local inventory = character:GetInventory()
		
		local radios = inventory:GetItemsByUniqueID("handheld_radio", true)
		--local radioTypes = {"walkietalkie","longrange"}
		for _,curtype in pairs(radioTypes) do
			local current = inventory:GetItemsByUniqueID(curtype, true)
			if (#current > 0) then 
				for k,v in pairs(current) do radios[#radios+1] = v end
			end
		end
		local bCanToggle = true
		
		-- activates the radio if no other powered on radios are in inventory already
		local enabl = false
		local activeFreq = ""
		local keepScanning = false
		for k, v in ipairs(radios) do
			if (v != itemTable and v:GetData("enabled", false)) then
				enabl = true
				if v:GetData("active", false) then
					activeFreq = v:GetData("frequency","100.0")
				end
				if v:GetData("scanning", false) then
					keepScanning = true
				end
			end
		end
		
		
		
		-- for k, v in ipairs(longranges) do
			-- if (v != itemTable and v:GetData("enabled", false)) then
				-- bCanToggle = false
				-- break
			-- end
		-- end
		
		bCanToggle = true
		if (bCanToggle) then
			itemTable:SetData("enabled", !itemTable:GetData("enabled", false))

			-- Sets frequency to that of currently active radio
			if (itemTable:GetData("enabled",false)) then
				if !enabl then
					itemTable:SetData("active",true)
					character:SetData("frequency",itemTable:GetData("frequency","100.0"))
					character:SetData("channel",itemTable:GetData("channel","1"))
				end
			else
				character:SetData("frequency",activeFreq) -- If there's another active radio, make that your current frequency, otherwise clear it
				itemTable:SetData("active",false)
				itemTable:SetData("broadcast",false)
				itemTable:SetData("scanning",false)
				character:SetData("scanning",keepScanning) -- Since scanning is a character variable, only clear it if there aren't any other scanning radios
			end
			
			itemTable.player:EmitSound("buttons/lever7.wav", 50, math.random(170, 180), 0.25)
		else
			itemTable.player:NotifyLocalized("radioAlreadyOn")
		end

		return false
	end
}

ITEM.functions.Activate = {
	OnRun = function(itemTable)
		local character = itemTable.player:GetCharacter()
		local inventory = character:GetInventory()
		
		local radios = inventory:GetItemsByUniqueID("handheld_radio", true)
		--local radioTypes = {"walkietalkie","longrange"}
		for _,curtype in pairs(radioTypes) do
			local current = inventory:GetItemsByUniqueID(curtype, true)
			if (#current > 0) then 
				for k,v in pairs(current) do radios[#radios+1] = v end
			end
		end
		
		if (itemTable:GetData("enabled",false)) then -- if the current radio is on...
			-- first deactivates all other active radios
			for k, v in ipairs(radios) do
				if (v != itemTable and v:GetData("enabled", false) and v:GetData("active",false)) then
					v:SetData("active",false)
					--bCanToggle = false
					--break
				end
			end
			
			-- toggles current radio active status
			itemTable:SetData("active", !itemTable:GetData("active", false))
			if itemTable:GetData("active") then
				character:SetData("frequency",itemTable:GetData("frequency","100.0"))
				character:SetData("channel",itemTable:GetData("channel","1"))
				itemTable.player:NotifyLocalized("You activated the radio.")
			else
				character:SetData("frequency","")
				itemTable:SetData("broadcast",false)
				itemTable.player:NotifyLocalized("You deactivated the radio.")
			end
			
			-- -- Sets frequency to that of currently active radio
			-- if (itemTable:GetData("active",false)) then 
				-- character:SetData("frequency",itemTable:GetData("frequency","100.0"))
			-- else
				-- character:SetData("frequency","")
			-- end
			
			itemTable.player:EmitSound("buttons/lever8.wav", 50, math.random(170, 180), 0.25)
		--else
		--	itemTable.player:NotifyLocalized("radioAlreadyOn")
		end

		return false
	end
}
