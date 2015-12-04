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
#import "iTunes.h"
#import <AVKit/AVKit.h>
#import <AVFoundation/AVPlayer.h>
#import <XCDYouTubeKit/XCDYouTubeKit.h>


@interface AppDelegate ()
@property (weak) IBOutlet AVPlayerView *playerView;
@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate {
  NSDate *startTime;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  NSDistributedNotificationCenter *center = [NSDistributedNotificationCenter defaultCenter];
  
  
  iTunesApplication* iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
  if ([iTunes isRunning]) {
    [center addObserver:self selector:@selector(updateTrackInfoFromSpotify:) name:@"com.apple.iTunes.playerInfo" object:nil];

    if (iTunes.playerState == iTunesEPlSPlaying) {
      NSString *artist = [[iTunes currentTrack] artist];
      NSString *name = [[iTunes currentTrack] name];
      double position = [iTunes playerPosition];
      NSString *songDetails = [NSString stringWithFormat:@"%@ %@", name, artist];
      [self playSong:songDetails];
      return;
    }
    
  }
  
  SpotifyApplication *spotify = [SBApplication applicationWithBundleIdentifier:@"com.spotify.client"];
  if ([spotify isRunning]) {
    [center addObserver:self selector:@selector(updateTrackInfoFromSpotify:) name:@"com.spotify.client.PlaybackStateChanged" object:nil];
    
    if (spotify.playerState == SpotifyEPlSPlaying) {
      NSString *artist = [[spotify currentTrack] artist];
      NSString *name = [[spotify currentTrack] name];
      double position = [spotify playerPosition];
      NSString *songDetails = [NSString stringWithFormat:@"%@ %@", name, artist];
      [self playSong:songDetails];
      return;
    }
  }
  
  
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
  [[NSDistributedNotificationCenter defaultCenter] removeObserver:self name:@"com.apple.iTunes.playerInfo" object:nil];
  [[NSDistributedNotificationCenter defaultCenter] removeObserver:self name:@"com.spotify.client.PlaybackStateChanged" object:nil];
}



- (void)updateTrackInfoFromSpotify:(NSNotification *)notification {
  startTime = [NSDate date];
  NSString *playerState = [notification.userInfo valueForKey:@"Player State"];
  NSString *artist = [notification.userInfo valueForKey:@"Artist"];
  NSString *name = [notification.userInfo valueForKey:@"Name"];
  NSNumber *position = [notification.userInfo valueForKey:@"Playback Position"];
  NSString *songDetails = [NSString stringWithFormat:@"%@ %@", name, artist];
  AVPlayer *player = self.playerView.player;
  
  if ([playerState isEqualToString:@"Playing"])  {
    if ([position intValue] == 0) {
      NSLog(@"search song: %@", songDetails);
      [self playSong:songDetails];
    } else {
      if (player) {
        [player play];
      } else {
        // first time start
        int pos = ([position intValue] / 1000) * -1;
        startTime = [startTime dateByAddingTimeInterval:pos];
        [self playSong:songDetails];
      }
      
    }
  } else if ([playerState isEqualToString:@"Paused"])  {
    if (player) {
      [player pause];
    }
  } else if ([playerState isEqualToString:@"Stopped"])  {
    if (player) {
      [player pause];
    }
  } else {
    NSLog(@"new state %@", playerState);
  }
}

- (void)playSong:(NSString *)songDetails {
  songDetails = [songDetails stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
  NSString *url = [NSString stringWithFormat:@"http://youtube.yannickweiss.com/?q=%@", songDetails];
  NSURLSession *session = [NSURLSession sharedSession];
  [[session dataTaskWithURL:[NSURL URLWithString:url] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
    NSString *videoID = @"GqkWnriHGUc";
    NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
    if (!error && statusCode == 200) {
      NSURL *lastURL = [response URL];
      NSString *url = [lastURL query];
      videoID = [[url componentsSeparatedByString:@"="] lastObject];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
      [self playYoutubeVideo:videoID];
    });
  }] resume];
}

- (void)playYoutubeVideo:(NSString *)videoID {
  [[XCDYouTubeClient defaultClient] getVideoWithIdentifier:videoID completionHandler:^(XCDYouTubeVideo *video, NSError *error) {
    if (video) {
      if (self.playerView.player) {
        [self.playerView.player removeObserver:self forKeyPath:@"status"];
      }
      
      NSDictionary *streamURLs = video.streamURLs;
      NSURL *url = streamURLs[XCDYouTubeVideoQualityHTTPLiveStreaming] ?: streamURLs[@(XCDYouTubeVideoQualityHD720)] ?: streamURLs[@(XCDYouTubeVideoQualityMedium360)] ?: streamURLs[@(XCDYouTubeVideoQualitySmall240)];
      AVPlayer *player = [AVPlayer playerWithURL:url];
      
      [player addObserver:self forKeyPath:@"status" options:0 context:nil];
      player.volume = 0;
      self.playerView.player = player;
      [player play];
    } else {
      [[NSAlert alertWithError:error] runModal];
    }
  }];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {
  AVPlayer *player = self.playerView.player;
  if (object == player && [keyPath isEqualToString:@"status"]) {
    if (player.status == AVPlayerStatusReadyToPlay) {
      NSTimeInterval diff = [startTime timeIntervalSinceNow] * -1;
      CMTime t = player.currentTime;
      t.value = diff;
      [player seekToTime:t];
    }
  }
}

@end
