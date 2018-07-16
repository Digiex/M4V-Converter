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
You can use this script almost anywhere, even on Windows (through virtualization) when using Docker. [Download Docker here!](https://store.docker.com/search?type=edition&offering=community) Run the following command to install the script with NZBGet in Docker!

```
docker create \
  --name nzbget \
  -p 6789:6789 \
  -e PUID=<UID> -e PGID=<GID> \
  -e TZ=<timezone> \
  -v </path/to/appdata>:/config \
  -v </path/to/downloads>:/downloads \
  xzkingzxburnzx/m4v-converter
```

If you prefer SABnzbd, you can get that to!

```
docker create \
  --name sabnzbd \
  -p 8080:8080 -p 9090:9090 \
  -e PUID=<UID> -e PGID=<GID> \
  -e TZ=<timezone> \
  -v </path/to/appdata>:/config \
  -v </path/to/downloads>:/downloads \
  -v </path/to/incomplete-downloads>:/incomplete-downloads \
  xzkingzxburnzx/m4v-converter:sabnzbd
```

Manual Script Usage
--------------------
To run the script manually, (good for batch operations) follow this format:
```
Help output
M4V-Converter.sh -h
Usage: M4V-Converter.sh [-v] [-c CONFIG] [-i INPUT] [-o OUTPUT]

This script automates media conversion to a universal MP4 format using FFmpeg.

optional arguments:
  -h, --help
    Shows this help message.
  -v, --verbose
    Prints extra details such as progress information and the FFmpeg command generated.
  -d, --debug
    Prints generated FFmpeg command ONLY, useful for debugging.
  -b, --background
    Automatically pauses any active converting if a process (determined by --processes=) is found running, including itself.
  -i INPUT, --input=INPUT
    Sets a file or directory as INPUT.
  -o OUTPUT, --output=OUTPUT
    Sets a directory as OUTPUT.
  -c CONFIG, --config=CONFIG
    Sets CONFIG file location.

advanced optional arguments: (Use ONLY if you know what you are doing)
  --ffmpeg=
    Use this to specify a location to the ffmpeg binary when using a non-standard setup.
  --ffprobe=
    Use this to specify a location to the ffprobe binary when using a non-standard setup.
  --threads=
    This is how many threads FFMPEG will use for conversion.
--languages=
    This is the language(s) you prefer.
      NOTE: This is used for audio and subtitles. The first listed is considered the default/preferred.
      NOTE: Selecting "*" will allow all languages.
      NOTE: Use 3 digit code language code, ISO 639-2.
      NOTE: https://en.wikipedia.org/wiki/List_of_ISO_639-2_codes
  --encoder=[h.264, h.265, *]
    This changes which encoder to use.
      NOTE: Selecting "*" will allow H.264 or H.265, defaulting to H.264.
      NOTE: H.264 offers siginificantly more compatbility with devices.
      NOTE: H.265 offers 50-75% more compression efficiency.
  --preset=[ultrafast, superfast, veryfast, faster, fast, medium, slow, slower, veryslow]
    This controls encoding speed to compression ratio.
      NOTE: https://trac.ffmpeg.org/wiki/Encode/H.264#Preset
  --profile=[baseline, main, high, *]
    This defines the features / capabilities that the encoder can use.
      NOTE: Selecting "*" will disable this check.
      NOTE: https://trac.ffmpeg.org/wiki/Encode/H.264#Profile
  --level=[3.0, 3.1, 3.2, 4.0, 4.1, 4.2, 5.0, 5.1, 5.2, *]
    This is another form of constraints that define things like maximum bitrates, framerates and resolution etc.
      NOTE: Selecting "*" will disable this check.
      NOTE: https://trac.ffmpeg.org/wiki/Encode/H.264#Compatibility
  --crf=[0-51]
    This controls maximum compression efficiency with a single pass.
      NOTE: https://trac.ffmpeg.org/wiki/Encode/H.264#crf
  --resolution=
    This will resize the video maintaining aspect ratio.
      NOTE: Ex. 'SD, HD, 720p, 1920x1080, 4K'
      NOTE: https://trac.ffmpeg.org/wiki/Scaling
      NOTE: Using this option MAY cause Radarr/Sonarr to need a manual import due to file quality not matching grabbed release
  --rename=[true,false]
    This will rename the file/folder when resolution is changed.
      NOTE: Ex. 'Video.2018.4K.UHD.King' to 'Video.2018.1080p.King' (when using the above Video Resolution option)
      NOTE: You must allow the script to run as a global extension (applies to all nzbs in queue) for this to work on NZBGet.
  --video-bitrate=
    Use this to limit video bitrate, if exceeded then video will be converted and quality downgraded.
      NOTE: This value is in Kilobytes, Ex. '8192' (8 Mbps)
  --force-video=
    Use this to force the video to convert, overriding all other checks.
  --dual-audio=
    This will create two audio streams, if possible. AAC 2.0 and AC3 5.1.
      NOTE: AAC will be the default for better compatability with more devices.
  --force-audio=
    Use this to force the audio to convert, overriding all other checks.
  --normalize=[]
    This will normalize audio if needed due to downmixing.
  --force-normalize=
    This will force check audio levels for all supported audio streams.
  --subtitles=[true, false, extract]
    This will copy/convert subtitles of your matching language(s) into the converted file or extract them into a srt file.
  --force-subtitles=[false, true]
    Use this to force the subtitles to convert, overriding all other checks.
  --format=[mp4,mov]
    MP4 is better supported universally. MOV is best with Apple devices and iTunes.
  --extension=[mp4,m4v]
    The extension applied at the end of the file, such as video.mp4.
  --delete=[false,true]
    If true then the original file will be deleted.
  --file-permission=
    This will set file permissions in either decimal (493) or octal (leading zero: 0755).
  --directory-permission=
    This will set directory permissions in either decimal (493) or octal (leading zero: 0755).
  --processes=
    These are the processes background mode will look for and auto-pause any active converting if found.
      NOTE: Use quotes when specifying more than one process. Ex. "ffmpeg, Plex Transcoder"
```

Credits & Useful Links
-------------------------
This project makes use of the following projects:
- https://github.com/linuxserver/docker-nzbget
- https://github.com/jrottenberg/ffmpeg

Useful links:
- http://ffmpeg.org/documentation.html
- https://trac.ffmpeg.org/wiki

Enjoy