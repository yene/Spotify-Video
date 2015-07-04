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

@implementation AppDelegate
// https://www.googleapis.com/youtube/v3/search?part=test&type=video&key=AIzaSyD9sGERE6yX4KvsGGOExAyaAitv7ODOHAY
// https://www.googleapis.com/youtube/v3/search?part=snippet&maxResults=1&order=viewCount&q=rick+roll&type=video&key=AIzaSyD9sGERE6yX4KvsGGOExAyaAitv7ODOHAY

// http://stackoverflow.com/questions/8272664/the-most-elegant-way-of-creating-a-fullscreen-overlay-on-mac-os-x-lion

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  // Insert code here to initialize your application
  [self spotifyData];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
  // Insert code here to tear down your application
}

- (void)spotifyData {
  NSArray *selectedApps = [NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.spotify.client"];
  if ([selectedApps count] == 0) {
    NSLog(@"Spotify not running");
    return;
  }
  
  SpotifyApplication *spotify = [SBApplication applicationWithBundleIdentifier:@"com.spotify.client"];
  if (spotify.playerState == SpotifyEPlSStopped) {
    NSLog(@"Spotify is stopped");
    return;
  }
  
  SpotifyTrack *track = spotify.currentTrack;
  NSString *apiURL = @"https://www.googleapis.com/youtube/v3/search?part=snippet&maxResults=1&order=viewCount&type=video&key=AIzaSyD9sGERE6yX4KvsGGOExAyaAitv7ODOHAY&q=";
  NSString *searchString = [NSString stringWithFormat:@"%@ %@", track.name, track.artist];
  searchString = [searchString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
  NSString *url = [apiURL stringByAppendingString:searchString];
  NSURL *urlurl = [NSURL URLWithString:url];
  NSURLRequest *urlRequest = [NSURLRequest requestWithURL:urlurl];
  NSURLResponse* response = nil;
  NSError *error = nil;
  NSData* data = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:&error];
  
  
  
  // TODO: more checking like http://stackoverflow.com/a/7794561/279890
  
  id object = [NSJSONSerialization
               JSONObjectWithData:data
               options:0
               error:&error];

  NSDictionary *results = object;
  NSArray *items = [results objectForKey:@"items"];
  NSString *videoIdentifier = [items[0] valueForKeyPath:@"id.videoId"];
  // https://www.youtube.com/watch?v=dQw4w9WgXcQ
  
  [[XCDYouTubeClient defaultClient] getVideoWithIdentifier:videoIdentifier completionHandler:^(XCDYouTubeVideo *video, NSError *error) {
    if (video)
    {
      // Do something with the `video` object
      NSDictionary *streamURLs = video.streamURLs;
      NSURL *url = streamURLs[XCDYouTubeVideoQualityHTTPLiveStreaming] ?: streamURLs[@(XCDYouTubeVideoQualityHD720)] ?: streamURLs[@(XCDYouTubeVideoQualityMedium360)] ?: streamURLs[@(XCDYouTubeVideoQualitySmall240)];
      AVPlayer *player = [AVPlayer playerWithURL:url];
      player.volume = 0;
      self.playerView.player = player;
      
      [player play];
    }
    else
    {
      // Handle error
      [[NSAlert alertWithError:error] runModal];
    }
  }];
  
}

@end
