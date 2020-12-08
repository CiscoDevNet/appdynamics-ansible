#!/usr/bin/env sh
VER=1.6
DIR=~/Downloads
MIRROR=https://github.com/stedolan/jq/releases/download/jq-$VER

dl()
{
    PLATFORM=$1
    SUFFIX=${2:-}
    wget -O $DIR/jq-$VER-$PLATFORM$SUFFIX $MIRROR/jq-$PLATFORM
}

dl linux32
dl linux64
dl osx-amd64
dl win32 .exe
dl win64 .exe
sha256sum $DIR/jq-$VER-*

