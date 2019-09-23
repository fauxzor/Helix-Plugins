
local PLUGIN = PLUGIN

PLUGIN.name = "Extended Radio"
PLUGIN.author = "faust"
PLUGIN.description = "A standalone radio plugin with extended functionality over the default."

-- Anonymous names, if radio callsigns are anonymous
local radioanon = {"Somebody", "Someone", "A voice", "A person"}

-- Clientside hooks
if (CLIENT) then

	-- Channel handling
	local function setTheChannel(ch)
		ix.command.Send("SetChan", ch)
	end
	
	netstream.Hook("Channel", function(this)
		Derma_Query("Choose your channel", "Channel selection",
		"CH1", function()
			setTheChannel("1")
		end, 
		"CH2", function() 
			setTheChannel("2")
		end, 
		"CH3", function()
			setTheChannel("3")
		end,
		"CH4", function()
			setTheChannel("4")
		end)
	end)

	-- Frequency handling
	netstream.Hook("Frequency", function(oldFrequency)
		Derma_StringRequest("Frequency", "What would you like to set the frequency to?", oldFrequency, function(text)
			ix.command.Send("SetFreq", text)
		end)
	end)
	
end

-- Sets up configurations
ix.config.Add("radioColor",Color(164,224,91), "The default color for radio chat.", nil, {category = "Extended Radio"})
--ix.config.Add("radioYellColor",Color(164+30,224+30,91+30), "The default color for yelling in radio chat.", nil, {category = "Extended Radio"})
ix.config.Add("longRangeColor", Color(255,139,82), "The default color for long range radio chat.", nil, {category = "Extended Radio"})
--ix.config.Add("longRangeYellColor",Color(255,139+30,82+30), "The default color for yelling in long range radio chat.", nil, {category = "Extended Radio"})

ix.config.Add("radioFreqColor",Color(190,190,190), "The default color for radio frequencies.", nil, {category = "Extended Radio"})
ix.config.Add("activeFreqColor", Color(255,255,255), "The default color for long range radio frequencies.", nil, {category = "Extended Radio"})

ix.config.Add("radioYellBig", true, "Whether to use larger font sizes for yelling in the radio.", nil, {
	category = "Extended Radio"
})
ix.config.Add("radioWhisperSmall", true, "Whether to use smaller font sizes for whispering in the radio.", nil, {
	category = "Extended Radio"
})

-- Max map size in Source is 32768 units, and chat range is default 280 units, so max possible multiplier should be about 120
-- However, radio is garbled as the square of the distance, so the maximum "effective range" is actually (much) less than that
-- To say nothing of modifiers, and different map sizes/configurations...
-- Therefore the max multiplier can go up to 135 (only ~75% garbled at max map distance) although I recommend using a much smaller value
-- Long range radios have a separate multiplier that can be jacked up & people aren't usually talking across the map anyways
ix.config.Add("radioRangeMult", 100, "Max radio range = IC chat range * mult", nil, {
	data = {min = 1, max = 135},
	category = "Extended Radio"
})

ix.config.Add("longrangeMult", 2, "Max long range radio range = radio range * mult", nil, {
	data = {min = 1, max = 10},
	category = "Extended Radio"
})

ix.config.Add("garbleRadio", true, "Whether or not radio chatter is garbled over long distances.", nil, {
	category = "Extended Radio"
})

ix.config.Add("enableCallsigns", true, "Whether or not callsigns are allowed.", nil, {
	category = "Extended Radio"
})

ix.config.Add("defaultCallsign", 1, "1 = Character name, 2 = Anonymous (Somebody, Someone, etc).", nil, {
	data = {min = 1, max = 2},
	category = "Extended Radio"
})

ix.config.Add("radioSounds", true, "Toggles radio sending/receiving beeps & boops.", nil, {
	category = "Extended Radio"
})

