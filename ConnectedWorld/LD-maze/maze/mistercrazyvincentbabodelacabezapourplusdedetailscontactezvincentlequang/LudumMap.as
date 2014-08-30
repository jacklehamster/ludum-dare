package  {
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.events.Event;
	import flash.net.SharedObject;
	import flash.utils.ByteArray;
	import com.dobuki.Cache;
	import flash.geom.Rectangle;
	import flash.geom.Point;
	
	public class LudumMap extends DungeonMap {

		[Embed(source="canvas.swf",mimeType="application/octet-stream")]
		private static const CanvasSWF:Class;
		
		[Embed(source="ut2.swf",mimeType="application/octet-stream")]
		private static const Ut2SWF:Class;
		
		
		
		[Embed("LD30.json", mimeType = "application/octet-stream")]
		var LDJSon:Class;
		
		private var so:SharedObject = SharedObject.getLocal("LD");
		public var entries:Array = [], seed:String;
		public var otherRandomList:Array = [
			"ut2.swf|YouTube||JB1S31R2SeQ|Ludum Maze 29",
			"ut2.swf|YouTube||sw3hv23GVo0|Ludum Dare 30 Keynote",
			"ut2.swf|YouTube||sw3hv23GVo0|Ludum Dare 30 Keynote",
			"ut2.swf|YouTube||sw3hv23GVo0|Ludum Dare 30 Keynote",
			"ut2.swf|YouTube||GO2g8Nk2-3M|Porn",
			"ut2.swf|YouTube||GVd0OWhBS5s|Oh Slime",
			"ut2.swf|YouTube||CHUuhEZvNWU|Juniper",
			"ut2.swf|YouTube||wEDWtuUqVjk|Dare to Believe",
			"ut2.swf|YouTube||GjKaCu6ZlV8|Indochine",
			"ut2.swf|YouTube||EWs4abqdwZ0|Cabin Crew",
			"ut2.swf|YouTube||mkzPPxPgpEw|Voyage",
			"ut2.swf|YouTube||DJAX65Ud1_E|Meat Boy",
			"ut2.swf|YouTube||H4U22Y6orcI|Starfox",
			"ut2.swf|YouTube||V6YkYTM164Y|My Champion",
			"ut2.swf|YouTube||t5qkBoHjDec|Dragonworm",
			"ut2.swf|YouTube||aFWi0Nv-UIE|onegameamonth",
			"ut2.swf|YouTube||6rIxWqcBk4M|jontron",
			"ut2.swf|YouTube||PNkJCJLBaoA|Civilization",
			"ut2.swf|YouTube||aQ0yOmtl96A|CDZ"
		];
		private var walls:Object = {};
		
		static public var instance:LudumMap;
		
		public function LudumMap(link:String,seed:String="") {
			Cache.instance.set("canvas.swf","bytes",new CanvasSWF());
			Cache.instance.set("ut2.swf","bytes",new Ut2SWF());
			
			
			instance = this;
			this.seed = seed;
			// constructor code
			if(link=="LD.json") {
				var bytes:ByteArray = new LDJSon() as ByteArray;
				var json:String = bytes.readUTFBytes(bytes.bytesAvailable);
				entries = JSON.parse(json) as Array;
				//trace(entries);
			}
			else {
				var urlloader:URLLoader = new URLLoader();
				urlloader.addEventListener(Event.COMPLETE,
					function(e:Event):void {
						entries = JSON.parse(urlloader.data) as Array;
						trace(entries.length);
				});
				urlloader.load(new URLRequest(link));
			}
//			http://r.playerio.com/r/princess-fart-zarir7fqlucotpfhkcxsa/LD29.json
		}

		private function extractYoutube(entry:Object):void {
			for each(var pair:Array in entry.links) {
				if(pair[1].indexOf("youtube.com/watch?v=")>=0) {
					var id:String = pair[1].split("youtube.com/watch?v=")[1].split("&")[0];
					otherRandomList.push("ut2.swf|YouTube||"+id+"|"+pair[0]);
					otherRandomList.unshift("ut2.swf|YouTube||"+id+"|"+pair[0]);
				}
			}
		}
		
		protected function setWall(wallID:String,value:String):void {
			walls[wallID] = value;
		}
		
		
		override public function getWallByID(wallID:String):String {
			var superWall:String = super.getWallByID(wallID);
			if(!superWall)
				return null;
			//return super.getWallByID(wallID);
			if(!walls[wallID] && entries.length) {
				if(!so.data[wallID]) {
					var md5:String = MD5.hash(wallID+seed);
					var xp:int = (wallID.split("|")[1]);
					var yp:int = (wallID.split("|")[2]);
					var DIR:String = (wallID.split("|")[3]);
					var index:int = -1;
					var rand:uint = parseInt(md5.substr(0,8),16);
					if(rand%10==0) {
						index = rand%entries.length;
						var entry:Object = entries[index];
						setWall(wallID,
							"canvas.swf|Canvas||"+entry.img+"|"+entry.title.split("|").join("_")+"|"
							+entry.author.split("|").join("_")+"|"+entry.id+"|"
							+entry.large+"|"+entry.type+"|"
							+JSON.stringify(entry.links).split("|").join("_"));
						extractYoutube(entry);
					}
					else if(rand%20==1 && otherRandomList.length) {
						//trace(wallID,otherRandomList.length,otherRandomList[0]);
						setWall(wallID,otherRandomList.shift());
					}
					so.setProperty(wallID,""+index);
				}
				else {
					index = parseInt(so.data[wallID]);
					if(index>=0) {
						entry = entries[index]; //entries.pop();
						setWall(wallID,
							"canvas.swf|Canvas||"+entry.img+"|"+entry.title.split("|").join("_")+"|"
							+entry.author.split("|").join("_")+"|"+entry.id+"|"
							+entry.large+"|"+entry.type+"|"
							+JSON.stringify(entry.links).split("|").join("_"));
						extractYoutube(entry);
					}
					else if(rand%30==1 && otherRandomList.length) {
						trace(wallID,otherRandomList.length,otherRandomList[0]);
						setWall(wallID,otherRandomList.shift());
					}
				}
			}
			if(walls[wallID]) {
				return walls[wallID];
			}
			return super.getWallByID(wallID);
		}
		
		override public function getStartingPoint():Point {
			return findEmptySpace(new Rectangle(0,0,1000,1000));
		}
		
	}
	
}
