package  {
	import flash.events.Event;
	
	public class NetworkEvent extends Event {

		static public const SEND_ACTION:String = "sendAction";

		public var data:Object = null;
		public var action:String;
		public var loopback:Boolean;
		
		public function NetworkEvent(type:String,action:String,data:Object,loopback:Boolean) {
			super(type);
			this.data = data;
			this.action = action;
			this.loopback = loopback;
		}

	}
	
}
