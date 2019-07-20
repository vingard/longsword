-- Longsword is a lightweight weapon base by vin

AddCSLuaFile()

SWEP.PrintName = "Longsword"
SWEP.Category = "LS"
SWEP.DrawWeaponInfoBox = false

SWEP.Spawnable = false
SWEP.AdminOnly = false

SWEP.ViewModelFOV = 55
SWEP.UseHands = true

SWEP.Slot = 1
SWEP.SlotPos = 1

SWEP.CSMuzzleFlashes = true

SWEP.Primary.Sound = Sound("Weapon_Pistol.Single")
SWEP.Primary.Recoil = 0.8
SWEP.Primary.Damage = 5
SWEP.Primary.NumShots = 1
SWEP.Primary.Cone = 0.03
SWEP.Primary.Delay = 0.13

SWEP.Primary.Ammo = "pistol"
SWEP.Primary.Automatic = false
SWEP.Primary.ClipSize = 12
SWEP.Primary.DefaultClip = 12

SWEP.Secondary.Ammo = "none"
SWEP.Secondary.Automatic = false
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1

SWEP.EmptySound = Sound("Weapon_Pistol.Empty")

SWEP.Spread = {}
SWEP.Spread.Min = 0
SWEP.Spread.Max = 0.5
SWEP.Spread.IronsightsMod = 0.1
SWEP.Spread.CrouchMod = 0.6
SWEP.Spread.AirMod = 1.2
SWEP.Spread.RecoilMod = 0.025
SWEP.Spread.VelocityMod = 0.5

SWEP.IronsightsPos = Vector( -5.9613, -3.3101, 2.706 )
SWEP.IronsightsAng = Angle( 0, 0, 0 )
SWEP.IronsightsFOV = 0.8
SWEP.IronsightsSensitivity = 0.8
SWEP.IronsightsCrosshair = false
SWEP.UseIronsightsRecoil = true

function SWEP:SetupDataTables()
	self:NetworkVar("Bool", 0, "Ironsights")
	self:NetworkVar("Bool", 1, "Reloading")
	self:NetworkVar("Bool", 2, "Bursting")
	self:NetworkVar("Int", 0, "Sight")
	self:NetworkVar("Float", 1, "IronsightsRecoil")
	self:NetworkVar("Float", 2, "Recoil")
	self:NetworkVar("Float", 3, "ReloadTime")
	self:NetworkVar("Float", 4, "NextIdle")
end

function SWEP:Initialize()
	self:SetIronsights(false)

	self:SetReloading(false)
	self:SetReloadTime(0)

	self:SetRecoil(0)
	self:SetNextIdle(0)

	self:SetHoldType(self.HoldType)
end

function SWEP:OnReloaded()
	timer.Simple(0, function()
		self:SetHoldType(self.HoldType)
	end)
end

function SWEP:PlayAnim(act)
	local vmodel = self.Owner:GetViewModel()
	local seq = vmodel:SelectWeightedSequence(act)

	vmodel:SendViewModelMatchingSequence(seq)
end

function SWEP:PlayAnimWorld(act)
	local wmodel = self
	local seq = wmodel:SelectWeightedSequence(act)

	self:ResetSequence(seq)
end

function SWEP:Deploy()
	self:PlayAnim(ACT_VM_DRAW)
	self.Owner:GetViewModel():SetPlaybackRate(1)

	return true
end

function SWEP:ShootBullet(damage, num_bullets, aimcone)
	local bullet = {}

	bullet.Num 	= num_bullets
	bullet.Src 	= self.Owner:GetShootPos() -- Source
	bullet.Dir 	= self.Owner:GetAimVector() -- Dir of bullet
	bullet.Spread 	= Vector(aimcone, aimcone, 0)	-- Aim Cone

	if self.Primary.Tracer then
		bullet.TracerName = self.Primary.Tracer
	end

	if self.Primary.Range then
		bullet.Distance = self.Primary.Range
	end

	bullet.Tracer	= 1 -- Show a tracer on every x bullets
	bullet.Force	= 1 -- Amount of force to give to phys objects
	bullet.Damage	= damage
	bullet.AmmoType = ""

	self.Owner:FireBullets(bullet)

	self:ShootEffects()
end

