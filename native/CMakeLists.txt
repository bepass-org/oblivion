cmake_minimum_required(VERSION 3.15)

set(OBLIVION_CORE_DIR "${CMAKE_CURRENT_LIST_DIR}/oblivion_core")
set(AETHER_CORE_DIR "${CMAKE_CURRENT_LIST_DIR}/../aetherproject/aether")
set(PSIPHON_CORE_DIR "${CMAKE_CURRENT_LIST_DIR}/../../psiphon-tunnel-core")

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
  set(PSIPHON_BIN_NAME "psiphon.exe")
elseif(APPLE)
  set(OBLIVION_CORE_LIB_NAME "liboblivion_core.dylib")
  set(AETHER_BIN_NAME "aether")
  set(PSIPHON_BIN_NAME "psiphon")
else()
  set(OBLIVION_CORE_LIB_NAME "liboblivion_core.so")
  set(AETHER_BIN_NAME "aether")
  set(PSIPHON_BIN_NAME "psiphon")
endif()

if(WIN32)
  set(OBLIVION_HELPER_NAME "oblivion-helper.exe")
else()
  set(OBLIVION_HELPER_NAME "oblivion-helper")
endif()

set(OBLIVION_CORE_LIB
  "${OBLIVION_CORE_DIR}/target/${OBLIVION_CARGO_PROFILE_DIR}/${OBLIVION_CORE_LIB_NAME}")
set(OBLIVION_HELPER_BIN
  "${OBLIVION_CORE_DIR}/target/${OBLIVION_CARGO_PROFILE_DIR}/${OBLIVION_HELPER_NAME}")

add_custom_command(
  OUTPUT "${OBLIVION_CORE_LIB}" "${OBLIVION_HELPER_BIN}"
  COMMAND cargo build ${OBLIVION_CARGO_FLAGS}
  WORKING_DIRECTORY "${OBLIVION_CORE_DIR}"
  COMMENT "Building the Oblivion FFI bridge and the privileged helper"
  VERBATIM
)

add_custom_target(oblivion_core_build ALL
  DEPENDS "${OBLIVION_CORE_LIB}" "${OBLIVION_HELPER_BIN}")

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

set(PSIPHON_BIN "${CMAKE_CURRENT_BINARY_DIR}/${PSIPHON_BIN_NAME}")

if(EXISTS "${PSIPHON_CORE_DIR}/go.mod")
  set(PSIPHON_BUILDINFO
    "github.com/Psiphon-Labs/psiphon-tunnel-core/psiphon/common/buildinfo")

  execute_process(
    COMMAND git rev-parse --short HEAD
    WORKING_DIRECTORY "${PSIPHON_CORE_DIR}"
    OUTPUT_VARIABLE PSIPHON_BUILD_REV
    OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_QUIET
  )
  execute_process(
    COMMAND git config --get remote.origin.url
    WORKING_DIRECTORY "${PSIPHON_CORE_DIR}"
    OUTPUT_VARIABLE PSIPHON_BUILD_REPO
    OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_QUIET
  )
  if(NOT PSIPHON_BUILD_REV)
    set(PSIPHON_BUILD_REV "unknown")
  endif()
  string(TIMESTAMP PSIPHON_BUILD_DATE "%Y-%m-%dT%H:%M:%SZ" UTC)

  add_custom_command(
    OUTPUT "${PSIPHON_BIN}"
    COMMAND go build -trimpath -ldflags
      "-s -w -X ${PSIPHON_BUILDINFO}.buildDate=${PSIPHON_BUILD_DATE} -X ${PSIPHON_BUILDINFO}.buildRepo=${PSIPHON_BUILD_REPO} -X ${PSIPHON_BUILDINFO}.buildRev=${PSIPHON_BUILD_REV}"
      -o "${PSIPHON_BIN}" ./ConsoleClient
    WORKING_DIRECTORY "${PSIPHON_CORE_DIR}"
    COMMENT "Building the Psiphon tunnel engine (${PSIPHON_BUILD_REV})"
    VERBATIM
  )
  add_custom_target(psiphon_core_build ALL DEPENDS "${PSIPHON_BIN}")
  set(OBLIVION_PSIPHON_BIN "${PSIPHON_BIN}" PARENT_SCOPE)
else()
  message(WARNING
    "Psiphon engine sources not found at ${PSIPHON_CORE_DIR}")
  set(OBLIVION_PSIPHON_BIN "" PARENT_SCOPE)
endif()

set(OBLIVION_CORE_BUNDLED_LIB "${OBLIVION_CORE_LIB}" PARENT_SCOPE)

set(OBLIVION_HELPER_BUNDLED_BIN "${OBLIVION_HELPER_BIN}" PARENT_SCOPE)

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
