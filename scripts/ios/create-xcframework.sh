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
FRAMEWORKS_DIR="$BUILD_DIR/frameworks"

# Create a .framework bundle from a dynamic library
create_framework_bundle() {
    local lib_name="$1"
    local source_dir="$2"
    local platform="$3"  # "device" or "simulator"
    local framework_dir="$FRAMEWORKS_DIR/$platform/${lib_name}.framework"
    
    # Find the dylib
    local dylib_path="$source_dir/lib/${lib_name}.dylib"
    if [[ ! -f "$dylib_path" ]]; then
        log_warn "Dylib not found: $dylib_path"
        return 1
    fi
    
    log_info "  Creating framework bundle: ${lib_name}.framework ($platform)"
    
    # Create framework structure
    rm -rf "$framework_dir"
    mkdir -p "$framework_dir/Headers"
    
    # Copy dylib and rename to framework name (without lib prefix and extension)
    local framework_name="${lib_name#lib}"  # Remove 'lib' prefix
    cp "$dylib_path" "$framework_dir/$framework_name"
    
    # Fix install name to use @rpath
    install_name_tool -id "@rpath/${lib_name}.framework/$framework_name" "$framework_dir/$framework_name"
    
    # Copy headers
    if [[ -d "$source_dir/include/$lib_name" ]]; then
        cp -R "$source_dir/include/$lib_name/"* "$framework_dir/Headers/"
    elif [[ -d "$source_dir/include" ]]; then
        # Copy all headers if lib-specific dir doesn't exist
        cp -R "$source_dir/include/"* "$framework_dir/Headers/" 2>/dev/null || true
    fi
    
    # Create Info.plist
    local bundle_id="org.ffmpeg.${framework_name}"
    cat > "$framework_dir/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>${framework_name}</string>
    <key>CFBundleIdentifier</key>
    <string>${bundle_id}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${framework_name}</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>MinimumOSVersion</key>
    <string>13.0</string>
</dict>
</plist>
EOF
    
    return 0
}

create_xcframework() {
    local lib_name="$1"
    local framework_name="${lib_name#lib}"
    
    local device_framework="$FRAMEWORKS_DIR/device/${lib_name}.framework"
    local simulator_framework="$FRAMEWORKS_DIR/simulator/${lib_name}.framework"
    
    if [[ ! -d "$device_framework" ]] || [[ ! -d "$simulator_framework" ]]; then
        log_warn "Framework bundles not found for: $lib_name (skipping)"
        return
    fi
    
    local output_path="$OUTPUT_DIR/${lib_name}.xcframework"
    
    log_info "Creating XCFramework: $lib_name"
    
    # Remove existing xcframework
    rm -rf "$output_path"
    
    # Create XCFramework from framework bundles
    xcodebuild -create-xcframework \
        -framework "$device_framework" \
        -framework "$simulator_framework" \
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
    
    # Create directories
    mkdir -p "$OUTPUT_DIR"
    mkdir -p "$FRAMEWORKS_DIR/device"
    mkdir -p "$FRAMEWORKS_DIR/simulator"
    
    # Step 1: Create framework bundles for each library
    log_info "Creating framework bundles..."
    for lib in "${FFMPEG_LIBS[@]}"; do
        create_framework_bundle "$lib" "$DEVICE_DIR" "device" || true
        create_framework_bundle "$lib" "$SIMULATOR_DIR" "simulator" || true
    done
    
    # Step 2: Create XCFrameworks from framework bundles
    log_info ""
    log_info "Creating XCFrameworks from framework bundles..."
    for lib in "${FFMPEG_LIBS[@]}"; do
        create_xcframework "$lib"
    done
    
    log_success ""
    log_success "All XCFrameworks created successfully!"
    log_success "Output directory: $OUTPUT_DIR"
}

main "$@"
