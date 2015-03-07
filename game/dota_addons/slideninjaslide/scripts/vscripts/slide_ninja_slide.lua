--[[
Last modified: 17/02/2015
Author: A_Dizzle
]]

print('[SNS] slide_ninja_slide.lua')

DEBUG = false
THINK_TIME = 0.1

VERSION = "0.1"

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

HERO_SELECTION_TIME = 0.0              -- How long should we let people select their hero?
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

--[[ Set up the GetDotaStats stats for this mod.
if not DEBUG then
  statcollection.addStats({
	modID = 'XXXXXXXXXXXXXXXXXXX' --GET THIS FROM http://getdotastats.com/#d2mods__my_mods
  })
end
]]

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
	GameRules:GetGameModeEntity():SetStashPurchasingDisabled(true)

	--mode = GameRules:GetGameModeEntity()
	--mode:SetFogOfWarDisabled(true)	

	if DEBUG then
		GameRules:SetUseUniversalShopMode( true )
	end
	print('[SNS] GameRules set')

	-- Hooks
	ListenToGameEvent('player_connect_full', Dynamic_Wrap(GameMode, 'OnConnectFull'), self)
--	ListenToGameEvent('player_chat', Dynamic_Wrap(GameMode, 'PlayerSay'), self) --[[Broken]]
	ListenToGameEvent('player_connect', Dynamic_Wrap(GameMode, 'PlayerConnect'), self)
	ListenToGameEvent('npc_spawned', Dynamic_Wrap(GameMode, 'OnNPCSpawned'), self)
	ListenToGameEvent('dota_player_used_ability', Dynamic_Wrap(GameMode, 'OnAbilityUsed'), self)
	ListenToGameEvent('dota_item_purchased', Dynamic_Wrap(GameMode, 'OnItemPurchased'), self)
	ListenToGameEvent('dota_item_picked_up', Dynamic_Wrap(GameMode, 'OnItemPickedUp'), self)

