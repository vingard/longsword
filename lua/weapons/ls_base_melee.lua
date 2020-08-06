AddCSLuaFile()

SWEP.Base = "ls_base"

SWEP.Primary.Ammo = "none"
SWEP.Primary.Automatic = false
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1

SWEP.Primary.Sound = Sound("WeaponFrag.Roll")
SWEP.Primary.ImpactSound = Sound("Canister.ImpactHard")

function SWEP:PrimaryAttack()
	if self.PrePrimaryAttack then
		self.PrePrimaryAttack(self)
	end

	if self.Primary.HitDelay then
		timer.Simple(self.Primary.HitDelay, function()
			if IsValid(self) and IsValid(self.Owner) then
				self:ClubAttack()
				self:ViewPunch()
			end
		end)
	else
		self:ClubAttack()
		self:ViewPunch()
	end

	self:EmitSound(self.Primary.Sound)

	self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

	self:SendWeaponAnim(ACT_VM_HITCENTER)
	self.Owner:SetAnimation(PLAYER_ATTACK1)
end

function SWEP:Think()
	self:IdleThink()
end

function SWEP:Reload()
	return
end

function SWEP:ClubAttack()
	self.Owner:LagCompensation(true)

	local trace = {}
	trace.start = self.Owner:GetShootPos()
	trace.endpos = trace.start + self.Owner:GetAimVector() * (self.Primary.Range or 85)
	trace.filter = self.Owner
	trace.mask = MASK_SHOT_HULL

	local boxSize = 6
	trace.mins = Vector(-boxSize, -boxSize, -boxSize)
	trace.maxs = Vector(boxSize, boxSize, boxSize)

	local tr = util.TraceHull(trace)

	if CLIENT then
		debugoverlay.BoxAngles(tr.HitPos, trace.mins, trace.maxs, self.Owner:EyeAngles(), 5, Color(200, 0, 0, 100))
	end

	self.Owner:LagCompensation(false)

	if SERVER and tr.Hit then
		hook.Run("LongswordMeleeHit", self.Owner)

		if self.Primary.ImpactSound and not self.Primary.ImpactSoundWorldOnly then
			self.Owner:EmitSound(self.Primary.ImpactSound)
		end

		if self.Primary.ImpactEffect then
			local effect = EffectData()
			effect:SetStart(tr.HitPos)
			effect:SetNormal(tr.HitNormal)
			effect:SetOrigin(tr.HitPos)

			util.Effect(self.Primary.ImpactEffect, effect, true, true)
		end

		local ent = tr.Entity

		if IsValid(ent) then
			local newdmg = hook.Run("LongswordCalculateMeleeDamage", self.Owner, self.Primary.Damage, ent)
			hook.Run("LongswordHitEntity", self.Owner, ent)

			local dmg = DamageInfo()
			dmg:SetAttacker(self.Owner)
			dmg:SetInflictor(self)
			dmg:SetDamage(newdmg or self.Primary.Damage)
			dmg:SetDamageType(DMG_CLUB)
			dmg:SetDamagePosition(tr.HitPos)

			if ent:GetClass() != "prop_ragdoll" then
				dmg:SetDamageForce(self.Owner:GetAimVector() * 10000)
			end

			ent:DispatchTraceAttack(dmg, trace.start, trace.endpos)

			if SERVER and ent:IsPlayer() then
				if self.Primary.FlashTime then
					ent:ScreenFade(SCREENFADE.IN, color_white, self.Primary.FlashTime, 0)
					ent.StunTime = CurTime() + self.Primary.FlashTime
					ent.StunStartTime = CurTime()
				elseif self.Primary.StunTime then
					ent.StunTime = CurTime() + self.Primary.StunTime
					ent.StunStartTime = CurTime()
				end
			end

			if tr.MatType == MAT_FLESH then
				ent:EmitSound("Flesh.ImpactHard")

				local effect = EffectData()
				effect:SetStart(tr.HitPos)
				effect:SetNormal(tr.HitNormal)
				effect:SetOrigin(tr.HitPos)

				util.Effect("BloodImpact", effect, true, true)
			elseif tr.MatType == MAT_WOOD then
				ent:EmitSound("Wood.ImpactHard")
			elseif tr.MatType == MAT_CONCRETE then
				ent:EmitSound("Concrete.ImpactHard")
			elseif self.Primary.ImpactSoundWorldOnly then
				self.Owner:EmitSound(self.Primary.ImpactSound)
			end
		elseif self.MeleeHitFallback and self.MeleeHitFallback(self, tr) then
			return
		elseif self.Primary.ImpactSoundWorldOnly then
			self.Owner:EmitSound(self.Primary.ImpactSound)
		end
	end
end