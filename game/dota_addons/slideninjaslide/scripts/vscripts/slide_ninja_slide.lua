--[[
Last modified: 06/11/2017
Website: http://steamcommunity.com/sharedfiles/filedetails/?id=401429935
Author: A_Dizzle <anthony@hatinacat.com>
Co-Author: Myll <stephennf@gmail.com>
]]

print('[SNS] slide_ninja_slide.lua')

DEBUG = false
THINK_TIME = 0.1

VERSION = "B061117"

ROUNDS = 4
LIVES = 3

STARTING_GOLD = 100
GOLD_PER_ROUND = 100
GOLD_BONUS_ROUND_WINNER = 200
EXP_BONUS_ROUND_WINNER = 300
EXP_SAFE_ZONE = 150

ITEMS_ON_MAP = 5
-- EXP_REWARDS_MATH = 150 x 1.08^(Player_score)

-- Map Settings

ENABLE_HERO_RESPAWN = false              -- Should the heroes automatically respawn on a timer or stay dead until manually respawned
UNIVERSAL_SHOP_MODE = false             -- Should the main shop contain Secret Shop items as well as regular items
ALLOW_SAME_HERO_SELECTION = true        -- Should we let people select the same hero as each other

HERO_SELECTION_TIME = 1.0              -- How long should we let people select their hero?
PRE_GAME_TIME = 0.0                    -- How long after people select their heroes should the horn blow and the game start?
POST_GAME_TIME = 60.0                   -- How long should we let people look at the scoreboard before closing the server automatically?

GOLD_PER_TICK = 0                     -- How much gold should players get per tick?
GOLD_TICK_TIME = 0                      -- How long should we wait in seconds between gold ticks?

RECOMMENDED_BUILDS_DISABLED = true     -- Should we disable the recommened builds for heroes (Note: this is not working currently I believe)
CAMERA_DISTANCE_OVERRIDE = 1600.0        -- How far out should we allow the camera to go?  1134 is the default in Dota

MINIMAP_ICON_SIZE = 500                 -- What icon size should we use for our heroes?
MINIMAP_CREEP_ICON_SIZE = 1             -- What icon size should we use for creeps?
MINIMAP_RUNE_ICON_SIZE = 500            -- What icon size should we use for runes?

BUYBACK_ENABLED = false                 -- Should we allow people to buyback when they die?

DISABLE_FOG_OF_WAR_ENTIRELY = true      -- Should we disable fog of war entirely for both teams?
--USE_STANDARD_DOTA_BOT_THINKING = false  -- Should we have bots act like they would in Dota? (This requires 3 lanes, normal items, etc)
USE_STANDARD_HERO_GOLD_BOUNTY = true    -- Should we give gold for hero kills the same as in Dota, or allow those values to be changed?

USE_CUSTOM_TOP_BAR_VALUES = true        -- Should we do customized top bar values or use the default kill count per team?
TOP_BAR_VISIBLE = true                  -- Should we display the top bar score/count at all?
SHOW_KILLS_ON_TOPBAR = true             -- Should we display kills only on the top bar? (No denies, suicides, kills by neutrals)  Requires USE_CUSTOM_TOP_BAR_VALUES

DISABLE_GOLD_SOUNDS = false             -- Should we disable the gold sound when players get gold?

END_GAME_ON_KILLS = false                -- Should the game end after a certain number of kills?

USE_CUSTOM_HERO_LEVELS = true           -- Should we allow heroes to have custom levels?
MAX_LEVEL = 12                          -- What level should we let heroes get to?
USE_CUSTOM_XP_VALUES = true             -- Should we use custom XP values to level up heroes, or the default Dota numbers?

SLIDE_VERSION = 1						-- Version 1 uses aaboxes, 2 uses PHYSICS_NAV_SLIDE
DROPPED_ITEM_RADIUS = 20

FORCE_PICKED_HERO = "npc_dota_hero_antimage"  -- What hero should we force all players to spawn as? (e.g. "npc_dota_hero_axe").  Use nil to allow players to pick their own hero.


XP_PER_LEVEL_TABLE = {}
for i=1,MAX_LEVEL do
  XP_PER_LEVEL_TABLE[i] = 50 * (i - 1) * (i + 2)
end


if GameMode == nil then
	print('[SNS] Creating slide_ninja_slide game mode')
	GameMode = class({})
end

