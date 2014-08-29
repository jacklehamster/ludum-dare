package com.dobuki
{
	public interface IDelegate
	{
		function refresh(world:ConnectedBattlefield):void;
		function wonder(title:String,mine:Boolean):void;
	}
}