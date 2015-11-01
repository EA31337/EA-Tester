#!/usr/bin/env bash

set -e

# Set delay for periodic checks
DELAY=5

echo "Downloading MT4 installer..."
wget -c -t0 https://download.mql5.com/cdn/web/metaquotes.software.corp/mt4/mt4setup.exe

echo "Starting MT4 Setup in Wine..."
wine mt4setup.exe &> ~/wine_mt4setup.exe.log &

# Wait until Wine initializes
while : ; do
	echo "Waiting for Wine to initialize..."
	sleep $DELAY
	set +e  # Workaround for xdotool issue #60
	WINDOW_ID=$(xdotool search --name "MetaTrader 4 Setup*")
	set -e  # Workaround for xdotool issue #60
	[[ -z $WINDOW_ID ]] || break
done

# Set focus on installer window and act to install platform
echo "Sending installer keystrokes..."
xdotool key --window $WINDOW_ID --delay 500 space Tab Tab Tab Return Tab Tab Tab space Alt+n

# Wait until installation is ready
while : ; do
	echo "Installing MT4 platform..."
	sleep $DELAY
	set +e  # Avoid script termination
	PS=$(ps | grep "mt4setup.exe")
	set -e  # Avoid script termination
	[[ ! -z $PS ]] || break
done

# Wait for MT4 to start
while : ; do
	echo "Waiting for MT4 platform to start..."
	sleep $DELAY
	set +e  # Workaround for xdotool issue #60
	WINDOW_ID=$(xdotool search -name "MetaTrader 4 - *")
	set -e  # Workaround for xdotool issue #60
	[[ -z $WINDOW_ID ]] || break
done

# Close running MT4 instance, first the two login popup window, secondly application itself
echo "Sending application closer keystrokes..."
xdotool key --window $WINDOW_ID --delay 500 Escape Escape Alt+f x

tree "$(find ~/.wine -name MetaTrader* -type d -print | grep 'Program Files')"
echo "$0 done."
