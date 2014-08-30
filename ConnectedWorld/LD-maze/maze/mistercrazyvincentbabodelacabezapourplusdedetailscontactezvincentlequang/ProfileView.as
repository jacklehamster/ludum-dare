package  {
	
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.system.Capabilities;
	import flash.system.TouchscreenType;
	import flash.display.BitmapData;
	import flash.display.Bitmap;
	import flash.geom.Rectangle;
	import flash.geom.Point;
	import flash.media.Camera;
	import flash.events.Event;
	import flash.media.Video;
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;
	
	
	public class ProfileView extends MovieClip {
		
		private var imageSelector:IImageSelector,
			point:Point = null,video:Video,camera:Camera,
			bitmapDataBackup:BitmapData = null, originalPicture:BitmapData = null, originalAlignment:Point = null;
		
		public function ProfileView() {
			profile.buttonMode = true;
			rollIcon.addEventListener(MouseEvent.CLICK,onRoll);
			cameraIcon.addEventListener(MouseEvent.CLICK,onCamera);
			profile.addEventListener(MouseEvent.MOUSE_DOWN,mouseDown);
			defaultIcon.addEventListener(MouseEvent.CLICK,onDefaultProfile);
			tf.addEventListener(KeyboardEvent.KEY_DOWN,onKey);
			addEventListener(MouseEvent.CLICK,namePromptClick);
		}
		
		public function imageHasChanged():Boolean {
			return originalPicture!=ProfilePicture.bitmapData;
		}

		public function alignmentHasChanged():Boolean {
			return imageHasChanged()||!ProfilePicture.alignment.equals(originalAlignment);
		}

		private function namePromptClick(e:MouseEvent):void {
			if(e.target==profileBg) {
				validateName();
			}
		}
		
		private function validateName():void {
			if(tf.text.length>=3) {
				visible = false;
				dispatchEvent(new Event(Event.CHANGE));
			}
			else {
				mini.visible = true;
			}
		}
		
		private function onKey(e:KeyboardEvent):void {
			if(e.keyCode==Keyboard.ENTER) {
				validateName();
			}
		}
		
		
		override public function set visible(value:Boolean):void {
			super.visible = value;
			if(!visible) {
				stopCamera();
				clearDefault();
			}
			else {
				originalPicture = ProfilePicture.bitmapData;
				originalAlignment = ProfilePicture.alignment.clone();
				defaultIcon.gotoAndStop(ProfilePicture.bitmapData==null?2:1);
				mini.visible = false;
				stage.focus = tf;
				tf.setSelection(0,tf.length);
			}
		}
		
		private function onRoll(e:MouseEvent):void {
			if(Capabilities.touchscreenType==TouchscreenType.NONE) {
				stopCamera();
				rollIcon.gotoAndStop(2);
				imageSelector = new WebImageSelector();
				imageSelector.select(imageLoaded);
			}
			e.preventDefault();
			e.stopImmediatePropagation();
		}
		
		private function onCamera(e:MouseEvent):void {
			if(camera) {
				stopCamera();
			}
			else {
				clearDefault();
				
				camera = Camera.getCamera();
				video = new Video(camera.width,camera.height);
				video.attachCamera(camera);
				var bitmapData:BitmapData = new BitmapData(camera.width,camera.height,false);			
				ProfilePicture.bitmapData = bitmapData;
				camera.addEventListener(Event.VIDEO_FRAME,onVideoFrame);
				cameraIcon.gotoAndStop(2);
				defaultIcon.gotoAndStop(ProfilePicture.bitmapData==null?2:1);
			}
			e.preventDefault();
			e.stopImmediatePropagation();
		}
		
		private function stopCamera():void {
			if(camera) {
				camera.removeEventListener(Event.VIDEO_FRAME,onVideoFrame);
				video.attachCamera(null);
				cameraIcon.gotoAndStop(1);
				camera = null;
				video = null;
			}
		}
		
		private function onVideoFrame(e:Event):void {
			ProfilePicture.bitmapData.draw(video);
		}
		
		private function mouseDown(e:MouseEvent):void {
			point = new Point(e.stageX,e.stageY);
			stage.addEventListener(MouseEvent.MOUSE_MOVE,onDrag);
			stage.addEventListener(MouseEvent.MOUSE_UP,release);
		}
		
		private function onDrag(e:MouseEvent):void {
			if(e.buttonDown) {
				ProfilePicture.shiftImage(e.stageX-point.x,e.stageY-point.y);
				point.x = e.stageX;
				point.y = e.stageY;
			}
		}
		
		private function release(e:MouseEvent):void {
			stage.removeEventListener(MouseEvent.MOUSE_MOVE,onDrag);
			stage.removeEventListener(MouseEvent.MOUSE_UP,release);
		}
		
		private function clearDefault():void {
			if(bitmapDataBackup) {
				bitmapDataBackup.dispose();
				bitmapDataBackup = null;
				defaultIcon.gotoAndStop(ProfilePicture.bitmapData==null?2:1);
			}
		}
		
		private function onDefaultProfile(e:MouseEvent):void {
			if(bitmapDataBackup) {
				ProfilePicture.bitmapData = bitmapDataBackup;
				defaultIcon.gotoAndStop(1);
				bitmapDataBackup = null;
			}
			else if(ProfilePicture.bitmapData) {
				defaultIcon.gotoAndStop(2);
				stopCamera();
				bitmapDataBackup = ProfilePicture.backupBitmapData();
			}
			e.preventDefault();
			e.stopImmediatePropagation();
		}
		
		private function imageLoaded(bitmapData:BitmapData):void {
			rollIcon.gotoAndStop(1);
			if(bitmapData) {
				clearDefault();
				ProfilePicture.bitmapData = bitmapData;
				defaultIcon.gotoAndStop(ProfilePicture.bitmapData==null?2:1);
			}
		}
	}
	
}
