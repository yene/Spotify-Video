//
//  AppDelegate.m
//  Spotify Video
//
//  Created by Yannick Weiss on 03/07/15.
//  Copyright © 2015 Yannick Weiss. All rights reserved.
//

#import "AppDelegate.h"
#import <ScriptingBridge/SBApplication.h>
#import "Spotify.h"
#import <AVKit/AVKit.h>
#import <AVFoundation/AVPlayer.h>
#import <XCDYouTubeKit/XCDYouTubeKit.h>


@interface AppDelegate ()
@property (weak) IBOutlet AVPlayerView *playerView;
@property (weak) IBOutlet NSWindow *window;
@end

/* Notes
 * example implementation: https://gist.github.com/kwylez/5337918
 * URL format: https://www.youtube.com/watch?v=dQw4w9WgXcQ
 * add a bit delay to the video so it matches spotify
 */

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  [self playURLinVLC2: @"http://localhost:8000/?q=rick+astley"];
  
  [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTrackInfoFromSpotify:) name:@"com.spotify.client.PlaybackStateChanged" object:nil];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
  // Insert code here to tear down your application
}

- (void)updateTrackInfoFromSpotify:(NSNotification *)notification {
  NSString *playerState = [notification.userInfo valueForKey:@"Player State"];
  NSString *artist = [notification.userInfo valueForKey:@"Artist"];
  NSString *name = [notification.userInfo valueForKey:@"Name"];
  //NSNumber *duration = [notification.userInfo valueForKey:@"Duration"];
  NSNumber *position = [notification.userInfo valueForKey:@"Playback Position"];
  NSString *songDetails = [NSString stringWithFormat:@"%@ %@", name, artist];
  
  if ([playerState isEqualToString:@"Playing"])  {
    if ([position intValue] == 0) {
      NSString *videoID = [self videoIDforSong:songDetails];
      [self playYoutubeVideo:videoID];
      
      /* tell VLC to mute and play localhost:8000/?q=rick+astley */
    } else {
      // todo: check if same video id before resume
      AVPlayer *player = self.playerView.player;
      [player play];
    }
  } else if ([playerState isEqualToString:@"Paused"])  {
    AVPlayer *player = self.playerView.player;
    [player pause];
  } else if ([playerState isEqualToString:@"Stopped"])  {
    
  } else {
    NSLog(@"new state %@", playerState);
  }
}

- (NSString *)videoIDforSong:(NSString *)songDetails {
  NSString *apiKey = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"apiKey"]; // old key: AIzaSyD9sGERE6yX4KvsGGOExAyaAitv7ODOHAY
  songDetails = [songDetails stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
  NSString *url = [NSString stringWithFormat:@"https://www.googleapis.com/youtube/v3/search?part=snippet&maxResults=1&order=viewCount&type=video&key=%@&q=%@", apiKey, songDetails];
  NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
  NSURLResponse* response = nil;
  NSError *error = nil;
  NSData* data = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:&error];
  
  // TODO: more error checking like http://stackoverflow.com/a/7794561/279890
  NSDictionary *results = [NSJSONSerialization
               JSONObjectWithData:data
               options:0
               error:&error];
  NSArray *items = [results objectForKey:@"items"];
  // TODO check items count, should be 1
  return [items[0] valueForKeyPath:@"id.videoId"];
}


- (void)playYoutubeVideo:(NSString *)videoID {
  [[XCDYouTubeClient defaultClient] getVideoWithIdentifier:videoID completionHandler:^(XCDYouTubeVideo *video, NSError *error) {
    if (video) {
      NSDictionary *streamURLs = video.streamURLs;
      NSURL *url = streamURLs[XCDYouTubeVideoQualityHTTPLiveStreaming] ?: streamURLs[@(XCDYouTubeVideoQualityHD720)] ?: streamURLs[@(XCDYouTubeVideoQualityMedium360)] ?: streamURLs[@(XCDYouTubeVideoQualitySmall240)];
      AVPlayer *player = [AVPlayer playerWithURL:url];
      player.volume = 0;
      self.playerView.player = player;
      [player play];
    } else {
      [[NSAlert alertWithError:error] runModal];
    }
  }];
}

- (void)playURLinVLC:(NSString *)url {
  NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
  NSURL *u = [NSURL fileURLWithPath:[workspace fullPathForApplication:@"VLC"]];
  //Handle url==nil
  NSError *error = nil;
  NSArray *arguments = [NSArray arrayWithObjects:url, @"--fullscreen", @"--volume-step=0", nil];
  [workspace launchApplicationAtURL:u options:0 configuration:[NSDictionary dictionaryWithObject:arguments forKey:NSWorkspaceLaunchConfigurationArguments] error:&error];
  //Handle error
}

- (void)playURLinVLC2:(NSString *)url {

  NSString * st = [NSString stringWithFormat:@"tell application \"VLC\" \n"
  "activate \n"
  "OpenURL \"%@\" \n"
  "if not fullscreen mode then \n"
  "fullscreen \n"
  "end if \n"
  "set audio volume to 0 \n"
                   "end tell", url];
  NSAppleScript *script = [[NSAppleScript alloc] initWithSource:st];
  [script executeAndReturnError:nil];
  

}

- (void)spotifyData {
  SpotifyApplication *spotify = [SBApplication applicationWithBundleIdentifier:@"com.spotify.client"];
  if (spotify.isRunning) {
    NSLog(@"spotify is running");
  } else {
    NSLog(@"Spotify not running");
    return;
  }
  
  if (spotify.playerState == SpotifyEPlSStopped) {
    NSLog(@"Spotify is stopped");
    return;
  }
  
  SpotifyTrack *track = spotify.currentTrack;
  NSString *songDetails = [NSString stringWithFormat:@"%@ %@", track.name, track.artist];
  
}

@end