function GameMode:InitGameMode()
	GameMode = self
	print('[SNS] Starting to load gamemode...')

	-- Setup rules
	GameRules:SetHeroSelectionTime( HERO_SELECTION_TIME )
	GameRules:GetGameModeEntity():SetThink( "OnThink", self, "GlobalThink", 2 )
	GameRules:SetHeroRespawnEnabled( ENABLE_HERO_RESPAWN )
	GameRules:SetSameHeroSelectionEnabled( ALLOW_SAME_HERO_SELECTION )
	GameRules:SetPreGameTime( PRE_GAME_TIME)
	GameRules:SetPostGameTime( POST_GAME_TIME )
	GameRules:SetUseCustomHeroXPValues ( USE_CUSTOM_XP_VALUES )
	GameRules:SetGoldPerTick( GOLD_PER_TICK )
	GameRules:SetGoldTickTime( GOLD_TICK_TIME )
	GameRules:SetHideKillMessageHeaders(true)
	-- GameRules:GetGameModeEntity():SetStashPurchasingDisabled(true) -- Broken??
	GameRules:GetGameModeEntity():SetWeatherEffectsDisabled(true)

	-- REBORN
	GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_GOODGUYS, 10 )
	GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_BADGUYS, 0 )
	GameRules:SetHeroMinimapIconScale(2)

	--mode = GameRules:GetGameModeEntity()
	--mode:SetFogOfWarDisabled(true)	

	if DEBUG then
		GameRules:SetUseUniversalShopMode( true )
	end
	print('[SNS] GameRules set')

	-- Filters
	GameRules:GetGameModeEntity():SetExecuteOrderFilter(Dynamic_Wrap(GameMode, "FilterExecuteOrder"), self)

	-- Hooks
	ListenToGameEvent('player_connect_full', Dynamic_Wrap(GameMode, 'OnConnectFull'), self)
	ListenToGameEvent('player_chat', Dynamic_Wrap(GameMode, 'PlayerSay'), self)
	ListenToGameEvent('player_connect', Dynamic_Wrap(GameMode, 'PlayerConnect'), self)
	ListenToGameEvent('game_rules_state_change', Dynamic_Wrap(GameMode, 'OnGameRulesStateChange'), self)
	ListenToGameEvent('npc_spawned', Dynamic_Wrap(GameMode, 'OnNPCSpawned'), self)
	ListenToGameEvent('entity_killed', Dynamic_Wrap(GameMode, 'OnEntityKilled'), self)
	ListenToGameEvent('dota_player_used_ability', Dynamic_Wrap(GameMode, 'OnAbilityUsed'), self)
	ListenToGameEvent('dota_item_purchased', Dynamic_Wrap(GameMode, 'OnItemPurchased'), self)
	ListenToGameEvent('dota_item_picked_up', Dynamic_Wrap(GameMode, 'OnItemPickedUp'), self)

	-- DEPRECIATED Scaleform UI
	Convars:RegisterCommand('player_say', function(...)
		local arg = {...}
		table.remove(arg,1)
		local sayType = arg[1]
		table.remove(arg,1)

		local cmdPlayer = Convars:GetCommandClient()
		keys = {}
		keys.ply = cmdPlayer
		keys.teamOnly = false
		keys.text = table.concat(arg, " ")

		if (sayType == 4) then
			-- Student messages
		elseif (sayType == 3) then
			-- Coach messages
		elseif (sayType == 2) then
			-- Team only
			keys.teamOnly = true
			-- Call your player_say function here like
			self:PlayerSay(keys)
		else
			-- All chat
			-- Call your player_say function here like
			self:PlayerSay(keys)
		end
	end, 'player say', 0)

	-- Round
	self.nCurrentRound = 1
	self.nMaxRounds = ROUNDS
	self.livesUsed = 0
	self.infinite = false
	self.doubleCheck = false
	self.canReset = false
	self.noReset = false -- Used to run things that should only be run once per player EVER!
	self.noChance = false -- Toggle game chances
	self.nDeaths = 0 -- Total deaths from all ninjas
	self.bSlide = true -- Toggle slide or run mode

	-- T.U.E Mode
	self.bTue = false 
	self.tueUnit = nil
	self.tueSpawn = Entities:FindByName(nil, "tue_spawn")
	self.tueTimerWaypoints = nil
	self.bTueChasing = false
	self.bBonusTue = true

	self.vPlayers = {}
	self.vRadiant = {}
	self.vDire = {}
	self.vSteamIds = {}
	self.vBots = {}
	self.vBroadcasters = {}
	self.vUserIds = {}
	self.vUserIdToPly = {}
	self.vPlayerIDToHero = {}
	self.bSeenWaitForPlayers = false

	-- PLAYER COLORS
	self.m_TeamColors = {}
	self.m_TeamColors[0] = { 50, 100, 220 } -- 49:100:218 / #3164DA
	self.m_TeamColors[1] = { 90, 225, 155 } -- 87:224:154 / #57E19A
	self.m_TeamColors[2] = { 170, 0, 160 } -- 171:0:156 / #AA00A0
	self.m_TeamColors[3] = { 210, 200, 20 } -- 211:203:16 / #D3CB14
	self.m_TeamColors[4] = { 215, 90, 5 } -- 214:87:8 / #D65705
	self.m_TeamColors[5] = { 210, 100, 150 } -- 210:97:153 / #D26496
	self.m_TeamColors[6] = { 130, 150, 80 } -- 130:154:80 / #829650
	self.m_TeamColors[7] = { 100, 190, 200 } -- 99:188:206 / #64BEC8
	self.m_TeamColors[8] = { 5, 110, 50 } -- 7:109:44 / #056E32
	self.m_TeamColors[9] = { 130, 80, 5 } -- 124:75:6 / #825005

	self.whitespace = {}

	self.haloParticles = {
		[1] = "particles/units/heroes/hero_silencer/silencer_last_word_status.vpcf",
		[2] = "particles/silencer_last_word_status_teal/silencer_last_word_status_teal.vpcf",
		[3] = "particles/silencer_last_word_status_purple/silencer_last_word_status_purple.vpcf",
		[4] = "particles/silencer_last_word_status_yellow/silencer_last_word_status_yellow.vpcf",
		[5] = "particles/silencer_last_word_status_orange/silencer_last_word_status_orange.vpcf",
		[6] = "particles/silencer_last_word_status_pink/silencer_last_word_status_pink.vpcf",
		[7] = "particles/silencer_last_word_status_lightgreen/silencer_last_word_status_lightgreen.vpcf",
		[8] = "particles/silencer_last_word_status_lightblue/silencer_last_word_status_lightblue.vpcf",
		[9] = "particles/silencer_last_word_status_green/silencer_last_word_status_green.vpcf",
		[10] = "particles/silencer_last_word_status_brown/silencer_last_word_status_brown.vpcf",
	}

	self.roundMessages = {
		[1] = "",
		[2] = "#slideninjaslide_round_message02",
		[3] = "#slideninjaslide_round_message03",
		[4] = "#slideninjaslide_round_message04",
		[5] = "#slideninjaslide_round_message05",
	}

	self.gameTheme = 1
	self.gameHeros = {
		[1] = {'npc_dota_hero_antimage', 'npc_wolf', 'scripts/music.kv'},
		[2] = {'npc_dota_hero_rattletrap', 'npc_mr_krabs', 'scripts/music_SB.kv'},
		[3] = {{'npc_dota_hero_kunkka', 'npc_dota_hero_chaos_knight', 'npc_dota_hero_alchemist', 'npc_dota_hero_omniknight', 'npc_dota_hero_beastmaster', 'npc_dota_hero_tidehunter', 'npc_dota_hero_abaddon', 'npc_dota_hero_lone_druid', 'npc_dota_hero_keeper_of_the_light', 'npc_dota_hero_juggernaut', 'npc_dota_hero_zuus', 'npc_dota_hero_centaur'}, 'npc_skin_head', 'scripts/music_RGR.kv'},
	}

	self.itemSpawns = {
		[1] = "item_potion_of_mana",
		[2] = "item_potion_of_speed",
		[3] = "item_boots_of_speed",
		[4] = "item_sobi_mask2",
		[5] = "item_pendant_of_energy",
		[6] = "item_pendant_of_mana",
		[7] = "item_socks_of_ultra_speed",
		[8] = "item_ultra_sobi_mask",
		[9] = "item_tome_of_experience",
		[10] = "item_tome_of_power",
	}

	--[[ Scoreborad updater
	self.scoreTimer = Timers:CreateTimer(2, function()
		self:UpdateScoreboard()
		return 0.5
	end)
	]]

	self.guardboxes = {}

	self.guardsxyz = {}
	self.guardsxyz[1] = {2560, 2275, 512, -2900, 2590, 0} -- 1 bottom
	self.guardsxyz[2] = {2900, 3502, 512, -2900, 3300, 0} -- 1 top
	self.guardsxyz[3] = {2585, 2597, 512, 2280, -2580, 0} -- 2 left
	self.guardsxyz[4] = {3478, 2900, 512, 3300, -2900, 0} -- 2 right
	self.guardsxyz[5] = {2900, -3300, 512, -2900, -3476, 0} -- 3 bottom
	self.guardsxyz[6] = {2554, -2280, 512, -2580, -2580, 0} -- 3 top
	self.guardsxyz[7] = {-3300, 1876, 512, -3476, -2900, 0} -- 4 left
	self.guardsxyz[8] = {-2280, 1710, 512, -2580, -2304, 0} -- 4 right
	self.guardsxyz[9] = {1792, 1710, 384, -2580, 1380, 0} -- 5 bottom
	self.guardsxyz[10] = {1792, 1700, 384, 1510, -1700, 0} -- 6 left
	self.guardsxyz[11] = {1792, -1800, 384, -1792, -1505, 0} -- 7 top
	self.guardsxyz[12] = {-1800, 1040, 384, -1510, -1792, 0} -- 8 right
	self.guardsxyz[13] = {1152, 1040, 384, -1792, 735, 0} -- 9 bottom
	self.guardsxyz[14] = {1152, 1040, 384, 870, -1152, 0} -- 10 left
	self.guardsxyz[15] = {1152, -870, 384, -1152, -1170, 0} -- 11 top
	self.guardsxyz[16] = {-896, 400, 384, -1170, -1152, 0} -- 12 right
	self.guardsxyz[17] = {530, 410, 384, -1170, 200, 0} -- 13 bottom
	self.guardsxyz[18] = {530, 400, 384, 300, -550, 0} -- 14 left
	self.guardsxyz[19] = {530, -300, 384, -500, -550, 0} -- 15 top

	self.wolves = {}
	self.wolvesHeaven = {}
	self.wolfHP = 550

	self.wolvesPerRound = {}
	self.wolvesPerRound[1] = 11
	self.wolvesPerRound[2] = 3
	self.wolvesPerRound[3] = 11
	self.wolvesPerRound[4] = 2
	self.wolvesPerRound[5] = 11
	self.wolvesPerRound[6] = 2
	self.wolvesPerRound[7] = 11
	self.wolvesPerRound[8] = 2
	self.wolvesPerRound[9] = 3
	self.wolvesPerRound[10] = 2
	self.wolvesPerRound[11] = 3
	self.wolvesPerRound[12] = 2
	self.wolvesPerRound[13] = 3
	self.wolvesPerRound[14] = 1
	self.wolvesPerRound[15] = 1

	-- Move the wolves in true zones only (reduce lag)
	self.wolvesToMove = {}
	self.wolvesToMove[1] = true
	for i=2,15 do
		self.wolvesToMove[i] = false
	end

	self.wolfRects = {}

	self.items = {}
	self.itemindex = 0

	self.ninjas = {}

	self.start = Entities:FindByName(nil, "start")

	self.walls = Entities:FindAllByName("wall") -- TUE MODE

	-- RGR
	if GetMapName() == "run_gay_run" then
		FORCE_PICKED_HERO = nil
		ROUNDS = 3
		self.nMaxRounds = ROUNDS
		EXP_BONUS_ROUND_WINNER = 500
		self.gameTheme = 3

		self.itemSpawns = {
			[1] = "item_bottle_of_seamen",
			[2] = "item_bottle_of_estrogen",
			[3] = "item_bottle_of_androgen",
			[4] = "item_lacoste_basic",
			[5] = "item_cosmopolitan",
			[6] = "item_penis_pump",
			[7] = "item_rubber",
			[8] = "item_penis_pump_deluxe",
			[9] = "item_kamasutra",
			[10] = "item_kamasutra_deluxe",
		}

		self.roundMessages = {
			[1] = "",
			[2] = "#slideninjaslide_round_message02_rgr",
			[3] = "#slideninjaslide_round_message03_rgr",
			[4] = "#slideninjaslide_round_message04_rgr",
			[5] = "",
		}
	end

	SpawnPoints = {}
	local goodguys = Entities:FindAllByClassname("info_player_start_goodguys")
	local badguys = Entities:FindAllByClassname("info_player_start_badguys")

	for i,v in ipairs(goodguys) do
		table.insert(SpawnPoints, v:GetAbsOrigin())
	end

	--[[
	for i,v in ipairs(badguys) do
		table.insert(SpawnPoints, v:GetAbsOrigin())
	end
	]]

	self.Thinker = Timers:CreateTimer(function()
		return self:OnThink()
	end)

	MusicPlayer:Init(self.gameHeros[self.gameTheme][3]) 
	ScoreBoard:Init()

	-- Don't end the game if everyone is unassigned
	SendToServerConsole("dota_surrender_on_disconnect 0")

	print('[SNS] Loading complete!')
end

--[[
	This function is called once and only once as soon as the first player (almost certain to be the server in local lobbies) loads in.
	It can be used to initialize state that isn't initializeable in InitGameMode() but needs to be done before everyone loads in.
]]
function GameMode:OnFirstPlayerLoaded()
	self:PopulateZonesWithWolves()
	self.itemDrops = Timers:CreateTimer(function()
		GameMode:SpawnItems()
		return 5
	end)

	if SLIDE_VERSION == 1 then
		GameMode:SetupGuards()
	end
end

-- Store teams, players and heroes
function GameMode:HeroInit( hero )
  local pID = hero:GetPlayerID()
  self.vPlayerIDToHero[pID] = hero
  if self.vPlayers[pID] ~= nil then
	return
  end
  self.vPlayers[pID] = pID
  --print('TeamNumber: '..hero:GetTeamNumber())
  if hero:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
	table.insert(self.vRadiant, pID)
  elseif hero:GetTeamNumber() == DOTA_TEAM_BADGUYS then
	table.insert(self.vDire, pID)
  end
end

mode = nil

-- This function is called as the first player loads and sets up the GameMode parameters
function GameMode:CaptureGameMode()
	if mode == nil then
		print("[SNS] CaptureGameMode")
		mode = GameRules:GetGameModeEntity()
		mode:SetFogOfWarDisabled( true ) -- BROKEN? not working on particles -> using ent_fov_revealer in hammer

		-- Hide some HUD elements
		--mode:SetHUDVisible(DOTA_HUD_VISIBILITY_TOP_HEROES, false)
		mode:SetHUDVisible(DOTA_HUD_VISIBILITY_TOP_SCOREBOARD, false)
		--mode:SetHUDVisible(DOTA_HUD_VISIBILITY_INVENTORY_COURIER, false) -- no courier
	--	mode:SetRecommendedItemsDisabled( RECOMMENDED_BUILDS_DISABLED ) BROKEN use entry below
		mode:SetHUDVisible( DOTA_HUD_VISIBILITY_SHOP_SUGGESTEDITEMS, false ) 
		--mode:SetHUDVisible(8, false)
		mode:SetTopBarTeamValuesOverride( USE_CUSTOM_TOP_BAR_VALUES )

		mode:SetCameraDistanceOverride( CAMERA_DISTANCE_OVERRIDE )
		mode:SetBuybackEnabled( BUYBACK_ENABLED )
		mode:SetUseCustomHeroLevels( USE_CUSTOM_HERO_LEVELS )
		mode:SetCustomHeroMaxLevel( MAX_LEVEL )
		mode:SetCustomXPRequiredToReachNextLevel( XP_PER_LEVEL_TABLE )
		mode:SetLoseGoldOnDeath( false )
		
		if FORCE_PICKED_HERO ~= nil then
			mode:SetCustomGameForceHero( FORCE_PICKED_HERO )
		end

		GameMode:OnFirstPlayerLoaded()
	end
end

function GameMode:PlayerConnect(keys)
	print('[SNS] PlayerConnect')
	--PrintTable(keys)

	if keys.bot == 1 then
		self.vBots[keys.userid] = 1
	end
end

-- This function is called once when the player fully connects and becomes "Ready" during Loading
function GameMode:OnConnectFull(keys)
	print ('[SNS] OnConnectFull')
	-- PrintTable(keys)
	GameMode:CaptureGameMode()

	local entIndex = keys.index
	-- The Player entity of the joining user
	local ply = EntIndexToHScript(entIndex)

	-- The Player ID of the joining player
	local playerID = ply:GetPlayerID()

	-- Update the user ID table with this user
	self.vUserIdToPly[keys.userid] = ply
	table.insert(self.vUserIds, ply)

	-- Update the Steam ID table
	self.vSteamIds[PlayerResource:GetSteamAccountID(playerID)] = ply

	-- If the player is a broadcaster flag it in the Broadcasters table
	if PlayerResource:IsBroadcaster(playerID) then
		self.vBroadcasters[keys.userid] = 1
		return
	end
