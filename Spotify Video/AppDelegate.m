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
  
  
  return;
  NSString* path = [[NSBundle mainBundle] pathForResource:@"spotify" ofType:@"scpt"];
  NSURL* url = [NSURL fileURLWithPath:path];
  NSDictionary* errors;
  NSAppleEventDescriptor* returnDescriptor = NULL;
  NSAppleScript* appleScript = [[NSAppleScript alloc] initWithContentsOfURL:url error:&errors];
  returnDescriptor = [appleScript executeAndReturnError: &errors];
  NSString *result = [returnDescriptor stringValue];
  NSString *arr = [result componentsSeparatedByString:@","];
  
  //[[returnDescriptor descriptorForKeyword:"form"] stringValue]
  

  
}

@end
