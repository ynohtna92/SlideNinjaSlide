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

--[[Author: Noya
	Date: 09.08.2015.
	Hides all dem hats
]]
function HideWearables( event )
	local hero = event.caster
	local ability = event.ability

	hero.hiddenWearables = {} -- Keep every wearable handle in a table to show them later
    local model = hero:FirstMoveChild()
    while model ~= nil do
        if model:GetClassname() == "dota_item_wearable" then
            model:AddEffects(EF_NODRAW) -- Set model hidden
            table.insert(hero.hiddenWearables, model)
        end
        model = model:NextMovePeer()
    end
end

function ShowWearables( event )
	local hero = event.caster

	for i,v in pairs(hero.hiddenWearables) do
		v:RemoveEffects(EF_NODRAW)
	end
end

function RemoveSkateAnimation( unit )
	unit:RemoveModifierByName(unit.skateAnimation)
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

function DickClap( keys )
	local ability = keys.ability
	local radius = ability:GetLevelSpecialValueFor("radius", ability:GetLevel() - 1)

	local target_team = DOTA_UNIT_TARGET_TEAM_ENEMY
	local target_type = DOTA_UNIT_TARGET_ALL
	local target_flag = DOTA_UNIT_TARGET_FLAG_INVULNERABLE

	local units = FindUnitsInRadius(keys.caster:GetTeamNumber(), keys.caster:GetAbsOrigin(), nil, radius, target_team, target_type, target_flag, FIND_CLOSEST, false)

	if #units > 0 then
		for _,v in ipairs(units) do
			GameMode:FleeWolf( keys.caster:GetAbsOrigin(), v)
		end
	end
end

function BladeFuryFlee( keys )
	local caster = keys.caster
	local target = keys.target
	GameMode:FleeWolf( caster:GetAbsOrigin(), target )
end

function BladeFuryStop( keys )
	local caster = keys.caster
	caster:StopSound("Hero_Juggernaut.BladeFuryStart")
end

function DoomStopSound( keys )
	print('DoomSoundStop')
	local unit = keys.unit
	StopSoundEvent("Hero_DoomBringer.Doom", unit)
end

function CycloneStopSound( keys )
	local unit = keys.target
	StopSoundEvent("Brewmaster_Storm.Cyclone", unit)
end

function CycloneUnitStart( keys )
	local target = keys.target
	local target_origin = target:GetAbsOrigin()
	local position = Vector(target_origin.x, target_origin.y, target_origin.z)
	local ability = keys.ability
	local duration = ability:GetLevelSpecialValueFor("duration", ability:GetLevel() - 1)
	target.cyclone_forward_vector = target:GetForwardVector()
	local total_degrees = 20

	local ground_position = GetGroundPosition(position, target)
	local cyclone_initial_height = 250 + ground_position.z
	local cyclone_min_height = 200 + ground_position.z
	local cyclone_max_height = 350 + ground_position.z
	local tornado_start = GameRules:GetGameTime()

	-- Height per time calculation
	local time_to_reach_initial_height = duration / 10  --1/10th of the total cyclone duration will be spent ascending and descending to and from the initial height.
	local initial_ascent_height_per_frame = ((cyclone_initial_height - position.z) / time_to_reach_initial_height) * .03  --This is the height to add every frame when the unit is first cycloned, and applies until the caster reaches their max height.
	
	local up_down_cycle_height_per_frame = initial_ascent_height_per_frame / 3  --This is the height to add or remove every frame while the caster is in up/down cycle mode.
	if up_down_cycle_height_per_frame > 7.5 then  --Cap this value so the unit doesn't jerk up and down for short-duration cyclones.
		up_down_cycle_height_per_frame = 7.5
	end
	
	local final_descent_height_per_frame = nil  --This is calculated when the unit begins descending.

	-- Time to go down
	local time_to_stop_fly = duration - time_to_reach_initial_height

	-- Loop up and down
	local going_up = true

	-- Loop every frame for the duration
	Timers:CreateTimer(function()
		local time_in_air = GameRules:GetGameTime() - tornado_start
		
		--Rotate as close to 20 degrees per .03 seconds (666.666 degrees per second) as possible, but such that the target lands facing their initial direction.
		if target.cyclone_degrees_to_spin == nil and duration ~= nil then
			local ideal_degrees_per_second = 666.666
			local ideal_full_spins = (ideal_degrees_per_second / 360) * duration
			ideal_full_spins = math.floor(ideal_full_spins + .5)  --Round the number of spins to aim for to the closest integer.
			local degrees_per_second_ending_in_same_forward_vector = (360 * ideal_full_spins) / duration

			target.cyclone_degrees_to_spin = degrees_per_second_ending_in_same_forward_vector * .03
		end
		target:SetForwardVector(RotatePosition(Vector(0,0,0), QAngle(0, target.cyclone_degrees_to_spin, 0), target:GetForwardVector()))

		-- First send the target to the cyclone's initial height.
		if position.z < cyclone_initial_height and time_in_air <= time_to_reach_initial_height then
			--print("+",initial_ascent_height_per_frame,position.z)
			position.z = position.z + initial_ascent_height_per_frame
			target:SetAbsOrigin(position)
			return 0.03

		-- Go down until the target reaches the ground.
		elseif time_in_air > time_to_stop_fly and time_in_air <= duration then
			--Since the unit may be anywhere between the cyclone's min and max height values when they start descending to the ground,
			--the descending height per frame must be calculated when that begins, so the unit will end up right on the ground when the duration is supposed to end.
			if final_descent_height_per_frame == nil then
				local descent_initial_height_above_ground = position.z - ground_position.z
				--print("ground position: " .. GetGroundPosition(position, target).z)
				--print("position.z : " .. position.z)
				final_descent_height_per_frame = (descent_initial_height_above_ground / time_to_reach_initial_height) * .03
			end
			
			--print("-",final_descent_height_per_frame,position.z)
			position.z = position.z - final_descent_height_per_frame
			target:SetAbsOrigin(position)
			return 0.03

		-- Do Up and down cycles
		elseif time_in_air <= duration then
			-- Up
			if position.z < cyclone_max_height and going_up then 
				--print("going up")
				position.z = position.z + up_down_cycle_height_per_frame
				target:SetAbsOrigin(position)
				return 0.03

			-- Down
			elseif position.z >= cyclone_min_height then
				going_up = false
				--print("going down")
				position.z = position.z - up_down_cycle_height_per_frame
				target:SetAbsOrigin(position)
				return 0.03

			-- Go up again
			else
				--print("going up again")
				going_up = true
				return 0.03
			end

		-- End
		else
			--print(GetGroundPosition(target:GetAbsOrigin(), target))
			--print("End TornadoHeight")
		end
	end)