function SWEP:ShootEffects()
	if not self:GetIronsights() or not self.UseIronsightsRecoil then
		self:PlayAnim(ACT_VM_PRIMARYATTACK)
		self:QueueIdle()
	else
		self:SetIronsightsRecoil( math.Clamp( 7.5 * (self.IronsightsRecoilVisualMultiplier or 1) * self.Primary.Recoil, 0, 20 ) )

		if CLIENT then
			local isThirdperson = hook.Run("ShouldDrawLocalPlayer", self.Owner)

			if not isThirdperson then
				local vm = self.Owner:GetViewModel()
				local attachment = vm:LookupAttachment("muzzle")
				local posang = vm:GetAttachment(attachment)

				if posang then
					local ef = EffectData()
					ef:SetOrigin(self.Owner:GetShootPos())
					ef:SetStart(self.Owner:GetShootPos())
					ef:SetNormal(self.Owner:EyeAngles():Forward())
					ef:SetEntity(self.Owner:GetViewModel())
					ef:SetAttachment(attachment)
					ef:SetScale(self.IronsightsMuzzleFlashScale or 1)

					util.Effect(self.IronsightsMuzzleFlash or "CS_MuzzleFlash", ef)
				end
			end
		end
	end

	self.Owner:MuzzleFlash()
	self:PlayAnimWorld(ACT_VM_PRIMARYATTACK)
	self.Owner:SetAnimation(PLAYER_ATTACK1)
end

function SWEP:IsSprinting()
	return ( self.Owner:GetVelocity():Length2D() > self.Owner:GetRunSpeed() - 50 )
		and self.Owner:IsOnGround()
end

function SWEP:PrimaryAttack()
	if not self:CanShoot() then return end

	local clip = self:Clip1()

	if self.Primary.Burst and clip >= 3 then
		self:SetBursting(true)
		self.Burst = 3

		local delay = CurTime() + ((self.Primary.Delay * 3) + (self.Primary.BurstEndDelay or 0.3))
		self:SetNextPrimaryFire(delay)
		self:SetReloadTime(delay)
	elseif clip >= 1 then
		self:TakePrimaryAmmo(1)

		self:ShootBullet(self.Primary.Damage, self.Primary.NumShots, self:CalculateSpread())

		self:AddRecoil()
		self:ViewPunch()

		self:EmitSound(self.Primary.Sound)

		self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
		self:SetReloadTime(CurTime() + self.Primary.Delay)
	else
		self:EmitSound(self.EmptySound)
		self:Reload()
		self:SetNextPrimaryFire(CurTime() + 1)
	end
end

function SWEP:SecondaryAttack() 
end

function SWEP:Holster()
	-- reset everything when we holster
	self:SetIronsights( false )
	self:SetIronsightsRecoil( 0 )

	self:SetReloading( false )
	self:SetReloadTime( 0 )

	self:SetRecoil( 0 )
	self:SetNextIdle( 0 )

	if CLIENT then
		self.ViewModelPos = Vector( 0, 0, 0 )
		self.ViewModelAng = Angle( 0, 0, 0 )
		self.FOV = nil
	end
	
	return true
end

function SWEP:QueueIdle()
	self:SetNextIdle( CurTime() + self.Owner:GetViewModel():SequenceDuration() + 0.1 )
end

function SWEP:IdleThink()
	if self:GetNextIdle() == 0 then return end

	if CurTime() > self:GetNextIdle() then
		self:SetNextIdle( 0 )
		self:SendWeaponAnim( self:Clip1() > 0 and ACT_VM_IDLE or ACT_VM_IDLE_EMPTY )
	end
end

function SWEP:Think()
	self:IronsightsThink()
	self:RecoilThink()
	self:IdleThink()

	if self:GetBursting() then self:BurstThink() end
	if self:GetReloading() then self:ReloadThink() end
end

function SWEP:AddRecoil()
	self:SetRecoil( math.Clamp( self:GetRecoil() + self.Primary.Recoil * 0.4, 0, 1 ) )
end

function SWEP:RecoilThink()
	self:SetRecoil( math.Clamp( self:GetRecoil() - FrameTime() * 1.4, 0, 1 ) )
end

function SWEP:BurstThink()
	if self.Burst and (self.nextBurst or 0) < CurTime() then
		self:TakePrimaryAmmo(1)

		self:ShootBullet(self.Primary.Damage, self.Primary.NumShots, self:CalculateSpread())

		self:AddRecoil()
		self:ViewPunch()

		self:EmitSound(self.Primary.Sound)

		self.Burst = self.Burst - 1

		if self.Burst < 1 then
			self:SetBursting(false)
			self.Burst = nil
		else
			self.nextBurst = CurTime() + self.Primary.Delay
		end	
	end
