
local PLUGIN = PLUGIN

PLUGIN.name = "Extended Radio"
PLUGIN.author = "faust"
PLUGIN.description = "A standalone radio plugin with extended functionality over the default."

ix.util.Include("thirdparty/sh_netstream2.lua")

-- Anonymous names, if radio callsigns are anonymous
local radioanon = {"Somebody", "Someone", "A voice", "A person"}
local radioTypes = {"walkietalkie","longrange","duplexradio","duplexwalkie","hybridradio","hybridwalkie"}

-- Serverside voice handling
-- If you care about applying the "rules" of the radio to voice chat, enable this
-- Otherwise, keep it disabled for performance reasons (this is called 3 times per tick)
-- function PLUGIN:PlayerCanHearPlayersVoice(listener,talker)
	-- return ( (listener:GetCharacter():GetData("frequency","100.0") == talker:GetCharacter():GetData("frequency","100.0")) and (listener:GetCharacter():GetData("channel","1") == talker:GetCharacter():GetData("channel","1")))
-- end

function numTraces(t1,t2, stFrac, incrementFrac)
	local hits = 0
	local st,en = t1:GetPos(),t2:GetPos()

	local curTrace
	local frac = 1
	local retFrac = stFrac
	local increFrac = (incrementFrac / 100) --0.005
	--local endPos = Vector(0,0,0)
	local holder = {}
	local data = {}
		data.start = st
		data.endpos = en
		data.filter = {t1}
		data.mask = MASK_ALL
		--data.collisiongroup = 20
		--data.output = holder

	local curHit
	local multiplier = 64
	local tries,maxTries = 0,100
	while curHit != data.endpos do
		--print(data.start)
		tries = tries+1
		curTrace = util.TraceLine(data)
		curHit = curTrace.HitPos
		if data.start == curHit then
			data.start = data.start + ( multiplier*curTrace.Normal )
		else
			data.start = curHit
			--hits = hits+1
		end
		hits = hits+1
		frac = frac + increFrac
		retFrac = retFrac*frac
		--hits = hits+1
		if tries >= maxTries then
			retFrac = stFrac * (1 + stFrac*math.random())
			break
		end
	end
	--print("hits: ",hits)
	return retFrac
end

-- Clientside hooks
if (CLIENT) then

	-- Channel handling
	local function setTheChannel(ch)
		ix.command.Send("SetChan", ch)
	end

	-- Channel renaming
	local function setTheName(ch,nm)
		ix.command.Send("ChanRename", ch..","..nm)
	end

	netstream.Hook("Channel", function(names)

		local dispNames = {1,2,3,4}
		for k=1,4 do
			if names[k] != "CH"..k then
				dispNames[k] = "("..k..") "..names[k]
			else
				dispNames[k] = "CH"..k
			end
		end

		local quer = Derma_Query("Left click to choose your channel\nRight click to rename the channel", "Channel selection",
		dispNames[1], function()
			setTheChannel("1")
		end,
		dispNames[2], function()
			setTheChannel("2")
		end,
		dispNames[3], function()
			setTheChannel("3")
		end,
		dispNames[4], function()
			setTheChannel("4")
		end)

		-- Overwriting functionality
		local ch1panel = quer:GetChildren()[6]:GetChildren()[1]
		function ch1panel:DoRightClick()
			Derma_StringRequest("Channel Name", "What would you like the new name to be?\nEnter a space to reset channel name to default", names[1], function(text)
				if text == " " then
					setTheName("1","CH1")
				else
					setTheName("1",text)
				end
				quer:Close()
			end)
		end
		local ch2panel = quer:GetChildren()[6]:GetChildren()[2]
		function ch2panel:DoRightClick()
			Derma_StringRequest("Channel Name", "What would you like the new name to be?\nEnter a space to reset channel name to default", names[2], function(text)
				if text == " " then
					setTheName("2","CH2")
				else
					setTheName("2",text)
				end
				quer:Close()
			end)
		end
		local ch3panel = quer:GetChildren()[6]:GetChildren()[3]
		function ch3panel:DoRightClick()
			Derma_StringRequest("Channel Name", "What would you like the new name to be?\nEnter a space to reset channel name to default", names[3], function(text)
				if text == " " then
					setTheName("3","CH3")
				else
					setTheName("3",text)
				end
				quer:Close()
			end)
		end
		local ch4panel = quer:GetChildren()[6]:GetChildren()[4]
		function ch4panel:DoRightClick()
			Derma_StringRequest("Channel Name", "What would you like the new name to be?\nEnter a space to reset channel name to default", names[4], function(text)
				if text == " " then
					setTheName("4","CH4")
				else
					setTheName("4",text)
				end
				quer:Close()
			end)
		end
		--:GetText())
	end)

	-- netstream.Hook("ChannelRename", function(names)
		-- Derma_Query("Choose channel to rename", "Channel renaming",
		-- names[1], function()
			-- Derma_StringRequest("Channel Name", "What would you like the new name to be?", names[1], function(text)
				-- setTheName("1",text)
			-- end)
		-- end,
		-- names[2], function()
			-- Derma_StringRequest("Channel Name", "What would you like the new name to be?", names[2], function(text)
				-- setTheName("2",text)
			-- end)
		-- end,
		-- names[3], function()
			-- Derma_StringRequest("Channel Name", "What would you like the new name to be?", names[3], function(text)
				-- setTheName("3",text)
			-- end)
		-- end,
		-- names[4], function()
			-- Derma_StringRequest("Channel Name", "What would you like the new name to be?", names[4], function(text)
				-- setTheName("4",text)
			-- end)
		-- end)
	-- end)

	-- Frequency handling
	netstream.Hook("Frequency", function(oldFrequency)
		Derma_StringRequest("Frequency", "What would you like to set the frequency to?", oldFrequency, function(text)
			ix.command.Send("SetFreq", text)
		end)
	end)

	-- Duplex frequency handling
	netstream.Hook("FrequencyMenu", function(oldFreqs)
		--local theEntity = LocalPlayer():GetEyeTrace().Entity

		--if theEntity:GetClass() == "ix_radiorepeater" then

		local oldTransmit = oldFreqs[1]
		local oldListen = oldFreqs[2]

		Derma_Query("Choose operation to perform", "Duplex Frequency Control",
		"Change Transmitting Frequency ("..oldTransmit.." MHz)",function()
			Derma_StringRequest("Frequency", "Current transmitting frequency: "..oldTransmit.." MHz".."\nWhat would you like to set the new frequency to?", oldTransmit, function(text)
			--repeater("I"..text)
			ix.command.Send("SetFreq", text)
			end)
		end,
		"Change Receiving Frequency ("..oldListen.." MHz)",function()
			Derma_StringRequest("Frequency", "Current receiving frequency: "..oldListen.." MHz".."\nWhat would you like to set the new frequency to?", oldListen, function(text)
			--repeater("O"..text)
			ix.command.Send("SetListenFreq", text)
			end)
		end,
		nil,nil,
		nil,nil)
		--end
	end)

	-- -- Duplex frequency handling
	-- netstream.Hook("DuplexFrequency", function(oldFrequency)
		-- Derma_StringRequest("Receiving Frequency", "What would you like to set the receiving frequency to?", oldFrequency, function(text)
			-- ix.command.Send("SetListenFreq", text)
		-- end)
	-- end)

end

