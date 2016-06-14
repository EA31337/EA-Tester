#!/usr/bin/env bash
CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"

# Check whether libgnutls needs patching.
echo "Checking version of secur32.dll.so..." >&2
if [ -d "/usr/lib/i386-linux-gnu" ]; then
  CHANNEL_PATH=$(find /usr/lib/i386-linux-gnu -type f -name 'secur32.dll.so')
  if [[ -n $(strings "$CHANNEL_PATH" 2> /dev/null | grep 'libgnutls.so.26') ]]; then
    echo "Found that Wine's secur32 channel is using libgnutls26 at '$CHANNEL_PATH'." >&2
    echo "Installing libgnutls28..." >&2
    sudo apt-get -qy install libgnutls28:i386
    echo 'Overwriting channel with the new build for wine-1.8.0 and libgnutls28...' >&2
    cp -vf "$CWD/../lib/secur32.dll.so" "$CHANNEL_PATH" && echo "The secur32.dll.so has been patched." >&2
  fi
fi