end

function SWEP:CanShoot()
	return self:CanPrimaryAttack() and not self:GetBursting() and not (self.LoweredPos and self:IsSprinting()) and self:GetReloadTime() < CurTime()
end

function SWEP:ViewPunch()
	local punch = Angle()

	local mul = self:GetIronsights() and 0.65 or 1
	punch.p = util.SharedRandom( "ViewPunch", -0.5, 0.5 ) * self.Primary.Recoil * mul
	punch.y = util.SharedRandom( "ViewPunch", -0.5, 0.5 ) * self.Primary.Recoil * mul
	punch.r = 0

	self.Owner:ViewPunch( punch )

	if IsFirstTimePredicted() and ( CLIENT or game.SinglePlayer() ) then
		self.Owner:SetEyeAngles( self.Owner:EyeAngles() -
			Angle( self.Primary.Recoil * ( self:GetIronsights() and 0.5 or 1 ), 0, 0 ) )
	end
end

function SWEP:CanIronsight()
	return not self:IsSprinting() and not self:GetReloading() and self.Owner:IsOnGround()
end

function SWEP:IronsightsThink()
	self:SetIronsightsRecoil( math.Approach( self:GetIronsightsRecoil(), 0, FrameTime() * 100 ) )

	self.BobScale = self:GetIronsights() and 0.1 or 1
	self.SwayScae = self:GetIronsights() and 0.1 or 1

	if not self:CanIronsight() then
		self:SetIronsights( false )
		return
	end

	if self.Owner:KeyDown( IN_ATTACK2 ) and not self:GetIronsights() then
		self:SetIronsights( true )
	elseif not self.Owner:KeyDown( IN_ATTACK2 ) and self:GetIronsights() then
		self:SetIronsights( false )
	end
end

function SWEP:CanReload()
	return self:Ammo1() > 0 and self:Clip1() < self.Primary.ClipSize
		and not self:GetReloading() and self:GetNextPrimaryFire() < CurTime()
end

function SWEP:Reload()
	if not self:CanReload() then return end

	self.Owner:DoReloadEvent()

	if not self.DoEmptyReloadAnim or self:Clip1() != 0 then
		self:PlayAnim(ACT_VM_RELOAD)
	else
		self:PlayAnim(ACT_VM_RELOAD_EMPTY)
	end
	self:QueueIdle()

	if self.ReloadSound then self:EmitSound(self.ReloadSound) end

	self:SetReloading( true )
	self:SetReloadTime( CurTime() + self.Owner:GetViewModel():SequenceDuration() )
end

function SWEP:ReloadThink()
	if self:GetReloadTime() < CurTime() then self:FinishReload() end
end

function SWEP:FinishReload()
	self:SetReloading( false )

	local amount = math.min( self:GetMaxClip1() - self:Clip1(), self:Ammo1() )

	self:SetClip1( self:Clip1() + amount )
	self.Owner:RemoveAmmo( amount, self:GetPrimaryAmmoType() )
end

function SWEP:CalculateSpread()
	local spread = self.Primary.Cone
	local maxSpeed = self.LoweredPos and self.Owner:GetWalkSpeed() or self.Owner:GetRunSpeed()

	spread = spread + self.Primary.Cone * math.Clamp( self.Owner:GetVelocity():Length2D() / maxSpeed, 0, self.Spread.VelocityMod )
	spread = spread + self:GetRecoil() * self.Spread.RecoilMod

	if not self.Owner:IsOnGround() then
		spread = spread * self.Spread.AirMod
	end

	if self.Owner:IsOnGround() and self.Owner:Crouching() then
		spread = spread * self.Spread.CrouchMod
	end

	if self:GetIronsights() then
		spread = spread * self.Spread.IronsightsMod
	end

	spread = math.Clamp( spread, self.Spread.Min, self.Spread.Max )

	if CLIENT and impulse_DevHud then
		self.LastSpread = spread
	end

	return spread
end

if SERVER then return end

SWEP.CrosshairAlpha = 1
SWEP.CrosshairSpread = 0

