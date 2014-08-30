package {
	
	public function SuperMap implements IMap {
		
		var submap:IMap = null;
		var supmap:IMap = null;
		public function SuperMap(supmap:IMap,submap:IMap) {
			this.supmap = supmap;
			this.submap = submap;
		}
		
		function hasGround(px:int,py:int,ph:int):Boolean {
			return supmap.hasGround(px,py,ph) || submap.hasGround(px,py,ph);
		}
		
		function getGroundObjects(px:int,py:int,ph:int):Object {
			var objects:Object = supmap.getGroundObjects(px,py,ph);
			if(!objects)
				objects = submap.getGroundObjects(px,py,ph);
			return objects;
		}
		
		function getWall(wallID:String):String {
			var wall:String = supmap.getWall(wallID);
			if(!wall)
				wall = submap.getWall(wallID);
			return wall;
		}
		
		// DIRTY
		var _dirty = false;
		public function get dirty():Boolean {
			return _dirty;
		}

		public function set dirty(value:Boolean):void {
			_dirty = value;
		}
		
		function getMap(xpos:int,ypos:int,hpos:int,idir:int,approach,mode:int):Array {
			var array1:Array = supmap.getMap(xpos,ypos,hpos,idir,approach,mode);
			var array2:Array = submap.getMap(xpos,ypos,hpos,idir,approach,mode);
			return array1.concat(array2);
		}
		
		function setWall(wallID:String,code:String):void {
			this.submap.setWall(wallID,code);
		}
	}
}