#!/bin/bash
# Build FFmpeg for iOS Simulator (arm64 + x86_64)
#
# This script builds for both simulator architectures and merges them with lipo
# Called by build-ios.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common/utils.sh"
source "$(get_project_root)/config/ffmpeg-config.sh"

# Configuration
IOS_MIN_VERSION="${IOS_MIN_VERSION:-13.0}"
PLATFORM="iphonesimulator"
BUILD_DIR="$(get_build_dir)/ios"
FFMPEG_SOURCE="$(get_ffmpeg_source_dir)"

# Architectures for simulator
ARCHS=("arm64" "x86_64")

build_arch() {
    local arch="$1"
    local arch_build_dir="$BUILD_DIR/simulator-$arch"
    
    log_info "Building for iOS Simulator ($arch)"
    
    # Get SDK path
    local sdk_path
    sdk_path=$(xcrun --sdk "$PLATFORM" --show-sdk-path)
    
    # Set up compiler
    local cc
    cc="$(xcrun --sdk $PLATFORM --find clang)"
    
    # Prepare build directory
    mkdir -p "$arch_build_dir"
    cd "$FFMPEG_SOURCE"
    
    # Clean previous build
    make distclean 2>/dev/null || true
    
    # Configure flags
    local cflags="-arch $arch -miphonesimulator-version-min=$IOS_MIN_VERSION -isysroot $sdk_path"
    local ldflags="-arch $arch -miphonesimulator-version-min=$IOS_MIN_VERSION -isysroot $sdk_path"
    
    log_info "Configuring FFmpeg for $arch..."
    # audiotoolbox uses macOS-only CoreAudio APIs (AudioDeviceID, etc.) - disable for iOS
    ./configure \
        --prefix="$arch_build_dir" \
        --enable-cross-compile \
        --target-os=darwin \
        --arch="$arch" \
        --cc="$cc" \
        --sysroot="$sdk_path" \
        --extra-cflags="$cflags" \
        --extra-ldflags="$ldflags" \
        --disable-indev=audiotoolbox \
        --disable-outdev=audiotoolbox \
        $(get_ffmpeg_configure_flags)
    
    log_info "Building FFmpeg for $arch..."
    make -j"$(get_cpu_count)"
    
    log_info "Installing to $arch_build_dir..."
    make install
    
    log_success "iOS Simulator ($arch) build complete"
}

merge_architectures() {
    log_info "Merging simulator architectures with lipo..."
    
    local merged_dir="$BUILD_DIR/simulator"
    mkdir -p "$merged_dir/lib"
    
    # Copy headers from first architecture
    cp -R "$BUILD_DIR/simulator-arm64/include" "$merged_dir/"
    
    # Get list of libraries
    local libs
    libs=$(ls "$BUILD_DIR/simulator-arm64/lib/"*.dylib 2>/dev/null || ls "$BUILD_DIR/simulator-arm64/lib/"*.a 2>/dev/null || true)
    
    if [[ -z "$libs" ]]; then
        die "No libraries found in simulator build"
    fi
    
    # Merge each library
    for lib_path in $libs; do
        local lib_name
        lib_name=$(basename "$lib_path")
        
        log_info "  Merging: $lib_name"
        
        # Build lipo command with all architectures
        local lipo_inputs=""
        for arch in "${ARCHS[@]}"; do
            local arch_lib="$BUILD_DIR/simulator-$arch/lib/$lib_name"
            if [[ -f "$arch_lib" ]]; then
                lipo_inputs="$lipo_inputs $arch_lib"
            fi
        done
        
        lipo -create $lipo_inputs -output "$merged_dir/lib/$lib_name"
    done
    
    log_success "Merged simulator libraries to: $merged_dir"
}

main() {
    log_info "Building for iOS Simulator"
    log_info "  Architectures: ${ARCHS[*]}"
    log_info "  Platform: $PLATFORM"
    log_info "  Min iOS: $IOS_MIN_VERSION"
    
    # Build each architecture
    for arch in "${ARCHS[@]}"; do
        build_arch "$arch"
    done
    
    # Merge architectures
    merge_architectures
}

main "$@"
