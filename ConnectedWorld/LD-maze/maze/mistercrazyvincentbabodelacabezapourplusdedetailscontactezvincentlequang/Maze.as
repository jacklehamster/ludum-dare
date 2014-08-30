package {		import flash.display.MovieClip;	import flash.display.Sprite;	import flash.display.DisplayObjectContainer;	import flash.display.Loader;	import flash.text.TextField;	import flash.filters.GlowFilter;	import flash.geom.ColorTransform;	import flash.utils.getDefinitionByName;	import flash.events.KeyboardEvent;	import flash.events.Event;	import flash.events.MouseEvent;	import flash.utils.getTimer;	import flash.net.SharedObject;	import flash.net.URLRequest;	import flash.net.URLRequestMethod;	import flash.ui.Mouse;	import flash.system.LoaderContext;	import flash.geom.Rectangle;	import Block;	import MD5;	import CustomEvent;	import flash.geom.Point;	import flash.events.IOErrorEvent;	import flash.net.URLLoader;	import flash.net.URLVariables;	import flash.system.Capabilities;	import flash.events.FocusEvent;	import flash.ui.Keyboard;	import flash.utils.ByteArray;
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
		
		
		private var version:String = "1.00"+new Date().getTime();		private var room:String = "NG";		public var map:IMap;		private var posx:Number = 1;//Math.random()*50-25;		private var posy:Number = 1;//Math.random()*50-25;		private var dstx:Number = 0;		private var dsty:Number = 0;		private var dir:Number = 0;		private var dstdir:Number = 0;		private var so:SharedObject = SharedObject.getLocal("Maze");		private var keycodes:Array = [];		private var forcerefresh = false;		private var screen:Sprite = new Sprite();		private var frontwall = null;		private var yshift:Number = 0;		private var level:int = 0;		private var approach:Point = null;		private var maparray:Array = null;		private var mouseRot:int = 0;		private var mdown:Boolean = false;//		private var minimap:Sprite = new Sprite();		private var recul:Boolean = false;		private var mode:int = 1;		private var idle:int = 0;/*		private var minimapx = 0;		private var minimapy = 0;		private var minimapdir = 0;		private var minipath:Array = null;*/		private var oldmouseX,oldmouseY;		private var cellui = null;		private var elemcache = {};		private var wallcache = {};		private var hypercache = {};				private var loadqueue:Array = [];		private var loadinprogress:Boolean = false;		private var glow = [new GlowFilter()];
		private var inited:Boolean;
		
		private var _hoveredGround:Block = null;
		
		private var colTransform:ColorTransform = new ColorTransform();
		private var channel:SoundChannel;		public function Maze() {
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
		private function init(params,data=null,bgpass=null) {			if(inited) {
				return;
			}
			inited = true;
			Achievement.init(this);
		
			channel = song.play(0,int.MAX_VALUE,new SoundTransform(.3));
			fadeInSound();
						//opaqueBackground = 0;			//Security.allowDomain("www.youtube.com");			//stage.quality = "LOW";			//viewOnlyMode();			stage.addEventListener(KeyboardEvent.KEY_DOWN,keyAction);			stage.addEventListener(KeyboardEvent.KEY_UP,keyAction);			screen.addEventListener(Event.ENTER_FRAME,refresh);			stage.addEventListener(MouseEvent.MOUSE_UP,mouseUp);			stage.addEventListener(Event.MOUSE_LEAVE,mouseUp);			stage.addEventListener(MouseEvent.MOUSE_MOVE,mouseMove);
			stage.addEventListener(MouseEvent.MOUSE_DOWN,mouseDown);			
			
			/*			if(so.data.posx)				dstx = posx = so.data.posx;			if(so.data.posy)				dsty = posy = so.data.posy;			if(so.data.dir)				dstdir = dir = so.data.dir;
				*//*							minimap.addEventListener(Event.ADDED_TO_STAGE,				function(e) {					var spot = frontspot(dir);					minimapx = Math.round(posx-spot.x);					minimapy = Math.round(posy-spot.y);					minimapdir = Math.round(dir);//					stage.addEventListener(KeyboardEvent.KEY_DOWN,keyMap);				});			minimap.addEventListener(Event.REMOVED_FROM_STAGE,				function(e) {//					stage.removeEventListener(KeyboardEvent.KEY_DOWN,keyMap);					posx = minimapx;					posy = minimapy;					dir = minimapdir;					dstx = minimapx;					dsty = minimapy;					dstdir = minimapdir;					approach.x = minimapx;					approach.y = minimapy;					forcerefresh = true;				});			minimap.opaqueBackground = 0;
			*/
			addChild(screen);			addChild(bars);			addChild(ui);
			addChild(uiOverlay);
			ui.left.addEventListener(MouseEvent.MOUSE_DOWN,				function(e) {					mouseRot = -1;				});			ui.right.addEventListener(MouseEvent.MOUSE_DOWN,				function(e) {					mouseRot = +1;						});/*			ui.back.addEventListener(MouseEvent.MOUSE_DOWN,				function(e) {					moveBack();				});			ui.front.addEventListener(MouseEvent.MOUSE_DOWN,
				function(e) {
					approachWall();
				});*/
			ui.back.visible = false;
			
			stage.addEventListener(KeyboardEvent.KEY_UP,
				function(e:KeyboardEvent):void {					instructions.visible = false;
				});//			ui.addvideo.visible = false;			//minimap.visible = false;			
							ui.info.addEventListener(KeyboardEvent.KEY_DOWN, //Event.CHANGE,				function(e:KeyboardEvent) {					if(e.keyCode==Keyboard.ENTER) {						var sp = e.currentTarget.text.split(",");						if(sp.length==2) {							dstx = posx = parseInt(sp[0]);							dsty = posy = parseInt(sp[1]);							stage.focus = stage;
							forcerefresh = true;							//map.dirty = true;
							e.preventDefault();
							e.stopImmediatePropagation();						}					}					(ui.info as TextField).textColor = 0x00FF00;				});//			setMap(new MixoMap(room));//			setMap(new CryptoMap());
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
		*/				private function setMap(map) {
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
		}		/*		private function viewOnlyMode() {
			return false;
		//	trace(MD5.hash(loaderInfo.url));//			return false;			var hypercode = MD5.hash(loaderInfo.url.split("/").slice(loaderInfo.url.split("/").length-3).join("Vincent"));			switch(hypercode) {				case '2fc15a82e3a0ca7a552649ca199ac60a':				case 'd047ae90da336813fbd60b333e8d2e2d':				case 'd5f5be949b1cad2b5c359bfd839e5167':				case 'a3d1f9e264a2c74feb03e0657b9f694d':				case 'fa89f6852c2d1048a33871859d9a1ce8':				case 'fd8a5cbe89922d1745e5ff8f43572fcc':				case '87db70ab584c969bbc5118fb5b1cb44a':				case '94734fa5924298b0c797192f95d1189a':
				case 'dbbdb55ef19adb892d395663e4c05806':
				case '8686d81661177d5750ff638fb2084a4d':					return false;					break;				default:					ui.info.autoSize = "left";					ui.info.mouseEnabled = true;					ui.info.selectable = true;					ui.info.text = hypercode;					if(loaderInfo.parameters.trace)						trace(hypercode);			}			return true;		//	trace(loaderInfo.url.split("/").slice(loaderInfo.url.split("/").length-3));		}*/		private function mouseMove(e) {			if(!e.buttonDown)				mdown = false;			idle = getTimer();
/*			
			var gid:String = hoveredGround?hoveredGround.gid:null;
			if(gid) {
				map.rubWall(gid);
			}*/
//			trace(hoveredGround?hoveredGround.gid:null);		}		private function keyAction(e:KeyboardEvent) {			keycodes[e.keyCode] = e.type==KeyboardEvent.KEY_DOWN;			
			for (var k:String in keyMapping) {
				ui.kb[k].visible = keycodes[keyMapping[k]];
			}
			
			if(e.type==KeyboardEvent.KEY_DOWN && Wall.hoveredWall) {
				Wall.hoveredWall.keyboardAction(e.keyCode);
			}
		}		private function mouseDown(e) {			var xshift = stage.mouseX-stage.stageWidth/2;			var hshift = stage.mouseY-stage.stageHeight/2;
			if(xshift<-250) {
				mouseRot = -1;
			}
			else if(xshift>250) {
				mouseRot = 1;
			}
			if(hshift>215 && approach) {
				moveBack();
			}
//			trace(hshift);//			trace(x,xshift,yshift);			//trace("clear" in e.currentTarget);		}				private function mouseUp(e) {			mdown = false;			//idle = getTimer();		}				/*		private function keyMap(e) {			var spot;			//map.hasGround			var imx = minimapx;			var imy = minimapy;			switch(e.keyCode) {				case 83:					spot = frontspot(minimapdir);					imx -=  spot.x;					imy -=  spot.y;					break;				case 87:					spot = frontspot(minimapdir);					imx +=  spot.x;					imy +=  spot.y;					break;				case 65:					spot = frontspot(minimapdir-1);					imx +=  spot.x;					imy +=  spot.y;					break;				case 68:					spot = frontspot(minimapdir+1);					imx +=  spot.x;					imy +=  spot.y;					break;				case 69:					minimapdir ++;					break;				case 81:					minimapdir --;					break;			}			if(map.hasGround(imx,imy,level)) {				minimapx = imx;				minimapy = imy;			}			refreshMiniMap(minimapx,minimapy,minimapdir);		}
		*//*		private function minimapMove(e) {			if(minipath) {				if(minipath.length) {					var nextstep = minipath[minipath.length-1];					if(nextstep[0]==minimapx && nextstep[1]==minimapy) {						minipath.pop();					}					else {						var choices = [								[frontspot(minimapdir),0],								[frontspot(minimapdir-1),-1],								[frontspot(minimapdir+1),+1]							];						var choice;						for(var i=0;i<choices.length;i++) {							choice = choices[i];							if(minimapx+choice[0].x==nextstep[0] && minimapy+choice[0].y==nextstep[1]) {								break;							}						}										if(choice[1]) {							minimapdir += choice[1];						}						else {							minimapx += choice[0].x;							minimapy += choice[0].y;						}						refreshMiniMap(minimapx,minimapy,minimapdir);					}				}				if(!minipath.length) {					minipath = null;					e.currentTarget.removeEventListener(e.type,arguments.callee);				}			}		}
		*/				private function frontspot(dir:Number):Point {			var idir:int = Math.round(dir);// Math.round(dir+4)%4;			var xd:int, yd:int, xyd:int, yxd:int;			var idirmod:int = (idir%4+4)%4;			switch(idirmod) {				case 0: xd=1;yd=1;xyd=0;yxd=0;break;				case 1: xd=0;yd=0;xyd=-1;yxd=1; break;				case 2: xd=-1;yd=-1;xyd=0;yxd=0; break;				case 3: xd=0;yd=0;xyd=1;yxd=-1; break;			}			return new Point(-xyd,yd);		}		/*				private function pathTo(x:int,y:int,destx:int,desty:int,maxsearch:int):Array {			var stack:Array = [];			stack.push([x,y,0,null]);			var closest = null;			var mindistsq:int = 0;			while(stack.length) {				var p:Array = stack.shift();				if(p[2]<=maxsearch) {					var spots:Array =						[[p[0]-1,p[1],p[2]+1,p],[p[0]+1,p[1],p[2]+1,p],[p[0],p[1]-1,p[2]+1,p],[p[0],p[1]+1,p[2]+1,p]];					for(var i=0;i<spots.length;i++) {						var spot = spots[i];						if(map.hasGround(spot[0],spot[1],level)) {							stack.push(spot);						}					}				}				var dx = p[0]-destx;				var dy = p[1]-desty;				var distsq = dx*dx+dy*dy;				if(!closest || mindistsq>distsq) {					closest = p;					mindistsq = distsq;				}				if(p[0]==destx && p[1]==desty) {					break;				}			}			var paths:Array = [];			while(closest) {				paths.push([closest[0],closest[1]]);				closest = closest[3];			}			return paths;		}
		*//*				private function pathFind(from:Object,to:Object) {			const DEPTH = 5;			if(!minipath) {				minipath = pathTo(from.x,from.y,to.x,to.y,DEPTH);				minimap.addEventListener(Event.ENTER_FRAME,minimapMove);			}		}*/		
		/*		private function refreshMiniMap(ix,iy,idir) {			ui.info.text = ""+[ix,iy];			ui.info.visible = true;			var minimapsize:int = 10;			for(var py=-minimapsize;py<=minimapsize;py++) {				for(var px=-minimapsize;px<=minimapsize;px++) {					var mm = minimap.getChildByName(px+"|"+py);					if(!mm) {						mm = new Tile();						mm.name = px+"|"+py;						mm.width = mm.height = 40;						minimap.addChild(mm);						mm.x = px*40;						mm.y = -py*40;						mm.me.visible = !px&&!py;						mm.addEventListener(MouseEvent.ROLL_OVER,							function(e) {								e.currentTarget.parent.addChild(e.currentTarget);								//e.currentTarget.filters = glow;								var psplit = e.currentTarget.name.split("|");								if(e.buttonDown) {									var namesplit:Array = e.currentTarget.name.split("|");									pathFind({x:minimapx,y:minimapy},{x:minimapx+parseInt(namesplit[0]),y:minimapy+parseInt(namesplit[1])});								}							});						mm.addEventListener(MouseEvent.ROLL_OUT,							function(e) {								e.currentTarget.filters = [];							});						mm.addEventListener(MouseEvent.MOUSE_DOWN,							function(e) {								if(!minipath) {									var namesplit:Array = e.currentTarget.name.split("|");									pathFind({x:minimapx,y:minimapy},{x:minimapx+parseInt(namesplit[0]),y:minimapy+parseInt(namesplit[1])});								}							});					}					mm.ground.visible = map.hasGround(ix+px,iy+py,level);					if(mm.me.visible)						mm.me.rotation = idir*90;					var g = map.getGroundObjects(ix+px,iy+py,level);					mm.G.visible = g && g.G;					mm.N.visible = g && g.N || map.getWallByID(["#",ix+px,iy+py,"N"].join("|"));					mm.E.visible = g && g.E || map.getWallByID(["#",ix+px,iy+py,"E"].join("|"));					mm.W.visible = g && g.W || map.getWallByID(["#",ix+px,iy+py,"W"].join("|"));					mm.S.visible = g && g.S || map.getWallByID(["#",ix+px,iy+py,"S"].join("|"));				}			}			minimap.width = 100;			minimap.height = 100;			var rect:Rectangle = minimap.getRect(minimap);			minimap.x = -rect.x*minimap.scaleX -50;			minimap.y = -rect.y*minimap.scaleY -100;			//Block.clearCache(minimap);		}
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
				private function refresh(e:Event):void {
			//found = {};
			//dig(root as MovieClip);
			//trace(JSON.stringify(found,null,'\t'));
			var displayedElements:Object = {};
			var screen:Sprite = e.currentTarget as Sprite;			var closeness:Number = approach ? Point.distance(approach,new Point(posx,posy)):0;
			var speed:Number = !approach?1/10:closeness<.7?1/7:1/30;
			var mousx = (approach?closeness:1)*(stage.mouseX-stage.stageWidth/2);			var mousy = (approach?closeness:1)*(stage.mouseY-stage.stageHeight/2);			var olddir:int = Math.round(dir);
			var rot:int = (keycodes[keyMapping.rotateleft]?-1:0)+(keycodes[keyMapping.rotateright]?1:0);
			var realrot:int = approach?0:rot;			dstdir = approach?dir:mouseRot?(dir+mouseRot):realrot?(dir+ realrot*.5):Math.round(dstdir);			mouseRot = 0;			dir += (dstdir-dir)/6;			var idir:int = Math.round(dir);			var oldmode:int = mode;			var xd:int, yd:int, xyd:int, yxd:int;			var idirmod:int = (idir%4+4)%4;			switch(idirmod) {				case 0: xd=1;yd=1;xyd=0;yxd=0;break;				case 1: xd=0;yd=0;xyd=-1;yxd=1; break;				case 2: xd=-1;yd=-1;xyd=0;yxd=0; break;				case 3: xd=0;yd=0;xyd=1;yxd=-1; break;			}
		
			var hshift:Number;			var xshift:Number;
									if(mode==1) {	//	change visual depending on mode				hshift = -(mousy)/400;				xshift = (dir-idir)*1.5+ (mousx)/400;				screen.scaleX = 1;				screen.scaleY = 1;				screen.x = stage.stageWidth/2-xshift*566;				screen.y = stage.stageHeight/2+hshift*283;//				sky.x = screen.x;//				sky.y = screen.y;			}			else {				hshift = -4;				xshift = 0;				//screen.scaleX = .12;				screen.scaleX = .15;				screen.scaleY = .1;				screen.x = stage.stageWidth/2;				screen.y = stage.stageHeight/3;			}
						var mov:int = (keycodes[keyMapping.backward]?-1:0)+(keycodes[keyMapping.forward]?1:0);
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
			dstx = ax?dstx+ax*speed:Math.round(dstx);			dsty = ay?dsty+ay*speed:Math.round(dsty);			var diffx:Number = (dstx-posx)*speed;			var diffy:Number = (dsty-posy)*speed;			var oldposfix:Number = Math.round(posx);			var oldposfiy:Number = Math.round(posy);			
/*			if(viewOnlyMode()) {
				dstx = oldposfix;
				dsty = oldposfiy;
			}			else*/ 
			if(approach) {
				posx += diffx;
				posy += diffy;
			}
			else if(mov>0 && lmov==0 && !map.canGo(oldposfix,oldposfiy,level,Math.round(posx+diffx),Math.round(posy+diffy),level) && !approach && hasFrontWall()) {
				approachWall();
			}
			else if(map.canGo(oldposfix,oldposfiy,level,Math.round(posx+diffx),Math.round(posy+diffy),level) &&
				(map.canGo(oldposfix,oldposfiy,level,Math.round(posx+diffx),Math.round(posy),level) ||				map.canGo(oldposfix,oldposfiy,level,Math.round(posx),Math.round(posy+diffy),level))) {				posx += diffx;				posy += diffy;
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
			}			else {				dstx = oldposfix;				dsty = oldposfiy;			}			var posfix:int = Math.round(posx);			var posfiy:int = Math.round(posy);			var poschanged:Boolean = posfix!=Math.round(oldposfix)||posfiy!=Math.round(oldposfiy)||olddir!=idir||!maparray||oldmode!=mode||forcerefresh;//||map.dirty;			forcerefresh = false;			var array:Array;						{				if(!approach)					notifyPosition(posfix,posfiy,idir);
				maparray = map.getMap(posfix,posfiy,0,idirmod,!recul?approach:null,mode);				//trace(maparray);//				map.dirty = false;				array = [];		//				if(!approach) {//					refreshMiniMap(posfix,posfiy,idirmod);//				}			}			var fix:Number = posfix-posx;			var fiy:Number = posfiy-posy;			var xdd:Number = xd*fix+xyd*fiy;			var ydd:Number = yd*fiy+yxd*fix;			var zoom:Number = Math.abs(dir-idir);						for(var i=0;i<maparray.length;i++) {				var mappa:Array = maparray[i];
								//trace(">>",mappa);				var xi:Number=mappa[0];				var yi:Number=mappa[1];				var hi:Number=mappa[2];				var type:String= mappa[3];				var sid:String = mappa[4];				var gid:String = mappa[5];
				var className:String = mappa[6];
				var objectType:String = mappa[7];
				var url:String = mappa[8];
				var classNameFromSWF:String = mappa[9];
				var label:String = mappa[10];
				var params:Array = mappa.slice(11);
												var dx:Number = Math.abs(xi+xdd);				var dy:Number = Math.abs(yi+ydd+1);				var num:Number = Math.min(1,2.5/(dx/2+dy));				num *= num;
				num = Math.round(num*100)/100;				var ground:Block = null;				if(elemcache[gid]) {					ground = elemcache[gid];				} else if(objectType=="load" && elemcache[sid]) {
					ground = elemcache[sid];
				}
				else {					ground = screen.getChildByName(sid) as Block;
				}
								if(!ground) 
				{
//					trace(mappa);
					if(objectType=='load') {
//						trace(mappa);
//						trace(params);
						ground = hyperLoad(url,classNameFromSWF,room,gid,label,params);
						elemcache[sid] = ground;
					}					else {						var classObj = getDefinitionByName(className);						ground =new classObj();						if(objectType=='unique') {						   elemcache[gid] = ground;						}					}					ground.name = sid;					ground.xi = xi;					ground.yi = yi;					ground.hi = hi;					screen.addChild(ground);					ground.stop();					ground.type = type;					ground.addEventListener(MouseEvent.MOUSE_DOWN,mouseDownGround);					ground.addEventListener(MouseEvent.ROLL_OVER,mouseOver);					ground.addEventListener(MouseEvent.ROLL_OUT,mouseOut);
					ground.addEventListener(Event.REMOVED_FROM_STAGE,
						function(e:Event):void {
							e.currentTarget.removeEventListener(MouseEvent.MOUSE_DOWN,mouseDownGround);
							e.currentTarget.removeEventListener(MouseEvent.ROLL_OVER,mouseOver);
							e.currentTarget.removeEventListener(MouseEvent.ROLL_OUT,mouseOut);
						});				}
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
					
					ground.gid = gid;					array.push(ground);										//	code below customized					if(ground is BLoader) {						ground.xi = xi;						ground.yi = yi;						ground.hi = hi;						ground.size = 1;						ground.mouseEnabled = true;						ground.mouseChildren =  ground.xi==0&&ground.yi==-.5;					}					else if(ground is SmurfBMP || ground is Dude13 || ground is Dude12) {						ground.xi = xi;						ground.yi = yi;						ground.hi = hi;						ground.size = .3;
					}					else if(objectType=="unique") {						ground.xi = xi;						ground.yi = yi;						ground.hi = hi;						ground.size = .3;					}					else if(objectType=="loadwall") {
						ground.clear();						if(!mmc) {
							mmc = wallLoad(url,classNameFromSWF,room,gid,label,params);							wallcache[gid] = mmc;						}
						displayedElements[gid] = mmc;
												if(ground.name.indexOf("F")>=0) {////=="F|0|-1|0") {							frontwall = mmc;							ground.place(mmc);							ground.mouseEnabled = false;							ground.mouseChildren =  true;							frontMc(mmc);						}						else {							frontwall = mmc;							ground.place(mmc);							if(mmc.content && mmc.content.hasOwnProperty("canDraw") && mmc.content.canDraw)								ground.draw(mmc.content,false);						}
						mmc.dispatchEvent(new WallEvent(WallEvent.MOVE_TO,Math.round(Math.sqrt(dx*dx+dy*dy))));					}/*					else if(ground.gid=="#|-4|0|W") {						ground.clear();						if(ground.name=="F|0|-1|0") {							frontwall = minimap;							ground.place(frontwall);							ground.mouseEnabled = true;							ground.mouseChildren =  true;						}						//else						//	ground.draw(minimap,false);					}*/					else {/*						if(ground.name=="F|0|-1|0") {							var wasvisible = ui.addvideo.visible;							ui.addvideo.visible = approach;							ui.addvideo.wallid.text = "wall"+ground.gid;							if(ui.addvideo.visible && !wasvisible)								ui.addvideo.gotoAndStop(1);						}*/
						ground.clear();
						var rand:uint = RandSeedCacher.instance.seed(gid)[0];
						//trace("#|"+startingPoint.x+"|"+startingPoint.y+"|");
						//trace(gid);
						var isStart:Boolean = gid.indexOf("#|"+(startingPoint.x+1)+"|"+startingPoint.y+"|")>=0
						||	gid.indexOf("#|"+(startingPoint.x-1)+"|"+startingPoint.y+"|")>=0
						||  gid.indexOf("#|"+(startingPoint.x)+"|"+(startingPoint.y-1)+"|")>=0
						||  gid.indexOf("#|"+(startingPoint.x)+"|"+(startingPoint.y+1)+"|")>=0;
						ground.draw(isStart?aaf:rand%500==1?aad:traces[gid]?aae:aab,false);					}				}
			}					ui.right.visible = !NOUI && !approach && mode==1;			ui.left.visible = !NOUI && !approach && mode==1;			ui.back.visible = !NOUI && approach && getTimer()-idle<4000;			if(ui.back.visible)				ui.back.alpha = Math.min(1,(4000-getTimer()+idle)/1000);
			var wall2 = screen.getChildByName("F|0|0|0");
			ui.front.visible = !NOUI && !approach && wall2 && wall2.visible;
			//bars.visible = !wall2 || !wall2.visible;//			if(ui.front.visible)
