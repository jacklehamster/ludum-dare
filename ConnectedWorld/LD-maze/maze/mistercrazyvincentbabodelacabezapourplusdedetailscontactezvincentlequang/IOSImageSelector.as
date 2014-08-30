package  {
	import flash.media.CameraRoll;
	import flash.media.CameraRollBrowseOptions;
	import flash.events.MediaEvent;
	
	public class IOSImageSelector implements IImageSelector {

		private var cameraRoll:CameraRoll;
		
		public function IOSImageSelector() {
			cameraRoll = new CameraRoll();
			cameraRoll.addEventListener(MediaEvent.SELECT,onMediaSelected);
			
		}

		public function select(callback:Function):void
		{
			trace(CameraRoll.supportsBrowseForImage);
			if(CameraRoll.supportsBrowseForImage)
			{
				cameraRoll.browseForImage();
			}			
		}
		
		private function onMediaSelected(e:MediaEvent):void {
			
		}

	}
	
}
