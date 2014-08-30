package {
	
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.utils.Dictionary;
	import flash.geom.Rectangle;
	import flash.geom.Matrix;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.utils.getTimer;
	
	public class Optimo extends Sprite {
		
		static var cloptima:Dictionary = new Dictionary();
		static var optima:Dictionary = new Dictionary(true);
		
		function Optimo() {
			var self:Optimo = this;
			if(parent) {
				initialize(null);
			}
			else {
				this.addEventListener(Event.ADDED_TO_STAGE,initialize);
			}
			function initialize(e:Event) {
				while(numChildren)
					removeChildAt(0);
				optimize(parent as Sprite);
			}
		}
		
		static public function optimize(master:Sprite) {
			if(!optima[master]) {
				master.addEventListener(Event.RENDER,rescale);
			}
			if(!optima[master] || isMonoFrame(master)) {
				master.addEventListener(Event.ENTER_FRAME,refresh);
			}
		}
		
		static function isMonoFrame(master:Sprite) {
			var mc:MovieClip = master as MovieClip;
			return !mc || mc.totalFrames==1;
		}
		
		static public function reset(master:Sprite) {
			var optim:Object = optima[master];
			if(optim && optim.image) {
				master.removeChild(optim.image);
				optim.cachebox[optim.frame].push(optim.image);
				optim.image = null;
			}
			getOptima(master,true);
			if(isMonoFrame(master))
				optimize(master);
			master.dispatchEvent(new Event(Event.ENTER_FRAME));
		}
		
		static function absoluteScales(mc:DisplayObject):Array {
			var m:Array = [Math.abs(mc.scaleX),Math.abs(mc.scaleY)];
			if(mc.parent) {
				var mparent:Array = absoluteScales(mc.parent);
				m[0] *= mparent[0];
				m[1] *= mparent[1];
			}
			return m;
		}
		
		static function getCloptima(master:Sprite):Object {
			var con:Class = (master as Object).constructor;
			var cloptim:Object = cloptima[con];
			if(!cloptim) {
				cloptim = cloptima[con] ={cachestore:{},nextframes:[]};
				var mc:MovieClip = master as MovieClip;
				var nextframes:Array = cloptim.nextframes;
				if(!mc) {
					nextframes[0] = nextframes[1] = 1;
				}
				else {					
					mc.stop();
					for(var i=1;i<=mc.totalFrames;i++) {
						mc.addFrameScript(i-1,null);
					}
					
					var labels:Array = mc.currentLabels;
					var preframe:int = 1;
					for(i=0;i<labels.length;i++) {
						var frame:int = labels[i].frame;
						nextframes[frame-1] = preframe;
						preframe = frame;
						mc.addFrameScript(frame-1,mc.stop);
					}
					nextframes[mc.totalFrames] = preframe;
					for(i=0;i<nextframes.length;i++) {
						if(!nextframes[i])
							nextframes[i] = i+1;
					}
				}
			}
			return cloptim;
		}
		
		static function getOptima(master:Sprite,doReset:Boolean=false):Object {
			var optim:Object = doReset?null:optima[master];
			if(!optim) {
				var cloptim:Object = getCloptima(master);
				var m:Array = absoluteScales(master);
				var cachebox:Array = cloptim.cachestore[m]?cloptim.cachestore[m]:cloptim.cachestore[m]=[];
				optim = optima[master] = { 
					scales:m,
					frame:0,freezeframe:0,
					cachebox:cachebox,image:null,
					nextframes:cloptim.nextframes };
			}
			return optim;
		}
		
		static public function setNext(mc:MovieClip,frame,nextframe):void {
			var optim = getOptima(mc);
			if(isNaN(frame) || isNaN(nextframe)) {
				var labels = mc.currentLabels;
				for(var i=0;i<mc.currentLabels;i++) {
					if(labels[i].name==frame) {
						frame = labels[i+1]?labels[i+1].frame-1:mc.totalFrames;
					}
					if(labels[i].name==nextframe) {
						nextframe = labels[i].frame;
					}
				}
			}
			if(isNaN(frame) || isNaN(nextframe) || frame<1 || nextframe<1 || frame>mc.totalFrames || nextframe>mc.totalFrames)
				return;
			optim.nextframes[frame] = nextframe;
		}
		
		static function setVisible(master:Sprite,value:Boolean,exception=null):void {
			for(var i=0;i<master.numChildren;i++) {
				var child:DisplayObject = master.getChildAt(i);
				if(child && exception!=child)
					child.visible = value;
			}
		}
		
		static public function getFrame(mc:MovieClip) {
			var optim = getOptima(mc);
			return optim.frame;
		}

		static public function getLabel(mc:MovieClip) {
			var optim = getOptima(mc);
			var labels = mc.currentLabels;
			var i=0;
			for(i=0;i<labels.length;i++) {
				if(labels[i].frame>optim.frame) {
					break;
				}
			}
			return labels[i-1]?labels[i-1].name:null;
		}
		
		static function cleanCache() : Boolean {
			var disposables:Array = [];
			for(var con in cloptima) {
				var cloptim:Object = cloptima[con];
				var cachestore:Object = cloptim.cachestore;
				for(var m in cachestore) {
					var cachebox:Array = cachestore[m];
					for(var frame:int=1;frame<cachebox.length;frame++) {
						var caches:Array = cachebox[frame];
						if(caches) {
							var cacheinfo:Object = caches[0];
							if(cacheinfo.instances==caches.length-1) {
								disposables.push(cacheinfo);
							}
						}
					}
				}
			}
			
			if(!disposables.length) {
				return false;
			}
			//	dispose of the oldest cacheinfo
			disposables.sortOn("lastused",Array.NUMERIC);
			cacheinfo = disposables[0];
			trace(disposables.length,getTimer()-cacheinfo.lastused,disposables[1]?getTimer()-disposables[1].lastused:0,cacheinfo.model.length);
			caches = cacheinfo.cachebox[cacheinfo.frame];
			var model:Array = cacheinfo.model;
			var bmp:Bitmap;
			for(var i=0;i<model.length;i++) {
				bmp = model[i] as Bitmap;
				bmp.bitmapData.dispose();
			}
			delete cacheinfo.cachebox[cacheinfo.frame];
			return true;
		}
		
		static function createBitmapData(w:int,h:int,transparent:Boolean=true,fillColor:uint=0):BitmapData {
			var bmpd:BitmapData;
			var cleaned:Boolean = false;
			
			do {
				try {
					bmpd = new BitmapData(w,h,transparent,fillColor);
				}
				catch(e) {
					cleaned = cleanCache();
				}
			} while(!bmpd && cleaned);
			return bmpd;
		}

		static const TILESIZE:int = 360;
		
		static function rescale(e:Event):void {
			var master:Sprite = e.currentTarget as Sprite;
			var scales:Array = absoluteScales(master);
			var optim:Object = getOptima(master);
			if(scales.toString()!=optim.scales.toString()) {
				reset(master);
			}
		}
		
		static function refresh(e:Event):void {
			var master:Sprite = e.currentTarget as Sprite;
			var mc:MovieClip = master as MovieClip;
			var optim:Object = mc.optim?mc.optim:mc.optim = getOptima(master);
			var cachebox:Array = mc.cachebox?mc.cachebox:mc.cachebox = optim.cachebox;
			var nextframes = mc.nextframes?mc.nextframes:mc.nextframes=optim.nextframes;
			var nextframe:int;
			if(mc && mc.currentFrame!=optim.freezeframe) {
				nextframe = optim.freezeframe = mc.currentFrame;
				mc.stop();
				setVisible(master,false,optim.image);
			}
			else {
				nextframe = nextframes[optim.frame];
			}
			if(nextframe!=optim.frame) {
				var bmp:Bitmap, cacheinfo:Object, caches:Array, model:Bitmap,i:int;
				if(optim.image) {
					master.removeChild(optim.image);
					cachebox[optim.frame].push(optim.image);
					caches = cachebox[optim.frame];
					/*if(caches[0].instances==caches.length-1) {
						caches[0].lastused = getTimer();
					}*/
					optim.image = null;
				}
				caches = cachebox[nextframe];
				if(!caches) {
					var scales:Array = optim.scales;
					if(mc) {
						mc.gotoAndStop(nextframe);
						optim.freezeframe = mc.currentFrame;
					}
					if(cachebox[nextframe]) {
						caches = cachebox[nextframe];
					}
					else {
						setVisible(master,true);
						var rect:Rectangle = master.getRect(master);
						var bwidth:int = Math.ceil(rect.width*scales[0]);
						var bheight:int = Math.ceil(rect.height*scales[1]);
						var bscaleX:Number = bwidth/rect.width;
						var bscaleY:Number = bheight/rect.height;
						var bmpd:BitmapData = createBitmapData(bwidth,bheight,true,0);
						if(!bmpd)
							return;
						bmpd.draw(master,new Matrix(bscaleX,0,0,bscaleY,(-rect.x)*bscaleX,(-rect.y)*bscaleY));
						setVisible(master,false);
						var nochange:Boolean = false;
						if(optim.frame) {
							var precaches:Array = cachebox[optim.frame];
							if(precaches) {
								cacheinfo = precaches[0];
								model = cacheinfo.model;
								nochange = true;
								var comp = bmpd.compare(model.bitmapData);
								if(comp!=0) {
									nochange = false;
									if(comp is BitmapData)
										comp.dispose();
								}
							}
						}
						
						if(nochange) {
							caches = cachebox[nextframe] = cachebox[optim.frame];
							bmpd.dispose();
						}
						else {
							bmp = new Bitmap(bmpd);
							bmp.scaleX = 1/bscaleX;
							bmp.scaleY = 1/bscaleY;
							bmp.x = rect.x;
							bmp.y = rect.y;
							caches = cachebox[nextframe] = [{
								model:bmp,
								instances:0,
								lastused:0,
								frame:nextframe,
								cachebox:cachebox}];
						}
					}
				}
				
				if(caches.length==1) {
					cacheinfo = caches[0];
					bmp = cacheinfo.model;
					var newbmp:Bitmap = new Bitmap(bmp.bitmapData,"auto",false);
					newbmp.scaleX = bmp.scaleX;
					newbmp.scaleY = bmp.scaleY;
					newbmp.x = bmp.x;
					newbmp.y = bmp.y;
					caches.push(newbmp);
					cacheinfo.instances++;
				}

				bmp = caches.pop();
				master.addChild(bmp);
				optim.image = bmp;
				optim.frame = nextframe;
			}
			else if(isMonoFrame(master)) {
				e.currentTarget.removeEventListener(e.type,arguments.callee);
			}
		}
	}
}