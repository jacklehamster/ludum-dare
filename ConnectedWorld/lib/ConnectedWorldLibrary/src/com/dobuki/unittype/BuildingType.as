package com.dobuki.unittype
{
	import com.dobuki.ConnectedBattlefield;
	import com.dobuki.Unit;
	
	import flash.geom.Point;

	public class BuildingType extends UnitType
	{
		override public function get Graphics():Class {
			return null;
//			return getDefinitionByName("House") as Class;
		}
		
		public function BuildingType()
		{
			super();
		}
		
		override public function get cost():int {
			return 0;
		}
		
		override public function initUnit(unit:Unit,world:ConnectedBattlefield):void {
			super.initUnit(unit,world);
			if(unit.user==world.user_id) {
				unit.data.lastSpawn = 0;
				unit.data.popAvailable = 1;
				unit.data.totalSpawn = 0;
				unit.data.startedReproduction = 0;
			}
		}
		
		protected function get unitType():String {
			return null;
		}
		
		override public function refresh(unit:Unit,world:ConnectedBattlefield):void {
			super.refresh(unit,world);
			if(unit.user==world.user_id) {
				if(unit.data.startedReproduction && world.clock - unit.data.startedReproduction>10000) {
					unit.data.startedReproduction = 0;
					unit.data.popAvailable = 1;
				}
				if(unit.data.popAvailable && world.clock - unit.data.lastSpawn>10000) {
					var newUnit:Unit = world.createUnit(unit.id + "_"+unit.data.totalSpawn,unitType,unit.position.add(new Point(0,2)));
					unit.data.popAvailable--;
					unit.data.lastSpawn = world.clock;
					unit.data.totalSpawn ++;
					newUnit.parent = unit;
					newUnit.randomNumber = unit.randomNumber + int((Math.random()-.5) * 4);
				}
			}
		}
		
		override public function calculatePopCount(unit:Unit,world:ConnectedBattlefield):int {
			return unit.data.popAvailable + (unit.data.startedReproduction?1:0);
		}	
		
		override public function isBuilding():Boolean {
			return true;
		}
		
	}
}