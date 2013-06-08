
if SERVER then

	AddCSLuaFile()
	SWEP.Weight				= 5
	SWEP.AutoSwitchTo		= false
	SWEP.AutoSwitchFrom		= false

	resource.AddFile( "sprites/scope" )
	resource.AddFile( "overlays/scope_lens" )
	resource.AddFile( "gmod/scope-refract" )

else

	SWEP.DrawAmmo			= true
	SWEP.DrawCrosshair		= false
	SWEP.ViewModelFOV		= 60
	SWEP.ViewModelFlip		= false
	SWEP.CSMuzzleFlashes	= true

	// This is the font that's used to draw the death icons
	surface.CreateFont( "CSKillIcons", { font = "csd", size = ScreenScale(30), weight = 500, antialias = true, additive = true } )
	surface.CreateFont( "CSSelectIcons", { font = "csd", size = ScreenScale(60), weight = 500, antialias = true, additive = true } )

end

SWEP.Author			= "Counter-Strike"
SWEP.Contact		= ""
SWEP.Purpose		= ""
SWEP.Instructions	= ""

// Note: This is how it should have worked. The base weapon would set the category
// then all of the children would have inherited that.
// But a lot of SWEPS have based themselves on this base (probably not on purpose)
// So the category name is now defined in all of the child SWEPS.
//SWEP.Category			= "Counter-Strike"

SWEP.Spawnable			= false
SWEP.AdminSpawnable		= false

SWEP.Primary.Sound			= Sound( "Weapon_AK47.Single" )
SWEP.Primary.Recoil			= 1.5
SWEP.Primary.Damage			= 40
SWEP.Primary.NumShots		= 1
SWEP.Primary.Cone			= 0.02
SWEP.Primary.Delay			= 0.15

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo			= "none"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= "none"

SWEP.PenetrationPower = 4 // thickness of a wall that this bullet can penetrate
SWEP.PenetrationDistance = 128 // distance at which the bullet is capable of penetrating a wall

SWEP.Zoom = {}
SWEP.Zoom.Level = 0
SWEP.Zoom.Sound = Sound( "Default.Zoom" )

SWEP.UseHands = true

function SWEP:Initialize()

	if ( SERVER ) then
		self:SetNPCMinBurst( 30 )
		self:SetNPCMaxBurst( 30 )
		self:SetNPCFireRate( 0.01 )
	end

	self:SetWeaponHoldType( self.HoldType )

end

function SWEP:SetupDataTables()

	self:NetworkVar( "Bool", 0, "Ironsights" )
	self:NetworkVar( "Int", 0, "ZoomLevel" )

	if SERVER then

		self:SetIronsights( false )
		self:SetZoomLevel( 0 )

	end

end

function SWEP:Reload()
	self.Weapon:DefaultReload( ACT_VM_RELOAD );
	self:SetIronsights( false )
end

function SWEP:Think()
end


/*---------------------------------------------------------
	PrimaryAttack
---------------------------------------------------------*/
function SWEP:PrimaryAttack()

	self.Weapon:SetNextSecondaryFire( CurTime() + self.Primary.Delay )
	self.Weapon:SetNextPrimaryFire( CurTime() + self.Primary.Delay )

	if ( !self:CanPrimaryAttack() ) then return end

	// Play shoot sound
	self.Weapon:EmitSound( self.Primary.Sound )

	// Shoot the bullet
	self:CSShootBullet( self.Primary.Damage, self.Primary.Recoil, self.Primary.NumShots, self.Primary.Cone )

	// Remove 1 bullet from our clip
	self:TakePrimaryAmmo( 1 )

	if ( self.Owner:IsNPC() ) then return end

	// Punch the player's view
	self.Owner:ViewPunch( Angle( math.Rand(-0.2,-0.1) * self.Primary.Recoil, math.Rand(-0.1,0.1) *self.Primary.Recoil, 0 ) )

	// In singleplayer this function doesn't get called on the client, so we use a networked float
	// to send the last shoot time. In multiplayer this is predicted clientside so we don't need to
	// send the float.
	if ( (game.SinglePlayer() && SERVER) || CLIENT ) then
		self.Weapon:SetNetworkedFloat( "LastShootTime", CurTime() )
	end

end

