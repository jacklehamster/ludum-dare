﻿package {
	import com.dobuki.Cache;
	import com.dobuki.WallLoader;
	import com.dobuki.events.WallEvent;
	import flash.system.Security;
	import com.dobuki.Wall;
	import flash.utils.getQualifiedClassName;
	import flash.utils.Dictionary;
	import flash.media.Sound;
	import flash.media.SoundMixer;
	import flash.media.SoundTransform;
	import flash.media.SoundChannel;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	
	public class Maze extends MovieClip {
		
		private var song:Sound = new StellaSong();
		static private const NOUI:Boolean = true;
		
		static public const MAPPING:Object = {
			QWERTY: {
				"forward":Keyboard.W,
				"backward":Keyboard.S,
				"left":Keyboard.A,
				"right":Keyboard.D,
				"rotateleft":Keyboard.Q,
				"rotateright":Keyboard.E
			},
			AZERTY: {
				"forward":Keyboard.Z,
				"backward":Keyboard.S,
				"left":Keyboard.Q,
				"right":Keyboard.D,
				"rotateleft":Keyboard.A,
				"rotateright":Keyboard.E
			}
		};
		
		static public var keyMapping:Object = MAPPING.QWERTY;
		
		static public var instance:Maze = null;
		
		
		private var version:String = "1.00"+new Date().getTime();
		private var inited:Boolean;
		
		private var _hoveredGround:Block = null;
		
		private var colTransform:ColorTransform = new ColorTransform();
		private var channel:SoundChannel;
			if(!instance) {
				Security.allowDomain("youtube.com");
				Security.allowDomain("ytimg.com");
				Security.allowDomain("s.ytimg.com");
				Security.allowDomain("i4.ytimg.com");
			}
			instance = this;
			stage.addEventListener(Event.ACTIVATE,
				function(e:Event):void {
					fadeInSound();
				});
			stage.addEventListener(Event.DEACTIVATE,
				function(e:Event):void {
					fadeOutSound();
				});
			GlobalDispatcher.instance.addEventListener("fadeIn",fadeInSound);
			GlobalDispatcher.instance.addEventListener("fadeOut",fadeOutSound);
				
			GlobalDispatcher.instance.addEventListener(PositionEvent.TRACE,
				function(e:PositionEvent):void {
					var gid:String = ["#",e.data.x,e.data.y,0,"F"].join("|");
					if(!traces[gid]) {
						traces[gid] = true;
						traceCount++;
						if(traceCount>=1000) {
							Achievement.unlock(Achievement.WALKED1000);
						}
					}
				});
				
		}
		
		
		
		private function fadeOutSound(e:Event=null):void {
			if(!channel)
				return;
			var timer:Timer = new Timer(30,100);
			timer.addEventListener(TimerEvent.TIMER,
				function(e:TimerEvent):void {
					channel.soundTransform = new SoundTransform(1-timer.currentCount/timer.repeatCount);
				});
			timer.start();
		}
		
		private function fadeInSound(e:Event=null):void {
			if(!channel)
				return;
			var timer:Timer = new Timer(30,100);
			timer.addEventListener(TimerEvent.TIMER,
				function(e:TimerEvent):void {
					channel.soundTransform = new SoundTransform(timer.currentCount/timer.repeatCount);
				});
			timer.start();
		}
		
		public function get hoveredGround():Block {
			return _hoveredGround;
		}
		
		public function set hoveredGround(value:Block):void {
			if(_hoveredGround && _hoveredGround.content) {
				_hoveredGround.content.rollOut(new MouseEvent(MouseEvent.ROLL_OUT));
			}
			_hoveredGround = value;
			if(_hoveredGround && _hoveredGround.content) {
				_hoveredGround.content.rollOver(new MouseEvent(MouseEvent.ROLL_OVER));
			}
		}
		
		private function get self():Maze {
			return this;
		}
		private function init(params,data=null,bgpass=null) {
				return;
			}
			inited = true;
			Achievement.init(this);
		
			channel = song.play(0,int.MAX_VALUE,new SoundTransform(.3));
			fadeInSound();
			
			stage.addEventListener(MouseEvent.MOUSE_DOWN,mouseDown);
			
			
				*/
			*/
			addChild(screen);
			addChild(uiOverlay);
			ui.left.addEventListener(MouseEvent.MOUSE_DOWN,
				function(e) {
					approachWall();
				});*/
			ui.back.visible = false;
			
			stage.addEventListener(KeyboardEvent.KEY_UP,
				function(e:KeyboardEvent):void {
				});
				
							forcerefresh = true;
							e.preventDefault();
							e.stopImmediatePropagation();
			setMap(new NetworkedLudumMap(stage,"LD.json",new Date().fullYear.toString()));//,loaderInfo.url));
//			setMap(new LudumMap("LD.json","aaa"));
//			setMap(DungeonMap.instance);

			startingPoint = map.getStartingPoint();
			dstx = posx = startingPoint.x;
			dsty = posy = startingPoint.y;
//			dstx = posx = map.;
//			dsty = posy = so.data.posy;
		}
		
		private var startingPoint:Point;

		/*
		private function transport(x:int,y:int):void {
			if(x==0 && y==0) {
				x = int(Math.random()*10-5);
				y = int(Math.random()*10-5);
			}
			dstx = posx = (posx+x);
			dsty = posy = (posy+y);
			stage.focus = stage;
			forcerefresh = true;
//			map.dirty = true;
		}
		*/
			if(this.map) {
				this.map.removeEventListener(Event.CHANGE,onChangeMap);
			}
			this.map = map;
			if(this.map) {
				this.map.addEventListener(Event.CHANGE,onChangeMap);
			}
		}
		
		private function onChangeMap(e:Event):void {			
			forcerefresh = true;
		}
			return false;
		//	trace(MD5.hash(loaderInfo.url));
				case 'dbbdb55ef19adb892d395663e4c05806':
				case '8686d81661177d5750ff638fb2084a4d':
