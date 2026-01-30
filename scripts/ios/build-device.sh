#!/bin/bash
# Build FFmpeg for iOS Device (arm64)
#
# This script is called by build-ios.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common/utils.sh"
source "$(get_project_root)/config/ffmpeg-config.sh"

# Configuration
IOS_MIN_VERSION="${IOS_MIN_VERSION:-13.0}"
ARCH="arm64"
PLATFORM="iphoneos"
BUILD_DIR="$(get_build_dir)/ios/device"
FFMPEG_SOURCE="$(get_ffmpeg_source_dir)"

main() {
    log_info "Building for iOS Device"
    log_info "  Architecture: $ARCH"
    log_info "  Platform: $PLATFORM"
    log_info "  Min iOS: $IOS_MIN_VERSION"
    
    # Get SDK path
    local sdk_path
    sdk_path=$(xcrun --sdk "$PLATFORM" --show-sdk-path)
    log_info "  SDK Path: $sdk_path"
    
    # Set up compiler
    local cc
    cc="$(xcrun --sdk $PLATFORM --find clang)"
    
    # Prepare build directory
    mkdir -p "$BUILD_DIR"
    cd "$FFMPEG_SOURCE"
    
    # Clean previous build
    make distclean 2>/dev/null || true
    
    # Configure flags
    local cflags="-arch $ARCH -miphoneos-version-min=$IOS_MIN_VERSION -isysroot $sdk_path -fembed-bitcode-marker"
    local ldflags="-arch $ARCH -miphoneos-version-min=$IOS_MIN_VERSION -isysroot $sdk_path"
    
    log_info "Configuring FFmpeg..."
    # audiotoolbox uses macOS-only CoreAudio APIs (AudioDeviceID, etc.) - disable for iOS
    # scale_vt uses VTPixelTransferSession which requires iOS 16+ - disable for iOS 13+ compat
    ./configure \
        --prefix="$BUILD_DIR" \
        --enable-cross-compile \
        --target-os=darwin \
        --arch="$ARCH" \
        --cc="$cc" \
        --sysroot="$sdk_path" \
        --extra-cflags="$cflags" \
        --extra-ldflags="$ldflags" \
        --disable-indev=audiotoolbox \
        --disable-outdev=audiotoolbox \
        --disable-filter=scale_vt \
        $(get_ffmpeg_configure_flags)
    
    log_info "Building FFmpeg..."
    make -j"$(get_cpu_count)"
    
    log_info "Installing to $BUILD_DIR..."
    make install
    
    log_success "iOS Device build complete"
}

main "$@"
