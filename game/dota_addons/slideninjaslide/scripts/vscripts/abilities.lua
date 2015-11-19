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

function SpongeBobTokyoDrift( keys )
	local caster = keys.caster
	local duration = keys.duration

	local time = 0
	local particles_active = {}

	print("Tokyo Drift")

	Timers:CreateTimer(0.1, function()
		local fxIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_beastmaster/beastmaster_primal_target_flash.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
		ParticleManager:SetParticleControlEnt( fxIndex, 2, caster, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true )
		table.insert(particles_active, fxIndex)
		if time < duration and caster:IsAlive() then
			time = time + 0.1
			return 0.1
		else
			for _,v in ipairs(particles_active) do
				ParticleManager:DestroyParticle(v, false)
			end
			return nil
		end
	end)
end

--[[
	FORKED from SpellLibrary
	Original Author: Pizzalol
	Date: 05.01.2015.
	'Leap' 
]]
function SpongeBobLeapOfFaith( keys )
	local caster = keys.caster
	local duration = keys.duration
	local mid = duration / 2
	local height = 250
	local jump = height/(mid/0.03)
	local time_elapsed = 0

	print(caster:GetAbsOrigin().z)

	caster:OnAction(function(box, unit)
		--PrintTable(box)
		local pos = unit:GetAbsOrigin()

		local x = pos.x
		local y = pos.y
		local middle = box.middle
		local xblock = true
		local value = 0
		local normal = Vector(1,0,0)

		if x > middle.x then
			if y > middle.y then
				-- up,right
				local relx = (pos.x - middle.x) / box.xScale
				local rely = (pos.y - middle.y) / box.yScale

				if relx > rely then
					--right
					normal = Vector(1,0,0)
					value = box.xMax
					xblock = true
				else
					--up
					normal = Vector(0,1,0)
					value = box.yMax
					xblock = false
				end
			elseif y <= middle.y then
				-- down,right
				local relx = (pos.x - middle.x) / box.xScale
				local rely = (middle.y - pos.y) / box.yScale

				if relx > rely then
					--right
					normal = Vector(1,0,0)
					value = box.xMax
					xblock = true
				else
					--down
					normal = Vector(0,-1,0)
					value = box.yMin
					xblock = false
				end
			end
		elseif x <= middle.x then
			if y > middle.y then
				-- up,left
				local relx = (middle.x - pos.x) / box.xScale
				local rely = (pos.y - middle.y) / box.yScale

				if relx > rely then
					--left
					normal = Vector(-1,0,0)
					value = box.xMin
					xblock = true
				else
					--up
					normal = Vector(0,1,0)
					value = box.yMax
					xblock = false
				end
			elseif y <= middle.y then
				-- down,left
				local relx = (middle.x - pos.x) / box.xScale
				local rely = (middle.y - pos.y) / box.yScale

				if relx > rely then
					--left
					normal = Vector(-1,0,0)
					value = box.xMin
					xblock = true
				else
					--down
					normal = Vector(0,-1,0)
					value = box.yMin
					xblock = false
				end
			end
		end

		Physics:BlockInAABox(unit, xblock, value, buffer, findClearSpace)

		if IsPhysicsUnit(unit) then
			--print('turn hero', unit:GetAbsOrigin())
			local reflection = (-2 * unit:GetForwardVector():Dot(normal) * normal) + unit:GetForwardVector()
			--unit:SetForwardVector(reflection)
			unit:MoveToPosition((200 * reflection) + unit:GetAbsOrigin())
		end
	end)	
	
	Timers:CreateTimer(0, function()		
		local ground_position = GetGroundPosition(caster:GetAbsOrigin() , caster)
		time_elapsed = time_elapsed + 0.03
		if time_elapsed < mid then
			caster:SetAbsOrigin(caster:GetAbsOrigin() + Vector(0,0,jump)) -- Up
		else
			caster:SetAbsOrigin(caster:GetAbsOrigin() - Vector(0,0,jump)) -- Down
		end
		--print(caster:GetAbsOrigin().z, ground_position.z)
		if caster:GetAbsOrigin().z - ground_position.z <= 0 then
			caster:OnAction( nil )
			return nil
		end

		return 0.03
	end)
end

function BubbleBeam( keys )
	print("BubbleBeam")

	-- init ability
	local caster = keys.caster
	local ability = keys.ability

	local radius = keys.radius
	local bubbleSpeed = keys.bubble_speed
	if ( caster.slide ) then
		bubbleSpeed = bubbleSpeed + (caster:GetIdealSpeed()*0.5)
	end
	print(bubbleSpeed, radius)
	local duration = keys.duration

	local casterOrigin = caster:GetAbsOrigin()
	local targetDirection = caster:GetForwardVector()
	local projVelocity = targetDirection * bubbleSpeed


	local startTime = GameRules:GetGameTime()
	local endTime = startTime + duration

	-- Create linear projectile
	local projID = ProjectileManager:CreateLinearProjectile( {
		Ability = ability,
		EffectName = keys.proj_particle,
		vSpawnOrigin = casterOrigin,
		fDistance = 1000,
		fStartRadius = radius,
		fEndRadius = radius,
		Source = caster,
		bHasFrontalCone = false,
		bReplaceExisting = false,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
		iUnitTargetType = DOTA_UNIT_TARGET_BASIC,
		fExpireTime = endTime,
		bDeleteOnHit = true,
		vVelocity = projVelocity,
		bProvidesVision = false,
		iVisionRadius = 1000,
		iVisionTeamNumber = caster:GetTeamNumber()
	} )
