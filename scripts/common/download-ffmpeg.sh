#!/bin/bash
# Download FFmpeg source code
#
# Usage: ./download-ffmpeg.sh [version]
# Example: ./download-ffmpeg.sh n7.1

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"
source "$(get_project_root)/config/ffmpeg-config.sh"

FFMPEG_REPO="https://git.ffmpeg.org/ffmpeg.git"
FFMPEG_SOURCE_DIR="$(get_ffmpeg_source_dir)"

# Get version from argument, env var, or config default
VERSION="${1:-$FFMPEG_VERSION}"

main() {
    log_info "FFmpeg Source Downloader"
    log_info "========================"
    
    require_command git
    
    if [[ -d "$FFMPEG_SOURCE_DIR/.git" ]]; then
        log_info "FFmpeg source already exists, updating..."
        cd "$FFMPEG_SOURCE_DIR"
        git fetch --tags
    else
        log_info "Cloning FFmpeg repository..."
        git clone "$FFMPEG_REPO" "$FFMPEG_SOURCE_DIR"
        cd "$FFMPEG_SOURCE_DIR"
    fi
    
    # Determine version to checkout
    if [[ -z "$VERSION" ]]; then
        log_info "No version specified, finding latest release..."
        # Get latest release tag (format: n7.1, n7.0.2, etc.)
        VERSION=$(git tag -l 'n[0-9]*' | sort -V | tail -1)
        if [[ -z "$VERSION" ]]; then
            die "Could not find any release tags"
        fi
    fi
    
    log_info "Checking out version: $VERSION"
    git checkout "$VERSION"
    
    # Verify and display version info
    if [[ -f "RELEASE" ]]; then
        log_success "FFmpeg version: $(cat RELEASE)"
    else
        log_success "FFmpeg version: $VERSION"
    fi
    
    log_success "FFmpeg source ready at: $FFMPEG_SOURCE_DIR"
}

main "$@"
