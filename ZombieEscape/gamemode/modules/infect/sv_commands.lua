concommand.Add("ze_scream", function(ply,cmd,args)

	if !IsValid(ply) or !ply:IsZombie() then return end
	
	if ply.ScreamCount == nil or ply.LastScream == nil then
		ply.ScreamCount = 0
		ply.LastScream = 0
	end
	
	if ply.ScreamCount >= 5 or CurTime() < ply.LastScream + 3 then return end
	
	ply:ZScream()
	ply.ScreamCount = ply.ScreamCount + 1

end)

local function FindPartialTarget(name)
	for _, ply in pairs(player.GetAll()) do
		if string.find(ply:Name(), name) then
			return ply
		end
	end
end

concommand.Add("ze_human", function(ply,cmd,args)

	if IsValid(ply) and !ply:IsSuperAdmin() then return end
	if not ( GetConVar("sv_cheats"):GetBool() or IsDebugMode() ) then return end
	
	local Target = args[1]
	if !isstring(Target) then
		ply:ChatPrint("The syntax is 'ze_human <playername>'")
		return
	end
	
	Target = FindPartialTarget(Target)
	if Target and IsValid(Target) and Target:IsPlayer() then
		if !Target:IsHuman() then
			local pos = Target:GetPos()
			Target:GoTeam(TEAM_HUMANS)
			Target:SetPos(pos)
			if IsValid(ply) then
				ply:ChatPrint("Your target has been humanized!")
			end
		else
			if IsValid(ply) then
				ply:ChatPrint("Your target is already a human")
			end
		end
	end

end)

concommand.Add("ze_infect", function(ply,cmd,args)

	if IsValid(ply) and !ply:IsSuperAdmin() then return end
	if not ( GetConVar("sv_cheats"):GetBool() or IsDebugMode() ) then return end
	
	local Target = args[1]
	if !isstring(Target) then
		ply:ChatPrint("The syntax is 'ze_infect <playername>'")
		return
	end
	
	Target = FindPartialTarget(Target)
	if Target and IsValid(Target) and Target:IsPlayer() then
		if !Target:IsZombie() then
			Target:Zombify()
			if !Target:Alive() then
				Target:Spawn()
			end
			if IsValid(ply) then
				ply:ChatPrint("Your target has been infected!")
			end
		else
			if IsValid(ply) then
				ply:ChatPrint("Your target is already infected")
			end
		end
	end
	
end)