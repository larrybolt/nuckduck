#!/usr/bin/env bash
set -o errexit  # Exit on most errors (see the manual)
set -o errtrace # Make sure any error trap is inherited
set -o nounset  # Disallow expansion of unset variables
set -o pipefail # Use last non-zero exit code in a pipeline


if [[ $# -eq 0  ]]; then
  echo "usage: $0 APPNAME [SUBDOMAIN]"
  exit 1
fi

APPNAME=$1
SUBDOMAIN=${2:-$APPNAME}

# TODO: try getting the next free port automatically
PORT=${3:-"9000:80"}

DOCKERCOMPOSE=/apps/$APPNAME/docker-compose.yml

if test -f "$DOCKERCOMPOSE"; then
  echo "filename does exist"
  exit 1
fi

mkdir -p /apps/$APPNAME

cat <<EOT > /apps/$APPNAME/docker-compose.yml
version: '3'
services:
  $APPNAME:
    image: $APPNAME/$APPNAME
    restart: unless-stopped
    volumes:
      - ./data:/data
      #- /var/run/docker.sock:/var/run/docker.sock
    ports:
      - "127.0.0.1:$PORT"
EOT
vim $DOCKERCOMPOSE

REVERSEPORT=$(cat $DOCKERCOMPOSE | grep -oE "127\.0\.0\.1:([0-9]{2,4})" | cut -d: -f2)

cat <<EOT > /apps/$APPNAME/Caddyfile
$SUBDOMAIN.{\$ZONE} {
  import internal_only
  import defaults
  reverse_proxy 127.0.0.1:$REVERSEPORT
}
EOT
