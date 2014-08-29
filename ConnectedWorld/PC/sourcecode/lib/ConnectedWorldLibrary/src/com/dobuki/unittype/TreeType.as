package com.dobuki.unittype
{
	import com.dobuki.ConnectedBattlefield;
	import com.dobuki.Unit;
	
	import flash.display.MovieClip;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;

	public class TreeType extends UnitType
	{
		static public const OCCUPIED:String = "occupied";
		static public const FREE:String = "free";
		
		override public function get Graphics():Class {
			return getDefinitionByName("Tree") as Class;
		}
		
		public function TreeType()
		{
			super();
		}
		
		override public function get cost():int {
			return 10;
		}
		
		override public function isBuilding():Boolean {
			return true;
		}
		
		override public function initUnit(unit:Unit,world:ConnectedBattlefield):void {
			super.initUnit(unit,world);
			if(unit.user==world.user_id) {
				unit.state = FREE;
				unit.data.food = 3;
			}
		}
		
		override public function affectDisplay(mc:MovieClip,unit:Unit,world:ConnectedBattlefield):void {
			if(unit.state==OCCUPIED) {
				mc.play();
				mc.tree.eye.visible = true;
			}
			else {
				mc.gotoAndStop(1);
				mc.tree.eye.visible = false;
			}
			mc.scaleX = mc.scaleY = this.defaultScale * Math.sqrt((2+unit.data.food) / 5);
		}
		
		override public function isVisible(unit:Unit):Boolean
		{
			return unit.data.food>0;
		}
		
		override public function isAlive(unit:Unit):Boolean {
			return unit.data.food>0;
		}
		
		override public function buildingRange():int {
			return 40;
		}
	}
}