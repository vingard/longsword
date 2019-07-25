AddCSLuaFile()

SWEP.Base = "ls_base"

SWEP.Primary.Ammo = "none"
SWEP.Primary.Automatic = false
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1

function SWEP:PrimaryAttack()
	self:ShootBullet(self.Primary.Damage, self.Primary.NumShots, 0)
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

function SWEP:ShootBullet(damage, num_bullets, aimcone)
	local bullet = {}

	bullet.Num 	= num_bullets
	bullet.Src 	= self.Owner:GetShootPos() -- Source
	bullet.Dir 	= self.Owner:GetAimVector() -- Dir of bullet
	bullet.Spread = 0
	bullet.Distance = self.Primary.Range or 85
	bullet.HullSize = 5

	bullet.Tracer	= 0 -- Show a tracer on every x bullets
	bullet.Force	= self.Primary.Force -- Amount of force to give to phys objects
	bullet.Damage	= damage
	bullet.AmmoType = ""

	bullet.Callback = function(attacker, tr)
		if IsValid(self) and tr.Hit then
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
		end
	end

	self.Owner:FireBullets(bullet)
end