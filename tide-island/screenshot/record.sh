#!/usr/bin/env bash

if pgrep -x "wf-recorder" > /dev/null; then
    pkill -INT -x "wf-recorder"
    notify-send -i video-x-generic "Screen Recorder" "Recording stopped and saved to ~/Videos/Recordings/"
    exit 0
fi

# Parse custom mode flags
if [ "$1" = "-w" ]; then
    sleep 0.25
    GEOM=$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
    if [ -z "$GEOM" ] || [ "$GEOM" = "null,null nullxnull" ]; then
        notify-send -i error "Screen Recorder" "No active window found."
        exit 1
    fi
    shift
    set -- -g "$GEOM" "$@"
elif [ "$1" = "-r" ]; then
    GEOM=$(slurp)
    if [ -z "$GEOM" ]; then
        exit 0 # Cancelled by user
    fi
    shift
    set -- -g "$GEOM" "$@"
fi

# Create directory if it doesn't exist
mkdir -p "$HOME/Videos/Recordings"

# Generate filename with timestamp
OUTPUT_FILE="$HOME/Videos/Recordings/recording-$(date +%F_%H-%M).mkv"

# Get default sink monitor or fallback
DEFAULT_SINK=$(pactl get-default-sink 2>/dev/null)
if [ -n "$DEFAULT_SINK" ]; then
    AUDIO_DEVICE="${DEFAULT_SINK}.monitor"
else
    AUDIO_DEVICE="default"
fi

# Run in background
wf-recorder "$@" -f "$OUTPUT_FILE" --audio="$AUDIO_DEVICE" > /dev/null 2>&1 &

notify-send -i video-x-generic "Screen Recorder" "Recording started..."

