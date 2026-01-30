#!/bin/bash
# Build FFmpeg for a specific Android architecture
#
# Usage: ./build-arch.sh <arch>
# Example: ./build-arch.sh arm64-v8a
#
# Supports 16KB page alignment for Android 15+ devices

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common/utils.sh"
source "$(get_project_root)/config/ffmpeg-config.sh"

# Configuration
ANDROID_MIN_SDK="${ANDROID_MIN_SDK:-21}"
BUILD_DIR="$(get_build_dir)/android"
OUTPUT_DIR="$(get_output_dir)/android"
FFMPEG_SOURCE="$(get_ffmpeg_source_dir)"

# Get the architecture from argument
ARCH="${1:-}"
if [[ -z "$ARCH" ]]; then
    die "Usage: $0 <arch> (arm64-v8a, armeabi-v7a, x86_64, x86)"
fi

# Map Android ABI to FFmpeg/toolchain values
get_arch_config() {
    case "$ARCH" in
        arm64-v8a)
            FFMPEG_ARCH="aarch64"
            FFMPEG_CPU="armv8-a"
            TARGET="aarch64-linux-android"
            TOOLCHAIN_PREFIX="aarch64-linux-android"
            ;;
        armeabi-v7a)
            FFMPEG_ARCH="arm"
            FFMPEG_CPU="armv7-a"
            TARGET="armv7a-linux-androideabi"
            TOOLCHAIN_PREFIX="arm-linux-androideabi"
            ;;
        x86_64)
            FFMPEG_ARCH="x86_64"
            FFMPEG_CPU="x86-64"
            TARGET="x86_64-linux-android"
            TOOLCHAIN_PREFIX="x86_64-linux-android"
            ;;
        x86)
            FFMPEG_ARCH="x86"
            FFMPEG_CPU="i686"
            TARGET="i686-linux-android"
            TOOLCHAIN_PREFIX="i686-linux-android"
            ;;
        *)
            die "Unknown architecture: $ARCH"
            ;;
    esac
}

main() {
    get_arch_config
    
    log_info "Building FFmpeg for Android"
    log_info "  ABI: $ARCH"
    log_info "  FFmpeg Arch: $FFMPEG_ARCH"
    log_info "  Target: $TARGET"
    log_info "  Min SDK: $ANDROID_MIN_SDK"
    
    # Detect host platform
    local host_tag
    if is_macos; then
        host_tag="darwin-x86_64"
    else
        host_tag="linux-x86_64"
    fi
    
    # Set up toolchain paths
    local toolchain="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/$host_tag"
    local sysroot="$toolchain/sysroot"
    
    if [[ ! -d "$toolchain" ]]; then
        die "Toolchain not found: $toolchain"
    fi
    
    # Compiler and tools
    local cc="$toolchain/bin/${TARGET}${ANDROID_MIN_SDK}-clang"
    local cxx="$toolchain/bin/${TARGET}${ANDROID_MIN_SDK}-clang++"
    local ar="$toolchain/bin/llvm-ar"
    local nm="$toolchain/bin/llvm-nm"
    local ranlib="$toolchain/bin/llvm-ranlib"
    local strip="$toolchain/bin/llvm-strip"
    
    # Verify compiler exists
    if [[ ! -f "$cc" ]]; then
        die "Compiler not found: $cc"
    fi
    
    # Build directories
    local arch_build_dir="$BUILD_DIR/$ARCH"
    local arch_output_dir="$OUTPUT_DIR/$ARCH"
    
    mkdir -p "$arch_build_dir"
    mkdir -p "$arch_output_dir"
    
    cd "$FFMPEG_SOURCE"
    
    # Clean previous build
    make distclean 2>/dev/null || true
    
    # Extra C flags
    # -fPIC: Position independent code (required for shared libs)
    # -ffunction-sections -fdata-sections: Enable dead code elimination
    # -Wl,-z,max-page-size=16384: 16KB page alignment for Android 15+ support
    local extra_cflags="-fPIC -ffunction-sections -fdata-sections"
    local extra_ldflags="-Wl,--gc-sections -Wl,-z,max-page-size=16384"
    
    # Add NEON for ARM architectures
    if [[ "$ARCH" == "arm64-v8a" ]] || [[ "$ARCH" == "armeabi-v7a" ]]; then
        extra_cflags="$extra_cflags -mfpu=neon"
    fi
    
    log_info "Configuring FFmpeg..."
    ./configure \
        --prefix="$arch_output_dir" \
        --enable-cross-compile \
        --target-os=android \
        --arch="$FFMPEG_ARCH" \
        --cpu="$FFMPEG_CPU" \
        --cc="$cc" \
        --cxx="$cxx" \
        --ar="$ar" \
        --nm="$nm" \
        --ranlib="$ranlib" \
        --strip="$strip" \
        --sysroot="$sysroot" \
        --extra-cflags="$extra_cflags" \
        --extra-ldflags="$extra_ldflags" \
        --enable-neon \
        --enable-asm \
        $(get_ffmpeg_configure_flags)
    
    log_info "Building FFmpeg..."
    make -j"$(get_cpu_count)"
    
    log_info "Installing to $arch_output_dir..."
    make install
    
    log_success "Android $ARCH build complete"
    log_info "Output: $arch_output_dir"
}

main "$@"
