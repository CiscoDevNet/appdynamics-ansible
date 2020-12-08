#!/usr/bin/env bash

VER=1.6
DIR=~/Downloads
MIRROR=https://github.com/stedolan/jq/releases/download/jq-"$VER"

ch()
{
    PLATFORM="$1"
    SUFFIX="${2:-}"
    wget -O "$DIR"/jq-"$VER"-"$PLATFORM$SUFFIX" "$MIRROR"/jq-"$PLATFORM"
}

ch linux32
ch linux64
ch osx-amd64
ch win32 .exe
ch win64 .exe
sha256sum "$DIR"/jq-"$VER"-*

