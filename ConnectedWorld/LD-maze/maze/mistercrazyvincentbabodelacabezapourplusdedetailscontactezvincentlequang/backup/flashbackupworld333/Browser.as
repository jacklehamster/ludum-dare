package {
	
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.events.Event;
	
	public class Browser {
		
		static function fixlink(base,link:String) {
			if(link.indexOf("http")==0) {
			}
			else if(link.indexOf("/")==0) {
				var usplit = base.split("/");
				link = usplit.slice(0,3).join("/") + link;
			}
			else {
				usplit = base.split("/");
				if(usplit.length>3) {
					usplit[usplit.length-1] = link;
				}
				else
					usplit.push(link);
				link = usplit.join("/");
			}
			return link;
		}
		
		public static function travel(url:String) {
			var stock:Array = [];
			var urlloader:URLLoader = new URLLoader();
			urlloader.addEventListener(Event.COMPLETE,
				function(e) {
					
					var str = (e.currentTarget.data);
					var array = str.split("<");
					var link = null;
					for(var i=0;i<array.length;i++)
					{
						var xml:XML = null;
						var split = array[i].split(">");
						
						for(var s=0;s<split.length;s++) {
							var m = (split[s].split('"'));
							for(var j=0;j<m.length;j++) {
								if(j%2==0 && s==0) {
									var att = m[j].split(" ");
									for(var k=0;k<att.length;k++) {
										var vsplit = att[k].split("=");
										if(vsplit[1]) {
											att[k] = [vsplit[0],'"'+vsplit[1]+'"'].join("=");
										}
									}
									m[j] = att.join(" ");
								}
								else if(j%2==1) {
									var string = m[j];
									if(m[j].indexOf(".swf")>=0) {
										stock.push(["flash",string]);
									}
									else if(m[j].indexOf(".jpg")>=0||m[j].indexOf(".gif")>=0) {
										stock.push(["img",string]);
									}
									else if(m[j].indexOf("http")==0) {
										stock.push(["link",string]);
									}
									else if(m[j].indexOf(".htm")>=0||m[j].indexOf(".php")>=0) {
										stock.push(["link",string]);
									}
								}
							}
							split[s] = m.join('"');
						}
	
						try
						{
							var block = "<"+split[0]+"/>";
							xml = new XML(block);
						}
						catch(e) {
							try {
								block = "<"+split[0]+">";
								xml = new XML(block);
							} catch(e2) {
							}
						}
						//if(array[i].indexOf("br")==0)
						//{
							//trace(array[i].split("\""));
							//trace("..." + array[i],"|",split[0],"|",split[1],"=>",xml);
						//}
						if(xml && xml.name()) {
							var sw = xml.name().toString().toUpperCase();
							switch(sw) {
								case "A":
									link = xml.@href;
									if(!link)
										link = xml.@HREF;
									link = fixlink(url,link);
									var tx = split[1];
									if(tx) {
										stock.push(["text",tx,link]);
									}
									break;
								case "IMG":
									if(xml.@src) {
										var src = fixlink(url,xml.@src);
										stock.push(["img",src,link]);
									}
									break;
								case "INPUT":
									var val = xml.@value;
									if(!val)
										val = xml.@VALUE;
									var type = xml.@type;
									if(!type)
										type = xml.@TYPE;
									stock.push(["input",val,null,type]);
									break;
								case "P":
								case "BR":
									stock.push("---",split[1]);
									break;
								default:
									if(split[1] && split[1].replace(/^\s+|\s+$/g, ""))
										stock.push(["text",split[1],null,sw]);
									break;
							}
						}
						else switch(split[0].toUpperCase()) {
							case "a/":
								link = null;
								break;
							default:
								if(split[1] && split[1].replace(/^\s+|\s+$/g, ""))
									stock.push(["text",split[1],null,split[0].toUpperCase()]);
								break;
						}
					}
					
					trace(stock.join("\n"));
				});
			urlloader.load(new URLRequest(url));
		}		
	}
}