package
{
	import com.dobuki.ConnectedBattlefield;
	import com.dobuki.ConnectedWorld;
	import com.dobuki.Mozart;
	
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.utils.setTimeout;
	
	import playerio.RoomInfo;
	
	[SWF(width="600",height="450",frameRate="45")]
	public class ConnectedWorldTester extends Sprite
	{
		private var cw:ConnectedBattlefield;
		private var canvas:Sprite = new Sprite();
		
		private function getUserId():String {
			return "dunki"+Math.random();
		}
		
		private var count:int = 0;
		
		public function ConnectedWorldTester()
		{
			addChild(canvas);
			canvas.x = stage.stageWidth/2;
			canvas.y = stage.stageHeight/2;
			graphics.beginFill(0xccFFcc);
			graphics.drawRect(0,0,stage.stageWidth,stage.stageHeight);
			graphics.endFill();
			
			var user_id:String = getUserId();
			
			cw = new ConnectedBattlefield(canvas,user_id);
			cw.createUnit(user_id+(count++),"general",new Point());
//			cw.enterWorld("paris");
			setTimeout(
				cw.listWorlds,1000,
				function(array:Array) {
					for each(var roomInfo:RoomInfo in array) {
						trace(roomInfo.id);
					}
				});
//			cw.enterWorld("paris");
//			cw.enterWorld("paris2");
			Mozart.instance.play(123);
		}
	}
}