//				ui.front.alpha = Math.min(1,(4000-getTimer()+idle)/1000);
//			ui.right.visible = ui.left.visible = false;								if(poschanged) {				array.sort(compareFunc);				function compareFunc(obj1,obj2):int {
					if(obj1.yi!=obj2.yi)						return obj2.yi<obj1.yi?-1:1;					return Math.abs(obj2.xi)<Math.abs(obj1.xi)?-1:Math.abs(obj2.xi)>Math.abs(obj1.xi)?1:0;
				}				for(i=0;i<array.length;i++) {					if(array[i].parent!=screen)						screen.addChild(array[i]);					array[i].visible = true;					screen.setChildIndex(array[i],i);				}				for(i=screen.numChildren-1;i>=array.length;i--) {
					var con:Class = Object(screen.getChildAt(i)).constructor;					if(con==Block||con==FrontWall) {						screen.getChildAt(i).visible = false;						(screen.getChildAt(i) as Block).clear();					}					else {
						screen.removeChildAt(i);					}
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
			}		}				private function mouseOver(e) {//			mdown = e.buttonDown;			if(mdown) {				var con = Object(e.currentTarget).constructor;				if(con==FrontWall || con==Block) {					if(e.currentTarget.name=="F|0|0|0") {					}					else if(!approach) {						maparray = null;						var gsplit:Array = e.currentTarget.gid.split("|");						var splitname:Array = e.currentTarget.name.split("|");						var spot = splitname[0]=='F'||splitname[0]=='D'||splitname[0]=='U'?frontspot(dir):new Point();						dstx = gsplit[1]-spot.x;						dsty = gsplit[2]-spot.y;					}				}			}						if(e.currentTarget.name=="R|-0.5|0|0") {				ui.left.transform.colorTransform = colorTransform(2,2,.5,1);			}			else if(e.currentTarget.name=="L|0.5|0|0") {				ui.right.transform.colorTransform = colorTransform(2,2,.5,1);			}			/*			if(e.currentTarget.name=="D|0|1|-1") {				e.currentTarget.filters = colo2.filters;			}			else if(e.currentTarget.name!="F|0|0|0"&&e.currentTarget.name!="F|0|-1|0")				e.currentTarget.filters = colo.filters;
*/			
			hoveredGround = e.currentTarget as Block;
		}				private function mouseOut(e) {			if(e.currentTarget.name=="R|-0.5|0|0") {				ui.left.transform.colorTransform = colorTransform();			}			else if(e.currentTarget.name=="L|0.5|0|0") {				ui.right.transform.colorTransform = colorTransform();			}			e.currentTarget.filters = [];
			if(hoveredGround==e.currentTarget) {
				hoveredGround = null;
			}		}
		
		private function mouseDownGround(e:MouseEvent) {			var con = Object(e.currentTarget).constructor;			if(con==BLoader)				mode = 1;//			trace(e.currentTarget,e.currentTarget.gid,e.currentTarget.name);//F|0|-1|0
//			trace(con);			mdown = e.buttonDown;			if(con==FrontWall || con==Block || con==BLoader) {				var splitname:Array = e.currentTarget.name.split("|");
				if(e.currentTarget.name=="F|0|-1|0") {					//map.setWall(e.currentTarget.gid,"ut.swf|JjTV8i_KjXM");					//trace(e.currentTarget.gid);				}				else if(mode==1 && e.currentTarget.name=="R|-0.5|0|0") {					mouseRot = -1;				}				else if(mode==1 && e.currentTarget.name=="L|0.5|0|0") {					mouseRot = 1;				}				else if(e.currentTarget.name=="F|0|0|0") {					approachWall();				}				else if(splitname[0]=='R'||splitname[0]=='L') {					gsplit = (e.currentTarget.gid).split("|");					spot = frontspot(dir);					dstx = Math.round(posx)+spot.x;					dsty = Math.round(posy)+spot.y;				}				else {					var gsplit:Array = (e.currentTarget.gid).split("|");					var spot = mode==2?new Point():splitname[0]=='F'||splitname[0]=='D'||splitname[0]=='U'?frontspot(dir):new Point();					dstx = gsplit[1]-spot.x;					dsty = gsplit[2]-spot.y;					if(splitname[0]=='D'&&e.currentTarget.name!='D|0|0|-1')						maparray = null;				}			}		}		/*		function supress(mc):void {			if("supress" in mc) {				mc.supress();			}			else if(mc is MovieClip) {				mc.stop();			}			if(mc is DisplayObjectContainer) {				for(var i=0;i<mc.numChildren;i++) {					var child = mc.getChildAt(i);					supress(child);				}			}		}
		
		
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
		}				static private function existAndTrue(mc,prop) {			return mc.hasOwnProperty(prop) && mc[prop];		}				private function loadComplete(e) {			if(loadqueue.length) {				var loadcombo = loadqueue.shift();				var url = loadcombo.url;				var request:URLRequest = new URLRequest(url.split("?")[0]);				if(flash.system.Capabilities.playerType=="External") {					request.method = URLRequestMethod.POST;				}				request.data = new URLVariables(url.split("?")[1]);				request.data.update = version;				loadcombo.loader.load(request,new LoaderContext(true));			}			else {				loadinprogress = false;			}		}				private function frontMc(mmc) {			//ui.info.visible = false;			stage.quality = "HIGH";			if(mmc.numChildren) {				var loader = mmc.getChildAt(0);				//cellui = loader.content.ui;				//if(cellui) {					//cellui.visible = true;					//addChild(cellui);				//}			}		}				private function backMc(mmc) {			stage.quality = "LOW";			ui.info.visible = true;			if(mmc.numChildren) {				Mouse.show();				var loader = mmc.getChildAt(0);				//if(cellui && loader.content) {					//cellui.visible = false;					//loader.content.addChild(cellui);					//cellui = null;				//}			}		}
		private function hyperLoad(url:String,className:String,room:String,gid:String,label:String,params:Array):Block {
			
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
			var loader = new Loader();			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,loadComplete);			loader.contentLoaderInfo.addEventListener(Event.COMPLETE,				function(e) {					try {						hypercache[e.currentTarget.url]=ground;						Block.clearCache(ground);									while(ground.numChildren) {							ground.removeChildAt(0);						}						if(e.currentTarget.width>100 || e.currentTarget.height>100) {							loader.scaleX = 100/e.currentTarget.width;							loader.scaleY = 100/e.currentTarget.height;							if(loader.scaleX<loader.scaleY) {								loader.scaleY = loader.scaleX;							}							else {								loader.scaleX = loader.scaleY;							}						}						//trace(url,e.currentTarget.height);						loader.x = -loader.scaleX*e.currentTarget.width/2;						loader.y = -loader.scaleY*e.currentTarget.height;						ground.addChild(loader);						if(loader.content is MovieClip) {							var mc = MovieClip(loader.content);							if(mc.initialize)								mc.initialize.apply(loader.content,params);							if(mc.errorevent && mc.readyevent) {								mc.addEventListener(mc.errorevent,loadComplete);								mc.addEventListener(mc.readyevent,loadComplete);							}							else {								loadComplete(e);							}						}						else {							loadComplete(e);						}					}					catch(error) {						loadComplete(error);					}				});			ground.loader = loader;
			var bytes:ByteArray = Cache.instance.get(url,"bytes") as ByteArray;
			if(bytes) {
				loader.loadBytes(bytes);
			}
			else {
				if(!loadinprogress) {					loadinprogress = true;					var request:URLRequest = new URLRequest(url.split("?")[0]);					request.data = new URLVariables(url.split("?")[1]);					request.data.update = version;					if(flash.system.Capabilities.playerType=="External") {						request.method = URLRequestMethod.POST;					}					loader.load(request,new LoaderContext(true));				}				else {					loadqueue.push({loader:loader,url:url});				}
			}						return ground;*/		}				private function approachWall() {
			idle = getTimer();
			approach = frontspot(dir);			approach.x += Math.round(posx);			approach.y += Math.round(posy);
			bars.gotoAndPlay("APPROACH");
			
			dstx = approach.x;
			dsty = approach.y;
			Mouse.show();
		}		/*		private function setGround(str:String,confirm:Boolean = false) {			var theWall = screen.getChildByName("F|0|-1|0");			var split = theWall.gid.split("|");			map.setGround(split[1],split[2],0,"");			//trace(str,theWall.gid);		}
		*/
		
/*		private function setFrontWall(str:String,confirm:Boolean = false) {			var theWall = screen.getChildByName("F|0|-1|0");			map.setWall(theWall.gid,str);			if(confirm) {				var urlloader:URLLoader = new URLLoader();				var urlrequest:URLRequest = new URLRequest("http://hamster.agilityhoster.com/mixo.php");				urlrequest.data = new URLVariables();				urlrequest.data.r = room;				urlrequest.data["f["+theWall.gid+"]"]=str;				urlrequest.method = URLRequestMethod.POST;				trace(urlrequest.data);				urlloader.load(urlrequest);			}					}
		*/				private function moveBack() {			bars.gotoAndPlay("MOVEBACK");
			approach = frontspot(dir);			approach.x = Math.round(posx)-approach.x;			approach.y = Math.round(posy)-approach.y;
			dstx = approach.x;
			dsty = approach.y;			recul = true;
			Mouse.hide();/*			if(ui.addvideo.visible) {				ui.addvideo.visible = false;				if(ui.addvideo.currentFrame==1) {					if(ui.addvideo.getChildByName("videoid").text != "<youtube video id>") {						var theWall = screen.getChildByName("F|0|-1|0");						setFrontWall("ut.swf|"+ui.addvideo.getChildByName("videoid").text+"|"+ui.addvideo.getChildByName("title").text+"|pending");						ui.addvideo.getChildByName("videoid").text = "<youtube video id>";						ui.addvideo.getChildByName("title").text = "<title>";					}				}
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
				}			}*/						if(frontwall) {				//Block.clearCache(frontwall);				backMc(frontwall);				if(frontwall.parent) {					frontwall.parent.mouseEnabled = false;					frontwall.parent.mouseChildren = false;				}				frontwall = null;			}		}				private function notifyPosition(x,y,dir) {			so.data.posx = x;			so.data.posy = y;			so.data.dir = dir;			//so.data.position = {x:x, y:y, dir:dir};			//so.flush();
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
		}	}///////////////////////////////////////////////////////////////////////////////////////////////////*var conn = new LocalConnection();conn.connect("yaya");conn.client = {	yaya: function (obj,url) {		var h = MovieClip(root).hypercache[url].loader;		if(h.contentLoaderInfo.applicationDomain.hasDefinition(obj)) {			for(var i=0;i<numChildren;i++) {				var child = ui.inventory.getChildAt(i);				if(!child.item) {					var o = new (h.contentLoaderInfo.applicationDomain.getDefinition(obj));					var rect = o.getRect(o);					o.x = -rect.x - rect.width/2;					o.y = -rect.y - rect.height;					child.item = o;					child.addChild(o);					child.gotoAndPlay(2);					break;				}			}		}	}};*///init//if(stage) {	//dispatchEvent(new Event(Event.ADDED_TO_STAGE));//}	}