#!/bin/bash
# FFmpeg shared configuration flags
# Edit this file to customize the build

# FFmpeg version (git tag) - set to empty for latest release
FFMPEG_VERSION="${FFMPEG_VERSION:-}"

# Libraries to build
FFMPEG_LIBS=(
    "libavcodec"
    "libavdevice"
    "libavfilter"
    "libavformat"
    "libavutil"
    "libswresample"
    "libswscale"
)

# Common configure flags for all platforms
get_common_flags() {
    echo "\
        --disable-doc \
        --disable-programs \
        --disable-static \
        --enable-shared \
        --enable-pic \
        --disable-debug \
        --disable-symver \
        --disable-stripping"
}

# Get enabled components
get_enabled_components() {
    echo "\
        --enable-avcodec \
        --enable-avdevice \
        --enable-avfilter \
        --enable-avformat \
        --enable-swresample \
        --enable-swscale"
}

# Get disabled components (for smaller binary size)
get_disabled_components() {
    echo "\
        --disable-postproc \
        --disable-network \
        --disable-vulkan"
}

# Full configure flags
get_ffmpeg_configure_flags() {
    echo "$(get_common_flags) $(get_enabled_components) $(get_disabled_components)"
}
