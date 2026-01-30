#!/bin/bash
# FFmpeg shared configuration flags
# Edit this file to customize the build

# FFmpeg version (git tag) - 6.1 has macOS AudioToolbox fixes
FFMPEG_VERSION="${FFMPEG_VERSION:-n6.1}"

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
        --enable-version3 \
        --enable-pic \
        --enable-optimizations \
        --enable-pthreads \
        --enable-small \
        --enable-lto \
        --disable-static \
        --enable-shared \
        --disable-autodetect \
        --disable-debug \
        --disable-doc \
        --disable-htmlpages \
        --disable-manpages \
        --disable-podpages \
        --disable-txtpages \
        --disable-programs \
        --disable-postproc \
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

# Get disabled components (for smaller binary size and cross-platform compat)
get_disabled_components() {
    echo "\
        --disable-xlib \
        --disable-sdl2 \
        --disable-sndio \
        --disable-schannel \
        --disable-xmm-clobber-test \
        --disable-neon-clobber-test"
}

# Android-specific flags
get_android_flags() {
    echo "\
        --enable-jni \
        --enable-mediacodec \
        --enable-decoder=h264_mediacodec \
        --enable-decoder=hevc_mediacodec \
        --enable-neon \
        --enable-asm \
        --enable-inline-asm \
        --disable-vulkan \
        --disable-v4l2-m2m \
        --disable-indev=fbdev \
        --disable-outdev=fbdev"
}

# iOS-specific flags
get_ios_flags() {
    echo "\
        --enable-videotoolbox \
        --disable-audiotoolbox \
        --disable-appkit \
        --disable-coreimage \
        --disable-vulkan"
}

# Full configure flags
get_ffmpeg_configure_flags() {
    echo "$(get_common_flags) $(get_enabled_components) $(get_disabled_components)"
}
