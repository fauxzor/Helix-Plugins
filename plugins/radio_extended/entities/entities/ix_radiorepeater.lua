
AddCSLuaFile()

local PLUGIN = PLUGIN

ENT.Type = "anim"
ENT.PrintName = "Radio Repeater"
ENT.Category = "Helix"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.PhysgunDisable = false
ENT.bNoPersist = true

-- function ENT:SetupDataTables()
	-- self:NetworkVar("Bool", 0, "Locked")
	-- self:NetworkVar("Bool", 1, "DisplayError")

	-- if (SERVER) then
		-- self:NetworkVarNotify("Locked", self.OnLockChanged)
	-- end
-- end

function ENT:SetupDataTables()
	self:NetworkVar("String", 2, "InputFreq")
	self:NetworkVar("String", 3, "OutputFreq")
	self:NetworkVar("Bool", 1, "Enabled")
end


if (SERVER) then
	util.AddNetworkString("ixRepeater")
	util.AddNetworkString("ixRepeaterPower")
	util.AddNetworkString("ixRepeaterMenu")

	sound.Add( {
		name = "repeater_idle",
		channel = CHAN_STATIC,
		volume = 1,
		level = 55,
		pitch = { 75, 90 },
		sound = "extendedradio/stationary1_loop.wav"--"ambient/machines/transformer_loop.wav"
	} )

	function ENT:SpawnFunction(client, trace)

		local normal = client:GetEyeTrace().HitNormal:Angle()
		normal:RotateAroundAxis(normal:Up(), 180)
		normal:RotateAroundAxis(normal:Forward(), 90)
		normal:RotateAroundAxis(normal:Right(), 90)

		local entity = ents.Create("ix_radiorepeater")
		entity:SetPos(trace.HitPos)
		entity:SetAngles(normal)
		entity:Spawn()
		entity:Activate()
		--entity:SetDoor(door, position, angles)

		--Schema:SaveCombineLocks()
		return entity
	end

	function ENT:Initialize()
		self:SetModel("models/props_c17/consolebox01a.mdl")
		self:SetSolid(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:PhysicsInit(SOLID_VPHYSICS)
		--self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
		self:SetUseType(SIMPLE_USE)
		
		
		self:SetInputFreq("900.1")
		self:SetOutputFreq("990.1")
		self:SetEnabled(true)
		
		
		
		self:EmitSound("repeater_idle")--, 65, 75, 0.2)
		self.nextUseTime = 0
	end

	function ENT:OnRemove()
		-- if (IsValid(self)) then
			-- self:SetParent(nil)
		-- end

		-- if (IsValid(self.door)) then
			-- self.door:Fire("unlock")
			-- self.door.ixLock = nil
		-- end

		-- if (IsValid(self.doorPartner)) then
			-- self.doorPartner:Fire("unlock")
			-- self.doorPartner.ixLock = nil
		-- end

		if (!ix.shuttingDown) then
			PLUGIN:SaveRadioRepeaters()
		end
		
		self:StopSound("repeater_idle")
	end

	function ENT:DisplayError()
		self:EmitSound("buttons/combine_button_locked.wav")

		--self:SetDisplayError(true)

		timer.Simple(1.2, function()
			if (IsValid(self)) then
				--self:SetDisplayError(false)
			end
		end)
	end
	
	net.Receive("ixRepeaterPower", function(length, client)
		local status = net.ReadBool()
		local radioent = client:GetEyeTrace().Entity
		radioent:SetEnabled(!radioent:GetEnabled())
		if !radioent:GetEnabled() then
			radioent:StopSound("repeater_idle")
			--radioent:EmitSound("extendedradio/stationary1.wav")
		else
			radioent:EmitSound("repeater_idle")--, 65, 75, 0.2)
		end
	end)
	
	net.Receive("ixRepeater", function(length, client)
		local this = net.ReadString()
		local that = client:GetEyeTrace().Entity

		local firstChar = string.sub(this,1,1)
		local trimThis = string.sub(this,2)
		if firstChar == "I" then
			that:SetInputFreq(trimThis)
		elseif firstChar == "O" then
			that:SetOutputFreq(trimThis)
		end
	end)

	function ENT:Use(client)
	
		-- NET STUFFS
		net.Start("ixRepeaterMenu")
		net.Send(client)
		
	end
	
