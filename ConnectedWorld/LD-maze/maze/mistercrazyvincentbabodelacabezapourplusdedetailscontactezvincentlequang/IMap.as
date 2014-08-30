package {
	import flash.events.IEventDispatcher;
	import flash.geom.Point;
	
	interface IMap extends IEventDispatcher {
		
		function canGo(fromx:int,fromy:int,fromh:int,px:int,py:int,ph:int):Boolean;
		function getMap(xpos:int,ypos:int,hpos:int,idir:int,approach:*,mode:int):Array;
		function getStartingPoint():Point;
	}
}