end

function BubbleBeamOnHit( keys )
	print("BubbleBeamOnHit")

	local target = keys.target
	local duration = keys.duration
	local mid = duration/2
	local height = 200
	local jump = height/(mid/0.03)
	local time_elapsed = 0

	Timers:CreateTimer(0, function()		
		local ground_position = GetGroundPosition(target:GetAbsOrigin() , target)
		time_elapsed = time_elapsed + 0.03
		if time_elapsed < mid then
			target:SetAbsOrigin(target:GetAbsOrigin() + Vector(0,0,jump)) -- Up
		else
			target:SetAbsOrigin(target:GetAbsOrigin() - Vector(0,0,jump)) -- Down
		end
		--print(caster:GetAbsOrigin().z, ground_position.z)
		if target:GetAbsOrigin().z - ground_position.z <= 0 then
			return nil
		end

		return 0.03
	end)

end

function BubbleBeamStop( keys )
	print("BubbleBeamStop")
end

function Gaynish( keys )
	GameMode:FleeWolf( keys.caster:GetAbsOrigin(), keys.target)
end

--[[Author: A_Dizzle
	Date: 19.11.2015
	Moves the Hero forward a random distance
]]
function LeapOfGayness( keys )
	local target = keys.target
	local ability = keys.ability
	local min = ability:GetLevelSpecialValueFor("min_blink_range", ability:GetLevel() - 1)
	local max = ability:GetLevelSpecialValueFor("blink_range", ability:GetLevel() - 1)

	local duration = ability:GetLevelSpecialValueFor("duration", ability:GetLevel() - 1)
	local mid = duration / 2
	local height = 250
	local jump = height/(mid/0.03)
	local time_elapsed = 0

	local connect = target:GetAbsOrigin()
	local direction = target:GetForwardVector()
	local distance = math.random(min, max)
	print(mid, jump, distance)
	local forward = distance/(duration/0.03)
	local moved = 0
	local point = (direction * distance) + connect

	local targetParticle = ParticleManager:CreateParticle("particles/units/heroes/hero_gyrocopter/gyro_guided_missile_target.vpcf", PATTACH_CUSTOMORIGIN, target)
	ParticleManager:SetParticleControl(targetParticle, 0, point)
	Timers:CreateTimer(duration, function()
		StopEffect(target, "particles/units/heroes/hero_gyrocopter/gyro_guided_missile_target.vpcf")
	end)

	Timers:CreateTimer(0, function()
		local ground_position = GetGroundPosition(target:GetAbsOrigin() , target)
		time_elapsed = time_elapsed + 0.03
		local nextPoint = target:GetAbsOrigin() + (direction * 55)
		if not GridNav:IsTraversable(nextPoint) or GridNav:IsBlocked(nextPoint) then
			print('checking')
			local testPoint1 = target:GetAbsOrigin() + Vector(0,32,0) -- UP
			local testPoint2 = target:GetAbsOrigin() + Vector(32,0,0) -- Right
			local testPoint3 = target:GetAbsOrigin() + Vector(0,-32,0) -- Down
			local testPoint4 = target:GetAbsOrigin() + Vector(-32,0,0) -- Left
			local newDirection = direction
			if not GridNav:IsTraversable(testPoint1) or GridNav:IsBlocked(testPoint1) then
				newDirection = reflection(Vector(0,-1,0), direction)
			end
			if not GridNav:IsTraversable(testPoint2) or GridNav:IsBlocked(testPoint2) then
				newDirection = reflection(Vector(-1,0,0), direction)
			end
			if not GridNav:IsTraversable(testPoint3) or GridNav:IsBlocked(testPoint3) then
				newDirection = reflection(Vector(0,1,0), direction)
			end
			if not GridNav:IsTraversable(testPoint4) or GridNav:IsBlocked(testPoint4) then
				newDirection = reflection(Vector(1,0,0), direction)
			end
			if newDirection ~= direction then
				direction = newDirection
				print(moved)
				local newPoint = target:GetAbsOrigin() + newDirection * (distance-moved)
				newPoint.z = ground_position.z
				ParticleManager:SetParticleControl(targetParticle, 0, newPoint)
			end
		end
		if time_elapsed < mid then
			target:SetAbsOrigin(target:GetAbsOrigin() + Vector(0,0,jump) + direction*forward) -- Up
		else
			target:SetAbsOrigin(target:GetAbsOrigin() - Vector(0,0,jump) + direction*forward) -- Down
		end
		moved = moved + forward

		if target:GetAbsOrigin().z - ground_position.z <= 0 then
			return nil
		end

		return 0.03
	end)

	target:Stop()
end

function reflection( normal, ray )
	local reflection = ray - 2*ray:Dot(normal)*normal
	print(reflection)
	return reflection
end

function debug_teleport( keys )
	print(keys.target_points[1])
	FindClearSpaceForUnit(keys.caster, keys.target_points[1], true)
end