-- Sets up configurations
ix.config.Add("radioColor",Color(164,224,91), "The default color for radio chat.", nil, {category = "Extended Radio"})
--ix.config.Add("radioYellColor",Color(164+30,224+30,91+30), "The default color for yelling in radio chat.", nil, {category = "Extended Radio"})
ix.config.Add("longRangeColor", Color(255,139,82), "The default color for long range radio chat.", nil, {category = "Extended Radio"})
ix.config.Add("walkieTalkieColor", Color(91,182,224), "The default color for walkie talkie radio chat.", nil, {category = "Extended Radio"})
--ix.config.Add("longRangeYellColor",Color(255,139+30,82+30), "The default color for yelling in long range radio chat.", nil, {category = "Extended Radio"})

ix.config.Add("radioFreqColor",Color(175,175,175), "The default color for radio frequencies.", nil, {category = "Extended Radio"})
ix.config.Add("activeFreqColor", Color(245,245,245), "The default color for long range radio frequencies.", nil, {category = "Extended Radio"})

ix.config.Add("radioYellBig", true, "Whether to use larger font sizes for yelling in the radio.", nil, {
	category = "Extended Radio"
})
ix.config.Add("radioWhisperSmall", true, "Whether to use smaller font sizes for whispering in the radio.", nil, {
	category = "Extended Radio"
})

ix.config.Add("radioDecayModel", 3, "The model used to calculate how scrambled radio messages become over distance.\n\n"..
	"(1) Quadratic (x^2)\nGood close range, bad past medium range\n\n"..
	"(2) Logarithmic (x^(1/3) Log10[2]/Log10[2/x])\nWorst overall, but smoothest/most predictable decay\n\n"..
	"(3) Hybrid (0.5(x + x^8))\nWorse close range than quadratic, better long range than logarithmic\n\n"..
	"(4) Lowest (0.5(x^2 + x^9))\nBest overall, with approximately quadratic decay at long range", nil, {
	data = {min = 1, max = 4},
	category = "Extended Radio"
})

-- Max map size in Source is 32768 units, and chat range is default 280 units, so max possible multiplier should be about 120
-- However, radio is garbled as the square of the distance, so the maximum "effective range" is actually (much) less than that
-- To say nothing of modifiers, and different map sizes/configurations...
-- Therefore the max multiplier can go up to 175 (only ~75% garbled at max map distance) although I recommend using a much smaller value
-- Long range radios have a separate multiplier that can be jacked up & people aren't usually talking across the map anyways
ix.config.Add("radioRangeMult", 100, "Max radio range = IC chat range * mult", nil, {
	data = {min = 1, max = 175},
	category = "Extended Radio"
})

ix.config.Add("repeaterMult", 2, "Max repeater range = radio range * mult", nil, {
	data = {min = 1, max = 20},
	category = "Extended Radio"
})

ix.config.Add("longrangeMult", 2, "Max long range radio range = radio range * mult", nil, {
	data = {min = 1, max = 10},
	category = "Extended Radio"
})

ix.config.Add("walkieMult", 0.3, "Max walkie talkie range = radio range * mult\n(always shorter than radio range)", nil, {
	data = {min = 0, max = 1, decimals=1},
	category = "Extended Radio"
})


ix.config.Add("garbleRadio", true, "Whether or not radio chatter is garbled over long distances.", nil, {
	category = "Extended Radio"
})

ix.config.Add("garbleOffset", 0, "Raw plus or minus modifier to the garbling fraction, no matter what.\nIt is almost always a better idea to tweak other settings before this one!", nil, {
	data = {min = -100, max = 100},
	category = "Extended Radio"
})

-- ix.config.Add("garbleMaxFrac", 60, "The maximum scrambling fraction at the maximum radio distance. Lower means less garbling over all distances.", nil, {
	-- data = {min = 0, max = 100},
	-- category = "Extended Radio"
-- })

ix.config.Add("enableCallsigns", true, "Whether or not callsigns are allowed.", nil, {
	category = "Extended Radio"
})

ix.config.Add("anonymousRadioNames", false, "If true, players' names will not show up when using the radio, and"..
	"instead will be replaced with 'Someone', 'Somebody', 'A voice', or 'A person'. "..
	"Callsigns become the only way to uniquely identify anyone on the radio.", nil, {
	--data = {min = 1, max = 2},
	category = "Extended Radio"
})

ix.config.Add("allowBroadcast", true, "Whether or not broadcasting on all channels is allowed for any radio.", nil, {
	--data = {min = 1, max = 2},
	category = "Extended Radio"
})

ix.config.Add("broadcastLevel", 1, "What types of radios can broadcast on all channels\n"..
	"1 = Long range only\n2 = Long ranges & regular radios\n3 = All radios & walkies.", nil, {
	data = {min = 1, max = 3},
	category = "Extended Radio"
})


ix.config.Add("radioSounds", true, "Toggles radio sending/receiving beeps & boops.", nil, {
	category = "Extended Radio"
})

ix.config.Add("radioSoundDistance", 280, "Distance to hear other people's radio beeps.\n"..
	"This is the same as the Helix chat range by default.", nil, {
	data = {min = 140, max = 560},
	category = "Extended Radio"
})

--ix.config.Add("radioOverhear", false, "Toggles being able to see other people's incoming radio messages in the chatbox.", nil, {
--	category = "Extended Radio"
--})

ix.config.Add("hearSelf", false, "Toggles being able to see your own radio calls in the chatbox.", nil, {
	category = "Extended Radio"
})

function playSound(target,voiceprefix,sending,distance,radioType) -- Fun new function to more easily play radio send/receive sounds

	-- local maxRange = ix.config.Get("chatRange",280) * ix.config.Get("radioRangeMult", 100)
	-- local distance = distance or 0
	-- local normDist = math.min(1, (distance/maxRange))
	-- local distFrac = (0.5*( normDist + normDist^8 ))
	-- if (!ix.config.Get("garbleRadio",true)) then
		-- distFrac = 0
	-- end

	-- local range = math.random(ix.config.Get("chatRange",280)-10, ix.config.Get("chatRange",280)+10)
  local soundDist = ix.config.Get("radioSoundDistance",280)
	local range = math.random(soundDist-10, soundDist+10)
	local pitchmod = math.random(110 - 50*distance, 120 - 50*distance) -- Pitch shifts the receive beep with increasing distance
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
			-- Walkie talkie sounds
			if radioType == "walkietalkie" or radioType == "duplexwalkie" or radioType == "hybridwalkie" then
				target:EmitSound("extendedradio/start11.wav",range,100 - 20*distance, 0.5*volume)
				timer.Simple(0.05, function() target:EmitSound("extendedradio/walkiestart1.wav", range, 110, volume) end)
				timer.Simple(0.7, function() target:EmitSound("extendedradio/end11.wav", range, math.random(115,120),volume) end)
			-- Regular radio sounds
			else--if radioType == "duplexradio" or radioType == "handheld_radio" then
				target:EmitSound(voiceprefix.."1"..".wav", range, pitchmodAlt,0.2)
				timer.Simple(0.05, function() target:EmitSound("extendedradio/walkiestart1.wav", range, 110, volume) end)
				timer.Simple(0.7, function() target:EmitSound(voiceprefix.."1"..".wav", range, pitchmodAlt2,volume) end)
				timer.Simple(0.77, function() target:EmitSound(voiceprefix.."1"..".wav", range, pitchmodAlt2,volume) end)
			end
		else
			if radioType == "walkietalkie" or radioType == "duplexwalkie" or radioType == "hybridwalkie" then
				timer.Simple(0.3,function() target:EmitSound("extendedradio/walkieend1.wav",range,110 - 20*distance, 0.3) end)
				timer.Simple(0.1,function() target:EmitSound("extendedradio/end22.wav",range,110 - 20*distance, 0.2) end)
			else--if radioType == "duplexradio" or radioType == "handheld_radio" then
				target:EmitSound(voiceprefix..whichnoise..".wav", range, pitchmod,0.2)
				timer.Simple(0.3,function() target:EmitSound("extendedradio/walkieend1.wav",range,110 - 20*distance, 0.3) end)
			end
		end
	end

