package {
	import flash.display.MovieClip;
	import flash.geom.Matrix;
	import flash.events.Event;
	import flash.display.DisplayObject;
	import flash.geom.Rectangle;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.utils.Dictionary;
	import flash.display.LoaderInfo;
	import flash.display.Loader;
	
	dynamic public class Block extends MovieClip {
		
		var position:Object = {x:0,y:0,h:0,type:""};
		var bmp:Bitmap = new Bitmap();
		
		function Block() {
			if(getChildByName("hitarea")) {
				hitArea = this.hitarea;
				mouseChildren = false;
			}
			addEventListener(Event.RENDER,render);
		}
		
		public function set posx(value:Number) {
			position.x = value;
			if(stage) stage.invalidate();
		}
		public function set posy(value:Number) {
			position.y = value;
			if(stage) stage.invalidate();
		}
		public function set posh(value:Number) {
			position.h = value;
			if(stage) stage.invalidate();
		}
		public function set size(value:Number) {
			position.size = value;
			if(stage) stage.invalidate();
		}
		public function set type(value:String) {
			position.type = value;
			if(stage) stage.invalidate();
		}

		public function get posx():Number {
			return position.x;
		}
		public function get posy():Number {
			return position.y;
		}
		public function get posh():Number {
			return position.h;
		}
		public function get size():Number {
			return position.size?position.size:1;
		}
		public function get type():String {
			return position.type;
		}
		
		public function clear():void {
			var harea = getChildByName("hitarea");
			if(harea)
				harea.visible = false;
			for(var i=numChildren-1;i>=0;i--) {
				var child = getChildAt(i);
				if(child!=harea) {
					removeChildAt(i);
				}
			}
		}

		static public function clearCache(mc:DisplayObject):void {
			if(cache[mc]) {
				for(var t in cache[mc]) {
					cache[mc][t].dispose();
					delete cache[mc][t];
				}
				delete cache[mc];
			}
		}
		
		public function place(mc:DisplayObject):void {
			addChild(mc);
		}
		
		static var cache:Dictionary = new Dictionary();
		public function draw(mc:DisplayObject,isLoader:Boolean=false):void {
			if(!isLoader)
				clear();
			if(isLoader && !(mc as MovieClip).numChildren)
				return;
			var flip:int = type=="R"||type=="U"?1:0;
			var bmpd2:BitmapData = null;
			if(cache[mc] && cache[mc][type]) {
				bmpd2 = cache[mc][type];
			}
			else {
				//	draw image
				var loader:Loader = isLoader?((mc as MovieClip).getChildAt(0) as Loader):null;
				var rect:Rectangle = isLoader?new Rectangle(
							-loader.contentLoaderInfo.width/2*loader.scaleX,
							-loader.contentLoaderInfo.height*loader.scaleY,
							loader.contentLoaderInfo.width*loader.scaleX,
							loader.contentLoaderInfo.height*loader.scaleY):mc.getRect(mc);
				var bmpd:BitmapData = null;
				if(type&&type!="F"&&type!="B") {
					if(type=="L"||type=="R") {
						bmpd = new BitmapData(rect.height,rect.width,true,0);
						bmpd.draw(mc,new Matrix(0,1,1,0,-rect.y,-rect.x),null,null,null,true);
					}
					else if(type=="U"||type=="D") {
						bmpd = new BitmapData(rect.width,rect.height,true,0);
						bmpd.draw(mc,new Matrix(1,0,0,1,-rect.x,-rect.y),null,null,null,true);
					}
					bmpd2 = new BitmapData(400,200,true,0);
					var bscaleX:Number = bmpd2.width/bmpd.width;
					var bscaleY:Number = bmpd2.height/bmpd.height;
					var factor:Number = .5;
					bmpd2.lock();
					for(var yi=0;yi<bmpd2.height;yi++) {
						var hpart:Number = (1+yi/bmpd2.height)*factor;
						var hshift:Number = (1-hpart)*bmpd2.width/2;
						for(var xi=0;xi<bmpd2.width*hpart;xi++) {
							var pix:uint = bmpd.getPixel32(xi/bscaleX/hpart,(flip?bmpd2.height-yi:yi)/bscaleY);
							bmpd2.setPixel32(xi+hshift,yi,pix);
						}
					}
					bmpd2.unlock();
					bmpd.dispose();
				}
				else {
					bmpd2 = new BitmapData(200,200,true,0);
					bscaleX = bmpd2.width/rect.width;
					bscaleY = bmpd2.height/rect.height;
					var bscale = bscaleX>bscaleY?bscaleY:bscaleX;
					bmpd2.draw(mc,new Matrix(bscale,0,0,bscale,-rect.x*bscaleX,-rect.y*bscaleY),null,null,null,true);
				}
				if(!cache[mc])
					cache[mc] = {};
				cache[mc][type] = bmpd2;
			}
			bmp.bitmapData = bmpd2;
			if(!type||type=="F"||type=="B") {
				bmp.width = bmp.height = 100;
				bmp.y = -bmp.height;
			}
			else {
				bmp.width = 200;
				bmp.height = 100;
			}
			bmp.x = -bmp.width/2;
			if(bmp.parent!=this)
				addChild(bmp);
		}
		
		function render(e:Event):void {
			var xfactor:Number 	= posx;
			var yfactor:Number 	= -posh;
			var scale:Number 	= Math.pow(.5,posy-1.5);
			
			switch(type) {
				case "L": case "R":
					transform.matrix = new Matrix(
						0,scale*size,xfactor*scale*size,yfactor*scale*.5*size,
						xfactor*100*scale,(scale*yfactor)*100*.5);
					break;
				case "D": case "U":
					transform.matrix = new Matrix(
						scale*size,0,xfactor*scale*size,yfactor*scale*.5*size,
						xfactor*100*scale,(scale*yfactor)*100*.5);
					break;
				default:
					transform.matrix = new Matrix(
						scale*size,0,0,scale*size,
						xfactor*100*scale,(scale*(yfactor+1))*100*.5);
					break;
			}
		}
	}
}