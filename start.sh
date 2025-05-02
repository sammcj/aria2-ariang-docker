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

# Try to use Python's built-in HTTP server if available
if command -v python3 >/dev/null 2>&1; then
    echo "Starting Python HTTP server for AriaNg on port 8080"
    cd /usr/local/www/ariang && python3 -m http.server 8080 &
    echo "Python HTTP server started with PID $!"
elif command -v python >/dev/null 2>&1; then
    echo "Starting Python HTTP server for AriaNg on port 8080"
    cd /usr/local/www/ariang && python -m SimpleHTTPServer 8080 &
    echo "Python HTTP server started with PID $!"
else
    echo "ERROR: Could not find a suitable web server. Please install python3, python, or add a web server to the container."
    echo "Will try to continue without the web UI."
fi

# Start aria2c in foreground
echo "Starting aria2c RPC server"
exec su-exec "$userid":"$groupid" aria2c --conf-path="$conf_path/aria2.conf" "$@"
