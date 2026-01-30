#!/bin/bash
# Download and setup Android NDK
#
# Usage: ./setup-ndk.sh [version]
# Example: ./setup-ndk.sh 28.0.13676358
#
# This will download the NDK to the project's 'ndk' directory

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

# Default NDK version (r28)
DEFAULT_NDK_VERSION="28.0.13676358"
NDK_VERSION="${1:-$DEFAULT_NDK_VERSION}"

# Where to install
PROJECT_ROOT="$(get_project_root)"
NDK_DIR="$PROJECT_ROOT/ndk"

main() {
    log_info "=========================================="
    log_info "Android NDK Setup"
    log_info "=========================================="
    log_info "NDK Version: $NDK_VERSION"
    log_info "Install Path: $NDK_DIR"
    log_info "=========================================="
    
    require_command curl
    require_command unzip
    
    # Detect platform
    local platform
    local ext="zip"
    if is_macos; then
        platform="darwin"
    else
        platform="linux"
    fi
    
    local ndk_zip="android-ndk-r${NDK_VERSION%.*.*}-$platform.zip"
    local download_url="https://dl.google.com/android/repository/android-ndk-r${NDK_VERSION%.*.*}-$platform.zip"
    
    # For version like 28.0.13676358, we need r28b format
    # Let's use the direct package name format instead
    local major_version="${NDK_VERSION%%.*}"
    local ndk_package="android-ndk-r${major_version}"
    download_url="https://dl.google.com/android/repository/${ndk_package}-${platform}.zip"
    
    log_info "Download URL: $download_url"
    
    # Create temp directory
    local temp_dir
    temp_dir=$(mktemp -d)
    local zip_path="$temp_dir/ndk.zip"
    
    # Download
    log_info "Downloading NDK (this may take a while)..."
    curl -L -o "$zip_path" "$download_url" || die "Failed to download NDK"
    
    # Extract
    log_info "Extracting NDK..."
    mkdir -p "$NDK_DIR"
    unzip -q "$zip_path" -d "$temp_dir"
    
    # Move to final location
    local extracted_dir
    extracted_dir=$(ls -d "$temp_dir"/android-ndk-* 2>/dev/null | head -1)
    if [[ -z "$extracted_dir" ]]; then
        die "Could not find extracted NDK directory"
    fi
    
    # Remove existing and move new
    rm -rf "$NDK_DIR/$NDK_VERSION"
    mv "$extracted_dir" "$NDK_DIR/$NDK_VERSION"
    
    # Cleanup
    rm -rf "$temp_dir"
    
    # Set environment variable
    export ANDROID_NDK_HOME="$NDK_DIR/$NDK_VERSION"
    
    log_success ""
    log_success "=========================================="
    log_success "NDK installed successfully!"
    log_success "=========================================="
    log_info "Path: $ANDROID_NDK_HOME"
    log_info ""
    log_info "To use, run:"
    log_info "  export ANDROID_NDK_HOME=\"$ANDROID_NDK_HOME\""
    log_info "  ./scripts/android/build-android.sh"
    log_info ""
    log_info "Or add to your shell profile (~/.zshrc or ~/.bashrc):"
    log_info "  export ANDROID_NDK_HOME=\"$ANDROID_NDK_HOME\""
}

main "$@"