end

--[[Author: Pizzalol
	Date: 03.04.2015.
	Pulls the targets to the center]]
function Vacuum( keys )
	local caster = keys.caster
	local target = keys.target
	local target_location = target:GetAbsOrigin()
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	-- Ability variables
	local duration = ability:GetLevelSpecialValueFor("duration", ability_level)
	local radius = ability:GetLevelSpecialValueFor("radius", ability_level)
	local vacuum_modifier = keys.vacuum_modifier
	local remaining_duration = duration - (GameRules:GetGameTime() - target.vacuum_start_time)

	-- Targeting variables
	local target_teams = ability:GetAbilityTargetTeam() 
	local target_types = ability:GetAbilityTargetType() 
	local target_flags = ability:GetAbilityTargetFlags() 

	local units = FindUnitsInRadius(caster:GetTeamNumber(), target_location, nil, radius, target_teams, target_types, target_flags, FIND_CLOSEST, false)

	-- Calculate the position of each found unit
	for _,unit in ipairs(units) do
		local unit_location = unit:GetAbsOrigin()
		local vector_distance = target_location - unit_location
		local distance = (vector_distance):Length2D()
		local direction = (vector_distance):Normalized()

		-- Check if its a new vacuum cast
		-- Set the new pull speed if it is
		if unit.vacuum_caster ~= target then
			unit.vacuum_caster = target
			-- The standard speed value is for 1 second durations so we have to calculate the difference
			-- with 1/duration
			unit.vacuum_caster.pull_speed = distance * 1/0.6 * 1/30
		end

		-- Apply the stun and no collision modifier then set the new location
		if not unit:HasModifier(vacuum_modifier) then
			ability:ApplyDataDrivenModifier(caster, unit, vacuum_modifier, {duration = remaining_duration})
		end
		if distance > 10 then
			unit:SetAbsOrigin(unit_location + direction * unit.vacuum_caster.pull_speed)
		end
	end
end

--[[Author: Pizzalol
	Date: 03.04.2015.
	Track the starting vacuum time]]
function VacuumStart( keys )
	local target = keys.target

	target.vacuum_start_time = GameRules:GetGameTime()
end

