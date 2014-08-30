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
	import flash.geom.Point;
	import flash.utils.*;
	
	public class Optimo extends Sprite {
		
		static var cloptima:Dictionary = new Dictionary();
		static var optima:Dictionary = new Dictionary(true);
		static const TILESIZE:int =180;
		
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
				master.addEventListener(Event.ENTER_FRAME,refresh);
				master.addEventListener(Event.REMOVED_FROM_STAGE,
					function(e) {
						master.removeEventListener(Event.ENTER_FRAME,refresh);
					});
			}
		}
		
		static public function reset(master:Sprite) {
			var optim:Object = optima[master];
			if(optim.images) {
				for(var i=0;i<optim.images.length;i++) {
					if(optim.images[i]) {
						master.removeChild(optim.images[i]);
						var gridstack:Array = optim.cachebox[optim.frame].grid[i];
						gridstack.push(optim.images[i]);
					}
				}
				optim.images = null;
			}
			if(optim.originalsprite) {
				while(optim.originalsprite.numChildren) {
					master.addChild(optim.originalsprite.removeChildAt(0));
				}
				optim.originalsprite = null;
			}
			else {
				var mc:MovieClip = master as MovieClip;
				if(mc) {
					mc.gotoAndStop(2);
					mc.gotoAndStop(1);
					mc.gotoAndStop(optim.frame);
				}
			}
			optim = getOptima(master,true);
		}
		
		static function isMonoFrame(master:DisplayObject):Boolean {
			return !(master as MovieClip)||(master as MovieClip).totalFrames==1;
		}
		
		static function absoluteScales(master:DisplayObject):Array {
			var m:Array = [Math.abs(master.scaleX),Math.abs(master.scaleY)];
			if(master.parent) {
				var mparent:Array = absoluteScales(master.parent);
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
					cachebox:cachebox,images:null,
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
		
		static function cleanCache():Boolean {
			var disposables:Array = [];
			for(var con in cloptima) {
				var cloptim:Object = cloptima[con];
				var cachestore:Object = cloptim.cachestore;
				for(var m in cachestore) {
					var cachebox:Array = cachestore[m];
					for(var frame:int=1;frame<cachebox.length;frame++) {
						var cacheinfo:Object = cachebox[frame];
						if(cacheinfo) {
							var grid:Array = cacheinfo.grid;
							for(var i=0;i<grid.length;i++) {
								if(grid[i]) {
									var gridstack:Array = grid[i];
									var gridinfo:Object = gridstack[0];
									if(gridinfo.instances==gridstack.length) {
										disposables.push(gridinfo);
									}
								}
							}
						}
					}
				}
			}
			if(!disposables.length) {
				return false;
			}
			while(disposables.length) {
				gridinfo = disposables.pop();
				gridinfo.model.bitmapData.dispose();
				delete gridinfo.model;
				delete gridinfo.instances;
			}
			return true;
		}
		
		static function rescale(master:Sprite):void {
			var scales:Array = absoluteScales(master);
			scales[0] = Math.round(scales[0]*100)/100;
			scales[1] = Math.round(scales[1]*100)/100;
			var optim:Object = getOptima(master);
			if(scales.toString()!=optim.scales.toString()) {
				reset(master);
			}
		}
		
		static function refresh(e:Event):void {
			var master:Sprite = e.currentTarget as Sprite;
			var mc:MovieClip = master as MovieClip;
			
			rescale(master);
			
			var optim:Object = getOptima(master);
			var nextframe:int;
			if(mc && mc.currentFrame!=optim.freezeframe) {
				nextframe = optim.freezeframe = mc.currentFrame;
				mc.stop();
			}
			else {
				nextframe = optim.nextframes[optim.frame];
			}
			var scales:Array = optim.scales;
			var hidden:Boolean = true;
			if(optim.images) {
				var grid:Array = optim.cachebox[optim.frame].grid;
				var images:Array = optim.images;
				while(images.length) {
					var image:Bitmap = images.pop();
					if(image) {
						master.removeChild(image);
						grid[images.length].push(image);
					}
				}
			}
			else
				optim.images = [];
			var cacheinfo:Object = optim.cachebox[nextframe];
			if(!cacheinfo) {
				if(optim.originalsprite) {
					while(optim.originalsprite.numChildren)
						master.addChild(optim.originalsprite.removeChildAt(0));
					optim.originalsprite = null;
				}
				else {
					mc.gotoAndStop(2);
					mc.gotoAndStop(1);
					mc.gotoAndStop(nextframe);
				}
				hidden = false;
				optim.freezeframe = nextframe;
				cacheinfo = optim.cachebox[nextframe] = {grid:[],rect:master.getRect(master)};
			}
			var rect:Rectangle = cacheinfo.rect;
			var xi:int = 0;
			var yi:int = 0;
			var count:int = 0;
			var topleft:Point = master.localToGlobal(new Point(rect.x,rect.y));
			var bwidth:int = Math.ceil(rect.width*scales[0]);
			var bheight:int = Math.ceil(rect.height*scales[1]);
			var bscaleX:Number = bwidth/rect.width;
			var bscaleY:Number = bheight/rect.height;
			if(master.stage && master.visible) {
				var swidth = master.stage.stageWidth;
				var sheight = master.stage.stageHeight;
				while(yi<bheight && xi<bwidth) {
					if(topleft.x+xi<swidth && topleft.y+yi<sheight
					   &&topleft.x+Math.min(bwidth,xi+TILESIZE)>=0
					   &&topleft.y+Math.min(bheight,yi+TILESIZE)>=0
					   ) {
						if(!cacheinfo.grid[count] || !cacheinfo.grid[count][0].model) {
							var localtopleft = new Point(rect.x*bscaleX,rect.y*bscaleY);
							if(hidden) {
								if(optim.originalsprite) {
									while(optim.originalsprite.numChildren) {
										master.addChild(optim.originalsprite.removeChildAt(0));
									}
									optim.originalsprite = null;
								}
								else {
									mc.gotoAndStop(2);
									mc.gotoAndStop(1);
									mc.gotoAndStop(nextframe);
									optim.freezeframe = nextframe;
								}
								hidden = false;
							}
							var bmpd:BitmapData = createBitmapData(Math.min(TILESIZE,bwidth-xi)+1,Math.min(TILESIZE,bheight-yi)+1,true,0);
							bmpd.draw(master,new Matrix(bscaleX,0,0,bscaleY,-localtopleft.x-xi,-localtopleft.y-yi),null,null,new Rectangle(0,0,TILESIZE+1,TILESIZE+1));
							// dispose if image hasn't changed
							var hasChanged = true;
							var precacheinfo = optim.cachebox[optim.frame]
							if(precacheinfo && precacheinfo.grid[count]) {
								var prebmp:Bitmap = precacheinfo.grid[count][0].model;
								if(prebmp) {
									var comp:Object = bmpd.compare(prebmp.bitmapData);
									if(comp is BitmapData) {
										comp.dispose();
									}
									else if(comp==0) {
										hasChanged = false;
									}
								}
							}
							
							if(hasChanged) {	
								var bmp:Bitmap = new Bitmap(bmpd);
								bmp.x = rect.x+xi/bscaleX;
								bmp.y = rect.y+yi/bscaleY;
								bmp.scaleX = 1/bscaleX;
								bmp.scaleY = 1/bscaleY;
								cacheinfo.grid[count] = [{ instances:1,model:bmp }];
							}
							else {
								bmpd.dispose();
								cacheinfo.grid[count] = precacheinfo.grid[count];
							}
						}
						var gridstack:Array = cacheinfo.grid[count];
						if(gridstack.length==1) {
							var model:Bitmap = gridstack[0].model;
							bmp = new Bitmap(model.bitmapData);
							bmp.x = model.x;
							bmp.y = model.y;
							bmp.scaleX = model.scaleX;
							bmp.scaleY = model.scaleY;
							gridstack.push(bmp);
							gridstack[0].instances++;
						}
						optim.images[count] = gridstack.pop();
					}
					count++;
					xi += TILESIZE;
					if(xi>=bwidth) {
						xi=0;
						yi += TILESIZE;
					}
				}
				// clean master
				if(isMonoFrame(master)) {
					if(!optim.originalsprite) {
						optim.originalsprite = new Sprite();
						while(master.numChildren) {
							optim.originalsprite.addChild(master.removeChildAt(0));
						}
					}
				}
				else {
					while(master.numChildren) {
						master.removeChildAt(0);
					}
				}
				for(var i=0;i<optim.images.length;i++) {
					if(optim.images[i])
						master.addChild(optim.images[i]);
				}
			}
			optim.frame = nextframe;
		}
	}
}