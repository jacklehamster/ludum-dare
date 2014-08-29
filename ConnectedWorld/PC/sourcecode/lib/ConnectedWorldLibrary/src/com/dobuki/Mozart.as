package com.dobuki
{
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	import flash.utils.Dictionary;
	import flash.utils.setInterval;
	import flash.utils.setTimeout;

	public class Mozart
	{
		
		[Embed(source="music/random.mp3")]
		private const RandomSample:Class;
		[Embed(source="music/bip.mp3")]
		private const ViolonSample:Class;
		private var dico:Dictionary = new Dictionary();
		private var count:int = 0;
		
		private var s:Number = 10000;
		
		private var samples:Array = [
			new ViolonSample(),
			new RandomSample()
		];
		
		static private var _instance:Mozart = new Mozart();
		static public function get instance():Mozart {
			return _instance;
		}
		
		public function play(seed:int):void {
			setInterval(
				function():void {
					if(count<3) {
						playSection(seed);
					}
					for each(var moz:Moz in dico) {
						moz.play();
						if(!moz.alive) {
							delete dico[moz];
							count--;
						}
					}
				},100);
		}
		
		private function playSection(seed:int):void {
			
			count++;
			
			var mods:Array = [4,8,16];
			var sound:Sound = (samples[int(Math.random()*samples.length)] as Sound);
			var moz:Moz = new Moz(sound,Math.random()*sound.length,new SoundTransform(.2),int(Math.random()*5+1)*4,Math.random()*20,mods[int(Math.random()*mods.length)]);
			dico[moz] = moz;
		}
	}
}
import flash.media.Sound;
import flash.media.SoundChannel;
import flash.media.SoundTransform;
import flash.utils.clearTimeout;
import flash.utils.setTimeout;

internal class Moz
{
	private var sound:Sound;
	private var transform:SoundTransform;
	private var index:Number;
	private var lifetime:int;
	private var cycle:int;
	private var cyclemod:int;
	
	
	function Moz(sound:Sound,index:Number,transform:SoundTransform,lifetime:int,cycle:int,cyclemod:int):void {
		this.sound = sound;
		this.index = index;
		this.transform = transform;
		this.lifetime = lifetime;
		this.cycle = cycle;
		this.cyclemod = cyclemod;
	}
	
	public function play():void {
		if(cycle<=0) {
			lifetime--;
			var channel:SoundChannel = sound.play(index,1,transform);
			var timeout:int = setTimeout(
				function():void {
					clearTimeout(timeout);
					channel.stop();
				},500);
			cycle = cyclemod;
		}
		cycle--;
	}
	
	public function get alive():Boolean
	{
		return lifetime>0;
	}
}
