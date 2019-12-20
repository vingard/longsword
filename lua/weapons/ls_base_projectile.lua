AddCSLuaFile()

SWEP.Base = "ls_base"

SWEP.Projectile = {}

function SWEP:PrimaryAttack()
	if self:Clip1() < 1 then
		self:SetNextPrimaryFire(CurTime() + 1)
		return
	end

	if self.Primary.ThrowDelay then
		timer.Simple(self.Primary.ThrowDelay, function()
			if IsValid(self) then
				self:ThrowAttack()
				self:ViewPunch()

				if self:Clip1() < 1 then
					self.Owner:StripWeapon(self:GetClass())
				end
			end
		end)
	else
		self:ThrowAttack()
		self:ViewPunch()
	end

	self:EmitSound(self.Primary.Sound)

	self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

	self:SendWeaponAnim(ACT_VM_THROW)
	self.Owner:SetAnimation(PLAYER_ATTACK1)
	self:SendWeaponAnim(ACT_VM_DRAW)

	if self:Clip1() < 1 then
		self.Owner:StripWeapon(self:GetClass())
	end
end

function SWEP:Think()
	self:IdleThink()
end

function SWEP:Reload()
	return
end

function SWEP:ThrowAttack()
	if CLIENT then return end

	self:TakePrimaryAmmo(1)

	local projectile = ents.Create("ls_projectile")
	projectile:SetModel(self.Projectile.Model)
	projectile.Owner = self.Owner

	local pos = self.Owner:GetShootPos()
	pos = pos + self.Owner:GetForward() * 2
	pos = pos + self.Owner:GetRight() * 3
	pos = pos + self.Owner:GetUp() * -3

	projectile:SetPos(pos)

	if self.Projectile.Mass then
		projectile:SetMass(self.Projectile.Mass)
	end

	if self.Projectile.Timer then
		projectile.Timer = CurTime() + self.Projectile.Timer
	end

	if self.Projectile.Touch then
		projectile.Touch = self.Projectile.Touch
	end

	if self.ProjectileFire then
		projectile.OnFire = self.ProjectileFire
	end

	if self.Projectile.FireSound then
		projectile.FireSound = self.Projectile.FireSound
	end

	projectile:Spawn()

	local force = 700

	if self.Owner:KeyDown(IN_FORWARD) then
		force = 1100
	elseif self.Owner:KeyDown(IN_BACK) then
		force = 300
	end

	if self.Projectile.ForceMod then
		force = force * self.Projectile.ForceMod
	end

	local phys = projectile:GetPhysicsObject()

	if not IsValid(phys) then
		return
	end

	phys:ApplyForceCenter(self.Owner:GetAimVector() * force * 2 + Vector(0, 0, 0))
	phys:AddAngleVelocity(Vector(math.random(-500,500),math.random(-500,500),math.random(-500,500)))
end