function SWEP:ShouldDrawCrosshair()
	if hook.Run("ShouldDrawLocalPlayer", self.Owner) then
		return true	
	end

	if self:GetReloading() or (self:IsSprinting() and self.LoweredPos) then
		return false
	end

	if (self:GetIronsights() and not self.IronsightsCrosshair) then
		return false
	end

	return true
end

function SWEP:GetOffset()
	if self:GetReloading() then return end

	if self.LoweredPos and self:IsSprinting() then
		return self.LoweredPos, self.LoweredAng
	end

	if self:GetIronsights() then
		return self.IronsightsPos + Vector( 0, -self:GetIronsightsRecoil(), 0 ), self.IronsightsAng
	end
end

SWEP.ViewModelPos = Vector( 0, 0, 0 )
SWEP.ViewModelAngle = Angle( 0, 0, 0 )

function SWEP:OffsetThink()
	local offset_pos, offset_ang = self:GetOffset()

	if not offset_pos then offset_pos = vector_origin end
	if not offset_ang then offset_ang = angle_zero end

	self.ViewModelPos = LerpVector(FrameTime() * 10, self.ViewModelPos, offset_pos)
	self.ViewModelAngle = LerpAngle(FrameTime() * 10, self.ViewModelAngle, offset_ang)
end

function SWEP:PreDrawViewModel()
	self:OffsetThink()
end

local sway = 1.5
local lastAng = Angle(0, 0, 0)
local cacheAng = Angle(0, 0, 0)

local c_jump = 0
local c_look = 0
local c_move = 0
local c_sight = 0

local bob = 1
local idle = 1

function SWEP:GetViewModelPosition( pos, ang )
	ang:RotateAroundAxis( ang:Right(), self.ViewModelAngle.p )
	ang:RotateAroundAxis( ang:Up(), self.ViewModelAngle.y )
	ang:RotateAroundAxis( ang:Forward(), self.ViewModelAngle.r )

	pos = pos + self.ViewModelPos.x * ang:Right()
	pos = pos + self.ViewModelPos.y * ang:Forward()
	pos = pos + self.ViewModelPos.z * ang:Up()

	local predicted = IsFirstTimePredicted()
	local ft = FrameTime()
	local ct = CurTime()

	-- camera move lag, based on QTG weapon base
	local aDelta = self.Owner:EyeAngles() - lastAng

	if aDelta.y >= 180 then
		aDelta.y = aDelta.y - 360
	elseif aDelta.y <= -180 then
		aDelta.y = aDelta.y + 360
	end

	aDelta.p = math.Clamp(aDelta.p, -5, 5)
	aDelta.y = math.Clamp(aDelta.y, -5, 5)
	aDelta.r = math.Clamp(aDelta.r, -5, 5)

	if self:GetIronsights() or self:GetReloading() then
		aDelta = aDelta * 0.02
	end

	if predicted then
		cacheAng = LerpAngle(math.Clamp(ft * 10, 0, 1), cacheAng, aDelta)
	end

	lastAng = self.Owner:EyeAngles()

	local psway = sway / (self.SwayFactor or 2)
	ang:RotateAroundAxis(ang:Right(), - cacheAng.p * sway)
	ang:RotateAroundAxis(ang:Up(), cacheAng.y * sway)
	ang:RotateAroundAxis(ang:Forward(), cacheAng.y * sway)
	pos = pos + ang:Right() * cacheAng.y * psway + ang:Up() * cacheAng.p * psway

	-- player movement and wep movement, based on QTG weapon base cuz i dont like maths
	local ovel = self.Owner:GetVelocity()
	local move = Vector(ovel.x, ovel.y, 0)
	local movement = move:LengthSqr()
	local movepercent = math.Clamp(movement / self.Owner:GetRunSpeed() ^ 2, 0, 1)

	local vel = move:GetNormalized()
	local rd = self.Owner:GetRight():Dot(vel)
	local fd = (self.Owner:GetForward():Dot(vel) + 1) / 2

	if predicted then
		local ft8 = math.min(ft * 8, 1)
		local onGround = self.Owner:OnGround()

		if self:GetIronsights() then
			movepercent = movepercent * 0.2
		end

		local c_move2 = movepercent
		c_move = Lerp(ft8, c_move or 0, onGround and movepercent or 0)
		c_sight = Lerp(ft8, c_sight or 0, self:GetIronsights() and onGround and not self:GetReloading() and not self:IsSprinting() and 0.1 or 1)

		local jump = self:GetIronsights() and math.Clamp(ovel.z / 120, -0.25, 0.5) or 0
		c_jump = Lerp(ft8, c_jump or 0, (self.Owner:GetMoveType() == MOVETYPE_NOCLIP or self:GetIronsights()) and jump or math.Clamp(ovel.z / 120, -1.5, 1))

		if rd > 0.5 then
			c_look = Lerp(math.Clamp(ft * 5, 0, 1), c_look, 20 * c_move2)
		elseif rd < -0.5 then
			c_look = Lerp(math.Clamp(ft * 5, 0, 1), c_look, -20 * c_move2)
		else
			c_look = Lerp(math.Clamp(ft * 5, 0, 1), c_look, 0)
		end
	end

	pos = pos + ang:Up() * 0.75 * c_jump
	ang.p = ang.p + (c_jump or 0) * 3
	ang.r = ang.r + c_look

	if bob != 0 and c_move > 0 then
		local p = c_move * c_sight * bob

		pos = pos - ang:Forward() * c_move * c_sight * fd - ang:Up() * 0.75 * c_move + ang:Right() * 0.5 * c_move * c_sight
		ang.y = ang.y + math.sin(ct * 8.4) * 1.2 * p
		ang.p = ang.p + math.sin(ct * 16.8) * 0.8 * p
		ang.r = ang.r + math.cos(ct * 8.4) * 0.3 * p
	end

	if idle != 0 then
		local p = (1 - c_move) * c_sight * idle

		ang.p = ang.p + math.sin(ct * 0.5) * p
		ang.y = ang.y + math.sin(ct) * 0.5 * p
		ang.r = ang.r + math.sin(ct * 2) * 0.25 * p
	end

	return pos, ang