function BehindStart( keys )
	local ability = keys.ability

	local target = keys.target
	local caster = keys.caster
	local initial_position = caster:GetAbsOrigin()
	local initial_fv = caster:GetForwardVector()

	local target_position = keys.target:GetAbsOrigin()
	local target_fv = keys.target:GetForwardVector()
	local target_bv = target_fv * -1

	local behind_position = target_position + target_bv * 100

	local duration = ability:GetLevelSpecialValueFor("duration", ability:GetLevel() - 1)

	RemoveSkateAnimation( caster )

	local fxIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_riki/riki_blink_strike.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(fxIndex, 0, initial_position)
	ParticleManager:SetParticleControl(fxIndex, 1, behind_position)
	FindClearSpaceForUnit(caster, behind_position, true)
	caster:SetForwardVector(target_fv)

	Timers:CreateTimer(duration, function()
		local fxIndex2 = ParticleManager:CreateParticle("particles/units/heroes/hero_riki/riki_blink_strike.vpcf", PATTACH_CUSTOMORIGIN, caster)

		ParticleManager:SetParticleControl(fxIndex2, 0, behind_position)
		ParticleManager:SetParticleControl(fxIndex2, 1, initial_position)
		FindClearSpaceForUnit(caster, initial_position, true)
		caster:SetForwardVector(initial_fv)
	end)
end

function BehindAttack( keys )
	local caster = keys.caster
	caster:StartGesture(ACT_DOTA_OVERRIDE_ABILITY_2)
	Timers:CreateTimer(0.30, function()
		caster:EmitSound("Hero_LoneDruid.TrueForm.Attack")
	end)
end

function TrueFormStart( event )
	local caster = event.caster
	local model = event.model
	local ability = event.ability

	-- Saves the original model
	if caster.caster_model == nil then 
		caster.caster_model = caster:GetModelName()
	end

	-- Sets the new model
	caster:SetOriginalModel(model)
end

-- Reverts back to the original model
function TrueFormEnd( event )
	local caster = event.caster
	local ability = event.ability
	caster:SetModel(caster.caster_model)
	caster:SetOriginalModel(caster.caster_model)
end

function SillynessTriggered( hero, unit )
	local ability = hero:FindAbilityByName("rgr_sillyness")
	local damage = ability:GetLevelSpecialValueFor("damage", ability:GetLevel() - 1)
	local damage_taken = ability:GetLevelSpecialValueFor("damage_taken", ability:GetLevel() - 1)
	if hero:GetHealth() > damage_taken then
		local damageTable = {
			victim = hero,
			attacker = unit,
			damage = damage_taken,
			damage_type = DAMAGE_TYPE_PURE,
		}
		ApplyDamage(damageTable)
		local damageTable2 = {
			victim = unit,
			attacker = hero,
			damage = damage,
			damage_type = DAMAGE_TYPE_PHYSICAL,
		}
		ApplyDamage(damageTable2)
		hero:StartGesture(ACT_DOTA_ATTACK)
		ability:ApplyDataDrivenModifier(hero, unit, "modifier_rgr_sillyness_target", {})
		return true
	else
		return false
	end
end

-- Store Hawk target to give to hawk unit when it spawns
function HawkStoreTarget( keys )
	local target = keys.target
	local caster = keys.caster
	caster.hawkTarget = target
end

function HawkTargetCheck( keys )
	local target = keys.target
	if target:IsIdle() and not target.hawkTarget:IsAlive() then
		target:ForceKill(false)
	end
end

function HawkAttack( keys )
	local target = keys.target
	local caster = keys.caster
	if caster.hawkTarget and caster.hawkTarget:IsAlive() then
		target.hawkTarget = caster.hawkTarget
		Timers:CreateTimer(0.10, function()
			target:MoveToTargetToAttack(caster.hawkTarget)
		end)
	else
		target:ForceKill(false)
	end
end

function HawkAttackFlee( keys )
	local unit = keys.attacker
	local target = keys.target
	GameMode:FleeWolf( unit:GetAbsOrigin(), target )
end

function HawkTargetKilled( keys )
	local unit = keys.attacker
	unit:ForceKill(false)
end

function QuilbeastSuicideDamage( keys )
	local caster = keys.caster
	local target = keys.target
	local ability = GameMode.vPlayerIDToHero[caster:GetPlayerOwnerID()]:FindAbilityByName("rgr_summon_quilbeast")
	local dmg = ability:GetLevelSpecialValueFor("damage", ability:GetLevel() - 1)

	local damageTable = {
		victim = target,
		attacker = caster,
		damage = dmg,
		damage_type = DAMAGE_TYPE_PHYSICAL,
	}
	ApplyDamage(damageTable)
end

