package
{
	import flash.display.Sprite
	import flash.filters.BlurFilter
	import flash.filters.GlowFilter
	import flash.utils.getQualifiedClassName
	import flash.utils.describeType
	import flash.utils.Dictionary
	import flash.display.MovieClip
	import flash.display.DisplayObject
	import flash.geom.Matrix
	import flash.display.Bitmap
	import flash.geom.Rectangle
	import flash.display.BitmapData
	import flash.events.Event
	import flash.utils.getTimer
	import flash.geom.Point
	import flash.events.MouseEvent;
	
	public class Scene3D extends MovieClip
	{
		var master:Sprite;
		public var projector:Sprite;
		var vs:Array;
		var bmpcache:Dictionary;
		public var projection:Dictionary;
		public var origin:Dictionary;
		var processQ:Array;
		var q:int;
		var globalframe:int;
		var _shift:Point;
		var _focus;
		var _click;
		const PRECISION:Number = 1;
		const MAGICNUMBER:int = 200;
		const DIMENSION = { MINX:-100,MAXX:100,MINY:-100,MAXY:69 };
		const CENTER = { X:0, Y:0 };
		static var bmpdstock:Dictionary = new Dictionary();
		
		function Scene3D()
		{
			this.mouseEnabled = this.mouseChildren = false;
			master = Sprite(this.parent);
			master.removeChild(this);
			
			projector = new Sprite();
			projector.x = x;
			projector.y = y;
			master.addChild(projector);
			
			bmpcache = new Dictionary();
			projection = new Dictionary();
			origin = new Dictionary();
			processQ = new Array();
			q = 0;
			vs = new Array();
			
			globalframe = 0;
			focus = null;
			_click = new Point();
			_shift = new Point();
			
			for(var yi=DIMENSION.MINY;yi<=DIMENSION.MAXY;yi++)
			{
				var v:Sprite = new Sprite();
				projector.addChild(v);
				var yzoo = (yi-DIMENSION.MINY+1)/100;
				//v.scaleX = v.scaleY = yzoo*yzoo;
				
				//v.y = (yi-DIMENSION.MINY+1)*v.scaleY*v.scaleY/10;
				v.alpha = yi>=0?1:(DIMENSION.MINY-yi)/DIMENSION.MINY;
				vs[yi-DIMENSION.MINY] = v;
			}
			
			addEventListener(Event.ENTER_FRAME,keepProcessing);
			play();
		}
		
		function keepProcessing(e:Event)
		{
			if(!processQ.length)
			{
				refresh();
				globalframe++;
				return;
			}
			if(q==processQ.length)
			{
				processQ = [];
				q = 0;
				refresh(true);
				dispatchEvent(new Event("doneprocessing"));
			}
			var starttimer:int = getTimer();
			while(q<processQ.length && getTimer()-starttimer<MAGICNUMBER)
			{
				var process:Array = processQ[q];
				var cache:Object = bmpcache[process[0]];
				var yi:int = process[1];
				var frame:int = process[2];
				var child:DisplayObject = process[3];
				var code:String = yi+"|"+frame;
				var mc:MovieClip = child as MovieClip;
				if(mc && frame!=mc.currentFrame)
					mc.gotoAndStop(frame);
				if(!cache[code])
				{
					var rect:Rectangle = child.getRect(child);
					//var scales:Array = //absoluteScale(vs[yi-DIMENSION.MINY]);
					var yzoo:Number = (yi-DIMENSION.MINY+1)/100;
					//sprite.scaleX = sprite.scaleY = yzoo;
			
					//trace(yzoo);
					var scales:Array = [ Math.min(MAGICNUMBER/rect.width,Math.max(2/rect.width,yzoo)), Math.min(MAGICNUMBER/rect.height,Math.max(2/rect.height,yzoo)) ];
					scales = [ Math.ceil(scales[0]*PRECISION)/PRECISION, Math.ceil(scales[1]*PRECISION)/PRECISION ];
					//trace(scales);
					var width:int = Math.round(rect.width*scales[0]);
					var height:int = Math.round(rect.height*scales[1]);
					var fary = Math.abs(yi);
					//trace(yi,fary,code,width,height);
					var blurvalue:int = fary>90?Math.ceil(fary*fary/1000):0;
					//child.filters = blurvalue?[ new BlurFilter(blurvalue,blurvalue) ]:[];
					var bmpd:BitmapData = getBitmapDataCache(process[0],frame,width,height,child,scales,rect);
					var bmp:Bitmap = new Bitmap(bmpd,"auto",true);
					bmp.x = rect.x;//Math.round(rect.x*scales[0]);
					bmp.y = rect.y;//Math.round(rect.y*scales[1]);
					bmp.width = rect.width;
					bmp.height = rect.height;
					//trace(bmp.width,bmp.height);
					//bmp.scaleX = 
					//bmp.scaleX = scales[0]*child.scaleX;
					//bmp.scaleY = 1/scales[1];
					//trace(bmp.scaleX);
//					bmp.scaleX = 1/scales[0];//width/rect.width;//scales[0]*child.scaleX;
//					bmp.scaleY = 1/scales[1];//height/rect.height;//1/scales[1];
					//bmp.scaleX = 1/scales[0];
					//bmp.scaleY = 1/scales[1];
					
					
					cache[code] = [bmp];
					produceBitmap(cache[code],yi);
				}
				q++;
			}
		}
		
		static function getBitmapDataCache(id,frame:int,width:int,height:int,child:DisplayObject,scales:Array,rect:Rectangle):BitmapData
		{
			var stock = bmpdstock[id];
			if(!stock)
			{
				stock = bmpdstock[id] = new Object();
			}
			var code:String = frame+"|"+width+"|"+height;
			if(!stock[code])
			{
				var bmpd:BitmapData = new BitmapData(width,height,true,0);
				bmpd.draw(child,new Matrix(scales[0],0,0,scales[1],-rect.x*scales[0],-rect.y*scales[1]),null,null,null,true);
				stock[code] = bmpd;
			}
			return stock[code];
		}
		
		function absoluteScale(clip:DisplayObject):Array
		{
			var scale = [ 1,1 ];
			while(clip)
			{
				scale[0] *= clip.scaleX;
				scale[1] *= clip.scaleY;
				clip = clip.parent;
			}
			return scale;
		}

		function refreshChild(child:DisplayObject,sync:Boolean)
		{
			var mc:MovieClip = child as MovieClip;
			if(mc && sync)
				mc.gotoAndPlay(1);
			var frame:int =mc?mc.currentFrame:0;// globalframe % mc.totalFrames + 1;
			var yline:int = Math.round(-_shift.y+child.y);
			var code:String = yline+"|"+frame;
			var sprite:Sprite;
			var projectioninfo:Object = projection[child];
					

			if(!projectioninfo)
			{
				projectioninfo = projection[child] = { code:null, sprite:null };
			}
			else if(code==projectioninfo.code)
			{
				//	move projection aling X-axis
				sprite = projectioninfo.sprite;
				if(sprite)
				{
//					if(sprite.scaleX*child.scaleX<0)
//						sprite.scaleX = -sprite.scaleX;
					sprite.x = (-_shift.x + child.x)*sprite.scaleX;
				}
				return;
			}
			
			var className:String = getQualifiedClassName(child);
			var id:Object = className.indexOf("flash")==0?child:className;
			var cache:Object = bmpcache[id];
			
			if(!cache)
			{
				for(var n=DIMENSION.MINY;n<=DIMENSION.MAXY;n++)
				{
					if(mc)
						for(var f=mc.totalFrames;f>=1;f--)
							processQ.push([id,n,f,child]);
					else
						processQ.push([id,n,0,child]);
				}
				bmpcache[id] = {};
			}
			else
			{
				if(projectioninfo.sprite)
				{
					projectioninfo.sprite.visible = false;
					cache[projectioninfo.code].push(projectioninfo.sprite);
				}
				
				var stagePoint:Point = localToGlobal(world2screen(child));
				var spritearray:Array = cache[code];
				if(mc.visible && spritearray && spritearray.length && yline>DIMENSION.MINY && stagePoint.x>0 && stagePoint.x<master.stage.stageWidth && stagePoint.y>0 && stagePoint.y-spritearray[0].height*vs[vs.length-1].scaleY<master.stage.stageHeight)//&& yline>=DIMENSION.MINY && yline<=DIMENSION.MAXY)
				{
					//trace(code,yline);
					if(spritearray.length<2)
						produceBitmap(spritearray,yline);
					sprite = spritearray.pop();
					projectioninfo.sprite = sprite;
					projectioninfo.code = code;
//					if(sprite.scaleX*child.scaleX<0)
//						sprite.scaleX = -sprite.scaleX;
					sprite.x = (-_shift.x+child.x)*sprite.scaleX;
					origin[sprite.getChildAt(0)] = child;
					sprite.visible = true;
				}
				else
				{
					projectioninfo.code = null;
					projectioninfo.sprite = null;
				}
			}
		}
		
		function produceBitmap(spritearray:Array,yline:int)
		{
			var bmptemplate:Bitmap = spritearray[0];
			var bmp:Bitmap = new Bitmap(bmptemplate.bitmapData,"auto",true);
			bmp.x = bmptemplate.x;
			bmp.y = bmptemplate.y;
			bmp.scaleX = bmptemplate.scaleX;
			bmp.scaleY = bmptemplate.scaleY;
			var sprite:Sprite = new Sprite();
			var yzoo = (yline-DIMENSION.MINY+1)/100;
			sprite.scaleX = sprite.scaleY = yzoo;
			sprite.addChild(bmp);
			sprite.y = (yline-DIMENSION.MINY+1)*sprite.scaleY*sprite.scaleY;
			//var yzoo = (yi-DIMENSION.MINY+1)/100;
				//v.scaleX = v.scaleY = yzoo*yzoo;
				
				//v.y = (yi-DIMENSION.MINY+1)*v.scaleY*v.scaleY/10;
			
			//var fary = Math.abs(CENTER.Y-yline-DIMENSION.MINY+1);
			//var blurvalue:int = fary>10?fary*fary/200:0;
			//if(blurvalue)
				//sprite.filters = [ new BlurFilter(blurvalue,blurvalue) ];
			//trace(sprite.scaleX);
			vs[yline-DIMENSION.MINY].addChild(sprite);
			//sprite.cacheAsBitmap = true;
			sprite.visible = false;
			spritearray.push(sprite);
		}
		
		public function world2screen(point):Point
		{
			var yscale = (point.y-_shift.y-DIMENSION.MINY+1)/MAGICNUMBER;
			return new Point((point.x-_shift.x)*yscale,(point.y-_shift.y-DIMENSION.MINY+1)*yscale);
		}
		
		public function screen2world(point):Point
		{
			return new Point(point.x * Math.sqrt(MAGICNUMBER/Math.max(1,point.y)) + _shift.x,Math.sqrt(Math.max(1,point.y)*MAGICNUMBER)+_shift.y+DIMENSION.MINY+1);
		}

		public function refresh(sync:Boolean = false)
		{
			for(var i=0;i<numChildren;i++)
			{
				refreshChild(getChildAt(i),sync);
			}
			if(_focus && _focus.x+_shift.x!=0 && _focus.y+_shift.y!=0)
			{
				_shift.x += Math.round((CENTER.X+_focus.x - _shift.x)/5);
				_shift.y += Math.round((CENTER.Y+_focus.y - _shift.y)/5);
			}
		}
		
		public function get underMouse():DisplayObject
		{
			var array:Array = projector.getObjectsUnderPoint(new Point(master.stage.mouseX,master.stage.mouseY));
			for(var i=array.length-1;i>=0;i--)
			{
				if(array[i] is Bitmap)
					if(array[i].bitmapData.getPixel32(array[i].mouseX,array[i].mouseY))
						return array[i];
			}
			return null;
		}
		
		public function set focus(subject):void
		{
			if(subject==null)
			{
				_focus = new Point();
				master.stage.addEventListener(MouseEvent.MOUSE_MOVE,mouseMoveForSlide);
				master.stage.addEventListener(MouseEvent.MOUSE_DOWN,mouseDownForSlide);
			}
			else
			{
				_focus = subject;
				master.stage.removeEventListener(MouseEvent.MOUSE_MOVE,mouseMoveForSlide);
				master.stage.removeEventListener(MouseEvent.MOUSE_DOWN,mouseDownForSlide);
			}
		}
		
		public function get focus()
		{
			return _focus;
		}
		
		public function get center()
		{
			return _shift;
		}
		
		function mouseMoveForSlide(e:MouseEvent)
		{
			if(e.buttonDown)
			{
				_focus.x += (_click.x-mouseX)*2;
				_focus.y += (_click.y-mouseY)/2;
				_click.x = mouseX;
				_click.y = mouseY;
				e.updateAfterEvent();
			}
		}
		
		function mouseDownForSlide(e:MouseEvent)
		{
			var sprite = origin[underMouse];
			if(sprite)
			{
				sprite.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_DOWN));
			}
			else
			{
				_click.x = mouseX;
				_click.y = mouseY;
			}
		}

		public function get code():String
		{
			var str = "";
			str += _shift + "\n";
			for(var i=0;i<numChildren;i++)
			{
				str += getQualifiedClassName(getChildAt(i)) + "," + Math.round(getChildAt(i).x) + "," + Math.round(getChildAt(i).y) + "," + getChildAt(i).scaleX + "\n";
				//str += getChildAt(i).loaderInfo.url + ",";
			}
			return str;
		}
	}
}