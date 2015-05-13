#!/bin/bash

if hash ffmpeg 2>/dev/null; then
	echo "FFMPEG is already installed."
	exit 1
fi

if [[ "$OSTYPE" == "darwin"* ]]; then
	if hash brew 2>/dev/null; then
		brew install ffmpeg
	else
		ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"
		brew install ffmpeg
	fi
elif [[ "$OSTYPE" == "linux-gnu" ]]; then
	sudo apt-get update
	sudo apt-get -y --force-yes install autoconf automake build-essential libass-dev libfreetype6-dev libgpac-dev \
	libsdl1.2-dev libtheora-dev libtool libva-dev libvdpau-dev libvorbis-dev libxcb1-dev libxcb-shm0-dev \
	libxcb-xfixes0-dev pkg-config texi2html zlib1g-dev cmake mercurial unzip nasm
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

	cd ~/ffmpeg_sources
	hg clone https://bitbucket.org/multicoreware/x265
	cd ~/ffmpeg_sources/x265/build/linux
	PATH="$HOME/bin:$PATH" cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$HOME/ffmpeg_build" -DENABLE_SHARED:bool=off ../../source
	make
	make install
	make distclean

	cd ~/ffmpeg_sources
	wget -O fdk-aac.zip https://github.com/mstorsjo/fdk-aac/zipball/master
	unzip fdk-aac.zip
	cd mstorsjo-fdk-aac*
	autoreconf -fiv
	./configure --prefix="$HOME/ffmpeg_build" --disable-shared
	make
	make install
	make distclean

	cd ~/ffmpeg_sources
	wget http://downloads.sourceforge.net/project/lame/lame/3.99/lame-3.99.5.tar.gz
	tar xzvf lame-3.99.5.tar.gz
	cd lame-3.99.5
	./configure --prefix="$HOME/ffmpeg_build" --enable-nasm --disable-shared
	make
	make install
	make distclean

	cd ~/ffmpeg_sources
	wget http://downloads.xiph.org/releases/opus/opus-1.1.tar.gz
	tar xzvf opus-1.1.tar.gz
	cd opus-1.1
	./configure --prefix="$HOME/ffmpeg_build" --disable-shared
	make
	make install
	make distclean

	cd ~/ffmpeg_sources
	wget http://webm.googlecode.com/files/libvpx-v1.3.0.tar.bz2
	tar xjvf libvpx-v1.3.0.tar.bz2
	cd libvpx-v1.3.0
	PATH="$HOME/bin:$PATH" ./configure --prefix="$HOME/ffmpeg_build" --disable-examples --disable-unit-tests
	PATH="$HOME/bin:$PATH" make
	make install
	make clean

	cd ~/ffmpeg_sources
	wget http://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2
	tar xjvf ffmpeg-snapshot.tar.bz2
	cd ffmpeg
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
fi

echo "Finished!"