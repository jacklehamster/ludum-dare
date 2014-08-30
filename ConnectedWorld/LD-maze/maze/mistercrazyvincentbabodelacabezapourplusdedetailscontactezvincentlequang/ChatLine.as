package  {
	
	import flash.display.MovieClip;
	import flash.utils.getTimer;
	import flash.events.Event;
	
	
	public class ChatLine extends MovieClip {
		
		public var created:uint = 0;
		public function ChatLine() {
			mouseEnabled = mouseChildren = false;
			created = getTimer();
			addEventListener(Event.ENTER_FRAME,onFrame);
			alpha = 0;
		}
		
		private function onFrame(e:Event):void 
		{
			var now:int = getTimer();
			alpha = now-created<300? Math.max((now-created)/300,.1) : Math.min(1,(created+10000-now)/2000);
			if(alpha<=0) {
				e.currentTarget.removeEventListener(e.type,arguments.callee);
				if(parent) {
					parent.removeChild(e.currentTarget as ChatLine);
				}
			}
		}
	}
	
}
