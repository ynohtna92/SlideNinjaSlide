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
	
	public class MusicPlayer extends MovieClip {
		
		public var gameAPI:Object;
		public var globals:Object;

		private var backg_valve:MovieClip;
		private var dropd_valve:MovieClip;

		public function MusicPlayer() {
			// constructor code
		}

		//set initialise this instance's gameAPI
		public function setup(api:Object, globals:Object) {
			this.gameAPI = api;
			this.globals = globals;
			
			// default: play btn is visible, stop button is not
			trace("##Called MusicPlayer Setup!");
			this.visible = true;

			mpTitle.text = Globals.instance.GameInterface.Translate("#MusicPlayerTitle")

			playBtn.addEventListener(MouseEvent.CLICK, onButtonClicked);
			stopBtn.addEventListener(MouseEvent.CLICK, onButtonClicked);
			rewindBtn.addEventListener(MouseEvent.CLICK, onButtonClicked);
			forwardBtn.addEventListener(MouseEvent.CLICK, onButtonClicked);
			loopBtn.addEventListener(MouseEvent.CLICK, onButtonClicked);

			// add children
			//WindowSkinned
			//backg_valve = replaceWithValveComponent(this.backg, "DB4_floading_panel", true);

			//dropd_valve = replaceWithValveComponent(this.dropd, "arrow_down", false);
			//backg_valve = replaceWithValveComponent(this.backg, "WindowSkinned", true);

			//this.addChild(backg_valve);
			//this.addChild(dropd_valve);
			this.addChild(mpTitle);
			this.addChild(playBtn);
			this.addChild(stopBtn);
			this.addChild(rewindBtn);
			this.addChild(forwardBtn);
			this.addChild(loopBtn);
			
			//dropd_valve.visible = true
			trace("## Called MusicPlayer Setup!");
		}

		private function onButtonClicked(event:MouseEvent) {
			var btnName:String = event.target.name;
			trace("## " + btnName + " clicked!");
			var pID:int = globals.Players.GetLocalPlayer();
			this.gameAPI.SendServerCommand("MusicPlayerButtonClicked " + btnName.substring(0,btnName.length-3));

			if (btnName == "playBtn") {
				playBtn.visible = false;
				stopBtn.visible = true;
			} else if (btnName == "stopBtn") {
				stopBtn.visible = false;
				playBtn.visible = true;
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
			
			this.x = 60*yScale;
			this.y = 70*yScale;
			
			trace("#Result Resize: ",this.x,this.y,yScale);

			this.width = this.width*yScale*1/4;
			this.height	 = this.height*yScale*1/4;
			
			//Now we just set the scale of this element, because these parameters are already the inverse ratios
			this.scaleX = xScale*1/4;
			this.scaleY = yScale*1/4;
			
			trace("#MusicPlayer Panel Resize");
		}
		/*
		public function screenResize(stageW:int, stageH:int, xScale:Number, yScale:Number, wide:Boolean) {

			trace("Stage Size: ",stageW,stageH);
			trace("y scale: " + yScale);

			this.x = 16*stageW/20;
			this.y = 18*stageH/20; //A bit on top of the middle to show the chat
					 
			//Now we just set the scale of this element, because these parameters are already the inverse ratios
			this.scaleX = xScale;
			this.scaleY = yScale;
		}*/

	}
}
