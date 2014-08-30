package {
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.utils.getTimer;
	import flash.filters.GlowFilter;
	
	public class Astero extends MovieClip {
		
		var mdown:Boolean = false;
		var missiles:Array = [];
		var cooldown:int = 50;
		var lastshoot:int = 0;
		
		
		function Astero() {
			
			addEventListener(Event.ENTER_FRAME,selfControl);
			stage.addEventListener(MouseEvent.MOUSE_DOWN,mouseHandle);
			stage.addEventListener(MouseEvent.MOUSE_UP,mouseHandle);
			
		}
		
		function mouseHandle(e) {
			mdown = e.type==MouseEvent.MOUSE_DOWN;
			if(mdown) {
				shoot(true);
			}
		}
		
		function checkCollision(missile:Missile) {
			var p = parent;
			for(var i=0;i<p.numChildren;i++) {
				var blob = p.getChildAt(i) as Blob;
				if(blob) {
					if(missile.x<blob.x && Math.abs(missile.y-blob.y)<blob.height/2 && blob.x<600) {
						blob.damage();
					}
				}
			}
		}
		
		function shoot(force:Boolean = false) {
			if(force || getTimer()-lastshoot>cooldown) {
				lastshoot = getTimer();
				var p = parent;
				var m = missiles.length?missiles.pop():null;
				if(!m) {
					m = new Missile();
					m.filters = [new GlowFilter()];
					m.onEnd = function() {
						p.removeChild(this);
						missiles.push(this);
					}
					m.onLine = function() {
						checkCollision(this);
					}
				}
				p.addChild(m);
				m.x = x;
				m.y = y;
			}
		}
		
		function selfControl(e) {
			var p = parent;
			var speed = .5;
			x = p.mouseX * speed + (1-speed) * x;
			y = p.mouseY * speed + (1-speed) * y;
			Blob.shiftX = -mouseX/2;
			Blob.shiftY = -mouseY/2;
			if(mdown)
				shoot();
		}
	}
}