package  {
	
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.display.SimpleButton;
	import flash.events.Event;
	
	
	public class GameTypeSelector extends MovieClip {
		
		
		public function GameTypeSelector() {
			addEventListener(MouseEvent.CLICK,onClick);
		}
		
		private function onClick(e:MouseEvent):void {
			var target:SimpleButton = e.target as SimpleButton;
			if(target) {
				switch(target.name) {
					case "onevsone":
						Project.instance.selectSound.play();
						gotoAndStop(1);
						break;
					case "twovstwo":
						Project.instance.selectSound.play();
						gotoAndStop(2);
						break;
					case "cutthroat":
						Project.instance.selectSound.play();
						gotoAndStop(3);
						break;
				}
				dispatchEvent(new Event(Event.CHANGE));
			}
		}
	}
	
}
