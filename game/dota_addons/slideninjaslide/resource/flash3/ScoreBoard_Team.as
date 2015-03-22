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
	
	public class ScoreBoard_Team extends MovieClip {
		
		public var gameAPI:Object;
		public var globals:Object;
		
		public var nameLabels:Object;
		public var scoreLabels:Object;

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

		public function ScoreBoard_Team() {
			// constructor code
		}

		//set initialise this instance's gameAPI
		public function setup(api:Object, globals:Object) {
			this.gameAPI = api;
			this.globals = globals;
			
			// default: play btn is visible, stop button is not
			trace("##Called ScoreBoard_t Setup!");
			this.visible = true;

			lbTitle.text = Globals.instance.GameInterface.Translate("#ScoreBoardTitle")
			
			buttonUp.addEventListener(MouseEvent.CLICK, onButtonClicked);
			buttonDown.addEventListener(MouseEvent.CLICK, onButtonClicked);
			
			//this.addChild(backg_valve);
			//this.addChild(dropd_valve);
			this.addChild(lbTitle);
			this.addChild(buttonUp);
			this.addChild(buttonDown);
			
			this.nameLabels = [lbP0,lbP1,lbP2,lbP3,lbP4,lbP5,lbP6,lbP7,lbP8,lbP9];
			this.scoreLabels = [lbN0,lbN1,lbN2,lbN3,lbN4,lbN5,lbN6,lbN7,lbN8,lbN9];

			//Player Labels
			this.addChild(lbP0);
			this.addChild(lbP1);
			this.addChild(lbP2);
			this.addChild(lbP3);
			this.addChild(lbP4);
			this.addChild(lbP5);
			this.addChild(lbP6);
			this.addChild(lbP7);
			this.addChild(lbP8);
			this.addChild(lbP9);
			//Player Scores
			this.addChild(lbN0);
			this.addChild(lbN1);
			this.addChild(lbN2);
			this.addChild(lbN3);
			this.addChild(lbN4);
			this.addChild(lbN5);
			this.addChild(lbN6);
			this.addChild(lbN7);
			this.addChild(lbN8);
			this.addChild(lbN9);
			
			this.addChild(lbP);
			this.addChild(lbN);
			lbP.visible = false;
			lbN.visible = false;
			
			for (var i:int = 0; i < this.nameLabels.length; i++)
			{
				this.nameLabels[i].text = "Disconnected";
			}
			
			this.gameAPI.SubscribeToGameEvent("cgm_scoreboard_update_score", this.onScoreUpdate);
			this.gameAPI.SubscribeToGameEvent("cgm_scoreboard_update_user", this.onUserUpdate);
			
			//dropd_valve.visible = true
			trace("## Called ScoreBoard_t Setup Completed!");
		}

		private function onButtonClicked(event:MouseEvent) {
			var btnName:String = event.target.name;
			trace("## " + btnName + " clicked!");
			var pID:int = globals.Players.GetLocalPlayer();
			this.gameAPI.SendServerCommand("ScoreBoardButtonClicked " + btnName.substring(0,btnName.length-3));
			
			if (btnName == "buttonUp") {
				buttonUp.visible = false;
				buttonDown.visible = true;
				background_1.visible = false;
				background_2.visible = true;
				lbP0.visible = false;
				lbP1.visible = false;
				lbP2.visible = false;
				lbP3.visible = false;
				lbP4.visible = false;
				lbP5.visible = false;
				lbP6.visible = false;
				lbP7.visible = false;
				lbP8.visible = false;
				lbP9.visible = false;
				lbN0.visible = false;
				lbN1.visible = false;
				lbN2.visible = false;
				lbN3.visible = false;
				lbN4.visible = false;
				lbN5.visible = false;
				lbN6.visible = false;
				lbN7.visible = false;
				lbN8.visible = false;
				lbN9.visible = false;
				lbP.visible = true;
				lbN.visible = true;
			} else if (btnName == "buttonDown") {
				buttonDown.visible = false;
				buttonUp.visible = true;
				background_2.visible = false;
				background_1.visible = true;
				lbP.visible = false;
				lbN.visible = false;
				lbP0.visible = true;
				lbP1.visible = true;
				lbP2.visible = true;
				lbP3.visible = true;
				lbP4.visible = true;
				lbP5.visible = true;
				lbP6.visible = true;
				lbP7.visible = true;
				lbP8.visible = true;
				lbP9.visible = true;
				lbN0.visible = true;
				lbN1.visible = true;
				lbN2.visible = true;
				lbN3.visible = true;
				lbN4.visible = true;
				lbN5.visible = true;
				lbN6.visible = true;
				lbN7.visible = true;
				lbN8.visible = true;
				lbN9.visible = true;
			}
		}

		//Parameters: 
		//	mc - The movieclip to replace
		//	type - The name of the class you want to replace with
		//	keepDimensions - Resize from default dimensions to the dimensions of mc (optional, false by default)
		public function replaceWithValveComponent(mc:MovieClip, type:String, keepDimensions:Boolean = false) : MovieClip {
			var parent = mc.parent;
			var oldx = mc.x;
			var oldy = mc.y;
			var oldwidth = mc.width;
			var oldheight = mc.height;
			
			var newObjectClass = getDefinitionByName(type);
			var newObject = new newObjectClass();
			newObject.x = oldx;
			newObject.y = oldy;
			if (keepDimensions) {
				newObject.width = oldwidth;
				newObject.height = oldheight;
			}
			
			parent.removeChild(mc);
			parent.addChild(newObject);
			
			return newObject;
		}
		
		//onScreenResize
		public function screenResize(stageW:int, stageH:int, xScale:Number, yScale:Number, wide:Boolean){
			
			trace("Stage Size: ",stageW,stageH);
						
			this.x = stageW - 180*yScale*0.8;
			this.y = 320*yScale*0.8;
			
			trace("#Result Resize: ",this.x,this.y,yScale);

			this.width = this.width*yScale;
			this.height	 = this.height*yScale;
			
			//Now we just set the scale of this element, because these parameters are already the inverse ratios
			this.scaleX = xScale*0.8;
			this.scaleY = yScale*0.8;
			
			trace("#ScoreBoard_t Panel Resize");			
		}
		
		//onScoreUpdate
		public function onScoreUpdate(args:Object) : void{
			var pID:int = globals.Players.GetLocalPlayer();
			//check of the player in the event is the owner of this UI. Note that args are the parameters of the event
			this.scoreLabels[args.playerID].text = args.playerScore;
			
			if (args.playerID == pID)
				this.lbN.text = args.playerScore;
		}
		
		//onUserUpdate
		public function onUserUpdate(args:Object) : void{
			var pID:int = globals.Players.GetLocalPlayer();
			//check of the player in the event is the owner of this UI. Note that args are the parameters of the event
			this.nameLabels[args.playerID].htmlText = args.playerName;
			this.lbP.htmlText = args.playerName;
		}
	}
}