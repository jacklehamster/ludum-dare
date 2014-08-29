package com.dobuki
{
	import com.dobuki.unittype.UnitType;
	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.media.Sound;
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;
	import flash.utils.getTimer;
	
	public class ConnectedBattlefield extends ConnectedField
	{
		
		
		[Embed(source="assets/connectedworld.swf",symbol="UI")]
		public var UI:Class;
		
		
		public var randomNumber:uint = uint.MAX_VALUE*Math.random();

		private var increment:int = 0;
		public var cursor:MovieClip = null;
		
		private var units:Object = {};
//		private var ui:MovieClip = new UI();
		
		public var delegate:IDelegate;
		public var faith:Number = 0;
		
		
		public function ConnectedBattlefield(canvas:Sprite, user_id:String)
		{
			super(canvas, user_id);
		}
		
		override protected function refresh():void {
			super.refresh();
			clock = getTimer();
			for each(var unit:Unit in units) {
				if(unit.user==user_id && unit.alive) {
					unit.refresh();
					unit.broadcastUnit();
					faith += (unit.faith);
				}
				if(!unit.alive) {
					delete units[unit.id];
					unit.broadcastUnit();
				}
			}
			if(delegate) {
				delegate.refresh(this);
			}
		}
		
		public function calculateSurroundings(point:Point,radius:Number,includeBuildingRange:Boolean):Array {
			var array:Array = [];
			for each(var u:Unit in units) {
				var range:Number = radius;
				if(includeBuildingRange) {
					var type:UnitType = UnitType.getUnitType(u.type);
					range = Math.max(range,type.buildingRange());
				}		
				if(Point.distance(point,u.position)<=range) {
					array.push(u);
				}
			}
			return array;
		}
		
		
		public function canPlace(point:Point,radius:Number):Boolean {
			var array:Array = calculateSurroundings(point,radius,true);
			for each(var u:Unit in array) {
				if(u.isBuilding) {
					return false;
				}
			}
			return true;
		}
		
		public function countUnits(type:String):int {
			var count:int = 0;
			for each(var unit:Unit in units) {
				if(unit.user==user_id && unit.type==type) {
					count++;
				}
			}
			return count;
		}
		
		public function createFromCursor():Boolean {
//		override protected function onMouseDown(e:MouseEvent):void {
//			super.onMouseDown(e);
			if(cursor) {
				var type:String = getQualifiedClassName(cursor).toLowerCase();
				var unitType:UnitType = UnitType.getUnitType(type);
				var point:Point = getMousePoint();
				if(!canPlace(point,unitType.buildingRange())) {
					return false;
				}
				createUnit(user_id+"_"+increment++,type,point);
				return true;
			}
			return false;
		}		
		
		override protected function onMouseMove(e:MouseEvent):void {
			super.onMouseMove(e);
			if(cursor) {
				cursor.gotoAndStop(1);
				canvas.addChild(cursor);
				cursor.x = canvas.mouseX;
				cursor.y = canvas.mouseY;
				var type:String = getQualifiedClassName(cursor).toLowerCase();
				var unitType:UnitType = UnitType.getUnitType(type);
				
				cursor.alpha = canPlace(getMousePoint(),unitType.buildingRange())?.5:.05;
				cursor.width = cursor.height = 30;
				cursor.scaleX = cursor.scaleY = Math.min(cursor.scaleX,cursor.scaleY);
				cursor.mouseChildren = cursor.mouseEnabled = false;
			}
			e.updateAfterEvent();
		}
		
		public function get popCount():int {
			var count:int = 0;
			for each(var unit:Unit in units) {
				count += unit.popCount;
			}
			return count;
		}
		
		public function findUnit(id:String):Unit {
			return units[id];
		}
		
		override protected function display(canvas:Sprite):void {
			super.display(canvas);
			
			var dico:Object = {};
			for(var i:int=0;i<canvas.numChildren;i++) {
				var m:MovieClip = canvas.getChildAt(i) as MovieClip;
				if(m && m!=cursor && m!=underCanvas) {
					dico[m.name] = m;
				}
			}
/*			while(underCanvas.numChildren) {
				underCanvas.removeChildAt(0);
			}*/
			
			var array:Array = [];
			for each(var unit:Unit in units) {
				var mc:MovieClip = unit.movieClip;
				if(unit.isVisible) {
					if(!unit.visualPosition) {
						unit.visualPosition = unit.position.clone();
					}
					mc.x = unit.visualPosition.x - scroll.x;
					mc.y = unit.visualPosition.y - scroll.y;
					if(mc.x>-stage.stageWidth && mc.x<stage.stageWidth && mc.y>-stage.stageHeight && mc.y<stage.stageHeight) {
						if(mc.parent!=canvas) {
							canvas.addChild(mc);
						}
						array.push(mc);
						delete dico[mc.name];
						var unitType:UnitType = UnitType.getUnitType(unit.type);
						unitType.affectDisplay(mc,unit,this);
					}
					
					if(unit.goal) {
						var dx:Number = -unit.position.x + unit.goal.x;
						var dy:Number = -unit.position.y + unit.goal.y;
						var dist:Number = Math.sqrt(dx*dx+dy*dy);
						
						
						if(dist>5) {
							if(unit.movieClip.slimo.currentLabel=="IDLE") {
								unit.movieClip.slimo.gotoAndPlay("GROUND");
							}
							
							if(unit.movieClip.slimo.currentLabel=="AIR") {
								unit.position.x += dx/dist*unit.speed;
								unit.position.y += dy/dist*unit.speed;
								unit.visualPosition.x += (unit.position.x - unit.visualPosition.x)/10;
								unit.visualPosition.y += (unit.position.y - unit.visualPosition.y)/10;
							}
						}
						else {
							unit.goal = null;
						}
					}
				}
//				canvas.addChild(mc);
				
				
				

			}
			
			array.sortOn("y",Array.NUMERIC);
			
			for (i=0;i<array.length;i++) {
				canvas.setChildIndex(array[i],i);
			}
			
			for each(m in dico) {
				if(m.parent==canvas)
					canvas.removeChild(m);
			}
		}
		
/*		override public function getCell(x:int,y:int):Array {
			var cell:Array = super.getCell(x,y);
			var units:Array = getUnits(x,y);
			if(units && units.length) {
				cell = cell?cell.concat(units):units;
			}
			return cell;
		}		
	*/	
		protected function getUnits(x:int,y:int):Array
		{
			var array:Array = [];
			for each(var unit:Unit in units) {
				var ux:int = Math.round(unit.position.x);
				var uy:int = Math.round(unit.position.y);
				if(ux==x && uy==y) {
					array.push(unit);
				}
			}
			
			return null;
		}
		
		public function createUnit(id:String,type:String,position:Point):Unit {
			var unit:Unit = units[id] = Unit.alloc().init(
				id,
				type,
				user_id,
				this
			);
			unit.position = position.clone();
			return unit;
		}
		
		override public function onAction(id:String,action:String,data:Object,user:String,world:World):void {
//			trace(id,action,JSON.stringify(data));
			switch(action) {
				case "updateUnit":
					if(!data.alive) {
						delete units[id];
					}
					else {
						if(!units[id]) {
							units[id] = Unit.alloc().init(id,data.type,data.user,this);
						}
						if(user!=user_id)
							(units[id] as Unit).update(data);
					}
					break;
				case "wonder":
					if(delegate)
						delegate.wonder(data.title,data.user==user_id);
					break;
				case "interMate":
					if(data.user1==user_id || data.user2==user_id)
						dispatchEvent(new Event("mateWithOtherPlayer"));
					break;
				default:
					super.onAction(id,action,data,user,world);
			}
		}
		
		private function removeOldUnits():void {
			for (var id:String in units) {
				var unit:Unit = units[id];
				if(unit.lastUpdated>Unit.LIFETIME) {
					units[id].destroy();
					delete units[id];
				}
			}
		}
	}
}