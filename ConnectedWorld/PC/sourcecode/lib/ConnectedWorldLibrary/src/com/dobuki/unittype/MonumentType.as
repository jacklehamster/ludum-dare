package com.dobuki.unittype
{
	import com.dobuki.ConnectedBattlefield;
	import com.dobuki.Unit;
	
	import flash.display.MovieClip;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.text.TextFieldType;
	import flash.ui.Keyboard;
	import flash.utils.getDefinitionByName;

	public class MonumentType extends UnitType
	{
		public function MonumentType()
		{
			super();
		}
		
		override public function get Graphics():Class {
			return getDefinitionByName("Wonder") as Class;
		}
		
		override public function get defaultScale():Number {
			return 1;
		}
		
		override public function buildingRange():int {
			return 200;
		}
		
		override public function affectDisplay(mc:MovieClip,unit:Unit,world:ConnectedBattlefield):void {
			if(!unit.title && unit.user==world.user_id) {
				if(mc.stage.focus!=mc.title) {
					mc.stage.focus = mc.title;
					if(!mc.initialized) {
						mc.title.setSelection(0,mc.title.length);
						mc.initialized = true;
						mc.title.addEventListener(KeyboardEvent.KEY_DOWN,
							function(e:KeyboardEvent):void {
								if(e.keyCode==Keyboard.ENTER) {
									unit.title = mc.title.text;
									unit.broadcastUnit();
									world.broadcast(null,unit.id,"wonder",{user:world.user_id,title:unit.title});
								}
							});
					}
				}
			}
			else {
				mc.title.border = false;
				mc.title.background = false;
				mc.title.text = unit.title?unit.title:"";
				mc.title.type = TextFieldType.DYNAMIC;
				mc.title.mouseEnabled = false;
			}
		}
		
	}
}