#!/usr/bin/env bash

# Voice Keyboard Debian Package Build Script
# Builds a .deb package for Ubuntu/Debian systems

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$SCRIPT_DIR/app"
BUILD_DIR="$SCRIPT_DIR/debian-build"
PACKAGE_NAME="voice-keyboard"
VERSION="0.1.0"
ARCHITECTURE="amd64"
MAINTAINER="Daniel Rosehill <public@danielrosehill.com>"

echo "Building Debian package for Voice Keyboard v${VERSION}"
echo "================================================"

# Clean previous build
if [ -d "$BUILD_DIR" ]; then
  echo "Cleaning previous build directory..."
  rm -rf "$BUILD_DIR"
fi

# Create package directory structure
echo "Creating package directory structure..."
mkdir -p "$BUILD_DIR/DEBIAN"
mkdir -p "$BUILD_DIR/usr/bin"
mkdir -p "$BUILD_DIR/usr/share/applications"
mkdir -p "$BUILD_DIR/usr/share/doc/$PACKAGE_NAME"
mkdir -p "$BUILD_DIR/usr/share/icons/hicolor/256x256/apps"
mkdir -p "$BUILD_DIR/etc/udev/rules.d"

# Build the Rust application in release mode
echo "Building Rust application in release mode..."
cd "$APP_DIR"
cargo build --release

if [ $? -ne 0 ]; then
  echo "Build failed!"
  exit 1
fi

# Copy binary
echo "Copying binary..."
cp "$APP_DIR/target/release/voice-keyboard" "$BUILD_DIR/usr/bin/"
chmod 755 "$BUILD_DIR/usr/bin/voice-keyboard"

# Create wrapper script that handles privilege elevation
echo "Creating wrapper script..."
cat > "$BUILD_DIR/usr/bin/voice-keyboard-launcher" << 'EOF'
#!/usr/bin/env bash

# Voice Keyboard Launcher
# Handles privilege elevation for uinput device creation

if [ "$EUID" -eq 0 ]; then
  echo "Error: Don't run this script as root. It will handle privileges automatically."
  exit 1
fi

# Run with sudo, preserving necessary environment variables
sudo \
  DEEPGRAM_API_KEY="$DEEPGRAM_API_KEY" \
  XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" \
  DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" \
  WAYLAND_DISPLAY="$WAYLAND_DISPLAY" \
  DISPLAY="$DISPLAY" \
  PULSE_RUNTIME_PATH="$PULSE_RUNTIME_PATH" \
  HOME="$HOME" \
  USER="$USER" \
  /usr/bin/voice-keyboard "$@"
EOF
chmod 755 "$BUILD_DIR/usr/bin/voice-keyboard-launcher"

# Create desktop entry
echo "Creating desktop entry..."
cat > "$BUILD_DIR/usr/share/applications/voice-keyboard.desktop" << EOF
[Desktop Entry]
Name=Voice Keyboard
Comment=System-level voice-to-text dictation for Ubuntu
Exec=/usr/bin/voice-keyboard-launcher --test-stt
Icon=voice-keyboard
Terminal=true
Type=Application
Categories=Utility;Accessibility;
Keywords=voice;dictation;speech;text;typing;
StartupNotify=true
EOF

# Copy icon if it exists
if [ -f "$SCRIPT_DIR/image.png" ]; then
  echo "Copying application icon..."
  cp "$SCRIPT_DIR/image.png" "$BUILD_DIR/usr/share/icons/hicolor/256x256/apps/voice-keyboard.png"
fi

# Create udev rules for uinput access
echo "Creating udev rules..."
cat > "$BUILD_DIR/etc/udev/rules.d/99-voice-keyboard.rules" << 'EOF'
# Allow members of input group to access uinput device
KERNEL=="uinput", GROUP="input", MODE="0660"
EOF

