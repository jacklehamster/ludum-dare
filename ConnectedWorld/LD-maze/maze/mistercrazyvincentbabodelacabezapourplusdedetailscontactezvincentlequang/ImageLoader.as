package  {
	import flash.display.MovieClip;
	import flash.display.Loader;
	import flash.net.URLRequest;
	import flash.events.Event;
	import flash.utils.ByteArray;
	import flash.geom.Point;
	
	public class ImageLoader extends MovieClip {

		var loader:Loader = new Loader(),alignment:Point;
		public function ImageLoader() {
			addChild(loader);
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE,onLoadImage);
			scrollRect = bg.getRect(this);
		}
		
		private function onLoadImage(e:Event):void {
			loader.visible = true;
			loader.width = bg.width;
			loader.height = bg.height;
			loader.scaleX = loader.scaleY = Math.max(loader.scaleX,loader.scaleY);
			loader.x = alignment.x*bg.width;
			loader.y = alignment.y*bg.height;
			bg.visible = false;
		}
		
		public function loadImage(bytes:ByteArray,url:String,alignment:Point):void {
			this.alignment = alignment;
			loader.visible = false;
			bg.visible = true;
			if(bytes && bytes.length) {
				loader.loadBytes(bytes);
			}
			else if(url) {
				loader.load(new URLRequest(url));
			}
		}

	}
	
}
