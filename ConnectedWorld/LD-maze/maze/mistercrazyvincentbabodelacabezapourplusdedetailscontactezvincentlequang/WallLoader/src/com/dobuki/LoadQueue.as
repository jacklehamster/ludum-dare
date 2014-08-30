package com.dobuki
{
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	
	
	public class LoadQueue {
		
		static public var FIFO:Boolean = true;
		private var vector:Vector.<LoadQueueItem> = new Vector.<LoadQueueItem>();
		private var inprogress:int = 0;
		
		public function add(object:EventDispatcher,action:Function,...params):void
		{
			vector.push(new LoadQueueItem(object,action,params));
			perform();
		}
		
		private function perform(e:Event=null):void {
			if(e!=null) {
				inprogress--;
			}
			if(inprogress<2 && vector.length) {
				inprogress++;
				var queueItem:LoadQueueItem = FIFO?vector.shift():vector.pop();
				var dispatcher:IEventDispatcher = (queueItem.object is URLLoader) ? queueItem.object : 
					(queueItem.object is Loader) ? (queueItem.object as Loader).contentLoaderInfo :
					null;
				if(dispatcher) {
					dispatcher.addEventListener(Event.COMPLETE,perform);
					dispatcher.addEventListener(IOErrorEvent.IO_ERROR,perform);
					dispatcher.addEventListener(SecurityErrorEvent.SECURITY_ERROR,perform);
				}
				queueItem.action.apply(queueItem.object,queueItem.params);
			}
		}
	}
		
}
import flash.events.EventDispatcher;

internal class LoadQueueItem {
	public var object:EventDispatcher;
	public var action:Function;
	public var params:Array;
	
	public function LoadQueueItem(object:EventDispatcher,action:Function,params:Array):void {
		this.object = object;
		this.action = action;
		this.params = params;
	}
}
