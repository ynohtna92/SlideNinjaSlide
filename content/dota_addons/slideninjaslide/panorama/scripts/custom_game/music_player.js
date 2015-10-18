
var mpTitle = $( "#MusicPlayerText" );

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

(function () {
	mpTitle = $.Localize( "#MusicPlayerTitle" );
	$('#playBtn').visible = false;
	$('#stopBtn').visible = true;
})();