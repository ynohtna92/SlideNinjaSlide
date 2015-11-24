function GameMode:PopulateZonesWithWolves()
	for i=1,15 do
		GameMode:CreateWolves(i)
	end
	GameMode:MoveWolvesInActiveZones()
end

function GameMode:CreateWolves( zone )
	print("Creating wolves for zone " .. tostring(zone))
	for i,v in ipairs(Entities:FindAllByName("wolf_" .. tostring(zone))) do
		local wolf = CreateUnitByName(self.gameHeros[self.gameTheme][2], v:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_NEUTRALS)
		wolf:SetForwardVector(Vector(RandomFloat(-1, 1), RandomFloat(-1, 1), 0))
		wolf.zone = zone
		wolf.isWolf = true
		table.insert(self.wolves, wolf)
	end
end

function GameMode:CreateWolvesNextRound()
	for i=1,15 do
		GameMode:CreateWolvesRandom(i, self.wolvesPerRound[i])
		print(i, self.wolvesPerRound[i])
	end
end

function GameMode:CreateWolvesRandom( zone , number )
	local object = Entities:FindByName(nil, "trigger_ice_slide_" .. tostring(zone))
	local bounds = object:GetBounds()
	local origin = object:GetAbsOrigin()
	for i=1,tonumber(number) do
		local x = RandomFloat(origin.x + bounds.Mins.x, origin.x + bounds.Maxs.x)
		local y = RandomFloat(origin.y + bounds.Mins.y, origin.y + bounds.Maxs.y)
		local wolf = CreateUnitByName(self.gameHeros[self.gameTheme][2], Vector(x,y,origin.z - bounds.Maxs.y + 1), true, nil, nil, DOTA_TEAM_NEUTRALS)
		wolf:SetForwardVector(Vector(RandomFloat(-1, 1), RandomFloat(-1, 1), 0))
		wolf.zone = zone
		wolf.isWolf = true
		table.insert(self.wolves, wolf)
	end
end

function GameMode:MoveWolvesInActiveZones()
	for i,v in ipairs(self.wolves) do
		if self.wolvesToMove[v.zone] then
			v.randomTimeTillMove = RandomInt(0,100)/10
			if v.randomMoveTimer ~= nil then
				Timers:RemoveTimer(v.randomMoveTimer)
			end
			v.randomMoveTimer = Timers:CreateTimer( v.randomTimeTillMove, function()
				if v:IsNull() then
					return nil
				end

				if not v:IsAlive() then
					return nil
				end
				if not self.wolvesToMove[v.zone] then
					return nil
				end
				if GameMode:MoveWolf(v) then
					v.randomTimeTillMove = RandomInt(0,100)/10
					return v.randomTimeTillMove
				end
				return 3
			end)
		end
	end
end

function GameMode:MoveWolf( wolf )
	if wolf.fleeing and not wolf:IsIdle() then
		return false
	elseif wolf.fleeing and wolf:IsIdle() then
		wolf.fleeing = false
	end
	for i=1,10 do        -- try x times to get a proper move location.
		local posToMove = wolf:GetAbsOrigin() + RandomVector(math.random(100,600))
		if self:IsPointWithinZone(posToMove, Entities:FindByName(nil, "trigger_ice_slide_" .. wolf.zone)) then
			wolf:MoveToPosition(posToMove)
			return true
		end
	end
	return false
end

function GameMode:IsPointWithinZone( point , zone)
	return isPointWithinEntity(point, zone)
end

function GameMode:IsPointInvalid( point )
	if not GridNav:IsTraversable(point) or GridNav:IsBlocked(point) then
		return true
	end
	return false
end

function GameMode:AssignWolfRect( wolf )
	wolf.wolfRect = self.wolfRects[1]
	for i,v in ipairs(self.wolfRects) do
		if isPointWithinRectangle( wolf:GetAbsOrigin(), self.wolfRects[i] ) then
			wolf.wolfRect = self.wolfRects[i]
		end
	end
end

function GameMode:FleeWolf( point, wolf )
	-- ScareWolf away from point.
	local wolfABS = wolf:GetAbsOrigin()
	local moveTo = wolfABS + (wolfABS - point):Normalized()*500
	local lastValid = wolfABS
	local endPoint = moveTo
	local midpoints = math.ceil((wolfABS - endPoint):Length() / 32)
	local navConnect = false
	local index = 1
	while not navConnect and index < midpoints do
		lastPoint = wolfABS
		wolfABS = wolfABS + (endPoint - wolfABS):Normalized() * 32 * index
		navConnect = not GridNav:IsTraversable(wolfABS) or GridNav:IsBlocked(wolfABS) or not self:IsPointWithinZone(wolfABS, Entities:FindByName(nil, "trigger_ice_slide_".. wolf.zone))
		index = index + 1
	end
	if navConnect then
		moveTo = lastPoint
	end
	if self:IsPointWithinZone(moveTo, Entities:FindByName(nil, "trigger_ice_slide_".. wolf.zone)) then
		wolf:MoveToPosition(moveTo)
		wolf.fleeing = true
	end
end

function GameMode:AttackUnit( unit, wolf )
	local bloodParticle = ParticleManager:CreateParticle("particles/units/heroes/hero_phantom_assassin/phantom_assassin_crit_impact.vpcf", PATTACH_CUSTOMORIGIN, unit)
	ParticleManager:SetParticleControl(bloodParticle, 0, unit:GetAbsOrigin() + Vector(0,0,100))
	ParticleManager:SetParticleControl(bloodParticle, 1, wolf:GetAbsOrigin())
	ParticleManager:SetParticleControlForward(bloodParticle, 1, (wolf:GetAbsOrigin() - unit:GetAbsOrigin()):Normalized() )
	wolf:StartGesture(ACT_DOTA_ATTACK)
	EmitSoundOn( "n_creep_Melee.Attack", wolf )
end

function GameMode:DestroyAllWolves(  )
	deleteUnitsInTable( self.wolves )
end

function GameMode:ReviveAllWolves( )
	for i,v in ipairs(self.wolves) do
		if not v:IsNull() then
			if v:IsAlive() then
				v:SetHealth(v:GetMaxHealth())
			end
			if not v:IsAlive() then
				v:RespawnUnit()
				print('respawning wolf')
			end
		end
	end
	for i,v in ipairs(self.wolvesHeaven) do
		local wolf = CreateUnitByName(self.gameHeros[self.gameTheme][2], v[1], true, nil, nil, DOTA_TEAM_NEUTRALS)
		wolf:SetForwardVector(Vector(RandomFloat(-1, 1), RandomFloat(-1, 1), 0))
		wolf.zone = v[2]
		wolf.isWolf = true
		table.insert(self.wolves, wolf)
		print(v[1], v[2])
	end
	self.wolvesHeaven = {}
end
