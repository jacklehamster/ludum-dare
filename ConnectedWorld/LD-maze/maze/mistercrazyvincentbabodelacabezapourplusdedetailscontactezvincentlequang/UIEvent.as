package  {
	import flash.events.Event;
	import flash.display.DisplayObject;
	
	public class UIEvent extends Event {

		static public const OVERLAY:String = "overlay";
		
		public var displayObject:DisplayObject;
		
		public function UIEvent(type:String,object:DisplayObject) {
			super(type);
			displayObject = object;
		}

	}
	
}
