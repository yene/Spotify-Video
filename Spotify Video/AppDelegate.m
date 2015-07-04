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

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate
// https://www.googleapis.com/youtube/v3/search?part=test&type=video&key=AIzaSyD9sGERE6yX4KvsGGOExAyaAitv7ODOHAY
// https://www.googleapis.com/youtube/v3/search?part=snippet&maxResults=1&order=viewCount&q=rick+roll&type=video&key=AIzaSyD9sGERE6yX4KvsGGOExAyaAitv7ODOHAY
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
  double bla = spotify.playerPosition;
  if (spotify.playerState == SpotifyEPlSPlaying) {
    SpotifyTrack *track = spotify.currentTrack;
    NSString *songName = track.name;
  }
  
  NSURL *url = [NSURL URLWithString:@"https://www.googleapis.com/youtube/v3/search?part=snippet&maxResults=1&order=viewCount&q=rick+roll&type=video&key=AIzaSyD9sGERE6yX4KvsGGOExAyaAitv7ODOHAY"];
  NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
  NSURLResponse* response = nil;
  NSData* data = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:nil];
  
  
  
  // TODO: more checking like http://stackoverflow.com/a/7794561/279890
  NSError *error = nil;
  id object = [NSJSONSerialization
               JSONObjectWithData:data
               options:0
               error:&error];

  NSDictionary *results = object;
  NSArray *items = [results objectForKey:@"items"];
  NSString *videoID = [items[0] valueForKeyPath:@"id.videoId"];
  // https://www.youtube.com/watch?v=dQw4w9WgXcQ
}

@end
