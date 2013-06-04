local EntityMeta = FindMetaTable("Entity")

function EntityMeta:HasTargetName()
	return self:GetName() != ""
end

function EntityMeta:EmitRandomSound(SoundTable)
	if !SoundTable or type(SoundTable) != 'table' or #SoundTable < 1 then return end
	self:EmitSound( table.Random(SoundTable) )
end

function EntityMeta:GetChildren()
	local tbl = {}
	for _, ent in pairs(ents.GetAll()) do
		if IsValid(ent) and IsValid(ent:GetParent()) and ent:GetParent() == self then
			table.insert(tbl, ent)
		end
	end
	return tbl
end

function EntityMeta:IsPressed()
	local value = self:GetSaveTable()["m_toggle_state"]
	return value and value == 0
end

function EntityMeta:ApplyPlayerProperties( ply )
	self.GetPlayerColor = function() return ply:GetPlayerColor() end
	self:SetBodygroup( ply:GetBodygroup(1), 1 )
	self:SetMaterial( ply:GetMaterial() )
	self:SetSkin( ply:GetSkin() or 1 )
end

local PlayerMeta = FindMetaTable("Player")

function PlayerMeta:GetTranslatedModel()
	return util.TranslateToPlayerModel( self:GetModel() )
end

function PlayerMeta:IsSpectator()
	return self:Team() == TEAM_SPECTATOR
end

function PlayerMeta:IsHuman()
	return self:Team() == TEAM_HUMANS
end

function PlayerMeta:IsZombie()
	return self:Team() == TEAM_ZOMBIES
end

if SERVER then

	function PlayerMeta:GoTeam(teamId, bNoRespawn)

		if !teamId then return end

		if self:Team() != teamId then
			self:SetTeam(teamId)
		end

		if teamId == TEAM_SPECTATOR then
			player_manager.SetPlayerClass( self, "player_spectator" )
		elseif teamId == TEAM_ZOMBIES then
			player_manager.SetPlayerClass( self, "player_zombie" )
		elseif teamId == TEAM_HUMANS then
			player_manager.SetPlayerClass( self, "player_human" )
		end

		if !bNoRespawn then

			if IsValid(self:GetPickupEntity()) then
				self:DropPickupEntity()
			end

			self:Spawn()

			timer.Simple(3, function()
				if IsValid(self) then
					self.SpawnInfo = { pos = self:GetPos() }
				end
			end)

		else

			player_manager.OnPlayerSpawn( self )
			player_manager.RunClass( self, "Spawn" )
			player_manager.RunClass( self, "Loadout" )

		end

	end

	function PlayerMeta:ResetAmmo()

		self:StripAmmo()

		local ammo = CVars.Ammo:GetInt()
		for _, type in pairs(GAMEMODE.AmmoTypes) do
			self:GiveAmmo(ammo, type, true)
		end

		local prevweap = self:GetActiveWeapon()

		self:GiveAmmo(1,"Grenade",true) -- give grenade

		-- Grenade automatically selects weapon_frag
		if IsValid(prevweap) then
			self:SelectWeapon(prevweap:GetClass())
		end

	end

	function PlayerMeta:SetSpeed(speed, crouchSpeed)

		self:SetWalkSpeed(speed)
		self:SetRunSpeed(speed)

		if crouchSpeed then
			self:SetCrouchedWalkSpeed(crouchSpeed)
		end

	end

	function PlayerMeta:SelectAvailableWeapon()
		local weap = table.Random( self:GetWeapons() or {} )
		if weap then
			self:SelectWeapon( weap:GetClass() )
		end
	end	

	-- Copied from TTT
	function PlayerMeta:ResetViewRoll()
		local ang = self:EyeAngles()
		if ang.r != 0 then
			ang.r = 0
			self:SetEyeAngles(ang)
		end
	end

end