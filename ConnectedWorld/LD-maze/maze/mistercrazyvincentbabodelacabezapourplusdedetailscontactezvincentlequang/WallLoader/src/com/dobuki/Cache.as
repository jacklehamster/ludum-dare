package com.dobuki
{
	public class Cache {
		
		static public var instance:Cache = new Cache();
		
		private var hash:Object = {};
		
		public function set(key:String,type:String,object:Object):void
		{
			if(!hash[type]) {
				hash[type] = {};
			}
			hash[type][key] = object;
		}
		
		public function get(key:String,type:String):Object
		{
			return hash[type] ? hash[type][key] : null;
		}
		
		public function has(key:String,type:String):Boolean
		{
			return hash[type] && hash[type][key];
		}
		
	}
}