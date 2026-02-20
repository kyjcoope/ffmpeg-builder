#!/bin/bash
# FFmpeg shared configuration flags
# Edit this file to customize the build

# FFmpeg version (git tag) - 6.1 has macOS AudioToolbox fixes
FFMPEG_VERSION="${FFMPEG_VERSION:-n6.1}"

# Libraries to build
FFMPEG_LIBS=(
    "libavcodec"
    "libavdevice"
    "libavfilter"
    "libavformat"
    "libavutil"
    "libswresample"
    "libswscale"
)

# Common configure flags for all platforms
get_common_flags() {
    echo "\
        --enable-version3 \
        --enable-pic \
        --enable-optimizations \
        --enable-pthreads \
        --enable-small \
        --enable-lto \
        --disable-static \
        --enable-shared \
        --disable-autodetect \
        --disable-debug \
        --disable-doc \
        --disable-htmlpages \
        --disable-manpages \
        --disable-podpages \
        --disable-txtpages \
        --disable-programs \
        --disable-postproc \
        --disable-symver \
        --disable-stripping"
}

# Get enabled components
get_enabled_components() {
    echo "\
        --enable-avcodec \
        --enable-avdevice \
        --enable-avfilter \
        --enable-avformat \
        --enable-swresample \
        --enable-swscale"
}

# Get disabled components (for smaller binary size and cross-platform compat)
get_disabled_components() {
    echo "\
        --disable-xlib \
        --disable-sdl2 \
        --disable-sndio \
        --disable-schannel \
        --disable-xmm-clobber-test \
        --disable-neon-clobber-test"
}

# Android-specific flags
get_android_flags() {
    echo "\
        --enable-jni \
        --enable-mediacodec \
        --enable-decoder=h264_mediacodec \
        --enable-decoder=hevc_mediacodec \
        --enable-neon \
        --enable-asm \
        --enable-inline-asm \
        --disable-vulkan \
        --disable-v4l2-m2m \
        --disable-indev=fbdev \
        --disable-outdev=fbdev"
}

# iOS-specific flags
get_ios_flags() {
    echo "\
        --enable-videotoolbox \
        --disable-audiotoolbox \
        --disable-appkit \
        --disable-coreimage \
        --disable-vulkan"
}

# macOS-specific flags
get_macos_flags() {
    echo "\
        --enable-videotoolbox \
        --enable-audiotoolbox \
        --enable-appkit \
        --disable-vulkan"
}

# Linux-specific flags (VAAPI for Intel/AMD hardware decoding)
get_linux_flags() {
    echo "\
        --enable-vaapi \
        --disable-vdpau \
        --disable-vulkan"
}

# Windows native flags (DXVA2/D3D11VA hardware decoding, built on Windows via MSYS2)
get_windows_native_flags() {
    echo "\
        --enable-dxva2 \
        --enable-d3d11va \
        --disable-vulkan"
}

# Windows cross-compile flags (software-only, built from Linux/macOS via mingw-w64)
get_windows_cross_flags() {
    echo "\
        --disable-vulkan"
}

# Full configure flags — pass optional platform name to include platform-specific flags
# Usage: get_ffmpeg_configure_flags [platform]
# Platforms: ios, macos, android, linux, windows-native, windows-cross
get_ffmpeg_configure_flags() {
    local platform="${1:-}"
    local flags="$(get_common_flags) $(get_enabled_components) $(get_disabled_components)"

    case "$platform" in
        ios)             flags="$flags $(get_ios_flags)" ;;
        macos)           flags="$flags $(get_macos_flags)" ;;
        android)         flags="$flags $(get_android_flags)" ;;
        linux)           flags="$flags $(get_linux_flags)" ;;
        windows-native)  flags="$flags $(get_windows_native_flags)" ;;
        windows-cross)   flags="$flags $(get_windows_cross_flags)" ;;
        "")              ;; # No platform, base flags only
        *)               echo "Warning: Unknown platform '$platform'" >&2 ;;
    esac

    echo "$flags"
}
