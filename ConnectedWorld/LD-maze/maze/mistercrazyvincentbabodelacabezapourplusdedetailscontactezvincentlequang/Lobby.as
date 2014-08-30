package  {
	
	import flash.display.MovieClip;
	import flash.events.KeyboardEvent;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.ui.Keyboard;
	import com.dobuki.yahooks.*;
	import flash.net.SharedObject;
	
	
	public class Lobby extends GameArea implements IHookUserReceiver {
		
		private var cleared:Boolean = false;
		private var yahook:IYahooks;
		private var myId:String;
		private var users:Object = {};
		private var count:int = 0;
		
		public function Lobby() {
			addEventListener(Event.ADDED_TO_STAGE,onStage);
			addEventListener(Event.REMOVED_FROM_STAGE,offStage);
			myId = Project.getUid();
		}
		
		private function get self():Lobby {
			return this;
		}
		
		private function onStage(e:Event):void {
			yahook = Yahooks.instance;
			yahook.register(self,"lobby");
			stage.addEventListener(KeyboardEvent.KEY_DOWN,onKey);
			chatbox.addEventListener(FocusEvent.FOCUS_IN,onFocus);
			
			yahook.setJoinCallback(self,onJoin);
			yahook.setLeaveCallback(self,onLeave);
			chatlog.text = "";
		}
		
		public function userUpdated(user:Object):void {
			if(!users[user.id]) {
				users[user.id] = user;
				users[user.id].order = count++;
			}
			else {
				for (var prop:String in user) {
					users[user.id][prop] = user[prop];
				}
			}
			updateUsers();
		}

		private function onJoin(playerId:String,count:int):void {
		}

		private function onLeave(playerId:String,count:int):void {
			delete users[playerId];
			updateUsers();
		}
		
		private function updateUsers():void {
			var array:Array = [];
			for each(var user:Object in users) {
				array.push(user);
			}
			array.sortOn("count",Array.NUMERIC);
			var attendeeHash:Object = {};
			for(var i:int = attendees.numChildren-1;i>=0;i--) {
				var attendee:Attendee = attendees.getChildAt(i) as Attendee;
				if(attendee) {
					attendeeHash[attendee.name] = attendee;
					attendees.removeChild(attendee);
				}
			}
			for(i=0;i<array.length;i++) {
				attendee = attendeeHash[escape(user.name)] || new Attendee();
				attendee.name = escape(user.name);
				attendee.tf.text = user.name;
				attendee.profile.loadImage(user.profilePicture,null,user.profilePictureAlignment);
				attendee.x = 5;
				attendee.y = 5+i*(3+attendee.height);
				attendees.addChild(attendee);
			}
		}

		private function offStage(e:Event):void {
			stage.removeEventListener(KeyboardEvent.KEY_DOWN,onKey);
			chatbox.removeEventListener(FocusEvent.FOCUS_IN,onFocus);
			yahook.unregister(self);
		}
		
		private function onKey(e:KeyboardEvent):void {
			if(mainArea && !MovieClip(root).namePrompt.visible) {
				if(stage.focus != chatbox) {
					stage.focus = chatbox;
				}
				if(e.keyCode==Keyboard.ENTER) {
					if(chatbox.text.length!=0) {
						yahook.call(self,"sendChat",true,Project.getName(),chatbox.text);
					}
					e.stopImmediatePropagation();
					e.preventDefault();
				}
			}
		}
		
		public function sendChat(author:String,message:String):void {
			chatlog.appendText(author+": "+message+"\n");
			chatlog.setSelection(chatlog.length,chatlog.length);
			chatbox.text = "";
			stage.focus = chatbox;
		}
		
		private function onFocus(e:FocusEvent):void {
			if(!cleared) {
				cleared = true;
				chatbox.text = "";
			}
		}
	}
	
}
