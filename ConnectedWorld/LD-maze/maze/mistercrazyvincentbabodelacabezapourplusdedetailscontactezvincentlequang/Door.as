package {
	
	import flash.display.Loader;
	import flash.events.Event;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	import flash.display.MovieClip;
	import flash.display.Bitmap;
	
	public class Door extends MovieClip {
		public var worldurl = null;
		var bmp;
		public function initialize(room,id,url,image,label) {
//			trace(">>",room,id,url,image,label);
			if(image) {
				var loader = new Loader();
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE,
					function(e) {
						door.window.cover.visible = false;
						door.window.addChild(loader);
						loader.width = 100;
						loader.height = 100;
						if(loader.scaleX>loader.scaleY) {
							loader.scaleX = loader.scaleY;
						}
						else {
							loader.scaleY = loader.scaleX;
						}
//						loader.x = door.window.x+door.window.width/2-loader.width/2;
//						loader.y = door.window.y+door.window.height/2-loader.height/2;
						dispatchEvent(new Event(Event.CHANGE));
						try {
							if(loader.content is Bitmap) {
								(loader.content as Bitmap).smoothing = true;
								bmp = loader.content;
							}
						}
						catch(e) {				
						}
					});
				loader.load(new URLRequest(image),new LoaderContext(true));
			}
			else
				door.window.visible = false;
			door.tf.text = label;
			worldurl = url;
		}
		
		public function get canDraw():Boolean {
			return bmp;
		}
	}
}