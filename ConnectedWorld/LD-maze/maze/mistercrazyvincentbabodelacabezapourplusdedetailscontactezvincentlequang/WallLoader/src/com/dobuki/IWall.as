package com.dobuki
{
	import com.dobuki.events.WallEvent;

	public interface IWall
	{
		function initialize(room:String,wallID:String,... params):IWall;
		function moveTo(e:WallEvent):void;
		function recycle():void;
	}
}