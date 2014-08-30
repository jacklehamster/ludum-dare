package  {
	import com.dobuki.Cache;
	import flash.utils.getTimer;
	
	public class DungeonMap extends DefaultMap {
		
		[Embed(source="Pokeball.swf",mimeType="application/octet-stream")]
		private static const Pokeball:Class;
		
		
		static public var instance:DungeonMap = new DungeonMap();
		
		
		public function DungeonMap():void {
			Cache.instance.set("Pokeball.swf","bytes",new Pokeball());
		}

		override protected function hasGround(px:int,py:int,ph:int):Boolean {
			var id:String = px+"|"+py+"|"+ph;
			if(block[id]===undefined && (Math.abs(px)>1 || Math.abs(py)>1)) {
				var rand:uint = RandSeedCacher.instance.seed(id)[0];
				block[id] = rand%100>65;
			}
			return !block[id];
		}
		
/*		override protected function getObjectsAtID(groundID):Array {
			var position:Object = getPositionAtGID(groundID);
			if(hasGround(position.x,position.y,position.h)) {
				var rand:uint = RandSeedCacher.instance.seed(groundID)[0];
				if(rand%100<10) {
					return ["Pokeball.swf|Pokeball"];
				}
			}
			return null;
		}
*/		
	}
	
}
