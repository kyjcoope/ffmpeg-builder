#!/bin/bash
# Create XCFrameworks from iOS device and simulator builds
#
# This script creates .xcframework bundles that work for both
# real devices and simulators (including Apple Silicon Macs)
# Called by build-ios.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common/utils.sh"
source "$(get_project_root)/config/ffmpeg-config.sh"

# Configuration
BUILD_DIR="$(get_build_dir)/ios"
OUTPUT_DIR="$(get_output_dir)/ios"
DEVICE_DIR="$BUILD_DIR/device"
SIMULATOR_DIR="$BUILD_DIR/simulator"

create_xcframework() {
    local lib_name="$1"
    local device_lib=""
    local simulator_lib=""
    
    # Find the library files (prefer .dylib, fall back to .a)
    for ext in dylib a; do
        if [[ -f "$DEVICE_DIR/lib/${lib_name}.${ext}" ]]; then
            device_lib="$DEVICE_DIR/lib/${lib_name}.${ext}"
            simulator_lib="$SIMULATOR_DIR/lib/${lib_name}.${ext}"
            break
        fi
    done
    
    if [[ -z "$device_lib" ]] || [[ ! -f "$device_lib" ]]; then
        log_warn "Library not found: $lib_name (skipping)"
        return
    fi
    
    if [[ ! -f "$simulator_lib" ]]; then
        log_warn "Simulator library not found: $lib_name (skipping)"
        return
    fi
    
    local output_path="$OUTPUT_DIR/${lib_name}.xcframework"
    
    log_info "Creating XCFramework: $lib_name"
    
    # Remove existing xcframework if it exists
    rm -rf "$output_path"
    
    # Create XCFramework
    xcodebuild -create-xcframework \
        -library "$device_lib" \
        -headers "$DEVICE_DIR/include" \
        -library "$simulator_lib" \
        -headers "$SIMULATOR_DIR/include" \
        -output "$output_path"
    
    log_success "  Created: $output_path"
}

main() {
    log_info "Creating XCFrameworks"
    log_info "  Device build: $DEVICE_DIR"
    log_info "  Simulator build: $SIMULATOR_DIR"
    log_info "  Output: $OUTPUT_DIR"
    
    # Verify builds exist
    if [[ ! -d "$DEVICE_DIR/lib" ]]; then
        die "Device build not found. Run build-device.sh first."
    fi
    
    if [[ ! -d "$SIMULATOR_DIR/lib" ]]; then
        die "Simulator build not found. Run build-simulator.sh first."
    fi
    
    # Create output directory
    mkdir -p "$OUTPUT_DIR"
    
    # Create XCFramework for each FFmpeg library
    for lib in "${FFMPEG_LIBS[@]}"; do
        create_xcframework "$lib"
    done
    
    log_success ""
    log_success "All XCFrameworks created successfully!"
    log_success "Output directory: $OUTPUT_DIR"
}

main "$@"