end

SWEP.FOVMultiplier = 1
SWEP.LastFOVUpdate = 0 -- gets called many times per frame... weird.
function SWEP:TranslateFOV(fov)
	if self.LastFOVUpdate < CurTime() then
		self.FOVMultiplier = Lerp(FrameTime() * 15, self.FOVMultiplier, self:GetIronsights() and self.IronsightsFOV or 1)
		self.LastFOVUpdate = CurTime()
	end

	return fov * self.FOVMultiplier
end

function SWEP:AdjustMouseSensitivity()
	if self:GetIronsights() then return self.IronsightsSensitivity end
end

SWEP.SelectColor = Color( 255, 210, 0 )
SWEP.EmptySelectColor = Color( 255, 50, 0 )
function SWEP:DrawWeaponSelection( x, y, w, h, a )
	local col = self:HasAmmo() and self.SelectColor or self.EmptySelectColor

	--draw.SimpleText( self.IconLetter, "CSSelectIcons", x + w / 2, y + h * 0.65,
	--	Color( col.r, col.g, col.b, a ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
end


local watermarkCol = Color(255,255,255,120)

function SWEP:DrawHUD()
	if impulse_DevHud and LocalPlayer():IsSuperAdmin() then
		local scrW = ScrW()
		local scrH = ScrH()

		surface.SetTextColor(watermarkCol)
		surface.SetFont("Impulse-Elements18-Shadow")

		surface.SetTextPos((scrW / 2) + 30, (scrH / 2))
		surface.DrawText("recoil: "..self:GetRecoil())

		surface.SetTextPos((scrW / 2) + 30, (scrH / 2) + 20)
		surface.DrawText("ironsights recoil: "..self:GetIronsightsRecoil())

		surface.SetTextPos((scrW / 2) + 30, (scrH / 2) + 40)
		surface.DrawText("ironsights: "..tostring(self:GetIronsights()))

		surface.SetTextPos((scrW / 2) + 30, (scrH / 2) + 60)
		surface.DrawText("last spread: "..(self.LastSpread or "shoot me"))
	end
end

surface.CreateFont( "CSKillIcons", { 
	size = ScreenScale( 30 ),
	weight = 500,
	antialiasing = true,
	additive = true,
	font = "csd"
} )

surface.CreateFont( "CSSelectIcons", { 
	size = ScreenScale( 60 ),
	weight = 500,
	antialiasing = true,
	additive = true,
	font = "csd"
} )

print("[longsword] Longsword weapon base loaded. Version 1. Copyright 2019 vin")