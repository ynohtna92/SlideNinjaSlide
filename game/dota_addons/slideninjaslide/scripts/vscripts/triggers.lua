require('physics')

function OnStartTouchIce (trigger)
	print("Start Ice")
	if trigger.activator.slide and trigger.activator:HasModifier("thaw_aura") then
		return
	end
	-- Turn on Slide

	if not IsPhysicsUnit(trigger.activator) then
		return
	end

	trigger.activator:Hibernate(false)
	trigger.activator:PreventDI(true)

	trigger.activator.slideNumber = 0
	trigger.activator.thaw = false
	--local hscript = EntIndexToHScript( trigger.activator )
	GiveUnitDataDrivenModifier(trigger.activator, trigger.activator, trigger.activator.skateAnimation, -1)

	trigger.activator:OnPhysicsFrame(function(unit)
		-- check for modifiers
		if trigger.activator:HasModifier("modifier_leap_of_faith_datadriven") then
			trigger.activator:SetPhysicsVelocity(Vector(0,0,0))
			trigger.activator:SetPhysicsAcceleration(Vector(0,0,0))
		elseif trigger.activator:HasModifier("thaw_aura") or trigger.activator:HasModifier("modifier_leap_of_gayness_datadriven") or trigger.activator:HasModifier("modifier_behind_datadriven") then
			if not trigger.activator.thaw then
				trigger.activator:StopPhysicsSimulation()
				trigger.activator.thaw = true
				trigger.activator:SetPhysicsVelocity(Vector(0,0,0))
				trigger.activator:PreventDI(false)
				trigger.activator:RemoveModifierByName(trigger.activator.skateAnimation)
				print("Thawed")
			end
		else  -- if no modifiers 
			if trigger.activator.thaw then
				trigger.activator:StartPhysicsSimulation()
				trigger.activator:PreventDI(true)
				trigger.activator.thaw = false
				GiveUnitDataDrivenModifier(trigger.activator, trigger.activator, trigger.activator.skateAnimation, -1)
				print("Unthawed")
			end

			local direction = trigger.activator:GetForwardVector()
			local multiplier = 1
			if trigger.activator:HasModifier("modifier_tokyo_drift") then
				multiplier = 2.25
			end

			trigger.activator:SetPhysicsVelocity(direction * trigger.activator:GetIdealSpeed() * 1.2 * multiplier)

			if trigger.activator.slideNumber == 3 then
				trigger.activator:Stop()
				trigger.activator.slideNumber = 0
			else
				trigger.activator.slideNumber = trigger.activator.slideNumber + 1
			end
		end
	end)

	trigger.activator:Stop()
	trigger.activator.slide = true
	print("Slide on")
end

function OnEndTouchIce (trigger)
	print("End Ice")
	if not trigger.activator then
		return
	end
	if not IsPhysicsUnit(trigger.activator) then
		return
	end
	if not trigger.activator.slide and trigger.activator:HasModifier("thaw_aura") then
		return
	end
	-- Turn off Slide
	trigger.activator:OnPhysicsFrame(nil)
	trigger.activator:PreventDI(false)
	trigger.activator:Stop()

	trigger.activator:RemoveModifierByName(trigger.activator.skateAnimation)

	trigger.activator:SetPhysicsVelocity(Vector(0,0,0))
	trigger.activator:SetPhysicsAcceleration(Vector(0,0,0))

	trigger.activator.slide = false

	FindClearSpaceForUnit(trigger.activator, trigger.activator:GetAbsOrigin(), false)
	print("Slide off")
end

function OnStartTouchWin( trigger )
	print("Win Trigger")
	GameMode:LevelCompleted(trigger.activator)
end

function OnStartTouchSafe( trigger )
	GameMode:SafetyReached(trigger)
end