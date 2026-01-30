#!/bin/bash
# Build FFmpeg for all platforms
#
# Usage: ./build-all.sh [options]
#
# Options:
#   --ios-only      Build only iOS
#   --android-only  Build only Android
#   --desktop-only  Build only desktop (current platform)
#   --mobile-only   Build only mobile (iOS + Android)
#   --skip-download Skip FFmpeg download (use existing source)
#   --setup-ndk     Download and setup NDK if not found

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/scripts/common/utils.sh"

# Parse arguments
BUILD_IOS=true
BUILD_ANDROID=true
BUILD_DESKTOP=false  # Desktop off by default, use --desktop to enable
SKIP_DOWNLOAD=false
SETUP_NDK=false

for arg in "$@"; do
    case $arg in
        --ios-only)
            BUILD_ANDROID=false
            BUILD_DESKTOP=false
            ;;
        --android-only)
            BUILD_IOS=false
            BUILD_DESKTOP=false
            ;;
        --desktop-only)
            BUILD_IOS=false
            BUILD_ANDROID=false
            BUILD_DESKTOP=true
            ;;
        --desktop)
            BUILD_DESKTOP=true
            ;;
        --mobile-only)
            BUILD_DESKTOP=false
            ;;
        --skip-download)
            SKIP_DOWNLOAD=true
            ;;
        --setup-ndk)
            SETUP_NDK=true
            ;;
        --help)
            echo "Usage: ./build-all.sh [options]"
            echo ""
            echo "Options:"
            echo "  --ios-only      Build only iOS"
            echo "  --android-only  Build only Android"
            echo "  --desktop-only  Build only desktop (current platform)"
            echo "  --desktop       Also build desktop (off by default)"
            echo "  --mobile-only   Build only mobile (iOS + Android)"
            echo "  --skip-download Skip FFmpeg download (use existing source)"
            echo "  --setup-ndk     Download and setup NDK if not found"
            exit 0
            ;;
    esac
done

main() {
    log_info "=========================================="
    log_info "FFmpeg Multi-Platform Build"
    log_info "=========================================="
    log_info "iOS: $BUILD_IOS"
    log_info "Android: $BUILD_ANDROID"
    log_info "Desktop: $BUILD_DESKTOP"
    log_info "=========================================="
    
    # Step 1: Download FFmpeg source
    if [[ "$SKIP_DOWNLOAD" == "false" ]]; then
        log_info ""
        log_info ">>> Step 1: Downloading FFmpeg source..."
        "$SCRIPT_DIR/scripts/common/download-ffmpeg.sh"
    else
        log_info ""
        log_info ">>> Step 1: Skipping FFmpeg download (--skip-download)"
    fi
    
    # Step 2: Setup NDK if requested
    if [[ "$SETUP_NDK" == "true" ]] && [[ "$BUILD_ANDROID" == "true" ]]; then
        log_info ""
        log_info ">>> Step 2: Setting up Android NDK..."
        "$SCRIPT_DIR/scripts/common/setup-ndk.sh"
        # Source the NDK path
        export ANDROID_NDK_HOME="$(get_project_root)/ndk/$(ls "$(get_project_root)/ndk" | head -1)"
    fi
    
    # Step 3: Build iOS
    if [[ "$BUILD_IOS" == "true" ]]; then
        if is_macos; then
            log_info ""
            log_info ">>> Building iOS..."
            "$SCRIPT_DIR/scripts/ios/build-ios.sh"
        else
            log_warn "Skipping iOS build (requires macOS)"
        fi
    fi
    
    # Step 4: Build Android
    if [[ "$BUILD_ANDROID" == "true" ]]; then
        log_info ""
        log_info ">>> Building Android..."
        "$SCRIPT_DIR/scripts/android/build-android.sh"
    fi
    
    # Step 5: Build Desktop
    if [[ "$BUILD_DESKTOP" == "true" ]]; then
        log_info ""
        log_info ">>> Building Desktop..."
        "$SCRIPT_DIR/scripts/desktop/build-desktop.sh"
    fi
    
    # Summary
    log_success ""
    log_success "=========================================="
    log_success "Build Complete!"
    log_success "=========================================="
    
    if [[ "$BUILD_IOS" == "true" ]] && is_macos; then
        log_info "iOS XCFrameworks: $(get_output_dir)/ios/"
    fi
    if [[ "$BUILD_ANDROID" == "true" ]]; then
        log_info "Android Libraries: $(get_output_dir)/android/"
    fi
    if [[ "$BUILD_DESKTOP" == "true" ]]; then
        log_info "Desktop Libraries: $(get_output_dir)/desktop/"
    fi
}

main "$@"

