
set(proj curl)

# Set dependency list
set(${proj}_DEPENDENCIES zlib)
if(CURL_ENABLE_SSL)
  if(NOT ${CMAKE_PROJECT_NAME}_USE_SYSTEM_${proj})
    list(APPEND ${proj}_DEPENDENCIES OpenSSL)
  else()
    # XXX - Add a test checking if system curl support OpenSSL
  endif()
endif()

# Include dependent projects if any
ExternalProject_Include_Dependencies(${proj} PROJECT_VAR proj DEPENDS_VAR ${proj}_DEPENDENCIES)

if(${CMAKE_PROJECT_NAME}_USE_SYSTEM_${proj})
  unset(CURL_INCLUDE_DIR CACHE)
  unset(CURL_LIBRARY CACHE)
  find_package(CURL REQUIRED)
endif()

if((NOT DEFINED CURL_INCLUDE_DIR
   OR NOT DEFINED CURL_LIBRARY) AND NOT ${CMAKE_PROJECT_NAME}_USE_SYSTEM_${proj})

  set(EXTERNAL_PROJECT_OPTIONAL_CMAKE_ARGS)

  if(CURL_ENABLE_SSL)
    list(APPEND EXTERNAL_PROJECT_OPTIONAL_CMAKE_ARGS CMAKE_ARGS
      -DOPENSSL_INCLUDE_DIR:PATH=${OPENSSL_INCLUDE_DIR}
      )
    if(UNIX)
      list(APPEND EXTERNAL_PROJECT_OPTIONAL_CMAKE_ARGS
        -DOPENSSL_SSL_LIBRARY:STRING=${OPENSSL_SSL_LIBRARY}
        -DOPENSSL_CRYPTO_LIBRARY:STRING=${OPENSSL_CRYPTO_LIBRARY}
        )
    elseif(WIN32)
      list(APPEND EXTERNAL_PROJECT_OPTIONAL_CMAKE_ARGS
        -DLIB_EAY_DEBUG:FILEPATH=${LIB_EAY_DEBUG}
        -DLIB_EAY_RELEASE:FILEPATH=${LIB_EAY_RELEASE}
        -DSSL_EAY_DEBUG:FILEPATH=${SSL_EAY_DEBUG}
        -DSSL_EAY_RELEASE:FILEPATH=${SSL_EAY_RELEASE}
        )
    endif()
  endif()

  set(${proj}_CMAKE_C_FLAGS ${ep_common_c_flags})
  if(CMAKE_SIZEOF_VOID_P EQUAL 8) # 64-bit
    set(${proj}_CMAKE_C_FLAGS "${ep_common_c_flags} -fPIC")
  endif()

  ExternalProject_SetIfNotDefined(
    ${CMAKE_PROJECT_NAME}_${proj}_GIT_REPOSITORY
    "${EP_GIT_PROTOCOL}://github.com/Slicer/curl.git"
    QUIET
    )

  ExternalProject_SetIfNotDefined(
    ${CMAKE_PROJECT_NAME}_${proj}_GIT_TAG
    "0722f23d53927ebe71b6f6126f6cc2014c147c1f"
    QUIET
    )

  set(EP_SOURCE_DIR ${CMAKE_BINARY_DIR}/${proj})
  set(EP_BINARY_DIR ${CMAKE_BINARY_DIR}/${proj}-build)
  set(EP_INSTALL_DIR ${CMAKE_BINARY_DIR}/${proj}-install)

  ExternalProject_Add(${proj}
    ${${proj}_EP_ARGS}
    GIT_REPOSITORY "${${CMAKE_PROJECT_NAME}_${proj}_GIT_REPOSITORY}"
    GIT_TAG "${${CMAKE_PROJECT_NAME}_${proj}_GIT_TAG}"
    SOURCE_DIR ${EP_SOURCE_DIR}
    BINARY_DIR ${EP_BINARY_DIR}
    CMAKE_CACHE_ARGS
    #Not needed -DCMAKE_CXX_COMPILER:FILEPATH=${CMAKE_CXX_COMPILER}
    #Not needed -DCMAKE_CXX_FLAGS:STRING=${ep_common_cxx_flags}
      -DCMAKE_C_COMPILER:FILEPATH=${CMAKE_C_COMPILER}
      -DCMAKE_C_FLAGS:STRING=${${proj}_CMAKE_C_FLAGS}
      -DCMAKE_INSTALL_PREFIX:PATH=${EP_INSTALL_DIR}
      -DBUILD_CURL_TESTS:BOOL=OFF # BUILD_TESTING is not used
      -DBUILD_CURL_EXE:BOOL=OFF
      -DBUILD_DASHBOARD_REPORTS:BOOL=OFF
      -DCURL_STATICLIB:BOOL=ON
      -DCURL_USE_ARES:BOOL=OFF
      -DCURL_ZLIB:BOOL=ON
      -DZLIB_INCLUDE_DIR:PATH=${ZLIB_INCLUDE_DIR}
      -DZLIB_LIBRARY:FILEPATH=${ZLIB_LIBRARY}
      -DCURL_DISABLE_FTP:BOOL=ON
      -DCURL_DISABLE_LDAP:BOOL=ON
      -DCURL_DISABLE_LDAPS:BOOL=ON
      -DCURL_DISABLE_TELNET:BOOL=ON
      -DCURL_DISABLE_DICT:BOOL=ON
      -DCURL_DISABLE_FILE:BOOL=ON
      -DCURL_DISABLE_TFTP:BOOL=ON
      -DHAVE_LIBIDN:BOOL=FALSE
      -DCMAKE_USE_OPENSSL:BOOL=${CURL_ENABLE_SSL}
      # macOS
      -DCMAKE_MACOSX_RPATH:BOOL=0
    ${EXTERNAL_PROJECT_OPTIONAL_CMAKE_ARGS}
    DEPENDS
      ${${proj}_DEPENDENCIES}
    )

  ExternalProject_GenerateProjectDescription_Step(${proj})

  if(UNIX)
    set(curl_IMPORT_SUFFIX .a)
    if(APPLE)
      set(curl_IMPORT_SUFFIX .a)
    endif()
  elseif(WIN32)
    set(curl_IMPORT_SUFFIX .lib)
  else()
    message(FATAL_ERROR "Unknown system !")
  endif()

  set(CURL_INCLUDE_DIR "${EP_INSTALL_DIR}/include")
  set(CURL_LIBRARY "${EP_INSTALL_DIR}/lib/libcurl${curl_IMPORT_SUFFIX}")

else()
  ExternalProject_Add_Empty(${proj} DEPENDS ${${proj}_DEPENDENCIES})
endif()

mark_as_superbuild(
  VARS
    CURL_INCLUDE_DIR:PATH
    CURL_LIBRARY:FILEPATH
  LABELS "FIND_PACKAGE"
  )

ExternalProject_Message(${proj} "CURL_INCLUDE_DIR:${CURL_INCLUDE_DIR}")
ExternalProject_Message(${proj} "CURL_LIBRARY:${CURL_LIBRARY}")