end

function endChatter(listener, distance, radioType)

	local volume
	if (distance != 0) then
		volume = 0.3
	else
		volume = 0.1
	end

	if ix.config.Get("radioSounds",true) then
		local maxRange = ix.config.Get("chatRange",280) * ix.config.Get("radioRangeMult", 75)
		local normDist = math.min(1, (distance/maxRange))
		local distFrac = (0.5*( normDist + normDist^8 ))
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
		--local startSound = "extendedradio/walkiestart1.wav"
		--startSound = "extendedradio/start11.wav"

		listener:EmitSound("extendedradio/walkiestart1.wav",range,100 - 20*distFrac, volume)
		--listener:EmitSound(startSound,range,100 - 20*distFrac, 0.5*volume)
		timer.Simple(1, function()
			if (!listener:IsValid() or !listener:Alive()) then
				return false
			end
			playSound(listener,prefix,false,distFrac,radioType)
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
-- function radioSilence(target, dist, frequency)
	-- local character = target:GetCharacter()
	-- local inventory = character:GetInventory()

	-- local radios = inventory:GetItemsByUniqueID("handheld_radio", true)
	-- --local radioTypes = {"walkietalkie","longrange"}
	-- for _,curtype in pairs(radioTypes) do
		-- local current = inventory:GetItemsByUniqueID(curtype, true)
		-- if (#current > 0) then
			-- for k,v in pairs(current) do radios[#radios+1] = v end
		-- end
	-- end

	-- for k, v in pairs(radios) do
		-- if v:GetData("enabled", false) and !v:GetData("silenced",false) then
			-- if (v:GetData("frequency") == frequency or v:GetData("duplex",v.duplex)) then
				-- endChatter(target,dist,v.uniqueID)
				-- break -- Play sound once
			-- end
		-- end
	-- end
-- end

--if (SERVER) then
--	util.AddNetworkString("ixRadioOverhear")
--	net.Receive("ixRadioOverhear", function(length, client)
--		local message = net.ReadString()
--		ix.chat.Send(player.GetAll()[2], "radio_overhear", message, nil, nil, nil)
--	end)
--end

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
			local wcolor = ix.config.Get("walkieTalkieColor",Color(91, 182, 224))

			if speaker == 1 then
				return lcolor
			elseif speaker == 2 then
				return wcolor
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


		function CLASS:CanHear(speaker, listener, data)
			--PrintTable(data)
			--local chatRange = ix.config.Get("chatRange",280)
			local maxRadioRange = ix.config.Get("radioRangeMult") * ix.config.Get("chatRange")
			local character = listener:GetCharacter()
			local spcharacter = speaker:GetCharacter()
			local spinventory = spcharacter:GetInventory()
			local inventory = character:GetInventory()

			local togetherDistance = listener:GetPos():Distance(speaker:GetPos())

			local radios = inventory:GetItemsByUniqueID("handheld_radio", true)
			local listenerActiveRadio = false
			local initialDuplexCheck = false
			--local radioTypes = {"walkietalkie","longrange"}
			for _,curtype in pairs(radioTypes) do
				local current = inventory:GetItemsByUniqueID(curtype)
				if (#current > 0) then
					for k,v in pairs(current) do
						radios[#radios+1] = v
						if v:GetData("active",false) then
							listenerActiveRadio = v
						end
						if ( (v.hybrid) or (v.duplex and v:GetData("duplex",v.duplex)) ) and v:GetData("enabled",false) then
							initialDuplexCheck = true
						end
					end
				end
			end
			local bHasRadio = false


			-- DUPLEX RADIO STUFF
			-- If they both don't have a duplex radios, don't bother checking anything about them
			local testA = false
			local duplex = false
			local spTrue = false
			local lisTrue = false
			if initialDuplexCheck and data.repeater != false then
				duplex = true
				spTrue = true --data.repeater
			end
			--

			-- Character-level frequency/channel handling
			--print(listener, duplex)
			if !duplex and data.repeater == false and !initialDuplexCheck then
				testA = spcharacter:GetData("frequency") == character:GetData("frequency")
			end
			local testB = spcharacter:GetData("channel") == character:GetData("channel")
			if character:GetData("scanning",false) then
				testB = true
			end
			local test1 = (testA and testB)

			--local duplex = false
			local radioSelect
			if (togetherDistance > self:GetRange()) then
				if test1 and speaker != listener then -- Don't even do all these checks
					bHasRadio = true
				else
					--print("Began loop for ",listener)
					-- Loop over radio items if character variables didn't solve it
					for k, v in pairs(radios) do
						if v:GetData("enabled",false) then -- First check if the radio is on, otherwise ignore it

							-- Item-level frequency/channel handling
							local testC = spcharacter:GetData("frequency") == v:GetData("frequency")
							local testD = spcharacter:GetData("channel") == v:GetData("channel")

							-- More duplex stuffs
							if v:GetData("duplex",v.duplex) and spTrue then
								local listenEnts = ents.FindInSphere(listener:GetPos(), ix.config.Get("repeaterMult")*maxRadioRange)
								for __,entity in pairs(listenEnts) do
									if entity:GetClass() == "ix_radiorepeater" and entity:GetEnabled() then
										--print("Enabled repeater in range")
										--print( tonumber(v:GetData("listenfrequency","100.1") ) )
										if tonumber(entity:GetOutputFreq()) == tonumber(v:GetData("listenfrequency","100.0")) then
										--	print("listenTrue is true")
											lisTrue = true
											break
										end
									end
								end
								if lisTrue then
								--	print("for ",listener, "lisTrue is ",lisTrue)
									testA = true
									testC = true
									if (testA and testB) then
										bHasRadio = true
										radioSelect = v
										break
									end
								end
							end
							-------------------

							local test2 = (testC and testD) -- Item-level check

							local test3 = false

							if !duplex and test2 and !v:GetData("duplex",v.duplex) then
								radioSelect = v
								bHasRadio = true
								break
							elseif duplex and (testB and testC and v:GetData("scanning",false)) then -- Test B should be true if you are scanning
								test3 = true
								bHasRadio = true
								radioSelect = v
								break
							end

							-- Broadcast handling
							if (!test1 and !test2 and !test3) then-- Only check the speaker's inventory if we have to

								-- Get speaker active radio
								local spradios = spinventory:GetItemsByUniqueID("handheld_radio", true)
								for _,curtype in pairs(radioTypes) do
									local current = spinventory:GetItemsByUniqueID(curtype)
									if (#current > 0) then
										for foo,bar in pairs(current) do spradios[#spradios+1] = bar end
									end
								end

								for _,b in pairs(spradios) do
									if b:GetData("enabled") and b:GetData("active") and b:GetData("broadcast") then
										if b:GetData("duplex",b.duplex) and spTrue and (testA or testC) then
											--print("spTrue is ",spTrue)
											bHasRadio = true
											radioSelect = v
											break
										end
									end
								end

							end

						end
					end
				end
			end

			if (ix.config.Get("hearSelf")) and  ( (speaker == listener) or radioSelect != nil ) then
				bHasRadio = true
			end

			if bHasRadio and (speaker != listener) then
				if radioSelect and !radioSelect:GetData("silenced",false) then
					endChatter(listener,togetherDistance,radioSelect.uniqueID)
				elseif listenerActiveRadio and !listenerActiveRadio:GetData("silenced",false) then
					endChatter(listener,togetherDistance,listenerActiveRadio.uniqueID)
				else -- Hacky solution, basically radioSelect and listenerActiveRadio handle everything BUT your active radio... should change how I do inventory searching later

					for k,v in pairs(inventory:GetItemsByUniqueID("handheld_radio", true)) do
						if (v:GetData("active",false) and !v:GetData("silenced",false)) then
							endChatter(listener,togetherDistance,v.uniqueID)
							break
						end
					end

				end
				--radioSilence(listener, (1 - self:GetMult()) * listener:GetPos():Distance(speaker:GetPos()), spcharacter:GetData("frequency"))
			end

			--print(listener,listener:GetCharacter():GetData("channel"))
			--print(listener, " heard: ",bHasRadio)

			--zprint(listener,bHasRadio)
			--print(listener,bHasRadio)
			return bHasRadio
		end

		function CLASS:OnChatAdd(speaker, text, bAnonymous, data)
			local repeater = false
			if data.repeater then
				repeater = data.repeater
			end

			-- Inventory searching up front
			local character = LocalPlayer():GetCharacter()
			local inventory = character:GetInventory()

			local radios = inventory:GetItemsByUniqueID("handheld_radio", true)
			--local radioTypes = {"walkietalkie","longrange"}
			for _,curtype in pairs(radioTypes) do
				local current = inventory:GetItemsByUniqueID(curtype, true)
				if (#current > 0) then
					for k,v in pairs(current) do radios[#radios+1] = v end
				end
			end

			--local activeradio
			local listenWalkie = false
			local foundActive = false
			local activeListenFreq = false
			local channelName = "CH"..data.chan
			local tally = 0 -- For determining how to send the chat later
			local badTally = false
			local freqList = {}
			for k,v in pairs(radios) do
				if (v:GetData("enabled", false)) then
					if (v:GetData("frequency","100.0") == data.freq and !v:GetData("duplex",v.duplex)) or (repeater != false and v:GetData("duplex",v.duplex) and tonumber(v:GetData("listenfrequency","900.0")) == tonumber(repeater:GetOutputFreq())) then
						if !foundActive then
							channelName = v:GetData("ch"..data.chan.."name","CH"..data.chan)
						end
						if v.walkietalkie then --and (tally == 0) then
							listenWalkie = true -- Get the walkie talkie channel name
						else
							listenWalkie = false
						end

						if v.longrange then
							channelName = v:GetData("ch"..data.chan.."name","CH"..data.chan)
							listenWalkie = false -- You're hearing it over long range instead
						end
						if v:GetData("active",false) then --and v:GetData("duplex",v.duplex) then --and (repeater and v:GetData("duplex",v.duplex) and tonumber(v:GetData("listenfrequency","900.0")) == tonumber(repeater:GetOutputFreq())) then
							channelName = v:GetData("ch"..data.chan.."name","CH"..data.chan)
							foundActive = true
							if v.walkietalkie then
								listenWalkie = true
							end
							activeListenFreq = v:GetData("listenfrequency","900.0")
						end
					-- elseif !listenWalkie then
						-- listenWalkie = false
					end

						if !v:GetData("duplex",v.duplex) then
							freqList[tally] = tonumber(v:GetData("frequency","100.0"))
						else
							freqList[tally] = tonumber(v:GetData("listenfrequency","900.0"))
						end
						if (tally > 0 and (freqList[tally] != freqList[tally-1])) then
							badTally = true
							--break
						end
						--if tally != -1 then
							tally = tally + 1
						--end
						--listenWalkie = false
						--print(channelName)
					--end
				end
			end

			--PrintTable(freqList)
			--print(listenWalkie)
			--print(tally)
			--
			local maxRadioRange = ix.config.Get("chatRange",280) * ix.config.Get("radioRangeMult",100)
			local dist = (1 - self:GetMult()) * LocalPlayer():GetPos():Distance(speaker:GetPos())
			--frac = 100*math.min(1, (dist / maxRadioRange )^2) -- Inverse square law

			-- Garbling fraction calculation, after distance modifiers
			if (data.repeater) then
				maxRadioRange = maxRadioRange * ix.config.Get("repeaterMult",2)
			elseif (data.lrange) then -- Long range radio handling
				maxRadioRange = maxRadioRange * ix.config.Get("longrangeMult",2)
			elseif (data.walkie or listenWalkie) then --(activeradio and activeradio.uniqueID == "walkietalkie")) then
				maxRadioRange = maxRadioRange * ix.config.Get("walkieMult",0.25)
			end

			--local repeater = false
			local repeaterPosn
			if repeater then
				repeaterPosn = repeater:GetPos()
				dist = (1 - self:GetMult()) * LocalPlayer():GetPos():Distance(repeaterPosn)
			end


			--local normDist = math.min(1, (dist / maxRadioRange))



			-- Random garbling setup
			local maxScaleGarbleFrac = 72.5 -- ix.config.Get("garbleMaxFrac",60) -- Maximum percent garbling at maximum radio distance
			-- local maxRandomGarble = 5 / 100

			-- Random garbling
			-- local sign = {-1,1}
			-- local rGarble = (1 + sign[math.random(#sign)]*maxRandomGarble*math.random(1,100)/100)
			--print("rGarble number ",(1 + sign[math.random(#sign)]*maxRandomGarble*math.random(1,100)/100)  )
			--print(rGarble)
			-- if (dist > maxRadioRange) then
				-- rGarble = (1 + maxScaleGarbleFrac*math.random(1,100)/100) -- math.random(1,100-maxScaleGarbleFrac)
			-- end
			--print("garble is ",rGarble)
			--dist = dist*rGarble

			-- Distance model selection
			local normDist = dist / maxRadioRange -- math.min(1, (dist / maxRadioRange))
			local quadratic = normDist^2 -- Quadratic, inverse square law
			local log2cal = 0.3 -- Approx. Log10(2)

			local logarithmic = normDist^(1/3)*( log2cal / (math.log10(1/normDist) + log2cal) ) -- Logarithmic, signal strength
			local hybrid = 0.5*(normDist + normDist^8) -- Quadratic/logarithmic hybrid, worse at close range but better at long range
			local lowest = 0.5*(normDist^2 + normDist^9) -- Better than hybrid model at all ranges with similar long range decay to quadratic

			local models = {quadratic,logarithmic,hybrid,lowest}
			local distModel = models[ix.config.Get("radioDecayModel",3)]

			frac = math.max(0, (maxScaleGarbleFrac * distModel )) -- Original garbling fraction

			--print("original frac ",frac)
			--print("new frac ",numTraces(speaker,LocalPlayer(),frac))

			local hitPenalty = 0.5 -- Percent
			if repeater then --data.walkie or listenWalkie then
				hitPenalty = 0.1
			elseif data.lrange then
				hitPenalty = 0.25
			elseif data.walkie then
				hitPenalty = 1.0
			end

			-- Percentage reduction in garbling based on line of sight (LOS)
			-- If you can see your recipient you should be able to hear their transmission
			local losFrac = 0.5
			local speakEnt
			if !repeater then
				speakEnt = speaker
			else
				speakEnt = repeater
			end

			--print(data.repeater)

			local randomPenalty = 5 -- Percent
			if LocalPlayer():IsLineOfSightClear(speakEnt) then -- If you can see them, you get a bonus
				frac = losFrac * frac
			elseif (repeater and !isOutdoors(LocalPlayer())) or (!repeater and (!isOutdoors(speaker) or !isOutdoors(LocalPlayer()))) then -- Indoors stuff
				--if repeater then print("Repter") end
				frac = frac * (1 + (randomPenalty/100)*math.random()) -- First penalty
				frac = numTraces(speaker,LocalPlayer(),frac,hitPenalty) -- Penalty for each trace
				--print(frac)
			end

			--print(frac)

			--print("final frac",frac)

			-- Final adjustments
			local garbleOffset = ix.config.Get("garbleOffset",0)
			local frac = math.min(math.max(0, frac+garbleOffset), 100)

			if (ix.config.Get("garbleRadio",true)) then text = mangleString(text, frac) else text = text end -- Garbling happens here

			-- Callsign handling
			if ((ix.config.Get("enableCallsigns",true)) and (data.callsign) and (data.callsign != "")) then
				name = data.callsign
			else
				name = speaker:Name()
			end
			--

			local useFreq = data.freq
			if repeater then
				useFreq = repeater:GetOutputFreq()
			end
			local theFreq = string.format("[%s *MHz*] ", useFreq)
			local theChan = string.format("[*%s*] ", channelName)

			local newColor = self:GetColor()
			local newFreqColor
			local newChanColor
			if data.lrange then
				newColor = self:GetColor(1) -- New LR chat color
			elseif data.walkie then
				newColor = self:GetColor(2)
				--newFreqColor = ix.config.Get("activeFreqColor",Color(255,255,255)) -- New LR freq color
			end

			--print(useFreq)
			--print(activeListenFreq)
			if (data.freq == character:GetData("frequency","100.0")) or (activeListenFreq == useFreq) then
				newFreqColor = ix.config.Get("activeFreqColor",Color(245,245,245)) -- New LR freq color
				if (data.chan == LocalPlayer():GetCharacter():GetData("channel","1")) then
					newChanColor = ix.config.Get("activeFreqColor",Color(245,245,245)) -- New LR freq color
				else
					newChanColor = ix.config.Get("radioFreqColor",Color(175,175,175))
				end
			else
				newFreqColor = ix.config.Get("radioFreqColor",Color(175,175,175))
				newChanColor = ix.config.Get("radioFreqColor",Color(175,175,175))
			end
			-- if (data.chan == LocalPlayer():GetCharacter():GetData("channel","1")) then
				-- newChanColor = ix.config.Get("activeFreqColor",Color(245,245,245)) -- New LR freq color
			-- else
				-- newChanColor = ix.config.Get("radioFreqColor",Color(175,175,175))
			-- end

			-- Sound handling
			--radioSilence(LocalPlayer(), dist, data.freq)
			--

			-- If you have more than one radio, and they're on different frequencies, show the frequency next to the name
			-- Otherwise just show channel
			if (data.broadcast and !listenWalkie) then
				chat.AddText(newFreqColor, theFreq, newColor, string.format(self:GetFormat(), name, text))
			elseif (data.broadcast and listenWalkie) then
				chat.AddText(newChanColor, theChan, newColor, string.format(self:GetFormat(), name, text))
			elseif (badTally and !listenWalkie) then
				--print("This one")
				chat.AddText(newFreqColor, theFreq, newChanColor, theChan, newColor, string.format(self:GetFormat(), name, text))
			else
				chat.AddText(newChanColor, theChan, newColor, string.format(self:GetFormat(), name, text))
			end
			--print("Yeah")

			-- Overhearing other people's incoming transmissions
			--local function radioOverhear(tex)
			--	net.Start("ixRadioOverhear")
			--		net.WriteString(text)
			--	net.SendToServer()
			--end

			--if ix.config.Get("radioOverhear",false) then
			--	radioOverhear(text)
			--end

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
			local wcolor = ix.config.Get("walkieTalkieColor", Color(91, 182, 224))

			if speaker == 1 then
				color = lcolor
			elseif speaker == 2 then
				color = wcolor
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
			local wcolor = ix.config.Get("walkieTalkieColor", Color(91, 182, 224))

			if speaker == 1 then
				color = lcolor
			elseif speaker == 2 then
				color = wcolor
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
			if !data.quiet then
				if data.walkie then
					--print("Yes")
					playSound(speaker, "npc/metropolice/vo/on", true, 0, "walkietalkie")
				else
					--print("No")
					playSound(speaker, "npc/metropolice/vo/on", true, 0, "handheld_radio")
				end
			end

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
	do

		-- Populates the class with the info from the radio eavesdrop class WITHOUT overwriting the original class
		-- local ALIAS
		-- ALIAS = {}
        -- for orig_key, orig_value in pairs(ix.chat.classes.radio_eavesdrop) do
            -- ALIAS[orig_key] = orig_value
        -- end

		-- local CLASS = ALIAS

		local CLASS = {}
		CLASS.color = ix.config.Get("chatColor")
		CLASS.format = "\"*%s*\""

		function CLASS:GetColor(speaker, text)
			local color = ix.config.Get("chatColor")

			-- Make the whisper chat slightly dimmer than IC chat.
			--return Color(color.r - 35, color.g - 35, color.b - 35)
			return Color(180,180,180)
		end

		function CLASS:GetRange()
			local range = 0.25*ix.config.Get("chatRange", 280)

			return range
		end

		function CLASS:CanHear(speaker, listener)
			--print(speaker,listener)
			local test = (listener:GetPos():Distance(speaker:GetPos()) <= self:GetRange())
			if speaker != listener then
				return test
			else
				return false
			end

		end

		function CLASS:OnChatAdd(speaker, text, bAnonymous, data)
			-- Randomly drops at least minDrop and up to maxDrop percent of message, from the start
			local message = text
			local minDrop,maxDrop = 0.05,0.3
			local randDrop = math.min(maxDrop, minDrop + math.random()*maxDrop)
			local dropStart = math.ceil(randDrop*string.len(message))

			local firstChar = string.sub(string.sub(message, dropStart),0,1)

			while (firstChar == " " or firstChar == "" or firstChar == "-" or firstChar == "," or firstChar == "." or firstChar == "!" or firstChar == "?") and (dropStart <= string.len(message) - 4) do
				dropStart = dropStart + 1
				firstChar = string.sub(string.sub(message, dropStart),0,1)
			end

			local message = "..."..string.sub(message, dropStart)
			chat.AddText(self:GetColor(speaker,text), string.format(self.format,message)) -- string.format(self.format, speaker:Name(), text))
			--end
		end

		CLASS.uniqueID = "radio_overhear" -- to be sure
		ix.chat.Register("radio_overhear", CLASS)
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
			local inventory = character:GetInventory()

			local radios = inventory:GetItemsByUniqueID("handheld_radio", true)
			--local radioTypes = {"walkietalkie","longrange","duplexradio"}
			for _,curtype in pairs(radioTypes) do
				local current = inventory:GetItemsByUniqueID(curtype, true)
				if (#current > 0) then
					for k,v in pairs(current) do radios[#radios+1] = v end
				end
			end

			local transmitLong = false
			local transmitWalkie = false
			local broadcasting = false
			local item

			-- Callsign handling
			local call
			local defCall
			local names = {"Somebody", "Someone", "A voice", "A person"}
			if (!ix.config.Get("anonymousRadioNames")) then
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
						transmitLong = v.longrange
						transmitWalkie = v.walkietalkie
						broadcasting = (v:GetData("broadcast",false))
						break
					end
				end
			end

			-- DUPLEX RADIO STUFF
			local bRepeater = false
			--local duplex = inventory:HasItem("duplexradio")
			if item and item:GetData("duplex",item.duplex) then

				local mult = 1
				if item.walkietalkie then
					mult = ix.config.Get("walkieMult")
				end

				local searchRange = mult * ix.config.Get("radioRangeMult")*ix.config.Get("chatRange",280)
				local localEnts = ents.FindInSphere(client:GetPos(), searchRange)--:GetRange()/2)
				for k,v in pairs(localEnts) do
					if v:GetClass() == "ix_radiorepeater" and v:GetEnabled() then
						--print(item:GetData("frequency","100.0"))
						if (tonumber(v:GetInputFreq()) == tonumber(item:GetData("frequency","100.0"))) then
							--print(bRepeater)
							bRepeater = v
						end
					end
				end
			end
			--

			-- You can't listen to your active radio and transmit on it at the same time, unless you are broadcasting on that same frequency
			if ( (item) and !item:GetData("scanning",false) ) or ( (item) and item:GetData("scanning",false) and item:GetData("broadcast",false) ) then
				if (!client:IsRestricted()) then
					--print("Check 1",item:GetData("duplex",item.duplex) and bRepeater != false)
					--print("Check 2",!item:GetData("duplex",item.duplex))
					--if ( item:GetData("duplex",item.duplex) and bRepeater != false ) or ( !item:GetData("duplex",item.duplex) ) then
						ix.chat.Send(client, "radio", message,nil,nil,{repeater = bRepeater, broadcast = broadcasting, callsign=call, walkie = transmitWalkie, lrange=transmitLong, freq=client:GetCharacter():GetData("frequency"), chan=client:GetCharacter():GetData("channel")})
					--end
						ix.chat.Send(client, "radio_eavesdrop", message,nil,nil,{quiet=item:GetData("silenced"),walkie = transmitWalkie })
					--endChatter(client,0)
					--playSound(client, "npc/metropolice/vo/on", true)
				else
					return "@notNow"
				end
			elseif (item) and item:GetData("scanning",false) then
				client:Notify("You cannot transmit on a radio you are listening to!")
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
			local inventory = character:GetInventory()

			local radios = inventory:GetItemsByUniqueID("handheld_radio", true)
			--local radioTypes = {"walkietalkie","longrange"}
			for _,curtype in pairs(radioTypes) do
				local current = inventory:GetItemsByUniqueID(curtype, true)
				if (#current > 0) then
					for k,v in pairs(current) do radios[#radios+1] = v end
				end
			end

			local transmitLong = false
			local transmitWalkie = false
			local broadcasting = false
			local item

			-- Callsign handling
			local call
			local defCall
			local names = {"Somebody", "Someone", "A voice", "A person"}
			if (!ix.config.Get("anonymousRadioNames")) then
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
						transmitLong = v.longrange
						transmitWalkie = v.walkietalkie
						broadcasting = (v:GetData("broadcast",false))
						break
					end
				end
			end

			-- DUPLEX RADIO STUFF
			local bRepeater = false
			if item and item:GetData("duplex",item.duplex) then

				local mult = 1
				if item.walkietalkie then
					mult = ix.config.Get("walkieMult")
				end

				local searchRange = mult * ix.config.Get("radioRangeMult")*ix.config.Get("chatRange",280)
				local localEnts = ents.FindInSphere(client:GetPos(), searchRange)--:GetRange()/2)
				for k,v in pairs(localEnts) do
					if v:GetClass() == "ix_radiorepeater" and v:GetEnabled() then
						--print(item:GetData("frequency","100.0"))
						if (tonumber(v:GetInputFreq()) == tonumber(item:GetData("frequency","100.0"))) then
							--print(bRepeater)
							bRepeater = v
						end
					end
				end
			end
			--

			if ( (item) and !item:GetData("scanning",false) ) or ( (item) and item:GetData("scanning",false) and item:GetData("broadcast",false) ) then
				if (!client:IsRestricted()) then

					if (item:GetData("duplex",item.duplex) and bRepeater != false) or (!item:GetData("duplex",item.duplex)) then
						ix.chat.Send(client, "radio_yell", message,nil,nil,{repeater=bRepeater, broadcast = broadcasting, callsign=call, walkie = transmitWalkie, lrange=transmitLong, freq=client:GetCharacter():GetData("frequency"), chan=client:GetCharacter():GetData("channel")})
					end
						ix.chat.Send(client, "radio_eavesdrop_yell", message,nil,nil,{quiet=item:GetData("silenced"),walkie = transmitWalkie})
					--endChatter(client,0)
					--playSound(client, "npc/metropolice/vo/on", true)
				else
					return "@notNow"
				end
			elseif (item) and item:GetData("scanning",false) then
				client:Notify("You cannot transmit on a radio you are listening to!")
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
			local inventory = character:GetInventory()

			local radios = inventory:GetItemsByUniqueID("handheld_radio", true)
			--local radioTypes = {"walkietalkie","longrange"}
			for _,curtype in pairs(radioTypes) do
				local current = inventory:GetItemsByUniqueID(curtype, true)
				if (#current > 0) then
					for k,v in pairs(current) do radios[#radios+1] = v end
				end
			end

			local transmitLong = false
			local transmitWalkie = false
			local broadcasting = false
			local item

			-- Callsign handling
			local call
			local defCall
			local names = {"Somebody", "Someone", "A voice", "A person"}
			if (!ix.config.Get("anonymousRadioNames")) then
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
						transmitLong = v.longrange
						transmitWalkie = v.walkietalkie
						broadcasting = (v:GetData("broadcast",false))
						break
					end
				end
			end

			-- DUPLEX RADIO STUFF
			local bRepeater = false
			--local duplex = inventory:HasItem("duplexradio")
			if item and item:GetData("duplex",item.duplex) then

				local mult = 1
				if item.walkietalkie then
					mult = ix.config.Get("walkieMult")
				end

				local searchRange = mult * ix.config.Get("radioRangeMult")*ix.config.Get("chatRange",280)
				local localEnts = ents.FindInSphere(client:GetPos(), searchRange)--:GetRange()/2)
				for k,v in pairs(localEnts) do
					if v:GetClass() == "ix_radiorepeater" and v:GetEnabled() then
						--print(item:GetData("frequency","100.0"))
						if (tonumber(v:GetInputFreq()) == tonumber(item:GetData("frequency","100.0"))) then
							--print(bRepeater)
							bRepeater = v
						end
					end
				end
			end
			--

			if ( (item) and !item:GetData("scanning",false) ) or ( (item) and item:GetData("scanning",false) and item:GetData("broadcast",false) ) then
				if (!client:IsRestricted()) then

					if (item:GetData("duplex",item.duplex) and bRepeater != false) or (!item:GetData("duplex",item.duplex)) then
						ix.chat.Send(client, "radio_whisper", message,nil,nil,{repeater=bRepeater, broadcast = broadcasting, callsign=call, walkie = transmitWalkie, lrange=transmitLong, freq=client:GetCharacter():GetData("frequency"), chan=client:GetCharacter():GetData("channel")})
					end
						ix.chat.Send(client, "radio_eavesdrop_whisper", message,nil,nil,{quiet=item:GetData("silenced"),walkie = transmitWalkie})
					--endChatter(client,0)
					--playSound(client, "npc/metropolice/vo/on", true)
				else
					return "@notNow"
				end
			elseif (item) and item:GetData("scanning",false) then
				client:Notify("You cannot transmit on a radio you are listening to!")
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

			local radios = inventory:GetItemsByUniqueID("handheld_radio", true)
			--local radioTypes = {"walkietalkie","longrange","duplexradio"}
			for _,curtype in pairs(radioTypes) do
				local current = inventory:GetItemsByUniqueID(curtype, true)
				if (#current > 0) then
					for k,v in pairs(current) do radios[#radios+1] = v end
				end
			end

			local active = 0
			-- print(self:TableLength(itemTable))
			-- PrintTable(itemTable)

			local notSame = true
			local itemTable
			local numEnabled = 0
			if (self:TableLength(radios) < 1) then
				client:Notify("You do not have a radio!")
			else
				for k, v in ipairs(radios) do
					if (v:GetData("enabled", false)) then
						itemTable = v
						if itemTable:GetData("duplex",itemTable.duplex) then
							notSame = tonumber(frequency) != tonumber(itemTable:GetData("listenfrequency","900.0"))
						end
						numEnabled = numEnabled + 1
						if (v:GetData("active")) then
							--print("Activated?")
							active = 1
							break
						end
					end
				end

				if itemTable.walkietalkie then
					client:Notify("You cannot directly change the frequency of this radio.")
				elseif itemTable:GetData("duplex",itemTable.duplex) and !notSame then
					client:Notify("Your transmitting and receiving frequencies cannot be the same!")
				elseif (active == 1) then
					if string.find(frequency, "^%d%d%d%.%d$") then
						character:SetData("frequency", frequency)
						character:SetData("channel", itemTable:GetData("channel","1"))
						itemTable:SetData("frequency", frequency)
						--if itemTable.uniqueID == "duplexradio" then
						--	itemTable:SetData("listenfrequency", "990.1") -- TESTING STUFFS
						--end

						client:Notify(string.format("You have set your radio frequency to %s MHz.", frequency))
					end
				elseif (itemTable and (numEnabled == 1) and (active == 0)) then
					if string.find(frequency, "^%d%d%d%.%d$") then
						character:SetData("frequency", frequency)
						character:SetData("channel", itemTable:GetData("channel","1"))
						itemTable:SetData("active", true)
						itemTable:SetData("frequency", frequency)

						client:Notify(string.format("You have set your radio frequency to %s MHz.", frequency))
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

		-----
	do
		local COMMAND = {}
		COMMAND.arguments = ix.type.number

		function COMMAND:TableLength(T)
			local count = 0
			for _ in pairs(T) do count = count + 1 end
			return count
		end

		function COMMAND:OnRun(client, listenfrequency)
			if string.len(listenfrequency) < 4 then
				listenfrequency = listenfrequency .. '.0'
			end
			local character = client:GetCharacter()
			local inventory = character:GetInventory()

			local radios = inventory:GetItemsByUniqueID("handheld_radio", true)
			--local radioTypes = {"walkietalkie","longrange","duplexradio"}
			for _,curtype in pairs(radioTypes) do
				local current = inventory:GetItemsByUniqueID(curtype, true)
				if (#current > 0) then
					for k,v in pairs(current) do radios[#radios+1] = v end
				end
			end

			local active = 0
			-- print(self:TableLength(itemTable))
			-- PrintTable(itemTable)

			local itemTable
			local notSame = true
			local numEnabled = 0
			local numEnabledDuplex = 0
			if (self:TableLength(radios) < 1) then
				client:Notify("You do not have a radio!")
			else
				for k, v in ipairs(radios) do
					if (v:GetData("enabled", false)) then
						itemTable = v
						notSame =  tonumber(listenfrequency) != tonumber(itemTable:GetData("frequency"))
						numEnabled = numEnabled + 1
						if v:GetData("duplex",v.duplex) then
							numEnabledDuplex = numEnabledDuplex + 1
						end
						if (v:GetData("active")) then
							--print("Activated?")
							active = 1
							break
						end
					end
				end

				if itemTable.walkietalkie then
					client:Notify("You cannot directly change the frequency of this radio.")
				elseif !notSame then
					client:Notify("Your transmitting and receiving frequencies cannot be the same!")
				elseif (active == 1 and itemTable:GetData("duplex",itemTable.duplex)) then
					if string.find(listenfrequency, "^%d%d%d%.%d$") then
						character:SetData("frequency", itemTable:GetData("frequency"))
						character:SetData("channel", itemTable:GetData("channel","1"))
						itemTable:SetData("listenfrequency", listenfrequency)

						client:Notify(string.format("You have set your receiving frequency to %s MHz.", listenfrequency))
					end
				elseif (itemTable and itemTable:GetData("duplex",itemTable.duplex) and (numEnabledDuplex == 1)) then
					if string.find(listenfrequency, "^%d%d%d%.%d$") then
						itemTable:SetData("listenfrequency", listenfrequency)
						client:Notify(string.format("You have set your receiving frequency to %s MHz.", listenfrequency))
					end
					if (numEnabled == 1 and numEnabledDuplex == 1) then
						itemTable:SetData("active", true)
						character:SetData("frequency", itemTable:GetData("frequency"))
						character:SetData("channel", itemTable:GetData("channel","1"))
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
				elseif !itemTable:GetData("duplex",itemTable.duplex) then
					client:Notify("None of your radios are capable of this action.")
				end
			end
		end

		ix.command.Add("SetListenFreq", COMMAND)
	end

	--

	do
		local COMMAND = {}

		COMMAND.alias = {"chan", "com"}

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
			--local radioTypes = {"walkietalkie","longrange"}
			for _,curtype in pairs(radioTypes) do
				local current = inventory:GetItemsByUniqueID(curtype, true)
				if (#current > 0) then
					for k,v in pairs(current) do radios[#radios+1] = v end
				end
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

		COMMAND.alias = {"tgc", "tc"}
--		COMMAND.arguments = ix.type.text

		function COMMAND:TableLength(T)
			local count = 0
			for _ in pairs(T) do count = count + 1 end
			return count
		end

		function COMMAND:OnRun(client)

			-- Valid channel handling

			local character = client:GetCharacter()
			local inventory = character:GetInventory()

			local radios = inventory:GetItemsByUniqueID("handheld_radio", true)
			--local radioTypes = {"walkietalkie","longrange"}
			for _,curtype in pairs(radioTypes) do
				local current = inventory:GetItemsByUniqueID(curtype, true)
				if (#current > 0) then
					for k,v in pairs(current) do radios[#radios+1] = v end
				end
			end

			--local active = false
			local itemTable
			local chan
			if (self:TableLength(radios) < 1) then
				client:Notify("You do not have a radio!")
			else
				for k, v in ipairs(radios) do
					if (v:GetData("enabled", false) and v:GetData("active")) then
						itemTable = v
						chan = v.data.channel
						if chan == 4 then chan = 1 else chan = chan+1 end
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

		ix.command.Add("ToggleChan", COMMAND)
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

			local chan, chanName = chan:match("([^,]+),([^,]+)")
			local maxChars = 16 -- Maximum number of characters in a new radio name

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
			elseif (string.len(chanName) > maxChars) then
				client:Notify("Your channel name is too long!")
				return
			end

			local character = client:GetCharacter()
			local inventory = character:GetInventory()

			local radios = inventory:GetItemsByUniqueID("handheld_radio", true)
			--local radioTypes = {"walkietalkie","longrange"}
			for _,curtype in pairs(radioTypes) do
				local current = inventory:GetItemsByUniqueID(curtype, true)
				if (#current > 0) then
					for k,v in pairs(current) do radios[#radios+1] = v end
				end
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
					--character:SetData("channel", chan)

					local store = "ch"..chan.."name"
					itemTable:SetData(store, chanName)

					client:Notify(string.format("You have set channel %s's name to %s.", chan,chanName))
				else
					client:Notify("You do not have an active radio.")
				end
			end
		end

		ix.command.Add("ChanRename", COMMAND)
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

	--

	do
		local COMMAND = {}
		--COMMAND.adminOnly = true
		--COMMAND.arguments = ix.type.text

		COMMAND.alias = {"rbc"}

		function COMMAND:TableLength(T)
			local count = 0
			for _ in pairs(T) do count = count + 1 end
			return count
		end

		function COMMAND:CheckLegal(chk,item)
			local itemType = item.uniqueID
			if !chk then
				return false
			elseif chk >= 1 and item.longrange then
				return true
			elseif chk == 3 and item.walkietalkie then
				return true
			elseif chk >= 2 and !item.walkietalkie then
				return true
			else
				return false
			end
		end

		function COMMAND:OnRun(client)
			local character = client:GetCharacter()
			local inventory = character:GetInventory()

			local radios = inventory:GetItemsByUniqueID("handheld_radio", true)
			--local radioTypes = {"walkietalkie","longrange"}
			for _,curtype in pairs(radioTypes) do
				local current = inventory:GetItemsByUniqueID(curtype, true)
				if (#current > 0) then
					for k,v in pairs(current) do radios[#radios+1] = v end
				end
			end

			if (ix.config.Get("allowBroadcast",true)) then

				local bAllowed = ix.config.Get("broadcastLevel",1)

				if (self:TableLength(radios) > 0) then
					local found = false
					for k,v in pairs(radios) do
						if (v:GetData("enabled",false) and v:GetData("active",true)) then
							-- Toggles broadcasting
							found = true
							if (self:CheckLegal(bAllowed, v) )  then
								v:SetData("broadcast", !v:GetData("broadcast", false))
								legal = true
								if v:GetData("broadcast") then
									local nowalkie = !v.walkietalkie
									local show = string.format("You are now broadcasting over all channels%s.",nowalkie and " on "..v:GetData("frequency","100.0").." MHz" or "")
									client:NotifyLocalized(show)
								else
									client:NotifyLocalized("You are no longer broadcasting over all channels.")
								end
								break
							end
						end
					end

					if !found then
						client:NotifyLocalized("None of your radios are currently active.")
					elseif !legal then
						client:NotifyLocalized("Your radio is not capable of broadcasting.")
					end
				else
					client:NotifyLocalized("You do not have a radio!")
				end

			else
				client:NotifyLocalized("Radio broadcasting has been disabled.")
			end
		end

		ix.command.Add("RadioBroadcast", COMMAND)
	end

	--

	do
		local COMMAND = {}
		--COMMAND.adminOnly = true
		--COMMAND.arguments = ix.type.text

		COMMAND.alias = {"rls"}

		function COMMAND:TableLength(T)
			local count = 0
			for _ in pairs(T) do count = count + 1 end
			return count
		end

		function COMMAND:OnRun(client)
			local character = client:GetCharacter()
			local inventory = character:GetInventory()

			local radios = inventory:GetItemsByUniqueID("handheld_radio", true)
			--local radioTypes = {"walkietalkie","longrange"}
			for _,curtype in pairs(radioTypes) do
				local current = inventory:GetItemsByUniqueID(curtype, true)
				if (#current > 0) then
					for k,v in pairs(current) do radios[#radios+1] = v end
				end
			end

			if (self:TableLength(radios) > 0) then
				local found = false
				for k,v in pairs(radios) do
					if (v:GetData("enabled",false) and v:GetData("active",false)) then
						-- Toggles broadcasting
						found = true
						--if (self:CheckLegal(bAllowed,v.uniqueID) )  then
						v:SetData("scanning", !v:GetData("scanning", false))
						--legal = true
						if v:GetData("scanning",false) then
							local nowalkie = !v.walkietalkie
							local preShow = string.format(" on %s MHz", v:GetData("duplex",v.duplex) and v:GetData("listenfrequency","100.0") or v:GetData("frequency","100.0"))
							local show = string.format("You are now listening to all channels%s.",nowalkie and preShow or "")
							client:NotifyLocalized(show)
						else
							client:NotifyLocalized("You are no longer listening to all channels.")
						end
						break
						--end
					end
				end

				if !found then
					client:NotifyLocalized("None of your radios are currently active.")
				end
			else
				client:NotifyLocalized("You do not have a radio!")
			end

			--else
				--client:NotifyLocalized("Radio broadcasting has been disabled.")
			--end
		end

		ix.command.Add("RadioListen", COMMAND)
	end

	--

	do
		local COMMAND = {}
		COMMAND.adminOnly = true
		--COMMAND.adminOnly = true
		--COMMAND.arguments = ix.type.text

		--COMMAND.alias = {"rls"}

		-- function COMMAND:TableLength(T)
			-- local count = 0
			-- for _ in pairs(T) do count = count + 1 end
			-- return count
		-- end

		-- function COMMAND:CheckLegal(chk,typ)
			-- if (chk == 1 and typ == "longrange") then
				-- return true
			-- elseif (chk == 2) then
				-- if (typ == "longrange" or typ == "handheld_radio" or typ == "duplexradio") then
					-- return true
				-- end
			-- elseif (chk == 3) then
				-- return true
			-- end
		-- end

		function COMMAND:OnRun(client)

			local radioEnts = ents.FindByClass("ix_radiorepeater")
			if (#radioEnts > 0) then
				for _, v in ipairs(radioEnts) do
					v:Remove()
				end
				client:Notify("Successfully removed all radio repeaters.")
			else
				client:Notify("No radio repeaters to remove!")
			end
		end

		ix.command.Add("ClearRadioRepeaters", COMMAND)
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

-- Repeater saving
-- saving
function PLUGIN:SaveRadioRepeaters()
	local data = {}

	for _, v in ipairs(ents.FindByClass("ix_radiorepeater")) do
		data[#data + 1] = {v:GetPos(), v:GetAngles(), v:GetEnabled(), v:GetInputFreq(), v:GetOutputFreq()}
	end

	ix.data.Set("radioRepeaters", data)
end

function PLUGIN:SaveData()
	self:SaveRadioRepeaters()
end

-- function PLUGIN:ClearRadioRepeaters()
	-- local data = {}

	-- for _, v in ipairs(ents.FindByClass("ix_radiorepeater")) do
		-- data[#data + 1] = {v:GetPos(), v:GetAngles(), v:GetEnabled(), v:GetInputFreq(), v:GetOutputFreq()}
	-- end

	-- ix.data.Set("radioRepeaters", data)
-- end

-- loading
function PLUGIN:LoadRadioRepeaters()
	for _, v in ipairs(ix.data.Get("radioRepeaters") or {}) do
		local repeater = ents.Create("ix_radiorepeater")

		repeater:SetPos(v[1])
		repeater:SetAngles(v[2])
		repeater:Spawn()
		repeater:SetEnabled(v[3])
		repeater:SetOutputFreq(v[4])
		repeater:SetOutputFreq(v[5])
	end
end

function PLUGIN:LoadData()
	self:LoadRadioRepeaters()
end

-- function PLUGIN:MessageReceived(client,info)
	-- if client != player.GetAll()[2] and info.chatType == "radio" then --and ix.chat.classes.radio_overhear:CanHear(client,LocalPlayer()) then
		-- --print(LocalPlayer())
		-- ix.chat.Send(player.GetAll()[2], "radio_overhear", "*"..info.text.."*", nil, nil, nil)
	-- end
-- end
