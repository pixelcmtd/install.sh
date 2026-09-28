#!/bin/sh

set -e

[ $# -ne 4 ] && {
        echo 'Usage: install.sh [name] [checksum-algorithm] [checksum] [url]' >&2
        exit 1
}

name="$1"
sumalgo="$2"
sum="$3"
url="$4"

[ "$sumalgo" = "sha256" -o "$sumalgo" = "sha1" -o "$sumalgo" = "md5" ] && sumalgo="$sumalgo"sum

tmp="$(mktemp "/usr/bin/.$name.XXXXXX")"
unit_tmp="$(mktemp "/etc/systemd/system/.$name.service.XXXXXX")"
trap 'rm -f "$tmp" "$unit_tmp"' 0
trap 'exit 1' 1 2 3 15
curl -fLo "$tmp" "$url"

"$sumalgo" "$tmp" | grep -q "$sum" || {
        echo "Checksum doesn't match!" >&2
        exit 2
}

chmod 755 "$tmp"
echo "[Unit]
Description=$name
[Service]
Type=simple
Restart=always
ExecStart=/usr/bin/$name
[Install]
WantedBy=multi-user.target" > "$unit_tmp"

systemctl stop "$name.service" 2>/dev/null || true
mv -f "$tmp" "/usr/bin/$name"
mv -f "$unit_tmp" "/etc/systemd/system/$name.service"
systemctl daemon-reload
systemctl enable --now "$name.service"
