#!/usr/bin/env bash

case "${OSTYPE}" in
  linux*)
    if [[ $(whoami) != "root" ]]; then
      echo "You must be root to run this script on Linux"
      exit 1
    fi
    distro=$(cat /etc/*-release | grep -x 'ID=.*' | sed -E 's/ID=|\"//g')
    case "${distro}" in
      ubuntu|debian) apt update && apt install -y ffmpeg ;;
      alpine) apk update && apk add ffmpeg ;;
      *) echo "This Linux distribution is unsupported"; exit 2 ;;
    esac
  ;;
  darwin*)
    if ! hash brew 2>/dev/null; then
      echo "You must install Homebrew from http://brew.sh/"
      exit 10
    fi
    brew install ffmpeg bash
  ;;
esac

exit 0
