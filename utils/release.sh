#!/bin/bash
# RELEASE SCRIPT FOR NAIKARI
#
# This script attempts to compile and build different parts of Naikari
# automatically in order to prepare for a new release. Files will  be written
# to the "dist/" directory.

if [[ ! -f "naikari.6" ]]; then
   echo "Please run from Naikari root directory."
   exit -1
fi

NAIKARIDIR="$(pwd)"
OUTPUTDIR="${NAIKARIDIR}/dist/"
LOGFILE="release.log"
THREADS="-j$(nproc --all)"

COMPILED=""
FAILED=""
SKIPPED=""

function log {
   echo
   echo
   echo "====================================="
   echo "$1"
   echo "====================================="
   return 0
}

function get_version {
   VERSION="$(cat ${NAIKARIDIR}/VERSION)"
   # Get version, negative minors mean betas
   if [[ -n $(echo "${VERSION}" | grep "-") ]]; then
      BASEVER=$(echo "${VERSION}" | sed 's/\.-.*//')
      BETAVER=$(echo "${VERSION}" | sed 's/.*-//')
      VERSION="${BASEVER}.0-beta.${BETAVER}"
   fi
   return 0
}

function make_generic {
   log "Compiling $2"
   make distclean
   ./autogen.sh
   ./configure $1
   make ${THREADS}
   get_version
   if [[ -f src/naikari ]]; then
      mv src/naikari "${OUTPUTDIR}/naikari-${VERSION}-$2"
      COMPILED="$COMPILED $2"
      return 0
   else
      FAILED="$FAILED $2"
      return 1
   fi
}

function make_win32 {
   # Openal isabled due to issues while compiling.. not sure what is up.
   make_generic "--host=i686-w64-mingw32.static --enable-lua=internal --with-openal=no" "win32"
}

function make_win64 {
   make_generic "--host=x86_64-w64-mingw32.static --enable-lua=internal" "win64"
}

function make_linux_64 {
   make_generic "--enable-lua=internal" "linux-x86-64"
}

function make_source {
   log "Making source bzip2"
   VERSIONRAW="$(cat ${NAIKARIDIR}/VERSION)"
   make dist-bzip2
   if [[ -f "naikari-${VERSIONRAW}.tar.bz2" ]]; then
      get_version
      mv "naikari-${VERSIONRAW}.tar.bz2" "dist/naikari-${VERSION}-source.tar.bz2"
      COMPILED="$COMPILED source"
      return 0
   else
      FAILED="$FAILED source"
      return 1
   fi
}

function make_ndata {
   log "Making ndata"
   get_version
   make "ndata.zip"
   if [[ -f "ndata.zip" ]]; then
      mv "ndata.zip" "${OUTPUTDIR}/ndata-${VERSION}.zip"
      COMPILED="$COMPILED ndata"
      return 0
   else
      FAILED="$FAILED ndata"
      return 1
   fi
}

# Create output dirdectory if necessary
test -d "${OUTPUTDIR}" || mkdir "${OUTPUTDIR}"

# Set up log
rm -f "${LOGFILE}"
touch "${LOGFILE}"

# Preparation
make distclean
./autogen.sh
./configure --enable-lua=internal
make VERSION

# Make stuff
make_source          >> "${LOGFILE}" 2>&1
make_ndata           >> "${LOGFILE}" 2>&1
make_win32           >> "${LOGFILE}" 2>&1
make_win64           >> "${LOGFILE}" 2>&1
make_linux_64        >> "${LOGFILE}" 2>&1

log "COMPILED"
for i in ${COMPILED[@]}; do echo "$i"; done

log "SKIPPED"
for i in ${SKIPPED[@]}; do echo "$i"; done

log "FAILED"
for i in ${FAILED[@]}; do echo "$i"; done
