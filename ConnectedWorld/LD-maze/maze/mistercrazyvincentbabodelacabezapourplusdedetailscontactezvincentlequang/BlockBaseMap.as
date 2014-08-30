package  {
	import flash.geom.Rectangle;
	import flash.geom.Point;
	
	public class BlockBaseMap extends Map {

		protected function hasGround(px:int,py:int,ph:int):Boolean {
			return true;
		}
		
		override public function canGo(fromx:int,fromy:int,fromh:int,tox:int,toy:int,toh:int):Boolean {
			return hasGround(tox,toy,toh);
		}
		
		override protected function getGroundByID(groundID:String):String {
			var position:Object = getPositionAtGID(groundID);
			return hasGround(position.x,position.y,position.h) ? super.getGroundByID(groundID) : null;
		}
		
		override public function getWallByID(wallID:String):String {
			var position:Object = getPositionAtGID(wallID);
			return hasGround(position.x,position.y,position.h) ? null : super.getWallByID(wallID);
		}
		
		public function findEmptySpace(rect:Rectangle):Point {
			var point:Point = new Point();
			for(var i:int=0;i<1000;i++) {
				point.x = Math.round(Math.random()*rect.width + rect.x);
				point.y = Math.round(Math.random()*rect.height + rect.y);
				if(hasGround(point.x,point.y,0)) {
					return point;
				}
			}
			return null;
		}
	}
	
}
