#!/bin/sh

set -e
set +u
# Avoid recursively calling this script.
if [[ $MC_MASTER_SCRIPT_RUNNING ]]
then
    exit 0
fi
set -u
export MC_MASTER_SCRIPT_RUNNING=1

MC_TARGET_NAME="IosMath"
MC_INPUT_STATIC_LIB="lib${MC_TARGET_NAME}.a"

function build_static_library {
    # Will rebuild the static library as specified
    #     build_static_library sdk
    xcrun xcodebuild -project "${PROJECT_DIR}/${PROJECT_NAME}.xcodeproj" \
        -target "${MC_TARGET_NAME}" \
        -configuration "${CONFIGURATION}" \
        -sdk "${1}" \
        ONLY_ACTIVE_ARCH=NO \
        BUILD_DIR="${BUILD_DIR}" \
        OBJROOT="${OBJROOT}" \
        BUILD_ROOT="${BUILD_ROOT}" \
        SYMROOT="${SYMROOT}" $ACTION
}

function make_fat_library {
    # Will smash 2 static libs together
    #     make_fat_library in1 in2 out
    xcrun lipo -create "${1}" "${2}" -output "${3}"
}


# 1 - Extract the platform (iphoneos/iphonesimulator) from the SDK name
if [[ "$SDK_NAME" =~ ([A-Za-z]+) ]]; then
    MC_SDK_PLATFORM=${BASH_REMATCH[1]}
else
    echo "Could not find platform name from SDK_NAME: $SDK_NAME"
    exit 1
fi

# 2 - Extract the version from the SDK
if [[ "$SDK_NAME" =~ ([0-9]+.*$) ]]; then
    MC_SDK_VERSION=${BASH_REMATCH[1]}
else
    echo "Could not find sdk version from SDK_NAME: $SDK_NAME"
    exit 1
fi

# 3 - Determine the other platform
if [ "$MC_SDK_PLATFORM" == "iphoneos" ]; then
    MC_OTHER_PLATFORM=iphonesimulator
else
    MC_OTHER_PLATFORM=iphoneos
fi

# 4 - Find the build directory
if [[ "$BUILT_PRODUCTS_DIR" =~ (.*)$MC_SDK_PLATFORM$ ]]; then
    MC_OTHER_BUILT_PRODUCTS_DIR="${BASH_REMATCH[1]}${MC_OTHER_PLATFORM}"
else
    echo "Could not find platform name from build products directory: $BUILT_PRODUCTS_DIR"
    exit 1
fi

# Build the other platform.
build_static_library "${MC_OTHER_PLATFORM}${MC_SDK_VERSION}"

# If we're currently building for iphonesimulator, then need to rebuild
#   to ensure that we get both i386 and x86_64
if [ "$MC_SDK_PLATFORM" == "iphonesimulator" ]; then
    build_static_library "${SDK_NAME}"
fi

# Join the 2 static libs into 1 and push into the .framework
make_fat_library "${BUILT_PRODUCTS_DIR}/${MC_INPUT_STATIC_LIB}" \
    "${MC_OTHER_BUILT_PRODUCTS_DIR}/${MC_INPUT_STATIC_LIB}" \
    "${HOME}/Desktop/${MC_INPUT_STATIC_LIB}"
