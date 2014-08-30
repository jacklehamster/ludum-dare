package  {
	
	import flash.display.MovieClip;
	
	
	public class Bullet extends MovieClip {
		
		static private var bin:Array = [];
		
		public function Bullet() {
			// constructor code
		}
		
		static public function create(x:Number,y:Number):Bullet {
			var bullet:Bullet = bin.pop();
			if(!bullet) {
				bullet = new Bullet();
			}
			bullet.x = x;
			bullet.y = y;
			return bullet;
		}
		
		static public function recycle(bullet:Bullet):Bullet {
			bin.push(bullet);
		}
	}
	
}
