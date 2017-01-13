M4V-Converter
=============

This script is designed to convert your media to a universal mp4 format with support for automation when combined with NZBGet/SABnzbd and many options to customize. Avoid transcoding and support native playback across all devices with Plex.

What does it do exactly? It converts your media to a universal format. Why? Plex! Plex transcodes anything a client cannot play normally but transcoding is a CPU intensive task and if your CPU falls short, soon after the client will begin to buffer. By using this script you will eliminate transcoding or at least cut down on it.

Fully integrates with NZBGet so that media converts on post-process! SABnzbd is also supported although it does not get a WebUI config.

Need help with something? [Get support here!](https://digiex.net/threads/m4v-converter-convert-your-media-to-a-universal-format-nzbget-sabnzbd-automation-linux-macos.14997/)

Tested using Ubuntu Server 16.04 LTS, Debian 8.6.0, Linux Mint 18.1, Fedora Server 25, CentOS 7 and macOS Sierra

Dependencies
------------

Requires FFMPEG, FFPROBE and Bash 4+

Usage
-----

You can run this script in many different ways but the best way is via NZBGet post-process.