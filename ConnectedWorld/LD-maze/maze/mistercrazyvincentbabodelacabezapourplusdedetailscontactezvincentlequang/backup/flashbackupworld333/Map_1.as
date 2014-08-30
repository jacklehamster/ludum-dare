package
{
	import flash.utils.getTimer;
	import flash.geom.Point;
	
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	public class Map
	{
		var pos:Object = {};
		function Map() {
			
		}
		
		public function hasGround(px:int,py:int):Boolean {
			var id:String = px+"|"+py;
			if(id in pos)
				return pos[id];
			var mt:int = (px^py)+1;//^(hi+hpos);
			return Boolean((Math.abs(mt)%3)||!(Math.abs(mt)%7)||!(Math.abs(mt)%13)||!(Math.abs(mt)%1978));
		}
		
		public function getGround(px:int,py:int) {
			var id:String = px+"|"+py;
			return pos[id];
		}
		
		public function setGround(px:int,py:int,value):void {
			var id:String = px+"|"+py;
			pos[id] = value;
		}
		
		static function transcode(xd:int,yd:int,xyd:int,yxd:int,xx:int,yy:int) {
			var xpart:int = xx*xd+yy*xyd;
			var ypart:int = yy*yd+xx*yxd;
			return xpart<0?'E':xpart>0?'W':ypart<0?'N':ypart>0?'S':'';
		}
		
		public function getMap(xpos:int,ypos:int,hpos:int,idir:int,approach,mode:int):Array {
			var array:Array = [];
			
			var xd:int, yd:int, xyd:int, yxd:int;
			switch(idir) {
				case 0: xd=1;yd=1;xyd=0;yxd=0;break;
				case 1: xd=0;yd=0;xyd=1;yxd=-1; break;
				case 2: xd=-1;yd=-1;xyd=0;yxd=0; break;
				case 3: xd=0;yd=0;xyd=-1;yxd=1; break;
			}
			var ylimit:int = approach?0:3+(mode==1?1:0);
			var SIDE4:Array = [['L',new Point(-1,0)],['R',new Point(1,0)],['F',new Point(0,-1)],['B',new Point(0,1)]];

			for(var yi=approach||mode==2?-1:0;yi<=ylimit;yi++) {
				var xlimit:int = approach?0:2+Math.max(0,yi*2)+(mode==2?3:0);
				for(var xi=-xlimit;xi<=xlimit;xi++) {
					var px:int = xi*xd+yi*xyd+xpos;
					var py:int = yi*yd+xi*yxd+ypos;
					var gid:String = ["#",px,py].join("|");
					if(hasGround(px,py)) {
						array.push([xi,yi,-1,'D',['D',xi,yi,-1].join("|"),gid+"|F","Block"]);
						if(mode==1)
							array.push([xi,yi, 1,'U',['U',xi,yi, 1].join("|"),gid+"|C","Block"]);
						if(px==1&&py==1) {
							var ixp = 1-xpos;
							var iyp = 1-ypos;
							var xxp = ixp*xd-iyp*xyd;
							var yyp = iyp*yd-ixp*yxd-.5;
							//trace(xxp,yyp);//[type,xi,yi].join(",")
							//array.push([xxp,yyp,0,null,"smurfy","smurfy","SmurfBMP"]);
							array.push([xxp,yyp,0,null,"jopi.swf",gid+"|"+"jopi.swf","jopi.swf","load"]);
						}
						else if(px==5&&py==3) {
							ixp = 5.2-xpos;//+getTimer()/10000;
							//trace(getTimer()/1000);
							iyp = 2.7-ypos;
							xxp = ixp*xd-iyp*xyd;
							yyp = iyp*yd-ixp*yxd-.5;
							array.push([xxp,yyp,0,null,"d12",gid+"|"+"d12","Dude12"]);
							ixp = 4.8-xpos;//+getTimer()/10000;
							//trace(getTimer()/1000);
							iyp = 2.2-ypos;
							xxp = ixp*xd-iyp*xyd;
							yyp = iyp*yd-ixp*yxd-.5;
							array.push([xxp,yyp,0,null,"d13",gid+"|"+"d13","Dude13"]);
						}
						/*else if(px==9&&py==14) {
							ixp = 9.2-xpos;//+getTimer()/10000;
							iyp = 14.2-ypos;
							xxp = ixp*xd-iyp*xyd;
							yyp = iyp*yd-ixp*yxd-.5;
							array.push([xxp,yyp,0,null,"pixoo",gid+"|"+"pixoo","Pixoo"]);						
						}*/
					}
					else {
						///*
						for(var i=0;i<SIDE4.length;i++) {
							//if(approach&&i!=2)
								//continue;
							
							if(i<2 || yi>=0) {
								var s4 = SIDE4[i];
								var xp:Number = xi+s4[1].x*.5;
								var yp:Number = yi+s4[1].y*.5-(i<2?0:.5);
								var sid:String = [s4[0],xp,yp,0].join("|");
								var ggid:String = gid+"|"+transcode(xd,yd,xyd,yxd,s4[1].x,s4[1].y);
								var cell:Array = [xp,yp,0,s4[0],sid,ggid,i<2?"Block":"FrontWall"];
								if(ggid=="#|-1|3|N") {
									cell[7]="loadwall";
									cell[8]="graph.swf";
								}
								else if(ggid=="#|0|-10|S") {
									cell[7]="loadwall";
									cell[8]="ut.swf";
									cell[9]="7syauAfRtRA";
									//cell[10]="Chatworld Beta v.1";
									//cell[11]="chatworld.swf";
								}
							//trace(s4,xp);
								array.push(cell);
							}
						}
						/*/
						array.push([xi-.5,yi,0,'L',['L',xi-.5,yi,0].join("|"),gid+"|"+transcode(xd,yd,xyd,yxd,-1,0),"Block"]);
						array.push([xi+.5,yi,0,'R',['R',xi+.5,yi,0].join("|"),gid+"|"+transcode(xd,yd,xyd,yxd,1,0),"Block"]);
						if(yi>=0) {
							array.push([xi,yi,0,'B',['B',xi,yi,0].join("|"),gid+"|"+transcode(xd,yd,xyd,yxd,0,1),"FrontWall"]);
							array.push([xi,yi-1,0,'F',['F',xi,yi-1,0].join("|"),gid+"|"+transcode(xd,yd,xyd,yxd,0,-1),"FrontWall"]);
						}
						//*/
					}
				}
			}
			return array;
		}
	}
}