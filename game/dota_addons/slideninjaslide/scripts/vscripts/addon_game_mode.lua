-- Generated from template
-- module_loader by Adynathos.
BASE_MODULES = {
	'util',
	'timers',
	'physics',
	--colliders_test,
	'lib.statcollection',
	'slide_ninja_slide',
	'wolves',
}

local function load_module(mod_name)
	-- load the module in a monitored environment
	local status, err_msg = pcall(function()
		require(mod_name)
	end)

	if status then
		log(' module ' .. mod_name .. ' OK')
	else
		err(' module ' .. mod_name .. ' FAILED: '..err_msg)
	end
end

-- Load all modules
for i, mod_name in pairs(BASE_MODULES) do
	load_module(mod_name)
end

--require('util')
--require('physics')
--require('slide_ninja_slide')
--require('wolves')

--[[if CAddonTemplateGameMode == nil then
	CAddonTemplateGameMode = class({})
end]]

function Precache( context )
	--[[
		Precache things we know we'll use.  Possible file types include (but not limited to):
			PrecacheResource( "model", "*.vmdl", context )
			PrecacheResource( "soundfile", "*.vsndevts", context )
			PrecacheResource( "particle", "*.vpcf", context )
			PrecacheResource( "particle_folder", "particles/folder", context )
	]]

	-- Particles
	PrecacheResource("particle", "particles/units/heroes/hero_omniknight/omniknight_guardian_angel_ally.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_doom_bringer/doom_bringer_doom.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_silencer/silencer_last_word.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_silencer/silencer_last_word_status.vpcf", context)

	PrecacheResource("particle", "particles/silencer_last_word_status_blue/silencer_last_word_status_blue.vpcf", context)
	PrecacheResource("particle", "particles/silencer_last_word_status_teal/silencer_last_word_status_teal.vpcf", context)
	PrecacheResource("particle", "particles/silencer_last_word_status_purple/silencer_last_word_status_purple.vpcf", context)
	PrecacheResource("particle", "particles/silencer_last_word_status_yellow/silencer_last_word_status_yellow.vpcf", context)
	PrecacheResource("particle", "particles/silencer_last_word_status_orange/silencer_last_word_status_orange.vpcf", context)
	PrecacheResource("particle", "particles/silencer_last_word_status_pink/silencer_last_word_status_pink.vpcf", context)
	PrecacheResource("particle", "particles/silencer_last_word_status_lightgreen/silencer_last_word_status_lightgreen.vpcf", context)
	PrecacheResource("particle", "particles/silencer_last_word_status_lightblue/silencer_last_word_status_lightblue.vpcf", context)
	PrecacheResource("particle", "particles/silencer_last_word_status_green/silencer_last_word_status_green.vpcf", context)
	PrecacheResource("particle", "particles/silencer_last_word_status_brown/silencer_last_word_status_brown.vpcf", context)

	--[[
	PrecacheResource("particle_folder", "particles/silencer_last_word_status_blue", context)
	PrecacheResource("particle_folder", "particles/silencer_last_word_status_teal", context)
	PrecacheResource("particle_folder", "particles/silencer_last_word_status_purple", context)
	PrecacheResource("particle_folder", "particles/silencer_last_word_status_yellow", context)
	PrecacheResource("particle_folder", "particles/silencer_last_word_status_orange", context)
	PrecacheResource("particle_folder", "particles/silencer_last_word_status_pink", context)
	PrecacheResource("particle_folder", "particles/silencer_last_word_status_lightgreen", context)
	PrecacheResource("particle_folder", "particles/silencer_last_word_status_lightblue", context)
	PrecacheResource("particle_folder", "particles/silencer_last_word_status_green", context)
	PrecacheResource("particle_folder", "particles/silencer_last_word_status_brown", context)
	]]

	-- Entire Heros
	PrecacheUnitByNameSync("npc_dota_hero_antimage", context)

	-- Sounds
	PrecacheResource( "soundfile", "soundevents/slideninjaslide_sounds_custom.vsndevts", context )
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_omniknight.vsndevts", context)
end

-- Create the game mode when we activate
function Activate()
	GameRules.AddonTemplate = GameMode()
	GameRules.AddonTemplate:InitGameMode()
end