
package  {
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.events.Event;
	import flash.net.SharedObject;
	import flash.utils.ByteArray;
	import flash.media.Sound;
	import flash.media.SoundTransform;
	
	public class TestMap extends DefaultMap {

		static public var instance:TestMap = new TestMap();
		
		static private var sounds:Array = [
			new mazeground1_sound(),
			new mazeground2_sound(),
			new mazeground3_sound(),
			new mazeground4_sound(),
			new mazeground5_sound()
		];
		
		private var movies:Array = [
			"GjKaCu6ZlV8",
			"3xHttYIwocY",
			"JzjLI2xkSSo",
			"aKibLPORq2s"
		];
		
		public function TestMap() {
//			setGround(5,3,0,"Dude12:H@G2,-3");
//			setGround(-4,0,0,":M@W"); 
		}

/*		override public function hasGround(px:int,py:int,ph:int):Boolean {
			var id:String = px+"|"+py+"|"+ph;
			var rand:uint = RandSeedCacher.instance.seed(id)[0];
			return rand%10<8;
			return super.hasGround(px,py,ph);
		}		
		*/
		
		override public function getWallByID(wallID:String):String {
//			if(!walls[wallID]) {
//				var seeds:Array = RandSeedCacher.instance.seed(wallID);
				//if(wallID.indexOf("#|-2|-6|")>=0) {
//					setWall(wallID,"ut2.swf|YouTube|EavpFIB83oI");//GjKaCu6ZlV8");
/*				var utid:String = randomYoutubeID(wallID);
				if(utid) {
					setWall(wallID,"ut2.swf|YouTube|"+utid);//GjKaCu6ZlV8");
				}
				else {
					setWall(wallID,"");
				}
				//}
*/			
//				setWall(wallID,"Base.swf|BaseWall")
//				return "Base.swf|BaseWall";
//			}
			return super.getWallByID(wallID);
		}
		
		override protected function defaultWall():String {
			return "Base.swf|BaseWall";
		}
		
		override protected function defaultGround():String {
			return "Base.swf|BaseWall";
		}
		
		private function randomYoutubeID(wallID):String {
			var seeds:Array = RandSeedCacher.instance.seed(wallID);
			return seeds[0]%10<5? movies[seeds[0]%movies.length]:null;
//			return "EavpFIB83oI";
//			return 
		}
		
		override public function canGo(fromx:int,fromy:int,fromh:int,tox:int,toy:int,toh:int):Boolean {
			return super.canGo(fromx,fromy,fromh,tox,toy,toh);
		}
		
		override public function getMap(xpos:int,ypos:int,hpos:int,idir:int,approach:*,mode:int):Array {
			var array:Array = super.getMap(xpos,ypos,hpos,idir,approach,mode);
/*			trace(array.length);
			if(array.length<=1) {
				var xd:int, yd:int, xyd:int, yxd:int;
				switch(idir) {
					case 0: xd=1;yd=1;xyd=0;yxd=0;break;
					case 1: xd=0;yd=0;xyd=1;yxd=-1; break;
					case 2: xd=-1;yd=-1;xyd=0;yxd=0; break;
					case 3: xd=0;yd=0;xyd=-1;yxd=1; break;
				}
				var ixp = xpos;
				var iyp = ypos;
				var xxp = ixp*xd-iyp*xyd;
				var yyp = iyp*yd-ixp*yxd-.5;
				
				array.push([xxp,yyp,0,null,"#|"+xpos+"|"+ypos+"|Dude12","#|"+xpos+"|"+ypos+"|Dude12","Dude12","unique"]);
				trace(xxp,yyp,xpos,ypos);
			}*/
			return array;
		}
		
/*		override public function rubWall(wallID:String):void {
			var rands:Array = RandSeedCacher.instance.seed(wallID);
			var sound:Sound = sounds[rands[0]%sounds.length];
			sound.play(0,0,new SoundTransform(.1));
		}*/
		
	}
	
}
