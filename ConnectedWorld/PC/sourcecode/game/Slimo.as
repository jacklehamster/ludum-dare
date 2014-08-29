package  {
	
	import flash.display.MovieClip;
	import flash.media.Sound;
	import flash.media.SoundTransform;
	
	
	public class Slimo extends MovieClip {
		
		static private var jumpSound:Sound;
		
		public function Slimo() {

			if(!jumpSound) {
				jumpSound = new JumpSound();
			}
		}
		
		public function playJumpSound():void {
			if(parent.parent) {
				jumpSound.play(0,1,new SoundTransform(.1*parent.parent.scaleX/(Math.sqrt(parent.x*parent.x+parent.y*parent.y)/100+.5),parent.x/200));
			}
		}
	}
	
}
