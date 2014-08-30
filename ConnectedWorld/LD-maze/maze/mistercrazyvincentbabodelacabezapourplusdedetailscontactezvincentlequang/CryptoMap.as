package {
	import flash.geom.Point;
	import flash.system.Security;
	import flash.utils.ByteArray;
	
	public class CryptoMap extends Map {

		public function CryptoMap(code:String=null) {
			if(code) {
				applyCode(code);
			}
		}
		
		function applyCode(code:String) {
			try {
				var bytes:ByteArray = Base64.decode(code);
				bytes.uncompress();
				var w = bytes.readObject();
				var g = bytes.readObject();
				for(var i in w) {
					setWall(i,w[i]);
				}
				for(i in g) {
					var split = i.split("|");
					setGround(split[0],split[1],split[2],g[i]);
				}
			}
			catch(error) {
			}
		}

		override public function hasGround(px:int,py:int,ph:int):Boolean {
			var id:String = px+"|"+py+"|"+ph;
			if(id in grounds)
				return getGround(px,py,ph) && getGroundObjects(px,py,ph).G;
			var mt:int = (px^py)+1;//^(hi+hpos);
			return !mt||Math.abs(Math.abs(mt))%13;
		}

		public function get mapcode():String {
			var bytes:ByteArray = new ByteArray();
			bytes.writeObject(walls);
			bytes.writeObject(grounds);
			bytes.compress();
			return Base64.encode(bytes);
		}
		
		override public function setWall(wallID:String,code:String):void {
			super.setWall(wallID,code);
			trace(mapcode);
		}
	}
}