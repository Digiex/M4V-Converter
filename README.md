M4V-Converter
=============

A script designed to convert media to mp4 format on post process.

What does it do exactly? It converts your media to a universal format. Why? Plex! Plex transcodes anything a client cannot play normally and this is almost always caused by the audio format. Though transcoding is a CPU intensive task and if your CPU falls short soon after the client will begin to buffer. By using this script you will eliminate transcoding or at least cut down on it.

While this script is good it can be better. Please feel free to offer suggestions or pull request.

Dependencies
------------

You will need [NzbGet](http://nzbget.net/)

If your on OS X you will need [Homebrew](http://brew.sh). You will also need ffmpeg. To get this execute 'brew install ffmpeg' in terminal.

This script works with linux, tested on Ubuntu 14.04. Just make sure [FFMPEG](https://trac.ffmpeg.org/wiki/UbuntuCompilationGuide) [FFPROBE](https://trac.ffmpeg.org/wiki/UbuntuCompilationGuide) and Bash 4+ is installed.

Usage
-----

Throw this script into your NzbGet script directory. Load up the webui and customize settings for 'M4V-Converter' (unless you renamed it).

Begin downloading media, click on an item downloading and select postprocess. Enable the 'M4V-Converter'. 

If everything went well you can go back into NzbGet settings and enable the script for certain categories, such as Movies / Series. (Please make sure you like the results before doing this, test multiple files)

Works with Sonarr & CouchPotato