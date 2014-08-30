package {
	import flash.geom.Point;
	import flash.system.Security;
	import flash.events.EventDispatcher;
	
	public class Map extends EventDispatcher implements IMap {

		protected function defaultWall():String {
			return "default";
		}
		
		protected function defaultGround():String {
			return "default";
		}
		
		public function getStartingPoint():Point {
			return new Point();
		}

		public function getWallByID(wallID:String):String {
			return defaultWall();
		}
		
		protected function getGroundByID(groundID:String):String {
			return defaultGround();
		}

		protected function getObjectsAtID(groundID):Array {
			return [];
		}
		
		static function transcode(xd:int,yd:int,xyd:int,yxd:int,xx:int,yy:int) {
			var xpart:int = xx*xd+yy*xyd;
			var ypart:int = yy*yd+xx*yxd;
			return xpart<0?'E':xpart>0?'W':ypart<0?'N':ypart>0?'S':'';
		}
		
		public function canGo(fromx:int,fromy:int,fromh:int,tox:int,toy:int,toh:int):Boolean {
			return true;
		}
		
		protected function getPositionAtGID(gid:String):Object {
			var split:Array = gid.split("|");
			return {x:split[1],y:split[2],h:split[3],wallType:split[4]};
		}
		
		public function getMap(xpos:int,ypos:int,hpos:int,idir:int,approach:*,mode:int):Array {
			var array:Array = [];
			
			var xd:int, yd:int, xyd:int, yxd:int;
			switch(idir) {
				case 0: xd=1;yd=1;xyd=0;yxd=0;break;
				case 1: xd=0;yd=0;xyd=1;yxd=-1; break;
				case 2: xd=-1;yd=-1;xyd=0;yxd=0; break;
				case 3: xd=0;yd=0;xyd=-1;yxd=1; break;
			}
			var ylimit:int = 3+(mode==1?1:0);
			var SIDE4:Array = [['L',new Point(-1,0)],['R',new Point(1,0)],['F',new Point(0,-1)],['B',new Point(0,1)]];
			
			for(var yi=approach||mode==2?-1:0;yi<=ylimit;yi++) {
				var xlimit:int = 2+Math.max(0,yi*2)+(mode==2?3:0);
				for(var xi=-xlimit;xi<=xlimit;xi++) {
					var px:int = xi*xd+yi*xyd+xpos;
					var py:int = yi*yd+xi*yxd+ypos;
					var ph:int = hpos;
					var positionID:String = ["#",px,py,ph].join("|");
					var ggid:String = positionID+"|D";
					var groundCode:String= getGroundByID(ggid);
					
					if(groundCode) {
						var floor:Array = [xi,yi,-1,'D',['D',xi,yi,-1].join("|"),positionID+"|F","Block"];
						if(groundCode != "default") {
							floor.push("loadwall");
							floor = floor.concat(groundCode.split("|"));
						}
//						trace("floor>",floor);
						array.push(floor);
						var ixp:int, iyp:int, xxp:Number, yyp:Number;
						if(px==1&&py==1 && false) {
							ixp = 1-xpos;
							iyp = 1-ypos;
							xxp = ixp*xd-iyp*xyd;
							yyp = iyp*yd-ixp*yxd-.5;
							//var a:Array = [xxp,yyp,0,"I",MD5.hash(Math.random()+""),positionID+"|I","Item","load","jopi.swf","JopiCharacter"];
//							var a:Array = [xxp,yyp,0,"I","pokeball",positionID+"|I","Item","load","Pokeball.swf","Pokeball"];
//							array.push(a);
							var a:Array = [xxp,yyp,0,"I","jopi",positionID+"|I","Item","load","jopi.swf","JopiCharacter"];
							array.push(a);
						}
					}
					for(var i=0;i<SIDE4.length;i++) {
						if(i<2 || yi>=0) {
							var s4 = SIDE4[i];
							ggid = positionID+"|"+transcode(xd,yd,xyd,yxd,s4[1].x,s4[1].y);
							var wallCode:String= getWallByID(ggid);
							if(wallCode) {
								var xp:Number = xi+s4[1].x*.5;
								var yp:Number = yi+s4[1].y*.5-(i<2?0:.5);
								var sid:String = [s4[0],xp,yp,0].join("|");
								var cell:Array = [xp,yp,0,s4[0],sid,ggid,i<2?"Block":"FrontWall"];
								if(wallCode!="default") {
									cell.push("loadwall");
									cell = cell.concat(wallCode.split("|"));
								}
								array.push(cell);
							}
						}
					}
					
					var objs:Array = getObjectsAtID(positionID+"|I");
					if(objs) {
//						trace(positionID,objs);
//						var ixp:int, iyp:int, xxp:Number, yyp:Number;
						for each(var obj:String in objs) {
							var objInfo:Object = obj.split("|");
							var swf:String = objInfo[0];
							var className:String = objInfo[1];
							var objID:String = objInfo[2];
							var posX:Number = objInfo[3]!==undefined?parseFloat(objInfo[3]):px;
							var posY:Number = objInfo[4]!==undefined?parseFloat(objInfo[4]):py;
							var posH:Number = objInfo[5]!==undefined?parseFloat(objInfo[5]):0;
							var label:String = objInfo[6];
							var params:Array = objInfo.slice(7);
							var iixp:Number = posX-xpos;
							var iiyp:Number = posY-ypos;
							xxp = iixp*xd-iiyp*xyd;
							yyp = iiyp*yd-iixp*yxd-.5;
//							trace(xxp,yyp,positionID,xpos,ypos);
//							var a:Array = [xxp,yyp,0,"I","jopi",positionID+"|I","Item","load","jopi.swf","JopiCharacter"];
							a = [xxp,yyp,posH,"I",objID?objID:MD5.hash(positionID),positionID+"|I","Item","load",swf,className,label].concat(params);
							array.push(a);
						}
					}
					/*
					var objs = getGroundObjects(px,py,ph);
//					trace([px,py,ph],"<<<<");
					if(objs) {
						for(var o in objs) {
							//trace(o);
							var list = objs[o];
							for(i=0;i<list.length;i++) {
								var l = list[i];
								ixp = px-xpos + (l[1]?parseInt(l[1])/10:0);//4.8-xpos;
								iyp = py-ypos + (l[2]?parseInt(l[2])/10:0);//2.2-ypos;
								xxp = ixp*xd-iyp*xyd;
								yyp = iyp*yd-ixp*yxd-.5;
								var entry:Array = [xxp,yyp,0,null,positionID+"|"+l[0],positionID+"|"+l[0],l[0],"unique"];
								//trace("object>",entry);
								array.push(entry);
//w								trace(gid,l[0],xxp,yyp);
//									trace([xxp,yyp,0,null,gid+"|d12"+l[0],gid+"|d13"+l[0],l[0],"unique"]);
							}
						}
					}
					*/
				}
			}
			
			return array;
		}

	}
	
	
}