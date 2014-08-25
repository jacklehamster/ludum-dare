package com.dobuki.unittype
{
	import com.dobuki.ConnectedBattlefield;
	import com.dobuki.Unit;
	
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.utils.getDefinitionByName;

	public class SlimeHouseType extends BuildingType
	{
		
		override public function get Graphics():Class {
			return getDefinitionByName("SlimeHouse") as Class;
		}
		override protected function get unitType():String {
			return "slime";
		}	
		
		override public function get cost():int {
			return 100;
		}
		
		override public function affectDisplay(mc:MovieClip,unit:Unit,world:ConnectedBattlefield):void {
			mc.scaleX = mc.scaleY = this.defaultScale * (Math.sqrt(Math.max(1,unit.data.totalSpawn)));
		}
		
		override public function buildingRange():int {
			return 80;
		}
	}
}