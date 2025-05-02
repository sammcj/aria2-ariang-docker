#!/bin/sh

conf_path=/aria2/conf
conf_copy_path=/aria2/conf-copy
data_path=/aria2/data
ariang_js_path=/usr/local/www/ariang/js/aria-ng*.js

# Basic setup
if [ ! -f $conf_path/aria2.conf ]; then
    cp $conf_copy_path/aria2.conf $conf_path/aria2.conf
fi

# Set up RPC secret
if [ -n "$RPC_SECRET" ]; then
    sed -i '/^rpc-secret=/d' $conf_path/aria2.conf
    printf 'rpc-secret=%s\n' "${RPC_SECRET}" >>$conf_path/aria2.conf

    if [ -n "$EMBED_RPC_SECRET" ]; then
        echo "Embedding RPC secret into AriaNg Web UI"
        RPC_SECRET_BASE64=$(printf "%s" "${RPC_SECRET}" | base64 -w 0)
        sed -i 's,secret:"[^"]*",secret:"'"${RPC_SECRET_BASE64}"'",g' $ariang_js_path
    fi
fi

# Add basic auth if configured
if [ -n "$BASIC_AUTH_USERNAME" ] && [ -n "$BASIC_AUTH_PASSWORD" ]; then
    echo "Enabling caddy basic auth"
    echo "
        basicauth / {
            $BASIC_AUTH_USERNAME $(caddy hash-password -plaintext "${BASIC_AUTH_PASSWORD}")
        }
    " >>/usr/local/caddy/Caddyfile
fi

touch $conf_path/aria2.session

# CRITICAL: Force AriaNg to use the correct RPC configuration
echo "Forcing AriaNg to use the correct RPC path to prevent CORS issues"

# First, create a backup
cp $ariang_js_path ${ariang_js_path}.bak

# Completely rewrite the RPC configuration in AriaNg
echo "Setting RPC to use relative path with current hostname"
sed -i 's/rpcHost:"[^"]*"/rpcHost:""/g' $ariang_js_path
sed -i 's/rpcPort:[^,]*/rpcPort:""/g' $ariang_js_path
sed -i 's/protocol:"[^"]*"/protocol:"https"/g' $ariang_js_path
sed -i 's/rpcInterface:"[^"]*"/rpcInterface:"jsonrpc"/g' $ariang_js_path

# Double-check our changes
echo "Verifying RPC configuration changes:"
grep -n "rpcHost\|rpcPort\|protocol\|rpcInterface" $ariang_js_path

# Setup ownership
userid="$(id -u)"
groupid="$(id -g)"

if [ -n "$PUID" ] && [ -n "$PGID" ]; then
    echo "Running as user $PUID:$PGID"
    userid=$PUID
    groupid=$PGID
fi

chown -R "$userid":"$groupid" $conf_path
chown -R "$userid":"$groupid" $data_path

# Update Caddyfile to explicitly handle CORS
cat > /usr/local/caddy/Caddyfile << 'EOL'
{
  admin off
  auto_https off
}

:8080 {
  # Handle WebSocket connections
  @websockets {
    header Connection *Upgrade*
    header Upgrade websocket
  }
  reverse_proxy @websockets 127.0.0.1:6800 {
    header_up Host {host}
    header_up Origin https://{host}
  }

  # Handle RPC requests with CORS headers
  @rpc {
    path /jsonrpc /rpc
  }
  handle @rpc {
    header Access-Control-Allow-Origin "*"
    header Access-Control-Allow-Methods "GET, POST, OPTIONS"
    header Access-Control-Allow-Headers "Origin, X-Requested-With, Content-Type, Accept, Authorization"
    header Access-Control-Max-Age "86400"
    reverse_proxy 127.0.0.1:6800 {
      header_up Host {host}
      header_up Origin https://{host}
    }
  }

  # Serve static files
  root * /usr/local/www/ariang
  file_server
  encode gzip

  log {
    level warn
  }
}
EOL

# Start Caddy in the background
echo "Starting Caddy web server with updated configuration"
caddy start --config /usr/local/caddy/Caddyfile --adapter caddyfile

# Start aria2c in foreground
echo "Starting aria2c RPC server"
exec su-exec "$userid":"$groupid" aria2c --conf-path="$conf_path/aria2.conf" "$@"
