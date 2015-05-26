package  {
	
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.utils.getDefinitionByName;
	import scaleform.clik.events.*;
	
	//import some stuff from the valve lib
	import ValveLib.Globals;
	import ValveLib.ResizeManager;

	import fl.transitions.Tween;
	import fl.transitions.easing.*;
	
	//copied from VotingPanel.as source
	import flash.display.*;
    import flash.filters.*;
    import flash.text.*;
    import scaleform.clik.events.*;
    import vcomponents.*;
	
	public class ScoreBoard extends MovieClip {
		
		public var gameAPI:Object;
		public var globals:Object;
		
		public var nameLabels:Object;
		public var scoreLabels:Object;
		public var image_mid:Object;
		
		public var players:Array = new Array();
		public var players_sorted:Array;
		
		public var sortTable:Boolean = true;
		
		public var players_no:int;

		private var backg_valve:MovieClip;
		private var dropd_valve:MovieClip;
		
		/*
		private var colorToID:Object = {
			4294931763:0,
			4290772838:1,
			4290707647:2,
			4278972659:3,
			4278217727:4,
			4290938622:5,
			4282889377:6,
			4294433125:7,
			4280386304:8,
			4278217124:9
		}
		
		for (i = 0; i < 10; i++){
			var topSlot:int = colorToID[globals.Players.GetPlayerColor(i)];
		}
		*/

		public function ScoreBoard() {
			// constructor code
		}

		//set initialise this instance's gameAPI
		public function setup(api:Object, globals:Object) {
			this.gameAPI = api;
			this.globals = globals;
			
			// default: play btn is visible, stop button is not
			trace("##Called ScoreBoard Setup!");
			this.visible = true;

			lbTitle.text = Globals.instance.GameInterface.Translate("#ScoreBoardTitle")
			
			buttonUp.addEventListener(MouseEvent.CLICK, onButtonClicked);
			buttonDown.addEventListener(MouseEvent.CLICK, onButtonClicked);
			
			//this.addChild(backg_valve);
			//this.addChild(dropd_valve);
			this.addChild(lbTitle);
			this.addChild(buttonUp);
			this.addChild(buttonDown);
			
			this.nameLabels = [sbP0,sbP1,sbP2,sbP3,sbP4,sbP5,sbP6,sbP7,sbP8,sbP9];
			this.scoreLabels = [sbN0,sbN1,sbN2,sbN3,sbN4,sbN5,sbN6,sbN7,sbN8,sbN9];
			this.image_mid = [mid_1,mid_2,mid_3,mid_4,mid_5,mid_6,mid_7,mid_8]

			//Player Labels
			this.addChild(sbP0);
			this.addChild(sbP1);
			this.addChild(sbP2);
			this.addChild(sbP3);
			this.addChild(sbP4);
			this.addChild(sbP5);
			this.addChild(sbP6);
			this.addChild(sbP7);
			this.addChild(sbP8);
			this.addChild(sbP9);
			//Player Scores
			this.addChild(sbN0);
			this.addChild(sbN1);
			this.addChild(sbN2);
			this.addChild(sbN3);
			this.addChild(sbN4);
			this.addChild(sbN5);
			this.addChild(sbN6);
			this.addChild(sbN7);
			this.addChild(sbN8);
			this.addChild(sbN9);
			
			this.addChild(sbP);
			this.addChild(sbN);
			sbP.visible = false;
			sbN.visible = false;
			
			var localID:int = this.globals.Players.GetLocalPlayer();
			
			for (var i:int = 0; i < this.nameLabels.length; i++)
			{
				this.nameLabels[i].text = "Disconnected";
				players.push({name:"Disconnected", id:99, score:0});
			}

			this.sbP.text = "Disconnected";
			
			players_no = 10;
			scoreBoardShow(players_no);		
			
			this.gameAPI.SubscribeToGameEvent("cgm_scoreboard_update_score", this.onScoreUpdate);
			this.gameAPI.SubscribeToGameEvent("cgm_scoreboard_update_user", this.onUserUpdate);
			this.gameAPI.SubscribeToGameEvent("cgm_scoreboard_update_title", this.onTitleUpdate);
			
			//dropd_valve.visible = true
			trace("## Called ScoreBoard Setup Completed!");
		}

		private function onButtonClicked(event:MouseEvent) {
			var btnName:String = event.target.name;
			trace("## " + btnName + " clicked!");
			var pID:int = globals.Players.GetLocalPlayer();
			this.gameAPI.SendServerCommand("ScoreBoardButtonClicked " + btnName.substring(0,btnName.length-3));
			
			if (btnName == "buttonUp") {
				buttonUp.visible = false;
				buttonDown.visible = true;
				top.visible = false;
				last.visible = false;
				for (var i:int = 0; i < this.image_mid.length; i++)
				{
					this.image_mid[i].visible = false;
				}
				single.visible = true;
				for (var j:int = 0; j < this.nameLabels.length; j++)
				{
					this.nameLabels[j].visible = false;
					this.scoreLabels[j].visible = false;
				}
				sbP.visible = true;
				sbN.visible = true;
			} else if (btnName == "buttonDown") {
				scoreBoardShow(players_no);
				trace(globals.Players.GetPlayerName( 0 ));
				trace(globals.Players.GetMaxPlayers( 0 ));
			}
		}
		
		//onScreenResize
		public function screenResize(stageW:int, stageH:int, xScale:Number, yScale:Number, wide:Boolean){
			
			trace("Stage Size: ",stageW,stageH);
						
			this.x = stageW - 180*yScale*0.8;
			this.y = 110*yScale*0.8;
			
			trace("#Result Resize: ",this.x,this.y,yScale);

			this.width = this.width*yScale;
			this.height	 = this.height*yScale;
			
			//Now we just set the scale of this element, because these parameters are already the inverse ratios
			this.scaleX = xScale*0.8;
			this.scaleY = yScale*0.8;
			
			trace("#ScoreBoard Panel Resize");			
		}
		
		// Hides or shows the leaderboard with correct number of slots
		public function scoreBoardShow(size:int){
			if(size > 10)
				return
			
			//Reset Objects
			for (var a:int = 0; a < this.image_mid.length; a++)
			{
				this.image_mid[a].visible = false;
			}
			for (var b:int = 0; b < this.nameLabels.length; b++)
			{
				this.nameLabels[b].visible = false;
				this.scoreLabels[b].visible = false;
			}
			sbP.visible = false;
			sbN.visible = false;
			
			//If single player
			if(size == 1){
				buttonUp.visible = false;
				buttonDown.visible = false;
				top.visible = false;
				last.visible = false;
				for (var k:int = 0; k < this.image_mid.length; k++)
				{
					this.image_mid[k].visible = false;
				}
				for (var l:int = 0; l < this.nameLabels.length; l++)
				{
					this.nameLabels[l].visible = false;
					this.scoreLabels[l].visible = false;
				}
				single.visible = true
				sbP.visible = true;
				sbN.visible = true;
				
				return;
			}
			
			//If more than one player
			buttonUp.visible = true;
			buttonDown.visible = false;
			top.visible = true;
			last.visible = true;
			last.y = 372.6 - (10-size)*41;
			if(size >= 3){
				for (var i:int = 0; i < size - 2; i++)
				{
					this.image_mid[i].visible = true;
				}
			}
			for (var j:int = 0; j < size; j++)
			{
				this.nameLabels[j].visible = true;
				this.scoreLabels[j].visible = true;
			}
		}

		//Sorts the scoreboard in descending order
		public function sortScoreBoard(){
			var count:int = 0;
			for (var i:int = 0; i < players.length; ++i) 
			{ 
				if (players[i].id != 99)
					count++;
			}
			this.players_no = count;
			
			players_sorted = [];
			for (var k:int = 0; k < players.length; ++k)
			{
				if (players[k].id != 99)
					players_sorted.push(players[k]);
			}
			players_sorted.sortOn(["score", "id"], [Array.NUMERIC | Array.DESCENDING, Array.NUMERIC]);
			for (var j:int = 0; j < players_sorted.length; ++j)
			{
				this.nameLabels[j].htmlText = players_sorted[j].name;
				this.scoreLabels[j].text = String(players_sorted[j].score);
			}
		}
		
		//onTitleUpdate
		public function onTitleUpdate(args:Object) : void{
			this.lbTitle.htmlText = Globals.instance.GameInterface.Translate(args.boardTitle);
		}		
		
		//onScoreUpdate
		public function onScoreUpdate(args:Object) : void{
			var pID:int = globals.Players.GetLocalPlayer();
			//check of the player in the event is the owner of this UI. Note that args are the parameters of the event
			this.scoreLabels[args.playerID].text = args.playerScore;
			this.players[args.playerID].score = Number(args.playerScore);
			
			if (args.playerID == pID)
				this.sbN.text = args.playerScore;
			if (this.sortTable)
				sortScoreBoard();
		}
		
		//onUserUpdate
		public function onUserUpdate(args:Object) : void{
			var pID:int = globals.Players.GetLocalPlayer();
			//check of the player in the event is the owner of this UI. Note that args are the parameters of the event
			this.players[args.playerID].name = args.playerName;
			this.players[args.playerID].id = args.playerID;
			
			this.nameLabels[args.playerID].htmlText = args.playerName;
			if (args.playerID == pID)
				this.sbP.htmlText = args.playerName;
			sortScoreBoard();
			scoreBoardShow(players_no);
		}
	}
}