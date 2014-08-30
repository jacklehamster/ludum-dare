package {
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.utils.getTimer;

	public class Blob extends MovieClip{
		
		static var shiftX = 0,shiftY = 0;
		static var count:int = 0;
		var self;
		var xmov=0,ymov=0;
		var identity:int = 0;
		static var stack:Array = [];
		var following:Blob = null;
		var born = 0;
		function Blob() {
			mouseEnabled = mouseChildren = false;
			count++;
			self = this;
			born = getTimer();
			identity = int(Math.random()*400);
			gotoAndPlay(int(Math.random()*7)+1);
			addEventListener(Event.ENTER_FRAME,selfMove);
		}
		
		static function createBlob(follow:Blob,p):Blob {
			var b:Blob = null;
			if(!follow || follow.scaleX>.1) {
				b = stack.pop();
				if(!b && count<1000) {
					b = new Blob();
				}
				if(b) {
					b.born = getTimer();
					p.addChild(b);
					b.following = follow;
					b.scaleX = b.scaleY = follow.scaleX * .7;
					b.alpha = b.scaleX;
					b.gotoAndStop(1);
				}
			}
			return b;
		}
		
		function selfMove(e) {
			if(parent) {
				if(getTimer()-born>3000) {
					born = getTimer();
					createBlob(self,parent);
				}
				x+=xmov + shiftX;
				y+=ymov + shiftY;
				if(following) {
					if(!following.parent)
						following = null;
					else {
						var dx = x-following.x, dy= y-following.y;
						var dist:Number = Math.sqrt(dx*dx+dy*dy);
						if(dist>50) {
							x = following.x;
							y = following.y;
						}
						else {
							xmov = (following.x-x)*(Math.random()-.5);
							ymov = (following.y-y)*(Math.random()-.5);
						}
					}
				}
				else {
					if(scaleX<1) {
						scaleY = (scaleX *= 1.01);
						alpha = scaleX;
					}
					xmov = (xmov+Math.cos((y+identity)%400/10)-Math.random())*.9;
					ymov = (ymov+Math.sin((x+identity)%400/100)-(y-200)/500 + Math.random()-.5)*.9;
					if(x<-50) {
						x = 600;
						y = Math.random()*400;
						identity = int(Math.random()*400);
					}
				}
			}
		}
		
		public function damage() {
			gotoAndPlay("destroy");
		}
		
		public function destroy() {
			stack.push(this);
			var p = parent;
			p.removeChild(this);
		}
	}
}