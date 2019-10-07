local PLUGIN = PLUGIN

function string:split( inSplitPattern, outResults )
  if not outResults then
    outResults = { }
  end
  local theStart = 1
  local theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
  while theSplitStart do
    table.insert( outResults, string.sub( self, theStart, theSplitStart-1 ) )
    theStart = theSplitEnd + 1
    theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
  end
  table.insert( outResults, string.sub( self, theStart ) )
  return outResults
end

function PLUGIN:LoadFonts(font, genericFont)
	surface.CreateFont("ixRadioFont", {
		font = "ixChatFont",
		size = math.max(ScreenScale(8), 17) * ix.option.Get("chatFontScale", 1),
		extended = true,
		weight = 800,
		antialias = true
	})
	
	surface.CreateFont("ixRadioWhisperFont", {
		font = "ixChatFont",
		size = math.max(ScreenScale(6), 16) * ix.option.Get("chatFontScale", 1),
		extended = true,
		weight = 1200,
		antialias = true
	})
end

local chatBorder = 32
local maxChatEntries = 50

-- radio chatbox history panel
-- holds individual messages in a scrollable panel
PANEL = {}

--AccessorFunc(PANEL, "filter", "Filter") -- blacklist of message classes
--AccessorFunc(PANEL, "id", "ID", FORCE_STRING)
--AccessorFunc(PANEL, "button", "Button") -- button panel that this panel corresponds to

function PANEL:Init()
	self:DockMargin(4, 0, 4, 0) -- smaller top margin to help blend tab button/history panel transition
	self:SetPaintedManually(true)

	local bar = self:GetVBar()
	bar:SetWide(0)

	self.entries = {}
	--self.filter = {}
end

DEFINE_BASECLASS("Panel") -- DScrollPanel doesn't have SetVisible member
function PANEL:SetVisible(bState)
	self:GetCanvas():SetVisible(bState)
	BaseClass.SetVisible(self, bState)
end

DEFINE_BASECLASS("DScrollPanel")
function PANEL:PerformLayout(width, height)
	local bar = self:GetVBar()
	local bScroll = !ix.gui.chat:GetActive() or bar.Scroll == bar.CanvasSize -- only scroll when we're not at the bottom/inactive

	BaseClass.PerformLayout(self, width, height)

	if (bScroll) then
		self:ScrollToBottom()
	end
end

function PANEL:ScrollToBottom()
	local bar = self:GetVBar()
	bar:SetScroll(bar.CanvasSize)
end

