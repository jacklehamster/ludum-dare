package com.dobuki.unittype
{
	import com.dobuki.ConnectedBattlefield;
	import com.dobuki.Unit;
	
	import flash.display.MovieClip;
	import flash.utils.getDefinitionByName;

	public class HouseType extends UnitType
	{
		static public const OCCUPIED:String = "occupied";
		static public const FREE:String = "free";
		static public const FULL:String = "full";
		
		override public function get Graphics():Class {
			return getDefinitionByName("House") as Class;
		}
		
		override public function get cost():int {
			return 50;
		}
		
		override public function initUnit(unit:Unit,world:ConnectedBattlefield):void {
			super.initUnit(unit,world);
			if(unit.user==world.user_id) {
				unit.state = FREE;
			}
		}
		
		override public function affectDisplay(mc:MovieClip,unit:Unit,world:ConnectedBattlefield):void {
			if(unit.state==FULL) {
				mc.play();
				mc.house.love.visible = true;
			}
			else {
				mc.gotoAndStop(1);
				mc.house.love.visible = false;
			}
		}
		
		override public function buildingRange():int {
			return 100;
		}
	}
}