package  {
	
	import flash.display.MovieClip;
	import com.dobuki.ConnectedBattlefield;
	import com.dobuki.IDelegate;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.utils.setTimeout;
	import com.dobuki.Mozart;
	import playerio.RoomInfo;
	import flash.events.MouseEvent;
	import flash.net.FileReference;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.net.FileFilter;
	import flash.utils.ByteArray;
	import flash.display.BitmapData;
	import flash.display.Bitmap;
	import flash.media.SoundChannel;
	import flash.media.Sound;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import flash.media.SoundTransform;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import by.blooddy.crypto.MD5;
	import flash.net.URLRequest;
	import com.newgrounds.API;
	
	
	public class ConnectedWorldGame extends MovieClip implements IDelegate {
		
		private var introMusic:Sound = new IntroMusic();
		private var cw:ConnectedBattlefield;
		private var canvas:Sprite = new Sprite();
		private var selectSound:Sound = new SelectSound();
		private var placeSound:Sound = new PlaceSound();
		private var cancelSound:Sound = new CancelSound();
		
		private function getUserId():String {
			return "dunki"+Math.random();
		}
		
		private var count:int = 0;
		private var pendingMoney:int = 0;
		private var moneyCounter:Number = 0;
		private var scale:Number = .3;
		
		private var score:int = 0;
		
		private function updateGold():void {
			refresh(cw);
		}
		
		private function fadeOut(channel:SoundChannel):void {
			var timer:Timer = new Timer(100,20);
			timer.addEventListener(TimerEvent.TIMER,
				function(e:TimerEvent):void {
					channel.soundTransform = new SoundTransform(1-timer.currentCount/timer.repeatCount);
				});
			timer.addEventListener(TimerEvent.TIMER_COMPLETE,
				function(e:TimerEvent):void {
					channel.stop();
				});
			timer.start();
		}
		
		public function ConnectedWorldGame() {
			API.connect(root,"38281:oywmHs2g","QaTRvuCHRIkPQp0AwEtMukvnUO9v40XT");
		}
		
		private function playIntro():void {
			var channel:SoundChannel = introMusic.play(0,int.MAX_VALUE,null);
			stage.addEventListener(MouseEvent.CLICK,
				function(e:MouseEvent):void {
					fadeOut(channel);
					intro.play();
					startGame();
					e.currentTarget.removeEventListener(e.type,arguments.callee);
				});
		}
		
		private function startGame():void {
			stage.addEventListener(MouseEvent.MOUSE_DOWN,onMouseDown);
//		trace("here");
			ui.wonderText.visible = false;
			addChildAt(canvas,0);
			canvas.x = stage.stageWidth/2;
			canvas.y = stage.stageHeight/2;
			graphics.beginFill(0xccFFcc);
			graphics.drawRect(0,0,stage.stageWidth,stage.stageHeight);
			graphics.endFill();
			
			var user_id:String = getUserId();
			
			cw = new ConnectedBattlefield(canvas,user_id);
			cw.delegate = this;
			var point:Point = new Point(Math.random()*2000,Math.random()*2000);
			cw.setScroll(point.x,point.y);
			
			cw.createUnit(user_id+(count++),"slimehouse",new Point(point.x,point.y));
//			cw.createUnit(user_id+(count++),"general",new Point());
//			cw.enterWorld("paris");
			setTimeout(
				cw.listWorlds,1000,
				function(array:Array) {
					for each(var roomInfo:RoomInfo in array) {
						trace(roomInfo.id);
					}
				});
//			cw.enterWorld("paris");
//			cw.enterWorld("paris2");
			//Mozart.instance.play(123);
			refresh(cw);
				
				
				
			cw.addEventListener("mateWithOtherPlayer",
				function(e:Event):void {
					API.unlockMedal("Connected Worlds");
				});
			ui.cancelBar.addEventListener(MouseEvent.MOUSE_DOWN,
				function(e:MouseEvent):void {
					if(cw.cursor) {
						clearSelection();
						cancelSound.play(0,0,new SoundTransform(.2));
					}
				});
				
			ui.water.addEventListener(MouseEvent.MOUSE_DOWN,
				function(e:MouseEvent):void {
					if(cw.cursor) {
						clearSelection();
						cancelSound.play(0,0,new SoundTransform(.2));
					}
					else if(gold>=cost(ui.water)) {
						selectSound.play(0,0,new SoundTransform(.2));
						ui.selector.visible =true;
						ui.selector.x = ui.water.x;
						ui.selector.y = ui.water.y;
						cw.cursor = new Water();
						gold -= cost(ui.water);
						pendingMoney = cost(ui.water);
						updateGold();
					}
					e.stopPropagation();
				});
				
			ui.house.addEventListener(MouseEvent.MOUSE_DOWN,
				function(e:MouseEvent):void {
					if(cw.cursor) {
						clearSelection();
						cancelSound.play(0,0,new SoundTransform(.2));
					}
					else if(gold>=cost(ui.house)) {
						selectSound.play(0,0,new SoundTransform(.2));
						ui.selector.visible =true;
						ui.selector.x = ui.house.x;
						ui.selector.y = ui.house.y;
						cw.cursor = new SlimeHouse();
						gold -= cost(ui.house);
						pendingMoney = cost(ui.house);
						updateGold();
					}
					e.stopPropagation();
				});
			ui.tree.addEventListener(MouseEvent.MOUSE_DOWN,
				function(e:MouseEvent):void {
					if(cw.cursor) {
						clearSelection();
						cancelSound.play(0,0,new SoundTransform(.2));
					}
					else if(gold>=cost(ui.tree)) {
						selectSound.play(0,0,new SoundTransform(.2));
						ui.selector.visible =true;
						ui.selector.x = ui.tree.x;
						ui.selector.y = ui.tree.y;
						cw.cursor = new Tree();
						gold -= cost(ui.tree);
						pendingMoney = cost(ui.tree);
						updateGold();
					}
					e.stopPropagation();
				});
			ui.nest.addEventListener(MouseEvent.MOUSE_DOWN,
				function(e:MouseEvent):void {
					if(cw.cursor) {
						clearSelection();
						cancelSound.play(0,0,new SoundTransform(.2));
					}
					else if(gold>=cost(ui.nest)) {
						selectSound.play(0,0,new SoundTransform(.2));
						ui.selector.visible =true;
						ui.selector.x = ui.nest.x;
						ui.selector.y = ui.nest.y;
						cw.cursor = new House();
						gold -= cost(ui.nest);
						pendingMoney = cost(ui.nest);
						updateGold();
					}
					e.stopPropagation();
				});
			ui.monument.addEventListener(MouseEvent.MOUSE_DOWN,
				function(e:MouseEvent):void {
					if(cw.cursor) {
						clearSelection();
						cancelSound.play(0,0,new SoundTransform(.2));
					}
					else if(gold>=cost(ui.monument)) {
						selectSound.play();
						//launchSelector();
						
						ui.selector.visible =true;
						ui.selector.x = ui.monument.x;
						ui.selector.y = ui.monument.y;
						cw.cursor = new Wonder();
						gold -= cost(ui.monument);
						pendingMoney = cost(ui.monument);
						updateGold();
					}
					e.stopPropagation();
				});
			addEventListener(Event.ENTER_FRAME,
				function(e:Event):void {
					updateMoneyCounter();
					scale += (2 / Math.pow(cw.popCount,.2) - scale)/50;
					canvas.scaleX = canvas.scaleY = scale;
				});
			ui.infospace.visible = false;
		}
		
		public function cost(button):int {
			if(button==ui.water) {
				return 1;
			}
			else if(button==ui.house) {
				return Math.min(999,Math.round(13.5*Math.pow(1.5,cw.countUnits("slimehouse"))));
			}
			else if(button==ui.tree) {
				return Math.min(999,Math.round(10*Math.pow(1.5,cw.countUnits("tree"))));
			}
			else if(button==ui.nest) {
				return Math.min(999,Math.round(200*Math.pow(1.5,cw.countUnits("house"))));
			}
			else if(button==ui.monument) {
				return 999;
			}
			return 0;
		}
		
		public function updateUI():void {
			ui.water_cost.text = cost(ui.water)+"";
			ui.tree_cost.text = cost(ui.tree)+"";
			ui.house_cost.text = cost(ui.house)+"";
			ui.nest_cost.text = cost(ui.nest)+"";
			ui.monument_cost.text = cost(ui.monument)+"";
			
			ui.water_cost.mouseEnabled = false;
			ui.tree_cost.mouseEnabled = false;
			ui.house_cost.mouseEnabled = false;
			ui.nest_cost.mouseEnabled = false;
			ui.monument_cost.mouseEnabled = false;
			
			updateButton(ui.water,ui.water_cost);
			updateButton(ui.monument,ui.monument_cost);
			updateButton(ui.nest,ui.nest_cost);
			updateButton(ui.house,ui.house_cost);
			updateButton(ui.tree,ui.tree_cost);
		}
		
		public function updateButton(button,textfield):void {
			if(cost(button)<=gold) {
				ui.addChild(button);
				ui.addChild(textfield);
			}
			else {
				ui.addChildAt(textfield,0);
				ui.addChildAt(button,0);				
			}
		}
		
		var file:FileReference = new FileReference();
		private function launchSelector():void {
			file.browse([new FileFilter("Images","*.jpeg; *.jpg;*.gif;*.png")]);
			file.addEventListener(Event.SELECT,onSelect);
		}
		
		private function onSelect(e:Event):void {
			file.addEventListener(Event.COMPLETE,onLoadImage);
			file.load();
			
		}
		
		private function onLoadImage(e:Event):void {
			var data:ByteArray= file.data;
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE,
				function(e:Event):void {
					var sprite:Sprite = new Sprite();
					sprite.addChild(loader);
					loader.width = 100; loader.height = 100;
					loader.scaleX = loader.scaleY = Math.min(loader.scaleX,loader.scaleY);
					loader.x = -loader.width/2 + loader.width/2;
					loader.y = -loader.height/2 + loader.height/2;
					var bitmapData:BitmapData = new BitmapData(loader.width,loader.height,true,0);
					bitmapData.draw(sprite,null,null,null,null,true);
					addChild(new Bitmap(bitmapData));
				});
			loader.loadBytes(data);
			file = null;
		}
		
		public function get gold():Number {
			return Math.floor(cw.faith);
		}
		
		public function set gold(value:Number):void {
			cw.faith = value;
		}
		
		private function onMouseDown(e:MouseEvent):void {
			if(cw.cursor) {
				if(cw.createFromCursor()) {
					placeSound.play(0,0,new SoundTransform(.2,canvas.mouseX/200));
					pendingMoney = 0;
					var smoke:Smoke = new Smoke();
					smoke.x = e.stageX;
					smoke.y = e.stageY;
					addChild(smoke);
				}
				else {
					cancelSound.play(0,0,new SoundTransform(.2));
				}
			}
			clearSelection();
		}
		
		private function clearSelection():void {
			gold += pendingMoney;
			pendingMoney = 0;
			if(cw.cursor && cw.cursor.parent==canvas)
				canvas.removeChild(cw.cursor);
			cw.cursor = null;
			ui.selector.visible = false;
		}
		
		public function refresh(cw:ConnectedBattlefield):void {
			ui.pop.text = cw.popCount + "";
			//ui.infospace.text = [Math.round(cw.scroll.x),Math.round(cw.scroll.y)].join(",");
			if(score<cw.popCount) {
				score = cw.popCount;
				if(score>=10) {
					if(API.isNewgrounds)
						API.unlockMedal("Pop 10");
				}
				if(score>=100) {
					if(API.isNewgrounds)
						API.unlockMedal("Pop 100");
				}
				postScore(score);
			}
			updateUI();
			
		}
		
		private function updateMoneyCounter():void {
			moneyCounter += (gold-moneyCounter)/5;
			ui.faith.text = Math.floor(moneyCounter) + "";
		}
		
		public function wonder(title:String,mine:Boolean):void {
			if(mine) {
				if(API.isNewgrounds)
					API.unlockMedal("Pyramid Scheme");
			}
			ui.wonderText.text = 
				mine ? "You have built a great Wonder of the World: " + title
				: title + ", a great wonder has been built in a faraway land";
			ui.wonderText.visible = true;
			setTimeout(function():void {ui.wonderText.visible = false},10000);
		}
		
		
		public function postScore(value:Number):void {
			//	gamejolt
			var username:String = root.loaderInfo.parameters.gjapi_username;
			var token:String = root.loaderInfo.parameters.gjapi_token;
			if(username) {
				var url:String = "http://gamejolt.com/api/game/v1/scores/add/?game_id="+"33181";
				url += "&score="+value;
				url += "&sort="+value;
				url += "&time="+new Date().time;
				url += "&username="+ username;
				url += "&user_token="+ token;
				url += "&format=json";
				url += "&time="+new Date().time;
				url += "&signature="+MD5.hash(url + "0973822742d4f5c51e3cc9064afe1dd5");
				var urlloader:URLLoader = new URLLoader();
				urlloader.addEventListener(IOErrorEvent.IO_ERROR,
					function(e:IOErrorEvent):void {
						trace(e);
					});
				urlloader.addEventListener(Event.COMPLETE,
				   function(e:Event):void {
				   });
				urlloader.load(new URLRequest(url));
			}
			
			//	newgrounds
			if(API.isNewgrounds) {
				API.postScore("Highest Population",value);
			}
		}
	}
	
}
