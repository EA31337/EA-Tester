#!/usr/bin/env bash
CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
CHANNEL_PATH="$(find /usr/lib/i386-linux-gnu -type f -name 'secur32.dll.so')"

if [[ -n $(strings "$CHANNEL_PATH" 2> /dev/null | grep 'libgnutls.so.26') ]]; then
  echo "Found Wine's secur32 channel using libgnutls26 at '$CHANNEL_PATH'"
  apt-get -qy install libgnutls28:i386
  printf 'Overwriting channel with new one built for wine-1.8.0 and libgnutls28... '
  cp -vf "$CWD/../lib/secur32.dll.so" "$CHANNEL_PATH" && echo 'OK :-)'
else
  echo "Wine's secur32 channel is fine, noting to do. :-|"
fi
