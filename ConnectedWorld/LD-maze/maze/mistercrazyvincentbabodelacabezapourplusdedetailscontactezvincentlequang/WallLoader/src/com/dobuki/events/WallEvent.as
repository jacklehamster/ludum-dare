package com.dobuki.events
{
	import flash.events.Event;
	
	public class WallEvent extends Event
	{
		static public const MOVE_TO:String = "moveTo";
		static public const RECYCLE:String = "recycle";
		
		public var distance:Number;
		
		public function WallEvent(type:String, distance:Number=0)
		{
			super(type, bubbles, cancelable);
			this.distance = distance;
		}
	}
}