
ITEM.name = "Walkie Talkie"
ITEM.model = Model("models/deadbodies/dead_male_civilian_radio.mdl")
ITEM.description = "A shiny handheld walkie talkie.\nIt is currently turned %s."
ITEM.cost = 50
ITEM.classes = {CLASS_EMP, CLASS_EOW}
ITEM.flag = "v"

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
			surface.DrawRect(w - 15, h - 20, 9, 2)
		end
	end
end

function ITEM:GetDescription()
	local enabled = self:GetData("enabled")
	local ret = string.format(self.description, enabled and "on" or "off")--, enabled and (" and tuned to " .. self:GetData("frequency", "100.0") .. " MHz") or "")
	
	if enabled then
		local defCh = "CH"..self:GetData("channel","1")
		local adStr = self:GetData("ch"..self:GetData("channel","1").."name",defCh)
		ret = ret.."\nIt is set to channel "..self:GetData("channel","1")..( (adStr != defCh) and ", known as "..adStr.."." or ".")
	end
	if (self:GetData("silenced") and enabled) then
		ret = ret .. " \nRadio tones are currently silenced."
	end
	if self:GetData("active") then
		local brdcastStr = ", and broadcasting on all channels!"
		ret = string.format("%s \nYou are transmitting on this radio%s",ret, self:GetData("broadcast") and brdcastStr or ".")
	end
	
	return ret
end

function ITEM.postHooks.drop(item, status)
	item:SetData("enabled", false)
	item:SetData("active",false)
	item:SetData("broadcast",false)
end

function ITEM.postHooks.Scan(item, status)
	local itemTable = item
	local character = itemTable.player:GetCharacter()

	-- Finds players within 1/4 the max radio range
	local loc = itemTable.player:GetPos()
	local randFreq = 100*math.random(1,9) + 10*math.random(0,9) + math.random(0,9) + 0.1*math.random(1,9)
	local maxRange =  (ix.config.Get("radioRangeMult") * ix.config.Get("chatRange",280)) / ix.config.Get("walkieMult",4)
	local listenerEnts = ents.FindInSphere(loc, maxRange)
	local lockedOn = false

	--print(loc)
	--local maxRange = (1/4) * ix.config.Get("radioRangeMult") * ix.config.Get("chatRange",280)
	--local normDist = (loc / maxRange)
	--local failChance = 1 - math.min(1, normDist^2) -- Chance to be set to a random frequency

	for k, v in ipairs(listenerEnts) do
		if ( v:IsPlayer() and itemTable.player != v ) then
			local dist = itemTable.player:GetPos():Distance(v:GetPos())
			local failChance = 0
			local otherFreq
			if (dist > ix.config.Get("chatRange",280)) then
				failChance = 1 - math.min(1, (dist / maxRange)^2)
			end
			
			local otherFreq
			if (math.random() > failChance) then
				otherFreq = randFreq
			end
			
			if ( dist  <= maxRange ) then 
				if  ( v:GetCharacter() and v:GetCharacter():GetData("frequency") and v:GetCharacter():GetData("channel") ) then
	
					local chr = v:GetCharacter()
					local inv = chr:GetInventory()
					local walkie = inv:GetItemsByUniqueID("walkietalkie")
					
					if walkie then
						for k,v in ipairs(walkie) do
							--PrintTable(v)
							if v:GetData("active") then
								local freq,chan = chr:GetData("frequency"),chr:GetData("channel") or otherFreq,"1"
								if freq == item:GetData("frequency") then
									freq,chan = otherFreq,"1"
								end
								itemTable:SetData("frequency",freq)
								itemTable:SetData("channel",chan)
								character:SetData("frequency",freq)
								character:SetData("channel",chan)
								lockedOn = true
								if (freq == otherFreq) then 
									itemTable.player:Notify("Locked on to a weak signal on channel 1.")
								elseif (freq != otherFreq) then
									itemTable.player:Notify("Locked on to a strong signal on channel "..chan..".")
								end
								break
							end
						end
						break
					end
				end
			end
		end
	end
	
	if !lockedOn then
		itemTable:SetData("frequency",randFreq)
		itemTable:SetData("channel","1")
		character:SetData("frequency",randFreq)
		character:SetData("channel","1")
		itemTable.player:Notify("Locked on to a weak signal on channel 1.")
	end
	
	--print(item:GetData("channel"))
end

