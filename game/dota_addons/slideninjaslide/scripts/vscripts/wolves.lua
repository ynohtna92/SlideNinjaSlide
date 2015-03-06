function GameMode:PopulateZonesWithWolves()
	for i=1,15 do
		GameMode:CreateWolves(i)
	end
	GameMode:MoveWolvesInActiveZones()
end

function GameMode:CreateWolves( zone )
	print("Creating wolves for zone " .. tostring(zone))
	for i,v in ipairs(Entities:FindAllByName("wolf_" .. tostring(zone))) do
		local wolf = CreateUnitByName("npc_wolf", v:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_NEUTRALS)
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
		local wolf = CreateUnitByName("npc_wolf", Vector(x,y,origin.z - bounds.Maxs.y + 1), true, nil, nil, DOTA_TEAM_NEUTRALS)
		wolf:SetForwardVector(Vector(RandomFloat(-1, 1), RandomFloat(-1, 1), 0))
		wolf.zone = zone
		wolf.isWolf = true
		table.insert(self.wolves, wolf)
	end
end

function GameMode:MoveWolvesInActiveZones()
	for i,v in ipairs(self.wolves) do
		if self.wolvesToMove[v.zone] then
			v.randomTimeTillMove = RandomInt(0,10)
			if v.randomMoveTimer ~= nil then
				Timers:RemoveTimer(v.randomMoveTimer)
			end
			v.randomMoveTimer = Timers:CreateTimer( v.randomTimeTillMove, function()
				if not v:IsAlive() then
					return nil
				end
				if not self.wolvesToMove[v.zone] then
					return nil
				end
				if GameMode:MoveWolf(v) then
					v.randomTimeTillMove = RandomInt(0,10)
					return v.randomTimeTillMove
				end
			end)
		end
	end
end

function GameMode:MoveWolf( wolf )
	for i=1,5 do        -- try x times to get a proper move location.
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

function GameMode:DestroyAllWolves(  )
	deleteUnitsInTable( self.wolves )
end
