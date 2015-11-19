--[[
	Items
]]

function IntellectBonusUsed( event )
	local picker = event.caster
	local tome = event.ability
	local statBonus = event.bonus_stat

	if picker:IsRealHero() == false then
		picker = picker:GetPlayerOwner():GetAssignedHero()
	end
	if picker:HasModifier("bonus_intellect_modifier") == false then
		tome:ApplyDataDrivenModifier( picker, picker, "bonus_intellect_modifier", nil)
		picker:SetModifierStackCount("bonus_intellect_modifier", picker, statBonus)
	else
		picker:SetModifierStackCount("bonus_intellect_modifier", picker, (picker:GetModifierStackCount("bonus_intellect_modifier", picker) + statBonus))
	end
	PopupIntTome(picker, statBonus)
end

function StrengthBonusUsed( event )
	local picker = event.caster
	local tome = event.ability
	local statBonus = event.bonus_stat

	if picker:IsRealHero() == false then
		picker = picker:GetPlayerOwner():GetAssignedHero()
	end
	if picker:HasModifier("bonus_strength_modifier") == false then
		tome:ApplyDataDrivenModifier( picker, picker, "bonus_strength_modifier", nil)
		picker:SetModifierStackCount("bonus_strength_modifier", picker, statBonus)
	else
		picker:SetModifierStackCount("bonus_strength_modifier", picker, (picker:GetModifierStackCount("bonus_strength_modifier", picker) + statBonus))
	end
	PopupStrTome(picker, statBonus)
end

function ReplenishMana( event )
	event.target:GiveMana(event.mana_amount)
	PopupMana(event.caster, event.mana_amount)
end

function PowerUpExp( event )
	event.caster:AddExperience(event.experience, false, false)
end

function PowerUpLevel( event )
	event.caster:HeroLevelUp(true)
end

function UltimateGayPotion( event )
	local caster = event.caster
	local ability = event.ability
	local time_flow = 0.0020833333
	local time_elapsed = 0
	local start_time_of_day = GameRules:GetTimeOfDay()
	local end_time_of_day = start_time_of_day + event.duration * time_flow
	if end_time_of_day >= 1 then end_time_of_day = end_time_of_day - 1 end

	-- Setting it to the middle of the night
	GameRules:SetTimeOfDay(0)

	-- Using a timer to keep the time as middle of the night and once Darkness is over, normal day resumes
	Timers:CreateTimer(1, function()
		if time_elapsed < event.duration then
			GameRules:SetTimeOfDay(0)
			time_elapsed = time_elapsed + 1
			return 1
		else
			GameRules:SetTimeOfDay(end_time_of_day)
			return nil
		end
	end)

	for _,v in ipairs(GameMode.wolves) do
		ability:ApplyDataDrivenModifier( v, v, "modifier_item_ultimate_gay_potion", nil)
	end
end

function GayTrapPlant( event )
	local caster = event.caster
	local target_point = event.target_points[1]
	local ability = event.ability

	local modifier_gay_trap = event.modifier_gay_trap
	local modifier_gay_trap_thinker = event.modifier_gay_trap_thinker

	local activation_time = ability:GetLevelSpecialValueFor("activation_time", 0)

	local gay_trap = CreateUnitByName("npc_gay_trap", target_point, false, nil, nil, caster:GetTeamNumber())
	gay_trap:SetRenderColor(255, 0, 255)
	ability:ApplyDataDrivenModifier(caster, gay_trap, modifier_gay_trap, {})
	ability:ApplyDataDrivenModifier(caster, gay_trap, modifier_gay_trap_thinker, {})
end

function GayTrapTracker( event )
	local target = event.target

	local trigger_radius = event.radius
	local explode_delay = event.activation_time

	local target_team = DOTA_UNIT_TARGET_TEAM_ENEMY
	local target_type = DOTA_UNIT_TARGET_ALL
	local target_flag = DOTA_UNIT_TARGET_FLAG_INVULNERABLE

	local units = FindUnitsInRadius(target:GetTeamNumber(), target:GetAbsOrigin(), nil, trigger_radius, target_team, target_type, target_flag, FIND_CLOSEST, false)

	if #units > 0 then
		Timers:CreateTimer(explode_delay, function()
			if target:IsAlive() then
				target:ForceKill(true)
			end
		end)
	end
end

function GayTrapDestroyAll()
	local traps = Entities:FindAllByModel("models/heroes/techies/fx_techiesfx_mine.vmdl")
	for _,v in ipairs(traps) do
		v:RemoveSelf()
	end
end

function UltimateGayPotionUnitStop( event )
	local unit = event.target
	unit:Stop()
end