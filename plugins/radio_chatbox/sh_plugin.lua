
local PLUGIN = PLUGIN

PLUGIN.name = "Radio Chatbox"
PLUGIN.author = "faust"
PLUGIN.description = "Creates another chatbox above the regular one for radio chatter only."

ix.config.Add("enableRadioChatbox", true, "Whether or not to show radio messages in their own chatbox.", nil, {
	category = "Extended Radio"
})

if (CLIENT) then

	function PLUGIN:ChatboxPositionChanged(x, y, width, height)
		--print(ix.gui.chat:GetSize())
		--print(self.rpanel:GetSize())
		if (IsValid(self.rpanel)) then
			local w,h = ix.gui.chat:GetDefaultSize()
			local border = 16
			local magic = (643-459-border)
			local magicHeight = 155
			--print(self.rpanel:GetSize())
			-- print(x,y)
			-- print(" ")
			-- print(self.rpanel:GetPos())
			-- print( (643-459) == (border - h) )
			self.rpanel:SetSize(w, magicHeight)
			self.rpanel:SetPos(x, y - magic) --+ border - h)
		end
	end
	
	function PLUGIN:CreateRadiochat()
		if (IsValid(self.rpanel)) then
			self.rpanel:Remove()
		end
		
		self.rpanel = vgui.Create("radioChatbox")
		self.rpanel:SetupPosition(util.JSONToTable(ix.option.Get("chatPosition", "")))
		
		--hook.Run("ChatboxCreated")
	end
	function PLUGIN:InitPostEntity()
		self:CreateRadiochat()
		--hook.Run("ChatboxPositionChanged",x,y,width,height)
	end
	
	-- function PLUGIN:PlayerBindPress(client, bind, pressed)
		-- bind = bind:lower()
		-- --print("Is this on?")
		-- if (bind:find("messagemode") and pressed) then
			-- --print("Got this far")
			-- if ((IsValid(self.rpanel)) and (ix.config.Get("enableRadioChatbox"))) then 
				-- --print("Message mode bind worked")
				-- self.rpanel:SetActive(true)
			-- end
			
			-- ix.gui.chat:SetActive(true)
			-- return true
		-- end
	-- end
	
	--hook.Add("PlayerBindPress", "PlayerBindPress", PLUGIN:radioBindPress())
	
	-- function PLUGIN:ChatText(index, name, text, messageType)
		-- if (messageType == "none" and IsValid(self.rpanel)) then
			-- self.rpanel:AddMessage(text)
			-- --ix.gui.chat:AddMessage(text)
		-- end
	-- end	
	
		-- luacheck: globals chat
	chat.ixAddText = chat.ixAddText or chat.AddText

	function chat.AddText(...)
		local chat_class = CHAT_CLASS
		local radiocheck = false
		
		if (chat_class != nil) then
			if (ix.config.Get("enableRadioChatbox") == false) then
				radiocheck = false
			elseif ((chat_class.uniqueID == "radio") or (chat_class.uniqueID == "radio_yell") or (chat_class.uniqueID == "radio_whisper")) then
				radiocheck = true
			end
		end

		--print(IsValid(PLUGIN.rpanel))
		if (IsValid(ix.gui.chat) and !radiocheck) then
		--print("Hi")
			ix.gui.chat:AddMessage(...)
			--print("Regular")
		elseif (IsValid(PLUGIN.rpanel) and radiocheck) then
		--	print("Here now")
			PLUGIN.rpanel:AddMessage(...)
			--print("New")
		end

		-- log chat message to console
		local text = {}

		for _, v in ipairs({...}) do
			if (istable(v) or isstring(v)) then
				text[#text + 1] = v
			elseif (isentity(v) and v:IsPlayer()) then
				text[#text + 1] = team.GetColor(v:Team())
				text[#text + 1] = v:Name()
			elseif (type(v) != "IMaterial") then
				text[#text + 1] = tostring(v)
			end
		end

		text[#text + 1] = "\n"
		MsgC(unpack(text))
	end
	
else
	util.AddNetworkString("ixChatMessage")

	net.Receive("ixChatMessage", function(length, client)
		local text = net.ReadString()

		if ((client.ixNextChat or 0) < CurTime() and isstring(text) and text:find("%S")) then
			hook.Run("PlayerSay", client, text)
			client.ixNextChat = CurTime() + 0.5
		end
	end)
end