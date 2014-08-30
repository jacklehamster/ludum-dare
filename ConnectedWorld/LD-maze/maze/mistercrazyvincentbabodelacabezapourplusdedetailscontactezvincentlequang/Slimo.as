package  {
	
	import flash.display.MovieClip;
	import com.dobuki.Wall;
	import com.dobuki.IWall;
	import flash.events.MouseEvent;
	import flash.utils.setTimeout;
	
	
	public class Slimo extends Wall {
		private var player:String;
		override public function initialize(room:String,wallID:String,... params):IWall {
			player = params[0];
			return this;
		}
		
		public function Slimo():void {
			tf.text = "";
			tf.mouseEnabled = false;
			buttonMode = true;
			addEventListener(MouseEvent.MOUSE_DOWN,
				function(e:MouseEvent):void {
					GlobalDispatcher.instance.dispatchEvent(new UIEvent(UIEvent.OVERLAY,new Textor(player)));
				});
			GlobalDispatcher.instance.addEventListener("chat",
				function(e:NetworkEvent):void {
					var data:Object = e.data;
					if(data.from==player) {
						tf.text = e.data.text;
						trace(JSON.stringify(e.data));
						setTimeout(clear,10000);
					}
				});
		}
		
		private function clear():void {
			tf.text = "";
		}
	}
	
}
