package  {
	import flash.events.Event;
	
	public class PositionEvent extends Event {

		static public const MOVEPOSITION:String = "movePosition";
		static public const TRACE:String = "trace";
		
		public var data:Object;
		
		public function PositionEvent(type:String,data:Object):void {
			super(type);
			this.data = data;
		}

	}
	
}
