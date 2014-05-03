M4V-Converter
=============

A simple script designed to convert your media to M4V (mp4) format.

What does it do exactly? It converts your media (movies & tv shows) to a universal format. 

Why? Plex! Plex transcodes anything a client cannot play normally and this is almost always caused by the audio format. Though transcoding is a CPU intensive task and if your CPU falls short soon after the client will begin to buffer. By doing this I've not seen Plex transcode not once yet.

If your going to use this make sure you understand exactly what it will do. Give it a try, even a few tries before actually turning it lose of your entire media collection. This way your sure you like the results its producing.

I take no responsibility if you use this and it destroys your entire media collection (although highly unlikely this will happen)

While this script is good it can be better. Please feel free to offer suggestions or pull request.

Dependencies
------------

In order to work properly this script will need root permissions.

If your on OS X you will need [Homebrew](http://brew.sh). You will also need ffmpeg. To get this execute 'brew install ffmpeg' in terminal.

This script works with linux, tested on Ubuntu 14.04. Just make sure [FFMPEG](https://trac.ffmpeg.org/wiki/UbuntuCompilationGuide) is installed.

Usage
-----

This script can be runned via terminal manually via 'sudo ./m4v.sh' or you can set it up to run automaticlly via cron. To do this you just need to execute this 'su', type the root passsword. Now execute 'crontab -e'. Then paste in the following. You should also edit the options before using it.

	* */3 * * * /Users/Digiex/Scripts/m4v.sh


This means it will run every 3 hours.