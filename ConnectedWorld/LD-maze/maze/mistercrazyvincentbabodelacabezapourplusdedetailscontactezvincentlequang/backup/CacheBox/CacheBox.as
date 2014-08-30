package
{
	
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Rectangle;
	import flash.geom.Matrix;
	import flash.utils.getQualifiedClassName;
	
	public class CacheBox extends MovieClip
	{
		static var instances:Array = [];
		var images:Array = [];
		static var imgcache:Object = new Object();
		var currentimage:Bitmap = null;
		const MAXSIZE = 1000;
		var master:MovieClip = null;
		var imagecount:int;
		var sx,sy;
		var greenbox = null;
		var reinit = false;
		var imageindex:int = 0;
		
		function CacheBox()
		{
			//parent.removeChild(this);
			this.addEventListener(Event.ADDED_TO_STAGE,addedToStage);
			instances.push(this);
		}
		
		function addedToStage(e)
		{
			greenbox = getChildAt(0);
			master = parent as MovieClip;
			greenbox.scaleX = scaleX;
			greenbox.scaleY = scaleY;
			scaleX = scaleY = 1;
			initialize();
		}
		
		function initialize()
		{
			var subject = this.parent;
			sx = sy = 1;
			imagecount = 0;
			while(subject)
			{
				sx *= subject.scaleX;
				sy *= subject.scaleY;
				subject = subject.parent;
			}
			sx = Math.abs(int(sx*1000)/1000);
			sy = Math.abs(int(sy*1000)/1000);
				
			this.visible = false;
			master.visible = false;
			this.addEventListener(Event.ENTER_FRAME,update);
		}
		
		function get id()
		{
			return instances.indexOf(this);
		}
		
		function update(e)
		{
			var p:MovieClip = master;
			if(!images[p.currentFrame-1])
			{
				snapshot();
			}
		}
		
		static public function updateAll()
		{
			for(var i=0;i<instances.length;i++)
			{
				if(instances[i].imagecount==instances[i].master.totalFrames)
				{
					instances[i].dispose();
					instances[i].initialize();
				}
				else
				{
					instances[i].reinit = true;
				}
			}
		}
		
		function dispose()
		{
			imagecount = 0;
			for(var i=0;i<images.length;i++)
				removeChild(images[i]);
			images = [];
			addChild(greenbox);
			for(i=master.numChildren-1;i>=0;i--)
				if(master.getChildAt(i)!=this)						
					master.getChildAt(i).visible = true;
			master.play();
			removeEventListener(Event.ENTER_FRAME,refresh);
		}
		
		function snapshot()
		{
			var cacheid = getQualifiedClassName(master) +"_"+ master.currentFrame + "_"+sx+"_"+sy;
			var bitmapData = imgcache[cacheid];
			if(!bitmapData)
			{
				var rect:Rectangle = this.getRect(master);
				if(rect.width && rect.height)
				{
					imgcache[cacheid] = bitmapData = new BitmapData(rect.width/scaleX*sx,rect.height/scaleY*sy,true,0);
					var matrix:Matrix = new Matrix(1/scaleX*sx,0,0,1/scaleY*sy,-rect.x/scaleX*sx,-rect.y/scaleY*sy);
					bitmapData.draw(master,matrix);
				}
				else
				{
					return;
				}
			}
			var bmp = new Bitmap(bitmapData);
//			bmp.smoothing = true;
			bmp.scaleX = 1/sx;
			bmp.scaleY = 1/sy;
			images[master.currentFrame-1] = bmp;
			imagecount ++;
			if(imagecount==master.totalFrames)
			{
				this.removeEventListener(Event.ENTER_FRAME,update);
				removeChild(greenbox);
				this.visible = true;
				var i;
				master.gotoAndStop(1);
				for(i=master.numChildren-1;i>=0;i--)
					if(master.getChildAt(i)!=this)						
						master.getChildAt(i).visible = false;
				imageindex = int(Math.random()*images.length);
				for(i=0;i<images.length;i++)
				{
					images[i].visible = i==imageindex;
					addChild(images[i]);
				}
				master.visible = true;
				this.addEventListener(Event.ENTER_FRAME,refresh);
				if(reinit)
				{
					reinit = false;
					dispose();
					initialize();
				}
			}
		}
		
		function refresh(e)
		{
			images[imageindex].visible = false;
			imageindex = (imageindex+1)%images.length;
			images[imageindex].visible = true;
		}
	}
}