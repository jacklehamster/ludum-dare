package  {
	
	public class RandSeedCacher {

		private var cacher:Object = {};
		private var list:Array = [];
		
		static public const instance:RandSeedCacher = new RandSeedCacher();
		
		public function seed(str:String):Array {
			var result:Array = cacher[str];
			if(!result) {
				var md5:String = MD5.hash(str);
				result = [
					(uint) (parseInt(md5.substr(0,8),16)),
					(uint) (parseInt(md5.substr(8,8),16)),
					(uint) (parseInt(md5.substr(16,8),16)),
					(uint) (parseInt(md5.substr(24,8),16))
				];

				cacher[str] = result;
				list.push(str);
				if(list.length>1000) {
					clean();
				}
			}
			return result;
		}
		
		private function clean():void {
			var array:Array = list.splice(0,100);
			for each(var str:String in array) {
				delete cacher[str];
			}
		}
	}
	
}
