package com.dobuki
{
	import com.dobuki.events.WallEvent;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.utils.Dictionary;
	
	import avmplus.getQualifiedClassName;
	
	public class Wall extends MovieClip
		implements IWall
	{
		static private var recycleBin:Dictionary = new Dictionary();
		
		static public var hoveredWall:Wall = null;

		protected var room:String, wallID:String, params:Array, 
			initialized:Boolean = false;
			
			

		public function Wall()
		{
			if(stage)
				onStage(null);
			addEventListener(Event.ADDED_TO_STAGE,onStage);
		}
		
		public function get canDraw():Boolean {
			return true;
		}
		
		public function get animated():Boolean {
			return totalFrames>1;
		}
		
		public function get cacheTag():String {
			return getQualifiedClassName(this);
		}
		
		public function get id():String {
			return wallID;
		}
		
		static public function recycleout(classObj:Class):Wall
		{
			var bin:Array = recycleBin[classObj];
			var wall:Wall = bin && bin.length ? bin.pop() : null;
			if(!wall) {
				wall = new classObj();
			}
			wall.initialized = false;
			return wall;
		}
		
		protected function get self():Wall
		{
			return this;
		}
		
		public function initialize(room:String,wallID:String,... params):IWall
		{
			initialized = true;
			this.room = room;
			this.wallID = wallID;
			this.params = params;
			
			addEventListener(MouseEvent.ROLL_OVER,rollOver);
			addEventListener(MouseEvent.ROLL_OUT,rollOut);
			
			return this;
		}
		
		public function keyboardAction(keyCode:int):void {
			
		}
		
		public function rollOver(e:MouseEvent):void {
			hoveredWall = self;
		}
		
		public function rollOut(e:MouseEvent):void {
			if(hoveredWall==self)
				hoveredWall = null;
		}
		
		public function get recyclable():Boolean
		{
			return true;
		}
		
		public function recycle():void {
			if(recyclable) {
				var bin:Array = recycleBin[Object(self).constructor];
				if(!bin) {
					recycleBin[Object(self).constructor] = bin = [];
				}
				bin.push(self);
				dispatchEvent(new WallEvent(WallEvent.RECYCLE));
			}
		}
		
		private function onStage(e:Event):void {
			var bin:Array = recycleBin[Object(self).constructor];
			if(bin) {
				var index:int = bin.indexOf(self);
				if(index>=0) {
					bin[index] = bin[bin.length-1];
					bin.pop();
				}
			}
			if(!initialized) {
				var ancestor:DisplayObjectContainer = self.parent;
				while(ancestor && !(ancestor is Wall)) {
					ancestor = ancestor.parent;
				}
				var wall:Wall = ancestor as Wall;
				if(wall) {
					initialize.apply(self,[wall.room,wall.wallID].concat(wall.params));
				}
			}
		}
		
		public function moveTo(e:WallEvent):void
		{
		}
	}
}