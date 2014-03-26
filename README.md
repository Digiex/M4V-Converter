M4V-Converter
=============

A simple script designed to convert your media to M4V (mp4) format.

What does it do exactly? It converts your media (movies & tv shows) to a universal format. It also can update couchpotato and sickbeard so they know the file has changed. It also downgrades 5.1 to stereo (2.0) so be aware of that. English audio is preferred and it will use that if found in a file otherwise it will fallback to whatever language is the default. Again thats something to be aware of before using. If for any reason it fails to convert the file it will mark it as ignored and move on. It will not attempt to convert it again. At this point you may need to convert this file mnaully or figure out what is the issue. It also does not bother wth subtitles and if dirty=true it will even delete your downloaded subtitles. If your like me then this will not matter as I only want a English media collection.

Why? Plex! Plex transcodes anything a client cannot play normally and this is almost always caused by the audio format. Though transcoding is a CPU intensive task and if your CPU falls short soon after the client will begin to buffer. By doing this I've not seen Plex transcode not once yet.

If your going to use this make sure you understand exactly what it will do. Give it a try, even a few tries before actually turning it lose of your entire media collection. This way your sure you like the results its producing.

It can be runned via terminal manually or you can set it up to run automaticlly via cron. To do this you just need to execute this 'crontab -e'. Then paste in the following. You should also edit the m4v.sh script and change messages=true to messages=false. Otherwise OS X will send you constant mail.

	SHELL=/usr/local/bin/bash
	PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

	* */6 * * * /Users/Digiex/Scripts/m4v.sh

This means it will run every 6 hours.

I take no reponsibility if you use this and it destroys your entire media collection (although highly unlikely this will happen)

While this script is good it can be better. Please feel free to offer suggestions or pull request.

Dependencies
------------

If your on OS X you will need [Homebrew](http://brew.sh). You will also need ffmpeg and bash. To get these you simple execute 'brew install bash ffmpeg' in terminal.