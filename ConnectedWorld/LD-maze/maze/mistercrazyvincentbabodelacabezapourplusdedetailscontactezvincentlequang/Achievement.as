package  {
	import com.newgrounds.API;
	import by.blooddy.crypto.MD5;
	import flash.display.MovieClip;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.display.LoaderInfo;
	import flash.system.Security;
	import com.newgrounds.APIEvent;
	import flash.net.SharedObject;
	
	public class Achievement {
		
		static private var root:MovieClip;
		
		static public const TEN:Object = { name:"Visited 10 games", id:"10791" };
		static public const THIRD:Object = { name:"Visited one third of all games", id:"10792" };
		static public const HALF:Object = { name:"You have played one half of all games!", id:"7932" };
		static public const VIDEO:Object = { name:"Checked out a video", id:"10796" };
		static public const ALL:Object = { name:"You have tried all Ludum Dare 30 games!", id:"7933" };		
		static public const JACK:Object = { name:"Find me", id:"10793" };
		static public const CONNECTEDWORLDS:Object = {name:"Connected Worlds", id:"10795" };
		static public const WALKED1000:Object = {name:"Walked 1000 steps", id:"10794" };
		
		static private const GAMEJOLT_ID:String = "33543";
		static private const GAMEJOLT_KEY:String = "3b28f18e770c6a5f93bc53f7a9046013";
		
		static private var kongregate:Object = null;
		static private var kongregateLoader:Loader = null;
		
		static private var highscore:int = 0;
		
		static public function init(mc:MovieClip):void {
			root = mc;
			if(isNewgrounds()) {
				API.connect(root, "38313:wri0SWWA", "moGKgxLB0YITY17H9rFc9lSpU3llT5et");
			}
			if(isKongregate()) {
				kongregateLoader = initKongregate();
			}
		}

		static public function unlock(obj:Object):void {
			var medal:String = obj.name, trophy_id:String = obj.id;
			//	newgrounds
			if(isNewgrounds()) {
				API.unlockMedal(medal);
			}
			
			//	gamejolt
			if(isGamejolt()) {
				var url:String = "http://gamejolt.com/api/game/v1/trophies/add-achieved/?game_id="+GAMEJOLT_ID;
				url += "&username="+ gamejolt_username;
				url += "&user_token="+ gamejolt_token;
				url += "&trophy_id="+trophy_id;
				url += "&signature="+MD5.hash(url + GAMEJOLT_KEY);
				var urlloader:URLLoader = new URLLoader();
				urlloader.load(new URLRequest(url));
			}
			
			//	kongregate
			if(isKongregate()) {
				if(!kongregate) {
					if(!kongregateLoader) {
						kongregateLoader = initKongregate();
					}
					kongregateLoader.contentLoaderInfo.addEventListener(Event.COMPLETE,
						function(e:Event):void {
							kongregate.stats.submit(medal,1);
						});
				}
				else {
					kongregate.stats.submit(medal,1);
				}
			}
		}
		
		static public function postScore(score:int):void {
			if(score<=highscore) {
				return;
			}
			
			//	newgrounds
			if(isNewgrounds()) {
				API.postScore("Games played",score);
			}
			
			//	gamejolt
			if(isGamejolt()) {
				var url:String = "http://gamejolt.com/api/game/v1/scores/add/?game_id="+GAMEJOLT_ID;
				url += "&username="+ gamejolt_username;
				url += "&user_token="+ gamejolt_token;
				url += "&score="+score+" games visited";
				url += "&sort="+score;
				url += "&signature="+MD5.hash(url + GAMEJOLT_KEY);
				var urlloader:URLLoader = new URLLoader();
				urlloader.load(new URLRequest(url));
			}
			
			//	kongregate
			if(isKongregate()) {
				if(!kongregate) {
					if(!kongregateLoader) {
						kongregateLoader = initKongregate();
					}
					kongregateLoader.contentLoaderInfo.addEventListener(Event.COMPLETE,
						function(e:Event):void {
							kongregate.stats.submit("games visited",score);
						});
				}
				else {
					kongregate.stats.submit("games visited",score);
				}
			}
		}
		
		static public function isNewgrounds():Boolean {
			return root.loaderInfo.url.indexOf("uploads.ungrounded.net")>=0;
		}
				
		static public function isKongregate():Boolean {
			return root.loaderInfo.parameters.kongregate_api_path!=null;
		}
		
		static public function isGamejolt():Boolean {
			return root.loaderInfo.url.indexOf("gamejolt")>=0;
		}
		
		static public function isMindJolt():Boolean {
			return root.loaderInfo.url.indexOf("mindjolt")>=0;
		}
		
		static public function get gamejolt_username():String {
		  return root.loaderInfo.parameters.gjapi_username;
		}

		static public function get gamejolt_token():String {
		  return root.loaderInfo.parameters.gjapi_token;
		}
		
		static public function initKongregate():Loader {
			var paramObj:Object = LoaderInfo(root.loaderInfo).parameters;
			var apiPath:String = paramObj.kongregate_api_path || 
			  "http://www.kongregate.com/flash/API_AS3_Local.swf";
			Security.allowDomain(apiPath);
			var request:URLRequest = new URLRequest(apiPath);
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loadComplete);
			loader.load(request);
			root.addChild(loader);

			function loadComplete(event:Event):void
			{
				kongregate = event.target.content;
				kongregate.services.connect();
				kongregateLoader = null;
			}
			return loader;
		}
		
		static function get playerName():String {
			if(Achievement.isGamejolt()) return root.loaderInfo.parameters.gjapi_username;
			if(Achievement.isNewgrounds()) return API.username;
			if(Achievement.isKongregate()) return root.loaderInfo.parameters.kongregate_username;
			var so:SharedObject = SharedObject.getLocal("Maze");
			if(!so.data.playername) {
				var domain:String = root.loaderInfo.url.split("?")[0].split("#")[0].split("://")[1].split("/")[0].toLowerCase();
				var playerName:String = MD5.hash(Math.random()+""+new Date()).slice(0,8) + "-"+domain;
				so.setProperty("playername",playerName);				
			}
			return so.data.playername;
		}
		
		static function get validPlayerName():Boolean {
			return Achievement.isGamejolt() || Achievement.isNewgrounds() || Achievement.isKongregate();
		}

	}
}
