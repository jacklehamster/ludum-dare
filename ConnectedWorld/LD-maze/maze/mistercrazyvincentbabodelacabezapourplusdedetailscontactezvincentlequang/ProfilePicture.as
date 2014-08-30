package  {
	
	import flash.display.MovieClip;
	import flash.display.BitmapData;
	import flash.events.EventDispatcher;
	import flash.events.Event;
	import flash.display.Bitmap;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.geom.Matrix;
	
	
	public class ProfilePicture extends MovieClip {
		
		static private var dimension:Rectangle = null;
		static private var _shift:Point = new Point();
		static private var _bitmapData:BitmapData = null;
		static private var dispatcher:EventDispatcher = new EventDispatcher();
		private var bitmap:Bitmap = new Bitmap();
		
		public function ProfilePicture() {
			if(!dimension) {
				dimension = getRect(this);
			}
			scrollRect = dimension;
			addEventListener(Event.ADDED_TO_STAGE,onStage);
			addEventListener(Event.REMOVED_FROM_STAGE,offStage);
			addChild(bitmap);
		}
		
		private function onStage(e:Event):void {
			bitmap.bitmapData = _bitmapData;
			dispatcher.addEventListener(Event.CHANGE,onImageChange);
		}

		private function offStage(e:Event):void {
			dispatcher.removeEventListener(Event.CHANGE,onImageChange);
		}
		
		private function onImageChange(e:Event):void {
			if(bitmap.bitmapData!=_bitmapData) {
				bitmap.bitmapData = _bitmapData;
				if(_bitmapData) {
					var scale:Number = Math.max(
						dimension.width/_bitmapData.width,
						dimension.height/_bitmapData.height);
					bitmap.scaleX = bitmap.scaleY = scale;
				}
			}
			bg.visible = bitmap.bitmapData==null;
			bitmap.x = _shift.x;
			bitmap.y = _shift.y;
		}
		
		static public function backupBitmapData():BitmapData {
			var bitmapData:BitmapData = _bitmapData;
			_bitmapData = null;
			_shift = new Point();
			dispatcher.dispatchEvent(new Event(Event.CHANGE));
			return bitmapData;
		}

		static public function set bitmapData(value:BitmapData):void {
			var oldBitmapData:BitmapData = _bitmapData;
			_bitmapData = value;
			if(_bitmapData) {
				if(_bitmapData.transparent) {
					var temp:BitmapData = new BitmapData(_bitmapData.width,_bitmapData.height,false);
					temp.copyPixels(_bitmapData,_bitmapData.rect,new Point());
					_bitmapData.dispose();
					_bitmapData = temp;
				}
				var scale:Number = Math.max(
					dimension.width/_bitmapData.width,
					dimension.height/_bitmapData.height);
				_shift = new Point(dimension.width/2- _bitmapData.width*scale/2,dimension.height/2- _bitmapData.height*scale/2);
			}
			else {
				_shift = new Point();
			}
			dispatcher.dispatchEvent(new Event(Event.CHANGE));
			if(oldBitmapData) {
				oldBitmapData.dispose();
			}
		}
		
		static public function get bitmapData():BitmapData {
			return _bitmapData;
		}
		
		static public function shiftImage(dx:Number,dy:Number):void {
			if(_bitmapData) {
				var scale:Number = Math.max(
					dimension.width/_bitmapData.width,
					dimension.height/_bitmapData.height);
				_shift.x = Math.min(Math.max(_shift.x+dx,-scale*_bitmapData.width+dimension.width),0);
				_shift.y = Math.min(Math.max(_shift.y+dy,-scale*_bitmapData.height+dimension.height),0);
				dispatcher.dispatchEvent(new Event(Event.CHANGE));
			}
		}
		
		static public function get alignment():Point {
			return new Point(_shift.x/dimension.width,_shift.y/dimension.height);
		}
		
		static public function set alignment(value:Point):void {
			_shift = new Point(value.x*dimension.width,value.y*dimension.height);
			dispatcher.dispatchEvent(new Event(Event.CHANGE));
		}
	}
	
}
