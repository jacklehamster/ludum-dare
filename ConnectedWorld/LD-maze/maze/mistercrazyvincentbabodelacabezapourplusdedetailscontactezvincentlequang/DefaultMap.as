package {
	import flash.geom.Point;
	import flash.system.Security;
	import flash.events.Event;
	
	public class DefaultMap extends BlockBaseMap 
		implements IBlockEditor
	{

		public function DefaultMap():void {
			Editor.editor = this;
		}
		
		
		protected var block:Object = {};
		
		public function setBlock(px:int,py:int,ph:int,value:Boolean):void {
			var id:String = px+"|"+py+"|"+ph;
			block[id] = value;
			dispatchEvent(new Event(Event.CHANGE));
		}
		
		public function getBlock(px:int,py:int,ph:int):Boolean {
			var id:String = px+"|"+py+"|"+ph;
			return block[id];
		}
		
		override protected function hasGround(px:int,py:int,ph:int):Boolean {
			var id:String = px+"|"+py+"|"+ph;
			if(block[id]===undefined) {
				var rand:uint = RandSeedCacher.instance.seed(id)[0];
				block[id] = rand%10<6;
			}
			return !block[id];
		}
		
		
	}
}