else

	local function repeater(freq)
		net.Start("ixRepeater")
			net.WriteString(freq)
		net.SendToServer()
	end
	
	local function repeaterpower(status)
		net.Start("ixRepeaterPower")
			net.WriteBool(status)
		net.SendToServer()
	end

	net.Receive("ixRepeaterMenu", function(length)
		local theEntity = LocalPlayer():GetEyeTrace().Entity

		if theEntity:GetClass() == "ix_radiorepeater" then
		
			local oldInputFreq = theEntity:GetInputFreq()
			local oldOutputFreq = theEntity:GetOutputFreq()
			
			Derma_Query("Choose operation to perform", "Radio Repeater Control",
			"Change Input Frequency ("..oldInputFreq.." MHz)",function()
				Derma_StringRequest("Frequency", "Current input frequency: "..oldInputFreq.." MHz".."\nWhat would you like to set the new frequency to?", oldInputFreq, function(text)
				repeater("I"..text)
				--ix.command.Send("SetFreq", text)
				end)
			end,
			"Change Output Frequency ("..oldOutputFreq.." MHz)",function()
				Derma_StringRequest("Frequency", "Current output frequency: "..oldOutputFreq.." MHz".."\nWhat would you like to set the new frequency to?", oldOutputFreq, function(text)
				repeater("O"..text)
				--ix.command.Send("SetFreq", text)
				end)
			end,
			"Toggle Power", function()
				repeaterpower(theEntity:GetEnabled())
			end, 
			nil,nil) 
		end
	end)
	
	local glowMaterial = ix.util.GetMaterial("sprites/glow04_noz")
	local color_green = Color(0, 255, 0, 255)
	local color_blue = Color(0, 100, 255, 255)
	local color_red = Color(255, 50, 50, 255)

	function ENT:Draw()
		self:DrawModel()

		local color = color_green

		if (!self:GetEnabled()) then
			color = color_red
		end
		-- elseif (self:GetLocked()) then
			-- color = color_blue
		-- end

		local position = self:GetPos() + self:GetUp() * 8.2 + self:GetForward() * 17 + self:GetRight() * -12

		render.SetMaterial(glowMaterial)
		render.DrawSprite(position, 10, 10, color)
	
		local position, angles = self:GetPos(), self:GetAngles()
		--local display = self:GetEnabled() and self.Displays[self:GetDisplay()] or self.Displays[6]
		--local display = {"FREQ: "..self:GetRepFreq(), color_white, 255}
		--local display = {"FREQ: "..self:GetRepFreq(), color_white, 255}
		
		angles:RotateAroundAxis(angles:Forward(), 0)
		--angles:RotateAroundAxis(angles:Right(), 180)

		-- cam.Start3D2D(position + self:GetForward() * -5.6 + self:GetRight()*  -3.5 + self:GetUp() * 11, angles, 0.1)
			-- render.PushFilterMin(TEXFILTER.NONE)
			-- render.PushFilterMag(TEXFILTER.NONE)

			-- surface.SetDrawColor(color_black)
			-- surface.DrawRect(10, 16, 153, 40)

			-- surface.SetDrawColor(60, 60, 60)
			-- surface.DrawOutlinedRect(9, 16, 155, 40)

			-- local alpha = display[3] and 255 or math.abs(math.cos(RealTime() * 2) * 255)
			-- local color = ColorAlpha(display[2], alpha)

			-- draw.SimpleText(display[1], "ixRationDispenser", 86, 36, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

			-- render.PopFilterMin()
			-- render.PopFilterMag()
		-- cam.End3D2D()
	end
end
