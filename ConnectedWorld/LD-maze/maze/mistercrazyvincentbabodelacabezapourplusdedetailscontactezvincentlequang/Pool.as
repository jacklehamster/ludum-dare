package {
	import flash.display.*;
	import flash.geom.*;
	import flash.events.*;
	import flash.utils.*;
	
	import flash.text.TextFieldType;
	import flash.ui.Keyboard;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	import flash.media.Sound;
	import flash.external.ExternalInterface;
	import flash.net.SharedObject;
	import flash.filters.GlowFilter;
	import flash.media.SoundTransform;
	import flash.system.Capabilities;
	import flash.system.TouchscreenType;
	import com.dobuki.yahooks.Yahooks;
	import com.dobuki.yahooks.IYahooks;
	import com.dobuki.yahooks.Room;
	import com.dobuki.yahooks.LocalYahooks;
//	import com.adobe.ane.gameCenter.GameCenterController;

	public class Pool extends MovieClip {
		
		var self = this;
		
		var qballspot:Point = new Point(28,30);
		var RAYON;
		var HOLERAYON;
		var qball;
		var carpet;
		var papa;
		var block:Boolean;

		
		var ballorigin = null;

		var balls:Array = [];
		var binfos:Array = [];
		var bhistory:Array = [];

		var lastsunk;
		var rotgoal = 0;
	
		var lasttime = 0;
		var stick;
		var windialog;
		var BALLFRICTION;
		var WALLFRICTION;
		var SPINEFFECT;
		var STEP;
		var SLOWDOWN;
		var INCREMENT;
		var MAXSPEED;

		var mdist:Number;
		var shooting:Boolean = false;
		
		var ballstock = null;
		var sunks:Array = [];
		var rolling = null;
		
		var MAXPLAYTIME;
		var SERIAL;
		var ROOM;
		var me;
		var master:Boolean;
		var net:NetConnection;
		var instream:NetStream;
		var outstream:NetStream;
//		var pindex:int = 0;
		var players:Array = null;
		var ranges:Array = ["",""];
		var ready:Array = [false,false];
		
		var ballstatus:Array = null;
		var firsthit;
		
		var _mpoint:Point = new Point();
		var nameChanged:Boolean = false;
		var timestart;
		var skippedonce:Boolean = false;
		var gamestopped:Boolean = false;
		var ack;
		var restartrequest;
		
		var poolskin:MovieClip = new PoolSkin();
		
		var gamesetting:Object = {};
		var session = null;
		var holes:Array = [];
		var ballSound:Sound = new BallSound();
		var stickSound:Sound = new StickSound();
		var wallSound:Sound = new WallSound();
		var holeSound:Sound = new HoleSound();
		var chalkSound:Sound = new ChalkSound();
		
		
		private var currentRoom:String = null;
		
		private var yahook:IYahooks;
		private var scorer:IGameScore;
		
		private var score:Number=0, combo:Number=2, bonus:Number = 0,
			totalShots:int = 0;
		
		
		public function Pool() {
			visible = false;
			addEventListener(Event.ADDED_TO_STAGE,init);
			
			backButton.addEventListener(MouseEvent.CLICK,
				function(e:MouseEvent):void {
					MovieClip(root).gotoAndStop("Intro","Intro");
					e.stopImmediatePropagation();
				});
			chatButton.addEventListener(MouseEvent.CLICK,
				function(e:MouseEvent):void {
					MovieClip(root).chatter.visible = true;
					e.stopImmediatePropagation();
				});
			chatCount.mouseEnabled = chatCount.mouseChildren = false;
			notifyPeopleCount(0);
			notifyChatCount(0);
				
			shootButton.addEventListener(MouseEvent.MOUSE_DOWN,
				function(e:MouseEvent):void {
					shootBall();
				});

				
			yahook = MovieClip(root).mode=="single"?LocalYahooks.instance:Yahooks.instance;
			MovieClip(root).chatButton.visible = MovieClip(root).mode!="single";

			currentRoom = getUid();
			yahook.connect(root as MovieClip,getUid(),currentRoom);
			yahook.register(this,"pool");
				
			MovieClip(root).chatButton.addEventListener(MouseEvent.CLICK,onChat);
		
			overlay = addChild(new Sprite()) as Sprite;
			overlay.mouseEnabled = overlay.mouseChildren = false;

			MovieClip(root).rules.stop();
			MovieClip(root).rules.rule.stop();
			MovieClip(root).rules.visible =false;

			MovieClip(root).helpButton.addEventListener(MouseEvent.CLICK,onHelp);


			MovieClip(root).chatter.addEventListener(Event.OPEN,onOpenChat);
			MovieClip(root).chatter.addEventListener(Event.CLOSE,onCloseChat);
//			yahook.call(this,"pingpong",false,"hello");

			if(MovieClip(root).mode!="single") {
				checkRooms();
			}
			updateScoreAndCombo();
			
			if(Capabilities.touchscreenType==TouchscreenType.NONE) {
				scorer = new WebGameScore(root as MovieClip);
			}
			else {
				if(IOSGameScore.isSupported) {
					scorer = new IOSGameScore(root as MovieClip);
				}
			}
		}
		
		private function updateScoreAndCombo():void {
			MovieClip(root).combo.combo_tf.text = "x"+combo;
			MovieClip(root).combo.combobonus_tf.textColor = bonus>=0?MovieClip(root).combo.plus.textColor:MovieClip(root).combo.minus.textColor;
			MovieClip(root).combo.combobonus_tf.text = bonus<0?bonus:bonus>0?"+"+bonus:"";
			MovieClip(root).score_tf.text = (""+(1000000+score)).substr(1);
			MovieClip(root).combo.remaining.text = (100-totalShots);
		}
		
		private function onOpenChat(e:Event):void {
			MovieClip(root).chatButton.visible = false;
		}
		
		private function onCloseChat(e:Event):void {
			MovieClip(root).chatButton.visible = true;
		}
		
		private function onChat(e:MouseEvent):void {
			MovieClip(root).chatter.show();
		}
		
		private function onHelp(e:MouseEvent):void {
			MovieClip(root).rules.visible = true;
			MovieClip(root).rules.rule.stop();
			MovieClip(root).rules.play();
			MovieClip(root).helpButton.visible = false;
			stage.addEventListener(MouseEvent.MOUSE_DOWN,
				function(e:MouseEvent):void {
					e.currentTarget.removeEventListener(e.type,arguments.callee);
					MovieClip(root).rules.stop();
					switch(MovieClip(root).mode) {
						case "single":
							MovieClip(root).rules.rule.gotoAndStop(1);
							break;
					}
					MovieClip(root).rules.visible =false;
					MovieClip(root).helpButton.visible = true;
					e.stopImmediatePropagation();
					e.preventDefault();
				});
		}
		
		public function checkRooms():void {
			Yahooks.instance.listRooms(
				function(array:Array):void {
					var users:int = 0;
					for each(var room:Room in array) {
						users += room.count;
						if(room.name==currentRoom) {
							users--;
						}
						trace(room.name,currentRoom,users);
					}
					notifyPeopleCount(users);
					setTimeout(checkRooms,20000);
				}
			);
		}

		public function getUid():String {
			var so:SharedObject = SharedObject.getLocal("desperado");
			if(!so.data.uid) {
				so.setProperty("uid",MD5.hash(Math.random()+" "+new Date()+" "));
			}
			return so.data.uid;
		}
		

		public function pingpong(message:String):void {
			trace(message);
		}
		
		function notifyChatCount(count:int):void {
			chatCount.tf.text = count+"";
			chatCount.visible = count>0;
		}
		function notifyPeopleCount(count:int):void {
			peopleCount.tf.text = count+"";
			peopleCount.visible = count>0;
		}
		
		function get params() {
			return parent && MovieClip(parent).params?MovieClip(parent).params:loaderInfo.parameters;
		}
		
		function get paused():Boolean {
			return gamestopped || (!players||players.length<2) && !playSolo();
		}
		
		function playSolo():Boolean {
			return !gamesetting.playmulti;
		}

		public function init(e=null) {
			if(e) {
				e.currentTarget.removeEventListener(e.type,arguments.callee);
			}
			MovieClip(root).stopMusic();
			for(var i in params) {
				gamesetting[i] = params[i];
			}
			
			
			for(i=0;i<numChildren;i++) {
				var hole = getChildAt(i);
				if(hole is Hole) {
					hole.visible = false;
					holes.push(new Point(hole.x,hole.y));
				}
			}
			
			
			MAXPLAYTIME = gamesetting.MAXPLAYTIME?gamesetting.MAXPLAYTIME:60;
			SERIAL = gamesetting.SERIAL?gamesetting.SERIAL:"43e0f3ce68fefbea14a58c7c-275bd17789bc";
			ROOM = gamesetting.ROOM?gamesetting.ROOM:"pool";
			
			session = MD5.hash(""+ new Date().getTime());
			stick = m_stick;
			windialog = m_windialog;
			RAYON = 10;
			HOLERAYON = hole1.width/2;
			qball = ballarea.ball0;
			carpet = (parent as MovieClip).carpet;
			
			papa = parent;
			block = false;
			
			produceBalls();
			addEventListener(Event.ENTER_FRAME,loop);
			
			stick.overlay = stick.addChild(new Sprite());
			stick.mouseEnabled = stick.mouseChildren = false;
			ballstock = addChildAt(new Sprite(),getChildIndex(blakk)-1);
			ballstock.y = dropper.y;
			ballstock.x = dropper.x + 50;
			
			aimer.info = {m : aimer.transform.matrix};
			aimer.info.m.tx = qballspot.x;
			aimer.info.m.ty = qballspot.y;
			loadBallBMP(aimer,0);
			aimer.addEventListener(MouseEvent.MOUSE_DOWN,setAim);
			aimer.addEventListener(MouseEvent.MOUSE_MOVE,setAim);
			aimer.buttonMode = true;
			ballorigin = new Point(ballarea.ball1.x,ballarea.ball1.y);
			ballarea.mouseEnabled = ballarea.mouseChildren = false;
			skipbutton.addEventListener(MouseEvent.CLICK,skipPlayer);
			removebutton.addEventListener(MouseEvent.CLICK,removePlayer);
			windialog.continuebutton.addEventListener(MouseEvent.CLICK,restart);
			challengebox.accept.addEventListener(MouseEvent.CLICK,newgame);
			challengebox.reject.addEventListener(MouseEvent.CLICK,reject);
			removeChild(windialog);
			
			if(gamesetting.pic1) {
				setPicture(pic1,gamesetting.pic1);
			}
			if(gamesetting.pic2) {
				setPicture(pic2,gamesetting.pic2);
			}
			setPicture(picbg,gamesetting.picbg?gamesetting.picbg:"");
			
			if(gamesetting.stick) {
				setStickImage(gamesetting.stick,0);
			}
			
			if(gamesetting.playername) {
				player1.text = gamesetting.playername;
				nameChanged = true;
			}
			
			if(gamesetting.debug) {// || flash.system.Capabilities.playerType=="External"
				uicover.visible = false;
			}
			
			chalkarea.visible = false;
			chalk.addEventListener(MouseEvent.CLICK,onChalk);
			dropper.visible = false;
			connect();
			
			addEventListener(Event.REMOVED_FROM_STAGE,onExit);
			
			showAd();
		}
		
		private function showAd():void {
			if(Capabilities.touchscreenType==TouchscreenType.NONE) {
				
			}
			else if(IOSAdvertising.isSupported) {
				IOSAdvertising.showAd(stage);
			}
		}
		
		private function onExit(e:Event):void {
			removeEventListener(Event.ENTER_FRAME,loop);
			stage.removeEventListener(MouseEvent.MOUSE_MOVE,mouseMove);
			stage.removeEventListener(MouseEvent.MOUSE_DOWN,mouseDown);
			stage.removeEventListener(MouseEvent.MOUSE_UP,mouseUp);
		}
				
		private function onChalk(e:MouseEvent):void {
			if(stick.visible && !gamestopped) {
				chalkSound.play(0,1,new SoundTransform(1,(stick.x-stage.stageWidth/2)/stage.stageWidth));
				chalk.visible = false;
				stick.visible = false;
				var timeout:int = setTimeout(
					function():void {
						chalk.visible = true;
						chalk.x = Math.random()*chalkarea.width+chalkarea.x;
						chalk.y = Math.random()*chalkarea.height+chalkarea.y;
						chalk.rotation = Math.random()*360;
						stick.visible = true;
					},1000);
			}
		}

		public function newgame(e=null) {
			outstream.send("acceptNewgame");
		}
		
		public function acceptNewgame() {
			MovieClip(parent).restarting = true;
			outstream.send("requestNewgame",me);			
		}
		
		public function reject(e=null) {
			outstream.send("rejectNewgame");			
		}

		public function restart(e=null) {
			windialog.continuebutton.visible = false;
			if(restartrequest || playSolo()) {
				gamesetting.peer = null;
				gamesetting.visitor = null;
				MovieClip(parent).params = gamesetting;
				savePeer(restartrequest?restartrequest:null);
				if(outstream)
					outstream.close();
				if(instream)
					instream.close();
				if(net)
					net.close();
				//if(MovieClip(parent).davinci_loader)
					//MovieClip(parent).davinci_loader.reload(gamesetting);
				//else
					MovieClip(parent).gotoAndPlay(1);
			}
			else {
				MovieClip(parent).restarting = true;
				outstream.send("requestRestart",me);
			}
		}
		
		public function destroy() {
		}
		
		public function requestRestart(id) {
			restartrequest = id;
		}
		
		public function requestNewgame(id) {
			restartrequest = id;
			//outstream.send("startNewgame",me);
			setTimeout(startNewgame,1000);
		}
		
		public function startNewgame() {
			
			gamesetting.peer = null;
			gamesetting.playmulti = 1;
			gamesetting.visitor = null;
			MovieClip(parent).params = gamesetting;
			savePeer(restartrequest?restartrequest:null);
			if(outstream)
				outstream.close();
			if(instream)
				instream.close();
			net.close();
			MovieClip(parent).gotoAndPlay(1);
		}

		public function rejectNewgame() {
			gamesetting.peer = null;
			gamesetting.playmulti = null;
			gamesetting.visitor = null;
			MovieClip(parent).params = gamesetting;
			savePeer(null);
			if(outstream)
				outstream.close();
			if(instream)
				instream.close();
			net.close();
			MovieClip(parent).gotoAndPlay(1);
		}
		

		function skipPlayer(e) {
			if(hasPeer())
				outstream.send("requestSkip");
			else
				confirmSkip(false);
		}
		
		function removePlayer(e) {
			if(hasPeer())
				outstream.send("requestRemove");
			else
				confirmRemove(true,false);
		}

		public function requestRemove() {
			if(!timeleft && myturn && stick.parent) {
				confirmRemove(false,true);
			}
		}
		
		public function requestSkip() {
			if(!timeleft && myturn && stick.parent) {
				confirmSkip(true);
			}
		}

		public function confirmRemove(mywin:Boolean,streamout:Boolean) {
			gameOver(mywin);
			if(streamout) {
				outstream.send("confirmRemove",!mywin,false);
			}
		}

		public function confirmSkip(streamout:Boolean) {
			if(!myturn)
				skippedonce = true;
			nextPlayer();
			timestart = 0;
			if(streamout) {
				outstream.send("confirmSkip",false);
			}
		}
		
		function gameOver(mywin:Boolean) {
			addChild(windialog);
			if(!playSolo()) {
				windialog.tf.autoSize = "center";
				windialog.tf.text = mywin?"You Win":"You lose!";//player2.text + " Wins";
				infospace.text = mywin?"You win!":"You lose!";
				ExternalInterface.call("gameOver",mywin);
			}
			else {
				windialog.tf.autoSize = "center";
				windialog.tf.text = "Game Over";
				infospace.text = "Game Over";				
			}
			updateWinDialog();
			stick.visible = false;
			//stick.overlay.visible = false;
			gamestopped = true;
			
			score += (100-totalShots);
			scorer.postScore(score);
		}
		
		function updateWinDialog() {
			windialog.waiting.visible = windialog.continuebutton.visible = hasPeer() && !playSolo()||playSolo() && !hasPeer();
		}

		function setStickImage(url,index) {
			var loader:Loader = new Loader();
			var context:LoaderContext = new LoaderContext(true);
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE,
				function(e) {
					loader.x = -loader.width;
					loader.y = -loader.height/2;
					var image = stick.innerstick.getChildByName("image"+index);
					image.removeChildAt(0);
					image.addChild(loader);
					image.link = url;
					try {
						var content = loader.content;
						content.smoothing = true;
					}
					catch(e) {
					}
				});
			loader.load(new URLRequest(url),context);
		}

		function setPicture(element,url) {
			if(url!=element.text) {
				element.text = url;
				element.visible = false;
				var loader_name = element.name+"_loader";
				var loader:Loader = getChildByName(loader_name)?getChildByName(loader_name) as Loader:new Loader();
				if(url.length) {
					loader.cacheAsBitmap = true;
					loader.name = loader_name;
					loader.x = element.x;
					loader.y = element.y;
					loader.load(new URLRequest(url));
					element.parent.addChildAt(loader,getChildIndex(element));
				}
				else if(loader.parent) {
					element.parent.removeChild(loader);
				}
			}
		}
		
		function hasPicture(element):Boolean {
			var loader_name = element.name+"_loader";
			return getChildByName(loader_name)!=null;
		}
		
		function hasPeer() {
			var myindex = players?players.indexOf(me):-1;
			return players?players[1-myindex]:null;
		}
		
		private function startGame():void {
			//myturn = true;
			visible = true;
			stage.addEventListener(MouseEvent.MOUSE_MOVE,mouseMove);
			stage.addEventListener(MouseEvent.MOUSE_DOWN,mouseDown);
			stage.addEventListener(MouseEvent.MOUSE_UP,mouseUp);
			
		}
		
		function connect() {
			startGame();

			return;
			net = new NetConnection();
			net.addEventListener(SecurityErrorEvent.SECURITY_ERROR, 
				function(e) {
					trace(e);
				});
			net.addEventListener(NetStatusEvent.NET_STATUS,
				function(e:NetStatusEvent) {
					
					if(!players) {
						sendbox.text = me = e.currentTarget.nearID;
						players = [ me ];
						pindex = 0;
						stick.innerstick.image0.visible = myturn;
						stick.innerstick.image1.visible = !myturn;
						if(ExternalInterface.available) {
							ExternalInterface.call("notify",me);
						}
					}

						var p:Array = [];
						for(i in e.info) {
							p.push([i,e.info[i]]);
						}
						trace(p.join(" "));

					if(e.info.code == "NetStream.Connect.Closed") {
						//throw new Error();
						//trace("WTFHERE?");
						for(var i=0;i<players.length;i++) {
							if(players[i]==e.info.stream.farID) {
								master = true;
								players[i] = null;
								updateWinDialog();
							}
							if(instream == e.info.stream) {
								receivebox.text = "Here enter serial key of another player you wish to join";
								receivebox.type = TextFieldType.INPUT;
								receivebox.background = true;
								receivebox.textColor = 0;
								instream = null;								
							}														
						}//trace(e.info.stream.farID);
						//ready = [false,false];
					}
					
					if(!outstream) {
						master = true;
						outstream = new NetStream(net,NetStream.DIRECT_CONNECTIONS);
						outstream.client = {
							onPeerConnect:function(subscriber:NetStream):Boolean {
								var id = subscriber.farID;
								if(players.indexOf(id)<0) {
									if(players.length==1) {
										players.push(id);
									}
									else {
										for(var i=0;i<players.length;i++) {
											if(!players[i]) {
												players[i]=id;
											}
										}
									}
									connectInstream(id);
								}
								var doack = !MovieClip(parent).restarting;
								if(MovieClip(parent).restarting) {
									gamesetting.playmulti = 1;
									savePeer(id);
									visible = false;
									MovieClip(parent).restarting = false;
									setTimeout(
										function() {				
											if(outstream)
												outstream.close();
											if(instream)
												instream.close();
											net.close();
											//MovieClip(parent).davinci_loader.reload(gamesetting);
											gamesetting.peer = null;
											gamesetting.visitor = null;
											MovieClip(parent).params = gamesetting;
											MovieClip(parent).gotoAndPlay(1);
										},1000);
								}
								else {
									setTimeout(
									   function() {
											if(doack)
												outstream.send("acknowledge");
										   //trace(player1.text,gamestopped,paused,players.length,pindex,players[pindex]==me);
										   //trace(MovieClip(root).loaderInfo.url.split("/").pop(),master,myturn);
											infospace.text = myturn?"Your turn":"Not your turn";
											if(master) {
												sendDeserialize();
											}
											outstream.send("setProfile",
												me,
												nameChanged?player1.text:null,
												hasPicture(pic1)?pic1.text:null,
												stick.innerstick.image0.link?stick.innerstick.image0.link:null);
									   },1000);								
								}
								return true;
							}};
						if(gamesetting.peer) {
							outstream.addEventListener(NetStatusEvent.NET_STATUS,
								function(e) {
									e.currentTarget.removeEventListener(e.type,arguments.callee);
									slaveConnect(gamesetting.peer);
								});
						}
						else {
							var so:SharedObject = SharedObject.getLocal("pool");
							if(so.data.peer) {
								outstream.addEventListener(NetStatusEvent.NET_STATUS,
									function(e) {
										e.currentTarget.removeEventListener(e.type,arguments.callee);
										slaveConnect(so.data.peer);
									});
							}
							else {
								visible = true;
							}
						}

						outstream.publish(ROOM);
						stage.addEventListener(MouseEvent.MOUSE_MOVE,mouseMove);
						stage.addEventListener(MouseEvent.MOUSE_DOWN,mouseDown);
						stage.addEventListener(MouseEvent.MOUSE_UP,mouseUp);
						player1.addEventListener(Event.CHANGE,
							function(e) {
								nameChanged = true;
								outstream.send("setProfile",me,player1.text,null);
							});
					}
				});
			net.connect("rtmfp://p2p.rtmfp.net",SERIAL);
			
			receivebox.addEventListener(KeyboardEvent.KEY_DOWN,
				function(e) {
					if(e.keyCode==Keyboard.ENTER) {
						slaveConnect(receivebox.text);
					}
				});
			
			//pingtimer.addEventListener(TimerEvent.TIMER,ping);
			
			//pingtimer.start();
			
		}
		
		var pingtimer:Timer = new Timer(1000);
		
		function ping(e) {
			var peer = hasPeer();
			if(peer) {
				master = true;
				for(var i=0;i<players.length;i++) {
					if(players[i]==e.info.stream.farID) {
						players[i] = null;								
					}
				}
			}
		}
		
		var _pindex;
		function get pindex():int {
			return _pindex;
		}
		
		function set pindex(value:int) {
			_pindex = value;
			/*try {
				throw new Error([player1.text,value]);
			}
			catch(e) {
				trace(e.getStackTrace());
			}*/
		}
		
		function savePeer(id:String) {
			var so:SharedObject = SharedObject.getLocal("pool");
			if(id)
				so.data.peer = id;
			else
				delete so.data.peer;
		}
		
		function sendDeserialize() {
			if(notmoving(binfos) && !mdist) {
				outstream.send("deserialize",serialize());
				stick.innerstick.image0.visible = myturn;
				stick.innerstick.image1.visible = !myturn;
				timestart = 0;
			}
			else {
				setTimeout(sendDeserialize,1000);
			}
		}
		
		function slaveConnect(id) {
			ack = false;
			gamestopped = true;
			loadingMode();
			if(stick.parent)
				stick.parent.removeChild(stick);
			master = false;
			if(connectInstream(id)) {
				setTimeout(disconnectIfNotAcknowledge,8000);
			}
		}
		
		function loadingMode() {
			visible = false;
		}
		
		public function acknowledge() {//;//willDeserialize:Boolean) {
			ack = true;
			//if(!willDeserialize) {
				if(!visible)
					visible = true;
				if(gamestopped)
					gamestopped = false;
			//}
			
/*			if(newgame) {
				if(waiter.parent)
					waiter.parent.removeChild(waiter);
				master = true;
				gamestopped = false;
				
				receivebox.text = "";
				receivebox.type = TextFieldType.INPUT;
				receivebox.background = true;
				receivebox.textColor = 0;
				
				visible = true;
				
				savePeer(null);
			}*/
		}
		
		function disconnectIfNotAcknowledge() {
			if(!ack) {
				master = true;
				gamestopped = false;
				
				receivebox.text = "Here enter serial key of another player you wish to join";
				receivebox.type = TextFieldType.INPUT;
				receivebox.background = true;
				receivebox.textColor = 0;
				
				visible = true;
				instream.close();
				instream = null;
				
				savePeer(null);
			}
		}
		
		public function setProfile(id:String,playername:String,pic=null,stickpic=null) {
			if(playername)
				player2.text = playername;
			if(pic) {
				setPicture(pic2,pic);
			}
			if(stickpic) {
				setStickImage(stickpic,1);
			}
		}

		function connectInstream(id) {
			if(!instream || instream.farID!=id) {
				receivebox.text = id;
				receivebox.type = TextFieldType.DYNAMIC;
				receivebox.background = false;
				receivebox.textColor = 0xFFFFFF;
				instream = new NetStream(net,id);
				instream.client = self;
				instream.play(ROOM);
				savePeer(id);
				return true;
			}
			return false;
		}
		
		function get myturn():Boolean {
			return !paused;// && players && players[pindex]==me;
		}
		
		function movePoint(x:Number,y:Number) {
			_mpoint.x = x;
			_mpoint.y = y;
		}
		
		function get mpoint():Point {
			if(myturn) {
				movePoint(mouseX,mouseY);
			}
			return _mpoint;
		}
		
		function replace(ball) {
			var b = {pos:ballorigin};
			var pshift:Point = new Point();
			var angle:Number = 2*Math.PI;
			var count:int = 0;
			var found:Boolean = false;
			while(!found) {
				found = true;
				for(var i=0;i<balls.length;i++) {
					if(!binfos[i].sunk) {
						var touch = processPair(b,binfos[i],true);
						if(touch) {
							found = false;
							break;
						}
					}
				}
				if(!found) {
					angle += Math.PI/3;
					if(angle>=2*Math.PI) {
						count++;
						angle = 0;
					}
					pshift = new Point(Math.cos(angle),Math.sin(angle));
					pshift.normalize(count*RAYON);
					b.pos = new Point(ballorigin.x+pshift.x,ballorigin.y+pshift.y);
				}
			}
			//trace(ball,b.pos);
			ball.info.sunk = null;
			ballarea.addChild(ball);
			ball.info.pos = b.pos;
			ball.info.mov = new Point();
		}
		
		function paintBall(ball) {
			if(ball.bmp) {
				ball.visible = true;
				ball.mball.graphics.clear();
				var m:Matrix = ball.info.m.clone();
				if(ball!=aimer)
					m.scale(.5,.5);
				ball.mball.graphics.beginBitmapFill(ball.bmp,m,true,ball!=aimer);
				ball.mball.graphics.drawCircle(0,0,RAYON);
				ball.mball.graphics.endFill();
			}
			else {
				ball.visible = false;
			}
		}

		function produceBalls() {
			for(var i=0;i<=15;i++) {
				var child = ballarea.getChildByName("ball"+i);
				if(child) {
					child.index = i;
					child.info = {pos:new Point(child.x,child.y),mov:new Point(),rmov:0,m:child.transform.matrix};
					child.info.m.tx = 23 + Math.random()*16-8;
					child.info.m.ty = 23 + Math.random()*16-8;
					if(gamesetting.skin && gamesetting.skin.length) {
						loadBallBMP(child,i,null);
						loadBallBMP(child,i,gamesetting.skin);
					}
					else
						loadBallBMP(child,i,null);
					balls.push(child);
					binfos.push(child.info);
				}
			}
		}
		
		function loadBallBMP(clip,index,skin:String=null) {
			if(skin) {
				trace(skin);
				var request:URLRequest = new URLRequest(skin+index+".jpg");
				var loader:Loader = new Loader();
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE,
					function(e) {
						if(clip.bmp) {
							clip.bmp.dispose();
							clip.bmp = null;
						}
						clip.bmp = e.currentTarget.content.bitmapData;
						paintBall(clip);
					});
				loader.load(request);
			}
			else {
				if(clip.bmp) {
					clip.bmp.dispose();
					clip.bmp = null;
				}
				poolskin.gotoAndStop(index==0?16:index);
				poolskin.tf.text = clip==aimer?"":index?index:".";
				var scale:Number = clip==aimer?1:2;
				clip.bmp = new BitmapData(poolskin.width*scale,poolskin.height*scale,false);
				if(clip.bmp.hasOwnProperty("drawWithQuality")) 
					(clip.bmp as BitmapData)["drawWithQuality"](poolskin,new Matrix(scale,0,0,scale,0,0),null,null,null,true,StageQuality.BEST);
				else
					(clip.bmp as BitmapData).draw(poolskin,new Matrix(scale,0,0,scale,0,0),null,null,null,true);
				if(clip==aimer) {
					var shape:Shape = new Shape();
//					shape.graphics.beginFill(0);
//					shape.graphics.drawCircle(poolskin.width/2+.5,poolskin.height/2-2,.7);
//					shape.graphics.endFill();
					shape.graphics.lineStyle(.5,0);
					shape.graphics.moveTo(poolskin.width/2+.5-2,poolskin.height/2-2.5);
					shape.graphics.lineTo(poolskin.width/2+.5+2,poolskin.height/2-2.5);
					shape.graphics.moveTo(poolskin.width/2+.5,poolskin.height/2-2.5-2);
					shape.graphics.lineTo(poolskin.width/2+.5,poolskin.height/2-2.5+2);
					(clip.bmp as BitmapData).draw(shape);
				}
				paintBall(clip);
			}
		}
		
		function sinkBall(ball,point:Point=null) {
			if(ball.parent == ballarea)
				ballarea.removeChild(ball);
			if(point) {
				animateSink(ball,point,ball!=qball);
			}
			else {
				if(ball!=qball) {
					stocksunk(ball);
				}
			}
		}
		
		var overlayBallRecycle:Array = [];
		function animateSink(ball,point:Point,stock:Boolean):void {
			var copy:Ball = overlayBallRecycle.length?overlayBallRecycle.pop():new Ball();
			copy.alpha = 1;
			copy.x = ball.x;
			copy.y = ball.y;
			copy.filters = [new GlowFilter(0,1,0,0,2,1,true)].concat(ballarea.filters);
			copy.info = ball.info;
			loadBallBMP(copy,balls.indexOf(ball));
			overlay.addChild(copy);
			point = point.clone();
			var reversePath:Array = [point.clone()];
			var ballPos:Point = new Point(copy.x,copy.y);
			while(Point.distance(point,ballPos)>5) {
				reversePath.push(point.clone());
				point.x += (copy.x - point.x)/3;
				point.y += (copy.y - point.y)/3;
			}
			var blurLevel:Number = 1;
			var sinking:Boolean = false;
			addEventListener(Event.ENTER_FRAME,
				function(e:Event):void {
					if(reversePath.length) {
						var p:Point = reversePath.pop();
						copy.info.m.tx += (p.x-copy.x);
						copy.info.m.ty += (p.y-copy.y);
						paintBall(copy);
						copy.x = p.x;
						copy.y = p.y;
					}
					else if(blurLevel<50) {
						blurLevel*=1.4;
						var filters:Array = copy.filters;
						(filters[0] as GlowFilter).blurX = (filters[0] as GlowFilter).blurY = blurLevel;
						copy.filters = filters;
						copy.alpha = (50-blurLevel)/50;
					}
					else {
						if(!sinking) {
							sinking = true;
							holeSound.play(0,1,new SoundTransform(1,(point.x-stage.stageWidth/2)/stage.stageWidth));
						}
						overlay.removeChild(copy);
						overlayBallRecycle.push(copy);
						e.currentTarget.removeEventListener(e.type,arguments.callee);
						if(stock) {
							stocksunk(ball);
						}
					}
				});
		}
		private var overlay:Sprite;
		
		function loop(e) {
			if(!paused && !gamestopped) {
				var st = getTimer();
				
				for(var i=0;i<balls.length;i++) {
					var ball = balls[i];
					if(ball.info.sunk) {
						if(ball.parent==ballarea) {
							sinkBall(ball,ball.info.sunk as Point);
							if(ballstatus)
								ballstatus[ball.index] = true;							
						}
					}
					else if(ball.info.mov) {
						paintBall(ball);
						
/*						if(ball.info.spin) {
							ball.graphics.clear();
							ball.graphics.lineStyle(1,0xFFFFFF);
							ball.graphics.moveTo(0,0);
							ball.graphics.lineTo(ball.info.spin.x*10,ball.info.spin.y*10);
						}*/
						
						if(!ball.info.placing) {
							ball.x = binfos[i].pos.x;
							ball.y = binfos[i].pos.y;
						}
					}
				}
				didSound = 0, didSoundWall = 0;
				panSound = 0, panSoundWall = 0;
				processTime(st);
				if(didSound) {
					var power:Number = didSound;//overlap*100;
					ballSound.play(0,1,new SoundTransform(power/200+.4,panSound/20));
				}
				if(didSoundWall) {
					power = didSoundWall;//overlap*100;
					wallSound.play(0,1,new SoundTransform(power/200+.4,panSoundWall/20));
				}
				if(notmoving(binfos)) {
					if(qball.info.sunk) {
						evaluateBallStatus();												
						qball.info.sunk = null;
						ballarea.addChild(qball);
						qball.info.placing = true;
						if(stick.parent)
							stick.parent.removeChild(stick);
					}
					if(qball.info.placing && myturn && !papa.buttonMode) {
						papa.buttonMode = true;
						stage.addEventListener(MouseEvent.CLICK,
							function(e) {
								var rect:Rectangle = carpet.getRect(self);
								rect.top += RAYON;
								rect.left += RAYON;
								rect.bottom -= RAYON;
								rect.right -= RAYON;
								if(rect.contains(qball.x,qball.y)) {
									papa.buttonMode = false;
									placeBall(qball.x,qball.y);
									if(outstream)
										outstream.send("placeBall",qball.x,qball.y);
									e.currentTarget.removeEventListener(e.type,arguments.callee);
								}
							});
					}
	//				if(lastsunk) {
						//replace(lastsunk);
						//lastsunk = false;
					//}
					if(processStick()) {
						if(playSolo()) {
							timestart = 0;
							notice.visible = timerbox.visible = removebutton.visible = skipbutton.visible = false;
							maybeShowChallengeBox();
						}
						else {
							timerbox.visible = true;
							if(!timestart) {
								timestart = st;
								timerbox.autoSize = "center";
							}
							timerbox.text = timeleft?timeleft.toString():"Time's up";
							skipbutton.visible = !timeleft && !myturn && players.length>1;
							removebutton.visible = skipbutton.visible && skippedonce;
							notice.visible = !timeleft && myturn && players.length>1;
							challengebox2.visible = challengebox.visible = false;
							cover.visible = false;
			
						}
						//trace(playSolo(), myturn, hasPeer());
					}
					else {
						maybeShowChallengeBox();
					}
				}
				else {
					timestart = 0;
					notice.visible = timerbox.visible = removebutton.visible = skipbutton.visible = false;
					maybeShowChallengeBox();
				}
			}
			else {
				for(i=0;i<balls.length;i++) {
					paintBall(balls[i]);
				}
				notice.visible = timerbox.visible = removebutton.visible = skipbutton.visible = false;
				maybeShowChallengeBox();
			}
		}
		
		function maybeShowChallengeBox() {
			challengebox.visible = playSolo() && (myturn||paused&&!gamesetting.visitor) && hasPeer();
			challengebox2.visible = playSolo() && gamesetting.visitor && hasPeer();
			cover.visible = playSolo() && !challengebox.visible && !challengebox2.visible;
			if(challengebox.visible) {
				challengebox.tf.text = player2.text	+ " would like to challenge you. Will you accept?";
			}
			if(challengebox2.visible) {
				challengebox2.tf.text = "Waiting for " + player2.text	+ " to accept the challenge";
			}
		}
		
		function get timeleft():int {
			return Math.floor(Math.max(0,MAXPLAYTIME - (getTimer()-timestart)/1000));
		}
		
		public function placeBall(xpos:Number,ypos:Number) {
			qball.info.placing = false;
			qball.info.pos.x = xpos;
			qball.info.pos.y = ypos;
			qball.info.mov = null;
		}


		function getConsts() {
			BALLFRICTION = Math.pow(SLOWDOWN,parseFloat(ballfriction.text));
			WALLFRICTION = Math.pow(SLOWDOWN,parseFloat(wallfriction.text));
			SPINEFFECT = parseInt(spineffect.text);
			STEP = parseFloat(stepbox.text);
			SLOWDOWN = Math.pow(parseFloat(slowdownbox.text),STEP);
			INCREMENT = parseFloat(incrementbox.text);
			MAXSPEED = parseFloat(maxspeedbox.text);
		}
		
		
		function oneProcessing(barray:Array) {
			var i,j;
			for(i=0;i<balls.length;i++) {
				processBall(barray[i]);
				barray[i].bouncing = false;
			}
			
			for(i=0;i<balls.length;i++) {
				var binfo1 = barray[i];
				if(!binfo1.sunk) {
					for(j=i+1;j<balls.length;j++) {
						var binfo2 = barray[j];
						if(!binfo2.sunk)
							if(binfo1.mov || binfo2.mov) {
								var collision = processPair(binfo1,binfo2);
								if(collision && !firsthit) {
									if(i==0) {
										firsthit = j;
									}
								}
							}
					}
				}
			}
			for(i=0;i<balls.length;i++) {
				processWall(barray[i],false);
			}
			barray.forEach(processHole);
		}
		
		function copy(barray:Array):Array {
			var newarray:Array = new Array(barray.length);
			for(var i=0;i<barray.length;i++) {
				newarray[i] = ({pos:barray[i].pos,mov:barray[i].mov,rmov:barray[i].rmov,m:barray[i].m,sunk:barray[i].sunk,placing:barray[i].placing,bouncing:barray[i].bouncing,spin:barray[i].spin});
			}
			return newarray;
		}
		
		function serialize():ByteArray {
			var bytes:ByteArray = new ByteArray();
			for(var i=0;i<balls.length;i++) {
				var binfo = binfos[i];
				bytes.writeDouble(binfo.sunk?0:binfo.pos.x);
				bytes.writeDouble(binfo.sunk?0:binfo.pos.y);
				bytes.writeDouble(!binfo.mov?0:binfo.mov.x);
				bytes.writeDouble(!binfo.mov?0:binfo.mov.y);
				bytes.writeDouble(binfo.rmov);
				bytes.writeBoolean(binfo.placing);
				bytes.writeBoolean(binfo.bouncing);
				bytes.writeShort(sunks.indexOf(balls[i]));
			}
			
			bytes.writeUTF(players.join(","));
			bytes.writeUTF(ranges.join(","));
			bytes.writeBoolean(ready[0]);
			bytes.writeBoolean(ready[1]);
			bytes.writeShort(pindex);
			bytes.writeUTF(gamesetting.skin?gamesetting.skin:"");
			bytes.writeUTF(gamesetting.picbg?gamesetting.picbg:"");
			bytes.writeBoolean(gamesetting.playmulti);
			bytes.writeUTF(session);
			return bytes;
		}

		public function deserialize(bytes:ByteArray) {
			if(notmoving(binfos) && !mdist) {
				gamestopped = true;
				if(stick.parent)
					stick.parent.removeChild(stick);
				var ssk:Array = [];
				for(var i=0;i<balls.length;i++) {
					var binfo = binfos[i];
					var bx = bytes.readDouble();
					var by = bytes.readDouble();
					if(bx || by) {
						binfo.sunk = null;
						binfo.pos = new Point(bx,by);
					}
					else {
						binfo.sunk = true;
					}
					timestart = 0;
					binfo.mov = new Point(bytes.readDouble(),bytes.readDouble());
					binfo.rmov = bytes.readDouble();
					binfo.placing = bytes.readBoolean();
					binfo.bouncing = bytes.readBoolean();
					var sunkindex = bytes.readShort();
					if(sunkindex>=0)
						ssk[sunkindex] = balls[i];
				}
				for(i=0;i<ssk.length;i++) {
					sinkBall(ssk[i]);
				}
				
				players = bytes.readUTF().split(",");
				ranges  = bytes.readUTF().split(",");
				ready = [bytes.readBoolean(),bytes.readBoolean()];
				pindex = bytes.readShort();
				infospace.text = myturn?"Your turn":"Not your turn";
				stick.innerstick.image0.visible = myturn;
				stick.innerstick.image1.visible = !myturn;
				gamesetting.skin = bytes.readUTF();
				for(i=0;i<balls.length;i++) {
					if(gamesetting.skin.length) {
						loadBallBMP(balls[i],i,null);
						loadBallBMP(balls[i],i,gamesetting.skin);
					}
					else
						loadBallBMP(balls[i],i,null);
				}
				gamesetting.picbg = bytes.readUTF();
				setPicture(picbg,gamesetting.picbg);
				gamesetting.playmulti = bytes.readBoolean();
				session = bytes.readUTF();
				gamestopped = false;
				visible = true;
					
				if(playSolo()) {
					gamesetting.visitor = true;
				}
				//trace(gamesetting.playsolo);
			}
			else {
				setTimeout(function() {deserialize(bytes);},1000);
			}
		}
		
		private var didSound:Number, didSoundWall:Number, panSound:Number, panSoundWall:Number;
		function processTime(time) {
			getConsts();
			
			var timepass:int = 0;
			while(lasttime<time || !timepass) {
				timepass ++;
				lasttime += INCREMENT;
			}
		
			while(getTimer()-time<25 && bhistory.length<100) {
				var blast:Array = bhistory.length?bhistory[bhistory.length-1]:binfos;
				if(notmoving(blast)) {
					break;
				}
				bhistory.push(copy(blast));
				oneProcessing(bhistory[bhistory.length-1]);
			}
				
			if(!block) {
				binfos = bhistory.length>=timepass?bhistory[timepass-1]:bhistory.length?bhistory[bhistory.length-1]:binfos;
				for(i=0;i<timepass;i++) {
					for each(var binfo:Object in bhistory[i]) {
						if(binfo.mov) {
							if(binfo.bouncing=="ball") {
								didSound+=binfo.mov.length;
								panSound=((binfo.pos.x-stage.stageWidth/2)/stage.stageWidth-panSound)/2;
							}
							else if(binfo.bouncing=="wall") {
								didSoundWall+= binfo.mov.length;
								panSoundWall=((binfo.pos.x-stage.stageWidth/2)/stage.stageWidth-panSoundWall)/2;
							}
						}
					}
				}
				bhistory.splice(0,timepass);
				for(var i=0;i<balls.length;i++) {
					balls[i].info = binfos[i];
				}
			}
		}

		function ontable(point:Point) {
			return carpet.getRect(this).containsPoint(point);
		}
		
		public function notifyMouse(action:String,x:Number,y:Number,rot:Number=0) {
			movePoint(x,y);
			switch(action) {
				case "mov":
					mouseMove(null);
					break;
				case "down":
					mouseDown(null);
					break;
				case "up":
					stick.rotation = rot;
					mouseUp(null);
					break;
			}
		}

		function mouseMove(e:MouseEvent){
			if(e && !myturn || paused) {
				return;
			}
			if(touchScreen() && !e.buttonDown) {
				return;
			}
			var mp:Point = mpoint;
			if(stick.parent) {
				rotgoal = qball.rotation + (Math.atan2(mp.y-qball.y,mp.x-qball.x)*180/Math.PI);
				//processStick();
				if(e) {
					e.updateAfterEvent();
				}
			}
			if(qball.info.placing) {
				qball.x = mp.x;
				qball.y = mp.y;
			}
			if(e && myturn && outstream) {
				outstream.send("notifyMouse","mov",mp.x,mp.y);
			}
		}
		
		private var buttonDown:Boolean = false;

		function mouseDown(e:MouseEvent) {
			if(e && !myturn) {
				return;
			}
			buttonDown = e.buttonDown;
			var mp:Point = mpoint;
//			if(ontable(mp)) {
				mdist = Point.distance(mp,qball.info.pos);
				if(myturn && outstream) {
					outstream.send("notifyMouse","down",mp.x,mp.y);
				}
//			}
		}

		function mouseUp(e) {
			if(e && !myturn) {
				return;
			}
			if(touchScreen()) {
				return;
			}
			shootBall();
		}
		
		function shootBall():void {
			if(mdist) {
				processStick();
				shoot();
				if(myturn && outstream) {
					var mp:Point = mpoint;
					outstream.send("notifyMouse","up",mp.x,mp.y,stick.rotation);
				}
			}
			
		}

		var waitingforstill = false;

		function shoot() {
			checkLowestBall(false);
			if(stick.innerstick.x) {
				var power:Number = stick.innerstick.x;
				//trace(power);
				var spinlateral = (qballspot.x-aimer.info.m.tx)*-power/50;
				var spindirect = (qballspot.y-aimer.info.m.ty)*-power/50;
				
				var balldirect = new Point(
					Math.cos(stick.rotation*Math.PI/180),
					Math.sin(stick.rotation*Math.PI/180));
				var balllateral = new Point(
					Math.sin(stick.rotation*Math.PI/180),
					-Math.cos(stick.rotation*Math.PI/180));
				
				qball.info.spin = new Point(spinlateral*balllateral.x+spindirect*balldirect.x,spinlateral*balllateral.y+spindirect*balldirect.y);
				ready = [false, false];
				firsthit = 0;
				shooting = true;
				var reverseshoot:Array = [];
				var pullbackx = stick.innerstick.x*1.5;
				var ix = 0;
				while(ix-pullbackx>5) {
					reverseshoot.push(ix);
					ix += (pullbackx-ix)/3;
				}
				
				var backshoot:Array = [];
				ix = stick.innerstick.x;
				while(ix-pullbackx>5) {
					ix += (pullbackx-ix)/3;
					backshoot.push(ix);
				}
				backshoot.reverse();
				reverseshoot = reverseshoot.concat(backshoot);
				
		//		trace(reverseshoot);
				block = true;
				pushBall(power);
				addEventListener(Event.ENTER_FRAME,
					function(e) {
						if(!reverseshoot.length) {
							e.currentTarget.removeEventListener(e.type,arguments.callee);
							if(stick.parent)
								removeChild(stick);
							shooting = false;
							block = false;
							infospace.text = "";
							//	hit
//							trace("hit",power,stick.x);
							stickSound.play(0,1,new SoundTransform(-power/80+.5,(stage.stageWidth/2-stick.x)/stage.stageWidth));
						}
						else {
							stick.innerstick.x = reverseshoot.pop();
						}
					});
				
				//var maxpoint = stick.inn
			}
			mdist = 0;
		}
		
		function pushBall(power:Number) {
			ballstatus = [];
			var barray:Array = copy(binfos);
			var DIVCONST = 5;
			barray[0].mov = new Point(-Math.cos(stick.rotation*Math.PI/180)*power/DIVCONST,-Math.sin(stick.rotation*Math.PI/180)*power/DIVCONST);
			bhistory = [barray];
		}
		
		function notmoving(barray:Array) {
			for(var i=0;i<barray.length;i++) {
				var binfo = barray[i];
				if(binfo.mov && binfo.mov.length>.01 || binfo.bouncing) {
					return false;
				}
			}
			return true;
		}

		function evaluateBallStatus() {
			if(ballstatus) {
				
				//gameOver(true);
				//return;
				
				var skip:Boolean = false;
				var scratch:Boolean = false;
				var playerissolid:Boolean = playSolo() || ranges[pindex]=="solid";
				var playerisstripe:Boolean = playSolo() || ranges[pindex]=="stripes";
				var qballsunk:Boolean = ballstatus[0];
				var eightballsunk:Boolean = ballstatus[8];
				var hasrange:Boolean = ranges[0]!="";
				var firsthitsolid:Boolean = firsthit<8;
				var firsthitstripes:Boolean = firsthit>8;
				var solidsunk:Boolean = false;				
				var stripesunk:Boolean = false;
				var allsolidsunk:Boolean = true;
				var allstripesunk:Boolean = true;
				var sunkCount:int = 0;
				var sunkBefore:int = 0;
				var inOrder:Boolean = true;
				for(var i=1;i<=15;i++) {
					//trace(JSON.stringify(binfos[i]));
					if(ballstatus[i]) {
						if(i<8)
							solidsunk = true;
						if(i>8)
							stripesunk = true;
						sunkCount++;
						if(sunkBefore<i-1) {
							inOrder = false;
						}
					}
					if(!binfos[i].sunk) {
						if(i<8)
							allsolidsunk = false;
						if(i>8)
							allstripesunk = false;
					}
					else {
						sunkBefore++;
					}
				}
				var almostwin:Boolean = playerisstripe && allstripesunk || playerissolid && allsolidsunk;
				
				if(qballsunk)
					scratch = true;
					
				if(playerisstripe && !stripesunk || playerissolid && !solidsunk) {
					skip = true;
				}
				
				if(!stripesunk && !solidsunk) {
					skip = true;
				}
				
				if(hasrange) {
					if(playerissolid && !firsthitsolid || playerisstripe && !firsthitstripes) {
						scratch = true;
					}
				}
				
				if(firsthit==8 && !almostwin) {
					scratch = true;
				}
				
				if(eightballsunk) {
					var lose:Boolean = false;
					if(!hasrange) {
						lose = true;
					}
					else if(qballsunk) {
						lose = true;
					}
					else if(!almostwin) {
						lose = true;
					}
					//trace(myturn);
					gameOver(lose?!myturn:myturn);
				}				
				else if(skip || scratch) {
					nextPlayer();
					if(scratch) {
						qball.info.sunk = true;
					}
				}
				else if(!(solidsunk && stripesunk)) {
					if(!hasrange) {
						ranges[pindex] = solidsunk?"solid":"stripes";
						ranges[ranges.length-1-pindex] =solidsunk?"stripes":"solid";
						var myindex = players.indexOf(me);				
						//trace(myindex);
						range1.text = ranges[myindex];
						range2.text = ranges[ranges.length-1-myindex];
					}
				}
				ballstatus = null;
				trace("8-sunk:",eightballsunk,"q-sunk:",qballsunk,"scratch:",scratch,"lose:",lose,"\n","skip:",skip,"stripesunk:",stripesunk,"solidsunk:",solidsunk,"sunk:",sunkCount,"inOrder:",inOrder);
				bonus = 0;
				if(eightballsunk && lose) {
					bonus = -10;
					combo = 1;
				}
				else if(qballsunk) {
					bonus = -5;
					combo = 1;
				}
				else if(sunkCount) {
					bonus = (sunkCount+(inOrder?4:0))*combo;
					combo += sunkCount*2;
					if(sunkCount>1) {
						combo += 3;
					}
					
				}
				else {
					combo = 1;
				}
				totalShots++;
				score = Math.max(0,score+bonus);
				updateScoreAndCombo();
			}
		}
		
		function nextPlayer() {
			if(!playSolo())
				pindex = (pindex+1)%players.length;
			//trace(players);
			//trace(loaderInfo.url,myturn);
		}
		
		public function getReady(index) {
			ready[index] = true;
		}
		
		private function touchScreen():Boolean {
			return Capabilities.touchscreenType && Capabilities.touchscreenType!=TouchscreenType.NONE;
		}
		
		private function checkLowestBall(glow:Boolean):void {
			//glower
			var lowest:int = 0;
			for(var i:int=1;i<=15;i++) {
				if(!lowest && i!=8) {
					if(!binfos[i].sunk) {
						lowest = i;
					}
				}
				if(i==lowest && glow) {
					balls[i].filters = MovieClip(root).glower.filters;
				}
				else {
					balls[i].filters = [];
				}
			}
		}

		function processStick():Boolean {
			if(!shooting && notmoving(binfos) && !qball.info.placing) {

				if(!playSolo()) {
					var myindex = players.indexOf(me);
					if(!ready[myindex]) {
						getReady(myindex);
						outstream.send("getReady",myindex);
					}
					if(!ready[0] && ready[1]) {
						return false;
					}				
				}
				
				stick.pos = qball.info.pos;
				stick.x = stick.pos.x;
				stick.y = stick.pos.y;
				
				if(!stick.parent) {
					evaluateBallStatus();
					if(!gamestopped) {
						infospace.text = myturn?"Your turn":"Not your turn";
						addChild(stick);
						stick.visible = true;
						aim(0,0);
						stick.innerstick.image0.visible = myturn;
						stick.innerstick.image1.visible = !myturn;
						fade(stick,true,500);
						checkLowestBall(true);
					}
				}
				if(!mdist || touchScreen()) {
					var rotdiff = rotgoal-stick.rotation;
					if(rotdiff>180) {
						rotdiff -= 360;
					}
					else if(rotdiff<-180) {
						rotdiff += 360;
					}
					stick.rotation += rotdiff/2;
					stick.innerstick.x = 0;
					stick.overlay.visible = myturn && !paused;
					if(stick.overlay.visible) {
						stick.overlay.alpha = 1;
						calcBallLine();
					}
				}
				if(mdist) {
					var spoint = globalToLocal(stick.innerstick.localToGlobal(new Point()));
					var mp:Point = mpoint;
					var dist = Point.distance(mp,qball.info.pos);
					stick.innerstick.x = Point.distance(spoint,mp)>Point.distance(spoint,qball.info.pos)?Math.min(0,dist-mdist):-(dist+mdist);
					if(stick.overlay.visible)
						stick.overlay.alpha = stick.innerstick.x?2:1;
				}
				return true;
			}
			return false;
		}
		
		function calcBallLine() {
			var p = { parent:1,pos:new Point(qball.info.pos.x,qball.info.pos.y) };
			var collide:Boolean = false;
			var bstep = 10;
			p.mov = new Point(Math.cos(stick.rotation*Math.PI/180)*bstep,Math.sin(stick.rotation*Math.PI/180)*bstep);
			var cc=0;
			var bcoll = null;
			while(cc++<1000 && !collide) {
				for(var i=0;i<balls.length;i++) {
					var binfo = binfos[i];
					if(binfo != qball.info && !binfo.sunk && processPair(p,binfo,true)) {
						if(p.mov.length>1) {
							p.pos.x -= p.mov.x;
							p.pos.y -= p.mov.y;
							p.mov.x /=2;
							p.mov.y /=2;
						}
						else {
							bcoll = binfo;
							collide = true;
							break;
						}
					}
					else if(processWall(p,true)) {
						if(p.mov.length>1) {
							p.pos.x -= p.mov.x;
							p.pos.y -= p.mov.y;
							p.mov.x /=2;
							p.mov.y /=2;
						}
						else {
							collide = true;
							break;
						}
					}
				}
				p.pos.x += p.mov.x;
				p.pos.y += p.mov.y;
			}
			
			var allsolidsunk:Boolean = true;
			var allstripesunk:Boolean = true;
			for(i=1;i<binfos.length;i++) {
				if(!binfos[i].sunk) {
					if(i<8)
						allsolidsunk = false;
					if(i>8)
						allstripesunk = false;
				}
			}			
			
			var myindex = 0;//players.indexOf(me);
			var bindex = binfos.indexOf(bcoll);
			var willscratch = bcoll && (
					ranges[0]!="" && (ranges[myindex]=="solid" && bindex>8 
									 || ranges[myindex]=="stripes" && bindex<8 )
					|| bindex==8 && 
						(ranges[0]=="" && !allsolidsunk && !allstripesunk
						 || ranges[myindex]=="solid" && !allsolidsunk
						 ||ranges[myindex]=="stripes" && !allstripesunk));
			
			stick.overlay.graphics.clear();
			stick.overlay.graphics.lineStyle(1,willscratch?0xFF4444:0xFFFFFF,.3);
			stick.overlay.graphics.moveTo(0,0);
			var pos = stick.globalToLocal(localToGlobal(p.pos));
			stick.overlay.graphics.lineTo(pos.x,pos.y);
			if(bcoll) {
				var bpos = stick.globalToLocal(localToGlobal(bcoll.pos));
				var bx = bpos.x-pos.x;
				var by = bpos.y-pos.y;
				stick.overlay.graphics.lineTo(pos.x + bx*2,pos.y + by*2);
				var angle = (Math.atan2(by,bx));
				var mside = angle<0?1:-1;
				stick.overlay.graphics.moveTo(pos.x,pos.y);
				stick.overlay.graphics.lineTo(pos.x - by*mside,pos.y + bx*mside);
			}
			stick.overlay.graphics.lineStyle();
			stick.overlay.graphics.beginFill(willscratch?0xFF4444:0xFFFFFF,.3);
			stick.overlay.graphics.drawCircle(pos.x,pos.y,RAYON);
		}
		
		function fade(clip:DisplayObject,fade_in:Boolean,time:int=1000,onFinish:Function=null) {
			var starttime = getTimer();
			if(fade_in) {
				clip.alpha = 0;
				clip.addEventListener(Event.ENTER_FRAME,
					function(e) {
						var clip = e.currentTarget;
						var now = getTimer();
						clip.alpha = time&&now-starttime<time?(now-starttime)/time:1;
						if(now-starttime>=time) {
							clip.removeEventListener(Event.ENTER_FRAME,arguments.callee);
							if(onFinish!=null) {
								onFinish();
							}
						}
					});
			}
			else {
				clip.alpha = 1;
				clip.addEventListener(Event.ENTER_FRAME,
					function(e) {
						var clip = e.currentTarget;
						var now = getTimer();
						clip.alpha = 1-(time&&now-starttime<time?(now-starttime)/time:1);
						if(now-starttime>=time) {
							clip.removeEventListener(Event.ENTER_FRAME,arguments.callee);
							if(onFinish!=null) {
								onFinish();
							}
						}
					});
			}
		}
		
		function processHole(binfo:*, index:int, array:Array):void {
			if(!binfo.sunk && !binfo.placing) {
				for each(var hole:Point in holes) {
					if(Point.distance(hole,binfo.pos)<HOLERAYON) {
						binfo.sunk = hole;
						binfo.mov = null;
						break;
					}
				}
			}
		}
		
		function processWall(binfo:*,detectOnly:Boolean=false):Boolean {
			if(binfo.mov) {
				var wallrect:Rectangle = carpet.getRect(this);
				if(binfo.pos.x < wallrect.left+RAYON) {
					if(detectOnly)
						return true;
					binfo.mov = binfo.mov.clone();
					binfo.mov.x += (wallrect.left+RAYON-binfo.pos.x);
					binfo.mov.x *= WALLFRICTION;
					binfo.mov.y *= WALLFRICTION;
					applySpin(binfo);
					binfo.bouncing = "wall";
				}
				else if(binfo.pos.x > wallrect.right-RAYON) {
					if(detectOnly)
						return true;
					binfo.mov = binfo.mov.clone();
					binfo.mov.x += (wallrect.right-RAYON-binfo.pos.x);
					binfo.mov.x *= WALLFRICTION;
					binfo.mov.y *= WALLFRICTION;
					applySpin(binfo);
					binfo.bouncing = "wall";
				}
				if(binfo.pos.y < wallrect.top+RAYON) {
					if(detectOnly)
						return true;
					binfo.mov = binfo.mov.clone();
					binfo.mov.y += (wallrect.top+RAYON-binfo.pos.y);
					binfo.mov.x *= WALLFRICTION;
					binfo.mov.y *= WALLFRICTION;
					applySpin(binfo);
					binfo.bouncing = "wall";
				}
				else if(binfo.pos.y > wallrect.bottom-RAYON) {
					if(detectOnly)
						return true;
					binfo.mov = binfo.mov.clone();
					binfo.mov.y += (wallrect.bottom-RAYON-binfo.pos.y);
					binfo.mov.x *= WALLFRICTION;
					binfo.mov.y *= WALLFRICTION;
					applySpin(binfo);
					binfo.bouncing = "wall";
				}
			}
			return false;
		}
		
				
		function processPair(binfo1,binfo2,detectOnly:Boolean=false):Boolean {
			var pos1:Point = binfo1.pos;
			var pos2:Point = binfo2.pos;
			var ddx = pos1.x-pos2.x;
			var ddy = pos1.y-pos2.y;
			var distsq:Number = ddx*ddx+ddy*ddy;//Point.distance(pos1,pos2);
			if(RAYON*2*RAYON*2>distsq) {
				if(detectOnly) {
					return true;
				}
				var dist:Number = Math.sqrt(distsq);
				var overlap:Number = RAYON*2-dist;
				binfo1.mov = binfo1.mov?binfo1.mov.clone():new Point();
				binfo2.mov = binfo2.mov?binfo2.mov.clone():new Point();
				binfo1.spin = binfo1.spin?binfo1.spin.clone():new Point();
				binfo2.spin = binfo2.spin?binfo2.spin.clone():new Point();
				var px:Number = (pos1.x-pos2.x)/dist;
				var py:Number = (pos1.y-pos2.y)/dist;
				binfo1.rmov = Math.atan2(py,px)/1000;
				binfo2.rmov = Math.atan2(-py,-px)/1000;
				binfo1.mov.x += px*overlap;
				binfo1.mov.y += py*overlap;
				binfo2.mov.x -= px*overlap;
				binfo2.mov.y -= py*overlap;
				binfo1.spin.x -= px*overlap/2;
				binfo1.spin.y -= py*overlap/2;
				binfo2.spin.x += px*overlap/2;
				binfo2.spin.y += py*overlap/2;
				binfo1.mov.x *= BALLFRICTION;
				binfo1.mov.y *= BALLFRICTION;
				binfo2.mov.x *= BALLFRICTION;
				binfo2.mov.y *= BALLFRICTION;
				
				applySpin(binfo1);
				applySpin(binfo2);
				
				binfo1.bouncing = binfo2.bouncing = "ball";
				

				return true;
			}
			return false;
		}
		
		function applySpin(binfo) {
			if(binfo.spin) {
				binfo.mov.x += binfo.spin.x/2;
				binfo.mov.y += binfo.spin.y/2;
				binfo.spin.x/=2;
				binfo.spin.y/=2;
			}
		}
		
		function processBall(binfo:*):void {
			if(binfo.mov && !binfo.sunk) {
				var speed = binfo.mov.length?binfo.mov.length:1;
				var norm:Point = binfo.mov.clone();
				if(norm.length>MAXSPEED)
					norm.normalize(MAXSPEED);
				binfo.pos = new Point(binfo.pos.x+norm.x*STEP,binfo.pos.y+norm.y*STEP);
				binfo.m = binfo.m.clone();
				if(binfo.rmov)
					binfo.m.rotate(binfo.rmov);
				binfo.m.translate(norm.x*STEP,norm.y*STEP);
				var speedmul = 1-(1-SLOWDOWN)/speed;
				binfo.mov = binfo.mov.clone();
				binfo.mov.x *= speedmul;
				binfo.mov.y *= speedmul;
				binfo.rmov *= SLOWDOWN;
				
				if(binfo.spin) {
					binfo.mov.x += binfo.spin.x/1000/speed*SPINEFFECT;
					binfo.mov.y += binfo.spin.y/1000/speed*SPINEFFECT;
					binfo.spin.x *= .999;
					binfo.spin.y *= .999;
					if(binfo.spin.length<.01) {
						binfo.spin = null;
					}
				}
				
				if(binfo.mov.length<.01 && !binfo.spin) {
					binfo.mov = null;
				}
			}
		}
		
		function setAim(e:MouseEvent) {
			if(e.buttonDown && myturn) {
				aim(aimer.mouseX,aimer.mouseY);
				if(outstream)
					outstream.send("aim",aimer.mouseX,aimer.mouseY);
				e.updateAfterEvent();
				e.stopImmediatePropagation();
			}
		}
		
		public function aim(x,y) {
			aimer.info.m.tx = x+qballspot.x ;
			aimer.info.m.ty =y+qballspot.y;
			stick.overlay.y = stick.innerstick.y =aimer.info.m.tx-qballspot.x;
			paintBall(aimer);			
		}

		function stocksunk(ball) {
			if(sunks.indexOf(ball)<0) {
				sunks.push(ball);
				ball.x = 700;
				ball.y = 0;
				ball.info.m.tx = 23 + Math.random()*16-8;
				ball.info.m.ty = 23 + Math.random()*16-8;
				var bgoal = l*RAYON*2;
				var bsteps = [];
				var bp = sunks.length*RAYON*2;
				while(ball.x-bp>100) {
					bsteps.push(bp);
					bp += Math.min((ball.x-bp)/30,10);
				}
				
				var l = sunks.length;
				ball.addEventListener(Event.ENTER_FRAME,
					function(e) {
						if(!rolling || rolling!=ball && rolling.x<700-RAYON*2) {
							rolling = ball;
							ballstock.addChild(ball);
						}
						if(rolling==ball) {
							ball.x = bsteps.pop();
							ball.info.m.rotate(-.5);
							paintBall(ball);
							if(!bsteps.length) {
								if(sunks.length==1)
									wallSound.play();
								else
									ballSound.play();
								e.currentTarget.removeEventListener(e.type,arguments.callee);
							}
						}
					});
			}
		}
	}
}