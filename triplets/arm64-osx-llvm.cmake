set(VCPKG_TARGET_ARCHITECTURE arm64)
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE static)

set(VCPKG_CMAKE_SYSTEM_NAME Darwin)
set(VCPKG_OSX_ARCHITECTURES arm64)

if(DEFINED ENV{OT_OSX_LLVM_VERSION})
    message(STATUS "Using build tools located at /usr/local/opt/llvm@$ENV{OT_OSX_LLVM_VERSION}")

    set(LLVM_PATH /usr/local/opt/llvm@$ENV{OT_OSX_LLVM_VERSION})
    set(LINKER_FLAGS "-L${LLVM_PATH}/lib/c++ -L${LLVM_PATH}/lib -L${LLVM_PATH}/lib/unwind -lunwind")
    set(VCPKG_CMAKE_CONFIGURE_OPTIONS -DCMAKE_C_COMPILER=${LLVM_PATH}/bin/clang -DCMAKE_CXX_COMPILER=${LLVM_PATH}/bin/clang++ -DCMAKE_SHARED_LINKER_FLAGS_INIT=${LINKER_FLAGS} -DCMAKE_EXE_LINKER_FLAGS_INIT=${LINKER_FLAGS} -DCMAKE_CXX_FLAGS_INIT=-I${LLVM_PATH}/include)
else()
    message(FATAL_ERROR "You must set OT_OSX_LLVM_VERSION in the environment before using this triplet")
endif()

if(DEFINED ENV{OT_OSX_DEPLOYMENT_TARGET})
    message(STATUS "Using $ENV{OT_OSX_DEPLOYMENT_TARGET} for VCPKG_OSX_DEPLOYMENT_TARGET")

    set(CMAKE_OSX_DEPLOYMENT_TARGET "$ENV{OT_OSX_DEPLOYMENT_TARGET}")
    set(VCPKG_OSX_DEPLOYMENT_TARGET "$ENV{OT_OSX_DEPLOYMENT_TARGET}")
else()
    message(FATAL_ERROR "You must set OT_OSX_DEPLOYMENT_TARGET in the environment before using this triplet")
endif()

if(DEFINED ENV{XCODE_ROOT})
    set(SDKROOT "$ENV{XCODE_ROOT}/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk")
    set(ENV{SDKROOT} "${SDKROOT}")

    message(STATUS "Using MacOSX sdk at $ENV{SDKROOT}")
else()
    message(FATAL_ERROR "You must set XCODE_ROOT in the environment before using this triplet")
endif()