end

-- The overall game state has changed
function GameMode:OnGameRulesStateChange(keys)
	print('[SNS] OnGameRulesStateChange')
	local newState = GameRules:State_Get()
	print('State: ' .. newState)
	if newState == DOTA_GAMERULES_STATE_WAIT_FOR_PLAYERS_TO_LOAD then
		self.bSeenWaitForPlayers = true
	elseif newState == DOTA_GAMERULES_STATE_INIT then
		--Timers:RemoveTimer("alljointimer")
	elseif newState == DOTA_GAMERULES_STATE_HERO_SELECTION then
		--GameMode:PostLoadPrecache()
		GameMode:OnAllPlayersLoaded()
	end
end

-- This function is called once when all players in the game have finished loading
function GameMode:OnAllPlayersLoaded()
	print('[SNS] OnAllPlayersLoaded')

	if FORCE_PICKED_HERO == nil and not DEBUG then
		for _,v in ipairs(self.vUserIds) do
			PlayerResource:SetHasRandomed(v:GetPlayerID())
			PlayerResource:SetCanRepick(v:GetPlayerID(), false)
			v:MakeRandomHeroSelection()
		end
	end
end

-- An NPC has spawned somewhere in game.  This includes heroes
function GameMode:OnNPCSpawned(keys)
	--print("[SNS] NPC Spawned")
	--PrintTable(keys)
	local npc = EntIndexToHScript(keys.entindex)

	-- Our heroes
	if npc:IsRealHero() then
		Timers:CreateTimer(.4, function()
			if npc.isNinja ~= nil and npc.isNinja == false then
				-- we're using a dummy
				return
			end
			
			self:HeroInit(npc)
			self:InitialiseNinja(npc)

			if not npc.bFirstSpawned then
				npc.bFirstSpawned = true
				GameMode:OnHeroInGame(npc)
			end
		end)
	elseif npc:IsRealHero() and not (npc:GetClassname() == "npc_dota_hero_antimage") then
		if not npc.bFirstSpawned then
			npc.bFirstSpawned = true
			GameMode:HeroInit(npc)
			GameMode:OnHeroInGame(npc)
		end
	end
end

-- An item was picked up by a player
function GameMode:OnItemPickedUp( keys )
	print ( '[SNS] OnItemPickedUp: ' .. keys.itemname )
	PrintTable(keys)

	local hero = PlayerResource:GetSelectedHeroEntity( keys.PlayerID )
	local itemEntity = keys.itemEnt
	if itemEntity == nil then
		itemEntity = EntIndexToHScript(keys.ItemEntityIndex)
	end
	local player = PlayerResource:GetPlayer(keys.PlayerID)
	local itemname = keys.itemname

	if itemname == "item_lacoste_basic" then
		local base = nil
		for i=0,5 do
			local item = hero:GetItemInSlot(i)
			if item then
				local itemName = item:GetName()
				if itemName == "item_lacoste_basic" then
					if base and base:GetName() == "item_lacoste_basic" then
						hero:RemoveItem(base)
						hero:RemoveItem(item)
						local newItem = CreateItem("item_lacoste_cavallion", nil, nil)
						newItem:SetPurchaseTime(0)
						hero:AddItem(newItem)
						return
					end
					base = item
				elseif itemName == "item_lacoste_cavallion" then
					hero:RemoveItem(itemEntity)
					hero:RemoveItem(item)
					local newItem = CreateItem("item_lacoste_sheldon_lace", nil, nil)
					newItem:SetPurchaseTime(0)
					hero:AddItem(newItem)
					return
				elseif itemName == "item_lacoste_sheldon_lace" then
					hero:RemoveItem(itemEntity)
					hero:RemoveItem(item)
					local newItem = CreateItem("item_lacoste_megagay_edition", nil, nil)
					newItem:SetPurchaseTime(0)
					hero:AddItem(newItem)
					return
				end
			end
		end
	end
end

-- An item was purchased by a player
function GameMode:OnItemPurchased( keys )
	print ( '[SNS] OnItemPurchased: ' .. keys.itemname )
	PrintTable(keys)
	-- The playerID of the hero who is buying something
	local player = EntIndexToHScript(keys.PlayerID)
	local hero = PlayerResource:GetSelectedHeroEntity( keys.PlayerID )

	-- The name of the item purchased
	local itemName = keys.itemname 

	-- The cost of the item purchased
	local itemcost = keys.itemcost
end

-- An ability was used by a player
function GameMode:OnAbilityUsed( keys )
	print('[SNS] AbilityUsed: ' .. keys.abilityname )
	--PrintTable(keys)

	local player = EntIndexToHScript(keys.PlayerID)
	local abilityname = keys.abilityname
	local hero = PlayerResource:GetSelectedHeroEntity( keys.PlayerID )

	-- Prevents double usage on ice.
	if abilityname == "item_gay_trap" or abilityname == "item_cosmopolitan" or abilityname == "item_bottle_of_seamen" or abilityname == "item_potion_of_mana" or abilityname == "item_potion_of_speed" then
		print("clearOrder")
		hero.lastOrder = nil
	end
end

--[[
  This function is called once and only once for every player when they spawn into the game for the first time.  It is also called
  if the player's hero is replaced with a new hero for any reason.  This function is useful for initializing heroes, such as adding
  levels, changing the starting gold, removing/adding abilities, adding physics, etc.

  The hero parameter is the hero entity that just spawned in
]]
function GameMode:OnHeroInGame( hero )
	print("[SNS] Hero spawned in the game for the first time -- " .. hero:GetUnitName())
	local className = hero:GetClassname()

	if className == "npc_dota_hero_rattletrap" then
		print('Removing Wearables')
		hero.wearableNames = {} -- In here we'll store the wearable names to revert the change
		hero.hiddenWearables = {} 
		local wearable = hero:FirstMoveChild()
		while wearable ~= nil do
			if wearable:GetClassname() == "dota_item_wearable" then
				local modelName = wearable:GetModelName()
				if string.find(modelName, "invisiblebox") == nil then
					-- Add the original model name to revert later
					table.insert(hero.wearableNames,modelName)
					--print("Hidden "..modelName.."")

					-- Set model invisible
					wearable:SetModel("models/development/invisiblebox.vmdl")
					table.insert(hero.hiddenWearables,wearable)
				end
			end
			wearable = wearable:NextMovePeer()
			if model ~= nil then
				--print("Next Peer:" .. wearable:GetModelName())
			end
		end
	end

	if not self.noReset then
		ShowGenericPopupToPlayer(hero.player, "#slideninjaslide_instructions_title", (GetMapName() == "run_gay_run" and "#slideninjaslide_instructions_body_rgr" or "#slideninjaslide_instructions_body"), "", "", DOTA_SHOWGENERICPOPUP_TINT_SCREEN )
	end

	if DEBUG then
		hero:SetGold(STARTING_GOLD, false)
	else
		hero:SetGold(STARTING_GOLD, false)
	end
end

