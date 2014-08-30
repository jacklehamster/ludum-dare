package  {
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.events.Event;
	import flash.media.Sound;
	import com.dobuki.yahooks.*;
	import flash.net.SharedObject;
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;
	import flash.display.SimpleButton;
	import flash.display.InteractiveObject;
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.Bitmap;
	
	public class GameSelector extends MovieClip implements IHookUserReceiver {

		private var buttons:Array, areas:Array, myId:String, yahook:IYahooks,myRoom:String, pictureLoader:Loader;
		private var roomsHash:Object = {};

		private function get selectSound():Sound {
			return Project.instance.selectSound;
		}
				
		public function GameSelector() {
			buttonMode = true;
			mouseEnabled = false;
			mouseChildren = true;
			
			buttons = [lobby, gameList, myGames];
			areas = [chatArea, grid, mygamesArea];
			
			gameList.mainArea = true;
			
			for each(var mc:MovieClip in buttons) {
				mc.addEventListener(MouseEvent.CLICK,onClick);
			}
			gameList.gotoAndPlay(2);
			grid.startGame.addEventListener(MouseEvent.CLICK,onStart);
			addEventListener(Event.ADDED_TO_STAGE,onStage);
			addEventListener(Event.REMOVED_FROM_STAGE,offStage);
			
			myId = Project.getUid();
			var playerName:String = Project.getName();
			if(!playerName) {
				promptForName(null);
				profile.playerName.text = "";				
			}
			else {
				namePrompt.tf.text = playerName;
				namePrompt.visible =false;
				profile.playerName.text = playerName;
			}
			profile.addEventListener(MouseEvent.CLICK,promptForName);
			namePrompt.addEventListener(Event.CHANGE,onProfileChange);
		}
		
		private function onProfileChange(e:Event):void {
			if(namePrompt.imageHasChanged()) {
				yahook.setProfilePicture(ProfilePicture.bitmapData);
			}
			if(namePrompt.alignmentHasChanged()) {
				yahook.setProfilePictureAlignment(ProfilePicture.alignment);
			}
			if(Project.getName()!=namePrompt.tf.text) {
				Project.setName(namePrompt.tf.text);
				yahook.setName(namePrompt.tf.text);
			}
		}
		
		public function userUpdated(user:Object):void {
			if(user.id==myId) {
				if(user.name) {
					profile.playerName.text = user.name;
				}
				if(user.profilePicture) {
					if(user.profilePicture.length) {
						pictureLoader = new Loader();
						pictureLoader.loadBytes(user.profilePicture);
						pictureLoader.contentLoaderInfo.addEventListener(Event.COMPLETE,
							function(e:Event):void {
								var bitmap:Bitmap = pictureLoader.content as Bitmap;
								ProfilePicture.bitmapData = bitmap.bitmapData;
								if(user.profilePictureAlignment) {
									ProfilePicture.alignment = user.profilePictureAlignment;
								}
								pictureLoader = null;
							});
					}
					else {
						ProfilePicture.bitmapData = null;
					}
				}
				else if(user.profilePictureAlignment) {
					if(pictureLoader) {
						pictureLoader.contentLoaderInfo.addEventListener(Event.COMPLETE,
							function(e:Event):void {
								ProfilePicture.alignment = user.profilePictureAlignment;
							});
					}
					else
						ProfilePicture.alignment = user.profilePictureAlignment;
				}
			}
		}

		private function promptForName(e:MouseEvent):void {
			namePrompt.visible = true;
		}
		
		private function get self():GameSelector {
			return this;
		}
		
		private function onStage(e:Event):void {
			yahook = Yahooks.instance;
			
			Yahooks.instance.connect(self,myId);
			(Yahooks.instance as Yahooks).addEventListener(Event.CONNECT,
				function(e:Event):void {
					e.currentTarget.removeEventListener(e.type,arguments.callee);
					joinSomeRoom();
				});


			(Yahooks.instance as Yahooks).addEventListener(Event.OPEN,
				function(e:Event):void {
					e.currentTarget.removeEventListener(e.type,arguments.callee);
					yahook.register(self,"gameSelector");
					MovieClip(parent).play();
				});
		}
		
		private function joinSomeRoom():void {
			Yahooks.instance.listRooms(
				function(rooms:Array):void {
					var smallestCount:int = int.MAX_VALUE, bestRoom:String = null;
					for each(var room:Room in rooms) {
						roomsHash[room.name] = room.count;
						if(room.name.indexOf("Pool_Lobby")==0) {
							if(room.count<smallestCount) {
								smallestCount = room.count;
								bestRoom = room.name;
							}
						}
					}
					if(smallestCount>20) {
						for(var i:int=1;i<100;i++) {
							if(!roomsHash["Pool_Lobby"+i]) {
								bestRoom = "Pool_Lobby"+i;
								break;
							}
						}
					}
					myRoom = bestRoom;
					Yahooks.instance.joinRoom(bestRoom,Project.getName()?{name:Project.getName()}:{});
				}
			);
		}
		
		private function offStage(e:Event):void {
			yahook.unregister(self);
			yahook.leaveRoom(myRoom);
			yahook.disconnect();
		}
		
		private function onStart(e:MouseEvent):void {
			Project.instance.selectSound.play();
			grid.play();
		}
		
		private function showArea(area:MovieClip):void {
			for each(var a:GameArea in areas) {
				a.mainArea = a==area;
			}
			
			var diff:Number= area.x;
			var pos:Array = [chatArea.x-diff,grid.x-diff,mygamesArea.x-diff];
			addEventListener(Event.ENTER_FRAME,
				function(e:Event):void {
					for(var i:int=0;i<pos.length;i++) {
						areas[i].x += (pos[i]-areas[i].x)/3;
					}
					diff += (-diff)/3;
					if(Math.abs(diff)<1) {
						for(i=0;i<pos.length;i++) {
							areas[i].x = pos[i];
						}
						e.currentTarget.removeEventListener(e.type,arguments.callee);
					}
				});
		}
		
		private function onClick(e:MouseEvent):void {
			selectSound.play(0,1);
			if(buttons.indexOf(e.currentTarget)>=0) {
				clicked(e.currentTarget as MovieClip);
			}
		}
		
		private function clicked(button:MovieClip):void {
			for each(var mc:MovieClip in buttons) {
				if(mc==button) {
					mc.gotoAndPlay(2);
					var index:int = buttons.indexOf(mc);
					showArea(areas[index]);
				}
				else {
					mc.gotoAndStop(1);
				}
			}
		}
		
		public function createGame(game:String,slots:int):void {
			yahook.createGame(game,slots);
			clicked(myGames);
		}
	}
	
}
