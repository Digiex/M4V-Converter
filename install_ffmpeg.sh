#!/usr/bin/env bash

#
# ONLY TESTED ON Ubuntu Server 16.04.1 LTS & macOS Sierra (10.12.1)
# USE AT YOUR OWN RISK
#

installLinux() {
  if [[ $(whoami) != "root" ]]; then
    echo "You must be root to run this script on Linux."
    exit 1
  fi

  apt-get update
  apt-get -y install autoconf automake build-essential libass-dev libfreetype6-dev \
    libtheora-dev libvorbis-dev libtool pkg-config texinfo zlib1g-dev

  mkdir ~/ffmpeg_sources

  cd ~/ffmpeg_sources
  wget http://www.tortall.net/projects/yasm/releases/yasm-1.3.0.tar.gz
  tar xzvf yasm-1.3.0.tar.gz
  cd yasm-1.3.0
  ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin"
  make
  make install
  make distclean

  cd ~/ffmpeg_sources
  wget http://download.videolan.org/pub/x264/snapshots/last_x264.tar.bz2
  tar xjvf last_x264.tar.bz2
  cd x264-snapshot*
  PATH="$HOME/bin:$PATH" ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" --enable-static
  PATH="$HOME/bin:$PATH" make
  make install
  make distclean

  apt-get -y install cmake mercurial
  cd ~/ffmpeg_sources
  hg clone https://bitbucket.org/multicoreware/x265
  cd ~/ffmpeg_sources/x265/build/linux
  PATH="$HOME/bin:$PATH" cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$HOME/ffmpeg_build" -DENABLE_SHARED:bool=off ../../source
  make
  make install
  make distclean

  cd ~/ffmpeg_sources
  wget -O fdk-aac.tar.gz https://github.com/mstorsjo/fdk-aac/tarball/master
  tar xzvf fdk-aac.tar.gz
  cd mstorsjo-fdk-aac*
  autoreconf -fiv
  ./configure --prefix="$HOME/ffmpeg_build" --disable-shared
  make
  make install
  make distclean

  apt-get -y install nasm
  cd ~/ffmpeg_sources
  wget http://downloads.sourceforge.net/project/lame/lame/3.99/lame-3.99.5.tar.gz
  tar xzvf lame-3.99.5.tar.gz
  cd lame-3.99.5
  ./configure --prefix="$HOME/ffmpeg_build" --enable-nasm --disable-shared
  make
  make install
  make distclean

  cd ~/ffmpeg_sources
  wget http://downloads.xiph.org/releases/opus/opus-1.1.3.tar.gz
  tar xzvf opus-1.1.3.tar.gz
  cd opus-1.1.3
  ./configure --prefix="$HOME/ffmpeg_build" --disable-shared
  make
  make install
  make clean

  cd ~/ffmpeg_sources
  wget http://storage.googleapis.com/downloads.webmproject.org/releases/webm/libvpx-1.6.0.tar.bz2
  tar xjvf libvpx-1.6.0.tar.bz2
  cd libvpx-1.6.0
  PATH="$HOME/bin:$PATH" ./configure --prefix="$HOME/ffmpeg_build" --disable-examples --disable-unit-tests
  PATH="$HOME/bin:$PATH" make
  make install
  make clean

  cd ~/ffmpeg_sources
  wget http://www.ffmpeg.org/releases/ffmpeg-3.2.tar.bz2
  tar xjvf ffmpeg-3.2.tar.bz2
  cd ffmpeg-3.2

  # Fixes multiple audio streams being default
  # http://trac.ffmpeg.org/ticket/3622
  # https://gist.github.com/outlyer/4a88f1adb7f895b93fd9
  # https://gist.github.com/xzKinGzxBuRnzx/da6406c854d18afdd76ab1ce7d4762c8
  wget https://gist.githubusercontent.com/xzKinGzxBuRnzx/da6406c854d18afdd76ab1ce7d4762c8/raw/55c75ba04ffb9e5cd93477b34617f35cede25f03/ffmpeg-3.2-defaultstreams.patch
  patch libavformat/movenc.c < ffmpeg-3.2-defaultstreams.patch

  PATH="$HOME/bin:$PATH" PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure \
    --prefix="$HOME/ffmpeg_build" \
    --pkg-config-flags="--static" \
    --extra-cflags="-I$HOME/ffmpeg_build/include" \
    --extra-ldflags="-L$HOME/ffmpeg_build/lib" \
    --bindir="$HOME/bin" \
    --enable-gpl \
    --enable-libass \
    --enable-libfdk-aac \
    --enable-libfreetype \
    --enable-libmp3lame \
    --enable-libopus \
    --enable-libtheora \
    --enable-libvorbis \
    --enable-libvpx \
    --enable-libx264 \
    --enable-libx265 \
    --enable-nonfree
  PATH="$HOME/bin:$PATH" make
  make install
  make distclean
  hash -r

  cp "$HOME"/bin/* /usr/local/bin/
  cp "$HOME"/ffmpeg_build/bin/* /usr/local/bin/

  rm -rf "$HOME"/bin
  rm -rf "$HOME"/ffmpeg_build
  rm -rf "$HOME"/ffmpeg_sources
}

installMac() {
  if ! hash brew 2>/dev/null; then
    echo "You must install Homebrew from http://brew.sh/ for this script to assist in installing ffmpeg."
    exit 1
  fi
  curl -s https://gist.githubusercontent.com/xzKinGzxBuRnzx/da6406c854d18afdd76ab1ce7d4762c8/raw/55c75ba04ffb9e5cd93477b34617f35cede25f03/ffmpeg.rb > ffmpeg.rb
  mv ffmpeg.rb /usr/local/Homebrew/Library/Taps/homebrew/homebrew-core/Formula/ffmpeg.rb
  brew reinstall ffmpeg --enable-gpl --enable-libass --enable-libfdk-aac --enable-libfreetype --enable-libmp3lame --enable-libopus --enable-libtheora --enable-libvorbis --enable-libvpx --enable-libx264 --enable-libx265 --enable-nonfree
}

case "${OSTYPE}" in
  linux-gnu) installLinux ;;
  darwin*) installMac ;;
esac

exit 0