/*---------------------------------------------------------
   Name: SWEP:CSShootBullet( )
---------------------------------------------------------*/
function SWEP:CSShootBullet( dmg, recoil, numbul, cone )

	numbul 	= numbul 	or 1
	cone 	= cone 		or 0.01

	local bullet = {}
	bullet.Num 		= numbul
	bullet.Src 		= self.Owner:GetShootPos()			// Source
	bullet.Dir 		= self.Owner:GetAimVector()			// Dir of bullet
	bullet.Spread 	= Vector( cone, cone, cone )			// Aim Cone
	bullet.Tracer	= 4									// Show a tracer on every x bullets
	bullet.Force	= 5									// Amount of force to give to phys objects
	bullet.Damage	= dmg

	self.Owner:FireBullets( bullet )
	self.Weapon:SendWeaponAnim( ACT_VM_PRIMARYATTACK ) 		// View model animation
	self.Owner:MuzzleFlash()								// Crappy muzzle light
	self.Owner:SetAnimation( PLAYER_ATTACK1 )				// 3rd Person Animation

	if ( self.Owner:IsNPC() ) then return end

	// CUSTOM RECOIL !
	if ( (game.SinglePlayer() && SERVER) || ( !game.SinglePlayer() && CLIENT && IsFirstTimePredicted() ) ) then

		local eyeang = self.Owner:EyeAngles()
		eyeang.pitch = eyeang.pitch - recoil
		self.Owner:SetEyeAngles( eyeang )

	end

end


/*---------------------------------------------------------
	Checks the objects before any action is taken
	This is to make sure that the entities haven't been removed
---------------------------------------------------------*/
function SWEP:DrawWeaponSelection( x, y, wide, tall, alpha )

	draw.SimpleText( self.IconLetter, "CSSelectIcons", x + wide/2, y + tall*0.2, Color( 255, 210, 0, 255 ), TEXT_ALIGN_CENTER )

	// try to fool them into thinking they're playing a Tony Hawks game
	draw.SimpleText( self.IconLetter, "CSSelectIcons", x + wide/2 + math.Rand(-4, 4), y + tall*0.2+ math.Rand(-14, 14), Color( 255, 210, 0, math.Rand(10, 120) ), TEXT_ALIGN_CENTER )
	draw.SimpleText( self.IconLetter, "CSSelectIcons", x + wide/2 + math.Rand(-4, 4), y + tall*0.2+ math.Rand(-9, 9), Color( 255, 210, 0, math.Rand(10, 120) ), TEXT_ALIGN_CENTER )

end

local IRONSIGHT_TIME = 0.25

/*---------------------------------------------------------
   Name: GetViewModelPosition
   Desc: Allows you to re-position the view model
---------------------------------------------------------*/
function SWEP:GetViewModelPosition( pos, ang )

	if ( !self.IronSightsPos ) then return pos, ang end

	local bIron = self:GetIronsights()

	if ( bIron != self.bLastIron ) then

		self.bLastIron = bIron
		self.fIronTime = CurTime()

		if ( bIron ) then
			self.SwayScale 	= 0.3
			self.BobScale 	= 0.1
		else
			self.SwayScale 	= 1.0
			self.BobScale 	= 1.0
		end

	end

	local fIronTime = self.fIronTime or 0

	if ( !bIron && fIronTime < CurTime() - IRONSIGHT_TIME ) then
		return pos, ang
	end

	local Mul = 1.0

	if ( fIronTime > CurTime() - IRONSIGHT_TIME ) then

		Mul = math.Clamp( (CurTime() - fIronTime) / IRONSIGHT_TIME, 0, 1 )

		if (!bIron) then Mul = 1 - Mul end

	end

	local Offset	= self.IronSightsPos

	if ( self.IronSightsAng ) then

		ang = ang * 1
		ang:RotateAroundAxis( ang:Right(), 		self.IronSightsAng.x * Mul )
		ang:RotateAroundAxis( ang:Up(), 		self.IronSightsAng.y * Mul )
		ang:RotateAroundAxis( ang:Forward(), 	self.IronSightsAng.z * Mul )


	end

	local Right 	= ang:Right()
	local Up 		= ang:Up()
	local Forward 	= ang:Forward()



	pos = pos + Offset.x * Right * Mul
	pos = pos + Offset.y * Forward * Mul
	pos = pos + Offset.z * Up * Mul

	return pos, ang

end

function SWEP:SecondaryAttack()

	if self.IronSightsPos then

		self:SetIronsights( !self:GetIronsights() )

	elseif self.Zoom.Level > 0 then

		self:ZoomIn()

	end

	self:SetNextSecondaryFire( CurTime() + 0.3 )

end