-- Commands can be registered for debugging purposes or as functions that can be called by the custom Scaleform UI
	Convars:RegisterCommand( "command_example", Dynamic_Wrap(GameMode, 'ExampleConsoleCommand'), "A console command example", 0 )

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

	self.vPlayers = {}
	self.vRadiant = {}
	self.vDire = {}
	self.vSteamIds = {}
	self.vBots = {}
	self.vBroadcasters = {}
	self.vUserIds = {}

	-- PLAYER COLORS
	self.m_TeamColors = {}
	self.m_TeamColors[0] = { 50, 100, 220 } -- 49:100:218
	self.m_TeamColors[1] = { 90, 225, 155 } -- 87:224:154
	self.m_TeamColors[2] = { 170, 0, 160 } -- 171:0:156
	self.m_TeamColors[3] = { 210, 200, 20 } -- 211:203:16
	self.m_TeamColors[4] = { 215, 90, 5 } -- 214:87:8
	self.m_TeamColors[5] = { 210, 100, 150 } -- 210:97:153
	self.m_TeamColors[6] = { 130, 150, 80 } -- 130:154:80
	self.m_TeamColors[7] = { 100, 190, 200 } -- 99:188:206
	self.m_TeamColors[8] = { 5, 110, 50 } -- 7:109:44
	self.m_TeamColors[9] = { 130, 80, 5 } -- 124:75:6

	self.whitespace = {}

	self.haloParticles = 
	{
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

	-- Scoreborad updater
	self.scoreTimer = Timers:CreateTimer(2, function()
		self:UpdateScoreboard()
		return 0.5
	end)

	self.guardboxes = {}

	self.guardsxyz = {}
	self.guardsxyz[1] = {2560, 2275, 512, -2900, 2590, 0} -- 1 bottom / GOOD
	self.guardsxyz[2] = {2900, 3502, 512, -2900, 3300, 0} -- 1 top / GOOD
	self.guardsxyz[3] = {2585, 2597, 512, 2280, -2580, 0} -- 2 left / GOOD
	self.guardsxyz[4] = {3478, 2900, 512, 3300, -2900, 0} -- 2 right / GOOD
	self.guardsxyz[5] = {2900, -3300, 512, -2900, -3476, 0} -- 3 bottom / GOOD
	self.guardsxyz[6] = {2554, -2280, 512, -2580, -2580, 0} -- 3 top / GOOD
	self.guardsxyz[7] = {-3300, 1876, 512, -3476, -2900, 0} -- 4 left / GOOD
	self.guardsxyz[8] = {-2280, 1710, 512, -2580, -2304, 0} -- 4 right / GOOD
	self.guardsxyz[9] = {1792, 1710, 384, -2580, 1380, 0} -- 5 bottom
	self.guardsxyz[10] = {1792, 1700, 384, 1510, -1700, 0} -- 6 left
	self.guardsxyz[11] = {1792, -1800, 384, -1792, -1505, 0} -- 7 top
	self.guardsxyz[12] = {-1800, 1040, 384, -1510, -1792, 0} -- 8 right
	self.guardsxyz[13] = {1152, 1040, 384, -1792, 735, 0} -- 9 bottom
	self.guardsxyz[14] = {1152, 1040, 384, 870, -1152, 0} -- 10 left
	self.guardsxyz[15] = {1152, -870, 384, -1152, -1170, 0} -- 11 top
	self.guardsxyz[16] = {-896, 400, 384, -1170, -1152, 0} -- 12 right
	self.guardsxyz[17] = {530, 400, 384, -1170, 200, 0} -- 13 bottom
	self.guardsxyz[18] = {530, 400, 384, 300, -550, 0} -- 14 left
	self.guardsxyz[19] = {530, -300, 384, -500, -550, 0} -- 15 top

	self.wolves = {}
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

	SpawnPoints = {}
	local goodguys = Entities:FindAllByClassname("info_player_start_goodguys")
	local badguys = Entities:FindAllByClassname("info_player_start_badguys")

	for i,v in ipairs(goodguys) do
		table.insert(SpawnPoints, v:GetAbsOrigin())
	end
		for i,v in ipairs(badguys) do
		table.insert(SpawnPoints, v:GetAbsOrigin())
	end

	self.songs = {
		[1] = {"SlideNinjaSlide.NumbEncore", 2*60+17 },
	}

	self.Thinker = Timers:CreateTimer(function()
		return self:OnThink()
	end)



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

mode = nil

-- This function is called as the first player loads and sets up the GameMode parameters
function GameMode:CaptureGameMode()
	if mode == nil then
		print("[SNS] CaptureGameMode")
		mode = GameRules:GetGameModeEntity()
	--	mode:SetFogOfWarDisabled( true ) BROKEN-not working on particles -> using ent_fov_revealer in hammer
	--	mode:SetRecommendedItemsDisabled( RECOMMENDED_BUILDS_DISABLED ) BROKEN use entry below
		mode:SetHUDVisible( DOTA_HUD_VISIBILITY_SHOP_SUGGESTEDITEMS, false ) 
		mode:SetCameraDistanceOverride( CAMERA_DISTANCE_OVERRIDE )
		mode:SetBuybackEnabled( BUYBACK_ENABLED )
		mode:SetUseCustomHeroLevels( USE_CUSTOM_HERO_LEVELS )
		mode:SetCustomHeroMaxLevel( MAX_LEVEL )
		mode:SetCustomXPRequiredToReachNextLevel( XP_PER_LEVEL_TABLE )

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
--	PrintTable(keys)
	GameMode:CaptureGameMode()

	local entIndex = keys.index+1
	-- The Player entity of the joining user
	local ply = EntIndexToHScript(entIndex)

	-- The Player ID of the joining player
	local playerID = ply:GetPlayerID()

	-- Update the user ID table with this user
	self.vUserIds[keys.userid] = ply

	-- Update the Steam ID table
	self.vSteamIds[PlayerResource:GetSteamAccountID(playerID)] = ply

	-- If the player is a broadcaster flag it in the Broadcasters table
	if PlayerResource:IsBroadcaster(playerID) then
		self.vBroadcasters[keys.userid] = 1
		return
	end
end

-- An NPC has spawned somewhere in game.  This includes heroes
function GameMode:OnNPCSpawned(keys)
	--print("[SNS] NPC Spawned")
	--PrintTable(keys)
	local npc = EntIndexToHScript(keys.entindex)

	if npc:IsRealHero() and (npc:GetClassname() == "npc_dota_hero_antimage") then
		Timers:CreateTimer(.4, function()
			if npc.isNinja ~= nil and npc.isNinja == false then
				-- we're using a dummy
				return
			end

			self:InitialiseNinja(npc)

			if not npc.bFirstSpawned then
				npc.bFirstSpawned = true
				GameMode:OnHeroInGame(npc)
			end
		end)
	elseif npc:IsRealHero() and not (npc:GetClassname() == "npc_dota_hero_antimage") then
		if not npc.bFirstSpawned then
			npc.bFirstSpawned = true
			GameMode:OnHeroInGame(npc)
		end
	end
end

-- An item was picked up by a player
function GameMode:OnItemPickedUp( keys )
	print ( '[SNS] OnItemPickedUp: ' .. keys.itemname )
	--PrintTable(keys)

	local hero = PlayerResource:GetSelectedHeroEntity( keys.PlayerID )
	local itemEntity = keys.itemEnt
	if itemEntity == nil then
		itemEntity = EntIndexToHScript(keys.ItemEntityIndex)
	end
	local player = PlayerResource:GetPlayer(keys.PlayerID)
	local itemname = keys.itemname

	if itemname == "item_tome_of_experience" then
		-- Remove item from inventory
		for i=0,11 do
			local item = hero:GetItemInSlot(i)
			if item then
				if item:GetAbilityName() == itemname then
					-- Remove item to prevent double spending
					hero:RemoveItem(item)
					hero:AddExperience(150, false, false)
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

	if itemName == "item_tome_of_power" then
		-- Remove item from inventory
		for i=0,11 do
			local item = hero:GetItemInSlot(i)
			if item then
				if item:GetAbilityName() == itemName then
					-- Remove item to prevent double spending
					hero:RemoveItem(item)
					hero:HeroLevelUp(true)
				end
			end
		end
	end
end

-- An ability was used by a player
function GameMode:OnAbilityUsed(keys)
	print('[SNS] AbilityUsed: ' .. keys.abilityname )
	--PrintTable(keys)

	local player = EntIndexToHScript(keys.PlayerID)
	local abilityname = keys.abilityname
	local hero = player:GetAssignedHero()

	if abilityname == "item_tome_of_power" then
		hero:HeroLevelUp(true)
	end

	if abilityname == "item_tome_of_experience" then
		hero:AddExperience(150, false, false)
	end
end

function GameMode:PlaySongs()
  if self.playSongs then
  	return
  end

  self.playSongs = true

  self.songsTimer = Timers:CreateTimer({
    useGameTime = false,
    callback = function()
      if not self.playSongs then
        return nil
      end

      if self.unplayedSongs == nil or #self.unplayedSongs == 0 then
        self.unplayedSongs = shallowcopy(self.songs)
      end

      local songIndex = math.random(#self.unplayedSongs)
      --print("Playing song " .. songIndex)
	  EmitGlobalSound(self.unplayedSongs[songIndex][1])
      --EmitSoundOnClient(self.unplayedSongs[songIndex][1], PlayerResource:GetPlayer(0))
      print("Playing song: " .. self.unplayedSongs[songIndex][1])
      self.currentSong = self.unplayedSongs[songIndex][1]
      --EmitGlobalSound(hero.unplayedSongs[songIndex][1])
      -- play until the length of the song is up.
      local timeTillOver = self.unplayedSongs[songIndex][2]
      table.remove(self.unplayedSongs, songIndex)
      return timeTillOver+4
    end})
end

--[[
  This function is called once and only once for every player when they spawn into the game for the first time.  It is also called
  if the player's hero is replaced with a new hero for any reason.  This function is useful for initializing heroes, such as adding
  levels, changing the starting gold, removing/adding abilities, adding physics, etc.

  The hero parameter is the hero entity that just spawned in
]]
function GameMode:OnHeroInGame(hero)
	print("[SNS] Hero spawned in the game for the first time -- " .. hero:GetUnitName())
	local className = hero:GetClassname()

	ShowGenericPopupToPlayer(hero.player, "#slideninjaslide_instructions_title", "#slideninjaslide_instructions_body", "", "", DOTA_SHOWGENERICPOPUP_TINT_SCREEN )

	-- Display new round message
	-- short pause before this text appears.
	Timers:CreateTimer(5, function()
		local msg = {
			message = "ROUND " .. self.nCurrentRound,
			duration = 3.0
		}
		FireGameEvent("show_center_message",msg)
	end)

	if DEBUG then
		hero:SetGold(STARTING_GOLD, false)
	else
		hero:SetGold(STARTING_GOLD, false)
	end
end

function GameMode:PlayerSay(keys)
	print ('[SNS] PlayerSay')
	PrintTable(keys)

	local ply = keys.ply
	local plyID = ply:GetPlayerID()
	local hero = ply:GetAssignedHero()
	local txt = keys.text

	print(plyID)

	if keys.teamOnly then
		-- This text was team-only
	end

	if txt == nill or txt == "" then
		return
	end

	if DEBUG and string.find(txt, "^-tractor") then
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

	if DEBUG and string.find(keys.text, "^-gold") then
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

	if DEBUG and string.find(keys.text, "^-kill") then
		GameMode:HeroKilled( hero )
		Timers:CreateTimer(3, function()
			GameMode:HeroRevivied( hero, hero)
		end)
	end

	if string.find(keys.text, "^-unstuck") then
		FindClearSpaceForUnit(hero, hero:GetAbsOrigin(), true)
	end

	if string.find(keys.text, "^-stopmusic") and plyID == 0 then
		StopSoundEvent(self.currentSong, ply)
		self.playSongs = false
		print("Music Stopped: " .. self.currentSong)
	end

	if string.find(keys.text, "^-playmusic") and plyID == 0 then
		GameMode:PlaySongs()
	end
end


-- This function runs constantly checking for player collisions (deaths/revives)
function GameMode:OnThink()
	for i,hero in ipairs(self.ninjas) do
		--Get nearby wolves
		if hero:IsAlive() then
			hero.nearbyWolves = {}
			hero.nearbyDeadNinjas = {}
			for i,v in ipairs(Entities:FindAllInSphere(hero:GetAbsOrigin(), 120)) do
				if v.isWolf and v:IsAlive() then
					table.insert(hero.nearbyWolves, v)
				elseif v.isNinja and not v:IsAlive() then
					table.insert(hero.nearbyDeadNinjas, v)
				end
			end

			if hero.nearbyWolves ~= nil and #hero.nearbyWolves ~= 0 then
				for i,wolf in ipairs(hero.nearbyWolves) do
					if not hero:IsInvulnerable() and not hero.isInvuln and circleCircleCollision(hero:GetAbsOrigin(), wolf:GetAbsOrigin(), hero:GetPaddedCollisionRadius(), wolf:GetPaddedCollisionRadius()) then
						GameMode:HeroKilled(hero)
					end
				end
			end

			if hero.nearbyDeadNinjas ~= nil and #hero.nearbyDeadNinjas ~= 0 then
				for i,deadninja in ipairs(hero.nearbyDeadNinjas) do
					if circleCircleCollision(hero:GetAbsOrigin(), deadninja.deadPos, hero:GetPaddedCollisionRadius()+25, deadninja:GetPaddedCollisionRadius()+25) then
						GameMode:HeroRevivied(deadninja, hero)
					end
				end
			end

			-- check for surrounding items
			local ents = Entities:FindAllInSphere(hero:GetAbsOrigin(), 300)
			for i,v in ipairs(ents) do
				if not v.pickedUp and v.isDroppedItem then
					local item = v
					if circleCircleCollision(hero:GetAbsOrigin(), item:GetAbsOrigin(), hero:GetPaddedCollisionRadius(), DROPPED_ITEM_RADIUS) then
						-- use this method to pickup dropped item to prevent a forced movement order.
						if not HasFullInventory(hero) then
							v.pickedUp = true
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
						--hero:PickupDroppedItem(v)
					end
				end
			end

		end
	end

	return 0.1
end

function GameMode:HeroKilled( hero )
	EmitSoundOn("Hero_Antimage.PreAttack", hero)

	-- record the pos
	hero.deadPos = hero:GetAbsOrigin()

	-- record the mana
	hero.prevMana = hero:GetMana()

	hero:ForceKill(false)

	-- Reimburse gold lost to death
	hero:SetGold(hero:GetGold() + hero:GetDeathGoldCost(), false)

	hero:StopPhysicsSimulation()
 
	-- Update score
	hero.score = hero.score - 1

	-- particle effect repetition
	Timers:CreateTimer(function()
		-- particles just run once
		if hero.halo == nil then
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
	hero:RespawnHero(false, false, false)
	--PlayerResource:SetCameraTarget(hero:GetPlayerID(), hero)

	-- prevent hero from moving
	hero:SetPhysicsVelocity(Vector(0,0,0))
	hero:SetForwardVector(reviver:GetForwardVector())

	count = 0
	Timers:CreateTimer(function()
		-- we need to setabs multiple times because for some reason it may lead to an inaccurate location if used once after respawn.
		if count < 4 then
			hero:SetAbsOrigin(hero.deadPos)
			count = count + 1
		else
			-- the hero is definitely at the correct location now, proceed with post-respawn stuff
			EmitSoundOn("Hero_Omniknight.GuardianAngel.Cast", hero)
			local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_omniknight/omniknight_guardian_angel_ally.vpcf", PATTACH_ABSORIGIN, hero)
			-- delete spawn effects after 1.5s
			Timers:CreateTimer(1.5,function()
				ParticleManager:DestroyParticle(particle, true)
			end)
			hero:StartPhysicsSimulation()
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
	if self.nCurrentRound > self.nMaxRounds then
		print("[SNS] The Players have won the game! Starting finishing sequence.")
		GameRules:SendCustomMessage("<font color='#FF1493'>You have completed all the rounds.</font>", 0, 0)
		local msg = {
			message = "YOU'VE WON!",
			duration = 3.0
		}
		FireGameEvent("show_center_message",msg)
		Timers:CreateTimer(3, function()
			GameRules:SetGameWinner( DOTA_TEAM_GOODGUYS )
			GameRules:SetSafeToLeave( true )
		end)
		self:EndMessage()
		return
	end

	print(hero:GetPlayerID())
	-- commend the player who completed the level.
	local completer = GameMode:GetNinja(hero:GetPlayerID()).playerName
	GameRules:SendCustomMessage("<font color='#FF1493'>" .. completer .. "</font> <font color='#7FFF00'>has reached the end!</font>", 0, 0)
	hero.score = hero.score + 5
	hero:SetGold(hero:GetGold() + GOLD_BONUS_ROUND_WINNER, false)
	hero:AddExperience(EXP_BONUS_ROUND_WINNER, false, false)
	--print(GameMode:GetNinja(hero:GetPlayerID()).score)

	-- reward team
	for i,v in ipairs(self.ninjas) do
		v:SetGold(v:GetGold() + GOLD_PER_ROUND, false)
	end

	-- Display round complete messege
	local msg = {
		message = "ROUND " .. self.nCurrentRound-1 .. " COMPLETED",
		duration = 3.0
	}
	FireGameEvent("show_center_message",msg)
	print('[SNS] Starting Round: ' .. tostring(self.nCurrentRound))

	-- Reset all ninjas
	for i,v in  ipairs(SpawnPoints) do
		local ninja = self.ninjas[i]
		if ninja ~= nil then

			-- revive dead ninjas
			if not ninja:IsAlive() then
				ninja:RespawnHero(false, false, false)
			end

			FindClearSpaceForUnit(ninja, v, true)
			-- reset camera pos
			ninja.player:SetAbsOrigin(v)
			
			-- stop moving after ninja teleports
			ninja:StartPhysicsSimulation()
			ninja:Stop()

			-- ninja:SetForwardVector(Vector(1,0,0)) BROKEN

			-- respawn effects
			EmitSoundOn("Hero_Omniknight.GuardianAngel.Cast", ninja)
			local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_omniknight/omniknight_guardian_angel_ally.vpcf", PATTACH_ABSORIGIN, ninja)
			-- delete spawn effects after 1.5s
			Timers:CreateTimer(1.5,function()
				ParticleManager:DestroyParticle(particle, true)
			end)
		end
	end

	-- Reset Camera of all players
	SendToConsole("dota_camera_center")

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
	if roll >= 99 then itemToSpawn = "item_tome_of_power"
	elseif roll >= 96 then itemToSpawn = "item_tome_of_experience"
	elseif roll >= 93 then itemToSpawn = "item_ultra_sobi_mask"
	elseif roll >= 90 then itemToSpawn = "item_socks_of_ultra_speed"
	elseif roll >= 87 then itemToSpawn = "item_pendant_of_mana"
	elseif roll >= 74 then itemToSpawn = "item_pendant_of_energy"
	elseif roll >= 61 then itemToSpawn = "item_sobi_mask2"
	elseif roll >= 41 then itemToSpawn = "item_boots_of_speed"
	elseif roll >= 21 then itemToSpawn = "item_potion_of_speed"
	else itemToSpawn = "item_potion_of_mana"
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
		if (self.items[self.itemindex]:GetContainer() ~= nil) then
			self.items[self.itemindex]:GetContainer():RemoveSelf()
			self.items[self.itemindex]:RemoveSelf()
		end
	end
	self.items[self.itemindex] = newItem
	self.itemindex = self.itemindex + 1
	local droppedItem = CreateItemOnPositionSync(Vector(x, y, 256), newItem)
	droppedItem.isDroppedItem = true
	droppedItem.itemName = itemToSpawn
end

-- Called when all heros haved died, providing additional chances to try again
function GameMode:ChanceRound()
	print('[SNS] Lives Used: ' .. tostring(self.livesUsed))
	GameRules:SendCustomMessage("<font color='#FF1493'>A chance has been used at the cost of 100G each.</font>", 0, 0)

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
				ninja:RespawnHero(false, false, false)
			end

			FindClearSpaceForUnit(ninja, v, true)
			-- reset camera pos
			ninja.player:SetAbsOrigin(v)
			
			-- stop moving after ninja teleports
			ninja:StartPhysicsSimulation()
			ninja:Stop()

			-- ninja:SetForwardVector(Vector(1,0,0)) BROKEN

			-- respawn effects
			EmitSoundOn("Hero_Omniknight.GuardianAngel.Cast", ninja)
			local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_omniknight/omniknight_guardian_angel_ally.vpcf", PATTACH_ABSORIGIN, ninja)
			-- delete spawn effects after 1.5s
			Timers:CreateTimer(1.5,function()
				ParticleManager:DestroyParticle(particle, true)
			end)
		end
	end

	-- Reset Camera of all players
	SendToConsole("dota_camera_center")

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
			message = "RESETING ROUND",
			duration = 1.5
		}
		FireGameEvent("show_center_message",msg)
	end)
	Timers:CreateTimer(2, function()
		local msg = {
			message = "CHANCES LEFT: " .. tostring(LIVES - self.livesUsed),
			duration = 2.0
		}
		FireGameEvent("show_center_message",msg)
	end)
end

function GameMode:CheckIfGameEnd()
	local gameEnd = true
	for i,v in ipairs(self.ninjas) do
		if v:IsAlive() then
			gameEnd = false
		end
	end

	-- allow extra trys after all ninjas have died
	if gameEnd and self.livesUsed < LIVES then
		self.livesUsed = self.livesUsed + 1
		gameEnd = false
		Timers:CreateTimer(4, function()
			GameMode:ChanceRound()
		end)
	end

	if gameEnd then
		print("[SNS] The Players have lost the game! Starting finishing sequence.")
		GameRules:SendCustomMessage("<font color='#FF1493'>All ninjas have fallen!</font>", 0, 0)
		local msg = {
			message = "YOU'VE LOST!",
			duration = 3.0
		}
		FireGameEvent("show_center_message",msg)
		Timers:CreateTimer(3, function()
			GameRules:SetGameWinner( DOTA_TEAM_BADGUYS )
			GameRules:SetSafeToLeave( true )
		end)
		self:EndMessage()
	end
end

function GameMode:EndMessage(  )
  GameRules:SendCustomMessage("Thank you for playing Slide Ninja Slide!", 0, 0)
  GameRules:SendCustomMessage("<font color='#7FFF00'>Remember to share your feedback on the Workshop Page</font>.", 0, 0)
  GameRules:SendCustomMessage("https://github.com/ynohtna92/SlideNinjaSlide", 0, 0)
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
		-- Start playing music on first ninja spawn
		self.firstTime = true
		Timers:CreateTimer(5, function()
			if not DEBUG then
				self:PlaySongs()
			end
		end)
		
		Timers:CreateTimer(4, function()
			GameRules:SendCustomMessage("Welcome to Slide Ninja Slide!", 0, 0)
			GameRules:SendCustomMessage("Developer: <font color='#FF1493'>A_Dizzle</font>", 0, 0)
			GameRules:SendCustomMessage("Credits: <font color='#FF1493'>Myll</font> for his work on D2 Slide Ninja Slide & <font color='#FF1493'>StrikerFred</font> for the original WC3 map ", 0, 0)
			GameRules:SendCustomMessage("Special Thanks: <font color='#FF1493'>BMD & Noya</font> and everyone on IRC", 0, 0)
			GameRules:SendCustomMessage("Support this project on Github at https://github.com/ynohtna92/SlideNinjaSlide", 0, 0)
		end)

		Timers:CreateTimer(20, function()
			GameRules:SendCustomMessage(" ", 0, 0)
			GameRules:SendCustomMessage("Use the -unstuck command if you are unable to move.", 0, 0)
		end)
	end

	if not hero.firstTime then
		Physics:Unit(hero)
		hero:SetNavCollisionType (PHYSICS_NAV_SLIDE)
		hero:SetGroundBehavior (PHYSICS_GROUND_LOCK)
		hero:AdaptiveNavGridLookahead (true)
		hero:SetPhysicsBoundingRadius(0)

		hero:Hibernate(false)

		hero.score = 0
		hero.zonesVisited = {}
		hero.lastZone = 0
		hero.isNinja = true

		for i=1,14 do
			hero.zonesVisited[i] = false
		end

		hero:FindAbilityByName("antimage_iceskates"):SetLevel(1)

		if DEBUG then
			hero:SetControllableByPlayer(0, true)
			AddAbilityToUnit(hero, "debug_teleport")
		end

		hero.id = hero:GetPlayerID()
		hero.player = PlayerResource:GetPlayer(hero:GetPlayerID())
		hero.playerName = PlayerResource:GetPlayerName(hero:GetPlayerID())

		-- Whitespace for scoreboard alignment.
		local whitespace = ""
		for i=1, 24-string.len(hero.playerName) do
			whitespace = whitespace .. " "
		end

		self.whitespace[hero.playerName] = whitespace

		hero.deathDummies = {}

		GameMode:MakeLabelForPlayer( hero )

		table.insert(self.ninjas, hero)

		-- We this so this function will not be called when a hero is respawned
		hero.firstTime = true
	end
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
function GameMode:MakeLabelForPlayer( hero )
	--[[
	if not PlayerResource:HasSelectedHero( nPlayerID ) then
		return
	end

	local hero = PlayerResource:GetSelectedHeroEntity( nPlayerID )
	if hero == nil then
		return
	end
	]]

	local color = self:ColorForPlayer( tonumber(hero.id) )
	local name = hero.playerName
	hero:SetCustomHealthLabel( name, color[1], color[2], color[3] )
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
