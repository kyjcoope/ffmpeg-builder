# FFmpeg Builder

Automated build scripts for compiling FFmpeg as native libraries for **Android**, **iOS**, **macOS**, and **Desktop** platforms.

## Features

- 📱 **iOS XCFramework** — Universal binary supporting devices + simulators (arm64 + x86_64)
- 🍎 **macOS Frameworks** — Universal binary frameworks (arm64 + x86_64) with VideoToolbox + AudioToolbox
- 🤖 **Android** — Shared libraries with 16KB page alignment for Android 15+
- 🖥️ **Desktop** — Linux, macOS (universal), Windows (cross-compile)
- 🔄 **Automated** — Single command builds, skip existing, GitHub Actions ready
- 📦 **FFmpeg 6.1** — Configurable version (default: 6.1)

## Quick Start

```bash
# 1. Clone the repo
git clone https://github.com/YOUR_USERNAME/ffmpeg-builder.git
cd ffmpeg-builder

# 2. Make scripts executable
chmod +x scripts/**/*.sh build-all.sh

# 3. Download FFmpeg source
./scripts/common/download-ffmpeg.sh

# 4. Build for mobile platforms (iOS + Android)
./build-all.sh --setup-ndk
```

## Build Commands

### Build All (Mobile)
```bash
./build-all.sh                    # iOS + Android (default)
./build-all.sh --macos            # iOS + Android + macOS
./build-all.sh --desktop          # iOS + Android + Desktop
./build-all.sh --skip-download    # Skip FFmpeg download
./build-all.sh --setup-ndk        # Auto-download NDK if missing
```

### Build Individual Platforms
```bash
./scripts/ios/build-ios.sh              # iOS XCFrameworks
./scripts/macos/build-macos.sh          # macOS Frameworks (arm64 + x86_64)
./scripts/android/build-android.sh      # Android all architectures
./scripts/desktop/build-desktop.sh      # Desktop (current platform)
```

### Build Options
| Flag | Description |
|------|-------------|
| `--force` | Rebuild even if output exists |
| `--clean` | Clean build directories first |
| `--ios-only` | Build only iOS |
| `--macos-only` | Build only macOS |
| `--android-only` | Build only Android |
| `--desktop-only` | Build only desktop |
| `--macos` | Also build macOS frameworks |
| `--desktop` | Also build desktop |
| `--mobile-only` | Skip macOS/desktop builds |
| `--setup-ndk` | Auto-download Android NDK |

## Output Structure

```
output/
├── ios/
│   ├── libavcodec.xcframework/
│   ├── libavformat.xcframework/
│   └── ...
├── macos/
│   ├── libavcodec.framework/
│   ├── libavformat.framework/
│   └── ...
├── android/
│   ├── arm64-v8a/lib/
│   ├── armeabi-v7a/lib/
│   └── x86_64/lib/
└── desktop/
    ├── linux/lib/
    ├── macos/lib/
    └── windows/lib/
```

## Hardware Acceleration

| Platform | Hardware Decode/Encode | Details |
|----------|----------------------|---------|
| **iOS** | VideoToolbox | H.264/HEVC hardware codec |
| **macOS** | VideoToolbox + AudioToolbox | Video + audio hardware codecs |
| **Android** | MediaCodec | H.264/HEVC via JNI |
| **Desktop** | None | Software-only |

## Configuration

### Environment Variables
| Variable | Default | Description |
|----------|---------|-------------|
| `FFMPEG_VERSION` | `n6.1` | Git tag to build |
| `IOS_MIN_VERSION` | `13.0` | Minimum iOS version |
| `MACOS_MIN_VERSION` | `11.0` | Minimum macOS version (Big Sur) |
| `ANDROID_MIN_SDK` | `21` | Minimum Android API level |
| `ANDROID_NDK_HOME` | auto | Path to NDK (auto-detected) |

### Customize FFmpeg
Edit `config/ffmpeg-config.sh` to change:
- FFmpeg version
- Enabled/disabled features
- Libraries to build

## Platform Requirements

| Platform | Requirements |
|----------|-------------|
| **iOS** | macOS + Xcode 14+ |
| **macOS** | macOS + Xcode 14+ (or Command Line Tools) |
| **Android** | NDK r25+ (auto-downloaded with `--setup-ndk`) |
| **Desktop Linux** | GCC/Clang, make |
| **Desktop macOS** | Xcode Command Line Tools |
| **Desktop Windows** | mingw-w64 (cross-compile from Linux/macOS) |

## Android Architectures

| Architecture | Description | Built |
|-------------|-------------|-------|
| arm64-v8a | 64-bit ARM (modern phones) | ✅ |
| armeabi-v7a | 32-bit ARM (legacy) | ✅ |
| x86_64 | Emulators, Chromebooks | ✅ |
| x86 | Very legacy (skipped) | ❌ |

All Android builds include **16KB page alignment** for Android 15+ compatibility.

## CI/CD

GitHub Actions workflow included. Push a tag to trigger builds:

```bash
git tag v1.0.0
git push origin v1.0.0
```

Builds iOS, macOS, and Android in parallel. Release artifacts include:
- `ffmpeg-ios-xcframeworks.zip`
- `ffmpeg-macos-frameworks.zip`
- `ffmpeg-android-libs.zip`

## License

Build scripts: MIT. FFmpeg: LGPL/GPL depending on configuration.
