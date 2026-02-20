#!/bin/bash
# Build FFmpeg natively on Windows inside MSYS2/MINGW64
#
# This script is meant to run inside MSYS2 with MINGW64 environment.
# Use build-windows-native.ps1 to invoke this from PowerShell, or
# run directly from an MSYS2 MINGW64 shell.
#
# Usage: ./build-native.sh [--force] [--clean]
#
# Output: output/windows/ (DLLs + headers with DXVA2/D3D11VA)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common/utils.sh"
source "$(get_project_root)/config/ffmpeg-config.sh"

# Configuration
BUILD_DIR="$(get_build_dir)/windows-native"
OUTPUT_DIR="$(get_output_dir)/windows"

# Parse arguments
FORCE_BUILD=false
CLEAN_BUILD=false

for arg in "$@"; do
    case $arg in
        --force) FORCE_BUILD=true ;;
        --clean) CLEAN_BUILD=true ;;
    esac
done

# Check if already built
already_built() {
    [[ -f "$OUTPUT_DIR/bin/avcodec.dll" ]] || [[ -f "$OUTPUT_DIR/bin/avcodec-*.dll" ]]
}

verify_msys2() {
    # Verify we're in MINGW64 environment
    if [[ "${MSYSTEM:-}" != "MINGW64" ]]; then
        log_warn "Not in MINGW64 environment (MSYSTEM=${MSYSTEM:-unset})"
        log_warn "For best results, run from MSYS2 MINGW64 shell or use build-windows-native.ps1"
    fi

    # Check for required tools
    require_command gcc
    require_command make
    require_command yasm
    require_command nasm
}

build_x86_64() {
    log_info "Building FFmpeg for Windows x86_64 (native)"
    log_info "Hardware acceleration: DXVA2 + D3D11VA"

    local ffmpeg_source
    ffmpeg_source="$(get_ffmpeg_source_dir)"

    cd "$ffmpeg_source"
    make distclean 2>/dev/null || true

    ./configure \
        --prefix="$OUTPUT_DIR" \
        --arch=x86_64 \
        --target-os=mingw32 \
        --enable-pic \
        $(get_ffmpeg_configure_flags "windows-native")

    make -j"$(get_cpu_count)"
    make install

    log_success "Windows x86_64 build complete"
}

main() {
    log_info "=========================================="
    log_info "FFmpeg Native Windows Build"
    log_info "=========================================="
    log_info "Architecture: x86_64"
    log_info "FFmpeg version: $FFMPEG_VERSION"
    log_info "Hardware accel: DXVA2 + D3D11VA"
    log_info "Output: $OUTPUT_DIR"
    log_info "Force rebuild: $FORCE_BUILD"
    log_info "=========================================="

    # Verify environment
    verify_msys2

    # Check if already built
    if [[ "$FORCE_BUILD" == "false" ]] && already_built; then
        log_info "Windows build already exists. Use --force to rebuild."
        return 0
    fi

    # Ensure FFmpeg source is available
    if [[ ! -d "$(get_ffmpeg_source_dir)" ]]; then
        log_info "FFmpeg source not found. Downloading..."
        "$SCRIPT_DIR/../common/download-ffmpeg.sh"
    fi

    # Clean if requested
    if [[ "$CLEAN_BUILD" == "true" ]]; then
        clean_dir "$BUILD_DIR"
        clean_dir "$OUTPUT_DIR"
    else
        mkdir -p "$BUILD_DIR"
        mkdir -p "$OUTPUT_DIR"
    fi

    # Build
    build_x86_64

    log_success ""
    log_success "=========================================="
    log_success "Windows native build complete!"
    log_success "Output: $OUTPUT_DIR"
    log_success "=========================================="

    # List output
    if [[ -d "$OUTPUT_DIR/bin" ]]; then
        log_info "Built DLLs:"
        ls -la "$OUTPUT_DIR/bin/"*.dll 2>/dev/null || true
    fi
}

main "$@"
