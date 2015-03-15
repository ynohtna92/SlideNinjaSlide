--[[
	Music Player lib for Dota 2 custom games.
	Author: Myll
	Version: 0.1
]]

MusicPlayer = {}


function MusicPlayer:Init(musicKV)
	self.DEBUG = false
	self.musicKV = LoadKeyValues(musicKV)

	local index = 1
	self.songs = {}
	-- song name is 'k'
	for k,v in pairs(self.musicKV) do
		--print("k: " .. k)
		-- define an index for the song
		v.index = index
		-- map index to song name
		self.songs[index] = k
		index = index + 1
	end
	self.totalSongs = index
	Convars:RegisterCommand( "MusicPlayerButtonClicked", function(name, btnName)
		--get the player that sent the command
		local cmdPlayer = Convars:GetCommandClient()
		if cmdPlayer and cmdPlayer.musicPlayer ~= nil then
			if MusicPlayer.DEBUG then
				print("btnName: " .. btnName)
			end
			if btnName == "loop" then
				cmdPlayer:LoopSong()
			elseif btnName == "play" then
				cmdPlayer:PlayMusic()
			elseif btnName == "stop" then
				cmdPlayer:StopMusic()
			elseif btnName == "forward" then
				cmdPlayer:ForwardMusic()
			elseif btnName == "rewind" then
				cmdPlayer:RewindMusic()
			end
			
		end
	end, "", 0 )

end