function QuilbeastSuicide( keys )
	local caster = keys.caster
	caster:ForceKill(false)
end

function AttackClosestTarget( keys )
	local target = keys.target
	local ability = target:GetAbilityByIndex(0)
	local unit = GetClosestTargetInRadius( target, 2000 )
	if unit then
		Timers:CreateTimer(0.1, function()
			print("move to target")
			target:CastAbilityOnTarget( unit, ability, target:GetPlayerOwnerID())
		end)
	end
end

-- ShortestPathableTarget
function GetClosestTargetInRadius( unit, radius )
	local target_team = DOTA_UNIT_TARGET_TEAM_ENEMY
	local target_type = DOTA_UNIT_TARGET_ALL
	local target_flag = DOTA_UNIT_TARGET_FLAG_INVULNERABLE

	local units = FindUnitsInRadius(unit:GetTeamNumber(), unit:GetAbsOrigin(), nil, radius, target_team, target_type, target_flag, FIND_CLOSEST, false)

	local shortest = nil
	local target = nil

	if #units > 0 then
		for _,v in ipairs(units) do
			local s = GridNav:FindPathLength( unit:GetAbsOrigin(), v:GetAbsOrigin() )
			if shortest == nil or s < shortest then
				target = v
				shortest = s
			end
		end
	end
	return target
end

function GetFrontPoint( keys )
	local caster = keys.caster
	local fv = caster:GetForwardVector()
	local origin = caster:GetAbsOrigin()
	local distance = 200

	local front_point = origin + fv * distance
	local result = {}
	table.insert(result, front_point)
	return result
end

function SetUnitsMoveForward( keys )
	local caster = keys.caster
	local target = keys.target
	local fv = caster:GetForwardVector()
	target:SetForwardVector(fv)
end

function CycloneUnitEnd( keys )
	local target = keys.target
	if target.cyclone_forward_vector ~= nil then
		target:SetForwardVector(target.cyclone_forward_vector)
	end
	target.cyclone_degrees_to_spin = nil
end

function EvasionStart( keys )
	print('EvasionStart')
	local ability = keys.ability
	local hero = keys.target
	local time_to_enabled = ability:GetLevelSpecialValueFor("evasion", ability:GetLevel() - 1)
	if hero.evasionTimer ~= nil then
		Timers:RemoveTimer(hero.evasionTimer)
	end
	hero.evasionTimer = Timers:CreateTimer(time_to_enabled, function()
		print('EvasionRenewed')
		ability:ApplyDataDrivenModifier(hero, hero, keys.modifier, {})
	end)
end

