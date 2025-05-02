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

if [ -n "$ARIA2RPCPORT" ]; then
    echo "Changing RPC request port to $ARIA2RPCPORT in AriaNg WebUI"
    sed -i "s/6800/${ARIA2RPCPORT}/g" $ariang_js_path
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

# Make sure the RPC port is correctly set in aria2.conf
if ! grep -q "^rpc-listen-port=" $conf_path/aria2.conf; then
    echo "Adding rpc-listen-port=6800 to aria2.conf"
    echo "rpc-listen-port=6800" >> $conf_path/aria2.conf
fi

# Ensure rpc-listen-all is enabled
if ! grep -q "^rpc-listen-all=true" $conf_path/aria2.conf; then
    echo "Ensuring rpc-listen-all=true in aria2.conf"
    sed -i '/^rpc-listen-all=/d' $conf_path/aria2.conf
    echo "rpc-listen-all=true" >> $conf_path/aria2.conf
fi

# Start Caddy in the background
echo "Starting Caddy web server"
caddy start --config /usr/local/caddy/Caddyfile --adapter caddyfile

# Start aria2c in foreground
echo "Starting aria2c RPC server"
exec su-exec "$userid":"$groupid" aria2c --conf-path="$conf_path/aria2.conf" "$@"
