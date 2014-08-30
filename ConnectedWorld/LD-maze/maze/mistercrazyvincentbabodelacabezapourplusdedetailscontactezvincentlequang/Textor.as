package  {
	
	import flash.display.MovieClip;
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;
	import flash.events.Event;
	
	
	public class Textor extends MovieClip {
		
		
		public function Textor(to:String=null) {
			var self:Textor = this;
			tf.addEventListener(KeyboardEvent.KEY_DOWN,
				function(e:KeyboardEvent):void {
					if(e.charCode==Keyboard.ENTER) {
						var x:Number = GlobalMess.instance.position.x;
						var y:Number = GlobalMess.instance.position.y;
						GlobalDispatcher.instance.dispatchEvent(new NetworkEvent(NetworkEvent.SEND_ACTION,"chat",{text:tf.text,from:Achievement.playerName,to:to,position:{x:x,y:y}},false));
						parent.removeChild(self);
						Achievement.unlock(Achievement.CONNECTEDWORLDS);
					}
					e.stopImmediatePropagation();
				});
			addEventListener(Event.ADDED_TO_STAGE,
				function(e:Event):void {
					stage.focus = tf;
				});
		}
	}
	
}
