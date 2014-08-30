package
{
	import flash.display.MovieClip;
	public class Smurf extends MovieClip
	{
		function Smurf()
		{
			gotoAndPlay(int(Math.random()*totalFrames));
		}
	}	
}