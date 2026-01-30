#!/bin/bash
# Build FFmpeg for iOS (device and simulator) and create XCFrameworks
#
# Usage: ./build-ios.sh
#
# Environment variables:
#   IOS_MIN_VERSION - Minimum iOS version (default: 13.0)
#   FFMPEG_VERSION  - FFmpeg version to build (optional)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common/utils.sh"
source "$(get_project_root)/config/ffmpeg-config.sh"

# Configuration
IOS_MIN_VERSION="${IOS_MIN_VERSION:-13.0}"
BUILD_DIR="$(get_build_dir)/ios"
OUTPUT_DIR="$(get_output_dir)/ios"

main() {
    log_info "=========================================="
    log_info "FFmpeg iOS Build"
    log_info "=========================================="
    log_info "iOS Min Version: $IOS_MIN_VERSION"
    log_info "Build Directory: $BUILD_DIR"
    log_info "Output Directory: $OUTPUT_DIR"
    log_info "=========================================="
    
    # Verify prerequisites
    require_xcode
    require_command make
    require_command lipo
    
    # Ensure FFmpeg source is available
    local ffmpeg_source
    ffmpeg_source="$(get_ffmpeg_source_dir)"
    if [[ ! -d "$ffmpeg_source" ]]; then
        die "FFmpeg source not found. Run: ./scripts/common/download-ffmpeg.sh"
    fi
    
    # Clean and create directories
    clean_dir "$BUILD_DIR"
    clean_dir "$OUTPUT_DIR"
    
    # Build for device (arm64)
    log_info ""
    log_info "=== Building for iOS Device (arm64) ==="
    "$SCRIPT_DIR/build-device.sh"
    
    # Build for simulator (arm64 + x86_64)
    log_info ""
    log_info "=== Building for iOS Simulator (arm64 + x86_64) ==="
    "$SCRIPT_DIR/build-simulator.sh"
    
    # Create XCFrameworks
    log_info ""
    log_info "=== Creating XCFrameworks ==="
    "$SCRIPT_DIR/create-xcframework.sh"
    
    log_success ""
    log_success "=========================================="
    log_success "iOS build complete!"
    log_success "XCFrameworks available at: $OUTPUT_DIR"
    log_success "=========================================="
    
    # List output
    ls -la "$OUTPUT_DIR"
}

main "$@"