function MusicPlayer:AttachMusicPlayer( hPlayer )
	-- create aliases for these MusicPlayer tables
	local songs = MusicPlayer.songs
	local musicKV = MusicPlayer.musicKV
	-- setup music player table for player
	hPlayer.musicPlayer = {}
	-- short-hand alias
	local mp = hPlayer.musicPlayer

	-- music player defaults to shuffle mode
	mp.shuffleMusicMode = true

	local onRanOutOfSongs = function()
		if MusicPlayer.DEBUG then
			print("onRanOutOfSongs")
		end
		-- index to songname table. 
		mp.unplayedSongs = shallowcopy(songs)
		-- shuffle list again.
		mp.unplayedSongs = shuffle(mp.unplayedSongs)
		-- keep track of previous songs played.
		mp.lastPlayedSongs = {}
		-- these are just for shuffled mode
		--mp.playedSongs = {}
		mp.songIndex = 0
		-- just initiate this to avoid fatal errors
		mp.currentSong = mp.unplayedSongs[1]
	end

	local setCurrentSong = function(song)
		mp.currSongKV = musicKV[song]
		-- this is for shuffled mode
		mp.currentSong = song

		if mp.songTimer ~= nil then
			Timers:RemoveTimer(mp.songTimer)
		end
		mp.currSongTime = 0
		mp.songTimer = Timers:CreateTimer({
			useGameTime = false,
			endTime = 1,
			callback = function()
				mp.currSongTime = mp.currSongTime + 1
				return 1
			end
		})
		
		mp.currSongLength = mp.currSongKV["Seconds"]
	end

	onRanOutOfSongs()

	function hPlayer:PlayMusic(  )
		hPlayer:ContinueMusic()
	end

	function hPlayer:StopMusic(  )
		if mp.musicTimer ~= nil then
			Timers:RemoveTimer(mp.musicTimer)
		end
		StopSoundEvent(mp.currentSong, hPlayer)
	end

	-- loop works like this: will keep looping the selected song, if any buttons are pressed
	-- (rewind/forward) loop will cancel
	function hPlayer:LoopSong(  )
		if mp.loopSong then
			mp.loopSong = false
		else
			mp.loopSong = true
		end
	end

	-- can't have a pause button, cause can't go to specific time of sound i think
	function hPlayer:PauseMusic(  )
		-- dont change the curr song.

	end

	function hPlayer:ForwardMusic(  )
		if mp.loopSong then mp.loopSong = false end
		hPlayer:ContinueMusic()
	end

	function hPlayer:RewindMusic(  )
		if mp.loopSong then mp.loopSong = false end
		mp.rewindMusic = true
		if MusicPlayer.DEBUG then
			print("currSongTime at rewind click " .. mp.currSongTime)
		end
		hPlayer:ContinueMusic()
	end

	function hPlayer:ShuffleMode(  )
		if mp.shuffleMusicMode then
			mp.shuffleMusicMode = false
		else
			mp.shuffleMusicMode = true
		end
	end

	-- private
	function hPlayer:ContinueMusic(  )
		StopSoundEvent(mp.currentSong, hPlayer)
		if mp.musicTimer ~= nil then
			if MusicPlayer.DEBUG then
				print("Removing current musicTimer")
			end
			Timers:RemoveTimer(mp.musicTimer)
		end
		mp.musicTimer = Timers:CreateTimer({
			useGameTime = false,
			callback = function()
				hPlayer:PickSong()
				return mp.currSongLength+2
			end
		})
	end

	-- private. this chooses the next song and plays it
	function hPlayer:PickSong(  )

		--print("Last played songs:")
		--PrintTable(mp.lastPlayedSongs)

		-- songToPlay defaults to the current song.
		local songToPlay = mp.unplayedSongs[mp.songIndex]

		if mp.loopSong then
			-- simply play the same song again.
			if MusicPlayer.DEBUG then
				print("Loop detected. Playing " .. mp.currentSong .. " again.")
			end
			setCurrentSong(mp.currentSong)
			EmitSoundOnClient(mp.currentSong, hPlayer)
			return
		end

		if mp.rewindMusic then
			if mp.currSongTime > 1/3*mp.currSongLength then
				-- play the same song again.
				if MusicPlayer.DEBUG then
					print("RewindMusic. Restarting " .. mp.currentSong)
				end
				setCurrentSong(mp.currentSong)
				--mp.currSongTime = 0
				mp.rewindMusic = false
				EmitSoundOnClient(mp.currentSong, hPlayer)
				return
			else
				if #mp.lastPlayedSongs == 1 then
					if MusicPlayer.DEBUG then
						print("mp.lastPlayedSongs has 1")
					end
					songToPlay = mp.unplayedSongs[1]
					mp.songIndex = 1
				else
					-- pop stack (remove current unfinished song)
					table.remove(mp.lastPlayedSongs, 1)
					songToPlay = mp.lastPlayedSongs[1]
					if mp.shuffleMusicMode and mp.songIndex > 1 then
						mp.songIndex = mp.songIndex - 1
					end
					if MusicPlayer.DEBUG then
						print("RewindMusic. The previous song " .. songToPlay .. " will now play. ")
					end
				end
			end
		end

		-- we're playing music now
		if MusicPlayer.DEBUG then
			print("*************************************************")
		end
		if not mp.rewindMusic then
			-- this code will always move forward the music
			if mp.shuffleMusicMode then
				-- could this be a song that hasn't been played yet?
				mp.songIndex = mp.songIndex + 1
				songToPlay = mp.unplayedSongs[mp.songIndex]
				if MusicPlayer.DEBUG then
					print("Song index: " .. mp.songIndex)
				end
				-- We also may have went over the end of the unplayedSongs table.
				if songToPlay == nil then
					-- Get a new list of shuffled unplayed songs.
					onRanOutOfSongs()
					mp.songIndex = 1
					songToPlay = mp.unplayedSongs[1]
				end

			elseif not shuffleMusicMode then
				print("not in shuffleMusicMode")
				-- Get the next song according to the original KV file.
				-- the original songs table helps with that.
				-- get the index of the current song
				local index = mp.currSongKV.index
				-- ensure we didn't exceed length of table
				if songs[index+1] ~= nil then
					songToPlay = songs[index+1]
				else
					-- if we exceeded length of table, loop back to first song in the KV
					songToPlay = songs[1]
				end
			end
		end

		if MusicPlayer.DEBUG then
			print("\nPickSong. Playing " .. songToPlay)
		end
		setCurrentSong(songToPlay)
		-- store song in the stack
		if not mp.rewindMusic then
			if MusicPlayer.DEBUG then
				print("Adding " .. songToPlay .. " to lastPlayedSongs.")
			end
			table.insert(mp.lastPlayedSongs, 1, songToPlay)
		end

		mp.rewindMusic = false
		if MusicPlayer.DEBUG then
			print("Song length: " .. mp.currSongLength)
			print("click rewind before " .. 1/3*mp.currSongLength .. " seconds in to skip song.")

			print("\nmp.lastPlayedSongs ")
			PrintTable(mp.lastPlayedSongs)
			print("\n")
		end
		EmitSoundOnClient(mp.currentSong, hPlayer)
	end

	hPlayer:PlayMusic()
end

-- ******************* UTILITY FUNCTIONS *******************

-- Returns a shallow copy of the passed table.
function shallowcopy(orig)
	local orig_type = type(orig)
	local copy
	if orig_type == 'table' then
		copy = {}
		for orig_key, orig_value in pairs(orig) do
			copy[orig_key] = orig_value
		end
	else -- number, string, boolean, etc
		copy = orig
	end
	return copy
end

-- shuffle function from: https://github.com/xfbs/PiL3/blob/master/18MathLibrary/shuffle.lua
-- doesn't use a while loop
function shuffle(list)
    -- make and fill array of indices
    local indices = {}
    for i = 1, #list do
        indices[#indices+1] = i
    end

    -- create shuffled list
    local shuffled = {}
    for i = 1, #list do
        -- get a random index
        local index = math.random(#indices)

        -- get the value
        local value = list[indices[index]]

        -- remove it from the list so it won't be used again
        table.remove(indices, index)

        -- insert into shuffled array
        shuffled[#shuffled+1] = value
    end

    return shuffled
end