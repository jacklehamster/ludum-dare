package
{
	import com.adobe.serialization.json.JSON;
	import com.adobe.crypto.MD5;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.net.URLRequestMethod;
	import flash.net.URLLoaderDataFormat;
	import flash.events.Event;
	import flash.net.URLVariables;
	import flash.events.IOErrorEvent;
	import flash.events.EventDispatcher;
	import flash.utils.setTimeout;
	import flash.utils.clearTimeout;;
	
	public class Com extends EventDispatcher {
		var mixi:String;
		var delay:int = 0;
		var commands:Object = {};
		var queueBytes:ByteArray = new ByteArray();
		var hqBytes:ByteArray = new ByteArray();
		var room:String,user:String,key:String,server:String;
		var loadinprogress = false;
		var timeshift:Number=0;
		static var _instance:Com = null;
		
		function Com(p:Object) {
			params = p;
		}
		
		static public function getInstance(p:Object) {
			return _instance?_instance:_instance=new Com(p);
		}
		
		public function start() {
			com();
		}
		
		public function get ready():Boolean {
			return mixi!=null;
		}
		
		public function set params(value:Object) {
			user = value.user;
			room = value.room;
			key = value.key;
			server = value.server;
		}
		
		public function register(command:String,func:Function,options:Object=null) {
			commands[command] = {
				func:func,
				options:options?options:{}
			};
		}
		
		public function send(command:String,... params:Array) {
			if(commands[command]) {
				queue(command,params,commands[command].options);
			}
		}

		function queue(command:String,params:Array,options:Object):void {
			var bytes:ByteArray = new ByteArray();
			bytes.writeUTF(command);
			bytes.writeObject(params);
			var queueWriter = options.history?hqBytes:queueBytes;
			queueWriter.writeShort(bytes.length);
			queueWriter.writeBytes(bytes);
		}
		
		function processCommand(command:String,params) {
			if(commands[command])
				commands[command].func.apply(null,params);
		}
		
		function com() {
			if(loadinprogress) {
				return;
			}
			var roomkey = MD5.hash("8D "+room+" "+key);
			var p = new URLVariables();
			p.u = user;
			p.r = room;
			p.k = key;
			p.rk = roomkey;
			p.timestamp = new Date().getTime() + timeshift;
			if(mixi) {
				p.mixi = mixi;
			}
			if(delay) {
				p.delay = delay;
			}
			if(queueBytes.length||hqBytes.length) {
				p.m = 1;
				if(hqBytes.length) {
					p.h = hqBytes.length;
				}
			}
			var comurl = "http://" + server + "/com.php?";
			var url = comurl + p.toString();
			var loader:URLLoader = new URLLoader();
			var request:URLRequest = new URLRequest(url);
			request.method = URLRequestMethod.POST;
			request.contentType = "application/octet-stream"; 
			if(queueBytes.length||hqBytes.length) {
				var bytes:ByteArray = new ByteArray();
				bytes.writeBytes(hqBytes);
				bytes.writeBytes(queueBytes);
				bytes.compress();
				queueBytes.clear();
				hqBytes.clear();
				request.data = bytes;
			}
			loader.dataFormat = URLLoaderDataFormat.BINARY;
			loader.addEventListener(IOErrorEvent.IO_ERROR,
				function(e) {
				});
			loader.addEventListener(Event.COMPLETE,
				function(e) {
					var command = null;
					var b:ByteArray;
					var size:int;
					var btemp:ByteArray;
					try {
						loadinprogress = false;
						b = ByteArray(e.currentTarget.data);
						b.uncompress();
						while(b.bytesAvailable) {
							size = b.readShort();
							btemp = new ByteArray();
							btemp.writeBytes(b,b.position,size);
							b.position += size;
							btemp.position = 0;
							command = btemp.readUTF();
							switch(command) {
								case "key":
									key = btemp.readUTFBytes(32);
									trace("k="+key);
									break;
								case "mixi":
									mixi = ""+btemp.readShort();
									break;
								case "delay":
									delay = btemp.readShort();
									break;
								case "time":
									timeshift = btemp.readFloat() - new Date().getTime();
									break;
								default:
									var parameters:Array = btemp.readObject();
									processCommand(command,parameters);
									break;
							}
						}
						if(ready) {
							if(delay) {
								var timeout;
								timeout = setTimeout(
									function() {
										clearTimeout(timeout);
										com();
									},delay);
							}
							else
								com();
						}
						else {
							trace("Not ready. Key might be invalid");
						}
					}
					catch(e:Error) {
						trace(btemp.position);
						btemp.position = 1;
						trace(escape(btemp.readUTFBytes(btemp.bytesAvailable)));
						//var t:Array = [];
						//while(btemp.bytesAvailable) {
							//t.push(btemp.readShort());
						//}
						//trace(t);
						trace(btemp.length);
						trace(">"+command+"<");
						trace(e);
					}
				});
			loader.load(request);
			loadinprogress = true;
		}
	}
}