/*			
			var gid:String = hoveredGround?hoveredGround.gid:null;
			if(gid) {
				map.rubWall(gid);
			}*/
//			trace(hoveredGround?hoveredGround.gid:null);
			for (var k:String in keyMapping) {
				ui.kb[k].visible = keycodes[keyMapping[k]];
			}
			
			if(e.type==KeyboardEvent.KEY_DOWN && Wall.hoveredWall) {
				Wall.hoveredWall.keyboardAction(e.keyCode);
			}
		}
			if(xshift<-250) {
				mouseRot = -1;
			}
			else if(xshift>250) {
				mouseRot = 1;
			}
			if(hshift>215 && approach) {
				moveBack();
			}
//			trace(hshift);
		*/
		*/
		*/
		/*
		*/
		
		private function hasFrontWall():Boolean {
			var wall2 = screen.getChildByName("F|0|0|0");
			return wall2 && wall2.visible;
		}

		private var found:Object = {};
		private function dig(root:DisplayObjectContainer):void {
			if(!root)
				return;
//			if(!found[getQualifiedClassName(root)]) {
				found[getQualifiedClassName(root)] = found[getQualifiedClassName(root)]?found[getQualifiedClassName(root)]+1:1;
//				trace(getQualifiedClassName(root));
//			}
			for(var i:int=0;i<root.numChildren;i++) {
				dig(root.getChildAt(i) as DisplayObjectContainer);
			}
		}
		
		private var traces:Object ={};
		private var traceCount:int;
		
			//found = {};
			//dig(root as MovieClip);
			//trace(JSON.stringify(found,null,'\t'));
			var displayedElements:Object = {};
			var screen:Sprite = e.currentTarget as Sprite;
			var speed:Number = !approach?1/10:closeness<.7?1/7:1/30;
			var mousx = (approach?closeness:1)*(stage.mouseX-stage.stageWidth/2);
			var rot:int = (keycodes[keyMapping.rotateleft]?-1:0)+(keycodes[keyMapping.rotateright]?1:0);
			var realrot:int = approach?0:rot;
		
			var hshift:Number;
						
			
			var lmov:int = (keycodes[keyMapping.left]?-1:0)+(keycodes[keyMapping.right]?1:0);
			if(!approach) {
				var ax:int = xd*lmov-xyd*mov;
				var ay:int = yd*mov-yxd*lmov;
				recul = false;				
			}
			else {
				ax = approach.x-Math.round(posx);
				ay = approach.y-Math.round(posy);
				
				if(!ax&&!ay && map.canGo(oldposfix,oldposfiy,level,Math.round(posx),Math.round(posy),level)) {
					approach = null;
				}
				if(!ax && !ay && (lmov!=0 || mov<0 || rot!=0) && !recul) {
					moveBack();
				}
				speed = Math.min(speed,Math.sqrt(ax*ax+ay*ay));
			}
//			trace(speed);
			dstx = ax?dstx+ax*speed:Math.round(dstx);
