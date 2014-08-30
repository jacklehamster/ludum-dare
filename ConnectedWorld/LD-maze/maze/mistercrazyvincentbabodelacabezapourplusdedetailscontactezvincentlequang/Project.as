package  {
	import flash.display.MovieClip;
	import com.dobuki.yahooks.*;
	import flash.events.Event;
	
	dynamic public class Project extends MovieClip {

		public var selectSound:Sound = new SelectSound();
		public var mode:String = "single";

		static public var instance:Project;
		
		public function Project() {
			Yahooks.gameId = "classy-fvkpovwqkijplc5ywq8iw";
			Yahooks.gameType = "Classy";
			Yahooks.online = false;
			instance = this;
		}
		
		static public function getUid():String {
			var so:SharedObject = SharedObject.getLocal("Pool");
			if(!so.data.uid) {
				so.setProperty("uid",MD5.hash(Math.random()+" "+new Date()+" "));
			}
			return so.data.uid;
		}

		static public function getName():String {
			var so:SharedObject = SharedObject.getLocal("Pool");
			return so.data.name;
		}
		
		static public function setName(value:String):void {
			var so:SharedObject = SharedObject.getLocal("Pool");
			so.setProperty("name",value);
		}
	}
	
}
