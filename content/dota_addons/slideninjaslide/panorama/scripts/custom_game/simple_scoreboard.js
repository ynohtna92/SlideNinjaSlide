
function OnButtonPressed( data ) {
	var iPlayerID = Players.GetLocalPlayer();
	var btnName = data;
	//$.Msg( data );
	if (btnName == "upBtn")
	{
		$('#upBtn').visible = false;
		$('#downBtn').visible = true;
		$('#ScoreboardBottom').visible = false;
		$('#sbP').visible = true;
		$('#sbN').visible = true;
		$('#sbP0').visible = false;
		$('#sbN0').visible = false;
		$('#ScoreboardTop').AddClass('ScoreboardSingle');
	}
	else if (btnName == "downBtn")
	{
		$('#upBtn').visible = true;
		$('#downBtn').visible = false;
		$('#ScoreboardBottom').visible = true;
		$('#sbP').visible = false;
		$('#sbN').visible = false;
		$('#sbP0').visible = true;
		$('#sbN0').visible = true;
		$('#ScoreboardTop').RemoveClass('ScoreboardSingle');
	}
}

(function () {
	$('#downBtn').visible = false;
	$('#upBtn').visible = true;
	$('#sbP').visible = false;
	$('#sbN').visible = false;
	$('#sbP0').visible = true;
	$('#sbN0').visible = true;
})();