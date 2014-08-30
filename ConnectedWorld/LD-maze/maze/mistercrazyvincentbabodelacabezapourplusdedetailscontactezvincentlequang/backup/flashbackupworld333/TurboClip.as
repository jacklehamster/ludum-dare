package {
	
	
	import flash.display.Sprite;
	import flash.display.MovieClip;
	
	public class TurboClip extends Sprite {
	
		function TurboClip() {
			var self:TurboClip = this;
			if(parent) {
				initialize(null);
			}
			else {
				this.addEventListener(Event.ADDED_TO_STAGE,initialize);
			}
			function initialize(e:Event) {
				while(numChildren)
					removeChildAt(0);
				optimize(parent as Sprite);
			}
		}
		
		
		
	
	}
}