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

function debug_teleport( keys )
	print(keys.target_points[1])
	FindClearSpaceForUnit(keys.caster, keys.target_points[1], true)
end