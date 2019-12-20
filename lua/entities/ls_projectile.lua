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
	if self.FireSound then
		self:EmitSound(self.FireSound)
	end

	self.OnFire(self, self.Owner, hit or nil)

	timer.Simple(0, function()
		if IsValid(self) then
			self:Remove()
		end
	end)
end

function ENT:Think()
	if self.Timer and self.Timer < CurTime() then
		self:DoFire()
	end
end

function ENT:PhysicsCollide(colData, phys)
	if self.Touch then
		if colData and colData.HitEntity and IsValid(colData.HitEntity) then
			self:DoFire(colData.HitEntity)
		else
			self:DoFire()
		end
	end
end