package com.dobuki
{
	import flash.events.Event;
	import flash.utils.ByteArray;
	
	import playerio.Client;
	import playerio.Connection;
	import playerio.Message;
	import playerio.PlayerIO;
	import playerio.PlayerIOError;

	public class World
	{
		public var world_id:String;
		private var connection:Connection;
		private var delegate:ConnectedWorld;
		
		public var timeEntered:int;
		
		public function World()
		{
		}
				
		public function get connected():Boolean {
			return connection!=null;
		}
		
		private function handleError(error:PlayerIOError):void{
			trace(error);
		}
		
		private function handleConnect(client:Client):void {
			client.multiplayer.createJoinRoom(world_id,"bounce",true,{},{},onJoin,handleError);
		}
		
		public function connect(world_id:String,delegate:ConnectedWorld):void {
			this.delegate = delegate;
			this.world_id = world_id;
			if(delegate.client) {
				handleConnect(delegate.client);
			}
			else {
				delegate.addEventListener(Event.CONNECT,
					function(e:Event):void {
						e.currentTarget.removeEventListener(e.type,arguments.callee);
						handleConnect(delegate.client);
					});
			}
		}
		
		private function onJoin(connection:Connection):void {
			trace("Sucessfully joined room:",connection.roomId);
			var self:World = this;
			connection.addMessageHandler("action",function(m:Message,id:String,action:String,bytes:ByteArray,user:String):void {
				var data:Object = bytes.readObject();
				delegate.onAction(id,action,data,user,self);
			});
			this.connection = connection;	
		}
		
		public function action(id:String,action:String,data:Object):void
		{
			if(connection) {
				var bytes:ByteArray = new ByteArray();
				bytes.writeObject(data);
				connection.send("action",id,action,bytes,delegate.user_id);
			}	
		}
		
		public function disconnect():void {
			connection.disconnect();
			connection = null;
		}
	}
}