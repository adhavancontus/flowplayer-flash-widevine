/*
 * This file is part of Flowplayer, http://flowplayer.org
 *
 * By: Anssi Piirainen, <api@iki.fi>
 *
 * Copyright (c) 2008-2011 Flowplayer Oy
 *
 * Released under the MIT License:
 * http://www.opensource.org/licenses/mit-license.php
 */
package org.flowplayer.slowmotion {
    import flash.events.NetStatusEvent;
	import flash.net.NetStream;
	
    import org.flowplayer.controller.StreamProvider;
    import org.flowplayer.controller.TimeProvider;
    import org.flowplayer.model.ClipEvent;
	import org.flowplayer.model.ClipEventType;
    import org.flowplayer.model.Playlist;
    import org.flowplayer.model.PluginModel;
	import com.widevine.WvNetStream;
	
    public class WidevineSlowMotion extends AbstractSlowMotion {
		
		private var _playlist:Playlist;

        public function WidevineSlowMotion(model:PluginModel, playlist:Playlist, provider:StreamProvider, providerName:String) {
            super(model, playlist, provider, providerName);
            playlist.onSeek(onSeek, slowMotionClipFilter);
			_playlist = playlist;
        }

        private function onSeek(event:ClipEvent):void {
			log.debug("onSeek(), isTrickPlay() = " + isTrickPlay() );
            if (isTrickPlay()) {
                restartTrickPlay();
            }
        }

        private function restartTrickPlay():void {
			log.debug("restartTrickPlay()");
            trickSpeed(info.speedMultiplier, info.forwardDirection);
        }

        override public function getTimeProvider():TimeProvider {
            return this;
        }
		
		override public function getTime(netStream:NetStream):Number {
			var ns:WvNetStream = netStream as WvNetStream;
		
			if (Math.random() * 100 > 99)
				log.debug("Current time: " + ns.getCurrentMediaTime());	
				
			return ns.getCurrentMediaTime();
        }

        override protected function normalSpeed():void {
            var ns:WvNetStream = netStream as WvNetStream;
			log.info("normalSpeed(), resuming");
			ns.resume();
			log.info("normalSpeed(), time is " + time + ", scale is " + ns.getPlayScale());
        }

        override protected function trickSpeed(multiplier:Number, forward:Boolean):void {
			var ns:WvNetStream = netStream as WvNetStream;
			
            log.info("trickSpeed(), multiplier == " + multiplier + ", time is " + time + ", scale is " + ns.getPlayScale());
            //var targetFps:Number = multiplier * 50;
            //provider.netConnection.call("setFastPlay", null, multiplier, targetFps, forward ? 1 : -1);
            //netStream.seek(time);
			
			//_playlist.current.dispatchEvent(new ClipEvent(ClipEventType.PAUSE));
			
			if (forward)
				ns.playForward();
			else
				ns.playRewind();
        }

        override public function getInfo(event:NetStatusEvent):SlowMotionInfo {
			var ns:WvNetStream = netStream as WvNetStream;
			
			var playScale:Number = ns.getPlayScale();
			// SlowMotionInfo(clip:Clip, isTrickPlay:Boolean, forwardDirection:Boolean, timeOffset:Number, speedMultiplier:Number) {
			return new SlowMotionInfo(playlist.current, playScale != 1, playScale >= 1, 0, playScale);
			
            /*if (event.info.code == "NetStream.Play.Start") {
				log.debug("Got Start");

                if (event.info.isFastPlay != undefined) {
					if ( event.info.isFastPlay ) {
						return new SlowMotionInfo(playlist.current, true, Number(event.info.fastPlayDirection) > 0, event.info.fastPlayOffset as Number, event.info.fastPlayMultiplier as Number);
	                    log.debug("isFastPlay = true");
					}
					else {
						log.debug("isFastPlay = false");
                        return new SlowMotionInfo(playlist.current, false, true, 0, 0);
					}

                }
            }*/
            return null;
        }
    }
}
