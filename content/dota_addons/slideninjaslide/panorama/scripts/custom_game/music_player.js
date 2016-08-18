
var nowPlayingMsgSch = null;

function OnButtonPressed( data ) {
	var iPlayerID = Players.GetLocalPlayer();
	var btnName = data;
	//$.Msg( data );
	Game.ServerCmd("MusicPlayerButtonClicked " + btnName.substring(0,btnName.length-3));
	if (btnName == "stopBtn")
	{
		$('#stopBtn').visible = false;
		$('#playBtn').visible = true;
	}
	else if (btnName == "playBtn")
	{
		$('#stopBtn').visible = true;
		$('#playBtn').visible = false;
	}
	else if (btnName == "forwardBtn")
	{
		$('#stopBtn').visible = true;
		$('#playBtn').visible = false;	
	}
	else if (btnName == "rewindBtn")
	{
		$('#stopBtn').visible = true;
		$('#playBtn').visible = false;	
	}
}

function NowPlaying( table )
{
	$('#stopBtn').visible = true;
	$('#playBtn').visible = false;
	$.Msg(table.song);
	$('#NowPlaying').text = table.song;
	$('#NowPlayingBox').AddClass('playing');
	if (nowPlayingMsgSch != null) 
	{
		$.CancelScheduled(nowPlayingMsgSch);
		nowPlayingMsgSch = null;
	}
	nowPlayingMsgSch = $.Schedule(8, function(){$('#NowPlayingBox').RemoveClass('playing'); nowPlayingMsgSch = null;});
}

(function () {
	GameEvents.Subscribe( "playing_music", NowPlaying );
	$('#playBtn').visible = false;
	$('#stopBtn').visible = true;
})();