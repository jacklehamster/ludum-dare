package com.dobuki.collision
{
	import flash.geom.Rectangle;

	public class Collider
	{
		static public function collisions(collidables:Vector.<ICollidable>):Vector.<Collision>
		{
			var horizontal:Array = [];
			var vertical:Array = [];
			
			for(var i:uint=0;i<collidables.length;i++) {
				var unit:ICollidable = collidables[i];
				var dimension:Rectangle = unit.dimension;
				if(dimension.width && dimension.height) {
					horizontal.push(Marker.alloc().init(dimension.left,i,Marker.IN));
					horizontal.push(Marker.alloc().init(dimension.right,i,Marker.OUT));
					vertical.push(Marker.alloc().init(dimension.top,i,Marker.IN));
					vertical.push(Marker.alloc().init(dimension.bottom,i,Marker.OUT));
				}
			}
			
			//	sort markers
			horizontal.sortOn("position",Array.NUMERIC);
			vertical.sortOn("position",Array.NUMERIC);
			
			//	go from left to right. check collisions
			var indexCollisions:Vector.<uint> = new Vector.<uint>(collidables.length);
			var indexIn:Vector.<uint> = new Vector.<uint>(collidables.length);
			
			for(i=0;i<horizontal.length;i++) {
				var marker:Marker = horizontal[i];
				
			}
			
			
			Marker.destroyAllReferences();
			return null;
		}
	}
}

internal class Marker
{
	
	static const IN:int = 0;
	static const OUT:int = 1;
	public var position:Number;
	public var index:uint;
	
	static private var recycler:Array = [];
	
	static private var references:Array = [];
	
	static public function alloc():Marker {
		var marker:Marker = recycler.length ? recycler.pop():new Marker();
		references.push(marker);
		return marker;
	}
	
	public function destroy():void {
		position = 0;
		index = 0;
		recycler.push(this);
	}
	
	static public function destroyAllReferences():void {
		for each(var marker:Marker in references) {
			marker.destroy();
		}
		references = [];
	}
	
	public function init(position:Number,index:uint,inOrOut:int):Marker {
		this.position = position;
		this.index = index;
		return this;
	}
	
}