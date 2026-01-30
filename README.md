# FFmpeg Builder

Automated build scripts for compiling FFmpeg as native libraries for **Android** (`.so`) and **iOS** (`.xcframework`).

## Features

- 📱 **iOS XCFramework** — Universal binary supporting devices and simulators (arm64 + x86_64)
- 🤖 **Android** — Shared libraries for arm64-v8a, armeabi-v7a, x86_64, x86 with 16KB page alignment
- 🔄 **Automated** — Single command builds, GitHub Actions CI/CD ready
- 📦 **Latest FFmpeg** — Builds the latest stable release

## Prerequisites

### For iOS Builds (macOS only)
- macOS 12+ with Xcode 14+ installed
- Xcode Command Line Tools: `xcode-select --install`

### For Android Builds
- Android NDK r25 or newer
- Set `ANDROID_NDK_HOME` environment variable

### Common
- `git`, `make`, `yasm` or `nasm`
- On macOS: `brew install yasm nasm pkg-config`

## Quick Start

### Clone the Repository
```bash
git clone https://github.com/YOUR_USERNAME/ffmpeg-builder.git
cd ffmpeg-builder
```

### Download FFmpeg Source
```bash
./scripts/common/download-ffmpeg.sh
```

### Build for iOS
```bash
./scripts/ios/build-ios.sh
# Output: output/ios/*.xcframework
```

### Build for Android
```bash
export ANDROID_NDK_HOME=/path/to/android-ndk
./scripts/android/build-android.sh
# Output: output/android/<arch>/lib/*.so
```

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `FFMPEG_VERSION` | latest | Git tag to checkout (e.g., `n7.1`) |
| `IOS_MIN_VERSION` | `13.0` | Minimum iOS deployment target |
| `ANDROID_MIN_SDK` | `21` | Minimum Android API level |
| `ANDROID_NDK_HOME` | — | Path to Android NDK (required) |

### FFmpeg Configure Flags

Edit `config/ffmpeg-config.sh` to customize enabled features and codecs.

## Output Structure

```
output/
├── ios/
│   ├── libavcodec.xcframework/
│   ├── libavformat.xcframework/
│   ├── libavutil.xcframework/
│   ├── libswresample.xcframework/
│   ├── libswscale.xcframework/
│   ├── libavdevice.xcframework/
│   └── libavfilter.xcframework/
│
└── android/
    ├── arm64-v8a/
    │   ├── include/
    │   └── lib/
    ├── armeabi-v7a/
    ├── x86_64/
    └── x86/
```

## CI/CD

GitHub Actions workflow is included. Push a tag to trigger a release build:

```bash
git tag v1.0.0
git push origin v1.0.0
```

## License

This project's build scripts are MIT licensed. FFmpeg itself is licensed under LGPL/GPL depending on configuration.
