#!/bin/bash
# Create universal macOS frameworks from per-architecture builds
#
# This script merges arm64 and x86_64 builds into universal dylibs
# and packages them as .framework bundles for macOS distribution.
# Called by build-macos.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common/utils.sh"
source "$(get_project_root)/config/ffmpeg-config.sh"

# Configuration
MACOS_MIN_VERSION="${MACOS_MIN_VERSION:-11.0}"
BUILD_DIR="$(get_build_dir)/macos"
OUTPUT_DIR="$(get_output_dir)/macos"
ARM64_DIR="$BUILD_DIR/arm64"
X86_64_DIR="$BUILD_DIR/x86_64"

# Architectures to merge
ARCHS=("arm64" "x86_64")

# Create a universal binary from per-arch slices and package as .framework
create_framework() {
    local lib_name="$1"
    local framework_dir="$OUTPUT_DIR/${lib_name}.framework"
    
    # Find the dylib in the first available arch
    local dylib_name=""
    for arch in "${ARCHS[@]}"; do
        local arch_lib_dir="$BUILD_DIR/$arch/lib"
        # Look for versioned dylib (e.g., libavcodec.60.dylib) or unversioned
        local found
        found=$(ls "$arch_lib_dir/${lib_name}"*.dylib 2>/dev/null | grep -v '\.dylib$' | head -1 || true)
        if [[ -z "$found" ]]; then
            found=$(ls "$arch_lib_dir/${lib_name}.dylib" 2>/dev/null | head -1 || true)
        fi
        if [[ -n "$found" ]]; then
            dylib_name=$(basename "$found")
            break
        fi
    done
    
    if [[ -z "$dylib_name" ]]; then
        log_warn "No dylib found for $lib_name (skipping)"
        return 1
    fi
    
    log_info "Creating framework: ${lib_name}.framework"
    log_info "  Source dylib: $dylib_name"
    
    # Create framework structure
    rm -rf "$framework_dir"
    mkdir -p "$framework_dir/Versions/A/Headers"
    mkdir -p "$framework_dir/Versions/A/Resources"
    
    # Merge architectures with lipo
    local lipo_inputs=""
    for arch in "${ARCHS[@]}"; do
        local arch_lib="$BUILD_DIR/$arch/lib/$dylib_name"
        if [[ -f "$arch_lib" ]]; then
            lipo_inputs="$lipo_inputs $arch_lib"
            log_info "  Adding $arch slice"
        else
            log_warn "  Missing $arch slice: $arch_lib"
        fi
    done
    
    if [[ -z "$lipo_inputs" ]]; then
        log_warn "No architecture slices found for $lib_name (skipping)"
        return 1
    fi
    
    # Create universal binary in Versions/A
    lipo -create $lipo_inputs -output "$framework_dir/Versions/A/$lib_name"
    
    # Fix install name to use @rpath
    install_name_tool -id "@rpath/${lib_name}.framework/Versions/A/$lib_name" \
        "$framework_dir/Versions/A/$lib_name"
    
    # Copy headers
    if [[ -d "$ARM64_DIR/include/$lib_name" ]]; then
        cp -R "$ARM64_DIR/include/$lib_name/"* "$framework_dir/Versions/A/Headers/"
    elif [[ -d "$X86_64_DIR/include/$lib_name" ]]; then
        cp -R "$X86_64_DIR/include/$lib_name/"* "$framework_dir/Versions/A/Headers/"
    fi
    
    # Create Info.plist
    local bundle_id="org.ffmpeg.${lib_name}"
    cat > "$framework_dir/Versions/A/Resources/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>${lib_name}</string>
    <key>CFBundleIdentifier</key>
    <string>${bundle_id}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${lib_name}</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>${MACOS_MIN_VERSION}</string>
</dict>
</plist>
EOF
    
    # Create standard framework symlinks (macOS convention)
    cd "$framework_dir/Versions"
    ln -sf A Current
    cd "$framework_dir"
    ln -sf Versions/Current/$lib_name $lib_name
    ln -sf Versions/Current/Headers Headers
    ln -sf Versions/Current/Resources Resources
    
    log_success "  Created: $framework_dir"
    return 0
}

main() {
    log_info "Creating macOS Universal Frameworks"
    log_info "  arm64 build: $ARM64_DIR"
    log_info "  x86_64 build: $X86_64_DIR"
    log_info "  Output: $OUTPUT_DIR"
    
    # Verify builds exist
    if [[ ! -d "$ARM64_DIR/lib" ]]; then
        die "arm64 build not found at $ARM64_DIR. Run build-arch.sh arm64 first."
    fi
    
    if [[ ! -d "$X86_64_DIR/lib" ]]; then
        die "x86_64 build not found at $X86_64_DIR. Run build-arch.sh x86_64 first."
    fi
    
    # Create output directory
    mkdir -p "$OUTPUT_DIR"
    
    # Create frameworks for each library
    log_info ""
    log_info "Creating framework bundles..."
    local success_count=0
    for lib in "${FFMPEG_LIBS[@]}"; do
        if create_framework "$lib"; then
            ((success_count++))
        fi
    done
    
    log_success ""
    log_success "Created $success_count frameworks successfully!"
    log_success "Output directory: $OUTPUT_DIR"
}

main "$@"
