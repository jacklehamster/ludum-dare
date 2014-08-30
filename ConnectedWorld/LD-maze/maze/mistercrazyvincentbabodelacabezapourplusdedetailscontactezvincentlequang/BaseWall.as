package  {
	
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import com.dobuki.Wall;
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;
	import com.dobuki.IWall;
	import flash.events.Event;
	
	
	public class BaseWall extends Wall {
		override public function initialize(room:String,wallID:String,... params):IWall {
			stop();
			return super.initialize.apply(this,[room,wallID].concat(params));
		}
		
		override public function rollOver(e:MouseEvent):void {
			gotoAndStop("HILIGHT");
			super.rollOver(e);
		}
		
		override public function rollOut(e:MouseEvent):void {
			gotoAndStop("NORMAL");
			super.rollOut(e);
		}
		
		override public function keyboardAction(keyCode:int):void {
			switch(keyCode) {
				case Keyboard.SPACE:	//build
					var split:Array = id.split("|");
					var value:Boolean = Editor.editor.getBlock(split[1],split[2],split[3]);
					Editor.editor.setBlock(split[1],split[2],split[3],!value);
					break;
			}
		}
	}
	
}