-- Triggering Intensifies
function EvasionTriggered( hero, unit )
	hero:RemoveModifierByName("modifier_evasion_evade")
	local evasionParticle = ParticleManager:CreateParticle("particles/units/heroes/hero_templar_assassin/templar_assassin_refract_hit.vpcf", PATTACH_POINT_FOLLOW, hero)
	ParticleManager:SetParticleControlEnt(evasionParticle, 0, hero, PATTACH_POINT_FOLLOW, "attach_origin", hero:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(evasionParticle, 2, hero, PATTACH_POINT_FOLLOW, "attach_origin", hero:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlForward(evasionParticle, 1, (hero:GetAbsOrigin()-unit:GetAbsOrigin()):Normalized() )
end

-- This function is called when the unit hits a creep with the chemical rage modifier
function ChemicalRageOnHit( hero )
	if (hero:GetStrength()*0.01*hero:GetHealthPercent()) > RandomFloat(0,20) then
		hero:SetHealth(hero:GetHealth()-RandomFloat(0.01, hero:GetHealth() - 1))
		return true
	else
		return false
	end
end

--[[Author: Pizzalol
	Date: 18.01.2015.
	Checks if the target is an illusion, if true then it kills it
	otherwise the target model gets swapped into a frog]]
function voodoo_start( keys )
	local target = keys.target
	local model = keys.model

	if target:IsIllusion() then
		target:ForceKill(true)
	else
		if target.target_model == nil then
			target.target_model = target:GetModelName()
		end

		target:SetOriginalModel(model)
	end
end

--[[Author: Pizzalol
	Date: 18.01.2015.
	Reverts the target model back to what it was]]
function voodoo_end( keys )
	local target = keys.target

	-- Checking for errors
	if target.target_model ~= nil then
		target:SetModel(target.target_model)
		target:SetOriginalModel(target.target_model)
	end
end

--[[
	Author: kritth
	Date: 10.01.2015
	Marks seen only to ally
]]
function ghostship_mark_allies( caster, ability, target )
	local allHeroes = HeroList:GetAllHeroes()
	local delay = ability:GetLevelSpecialValueFor( "tooltip_delay", ability:GetLevel() - 1 )
	local particleName = "particles/units/heroes/hero_kunkka/kunkka_ghostship_marker.vpcf"
	
	for k, v in pairs( allHeroes ) do
		if v:GetPlayerID() and v:GetTeam() == caster:GetTeam() then
			local fxIndex = ParticleManager:CreateParticleForPlayer( particleName, PATTACH_ABSORIGIN, v, PlayerResource:GetPlayer( v:GetPlayerID() ) )
			ParticleManager:SetParticleControl( fxIndex, 0, target )
			
			EmitSoundOnClient( "Ability.pre.Torrent", PlayerResource:GetPlayer( v:GetPlayerID() ) )
			
			-- Destroy particle after delay
			Timers:CreateTimer( delay, function()
					ParticleManager:DestroyParticle( fxIndex, false )
					return nil
				end
			)
		end
	end
end

--[[
	Author: kritth
	Date: 10.01.2015
	Start traversing the ship
]]
function ghostship_start_traverse( keys )
	-- Variables
	local caster = keys.caster
	local ability = keys.ability
	local casterPoint = caster:GetAbsOrigin()
	local targetPoint = keys.target_points[1]
	local spawnDistance = ability:GetLevelSpecialValueFor( "ghostship_distance", ability:GetLevel() - 1 )
	local projectileSpeed = ability:GetLevelSpecialValueFor( "ghostship_speed", ability:GetLevel() - 1 )
	local radius = ability:GetLevelSpecialValueFor( "ghostship_width", ability:GetLevel() - 1 )
	local stunDelay = ability:GetLevelSpecialValueFor( "tooltip_delay", ability:GetLevel() - 1 )
	local stunDuration = ability:GetLevelSpecialValueFor( "stun_duration", ability:GetLevel() - 1 )
	local damage = ability:GetAbilityDamage()
	local damageType = ability:GetAbilityDamageType()
	local targetBuffTeam = DOTA_UNIT_TARGET_TEAM_FRIENDLY
	local targetImpactTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local targetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL
	local targetFlag = DOTA_UNIT_TARGET_FLAG_NONE
	
	-- Get necessary vectors
	local forwardVec = targetPoint - casterPoint
		forwardVec = forwardVec:Normalized()
	local backwardVec = casterPoint - targetPoint
		backwardVec = backwardVec:Normalized()
	local spawnPoint = casterPoint + ( spawnDistance * backwardVec )
	local impactPoint = casterPoint + ( spawnDistance * forwardVec )
	local velocityVec = Vector( forwardVec.x, forwardVec.y, 0 )
	
	-- Show visual effect
	ghostship_mark_allies( caster, ability, impactPoint )
	
	-- Spawn projectiles
	local projectileTable = {
		Ability = ability,
		EffectName = "particles/units/heroes/hero_kunkka/kunkka_ghost_ship.vpcf",
		vSpawnOrigin = spawnPoint,
		fDistance = spawnDistance * 2,
		fStartRadius = radius,
		fEndRadius = radius,
		fExpireTime = GameRules:GetGameTime() + 5,
		Source = caster,
		bHasFrontalCone = false,
		bReplaceExisting = false,
		bProvidesVision = false,
		iUnitTargetTeam = targetImpactTeam,
		iUnitTargetType = targetType,
		vVelocity = velocityVec * projectileSpeed
	}
	ProjectileManager:CreateLinearProjectile( projectileTable )
	
	-- Create timer for crashing
	Timers:CreateTimer( stunDelay, function()
		local units = FindUnitsInRadius(
			caster:GetTeamNumber(), impactPoint, caster, radius, targetImpactTeam,
			targetType, targetFlag, FIND_ANY_ORDER, false
		)
		
		-- Fire sound event
		local dummy = CreateUnitByName( "npc_dummy_unit", impactPoint, false, caster, caster, caster:GetTeamNumber() )
		StartSoundEvent( "Ability.Ghostship.crash", dummy )
		dummy:ForceKill( true )
		
		-- Stun and damage enemies
		for k, v in pairs( units ) do
			if not v:IsMagicImmune() then
				local damageTable = {
					victim = v,
					attacker = caster,
					damage = damage,
					damage_type = damageType
				}
				ApplyDamage( damageTable )
			end
			
			v:AddNewModifier( caster, nil, "modifier_stunned", { duration = stunDuration } )
		end
		
		return nil	-- Delete timer
	end)
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