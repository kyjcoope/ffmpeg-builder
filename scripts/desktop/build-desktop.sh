#!/bin/bash
# Build FFmpeg for Desktop platforms (Linux, Windows cross-compile)
#
# Usage: ./build-desktop.sh [--force] [--clean] [platform]
#
# Platforms:
#   linux   - Linux (x86_64) with VAAPI hardware acceleration
#   windows - Windows via cross-compile (requires mingw-w64, software-only)
#   all     - Build all desktop platforms (default)
#
# Options:
#   --force  Rebuild even if output already exists
#   --clean  Clean build directories before building
#
# NOTE: For macOS, use scripts/macos/build-macos.sh (with VideoToolbox + AudioToolbox)
# NOTE: For Windows native build with DXVA2/D3D11VA, use scripts/windows/build-windows-native.ps1

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common/utils.sh"
source "$(get_project_root)/config/ffmpeg-config.sh"

# Configuration
BUILD_DIR="$(get_build_dir)/desktop"
OUTPUT_DIR="$(get_output_dir)/desktop"

# Parse arguments
FORCE_BUILD=false
CLEAN_BUILD=false
PLATFORM="all"

for arg in "$@"; do
    case $arg in
        --force) FORCE_BUILD=true ;;
        --clean) CLEAN_BUILD=true ;;
        linux|windows|all) PLATFORM="$arg" ;;
    esac
done

# Check if platform output already exists
platform_already_built() {
    local platform="$1"
    local lib_dir="$OUTPUT_DIR/$platform/lib"
    case "$platform" in
        linux)   [[ -f "$lib_dir/libavcodec.so" ]] ;;
        windows) [[ -f "$lib_dir/avcodec.dll" ]] || [[ -f "$lib_dir/libavcodec.dll.a" ]] ;;
        *)       false ;;
    esac
}

build_linux() {
    log_info "Building FFmpeg for Linux (x86_64)"
    log_info "Hardware acceleration: VAAPI"

    local platform_output="$OUTPUT_DIR/linux"
    mkdir -p "$platform_output"

    cd "$(get_ffmpeg_source_dir)"
    make distclean 2>/dev/null || true

    ./configure \
        --prefix="$platform_output" \
        --enable-pic \
        $(get_ffmpeg_configure_flags "linux")

    make -j"$(get_cpu_count)"
    make install

    log_success "Linux build complete: $platform_output"
}

build_windows() {
    log_info "Building FFmpeg for Windows (cross-compile with mingw-w64)"
    log_info "Hardware acceleration: None (software-only)"
    log_info "TIP: For DXVA2/D3D11VA hardware accel, use scripts/windows/build-windows-native.ps1"

    require_command x86_64-w64-mingw32-gcc

    local platform_output="$OUTPUT_DIR/windows"
    mkdir -p "$platform_output"

    cd "$(get_ffmpeg_source_dir)"
    make distclean 2>/dev/null || true

    ./configure \
        --prefix="$platform_output" \
        --arch=x86_64 \
        --target-os=mingw32 \
        --cross-prefix=x86_64-w64-mingw32- \
        --enable-cross-compile \
        $(get_ffmpeg_configure_flags "windows-cross")

    make -j"$(get_cpu_count)"
    make install

    log_success "Windows cross-compile build complete: $platform_output"
}

main() {
    log_info "=========================================="
    log_info "FFmpeg Desktop Build"
    log_info "=========================================="
    log_info "Platform: $PLATFORM"
    log_info "FFmpeg version: $FFMPEG_VERSION"
    log_info "Force rebuild: $FORCE_BUILD"
    log_info "=========================================="

    require_command make

    # Ensure FFmpeg source is available
    if [[ ! -d "$(get_ffmpeg_source_dir)" ]]; then
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

    # Build requested platforms
    local platforms=()
    case "$PLATFORM" in
        all)     platforms=("linux" "windows") ;;
        *)       platforms=("$PLATFORM") ;;
    esac

    for platform in "${platforms[@]}"; do
        if [[ "$FORCE_BUILD" == "false" ]] && platform_already_built "$platform"; then
            log_info "=== Skipping $platform (already built) ==="
        else
            log_info ""
            log_info "=== Building for $platform ==="
            case "$platform" in
                linux) build_linux ;;
                windows) build_windows ;;
            esac
        fi
    done

    log_success ""
    log_success "Desktop build complete!"
    log_success "Output: $OUTPUT_DIR"
}

main "$@"