# Copy documentation
echo "Copying documentation..."
cp "$SCRIPT_DIR/README.md" "$BUILD_DIR/usr/share/doc/$PACKAGE_NAME/"
cp "$SCRIPT_DIR/CLAUDE.md" "$BUILD_DIR/usr/share/doc/$PACKAGE_NAME/"
if [ -f "$APP_DIR/LICENSE.txt" ]; then
  cp "$APP_DIR/LICENSE.txt" "$BUILD_DIR/usr/share/doc/$PACKAGE_NAME/copyright"
fi

# Create control file
echo "Creating control file..."
cat > "$BUILD_DIR/DEBIAN/control" << EOF
Package: $PACKAGE_NAME
Version: $VERSION
Section: utils
Priority: optional
Architecture: $ARCHITECTURE
Maintainer: $MAINTAINER
Depends: libc6, libgcc-s1, sudo
Recommends: pipewire, pulseaudio
Description: System-level voice-to-text dictation for Ubuntu
 Voice Keyboard provides OS-level speech-to-text integration for Ubuntu Linux.
 Uses cloud-based STT APIs (Deepgram) for high-quality real-time transcription.
 .
 Features:
  - Works across all applications on Wayland
  - Configurable hotkey activation
  - API spend monitoring
  - System tray integration (planned)
  - Multiple cloud STT provider support (planned)
Homepage: https://github.com/danielrosehill/Voice-Typing-Ubuntu-App
EOF

# Create postinst script
echo "Creating postinst script..."
cat > "$BUILD_DIR/DEBIAN/postinst" << 'EOF'
#!/bin/bash
set -e

# Reload udev rules
if [ -x /bin/udevadm ]; then
  udevadm control --reload-rules
  udevadm trigger
fi

# Add current user to input group if not already a member
if [ -n "$SUDO_USER" ]; then
  if ! groups "$SUDO_USER" | grep -q "\binput\b"; then
    echo "Adding $SUDO_USER to input group..."
    usermod -a -G input "$SUDO_USER"
    echo "Please log out and log back in for group changes to take effect."
  fi
fi

echo ""
echo "Voice Keyboard installed successfully!"
echo ""
echo "Setup instructions:"
echo "1. Set your Deepgram API key:"
echo "   export DEEPGRAM_API_KEY='your-api-key-here'"
echo "   (Add this to your ~/.bashrc or ~/.zshrc for persistence)"
echo ""
echo "2. Run the application:"
echo "   voice-keyboard-launcher --test-stt"
echo ""
echo "Or launch from your application menu."
echo ""

exit 0
EOF
chmod 755 "$BUILD_DIR/DEBIAN/postinst"

# Create prerm script
echo "Creating prerm script..."
cat > "$BUILD_DIR/DEBIAN/prerm" << 'EOF'
#!/bin/bash
set -e

# Nothing specific needed for now
exit 0
EOF
chmod 755 "$BUILD_DIR/DEBIAN/prerm"

# Calculate installed size
echo "Calculating package size..."
INSTALLED_SIZE=$(du -sk "$BUILD_DIR" | cut -f1)
echo "Installed-Size: $INSTALLED_SIZE" >> "$BUILD_DIR/DEBIAN/control"

# Build the package
echo "Building .deb package..."
cd "$SCRIPT_DIR"
dpkg-deb --build "$BUILD_DIR" "${PACKAGE_NAME}_${VERSION}_${ARCHITECTURE}.deb"

if [ $? -eq 0 ]; then
  echo ""
  echo "================================================"
  echo "Success! Package created:"
  echo "  ${PACKAGE_NAME}_${VERSION}_${ARCHITECTURE}.deb"
  echo ""
  echo "To install:"
  echo "  sudo dpkg -i ${PACKAGE_NAME}_${VERSION}_${ARCHITECTURE}.deb"
  echo "  sudo apt-get install -f  # If there are dependency issues"
  echo ""
  echo "Package details:"
  dpkg-deb --info "${PACKAGE_NAME}_${VERSION}_${ARCHITECTURE}.deb"
else
  echo "Package build failed!"
  exit 1
fi
