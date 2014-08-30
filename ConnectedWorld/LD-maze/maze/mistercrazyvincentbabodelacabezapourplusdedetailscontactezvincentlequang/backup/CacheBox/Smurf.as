package
{
	import flash.display.MovieClip;
	public class Smurf extends MovieClip
	{
		static var count = 0;
		function Smurf()
		{
			count++;
			trace(count);
			gotoAndPlay(int(Math.random()*totalFrames));
		}
	}	
}