function playSound(target,voiceprefix,sending,distance) -- Fun new function to more easily play radio send/receive sounds

	local maxRange = ix.config.Get("chatRange",280) * ix.config.Get("radioRangeMult", 100)
	local distance = distance or 0
	local distFrac = math.min(1, (distance/maxRange)^2)
	if (!ix.config.Get("garbleRadio",true)) then
		distFrac = 0
	end
	
	local range = math.random(ix.config.Get("chatRange",280),ix.config.Get("chatRange",280))
	local pitchmod = math.random(110 - 50*distFrac, 120 - 50*distFrac) -- Pitch shifts the receive beep with increasing distance
	local pitchmodAlt = math.random(50,50)
	local pitchmodAlt2 = math.random(120,120)
	local whichnoise = math.random(2,3)
	
	local volume
	if (distance != 0) then
		volume = 0.9
	else
		volume = 0.3
	end
	
	if ix.config.Get("radioSounds",true) then
		if sending then 	
			target:EmitSound(voiceprefix.."1"..".wav", range, pitchmodAlt,0.2)
			timer.Simple(0.05, function() target:EmitSound("extendedradio/walkiestart1.wav", range, 110, volume) end)
			//timer.Simple(0.03,function() target:EmitSound(voiceprefix.."1"..".wav", range, pitchmodAlt) end)
			
			timer.Simple(0.7, function() target:EmitSound(voiceprefix.."1"..".wav", range, pitchmodAlt2,volume) end)
			timer.Simple(0.77, function() target:EmitSound(voiceprefix.."1"..".wav", range, pitchmodAlt2,volume) end)
			//timer.Simple(0.071,function() target:EmitSound(voiceprefix.."1"..".wav", range, pitchmodAlt) end)
			//timer.Simple(0.03,function() target:EmitSound(voiceprefix.."1"..".wav", range, pitchmodAlt) end)
			//timer.Simple(0.035,function() target:EmitSound(voiceprefix.."1"..".wav", range, pitchmodAlt) end)
			//timer.Simple(0.1,function() target:EmitSound(voiceprefix.."1"..".wav", range, pitchmodAlt) end)
			//timer.Simple(1,function() target:EmitSound("walkieend1.wav") end)
		else
			//print(voiceprefix..whichnoise..".wav")
			target:EmitSound(voiceprefix..whichnoise..".wav", range, pitchmod,0.2)
			timer.Simple(0.3,function() target:EmitSound("extendedradio/walkieend1.wav",range,110 - 20*distFrac, 0.3) end)
		end
	end

end	

