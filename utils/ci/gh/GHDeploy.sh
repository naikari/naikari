#!/bin/bash

# GITHUB DEPLOYMENT SCRIPT FOR NAIKARI
#
# This script should be run after downloading all build artefacts.
# It also makes use of ENV variable GH_TOKEN to login. ensure this is exported.
#
#
# Pass in [-d] [-n] (set this for nightly builds) [-p] (set this for pre-release builds.) [-c] (set this for CI testing) -t <TEMPPATH> (build artefact location) -o <OUTDIR> (dist output directory) -r <TAGNAME> (tag of release *required*) -g <REPONAME> (defaults to naikari/naikari)

set -e

# Defaults
NIGHTLY="false"
PRERELEASE="false"
REPO="naikari/naikari"
TEMPPATH="$(pwd)"
OUTDIR="$(pwd)/dist"
DRYRUN="false"
REPONAME="naikari/naikari"

while getopts dnpct:o:r:g: OPTION "$@"; do
    case $OPTION in
    d)
        set -x
        ;;
    n)
        NIGHTLY="true"
        ;;
    p)
        PRERELEASE="true"
        ;;
    c)
        DRYRUN="true"
        ;;
    t)
        TEMPPATH="${OPTARG}"
        ;;
    o)
        OUTDIR="${OPTARG}"
        ;;
    r)
        TAGNAME="${OPTARG}"
        ;;
    g)
        REPONAME="${OPTARG}"
        ;;
    esac
done

if [[ -z "$TAGNAME" ]]; then
    echo "usage: `basename $0` [-d] [-n] (set this for nightly builds) [-p] (set this for pre-release builds.) [-c] (set this for CI testing) -t <TEMPPATH> (build artefact location) -o <OUTDIR> (dist output directory) -r <TAGNAME> (tag of release *required*) -g <REPONAME> (defaults to naikari/naikari)"
    exit -1
fi

retry() {
    local -r -i max_attempts="$1"; shift
    local -i attempt_num=1
    until "$@"
    do
        if ((attempt_num==max_attempts))
        then
            echo "Attempt $attempt_num failed and there are no more attempts left!"
            return 1
        else
            echo "Attempt $attempt_num failed! Trying again in $attempt_num seconds..."
            sleep $((attempt_num++))
        fi
    done
}

if ! [ -x "$(command -v gh)" ]; then
    echo "You don't have gh (github cli client) in PATH"
    exit -1
else
    GH="gh"
fi

run_gh () {
    retry 5 $GH $@
}

# Collect date and assemble the VERSION suffix

BUILD_DATE="$(date +%Y%m%d)"
VERSION="$(<"$TEMPPATH/naikari-version/VERSION")"

if [ "$NIGHTLY" == "true" ]; then
    SUFFIX="$VERSION+DEBUG.$BUILD_DATE"
elif [ "$PRERELEASE" == "true" ]; then
    SUFFIX="$VERSION+DEBUG.$BUILD_DATE"
else
    SUFFIX="$VERSION"
fi


# Make dist path if it does not exist
mkdir -p "$OUTDIR"/dist
mkdir -p "$OUTDIR"/lin64
mkdir -p "$OUTDIR"/macos
mkdir -p "$OUTDIR"/win64

# Move all build artefacts to deployment locations
# Move Linux binary and set as executable
cp "$TEMPPATH"/naikari-linux-x86-64/*.AppImage "$OUTDIR"/lin64/naikari-$SUFFIX-linux-x86-64.AppImage
chmod +x "$OUTDIR"/lin64/naikari-$SUFFIX-linux-x86-64.AppImage

# Move macOS bundle to deployment location
cp "$TEMPPATH"/naikari-macos/*.zip -d "$OUTDIR"/macos/naikari-$SUFFIX-macos.zip

# Move Windows installer to deployment location
cp "$TEMPPATH"/naikari-win64/naikari*.exe "$OUTDIR"/win64/naikari-$SUFFIX-win64.exe

# Move Dist to deployment location
cp "$TEMPPATH"/naikari-dist/source.tar.xz "$OUTDIR"/dist/naikari-$SUFFIX-source.tar.xz

# Push builds to github via gh

if [ "$DRYRUN" == "false" ]; then
    run_gh --version
    run_gh release upload "$TAGNAME" "$OUTDIR"/lin64/* -R "$REPONAME" --clobber
    run_gh release upload "$TAGNAME" "$OUTDIR"/macos/* -R "$REPONAME" --clobber
    run_gh release upload "$TAGNAME" "$OUTDIR"/win64/* -R "$REPONAME" --clobber
    run_gh release upload "$TAGNAME" "$OUTDIR"/dist/* -R "$REPONAME" --clobber
elif [ "$DRYRUN" == "true" ]; then
    run_gh --version
    if [ "$NIGHTLY" == "true" ]; then
        # Run github nightly upload
        echo "github nightly upload"
        ls -l -R "$OUTDIR"
    else
        if [ "$PRERELEASE" == "true" ]; then
            # Run github beta upload
            echo "github beta upload"
            ls -l -R "$OUTDIR"
        elif [ "$PRERELEASE" == "false" ]; then
            # Run github release upload
            echo "github release upload"
            ls -l -R "$OUTDIR"

        else
            echo "Something went wrong determining if this is a PRERELEASE or not."
        fi
    fi

else
    echo "Something went wrong determining which mode to run this script in."
    exit 1
fi
