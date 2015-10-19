
var local = Game.GetLocalPlayerInfo();
var players = [];

var nameLabels = [$('#sbP0'),$('#sbP1'),$('#sbP2'),$('#sbP3'),$('#sbP4'),$('#sbP5'),$('#sbP6'),$('#sbP7'),$('#sbP8'),$('#sbP9')];
var scoreLabels = [$('#sbN0'),$('#sbN1'),$('#sbN2'),$('#sbN3'),$('#sbN4'),$('#sbN5'),$('#sbN6'),$('#sbN7'),$('#sbN8'),$('#sbN9')];
var containers = [$('#sb1'),$('#sb2'),$('#sb3'),$('#sb4'),$('#sb5'),$('#sb6'),$('#sb7'),$('#sb8'),$('#sb9')];
var colors = ['#3164DA','#57E19A','#AA00A0','#D3CB14','#D65705','#D26496','#829650','#64BEC8','#056E32','#825005'];

function OnButtonPressed( data ) {
	var iPlayerID = Players.GetLocalPlayer();
	var btnName = data;
	$.Msg( players );
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

function OnUserUpdate( data ) {

}

function OnScoreUpdate( data ) {
	if (data.id == local.player_id)
		$('#sbN').text = data.score;
	ScoreUpdate(data.id, data.score);
	SortScoreboard();
	DisplayScoreboard();
}

function ScoreUpdate( pID, score ) {
	for (var i in players) {
		if (players[i][0] == pID) {
			players[i][2] = score;
			break;
		}
	}
}

function OnTitleUpdate( data ) {
	$('#sbTitle').text = data.title;
}

function SortScoreboard() {
	players.sort(function(a, b) {
		return b[2] - a[2];
	});
}

function DisplayScoreboard() {
	for (var i = 0; i < players.length; i++) {
		nameLabels[i].text = players[i][1];
		nameLabels[i].style['color'] = colors[players[i][0]];
		scoreLabels[i].text = players[i][2];
	}

	for (var i = 0; i < 9; i++) {
		if (i+1 < players.length) {
			containers[i].visible = true;
			containers[i].RemoveClass('ScoreboardLast');
			containers[i].RemoveClass('ScoreboardMiddle');
			if (i+1 == players.length-1)
				containers[i].AddClass('ScoreboardLast');
			else
				containers[i].AddClass('ScoreboardMiddle');				
		}
		else
			containers[i].visible = false;	
	}
}

(function () {
	$('#sbP').text = local.player_name;
	$('#sbP').style['color'] = colors[local.player_id];
	GameEvents.Subscribe( "update_user_scoreboard", OnUserUpdate );
	GameEvents.Subscribe( "update_score_scoreboard", OnScoreUpdate );
	GameEvents.Subscribe( "update_title_scoreboard", OnTitleUpdate );
	$('#downBtn').visible = false;
	$('#upBtn').visible = true;
	$('#sbP').visible = false;
	$('#sbN').visible = false;
	$('#sbP0').visible = true;
	$('#sbN0').visible = true;
	var player = Game.GetAllPlayerIDs();
	if (player.length == 1)
	{
		$('#upBtn').visible = false;
		$('#downBtn').visible = false;
		$('#ScoreboardBottom').visible = false;
		$('#ScoreboardTop').AddClass('ScoreboardSingle');
	}
	for (var i = 0; i < player.length; i++) {
		var p = Game.GetPlayerInfo(player[i]);
		players.push([p.player_id, p.player_name, 0]);
	}
	DisplayScoreboard();
})();