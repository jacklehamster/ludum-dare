package  {
	
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	import flash.display.Bitmap;
	import flash.geom.Rectangle;
	
	
	public class CanvasInner extends MovieClip {
		
		private var rect:Rectangle;
		private static var currentLoader:Loader = null;
		
		public function CanvasInner() {
			rect = getRect(this);
			loadbutton.addEventListener(MouseEvent.CLICK,
				function(e) {
					loadURL(url.text,url.text);
				});
		}

		public function loadURL(url:String,url2:String=null) {
			if(currentLoader) {
				currentLoader.contentLoaderInfo.addEventListener(Event.COMPLETE,
					function(e:Event):void {
						loadURL(url,url2);
					});
				return;
			}
			
			var loader:Loader = new Loader();
			currentLoader = loader;
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE,
				function(e) {
					currentLoader = null;
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
					for(var i=numChildren-1;i>=0;i--) {
						removeChildAt(i);
					}
					addChild(loader);
					visible = true;
					MovieClip(parent).dispatchEvent(new Event(Event.CHANGE));
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
						loadURL(url2);
						return;;
					}
				},false,1);
			loader.load(new URLRequest(url));
		}
	}
	
}
