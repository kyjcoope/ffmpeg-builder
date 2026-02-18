#!/bin/bash
# Build FFmpeg for a specific macOS architecture
#
# Usage: ./build-arch.sh <arch>
#   arch: arm64 or x86_64
#
# This script is called by build-macos.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common/utils.sh"
source "$(get_project_root)/config/ffmpeg-config.sh"

# Configuration
MACOS_MIN_VERSION="${MACOS_MIN_VERSION:-11.0}"
ARCH="${1:?Usage: build-arch.sh <arch> (arm64 or x86_64)}"
PLATFORM="macosx"
BUILD_DIR="$(get_build_dir)/macos/$ARCH"
FFMPEG_SOURCE="$(get_ffmpeg_source_dir)"

main() {
    log_info "Building for macOS ($ARCH)"
    log_info "  Architecture: $ARCH"
    log_info "  Platform: $PLATFORM"
    log_info "  Min macOS: $MACOS_MIN_VERSION"
    
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
    local cflags="-arch $ARCH -mmacosx-version-min=$MACOS_MIN_VERSION -isysroot $sdk_path"
    local ldflags="-arch $ARCH -mmacosx-version-min=$MACOS_MIN_VERSION -isysroot $sdk_path"
    
    log_info "Configuring FFmpeg..."
    ./configure \
        --prefix="$BUILD_DIR" \
        --enable-cross-compile \
        --target-os=darwin \
        --arch="$ARCH" \
        --cc="$cc" \
        --sysroot="$sdk_path" \
        --extra-cflags="$cflags" \
        --extra-ldflags="$ldflags" \
        $(get_ffmpeg_configure_flags) \
        $(get_macos_flags)
    
    log_info "Building FFmpeg..."
    make -j"$(get_cpu_count)"
    
    log_info "Installing to $BUILD_DIR..."
    make install
    
    log_success "macOS ($ARCH) build complete"
}

main "$@"
