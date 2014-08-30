package  {
	
	public interface IGameScore {

		function unlock(title:String,percentComplete:Number=1):void;
		function postScore(score:Number):void;
		function fetchScore():void;
		function leaderboard():void;
	}
	
}
