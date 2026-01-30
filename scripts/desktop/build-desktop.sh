#!/bin/bash
# Build FFmpeg for Desktop platforms (Linux, macOS, Windows)
#
# Usage: ./build-desktop.sh [--force] [--clean] [platform]
#
# Platforms:
#   linux   - Linux (x86_64)
#   macos   - macOS (arm64 + x86_64 universal)
#   windows - Windows via cross-compile (requires mingw-w64)
#   all     - Build all platforms (default)
#
# Options:
#   --force  Rebuild even if output already exists
#   --clean  Clean build directories before building

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
PLATFORM="current"

for arg in "$@"; do
    case $arg in
        --force) FORCE_BUILD=true ;;
        --clean) CLEAN_BUILD=true ;;
        linux|macos|windows|all) PLATFORM="$arg" ;;
    esac
done

# Detect current platform if not specified
if [[ "$PLATFORM" == "current" ]]; then
    if is_macos; then
        PLATFORM="macos"
    elif is_linux; then
        PLATFORM="linux"
    else
        die "Unknown platform. Please specify: linux, macos, or windows"
    fi
fi

# Check if platform output already exists
platform_already_built() {
    local platform="$1"
    local lib_dir="$OUTPUT_DIR/$platform/lib"
    [[ -f "$lib_dir/libavcodec.so" ]] || [[ -f "$lib_dir/libavcodec.dylib" ]] || [[ -f "$lib_dir/avcodec.dll" ]] || [[ -f "$lib_dir/libavcodec.a" ]]
}

build_linux() {
    log_info "Building FFmpeg for Linux (x86_64)"
    
    local platform_output="$OUTPUT_DIR/linux"
    mkdir -p "$platform_output"
    
    cd "$(get_ffmpeg_source_dir)"
    make distclean 2>/dev/null || true
    
    ./configure \
        --prefix="$platform_output" \
        --enable-pic \
        $(get_ffmpeg_configure_flags)
    
    make -j"$(get_cpu_count)"
    make install
    
    log_success "Linux build complete: $platform_output"
}

build_macos() {
    log_info "Building FFmpeg for macOS (arm64 + x86_64)"
    
    require_xcode
    
    local platform_output="$OUTPUT_DIR/macos"
    local arm64_dir="$BUILD_DIR/macos-arm64"
    local x86_64_dir="$BUILD_DIR/macos-x86_64"
    
    mkdir -p "$platform_output/lib"
    mkdir -p "$arm64_dir"
    mkdir -p "$x86_64_dir"
    
    cd "$(get_ffmpeg_source_dir)"
    
    # Build arm64
    log_info "Building for arm64..."
    make distclean 2>/dev/null || true
    ./configure \
        --prefix="$arm64_dir" \
        --arch=arm64 \
        --enable-cross-compile \
        --target-os=darwin \
        --extra-cflags="-arch arm64" \
        --extra-ldflags="-arch arm64" \
        $(get_ffmpeg_configure_flags)
    make -j"$(get_cpu_count)"
    make install
    
    # Build x86_64
    log_info "Building for x86_64..."
    make distclean 2>/dev/null || true
    ./configure \
        --prefix="$x86_64_dir" \
        --arch=x86_64 \
        --enable-cross-compile \
        --target-os=darwin \
        --extra-cflags="-arch x86_64" \
        --extra-ldflags="-arch x86_64" \
        $(get_ffmpeg_configure_flags)
    make -j"$(get_cpu_count)"
    make install
    
    # Create universal binaries
    log_info "Creating universal binaries..."
    cp -R "$arm64_dir/include" "$platform_output/"
    
    for lib in "$arm64_dir/lib/"*.dylib; do
        if [[ -f "$lib" ]]; then
            local libname=$(basename "$lib")
            local x86_lib="$x86_64_dir/lib/$libname"
            if [[ -f "$x86_lib" ]]; then
                lipo -create "$lib" "$x86_lib" -output "$platform_output/lib/$libname"
                log_info "  Created universal: $libname"
            fi
        fi
    done
    
    log_success "macOS build complete: $platform_output"
}

build_windows() {
    log_info "Building FFmpeg for Windows (cross-compile with mingw-w64)"
    
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
        $(get_ffmpeg_configure_flags)
    
    make -j"$(get_cpu_count)"
    make install
    
    log_success "Windows build complete: $platform_output"
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
        all)
            if is_macos; then
                platforms=("macos" "linux" "windows")
            else
                platforms=("linux" "windows")
            fi
            ;;
        *)
            platforms=("$PLATFORM")
            ;;
    esac
    
    for platform in "${platforms[@]}"; do
        if [[ "$FORCE_BUILD" == "false" ]] && platform_already_built "$platform"; then
            log_info "=== Skipping $platform (already built) ==="
        else
            log_info ""
            log_info "=== Building for $platform ==="
            case "$platform" in
                linux) build_linux ;;
                macos) build_macos ;;
                windows) build_windows ;;
            esac
        fi
    done
    
    log_success ""
    log_success "Desktop build complete!"
    log_success "Output: $OUTPUT_DIR"
}

main "$@"
