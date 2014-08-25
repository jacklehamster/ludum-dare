package com.dobuki.unittype
{
	import flash.utils.getDefinitionByName;

	public class WaterType extends UnitType
	{
		public function WaterType()
		{
			super();
		}
		
		override public function get Graphics():Class {
			return getDefinitionByName("Water") as Class;
		}
		
		override public function get UnderGraphics():Class {
			return getDefinitionByName("WaterUnder") as Class;;
		}		
		
		override public function get defaultScale():Number {
			return 1;
		}
		
		override public function buildingRange():int {
			return 10;
		}
	}
}