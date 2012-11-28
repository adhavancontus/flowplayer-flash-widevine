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
			return netStream["getCurrentMediaTime"]();
        }

        override protected function normalSpeed():void {
			log.info("normalSpeed(), resuming");
			netStream.resume();
        }

        override protected function trickSpeed(multiplier:Number, forward:Boolean):void {
			if (forward)
				netStream["playForward"]();
			else
				netStream["playRewind"]();
        }

        override public function getInfo(event:NetStatusEvent):SlowMotionInfo {
			
			var playScale:Number = netStream["getPlayScale"]();
			// SlowMotionInfo(clip:Clip, isTrickPlay:Boolean, forwardDirection:Boolean, timeOffset:Number, speedMultiplier:Number) {
			return new SlowMotionInfo(playlist.current, playScale != 1, playScale >= 1, 0, Math.abs(playScale));
        }
    }
}
