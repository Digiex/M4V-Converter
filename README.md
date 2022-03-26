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
Requires `Bash v4+`, `FFmpeg`, `FFprobe` and `jq`

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
