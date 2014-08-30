package  {
	import flash.display.Stage;
	import com.adobe.ane.stageAd.StageAdAlign;
	import com.adobe.ane.stageAd.StageBannerAd;
	
	public class IOSAdvertising {

		static private var instance:IOSAdvertising = new IOSAdvertising();
		
		private var ad:StageBannerAd;
		
		static public function showAd(stage:Stage):void {
			instance.showAd(stage);
		}

		private function showAd(stage:Stage):void {
			ad = new StageBannerAd();
			ad.stage = stage;
		}
		
		static public function get isSupported():Boolean {
			return StageBannerAd.isSupported;
		}
	}
	
}
