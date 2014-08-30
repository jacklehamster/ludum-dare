package  {
	
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.display.SimpleButton;
	
	
	public class NumPlayerSwitch extends MovieClip {
		
		
		public function NumPlayerSwitch() {
			stop();
			addEventListener(MouseEvent.CLICK,onClick);
		}
		
		private function onClick(e:MouseEvent):void {
			var target:SimpleButton = e.target as SimpleButton;
			if(target) {
				switch(target.name) {
					case "three":
						Project.instance.selectSound.play();
						gotoAndStop(1);
						break;
					case "four":
						Project.instance.selectSound.play();
						gotoAndStop(2);
						break;
					case "five":
						Project.instance.selectSound.play();
						gotoAndStop(3);
						break;
				}
			}
		}
	}
	
}
