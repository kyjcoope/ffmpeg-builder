#!/bin/bash
# Common utility functions for build scripts

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Exit with error message
die() {
    log_error "$1"
    exit 1
}

# Check if a command exists
require_command() {
    local cmd="$1"
    if ! command -v "$cmd" &> /dev/null; then
        die "Required command '$cmd' not found. Please install it."
    fi
}

# Get the project root directory
get_project_root() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    echo "$(cd "$script_dir/../.." && pwd)"
}

# Get the FFmpeg source directory
get_ffmpeg_source_dir() {
    echo "$(get_project_root)/ffmpeg-source"
}

# Get the build directory
get_build_dir() {
    echo "$(get_project_root)/build"
}

# Get the output directory
get_output_dir() {
    echo "$(get_project_root)/output"
}

# Clean a directory (remove and recreate)
clean_dir() {
    local dir="$1"
    log_info "Cleaning directory: $dir"
    rm -rf "$dir"
    mkdir -p "$dir"
}

# Get number of CPU cores for parallel builds
get_cpu_count() {
    if [[ "$(uname)" == "Darwin" ]]; then
        sysctl -n hw.ncpu
    else
        nproc
    fi
}

# Check if running on macOS
is_macos() {
    [[ "$(uname)" == "Darwin" ]]
}

# Check if running on Linux
is_linux() {
    [[ "$(uname)" == "Linux" ]]
}

# Verify Xcode is available (macOS only)
require_xcode() {
    if ! is_macos; then
        die "Xcode is only available on macOS"
    fi
    
    if ! xcode-select -p &> /dev/null; then
        die "Xcode Command Line Tools not found. Run: xcode-select --install"
    fi
    
    log_info "Xcode path: $(xcode-select -p)"
}

# Auto-detect Android NDK if not set
find_android_ndk() {
    # Already set, use it
    if [[ -n "${ANDROID_NDK_HOME:-}" ]] && [[ -d "$ANDROID_NDK_HOME" ]]; then
        echo "$ANDROID_NDK_HOME"
        return
    fi
    
    # Common NDK locations to search
    local search_paths=(
        # macOS Android Studio
        "$HOME/Library/Android/sdk/ndk"
        # Linux Android Studio
        "$HOME/Android/Sdk/ndk"
        # ANDROID_HOME/ANDROID_SDK_ROOT
        "${ANDROID_HOME:-}/ndk"
        "${ANDROID_SDK_ROOT:-}/ndk"
    )
    
    for base_path in "${search_paths[@]}"; do
        if [[ -d "$base_path" ]]; then
            # Find the latest NDK version in this directory
            local latest
            latest=$(ls -1 "$base_path" 2>/dev/null | sort -V | tail -1)
            if [[ -n "$latest" ]] && [[ -d "$base_path/$latest" ]]; then
                echo "$base_path/$latest"
                return
            fi
        fi
    done
    
    # Not found
    echo ""
}

# Verify Android NDK is available (auto-detects if not set)
require_android_ndk() {
    # Try to auto-detect if not set
    if [[ -z "${ANDROID_NDK_HOME:-}" ]]; then
        local detected
        detected=$(find_android_ndk)
        if [[ -n "$detected" ]]; then
            export ANDROID_NDK_HOME="$detected"
            log_info "Auto-detected NDK: $ANDROID_NDK_HOME"
        else
            die "ANDROID_NDK_HOME is not set and could not auto-detect NDK. Please set it manually."
        fi
    fi
    
    if [[ ! -d "$ANDROID_NDK_HOME" ]]; then
        die "ANDROID_NDK_HOME directory does not exist: $ANDROID_NDK_HOME"
    fi
    
    local ndk_version_file="$ANDROID_NDK_HOME/source.properties"
    if [[ -f "$ndk_version_file" ]]; then
        local version
        version=$(grep "Pkg.Revision" "$ndk_version_file" | cut -d= -f2 | tr -d ' ')
        log_info "Android NDK version: $version"
    fi
}
