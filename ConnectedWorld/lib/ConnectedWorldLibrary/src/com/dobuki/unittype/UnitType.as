package com.dobuki.unittype
{
	import com.dobuki.ConnectedBattlefield;
	import com.dobuki.Unit;
	import com.dobuki.World;
	import com.dobuki.utils.Size;
	
	import flash.display.MovieClip;

	public class UnitType
	{
		public function get size():Size
		{
			return Size.nullSize;
		}
		
		public function get Graphics():Class {
			return null;
		}
		
		public function get UnderGraphics():Class {
			return null;
		}
		
		public function get defaultScale():Number {
			return .3;
		}
		
		public function get cost():int {
			return 0;
		}
		
		static private var cache:Object = {};
		static private function createType(type:String,ClassObj:Class):UnitType {
			if(!cache[type]) {
				cache[type] = new ClassObj();
			}
			return cache[type];
		}
		
		static public function getUnitType(type:String):UnitType {
			switch(type) {
				case "house":
					return createType(type,HouseType);
					break;
				case "slimehouse":
					return createType(type,SlimeHouseType);
				case "tree":
					return createType(type,TreeType);
					break;
				case "slime":
				case "general":
					return createType(type,SlimeType);
				case "wonder":
					return createType(type,MonumentType);
				case "water":
					return createType(type,WaterType);
			}
			return new UnitType();
		}
		
		public function initUnit(unit:Unit,world:ConnectedBattlefield):void {
		}
		
		public function refresh(unit:Unit,world:ConnectedBattlefield):void {
		}
		
		public function calculatePopCount(unit:Unit,world:ConnectedBattlefield):int {
			return 0;
		}
		
		public function calculateFaith(unit:Unit,world:ConnectedBattlefield):Number {
			return 0;
		}
		
		public function isBuilding():Boolean {
			return false;
		}
		
		public function isVisible(unit:Unit):Boolean {
			return true;
		}

		public function isAlive(unit:Unit):Boolean {
			return true;
		}

		public function affectDisplay(mc:MovieClip,unit:Unit,world:ConnectedBattlefield):void {
			
		}
		
		public function getSpeed(unit:Unit,world:ConnectedBattlefield):Number {
			return 0;
		}
		
		public function buildingRange():int {
			return 80;
		}
	}
}