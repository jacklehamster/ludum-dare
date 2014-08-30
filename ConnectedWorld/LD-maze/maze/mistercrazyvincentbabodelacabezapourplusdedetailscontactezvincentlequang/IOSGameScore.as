package  {
	import com.adobe.ane.gameCenter.GameCenterController;
	import flash.display.MovieClip;
	import com.adobe.ane.gameCenter.GameCenterLeaderboardEvent;
	
	public class IOSGameScore  implements IGameScore {

		public var gameCenter:GameCenterController;
		
		
		public function IOSGameScore(root:MovieClip):void {
			gameCenter = new GameCenterController(root);
			gameCenter.authenticate();
			
			gameCenter.addEventListener(GameCenterLeaderboardEvent.SUBMIT_SCORE_SUCCEEDED,
				function(e:GameCenterLeaderboardEvent):void {
					leaderboard();
				});
		}
		
		static public function get isSupported():Boolean
		{
			return GameCenterController.isSupported;
		}
		
		public function unlock(title:String,percentComplete:Number=1):void
		{
			gameCenter.submitAchievement(title,percentComplete*100);
		}
		
		public function postScore(score:Number):void
		{
			gameCenter.submitScore(score);
		}
		
		public function fetchScore():void
		{
			gameCenter.requestScores();
		}
		
		public function leaderboard():void
		{
			gameCenter.showLeaderboardView();
		}

	}
	
}
