#!/usr/bin/env bash

# Voice Keyboard Package Update Script
# Updates the version, rebuilds, and optionally reinstalls the package

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$SCRIPT_DIR/app"
PACKAGE_NAME="voice-keyboard"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_usage() {
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  -v VERSION    Set new version (e.g., 0.2.0)"
  echo "  -i            Install after building"
  echo "  -r            Reinstall (remove old version first)"
  echo "  -h            Show this help message"
  echo ""
  echo "Examples:"
  echo "  $0 -v 0.2.0              # Build new version"
  echo "  $0 -v 0.2.0 -i           # Build and install"
  echo "  $0 -v 0.2.0 -r           # Build and reinstall"
  echo "  $0                       # Just rebuild current version"
}

# Parse command line arguments
NEW_VERSION=""
INSTALL=false
REINSTALL=false

while getopts "v:irh" opt; do
  case $opt in
    v)
      NEW_VERSION="$OPTARG"
      ;;
    i)
      INSTALL=true
      ;;
    r)
      REINSTALL=true
      INSTALL=true
      ;;
    h)
      print_usage
      exit 0
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      print_usage
      exit 1
      ;;
  esac
done

# Get current version from Cargo.toml
CURRENT_VERSION=$(grep '^version = ' "$APP_DIR/Cargo.toml" | head -n 1 | sed 's/version = "\(.*\)"/\1/')

if [ -z "$CURRENT_VERSION" ]; then
  echo -e "${RED}Error: Could not determine current version from Cargo.toml${NC}"
  exit 1
fi

echo "Current version: $CURRENT_VERSION"

# Update version if requested
if [ -n "$NEW_VERSION" ]; then
  echo -e "${YELLOW}Updating version from $CURRENT_VERSION to $NEW_VERSION${NC}"

  # Update Cargo.toml
  sed -i "s/^version = \".*\"/version = \"$NEW_VERSION\"/" "$APP_DIR/Cargo.toml"

  # Update build-deb.sh
  sed -i "s/^VERSION=\".*\"/VERSION=\"$NEW_VERSION\"/" "$SCRIPT_DIR/build-deb.sh"

  echo -e "${GREEN}Version updated to $NEW_VERSION${NC}"
  VERSION="$NEW_VERSION"
else
  VERSION="$CURRENT_VERSION"
fi

# Clean previous build artifacts
echo "Cleaning previous build artifacts..."
if [ -d "$SCRIPT_DIR/debian-build" ]; then
  rm -rf "$SCRIPT_DIR/debian-build"
fi

# Remove old .deb files
OLD_DEBS=$(ls "$SCRIPT_DIR"/${PACKAGE_NAME}_*.deb 2>/dev/null || true)
if [ -n "$OLD_DEBS" ]; then
  echo "Removing old .deb files..."
  rm -f "$SCRIPT_DIR"/${PACKAGE_NAME}_*.deb
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
fi

# Build the package
echo -e "${YELLOW}Building Debian package...${NC}"
bash "$SCRIPT_DIR/build-deb.sh"

if [ $? -ne 0 ]; then
  echo -e "${RED}Package build failed!${NC}"
  exit 1
fi

PACKAGE_FILE="${PACKAGE_NAME}_${VERSION}_amd64.deb"

if [ ! -f "$SCRIPT_DIR/$PACKAGE_FILE" ]; then
  echo -e "${RED}Error: Package file not found: $PACKAGE_FILE${NC}"
  exit 1
fi

echo -e "${GREEN}Package built successfully: $PACKAGE_FILE${NC}"

# Install or reinstall if requested
if [ "$INSTALL" = true ]; then
  if [ "$REINSTALL" = true ]; then
    echo -e "${YELLOW}Removing old version...${NC}"
    sudo dpkg -r "$PACKAGE_NAME" 2>/dev/null || true
  fi

  echo -e "${YELLOW}Installing package...${NC}"
  sudo dpkg -i "$SCRIPT_DIR/$PACKAGE_FILE"

  if [ $? -ne 0 ]; then
    echo -e "${YELLOW}Attempting to fix dependencies...${NC}"
    sudo apt-get install -f -y
  fi

  # Verify installation
  if dpkg -l | grep -q "^ii.*$PACKAGE_NAME"; then
    echo -e "${GREEN}Package installed successfully!${NC}"
    echo ""
    echo "Installed version:"
    dpkg -l | grep "$PACKAGE_NAME"
  else
    echo -e "${RED}Installation verification failed!${NC}"
    exit 1
  fi
fi

# Summary
echo ""
echo -e "${GREEN}Update complete!${NC}"
echo ""
echo "Package file: $PACKAGE_FILE"
echo "Version: $VERSION"

if [ "$INSTALL" = true ]; then
  echo "Status: Installed"
  echo ""
  echo "To run:"
  echo "  voice-keyboard-launcher --test-stt"
else
  echo "Status: Built (not installed)"
  echo ""
  echo "To install:"
  echo "  sudo dpkg -i $PACKAGE_FILE"
  echo "  sudo apt-get install -f  # If there are dependency issues"
fi

echo ""
echo "Next steps:"
echo "  - Test the application"
echo "  - Commit version changes to git"
echo "  - Tag the release: git tag v$VERSION"
echo "  - Push to GitHub: git push && git push --tags"
