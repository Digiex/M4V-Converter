M4V-Converter
==============
This script automates media conversion to a universal MP4 format using FFmpeg.

Fully integrates with NZBGet so that media converts automatically
on post-process! SABnzbd is also supported although it does not
get a WebUI config, though can still be configured using a config file!

Tested on x86-64 alpine/ubuntu/macOS and arm64 macOS (Apple Silicon/M1)

Found a bug? [Report it here!](https://github.com/Digiex/M4V-Converter/issues/new)

Dependencies
-------------
Requires `bash` version 4 or greater, `ffmpeg`, `ffprobe` and `jq`

Ubuntu:
```
apt-get update
apt-get install ffmpeg jq
```

Alpine:
```
apk update
apk add bash ffmpeg jq
```

macOS: Requires [Homebrew](https://brew.sh/)
```
brew update
brew install bash ffmpeg jq
```
When using macOS the default bash is still only version 3 and if you want to use the NZBGet.app or SABnzbd.app with the script you will need to do the following to correct PATH issues:

1. Find the PATH to bash, `which bash` This should return either `/opt/homebrew/bin/bash` (arm64) or `/usr/local/bin/bash` (x86) depending on your Mac architecture

2.  - NZBGet: Open the [NZBGet webui](http://127.0.0.1:6789/), go to settings, extension scripts, look for ShellOverride, give it the PATH to the newer version of bash. This should look like: `.sh=/opt/homebrew/bin/bash`
    - SABnzbd: Edit the script, change line 1 `#!/usr/bin/env bash` to the PATH of the newer version of bash. This should look like: `#!/opt/homebrew/bin/bash`
  
One solution that works for both is to set a launchctl environment variable, You can do so with the following:
```
launchctl setenv PATH $PATH
killall Dock
```
If you have the NZBGet.app or SABnzbd.app already running you will need to restart them.

NOTE: If you choose not to use the launchctl solution, remember to also set the PATH for ffmpeg, ffprobe and jq in either the NZBGet webui or mp4.conf for SABnzbd

Usage
-------
Example commands

```
./mp4.sh -i /path/to/process

./mp4.sh -v -i /path/to/process -c /path/to/config

./mp4.sh -v -i /path/to/process --video-codec=hevc --dual-audio=true --normalize=true
```

Docker
-------
Example [Docker](https://store.docker.com/search?type=edition&offering=community) commands

```
docker run -it --rm \
  -v /path/to/process:/input \
  ghcr.io/digiex/mp4:latest -i /input
```

```
docker create \
  --name nzbget \
  -p 6789:6789 \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=America/New_York \
  -v /path/to/appdata:/config \
  -v /path/to/downloads:/downloads \
  ghcr.io/digiex/nzbget:latest
```

```
docker create \
  --name sabnzbd \
  -p 8080:8080 \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=America/New_York \
  -v /path/to/appdata:/config \
  -v /path/to/downloads:/downloads \
  ghcr.io/digiex/sabnzbd:latest
```

Docker Compose
-------
Examples for docker-compose

```
nzbget:
  image: ghcr.io/digiex/nzbget:latest
  container_name: nzbget
  environment:
    - PUID=1000
    - PGID=1000
    - TZ=America/New_York
    - UMASK_SET=022
  volumes:
    - /path/to/appdata:/config
    - /path/to/downloads:/downloads
  ports:
    - 6789:6789
  restart: unless-stopped
```

```
sabnzbd:
  image: ghcr.io/digiex/sabnzbd:latest
  container_name: sabnzbd
  environment:
    - PUID=1000
    - PGID=1000
    - TZ=America/New_York
    - UMASK_SET=022
  volumes:
    - /path/to/appdata:/config
    - /path/to/downloads:/downloads
  ports:
    - 8080:8080
  restart: unless-stopped
```

Configuration
------------
Running the script once `./mp4.sh` will create a `mp4.conf` file, You may edit
these settings to your liking. You can also specify a location to this
file (if one already exists) by using `-c /path/to/mp4.conf` or `--config=/path/to/mp4.conf`.

Credits & Useful Links
-------------------------
This project makes use of the following:
- https://github.com/linuxserver/docker-nzbget
- https://github.com/linuxserver/docker-sabnzbd

Useful links:
- http://ffmpeg.org/documentation.html
- https://trac.ffmpeg.org/wiki

Enjoy
