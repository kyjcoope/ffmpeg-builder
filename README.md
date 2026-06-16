# FFmpeg Builder

Automated build scripts for compiling FFmpeg as native libraries for **Android**, **iOS**, **macOS**, **Windows**, and **Linux** platforms.

## Features

- 📱 **iOS XCFramework** — Universal binary supporting devices + simulators (arm64 + x86_64)
- 🍎 **macOS Frameworks** — Universal binary frameworks (arm64 + x86_64) with VideoToolbox + AudioToolbox
- 🤖 **Android** — Shared libraries with 16KB page alignment for Android 15+
- 🪟 **Windows** — Native build with DXVA2 + D3D11VA hardware acceleration (via MSYS2)
- 🐧 **Linux** — Shared libraries with VAAPI hardware acceleration
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
./build-all.sh --desktop          # iOS + Android + Desktop (Linux + Windows cross-compile)
./build-all.sh --windows          # iOS + Android + Windows native (DXVA2/D3D11VA)
./build-all.sh --skip-download    # Skip FFmpeg download
./build-all.sh --setup-ndk        # Auto-download NDK if missing
```

### Build Individual Platforms
```bash
./scripts/ios/build-ios.sh              # iOS XCFrameworks
./scripts/macos/build-macos.sh          # macOS Frameworks (arm64 + x86_64)
./scripts/android/build-android.sh      # Android all architectures
./scripts/desktop/build-desktop.sh      # Desktop (Linux + Windows cross-compile)
./scripts/windows/build-native.sh       # Windows native (run from MSYS2 shell)
```

### Windows Native Build (from PowerShell)
```powershell
# Option 1: PowerShell script (handles MSYS2 setup automatically)
.\scripts\windows\build-windows-native.ps1

# Option 2: With options
.\scripts\windows\build-windows-native.ps1 -Force            # Rebuild even if exists
.\scripts\windows\build-windows-native.ps1 -Clean            # Clean build directories first
.\scripts\windows\build-windows-native.ps1 -SkipMsys2Setup   # Skip MSYS2 package installation
```

### Build Options
| Flag | Description |
|------|-------------|
| `--force` | Rebuild even if output exists |
| `--clean` | Clean build directories first |
| `--ios-only` | Build only iOS |
| `--macos-only` | Build only macOS |
| `--android-only` | Build only Android |
| `--desktop-only` | Build only desktop (Linux + Windows cross-compile) |
| `--windows-only` | Build only Windows native (DXVA2/D3D11VA) |
| `--macos` | Also build macOS frameworks |
| `--desktop` | Also build desktop |
| `--windows` | Also build Windows native |
| `--mobile-only` | Skip macOS/desktop/Windows builds |
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
├── windows/
│   ├── bin/*.dll
│   ├── lib/
│   └── include/
└── desktop/
    ├── linux/lib/
    └── windows/lib/  (cross-compiled, software-only)
```

## Hardware Acceleration

| Platform | Hardware Decode/Encode | Details |
|----------|----------------------|---------|
| **iOS** | VideoToolbox | H.264/HEVC hardware codec |
| **macOS** | VideoToolbox + AudioToolbox | Video + audio hardware codecs |
| **Android** | MediaCodec | H.264/HEVC via JNI |
| **Windows (native)** | DXVA2 + D3D11VA | DirectX hardware decode (H.264/HEVC) |
| **Linux** | VAAPI | Intel/AMD hardware decode |
| **Windows (cross-compile)** | None | Software-only |

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
- Platform-specific hardware acceleration flags
- Libraries to build

All platform build scripts use the shared config via `get_ffmpeg_configure_flags "platform"`:
```bash
# Platform names: ios, macos, android, linux, windows-native, windows-cross
get_ffmpeg_configure_flags "ios"            # Base flags + iOS (VideoToolbox)
get_ffmpeg_configure_flags "macos"          # Base flags + macOS (VideoToolbox + AudioToolbox)
get_ffmpeg_configure_flags "android"        # Base flags + Android (MediaCodec)
get_ffmpeg_configure_flags "linux"          # Base flags + Linux (VAAPI)
get_ffmpeg_configure_flags "windows-native" # Base flags + Windows (DXVA2 + D3D11VA)
get_ffmpeg_configure_flags "windows-cross"  # Base flags + Windows (software-only)
```

## Platform Requirements

| Platform | Requirements |
|----------|-------------|
| **iOS** | macOS + Xcode 14+ |
| **macOS** | macOS + Xcode 14+ (or Command Line Tools) |
| **Android** | NDK r28+ recommended (16KB-aligned by default; auto-downloaded with `--setup-ndk`). r27 and lower also work — the build passes the 16KB linker flags explicitly. |
| **Windows (native)** | Windows 10+ with MSYS2 (auto-installed by PowerShell script) |
| **Linux** | GCC/Clang, make, libva-dev (for VAAPI) |
| **Windows (cross-compile)** | Linux or macOS with mingw-w64 |

### Windows Native Prerequisites

The PowerShell script `build-windows-native.ps1` handles MSYS2 setup automatically, but you can also set it up manually:

1. Install [MSYS2](https://www.msys2.org/)
2. Open **MSYS2 MINGW64** shell
3. Install packages:
   ```bash
   pacman -S mingw-w64-x86_64-toolchain mingw-w64-x86_64-yasm mingw-w64-x86_64-nasm make diffutils pkg-config git
   ```
4. Run the build:
   ```bash
   cd /path/to/ffmpeg-builder
   ./scripts/windows/build-native.sh
   ```

### Linux Prerequisites

For hardware-accelerated builds with VAAPI, install the VAAPI development headers:

```bash
# Ubuntu/Debian
sudo apt-get install libva-dev

# Fedora/RHEL
sudo dnf install libva-devel

# Arch Linux
sudo pacman -S libva
```

## Android Architectures

| Architecture | Description | Built |
|-------------|-------------|-------|
| arm64-v8a | 64-bit ARM (modern phones) | ✅ |
| armeabi-v7a | 32-bit ARM (legacy) | ✅ |
| x86_64 | Emulators, Chromebooks | ✅ |
| x86 | Very legacy (skipped) | ❌ |

All 64-bit Android builds use **16KB ELF page alignment** for Android 15+ (API 35+)
compatibility, required by Google Play. The build links with
`-Wl,-z,max-page-size=16384 -Wl,-z,common-page-size=16384` and every build is
gated by `scripts/android/verify-16kb.sh`, which fails if any 64-bit `.so` has a
LOAD segment aligned below `2**14`. Run it standalone any time:

```bash
./scripts/android/verify-16kb.sh            # checks output/android/{arm64-v8a,x86_64}
```

> Note: the consuming Android/Flutter app is still responsible for APK/AAB zip
> alignment (AGP 8.5.1+ / `zipalign -P 16`) and for shipping a 16KB-aligned
> `libc++_shared.so`. This builder only produces the FFmpeg `.so` files (pure C,
> no C++ runtime dependency).

## CI/CD

GitHub Actions workflow included. Push a tag to trigger builds:

```bash
git tag v1.0.0
git push origin v1.0.0
```

Builds iOS, macOS, Android, and Windows in parallel. Release artifacts include:
- `ffmpeg-ios-xcframeworks.zip`
- `ffmpeg-macos-frameworks.zip`
- `ffmpeg-android-libs.zip`
- `ffmpeg-windows-libs.zip`

## License

Build scripts: MIT. FFmpeg: LGPL/GPL depending on configuration.
