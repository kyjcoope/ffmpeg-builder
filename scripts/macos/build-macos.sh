#!/bin/bash
# Build FFmpeg for macOS (arm64 + x86_64 universal) and create frameworks
#
# Usage: ./build-macos.sh
#
# Environment variables:
#   MACOS_MIN_VERSION - Minimum macOS version (default: 11.0)
#   FFMPEG_VERSION    - FFmpeg version to build (optional)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common/utils.sh"
source "$(get_project_root)/config/ffmpeg-config.sh"

# Configuration
MACOS_MIN_VERSION="${MACOS_MIN_VERSION:-11.0}"
BUILD_DIR="$(get_build_dir)/macos"
OUTPUT_DIR="$(get_output_dir)/macos"

# Architectures to build
ARCHS=("arm64" "x86_64")

main() {
    log_info "=========================================="
    log_info "FFmpeg macOS Build"
    log_info "=========================================="
    log_info "macOS Min Version: $MACOS_MIN_VERSION"
    log_info "Architectures: ${ARCHS[*]}"
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
    
    # Build each architecture
    for arch in "${ARCHS[@]}"; do
        log_info ""
        log_info "=== Building for macOS ($arch) ==="
        "$SCRIPT_DIR/build-arch.sh" "$arch"
    done
    
    # Create universal frameworks
    log_info ""
    log_info "=== Creating Universal Frameworks ==="
    "$SCRIPT_DIR/create-framework.sh"
    
    log_success ""
    log_success "=========================================="
    log_success "macOS build complete!"
    log_success "Frameworks available at: $OUTPUT_DIR"
    log_success "=========================================="
    
    # List output
    ls -la "$OUTPUT_DIR"
}

main "$@"
