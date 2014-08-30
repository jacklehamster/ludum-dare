package  {
	import flash.net.FileReference;
	import flash.filesystem.File;
	import flash.events.Event;
	import flash.net.FileFilter;
	import flash.utils.ByteArray;
	import flash.display.Loader;
	import flash.display.BitmapData;
	import flash.display.Bitmap;
	
	public class WebImageSelector implements IImageSelector {

		private var file:FileReference = new FileReference();
		private var callback:Function = null;
		
		public function WebImageSelector() {
			file.addEventListener(Event.SELECT,onSelect);
			file.addEventListener(Event.COMPLETE,onCompleted);
			file.addEventListener(Event.CANCEL,onCancel);
		}

		public function select(callback:Function):void
		{
			this.callback = callback;
			file.browse([new FileFilter("Images", "*.jpg;*.jpeg;*.gif;*.png;")]);
		}
		
		private function onSelect(e:Event):void {
			file.load();
		}
		
		private function onCompleted(e:Event):void {
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE,
				function(e:Event):void {
					var bitmapData:BitmapData = (loader.content as Bitmap).bitmapData;
					callback(bitmapData);
				});
			loader.loadBytes(file.data);
		}
		
		private function onCancel(e:Event):void {
			callback(null);
		}
	}
	
}
