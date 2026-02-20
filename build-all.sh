#!/bin/bash
# Build FFmpeg for all platforms
#
# Usage: ./build-all.sh [options]
#
# Options:
#   --ios-only      Build only iOS
#   --android-only  Build only Android
#   --macos-only    Build only macOS
#   --desktop-only  Build only desktop (Linux + Windows cross-compile)
#   --windows-only  Build only Windows (native with DXVA2/D3D11VA)
#   --mobile-only   Build only mobile (iOS + Android)
#   --macos         Also build macOS frameworks
#   --desktop       Also build desktop (Linux + Windows cross-compile)
#   --windows       Also build Windows native (requires MSYS2 on Windows)
#   --skip-download Skip FFmpeg download (use existing source)
#   --setup-ndk     Download and setup NDK if not found

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/scripts/common/utils.sh"

# Parse arguments
BUILD_IOS=true
BUILD_ANDROID=true
BUILD_MACOS=false    # macOS off by default, use --macos to enable
BUILD_DESKTOP=false  # Desktop off by default, use --desktop to enable
BUILD_WINDOWS=false  # Windows native off by default, use --windows to enable
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
        --macos-only)
            BUILD_IOS=false
            BUILD_ANDROID=false
            BUILD_MACOS=true
            BUILD_DESKTOP=false
            BUILD_WINDOWS=false
            ;;
        --macos)
            BUILD_MACOS=true
            ;;
        --desktop-only)
            BUILD_IOS=false
            BUILD_ANDROID=false
            BUILD_MACOS=false
            BUILD_DESKTOP=true
            BUILD_WINDOWS=false
            ;;
        --desktop)
            BUILD_DESKTOP=true
            ;;
        --windows-only)
            BUILD_IOS=false
            BUILD_ANDROID=false
            BUILD_MACOS=false
            BUILD_DESKTOP=false
            BUILD_WINDOWS=true
            ;;
        --windows)
            BUILD_WINDOWS=true
            ;;
        --mobile-only)
            BUILD_MACOS=false
            BUILD_DESKTOP=false
            BUILD_WINDOWS=false
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
            echo "  --macos-only    Build only macOS"
            echo "  --desktop-only  Build only desktop (Linux + Windows cross-compile)"
            echo "  --windows-only  Build only Windows native (DXVA2/D3D11VA)"
            echo "  --macos         Also build macOS frameworks"
            echo "  --desktop       Also build desktop (off by default)"
            echo "  --windows       Also build Windows native (off by default)"
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
    log_info "macOS: $BUILD_MACOS"
    log_info "Desktop: $BUILD_DESKTOP"
    log_info "Windows Native: $BUILD_WINDOWS"
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
    
    # Step 4: Build macOS
    if [[ "$BUILD_MACOS" == "true" ]]; then
        if is_macos; then
            log_info ""
            log_info ">>> Building macOS..."
            "$SCRIPT_DIR/scripts/macos/build-macos.sh"
        else
            log_warn "Skipping macOS build (requires macOS)"
        fi
    fi
    
    # Step 5: Build Android
    if [[ "$BUILD_ANDROID" == "true" ]]; then
        log_info ""
        log_info ">>> Building Android..."
        "$SCRIPT_DIR/scripts/android/build-android.sh"
    fi
    
    # Step 6: Build Desktop (Linux + Windows cross-compile)
    if [[ "$BUILD_DESKTOP" == "true" ]]; then
        log_info ""
        log_info ">>> Building Desktop..."
        "$SCRIPT_DIR/scripts/desktop/build-desktop.sh"
    fi
    
    # Step 7: Build Windows Native (DXVA2/D3D11VA)
    if [[ "$BUILD_WINDOWS" == "true" ]]; then
        log_info ""
        log_info ">>> Building Windows Native..."
        "$SCRIPT_DIR/scripts/windows/build-native.sh"
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
    if [[ "$BUILD_MACOS" == "true" ]] && is_macos; then
        log_info "macOS Frameworks: $(get_output_dir)/macos/"
    fi
    if [[ "$BUILD_DESKTOP" == "true" ]]; then
        log_info "Desktop Libraries: $(get_output_dir)/desktop/"
    fi
    if [[ "$BUILD_WINDOWS" == "true" ]]; then
        log_info "Windows Libraries: $(get_output_dir)/windows/"
    fi
}

main "$@"

