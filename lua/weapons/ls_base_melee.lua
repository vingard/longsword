AddCSLuaFile()

SWEP.Base = "ls_base"

SWEP.Primary.Ammo = "none"
SWEP.Primary.Automatic = false
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1

function SWEP:PrimaryAttack()
	if self.PrePrimaryAttack then
		self.PrePrimaryAttack(self)
	end

	self:ClubAttack()
	self:ViewPunch()
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

	local tr = util.TraceLine(trace)

	self.Owner:LagCompensation(false)

	if SERVER and tr.Hit then
		if self.Primary.ImpactSound then
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
			local dmg = DamageInfo()
			dmg:SetAttacker(self.Owner)
			dmg:SetInflictor(self)
			dmg:SetDamage(self.Primary.Damage)
			dmg:SetDamageType(DMG_CLUB)
			dmg:SetDamagePosition(tr.HitPos)
			dmg:SetDamageForce(self.Owner:GetAimVector() * 10000)

			ent:DispatchTraceAttack(dmg, trace.start, trace.endpos)
		end
	end
end