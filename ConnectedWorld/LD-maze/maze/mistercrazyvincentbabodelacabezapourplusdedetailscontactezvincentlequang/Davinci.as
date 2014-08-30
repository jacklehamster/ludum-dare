package {
	
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.IOErrorEvent;
	import flash.ui.Keyboard;
	import flash.geom.Rectangle;
	import flash.geom.Point;
	import flash.geom.Matrix;
	import flash.ui.Mouse;
	import flash.display.Sprite;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.geom.ColorTransform;
	import flash.filters.GlowFilter;
	import flash.display.BitmapData;
	import flash.display.Bitmap;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.ByteArray;
	import flash.events.EventDispatcher;
	import flash.display.BlendMode;
	import flash.utils.Dictionary;
	import flash.display.PixelSnapping;
	import flash.display.Loader;
	import flash.net.URLRequest;
	import flash.net.URLLoader;
	import flash.net.URLVariables;
	import flash.net.URLRequestMethod;
	import flash.filters.BlurFilter;
	import flash.net.LocalConnection;
	import flash.utils.getQualifiedClassName;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import flash.utils.getTimer;	
	import com.adobe.images.PNGEncoder;
	import flash.net.navigateToURL;
	import flash.external.ExternalInterface;
	import flash.system.System;
	import flash.system.LoaderContext;
	import flash.net.URLRequestHeader;
	
	public class Davinci extends MovieClip {
		
		var _action:String;
		
		const Command = { 
			StartDraw:1, 
			EndDraw:2, 
			SetColor:3, 
			SetSize:4, 
			SetOpacity:5, 
			SetBlur:6,
			StartErase:7, 
			Clearsnap:8,
			Snapshot:9, 
			Removesnap:10, 
			SetPrecision:11,
			JumpTo:12,
			ImportBitmap:13,
			ResizeBitmap:14,
			Resize:15,
			AddText:16};
		
		const MAXBLUR = 16;
		
		var self = this;
		var drawcommand:int;
		var drawbrushinfo = { };
		var layers:Array;
		var canvas:Sprite;
		var layerdata:Dictionary = new Dictionary();
		var freshlayerstyle:Array;
		var drawpoint:Point;
		var canvascache:Bitmap;
		var strips:Array;
		var stripindex:int = 0;
		var checkpoints:Array;
		var redopoints:Array;
		var cursor:Cursor;
		var brushdisplay:Sprite;
		var brush:Sprite;
		var smallbrush:Sprite;
		var bigbrush:Sprite;
		var lightbrush:Sprite;
		var heavybrush:Sprite;
		var blurbrush:Sprite;
		var sharpbrush:Sprite;
		var mdown:Point;
		var barray:ByteArray;
		var histopoint:Point;
		var histocommand:int;
		var histobrushinfo = { };
		var screenshot:BitmapData;
		var overlay:Sprite;
		var textlay:Sprite;
		var clip:MovieClip;
		var clipindex:int;
		var zoomfix:Number=0;
		var rotatefix:Number=0;
		var lastdraw:String;
		var bg:MovieClip;
		
		var brushinfo = { color:0xFF, size:2, opacity:.7, precision:1, blur:0 };
		var loading:Boolean;
		var orgpos:Object;
		
		var urldialog:MovieClip;
		var frienddialog:MovieClip;
		var textdialog:MovieClip;
		var playerui:MovieClip;
		var cover:MovieClip;
		var popdialog:MovieClip;
		var param_box:TextField;

		var pid:String = null;
		var uid:String = null;
		var passkey:String = null;
		var timeout:int;
		
		var watermark:MovieClip;
		var framer:MovieClip;
		var framerclip:MovieClip;
		var ui:MovieClip;
		var noui:Boolean = false;
		var noedit:Boolean = false;
		
		var bgpass:DisplayObject = null;
		var params:Object;
		var artcodecache:String = null;
		var savedartcode:String = null;
		var pendingartcode:String = null;
		var savetimer:Timer;
		var thumbnail:BitmapData = null;
		var idle:int = 0;

		var photos = null;
		var photosloader:Object = {};
		var friends = null;
		var friendboxes:Array = null;
		var friendspic:Object = {};
		var friendindex:int = 0;
		var friendsent:Object = {};

		public function Davinci() {
			if(stage)
				init(loaderInfo.parameters);
		}
		
		public function initialize(room,id,title:String=null) {
			init({pid:[room,id],playspeed:.5,noedit:0,title:title,fastforward:1,preview:1,background:0xFFFFFF});
			//init({pid:[room,id]});
			
			//uid=1&pid=10&playloop=&playspeed=.5&noui=&noedit=1&title=Hamster&author=Vincent&host=http://vincent.hostzi.com/&app=davinci&fastforward=1&zoom=1&shift=0,0&a=0
			
		}
		
		public function moveTo(e) {
			//opaqueBackground = e.distance==0?params.background:null;
			ui.visible = playerui.visible = !noui && e.distance==0;
			framerclip.visible = !noui&&!noedit && e.distance==0;
//									playerui.tools.visible = framerclip.visible = !noui&&!noedit;
		}

		
		public function init(params,data=null,davinci_loader=null) {
			this.params=  params;
			if(params.background) {
				opaqueBackground = params.background;
			}
			if(davinci_loader)
				this.bgpass = davinci_loader.bg;
			framer = getChildByName("m_framer") as MovieClip;
			watermark = getChildByName("m_watermark") as MovieClip;
			framerclip = getChildByName("m_framerclip") as MovieClip;
			ui = getChildByName("m_ui") as MovieClip;
			textdialog = getChildByName("m_textdialog") as MovieClip;
			urldialog = getChildByName("m_urldialog") as MovieClip;
			frienddialog = getChildByName("m_frienddialog") as MovieClip;
			playerui = getChildByName("m_playerui") as MovieClip;
			cover = getChildByName("m_cover") as MovieClip;
			canvas = addChildAt(new Sprite(),getChildIndex(framer)) as Sprite;
			canvas.blendMode = BlendMode.LAYER;
			canvas.mouseEnabled = canvas.mouseChildren = false;
			if(params.bgshift) {
				canvas.x = params.bgshift.split(",")[0];
				canvas.y = params.bgshift.split(",")[1];
			}
			bg = new MovieClip();
			canvas.addChildAt(bg,0);
			textlay = addChild(new Sprite()) as Sprite;
			textlay.mouseEnabled = textlay.mouseChildren = false;
			overlay = addChild(new Sprite()) as Sprite;
			overlay.mouseEnabled = overlay.mouseChildren = false;
			clip = addChildAt(new MovieClip(),getChildIndex(framerclip)+1) as MovieClip;
			clip.mouseEnabled = clip.mouseChildren = false;
			clip.x = framerclip.x;
			clip.y = framerclip.y;
			brushdisplay = ui.addChild(new Sprite()) as Sprite;
			brushdisplay.x = ui.brushdisplay.x;
			brushdisplay.y = ui.brushdisplay.y;
			brush = addChild(new Sprite()) as Sprite;
			cursor = addChild(new Cursor()) as Cursor;
			cursor.scaleX = cursor.scaleY = 1.5;
			smallbrush = ui.addChild(new Sprite()) as Sprite;
			bigbrush = ui.addChild(new Sprite()) as Sprite;
			lightbrush = ui.addChild(new Sprite()) as Sprite;
			heavybrush = ui.addChild(new Sprite()) as Sprite;
			blurbrush = ui.addChild(new Sprite()) as Sprite;
			sharpbrush = ui.addChild(new Sprite()) as Sprite;
			var rectsizer = ui.sizeknob.getRect(ui);
			smallbrush.x = rectsizer.x - 15;
			bigbrush.x = rectsizer.x + rectsizer.width + 15;
			bigbrush.y = smallbrush.y = rectsizer.y + rectsizer.height/2;
			var rectopacity = ui.opacityknob.getRect(ui);
			lightbrush.x = rectopacity.x - 15;
			heavybrush.x = rectopacity.x + rectopacity.width + 15;
			heavybrush.y = lightbrush.y = rectopacity.y + rectopacity.height/2;
			var rectblur = ui.blurknob.getRect(ui);
			blurbrush.x = rectblur.x - 15;
			sharpbrush.x = rectblur.x + rectopacity.width + 15;
			sharpbrush.y = blurbrush.y = rectblur.y + rectblur.height/2;
			
			barray = new ByteArray();
			
			drawpoint = new Point();
			histopoint = new Point();
			drawcommand = histocommand = 0;
			checkpoints = [];
			redopoints = [];
			strips = [];
			
			var ar:Array = [canvas,cursor,brush,brushdisplay,smallbrush,bigbrush,lightbrush,heavybrush,blurbrush,sharpbrush];
			ar.forEach(
				function (item:*, index:int, array:Array):void {
					item.mouseEnabled = item.mouseChildren = false;
				});
			
			action = "drawcapture";
			updateBrush();
			changeColor();
			updateCursor();
			updateUndo();
			updateStrip();
			
			if(urldialog.parent)
				urldialog.parent.removeChild(urldialog);
			if(frienddialog.parent)
				frienddialog.parent.removeChild(frienddialog);
			if(textdialog.parent)
				textdialog.parent.removeChild(textdialog);
			if(playerui.parent)
				playerui.parent.removeChild(playerui);
			if(cover.parent)
				cover.parent.removeChild(cover);
			if(watermark.parent)
				watermark.parent.removeChild(watermark);
				
			ui.sizeknob.setVal(Math.max(0,Math.min(1,Math.log(brushinfo.size)/Math.log(16))));
			ui.opacityknob.setVal((brushinfo.opacity-.05)/.95);
			ui.blurknob.setVal(1-brushinfo.blur/MAXBLUR);;

			framer.inner.addEventListener(MouseEvent.ROLL_OVER,updateCursor);
			framer.inner.addEventListener(MouseEvent.ROLL_OUT,updateCursor);
			framer.inner.addEventListener(MouseEvent.MOUSE_MOVE,mouseMove);
			framer.inner.addEventListener(MouseEvent.MOUSE_DOWN,mouseDown);
			framer.inner.addEventListener(MouseEvent.MOUSE_UP,updateCursor);
			ui.sizeknob.addEventListener(Event.CHANGE,changeBrushSize);
			ui.opacityknob.addEventListener(Event.CHANGE,changeOpacity);
			ui.blurknob.addEventListener(Event.CHANGE,changeBlur);
			ui.colorgrid.wheel.addEventListener(MouseEvent.MOUSE_MOVE,changeColor);
			ui.colorgrid.wheel.addEventListener(MouseEvent.MOUSE_DOWN,changeColor);
			ui.colorgrid.shade.addEventListener(MouseEvent.MOUSE_MOVE,changeColor);
			ui.colorgrid.shade.addEventListener(MouseEvent.MOUSE_DOWN,changeColor);
			ui.colorgrid.addEventListener(MouseEvent.ROLL_OUT,changeColor);
			ui.undo.addEventListener(MouseEvent.ROLL_OVER,onHoverUndo);
			ui.undo.addEventListener(MouseEvent.ROLL_OUT,onHoverUndo);
			ui.undo.addEventListener(MouseEvent.CLICK,onHoverUndo);
			ui.undo.buttonMode = true;
			ui.redo.addEventListener(MouseEvent.ROLL_OVER,onHoverUndo);
			ui.redo.addEventListener(MouseEvent.ROLL_OUT,onHoverUndo);
			ui.redo.addEventListener(MouseEvent.CLICK,onHoverUndo);
			ui.redo.buttonMode = true;
			canvas.addEventListener(Event.RENDER,render);
			stage.addEventListener(Event.MOUSE_LEAVE,updateCursor);
			clip.addEventListener(Event.ENTER_FRAME,refreshClip);
			framerclip.buttonMode = true;
			framerclip.addEventListener(MouseEvent.CLICK,onPreview);
			playerui.tools.buttonMode = true;
			playerui.playb.buttonMode = true;
			playerui.loopb.buttonMode = true;
			playerui.linkb.buttonMode = true;
			playerui.speedknob.buttonMode = true;
			playerui.tools.addEventListener(MouseEvent.CLICK,onPreview);
			playerui.linkb.addEventListener(MouseEvent.CLICK,onLink);
			addEventListener("finishdrawing",onFinishDrawing);
			ui.zoomknob.visible = false;
			ui.zoomknob.addEventListener("releaseknob",onZoom);
			ui.zoombutton.buttonMode = true;
			ui.zoombutton.addEventListener(MouseEvent.MOUSE_DOWN,onZoom);
			ui.zoomknob.addEventListener(Event.CHANGE,onZoom);
			ui.rotationknob.visible = false;
			ui.rotationknob.addEventListener("releaseknob",onRotate);
			ui.rotationbutton.buttonMode = true;
			ui.rotationbutton.addEventListener(MouseEvent.MOUSE_DOWN,onRotate);
			ui.rotationknob.addEventListener(Event.CHANGE,onRotate);
			ui.delbutton.buttonMode = true;
			ui.addbutton.buttonMode = true;
			ui.addbutton.addEventListener(MouseEvent.MOUSE_DOWN,snapshot);
			ui.delbutton.addEventListener(MouseEvent.MOUSE_DOWN,removesnapshot);
			ui.fb.addEventListener(MouseEvent.CLICK,sendFriends);
			
			ui.eye.pupil.addEventListener(Event.ENTER_FRAME,followMouse);
			
			ui.sendbutton.addEventListener(MouseEvent.CLICK,onSend);
			
			pid = params.pid?params.pid:null;
			uid = params.uid?params.uid:null;
			passkey = params.passkey?params.passkey:null;
			
			if(!playerui.speedknob.inited) {
				playerui.speedknob.inited = true;
				playerui.speedknob.setVal(!params.fastforward?(params.playspeed?params.playspeed:.3):1);
				if(params.fastforward && params.playspeed) {
					playerui.speedknob.willplayspeed = (params.playspeed?params.playspeed:.3);
				}
				playerui.speedknob.limit = true;
				playerui.speedknob.setRule(true);
			}
			
			if(params.playloop) {
				playerui.loopb.gotoAndStop(2);
			}
			
			playerui.titlebox.text = params.title?params.title:"";
			playerui.authorbox.text = params.author?"- " + params.author:"";
			playerui.linkb.visible = params.link;
			if(params.app_url) {
				watermark.tf.autoSize = "right";
				watermark.tf.text = params.app_url;
			}
			
			//framer.gotoAndStop(3);
			//framerclip.frame.gotoAndStop(3);
			//ui.visible = false;
			//framer.visible = ui.visible = false;
			//framerclip.visible = false;
			//flash.utils.setTimeout(connect,2000);
			
			if(data) {
				parseData(data,params.preview);
			}
			
			if(!uid || !pid) {
				autoGenerate(
					function() {
						if(pid&&uid) {
							serverloading = true;
							var urlloader:URLLoader = new URLLoader();
							urlloader.addEventListener(Event.COMPLETE,
								function(e) {
									parseData(e.currentTarget.data,params.preview);
									serverloading = false;
								});
							var request:URLRequest = new URLRequest(host + "/davinci/get.php");
							request.data = new URLVariables();
//							request.data.pid = pid;
							request.data.uid = uid;
							request.data.time = new Date().getTime();
							urlloader.load(request);
						}
					});
			}
			ui.sendbutton.stop();
			ui.sendbutton.visible = false;
			
			savedartcode = pendingartcode = artcode;
			if(!noedit) {
				savetimer = new Timer(1000);
				savetimer.addEventListener(TimerEvent.TIMER,timeToSave);
				savetimer.start();
			}
		}
		
		function sendFriends(e) {
			popDialog(frienddialog);
			if(!frienddialog.inited) {
				frienddialog.inited = true;
				frienddialog.okbutton.addEventListener(MouseEvent.CLICK,
					function(e) {
						closeDialog();
					});
				frienddialog.leftpage.addEventListener(MouseEvent.CLICK,
					function(e) {
						refreshFriends(friendindex+12);
					});
				frienddialog.tf.addEventListener(Event.CHANGE,
					function(e) {
						refreshFriends(0);
					});
				friendboxes = [];
				for(var i=0;i<frienddialog.numChildren;i++) {
					var child = frienddialog.getChildAt(i);
					if(child is Box) {
						child.visible = false;
						child.tf.mouseEnabled = false;
						child.eye.buttonMode = true;						
						child.eye.addEventListener(MouseEvent.CLICK,
							function(e) {
										var id = e.currentTarget.parent.id;
										friendsent[id] = true;
										e.currentTarget.parent.alpha = .3;
										ExternalInterface.call("publishStream",id,false);
							});
						child.tool.buttonMode = true;
						child.tool.addEventListener(MouseEvent.CLICK,
							function(e) {
										var id = e.currentTarget.parent.id;
										friendsent[id] = true;
										e.currentTarget.parent.alpha = .3;
										ExternalInterface.call("publishStream",id,true);
							});
						friendboxes.push(child);
					}
				}
				
				var timer:Timer = new Timer(500);
				timer.addEventListener(TimerEvent.TIMER,
					function(e) {
						if(!friends) {
							friends = ExternalInterface.call("getFriends");							
							
							if(friends) {
								var array:Array = [];
								for(var i=0;friends[i];i++) {
									array[i] = friends[i];
								}
								friends = array;
								friends.sortOn("name");
								refreshFriends(0);
								timer.removeEventListener(e.type,arguments.callee);
								timer.stop();
							}
						}
					});
				timer.start();
				
			}
		}
		
		function refreshFriends(index) {
			if(friends) {
				var filter = frienddialog.tf.text.toLowerCase();
				friendindex = index;
				var i = 0;
				for(i=0;i<friendboxes.length;i++) {
					friendboxes[i].visible = false;
					if(friendboxes[i].loader) {
						friendboxes[i].loader.visible = false;
					}
				}
				
				var count = 0;
				var foundone:Boolean = false;
				var skips = friendindex;
				i=0;
				while(friends[i]) {
					var friendname = friends[i].name;
					var match = filter=="";
					if(!match) {
						var namesplit = friendname.split(" ");
						for(var j=0;j<namesplit.length && !match;j++) {
							if(namesplit[j].toLowerCase().indexOf(filter)==0) {
								match = true;
								namesplit[j] = "<u>"+namesplit[j].substr(0,filter.length)+"</u>" + namesplit[j].substr(filter.length);
							}
						}
						friendname = namesplit.join(" ");
					}
					
					if(match) {
						foundone = true;
						if(skips>0) {
							skips--;
						}
						else {
							friendboxes[count].visible = true;
							friendboxes[count].alpha = friendsent[friends[i].id]?.3:1;
							friendboxes[count].tf.htmlText = friendname;
							var loader:Loader = friendspic[friends[i].id];
							if(!loader) {
								loader = friendspic[friends[i].id] = new Loader();
								var context:LoaderContext = new LoaderContext(true);
								loader.load(new URLRequest(friends[i].picture),context);
							}
							loader.visible = true;
							friendboxes[count].loader = loader;
							friendboxes[count].addChild(loader);
							friendboxes[count].id = friends[i].id;
							
							count++;
						}
					}
					i++;
				}
				if(friendindex && !count) {
					refreshFriends(0);
				}
			}
		}
		
		function timeToSave(e) {
			var code = artcode;
			var beenIdle:int = idle&&getTimer()-idle;
			if(beenIdle>2000) {
				coverCanvas(true);
			}
			if(sending) {
				serverloading = false;
			}
			else if(code==savedartcode && (beenIdle<=7000)) {
				serverloading = false;
			}
			else if(pendingartcode != code) {
				pendingartcode = code;
				serverloading = true;
			}
			else {
//				trace(code,pendingartcode,savedartcode);
				sendData(beenIdle>7000);
			}
		}
		
		function set serverloading(value:Boolean) {
			ui.sendbutton.visible = value;
			if(value) {
				ui.sendbutton.play();
			}
			else {
				ui.sendbutton.stop();
			}
		}
		
		function parseData(data,preview:Boolean) {
			var firstline = data.split("\n")[0];
			if(firstline.length && pid) {
				try {
					var vars:URLVariables = new URLVariables(firstline);
					if(vars.success && vars.data) {
						var vars2:URLVariables = new URLVariables(vars.data);
						
						for(var i in vars2) {
							if(i==pid) {
								var datacode:String = vars2[pid];
								if(datacode) {
									noui=params.noui;
									noedit=params.noedit;
									playerui.tools.visible = framerclip.visible = !noui&&!noedit;
									//framer.visible = !noedit;
									ui.visible = playerui.visible = !noui;
									applyData(datacode,preview);
								}
							}
							else {
								
							}
						}
					}
				}
				catch(e) {
					trace("^O^");
				}
			}
		}
		
		function get version() {
			var V = 1;
			return (V*10000 + loaderInfo.bytesTotal%1000)/10000;
		}
		
		function get host():String {
			return params.host?params.host:"http://vincent.hostzi.com";
		}
		
		function autoGenerate(onDone:Function=null) {
			var urlloader:URLLoader = new URLLoader();
			var request = new URLRequest(host+"/user/auto.php");
			request.data = new URLVariables();
			request.data.v = version;
			request.data.game = getQualifiedClassName(this)+"%O%";
			urlloader.addEventListener(Event.COMPLETE,
				function(e) {
					var data = e.currentTarget.data.split(",");
					if(!pid) {
						pid = data[0]?data[0]:null;
					}
					if(!uid) {
						uid = data[1]?data[1]:loaderInfo.url.split("/").pop().split(".")[0];
					}
					if(onDone!=null)
						onDone();
				});
			urlloader.load(request);
		}
		
//		var get_url = "http://davinci.agilityhoster.com/get_update.php";
//		var set_url = "http://davinci.agilityhoster.com/set_update.php";
//		var get_url = "http://vincent.hostzi.com/davinci/get.php";
		var set_url = "http://vincent.hostzi.com/davinci/set.php";

		function onSend(e) {
			sendData(false);
		}
		
		function savePng(doPrint:Boolean=false) {
			var bytes:ByteArray = getThumb(500,true);
			var header:URLRequestHeader = new URLRequestHeader("Content-type", "application/octet-stream");
			var request:URLRequest = new URLRequest((params.pngurl?params.pngurl:"http://vincent.hostzi.com/davinci/png.php") + (doPrint?"?print":""));
			request.method = URLRequestMethod.POST;
			request.requestHeaders.push(header);
			request.data = bytes;
			flash.net.navigateToURL(request,"png");
		}
		
		function getThumb(thumbsize:int,sign:Boolean=false):ByteArray {
			var rect:Rectangle = framer.inner.getRect(canvas);
			var scale = thumbsize/rect.width;
			var bmpd:BitmapData = new BitmapData(thumbsize,thumbsize,true,0);
			
			var bgloader =  bg && bg.loader && bg.loader.parent==bg?bg.loader:null;
			bmpd.draw(canvas,new Matrix(scale,0,0,scale,-rect.left*scale,-rect.top*scale));	
			if(sign)
				bmpd.draw(watermark);
			var ba:ByteArray = PNGEncoder.encode(bmpd);
			bmpd.dispose();
			return ba;
		}
		
		var sending:Boolean = false;
		public function sendData(saveThumbnail:Boolean,onSent:Function=null) {
			if(noedit)
				return;
			if(sending)
				return;
				
			sending = true;
			if(timeout)
				flash.utils.clearTimeout(timeout);
			var loader:URLLoader = new URLLoader();
			var request:URLRequest = new URLRequest(set_url);
			request.data = new URLVariables();
			request.data.pid = pid;
			request.data.uid = uid;
			request.data.data = artcode?artcode:'';
			request.data.passkey = '';
			if(saveThumbnail) {
				request.data.thumbnail = Base64.encode(getThumb(140));
				idle = 0;
			}
			request.method = URLRequestMethod.POST;
			
			loader.addEventListener(Event.COMPLETE,
				function(e) {
					sending = false;
					savedartcode = pendingartcode;
					if(saveThumbnail)	
						ExternalInterface.call("updateArt",pid);
					if(onSent!=null)
						onSent();
				});
			loader.load(request);
/*			
			var ll= new Loader();
			var urlrequest:URLRequest = new URLRequest("http://vincent.hostzi.com/davinci/img.php");
			urlrequest.method = URLRequestMethod.POST;
			urlrequest.data = new URLVariables();
			urlrequest.data.thumbnail = Base64.encode(getThumb());
			ll.load(urlrequest);
			visible = false;
			stage.addChild(ll);*/
		}
		
		function applyData(data,preview:Boolean) {
			processData(data);
			if(preview)
				showPreview();
			savedartcode = artcode;
		}
		
/*		function connect() {
			loading = true;

			if(timeout)
				flash.utils.clearTimeout(timeout);
			get_loader = new URLLoader();
			var request:URLRequest = new URLRequest(get_url);
			request.data = new URLVariables();
			if(timestamp)
				request.data.timestamp = timestamp;
			request.data.rand = flash.utils.getTimer();
			request.data.pid = pid;
			request.data.uid = uid;
			get_loader.addEventListener(Event.COMPLETE,
				function(e) {
					try {
						//trace(e.currentTarget.data);
						var firstline = e.currentTarget.data.split("\n")[0];
						if(firstline.length && pid) {
							var vars:URLVariables = new URLVariables(firstline);
							processData(vars[pid]);
							showPreview();
						}
						//var obj:Object = JSON.decode(e.currentTarget.data);
						//if(obj.timestamp)
							//timestamp = obj.timestamp;
						//if(obj.data) {
							//processData(obj.data);
							//showPreview();
						//}
						get_loader = null;
						loading = false;
//						timeout = flash.utils.setTimeout(connect,3000);
					}catch(e) {
						get_loader = null;
						loading = false;
					}
				});
			get_loader.load(request);
		}
		*/
		
		function processData(data:String) {
			barray = Base64.decode(uncleanString(data));
			barray.uncompress();
			drawBytes(barray);
			barray.clear();
			barray.position = 0;
		}
		
		function followMouse(e) {
			var dx = e.currentTarget.mouseX;
			var dy = e.currentTarget.mouseY;
			var dist = Math.sqrt(dx*dx+dy*dy);
			e.currentTarget.x = dx/dist*7;
			e.currentTarget.y = dy/dist*7;
		}
		
		function onRotate(e) {
			if(e.type=="releaseknob") {
				ui.rotationknob.visible = false;
				onFinishDrawing();
			}
			else if(e.type==Event.CHANGE) {
				if(ui.rotationknob.visible) {
					var center = globalToLocal(framer.localToGlobal(new Point(framer.width/2,framer.height/2)));
					var pcenter = canvas.globalToLocal(center);
					canvas.rotation = (ui.rotationknob.val()*180/Math.PI+rotatefix);
					var newpcenter = globalToLocal(canvas.localToGlobal(pcenter));
					canvas.x -= (newpcenter.x-center.x);
					canvas.y -= (newpcenter.y-center.y);
					artcodecache = null;
					adjustBG();
				}
			}
			else {
				ui.rotationknob.touchKnob();
				ui.rotationknob.visible = true;
				rotatefix = canvas.rotation-ui.rotationknob.val()*180/Math.PI;
			}
		}
		
		function get zoom():Number {
			return canvas.scaleX;
		}
		
		function set zoom(value:Number):void {
			var newpcenter:Point;
			var presize = brushinfo.size/canvas.scaleX;
			var center = globalToLocal(framer.localToGlobal(new Point(framer.width/2,framer.height/2)));
			var pcenter = canvas.globalToLocal(center);
			canvas.scaleY = canvas.scaleX = Math.max(.01,value);
			newpcenter = globalToLocal(canvas.localToGlobal(pcenter));
			canvas.x -= (newpcenter.x-center.x);
			canvas.y -= (newpcenter.y-center.y);
			brushinfo.size=presize*canvas.scaleX;
			ui.sizeknob.setVal(Math.max(0,Math.min(1,Math.log(brushinfo.size)/Math.log(16))));
			artcodecache = null;			
			adjustBG();
			updateBrush();
		}
		
		function onZoom(e) {
			if(e.type=="releaseknob") {
				ui.zoomknob.visible = false;
				onFinishDrawing();
			}
			else if(e.type==Event.CHANGE) {
				if(ui.zoomknob.visible) {
					zoom = ui.zoomknob.val()*zoomfix;
				}
			}
			else {
				ui.zoomknob.touchKnob();
				ui.zoomknob.visible = true;
				zoomfix = canvas.scaleX/ui.zoomknob.val();
			}
		}
		
		function onLink(e) {
			flash.net.navigateToURL(new URLRequest(params.link));
		}
		
		function onPreview(e) {
			if(!orgpos) {
				showPreview();
			}
			else {
				action = lastdraw?lastdraw:"draw";
				ui.visible = true;
				//framer.visible = true;
				if(playerui.parent)
					playerui.parent.removeChild(playerui);
				setFrame(orgpos.stripindex);
				zoom = orgpos.zoom;
				canvas.x = orgpos.x;
				canvas.y = orgpos.y;
				orgpos = null;
				framerclip.frame.gotoAndStop(1);
			}
		}
				
		function topSpeed() {
			return Math.round(playerui.speedknob.val()*8)>=7 && playerui.playb.currentFrame==2;		
		}
				
		function progressLayer(layer,func:Function,index:int) {
			
			if(!playerui.progressbar.inited) {
				playerui.progressbar.inited = true;
				playerui.progressbar.bar = playerui.progressbar.addChildAt(new Sprite(),0);
				playerui.progressbar.orgRect = playerui.progressbar.getRect(ui.progressbar);
				//playerui.progressbar.addEventListener(MouseEvent.MOUSE_MOVE,onHoverUndo);
				//playerui.progressbar.addEventListener(MouseEvent.ROLL_OUT,onHoverUndo);
				//playerui.progressbar.addEventListener(MouseEvent.MOUSE_DOWN,onHoverUndo);
			}
			
			var info = layerdata[layer];
			var count = 0;
			var playstopped = false;
			layer.filters = info.brushinfo.blur?[new BlurFilter(info.brushinfo.blur,info.brushinfo.blur)]:[];
			layer.graphics.clear();
			layer.graphics.lineStyle(info.brushinfo.size*2,info.brushinfo.color,info.brushinfo.opacity);
			if(topSpeed()) {
				layer.graphics.drawPath(info.commands,info.data);
			}
			
			layer.addEventListener(Event.ENTER_FRAME,
				function(e) {
					var dontstop:Boolean = playstopped && playerui.playb.currentFrame==2;
					var pausedplay:Boolean = playerui.playb.currentFrame==1;
					var noloop:Boolean = playerui.loopb.currentFrame==1;
					if(!orgpos) {
						layer.graphics.clear();
						layer.graphics.lineStyle(info.brushinfo.size*2,info.brushinfo.color,info.brushinfo.opacity);
						layer.graphics.drawPath(info.commands,info.data);
						e.currentTarget.removeEventListener(e.type,arguments.callee);
						if(func!=null) {
							func();
						}
						return;
					}
					
					var speed:Number = pausedplay?0:topSpeed()?info.commands.length:playerui.speedknob.val()==1?info.commands.length:Math.max(0,playerui.speedknob.val()*8);
//					trace(Math.round(playerui.speedknob.val()*8),playerui.speedknob.val()*10);
					speed = speed<1 && Math.random()>speed?0:Math.ceil(speed);
					if(speed && Math.round(playerui.speedknob.val()*8)<7) {
						layer.graphics.drawPath(info.commands.slice(count,count+speed),info.data.slice(count*2,count*2+speed*2));
					}
					var eye = cursor.getChildByName("eye");
					if(eye && count<info.commands.length) {
						var lastarrayindex:int = Math.min(info.data.length-1,count*2+speed*2-1);
						var pos:Point = speed?new Point(info.data[lastarrayindex-1],info.data[lastarrayindex]):null;
						if(pos) {
							var pupilpos:Point = eye.pupil.globalToLocal(layer.localToGlobal(pos));
							eye.pupil.x = pupilpos.x/pupilpos.length*8;
							eye.pupil.y = pupilpos.y/pupilpos.length*8;
						}
					}
					if(!noui) {
						if(mdown) {
							var center = globalToLocal(new Point(mouseX,mouseY));
							var pcenter = canvas.globalToLocal(center);
							zoom = Math.min(orgpos.zoom*3,zoom*1.1);
							var newpcenter = globalToLocal(canvas.localToGlobal(pcenter));
							canvas.x -= (newpcenter.x-center.x);
							canvas.y -= (newpcenter.y-center.y);
						}
						else {
							if(zoom!=orgpos.zoom) {
								zoom = zoom*.3+orgpos.zoom*.7;
								if(Math.abs(zoom-orgpos.zoom)<.1) {
									zoom = orgpos.zoom;
								}
							}
							else {
								canvas.x += (orgpos.x-canvas.x)*.4*zoom;
								canvas.y += (orgpos.y-canvas.y)*.4*zoom;
							}
						}
					}


					count+=speed;
					if(count>=info.commands.length) {
						if(index==strips.length-1 && !noloop && playstopped) {
							playerui.playb.gotoAndStop(2);
							playstopped = false;
							if(noui) {
								e.currentTarget.removeEventListener(e.type,arguments.callee);
							}
						}
						else if(index==strips.length-1 && noloop && !dontstop) {
							playerui.playb.gotoAndStop(1);
							playstopped = true;
							if(playerui.speedknob.willplayspeed) {
							   playerui.speedknob.setVal(playerui.speedknob.willplayspeed);
							   playerui.speedknob.willplayspeed = 0;
							}
						}
						else {
							e.currentTarget.removeEventListener(e.type,arguments.callee);
							if(func!=null) {
								func();
							}
						}
					}
					var miniprogress:Number = Math.min(1,count/info.commands.length);
					var w:int = Math.floor((((index+miniprogress)%strips.length)/strips.length)*playerui.progressbar.orgRect.width);
					playerui.progressbar.bar.graphics.clear();
					playerui.progressbar.bar.graphics.beginFill(0x00FF00);
					playerui.progressbar.bar.graphics.drawRect(playerui.progressbar.orgRect.x,playerui.progressbar.orgRect.y,w,playerui.progressbar.orgRect.height);
					playerui.progressbar.bar.graphics.endFill();
					
				});
		}
		
		var loco = null;
		function showPreview() {
			playerui.playb.gotoAndStop(2);
			orgpos = {
				x:canvas.x,
				y:canvas.y,
				zoom:zoom,
				stripindex:stripindex
			};
			action = "eye";
			addChild(playerui);
			ui.visible = false;
			framer.gotoAndStop(3);
			framerclip.frame.gotoAndStop(3);
			
			var progressPreview = function() {
				if(orgpos) {
					var func:Function = arguments.callee;
					if(Math.round(playerui.speedknob.val()*8)==8) {
						index = strips.length-1;
					}
					setFrame(index%strips.length);
					var firstcheckpoint = checkpoints[checkpoints.length-1];
					if(firstcheckpoint) {
						progressLayer(firstcheckpoint.layers[0],
							function() {
								index++;
								func();
							},index%strips.length);
					}
				}
			}
			var index = 0;
			//setFrame(index = strips.length-1)
			progressPreview();
			//var index = strips.length-1;
			//progressPreview(true);
			/*if(checkpoints.length) {
				ui.visible = false;
				framer.visible = false;
				canvas.visible = false;
				addChild(clip);
				//visible = false;
				//parent.addChild(clip);
				var margin = 100;
				rectcenter(clip,margin,margin,stage.stageWidth-margin*2,stage.stageHeight-margin*4);
				//textlay.x = clip.x;
				//textlay.y = clip.y;
				//trace(clip.width);
				var bytes = byteDrawing(canvas).bytes;
				trace(bytes.length);
				bytes.compress();
				trace(bytes.length);
				trace(encodeURIComponent(Base64.encode(bytes)).length);
				trace(encodeURIComponent(Base64.encode(bytes)));
				/*
				var rect = clip.getRect(clip);
				clip.width = stage.stageWidth - 50;
				clip.height = stage.stageHeight - 350;
				if(clip.scaleX>clip.scaleY) {
					clip.scaleX = clip.scaleY;
				}
				else {
					clip.scaleY = clip.scaleX;
				}
				clip.x = -rect.x*clip.scaleX + stage.stageWidth/2 - clip.width/2;
				clip.y = -rect.y*clip.scaleY + stage.stageHeight/2 - clip.height/2 - 100;
				visible = false;
				parent.addChild(clip);
				var bytes = byteDrawing(canvas).bytes;
				trace(bytes.length);
				bytes.compress();
				trace(bytes.length);
				trace(encodeURIComponent(Base64.encode(bytes)).length);
				
			}*/
		}
		
		function get artcode():String {
			if(artcodecache) {
				return artcodecache;
			}
			var byteinfo = {bytes:new ByteArray()};
			if(checkpoints.length) {				
				byteDrawing(canvas,byteinfo);
			}
			byteMoreInfos(byteinfo);
			var bytes = byteinfo.bytes;
			//trace(bytes.length);
			bytes.compress();
			//trace(bytes.length);
			//trace(encodeURIComponent(Base64.encode(bytes)).length);
			//trace(encodeURIComponent(Base64.encode(bytes)));
			//trace(Base64.encode(bytes));
			var base64:String = cleanString(Base64.encode(bytes));
			artcodecache = base64;
			return base64;
		}
		
		function cleanString(str:String):String {
			return str.split("/").join("_")
			          .split("+").join("*")
					  .split("=").join("~");
					  
		}
		
		function uncleanString(str:String):String {
			return str.split("_").join("/")
			          .split("*").join("+")
					  .split("~").join("=");
					  
		}
		
		function mouseDown(e=null) {
			updateCursor(e);
			if(action=="draw"||action=="drawcapture"||action=="eraser") {
				var lastStrip:Boolean = !strips || !strips.length || stripindex==strips.length-1;
				if(lastStrip) {
					stopDraw(barray,histocommand);
					if(action=="drawcapture")
						snapshot();
					if(brushinfo.color!=histobrushinfo.color) {
						recordCommand(Command.SetColor,barray,brushinfo.color);
					}
					if(brushinfo.size/canvas.scaleX!=histobrushinfo.size) {
						recordCommand(Command.SetSize,barray,brushinfo.size/canvas.scaleX);
					}
					if(brushinfo.opacity!=histobrushinfo.opacity) {
						recordCommand(Command.SetOpacity,barray,brushinfo.opacity);
					}
					if(brushinfo.blur!=histobrushinfo.blur) {
						recordCommand(Command.SetBlur,barray,brushinfo.blur);
					}
					if(brushinfo.precision*canvas.scaleX!=histobrushinfo.precision) {
						recordCommand(Command.SetPrecision,barray,brushinfo.precision*canvas.scaleX);
					}
					histoMove(canvas.mouseX,canvas.mouseY,barray,histopoint,histobrushinfo.precision);
					recordCommand(action=="draw"||action=="drawcapture"?Command.StartDraw:Command.StartErase,barray);
					stage.invalidate();
				}
			}
			else if(action=="hand") {
				canvas.startDrag();
				stage.addEventListener(MouseEvent.MOUSE_MOVE,adjustBG);
				stage.addEventListener(MouseEvent.MOUSE_UP,
					function(e) {
						e.currentTarget.removeEventListener(e.type,arguments.callee);
						stage.removeEventListener(MouseEvent.MOUSE_MOVE,adjustBG);
						canvas.stopDrag();
						overlay.x = canvas.x;
						overlay.y = canvas.y;
						updateStrip();
						artcodecache = null;
						stage.invalidate();
					});
			}
			else if(action=="texter") {
				var tf:TextField = new TextField();
				tf.textColor = brushinfo.color;
				tf.embedFonts = false;
				tf.autoSize = "left";
				var tff:TextFormat = tf.getTextFormat();
				tff.font = "_sans";
				tff.size = Math.max(5,Math.round(textdialog.fontsizeknob.val()*150));
				tf.setTextFormat(tff);
				textlay.addChild(tf);
				var px = mouseX;
				var py = mouseY
				editText(tf,px,py);
				tf.addEventListener(MouseEvent.CLICK,
					function(e) {
						editText(e.currentTarget,px,py);
					});
			}
		}
		
		function adjustBG(e=null) {
			return;
			if(bgpass) {
				bgpass.visible = false;
				bgpass.scaleX = canvas.scaleX;
				bgpass.scaleY = canvas.scaleY;
				bgpass.rotation = canvas.rotation;
				bgpass.x = canvas.x;
				bgpass.y = canvas.y;
			}
		}
		
		function editText(tf:TextField,px:int,py:int) {
			popDialog(textdialog);
			textdialog.tf.text = tf.text;
			textdialog.tf.setSelection(textdialog.tf.length,textdialog.tf.length);
			textdialog.x = textdialog.px = px;
			textdialog.y = textdialog.py = py;
			var rect = textdialog.getRect(stage);
			if(rect.right>stage.stageWidth) {
				textdialog.x -= rect.right - stage.stageWidth;
			}
			stage.focus = textdialog.tf;
			textdialog.field = tf;
			if(!textdialog.inited) {
				textdialog.inited = true;
				textdialog.fontsizeknob.setVal(.2);
				textdialog.fontsizeknob.limit = true;
				textdialog.fontsizeknob.addEventListener(Event.CHANGE,
					function(e) {
						var tff:TextFormat = textdialog.field.getTextFormat();
						tff.size = Math.max(5,Math.round(e.currentTarget.val()*150));
						textdialog.field.setTextFormat(tff);
						var pos = textdialog.field.parent.globalToLocal(localToGlobal(new Point(textdialog.px,textdialog.py)));
						textdialog.field.x = pos.x;
						textdialog.field.y = pos.y - textdialog.field.height;
					});
				textdialog.okbutton.addEventListener(MouseEvent.CLICK,
					function(e) {
						closeDialog();
					});
				textdialog.tf.addEventListener(Event.CHANGE,
					function(e) {
						textdialog.field.text = e.currentTarget.text;
						var tff:TextFormat = textdialog.field.getTextFormat();
						tff.font = "_sans";
						tff.size = Math.max(5,Math.round(textdialog.fontsizeknob.val()*150));
						textdialog.field.setTextFormat(tff);
						var pos = textdialog.field.parent.globalToLocal(localToGlobal(new Point(textdialog.px,textdialog.py)));
						textdialog.field.x = pos.x;
						textdialog.field.y = pos.y - textdialog.field.height;
					});
				textdialog.tf.addEventListener(KeyboardEvent.KEY_UP,
					function(e) {
						if(e.keyCode==Keyboard.ENTER) {
							closeDialog();
						}
					});
			}
		}
		
		function stopDraw(barray:ByteArray,histocommand) {
			if(histocommand==Command.StartDraw||histocommand==Command.StartErase) {
				recordCommand(Command.EndDraw,barray);
				stage.invalidate();
			}				
		}
		
		function recordCommand(command:int,barray:ByteArray,value=null) {
			var precommand = histocommand;
			barray.writeByte(0);
			barray.writeByte(0);
			barray.writeByte(command);
			histocommand = command;
			switch(histocommand) {
				case Command.SetColor:
					barray.writeUnsignedInt(value);
					histobrushinfo.color = value;
					break;
				case Command.SetSize:
					barray.writeDouble(value);
					histobrushinfo.size = value;
					break;
				case Command.SetOpacity:
					barray.writeDouble(value);
					histobrushinfo.opacity = value;
					break;
				case Command.SetBlur:
					barray.writeDouble(value);
					histobrushinfo.blur = value;
					break;
				case Command.SetPrecision:
					barray.writeDouble(value);
					histobrushinfo.precision = value;
					break;
				case Command.Snapshot:
					var length = value.length;
					barray.writeShort(length);
					for(var i=0;i<length;i++) {
						barray.writeShort(value[i]);
					}
					break;
				case Command.ImportBitmap:
					barray.writeUTF(value[0]);
					barray.writeByte(value[1]);
					break;
				case Command.JumpTo:
					barray.writeDouble(value[0]);
					barray.writeDouble(value[1]);
					histocommand = precommand;
					break;
			}
		}
		
		function onFinishDrawing(e=null) {
			updateUndo();
			updateStrip();
			//var lastcheckpoint = checkpoints[checkpoints.length-1];
			//if(lastcheckpoint) {
				//processMini(lastcheckpoint,checkpoints.length);
			//}
		}
		
		function updateUndo() {
			if(!ui.undobar.inited) {
				ui.undobar.inited = true;
				ui.undobar.bar = ui.undobar.addChildAt(new Sprite(),0);
				ui.undobar.orgRect = ui.undobar.getRect(ui.undobar);
				ui.undobar.addEventListener(MouseEvent.MOUSE_MOVE,onHoverUndo);
				ui.undobar.addEventListener(MouseEvent.ROLL_OUT,onHoverUndo);
				ui.undobar.addEventListener(MouseEvent.MOUSE_DOWN,onHoverUndo);
			}
			ui.undobar.bar.graphics.clear();
			var lastStrip:Boolean = !strips || !strips.length || stripindex==strips.length-1;
			setEnable(ui.undo,lastStrip && checkpoints.length);
			setEnable(ui.redo,lastStrip && redopoints.length);
			if(redopoints.length) {
				ui.undobar.bar.graphics.beginFill(0x00FF00);
				ui.undobar.bar.graphics.drawRect(ui.undobar.orgRect.x+checkpoints.length,ui.undobar.orgRect.y,redopoints.length,ui.undobar.orgRect.height);
				ui.undobar.bar.graphics.endFill();
			}
			ui.undobar.bar.graphics.lineStyle(1,0x00FFFF);
			ui.undobar.bar.graphics.beginFill(0xFFFF00);
			ui.undobar.bar.graphics.drawRect(ui.undobar.orgRect.x,ui.undobar.orgRect.y,checkpoints.length,ui.undobar.orgRect.height);
			ui.undobar.bar.graphics.endFill();
		}
		
		function onHoverUndo(e) {
			var undoplace:int = Math.round(Math.max(0,ui.undobar.mouseX - ui.undobar.orgRect.x));
			var undocount:int = previewUndo(e.type==MouseEvent.ROLL_OUT?0:e.currentTarget==ui.undo?1:e.currentTarget==ui.redo?-1:checkpoints.length-undoplace,e.buttonDown||e.type==MouseEvent.CLICK);
			
			if(undocount) {
				if(undocount>0) {
					var count = 0;
					for(var i=strips.length-1;i>=0;i--) {
						var finalstrip = strips[i];
						if(checkpoints.indexOf(finalstrip.checkpoint)>=0) {
							break;
						}
						count++;
					}
					for(i=0;i<count;i++)
						removesnapshot();
				}
				updateStrip(true);
			}
		}
		
		function previewUndo(undocount:int,commit:Boolean):int {
			var maxundoplace = checkpoints.length-1-Math.max(0,undocount);
			var clearpoint:Boolean = false;
			for(var i=checkpoints.length-1;i>=0;i--) {
				var layers:Array = checkpoints[i].layers;
				for(var j=layers.length-1;j>=0;j--) {
					if(layerdata[layers[j]].clearrect && i<=maxundoplace) {
						clearpoint = true;
					}
					if(clearpoint) {
						layers[j].visible = false;
					}
					else {
						var opacity = i<=maxundoplace?1:Math.pow(.5,i-maxundoplace);
						if(opacity>.01) {
							layers[j].visible = true;
							layers[j].alpha = opacity;
						}
						else {
							layers[j].visible = false;
						}
					}
				}
			}
			for(i=0;i<redopoints.length;i++) {
				layers = redopoints[i].layers;
				for(j=0;j<layers.length;j++) {
					layers[j].visible = i<-undocount;
					layers[j].alpha = .3;
				}
			}
			if(commit) {
				if(undocount>0) {
					for(i=0;i<undocount;i++) {
						var undoinfo = checkpoints.pop();
						if(!undoinfo)
							break;
						layers = undoinfo.layers;
						for(j=0;j<layers.length;j++)
							layers[j].visible = false;
						redopoints.unshift(undoinfo);
					}
				}
				else {
					for(i=0;i<-undocount;i++) {
						undoinfo = redopoints.shift();
						if(!undoinfo)
							break;
						layers = undoinfo.layers;
						for(j=0;j<layers.length;j++) {
							layers[j].visible = true;
							layers[j].alpha = 1;
						}
						checkpoints.push(undoinfo);
					}
				}
				updateUndo();
			}
			return commit?undocount:0;
		}
		
		function processCommand(sprite:Sprite) {
			var info = layerdata[sprite];
			sprite.filters = info.brushinfo.blur?[new BlurFilter(info.brushinfo.blur,info.brushinfo.blur)]:[];
			sprite.graphics.clear();
			if(info.commands.length) {
				sprite.graphics.lineStyle(info.brushinfo.size*2,info.brushinfo.color,info.brushinfo.opacity);
				sprite.graphics.drawPath(info.commands,info.data);
			}
			else if(info.brushinfo) {
				sprite.graphics.beginFill(info.brushinfo.color,info.brushinfo.opacity);
				sprite.graphics.drawCircle(0,0,info.brushinfo.size);
				sprite.graphics.endFill();
			}
		}
		
		function refreshClip(e) {
			if(mdown)
				return;
			var clip = e.currentTarget;
			clip.visible = framerclip.visible;
			if(!clip.visible)
				return;
			if(!strips.length)
				clipindex = 0;
			else if(orgpos)
				clipindex = orgpos.stripindex;
			else
				clipindex = (clipindex+1)%strips.length;
			
			var count = 0;
			for(var i=0;i<strips.length;i++) {
				var strp = strips[i];
				var chkindex = checkpoints.indexOf(strp.checkpoint);
				if(!strp.maxi && strp.mini && chkindex>=0) {
					strp.maxi = new MovieClip();
					strp.maxi.addChild(strp.maxi.clip = mergeDraw(canvas,chkindex));
					strp.maxi.clip.x = strp.maxi.clip.y = 0;
					strp.maxi.cacheAsBitmap = true;
					strp.maxi.scaleX = strp.maxi.scaleY = .2;
					clip.addChild(strp.maxi);
				}
				if(strp.maxi) {
					strp.maxi.rotation = canvas.rotation;
					clip.setChildIndex(strp.maxi,count);
					strp.maxi.visible = i==clipindex;
					count++;
				}
			}
			while(clip.numChildren>strips.length)
				clip.removeChildAt(strips.length);
			if(ui.visible) {
				rectcenter(clip,framerclip.x,framerclip.y,framerclip.width,framerclip.height);
			}
		}
		
		function mergeDraw(sprite:Sprite,limit:int=-1,selection:Array=null):Sprite {
			var info = layerdata[sprite];
			var newsprite:Sprite;
			if(info && info.commands) {
				var chkindex = checkpoints.indexOf(info.checkpoint);
				if(chkindex<0 || limit>=0 && chkindex>limit) {
					return null;
				}
				newsprite = new Sprite();
				layerdata[newsprite] = {
					commands:info.commands,
					data:info.data,
					brushinfo:info.brushinfo,
					clearrect:info.clearrect
				};
				processCommand(newsprite);
			}
			else {
				newsprite = new Sprite();
				layerdata[newsprite] = {
					commands:new Vector.<int>(), 
					data:new Vector.<Number>(), 
					brushinfo:null
				};
			}
			newsprite.x = sprite.x;
			newsprite.y = sprite.y;
			newsprite.blendMode = sprite.blendMode==BlendMode.LAYER?BlendMode.NORMAL:sprite.blendMode;
			
			if(!selection) {
				selection = [];
				for(var i=0;i<sprite.numChildren;i++) {
					var child = sprite.getChildAt(i) as Sprite;
					selection.push(child);
				}
			}
			for(i=0;i<selection.length;i++) {
				child = selection[i];
				if(child) {
					info = layerdata[child];
					if(info) {
						if(info.clearrect) {
							while(newsprite.numChildren) {
								newsprite.removeChildAt(0);
							}
						}
						else {
							var spriteplus = mergeDraw(child,limit);
							if(spriteplus)
								newsprite.addChild(spriteplus);
						}
					}
				}
			}
			return newsprite;
		}
		
		function render(e=null) {
			if(!barray.length)
				return;
			barray.position = 0;
			drawBytes(barray);
			barray.clear();
			barray.position = 0;
		}
		

			
		//var bb:ByteArray=new ByteArray();
		const midbox = 8;
			
		function iniStripBoxes() {
			if(!ui.strip.inited) {
				ui.strip.inited = true;
				ui.strip.boxes = [];
				ui.strip.boxesorg = [];
				for(var i=0;i<ui.strip.numChildren;i++) {
					ui.strip.boxes.push(ui.strip.getChildAt(i));
					var b = ui.strip.boxes[i];
					ui.strip.boxesorg.push({x:b.x,y:b.y,scaleX:b.scaleX,scaleY:b.scaleY});
				}
				ui.strip.boxes.sortOn("x",Array.NUMERIC);
				//ui.strip.boxes[midbox-1].addEventListener(MouseEvent.MOUSE_DOWN,snapshot);
				for(i=0;i<ui.strip.boxes.length;i++) {
					ui.strip.boxes[i].addEventListener(MouseEvent.MOUSE_DOWN,switchMini);
				}
			}
		}
		
		function removesnapshot(e=null) {
			recordCommand(Command.Removesnap,barray,stripindex);
			stage.invalidate();
		}
		
		function snapshot(e=null) {
			if(checkpoints.length) {
				recordCommand(Command.Snapshot,barray,[checkpoints.length-1]);
				stage.invalidate();
			}
		}
		
		function processMini(checkpoint,index:int) {
			var sprite:Sprite = new Sprite();
			sprite.addChild(mergeDraw(canvas,index));
			checkpoint.mini = sprite;
			rectcenter(checkpoint.mini,0,0,40,40);
		}
		
		function rectcenter(clip:DisplayObject,px:int,py:int,width:int,height:int,rect=null) {
			if(!rect)
				rect = clip.getRect(clip);
			clip.width = width;
			clip.height = height;
			if(clip.scaleX>clip.scaleY) {
				clip.scaleX = clip.scaleY;
			}
			else {
				clip.scaleY = clip.scaleX;
			}
			clip.x = px-rect.x*clip.scaleX + width/2 - clip.width/2;
			clip.y = py-rect.y*clip.scaleY + height/2 - clip.height/2;
		}
		
		function setFrame(index:int) {
			var chkindex = strips[index]?checkpoints.indexOf(strips[index].checkpoint):0;
			stripindex = index;
			if(ui.visible) {
				for(var i=0;i<ui.strip.boxes.length;i++) {
					var minibox = ui.strip.boxes[i];
					if(minibox.moving) {
						minibox.x = minibox.moving.x;
						minibox.y = minibox.moving.y;
						minibox.scaleX = minibox.moving.scaleX;
						minibox.scaleY = minibox.moving.scaleY;
						minibox.removeEventListener(Event.ENTER_FRAME,moveBox);
						minibox.moving = null;
					}
				}
			}
			
			updateStrip(false);
			
			if(chkindex>=0) {
				previewUndo(checkpoints.length-1 - chkindex,true);
			}
			else {
				chkindex = redopoints.indexOf(strips[index].checkpoint);
				if(chkindex>=0) {
					previewUndo(-chkindex-1,true);
				}
			}
			if(ui.visible) {
				var lastStrip:Boolean = !strips || !strips.length || stripindex==strips.length-1;
				setEnable(ui.toolbar.draw,lastStrip);
				setEnable(ui.toolbar.drawcapture,lastStrip);
				setEnable(ui.toolbar.eraser,lastStrip);
				setEnable(ui.addbutton,lastStrip);
				setEnable(ui.undo,lastStrip && checkpoints.length);
				setEnable(ui.redo,lastStrip && redopoints.length);
				setEnable(ui.undobar,lastStrip);
				
				framer.gotoAndStop(lastStrip?1:2);
			}
		}
		
		function switchMini(e) {
			var box = e.currentTarget;
			var index = strips.indexOf(box.strip);
			if(index>=0) {
				setFrame(index);
			}
		}
		
		function setEnable(item,enabled) {
			item.mouseEnabled = enabled;
			if(item is DisplayObjectContainer) {
				item.mouseChildren = enabled;
			}
			item.alpha = enabled?1:.2;
		}
		
		function moveBox(e) {
			var box = e.currentTarget;
			var dx = (box.moving.x-box.x)/2;
			var dy = (box.moving.y-box.y)/2;
			var dsx = (box.moving.scaleX-box.scaleX)/2;
			var dsy = (box.moving.scaleY-box.scaleY)/2;
			box.x += dx;
			box.y += dy;
			box.scaleX += dsx;
			box.scaleY += dsy;
			if(dx*dx+dy*dy<1) {
				box.x = box.moving.x;
				box.y = box.moving.y;
				box.scaleX = box.moving.scaleX;
				box.scaleY = box.moving.scaleY;
				box.removeEventListener(e.type,arguments.callee);
				box.moving = null;
			}
		}
		
		function updateStrip(update=true) {
			iniStripBoxes();
			if(mdown)
				return;
			if(!loading && update)
				strips[stripindex] = {checkpoint:checkpoints[checkpoints.length-1]};
			//trace(stripindex,strips?strips.length:null);
			for(var i=0;i<ui.strip.boxes.length;i++) {
				var box = ui.strip.boxes[i];
				var strp = strips[stripindex-midbox+i+1];
				var checkpoint = strp?strp.checkpoint:null;//i<midbox?checkpoints[checkpoints.length+i-midbox]:redopoints[i-midbox];
				while(box.numChildren>1)
					box.removeChildAt(1);
				if(checkpoint) {
					if(!strp.mini) {
						var chkindex = checkpoints.indexOf(checkpoint);
						if(chkindex<0)
							chkindex = checkpoints.length+redopoints.indexOf(checkpoint);
						processMini(strp,chkindex);
					}
					if(strp.mini.getChildAt(0).rotation!=canvas.rotation) {
						strp.mini.getChildAt(0).rotation = canvas.rotation;
						rectcenter(strp.mini,0,0,40,40);
					}
					//processMini(checkpoint,checkpoints.indexOf(checkpoint));
					box.strip = strp;
					var boxpos = box.moving?{x:box.moving.x,y:box.moving.y,scaleX:box.moving.scaleX,scaleY:box.moving.scaleY}:
											{x:box.x,y:box.y,scaleX:box.scaleX,scaleY:box.scaleY};
					if(strp.prepos && !box.moving) {
						box.moving = {x:box.x,y:box.y,scaleX:box.scaleX,scaleY:box.scaleY};
						box.x = strp.prepos.x;
						box.y = strp.prepos.y;
						box.scaleX = strp.prepos.scaleX;
						box.scaleY = strp.prepos.scaleY;
						box.addEventListener(Event.ENTER_FRAME,moveBox);
					}
					strp.prepos = boxpos;
					box.addChild(strp.mini);
					box.visible = true;
					var f = strips.indexOf(strp)==strips.length-1?1:2;
					if(box.frame.currentFrame!=f) {
						box.frame.gotoAndStop(f);
					}
					
					//box.alpha = checkpoint.active?1:.3;
				}
				else {
					box.visible = false;
				}
			}
				/*
			for(var i=0;i<checkpoints.length;i++) {
				var checkpoint = checkpoints[i];
				if(checkpoint.mini) {
					if(i<checkpoints.length-7) {
						if(checkpoint.mini.parent) {
							checkpoint.mini.parent.removeChild(checkpoint.mini);
						}
					}
					else {
						ui.strip.boxes[i+7-checkpoints.length].addChild(checkpoint.mini);
					}
				}
			}
			for(i=0;i<redopoints.length;i++) {
				checkpoint = redopoints[i];
				if(checkpoint.mini) {
					if(i<=7) {
						ui.strip.boxes[7+i+1].addChild(checkpoint.mini);
					}
					else if(checkpoint.mini.parent) {
						checkpoint.mini.parent.removeChild(checkpoint.mini);
					}
				}
			}*/
		}
		
		function mouseMove(e=null) {
			idle = getTimer();
			if(e&&!e.buttonDown)
				mdown = null;
			if(cursor.visible) {
				cursor.x = mouseX;
				cursor.y = mouseY;
			}
			if(brush.visible) {
				brush.x = mouseX;
				brush.y = mouseY;
			}
			if(e)
				e.updateAfterEvent();
			if(mdown) {
				if(action=="draw"||action=="drawcapture"||action=="eraser") {
					histoMove(canvas.mouseX,canvas.mouseY,barray,histopoint,histobrushinfo.precision);
					stage.invalidate();
				} else if(action=="select") {
					var minx = Math.min(mdown.x,canvas.mouseX);
					var miny = Math.min(mdown.y,canvas.mouseY);
					var maxx = Math.max(mdown.x,canvas.mouseX);
					var maxy = Math.max(mdown.y,canvas.mouseY);
					var selectrect:Rectangle = new Rectangle(minx,miny,1+maxx-minx,1+maxy-miny);
					updateSelection(selectrect);
				}
			}
		}
		
		function getSelection() {
			var array:Array = [];
			for(var i=0;i<canvas.numChildren;i++) {
				var child = canvas.getChildAt(i);
				var info = layerdata[child];
				if(info && info.selected) {
					array.push(child);
				}
			}
			return array;
		}
		
		function updateSelection(selectrect:Rectangle) {
			overlay.graphics.clear();
			if(selectrect) {
				overlay.graphics.lineStyle(1,0xFF00);
				overlay.graphics.drawRect(selectrect.x,selectrect.y,selectrect.width,selectrect.height);
			}
			var selchanged:Boolean = false;
			for(var i=0;i<canvas.numChildren;i++) {
				var child = canvas.getChildAt(i);
				if(child.visible) {
					var rect = child.getBounds(canvas);
					var info = layerdata[child];
					if(info) {
						if(info.selected!=(selectrect && selectrect.intersects(rect))) {
							selchanged = true;
							info.selected = selectrect && selectrect.intersects(rect);
						}
						if(info.selected) {
							if(!info.overlay) {
								info.overlay = new Sprite();
								info.overlay.graphics.lineStyle(1,0xFF);
								info.overlay.graphics.drawRect(rect.x,rect.y,rect.width,rect.height);
							}
							canvas.addChildAt(info.overlay,canvas.getChildIndex(child));
						}
						else {
							if(info.overlay && info.overlay.parent==canvas) {
								canvas.removeChild(info.overlay);
							}
						}
					}
				}
			}
			if(selchanged)
				updateBrush();
		}
		
		function changeBrushSize(e=null) {
			brushinfo.size = Math.pow(16,e.currentTarget.val());
			updateBrush();
		}

		function changeOpacity(e=null) {
			brushinfo.opacity = e.currentTarget.val()*.95+.05;
			updateBrush();
		}
		
		function changeBlur(e=null) {
			brushinfo.blur = (1-e.currentTarget.val())*MAXBLUR;
			updateBrush();
		}
		
		const hexchar:Array = "0123456789ABCDEF".split("");
		function colorHex(color:uint):String {
			var str:String = "";
			for(var i=0;i<6;i++) {
				str = hexchar[(color>>(i*4))&0xF]+str;
			}
			return str;
		}
		
		function hexColor(str:String):uint {
			var num:uint = 0;
			str = str.toUpperCase();
			var s = str.concat("");;
			while(s.length<6) {
				s = "0"+s;
			}
			
			for(var i=0;i<6;i++) {
				var c:int = hexchar.indexOf(s.charAt(5-i))
				num |= c<<(i*4);
			}
			return num;
		}
		
		function antiColor(color:uint):uint {
			var num:uint = 0;
			for(var i=0;i<3;i++) {
				var col = (color>>(i*8))&0xFF;
				num |= (col<128?0xFF:0)<<(i*8);
			}
			return num;
		}
		
		function onInput(e) {
			brushinfo.color = hexColor(e.currentTarget.text);
			hoverColor(brushinfo.color,true,true,false);
		}
		
		function hoverColor(color:uint,select:Boolean,changeShader:Boolean,changetext:Boolean):void {
			ui.colorgrid.colorbar.opaqueBackground = color;
			if(changeShader) {
				ui.colorgrid.shade.opaqueBackground = color;
				if(!ui.colorgrid.bmpd)
					ui.colorgrid.bmpd = new BitmapData(ui.colorgrid.width,ui.colorgrid.height,false);
				ui.colorgrid.bmpd.draw(ui.colorgrid);
			}
			if(changetext)
				ui.colorgrid.colorbartext.tf.text = colorHex(color);
			var tff:TextFormat = ui.colorgrid.colorbartext.tf.getTextFormat();
			tff.color = antiColor(color);
			ui.colorgrid.colorbartext.tf.setTextFormat(tff);
			if(!ui.colorgrid.colorbartext.inited) {
				ui.colorgrid.colorbartext.inited = true;
				ui.colorgrid.colorbartext.tf.restrict = "a-f, A-F, 0-9";
				ui.colorgrid.colorbartext.tf.maxChars = 6;
				ui.colorgrid.colorbartext.tf.addEventListener(Event.CHANGE,onInput);
			}
			
			if(select) {
				brushinfo.color = color;
				updateBrush();
			}		
		}
		
		function changeColor(e=null) {
			if(!ui.colorgrid.bmpd) {
				ui.colorgrid.bmpd = new BitmapData(ui.colorgrid.width,ui.colorgrid.height,false);
				ui.colorgrid.bmpd.draw(ui.colorgrid);
			}
			var pixel:uint = !e||e.type==MouseEvent.ROLL_OUT?brushinfo.color:ui.colorgrid.bmpd.getPixel(ui.colorgrid.mouseX,ui.colorgrid.mouseY);
			hoverColor(pixel,e&&e.buttonDown,!e||e.currentTarget!=ui.colorgrid.shade&&e.buttonDown,true);
			if(e&&e.buttonDown)
				action = lastdraw?lastdraw:"draw";
		}
		
		public function popDialog(dialog):MovieClip {
			addChild(cover);
			addChild(dialog);
			return popdialog = dialog;
		}
		
		public function closeDialog() {
			if(popdialog) {
				if(popdialog.parent)
					popdialog.parent.removeChild(popdialog);
				if(cover.parent)
					cover.parent.removeChild(cover);
				popdialog = null;
			}
		}

		public function set action(value:String) {
			if(_action!=value) {
				var preaction = action;
				switch(preaction) {
					case "eyedrop":
						stage.removeEventListener(MouseEvent.MOUSE_MOVE,eyedropSelect);
						stage.removeEventListener(MouseEvent.MOUSE_DOWN,eyedropSelect);
						stage.removeEventListener(MouseEvent.MOUSE_UP,eyedropSelect);
						break;
				}
				
				_action = value;
				updateCursor();
				updateIcons();
				if(action!="select") {
					updateSelection(null);
				}
				textlay.mouseEnabled = textlay.mouseChildren = action=="texter";
				switch(action) {
					case "png":
						savePng();
						action = preaction;
						break;
					case "printer":
						savePng(true);
						action = preaction;
						break;
					case "bgimport":
						popDialog(urldialog);
						urldialog.lastaction = preaction=="bgimport"?"draw":preaction;
						urldialog.tf.setSelection(0,urldialog.tf.length);
						stage.focus = urldialog.tf;
						if(!urldialog.inited) {
							urldialog.inited = true;
							urldialog.index = 0;
							urldialog.opacityknob.addEventListener(Event.CHANGE,
								function(e) {
									bg.alpha = e.currentTarget.val();
								});
							urldialog.cancelbutton.addEventListener(MouseEvent.CLICK,
								function(e) {
									closeDialog();
									action = urldialog.lastaction;
								});
							urldialog.okbutton.addEventListener(MouseEvent.CLICK,
								function(e) {
									importBitmap(urldialog.tf.text);
									bg.alpha = urldialog.opacityknob.val();
								});
							urldialog.tf.addEventListener(KeyboardEvent.KEY_UP,
								function(e) {
									if(e.keyCode==Keyboard.ENTER) {
										importBitmap(urldialog.tf.text);
										bg.alpha = urldialog.opacityknob.val();
									}
								});
							urldialog.leftpage.addEventListener(MouseEvent.CLICK,
								function(e) {
									urldialog.index ++;
									showPhotos(urldialog.index);
								});
							var timer:Timer = new Timer(500);
							timer.addEventListener(TimerEvent.TIMER,
								function(e) {
									photos = ExternalInterface.call("getPhotos",urldialog.index+6);
									if(photos) {
										var array:Array = [];
										for(var i=0;photos[i];i++) {
											array[i] = photos[i];
										}
										photos = array;
										if(urldialog.parent)
											showPhotos(urldialog.index);
									}
								});
							showPhotos(0);
							timer.start();							
						}
						break;
					case "draw":
					case "drawcapture":
						lastdraw = action;
						break;
					case "eyedrop":
						if(!screenshot) {
							screenshot = new BitmapData(stage.stageWidth,stage.stageHeight,false);
						}
						screenshot.draw(stage);
						stage.addEventListener(MouseEvent.MOUSE_MOVE,eyedropSelect);
						stage.addEventListener(MouseEvent.MOUSE_DOWN,eyedropSelect);
						stage.addEventListener(MouseEvent.MOUSE_UP,eyedropSelect);
						break;
				}
			}
		}
		
		function showPhotos(index:int) {
			for(var i=0;i<6;i++) {
				var img = urldialog.getChildByName("img"+(i+1));
				if(img.loader) {
					if(img.loader.parent==img)
						img.removeChild(img.loader);
					img.loader = null;
				}
			}
			for(i=0;i<6;i++) {
				img = urldialog.getChildByName("img"+(i+1));
				var url = photos && photos[(index+i)%photos.length]?photos[(index+i)%photos.length]:null;
				loadPhoto(img,url);
			}
		}
		
		function loadPhoto(img,url) {
			if(img.loader) {
				if(img.loader.parent==img)
					img.removeChild(img.loader);
				img.loader = null;
			}
			if(url) {
				if(!img.inited) {
					img.inited = true;
					img.buttonMode = true;
					img.addEventListener(MouseEvent.CLICK,
						function(e) {
							urldialog.tf.text = e.currentTarget.url?e.currentTarget.url:"";
						});
				}
				var loader:Loader = photosloader[url];
				if(!loader) {
					loader = photosloader[url] = new Loader();
					loader.contentLoaderInfo.addEventListener(Event.COMPLETE,
						function(e) {
							loader.width = loader.height = 25;
							if(loader.scaleX>loader.scaleY)
								loader.scaleX = loader.scaleY;
							else
								loader.scaleY = loader.scaleX;
							loader.x = -loader.width/2;
							loader.y = -loader.height/2;
							try {
								Bitmap(e.currentTarget.content).smoothing = true;
							}
							catch(e) {
							}
						});
					var context:LoaderContext = new LoaderContext(true);
					loader.load(new URLRequest(url),context);
				}
				img.loader = loader;
				img.addChild(loader);
			}
			img.url = url;
			img.visible = url!=null;
		}
		//				if(!img.url) {
//					img.loader = new Loader();
		//		}

				
		function importBitmap(url:String) {
			stopDraw(barray,histocommand);
			recordCommand(Command.ImportBitmap,barray,[url,1]);
			stage.invalidate();
		}
		
		function eyedropSelect(e=null) {
			var target = e?e.target as EventDispatcher:null;
			if(target && !target.willTrigger(MouseEvent.CLICK)) {
				if(action=="eyedrop") {
					var pixel:uint = screenshot.getPixel(stage.mouseX,stage.mouseY);
					hoverColor(pixel,e&&e.buttonDown,true,true);
				}
				if(e&&e.type==MouseEvent.MOUSE_UP) {
					action = lastdraw?lastdraw:"draw";
				}
			}
		}
		
		public function get action():String {
			return _action;
		}
		
		function initIcon(icon) {
			if(!icon.inited) {
				icon.inited = true;
				icon.buttonMode = true;
				icon.addEventListener(MouseEvent.CLICK,
					function(e) {
						action = e.currentTarget.name;
					});
			}
		}
		
		function updateBrush(e=null) {
			
			if(ui.brushdisplay.brush) {
				if(ui.brushdisplay.brush.parent==ui)
					ui.removeChild(ui.brushdisplay.brush);
				delete ui.brushdisplay.brush;
			}
			
			var sel:Array = getSelection();
			if(!sel.length) {
				brushdisplay.graphics.clear();
				brushdisplay.graphics.beginFill(brushinfo.color,brushinfo.opacity);
				brushdisplay.graphics.drawCircle(0,0,brushinfo.size);
				brushdisplay.graphics.endFill();
				brush.graphics.clear();
			}
			else {
				brushdisplay.graphics.clear();
				ui.brushdisplay.brush = mergeDraw(canvas,-1,sel.length?sel:null);
				ui.addChild(ui.brushdisplay.brush);
				ui.brushdisplay.brush.scaleX = ui.brushdisplay.brush.scaleY = .14;
				var brect = ui.brushdisplay.getRect(ui.brushdisplay);
				
				var rect = ui.brushdisplay.getRect(ui);
				ui.brushdisplay.brush.x = rect.x + (- brect.x)*ui.brushdisplay.brush.scaleX;
				ui.brushdisplay.brush.y = rect.y + (- brect.y)*ui.brushdisplay.brush.scaleY;
			}
			
			brushdisplay.filters = brushinfo.blur?[new BlurFilter(brushinfo.blur,brushinfo.blur)]:[];
			brush.filters = brushinfo.blur?[new BlurFilter(brushinfo.blur,brushinfo.blur)]:[];
				
			//brush.graphics.beginFill(brushinfo.color,brushinfo.opacity);
			brush.graphics.lineStyle(.5,brushinfo.color,brushinfo.opacity);
			brush.graphics.drawCircle(0,0,brushinfo.size);
			//brush.graphics.endFill();
			
			smallbrush.graphics.clear();
			smallbrush.graphics.beginFill(brushinfo.color,Math.max(.1,brushinfo.opacity));
			smallbrush.graphics.drawCircle(0,0,2);
			smallbrush.graphics.endFill();
			smallbrush.filters = brushinfo.blur?[new BlurFilter(brushinfo.blur,brushinfo.blur)]:[];
			bigbrush.graphics.clear();
			bigbrush.graphics.beginFill(brushinfo.color,Math.max(.1,brushinfo.opacity));
			bigbrush.graphics.drawCircle(0,0,10);
			bigbrush.graphics.endFill();
			bigbrush.filters = brushinfo.blur?[new BlurFilter(brushinfo.blur,brushinfo.blur)]:[];
			lightbrush.graphics.clear();
			lightbrush.graphics.beginFill(brushinfo.color,.2);
			lightbrush.graphics.drawCircle(0,0,Math.max(1,brushinfo.size));
			lightbrush.graphics.endFill();
			lightbrush.filters = brushinfo.blur?[new BlurFilter(brushinfo.blur,brushinfo.blur)]:[];
			heavybrush.graphics.clear();
			heavybrush.graphics.beginFill(brushinfo.color,1);
			heavybrush.graphics.drawCircle(0,0,Math.max(1,brushinfo.size));
			heavybrush.graphics.endFill();
			heavybrush.filters = brushinfo.blur?[new BlurFilter(brushinfo.blur,brushinfo.blur)]:[];
			blurbrush.graphics.clear();
			blurbrush.graphics.beginFill(brushinfo.color,brushinfo.opacity);
			blurbrush.graphics.drawCircle(0,0,brushinfo.size);
			blurbrush.graphics.endFill();
			blurbrush.filters = [new BlurFilter(10,10)];
			sharpbrush.graphics.clear();
			sharpbrush.graphics.beginFill(brushinfo.color,brushinfo.opacity);
			sharpbrush.graphics.drawCircle(0,0,brushinfo.size);
			sharpbrush.graphics.endFill();
			
		}
		
		function updateCursor(e=null) {
			var inFrame:Boolean = framer.inner.getRect(this).containsPoint(new Point(mouseX,mouseY));
			var cursorOn:Boolean = !e && inFrame 
					||  e && e.type!=MouseEvent.ROLL_OUT && (action!="draw"&&action!="drawcapture"&&action!="eraser"||e.type!=MouseEvent.MOUSE_DOWN) && e.type!=Event.MOUSE_LEAVE;
			if(e&&e.type==MouseEvent.MOUSE_DOWN) {
				mdown = new Point(canvas.mouseX,canvas.mouseY);
				overlay.visible = action=="select";
				if(action=="select") {
					updateSelection(null);
				}
			}
			else if(e&&e.type==MouseEvent.MOUSE_UP) {
				mdown = null;
				stopDraw(barray,histocommand);
				overlay.visible = false;
			}
			cursor.visible = cursorOn && action!="select" && !noui && !noedit;
			brush.visible = ((action=="draw"||action=="drawcapture") && cursorOn || action=="eraser" && inFrame);
			var lastStrip:Boolean = !strips || !strips.length || stripindex==strips.length-1;
			cursor.alpha = cursor.visible && (action=="draw"||action=="drawcapture"||action=="eraser") && !lastStrip?.2:1;
			if(cursor.visible) {
				cursor.gotoAndStop(action);
				var icon:MovieClip = cursor.getChildByName(action) as MovieClip;
				if(icon && icon.bg) {
					icon.bg.visible = false;
				}
				if(action=="draw") {
					cursor.draw.cc.ccol.opaqueBackground = brushinfo.color;
				}
				mouseMove();
				Mouse.hide();
			}
			else if(action!="draw"&&action!="drawcapture"&&action!="eraser"||!mdown) {
				Mouse.show();
			}
		}
		
		function updateIcons() {
			for(var i=0;i<ui.toolbar.numChildren;i++) {
				var child = ui.toolbar.getChildAt(i);
				var selected = child.name==action;
				child.bg.rotation = selected?180:0;
				child.bg.bgsurface.visible = selected;
				if(!child.inited) {
					initIcon(child);
				}
			}
		}

		protected function drawBytes(barray:ByteArray) {
			artcodecache = null;
			var commands:Vector.<int> = new Vector.<int>();
			var data:Vector.<Number> = new Vector.<Number>();
			while(barray.bytesAvailable)  {
				var dx:int = barray.readByte();
				var dy:int = barray.readByte();
				
				if(!dx && !dy) {
					var command = drawcommand;
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
						case Command.SetBlur:
							drawbrushinfo.blur = barray.readDouble();
							break;
						case Command.SetPrecision:
							drawbrushinfo.precision = barray.readDouble();
							break;
						case Command.EndDraw:
							finishDrawing(commands,data);
							commands = new Vector.<int>();
							data = new Vector.<Number>();
							layers = null;
							coverCanvas(false);
							break;
						case Command.StartDraw:
							//coverCanvas(true);
							layers = [createLayer()];
							layerdata[layers[layers.length-1]] = { 
									commands:new Vector.<int>(), 
									data:new Vector.<Number>(), 
									brushinfo:{color:drawbrushinfo.color,size:drawbrushinfo.size,opacity:drawbrushinfo.opacity,precision:drawbrushinfo.precision,blur:drawbrushinfo.blur}
								};
							layers[layers.length-1].graphics.beginFill(drawbrushinfo.color,drawbrushinfo.opacity);
							layers[layers.length-1].graphics.drawCircle(0,0,drawbrushinfo.size);
							layers[layers.length-1].graphics.endFill();
							freshlayerstyle = [drawbrushinfo.size*2,drawbrushinfo.color,drawbrushinfo.opacity];
							layers[layers.length-1].x = drawpoint.x;
							layers[layers.length-1].y = drawpoint.y;
							layers[layers.length-1].filters = drawbrushinfo.blur?[new BlurFilter(drawbrushinfo.blur,drawbrushinfo.blur)]:[];
							break;
						case Command.StartErase:
							//coverCanvas(true);
							layers = [createLayer()];
							layerdata[layers[layers.length-1]] = { 
									commands:new Vector.<int>(), 
									data:new Vector.<Number>(), 
									brushinfo:{color:0,size:drawbrushinfo.size,opacity:1,precision:drawbrushinfo.precision,blur:drawbrushinfo.blur,blendMode:BlendMode.ERASE}
								};
							layers[layers.length-1].graphics.beginFill(0,1);
							layers[layers.length-1].graphics.drawCircle(0,0,drawbrushinfo.size);
							layers[layers.length-1].graphics.endFill();
							freshlayerstyle = [drawbrushinfo.size*2,0,1];
							layers[layers.length-1].x = drawpoint.x;
							layers[layers.length-1].y = drawpoint.y;
							layers[layers.length-1].blendMode = BlendMode.ERASE;
							layers[layers.length-1].filters = drawbrushinfo.blur?[new BlurFilter(drawbrushinfo.blur,drawbrushinfo.blur)]:[];
							break;
						case Command.Clearsnap:
							strips = [];
							break;
						case Command.Snapshot:
							var length = barray.readShort();
							for(var i=0;i<length;i++) {
								strips.push({checkpoint:checkpoints[barray.readShort()]});
								stripindex = strips.length-1;
							}
							break;
						case Command.Removesnap:
							if(strips.length>1) {
								strips.splice(stripindex,1);
								stripindex--;
								if(stripindex<0 && strips.length)
									stripindex = 0;
								var chkindex = strips[stripindex]?checkpoints.indexOf(strips[stripindex].checkpoint):-1;
								if(chkindex>=0) {
									previewUndo(checkpoints.length-1 - chkindex,true);
								}
								else {
									chkindex = strips[stripindex]?redopoints.indexOf(strips[stripindex].checkpoint):-1;
									if(chkindex>=0) {
										previewUndo(-chkindex-1,true);
									}
									else {
										previewUndo(1,true);
									}
								}
								setFrame(stripindex);
							}
							else {
								previewUndo(1,true);
							}
							break;
						case Command.ImportBitmap:
							var url:String = barray.readUTF();
							var autoResize:int = barray.readByte();
							queueLoad(url,autoResize!=0);
							break;
						case Command.ResizeBitmap:
							bg.x = barray.readDouble();
							bg.y = barray.readDouble();
							bg.scaleX = barray.readDouble();
							bg.scaleY = barray.readDouble();
							bg.rotation = barray.readDouble();
							bg.alpha = barray.readByte()/100;
							smoothBitmap();
							break;
						case Command.Resize:
							canvas.x = barray.readDouble();
							canvas.y = barray.readDouble();
							canvas.scaleX = barray.readDouble();
							canvas.scaleY = barray.readDouble();
							canvas.rotation = barray.readDouble();
							adjustBG();
							//trace(canvas.x,canvas.y,canvas.scaleX,canvas.scaleY,canvas.rotation);
							break;
						case Command.JumpTo:
							drawpoint.x = barray.readDouble();
							drawpoint.y = barray.readDouble();
							drawcommand = command;
							break;
						case Command.AddText:
							var tf:TextField = new TextField();
							tf.textColor = barray.readUnsignedInt();
							tf.textColor = drawbrushinfo.color;
							tf.embedFonts = false;
							tf.autoSize = "left";
							var tff:TextFormat = tf.getTextFormat();
							tff.font = "_sans";
							tff.size=barray.readShort();
							tf.text = barray.readUTF();
							tf.x = barray.readDouble();
							tf.y = barray.readDouble();
							tf.setTextFormat(tff);
							textlay.addChild(tf);
							break;
					}
				}
				else {
					drawpoint.x += dx/drawbrushinfo.precision;
					drawpoint.y += dy/drawbrushinfo.precision;
				}
							
				if(drawcommand==Command.StartDraw||drawcommand==Command.StartErase) {
					var px = drawpoint.x - layers[layers.length-1].x;
					var py = drawpoint.y - layers[layers.length-1].y;
					if(px||py) {
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
		}
		
		function smoothBitmap() {
			try {
				var matrix = bg.loader.content.concatenatedMatrix;
				var scaleddown = matrix.a<1||matrix.d<1;
				Bitmap(bg.loaderInfo.content).smoothing = !scaleddown;
			}
			catch(e) {
			}
		}
		
		function queueLoad(url,autoResize:Boolean) {
			bg.autoResize = autoResize;
			if(!bg.loader) {
				bg.loader = new Loader();
				bg.addChildAt(bg.loader,0);
				bg.loader.contentLoaderInfo.addEventListener(
					Event.COMPLETE,
					function(e) {
						bg.inprogress = false;
						if(bg.autoResize) {
							bg.rotation = -canvas.rotation;						
							bg.scaleX = bg.scaleY = 1;
							bg.x = bg.y = 0;
							var rect = framer.getRect(bg);
							rectcenter(bg.loader,rect.x,rect.y,rect.width,rect.height);
							var bgp = bg.parent;
							var p = bgp.globalToLocal(bg.loader.localToGlobal(new Point(0,0)));
							bg.scaleX = bg.loader.scaleX;
							bg.scaleY = bg.loader.scaleY;
							bg.loader.scaleX = 1;
							bg.loader.scaleY = 1;
							bg.x = p.x;
							bg.y = p.y;
							bg.loader.x = 0;
							bg.loader.y = 0;
							artcode;
						}
						smoothBitmap();
					});
				bg.loader.contentLoaderInfo.addEventListener(
					IOErrorEvent.IO_ERROR,
					function(e) {
						bg.inprogress = false;
						bg.link = null;
					});
			}
			if(bg.inprogress) {
				bg.loader.close();
				bg.inprogress = false;
			}
			if(bg.link) {
				bg.loader.unloadAndStop();
				bg.link = null;
			}
			if(url) {
				bg.inprogress = true;
				bg.link = url;	
				urldialog.tf.text = url;
				var context:LoaderContext = new LoaderContext(true);
				bg.loader.load(new URLRequest("http://vincent.hostzi.com/davinci/fish.php?url="+url),context);
			}
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

		function coverCanvas(docover:Boolean) {
			if(docover && canvas.width && canvas.height && stage) {
				if(!canvascache) {
					var rect:Rectangle = canvas.getBounds(canvas);
					var topleft = canvas.globalToLocal(new Point(0,0));
					var topright = canvas.globalToLocal(new Point(stage.stageWidth,0));
					var botleft = canvas.globalToLocal(new Point(0,stage.stageHeight));
					var botright = canvas.globalToLocal(new Point(stage.stageWidth,stage.stageHeight));
					var minx = Math.max(Math.min(topleft.x,topright.x,botleft.x,botright.x),rect.left);
					var miny = Math.max(Math.min(topleft.y,topright.y,botleft.y,botright.y),rect.top);
					var maxx = Math.min(Math.max(topleft.x,topright.x,botleft.x,botright.x),rect.right);
					var maxy = Math.min(Math.max(topleft.y,topright.y,botleft.y,botright.y),rect.bottom);
					rect = new Rectangle(minx-10,miny-10,maxx-minx+20,maxy-miny+20);
					if(rect.width>=0 && rect.height>=0) {
						canvascache = new Bitmap(new BitmapData(rect.width*canvas.scaleX+1,rect.height*canvas.scaleY+1,true,0),PixelSnapping.NEVER,true);
						if(bg && bg.parent==canvas) {
							canvas.removeChild(bg);
						}
						canvascache.bitmapData.draw(canvas,new Matrix(canvas.scaleX,0,0,canvas.scaleY,-Math.round(rect.x*canvas.scaleX),-Math.round(rect.y*canvas.scaleY)));
						canvascache.x = rect.x;
						canvascache.y = rect.y;
						canvascache.scaleX = 1/canvas.scaleX;
						canvascache.scaleY = 1/canvas.scaleY;
						for(var i=0;i<canvas.numChildren;i++) {
							var child = canvas.getChildAt(i);
							if(child.blendMode!=BlendMode.ERASE)
								canvas.getChildAt(i).visible = false;
						}
						canvas.addChild(canvascache);
						if(bg) {
							canvas.addChildAt(bg,0);
						}
					}
				}
			}
			else {
				if(canvascache) {
					if(canvascache.parent==canvas)
						canvas.removeChild(canvascache);
					canvascache.bitmapData.dispose();
					canvascache = null;
					previewUndo(0,false);
				}
			}
		}
		
		function byteDrawing(sprite:Sprite,byteinfo:Object):Object {
			var rootdrawing:Boolean = false;
			if(!byteinfo.pos) {
				byteinfo.pos = new Point(0,0);
				rootdrawing = true;
			}
			var info = layerdata[sprite];
			if(info) {
				if(!byteinfo.brushinfo)
					byteinfo.brushinfo = {};
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
					if(byteinfo.brushinfo.blur!=info.brushinfo.blur) {
						writeCommand(Command.SetBlur,byteinfo);
						byteinfo.bytes.writeDouble(info.brushinfo.blur);
						byteinfo.brushinfo.blur = info.brushinfo.blur;
					}
					if(byteinfo.brushinfo.precision!=info.brushinfo.precision) {
						writeCommand(Command.SetPrecision,byteinfo);
						byteinfo.bytes.writeDouble(info.brushinfo.precision);
						byteinfo.brushinfo.precision = info.brushinfo.precision;
					}
				}
				if(info.commands && info.commands.length) {
					histoMove(sprite.x,sprite.y,byteinfo.bytes,byteinfo.pos,byteinfo.brushinfo.precision);
					writeCommand(info.brushinfo.blendMode==BlendMode.ERASE?Command.StartErase:Command.StartDraw,byteinfo);
					for(i=0;i<info.commands.length;i++) {
						var px = info.data[i*2];
						var py = info.data[i*2+1];
						histoMove(sprite.x+px,sprite.y+py,byteinfo.bytes,byteinfo.pos,byteinfo.brushinfo.precision);
					}
					writeCommand(Command.EndDraw,byteinfo);
				}
			}
			
			for(var i=0;i<sprite.numChildren;i++) {
				var child:Sprite = sprite.getChildAt(i) as Sprite;
				if(child) {
					byteDrawing(child,byteinfo);
				}
			}
			if(rootdrawing) {
				histoMove(0,0,byteinfo.bytes,byteinfo.pos,byteinfo.brushinfo.precision);
				writeCommand(Command.Clearsnap,byteinfo);
				writeCommand(Command.Snapshot,byteinfo);
				byteinfo.bytes.writeShort(strips.length);
				for(i=0;i<strips.length;i++) {
					var index = checkpoints.indexOf(strips[i].checkpoint);
					if(index<0) {
						index = redopoints.indexOf(strips[i].checkpoint) + checkpoints.length;
					}
					byteinfo.bytes.writeShort(index);
				}
				//trace(canvas.x,canvas.y,canvas.scaleX,canvas.scaleY,canvas.rotation);
			}
			return byteinfo;
		}
		
		function byteMoreInfos(byteinfo) {
			for(var i=0;i<textlay.numChildren;i++) {
				var tf:TextField = textlay.getChildAt(i) as TextField;
				if(tf && tf.text.length>0) {
					var tff:TextFormat = tf.getTextFormat();
					writeCommand(Command.AddText,byteinfo);
					byteinfo.bytes.writeUnsignedInt(tf.textColor);
					byteinfo.bytes.writeShort(tff.size);
					byteinfo.bytes.writeUTF(tf.text);
					byteinfo.bytes.writeDouble(tf.x);
					byteinfo.bytes.writeDouble(tf.y);
				}
			}
			
			if(bg.link) {
				writeCommand(Command.ImportBitmap,byteinfo);
				byteinfo.bytes.writeUTF(bg.link);
				byteinfo.bytes.writeByte(0);
				writeCommand(Command.ResizeBitmap,byteinfo);
				byteinfo.bytes.writeDouble(bg.x);
				byteinfo.bytes.writeDouble(bg.y);
				byteinfo.bytes.writeDouble(bg.scaleX);
				byteinfo.bytes.writeDouble(bg.scaleY);
				byteinfo.bytes.writeDouble(bg.rotation);
				byteinfo.bytes.writeByte(Math.min(100,Math.round(bg.alpha*100)));
			}
			
			writeCommand(Command.Resize,byteinfo);
			byteinfo.bytes.writeDouble(canvas.x);
			byteinfo.bytes.writeDouble(canvas.y);
			byteinfo.bytes.writeDouble(canvas.scaleX);
			byteinfo.bytes.writeDouble(canvas.scaleY);
			byteinfo.bytes.writeDouble(canvas.rotation);
		}
		
		function histoMove(px:Number,py:Number,barray:ByteArray,histopoint:Object,precision:Number):void {
			var dx:int = Math.round((px-histopoint.x)*precision);
			var dy:int = Math.round((py-histopoint.y)*precision);
			var b = barray.position;
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
				histopoint.x += diffx/precision;
				histopoint.y += diffy/precision;
				barray.writeByte(diffx);
				barray.writeByte(diffy);
			}
			if(barray.position-b>20) {
				barray.position = b;
				recordCommand(Command.JumpTo,barray,[px,py]);
			}
		}
		
		function finishDrawing(commands:Vector.<int>,data:Vector.<Number>) {
			var lastcheckpoint = checkpoints[checkpoints.length-1];			
			//trace(lastcheckpoint);
			if(!lastcheckpoint || lastcheckpoint.layers!=layers) {
				//trace(layers);
				if(layers) {
					checkpoints.push({layers:layers,active:1});
					for(var i=0;i<layers.length;i++) {
						layerdata[layers[i]].checkpoint = checkpoints[checkpoints.length-1];
					}
					lastcheckpoint = checkpoints[checkpoints.length-1];
					redopoints = [];
					cleanCanvas();
					/*for(i=0;i<redopoints.length;i++) {
						for(var j=0;j<redopoints[i].layers.length;j++) {
							layerdata[redopoints[i].layers[j]].checkpoint = checkpoints.length+i;
						}
						delete(redopoints[i].mini);
						delete(redopoints[i].maxi);
					}
					*/
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
		
		function cleanCanvas() {
			for(var i=canvas.numChildren-1;i>=0;i--) {
				var child = canvas.getChildAt(i);
				var info = layerdata[child];
				if(info && info.checkpoint && checkpoints.indexOf(info.checkpoint)<0) {
					canvas.removeChildAt(i);
				}
			}
		}
		
		function writeCommand(command:int,byteinfo:Object) {
			byteinfo.bytes.writeByte(0);
			byteinfo.bytes.writeByte(0);
			byteinfo.bytes.writeByte(command);
		}
	}
}