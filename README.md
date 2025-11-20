# Deepgram Voice Keyboard for Linux

![alt text](image.png)

**Status**: Working prototype! Successfully types into applications on Wayland (KDE Plasma 25.10)

A system-level voice-to-text/dictation application for Ubuntu Linux using Deepgram's cloud STT API. Types wherever your cursor is - works across all applications on Wayland.

## Installation

### Option 1: Install from Debian Package (Recommended)

1. Download the latest `.deb` package from [Releases](https://github.com/danielrosehill/Voice-Typing-Ubuntu-App/releases)

2. Install:
```bash
sudo dpkg -i voice-keyboard_0.1.0_amd64.deb
sudo apt-get install -f  # Fix dependencies if needed
```

3. Set your Deepgram API key:
```bash
export DEEPGRAM_API_KEY="your-api-key-here"
# Add to ~/.bashrc or ~/.zshrc for persistence
```

4. Run:
```bash
voice-keyboard-launcher --test-stt
```

Or launch from your application menu.

### Option 2: Build from Source

1. Set your Deepgram API key:
```bash
export DEEPGRAM_API_KEY="your-api-key-here"
```

2. Run the application:
```bash
./run.sh --test-stt
```

The run script will automatically:
- Create a Python virtual environment (for future GUI components)
- Build the Rust application
- Run with proper privilege handling (sudo for keyboard creation, drops to user for audio)

### Building a Debian Package

To build your own `.deb` package:

```bash
./build-deb.sh
```

See [PACKAGING.md](PACKAGING.md) for detailed packaging documentation.

## Validated

✓ Text input into Kate text editor on Wayland (KDE Plasma 25.10)
✓ Cloud-based STT via Deepgram API
✓ Real-time transcription with on-the-fly punctuation

## Project Structure

```
Voice-Typing-Ubuntu-App/
├── app/                    # Main application code (Rust)
│   ├── src/               # Source files
│   │   ├── main.rs        # Entry point with privilege handling
│   │   ├── audio_input.rs # Audio capture via CPAL
│   │   ├── stt_client.rs  # Deepgram WebSocket client
│   │   ├── virtual_keyboard.rs # Virtual keyboard & typing logic
│   │   └── input_event.rs # Linux input event definitions
│   ├── Cargo.toml         # Dependencies and build config
│   └── target/            # Build artifacts
├── build-deb.sh           # Build Debian package
├── update-package.sh      # Update version and rebuild
├── run.sh                 # Convenience script to build and run
├── CLAUDE.md              # AI assistant context
├── PACKAGING.md           # Debian packaging documentation
└── README.md              # This file
```

## Roadmap

See [PROJECT_NOTES.md](PROJECT_NOTES.md) for the complete feature roadmap and project context.

### MVP Features (In Priority Order)

1. **Hotkey support** - Configurable activation key (default: F13), tap-to-start/tap-to-stop, with PTT option
2. **Microphone handling** - Device selection with persistent settings
3. **Model selection** - Starting with Deepgram, future: multiple cloud providers
4. **GUI** - Simple interface with system tray integration
5. **Type anywhere** - ✓ Works on Wayland across all applications
6. **API spend monitoring** - Track usage costs with hourly polling

### Future Enhancements

- Mic level monitoring with dB display and alerts
- Post-processing for transcriptions
- Custom dictionary/replacements
- Long-form STT with chunking for extended recordings

## Why This Project?

After a year of voice typing becoming my default input method, I needed an OS-level dictation solution that:
- Works with cloud STT APIs (not local inference)
- Types anywhere on Wayland (the critical technical hurdle)
- Supports quality real-time transcription with punctuation
- Provides cost visibility for API usage

This builds on [Deepgram's voice-keyboard-linux starter](https://github.com/deepgram/voice-keyboard-linux) which successfully solved the Wayland typing challenge.

## Technical Details

- **Language**: Rust (core), Python (future GUI)
- **STT Provider**: Deepgram cloud API
- **OS**: Ubuntu 25.10 with KDE Plasma on Wayland
- **Audio**: PipeWire via CPAL
- **Input**: Virtual keyboard device via uinput

## Credits

Based on [Deepgram's voice-keyboard-linux](https://github.com/deepgram/voice-keyboard-linux) starter project.
