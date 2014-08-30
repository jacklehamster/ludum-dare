package  {
	import playerio.Client;
	import playerio.Connection;
	import flash.display.Stage;
	import playerio.PlayerIO;
	import playerio.PlayerIOError;
	import playerio.Message;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.utils.ByteArray;
	import flash.net.URLRequest;
	import flash.media.Sound;
	import flash.media.SoundTransform;
	
	public class NetworkedLudumMap extends LudumMap {

		static public var gameType:String = "bounce";
		static public var gameId:String = "ludum-maze-wowd18ch7eys0rxfbjac7q";
		static public var online:Boolean = true;
		static public var ip_address:String = "172.16.73.128:8184";
		
		private var client:Client, xpos:int=0,ypos:int=0,hpos:int=0;
		private var connections:Object = {};
		private var joining:Object = {};
		private var currentConnection:Connection;
		
		public function NetworkedLudumMap(stage:Stage,link:String,seed:String="") {
			super(link,seed);
			PlayerIO.connect(
				stage,								//Referance to stage
				gameId,								//Game id (Get your own at playerio.com. 1: Create user, 2:Goto admin pannel, 3:Create game, 4: Copy game id inside the "")
				"public",							//Connection id, default is public
				Achievement.playerName,				//Username
				"",									//User auth. Can be left blank if authentication is disabled on connection
				null,								//Current PartnerPay partner.
				handleConnect,						//Function executed on successful connect
				handleError							//Function executed if we recive an error
			);
			GlobalDispatcher.instance.addEventListener(PositionEvent.MOVEPOSITION,
				function(e:PositionEvent):void {
					if(currentConnection)
						currentConnection.send("move",Achievement.playerName,e.data.x,e.data.y,e.data.dir);
				});
			GlobalDispatcher.instance.addEventListener(NetworkEvent.SEND_ACTION,
				function(e:NetworkEvent):void {
					if(currentConnection) {
						var bytes:ByteArray = new ByteArray();
						bytes.writeObject(e.data);
						currentConnection.send("action",Achievement.playerName,e.action,bytes,e.loopback);
					}
				});
			GlobalDispatcher.instance.addEventListener("chat",
				function(e:NetworkEvent):void {
					var data:Object = e.data;
//					if(data.to==Achievement.playerName) {
						var slimePoint:Point = new Point(e.data.position.x,e.data.position.y);
						var dist:Number = Point.distance(slimePoint,GlobalMess.instance.position);
						if(dist<100) {
							var title:String = data.text;
							var s:String = "http://vincent.netau.net/proxy.php?q="+encodeURIComponent(title);				
							var sound:Sound = new Sound(new URLRequest(s));
							sound.play(0,0,new SoundTransform(Math.max(Math.min(100/dist,1),.1)));
						}
//					}
				});
			stage.addEventListener(Event.ENTER_FRAME,
				function(e:Event):void {
					refreshPlayers();
				});
		}
		
		private function handleError(error:PlayerIOError):void{
			trace(error);
		}
		
/*		override public function getMap(xpos:int,ypos:int,hpos:int,idir:int,approach,mode:int):Array {
			this.xpos = xpos;
			this.ypos = ypos;
			this.hpos = hpos;
			updateRooms();
			return super.getMap(xpos,ypos,hpos,idir,approach,mode);
		}*/
		
/*		public function sendMessage(message:Object):void {
			if(message.type=="comment") {
				trace(JSON.stringify(message));
				var roomX:int = Math.round(xpos/100);
				var roomY:int = Math.round(ypos/100);
				var roomID:String = "room_"+roomX+"_"+roomY;
				var connection:Connection = connections[roomID];
				if(connection) {
					connection.send("comment",message.wallID,message.message,message.author);
				}
			}
		}
		*/
				
				/*
		private function updateRooms():void {
			var roomX:int = Math.round(xpos/100);
			var roomY:int = Math.round(ypos/100);
			var roomsToJoin:Object = {};
			for(var rY:int=-1;rY<=1;rY++) {
				for(var rX:int=-1;rX<=1;rX++) {
					var roomID:String = "room_"+(roomX+rX)+"_"+(roomY+rY);					
					roomsToJoin[roomID] = true;
					if(rX==0 && rY==0) {
						var connection:Connection = connections[roomID];
						if(!connection) {
							joinRoom(roomID);
						}
					}
				}
			}
			for(roomID in connections) {
				if(!roomsToJoin[roomID]) {
					leaveRoom(roomID);
				}
			}
		}*/
		
		private function leaveRoom(room:String):void {
			trace("Leaving ",room);
			(connections[room] as Connection).disconnect();
			delete connections[room];
		}
		
		private function joinRoom(room:String):void {
			if(!client)
				return;
			if(!joining[room] && !connections[room]) {
				trace("Joining ",room);
				joining[room] = true;
				client.multiplayer.createJoinRoom(
					room,								//Room id. If set to null a random roomid is used
					gameType,							//The game type started on the server
					true,								//Should the room be visible in the lobby?
					{},									//Room data. This data is returned to lobby list. Variabels can be modifed on the server
					{},									//User join data
					handleJoin,							//Function executed on successful joining of the room
					handleError							//Function executed if we got a join error
				);			
			}
		}
		
		private function handleConnect(client:Client):void{
			trace("Sucessfully connected to Yahoo Games Network");
			this.client = client;
			//Set developmentsever (Comment out to connect to your server online)
			if(!online)
				client.multiplayer.developmentServer = ip_address;
//			updateRooms();
			joinRoom("LD30");
		}
		
		private var players:Object = {};
		
		private function handleJoin(connection:Connection):void{
			delete joining[connection.roomId];
			connections[connection.roomId] = connection;
			
			trace("Sucessfully connected to the multiplayer room "+connection.roomId);
			currentConnection = connection;
			connection.addMessageHandler("move",function(m:Message,player:String,x:int,y:int,dir:int):void {
				if(player!=Achievement.playerName) {
					if(!players[player]) {
						players[player] = {id:player,position:{x:x,y:y},dir:dir};
					}
					players[player].goal = {x:x,y:y,dir:dir};
					players[player].dir = dir;
				}
				GlobalDispatcher.instance.dispatchEvent(new PositionEvent(PositionEvent.TRACE,{x:x,y:y}));

			});
			connection.addMessageHandler("action",function(m:Message,player:String,action:String,bytes:ByteArray,loopback:Boolean):void {
				if(player!=Achievement.playerName || loopback) {
					var data:Object = bytes.readObject();
					GlobalDispatcher.instance.dispatchEvent(new NetworkEvent(action,action,data,loopback));
					trace(player,Achievement.playerName,action,JSON.stringify(data),loopback);
				}
			});
/*			connection.addMessageHandler("comment",function(m:Message):void {
				for(var i:int=0;i<m.length;i+=4) {
					var wallID:String = m.getString(i+0);
					trace(wallID);
					var comment:String = m.getString(i+1);
					trace(comment);
					var author:String = m.getString(i+2);
					trace(author);
					var extra:String = i+3<m.length? m.getString(i+3):"";
					
					setWall(wallID,"comment.swf|"+comment+"|"+author+"|true");
				}
			});*/
		}
		
		private function refreshPlayers():void {
			for each(var p:Object in players) {
				if(p.goal) {
					var dx:Number = p.goal.x-p.position.x;
					var dy:Number = p.goal.y-p.position.y;
					var dist:Number = Math.sqrt(dx*dx+dy*dy);
					if(dist) {
						p.position.x += dx/dist * Math.min(.1,dist);
						p.position.y += dy/dist * Math.min(.1,dist);
					}
					if(dist<.1) {
						p.position = p.goal;
						p.goal = null;
					}
				}
			}
		}
		
		override protected function getObjectsAtID(groundID):Array {
			var array:Array = super.getObjectsAtID(groundID);
			if(!array)
				array = [];
			var position:Object = getPositionAtGID(groundID);
			for each(var p:Object in players) {
				if(Math.round(p.position.x)==position.x && Math.round(p.position.y)==position.y) {
					array.push(["Pokeball.swf","Slimo",p.id,p.position.x,p.position.y,1,p.goal?"AIR":"",p.id].join("|"));
				}
			}
			return array;
			
/*			var position:Object = getPositionAtGID(groundID);
			if(hasGround(position.x,position.y,position.h)) {
				var rand:uint = RandSeedCacher.instance.seed(groundID)[0];
				if(rand%100<10) {
					return ["Pokeball.swf|Pokeball"];
				}
			}
			return null;*/
		}
		
		
	}
	
}
