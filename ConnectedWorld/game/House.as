package  {
	
	import flash.display.MovieClip;
	import flash.media.Sound;
	import flash.media.SoundTransform;
	
	
	public class House extends MovieClip {
		
		
		static private var kissSound:Sound;
		
		public function House() {

			if(!kissSound) {
				kissSound = new KissSound();
			}
		}
		public function playKissSound():void {
			if(parent) {
				kissSound.play(0,1,new SoundTransform(.1*parent.scaleX/(Math.sqrt(x*x+y*y)/100+.5),x/200));
			}
		}
	}
	
}
