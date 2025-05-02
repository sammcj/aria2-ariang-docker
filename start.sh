#!/bin/sh

conf_path=/aria2/conf
conf_copy_path=/aria2/conf-copy
data_path=/aria2/data
# shellcheck disable=SC2125
ariang_js_path=/usr/local/www/ariang/js/aria-ng*.js

# If config does not exist - use default
if [ ! -f $conf_path/aria2.conf ]; then
    cp $conf_copy_path/aria2.conf $conf_path/aria2.conf
fi

if [ -n "$RPC_SECRET" ]; then
    sed -i '/^rpc-secret=/d' $conf_path/aria2.conf
    printf 'rpc-secret=%s\n' "${RPC_SECRET}" >>$conf_path/aria2.conf

    if [ -n "$EMBED_RPC_SECRET" ]; then
        echo "Embedding RPC secret into AriaNg Web UI"
        RPC_SECRET_BASE64=$(printf "%s" "${RPC_SECRET}" | base64 -w 0)
        # shellcheck disable=SC2086
        sed -i 's,secret:"[^"]*",secret:"'"${RPC_SECRET_BASE64}"'",g' $ariang_js_path
    fi
fi

if [ -n "$BASIC_AUTH_USERNAME" ] && [ -n "$BASIC_AUTH_PASSWORD" ]; then
    echo "Enabling caddy basic auth"
    echo "
        basicauth / {
            $BASIC_AUTH_USERNAME $(caddy hash-password -plaintext "${BASIC_AUTH_PASSWORD}")
        }
    " >>/usr/local/caddy/Caddyfile
fi

touch $conf_path/aria2.session

# Configure AriaNg to use the correct RPC endpoint through Traefik
echo "Configuring AriaNg to use relative RPC path with proper CORS support"
sed -i 's#rpcInterface:"[^"]*"#rpcInterface:"jsonrpc"#g' $ariang_js_path
sed -i 's#protocol:"[^"]*"#protocol:"https"#g' $ariang_js_path
sed -i 's#rpcHost:"[^"]*"#rpcHost:window.location.hostname#g' $ariang_js_path
sed -i 's#rpcPort:[^,]*#rpcPort:""#g' $ariang_js_path

# If ARIA2RPCPORT is set, override the conf file
if [ -n "$ARIA2RPCPORT" ]; then
    echo "Overriding RPC port to $ARIA2RPCPORT"
    sed -i "s/^rpc-listen-port=.*/rpc-listen-port=${ARIA2RPCPORT}/" $conf_path/aria2.conf
fi

userid="$(id -u)" # 65534 - nobody, 0 - root
groupid="$(id -g)"

if [ -n "$PUID" ] && [ -n "$PGID" ]; then
    echo "Running as user $PUID:$PGID"
    userid=$PUID
    groupid=$PGID
fi

chown -R "$userid":"$groupid" $conf_path
chown -R "$userid":"$groupid" $data_path

# Start Caddy in the background
echo "Starting Caddy web server"
caddy start --config /usr/local/caddy/Caddyfile --adapter caddyfile

# Start aria2c in foreground
echo "Starting aria2c RPC server"
exec su-exec "$userid":"$groupid" aria2c --conf-path="$conf_path/aria2.conf" "$@"
