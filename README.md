# Spotify Video
An OSX app that watches Spotify and plays a matching youtube video.

![screenshot](http://i.imgur.com/dsyslie.png)

# Notes
* Example implementation taken from https://gist.github.com/kwylez/5337918
* URL format: https://www.youtube.com/watch?v=dQw4w9WgXcQ
* TODO: video is not perfectly in sync with the song
* TODO: get the correct iTunes position form http://blog.corywiles.com/now-playing-with-spotify-and-itunes
* TODO: let the user skip to the next youtube video
* TODO: add shazam support

# How to release update
A quick guide for me:

* Increase Version
* Commit all files
* Push master to Github
* In Xcode archive Version and Export a Developer ID-signed Application
* Zip the exported application
* On github create a new release with the same version (and add a v in front like v2.0)
