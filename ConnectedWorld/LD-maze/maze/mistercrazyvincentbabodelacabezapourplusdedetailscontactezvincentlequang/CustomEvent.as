package {
	import flash.events.Event;
	
	dynamic public class CustomEvent extends Event {
		public function CustomEvent(str:String,obj:Object=null) {
			if(obj) {
				for(var i in obj) {
					this[i] = obj[i];
				}
			}
			super(str);
		}
	}
}