package  {
	
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.media.Sound;
	import flash.media.SoundTransform;
	
	
	public class PlayerSelectMenu extends MovieClip {
		
		private var selected:String;
		
		private function get selectSound():Sound {
			return Project.instance.selectSound;
		}
		
		public function PlayerSelectMenu() {

			one.buttonMode = two.buttonMode = true;
			
			addEventListener(MouseEvent.CLICK,
				function(e:MouseEvent):void {
					var button:MovieClip = e.target as MovieClip;
					if(button) {
						switch(button.name) {
							case "one":
							case "two":
								selectSound.play(0,1,new SoundTransform(1,button.name=="one"?-.5:button.bane=="three"?.5:0));
								selected = button.name;
								button.play();
								gotoAndPlay("select1");
								break;
							default:
								trace("PlayerSelectMenu - click",button.name);
								break;
						}
					}
				});
		}
	}
	
}
