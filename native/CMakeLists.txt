cmake_minimum_required(VERSION 3.15)

set(OBLIVION_CORE_DIR "${CMAKE_CURRENT_LIST_DIR}/oblivion_core")
set(AETHER_CORE_DIR "${CMAKE_CURRENT_LIST_DIR}/../aetherproject/aether")

if(CMAKE_BUILD_TYPE STREQUAL "Debug")
  set(OBLIVION_CARGO_PROFILE_DIR "debug")
  set(OBLIVION_CARGO_FLAGS "")
else()
  set(OBLIVION_CARGO_PROFILE_DIR "release")
  set(OBLIVION_CARGO_FLAGS "--release")
endif()

if(WIN32)
  set(OBLIVION_CORE_LIB_NAME "oblivion_core.dll")
  set(AETHER_BIN_NAME "aether.exe")
elseif(APPLE)
  set(OBLIVION_CORE_LIB_NAME "liboblivion_core.dylib")
  set(AETHER_BIN_NAME "aether")
else()
  set(OBLIVION_CORE_LIB_NAME "liboblivion_core.so")
  set(AETHER_BIN_NAME "aether")
endif()

set(OBLIVION_CORE_LIB
  "${OBLIVION_CORE_DIR}/target/${OBLIVION_CARGO_PROFILE_DIR}/${OBLIVION_CORE_LIB_NAME}")

add_custom_command(
  OUTPUT "${OBLIVION_CORE_LIB}"
  COMMAND cargo build ${OBLIVION_CARGO_FLAGS}
  WORKING_DIRECTORY "${OBLIVION_CORE_DIR}"
  COMMENT "Building the Oblivion FFI bridge"
  VERBATIM
)

add_custom_target(oblivion_core_build ALL DEPENDS "${OBLIVION_CORE_LIB}")

set(AETHER_BIN "${AETHER_CORE_DIR}/target/release/${AETHER_BIN_NAME}")

if(EXISTS "${AETHER_CORE_DIR}/Cargo.toml")
  add_custom_command(
    OUTPUT "${AETHER_BIN}"
    COMMAND cargo build --release --bin aether
    WORKING_DIRECTORY "${AETHER_CORE_DIR}"
    COMMENT "Building the Aether tunnel engine"
    VERBATIM
  )
  add_custom_target(aether_core_build ALL DEPENDS "${AETHER_BIN}")
  set(OBLIVION_AETHER_BIN "${AETHER_BIN}" PARENT_SCOPE)
else()
  message(WARNING
    "Aether engine sources not found at ${AETHER_CORE_DIR}")
  set(OBLIVION_AETHER_BIN "" PARENT_SCOPE)
endif()

set(OBLIVION_CORE_BUNDLED_LIB "${OBLIVION_CORE_LIB}" PARENT_SCOPE)

if(WIN32)
  set(OBLIVION_HEVTUN_DIR "${CMAKE_CURRENT_LIST_DIR}/../windows/hevtun")
  file(GLOB OBLIVION_HEVTUN_PAYLOAD
    "${OBLIVION_HEVTUN_DIR}/hev-socks5-tunnel.exe"
    "${OBLIVION_HEVTUN_DIR}/*.dll")

  if(OBLIVION_HEVTUN_PAYLOAD)
    set(OBLIVION_HEVTUN_FILES "${OBLIVION_HEVTUN_PAYLOAD}" PARENT_SCOPE)
  else()
    set(OBLIVION_HEVTUN_FILES "" PARENT_SCOPE)
    message(WARNING
      "No tunnel helper in ${OBLIVION_HEVTUN_DIR}, this build will be proxy only")
  endif()
endif()
