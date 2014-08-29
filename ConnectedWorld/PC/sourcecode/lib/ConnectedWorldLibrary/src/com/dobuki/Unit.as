package com.dobuki
{
	import com.dobuki.collision.ICollidable;
	import com.dobuki.unittype.UnitType;
	
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	public class Unit implements ICollidable
	{
		static public const LIFETIME:int = 60000;
		
		public var id:String;
		public var position:Point = new Point();
		public var visualPosition:Point = null;
		public var updated:int, born:int;
		public var world:ConnectedBattlefield;
		public var user:String;
		private var rectangle:Rectangle = new Rectangle();
		public var type:String;
		private var mc:MovieClip, under_mc:MovieClip;
		public var goal:Point;
		public var data:Object = {};
		public var parent:Unit;
		public var randomNumber:uint;
		private var _state:String;
		public var lastStateChange:int;
		public var title:String;
		
		public function Unit():void {
			
		}
		
		public function set state(value:String):void {
			if(_state!=value) {
				_state = value;
				lastStateChange = world.clock;
			}
		}
		
		public function get state():String {
			return _state;
		}
		
		static private var recycler:Array = [];
		
		static public function alloc():Unit {
			return recycler.length ? recycler.pop():new Unit();
		}
		
		public function destroy():void {
			id = null;
			position = new Point();
			updated = 0;
			world = null;
			recycler.push(this);
		}
		
		public function get movieClip():MovieClip {
			if(!mc) {
				var unitType:UnitType = UnitType.getUnitType(type);
				mc = new (unitType.Graphics);
				mc.name = id;
				mc.scaleX = unitType.defaultScale;
				mc.scaleY = unitType.defaultScale;
				mc.gotoAndStop((randomNumber)%mc.totalFrames+1);
			}
			return mc;
		}
		
		public function get underClip():MovieClip {
			if(!under_mc) {
				var unitType:UnitType = UnitType.getUnitType(type);
				if(unitType.UnderGraphics) {
					mc = new (unitType.UnderGraphics);
					mc.name = id;
					mc.scaleX = unitType.defaultScale;
					mc.scaleY = unitType.defaultScale;
					mc.gotoAndStop((randomNumber)%mc.totalFrames+1);
				}
			}
			return under_mc;
		}
		
		public function get popCount():int {
			var unitType:UnitType = UnitType.getUnitType(type);
			if(this.user==world.user_id)
				return unitType.calculatePopCount(this,world);
			return 0;
		}
		
		public function get faith():Number {
			var unitType:UnitType = UnitType.getUnitType(type);
			if(this.user==world.user_id)
				return unitType.calculateFaith(this,world);
			return 0;
		}
		
		public function broadcastUnit():void {
			world.broadcast(position,id,"updateUnit",
				{
					type:type,
					user:user,
					position:{
						x:position.x,
						y:position.y
					},
					goal:!goal?null:{
						x:goal.x,
						y:goal.y
					},
					state:state,
					alive:alive,
					title:title,
					data:data,
					randomNumber:randomNumber,
					age:age
				});
		}
		
		static public function distance(unit:Unit,unit2:Unit):Number {
			return Point.distance(unit.position,unit2.position);
		}
		
		public function init(id:String,type:String,user:String,world:ConnectedBattlefield):Unit {
			this.id = id;
			this.world = world;
			this.user = user;
			this.type = type;
			this.mc = null;
			this.goal = null;
			this.randomNumber = world.randomNumber;
			this.data = {};
			born = world.clock;
			
			var unitType:UnitType = UnitType.getUnitType(type);
			rectangle.width = unitType.size.width;
			rectangle.height = unitType.size.height;
			unitType.initUnit(this,world);
			
			
			return this;
		}
		
		public function update(data:Object):void
		{
//			trace(this.id,this.type,JSON.stringify(data));
			updated = world.clock;
			if(data.position) {
				position.x = data.position.x;
				position.y = data.position.y;
			}	
			if(data.goal) {
				goal = new Point(data.goal.x,data.goal.y);
			}
			state = data.state;
			type = data.type;
			user = data.user;
			born = data.born;
			title = data.title;
			this.data = data.data;
			randomNumber = data.randomNumber;
			born = world.clock - data.age;
		}
		
		public function get lastUpdated():int {
			return world.clock-updated;
		}
		
		public function get age():int {
			return world.clock - born;
		}
		
		public function refresh():void {
			var unitType:UnitType = UnitType.getUnitType(type);
			unitType.refresh(this,world);
		}
		
		public function get dimension():Rectangle
		{
			rectangle.x = position.x - rectangle.width/2;
			rectangle.y = position.y - rectangle.height/2;
			return rectangle;
		}
		
		public function get isBuilding():Boolean {
			var unitType:UnitType = UnitType.getUnitType(type);
			return unitType.isBuilding();
		}
		
		public function get isVisible():Boolean {
			var unitType:UnitType = UnitType.getUnitType(type);
			return unitType.isVisible(this);
		}
		
		public function get speed():Number {
			var unitType:UnitType = UnitType.getUnitType(type);
			return unitType.getSpeed(this,world);
		}
		
		public function get alive():Boolean {
			var unitType:UnitType = UnitType.getUnitType(type);
			return this.user != world.user_id || unitType.isAlive(this);
		}
		
	}
}