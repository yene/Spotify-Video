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
#import <AVFoundation/AVPlayerItem.h>
#import <XCDYouTubeKit/XCDYouTubeKit.h>


@interface AppDelegate ()
@property (weak) IBOutlet AVPlayerView *playerView;
@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate {
  NSDate *startTime;
  double requestedPosition;
  NSString *currentSongDetails;
}

- (void)debugSeconds:(double)position {
  int minute = (int)(position/60);
  int seconds = (int)position % 60;
  NSLog(@"start at %d:%01d", minute, seconds);
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  NSDistributedNotificationCenter *center = [NSDistributedNotificationCenter defaultCenter];
  
  currentSongDetails = @"";
  
  SpotifyApplication *spotify = [SBApplication applicationWithBundleIdentifier:@"com.spotify.client"];
  if ([spotify isRunning]) {
    [center addObserver:self selector:@selector(updateTrackInfoFromSpotify:) name:@"com.spotify.client.PlaybackStateChanged" object:nil];
    
    if (spotify.playerState == SpotifyEPlSPlaying) {
      NSString *artist = [[spotify currentTrack] artist];
      NSString *name = [[spotify currentTrack] name];
      double position = [spotify playerPosition];
      
      NSString *songDetails = [NSString stringWithFormat:@"%@ %@", name, artist];
      [self playSong:songDetails fromPosition:position];
      return;
    }
  }
  
  iTunesApplication* iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
  if ([iTunes isRunning]) {
    [center addObserver:self selector:@selector(updateTrackInfoFromSpotify:) name:@"com.apple.iTunes.playerInfo" object:nil];
    
    if (iTunes.playerState == iTunesEPlSPlaying) {
      NSString *artist = [[iTunes currentTrack] artist];
      NSString *name = [[iTunes currentTrack] name];
      double position = [iTunes playerPosition];
      NSString *songDetails = [NSString stringWithFormat:@"%@ %@", name, artist];
      [self playSong:songDetails fromPosition:position];
      return;
    }
  }
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
  //[[NSDistributedNotificationCenter defaultCenter] removeObserver:self name:@"com.apple.iTunes.playerInfo" object:nil];
  [[NSDistributedNotificationCenter defaultCenter] removeObserver:self name:@"com.spotify.client.PlaybackStateChanged" object:nil];
}



- (void)updateTrackInfoFromSpotify:(NSNotification *)notification {
  NSString *playerState = [notification.userInfo valueForKey:@"Player State"];
  NSString *artist = [notification.userInfo valueForKey:@"Artist"];
  NSString *name = [notification.userInfo valueForKey:@"Name"];
  double position = [[notification.userInfo valueForKey:@"Playback Position"] doubleValue];
  NSString *songDetails = [NSString stringWithFormat:@"%@ %@", name, artist];
  AVPlayer *player = self.playerView.player;
  
  if ([playerState isEqualToString:@"Playing"])  {
    if ([currentSongDetails isEqualToString:songDetails]) {
      [player play];
      CMTime t = CMTimeMakeWithSeconds((int)position,1);
      [player seekToTime:t];
    } else {
      // this is a new song
      [self playSong:songDetails fromPosition:position];
    }
  } else if ([playerState isEqualToString:@"Paused"])  {
    [player pause];
  } else if ([playerState isEqualToString:@"Stopped"])  {
    [player pause];
  }
}

- (void)playSong:(NSString *)songDetails fromPosition:(double)pos {
  currentSongDetails = songDetails;
  requestedPosition = pos;
  startTime = [NSDate date];
  
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
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:[self.playerView.player currentItem]];
        
        [self.playerView.player removeObserver:self forKeyPath:@"status"];
      }
      
      NSDictionary *streamURLs = video.streamURLs;
      NSURL *url = streamURLs[XCDYouTubeVideoQualityHTTPLiveStreaming] ?: streamURLs[@(XCDYouTubeVideoQualityHD720)] ?: streamURLs[@(XCDYouTubeVideoQualityMedium360)] ?: streamURLs[@(XCDYouTubeVideoQualitySmall240)];
      AVPlayer *player = [AVPlayer playerWithURL:url];
      
      [player addObserver:self forKeyPath:@"status" options:0 context:nil];
      player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
      
      [[NSNotificationCenter defaultCenter] addObserver:self
                                               selector:@selector(playerItemDidReachEnd:)
                                                   name:AVPlayerItemDidPlayToEndTimeNotification
                                                 object:[player currentItem]];
      
      player.volume = 0;
      self.playerView.player = player;
      [player play];
    } else {
      [[NSAlert alertWithError:error] runModal];
    }
  }];
}

// This gets called when the video is loaded and starts playing.
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {
  AVPlayer *player = self.playerView.player;
  if (object == player && [keyPath isEqualToString:@"status"]) {
    if (player.status == AVPlayerStatusReadyToPlay) {
      // Add the time it too to load and play the video to the current play position.
      NSTimeInterval diff = [startTime timeIntervalSinceNow] * -1;
      CMTime t = CMTimeMakeWithSeconds(round(requestedPosition + diff), 1);
      [player seekToTime:t];
    }
  }
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
  AVPlayerItem *p = [notification object];
  [p seekToTime:kCMTimeZero];
}

@end
