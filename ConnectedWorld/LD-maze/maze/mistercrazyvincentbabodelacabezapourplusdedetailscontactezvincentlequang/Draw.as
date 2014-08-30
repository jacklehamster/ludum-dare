package {
	
	import flash.display.MovieClip;
	import flash.utils.ByteArray;
	import flash.display.Sprite;
	import flash.utils.Dictionary;
	import flash.geom.Point;
	import flash.display.BlendMode;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Matrix;
	import flash.events.Event;
	import flash.display.PixelSnapping;
	
	public class Draw extends MovieClip {
		
		
		
		public function Draw() {
			canvas = addChild(new Sprite()) as Sprite;
			canvas.blendMode = BlendMode.LAYER;
			canvas.mouseEnabled = canvas.mouseChildren = false;
			checkpoints = [];
			redopoints = [];
		}
		
		protected function drawBytes(barray:ByteArray) {
			if(!barray.length)
				return;
			barray.position = 0;
			var commands:Vector.<int> = new Vector.<int>();
			var data:Vector.<Number> = new Vector.<Number>();
			
			while(barray.bytesAvailable)  {
				var dx:int = barray.readByte();
				var dy:int = barray.readByte();
				if(!dx && !dy) {
					drawcommand = barray.readByte();
					switch(drawcommand) {
						case Command.SetColor:
							drawbrushinfo.color = barray.readUnsignedInt();
							break;
						case Command.SetSize:
							drawbrushinfo.size = barray.readDouble();
							break;
						case Command.SetOpacity:
							drawbrushinfo.opacity = barray.readDouble();
							break;
						case Command.EndDraw:
							finishDrawing(commands,data);
							commands = new Vector.<int>();
							data = new Vector.<Number>();
							layers = null;
							coverCanvas(false);
							break;
						case Command.StartDraw:
							coverCanvas();
							layers = [createLayer()];
							layerdata[layers[layers.length-1]] = { 
									commands:new Vector.<int>(), 
									data:new Vector.<Number>(), 
									brushinfo:{color:drawbrushinfo.color,size:drawbrushinfo.size,opacity:drawbrushinfo.opacity}
								};
							layers[layers.length-1].graphics.beginFill(drawbrushinfo.color,drawbrushinfo.opacity);
							layers[layers.length-1].graphics.drawCircle(0,0,drawbrushinfo.size);
							layers[layers.length-1].graphics.endFill();
							freshlayerstyle = [drawbrushinfo.size*2,drawbrushinfo.color,drawbrushinfo.opacity];
							layers[layers.length-1].x = drawpoint.x;
							layers[layers.length-1].y = drawpoint.y;
							break;
						case Command.StartErase:
							coverCanvas();
							layers = [createLayer()];
							layerdata[layers[layers.length-1]] = { 
									commands:new Vector.<int>(), 
									data:new Vector.<Number>(), 
									brushinfo:{color:0,size:drawbrushinfo.size,opacity:1,blendMode:BlendMode.ERASE}
								};
							layers[layers.length-1].graphics.beginFill(0,1);
							layers[layers.length-1].graphics.drawCircle(0,0,drawbrushinfo.size);
							layers[layers.length-1].graphics.endFill();
							freshlayerstyle = [drawbrushinfo.size*2,0,1];
							layers[layers.length-1].x = drawpoint.x;
							layers[layers.length-1].y = drawpoint.y;
							layers[layers.length-1].blendMode = BlendMode.ERASE;
							break;
						case Command.Snapshot:
							var length = barray.readShort();
							for(var i=0;i<length;i++) {
								strips.push({checkpoint:checkpoints[barray.readShort()]});
								stripindex++;
							}
							break;
						case Command.Removesnap:
							strips.splice(stripindex,1);
							stripindex--;
							if(stripindex<0 && strips.length)
								stripindex = 0;
							updateStrip(false);
							if(chkindex>=0) {
								previewUndo(checkpoints.length-1 - chkindex,true);
							}
							else {
								chkindex = redopoints.indexOf(box.strip.checkpoint);
								if(chkindex>=0) {
									previewUndo(-chkindex-1,true);
								}
							}				
							break;
					}
				}
				else {
					//trace(drawcommand,dx,dy);
					drawpoint.x += dx;
					drawpoint.y += dy;
					if(drawcommand==Command.StartDraw||drawcommand==Command.StartErase) {
						var px = drawpoint.x - layers[layers.length-1].x;
						var py = drawpoint.y - layers[layers.length-1].y;
						var info = layerdata[layers[layers.length-1]];
						info.commands.push(2);
						info.data.push(px);
						info.data.push(py);
						commands.push(2);
						data.push(px);
						data.push(py);
					}
				}
			}
			
			finishDrawing(commands,data);
/*			var bstore:ByteArray = checkpoints[checkpoints.length-1].bytes;
			bb.uncompress();
			bb.position = bb.length;
			bb.writeBytes(barray);
			var s = bb.length;
			bb.compress();
			bstore.writeBytes(barray);
			size.text = s+","+bb.length;*/
			barray.clear();
			barray.position = 0;
		}

		function createLayer():Sprite {
			var lay:Sprite = new Sprite();
			var i;
			for(i=canvas.numChildren-1;i>=0;i--) {
				var child = canvas.getChildAt(i);
				if(child.visible) {
					break;
				}
			}
			canvas.addChildAt(lay,i+1);
			return lay;
		}

		function coverCanvas(docover:Boolean=true) {
			if(docover && canvas.width && canvas.height) {
				if(!canvascache) {
					var rect = canvas.getBounds(canvas);
					canvascache = new Bitmap(new BitmapData(rect.width*canvas.scaleX,rect.height*canvas.scaleY,true,0),PixelSnapping.NEVER,true);
					canvascache.bitmapData.draw(canvas,new Matrix(canvas.scaleX,0,0,canvas.scaleY,-rect.x*canvas.scaleX,-rect.y*canvas.scaleY));
					canvascache.x = rect.x;
					canvascache.y = rect.y;
					canvascache.scaleX = 1/canvas.scaleX;
					canvascache.scaleY = 1/canvas.scaleY;
					for(var i=0;i<canvas.numChildren;i++) {
						canvas.getChildAt(i).visible = false;
					}
					canvas.addChild(canvascache);
				}
			}
			else {
				if(canvascache) {
					canvas.removeChild(canvascache);
					canvascache = null;
					for(i=0;i<canvas.numChildren;i++) {
						canvas.getChildAt(i).visible = true;
					}
				}
			}
		}
		
		function byteDrawing(sprite:Sprite,byteinfo:Object=null):Object {
			var rootdrawing:Boolean = false;
			if(!byteinfo) {
				byteinfo = {pos:new Point(0,0)};
				rootdrawing = true;
			}
			var info = layerdata[sprite];
			if(info) {
				if(!byteinfo.brushinfo)
					byteinfo.brushinfo = {};
				if(!byteinfo.bytes)
					byteinfo.bytes = new ByteArray();
				if(info.brushinfo.blenMode != BlendMode.ERASE) {
					if(byteinfo.brushinfo.color!=info.brushinfo.color) {
						writeCommand(Command.SetColor,byteinfo);
						byteinfo.bytes.writeUnsignedInt(info.brushinfo.color);
						byteinfo.brushinfo.color = info.brushinfo.color;
					}
					if(byteinfo.brushinfo.size!=info.brushinfo.size) {
						writeCommand(Command.SetSize,byteinfo);
						byteinfo.bytes.writeDouble(info.brushinfo.size);
						byteinfo.brushinfo.size = info.brushinfo.size;
					}
					if(byteinfo.brushinfo.opacity!=info.brushinfo.opacity) {
						writeCommand(Command.SetOpacity,byteinfo);
						byteinfo.bytes.writeDouble(info.brushinfo.opacity);
						byteinfo.brushinfo.opacity = info.brushinfo.opacity;
					}
				}
				if(info.commands && info.commands.length) {
					histoMove(sprite.x,sprite.y,byteinfo.bytes,byteinfo.pos);
					writeCommand(info.brushinfo.blendMode==BlendMode.ERASE?Command.StartErase:Command.StartDraw,byteinfo);
					for(i=0;i<info.commands.length;i++) {
						var px = info.data[i*2];
						var py = info.data[i*2+1];
						histoMove(sprite.x+px,sprite.y+py,byteinfo.bytes,byteinfo.pos);
					}
					writeCommand(Command.EndDraw,byteinfo);
				}
			}
			
			for(var i=0;i<sprite.numChildren;i++) {
				var child = sprite.getChildAt(i) as Sprite;
				if(child) {
					byteDrawing(child,byteinfo);
				}
			}
			if(rootdrawing) {
				histoMove(0,0,byteinfo.bytes,byteinfo.pos);
				writeCommand(Command.Snapshot,byteinfo);
				byteinfo.bytes.writeShort(strips.length);
				for(i=0;i<strips.length;i++) {
					var index = checkpoints.indexOf(strips[i].checkpoint);
					if(index<0) {
						index = redopoints.indexOf(strips[i].checkpoint) + checkpoints.length;
					}
					byteinfo.bytes.writeShort(index);
				}
			}
			return byteinfo;
		}
		
		function histoMove(px:Number,py:Number,barray:ByteArray,histopoint:Object):void {
			var dx:int = Math.round(px-histopoint.x);
			var dy:int = Math.round(py-histopoint.y);
			while(dx||dy) {
				var diffx:int,diffy:int;
				if(Math.abs(dx)>Math.abs(dy)) {
					diffx = dx>0?Math.min(dx,127):Math.max(dx,-128);
					diffy = Math.round(diffx*dy/dx);
				}
				else {
					diffy = dy>0?Math.min(dy,127):Math.max(dy,-128);
					diffx = Math.round(diffy*dx/dy);
				}
				dx -= diffx;
				dy -= diffy;
				histopoint.x += diffx;
				histopoint.y += diffy;
				barray.writeByte(diffx);
				barray.writeByte(diffy);
				//trace(diffx,diffy);
			}
		}
		
		function finishDrawing(commands:Vector.<int>,data:Vector.<Number>) {
			var lastcheckpoint = checkpoints[checkpoints.length-1];			
			//trace(lastcheckpoint);
			if(!lastcheckpoint || lastcheckpoint.layers!=layers) {
				//trace(layers);
				if(layers) {
					for(var i=0;i<layers.length;i++) {
						layerdata[layers[i]].checkpoint = checkpoints.length;
					}
					checkpoints.push({layers:layers,active:1});
					lastcheckpoint = checkpoints[checkpoints.length-1];
					//redopoints = [];
					for(i=0;i<redopoints.length;i++) {
						for(var j=0;j<redopoints[i].layers.length;j++) {
							layerdata[redopoints[i].layers[j]].checkpoint = checkpoints.length+i;
						}
						delete(redopoints[i].mini);
						delete(redopoints[i].maxi);
					}
				}
			}

			if(commands.length) {
				if(freshlayerstyle) {
					layers[layers.length-1].graphics.clear();
					layers[layers.length-1].graphics.lineStyle.apply(layers[0].graphics,freshlayerstyle);
					freshlayerstyle = null;
				}
				layers[layers.length-1].graphics.drawPath(commands,data);
			}
			
			dispatchEvent(new Event("finishdrawing"));
		}		
		
		function writeCommand(command:int,byteinfo:Object) {
			byteinfo.bytes.writeByte(0);
			byteinfo.bytes.writeByte(0);
			byteinfo.bytes.writeByte(command);
		}
	}
}