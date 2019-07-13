M4V-Converter
==============
This script automates media conversion to a universal MP4 format with many options to customize. Avoid transcoding and support native playback across all devices when using Plex.

Fully integrates with NZBGet so that media converts automatically on post-process! SABnzbd is also supported although it does not get a WebUI config, though can still be configured using a config file!

Tested using Ubuntu Server 16.04 LTS, Debian 8.6.0, Linux Mint 18.1, Fedora Server 25, CentOS 7 and macOS Sierra

Need help with something? [Get support here!](https://digiex.net/threads/m4v-converter-convert-your-media-to-a-universal-format-nzbget-sabnzbd-automation-linux-macos.14997/) Found a bug? [Report it here!](https://github.com/Digiex/M4V-Converter/issues/new)

Dependencies
-------------
Requires `FFmpeg`, `FFprobe` and `Bash`

Docker
-------
[Download Docker](https://store.docker.com/search?type=edition&offering=community) 

```
docker run -it --rm \
  -u <UID>:<GID> \
  -v </path/to/process>:/process \
  xzkingzxburnzx/m4v-converter
```
Run the following command to install the script with NZBGet in Docker!

```
docker create \
  --name nzbget \
  -p 6789:6789 \
  -e PUID=<UID> \
  -e PGID=<GID> \
  -e TZ=<timezone> \
  -v </path/to/appdata>:/config \
  -v </path/to/downloads>:/downloads \
  xzkingzxburnzx/m4v-converter:nzbget
```
If you prefer SABnzbd, you can get that to!

```
docker create \
  --name sabnzbd \
  -p 8080:8080 \
  -p 9090:9090 \
  -e PUID=<UID> \
  -e PGID=<GID> \
  -e TZ=<timezone> \
  -v </path/to/appdata>:/config \
  -v </path/to/downloads>:/downloads \
  -v </path/to/incomplete-downloads>:/incomplete-downloads \
  xzkingzxburnzx/m4v-converter:sabnzbd
```

Manual Script Usage
--------------------
To run the script manually follow this format:
```
Usage: M4V-Converter.sh [-i INPUT]

This script automates media conversion to a universal MP4 format using FFmpeg.

optional arguments:
  -h, --help
    Shows this help message.
  -v, --verbose
    Prints extra details such as progress information and the FFmpeg command generated.
  -d, --debug
    Prints generated FFmpeg command ONLY, useful for debugging.
  -b, --background
    Automatically pauses ffmpeg if a process (determined by --processes=) is found running.
  -i INPUT, --input=INPUT
    Sets a file or directory as INPUT.
  -o OUTPUT, --output=OUTPUT
    Sets a directory as OUTPUT.
  -c CONFIG, --config=CONFIG
    Sets CONFIG file location.

advanced optional arguments: (Use ONLY if you know what you are doing)
  --ffmpeg=
  --ffprobe=
  --threads=
  --languages=
  --encoder=[h.264, h.265, *]
  --preset=[ultrafast, superfast, veryfast, faster, fast, medium, slow, slower, veryslow]
  --profile=[baseline, main, high, *]
  --level=[3.0, 3.1, 3.2, 4.0, 4.1, 4.2, 5.0, 5.1, 5.2, *]
  --force-level=[false, true]
  --crf=[0-51]
  --force-pixel=[false, true]
  --resolution=
  --rename=[true, false]
  --video-bitrate=
  --force-video=[false, true]
  --audio-mode=[aac, ac3, dual, source]
  --force-audio=[false, true]
  --normalize=[false, true]
  --force-normalize=[false, true]
  --subtitles=[true, false, extract]
  --force-subtitles=[false, true]
  --format=[mp4, mov]
  --extension=[mp4, m4v]
  --delete=[false, true]
  --file-permission=
  --directory-permission=
  --processes=
  --required=[false, true]
```
Config File
------------
Included is a `default.conf`, copy/paste it and edit the settings to you liking. Once done, rename it to match the script name exactly and it will be automatically used. This will allow you to avoid having to type long commands. You can also specify a location to this file by using `-c CONFIG` or `--config=CONIFG` replacing CONFIG with the path to your config file.

Credits & Useful Links
-------------------------
This project makes use of the following projects:
- https://github.com/linuxserver/docker-nzbget
- https://github.com/linuxserver/docker-sabnzbd

Useful links:
- http://ffmpeg.org/documentation.html
- https://trac.ffmpeg.org/wiki

Enjoy
