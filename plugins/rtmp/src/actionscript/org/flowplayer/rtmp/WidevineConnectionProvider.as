
package org.flowplayer.rtmp {
    import flash.events.NetStatusEvent;
    import flash.utils.setTimeout;

    import org.flowplayer.controller.NetStreamControllingStreamProvider;
    import org.flowplayer.controller.ConnectionProvider;
    import org.flowplayer.controller.StreamProvider;
	import org.flowplayer.model.Clip;
	import org.flowplayer.util.Log;
	
	import flash.events.NetStatusEvent;
	import flash.net.NetConnection;		

	import com.widevine.WvNetConnection;

	/**
	 * @author api
	 */
	public class WidevineConnectionProvider implements ConnectionProvider {
		protected var log:Log = new Log(this);
		private var _connection:WvNetConnection;
		private var _successListener:Function;
		private var _failureListener:Function;
		private var _connectionClient:Object;
        private var _provider:NetStreamControllingStreamProvider;
        private var _connectionArgs:Array;
        private var _clip:Clip;
	private var _netConnectionUrl:String;

        public function WidevineConnectionProvider(config:Config) {
			_netConnectionUrl = config.netConnectionUrl;
        }

        private function doConnect(connectionArgs:Array, connectionUrl:String):void {
            if (connectionArgs.length > 0) {
                _connection.connect.apply(_connection, [connectionUrl].concat(connectionArgs));
            } else {
                _connection.connect(connectionUrl);
            }

	    log.debug("getNewURL: " + _connection.getNewURL() );
        }

        public function connect(provider:StreamProvider, clip:Clip, successListener:Function, objectEndocing:uint, connectionArgs:Array):void {
            _provider = provider as NetStreamControllingStreamProvider;
			_successListener = successListener;
			_connection = new WvNetConnection();
			_connection.proxyType = "best";
            _connectionArgs = connectionArgs;
            _clip = clip;
			
			if (_connectionClient) {
				_connection.client = _connectionClient;
			}
			_connection.addEventListener(NetStatusEvent.NET_STATUS, _onConnectionStatus);

            var connectionUrl:String = getNetConnectionUrl(clip);
            log.debug("connectionUrl: " + connectionUrl);
            doConnect(connectionArgs, connectionUrl);
        }

		protected function getNetConnectionUrl(clip:Clip):String {
			log.debug("using netConnectionUrl from config " + _netConnectionUrl);
			return _netConnectionUrl;
		}

		private function _onConnectionStatus(event:NetStatusEvent):void {
			log.debug("[NetStatusEvent] code:" + event.info.code + ", description:" + event.info.description +
			 ", details:" + event.info.details + ", level:" + event.info.level);
            onConnectionStatus(event);
			if (event.info.code == "NetConnection.Connect.Success" && _successListener != null) {
				_successListener(_connection);
                
            } else if (event.info.code == "NetConnection.Connect.Rejected") {
                if(event.info.ex.code == 302) {
                    var redirectUrl:String = event.info.ex.redirect;
                    log.debug("doing a redirect to " + redirectUrl);
                    _clip.setCustomProperty("netConnectionUrl", redirectUrl);
                    setTimeout(connect, 100, _provider, _clip, _successListener, _connection.objectEncoding, _connectionArgs);
				}
                
            } else if (["NetConnection.Connect.Failed", "NetConnection.Connect.AppShutdown", "NetConnection.Connect.InvalidApp"].indexOf(event.info.code) >= 0) {
				
				if (_failureListener != null) {
					_failureListener();
				}
			}	
		}

        /**
         * Called when NetStatusEvent.NET_STATUS is received for the NetConnection. This
         * gets called before the successListener() gets called. 
         * @param event
         * @return
         */
        protected function onConnectionStatus(event:NetStatusEvent):void {
        }

		public function set connectionClient(client:Object):void {
			if (_connection) {
				_connection.client = client;
			}
			_connectionClient = client;
		}
		
		public function set onFailure(listener:Function):void {
			_failureListener = listener;
		}
		
		protected function get connection():NetConnection {
			return _connection;
		}

        public function handeNetStatusEvent(event:NetStatusEvent):Boolean {
			// Time is wrong at start of notify
			if (event.info.code == "NetStream.Seek.Notify")
				return false;
				
            return true;
        }

        protected function get provider():NetStreamControllingStreamProvider {
            return _provider;
        }

        protected function get failureListener():Function {
            return _failureListener;
        }

        protected function get successListener():Function {
            return _successListener;
        }
    }
}
