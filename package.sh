#!/usr/bin/env bash

# Voice Keyboard Package Manager
# All-in-one script for building, versioning, and installing the Debian package

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$SCRIPT_DIR/app"
BUILD_DIR="$SCRIPT_DIR/debian-build"
PACKAGE_NAME="voice-keyboard"
ARCHITECTURE="amd64"
MAINTAINER="Daniel Rosehill <public@danielrosehill.com>"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get current version from Cargo.toml
get_current_version() {
  grep '^version = ' "$APP_DIR/Cargo.toml" | head -n 1 | sed 's/version = "\(.*\)"/\1/'
}

print_usage() {
  echo "Usage: $0 [COMMAND] [OPTIONS]"
  echo ""
  echo "Commands:"
  echo "  build             Build the Debian package (default)"
  echo "  install           Build and install the package"
  echo "  reinstall         Build and reinstall (removes old version first)"
  echo "  update VERSION    Update version number and rebuild"
  echo ""
  echo "Options:"
  echo "  -i, --install     Install after building (can combine with build/update)"
  echo "  -r, --reinstall   Reinstall (remove old version first)"
  echo "  -h, --help        Show this help message"
  echo ""
  echo "Examples:"
  echo "  $0                      # Just build"
  echo "  $0 build                # Same as above"
  echo "  $0 install              # Build and install"
  echo "  $0 reinstall            # Build and reinstall"
  echo "  $0 update 0.2.0         # Update to version 0.2.0 and build"
  echo "  $0 update 0.2.0 -i      # Update to 0.2.0 and install"
  echo ""
  echo "Current version: $(get_current_version)"
}

# Parse arguments
COMMAND="build"
NEW_VERSION=""
INSTALL=false
REINSTALL=false

# First argument might be a command
if [[ $# -gt 0 && "$1" != -* ]]; then
  COMMAND="$1"
  shift

  # If command is update, next arg is version
  if [ "$COMMAND" = "update" ] && [ $# -gt 0 ] && [[ "$1" != -* ]]; then
    NEW_VERSION="$1"
    shift
  fi
fi

# Parse options
while [[ $# -gt 0 ]]; do
  case $1 in
    -i|--install)
      INSTALL=true
      shift
      ;;
    -r|--reinstall)
      REINSTALL=true
      INSTALL=true
      shift
      ;;
    -h|--help)
      print_usage
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      print_usage
      exit 1
      ;;
  esac
done

# Apply command shortcuts
case $COMMAND in
  install)
    INSTALL=true
    ;;
  reinstall)
    REINSTALL=true
    INSTALL=true
    ;;
  update)
    if [ -z "$NEW_VERSION" ]; then
      echo -e "${RED}Error: Version number required for update command${NC}"
      echo "Usage: $0 update VERSION [OPTIONS]"
      exit 1
    fi
    ;;
  build)
    # Default, nothing special
    ;;
  help|--help|-h)
    print_usage
    exit 0
    ;;
  *)
    echo -e "${RED}Unknown command: $COMMAND${NC}"
    print_usage
    exit 1
    ;;
esac

# Get current version
CURRENT_VERSION=$(get_current_version)

if [ -z "$CURRENT_VERSION" ]; then
  echo -e "${RED}Error: Could not determine current version from Cargo.toml${NC}"
  exit 1
fi

VERSION="$CURRENT_VERSION"

echo -e "${GREEN}Voice Keyboard Package Manager${NC}"
echo "================================"
echo "Current version: $CURRENT_VERSION"

# Update version if requested
if [ -n "$NEW_VERSION" ]; then
  echo -e "${YELLOW}Updating version from $CURRENT_VERSION to $NEW_VERSION${NC}"

  # Update Cargo.toml
  sed -i "s/^version = \".*\"/version = \"$NEW_VERSION\"/" "$APP_DIR/Cargo.toml"

  echo -e "${GREEN}Version updated to $NEW_VERSION${NC}"
  VERSION="$NEW_VERSION"
fi

echo ""

