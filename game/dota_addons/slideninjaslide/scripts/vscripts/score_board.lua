--[[
	Scoreboard library for custom games
	Author: a_dizzle
	Last Modified: 18/03/2015
]]

ScoreBoard = {}

function ScoreBoard:Init()
	-- If there was something to do it would go here.
end

function ScoreBoard:ScoreBoardTitleUpdate( string )
	FireGameEvent('cgm_scoreboard_update_title', { boardTitle = string })
end

function ScoreBoard:PlayerUpdate(hero)
	local pID = tonumber(hero.id)
	local pName = ColorIt(hero.playerName, tostring(pID))
	print(pID,"<b>"..pName.."</b>")
	FireGameEvent('cgm_scoreboard_update_user', { playerID = pID, playerName = pName})
end

function ScoreBoard:ScoreUpdate(hero)
	local pID = tonumber(hero.id)
	local pScore = hero.score
	--print(pID,pScore)
	FireGameEvent('cgm_scoreboard_update_score', { playerID = pID, playerScore = pScore})
	CustomGameEventManager:Send_ServerToAllClients("update_score_scoreboard", { id = pID, score = pScore } )
end