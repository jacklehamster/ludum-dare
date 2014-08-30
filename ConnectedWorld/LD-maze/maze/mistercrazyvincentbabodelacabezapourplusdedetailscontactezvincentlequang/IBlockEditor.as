package  {
	
	public interface IBlockEditor {

		function setBlock(px:int,py:int,ph:int,value:Boolean):void;
		
		function getBlock(px:int,py:int,ph:int):Boolean;

	}
	
}
