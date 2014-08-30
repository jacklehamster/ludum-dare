package {
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.text.TextFieldAutoSize;
	import flash.net.SharedObject;
	import flash.geom.ColorTransform;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.display.Bitmap;
	import flash.media.Video;
	import flash.system.LoaderContext;
	import com.dobuki.Wall;
	import com.dobuki.IWall;
	import com.dobuki.events.WallEvent;
	import flash.geom.Rectangle;
	import flash.events.IOErrorEvent;

	
	public class Canvas extends Wall {
		
		public var distance:Number;
		static public var currentLoader:Loader = null;
		
		private var rect:Rectangle;
		
		public var bmp;
		private var prefix:String = "http://www.ludumdare.com/compo/ludum-dare-30/?action=preview&uid=";
		private var imgprefix:String = "";// "http://www.ludumdare.com/compo/wp-content/compo2/thumb/";
		private var LDID:String;
		static const colorTransform:ColorTransform = new ColorTransform(1,1,1,1,-150,-150,-150);
		static private var iconLoaders:Object = {};
		
		override public function initialize(room:String,id:String,...params):IWall {
			super.initialize.apply(this,[room,id].concat(params));

			rect = canvas.getRect(canvas);
			canvas.loadbutton.addEventListener(MouseEvent.CLICK,
				function(e) {
					loadURL(canvas.url_box.text,canvas.url_box.text);
				});
			//	image=null,caption=null,author=null,LDID=null,large=null,type=null,links:String=null):void {
			
			var image:String = params[0];
			var caption:String = params[1];
			var author:String = params[2];
			var LDID:String = params[3];
			var large:String = params[4];
			var type:String = params[5];
			var links:String = params[6];
			
				
			
			
			this.LDID = LDID;
			if(image) {
				canvas.visible = false;
				//trace(caption,image,large);
				loadURL(image,large && large.split(".").pop().toLowerCase()!="bmp"?large:null);//large);
			}
			if(caption) {
				caption_text.text = caption;
				caption_text.autoSize = TextFieldAutoSize.LEFT;
				caption_text.width = canvas.width;
				caption_text.scaleY = caption_text.scaleX;
			}
			if(author) {
				author_text.text = author;
			}
			if(type) {
				type_tf.text = type;
			}
			if(links) {
				var lnks:Array = JSON.parse(links) as Array;
				for(var i=0;i<5;i++) {
					var icono:MovieClip = this["link"+(i+1)];
					var pair:Array = lnks[i];
					if(pair) {
						icono.visible = true;
						icono.type_tf.text = pair[0];
						var domain:String = pair[1].split("?")[0].split("#")[0].split("://")[1].split("/")[0].toLowerCase();
						loadIcon(icono,domain);
					}
					else {
						icono.visible = false;
					}
				}
			}
			addEventListener(MouseEvent.CLICK,doVisit);
			addEventListener(Event.CHANGE,
				onChange =function(e:Event):void {
					setURL(image);
				});
			addEventListener(Event.ADDED_TO_STAGE,onChange);
			setVisited();
			return this;
		}
		
		
		
		private var onChange:Function;
		
		override public function recycle():void {
			super.recycle();
			distance = int.MAX_VALUE;
			removeEventListener(MouseEvent.CLICK,doVisit);
			if(onChange!=null) {
				removeEventListener(Event.CHANGE,onChange);
				removeEventListener(Event.ADDED_TO_STAGE,onChange);
			}
			onChange = null;
		}
		
		private function doVisit(e:MouseEvent):void {
			if(canvas.buttonMode) {
				navigateToURL(new URLRequest(prefix + LDID));
				var so:SharedObject = SharedObject.getLocal("Maze");
				if(!so.data["visited_"+LDID]) {
					so.setProperty("visited_"+LDID,true);
					setVisited();
					checkVisited();
					if(LDID=="20841") {
						Achievement.unlock(Achievement.JACK);
					}
				}
			}
		}
		
		private function loadIcon(icono:MovieClip,domain:String):void {
			var loader:Loader = iconLoaders[domain];
			if(!loader) {
//				iconLoaders[domain] = loader = new Loader();
//				loader.load(new URLRequest("http://www.google.com/s2/favicons?domain="+domain), new LoaderContext(true));
				loader = new Loader();
				loader.load(new URLRequest("http://www.google.com/s2/favicons?domain="+domain));
				icono.addChild(loader);
				loader.x = -16;
				return;
			}
			if(!loader.content) {
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE,
					function(e:Event):void {
						var bitmap:Bitmap = icono.addChild(new Bitmap((loader.content as Bitmap).bitmapData)) as Bitmap;
						icono.addChild(bitmap);
						bitmap.x = -16;
					});
				loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,trace);
			}
			else {
				var bitmap:Bitmap = new Bitmap((loader.content as Bitmap).bitmapData);
				icono.addChild(bitmap);
				bitmap.x = -16;
			}
		}
		
		public function checkVisited():void {
			var entries:Array = LudumMap.instance.entries;
			var so:SharedObject = SharedObject.getLocal("Maze");
			var count:int = 0;
			for each(var entry:Object in entries) {
				if(so.data["visited_"+entry.id]) {
					count++;
				}
			}
			if(count>=10) {
				Achievement.unlock(Achievement.TEN);
			}
			if(count>=entries.length/3) {
				Achievement.unlock(Achievement.THIRD);
			}
			if(count>=entries.length/2) {
				Achievement.unlock(Achievement.HALF);
			}
			if(count==entries.length) {
				Achievement.unlock(Achievement.ALL);
			}
			Achievement.postScore(count);
			progress.visible = true;
			clickToView.visible = true;
			progress.text = count+"/"+entries.length;
		}
		
		override public function moveTo(e:WallEvent):void {
			super.moveTo(e);
			canvas.buttonMode = e.distance<1;
			progress.visible = e.distance<1;
			clickToView.visible = e.distance<1;
			
			if(progress.visible) {
				checkVisited();
			}
			distance = e.distance;
		}
		
		private function setVisited():void {
			var so:SharedObject = SharedObject.getLocal("Maze");
			check.visible = so.data["visited_"+LDID];
			
//				transform.colorTransform = colorTransform;
		}

		override public function get recyclable():Boolean
		{
			return false;
		}
		
		override public function get canDraw():Boolean {
			return bmp;
		}
		
		static private var queue:Array = [];
		static private var loadCount:int = 0;
		
		static private function checkCompletion():void {
			if(queue.length) {
				queue.sort(compare);
				var pop:Array = queue.pop();
				var canvas:Canvas = pop[0];
				var url:String = pop[1];
				var url2:String = pop[2];
				var id:String = pop[3];
				canvas.loadURL(url,url2,id);
			}
		}
		
		static private function compare(q1:Array,q2:Array):int {
			var canvas1:Canvas = q1[0];
			var canvas2:Canvas = q2[0];
			return canvas1.distance>canvas2.distance?-1:canvas1.distance<canvas2.distance?1:0;
		}
		
		static private var loaders:Object = {};
		public function loadURL(url:String,url2:String=null,id:String=null) {
			if(!id) {
				id = url;
			}
			
			//trace(caption_text.text,url,url2);
			if(!loaders[url]) {
				if(currentLoader) {
					currentLoader.contentLoaderInfo.addEventListener(Event.COMPLETE,
						function(e:Event):void {
							loadURL(url,url2,id);
						});
					currentLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,
						function(e:IOErrorEvent):void {
							loadURL(url,url2,id);
						});
					return;
				}
				if(loadCount>=3) {
					queue.push([this,url,url2,id]);
					return;
				}
				
				loadCount++;
				var loader:Loader = new Loader();
				loaders[url] = loader;
				//currentLoader = loader;
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE,
					function(e) {
						loadCount--;
						checkCompletion();
						
						loaders[id] = loader;
//						currentLoader = null;
	//					trace(url,url2);
						loader.width = rect.width;
						loader.height = rect.height;
						if(loader.scaleX<loader.scaleY) {
							loader.scaleY = loader.scaleX;
						}
						else {
							loader.scaleX = loader.scaleY;
						}
						loader.x = rect.width/2-loader.width/2;
						loader.y = rect.height/2-loader.height/2;
	//					for(var i=canvas.numChildren-1;i>=0;i--) {
	//						canvas.removeChildAt(i);
	//					}
	//					canvas.addChild(loader);
	//					canvas.visible = true;
						dispatchEvent(new Event(Event.CHANGE));
	/*					try {
							if(loader.content is Bitmap) {
								(loader.content as Bitmap).smoothing = false;
								MovieClip(root).bmp = loader.content;
							}
						}
						catch(e) {				
							trace(e);
						}*/
						if(url2) {
							loader.removeEventListener(e.type,arguments.callee);
							loadURL(url2,null,id);
							return;;
						}
						
					},false,1);
				loader.load(new URLRequest(url));
			}
			
			
		}
		private function setURL(url:String):void {
			if(!loaders[url]) {
				return;
			}
					for(var i=canvas.numChildren-1;i>=0;i--) {
						canvas.removeChildAt(i);
					}
					//trace(url,loaders[url]);
					canvas.addChild(loaders[url]);
					canvas.visible = true;
		}
	}
	
}