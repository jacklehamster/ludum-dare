package  {
	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;
	import com.dobuki.yahooks.*;
	import flash.events.Event;
	import flash.net.SharedObject;
	
	
	public class Chatter extends MovieClip {
		
		public var username:String = null;
		private var overlay:Sprite;
		private var yahook:IYahooks;
		public var active:Boolean;
		public function Chatter() {
			active = true;
			addEventListener(Event.ADDED_TO_STAGE,onStage);
			addEventListener(Event.REMOVED_FROM_STAGE,offStage);
		}
		
		private function get self():Chatter {
			return this;
		}
		
		private function onStage(e:Event):void {
			yahook = Yahooks.instance;
			yahook.register(self,"chatter");
			chatbox.visible = false;
			profile.visible = false;
			mouseEnabled = mouseChildren = false;
			overlay = addChild(new Sprite()) as Sprite;
			stage.addEventListener(KeyboardEvent.KEY_DOWN,onKey);
		}
		
		private function offStage(e:Event):void {
			stage.removeEventListener(KeyboardEvent.KEY_DOWN,onKey);
		}
		
		public function show():void {
			if(active) {
				chatbox.visible = true;
				profile.visible = true;
				chatbox.text = "";
				stage.focus = chatbox;
				dispatchEvent(new Event(Event.OPEN));
			}
		}
		
		private function onKey(e:KeyboardEvent):void {
			if(!visible || stage.focus!=chatbox) {
				show();
			}
			else {
				if(e.keyCode==Keyboard.ENTER) {
					if(chatbox.text.length)
						yahook.call(this,"serverSendMessage",false,(username?username+": ":"") + chatbox.text);
					chatbox.text = "";
					chatbox.visible = false;
					profile.visible = false;
					dispatchEvent(new Event(Event.CLOSE));
					stage.focus = MovieClip(root);
					e.preventDefault();
					e.stopImmediatePropagation();
				}
			}
		}
		
		public function serverSendMessage(message:String):void {
			trace(message);
			var chatLine:ChatLine = new ChatLine();
			chatLine.tf.text = message;
			overlay.addChild(chatLine);
			orderLine();
			shiftUp();
		}
		
		private function orderLine():void {
			var array:Array = [];
			for(var i:int=0;i<overlay.numChildren;i++) {
				var child:ChatLine = overlay.getChildAt(i) as ChatLine;
				if(child)
					array.push(child);
			}
			array.sortOn("created",Array.NUMERIC|Array.DESCENDING);
			for(i=0;i<array.length;i++) {
				array[i].y = -(i+1)*28;
			}
		}
		
		private var shift:Number;
		private function shiftUp():void {
			shift = 28;
			removeEventListener(Event.ENTER_FRAME,onShift);
			addEventListener(Event.ENTER_FRAME,onShift);
		}
		
		private function onShift(e:Event):void {
			if(shift>=1) {
				shift/=2;
			}
			else {
				shift = 0;
				e.currentTarget.removeEventListener(e.type,arguments.callee);
			}
			overlay.y = shift;
		}
		
	}
	
}
