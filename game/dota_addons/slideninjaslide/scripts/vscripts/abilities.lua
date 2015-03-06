--[[
	Abilities
]]

--[[
	Leap of Faith
]]

--[[Stop loop sound
	Author: chrislotix
	Date: 6.1.2015.]]
function LeapOfFaithStopSound ( keys )
	local sound_name = "Hero_Chen.TeleportLoop"
	local target = keys.target

	StopSoundEvent(sound_name, target)
--	StopEffect(target, "particles/units/heroes/hero_chen/chen_teleport.vpcf")
	StopEffect(target, "particles/units/heroes/hero_chen/chen_teleport_bits.vpcf")
--	StopEffect(target, "particles/units/heroes/hero_chen/chen_teleport_cast.vpcf")
--	StopEffect(target, "particles/units/heroes/hero_chen/chen_teleport_cast_sparks.vpcf")
	StopEffect(target, "particles/units/heroes/hero_chen/chen_teleport_rings.vpcf")
end

--[[
	Author: Ractidous
	Date: 29.01.2015.
	Hide caster's model.
]]
function HideHero( keys )
	keys.caster:AddNoDraw()
end

--[[
	Author: Ractidous
	Date: 29.01.2015.
	Show caster's model.
]]
function ShowHero ( keys )
	keys.caster:RemoveNoDraw()
end

--[[Author: A_Dizzle
	Date: 23.02.2015
	Moves the Hero forward a random distance
]]
function LeapOfFaith ( keys )
	local target = keys.target
	local min = keys.min
	local max = keys.max

	local connect = target:GetAbsOrigin()
	local direction = target:GetForwardVector()
	local distance = math.random(min, max)
	print(distance)

	local point = (direction * distance) + connect 
	print(point)
	local lastValid = connect
	local endPoint = point
	local midpoints = math.ceil((connect - endPoint):Length() / 32)
	local navConnect = false
	local index = 1
	while not navConnect and index < midpoints do
		lastPoint = connect
		connect = connect + (endPoint - connect):Normalized() * 32 * index
		navConnect = not GridNav:IsTraversable(connect) or GridNav:IsBlocked(connect) 
		index = index + 1
	end

	if not navConnect then
		lastPoint = connect
		connect = endPoint
		navConnect = not GridNav:IsTraversable(connect) or GridNav:IsBlocked(connect)
		if not navConnect then
			lastPoint = endPoint 
		end
	end

	target:Stop()
	FindClearSpaceForUnit(target, lastPoint, false)
	--ParticleManager:CreateParticle("particles/units/heroes/hero_chen/chen_teleport.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
	ParticleManager:CreateParticle("particles/units/heroes/hero_chen/chen_teleport_bits.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
--	ParticleManager:CreateParticle("particles/units/heroes/hero_chen/chen_teleport_cast.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
--	ParticleManager:CreateParticle("particles/units/heroes/hero_chen/chen_teleport_cast_sparks.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
	ParticleManager:CreateParticle("particles/units/heroes/hero_chen/chen_teleport_rings.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
end

function debug_teleport( keys )
	print(keys.target_points[1])
	FindClearSpaceForUnit(keys.caster, keys.target_points[1], true)
end