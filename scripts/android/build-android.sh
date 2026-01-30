#!/bin/bash
# Build FFmpeg for Android (all architectures)
#
# Usage: ./build-android.sh [--force] [--clean]
#
# Options:
#   --force  Rebuild even if output already exists
#   --clean  Clean build directories before building
#
# Environment variables:
#   ANDROID_NDK_HOME - Path to Android NDK (auto-detected)
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

# Parse arguments
FORCE_BUILD=false
CLEAN_BUILD=false
for arg in "$@"; do
    case $arg in
        --force) FORCE_BUILD=true ;;
        --clean) CLEAN_BUILD=true ;;
    esac
done

# Architectures to build
# arm64-v8a   - 64-bit ARM (modern phones, 99%+ of devices)
# armeabi-v7a - 32-bit ARM (older phones, ~5% of market)
# x86_64      - 64-bit x86 (emulators, Chromebooks)
ARCHS=("arm64-v8a" "armeabi-v7a" "x86_64")

# Check if architecture output already exists
arch_already_built() {
    local arch="$1"
    local lib_dir="$OUTPUT_DIR/$arch/lib"
    # Check if libavcodec exists (a good indicator of complete build)
    [[ -f "$lib_dir/libavcodec.so" ]] || [[ -f "$lib_dir/libavcodec.a" ]]
}

main() {
    log_info "=========================================="
    log_info "FFmpeg Android Build"
    log_info "=========================================="
    
    # Verify prerequisites
    require_android_ndk
    require_command make
    
    log_info "NDK: $ANDROID_NDK_HOME"
    log_info "Min SDK: $ANDROID_MIN_SDK"
    log_info "Architectures: ${ARCHS[*]}"
    log_info "Force rebuild: $FORCE_BUILD"
    log_info "=========================================="
    
    # Ensure FFmpeg source is available
    local ffmpeg_source
    ffmpeg_source="$(get_ffmpeg_source_dir)"
    if [[ ! -d "$ffmpeg_source" ]]; then
        die "FFmpeg source not found. Run: ./scripts/common/download-ffmpeg.sh"
    fi
    
    # Clean if requested
    if [[ "$CLEAN_BUILD" == "true" ]]; then
        clean_dir "$BUILD_DIR"
        clean_dir "$OUTPUT_DIR"
    else
        mkdir -p "$BUILD_DIR"
        mkdir -p "$OUTPUT_DIR"
    fi
    
    # Build each architecture
    local built_count=0
    local skipped_count=0
    
    for arch in "${ARCHS[@]}"; do
        if [[ "$FORCE_BUILD" == "false" ]] && arch_already_built "$arch"; then
            log_info ""
            log_info "=== Skipping $arch (already built) ==="
            ((skipped_count++))
        else
            log_info ""
            log_info "=== Building for $arch ==="
            "$SCRIPT_DIR/build-arch.sh" "$arch"
            ((built_count++))
        fi
    done
    
    log_success ""
    log_success "=========================================="
    log_success "Android build complete!"
    log_success "Built: $built_count, Skipped: $skipped_count"
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

