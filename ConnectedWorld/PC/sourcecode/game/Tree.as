package  {
	
	import flash.display.MovieClip;
	import flash.media.Sound;
	import flash.media.SoundTransform;
	
	
	public class Tree extends MovieClip {
		
		
		static private var crunchSound:Sound;
		
		public function Tree() {

			if(!crunchSound) {
				crunchSound = new CrunchSound();
			}
		}
		
		public function playCrunchSound():void {
			if(parent) {
				crunchSound.play(0,1,new SoundTransform(.1*parent.scaleX/(Math.sqrt(x*x+y*y)/100+.5),x/200));
			}
		}
	}
	
}
