#!/bin/bash
# Build FFmpeg for Android (all architectures)
#
# Usage: ./build-android.sh
#
# Environment variables:
#   ANDROID_NDK_HOME - Path to Android NDK (required)
#   ANDROID_MIN_SDK  - Minimum SDK version (default: 21)
#   FFMPEG_VERSION   - FFmpeg version to build (optional)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common/utils.sh"
source "$(get_project_root)/config/ffmpeg-config.sh"

# Configuration
ANDROID_MIN_SDK="${ANDROID_MIN_SDK:-21}"
BUILD_DIR="$(get_build_dir)/android"
OUTPUT_DIR="$(get_output_dir)/android"

# Architectures to build
# arm64-v8a  - 64-bit ARM (modern phones)
# armeabi-v7a - 32-bit ARM (older phones)
# x86_64     - 64-bit x86 (emulators, Chromebooks)
# x86        - 32-bit x86 (old emulators)
ARCHS=("arm64-v8a" "armeabi-v7a" "x86_64" "x86")

main() {
    log_info "=========================================="
    log_info "FFmpeg Android Build"
    log_info "=========================================="
    log_info "NDK: $ANDROID_NDK_HOME"
    log_info "Min SDK: $ANDROID_MIN_SDK"
    log_info "Architectures: ${ARCHS[*]}"
    log_info "Build Directory: $BUILD_DIR"
    log_info "Output Directory: $OUTPUT_DIR"
    log_info "=========================================="
    
    # Verify prerequisites
    require_android_ndk
    require_command make
    
    # Ensure FFmpeg source is available
    local ffmpeg_source
    ffmpeg_source="$(get_ffmpeg_source_dir)"
    if [[ ! -d "$ffmpeg_source" ]]; then
        die "FFmpeg source not found. Run: ./scripts/common/download-ffmpeg.sh"
    fi
    
    # Clean and create directories
    clean_dir "$BUILD_DIR"
    clean_dir "$OUTPUT_DIR"
    
    # Build each architecture
    for arch in "${ARCHS[@]}"; do
        log_info ""
        log_info "=== Building for $arch ==="
        "$SCRIPT_DIR/build-arch.sh" "$arch"
    done
    
    log_success ""
    log_success "=========================================="
    log_success "Android build complete!"
    log_success "Libraries available at: $OUTPUT_DIR"
    log_success "=========================================="
    
    # List output
    for arch in "${ARCHS[@]}"; do
        log_info ""
        log_info "$arch:"
        ls -la "$OUTPUT_DIR/$arch/lib/" 2>/dev/null || log_warn "  No output for $arch"
    done
}

main "$@"
