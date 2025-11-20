# Debian Package Build Guide

This document describes how to build and distribute the Voice Keyboard application as a Debian package (.deb) for Ubuntu systems.

## Quick Start

### Build a Package

```bash
./build-deb.sh
```

This creates: `voice-keyboard_0.1.0_amd64.deb`

### Update Version and Rebuild

```bash
# Build new version
./update-package.sh -v 0.2.0

# Build and install
./update-package.sh -v 0.2.0 -i

# Build and reinstall (removes old version first)
./update-package.sh -v 0.2.0 -r
```

## Scripts Overview

### build-deb.sh

Builds a complete Debian package with:
- Compiled Rust binary in release mode
- Launcher wrapper script for privilege handling
- Desktop entry for application menu
- udev rules for uinput device access
- Documentation (README, CLAUDE.md, LICENSE)
- Postinstall script for setup

**Output**: `voice-keyboard_VERSION_amd64.deb`

### update-package.sh

Manages version updates and rebuilding:
- Updates version in Cargo.toml and build-deb.sh
- Cleans old build artifacts
- Runs tests (if available)
- Builds new package
- Optionally installs or reinstalls

**Usage**:
```bash
./update-package.sh [OPTIONS]

Options:
  -v VERSION    Set new version (e.g., 0.2.0)
  -i            Install after building
  -r            Reinstall (remove old version first)
  -h            Show help
```

## Package Structure

```
voice-keyboard_0.1.0_amd64.deb
├── DEBIAN/
│   ├── control              # Package metadata
│   ├── postinst             # Post-installation script
│   └── prerm                # Pre-removal script
├── usr/
│   ├── bin/
│   │   ├── voice-keyboard           # Main binary
│   │   └── voice-keyboard-launcher  # Wrapper script
│   ├── share/
│   │   ├── applications/
│   │   │   └── voice-keyboard.desktop
│   │   ├── icons/hicolor/256x256/apps/
│   │   │   └── voice-keyboard.png
│   │   └── doc/voice-keyboard/
│   │       ├── README.md
│   │       ├── CLAUDE.md
│   │       └── copyright
└── etc/
    └── udev/rules.d/
        └── 99-voice-keyboard.rules
```

## Installation

### From .deb Package

```bash
# Install
sudo dpkg -i voice-keyboard_0.1.0_amd64.deb

# Fix dependencies if needed
sudo apt-get install -f
```

### Post-Installation Setup

1. **Set Deepgram API key**:
   ```bash
   export DEEPGRAM_API_KEY="your-api-key-here"
   ```
   Add to `~/.bashrc` or `~/.zshrc` for persistence.

2. **Log out and log back in** (if newly added to input group)

3. **Run the application**:
   ```bash
   voice-keyboard-launcher --test-stt
   ```
   Or launch from application menu.

## Uninstallation

```bash
sudo dpkg -r voice-keyboard
```

## Dependencies

### Build Dependencies

- Rust toolchain (cargo, rustc)
- Standard build tools (gcc, make, etc.)
- dpkg-deb

### Runtime Dependencies

- libc6
- libgcc-s1
- sudo

### Recommended

- pipewire (or pulseaudio)
- PipeWire audio system

## Version Management

The version is stored in two places:
1. `app/Cargo.toml` - Rust package version
2. `build-deb.sh` - Debian package version

Use `update-package.sh -v VERSION` to update both automatically.

## Distribution

### Local Distribution

Share the `.deb` file directly:
```bash
# Users install with:
sudo dpkg -i voice-keyboard_VERSION_amd64.deb
```

### Repository Distribution (Future)

For broader distribution, consider:
1. **PPA (Personal Package Archive)** on Launchpad
2. **GitHub Releases** with attached .deb files
3. **Custom APT repository**

## Troubleshooting

### Build Fails

**Issue**: Cargo build errors
```bash
# Check Rust installation
rustc --version
cargo --version

# Update Rust
rustup update
```

**Issue**: Missing dependencies
```bash
# Install build essentials
sudo apt-get install build-essential
```

### Installation Fails

**Issue**: Dependency errors
```bash
# Attempt to fix
sudo apt-get install -f
```

**Issue**: Permission denied
```bash
# Ensure you're using sudo
sudo dpkg -i voice-keyboard_VERSION_amd64.deb
```

### Runtime Issues

**Issue**: uinput device access denied
```bash
# Check group membership
groups

# Should include "input" group
# If not, log out and log back in
```

**Issue**: Audio device not found
```bash
# Check PipeWire status
systemctl --user status pipewire

# List audio devices
pactl list sources short
```

## Advanced Customization

### Changing Installation Prefix

Currently installs to `/usr/bin`. To change:

Edit `build-deb.sh`:
```bash
mkdir -p "$BUILD_DIR/opt/voice-keyboard/bin"
cp "$APP_DIR/target/release/voice-keyboard" "$BUILD_DIR/opt/voice-keyboard/bin/"
```

Update paths in launcher script and desktop file accordingly.

### Adding Additional Files

Edit `build-deb.sh`:
```bash
# Example: Add config file
mkdir -p "$BUILD_DIR/etc/voice-keyboard"
cp your-config.toml "$BUILD_DIR/etc/voice-keyboard/config.toml"
```

### Custom Postinstall Actions

Edit `DEBIAN/postinst` section in `build-deb.sh`:
```bash
cat > "$BUILD_DIR/DEBIAN/postinst" << 'EOF'
#!/bin/bash
set -e

# Your custom setup here

exit 0
EOF
```

## Release Workflow

1. **Make changes and test**:
   ```bash
   ./run.sh --test-stt
   ```

2. **Update version**:
   ```bash
   ./update-package.sh -v 0.2.0
   ```

3. **Test package installation**:
   ```bash
   ./update-package.sh -r  # Reinstall
   voice-keyboard-launcher --test-stt
   ```

4. **Commit and tag**:
   ```bash
   git add -A
   git commit -m "Release v0.2.0"
   git tag v0.2.0
   git push && git push --tags
   ```

5. **Create GitHub release**:
   - Attach `.deb` file
   - Add release notes
   - Mark as release/pre-release

## CI/CD Integration (Future)

Example GitHub Actions workflow for automated builds:

```yaml
name: Build Debian Package

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: actions-rs/toolchain@v1
        with:
          toolchain: stable
      - name: Build package
        run: ./build-deb.sh
      - name: Upload Release Asset
        uses: actions/upload-release-asset@v1
        with:
          upload_url: ${{ steps.create_release.outputs.upload_url }}
          asset_path: ./voice-keyboard_*_amd64.deb
          asset_name: voice-keyboard_${{ github.ref_name }}_amd64.deb
          asset_content_type: application/vnd.debian.binary-package
```

## Support

For issues or questions:
- GitHub Issues: https://github.com/danielrosehill/Voice-Typing-Ubuntu-App/issues
- Email: public@danielrosehill.com
