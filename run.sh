#!/usr/bin/env bash

# Voice Keyboard Runner Script
# This script runs the voice-keyboard with proper privilege handling
#
# Usage examples:
#   ./run.sh --test-audio              # Test audio input
#   ./run.sh --test-stt                # Test STT with typing
#   ./run.sh --debug-stt               # Debug STT (print only)
#   ./run.sh --debug-stt --stt-url ... # Debug with custom URL

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$SCRIPT_DIR/app"
VENV_DIR="$APP_DIR/.venv"

# Check if we're already running as root
if [ "$EUID" -eq 0 ]; then
  echo "Error: Don't run this script as root. It will handle privileges automatically."
  exit 1
fi

# Check if virtual environment exists for Python dependencies (future use)
if [ ! -d "$VENV_DIR" ]; then
  echo "Virtual environment not found at $VENV_DIR"
  echo "Creating virtual environment..."
  python3 -m venv "$VENV_DIR"
  echo "Virtual environment created successfully"
fi

# Change to app directory
cd "$APP_DIR"

# Build the project first
echo "Building voice-keyboard..."
cargo build

if [ $? -ne 0 ]; then
  echo "Build failed!"
  exit 1
fi

# Run with sudo, explicitly preserving critical environment variables
echo "Starting voice-keyboard with privilege dropping..."
echo "Note: This will create a virtual keyboard as root, then drop privileges for audio access."
echo ""

sudo \
  DEEPGRAM_API_KEY="$DEEPGRAM_API_KEY" \
  XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" \
  DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" \
  WAYLAND_DISPLAY="$WAYLAND_DISPLAY" \
  DISPLAY="$DISPLAY" \
  PULSE_RUNTIME_PATH="$PULSE_RUNTIME_PATH" \
  HOME="$HOME" \
  USER="$USER" \
  ./target/debug/voice-keyboard "$@"
