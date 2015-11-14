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

function UltimateGayPotionUnitStop( event )
	local unit = event.target
	unit:Stop()
end