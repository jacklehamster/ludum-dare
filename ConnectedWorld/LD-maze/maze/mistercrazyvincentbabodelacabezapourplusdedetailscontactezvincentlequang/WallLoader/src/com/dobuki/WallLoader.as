package com.dobuki
{
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	import flash.utils.ByteArray;
	import flash.utils.Timer;

	public class WallLoader
	{
		static public var instance:WallLoader = new WallLoader();
		
		static private var cache:Cache = Cache.instance;
		private var loadQueue:LoadQueue = new LoadQueue();
		static private var timer:Timer = new Timer(0,1);
		
		static public function fetchWall(url:String,className:String,callback:Function):void {
			if(cache.has(url+"|"+className,"class")) {
				timer.addEventListener(TimerEvent.TIMER_COMPLETE,
					function(e:TimerEvent):void {
						e.currentTarget.removeEventListener(e.type,arguments.callee);
						var loader:Loader = Cache.instance.get(url,"loader") as Loader;
						var mc:Wall = Wall.recycleout(Cache.instance.get(url+"|"+className,"class") as Class) as Wall;
						callback(mc,loader.contentLoaderInfo.width,loader.contentLoaderInfo.height);
					});
				timer.reset();
				timer.start();
				return;
			}
			fetchLoader(url,
				function(loader:Loader,sandboxed:Boolean):void {
					if(sandboxed) {
						callback(loader.content,loader.contentLoaderInfo.width,loader.contentLoaderInfo.height);
					}
					else {
						var classObj:Class = cache.get(url+"|"+className,"class") as Class;
						if(!classObj) {
							classObj = loader.contentLoaderInfo.applicationDomain.getDefinition(className) as Class;
							cache.set(url+"|"+className,"class",classObj);
						}
						var mc:Wall = Wall.recycleout(classObj) as Wall;
						callback(mc,loader.contentLoaderInfo.width,loader.contentLoaderInfo.height);
					}
				});
		}
		
		static public function fetchLoader(url:String,callback:Function):void {
			instance.fetchLoader(url,
				function(loader:Loader,sandboxed:Boolean):void {
					callback(loader,sandboxed);
				}
			);
		}
		
		private function fetchLoaderWithBytes(bytes:ByteArray,callback:Function):Loader {
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE,
				function(e:Event):void {
					callback(loader,false);
				});
			loader.loadBytes(bytes);
			return loader;
		}
		
		private function fetchLoader(url:String,callback:Function):void {
			if(cache.has(url,"loader")) {
				loader = cache.get(url,"loader") as Loader;
				if(loader.contentLoaderInfo.bytesLoaded 
					&& loader.contentLoaderInfo.content
				) {
					callback(loader,false);
				}
				else {
					loader.contentLoaderInfo.addEventListener(Event.COMPLETE,
						function(e:Event):void {
							e.currentTarget.removeEventListener(e.type,arguments.callee);
							callback(loader,false);
						});
				}
				return;
			}
			
			var bytes:ByteArray = cache.get(url,"bytes") as ByteArray;
			
			if(bytes) {
				cache.set(url,"loader",fetchLoaderWithBytes(bytes,callback));
			}
			else if(cache.get(url,"crossdomain")) {
				var loader:Loader = new Loader();
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE,
					function(e:Event):void {
						callback(loader,true);
					});
				loadQueue.add(loader,loader.load,urlrequest,new LoaderContext(false));
			}
			else if(cache.has(url,"URLLoader")) {
				urlloader = cache.get(url,"URLLoader") as URLLoader;
				urlloader.addEventListener(Event.COMPLETE,
					function(e:Event):void {
						fetchLoader(url,callback);
//						var bytes:ByteArray = urlloader.data;
	//					fetchLoaderWithBytes(bytes,callback);
					});
				urlloader.addEventListener(SecurityErrorEvent.SECURITY_ERROR,
					function(e:Event):void {
						var loader:Loader = new Loader();
						loader.contentLoaderInfo.addEventListener(Event.COMPLETE,
							function(e:Event):void {
								callback(loader,true);
							});
						loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,
							function(e:IOErrorEvent):void {
								trace(e);
							});
						loadQueue.add(loader,loader.load,urlrequest,new LoaderContext(false));
					});
			}
			else {
				var urlloader:URLLoader = new URLLoader();
				cache.set(url,"URLLoader",urlloader);
				var urlrequest:URLRequest = new URLRequest(url);
				urlloader.dataFormat = URLLoaderDataFormat.BINARY;
				urlloader.addEventListener(Event.COMPLETE,
					function(e:Event):void {
						var bytes:ByteArray = urlloader.data;
						cache.set(url,"bytes",bytes);
						var loader:Loader = fetchLoaderWithBytes(bytes,callback);
						cache.set(url,"loader",loader);
					});
				urlloader.addEventListener(SecurityErrorEvent.SECURITY_ERROR,
					function(e:Event):void {
						cache.set(url,"crossdomain",true);
						var loader:Loader = new Loader();
						loader.contentLoaderInfo.addEventListener(Event.COMPLETE,
							function(e:Event):void {
								callback(loader,true);
							});
						loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,
							function(e:IOErrorEvent):void {
								trace(e);
							});
						loadQueue.add(loader,loader.load,urlrequest,new LoaderContext(false));
					});
				loadQueue.add(urlloader,urlloader.load,urlrequest);
			}
		}
	}
}


