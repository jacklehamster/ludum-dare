package com.dobuki.unittype
{
	import com.dobuki.ConnectedBattlefield;
	import com.dobuki.Unit;
	import com.dobuki.World;
	
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.media.Sound;
	import flash.media.SoundTransform;
	import flash.utils.getDefinitionByName;

	public class SlimeType extends UnitType
	{
		[Embed(source="../music/aio_01.mp3")]
		private const Voice:Class;
		public var voice:Sound = new Voice();
		
		
		static public const NONE:String = "none";
		static public const HUNGRY:String = "hungry";
		static public const EATING:String = "eating";
		static public const LONELY:String = "lonely";
		static public const TALKING:String = "talking";
		static public const HORNY:String = "horny";
		static public const MATING:String = "mating";
		static public const PREGNANT:String = "pregnant";
		static public const RESTING:String = "restings";
		
		override public function get Graphics():Class {
			return getDefinitionByName("Slime") as Class;
		}
		
		override public function get defaultScale():Number {
			return .1;
		}
		
		public function SlimeType()
		{
			super();
		}
		
		override public function isVisible(unit:Unit):Boolean {
			return unit.state!=EATING && unit.state!=MATING && unit.state!=RESTING;
		}
		
		override public function get cost():int {
			return 10;
		}
		
		override public function calculatePopCount(unit:Unit,world:ConnectedBattlefield):int {
			return 1;
		}
		
		override public function initUnit(unit:Unit,world:ConnectedBattlefield):void {
			super.initUnit(unit,world);
			if(unit.user==world.user_id) {
				unit.goal = null;
				unit.state = NONE;
				unit.data.lunchTime = 0;
			}
		}
		
		public function radius(unit:Unit):Number {
			return Math.log(unit.age+2)+(unit.state==HORNY||unit.state==HUNGRY||unit.state==LONELY?150:100);
		}
		
		override public function refresh(unit:Unit,world:ConnectedBattlefield):void {
			super.refresh(unit,world);
			if(unit.state==TALKING && Math.random()<.2) {
				voice.play(0,1,new SoundTransform(.1));
			}
			if(unit.user==world.user_id) {
				if(!unit.goal) {
					if(world.clock - unit.lastStateChange>10000) {
						
						if(unit.state==LONELY) {
							if(world.clock - unit.data.lunchTime>60000) {
								unit.state = HUNGRY;
							}
						}
						
						switch(unit.state) {
							case NONE:
								unit.state = HUNGRY;
								break;
							case HUNGRY:
								lookForTree(unit,world);
								break;
							case EATING:
								unit.data.lunchTime = world.clock;
								unit.state = LONELY;
								var tree:Unit = world.findUnit(unit.data.tree);
								tree.state = TreeType.FREE;
								tree.data.food--;
								unit.position.offset(0,5);
								delete unit.data.tree;
								tree.broadcastUnit();
								break;
							case LONELY:
								lookForMate(unit,world);
								break;
							case TALKING:
								unit.goal = unit.position.add(new Point(Math.random()*10-5,Math.random()*10-5));
								unit.state = HORNY;
								break;
							case HORNY:
								lookForSexSpot(unit,world);
								break;
							case MATING:
								var nest:Unit = world.findUnit(unit.data.nest);
								if(nest.state==HouseType.FULL && world.clock-nest.data.started>10000) {
									doneReproducing(nest);
									doneMating(world.findUnit(unit.data.mate),PREGNANT);
									doneMating(unit,PREGNANT);
								}
								break;
							case PREGNANT:
								lookForHome(unit,world);
								break;
							case RESTING:
								unit.state = NONE;
								break;
						}
					}
					
					if(!unit.goal && unit.isVisible && unit.state!=TALKING) {
						var rad:Number = radius(unit);
						var angle:Number = Math.random()*Math.PI*2;
						unit.goal = new Point(unit.parent.position.x+Math.cos(angle)*rad,unit.parent.position.y+Math.sin(angle)*rad);
					}
				}
			}
		}
		
		private function doneMating(unit:Unit,state:String):void {
			delete unit.data.mate;
			delete unit.data.nest;
			unit.state = state;
			unit.position.offset(0,5);
			unit.broadcastUnit();
		}
		
		private function doneReproducing(nest:Unit):void {
			nest.state = HouseType.FREE;
			delete nest.data.started;
			nest.broadcastUnit();
		}
		
		private function lookForHome(unit,world):void {
			var home:Unit = unit.parent;
			if(Unit.distance(unit,home)<20) {
				unit.state = RESTING;
				home.data.startedReproduction = world.clock;
			}
			else {
				unit.goal = home.position;
			}
		}
		
		private function lookForSexSpot(unit:Unit,world:ConnectedBattlefield):void {
			var closestNest:Unit = null;
			var mate:Unit = world.findUnit(unit.data.mate);
			if(!mate) {
				unit.state = LONELY;
				return;
			}
			
			if(mate.data.nest) {
				closestNest = world.findUnit(mate.data.nest);
			}
			else {
				var surroundings:Array = world.calculateSurroundings(unit.parent.position,radius(unit),false);
				for each(var u:Unit in surroundings) {
					if(u.type=="house" && u.state==HouseType.FREE) {
						if(!closestNest || Unit.distance(u,unit)<Unit.distance(closestNest,unit)) {
							closestNest = u;
						}
					}
				}
			}
			if(closestNest) {
				if(Unit.distance(unit,closestNest)<20) {
					if(closestNest.state==HouseType.FREE) {
						closestNest.state = HouseType.OCCUPIED;
						unit.state = MATING;
						unit.data.nest = closestNest.id;
					}
					else if(closestNest.state==HouseType.OCCUPIED) {
						closestNest.state = HouseType.FULL;
						unit.state = MATING;
						unit.data.nest = closestNest.id;
						closestNest.data.started = world.clock;
					}
					closestNest.broadcastUnit();
				}
				else {
					unit.goal = closestNest.position;
				}
			}
		}
		
		private function lookForMate(unit:Unit,world:ConnectedBattlefield):void {
			var surroundings:Array = world.calculateSurroundings(unit.parent.position,radius(unit),false);
			var closestMate:Unit = null;
			for each(var u:Unit in surroundings) {
				if(u.type=="slime" && u!=unit && u.parent!=unit.parent) {
					if(!closestMate || Unit.distance(u,unit)<Unit.distance(closestMate,unit)) {
						closestMate = u;
					}
				}
			}
			if(closestMate) {
				if(Unit.distance(unit,closestMate)<20 && closestMate.state == SlimeType.LONELY) {
					closestMate.state = SlimeType.TALKING;
					closestMate.goal = null;
					unit.state = SlimeType.TALKING;
					unit.state = TALKING;
					unit.goal = null;
					unit.data.mate = closestMate.id;
					unit.data.lastTalked = world.clock;
					closestMate.data.lastTalked = world.clock;
					closestMate.data.mate = unit.id;
					closestMate.broadcastUnit();
				}
				else {
					unit.goal = closestMate.position;
				}
			}
		}
		
		private function lookForTree(unit:Unit,world:ConnectedBattlefield):void {
			var surroundings:Array = world.calculateSurroundings(unit.parent.position,radius(unit),false);
			var closestTree:Unit = null;
			for each(var u:Unit in surroundings) {
				if(u.type=="tree" && u.state==TreeType.FREE && u.data.food>0) {
					if(!closestTree || Unit.distance(u,unit)<Unit.distance(closestTree,unit)) {
						closestTree = u;
					}
				}
			}
			if(closestTree) {
				if(Unit.distance(unit,closestTree)<20) {
					closestTree.state = TreeType.OCCUPIED;
					unit.state = EATING;
					unit.data.tree = closestTree.id;
					closestTree.broadcastUnit();
				}
				else {
					unit.goal = closestTree.position;
				}
			}
		}
		
		override public function calculateFaith(unit:Unit,world:ConnectedBattlefield):Number {
			return unit.state==HUNGRY || unit.state==LONELY ? .5 : .8;
		}
		
		override public function affectDisplay(mc:MovieClip,unit:Unit,world:ConnectedBattlefield):void {
			mc.graphics.clear();
			if(unit.goal) {
				var point:Point = new Point(unit.goal.x-unit.position.x,unit.goal.y-unit.position.y);
				point.normalize(10);
				mc.graphics.lineStyle(3,0x00FF00);
				mc.graphics.lineTo(point.x,point.y);
			}
			if(mc.state) {
				mc.state.text = unit.state?unit.state:"";
				mc.state.visible = false;
			}			
			mc.slimo.mouth.gotoAndStop(unit.state.toUpperCase());
			mc.slimo.mouth.visible = true;
			
			mc.scaleX = mc.scaleY = this.defaultScale * (Math.log(unit.age+2)/10);
		}
		
		override public function getSpeed(unit:Unit,world:ConnectedBattlefield):Number {
			return unit.state==HUNGRY?1:1.5;
		}
		
		override public function isAlive(unit:Unit):Boolean {
			var wonders:Array = unit.world.calculateSurroundings(unit.parent.position,1000,false);
			var hasMonument:Boolean = false;
			for each(var u:Unit in wonders) {
				if(u.type=="wonder") {
					hasMonument = true;
					break;
				}
			}
			
			return unit.age<1000 * 60 * (hasMonument ? 10 : 5) || (unit.state!=NONE && unit.state!=LONELY && unit.state!=HUNGRY);
		}
		
	}
}