ITEM.functions.Scan = {
	OnRun = function(itemTable)
	
		local character = itemTable.player:GetCharacter()
		local inventory = character:GetInventory()
		
		local radios = inventory:GetItemsByUniqueID("handheld_radio", true)
		local radioTypes = {"walkietalkie","longrange"}
		for _,curtype in pairs(radioTypes) do
			local current = inventory:GetItemsByUniqueID(curtype, true)
			if (#current > 0) then 
				for k,v in pairs(current) do radios[#radios+1] = v end
			end
		end
		
		-- local walkies = character:GetInventory():GetItemsByUniqueID("walkietalkie", true)
		-- local radios = character:GetInventory():GetItemsByUniqueID("handheld_radio", true)
		-- local longranges = {walkies, character:GetInventory():GetItemsByUniqueID("longrange", true)}
		-- --local bBreak = false
		
		-- -- Puts the long ranges in with regular radios
		-- if (#longranges > 0) then
			-- for k,v in pairs(longranges) do radios[#radios+1] = v end
		-- end
		-- if (#walkies > 0) then
			-- for k,v in pairs(walkies) do radios[#radios+1] = v end
		-- end
		
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

ITEM.functions.Broadcast = {
	OnRun = function(itemTable)
		
		local character = itemTable.player:GetCharacter()
		local inventory = character:GetInventory()
		
		local radios = inventory:GetItemsByUniqueID("handheld_radio", true)
		local radioTypes = {"walkietalkie","longrange"}
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
			itemTable.player:NotifyLocalized("You are now broadcasting over all channels.")
		else
			itemTable.player:NotifyLocalized("You are no longer broadcasting over all channels.")
		end
		
		return false
	end,
	
	OnCanRun = function(itemTable)
		local bAllowed = ix.config.Get("broadcastLevel",1)
		if !ix.config.Get("allowBroadcast",true) then
			return false
		elseif bAllowed == 3 then
			return true
		else
			return false
		end
	end
}


ITEM.functions.Channel = {
	OnRun = function(itemTable)
	
		-- If it's not active, make it so
		local character = itemTable.player:GetCharacter()
		local inventory = character:GetInventory()
		
		local radios = inventory:GetItemsByUniqueID("handheld_radio", true)
		local radioTypes = {"walkietalkie","longrange"}
		for _,curtype in pairs(radioTypes) do
			local current = inventory:GetItemsByUniqueID(curtype, true)
			if (#current > 0) then 
				for k,v in pairs(current) do radios[#radios+1] = v end
			end
		end
		local bBreak = false
		
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
		
		netstream.Start(itemTable.player, "Channel")
		
		return false
	end
}

ITEM.functions.ChannelRename = {
	
	OnRun = function(itemTable)
	
		-- If it's not active, make it so
		local character = itemTable.player:GetCharacter()
		local inventory = character:GetInventory()
		
		local radios = inventory:GetItemsByUniqueID("handheld_radio", true)
		local radioTypes = {"walkietalkie","longrange"}
		for _,curtype in pairs(radioTypes) do
			local current = inventory:GetItemsByUniqueID(curtype, true)
			if (#current > 0) then 
				for k,v in pairs(current) do radios[#radios+1] = v end
			end
		end
		local bBreak = false
		
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
		end
		
		netstream.Start(itemTable.player, "ChannelRename", tab)
		return false
	end
}

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

ITEM.functions.Toggle = {
	OnRun = function(itemTable)
		local character = itemTable.player:GetCharacter()
		local inventory = character:GetInventory()
		
		local radios = inventory:GetItemsByUniqueID("handheld_radio", true)
		local radioTypes = {"walkietalkie","longrange"}
		for _,curtype in pairs(radioTypes) do
			local current = inventory:GetItemsByUniqueID(curtype, true)
			if (#current > 0) then 
				for k,v in pairs(current) do radios[#radios+1] = v end
			end
		end
		local bCanToggle = true
		
		-- activates the radio if no other powered on radios are in inventory already
		local enabl = false
		for k, v in ipairs(radios) do
			if (v != itemTable and v:GetData("enabled", false)) then
				enabl = true
				break
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
				character:SetData("frequency","")
				itemTable:SetData("active",false)
				itemTable:SetData("broadcast",false)
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
		local radioTypes = {"walkietalkie","longrange"}
		for _,curtype in pairs(radioTypes) do
			local current = inventory:GetItemsByUniqueID(curtype, true)
			if (#current > 0) then 
				for k,v in pairs(current) do radios[#radios+1] = v end
			end
		end
		local bCanToggle = true
		
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
