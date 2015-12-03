# Music Video
An OSX app that plays the first youtube video that matches the current iTunes/Spotify song.

![screenshot](http://i.imgur.com/dsyslie.png)

## Notes
* It uses [Sparkle for Github](https://github.com/yene/Sparkle-for-Github) to update.
* URL format: https://www.youtube.com/watch?v=dQw4w9WgXcQ

## Todo
* video should loop
* video is not perfectly in sync with the song
* let the user skip to the next youtube video
* add shazam support
* display a message at the start in the poster image of the video (waiting for spotify itunes + spinner)
* new icon
* test with spotify free and the ads


## Credits and Material
* Example implementation taken from https://gist.github.com/kwylez/5337918
* http://blog.corywiles.com/now-playing-with-spotify-and-itunes

## Getting Spotify and iTunes bridge headers
* `sdef /Applications/iTunes.app | sdp -fh --basename iTunes`

## How to release an update
A quick guide for me:

* Increase Version
* Commit all files
* Push master to Github
* In Xcode archive Version and Export a Developer ID-signed Application
* Zip the exported application
* On github create a new release with the same version (and add a v in front like v2.0)
