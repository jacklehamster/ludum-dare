package com.dobuki
{
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.geom.Point;
	import flash.utils.getTimer;
	import flash.utils.setInterval;
	import flash.utils.setTimeout;
	
	import playerio.Client;
	import playerio.PlayerIO;
	import playerio.PlayerIOError;

	[Event(name="connect", type="flash.events.Event")]
	public class ConnectedWorld extends EventDispatcher
	{
		public var clock:int = 0;
		public static const GAME_ID:String = "connectedworld-cpzhnfcmey7fojh4xsrjw";
		static public const online:Boolean = true;
		private static const MAXCONNECTEDWORLDS:int = 4;
		public var client:Client;
		
		private var worlds:Object = {}, worldCount:int = 0;

		protected var stage:Stage;
		public var user_id:String;
		protected var canvas:Sprite;
		protected var underCanvas:Sprite = new Sprite();
				
		public function ConnectedWorld(canvas:Sprite,user_id:String)
		{
			this.canvas = canvas;
			this.stage = canvas.stage;
			this.user_id = user_id;
			connect(stage,user_id);
			setInterval(heartbeat,1000);
			stage.addEventListener(Event.ENTER_FRAME,
				function(e:Event):void {
					display(canvas);
				});
		}
		
		
		
		protected function refresh():void {
		}
		
		protected function display(canvas:Sprite):void {			
			canvas.addChildAt(underCanvas,0);
		}
		
		private function heartbeat():void {
			for each(var world:World in worlds) {
				//world.action(user_id,"heartbeat",null);
			}
			refresh();
		}
		
		public function connect(stage:Stage,user:String):void {
			
			PlayerIO.connect(
				stage,								//Referance to stage
				ConnectedWorld.GAME_ID,							//Game id (Get your own at playerio.com. 1: Create user, 2:Goto admin pannel, 3:Create game, 4: Copy game id inside the "")
				"public",							//Connection id, default is public
				user,								//Username
				"",									//User auth. Can be left blank if authentication is disabled on connection
				null,								//Current PartnerPay partner.
				handleConnect,						//Function executed on successful connect
				handleError							//Function executed if we recive an error
			);
		}
		
		private function handleError(error:PlayerIOError):void{
			trace(error);
		}
		
		private function handleConnect(client:Client):void {
			trace("Sucessfully connected to Yahoo Games Network");
			this.client = client;
			dispatchEvent(new Event(Event.CONNECT));
		}
				
		public function listWorlds(callback:Function):void {
			if(!client) {
				addEventListener(Event.CONNECT,
					function(e:Event):void {
						e.currentTarget.removeEventListener(e.type,arguments.callee);
						listWorlds(callback);
					});
				return;
			}
			client.multiplayer.listRooms("bounce",{},10,0,callback);
		}
		
		public function enterWorld(world_id:String):World {
			if(!worlds[world_id]) {
				worldCount++;
				var world:World = worlds[world_id] = new World();
				world.timeEntered = getTimer();
				world.connect(world_id,this);
				if(worldCount>4) {
					//	remove oldest world
					var oldestWorld:World = world;
					for(var w_id:String in worlds) {
						var w:World = worlds[w_id];
						if(w.timeEntered<oldestWorld.timeEntered) {
							oldestWorld = w;
						}
					}
					oldestWorld.disconnect();
					delete worlds[oldestWorld.world_id];
					worldCount--;
				}
			}
			else {
				world.timeEntered = getTimer();
			}
			return world;
		}
		
		public function broadcast(point:Point,id:String,action:String,data:Object):void {
			if(point) {
				var w_id:String = Math.round(point.x/1000)+"_"+Math.round(point.y/1000);
				var world:World = worlds[w_id];
				if(world)
					world.action(id,action,data);
			}
			else {
				for each(world in worlds) {
					world.action(id,action,data);
				}
			}
		}
		
		public function setWorld(x:Number,y:Number):void {
			var w_id:String = Math.round(x/1000)+"_"+Math.round(y/1000);
			var world:World = worlds[w_id];
			if(!world)
			{
				enterWorld(w_id);
			}
		}
		
		public function onAction(id:String,action:String,data:Object,user:String,world:World):void {
//			trace(user_id,">>",id,action,JSON.stringify(data),world.world_id);
		}
	}
}