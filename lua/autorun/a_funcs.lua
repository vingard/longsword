function RPM(rpm)
	return 60 / rpm
end

if SERVER then
	hook.Add("SetupMove", "longswordStunMove", function(ply, mvData)
		if ply.StunTime then
			if ply.StunTime < CurTime() then
				ply.StunTime = nil
			else
				local v = math.Clamp((ply.StunStartTime - CurTime()) / (ply.StunStartTime - ply.StunTime), 0, 1)
				mvData:SetMaxClientSpeed(mvData:GetMaxClientSpeed() * v)
			end
		end
	end)

	hook.Add("ScalePlayerDamage", "longswordArmourPen", function(ply, hitgroup, dmg)
		if ply:Armor() == 0 then
			return
		end

		local attacker = dmg:GetAttacker()

		if IsValid(attacker) and attacker:IsPlayer() then
			local wep = attacker:GetActiveWeapon()

			if IsValid(wep) and wep.Primary.PenetrationScale then
				dmg:ScaleDamage(wep.Primary.PenetrationScale)
			end
		end
	end)
end