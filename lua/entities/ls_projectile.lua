AddCSLuaFile()

ENT.Type = "anim"
ENT.Spawnable = false

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:DrawShadow(false)
end

function ENT:DoFire(hit)
	if self.Fired then
		return
	end

	self.Fired = true

	if self.FireSound then
		self:EmitSound(self.FireSound)
	end

	self.OnFire(self, self.Owner, hit or nil)

	timer.Simple(self.RemoveWait or 0, function()
		if IsValid(self) then
			if self.ProjRemove then
				self:ProjRemove()
			end
			
			self:Remove()
		end
	end)
end

function ENT:Think()
	if CLIENT then
		return
	end

	if self.Fired and self.ProjThink then
		self:ProjThink()
	end

	if self.Timer and self.Timer < CurTime() then
		self:DoFire()
	end
end

function ENT:PhysicsCollide(colData, phys)
	if self.ProjTouch then
		if colData and colData.HitEntity and IsValid(colData.HitEntity) then
			if colData.HitEntity:GetClass() == "ls_projectile" then
				return
			end
			
			self:DoFire(colData.HitEntity)
		else
			self:DoFire()
		end
	elseif self.HitSound then
		self:EmitSound(self.HitSound)
	end
end