package com.dobuki.collision
{
	public class Collision
	{
		public var A:ICollidable,B:ICollidable;
		
		static private var recycler:Array = [];
		
		static public function alloc():Collision {
			return recycler.length ? recycler.pop():new Collision();
		}
		
		public function destroy():void {
			A = null;
			B = null;
			recycler.push(this);
		}
		
		public function init(colliderA:ICollidable,colliderB:ICollidable):Collision {
			A = colliderA;
			B = colliderB;
			return this;
		}
	}
}