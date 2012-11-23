package org.flowplayer.rtmp {
	import com.widevine.WvNetStream;
	import com.widevine.WvNetConnection;
	import flash.events.NetStatusEvent;
	import org.flowplayer.util.Log;
	import org.flowplayer.controller.NetStreamControllingStreamProvider;
	import org.flowplayer.view.Flowplayer;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	public class WidevineNetStream extends WvNetStream {
		protected var log:Log = new Log(this);
		private var rePause:Boolean;
		//private var _streamProvider:NetStreamControllingStreamProvider;
		//private var _player:Flowplayer;
		private var _pauseWaitTimer:Timer;
		private var _pauseRequired:Boolean;
		
		public function WidevineNetStream(connection:WvNetConnection):void
		{
			super(connection);
			//_streamProvider = streamProvider;
			//_player = player;
			addEventListener(NetStatusEvent.NET_STATUS, onNetStatus);
		}
		
		private function onNetStatus(event:NetStatusEvent):void {
            log.info("_onNetStatus, code: " + event.info.code + ", isPlaying: " + getPlayStatus() + ", time: " + getCurrentMediaTime());
			
			switch (event.info.code) {
				case "NetStream.Seek.Complete":
				if(rePause) {
					log.info("repausing");
					super.pause();
					rePause = false;
				}
					break;
					
				/*case "NetStream.Play.Complete":
					log.info("Jumping back to start");
					rePause = true;
					super.resume();
					super.seek(0);
					break;*/
			}
		}
		
		public override function pause():void 
		{
			log.info("pause() timer started");
			
			if (_pauseWaitTimer && _pauseWaitTimer.running) return;
			_pauseRequired = true;
            _pauseWaitTimer = new Timer(200);
            _pauseWaitTimer.addEventListener(TimerEvent.TIMER, onPauseWait);
            _pauseWaitTimer.start();

		}
		
		public override function resume():void 
		{
			/*if (getPlayStatus() && getPlayScale() == 1) {
				log.info("ignoring resume()");
				return;
			}*/
			log.info("resume()");
			super.resume();
		}
		
        private function onPauseWait(event:TimerEvent):void {
			_pauseWaitTimer.stop();
            if (_pauseRequired) {
				log.info("pausing");
				super.pause();
				_pauseRequired = false;
            } else {
				log.info("pause cancelled by seek");
			}
        }

		
		public override function seek(offset:Number):void 
		{
			// To ignore a recent pause
			_pauseRequired = false;
			
			log.info("seek to " + offset + ", isPlaying " + getPlayStatus());
			// Widevine cannot seek while paused
			if (getPlayStatus()  == false) {
				log.info("paused during seek, resuming and requesting pause");
				resume();
				rePause = true;
			}
			super.seek(offset);
		}
	}
}