/*			if(viewOnlyMode()) {
				dstx = oldposfix;
				dsty = oldposfiy;
			}
			if(approach) {
				posx += diffx;
				posy += diffy;
			}
			else if(mov>0 && lmov==0 && !map.canGo(oldposfix,oldposfiy,level,Math.round(posx+diffx),Math.round(posy+diffy),level) && !approach && hasFrontWall()) {
				approachWall();
			}
			else if(map.canGo(oldposfix,oldposfiy,level,Math.round(posx+diffx),Math.round(posy+diffy),level) &&
				(map.canGo(oldposfix,oldposfiy,level,Math.round(posx+diffx),Math.round(posy),level) ||
			}
			else if(map.canGo(oldposfix,oldposfiy,level,Math.round(posx+diffx),Math.round(posy),level)) {
				posx += diffx;
				diffy = 0;
				dsty = oldposfiy;
			}
			else if(map.canGo(oldposfix,oldposfiy,level,Math.round(posx),Math.round(posy+diffy),level)) {
				posy += diffy;
				diffx = 0;
				dstx = oldposfix;
			}
				maparray = map.getMap(posfix,posfiy,0,idirmod,!recul?approach:null,mode);
				
				var className:String = mappa[6];
				var objectType:String = mappa[7];
				var url:String = mappa[8];
				var classNameFromSWF:String = mappa[9];
				var label:String = mappa[10];
				var params:Array = mappa.slice(11);
								
				num = Math.round(num*100)/100;
					ground = elemcache[sid];
				}
				else {
				}
				
				{
//					trace(mappa);
					if(objectType=='load') {
//						trace(mappa);
//						trace(params);
						ground = hyperLoad(url,classNameFromSWF,room,gid,label,params);
						elemcache[sid] = ground;
					}
					ground.addEventListener(Event.REMOVED_FROM_STAGE,
						function(e:Event):void {
							e.currentTarget.removeEventListener(MouseEvent.MOUSE_DOWN,mouseDownGround);
							e.currentTarget.removeEventListener(MouseEvent.ROLL_OVER,mouseOver);
							e.currentTarget.removeEventListener(MouseEvent.ROLL_OUT,mouseOut);
						});
				if(label) {
					ground.label = label;
				}
				ground.posx = xi + xshift + xdd;
				ground.posy = yi + yshift + ydd - zoom;
				ground.posh = hi + hshift;
				ground.transform.colorTransform = colorTransform(num,num,num);
		
				
				var mmc:WallContainer = wallcache[gid];
				if(poschanged || mmc && mmc.content && mmc.content.animated)
				{
					
					ground.gid = gid;
					}
						ground.clear();
							mmc = wallLoad(url,classNameFromSWF,room,gid,label,params);
						displayedElements[gid] = mmc;

						mmc.dispatchEvent(new WallEvent(WallEvent.MOVE_TO,Math.round(Math.sqrt(dx*dx+dy*dy))));
						ground.clear();
						var rand:uint = RandSeedCacher.instance.seed(gid)[0];
						//trace("#|"+startingPoint.x+"|"+startingPoint.y+"|");
						//trace(gid);
						var isStart:Boolean = gid.indexOf("#|"+(startingPoint.x+1)+"|"+startingPoint.y+"|")>=0
						||	gid.indexOf("#|"+(startingPoint.x-1)+"|"+startingPoint.y+"|")>=0
						||  gid.indexOf("#|"+(startingPoint.x)+"|"+(startingPoint.y-1)+"|")>=0
						||  gid.indexOf("#|"+(startingPoint.x)+"|"+(startingPoint.y+1)+"|")>=0;
						ground.draw(isStart?aaf:rand%500==1?aad:traces[gid]?aae:aab,false);
			}
			var wall2 = screen.getChildByName("F|0|0|0");
			ui.front.visible = !NOUI && !approach && wall2 && wall2.visible;
			//bars.visible = !wall2 || !wall2.visible;
//				ui.front.alpha = Math.min(1,(4000-getTimer()+idle)/1000);
//			ui.right.visible = ui.left.visible = false;
					if(obj1.yi!=obj2.yi)
				}
					var con:Class = Object(screen.getChildAt(i)).constructor;
						screen.removeChildAt(i);
				}
				for(gid in wallcache) {
					if(!displayedElements[gid]) {
						if(wallcache[gid].content)
							wallcache[gid].content.recycle();
						delete wallcache[gid];
					}
				}
				ui.info.text = ""+[posfix,posfiy];
				GlobalDispatcher.instance.dispatchEvent(new PositionEvent(PositionEvent.MOVEPOSITION,{x:posfix,y:posfiy,dir:idirmod}));
			}
			if(!stage.focus || !self.contains(stage.focus)) {
				stage.focus = self;
			}
*/			
			hoveredGround = e.currentTarget as Block;
		}
			if(hoveredGround==e.currentTarget) {
				hoveredGround = null;
			}
		
		private function mouseDownGround(e:MouseEvent) {
//			trace(con);
				if(e.currentTarget.name=="F|0|-1|0") {
		
		
*/		
		private function wallLoad(url:String,className:String,room:String,gid:String,label:String,params:Array):WallContainer {
			var mmc:WallContainer = new WallContainer();
			WallLoader.fetchWall(url,className,
				function(wall:Wall,width:Number,height:Number):void {
					try {
						var sprite:Sprite = new Sprite();
						var mc:Wall = wall;
						mmc.addChild(sprite);
						mmc.content = mc;
						sprite.addChild(mc);
						var ss:Sprite = mc;
						ss.scaleX = 100/width;
						ss.scaleY = 100/height;
						if(ss.scaleX>ss.scaleY) {
							ss.scaleX = ss.scaleY;
						}
						else {
							ss.scaleY = ss.scaleX;
						}
						ss.x = -width/2 * ss.scaleX;
						ss.y = -height/2 * ss.scaleY-50;
						
						
						
						forcerefresh = true;
						
						if(mc is MovieClip) {
							if(mc.initialize!=null) {
								mc.initialize.apply(mc,[room,gid].concat(params));	
							}
							mc.addEventListener(Event.CHANGE,
								function(e) {
									Block.clearCache(mmc.content);
								});
							if(existAndTrue(mc,"moveTo")) {
								mmc.addEventListener(WallEvent.MOVE_TO,mc.moveTo);
							}
						}
					}
					catch(error) {
						trace(error);
						loadComplete(error);
					}
				});
			
			return mmc;


			
//			trace(className,room,gid,params);
			var ground:Block = new BLoader();
			
			
			WallLoader.fetchWall(url,className,
				function(wall:Wall,width:Number,height:Number):void {
					while(ground.numChildren) {
						ground.removeChildAt(0);
					}
					wall.scaleX = wall.scaleY = .2;
					ground.addChild(wall);
					ground.content = wall;
					wall.initialize.apply(wall,[room,gid].concat(params));
					
				});
			return ground;
/*			
			WallLoader.fetchLoader(url,
				function(loader:Loader,sandboxed:Boolean):void {
					var width:Number = loader.contentLoaderInfo.width;
					var height:Number = loader.contentLoaderInfo.height;						
					hypercache[loader.contentLoaderInfo.url]=ground;
					//Block.clearCache(ground);
		
					while(ground.numChildren) {
						ground.removeChildAt(0);
					}
					if(width>100 || height>100) {
						loader.scaleX = 100/width;
						loader.scaleY = 100/height;
						if(loader.scaleX<loader.scaleY) {
							loader.scaleY = loader.scaleX;
						}
						else {
							loader.scaleX = loader.scaleY;
						}
					}
					//trace(url,e.currentTarget.height);
					loader.x = -loader.scaleX*width/2;
					loader.y = -loader.scaleY*height;
					ground.addChild(loader);
					if(loader.content is MovieClip) {
						var mc = MovieClip(loader.content);
						if(mc.initialize)
							mc.initialize.apply(loader.content,params);
						if(mc.errorevent && mc.readyevent) {
							mc.addEventListener(mc.errorevent,loadComplete);
							mc.addEventListener(mc.readyevent,loadComplete);
						}
					}
				});
			
			return ground;
			*/
			/*
			trace(url);
			var loader = new Loader();
			var bytes:ByteArray = Cache.instance.get(url,"bytes") as ByteArray;
			if(bytes) {
				loader.loadBytes(bytes);
			}
			else {
				if(!loadinprogress) {
			}
			idle = getTimer();
			approach = frontspot(dir);
			bars.gotoAndPlay("APPROACH");
			
			dstx = approach.x;
			dsty = approach.y;
			Mouse.show();
		}
		*/
		
/*		private function setFrontWall(str:String,confirm:Boolean = false) {
		*/
			approach = frontspot(dir);
			dstx = approach.x;
			dsty = approach.y;
			Mouse.hide();
				else if(ui.addvideo.currentFrame==4) {
					if(ui.addvideo.clicka.dirty && ui.addvideo.clicka.comment.text.length) {
						setFrontWall("comment.swf|"+escape(ui.addvideo.clicka.comment.text)+"|"+Achievement.playerName+"|true");
						
						theWall = screen.getChildByName("F|0|-1|0");
						map.sendMessage(
							{
								type:"comment",
								message:escape(ui.addvideo.clicka.comment.text),
								wallID:theWall.gid,
								author:Achievement.playerName
							}
						);
						
						ui.addvideo.clicka.dirty = false;
						ui.addvideo.clicka.comment.text = "Click here to enter comment";
					}
				}
			GlobalMess.instance.position.x = x;
			GlobalMess.instance.position.y = y;
		}
		
		private function colorTransform(r:Number=1.0,g:Number=1.0,b:Number=1.0,a:Number=1.0,ro:Number=0,go:Number=0,bo:Number=0,ao:Number=0):ColorTransform {
			colTransform.redMultiplier = r;
			colTransform.greenMultiplier = g;
			colTransform.blueMultiplier = b;
			colTransform.alphaMultiplier = a;
			colTransform.redOffset = ro;
			colTransform.greenOffset = go;
			colTransform.blueOffset = bo;
			colTransform.alphaOffset = ao;
			return colTransform;
		}