package  {
	
	import flash.display.MovieClip;
	
	
	public class UIOverlay extends MovieClip {
		
		
		public function UIOverlay() {
			GlobalDispatcher.instance.addEventListener(UIEvent.OVERLAY,
				function(e:UIEvent):void {
					addChild(e.displayObject);
				});
		}
	}
	
}
