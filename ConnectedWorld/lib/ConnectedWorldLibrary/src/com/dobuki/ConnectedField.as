package com.dobuki
{
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.text.TextField;
	
	import by.blooddy.crypto.MD5;
	
	public class ConnectedField extends ConnectedWorld
	{
		public var scroll:Point = new Point();
		private var mpoint:Point,goal:Point;
		private var mouseSprite:Sprite = new Sprite();
		private var lastMouseUpdate:int;
		
		public function ConnectedField(canvas:Sprite, user_id:String)
		{
			super(canvas, user_id);
			stage.addEventListener(MouseEvent.MOUSE_DOWN,onMouseDown);
			stage.addEventListener(MouseEvent.MOUSE_MOVE,onMouseMove);
			setWorld(scroll.x,scroll.y);
			canvas.addChild(mouseSprite);
			mouseSprite.mouseChildren = mouseSprite.mouseEnabled = false;
		}
		
		public function setScroll(x:Number,y:Number):void {
			scroll.x = x;
			scroll.y = y;
			setWorld(scroll.x,scroll.y);
		}
		
		protected function onMouseDown(e:MouseEvent):void {
			mpoint = new Point(e.stageX,e.stageY);
			goal = new Point();
			
		}
		
		protected function onMouseMove(e:MouseEvent):void {
			if(goal) {
				if(e.buttonDown) {
					goal.x =  mpoint.x-e.stageX;
					goal.y =  mpoint.y-e.stageY;
				}
				else {
					goal = null;
				}
			}
			this.broadcast(new Point(canvas.mouseX+scroll.x,canvas.mouseY+scroll.y),user_id,"mouse",{x:canvas.mouseX+scroll.x,y:canvas.mouseY+scroll.y});
		}
		
		protected function getMousePoint():Point {
			return new Point(canvas.mouseX+scroll.x,canvas.mouseY+scroll.y);
		}
		
		override protected function display(canvas:Sprite):void {
			super.display(canvas);
			if(goal) {
				var dx:Number = goal.x;
				var dy:Number = goal.y;
				scroll.x += dx;
				scroll.y += dy;
				mpoint.x -= dx;
				mpoint.y -= dy;
				goal.x = 0;
				goal.y = 0;
				setWorld(scroll.x,scroll.y);
			}
/*			var scrollX:int = Math.round(scroll.x/10);
			var scrollY:int = Math.round(scroll.y/10);
			var SIZE:int = 10;
			for(var xi:int=-SIZE; xi<SIZE;xi++) {
				for(var yi:int=-SIZE; yi<SIZE; yi++) {
					var cell:Array = getCell(xi+scrollX,yi+scrollY);
					for each(var o:Object in cell) {
						var tf:TextField = canvas.getChildByName(o.id) as TextField;
						if(!tf) {
							tf = new TextField();
							tf.mouseEnabled = false;
							tf.name = o.id;
							tf.text = o.id;
							canvas.addChild(tf);
						}
						tf.x = +scroll.x+o.y*10;
						tf.y = +scroll.y+o.y*10;
					}
				}
			}
//			for each(var o:Object in 
			*/
		}
		
		private var md5s:Object = {};
		
		public function getCell(x:int,y:int):Array {
			var array:Array = md5s[x+","+y];
			if(!array) {
				var md5:String = ( MD5.hash(x+","+y));
				array = md5s[x+","+y] = [
					(uint) (parseInt(md5.substr(0,8),16)),
					(uint) (parseInt(md5.substr(8,8),16)),
					(uint) (parseInt(md5.substr(16,8),16)),
					(uint) (parseInt(md5.substr(24,8),16))
				];
			}
			return array[0]%100==0? [{id:array[0],x:x,y:y}] : null;
		}
		
		override protected function refresh():void {
			if(clock-lastMouseUpdate>10000) {
				mouseSprite.graphics.clear();
			}
		}
		
		
		override public function onAction(id:String,action:String,data:Object,user:String,world:World):void {
			switch(action) {
				case "mouse":
					if(id!=user_id) {
						mouseSprite.graphics.clear();
						mouseSprite.graphics.lineStyle(1,0,.5);
						mouseSprite.graphics.drawCircle(data.x-scroll.x,data.y-scroll.y,5);
						lastMouseUpdate = clock;
					}
					break;
				default:
					super.onAction(id,action,data,user,world);
			}
		}
		
		
	}
}