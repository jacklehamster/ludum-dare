package  {
	
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import com.dobuki.Wall;
	
	
	public class Pokeball extends Wall {
		
		
		public function Pokeball() {
			buttonMode = true;
			addEventListener(MouseEvent.CLICK,
				function(e:MouseEvent):void {
					trace(room,wallID,params);
				}
			);
			// constructor code
		}
	}
	
}