# Clean previous build artifacts
echo "Cleaning previous build artifacts..."
if [ -d "$BUILD_DIR" ]; then
  rm -rf "$BUILD_DIR"
fi

# Remove old .deb files if building new version
if [ -n "$NEW_VERSION" ]; then
  OLD_DEBS=$(ls "$SCRIPT_DIR"/${PACKAGE_NAME}_*.deb 2>/dev/null || true)
  if [ -n "$OLD_DEBS" ]; then
    echo "Removing old .deb files..."
    rm -f "$SCRIPT_DIR"/${PACKAGE_NAME}_*.deb
  fi
fi

# Run tests if they exist
if [ -d "$APP_DIR/tests" ]; then
  echo -e "${YELLOW}Running tests...${NC}"
  cd "$APP_DIR"
  cargo test
  if [ $? -ne 0 ]; then
    echo -e "${RED}Tests failed! Aborting build.${NC}"
    exit 1
  fi
  cd "$SCRIPT_DIR"
  echo ""
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
echo -e "${YELLOW}Building Rust application in release mode...${NC}"
cd "$APP_DIR"
cargo build --release

if [ $? -ne 0 ]; then
  echo -e "${RED}Build failed!${NC}"
  exit 1
fi

# Copy binary
echo "Copying binary..."
cp "$APP_DIR/target/release/voice-keyboard" "$BUILD_DIR/usr/bin/"
chmod 755 "$BUILD_DIR/usr/bin/voice-keyboard"

# Copy voice-dictation launcher if it exists
if [ -f "$SCRIPT_DIR/voice-dictation" ]; then
  echo "Copying voice-dictation launcher..."
  cp "$SCRIPT_DIR/voice-dictation" "$BUILD_DIR/usr/bin/"
  chmod 755 "$BUILD_DIR/usr/bin/voice-dictation"
fi

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
echo -e "${YELLOW}Building .deb package...${NC}"
cd "$SCRIPT_DIR"
PACKAGE_FILE="${PACKAGE_NAME}_${VERSION}_${ARCHITECTURE}.deb"
dpkg-deb --build "$BUILD_DIR" "$PACKAGE_FILE"

if [ $? -ne 0 ]; then
  echo -e "${RED}Package build failed!${NC}"
  exit 1
fi

echo ""
echo "================================================"
echo -e "${GREEN}Success! Package created:${NC}"
echo "  $PACKAGE_FILE"
echo ""

# Install if requested
if [ "$INSTALL" = true ]; then
  if [ "$REINSTALL" = true ]; then
    echo "Removing old version..."
    sudo dpkg -r "$PACKAGE_NAME" 2>/dev/null || true
    echo ""
  fi

  echo "Installing package..."
  sudo dpkg -i "$PACKAGE_FILE"

  if [ $? -ne 0 ]; then
    echo "Attempting to fix dependencies..."
    sudo apt-get install -f -y
  fi

  # Verify installation
  if dpkg -l | grep -q "^ii.*$PACKAGE_NAME"; then
    echo ""
    echo "================================================"
    echo -e "${GREEN}Package installed successfully!${NC}"
    echo ""
    echo "Installed version:"
    dpkg -l | grep "$PACKAGE_NAME"
    echo ""
    echo "To run:"
    echo "  voice-keyboard-launcher --test-stt"
    echo ""
  else
    echo ""
    echo -e "${RED}Installation verification failed!${NC}"
    exit 1
  fi
else
  echo "To install:"
  echo "  sudo dpkg -i $PACKAGE_FILE"
  echo ""
  echo "Or run:"
  echo "  ./package.sh install"
  echo ""
fi

# Summary for version updates
if [ -n "$NEW_VERSION" ]; then
  echo "Next steps:"
  echo "  - Test the application"
  echo "  - Commit version changes: git commit -am 'Bump version to $VERSION'"
  echo "  - Tag the release: git tag v$VERSION"
  echo "  - Push to GitHub: git push && git push --tags"
  echo ""
fi