-- adds a line of text as described by its elements
function PANEL:AddLine(elements, bShouldScroll)
	-- table.concat is faster than regular string concatenation where there are lots of strings to concatenate
	local buffer = {
		"<font=ixChatFont>"
	}

	if (ix.option.Get("chatTimestamps", false)) then
		buffer[#buffer + 1] = "<color=150,150,150>("

		if (ix.option.Get("24hourTime", false)) then
			buffer[#buffer + 1] = os.date("%H:%M")
		else
			buffer[#buffer + 1] = os.date("%I:%M %p")
		end

		buffer[#buffer + 1] = ") "
	end

	if (CHAT_CLASS) then
		buffer[#buffer + 1] = "<font="
		buffer[#buffer + 1] = CHAT_CLASS.font or "ixChatFont"
		buffer[#buffer + 1] = ">"
	end
	
	local phrases = elements[#elements]
	local phraseTable = phrases:split(': "')
	
	phraseTable[1] = phraseTable[1] .. ": "
	phraseTable[2] = '"' .. phraseTable[2]
	--PrintTable(phraseTable)
	elements[#elements] = phraseTable[1]
	elements[#elements + 1] = elements[#elements - 1]
	elements[#elements + 1] = phraseTable[2]

	--local ct = 0
	for _, v in ipairs(elements) do
		--ct = ct + 1
		if (type(v) == "IMaterial") then
			local texture = v:GetName()

			if (texture) then
				buffer[#buffer + 1] = string.format("<img=%s,%dx%d> ", texture, v:Width(), v:Height())
			end
		elseif (istable(v) and v.r and v.g and v.b) then
			buffer[#buffer + 1] = string.format("<color=%d,%d,%d>", v.r, v.g, v.b)
		elseif (type(v) == "Player") then
			local color = team.GetColor(v:Team())

			buffer[#buffer + 1] = string.format("<color=%d,%d,%d>%s", color.r, color.g, color.b,
				v:GetName():gsub("<", "&lt;"):gsub(">", "&gt;"))
		else
			buffer[#buffer + 1] = tostring(v):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub("%b**", function(value)
				local inner = value:sub(2, -2)
				if (inner:find("%S")) then
					return "<font=ixChatFontItalics>" .. value:sub(2, -2) .. "</font>"
				end
			end)
			--buffer[#buffer + 1] = "</font>"
		end
	end
	
	if (ix.config.Get("radioYellBig", true) and (CHAT_CLASS.uniqueID == "radio_yell")) then
		buffer[#buffer] = "<font=ixRadioFont>" .. buffer[#buffer] .. "</font>"
	end
	if (ix.config.Get("radioWhisperSmall", true) and (CHAT_CLASS.uniqueID == "radio_whisper")) then
		buffer[#buffer] = "<font=ixRadioWhisperFont>" .. buffer[#buffer] .. "</font>"
	end

	local panel = self:Add("ixChatMessage")
	panel:Dock(TOP)
	
	-- Unnecessary, I think....
	if (ix.config.Get("radioYellBig", true) and (CHAT_CLASS.uniqueID == "radio_yell")) then
		--local lt,tp,rt,bt = panel:GetDockMargin()
		--print( panel:GetDockMargin())
		panel:DockMargin(0,-2,0,0) -- Left, top, right, bottom
	end
	
	panel:InvalidateParent(true)
	panel:SetMarkup(table.concat(buffer))

	if (#self.entries >= maxChatEntries) then
		local oldPanel = table.remove(self.entries, 1)

		if (IsValid(oldPanel)) then
			oldPanel:Remove()
		end
	end

	self.entries[#self.entries + 1] = panel
	return panel
end

vgui.Register("radioChatboxHistory", PANEL, "DScrollPanel")

------

local PANEL = {}

AccessorFunc(PANEL, "bActive", "Active", FORCE_BOOL)

function PANEL:Init()
	self:SetSize(self:GetDefaultSize())
	self:SetPos(self:GetDefaultPosition())
	
	local histPanel = self:Add("radioChatboxHistory")
	histPanel:SetZPos(5) -- Big numbers
	histPanel:Dock(FILL)
	self.history = histPanel
	
	-- local holder = vgui.Create("DPanel", self)
	-- holder:Dock(TOP)
	-- holder:DockMargin(0,4,0,4)
	-- holder:SetPaintBackground(false) -- Color(0,0,0,0))
	-- --holder:SetPaintShadow(false)
	
	-- local Button = vgui.Create( "DButton", holder )
	-- Button:Dock(LEFT)
	-- Button:SetText( "Click me I'm pretty!" )
	-- Button:SetTextColor( Color( 255, 255, 255 ) )
	-- --Button:SetPos( 100, 100 )
	-- Button:SetSize( 100, 30 )
	-- Button.Paint = function( self, w, h )
		-- draw.RoundedBox( 0, 0, 0, w, h, Color( 41, 128, 185, 150 ) ) -- Draw a blue button
	-- end
	-- Button.DoClick = function()
		-- print( "I was clicked!" )
	-- end
	
	
	-- local radioButton = vgui.Create( "DButton" )
	-- --radioButton:SetParent(histPanel)
	-- radioButton:DOCK(TOP)
	-- radioButton:DockMargin(1,1,0,0)
	-- radioButton:SetText( "Click me I'm pretty!" )
	-- radioButton:SetTextColor( Color( 255, 255, 255 ) )
	-- --buttonHolder:SetPos( 100, 100 )
	-- radioButton:SetSize( 20, 15 )
	-- radioButton.Paint = function( self, w, h )
		-- draw.RoundedBox( 0, 0, 0, w, h, Color( 41, 128, 185, 250 ) ) -- Draw a blue button
	-- end
	-- radioButton.DoClick = function()
		-- print( "I was clicked!" )
	-- end
	
	--self.history = histPanel
	--self.history:SetVisible(false)
	
	--self:SetBackgroundColor(Color(0,0,0,0))
	self.alpha = 0
	self:SetActive(false)
end

function PANEL:GetDefaultSize()
	local magicHeight = 153
	return ScrW() * 0.4, magicHeight --ScrH() * 0.2
end

function PANEL:GetDefaultPosition()
	local magicPos = 643 -- for 1080p screen this is default y positon, fuck this mess
	return chatBorder, magicPos -- ScrH() - 3 * self:GetTall() - chatBorder
end

function PANEL:SetupPosition(info)
	local x, y, width, height

	if (!istable(info)) then
		x, y = self:GetDefaultPosition()
		width, height = self:GetDefaultSize()
	else
		-- screen size may have changed so we'll need to clamp the values
		width = math.Clamp(info[3], 32, ScrW() - chatBorder * 2)
		height = math.Clamp(info[4], 32, ScrH() - chatBorder * 2)
		x = math.Clamp(info[1], 0, ScrW() - width)
		y = math.Clamp(info[2], 0, ScrH() - height)
	end
	
	local magicHeight = 155
	local magicYPos = (643-459-16)
	self:SetSize(width, magicHeight) --0.375*height)
	self:SetPos(x, y - magicYPos) -- 0.4*height)

	--PLUGIN:SavePosition()
end

DEFINE_BASECLASS("Panel")
function PANEL:SetAlpha(amount, duration)
	self:CreateAnimation(duration or animationTime, {
		index = 1,
		target = {alpha = amount},
		easing = "outQuint",

		Think = function(animation, panel)
			BaseClass.SetAlpha(panel, panel.alpha)
		end
	})
end

function PANEL:SetActive(bActive)
	--print(bActive)
	if (bActive) then
		self:SetAlpha(255)
		--self:MakePopup()
		self:SetVisible(true)
		self:SetMouseInputEnabled(true)
		self.history:SetMouseInputEnabled(true)
		--print("Made active")
		--print("History has focus",self.history:HasFocus())
		--print("Master has focus",self:HasFocus())
		--self.history:SetDisabled(false)
		--self.history:SetVisible(true)
		--self.entry:RequestFocus()

		--input.SetCursorPos(self:LocalToScreen(-1, -1))

		--hook.Run("StartChat")
		--self.prefix:SetText(hook.Run("GetChatPrefixInfo", ""))
	else
		self:SetAlpha(0)
		self:SetMouseInputEnabled(false)
		--self.history:SetMouseInputEnabled(false)
		self:SetKeyboardInputEnabled(false)
		--print("Made inactive")
		--self.history:SetVisible(false)
		--self.autocomplete:SetVisible(false)
		--self.preview:SetVisible(false)
		--self.entry:SetText("")
		--self.preview:SetCommand("")
		--self.prefix:SetText(hook.Run("GetChatPrefixInfo", ""))

		--CloseDermaMenus()
		--gui.EnableScreenClicker(false)

		--hook.Run("FinishChat")
	end

	if (self.history) then
		-- we'll scroll to bottom even if we're opening since the SetVisible for the textentry will shift things a bit
		self.history:ScrollToBottom()
	end

	self.bActive = tobool(bActive)
end



function PANEL:Paint(width, height)
	local hist = self.history
	local alpha = self:GetAlpha()

	--derma.SkinFunc("PaintChatboxBackground", self, width, height)
		-- manually paint active tab since messages handle their own alpha lifetime
		--surface.SetDrawColor(0, 0, 0, 200)
		--surface.DrawRect(0, 0, width, height)
		
		surface.SetAlphaMultiplier(1)
		hist:PaintManual()
		surface.SetAlphaMultiplier(alpha / 255)
		
	--end

	-- if (alpha > 0) then
		-- hook.Run("PostChatboxDraw", width, height, self:GetAlpha())
end



function PANEL:Think()
	-- if (gui.IsGameUIVisible() and self.bActive) then
		-- self:SetActive(false)
		-- return
	-- end
	
	-- if (ix.config.Get("enableRadioChatbox") == false) then
		-- self:SetActive(false)
		-- self.history:SetVisible(false)
		-- return
	-- end
	
	if (IsValid(ix.gui.chat) and !ix.gui.chat.bActive) then
		--print("Set false")
		self:SetActive(false)
		return
	end
	
	if (IsValid(ix.gui.chat) and ix.gui.chat.bActive and !self.bActive) then
		--print("Set false")
		self:SetActive(true)
		return
	end
	
	if (!self.bActive) then
		return
	end
end

-- called when a message needs to be added to applicable tabs
function PANEL:AddMessage(...)
	local class = CHAT_CLASS and CHAT_CLASS.uniqueID or "notice"
	-- local radiocheck = false
	-- if (class == "radio" or class == "radio_yell" or class == "radio_whisper") then
		-- radiocheck = true
	-- end

	-- track whether or not the message was filtered out in the active tab
	local bShown = false

	if (self.history) then -- and radiocheck) then
		self.history:AddLine({...}, true)
		bShown = true
	end

	if (bShown and !ix.config.Get("radioSounds", false)) then
		chat.PlaySound()
	end
end

vgui.Register("radioChatbox", PANEL, "EditablePanel")