/*---------------------------------------------------------
	DrawHUD

	Just a rough mock up showing how to draw your own crosshair.

---------------------------------------------------------*/
function SWEP:DrawHUD()

	if self:ShouldZoom() then
		self:DrawScope()
		return
	end

	// No crosshair when ironsights is on
	if self:GetIronsights() then return end

	local x, y

	// If we're drawing the local player, draw the crosshair where they're aiming,
	// instead of in the center of the screen.
	if ( self.Owner == LocalPlayer() && self.Owner:ShouldDrawLocalPlayer() ) then

		local tr = util.GetPlayerTrace( self.Owner )
		tr.mask = bit.bor(CONTENTS_SOLID,CONTENTS_MOVEABLE,CONTENTS_MONSTER,CONTENTS_WINDOW,CONTENTS_DEBRIS,CONTENTS_GRATE,CONTENTS_AUX)
		local trace = util.TraceLine( tr )

		local coords = trace.HitPos:ToScreen()
		x, y = coords.x, coords.y

	else
		x, y = ScrW() / 2.0, ScrH() / 2.0
	end

	local scale = 10 * self.Primary.Cone

	// Scale the size of the crosshair according to how long ago we fired our weapon
	local LastShootTime = self.Weapon:GetNetworkedFloat( "LastShootTime", 0 )
	scale = scale * (2 - math.Clamp( (CurTime() - LastShootTime) * 5, 0.0, 1.0 ))

	surface.SetDrawColor( 0, 255, 0, 255 )

	// Draw an awesome crosshair
	local gap = 40 * scale
	local length = gap + 20 * scale
	surface.DrawLine( x - length, y, x - gap, y )
	surface.DrawLine( x + length, y, x + gap, y )
	surface.DrawLine( x, y - length, x, y - gap )
	surface.DrawLine( x, y + length, x, y + gap )

end

/*---------------------------------------------------------
	onRestore
	Loaded a saved game (or changelevel)
---------------------------------------------------------*/
function SWEP:OnRestore()

	self.NextSecondaryAttack = 0
	self:SetIronsights( false )

end

function SWEP:Deploy()
	self.Weapon:SetNextPrimaryFire( CurTime() )
	self.Weapon:SetNextSecondaryFire( CurTime() )
	self.Weapon:DisableZoom()
end

/*---------------------------------------------------------
	Zoom
---------------------------------------------------------*/
function SWEP:IsZoomed()
	return self:GetZoomLevel() > 0
end

function SWEP:DisableZoom()
	self:SetZoomLevel( 0 )
end

function SWEP:ZoomIn()

	self.Weapon:EmitSound( self.Zoom.Sound )

	local level = (self:GetZoomLevel() + 1) % (self.Zoom.Level + 1)
	self:SetZoomLevel( level )

	-- self.m_zoomFullyActiveTime = CurTime() + 0.15

end

if CLIENT then

	function SWEP:ShouldZoom()
		return self:IsZoomed() and
			self:Clip1() > 0 and
			self:GetNextPrimaryFire() < CurTime()
	end

	function SWEP:AdjustMouseSensitivity()
		return self:ShouldZoom() and ( 1 / (self:GetZoomLevel() * 5) ) or 1
	end

	local ZoomHidden = {}
	ZoomHidden[ "CHudHealth" ] 			= true
	ZoomHidden[ "CHudSuitPower" ] 		= true
	ZoomHidden[ "CHudBattery" ] 		= true
	ZoomHidden[ "CHudAmmo" ] 			= true
	ZoomHidden[ "CHudSecondaryAmmo" ] 	= true
	ZoomHidden[ "CHudCrosshair" ] 		= true

	function SWEP:HUDShouldDraw( name )
		return not ( self:ShouldZoom() and ZoomHidden[ name ] )
	end

	function SWEP:TranslateFOV( fov )
		return self:ShouldZoom() and ( fov / (self:GetZoomLevel() * 5) ) or fov
	end

	local ScopeMat = surface.GetTextureID( "sprites/scope" )
	local ScopeLensMat = surface.GetTextureID( "overlays/scope_lens" )
	local ScopeRefractMat = surface.GetTextureID( "gmod/scope-refract" )

	function SWEP:DrawScope()

		local sw = (ScrW() > ScrH()) and ScrH() or ScrW()	-- Scope width
		local p = (ScrW() - sw) / 2 -- scope width padding

		surface.SetDrawColor( 0, 0, 0, 255 )

		-- Scope refraction texture
		local offset = sw * 0.22 -- texture inset correction
		surface.SetTexture( ScopeRefractMat )
		surface.DrawTexturedRect( p - offset, -offset, sw + offset*2, sw + offset*2 )

		-- Scope lens texture
		surface.SetTexture( ScopeLensMat )
		surface.DrawTexturedRect( p, 0, sw, sw )

		-- Scope texture
		surface.SetTexture( ScopeMat )
		surface.DrawTexturedRect( p, 0, sw, sw )

		-- Padding
		surface.DrawRect( 0, 0, p, ScrH() )
		surface.DrawRect( ScrW() - p, 0, p, ScrH() )

		-- Crosshair
		surface.DrawLine( ScrW() / 2, 0, ScrW() / 2, ScrH() )
		surface.DrawLine( 0, ScrH() / 2, ScrW(), ScrH() / 2 )

	end

end