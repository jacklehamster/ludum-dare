package
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.text.TextField;
	
	public class LD extends Sprite
	{
		static private const LD_NUMBER:Number = 31;
		
		static private const MAXDOWNLOADS:int = 15;
		static private const PAGING:int = 24;
		
		private var start:int = 0;
		private var url:String = "http://www.ludumdare.com/compo/ludum-dare-"+LD_NUMBER+"/?action=preview&q=&etype=&start=%start";
		private var prefix:String = "http://www.ludumdare.com/compo/ludum-dare-"+LD_NUMBER+"/?action=preview&uid=";
		private var imgprefix:String = "http://www.ludumdare.com/compo/wp-content/compo2/thumb/";
		private var entries:Array = [];
		private var pending:int = 0;
		private var fetchers:Array = [];

		private var tf:TextField = new TextField();
		
		public function LD()
		{
			addChild(tf);
			tf.multiline = true;
			tf.width = stage.stageWidth;
			tf.height = stage.stageHeight;
//			followUp({id:20841});
			
//			return;
			fetch();
		}
		
		
		
		public function fetch():void {
			pending++;
//			start = 2000;
			var u:String = url.replace("%start",start);
			//trace(u);
			start += PAGING;
			//trace(u);
//			urlloader.load(new URLRequest(u));
			var urlloader:URLLoader = new URLLoader();
			urlloader.addEventListener(Event.COMPLETE,onFetch);
			urlloader.addEventListener(IOErrorEvent.IO_ERROR,
				function(e:IOErrorEvent):void {
					trace(e);
					tf.appendText(e+"\n");
					tf.setSelection(tf.length,tf.length);
					inProgress--;
					prepare(urlloader,u);
				});
			prepare(urlloader,u);
		}
		
		private var inProgress:int = 0;
		private function prepare(loader:URLLoader,url:String):void {
			fetchers.push({loader:loader,url:url});
			process();
		}
		
		private function log(text:String):void {
			trace(text);
			tf.appendText(text+"\n");
			tf.setSelection(tf.length,tf.length);
		}
		
		private function process():void {
			if(inProgress<MAXDOWNLOADS) {
				var obj:Object = fetchers.pop();
				if(obj) {
					inProgress++;
					trace(pending,inProgress,obj.url);
					tf.appendText([pending,inProgress,obj.url]+"\n");
					tf.setSelection(tf.length,tf.length);
					
					obj.loader.load(new URLRequest(obj.url));
				}
			}
		}
		
		private function onFetch(e:Event):void {
			inProgress--;
			pending--;
			var data:String = ((e.currentTarget as URLLoader).data);
//			trace(data);
			
			var split:Array = data.split("<div><a href='?action=preview&uid=");
			var found:Boolean = false;
			for(var i:int=0;i<split.length;i++) {
				var chunk:String = (split[i].split("</a></div>")[0]);
				var id:int = parseInt(chunk.split("'")[0]);
				var img:String = chunk.split("<img src='")[1];
				if(!img) {
					continue;
				}
				img = img.split("'><div")[0];
				img = img.split(imgprefix)[1];
				if(isNaN(id)) {
					continue;
				}
				var title:String = chunk.split("class='title'><i>")[1].split("</i></div>")[0];
				var author:String = chunk.split("</i></div>")[1];
		
				log(title + " by " + author);
				
				followUp({id:id,link:prefix+id,title:title,author:author,img:imgprefix+img});
				found = true;
			}
			if(found) {
				fetch();
			}
			process();
			checkCompletion();
		}
		
		private function followUp(entry:Object):void {
			//prefix
			pending++;
			var followup:String = prefix + entry.id;
			var loader:URLLoader = new URLLoader();
			loader.addEventListener(Event.COMPLETE,
				function(e:Event):void {
					pending--;
					inProgress--;
					var data:String = (e.currentTarget as URLLoader).data;
					if(data.length) {
						var largeImg:String = data.split("<td colspan=4 align=center><a href='")[1].split("' target='_blank'>")[0];
						var links:String = data.split("<p class='links'>")[1].split("</p>")[0];
						var type:String = data.indexOf("<i>Jam Entry</i>")>=0 ? "Jam":"48h";
						var lnks:Array = [];
						for(var i:int=0;i<5;i++) {
							if(links.indexOf(" target='_blank'>")>0) {
	//							trace(links);
								var split0:Array = links.split(" target='_blank'>");
								var splita:Array = split0[1].split("</a>");
								//trace(splita[0]);
	//							trace(splita[0],split0[0]);
	//							var url:String = "";
								var url:String = split0[0].split("<a href=\"")[1].split('"')[0];
								links = split0.slice(1).join(" target='_blank'>");
								lnks.push([splita[0],url]);
							}
							else {
								break;
							}
						}
						
						var twiterDesc:String = data.split('" name="twitter:description"')[0].split("<meta content=").pop();
						
	//					trace(JSON.stringify(lnks,null,'\t'));
	//					trace(links);
						entry.large = largeImg;
						entry.links= lnks;
						entry.type = type;
						entries.push(entry);
						process();
						checkCompletion();
					}
					else {
						followUp(entry);
					}
				});
			//trace(followup);
//			loader.load(new URLRequest(followup));
			loader.addEventListener(IOErrorEvent.IO_ERROR,
				function(e:IOErrorEvent):void {
					trace(e);
					tf.appendText(e+"\n");
					tf.setSelection(tf.length,tf.length);
					inProgress--;
					prepare(loader,followup);
				});
			prepare(loader,followup);
		}
		
		private function checkCompletion():void {
			if(!pending) {
				//	the file ends up in our document directory
				var file:File = File.documentsDirectory.resolvePath("LD"+LD_NUMBER+".json");
				var stream:FileStream = new FileStream();
				stream.open(file,FileMode.WRITE);
				stream.writeUTFBytes(JSON.stringify(entries,null,'\t'));
				stream.close();
				trace("\nDONE");
				tf.appendText("\nDONE");
				tf.setSelection(tf.length,tf.length);
				log("File saved:\n"+file.nativePath);
			}
		}
	}
}