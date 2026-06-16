#!/bin/bash
# Verify that built Android shared libraries use 16KB ELF segment alignment.
#
# Google Play requires apps targeting Android 15+ (API 35+) to support 16KB page
# sizes on 64-bit devices. Every shipped 64-bit .so must have its ELF LOAD
# segments aligned to at least 2**14 (16384 bytes). This script fails (exit 1)
# if any 64-bit .so is not compliant, so it can gate CI and local builds.
#
# Usage: ./verify-16kb.sh [output_dir]
#   output_dir defaults to <project>/output/android
#
# See: https://developer.android.com/guide/practices/page-sizes

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common/utils.sh"

OUTPUT_DIR="${1:-$(get_output_dir)/android}"

# Only 64-bit ABIs are subject to the 16KB requirement. 32-bit (armeabi-v7a)
# devices always use 4KB pages and are not checked by Google Play.
ABIS_64BIT=("arm64-v8a" "x86_64")

# Locate an objdump that understands ELF program headers. Prefer the NDK's
# llvm-objdump, then any llvm-objdump/objdump on PATH.
find_objdump() {
    if [[ -n "${ANDROID_NDK_HOME:-}" ]]; then
        local host_tag
        if is_macos; then host_tag="darwin-x86_64"; else host_tag="linux-x86_64"; fi
        local candidate="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/$host_tag/bin/llvm-objdump"
        if [[ -x "$candidate" ]]; then echo "$candidate"; return; fi
    fi
    if command -v llvm-objdump &>/dev/null; then echo "llvm-objdump"; return; fi
    if command -v objdump &>/dev/null; then echo "objdump"; return; fi
    echo ""
}

main() {
    local objdump
    objdump="$(find_objdump)"
    [[ -z "$objdump" ]] && die "No llvm-objdump/objdump found. Set ANDROID_NDK_HOME or install LLVM/binutils."

    log_info "Verifying 16KB alignment of 64-bit .so files in: $OUTPUT_DIR"
    log_info "Using: $objdump"

    local checked=0 failures=0

    for abi in "${ABIS_64BIT[@]}"; do
        local lib_dir="$OUTPUT_DIR/$abi/lib"
        if [[ ! -d "$lib_dir" ]]; then
            log_warn "No lib directory for $abi (skipping): $lib_dir"
            continue
        fi

        while IFS= read -r -d '' so; do
            ((checked++)) || true
            # Find the smallest LOAD-segment alignment exponent N (from "2**N").
            local min_align
            min_align=$("$objdump" -p "$so" | awk '
                /LOAD/ {
                    for (i = 1; i <= NF; i++)
                        if ($i ~ /^2\*\*[0-9]+$/) {
                            n = substr($i, 4) + 0
                            if (m == "" || n < m) m = n
                        }
                }
                END { print (m == "" ? "" : m) }')

            if [[ -z "$min_align" ]]; then
                log_warn "  ? $(basename "$so") ($abi): no LOAD segments found"
            elif [[ "$min_align" -lt 14 ]]; then
                log_error "  ✗ $(basename "$so") ($abi): LOAD align is 2**$min_align (need >= 2**14 / 16KB)"
                ((failures++)) || true
            else
                log_success "  ✓ $(basename "$so") ($abi): 16KB aligned (2**$min_align)"
            fi
        done < <(find "$lib_dir" -name '*.so' -print0)
    done

    if [[ "$checked" -eq 0 ]]; then
        die "No 64-bit .so files found under $OUTPUT_DIR — nothing verified."
    fi
    if [[ "$failures" -gt 0 ]]; then
        die "$failures shared librar(ies) are NOT 16KB aligned. Rebuild with NDK r28+ or the 16KB linker flags."
    fi

    log_success "All $checked 64-bit shared libraries are 16KB aligned (>= 2**14)."
}

main "$@"
