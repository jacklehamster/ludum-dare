package  {
	import com.dobuki.Wall;
	import com.dobuki.events.WallEvent;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import com.dobuki.IWall;
	import flash.display.Loader;
	import flash.system.Security;
	import flash.geom.Rectangle;
	import flash.filters.GlowFilter;
	import flash.net.URLRequest;
	import flash.net.URLLoader;
	import flash.net.URLVariables;
	import flash.display.Bitmap;
	import com.dobuki.Cache;
	import flash.utils.ByteArray;
	
	public class YouTube extends Wall {

		static private var _once:Boolean = false;

		private var mytitle:String = null;
		private var readyevent:String = "ready";
		private var errorevent:String = "onError";

		private var loader:Loader = new Loader();
		private var utid;
		private var option;
		private var started:Boolean = false;
		private var doleaveiton = true;
		private var wasplaying = false;
		
		static private var playingInstance:YouTube = null;
		
		public function YouTube():void {
			if(!_once) {
				Security.allowDomain("youtube.com");
				Security.allowDomain("ytimg.com");
				Security.allowDomain("s.ytimg.com");
				Security.allowDomain("i4.ytimg.com");
				_once = true;
			}
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE,
				function(e:Event):void {
					var rect:Rectangle = ut.getRect(self);
					loader.width = rect.width;
					loader.height = rect.height;
					loader.scaleX = loader.scaleY = Math.min(loader.scaleX,loader.scaleY);
					loader.x = (rect.left+rect.right-loader.width)/2;
					loader.y = (rect.top+rect.bottom-loader.height)/2;
					Cache.instance.set(utid,"thumbnail",loader.contentLoaderInfo.bytes);
				});
			ut.addEventListener("onError",
				function(e) {
					ut.visible = false;
				});
			ut.addEventListener(errorevent,
				function(e) {
					trace(e);
					dispatchEvent(e);
				});
			ut.addEventListener("playing",
				function(e) {
					if(playingInstance && playingInstance!=self) {
						playingInstance.doPause();
					}
					playingInstance = self as YouTube;
					GlobalDispatcher.instance.dispatchEvent(new Event("fadeOut"));

				});
				
			leaveiton.visible = false;
			leaveiton.addEventListener(MouseEvent.MOUSE_DOWN,
				function(e) {
					doleaveiton = !doleaveiton;
					e.currentTarget.filters = doleaveiton?[new GlowFilter()]:[];
					if(doleaveiton)
						addEventListener(Event.ENTER_FRAME,refresh);
					else
						removeEventListener(Event.ENTER_FRAME,refresh);		
					e.stopPropagation();
				});

			addEventListener(Event.ADDED_TO_STAGE,
				function(e) {
					if(wasplaying && ut.visible)
						ut.playVideo();
				});
			addEventListener(Event.REMOVED_FROM_STAGE,
				function(e) {
					if(!doleaveiton) {
						doPause();
						GlobalDispatcher.instance.dispatchEvent(new Event("fadeIn"));
						ut.stopVideo();
						
					}
				});
				
			playbutton.addEventListener(MouseEvent.MOUSE_DOWN,onPlay);
			loader.addEventListener(MouseEvent.MOUSE_DOWN,
				function(e:MouseEvent):void 
				{
					if(!cover.visible) {
						if(!wasplaying) {
							onPlay(null);
						}
					}
				});
			ut.buttonMode = true;
				
			pausebutton.addEventListener(MouseEvent.MOUSE_DOWN,
				function(e) {
					doPause();
					e.stopPropagation();
				});
		}
		
		private function refresh(e) {
			dispatchEvent(new Event(Event.CHANGE));
		}
		
		override public function initialize(room:String,id:String,... option):IWall {
///			trace(">>",room,id,option);
			var utid:String = option[0];
			var title:String = option[1];
			super.initialize(room,id);
			this.option = option.slice(2);
			this.utid = utid;
			var bytes:ByteArray = Cache.instance.get(utid,"thumbnail") as ByteArray;
			if(bytes) {
				loader.loadBytes(bytes);
			}
			else {
				loader.load(new URLRequest("http://i4.ytimg.com/vi/"+utid+"/mqdefault.jpg"));
			}
			addChild(loader);
			ut.visible = false;
			pausebutton.visible = false;
			return this;
		}
		
		override public function moveTo(e:WallEvent):void {
			super.moveTo(e);
			cover.visible = false;//e.distance>1;
			ut.setVolume(100/(Math.pow(e.distance,2)+1));
			if(e.distance>=5 && wasplaying) {
				GlobalDispatcher.instance.dispatchEvent(new Event("fadeIn"));
				doPause();
				ut.stopVideo();
			}			
			if(!wasplaying && e.distance==0) {
				onPlay(null);
			}
		}

		private function startVideo(room,id,utid,title,option) {
			started = true;
			mytitle = title;
			ut.addEventListener(readyevent,
				function(e) {
					if(loader.parent)
						removeChild(loader);
					e.currentTarget.removeEventListener(e.type,arguments.callee);
					dispatchEvent(e);
				});
			if(option.indexOf("pending")>=0) {
				ut.addEventListener(readyevent,
					function(e) {
						if(option.indexOf("pending")>=0) {
							var urlloader = new URLLoader();
							var urlrequest = new URLRequest("http://hamster.agilityhoster.com/mixo.php");
							urlrequest.data = new URLVariables();
							urlrequest.data.r = room;
							urlrequest.data["f["+id+"]"]="ut.swf|"+utid+"|"+title;
							//trace(urlrequest.url+"?"+urlrequest.data);
							urlloader.load(urlrequest);
						}
						e.currentTarget.removeEventListener(e.type,arguments.callee);
					});
			}
			cover.visible = false;
			ut.loadup(utid);
		}

		private function onPlay(e:MouseEvent):void {
			ut.buttonMode = false;
			wasplaying = true;
			ut.visible = true;
			if(!started) {
				if(loader.parent)
					removeChild(loader);
				startVideo(room,wallID,utid,mytitle,option);
			}
			else
				ut.playVideo();
			if(e)
				e.stopPropagation();
		}
		
		private function doPause():void {
			wasplaying = false;
			if(ut.visible)
				ut.stopVideo();
		}
	}
	
}