function GameMode:OnEntityKilled( keys )
	local entity = EntIndexToHScript(keys.entindex_killed)
	local name = entity:GetUnitName()
	print(name)
	if name == "npc_wolf" or name == "npc_mr_krabs" then
		table.insert(self.wolvesHeaven, { entity:GetAbsOrigin(), entity.zone } )
		print(#self.wolvesHeaven)
	end
end

function GameMode:PlayerSay(keys)
	--print ('[SNS] PlayerSay')
	--PrintTable(keys)

	local ply = self.vUserIdToPly[keys.userid]
	local plyID = ply:GetPlayerID()
	local hero = self.vPlayerIDToHero[plyID]
	local txt = keys.text
	local args = split(txt, " ")
	local host = GameRules:PlayerHasCustomGameHostPrivileges(ply)
	local server = GetListenServerHost()
	local localID = -1
	if server ~= nil then
		localID = 0
	end

	if keys.teamOnly then
		-- This text was team-only
	end

	if txt == nil or txt == "" then
		return
	end

	if DEBUG and string.find(txt, "^-tractor$") then
		print('tractor')
		local m = string.match(txt, "(%d)")
		if m ~= nil then
			local p = PlayerResource:GetPlayer(tonumber(m))
			local target = p:GetAssignedHero()
			local source = player.hero

			target:SetPhysicsVelocityMax(500)
			target:PreventDI()

			local direction = source:GetAbsOrigin() - target:GetAbsOrigin()
			direction = direction:Normalized()
			target:SetPhysicsAcceleration(direction * 50)

			target:OnPhysicsFrame(function(unit)
				-- Retarget acceleration vector
				local distance = source:GetAbsOrigin() - target:GetAbsOrigin()
				local direction = distance:Normalized()
				target:SetPhysicsAcceleration(direction * 50)

				-- Stop if reached the unit
				if distance:Length() < 100 then
					target:SetPhysicsAcceleration(Vector(0,0,0))
					target:SetPhysicsVelocity(Vector(0,0,0))
					target:OnPhysicsFrame(nil)
				end
			end)
		end
	end

	if DEBUG and string.find(keys.text, "^-gold$") then
		print("Giving gold to player")
		for k,v in pairs(HeroList:GetAllHeroes()) do
			v:SetGold(50000, false)
			GameRules:SetUseUniversalShopMode( true )
		end
	end

	if DEBUG and string.find(keys.text, "^-slide$") then
		player.hero:Slide(not player.hero:IsSlide())
		print(player.hero:IsSlide())
	end

	if DEBUG and string.find(keys.text, "^-kill$") then
		GameMode:HeroKilled( hero )
		Timers:CreateTimer(3, function()
			GameMode:HeroRevivied( hero, hero)
		end)
	end

	if DEBUG and string.find(keys.text, "^-test$") then
		GameMode:ReviveAllWolves()
	end

	if DEBUG and string.find(keys.text, "^-test2$") then
		hero:Stop()
		hero:SetForwardVector(Vector(1,0,0))
		print(hero:GetForwardVector(), hero:GetAnglesAsVector())
	end

	if DEBUG and string.find(keys.text, "^-test3$") then
		print("firesound")
		EmitSoundOn("SlideNinjaSlide.LandMine.Detonate", hero)
	end

	if string.find(keys.text, "^-players$") and ( plyID == localID or host ) then
		GameRules:SendCustomMessage("Players: " .. #self.vUserIds .. "/10", 0, 0)
		for i,v  in ipairs(self.vUserIds) do
			local phero = v:GetAssignedHero()
			GameRules:SendCustomMessage("PID: " .. v:GetPlayerID() .. " host:" .. tostring(GameRules:PlayerHasCustomGameHostPrivileges(v)) .. " abandoned:" .. tostring(phero:HasOwnerAbandoned()) .. " " .. phero:GetClassname(), 0, 0)
		end
	end

	if string.find(keys.text, "^-unstuck$") then
		FindClearSpaceForUnit(hero, hero:GetAbsOrigin(), true)
		hero:Stop()
	end

	if args[1] == "-g" then
		if args[2] ~= nil then
			local id2 = tonumber(args[2])
			if not id2 then
				SendErrorMessage( hero:GetPlayerID(), "#error_syntax_give" )
				return
			end
			local gold = tonumber(args[3])
			local player = PlayerResource:GetPlayer(id2)
			if not player then
				SendErrorMessage( hero:GetPlayerID(), "#error_syntax_give" )
				return
			end
			local hero2 = player:GetAssignedHero()
			if hero2 and hero:GetTeamNumber() == hero2:GetTeamNumber() then
				if gold then
					if gold > 0 and gold <= hero:GetGold() then
						print('GIVE: '..args[2]..' '..gold)
						hero:SpendGold( gold, DOTA_ModifyGold_Unspecified)
						hero2:ModifyGold( gold, false, DOTA_ModifyGold_Unspecified)
						Notifications:Bottom(hero:GetPlayerID() , {text="Gave ".. gold .. " gold to " .. PlayerResource:GetPlayerName(id2)..".", style={color='#FFFF00'}, duration=3})
						Notifications:Bottom(hero2:GetPlayerID() , {text="Recieved ".. gold .. " gold from " .. PlayerResource:GetPlayerName(hero:GetPlayerID())..".", style={color='#FFFF00'}, duration=3})
					else
						SendErrorMessage( hero:GetPlayerID(), "#error_not_enough_gold" )
					end
				else
					local all = hero:GetGold()
					if all > 0 then
						print('GIVE: '..args[2])
						hero:SpendGold( all, DOTA_ModifyGold_Unspecified)
						hero2:ModifyGold( all, false, DOTA_ModifyGold_Unspecified)
						Notifications:Bottom(hero:GetPlayerID() , {text="Gave ".. gold .. " gold to " .. PlayerResource:GetPlayerName(id2)..".", style={color='#FFFF00'}, duration=3})
						Notifications:Bottom(hero2:GetPlayerID() , {text="Recieved ".. gold .. " gold from " .. PlayerResource:GetPlayerName(hero:GetPlayerID())..".", style={color='#FFFF00'}, duration=3})
					else
						SendErrorMessage( hero:GetPlayerID(), "#error_not_enough_gold" )
					end
				end
			end
		end
	end

	if (string.find(keys.text, "^-toggleanimation$") or string.find(keys.text, "^-ta$")) and not hero.slide then
		if hero.skateAnimation == "modifier_skatimation_datadriven" then
			hero.skateAnimation = "modifier_skatimation2_datadriven"
		else
			hero.skateAnimation = "modifier_skatimation_datadriven"
		end
	end

	if string.find(keys.text, "^-reset$") and ( plyID == localID or host ) then
		if self.canReset then
			self.noReset = true
			self.resetting = true
			self.bBonusTue = true
			GameMode:ResetGame()
			self.canReset = false
		end
	end

	if string.find(keys.text, "^-nochance$") and ( plyID == localID or host ) then
		if self.noChance then
			GameRules:SendCustomMessage("#slideninjaslide_command_nochance_on", 0, 0)
			self.noChance = false
		else
			GameRules:SendCustomMessage("#slideninjaslide_command_nochance_off", 0, 0)
			self.noChance = true
		end
	end

	if string.find(keys.text, "^-end$") and ( plyID == localID or host ) then
		GameRules:SendCustomMessage("#slideninjaslide_end_command", 0, 0)
		Timers:CreateTimer(2, function()
			self:ForceEnd()
		end)
	end

	if string.find(keys.text:lower(), "^-tue$") and ( plyID == localID or host ) then
		GameMode:TueModeStart()
	end

	if string.find(keys.text:lower(), "^who lives in a pineapple under the sea$") and ( plyID == localID or host ) then
		if GetMapName() == "run_gay_run" then
			GameRules:SendCustomMessage("This mode only works on the Slide Ninja Slide map.", 0, 0)
			return
		end

		GameRules:SendCustomMessage("SPONGEBOB SQUAREPANTS!", 0, 0)
		SendToServerConsole( "dota_combine_models 0" )
		--SendToServerConsole( "dota_wearables_clientside 1" )
		--SendToConsole( "dota_wearables_clientside -rep" )
		SendToConsole( "dota_combine_models 0" )
		self.gameTheme = 2
		--FireGameEvent("show_center_message",msg)
		Timers:CreateTimer(2,function()
			self.noReset = true
			GameMode:ResetGame()

			MusicPlayer:ChangePlaylist("scripts/music_SB.kv")
			for i,v  in ipairs(self.vUserIds) do
				print('Updating Playlist for PlayerID: ' .. v:GetPlayerID())
				v:UpdateMusicPlaylist( )
			end
		end)
	end
	--[[
	if string.find(keys.text, "^-time") then
		FireGameEvent('cgm_timer_display', { timerMsg = "Test", timerSeconds = 8, timerWarning = 8, timerPosition = 1, timerEnd = true })
	end
	if string.find(keys.text, "^-pause") then
		FireGameEvent('cgm_timer_pause', { timePaused = true})
	end
	if string.find(keys.text, "^-upause") then
		FireGameEvent('cgm_timer_pause', { timePaused = false})
	end
	]]
end


-- This function runs constantly checking for player collisions (deaths/revives)
function GameMode:OnThink()
	for i,hero in ipairs(self.ninjas) do
		--Get nearby wolves
		if hero:IsAlive() then
			hero.nearbyWolves = {}
			hero.nearbyDeadNinjas = {}
			hero.nearbyDroppedItems = {}
			for i,v in ipairs(Entities:FindAllInSphere(hero:GetAbsOrigin(), 180)) do
				if v.isWolf and v:IsAlive() then
					table.insert(hero.nearbyWolves, v)
				elseif v.isNinja and not v:IsAlive() then
					table.insert(hero.nearbyDeadNinjas, v)
				elseif v.isDroppedItem and not v.pickedUp then
					table.insert(hero.nearbyDroppedItems, v)
				end
			end

			if hero.nearbyWolves ~= {} then
				for i,wolf in ipairs(hero.nearbyWolves) do
					if not hero:IsInvulnerable() 
						and not hero.isInvuln
						and not hero:HasModifier("modifier_bladestorm")
						and not hero:HasModifier("modifier_behind_datadriven")
						and not wolf:HasModifier("modifier_tue_bubble_beam_projectile_datadriven") 
						and not wolf:HasModifier("modifier_item_ultimate_gay_potion")
						and not wolf:HasModifier("modifier_rgr_gaynish")
						and not wolf:HasModifier("modifier_hex")
						and not wolf:HasModifier("modifier_rgr_tornado")
						and not wolf:HasModifier("modifier_devour_eaten_target")
						and circleCircleCollision(hero:GetAbsOrigin(), wolf:GetAbsOrigin(), hero:GetPaddedCollisionRadius(), wolf:GetPaddedCollisionRadius()) then
						local killHero = true
						-- Check if we should trigger rgr_evasion or not
						if hero:HasModifier("modifier_evasion_evade") then
							killHero = false
							EvasionTriggered( hero, wolf )
						end
						-- Check if chemical rage modifier is on hero and check on hit.
						if hero:HasModifier("modifier_rgr_chemical_rage") and ChemicalRageOnHit(hero) then
							killHero = false
						end
						if hero:HasModifier("modifier_rgr_sillyness") and not wolf:HasModifier("modifier_rgr_sillyness_target") and SillynessTriggered( hero, wolf ) then
							killHero = false
						end
						-- This will only run for RGR
						if wolf:IsIdle() and self.gameTheme == 3 then
							RotateUnitToFace( wolf, hero:GetAbsOrigin() )
							GameMode:AttackUnit(hero,wolf,killHero)
						end
						if killHero then
							GameMode:HeroKilled(hero)
						else
							-- This is for temp invul
							hero.isInvuln = true
							Timers:CreateTimer(0.4, function()
								hero.isInvuln = false
							end)
						end
					end
				end
			end

			if hero.nearbyDeadNinjas ~= {} then
				for i,deadninja in ipairs(hero.nearbyDeadNinjas) do
					if deadninja.deadPos then
						if circleCircleCollision(hero:GetAbsOrigin(), deadninja.deadPos, hero:GetPaddedCollisionRadius()+25, deadninja:GetPaddedCollisionRadius()+25) then
							if deadninja.reviveTick == 0 then
								GameMode:HeroRevivied(deadninja, hero)
							end
						end
					end
				end
			end

			if hero.nearbyDroppedItems ~= {} then
				for i, item in pairs(hero.nearbyDroppedItems) do
					if circleCircleCollision(hero:GetAbsOrigin(), item:GetAbsOrigin(), hero:GetPaddedCollisionRadius(), DROPPED_ITEM_RADIUS) then
						-- use this method to pickup dropped item to prevent a forced movement order.
						if not HasFullInventory(hero) then
							item.pickedUp = true
							local newItem = CreateItem(item.itemName, hero, hero)
							hero:AddItem(newItem)
							newItem.itemName = item.itemName

							-- manually call item pickup event
							local keys =
							{
								PlayerID = hero:GetPlayerID(),
								itemname = newItem.itemName,
								itemEnt = newItem
							}
							self:OnItemPickedUp(keys)

							-- destroy item on ground
							item:RemoveSelf()
						end
						-- this func will force a movement:
						--hero:PickupDroppedItem(item)
					end
				end
			end
		end

		if hero.reviveTick > 0 then
			hero.reviveTick = hero.reviveTick - 1
		end
	end

	return 0.1
end

function GameMode:HeroKilled( hero )
	EmitSoundOn("Hero_Antimage.PreAttack", hero)

	-- revive timeout
	hero.reviveTick = 2

	-- record the pos
	hero.deadPos = hero:GetAbsOrigin()

	-- record the mana
	hero.prevMana = hero:GetMana()

	hero:ForceKill(false)

	-- Reimburse gold lost to death
	--hero:SetGold(hero:GetGold() + hero:GetDeathGoldCost(), false)
	if IsPhysicsUnit(hero) then
		hero:StopPhysicsSimulation()
	end

	-- Update score
	hero.score = hero.score - 1

	self.nDeaths = self.nDeaths + 1

	GameRules:GetGameModeEntity():SetTopBarTeamValue ( DOTA_TEAM_BADGUYS, self.nDeaths )
	CustomGameEventManager:Send_ServerToAllClients("SetTopBarScoreValue", { teamId = DOTA_TEAM_BADGUYS, teamScore = self.nDeaths } )

	ScoreBoard:ScoreUpdate(hero)

	-- particle effect repetition
	hero.haloTimer = Timers:CreateTimer(function()
		if hero:IsNull() then
			return nil
		end

		-- particles just run once
		if hero.halo == nil then
			--print("Creating Particles: "..self.haloParticles[hero:GetPlayerID()+1])
			--hero.halo = ParticleManager:CreateParticle(self.haloParticles[hero:GetPlayerID()+1], PATTACH_ABSORIGIN, hero)
			hero.halo = ParticleManager:CreateParticle(self.haloParticles[hero:GetPlayerID()+1], PATTACH_ABSORIGIN, hero)
			--hero.halo = ParticleManager:CreateParticle("particles/units/heroes/hero_silencer/silencer_last_word.vpcf", PATTACH_ABSORIGIN, hero)
			--[[Timers:CreateTimer(0.3, function()
				hero.halo2 = ParticleManager:CreateParticle("particles/silencer_last_word_status_pink/silencer_last_word_status_pink.vpcf", PATTACH_ABSORIGIN, hero)
			end)
			]]
		end

		-- repeat as long as the hero is dead
		if not hero:IsAlive() then
			if hero.halo ~= nil then
				ParticleManager:SetParticleControl( hero.halo, 0, hero.deadPos )
			end
			return .5 -- sync this with the particle effect
		else
			print("Deleting halo particles")
			-- the hero is alive, so end the particle effect and timer.
			if hero.halo ~= nil then
				ParticleManager:DestroyParticle(hero.halo, true)
				--ParticleManager:DestroyParticle(hero.halo2, true)
				hero.halo = nil
			end
			return nil
		end
	end)

	GameMode:CheckIfGameEnd()
end

function GameMode:HeroRevivied( hero , reviver)
	-- respawn the ninja
	hero:SetRespawnPosition(hero.deadPos)
	hero:RespawnHero(false, false)
	--PlayerResource:SetCameraTarget(hero:GetPlayerID(), hero)

	-- prevent hero from moving
	if IsPhysicsUnit(hero) then
		hero:SetPhysicsVelocity(Vector(0,0,0))
	end
	hero:SetForwardVector(reviver:GetForwardVector())

	local count = 0
	Timers:CreateTimer(function()
		-- we need to setabs multiple times because for some reason it may lead to an inaccurate location if used once after respawn.
		if count < 4 then
			hero:SetAbsOrigin(hero.deadPos)
			count = count + 1
		else
			-- the hero is definitely at the correct location now, proceed with post-respawn stuff
			--EmitSoundOn("Hero_Omniknight.GuardianAngel.Cast", hero)
			hero:EmitSoundParams("Hero_Omniknight.GuardianAngel.Cast", 1, 0.5, 1)
			local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_omniknight/omniknight_guardian_angel_ally.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
			-- delete spawn effects after 1.5s
			Timers:CreateTimer(1.5,function()
				ParticleManager:DestroyParticle(particle, true)
			end)
			if IsPhysicsUnit(hero) then
				hero:StartPhysicsSimulation()
			end
			hero:Stop()
			return nil
		end
		-- setabs every small interval
		return .04
	end)

	hero:SetMana(hero.prevMana)

	--PlayerResource.SetCameraTarget(hero:GetPlayerID(),hero)
	-- update score, gold and xp for both hero and reviver
	hero:SetGold(hero:GetGold() - 15, false)
	-- hero:RemoveExperience when possible
	reviver:SetGold(reviver:GetGold() + 30, false)
	reviver:AddExperience(50, false, false)
	reviver.score = reviver.score + 1

	ScoreBoard:ScoreUpdate(reviver)

	-- give split second of invulnerability
	hero.isInvuln = true
	Timers:CreateTimer(.3, function()
		hero.isInvuln = false
	end)

	print(hero.id .. " has been revivied by " .. reviver.id)
end

function GameMode:SafetyReached( trigger )
	local zone = split(trigger.caller:GetName(), "_")[3]
	print("Safe Zone " .. zone .. " reached.")
	if not trigger.activator:IsInvulnerable() then
		GameMode:CheckIfVisitedZone(trigger.activator, tonumber(zone))
	else -- If using leap of faith give xp after the hero has returned to the game
		Timers:CreateTimer(1.5,function()
			GameMode:CheckIfVisitedZone(trigger.activator, tonumber(zone))
		end)
	end
end

function GameMode:LevelCompleted( hero )
	self.nCurrentRound = self.nCurrentRound + 1

	GameRules:GetGameModeEntity():SetTopBarTeamValue ( DOTA_TEAM_GOODGUYS, self.nCurrentRound )
	CustomGameEventManager:Send_ServerToAllClients("SetTopBarScoreValue", { teamId = DOTA_TEAM_GOODGUYS, teamScore = self.nCurrentRound } )

	local teleportParticle = ParticleManager:CreateParticle("particles/units/heroes/hero_chen/chen_teleport_flash.vpcf", PATTACH_CUSTOMORIGIN, hero )
	ParticleManager:SetParticleControl( teleportParticle, 0, hero:GetAbsOrigin() )
	ParticleManager:ReleaseParticleIndex(teleportParticle)
	GiveUnitDataDrivenModifier(hero, hero, "modifier_hide_hero_datadriven", -1)

	print(hero:GetPlayerID())
	-- commend the player who completed the level.
	local completer = GameMode:GetNinja(hero:GetPlayerID()).playerName
	GameRules:SendCustomMessage("<font color='#FF1493'>" .. completer .. "</font> <font color='#7FFF00'>has reached the end!</font>", 0, 0)
	hero.score = hero.score + 5
	hero:SetGold(hero:GetGold() + GOLD_BONUS_ROUND_WINNER, false)
	hero:AddExperience(EXP_BONUS_ROUND_WINNER, false, false)

	ScoreBoard:ScoreUpdate(hero)
	--print(GameMode:GetNinja(hero:GetPlayerID()).score)

	-- reward team
	for i,v in ipairs(self.ninjas) do
		v:SetGold(v:GetGold() + GOLD_PER_ROUND, false)

		if GetMapName() == "run_gay_run" then
			local kappaPride = ParticleManager:CreateParticleForPlayer("particles/screen/kappapride.vpcf", PATTACH_EYES_FOLLOW, v, PlayerResource:GetPlayer(v:GetPlayerID()))
			print('kappa')
		end
	end

	if self.nCurrentRound > self.nMaxRounds then
		print("[SNS] The Players have won the game! Starting finishing sequence.")
		GameRules:SendCustomMessage("#slideninjaslide_levelcomplete", 0, 0)
		local msg = {
			message = "#slideninjaslide_won",
			duration = 3.0
		}
		FireGameEvent("show_center_message",msg)
		local delay = 3

		if GetMapName() == "run_gay_run" then
			delay = 15
			MusicPlayer:ChangePlaylist("scripts/music_RGR_END.kv")
			for i,v  in ipairs(self.vUserIds) do
				print('Updating Playlist for PlayerID: ' .. v:GetPlayerID())
				v:UpdateMusicPlaylist( )
			end
		end

		Timers:CreateTimer(delay, function()
			GameRules:SetGameWinner( DOTA_TEAM_GOODGUYS )
			GameRules:SetSafeToLeave( true )
		end)
		self:EndMessage()
		return
	end

	-- Display round complete messege
	local msg = {
		message = "ROUND " .. self.nCurrentRound-1 .. " COMPLETED",
		duration = 3.0
	}
	FireGameEvent("show_center_message",msg)

	-- Set camera and hide all ninjas
	for i,v in ipairs(SpawnPoints) do
		local ninja = self.ninjas[i]
		if ninja ~= nil then
			if (hero:GetPlayerID() ~= ninja.id) then
				PlayerResource:SetCameraTarget( ninja.id , hero)
				Timers:CreateTimer(0.2, function()
					PlayerResource:SetCameraTarget( ninja.id , nil)
				end)
				local teleportParticle = ParticleManager:CreateParticle("particles/units/heroes/hero_chen/chen_teleport_flash.vpcf", PATTACH_CUSTOMORIGIN, ninja )
				ParticleManager:SetParticleControl( teleportParticle, 0, ninja:GetAbsOrigin() )
				ParticleManager:ReleaseParticleIndex(teleportParticle)
				GiveUnitDataDrivenModifier(ninja, ninja, "modifier_hide_hero_datadriven", -1)
			end
		end
	end

	Timers:CreateTimer(3, function()		
		print('[SNS] Starting Round: ' .. tostring(self.nCurrentRound))

		-- Attaching a particle to the leading team heroes
		local existingParticle = hero:Attribute_GetIntValue( "particleID", -1 )
		if existingParticle == -1 then
			local particleLeader = ParticleManager:CreateParticle( "particles/leader/leader_overhead.vpcf", PATTACH_OVERHEAD_FOLLOW, hero )
			ParticleManager:SetParticleControlEnt( particleLeader, PATTACH_OVERHEAD_FOLLOW, hero, PATTACH_OVERHEAD_FOLLOW, "follow_overhead", hero:GetAbsOrigin(), true )
			hero:Attribute_SetIntValue( "particleID", particleLeader )
			Timers:CreateTimer(10, function()
				local particleLeader = hero:Attribute_GetIntValue( "particleID", -1 )
				if particleLeader ~= -1 then
					ParticleManager:DestroyParticle( particleLeader, true )
					hero:DeleteAttribute( "particleID" )
				end
			end)
		end

		-- Reset all ninjas
		for i,v in  ipairs(SpawnPoints) do
			local ninja = self.ninjas[i]
			if ninja ~= nil then

				-- Remove hide hero modifier	
				ninja:RemoveModifierByName("modifier_hide_hero_datadriven")

				-- revive dead ninjas
				if not ninja:IsAlive() then
					ninja:RespawnHero(false, false)
				end
				if not ninja:IsAlive() then
					ninja:RespawnHero(false, false)
				end

				FindClearSpaceForUnit(ninja, v, true)
				FindClearSpaceForUnit(ninja, v, false)

				-- reset camera pos
				if ninja.player and not ninja.player:IsNull() then
					ninja.player:SetAbsOrigin(v)
				end
				
				-- stop moving after ninja teleports
				ninja:StartPhysicsSimulation()
				ninja:Stop()

				Timers:CreateTimer(0.1,function()
					if ninja ~= nil then
						ninja:Stop()
						ninja:SetForwardVector(Vector(1,0,0))
					end
				end)			

				PlayerResource:SetCameraTarget(ninja.id, ninja)
				Timers:CreateTimer(0.2, function()
					PlayerResource:SetCameraTarget(ninja.id, nil)
				end)

				-- respawn effects
				--EmitSoundOnClient("Hero_Omniknight.GuardianAngel.Cast", ninja:GetPlayerOwner())
				local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_omniknight/omniknight_guardian_angel_ally.vpcf", PATTACH_ABSORIGIN, ninja)
				-- delete spawn effects after 1.5s
				Timers:CreateTimer(1.5,function()
					ParticleManager:DestroyParticle(particle, true)
				end)
			end
		end

		if self.bTue then
			self:TueNewRound()
		end

		-- Delay by one tick
		Timers:CreateTimer( function()
				EmitSoundOn("Hero_Omniknight.GuardianAngel.Cast", self.start)
			end)

		-- clear all zones.
		for i,v in ipairs(self.ninjas) do
			for i2,v2 in ipairs(v.zonesVisited) do
				v.zonesVisited[i2] = false
			end
			v.lastZone = 0
		end

		GameMode:ReviveAllWolves()
		
		-- Move the wolves in true zones only (reduce lag)
		for i=1,15 do
			self.wolvesToMove[i] = false
		end
		GameMode:CreateWolvesNextRound()
		self.wolvesToMove[1] = true
		GameMode:MoveWolvesInActiveZones()

		-- Display new round message
		-- short pause before this text appears.
		Timers:CreateTimer(5, function()
			local msg = {
				message = "ROUND " .. self.nCurrentRound,
				duration = 3.0
			}
			FireGameEvent("show_center_message",msg)
			GameRules:SendCustomMessage(self.roundMessages[self.nCurrentRound], 0, 0)
		end)
	end)
end

function GameMode:CheckIfVisitedZone( hero, zone )
	hero.lastZone = zone
	GameMode:UpdateActiveWolfZones()
	if not hero.zonesVisited[zone] then
		print(EXP_SAFE_ZONE*(1.08^hero.score) .." xp has been added to player " .. hero:GetPlayerID())
		hero:AddExperience(EXP_SAFE_ZONE * (1.08^hero.score), false, false)
		hero.zonesVisited[zone] = true
	end
end

function GameMode:UpdateActiveWolfZones()
	for i=0,15 do
		self.wolvesToMove[i] = false
	end
	for i,v in ipairs(self.ninjas) do
		self.wolvesToMove[v.lastZone] = true
		self.wolvesToMove[v.lastZone + 1] = true
		if v.lastZone == 13 then
			self.wolvesToMove[15] = true
		end
	end
	GameMode:MoveWolvesInActiveZones()
end

-- Controls the spawning of items on the map
function GameMode:SpawnItems()
	local roll = RandomInt(1, 100)
	local itemToSpawn = ""
	if roll >= 99 then itemToSpawn = self.itemSpawns[10]
	elseif roll >= 96 then itemToSpawn = self.itemSpawns[9]
	elseif roll >= 93 then itemToSpawn = self.itemSpawns[8]
	elseif roll >= 90 then itemToSpawn = self.itemSpawns[7]
	elseif roll >= 87 then itemToSpawn = self.itemSpawns[6]
	elseif roll >= 74 then itemToSpawn = self.itemSpawns[5]
	elseif roll >= 61 then itemToSpawn = self.itemSpawns[4]
	elseif roll >= 41 then itemToSpawn = self.itemSpawns[3]
	elseif roll >= 21 then itemToSpawn = self.itemSpawns[2]
	else itemToSpawn = self.itemSpawns[1]
	end
	if DEBUG then
		print(roll, itemToSpawn)
	end
	local newItem = CreateItem(itemToSpawn, nil, nil)
	newItem:SetPurchaseTime(0)
	local x = RandomInt(-3328, 3328)
	local y = RandomInt(-3328, 3328)
	if (self.itemindex == ITEMS_ON_MAP) then
		self.itemindex = 0
	end
	if not (self.items[self.itemindex] == nil) then
		if IsValidEntity(self.items[self.itemindex]) then
			local container = self.items[self.itemindex]:GetContainer()
			if (container ~= nil) then
				-- Overthrow particles :)
				local nFXIndex = ParticleManager:CreateParticle( "particles/items2_fx/veil_of_discord.vpcf", PATTACH_CUSTOMORIGIN, container )
				ParticleManager:SetParticleControl( nFXIndex, 0, container:GetOrigin() )
				ParticleManager:SetParticleControl( nFXIndex, 1, Vector( 35, 35, 25 ) )
				ParticleManager:ReleaseParticleIndex( nFXIndex )
				self.items[self.itemindex]:GetContainer():RemoveSelf()
				self.items[self.itemindex]:RemoveSelf()
			end
		end
	end
	self.items[self.itemindex] = newItem
	self.itemindex = self.itemindex + 1
	local droppedItem = CreateItemOnPositionSync(Vector(x, y, 256), newItem)
	droppedItem.isDroppedItem = true
	droppedItem.itemName = itemToSpawn
	if (self.gameTheme == 3) then
		droppedItem:SetRenderColor(255, 0, 255)
	end
end

-- Called when all heros haved died, providing additional chances to try again
function GameMode:ChanceRound()
	-- Double check
	local gameEnd = true
	for i,v in ipairs(self.ninjas) do
		if v:IsAlive() then
			gameEnd = false
		end
	end
	if not gameEnd then
		return
	end

	if self.bTue then
		self:TueEnd()
		return
	end

	self.livesUsed = self.livesUsed + 1
	print('[SNS] Lives Used: ' .. tostring(self.livesUsed))
	GameRules:SendCustomMessage("#slideninjaslide_chanceround_penalty", 0, 0)

	-- penalty team
	for i,v in ipairs(self.ninjas) do
		v:SetGold(v:GetGold() - 100, false)
	end

	-- Reset all ninjas
	for i,v in  ipairs(SpawnPoints) do
		local ninja = self.ninjas[i]
		if ninja ~= nil then

			-- revive dead ninjas
			if not ninja:IsAlive() then
				if ninja.halo ~= nil then
					ParticleManager:DestroyParticle(ninja.halo, true)
					ninja.halo = nil
				end
				ninja:RespawnHero(false, false)
			end

			FindClearSpaceForUnit(ninja, v, true)
			-- reset camera pos
			if ninja.player and not ninja.player:IsNull() then
				ninja.player:SetAbsOrigin(v)
			end

			-- stop moving after ninja teleports
			ninja:StartPhysicsSimulation()
			ninja:Stop()

			ninja:SetForwardVector(Vector(1,0,0))

			-- respawn effects
			--EmitSoundOnClient("Hero_Omniknight.GuardianAngel.Cast", ninja:GetPlayerOwner())
			local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_omniknight/omniknight_guardian_angel_ally.vpcf", PATTACH_ABSORIGIN, ninja)
			-- delete spawn effects after 1.5s
			Timers:CreateTimer(1.5,function()
				ParticleManager:DestroyParticle(particle, true)
			end)
		end
	end

	EmitSoundOn("Hero_Omniknight.GuardianAngel.Cast", self.start)

	-- clear all zones.
	for i,v in ipairs(self.ninjas) do
		for i2,v2 in ipairs(v.zonesVisited) do
			v.zonesVisited[i2] = false
		end
		v.lastZone = 0
	end

	-- Move the wolves in true zones only (reduce lag)
	for i=1,15 do
		self.wolvesToMove[i] = false
	end
	self.wolvesToMove[1] = true
	GameMode:MoveWolvesInActiveZones()

	-- Display new round message
	-- short pause before this text appears.
	Timers:CreateTimer(0, function()
		local msg = {
			message = "#slideninjaslide_resetround",
			duration = 1.5
		}
		FireGameEvent("show_center_message",msg)
	end)
	Timers:CreateTimer(2, function()
		local lives = LIVES - self.livesUsed
		local msg = {
			message = "CHANCES LEFT: " .. tostring(lives),
			duration = 2.0
		}
		if lives == 0 then
			msg = {
				message = "#slideninjaslide_lastchance",
				duration = 2.0
			}
		end
		FireGameEvent("show_center_message",msg)
	end)
end

function GameMode:ResetGame()
	local msg = {
		message = "#slideninjaslide_gamereset",
		duration = 2.0
	}
	FireGameEvent("show_center_message",msg)

	-- Check if TUE is still running
	if self.bTue and self.bTueChasing then
		self:TueEnd()
		return
	end

	-- Reset all ninjas
	local temp = self.ninjas
	self.ninjas = {}
	for i,v in ipairs(SpawnPoints) do
		local ninja = temp[i]
		if ninja ~= nil then
			if ninja.haloTimer ~= nil then
				Timers:RemoveTimer(ninja.haloTimer)
			end
			local oldHero = PlayerResource:GetSelectedHeroEntity( ninja.id )
			local heroName = self.gameHeros[self.gameTheme][1]
			if GetMapName() == "run_gay_run" then
				heroName = oldHero:GetUnitName()
			end
			self:StopSoundForce( oldHero )
			local newHero = PlayerResource:ReplaceHeroWith(ninja.id, heroName, 0, 0)
			UTIL_Remove( oldHero )
			newHero:SetAbsOrigin( SpawnPoints[ninja.id + 1] )

			-- Remove items from inventory
			for i=0,14 do
				-- Leave backpack filler items intact
				if i ~= 6 and i ~= 7 and i ~= 8 then
					local item = newHero:GetItemInSlot(i)
					if item then
						newHero:RemoveItem(item)
					end
				end
			end

			-- Remove abilities from hero and add 1 ability point.
			newHero:SetAbilityPoints(1)
			for i=0,3 do
				local ability = newHero:GetAbilityByIndex(i)
				ability:SetLevel(0)
			end
		end
	end

	self.nCurrentRound = 1
	self.livesUsed = 0
	self.nDeaths = 0

	GameRules:GetGameModeEntity():SetTopBarTeamValue ( DOTA_TEAM_GOODGUYS, self.nCurrentRound )
	GameRules:GetGameModeEntity():SetTopBarTeamValue ( DOTA_TEAM_BADGUYS, self.nDeaths )
	CustomGameEventManager:Send_ServerToAllClients("SetTopBarScoreValue", { teamId = DOTA_TEAM_GOODGUYS, teamScore = self.nCurrentRound } )
	CustomGameEventManager:Send_ServerToAllClients("SetTopBarScoreValue", { teamId = DOTA_TEAM_BADGUYS, teamScore = self.nDeaths } )	

	Timers:CreateTimer(4, function()
		local msg = {
			message = "ROUND " .. self.nCurrentRound,
			duration = 3.0
		}
		FireGameEvent("show_center_message",msg)
	end)

	-- Clear Wolves
	for i,v in ipairs(self.wolves) do
		if v.randomMoveTimer ~= nil then
			Timers:RemoveTimer(v.randomMoveTimer)
		end
		if not v:IsNull() then
			v:RemoveSelf()
		end
	end

	-- Remove items on the ground
	while GameRules:NumDroppedItems() > 0 do
		local item = GameRules:GetDroppedItem(0)
		UTIL_RemoveImmediate( item )
	end

	-- Clear Item/Ability Entities
	GayTrapDestroyAll()

	self.wolves = {}
	self.wolvesHeaven = {}

	self:PopulateZonesWithWolves()

	-- Move the wolves in true zones only (reduce lag)
	for i=1,15 do
		self.wolvesToMove[i] = false
	end
	self.wolvesToMove[1] = true
	GameMode:MoveWolvesInActiveZones()
end

function GameMode:CheckIfGameEnd()
	local gameEnd = true
	for i,v in ipairs(self.ninjas) do
		if v:IsAlive() then
			gameEnd = false
		end
	end
	
	-- Set all lives used on bonus round
	if not self.bBonusTue then
		self.livesUsed = LIVES
	end

	-- allow extra trys after all ninjas have died
	if gameEnd and not self.noChance and self.livesUsed < LIVES then
		gameEnd = false
		Timers:CreateTimer(4, function()
			GameMode:ChanceRound()
		end)
	end

	-- Bonus tue round
	if gameEnd and RandomInt(1,4) == 1 and self.bBonusTue then
		self.bBonusTue = false
		GameRules:SendCustomMessage("#slideninjaslide_tue_bonus_round", 0, 0)
		GameMode:TueModeStart()
		return
	end

	if gameEnd then	-- Triple check
		Timers:CreateTimer(0.1, function()
			for i,v in ipairs(self.ninjas) do
				if v:IsAlive() then
					return
				end
			end

			print("[SNS] The Players have lost the game! Starting reset/finishing sequence.")
			GameRules:SendCustomMessage("#slideninjaslide_heros_fallen", 0, 0)
			local msg = {
				message = "#slideninjaslide_lost",
				duration = 3.0
			}
			FireGameEvent("show_center_message",msg)

			self.canReset = true
			Timers:CreateTimer(15, function()
				if not self.resetting then
					self.canReset = false
					GameRules:SetGameWinner( DOTA_TEAM_BADGUYS )
					GameRules:SetSafeToLeave( true )
				end
				self.resetting = false
			end)
			self:EndMessage()
			GameRules:SendCustomMessage("#slideninjaslide_reset_game_message", 0, 0)	
		end)
	end
end

function GameMode:ForceEnd(  )
	self:EndMessage()
	Timers:CreateTimer(3, function()
		GameRules:SetGameWinner( DOTA_TEAM_BADGUYS )
		GameRules:SetSafeToLeave( true )
	end)
end

function GameMode:TueModeStart( )
	if not self.bTue then
		self.bTue = true
		GameRules:SendCustomMessage("#slideninjaslide_command_tue", 0, 0)
		-- Reset Game into T.U.E mode
		self.noReset = true
		GameMode:ResetGame()
		GameMode:TueMode()

		Timers:CreateTimer(2, function()
			MusicPlayer:ChangePlaylist("scripts/music_TUE.kv")
			for i,v  in ipairs(self.vUserIds) do
				print('Updating Playlist for PlayerID: ' .. v:GetPlayerID())
				v:UpdateMusicPlaylist( )
			end
		end)
	end
end

function GameMode:TueMode(  )
	-- Enable Wall
	for _,v in ipairs(self.walls) do
		v:SetEnabled(true, false)
	end

	local barrier =  ParticleManager:CreateParticle("particles/units/heroes/hero_dark_seer/dark_seer_wall_of_replica.vpcf", PATTACH_ABSORIGIN, self.walls[1])
	ParticleManager:SetParticleControl(barrier, 0, Entities:FindByName(nil, "wall_1"):GetAbsOrigin())
	ParticleManager:SetParticleControl(barrier, 1, Entities:FindByName(nil, "wall_2"):GetAbsOrigin())

	-- Spawn Unit and kill Old
	self.tueUnit = CreateUnitByName("npc_crash_tue", self.tueSpawn:GetAbsOrigin(), false, nil, nil, DOTA_TEAM_NEUTRALS)

	Timers:CreateTimer(2, function()
		GameRules:SendCustomMessage("#slideninjaslide_tue_barrier", 0, 0)

		local count = 0
		Timers:CreateTimer(5, function()
			local msg = {
				message = 5 - count,
				duration = 0.5
			}
			if count == 5 then
				msg = {
					message = "#slideninjaslide_tue_go",
					duration = 0.5
				}
			end
			FireGameEvent("show_center_message",msg)
			if count >= 5 then
				-- Disable Wall
				for _,v in ipairs(self.walls) do
					v:SetEnabled(false, false)
				end
				ParticleManager:DestroyParticle(barrier, false)
				Timers:CreateTimer(4, function()
					self:TueChase()
				end)
				return nil
			end
			count = count + 1
			return 1
		end)
	end)
end

function GameMode:TueChase(  )
	self.bTueChasing = true

	local waypoints = {}
	for i=1,15 do
		table.insert(waypoints, Entities:FindByName(nil, "tue_waypoint_" .. tostring(i)))
	end
	local currentWaypoint = 1

	EmitGlobalSound("RoshanDT.Scream")
	local range = 370

	-- Waypoints
	Timers:CreateTimer(function()
		if self.tueUnit == nil or not self.bTueChasing then
			return nil
		end
		if self.tueUnit:IsIdle() then
			if currentWaypoint == 16 then
				self:TueEnd()
				return nil
			end	
			if distanceBetweenEntities2D(waypoints[currentWaypoint], self.tueUnit) > 10 then
				self.tueUnit:MoveToPosition(waypoints[currentWaypoint]:GetAbsOrigin())
			else
				currentWaypoint = currentWaypoint + 1
			end
		end
		return 0.03
	end)

	-- Kill units in path
	Timers:CreateTimer(function()
		if self.tueUnit == nil or not self.bTueChasing then
			return nil
		end
		for _,v in ipairs(Entities:FindAllInSphere(self.tueUnit:GetAbsOrigin(), range)) do
			if v.isWolf and v:IsAlive() then
				local mine = ParticleManager:CreateParticle("particles/units/heroes/hero_techies/techies_land_mine_explode.vpcf", PATTACH_ABSORIGIN, self.tueUnit)
				ParticleManager:SetParticleControl(mine, 0, v:GetAbsOrigin())
				ParticleManager:SetParticleControl(mine, 1, Vector(0, 0, 300))
				EmitSoundOn("SlideNinjaSlide.LandMine.Detonate", v)
				v:ForceKill(false)
			elseif v.isNinja and not v:IsInvulnerable() and not v.isInvuln and v:IsAlive() then
				local damage_indicator = ParticleManager:CreateParticleForPlayer("particles/generic_gameplay/screen_damage_indicator.vpcf", PATTACH_EYES_FOLLOW, v, PlayerResource:GetPlayer(v:GetPlayerID()))
				local splat = ParticleManager:CreateParticleForPlayer("particles/screen/splat_screen.vpcf", PATTACH_EYES_FOLLOW, v, PlayerResource:GetPlayer(v:GetPlayerID()))
				EmitGlobalSound("SlideNinjaSlide.ArtilleryCorpseExplodeDeath1")
				self:HeroKilled(v)
			end
		end
		return 0.03
	end)

	-- Explosion Particles
	Timers:CreateTimer(function()
		if self.tueUnit == nil or not self.bTueChasing then
			return nil
		end
		local lastpos = self.tueUnit:GetAbsOrigin()
		Timers:CreateTimer(0.5, function()
			local mine = ParticleManager:CreateParticle("particles/units/heroes/hero_techies/techies_land_mine_explode.vpcf", PATTACH_ABSORIGIN, self.tueUnit)
			ParticleManager:SetParticleControl(mine, 0, lastpos)
			ParticleManager:SetParticleControl(mine, 1, Vector(0, 0, 300))
			EmitSoundOn("SlideNinjaSlide.LandMine.Detonate", self.tueUnit)
		end)
		return 1
	end)
end

function GameMode:TueNewRound(  )
	print('TUE Round Completed!')
	self.bTueChasing = false
	self.tueUnit:RemoveSelf()
	self.tueUnit = nil
	self:TueMode()
end

function GameMode:TueEnd(  )
	self.bTue = false
	self.bTueChasing = false
	self.tueUnit:RemoveSelf()
	self.tueUnit = nil
	GameRules:SendCustomMessage("#slideninjaslide_tue_lost", 0, 0)
	self:ResetGame()
	MusicPlayer:ChangePlaylist(self.gameHeros[self.gameTheme][3])
	for i,v  in ipairs(self.vUserIds) do
		print('Updating Playlist for PlayerID: ' .. v:GetPlayerID())
		v:UpdateMusicPlaylist( )
	end
end

function GameMode:EndMessage(  )
  GameRules:SendCustomMessage("#slideninjaslide_end_message01", 0, 0)
  GameRules:SendCustomMessage("#slideninjaslide_end_message02", 0, 0)
  GameRules:SendCustomMessage("#slideninjaslide_end_message03", 0, 0)
  GameRules:SendCustomMessage(" ", 0, 0)
end

function GameMode:GetNinja( id )
	for i,v in ipairs(self.ninjas) do
		if v.id == id then
			return v
		end
	end
end

function GameMode:InitialiseNinja(hero)
	if not self.firstTime then
		self.firstTime = true
		
		SendToConsole('dota_always_show_player_names 1')
		
		Timers:CreateTimer(5, function()
			local msg = {
				message = "ROUND " .. self.nCurrentRound,
				duration = 3.0
			}
			FireGameEvent("show_center_message",msg)
			GameRules:GetGameModeEntity():SetTopBarTeamValue ( DOTA_TEAM_GOODGUYS, self.nCurrentRound )
			CustomGameEventManager:Send_ServerToAllClients("SetTopBarScoreValue", { teamId = DOTA_TEAM_GOODGUYS, teamScore = self.nCurrentRound } )
		end)

		Timers:CreateTimer(4, function()
			GameRules:SendCustomMessage("Welcome to Slide Ninja Slide! [".. VERSION .. "]", 0, 0)
			GameRules:SendCustomMessage("#slideninjaslide_start_message02", 0, 0)
			GameRules:SendCustomMessage("#slideninjaslide_start_message03", 0, 0)
			GameRules:SendCustomMessage("#slideninjaslide_start_message04", 0, 0)
			GameRules:SendCustomMessage("#slideninjaslide_start_message05", 0, 0)
		end)

		Timers:CreateTimer(20, function()
			GameRules:SendCustomMessage("#slideninjaslide_commands01", 0, 0)
			GameRules:SendCustomMessage("#slideninjaslide_commands02", 0, 0)
			GameRules:SendCustomMessage("#slideninjaslide_commands03", 0, 0)
			GameRules:SendCustomMessage("#slideninjaslide_commands04", 0, 0)
			GameRules:SendCustomMessage("#slideninjaslide_commands05", 0, 0)
		end)
	end

	if not hero.firstTime then
		if not self.noReset then
			-- attach music player to this player ent
			MusicPlayer:AttachMusicPlayer( hero:GetPlayerOwner() )
			Timers:CreateTimer(5, function()
				if not hero:IsNull() then
					hero:GetPlayerOwner():PlayMusic()
				end
			end)

			-- Remove items from inventory purchased during pregame
			for i=0,14 do
				local item = hero:GetItemInSlot(i)
				if item then
					hero:RemoveItem(item)
				end
			end

			-- Workaround: Fill backpack with permanent items
			for i=0,8 do
				local newItem = CreateItem("item_faerie_fire", nil, nil)
				hero:AddItem(newItem)
			end
			for i=0,5 do
				local item = hero:GetItemInSlot(i)
				if item then
					hero:RemoveItem(item)
				end
			end
		end
		if self.bSlide then
			-- Physics
			Physics:Unit(hero)
			hero:SetNavCollisionType (PHYSICS_NAV_SLIDE)
			hero:SetGroundBehavior (PHYSICS_GROUND_ABOVE)
			hero:AdaptiveNavGridLookahead (true)
			hero:SetPhysicsBoundingRadius(0)

			hero:Hibernate(false)
		end

		hero.score = 0
		hero.zonesVisited = {}
		hero.lastZone = 0
		hero.isNinja = true
		hero.reviveTick = 0
		hero.skateAnimation = "modifier_skatimation_datadriven"

		for i=1,14 do
			hero.zonesVisited[i] = false
		end

		hero:FindAbilityByName("antimage_iceskates"):SetLevel(1)

		--[[
		for i=0,15 do
			local ability = hero:GetAbilityByIndex(i)
			if ability then
				print(ability:GetAbilityName())
			end
		end
		]]

		-- Removed old special hero abilities to make space for our added ones
		for i=5,9 do
			local ability = hero:GetAbilityByIndex(i)
			if ability then
				hero:RemoveAbility(ability:GetAbilityName())
			end
		end

		if DEBUG then
			hero:SetControllableByPlayer(0, true)
			AddAbilityToUnit(hero, "tue_bubble_beam"):SetAbilityIndex(5)
			AddAbilityToUnit(hero, "debug_teleport"):SetAbilityIndex(6)
		end

		if self.bTue then
			AddAbilityToUnit(hero, "tue_bubble_beam"):SetAbilityIndex(5)
		end

		hero.id = hero:GetPlayerID()
		hero.player = PlayerResource:GetPlayer(hero:GetPlayerID())
		hero.playerName = PlayerResource:GetPlayerName(hero:GetPlayerID())

		ScoreBoard:PlayerUpdate(hero)
		ScoreBoard:ScoreUpdate(hero)
		
		-- Whitespace for scoreboard alignment.
		local whitespace = ""
		for i=1, 24-string.len(hero.playerName) do
			whitespace = whitespace .. " "
		end

		self.whitespace[hero.playerName] = whitespace

		hero.deathDummies = {}

		GameMode:UpdatePlayerColor( hero.id )

		table.insert(self.ninjas, hero)

		-- We this so this function will not be called when a hero is respawned
		hero.firstTime = true
	end
end

-- Sounds are left playing on Reset Game
function GameMode:StopSoundForce ( unit )
	local sound_name = "Hero_Chen.TeleportLoop"
	local target = unit

	StopSoundEvent(sound_name, target)
	StopEffect(target, "particles/units/heroes/hero_chen/chen_teleport_bits.vpcf")
	StopEffect(target, "particles/units/heroes/hero_chen/chen_teleport_rings.vpcf")
end

---------------------------------------------------------------------------
-- Get the color associated with a given teamID
---------------------------------------------------------------------------
function GameMode:ColorForPlayer( plyID )
	local color = self.m_TeamColors[ plyID ]
	if color == nil then
		color = { 255, 255, 255 } -- default to white
	end
	return color
end

---------------------------------------------------------------------------
-- Put a label over a player's hero so people know who is on what team
---------------------------------------------------------------------------
function GameMode:UpdatePlayerColor( nPlayerID )
	if not PlayerResource:HasSelectedHero( nPlayerID ) then
		return
	end

	local hero = PlayerResource:GetSelectedHeroEntity( nPlayerID )
	if hero == nil then
		return
	end

	local color = self:ColorForPlayer( nPlayerID )
	--local name = hero.playerName
	PlayerResource:SetCustomPlayerColor( nPlayerID, color[1], color[2], color[3] )
end

---------------------------------------------------------------------------
-- Simple scoreboard using debug text
---------------------------------------------------------------------------
function GameMode:UpdateScoreboard()
	local sortedNinjas = {}

	for i,v in ipairs (self.ninjas) do
		table.insert(sortedNinjas, {name = v.playerName, plyID = v:GetPlayerID(), score = v.score})
	end
	-- reverse-sort by score
	table.sort( sortedNinjas, function(a,b) return ( a.score > b.score ) end )

	UTIL_ResetMessageTextAll()
	UTIL_MessageTextAll( "#ScoreboardTitle", 204, 0, 102, 255 )

	for _, vals in pairs( sortedNinjas ) do
		local clr = self:ColorForPlayer( vals.plyID )
		UTIL_MessageTextAll(vals.name .. self.whitespace[vals.name] .. vals.score, clr[1], clr[2], clr[3], 255)
	end
end

function GameMode:SetupGuards()
	print("[SNS] Setup Guards")
	for i=1,#self.guardsxyz do
		Physics:RemoveCollider("box_"..tostring(i))
		self.guardboxes[i] = Physics:AddCollider("box_"..tostring(i), Physics:ColliderFromProfile("aaboxblocker"))
		self.guardboxes[i].box = {Vector(self.guardsxyz[i][1],self.guardsxyz[i][2],self.guardsxyz[i][3]), Vector(self.guardsxyz[i][4],self.guardsxyz[i][5],self.guardsxyz[i][6])} -- 340 from end, 50 units from skip
		--self.guardboxes[i].skipFrames = 1
		self.guardboxes[i].test = function(self, unit)
			return IsPhysicsUnit(unit)
		end
		self.guardboxes[i].filter = self.ninjas
		if DEBUG then
			self.guardboxes[i].draw = true
		end
	end
end

ORDERS = {
	[0] = "DOTA_UNIT_ORDER_NONE",
	[1] = "DOTA_UNIT_ORDER_MOVE_TO_POSITION",
	[2] = "DOTA_UNIT_ORDER_MOVE_TO_TARGET",
	[3] = "DOTA_UNIT_ORDER_ATTACK_MOVE",
	[4] = "DOTA_UNIT_ORDER_ATTACK_TARGET",
	[5] = "DOTA_UNIT_ORDER_CAST_POSITION",
	[6] = "DOTA_UNIT_ORDER_CAST_TARGET",
	[7] = "DOTA_UNIT_ORDER_CAST_TARGET_TREE",
	[8] = "DOTA_UNIT_ORDER_CAST_NO_TARGET",
	[9] = "DOTA_UNIT_ORDER_CAST_TOGGLE",
	[10] = "DOTA_UNIT_ORDER_HOLD_POSITION",
	[11] = "DOTA_UNIT_ORDER_TRAIN_ABILITY",
	[12] = "DOTA_UNIT_ORDER_DROP_ITEM",
	[13] = "DOTA_UNIT_ORDER_GIVE_ITEM",
	[14] = "DOTA_UNIT_ORDER_PICKUP_ITEM",
	[15] = "DOTA_UNIT_ORDER_PICKUP_RUNE",
	[16] = "DOTA_UNIT_ORDER_PURCHASE_ITEM",
	[17] = "DOTA_UNIT_ORDER_SELL_ITEM",
	[18] = "DOTA_UNIT_ORDER_DISASSEMBLE_ITEM",
	[19] = "DOTA_UNIT_ORDER_MOVE_ITEM",
	[20] = "DOTA_UNIT_ORDER_CAST_TOGGLE_AUTO",
	[21] = "DOTA_UNIT_ORDER_STOP",
	[22] = "DOTA_UNIT_ORDER_TAUNT",
	[23] = "DOTA_UNIT_ORDER_BUYBACK",
	[24] = "DOTA_UNIT_ORDER_GLYPH",
	[25] = "DOTA_UNIT_ORDER_EJECT_ITEM_FROM_STASH",
	[26] = "DOTA_UNIT_ORDER_CAST_RUNE",
	[27] = "DOTA_UNIT_ORDER_PING_ABILITY",
	[28] = "DOTA_UNIT_ORDER_MOVE_TO_DIRECTION",
}

function GameMode:FilterExecuteOrder( filterTable )
	--[[
	print("-----------------------------------------")
	for k, v in pairs( filterTable ) do
		print("Order: " .. k .. " " .. tostring(v) )
	end
	]]

	local units = filterTable["units"]
	local order_type = filterTable["order_type"]
	local issuer = filterTable["issuer_player_id_const"]
	local abilityIndex = filterTable["entindex_ability"]
	local targetIndex = filterTable["entindex_target"]
	local queue = tobool(filterTable["queue"])
	local x = tonumber(filterTable["position_x"])
	local y = tonumber(filterTable["position_y"])
	local z = tonumber(filterTable["position_z"])
	local point = Vector(x,y,z)

	if order_type == DOTA_UNIT_ORDER_PURCHASE_ITEM then
		return true
	end

	-- Skip Prevents order loops
	local unit = EntIndexToHScript(units["0"])
	if unit and unit.skip then
		unit.skip = false
		return true
	end

	-- Prevent glyph and radar orders
	if order_type == DOTA_UNIT_ORDER_GLYPH or order_type == DOTA_UNIT_ORDER_RADAR then
		SendErrorMessage( issuer, "#error_order_blocked" )
		return false
	end

	if order_type == DOTA_UNIT_ORDER_CAST_POSITION then
		if unit.slide then
			unit.lastOrder = { UnitIndex = units["0"], OrderType = order_type, Position = point, TargetIndex = targetIndex, AbilityIndex = abilityIndex, Queue = queue}
		end
	elseif order_type == DOTA_UNIT_ORDER_CAST_TARGET then
		if unit.slide then
			unit.lastOrder = { UnitIndex = units["0"], OrderType = order_type, TargetIndex = targetIndex, AbilityIndex = abilityIndex, Queue = queue}
		end
	else
		if unit.lastOrder then
			unit.lastOrder = nil
		end
	end

	return true
end

function GetVersion()
	return VERSION
end