function endChatter(listener, distance)

	local volume
	if (distance != 0) then
		volume = 0.3
	else
		volume = 0.1
	end
	
	if ix.config.Get("radioSounds",true) then
		local maxRange = ix.config.Get("chatRange",280) * ix.config.Get("radioRangeMult", 75)
		local distFrac = math.min(1, (distance/maxRange)^2)
		if (!ix.config.Get("garbleRadio",true)) then
			distFrac = 0
		end
		
		local pickOne = {"npc/metropolice/vo/off","npc/combine_soldier/vo/off"}
			if (distFrac <= 0.33) then 
				prefix = pickOne[1]
			elseif (0.33 < distFrac and distFrac <= 0.66) then 
				prefix = pickOne[math.random(#pickOne)]
			elseif (0.66 < distFrac) then
				prefix = pickOne[2]
			end
		
		local range = ix.config.Get("chatRange",280) -- math.random(ix.config.Get("chatRange",280), (1.5)*ix.config.Get("chatRange",280))
		listener:EmitSound("extendedradio/walkiestart1.wav",range,100 - 20*distFrac, volume)
		timer.Simple(1, function()
			if (!listener:IsValid() or !listener:Alive()) then
				return false
			end
			
			playSound(listener,prefix,false,distance)
		end)
	end
end

function mangleString(str, pct)
	local limit = pct/100
	local last
	return (string.gsub(str, ".", function(c)
		if not c:match("%W") and math.random() < limit*((last and 3 or c:match("[AEIOUaeiou]")) and 1.5 or 0.5) then
			last = true
			return "-"
		end
		last = false
	end))
end

function isOutdoors(target)
	local tr = util.TraceLine( util.GetPlayerTrace(target,target:GetUp()) )
	
	return tr.HitSky
end

-- Checks a player's inventory to see if their active radio is set to silent, and plays/doesn't play the appropriate sounds
function radioSilence(target, dist, frequency)
	local inventory = target:GetCharacter():GetInventory()
	local radios = inventory:GetItemsByUniqueID("handheld_radio", true)
	local longranges = inventory:GetItemsByUniqueID("longrange", true)
	-- Puts the long ranges in with regular radios
	if (#longranges > 0) then
		for k,v in pairs(longranges) do radios[#radios+1] = v end
	end

	for k, v in pairs(radios) do
		if (v:GetData("enabled", false) and !v:GetData("silenced",false) and (v:GetData("frequency") == frequency)) then
			endChatter(target,dist)
			break -- Play sound once
		end
	end
end

function PLUGIN:MessageReceived()
	
end

function PLUGIN:OverwriteClasses()
	-- 
	-- Re-registers & overwrites the existing "radio" chat type
	--
	do
		local CLASS = {}
		CLASS.color = ix.config.Get("radioColor",Color(164,224,91)) -- Old: Color(75, 150, 50)
		CLASS.format = "%s radios in: \"%s\""
		CLASS.mult = 0 -- Percent multiplier to garbling fraction
		
		function CLASS:GetColor(speaker, text)
			local color = ix.config.Get("radioColor",Color(164,224,91))
			local lcolor = ix.config.Get("longRangeColor", Color(255,139,82))
			
			if speaker then
				return lcolor
			else
				return color
			end
		end
		
		-- Accessor functions just in case something changes, and for later use in aliased chat class
		-- Maybe unnecessary? The GetColor() one seemed useful...
		function CLASS:GetRange()
			local range = ix.config.Get("chatRange", 280)

			return range
		end
		
		function CLASS:GetFormat()
			local form = self.format

			return form
		end
		
		function CLASS:GetMult()
			local mul = self.mult

			return mul
		end


		function CLASS:CanHear(speaker, listener)
			--local chatRange = ix.config.Get("chatRange",280)
			local character = listener:GetCharacter()
			local inventory = character:GetInventory()
			local bHasRadio = false
			
			local radios = inventory:GetItemsByUniqueID("handheld_radio", true)
			local longranges = inventory:GetItemsByUniqueID("longrange", true)
			-- Puts the long ranges in with regular radios
			if (#longranges > 0) then
				for k,v in pairs(longranges) do radios[#radios+1] = v end
			end
			
			
			-- Character-level frequency/channel handling
			local testA = speaker:GetCharacter():GetData("frequency") == character:GetData("frequency")
			local testB = speaker:GetCharacter():GetData("channel") == character:GetData("channel")
			local test1 = (testA and testB)
			--print(test1)
			
			if (listener:GetPos():Distance(speaker:GetPos()) > self:GetRange()) then
				for k, v in pairs(radios) do
					
					-- Item-level frequency/channel handling
					local testC = speaker:GetCharacter():GetData("frequency") == v:GetData("frequency")
					local testD = speaker:GetCharacter():GetData("channel") == v:GetData("channel")
					local test2 = (testC and testD)
					
					if ( v:GetData("enabled", false) and (test1 or test2) ) then
						bHasRadio = true
						break
					end
				end
			end
			
			if (bHasRadio and (speaker != listener)) then 
				radioSilence(listener, (1 - self:GetMult()) * listener:GetPos():Distance(speaker:GetPos()), speaker:GetCharacter():GetData("frequency"))
			end
			
			return bHasRadio
		end

		function CLASS:OnChatAdd(speaker, text, bAnonymous, data)
		
			local maxRadioRange = ix.config.Get("chatRange",280) * ix.config.Get("radioRangeMult",100)
			local dist = (1 - self:GetMult()) * LocalPlayer():GetPos():Distance(speaker:GetPos())
			--frac = 100*math.min(1, (dist / maxRadioRange )^2) -- Inverse square law
			
			-- Garbling fraction calculation, after distance modifiers
			if (data.lrange) then -- Long range radio handling
				maxRadioRange = maxRadioRange * ix.config.Get("longrangeMult",2)
			end
			local normDist = math.min(1, (dist / maxRadioRange))
			
			-- Random garbling
			local maxScaleGarbleFrac = 60 -- Maximum percent garbling at maximum radio distance
			local maxRandomGarble = 10
			
			local sign = {-1,1}
			local rGarble = sign[math.random(#sign)] * ( maxRandomGarble*math.random()) * (0.5*( normDist + normDist^8 ))
			--print(rGarble)
			if (normDist == 1) then
				rGarble = math.random(1,100-maxScaleGarbleFrac)
			end
			
			--frac = 100*math.min(1, normDist^2) -- Inverse square law
			frac = math.max(0, rGarble + (maxScaleGarbleFrac * (0.5*( normDist + normDist^8 )) )) -- Me own function
			
			-- Indoor handling
			local minPenalty = 3
			local indoorPenalty = 10 -- Will be max of indoorPenalty percent harder to understand when inside
			if !isOutdoors(speaker) then
				frac = math.min(100, frac + (minPenalty + indoorPenalty*math.random()))
			end
			if ( (speaker != LocalPlayer()) and !isOutdoors(LocalPlayer()) ) then
				frac = math.min(100, frac + (minPenalty + indoorPenalty*math.random()))
			end
			
			-- Percentage reduction in garbling based on line of sight (LOS)
			-- If you can see your recipient you should be able to hear their transmission
			local losFrac = 0.5 -- Worst case, message is 50% garbled (transmitting past max distance)
			if speaker:IsLineOfSightClear(LocalPlayer()) then
				frac = frac * losFrac
			end
			
			--print(frac)
			
			--print(frac)
			if (ix.config.Get("garbleRadio",true)) then text = mangleString(text, frac) else text = text end
			
			-- Callsign handling
			if ((ix.config.Get("enableCallsigns",true)) and (data.callsign) and (data.callsign != "")) then
				name = data.callsign
			else
				name = speaker:Name()
			end
			--
			
			local theFreq = string.format("[%s *MHz*] ", data.freq) -- LocalPlayer():GetCharacter():GetData("frequency"))
			local theChan = string.format("[*CH%s*] ", data.chan)

			local newColor = self:GetColor()
			local newFreqColor
			local newChanColor
			if data.lrange then
				newColor = self:GetColor(true) -- New LR chat color
				--newFreqColor = ix.config.Get("activeFreqColor",Color(255,255,255)) -- New LR freq color
			end
			
			if (data.freq == LocalPlayer():GetCharacter():GetData("frequency","100.0")) then
				newFreqColor = ix.config.Get("activeFreqColor",Color(255,255,255)) -- New LR freq color
			else
				newFreqColor = ix.config.Get("radioFreqColor",Color(190,190,190))
			end
			if (data.chan == LocalPlayer():GetCharacter():GetData("channel","1")) then
				newChanColor = ix.config.Get("activeFreqColor",Color(255,255,255)) -- New LR freq color
			else
				newChanColor = ix.config.Get("radioFreqColor",Color(190,190,190))
			end
			
			-- Sound handling
			--radioSilence(LocalPlayer(), dist, data.freq)
			--
			
			local character = LocalPlayer():GetCharacter()
			local inventory = character:GetInventory()
			local radios = inventory:GetItemsByUniqueID("handheld_radio", true)
			local longranges = inventory:GetItemsByUniqueID("longrange", true)
			-- Puts the long ranges in with regular radios
			if (#longranges > 0) then
				for k,v in pairs(longranges) do radios[#radios+1] = v end
			end
			
			local tally = 0
			local freqList = {}
			for k,v in pairs(radios) do
				if (v:GetData("enabled", false)) then
					freqList[tally] = v:GetData("frequency","100.0")
					if (tally > 0 and (freqList[tally] != freqList[tally-1])) then
						tally = -1
						break
					end
					tally = tally + 1
				end
			end

			-- If you have more than one radio, and they're on different frequencies, show the frequency next to the name
			-- Otherwise just show channel
			if (tally == -1) then
				chat.AddText(newFreqColor, theFreq, newChanColor, theChan, newColor, string.format(self:GetFormat(), name, text))
			else
				chat.AddText(newChanColor, theChan, newColor, string.format(self:GetFormat(), name, text))
			end
		end

		ix.chat.Register("radio", CLASS)
	end

	--- 2ND ONE FOR YELLING
	do
		
		-- Populates the class with the info from the radio class WITHOUT overwriting the original class
		local ALIAS
		ALIAS = {}
        for orig_key, orig_value in pairs(ix.chat.classes.radio) do
            ALIAS[orig_key] = orig_value
        end
		
		local CLASS = ALIAS
		
		CLASS.color = ix.config.Get("radioYellColor",Color(164+30,224+30,91+30)) -- Old: Color(75, 150, 50)
		CLASS.format = "%s yells in the radio: \"%s\""
		CLASS.mult = 0.15
	
		function CLASS:GetColor(speaker, text)
			local color = ix.config.Get("radioColor",Color(164,224,91))
			local lcolor = ix.config.Get("longRangeColor", Color(255,139,82))
			
			if speaker then
				color = lcolor
			end
			
			-- Make the yell chat slightly brighter than IC chat.
			return Color(color.r + 35, color.g + 35, color.b + 35)
		end
		
		function CLASS:GetRange()
			local range = ix.config.Get("chatRange", 280) * 2 -- Yelling is twice as far

			return range
		end
		
		CLASS.uniqueID = "radio_yell" -- Just to be sure that particular key is overwritten properly
		ix.chat.Register("radio_yell", CLASS)
	end
	-- LAST ONE FOR WHISPERING
		do
		
		-- Populates the class with the info from the radio class WITHOUT overwriting the original class
		local ALIAS
		ALIAS = {}
        for orig_key, orig_value in pairs(ix.chat.classes.radio) do
            ALIAS[orig_key] = orig_value
        end
		
		local CLASS = ALIAS
		
		CLASS.color = ix.config.Get("radioColor",Color(164-35,224-35,91-35)) -- Old: Color(75, 150, 50)
		CLASS.format = "%s whispers in the radio: \"%s\""
		CLASS.mult = -0.3
	
		function CLASS:GetColor(speaker, text)
			local color = ix.config.Get("radioColor",Color(164,224,91))
			local lcolor = ix.config.Get("longRangeColor", Color(255,139,82))
			
			if speaker then
				color = lcolor
			end
			
			-- Make the whisper chat slightly dimmer than IC chat.
			return Color(color.r - 35, color.g - 35, color.b - 35)
		end
		
		function CLASS:GetRange()
			local range = ix.config.Get("chatRange", 280) * 0.25 -- Whispering is 0.25 times as far

			return range
		end
		
		CLASS.uniqueID = "radio_whisper" -- Just to be sure that particular key is overwritten properly
		ix.chat.Register("radio_whisper", CLASS)
	end
	------------------------------------------------
	do
		local CLASS = {}
		CLASS.color = ix.config.Get("chatColor") -- ix.chat.classes.ic.color Color(255, 255, 175)
		CLASS.format = "%s radios in: \"%s\""

		function CLASS:GetColor(speaker, text)
			local color = ix.config.Get("chatColor")
			
			--if (LocalPlayer():GetEyeTrace().Entity == speaker) then
			--	return Color(175, 255, 175)
			--end

			return color
		end
		
		function CLASS:GetRange()
			local range = ix.config.Get("chatRange", 280)

			return range
		end

		function CLASS:CanHear(speaker, listener)
	
			-- if (ix.chat.classes.radio:CanHear(speaker, listener)) then
				-- return false
			-- end

			return (listener:GetPos():Distance(speaker:GetPos()) <= (self:GetRange()))
		end

		function CLASS:OnChatAdd(speaker, text, bAnonymous, data)
			-- text = string.format("<:: %s ::>", text)
			local dist = LocalPlayer():GetPos():Distance(speaker:GetPos())
				
			-- Sending sound handling
			if !data.quiet then playSound(speaker, "npc/metropolice/vo/on", true) end
			
			chat.AddText(self:GetColor(speaker,text), string.format(self.format, speaker:Name(), text))
		end

		ix.chat.Register("radio_eavesdrop", CLASS)
	end
	
	do
	
		-- Populates the class with the info from the radio eavesdrop class WITHOUT overwriting the original class
		local ALIAS
		ALIAS = {}
        for orig_key, orig_value in pairs(ix.chat.classes.radio_eavesdrop) do
            ALIAS[orig_key] = orig_value
        end
		
		local CLASS = ALIAS
	
		--local CLASS = {}
		CLASS.color = ix.config.Get("chatColor")
		CLASS.format = "%s yells in the radio: \"%s\""

		function CLASS:GetColor(speaker, text)
			local color = ix.config.Get("chatColor")
			
			-- Make the yell chat slightly brighter than IC chat.
			return Color(color.r + 35, color.g + 35, color.b + 35)
		end
		
		function CLASS:GetRange()
			local range = ix.config.Get("chatRange", 280)

			return range
		end

		-- function CLASS:CanHear(speaker, listener)
			-- if (ix.chat.classes.radio_yell:CanHear(speaker, listener)) then
				-- return false
			-- end

			-- local chatRange = ix.config.Get("chatRange", 280)
			
			-- return (listener:GetPos():Distance(speaker:GetPos()) <= (2*chatRange))
		-- end

		-- function CLASS:OnChatAdd(speaker, text, bAnonymous, data)
			-- local yellMult = 0.25 -- Treats a yelling person on the radio at yellMult percent closer to listener
			-- local dist = (1 - yellMult) * LocalPlayer():GetPos():Distance(speaker:GetPos())
			-- -- text = string.format("<:: %s ::>", text)
			-- --endChatter(speaker,dist)
			
			-- -- Sound handling
			-- if !data.quiet then playSound(speaker, "npc/metropolice/vo/on", true) end
			
			-- chat.AddText(self:GetColor(speaker,text), string.format(self.format, speaker:Name(), text))
		-- end

		CLASS.uniqueID = "radio_eavesdrop_yell" -- to be sure
		ix.chat.Register("radio_eavesdrop_yell", CLASS)
	end
	
		do
	
		-- Populates the class with the info from the radio eavesdrop class WITHOUT overwriting the original class
		local ALIAS
		ALIAS = {}
        for orig_key, orig_value in pairs(ix.chat.classes.radio_eavesdrop) do
            ALIAS[orig_key] = orig_value
        end
		
		local CLASS = ALIAS
	
		--local CLASS = {}
		CLASS.color = ix.config.Get("chatColor")
		CLASS.format = "%s whispers in the radio: \"%s\""

		function CLASS:GetColor(speaker, text)
			local color = ix.config.Get("chatColor")
			
			-- Make the whisper chat slightly dimmer than IC chat.
			return Color(color.r - 35, color.g - 35, color.b - 35)
		end
		
		function CLASS:GetRange()
			local range = 0.25*ix.config.Get("chatRange", 280)

			return range
		end

		-- function CLASS:CanHear(speaker, listener)
			-- if (ix.chat.classes.radio_yell:CanHear(speaker, listener)) then
				-- return false
			-- end

			-- local chatRange = ix.config.Get("chatRange", 280)
			
			-- return (listener:GetPos():Distance(speaker:GetPos()) <= (2*chatRange))
		-- end

		-- function CLASS:OnChatAdd(speaker, text, bAnonymous, data)
			-- local yellMult = 0.25 -- Treats a yelling person on the radio at yellMult percent closer to listener
			-- local dist = (1 - yellMult) * LocalPlayer():GetPos():Distance(speaker:GetPos())
			-- -- text = string.format("<:: %s ::>", text)
			-- --endChatter(speaker,dist)
			
			-- -- Sound handling
			-- if !data.quiet then playSound(speaker, "npc/metropolice/vo/on", true) end
			
			-- chat.AddText(self:GetColor(speaker,text), string.format(self.format, speaker:Name(), text))
		-- end

		CLASS.uniqueID = "radio_eavesdrop_whisper" -- to be sure
		ix.chat.Register("radio_eavesdrop_whisper", CLASS)
	end

	-- 
	-- Overwrites the existing "/radio" chat command with new functionality
	--
	do
		local COMMAND = {}
		COMMAND.arguments = ix.type.text
		
		COMMAND.alias = {"r"} -- NEW

		function COMMAND:OnRun(client, message)
			local character = client:GetCharacter()
			local radios = character:GetInventory():GetItemsByUniqueID("handheld_radio", true)
			local longranges = character:GetInventory():GetItemsByUniqueID("longrange", true)
			-- Puts the long ranges in with regular radios
			if (#longranges > 0) then
				for k,v in pairs(longranges) do radios[#radios+1] = v end
			end
			
			local transmitLong = false
			local item
			
			-- Callsign handling
			local call
			local defCall
			local names = {"Somebody", "Someone", "A voice", "A person"}
			if (ix.config.Get("defaultCallsign") == 1) then
				defCall = client:Name()
			else
				defCall = names[math.random(#names)]
			end
			
			if ix.config.Get("enableCallsigns",true) then
				call = character:GetData("callsign",defCall)
			else
				call = client:Name()
			end

			local enabl = false
			for k, v in ipairs(radios) do
				if (v:GetData("enabled", false)) then
					enabl = true
					if (v:GetData("active")) then
						item = v
						transmitLong = (v.uniqueID == "longrange")
						break
					end
				end
			end

			if (item) then
				if (!client:IsRestricted()) then
					ix.chat.Send(client, "radio", message,nil,nil,{callsign=call, lrange=transmitLong, freq=client:GetCharacter():GetData("frequency"), chan=client:GetCharacter():GetData("channel")})
					ix.chat.Send(client, "radio_eavesdrop", message,nil,nil,{quiet=item:GetData("silenced")})
					--endChatter(client,0)
					--playSound(client, "npc/metropolice/vo/on", true)
				else
					return "@notNow"
				end
			elseif (#radios > 0 and enabl and (!client:GetCharacter():GetData("frequency") or client:GetCharacter():GetData("frequency") == "")) then
				client:Notify("You do not have an active radio.")
			elseif (#radios > 0 and !enabl) then
				return "@radioNotOn"
			else
				return "@radioRequired"
			end
		end

		ix.command.Add("Radio", COMMAND)
	end

	-- 
	-- Overwrites the existing "/radio" chat command with new functionality
	--
	do
		local COMMAND = {}
		COMMAND.arguments = ix.type.text
		
		COMMAND.alias = {"ry"} -- NEW
		
		function COMMAND:OnRun(client, message)
			local character = client:GetCharacter()
			local radios = character:GetInventory():GetItemsByUniqueID("handheld_radio", true)
			local longranges = character:GetInventory():GetItemsByUniqueID("longrange", true)
			-- Puts the long ranges in with regular radios
			if (#longranges > 0) then
				for k,v in pairs(longranges) do radios[#radios+1] = v end
			end
			
			local transmitLong = false
			local item
			
			-- Callsign handling
			local call
			local defCall
			local names = {"Somebody", "Someone", "A voice", "A person"}
			if (ix.config.Get("defaultCallsign") == 1) then
				defCall = client:Name()
			else
				defCall = names[math.random(#names)]
			end
			
			if ix.config.Get("enableCallsigns",true) then
				call = character:GetData("callsign",defCall)
			else
				call = client:Name()
			end

			local enabl = false
			for k, v in ipairs(radios) do
				if (v:GetData("enabled", false)) then
					enabl = true
					if (v:GetData("active")) then
						item = v
						transmitLong = (v.uniqueID == "longrange")
						break
					end
				end
			end

			if (item) then
				if (!client:IsRestricted()) then
					ix.chat.Send(client, "radio_yell", message,nil,nil,{callsign=call, lrange=transmitLong, freq=client:GetCharacter():GetData("frequency"), chan=client:GetCharacter():GetData("channel")})
					ix.chat.Send(client, "radio_eavesdrop_yell", message,nil,nil,{quiet=item:GetData("silenced")})
					--endChatter(client,0)
					--playSound(client, "npc/metropolice/vo/on", true)
				else
					return "@notNow"
				end
			elseif (#radios > 0 and enabl and (!client:GetCharacter():GetData("frequency") or client:GetCharacter():GetData("frequency") == "")) then
				client:Notify("You do not have an active radio.")
			elseif (#radios > 0 and !enabl) then
				return "@radioNotOn"
			else
				return "@radioRequired"
			end
		end

		ix.command.Add("RadioYell", COMMAND)
	end
	-----
	do
		local COMMAND = {}
		COMMAND.arguments = ix.type.text
		
		COMMAND.alias = {"rw"} -- NEW
		
		function COMMAND:OnRun(client, message)
			local character = client:GetCharacter()
			local radios = character:GetInventory():GetItemsByUniqueID("handheld_radio", true)
			local longranges = character:GetInventory():GetItemsByUniqueID("longrange", true)
			-- Puts the long ranges in with regular radios
			if (#longranges > 0) then
				for k,v in pairs(longranges) do radios[#radios+1] = v end
			end
			
			local transmitLong = false
			local item
			
			-- Callsign handling
			local call
			local defCall
			local names = {"Somebody", "Someone", "A voice", "A person"}
			if (ix.config.Get("defaultCallsign") == 1) then
				defCall = client:Name()
			else
				defCall = names[math.random(#names)]
			end
			
			if ix.config.Get("enableCallsigns",true) then
				call = character:GetData("callsign",defCall)
			else
				call = client:Name()
			end

			local enabl = false
			for k, v in ipairs(radios) do
				if (v:GetData("enabled", false)) then
					enabl = true
					if (v:GetData("active")) then
						item = v
						transmitLong = (v.uniqueID == "longrange")
						break
					end
				end
			end

			if (item) then
				if (!client:IsRestricted()) then
					ix.chat.Send(client, "radio_whisper", message,nil,nil,{callsign=call, lrange=transmitLong, freq=client:GetCharacter():GetData("frequency"), chan=client:GetCharacter():GetData("channel")})
					ix.chat.Send(client, "radio_eavesdrop_whisper", message,nil,nil,{quiet=item:GetData("silenced")})
					--endChatter(client,0)
					--playSound(client, "npc/metropolice/vo/on", true)
				else
					return "@notNow"
				end
			elseif (#radios > 0 and enabl and (!client:GetCharacter():GetData("frequency") or client:GetCharacter():GetData("frequency") == "")) then
				client:Notify("You do not have an active radio.")
			elseif (#radios > 0 and !enabl) then
				return "@radioNotOn"
			else
				return "@radioRequired"
			end
		end

		ix.command.Add("RadioWhisper", COMMAND)
	end

	-----
	do
		local COMMAND = {}
		COMMAND.arguments = ix.type.number

		function COMMAND:TableLength(T)
			local count = 0
			for _ in pairs(T) do count = count + 1 end
			return count
		end
		
		function COMMAND:OnRun(client, frequency)
			if string.len(frequency) < 4 then
				frequency = frequency .. '.0'
			end
			local character = client:GetCharacter()
			local inventory = character:GetInventory()
			--local itemTable = inventory:GetItemsByUniqueID("handheld_radio", true)

			local radios = inventory:GetItemsByUniqueID("handheld_radio", true)
			local longranges = inventory:GetItemsByUniqueID("longrange", true)
			-- Puts the long ranges in with regular radios
			if (#longranges > 0) then
				for k,v in pairs(longranges) do radios[#radios+1] = v end
			end
			
			local active = 0
			-- print(self:TableLength(itemTable))
			-- PrintTable(itemTable)
			
			local itemTable
			local numEnabled = 0
			if (self:TableLength(radios) < 1) then
				client:Notify("You do not have a radio!")
			else
				for k, v in ipairs(radios) do
					if (v:GetData("enabled", false)) then
						itemTable = v
						numEnabled = numEnabled + 1
						if (v:GetData("active")) then
							active = 1
							break
						end
					end
				end

				if (active == 1) then
					if string.find(frequency, "^%d%d%d%.%d$") then
						character:SetData("frequency", frequency)
						character:SetData("channel", itemTable:GetData("channel","1"))
						itemTable:SetData("frequency", frequency)

						client:Notify(string.format("You have set your radio frequency to %s.", frequency))
					end
				elseif (itemTable and (numEnabled == 1) and (active == 0)) then
					if string.find(frequency, "^%d%d%d%.%d$") then
						character:SetData("frequency", frequency)
						character:SetData("channel", itemTable:GetData("channel","1"))						
						itemTable:SetData("active", true)
						itemTable:SetData("frequency", frequency)

						client:Notify(string.format("You have set your radio frequency to %s.", frequency))
					end
				elseif (numEnabled > 1) then
					client:Notify("Activate one of your radios to set the frequency.")
					-- for k, v in ipairs(radios) do
						-- if (v:GetData("enabled", false)) then
						
							-- if (string.find(frequency, "^%d%d%d%.%d$")) then
								-- v:SetData("frequency",frequency)
								-- if (active < 1) then 
									-- client:Notify(string.format("You have set your radio frequency to %s.", frequency))
								-- end
								-- active = active+1
							-- end
							
						-- end
					-- end
					
					-- if (active < 1) then 
						-- client:Notify("None of your radios are turned on.")
					-- end
				end
			end
		end

		ix.command.Add("SetFreq", COMMAND)
	end

	--
	
	do
		local COMMAND = {}
		COMMAND.arguments = ix.type.text

		function COMMAND:TableLength(T)
			local count = 0
			for _ in pairs(T) do count = count + 1 end
			return count
		end
		
		function COMMAND:OnRun(client, chan)
		
			-- Valid channel handling
			local validchan = false
			for _,v in pairs({"1","2","3","4"}) do
				if (chan == v) then
					validchan = true
					break
				end
			end
			if !validchan then
				client:Notify("Invalid channel specification.")
				return
			end

			local character = client:GetCharacter()
			local inventory = character:GetInventory()
			local radios = inventory:GetItemsByUniqueID("handheld_radio", true)
			local longranges = inventory:GetItemsByUniqueID("longrange", true)
			-- Puts the long ranges in with regular radios
			if (#longranges > 0) then
				for k,v in pairs(longranges) do radios[#radios+1] = v end
			end
			
			--local active = false
			
			local itemTable
			if (self:TableLength(radios) < 1) then
				client:Notify("You do not have a radio!")
			else
				for k, v in ipairs(radios) do
					if (v:GetData("enabled", false) and v:GetData("active")) then
						itemTable = v
						--active = true
						break
					end
				end
						
				if itemTable then
					character:SetData("channel", chan)
					
					itemTable:SetData("channel", chan)

					client:Notify(string.format("You have set your radio channel to %s.", chan))
				else
					client:Notify("You do not have an active radio.")
				end
			end
		end

		ix.command.Add("SetChan", COMMAND)
	end
	
	--

	do
		local COMMAND = {}
		COMMAND.adminOnly = true
		COMMAND.arguments = {
			ix.type.character,
			ix.type.text
		}

		function COMMAND:OnRun(client, target, callsign)
			local call
			if (callsign == "") then 
				call = nil
			else
				call = string.format("*%s*",callsign)
			end

			if (ix.config.Get("enableCallsigns")) then
				target:SetData("callsign",call)
				client:Notify(string.format("You have set %s's callsign to %s",target:GetName(),callsign))
				target:GetPlayer():Notify(string.format("Your callsign has been set to %s by %s",callsign,client:Name()))
			else
				client:Notify("Callsigns are currently disabled!")
			end
		end

		ix.command.Add("SetCallsign", COMMAND)
	end
	
end -- For PLUGIN:OverwriteClasses()

	-- creates labels in the status screen
function PLUGIN:CreateCharacterInfo(panel)
	local test = (LocalPlayer():GetCharacter():GetData("callsign") == nil)
	
	if (!test and ix.config.Get("enableCallsigns")) then
		panel.callsign = panel:Add("ixListRow")
		panel.callsign:SetList(panel.list)
		panel.callsign:Dock(BOTTOM)
		panel.callsign:DockMargin(0, 0, 0, 8)
	elseif (!ix.config.Get("enableCallsigns") and IsValid(panel.callsign)) then
		panel.callsign:Remove()
	end
end

-- populates labels in the status screen
function PLUGIN:UpdateCharacterInfo(panel)
	local test = (LocalPlayer():GetCharacter():GetData("callsign") == nil)
	
	if (!test and ix.config.Get("enableCallsigns")) then
		panel.callsign:SetLabelText("Callsign")
		panel.callsign:SetText(LocalPlayer():GetCharacter():GetData("callsign"):sub(2,-2))
		panel.callsign:SizeToContents()
	elseif (!ix.config.Get("enableCallsigns") and IsValid(panel.callsign)) then
		panel.callsign:Remove()
	end
end


function PLUGIN:InitializedChatClasses() -- Initial registration on start-up
	self:OverwriteClasses()
end

function PLUGIN:InitializedPlugins() -- Should handle any lua refreshing since start-up
	self:OverwriteClasses()
end
